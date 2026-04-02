# Text to Image (CC12M Diffusion).ipynb
# Original file is located at https://colab.research.google.com/drive/1TBo4saFn1BCSfgXsmREFrUl3zSQFg6CC

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./v-diffusion-pytorch')

import gc
import math
import sys
import torch
from PIL import Image
from torch import nn
from torchvision import utils as tv_utils
from torchvision.transforms import functional as TF
from torchvision import transforms
from torch.nn import functional as F
from CLIP import clip
from diffusion import get_model, sampling, utils
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompts', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Iterations per update')
  parser.add_argument('--cutn', type=int, help='Cutouts')
  parser.add_argument('--cutpower', type=int, help='Cut power')
  parser.add_argument('--eta', type=float, help='ETA')
  parser.add_argument('--n', type=int, help='Number of images')
  parser.add_argument('--cfg', type=int, help='CFG sampling')
  parser.add_argument('--clip-guidance-scale', type=int, help='CLIP guidance scale')
  parser.add_argument('--model', type=str, help='Diffusion model to load.')
  parser.add_argument('--clipmodel', type=str, help='CLIP model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--starting_timestep', type=float, help='Like skip timesteps but floating point befault 0.9', default=None)
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args3 = parser.parse_args()
  return args3

args=parse_args();

if args.seed is not None:
    sys.stdout.write(f'Setting seed to {args.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args.seed)
    import random
    random.seed(args.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args.seed)
    torch.cuda.manual_seed(args.seed)
    torch.cuda.manual_seed_all(args.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 




device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

sys.stdout.write(f'Loading {args.model}.pth ...\n')
sys.stdout.flush()


class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        for _ in range(self.cutn):
            size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutout = F.adaptive_avg_pool2d(cutout, self.cut_size)
            cutouts.append(cutout)
        return torch.cat(cutouts)

def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)


# Load the models

model = get_model(args.model)()
_, side_y, side_x = model.shape

side_x = args.sizex
side_y = args.sizey

checkpoint = f'./checkpoints/{args.model}.pth'
model.load_state_dict(torch.load(checkpoint, map_location=device))
if device.type == 'cuda':
    model = model.half()
model = model.to(device).eval().requires_grad_(False)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
 

#model.load_state_dict(torch.load('./checkpoints/cc12m_1_cfg.pth', map_location='cpu'))
#model = model.half().cuda().eval().requires_grad_(False)

sys.stdout.write(f'Loading {args.clipmodel} ...\n')
sys.stdout.flush()

clip_model = clip.load(args.clipmodel, jit=False, device=device)[0]

make_cutouts = MakeCutouts(clip_model.visual.input_resolution, args.cutn, args.cutpower )

#@title Settings

#@markdown The text prompt
prompt = args.prompts #'New York City, oil on canvas'  #@param {type:"string"}

#@markdown The strength of the text conditioning (0 means don't condition on text, 1 means sample images that match the text about as well as the images match the text captions in the training set, 3+ is recommended).
weight = 5  #@param {type:"number"}

#@markdown Sample this many images.
n_images = args.n # 4  #@param {type:"integer"}

#@markdown Specify the number of diffusion timesteps (default is 500, can lower for faster but lower quality sampling).
steps = args.iterations # 500  #@param {type:"integer"}

#@markdown Set to 0 for deterministic (DDIM) sampling, 1 (the default) for stochastic (DDPM) sampling, and in between to interpolate between the two. 0 is preferred for low numbers of timesteps.
eta = args.eta  #@param {type:"number"}

#@markdown The random seed. Change this to sample different images.
seed = args.seed #  0#@param {type:"integer"}

#@markdown Display progress every this many timesteps.
display_every = args.update #100  #@param {type:"integer"}

"""### Actually do the run..."""

target_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()
clip_embed = F.normalize(target_embed.mul(weight).sum(0, keepdim=True), dim=-1)
clip_embed = clip_embed.repeat([n_images, 1])

def cfg_model_fn(x, t):
    """The CFG wrapper function."""
    n = x.shape[0]
    x_in = x.repeat([2, 1, 1, 1])
    t_in = t.repeat([2])
    clip_embed_repeat = target_embed.repeat([n, 1])
    clip_embed_in = torch.cat([torch.zeros_like(clip_embed_repeat), clip_embed_repeat])
    v_uncond, v_cond = model(x_in, t_in, clip_embed_in).chunk(2, dim=0)
    v = v_uncond + (v_cond - v_uncond) * weight
    return v


def model_fn(x, t, pred, clip_embed):
    """The non CFG wrapper function."""
    clip_in = normalize(make_cutouts((pred + 1) / 2))
    image_embeds = clip_model.encode_image(clip_in).view([args.cutn, x.shape[0], -1])
    losses = spherical_dist_loss(image_embeds, clip_embed[None])
    loss = losses.mean(0).sum() * args.clip_guidance_scale
    grad = -torch.autograd.grad(loss, x)[0]
    return grad

def display_callback(info):
    sys.stdout.write(f'Iteration {info["i"]+1}\n')
    sys.stdout.flush()
    if (info['i']+1) % display_every == 0:
        nrow = math.ceil(info['pred'].shape[0]**0.5)
        grid = tv_utils.make_grid(info['pred'], nrow, padding=0)
        #sys.stdout.write(f'Step {info["i"]} of {steps}:\n')
        #display.display(utils.to_pil_image(grid))
        #utils.to_pil_image(grid).save('Progress.png')
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()
        
        utils.to_pil_image(grid).save(args.image_file)
        
        if args.frame_dir is not None:
            import os
            file_list = []
            for file in os.listdir(args.frame_dir):
                if file.startswith("FRA"):
                    if file.endswith("png"):
                        if len(file) == 12:
                            file_list.append(file)
            if file_list:
                last_name = file_list[-1]
                count_value = int(last_name[3:8])+1
                count_string = f"{count_value:05d}"
            else:
                count_string = "00001"
            save_name = args.frame_dir+"\FRA"+count_string+".png"
            utils.to_pil_image(grid).save(save_name)
        
        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
        

def run():
    #gc.collect()
    #torch.cuda.empty_cache()
    #torch.manual_seed(seed)
    x = torch.randn([n_images, 3, side_y, side_x], device=device)
    t = torch.linspace(1, 0, steps + 1, device=device)[:-1]
    step_list = utils.get_spliced_ddpm_cosine_schedule(t)
    if args.model=='cc12m_1_cfg':
        if args.cfg==1:
            sys.stdout.write("Sampling with cc12m_1_cgf cfg_model_fn\n")
            sys.stdout.flush()
            outs = sampling.sample(cfg_model_fn, x, step_list, eta, {}, callback=display_callback)
        else:
            sys.stdout.write("Sampling with cc12m_1_cg model_fn\n")
            sys.stdout.flush()
            outs = sampling.cond_sample(model, x, step_list, eta, {'clip_embed': clip_embed}, model_fn, callback=display_callback)
    else:
        sys.stdout.write("Sampling with model_fn\n")
        sys.stdout.flush()
        outs = sampling.cond_sample(model, x, step_list, eta, {'clip_embed': clip_embed}, model_fn, callback=display_callback)

    """
    #tqdm.write('Done!')
    for i, out in enumerate(outs):
        filename = f'out_{i}.png'
        utils.to_pil_image(out).save(filename)
        #display.display(display.Image(filename))
    """

run()