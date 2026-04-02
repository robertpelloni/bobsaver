# CLIP Guided Diffusion HQ.ipynb
# Original file is located at https://colab.research.google.com/drive/12a_Wrfi2_gwwAuN3VvMTwVMz9TfqctNj

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')

import math
from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
import argparse

#In Script Movement
sys.path.append('../')
from image_warping import do_image_warping
from torchvision.transforms import functional as TF

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cutpower', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  parser.add_argument('--r', type=float, help='In script movement. Rotation in degrees.')
  parser.add_argument('--z', type=int, help='In script movement. Zoom in pixels.')
  parser.add_argument('--px', type=int, help='In script movement. Pan X in pixels.')
  parser.add_argument('--py', type=int, help='In script movement. Pan Y in pixels.')
  parser.add_argument('--w', type=int, help='In script movement. Warp in pixels.')
  args = parser.parse_args()
  return args

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




# Define necessary functions

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
            cutout = F.interpolate(cutout, (self.cut_size, self.cut_size),
                                   mode='bilinear', align_corners=False)
            cutouts.append(cutout)
        return torch.cat(cutouts)


def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)


def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])

# Model settings

model_config = model_and_diffusion_defaults()
model_config.update({
    'attention_resolutions': '32, 16, 8',
    'class_cond': False,
    'diffusion_steps': max(1000,args.iterations),
    'rescale_timesteps': True,
    'timestep_respacing': str(args.iterations), #'1000',
    'image_size': 256,
    'learn_sigma': True,
    'noise_schedule': 'linear',
    'num_channels': 256,
    'num_head_channels': 64,
    'num_res_blocks': 2,
    'resblock_updown': True,
    'use_fp16': True,
    'use_scale_shift_norm': True,
})

# Load models

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

sys.stdout.write("Loading 256x256_diffusion_uncond.pt ...\n")
sys.stdout.flush()

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load('256x256_diffusion_uncond.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

clip_model = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

"""## Settings for this run:"""

prompt = args.prompt
batch_size = 1
init_image = args.seed_image
clip_guidance_scale = 1000
tv_scale = 200 #originally 100, but Katherine Crowson recommended 200 on discord
cutn = args.cutn #16
skip_timesteps = 0
seed = 0

"""### Actually do the run..."""

text_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

init = None
if init_image is not None:
    init = Image.open(init_image).convert('RGB')
    init = init.resize((model_config['image_size'], model_config['image_size']), Image.LANCZOS)
    init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
    skip_timesteps = 100  #skip a number of initial steps to allow the seed image to work

make_cutouts = MakeCutouts(clip_size, cutn)

cur_t = diffusion.num_timesteps - 1

def cond_fn(x, t, y=None):
    with torch.enable_grad():
        x = x.detach().requires_grad_()
        n = x.shape[0]
        my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
        out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
        fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
        x_in = out['pred_xstart'] * fac + x * (1 - fac)
        clip_in = normalize(make_cutouts(x_in.add(1).div(2)))
        image_embeds = clip_model.encode_image(clip_in).float().view([cutn, n, -1])
        dists = spherical_dist_loss(image_embeds, text_embed.unsqueeze(0))
        losses = dists.mean(0)
        tv_losses = tv_loss(x_in)
        loss = losses.sum() * clip_guidance_scale + tv_losses.sum() * tv_scale
        return -torch.autograd.grad(loss, x)[0]

if model_config['timestep_respacing'].startswith('ddim'):
    sample_fn = diffusion.ddim_sample_loop_progressive
else:
    sample_fn = diffusion.p_sample_loop_progressive

samples = sample_fn(
    model,
    (batch_size, 3, model_config['image_size'], model_config['image_size']),
    clip_denoised=False,
    model_kwargs={},
    cond_fn=cond_fn,
    progress=False,
    skip_timesteps=skip_timesteps,
    init_image=init,
)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
for i, sample in enumerate(samples):
    cur_t -= 1
    sys.stdout.write(f'Iteration {itt}\n')
    sys.stdout.flush()
    if itt % args.update == 0 or cur_t == -1:
        #print()
        for j, image in enumerate(sample['pred_xstart']):
            sys.stdout.flush()
            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()
            filename = args.image_file
            TF.to_pil_image(image.add(1).div(2).clamp(0, 1)).save(filename)
            
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
                TF.to_pil_image(image.add(1).div(2).clamp(0, 1)).save(save_name)
            
            sys.stdout.flush()
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()
            
            #In Script Movement - make sure "global z" and "global opt" are defined
            if args.r is not None:
                #do_image_warping(Image.fromarray(im_arr),r,z,px,py,w):  
                #im_arr = np.array(image.add(1).div(2).clamp(0, 1))
                im_arr = TF.to_tensor(image.add(1).div(2).clamp(0, 1))
                im_arr = do_image_warping(im_arr,args.r,args.z,args.px,args.py,args.w)
                #convert warped image array back into the optimizer for the next iteration
                #z, *_ = model.encode(TF.to_tensor(im_arr).to(device).unsqueeze(0) * 2 - 1)
                #z.requires_grad_(True)
                #opt = optim.Adam([z], lr=args.mse_step_size, weight_decay=0.00000000)
                #image = TF.to_tensor(im_arr).to(device).unsqueeze(0) * 2 - 1

            
    itt = itt+1
