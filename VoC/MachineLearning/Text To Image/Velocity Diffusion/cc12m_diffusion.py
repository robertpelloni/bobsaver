# Text to Image (CC12M Diffusion).ipynb
# Original file is located at https://colab.research.google.com/drive/1TBo4saFn1BCSfgXsmREFrUl3zSQFg6CC

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./v-diffusion-pytorch')

import gc
import math
import sys
from IPython import display
import torch
from torchvision import utils as tv_utils
from torchvision.transforms import functional as TF
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
  parser.add_argument('--images', type=int, help='Number of images')
  parser.add_argument('--update', type=int, help='Iterations per update')
  parser.add_argument('--image_file', type=str, help='Output image name.')
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


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

sys.stdout.write(f'Loading cc12m_1_cfg ...\n')
sys.stdout.flush()

# Load the models

model = get_model('cc12m_1_cfg')()
_, side_y, side_x = model.shape

side_x = args.sizex
side_y = args.sizey

model.load_state_dict(torch.load('./checkpoints/cc12m_1_cfg.pth', map_location='cpu'))
model = model.half().cuda().eval().requires_grad_(False)
clip_model = clip.load(model.clip_model, jit=False, device='cpu')[0]

#@title Settings

#@markdown The text prompt
prompt = args.prompts #'New York City, oil on canvas'  #@param {type:"string"}

#@markdown The strength of the text conditioning (0 means don't condition on text, 1 means sample images that match the text about as well as the images match the text captions in the training set, 3+ is recommended).
weight = 5  #@param {type:"number"}

#@markdown Sample this many images.
n_images = args.images  #@param {type:"integer"}

#@markdown Specify the number of diffusion timesteps (default is 50, can lower for faster but lower quality sampling).
steps = args.iterations #50  #@param {type:"integer"}

#@markdown The random seed. Change this to sample different images.
seed = args.seed  #@param {type:"integer"}

#@markdown Display progress every this many timesteps.
display_every =   args.update #10#@param {type:"integer"}

"""### Actually do the run..."""

target_embed = clip_model.encode_text(clip.tokenize(prompt)).float().cuda()


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


def display_callback(info):
    sys.stdout.write(f'Iteration {info["i"]+1}\n')
    sys.stdout.flush()
    if (info['i']+1) % display_every == 0:
        nrow = math.ceil(info['pred'].shape[0]**0.5)
        grid = tv_utils.make_grid(info['pred'], nrow, padding=0)

        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()
        
        utils.to_pil_image(grid).save(args.image_file)
        
        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
        


def run():
    gc.collect()
    torch.cuda.empty_cache()
    torch.manual_seed(seed)
    x = torch.randn([n_images, 3, side_y, side_x], device='cuda')
    t = torch.linspace(1, 0, steps + 1, device='cuda')[:-1]
    step_list = utils.get_spliced_ddpm_cosine_schedule(t)
    outs = sampling.plms_sample(cfg_model_fn, x, step_list, {}, callback=display_callback)

    """
    for i, out in enumerate(outs):
        filename = f'out_{i}.png'
        utils.to_pil_image(out).save(filename)
    """
    
run()