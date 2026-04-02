# Upscaling-UltraQuick CLIP Guided Diffusion HQ 256x256 and 512x512.ipynb
# Original file is located at https://colab.research.google.com/github/sadnow/360Diffusion/blob/main/360Diffusion_AlphaTesting.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
#@markdown ##imports
import time
import gc
import io
import math
import sys
import lpips
from PIL import Image, ImageOps
import requests
import torch
from torch import nn
from torch.nn import functional as F
import torchvision.transforms as T
import torchvision.transforms.functional as TF
sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')
import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
from datetime import datetime #filename
import numpy as np
import matplotlib.pyplot as plt
import random

#import subprocess #future implementation
import os
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
  parser.add_argument('--cutnbatches', type=int, help='Cutout batches')
  parser.add_argument('--tvscale', type=int, help='TV scale')
  parser.add_argument('--rangescale', type=int, help='Range scale')
  parser.add_argument('--guidancescale', type=int, help='CLIP guidance scale')
  parser.add_argument('--saturationscale', type=int, help='Saturation scale')
  parser.add_argument('--ddim', type=int, help='Use ddim iterations')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--initscale', type=int, help='Init scale')
  parser.add_argument('--skiptimesteps', type=int, help='Skip timesteps')
  parser.add_argument('--skipseedtimesteps', type=int, help='Skip timesteps')
  parser.add_argument('--image256', type=int, help='Render smaller 256x256 sized images.')
  parser.add_argument('--clipmodel', type=str, help='CLIP Model.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();





# Check the GPU status
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

# a100_support = False #@param {type:"boolean"}

enable_error_checking = False #saves ram

#@markdown *Special thanks to sportracer48 and his Discord channel. If you want to make AI animations, he has the meats in closed beta.* https://www.patreon.com/sportsracer48
# if a100_support:
#   print("If you have an A100: Turn your cutn to 64-96 and keep your batch_n low (1 or 2), and it will be fast!")
#   !pip install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html

# function runAllCells() {
#   const F9Event = {key: "F9", code: "F9", metaKey: true, keyCode: 120};
#   document.dispatchEvent(new KeyboardEvent("keydown", F9Event));
# } #https://stackoverflow.com/questions/65984431/run-all-cells-command-in-google-colab-programmatically




#@title Choose model here:
if args.image256==0:
    diffusion_model = "512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]
else:
    diffusion_model = "256x256_diffusion_uncond"

#@markdown If you connect your Google Drive, you can save the final image of each run on your drive.

google_drive = False #@param {type:"boolean"}

#@markdown You can use your mounted Google Drive to load the model checkpoint file if you've already got a copy downloaded there. This will save time (and resources!) when you re-visit this notebook in the future.

#@markdown Click here if you'd like to save the diffusion model checkpoint file to (and/or load from) your Google Drive:
yes_please = False #@param {type:"boolean"}



_drive_location = './' #@param{type:"string"}
contains_slash = (_drive_location.endswith('/'))
if not contains_slash:
  _drive_location = _drive_location + '/'



model_path = './'


#@title  { form-width: "100px" }

# https://gist.github.com/adefossez/0646dbe9ed4005480a2407c62aac8869

def add_command(var,string):
  var = (var + string + ' ')
  return var

def image_resize(filepath,width):
  from PIL import Image
  basewidth = width
  img = Image.open(filepath)
  wpercent = (basewidth/float(img.size[0]))
  hsize = int((float(img.size[1])*float(wpercent)))
  #img = img.resize((basewidth,hsize), Image.ANTIALIAS)
  if width == 1024: img = img.resize((basewidth,hsize), Image.LANCZOS)
  else: img = img.resize((basewidth,hsize), Image.BICUBIC)
  img.save(filepath)


# def image_filter_edge(filepath):
#   #Import required image modules
#   from PIL import Image, ImageFilter
#   #Import all the enhancement filter from pillow
#   from PIL.ImageFilter import (
#     BLUR, CONTOUR, DETAIL, EDGE_ENHANCE, EDGE_ENHANCE_MORE,
#     EMBOSS, FIND_EDGES, SMOOTH, SMOOTH_MORE, SHARPEN
#   )
#   #Create image object
#   img = Image.open(filepath)
#   #Applying the blur filter
#   img1 = img.filter(EDGE_ENHANCE_MORE)
#   img1.save(filepath)
#   img1.show()

#####################################################################################################################
# https://gist.github.com/adefossez/0646dbe9ed4005480a2407c62aac8869

def interp(t):
    return 3 * t**2 - 2 * t ** 3

def perlin(width, height, scale=10, device=None):
    gx, gy = torch.randn(2, width + 1, height + 1, 1, 1, device=device)
    xs = torch.linspace(0, 1, scale + 1)[:-1, None].to(device)
    ys = torch.linspace(0, 1, scale + 1)[None, :-1].to(device)
    wx = 1 - interp(xs)
    wy = 1 - interp(ys)
    dots = 0
    dots += wx * wy * (gx[:-1, :-1] * xs + gy[:-1, :-1] * ys)
    dots += (1 - wx) * wy * (-gx[1:, :-1] * (1 - xs) + gy[1:, :-1] * ys)
    dots += wx * (1 - wy) * (gx[:-1, 1:] * xs - gy[:-1, 1:] * (1 - ys))
    dots += (1 - wx) * (1 - wy) * (-gx[1:, 1:] * (1 - xs) - gy[1:, 1:] * (1 - ys))
    return dots.permute(0, 2, 1, 3).contiguous().view(width * scale, height * scale)

def perlin_ms(octaves, width, height, grayscale, device=device):
    out_array = [0.5] if grayscale else [0.5, 0.5, 0.5]
    # out_array = [0.0] if grayscale else [0.0, 0.0, 0.0]
    for i in range(1 if grayscale else 3):
        scale = 2 ** len(octaves)
        oct_width = width
        oct_height = height
        for oct in octaves:
            p = perlin(oct_width, oct_height, scale, device)
            out_array[i] += p * oct
            scale //= 2
            oct_width *= 2
            oct_height *= 2
    return torch.cat(out_array)

def create_perlin_noise(octaves=[1, 1, 1, 1], width=2, height=2, grayscale=True):
    out = perlin_ms(octaves, width, height, grayscale)
    if grayscale:
        out = TF.resize(size=(side_x, side_y), img=out.unsqueeze(0))
        out = TF.to_pil_image(out.clamp(0, 1)).convert('RGB')
    else:
        out = out.reshape(-1, 3, out.shape[0]//3, out.shape[1])
        out = TF.resize(size=(side_x, side_y), img=out)
        out = TF.to_pil_image(out.clamp(0, 1).squeeze())

    out = ImageOps.autocontrast(out)
    return out

#################################################################################################################
def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')


def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    return vals[0], float(vals[1])

def sinc(x):
    return torch.where(x != 0, torch.sin(math.pi * x) / (math.pi * x), x.new_ones([]))

def lanczos(x, a):
    cond = torch.logical_and(-a < x, x < a)
    out = torch.where(cond, sinc(x) * sinc(x/a), x.new_zeros([]))
    return out / out.sum()

def ramp(ratio, width):
    n = math.ceil(width / ratio + 1)
    out = torch.empty([n])
    cur = 0
    for i in range(out.shape[0]):
        out[i] = cur
        cur += ratio
    return torch.cat([-out[1:].flip([0]), out])[1:-1]

def resample(input, size, align_corners=True):
    n, c, h, w = input.shape
    dh, dw = size

    input = input.reshape([n * c, 1, h, w])

    if dh < h:
        kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
        pad_h = (kernel_h.shape[0] - 1) // 2
        input = F.pad(input, (0, 0, pad_h, pad_h), 'reflect')
        input = F.conv2d(input, kernel_h[None, None, :, None])

    if dw < w:
        kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
        pad_w = (kernel_w.shape[0] - 1) // 2
        input = F.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
        input = F.conv2d(input, kernel_w[None, None, None, :])

    input = input.reshape([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)


class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, skip_augs=False):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.skip_augs = skip_augs
        self.augs = T.Compose([
            T.RandomHorizontalFlip(p=0.5),
            T.RandomAffine(degrees=15, translate=(0.1, 0.1)),
            T.RandomPerspective(distortion_scale=0.4, p=0.7),
            T.RandomGrayscale(p=0.15),
        ])


    def forward(self, input):
        input = T.Pad(input.shape[2]//4, fill=0)(input)
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)

        cutouts = []
        for ch in range(cutn):
            if ch > cutn - cutn//4:
                cutout = input.clone()
            else:
                size = int(max_size * torch.zeros(1,).normal_(mean=.8, std=.3).clip(float(self.cut_size/max_size), 1.))
                offsetx = torch.randint(0, abs(sideX - size + 1), ())
                offsety = torch.randint(0, abs(sideY - size + 1), ())
                cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]

            if not self.skip_augs:
                cutout = self.augs(cutout)
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
            del cutout

        cutouts = torch.cat(cutouts, dim=0)
        return cutouts


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


def range_loss(input):
    return (input - input.clamp(-1, 1)).pow(2).mean([1, 2, 3])

###
# NEWEST PERLIN NOISE EDITS
def unitwise_norm(x, norm_type=2.0):
    if x.ndim <= 1:
        return x.norm(norm_type)
    else:
        # works for nn.ConvNd and nn,Linear where output dim is first in the kernel/weight tensor
        # might need special cases for other weights (possibly MHA) where this may not be true
        return x.norm(norm_type, dim=tuple(range(1, x.ndim)), keepdim=True)
def adaptive_clip_grad(parameters, clip_factor=0.01, eps=1e-3, norm_type=2.0):
    if isinstance(parameters, torch.Tensor):
        parameters = [parameters]
    for p in parameters:
        if p.grad is None:
            continue
        p_data = p.detach()
        g_data = p.grad.detach()
        max_norm = unitwise_norm(p_data, norm_type=norm_type).clamp_(min=eps).mul_(clip_factor)
        grad_norm = unitwise_norm(g_data, norm_type=norm_type)
        clipped_grad = g_data * (max_norm / grad_norm.clamp(min=1e-6))
        new_grads = torch.where(grad_norm < max_norm, g_data, clipped_grad)
        p.grad.detach().copy_(new_grads)

def regen_perlin(): #NEWEST PERLIN UPDATE
    if perlin_mode == 'color':
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, False)
    elif perlin_mode == 'gray':
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, True)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
    else:
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)

    init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device).unsqueeze(0).mul(2).sub(1)
    del init2
    return init

