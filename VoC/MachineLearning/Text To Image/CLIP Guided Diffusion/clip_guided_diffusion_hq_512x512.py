# CLIP Guided Diffusion HQ (512x512 edit).ipynb
# Original file is located at https://colab.research.google.com/drive/1Fl2SZvLv23MVSAHxkoiNdxPeAZwibvu1

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import math
from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF

sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')

from CLIP.clip import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults


import argparse

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
  parser.add_argument('--finetune', type=int, help='Use alternate fine tune model.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
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

# Model setup
model_config = model_and_diffusion_defaults()
if args.finetune == 1:
    model_config.update({
        "attention_resolutions": "32, 16, 8",
        "class_cond": False,
        "diffusion_steps": max(1000,args.iterations),
        "rescale_timesteps": True,
        "timestep_respacing": str(args.iterations),
        "image_size": 512,
        "learn_sigma": True,
        "noise_schedule": "linear",
        "num_channels": 256,
        "num_head_channels": 64,
        "num_res_blocks": 2,
        "resblock_updown": True,
        "use_fp16": True,
        "use_scale_shift_norm": True,
    })
else:
    model_config.update({
        "attention_resolutions": "32, 16, 8",
        "class_cond": True,
        "diffusion_steps": max(1000,args.iterations),
        "rescale_timesteps": True,
        "timestep_respacing": str(args.iterations),
        "image_size": 512,
        "learn_sigma": True,
        "noise_schedule": "linear",
        "num_channels": 256,
        "num_head_channels": 64,
        "num_res_blocks": 2,
        "resblock_updown": True,
        "use_fp16": True,
        "use_scale_shift_norm": True,
    })


model_config

# Load models

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

"""
sys.stdout.write("Loading 512x512_diffusion.pt ...\n")
sys.stdout.flush()

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load('512x512_diffusion.pt', map_location='cpu'))
"""

if args.finetune==1:
    sys.stdout.write("Loading 512x512_diffusion_uncond_finetune_008100.pt ...\n")
    sys.stdout.flush()
    model, diffusion = create_model_and_diffusion(**model_config)
    model.load_state_dict(torch.load('512x512_diffusion_uncond_finetune_008100.pt', map_location='cpu'))
else:
    sys.stdout.write("Loading 512x512_diffusion.pt ...\n")
    sys.stdout.flush()
    model, diffusion = create_model_and_diffusion(**model_config)
    model.load_state_dict(torch.load('512x512_diffusion.pt', map_location='cpu'))

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

# Pick a class for sampling
if args.finetune == 1:
    model_kwargs = {}
else:
    model_kwargs = {"y": torch.randint(low=0, high=999, size=(1,), device=device,)} # picks a random Imagenet 2012 class
#model_kwargs["y"] = torch.Tensor([classnumber]).to(int).to(device) # alternatively, uncomment this line, then choose a class from https://gist.github.com/yrevar/942d3a0ac09ec9e5eb3a and put its number where classnumber is

prompt = args.prompt
batch_size = 1
init_image = args.seed_image
clip_guidance_scale = 1000
tv_scale = 150
cutn = args.cutn
skip_timesteps = 0
n_batches = 1
seed = args.seed

"""### Actually do the run..."""

#if seed is not None:
#    torch.manual_seed(seed)

text_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

init = None
if init_image is not None:
    init = Image.open(init_image).convert('RGB')
    init = init.resize((model_config['image_size'], model_config['image_size']), Image.LANCZOS)
    init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
    skip_timesteps = 25 #skip a number of initial steps to allow the seed image to work


make_cutouts = MakeCutouts(clip_size, cutn)

cur_t = None

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

itt=1
for i in range(n_batches):
    cur_t = diffusion.num_timesteps - 1

    samples = sample_fn(
        model,
        (batch_size, 3, model_config['image_size'], model_config['image_size']),
        clip_denoised=False,
        model_kwargs=model_kwargs,
        cond_fn=cond_fn,
        progress=False,
        skip_timesteps=skip_timesteps,
        init_image=init,
    )

    for j, sample in enumerate(samples):
        sys.stdout.write(f'Iteration {itt}\n')
        sys.stdout.flush()
        cur_t -= 1
        if itt % args.update == 0 or cur_t == -1:
            #print()
            for k, image in enumerate(sample['pred_xstart']):
                #filename = f'progress_{i * batch_size + k:05}.png'
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
        itt = itt+1