##########################################################################################################

#@markdown ##def do_run()
def do_run():
    global firstRun,_scale_multiplier
    loss_values = []

    if seed is not None:
        np.random.seed(seed)
        random.seed(seed)
        torch.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True

    make_cutouts = MakeCutouts(clip_size, cutn, skip_augs=skip_augs)
    target_embeds, weights = [], []

    for prompt in text_prompts:
        txt, weight = parse_prompt(prompt)
        txt = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()
        #----
        if fuzzy_prompt:
            for i in range(25):
                # target_embeds.append((txt + torch.randn(txt.shape).cuda() * rand_mag).clamp(0,1))
                target_embeds.append(txt + torch.randn(txt.shape).cuda() * rand_mag)
                weights.append(weight)
        else:
            target_embeds.append(txt)
            weights.append(weight)

    for prompt in image_prompts:
        path, weight = parse_prompt(prompt)
        img = Image.open(fetch(path)).convert('RGB')
        img = TF.resize(img, min(side_x, side_y, *img.size), T.InterpolationMode.LANCZOS)
        batch = make_cutouts(TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
        embed = clip_model.encode_image(normalize(batch)).float()
        if fuzzy_prompt:
            for i in range(25):
                # target_embeds.append((embed + torch.randn(embed.shape).cuda() * rand_mag).clamp(0,1))
                target_embeds.append(embed + torch.randn(embed.shape).cuda() * rand_mag)
                weights.extend([weight / cutn] * cutn)
        else:
            target_embeds.append(embed)
            weights.extend([weight / cutn] * cutn)

    target_embeds = torch.cat(target_embeds)
    weights = torch.tensor(weights, device=device)
    if weights.sum().abs() < 1e-3:
        raise RuntimeError('The weights must not sum to 0.')
    weights /= weights.sum().abs()

    init = None
    if init_image is not None:
        init = Image.open(fetch(init_image)).convert('RGB')
        init = init.resize((side_x, side_y), Image.LANCZOS)
        init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
    
    cur_t = None

    def cond_fn(x, t, y=None):
        with torch.enable_grad():
            x = x.detach().requires_grad_()
            n = x.shape[0]
            my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
            out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
            fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
            x_in = out['pred_xstart'] * fac + x * (1 - fac)
            x_in_grad = torch.zeros_like(x_in)
            for i in range(cutn_batches):
                clip_in = normalize(make_cutouts(x_in.add(1).div(2)))
                image_embeds = clip_model.encode_image(clip_in).float()
                dists = spherical_dist_loss(image_embeds.unsqueeze(1), target_embeds.unsqueeze(0))
                dists = dists.view([cutn, n, -1])
                losses = dists.mul(weights).sum(2).mean(0)
                loss_values.append(losses.sum().item()) # log loss, probably shouldn't do per cutn_batch
                x_in_grad += torch.autograd.grad(losses.sum() * clip_guidance_scale, x_in)[0] / cutn_batches
            tv_losses = tv_loss(x_in)
            range_losses = range_loss(out['pred_xstart'])
            sat_losses = torch.abs(x_in - x_in.clamp(min=-1,max=1)).mean()
            loss = tv_losses.sum() * tv_scale + range_losses.sum() * range_scale + sat_losses.sum() * sat_scale
            if init is not None and init_scale:
                init_losses = lpips_model(x_in, init)
                loss = loss + init_losses.sum() * init_scale
            x_in_grad += torch.autograd.grad(loss, x_in)[0]
            grad = -torch.autograd.grad(x_in, x, x_in_grad)[0]
        if clamp_grad:
            adaptive_clip_grad([x]) #ADDED WITH PERLIN UPDATE
            magnitude = grad.square().mean().sqrt()
            return grad * magnitude.clamp(max=0.05) / magnitude
        return grad

    if model_config['timestep_respacing'].startswith('ddim'):
        sample_fn = diffusion.ddim_sample_loop_progressive
    else:
        sample_fn = diffusion.p_sample_loop_progressive

    sys.stdout.write("Starting ...\n")
    sys.stdout.flush()

    itt=1
    for i in range(n_batches):
        cur_t = diffusion.num_timesteps - skip_timesteps - 1
        
        if perlin_init: #ADDED WITH PERLIN UPDATE 
            init = regen_perlin()

        if model_config['timestep_respacing'].startswith('ddim'):
            samples = sample_fn(
                model,
                (batch_size, 3, side_y, side_x),
                clip_denoised=clip_denoised,
                model_kwargs={},
                cond_fn=cond_fn,
                progress=False,
                skip_timesteps=skip_timesteps,
                init_image=init,
                randomize_class=randomize_class,
                eta=eta,
            )
        else:
            samples = sample_fn(
                model,
                (batch_size, 3, side_y, side_x),
                clip_denoised=clip_denoised,
                model_kwargs={},
                cond_fn=cond_fn,
                progress=False,
                skip_timesteps=skip_timesteps,
                init_image=init,
                randomize_class=randomize_class,
            )

        for j, sample in enumerate(samples):
            cur_t -= 1
            sys.stdout.write(f'Iteration {itt}\n')
            sys.stdout.flush()
            #if j % display_rate == 0 or cur_t == -1:  #Only single iteration has finished
            if itt % args.update == 0 or cur_t == -1:
                for k, image in enumerate(sample['pred_xstart']):
                    sys.stdout.flush()
                    sys.stdout.write('Saving progress ...\n')
                    sys.stdout.flush()

                    image = TF.to_pil_image(image.add(1).div(2).clamp(0, 1))
                    image.save(args.image_file) 
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
                        image.save(save_name) 
                    
                    
                    sys.stdout.flush()
                    sys.stdout.write('Progress saved\n')
                    sys.stdout.flush()
            itt+=1


"""# Settings & Generation"""

if args.seed_image is not None:
    init_image = args.seed_image   # This can be an URL or Colab local path and must be in quotes.
    skip_timesteps = args.skipseedtimesteps  # 12 Skip unstable steps                  # Higher values make the output look more like the init.
    init_scale = args.initscale      # This enhances the effect of the init image, a good value is 1000.
else:
    init_image = None   # This can be an URL or Colab local path and must be in quotes.
    skip_timesteps = 5  # 12 Skip unstable steps                  # Higher values make the output look more like the init.
    init_scale = 0      # This enhances the effect of the init image, a good value is 1000.



if args.ddim == 1:
    timestep_respacing = "ddim"+str(args.iterations)
else:
    timestep_respacing = str(args.iterations)
# timestep_respacing = '25'
diffusion_steps = max(1000,args.iterations)

model_config = model_and_diffusion_defaults()
if diffusion_model == '512x512_diffusion_uncond_finetune_008100':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': diffusion_steps,
        'rescale_timesteps': True,
        'timestep_respacing': timestep_respacing,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == '256x256_diffusion_uncond':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': diffusion_steps,
        'rescale_timesteps': True,
        'timestep_respacing': timestep_respacing,
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
side_x = side_y = model_config['image_size']

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load(f'{model_path}{diffusion_model}.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

################################################

sys.stdout.write("Loading "+args.clipmodel+" CLIP model ...\n")
sys.stdout.flush()

clip_model = clip.load(args.clipmodel, jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)

# Commented out IPython magic to ensure Python compatibility.
#file
  #open
#edit
#view
########################################################################
#INITIAL VALUES
#@title  { form-width: "300px" }
firstRun = True
msg_runtime = ''
_keep_first_upscale = False
_run_upscaler = True
batch_size =  1
clamp_grad = True # True - Experimental: Using adaptive clip grad in the cond_fn
skip_augs = False # False - Controls whether to skip torchvision augmentations
randomize_class = True # True - Controls whether the imagenet class is randomly changed each iteration
#############################################################################################
  # This will be the name of your project folder in Drive.

_batch_genetics = False #future implementation
_init_genetics = False  #not currently implemented
_max_genetic_variance =  0.1
_saturation_scale =  0

#_enhance_upscale = True #@param{type:"boolean"}

cutn =  args.cutn #30#@param{type:"raw"}
  #Controls how many crops to take from the image. Increase for higher quality.
cutn_batches = args.cutnbatches #2 #@param [1,2,4,8,16] {type:"raw"}

  #Accumulate CLIP gradient from multiple batches of cuts [Can help with OOM errors / Low VRAM]
_esrgan_tilesize = "512" #@param[16,32,64,128,256,512,1024]
#_upscale_performance_mode = False
#@markdown `Performance Settings`

#@markdown ---
clip_denoised = False #@param{type:"boolean"}
fuzzy_prompt = False #@param{type:"boolean"}
  # False - Controls whether to add multiple noisy prompts to the prompt losses
eta =  0.5
_clip_guidance_scale =  args.guidancescale#@param {type:"raw"}
_tv_scale =  args.tvscale #50#@param {type:"raw"}
_range_scale =  args.rangescale #150#@param {type:"raw"}
_scale_multiplier = 1 #@param {type:"slider", min:0.1, max:5, step:0.1}
#@markdown `Visual Settings`
##@markdown ---
seed = args.seed
# seed = random.randint(0, 2**32) # Choose a random seed and print it at end of run for reproduction

#@markdown ---
#_text_prompt =  "art piece titled 'The meaning of life is to find meaning IN life', existential clipart featuring your friend Dave, vector clipart anime faces" #@param {type:"string"} 
_text_prompt =  str(args.prompt) #@param {type:"string"} 
_noise_mode = 'gray' #@param ['mixed','gray','color']
_noise_amount = 0.05 #@param {type:"slider", min:0.00, max:1, step:0.01}



n_batches =  1#@param{type:"raw"}
  #Controls the starting point along the diffusion timesteps

#@markdown `Generation Settings`

#@markdown ---
_project_name = 'existential' #@param{type:"string"}
global _debug_mode
_debug_mode = False #@param{type:"boolean"}
_upscale_model='RealESRGAN 4x' #@param ['(Regular) ESRGAN 4x','RealESR_NET 4x','RealESRGAN 2x','RealESRGAN 4x','RealESRGAN x4 Anime_6B']
_target_resolution = "2048" #@param[256,512,1024,2048,4096]
_skip_upscaling = False
display_rate =  1#@param{type:"raw"}
##@markdown Original Defaults: `clip_guidance_scale 5000`,`tv_scale 150`,`range scale 150`
##@markdown Recommended defaults for init_images (ddim50): `clip_guidance_scale 2000`,`tv_scale 150`,`range scale 50`, `init_scale 1000`, `skip_timesteps 16 (7-9 for ddim25)`
##@markdown There is a possibility that `tv_scale` can be set between `0` to `10000`
##@markdown `skip_timesteps` does a lot for the similarity in `init_settings`
##@markdown Special thanks to many people on the VQLIPSE Discord
##---

#--------------------------------------------------------------------------------------------------------

"""
text_prompts = [
    # "an abstract painting of 'ravioli on a plate'",
    # 'cyberpunk wizard on top of a skyscraper, trending on artstation, photorealistic depiction of a cyberpunk wizard',
    _text_prompt]
    # 'cyberpunk wizard',
"""
text_prompts =  [ phrase.strip() for phrase in args.prompt.split("|") ]

if diffusion_model == "512x512_diffusion_uncond_finetune_008100": model_size = 512
else: model_size = 256
if int(_target_resolution) == model_size:
  print("\n Due to your _target_resolution, _skip_upsscaling will be enabled. \n")
  _skip_upscaling = True
if int(model_size) > int(_target_resolution):
  print("\n NOTICE: Your _upscale_reoslution is higher than your model size! Setting to match and disabling upscaling... \n")
  _target_resolution = int(model_size)
  _skip_upscaling = True


if _noise_amount > 0: 
  add_random_noise = True
else:
  add_random_noise = False

# if not _init_image == '':  #to prevent noise from messing with init
#   if add_random_noise == True:
#     msg_runtime = msg_runtime + 'Notice: init_images have mixed results when _noise_amount > 0 \n'
#   # _noise_amount = 0
#   # add_random_noise = False
perlin_init = add_random_noise
if init_image is not None: # Can't combine init_image and perlin options
  perlin_init = False
  msg_runtime = msg_runtime + 'NOTICE: You may want to disable _noise_amount when using _init_images \n'


rand_mag = _noise_amount # 0.1 - Controls the magnitude of the random noise

image_prompts = []
perlin_mode = _noise_mode # 'mixed' ('gray', 'color')

sat_scale = _saturation_scale
  # 0 - Controls how much saturation is allowed. From nshepperd's JAX notebook.

##@markdown `skip_timesteps` best 5 (thx steven), 10 for dd50

###@markdown False - Determines whether CLIP discriminates a noisy or denoised image
# if _diffusion_int == 512: display_rate = 2
# else: display_rate = 1
###@markdown False - Controls whether to add multiple noisy prompts to the prompt losses
###@markdown 0.0 - DDIM hyperparameter


################################################
#---------------------------------------------------------------------------------------
#Output image directory handling
import os
output_folder_images = '.'
temp_image_storage = './'  #for non-upscaled images

#---------------------------------------------------------------------------------------
def calculate_scale_multiplier():
  global clip_guidance_scale,tv_scale,range_scale
  clip_guidance_scale = _scale_multiplier * _clip_guidance_scale
  tv_scale = _scale_multiplier * _tv_scale
  range_scale = _scale_multiplier * _range_scale
  return clip_guidance_scale,tv_scale,range_scale
calculate_scale_multiplier()

#-------------------------------------------------------

do_run()
