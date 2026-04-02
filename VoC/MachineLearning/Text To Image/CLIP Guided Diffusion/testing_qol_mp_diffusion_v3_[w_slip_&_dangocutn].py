# Testing QoL MP Diffusion v3 [w/ SLIP & DangoCutn].ipynb
# Original file is located at https://colab.research.google.com/drive/1bItz4NdhAPHg5-u87KcH-MmJZjK-XqHN

google_drive = False #@param {type:"boolean"}

#@markdown Click here if you'd like to save the diffusion model checkpoint file to (and/or load from) your Google Drive:
yes_please = False #@param {type:"boolean"}

root_path = '.'
initDirPath = './init_images'
outDirPath = './images_out'
model_path = '.'

import os
from os import path

import sys
sys.path.append('./SLIP')
sys.path.append('./ResizeRight')
from dataclasses import dataclass
from functools import partial
import gc
import io
import math
import timm
from IPython import display
import lpips
from PIL import Image, ImageOps
import requests
from glob import glob
import json
import torch
from torch import nn
from torch.nn import functional as F
import torchvision.transforms as T
import torchvision.transforms.functional as TF
from tqdm.notebook import tqdm
sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')
import clip
from resize_right import resize
from models import SLIP_VITB16, SLIP, SLIP_VITL16
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
import random

import torch
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))


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
        out = TF.resize(size=(side_y, side_x), img=out.unsqueeze(0))
        out = TF.to_pil_image(out.clamp(0, 1)).convert('RGB')
    else:
        out = out.reshape(-1, 3, out.shape[0]//3, out.shape[1])
        out = TF.resize(size=(side_y, side_x), img=out)
        out = TF.to_pil_image(out.clamp(0, 1).squeeze())

    out = ImageOps.autocontrast(out)
    return out

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
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomAffine(degrees=15, translate=(0.1, 0.1)),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomPerspective(distortion_scale=0.4, p=0.7),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomGrayscale(p=0.15),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            # T.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1),
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

cutout_debug = False
padargs = {}

class MakeCutoutsDango(nn.Module):
    def __init__(self, cut_size,
                 Overview=4, 
                 InnerCrop = 0, IC_Size_Pow=0.5, IC_Grey_P = 0.2
                 ):
        super().__init__()
        self.cut_size = cut_size
        self.Overview = Overview
        self.InnerCrop = InnerCrop
        self.IC_Size_Pow = IC_Size_Pow
        self.IC_Grey_P = IC_Grey_P
        self.augs = T.Compose([
            T.RandomHorizontalFlip(p=0.5),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomAffine(degrees=10, translate=(0.05, 0.05),  interpolation = T.InterpolationMode.BILINEAR),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomGrayscale(p=0.1),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1),
        ])

    def forward(self, input):
        cutouts = []
        gray = T.Grayscale(3)
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        l_size = max(sideX, sideY)
        output_shape = [1,3,self.cut_size,self.cut_size] 
        output_shape_2 = [1,3,self.cut_size+2,self.cut_size+2]
        pad_input = F.pad(input,((sideY-max_size)//2,(sideY-max_size)//2,(sideX-max_size)//2,(sideX-max_size)//2), **padargs)
        cutout = resize(pad_input, out_shape=output_shape)

        if self.Overview>0:
            if self.Overview<=4:
                if self.Overview>=1:
                    cutouts.append(cutout)
                if self.Overview>=2:
                    cutouts.append(gray(cutout))
                if self.Overview>=3:
                    cutouts.append(TF.hflip(cutout))
                if self.Overview==4:
                    cutouts.append(gray(TF.hflip(cutout)))
            else:
                cutout = resize(pad_input, out_shape=output_shape)
                for _ in range(self.Overview):
                    cutouts.append(cutout)

            if cutout_debug:
                TF.to_pil_image(cutouts[0].add(1).div(2).clamp(0, 1).squeeze(0)).save("content/diff/cutouts/cutout_overview.jpg",quality=99)
                
        if self.InnerCrop >0:
            for i in range(self.InnerCrop):
                size = int(torch.rand([])**self.IC_Size_Pow * (max_size - min_size) + min_size)
                offsetx = torch.randint(0, sideX - size + 1, ())
                offsety = torch.randint(0, sideY - size + 1, ())
                cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
                if i <= int(self.IC_Grey_P * self.InnerCrop):
                    cutout = gray(cutout)
                cutout = resize(cutout, out_shape=output_shape)
                cutouts.append(cutout)
            if cutout_debug:
                TF.to_pil_image(cutouts[-1].add(1).div(2).clamp(0, 1).squeeze(0)).save("content/diff/cutouts/cutout_InnerCrop.jpg",quality=99)
        cutouts = torch.cat(cutouts)
        if skip_augs is not True: cutouts=self.augs(cutouts)
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


def do_run():
    loss_values = []
 
    if seed is not None:
        np.random.seed(seed)
        random.seed(seed)
        torch.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
 
    target_embeds, weights = [], []
    
    
    model_stats = []
    for clip_model in clip_models:
          
          model_stat = {"clip_model":None,"target_embeds":[],"make_cutouts":None,"weights":[]}
          model_stat["clip_model"] = clip_model
          # model_stat["make_cutouts"] = MakeCutouts(clip_model.visual.input_resolution, cutn, skip_augs=skip_augs)
          # model_stat["make_cutouts"] = MakeCutoutsDango(clip_model.visual.input_resolution,
          #          Overview= cut_overview[1000-t], 
          #          InnerCrop = cut_innercut[1000-t], IC_Size_Pow=cut_ic_pow, IC_Grey_P = cut_icgray_p[1000-t]
          #          )
          model_stat["make_cutouts"] = MakeCutouts(224, cutn, skip_augs=skip_augs)  

          for prompt in text_prompts:
              txt, weight = parse_prompt(prompt)
              txt = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

              if fuzzy_prompt:
                  for i in range(25):
                      model_stat["target_embeds"].append((txt + torch.randn(txt.shape).cuda() * rand_mag).clamp(0,1))
                      model_stat["weights"].append(weight)
              else:
                  model_stat["target_embeds"].append(txt)
                  model_stat["weights"].append(weight)
      
          # for prompt in image_prompts:
          #     path, weight = parse_prompt(prompt)
          #     img = Image.open(fetch(path)).convert('RGB')
          #     img = TF.resize(img, min(side_x, side_y, *img.size), T.InterpolationMode.LANCZOS)
          #     batch = model_stat["make_cutouts"](TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
          #     embed = clip_model.encode_image(normalize(batch)).float()
          #     if fuzzy_prompt:
          #         for i in range(25):
          #             model_stat["target_embeds"].append((embed + torch.randn(embed.shape).cuda() * rand_mag).clamp(0,1))
          #             weights.extend([weight / cutn] * cutn)
          #     else:
          #         model_stat["target_embeds"].append(embed)
          #         model_stat["weights"].extend([weight / cutn] * cutn)
      
          model_stat["target_embeds"] = torch.cat(model_stat["target_embeds"])
          model_stat["weights"] = torch.tensor(model_stat["weights"], device=device)
          if model_stat["weights"].sum().abs() < 1e-3:
              raise RuntimeError('The weights must not sum to 0.')
          model_stat["weights"] /= model_stat["weights"].sum().abs()
          model_stats.append(model_stat)
 
    init = None
    if init_image is not None:
        init = Image.open(fetch(init_image)).convert('RGB')
        init = init.resize((side_x, side_y), Image.LANCZOS)
        init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
    
    if perlin_init:
        if perlin_mode == 'color':
            init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
            init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, False)
        elif perlin_mode == 'gray':
           init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, True)
           init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
        else:
           init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
           init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
        
        # init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device)
        init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device).unsqueeze(0).mul(2).sub(1)
        del init2
 
    cur_t = None
 
    def cond_fn(x, t, y=None):
        with torch.enable_grad():
            # prep_model_cuts(clip_models, model_stats, t)
            # for clip_model in clip_models:
            #   for model_stat in model_stats:
            #     if model_stat["clip_model"] == clip_model:
            #       print('making cutouts')
            #       model_stat["make_cutouts"] = MakeCutoutsDango(224,
            #               Overview= cut_overview[1000-t], 
            #               InnerCrop = cut_innercut[1000-t], IC_Size_Pow=cut_ic_pow, IC_Grey_P = cut_icgray_p[1000-t]
            #               )
            x = x.detach().requires_grad_()
            n = x.shape[0]
            if use_secondary_model is True:
              alpha = torch.tensor(diffusion.sqrt_alphas_cumprod[cur_t], device=device, dtype=torch.float32)
              sigma = torch.tensor(diffusion.sqrt_one_minus_alphas_cumprod[cur_t], device=device, dtype=torch.float32)
              cosine_t = alpha_sigma_to_t(alpha, sigma)
              out = secondary_model(x, cosine_t[None].repeat([n])).pred
              fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
              x_in = out * fac + x * (1 - fac)
              x_in_grad = torch.zeros_like(x_in)
            else:
              my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
              out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
              fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
              x_in = out['pred_xstart'] * fac + x * (1 - fac)
              x_in_grad = torch.zeros_like(x_in)
            for model_stat in model_stats:
              for i in range(cutn_batches):
                  t_int = int(t.item())+1 #errors on last step without +1, need to find source
                  #cuts = MakeCutoutsDango(224,
                  try:
                    input_resolution=model_stat["clip_model"].visual.input_resolution
                  except:
                    input_resolution=224
                  cuts = MakeCutoutsDango(input_resolution,
                          Overview= cut_overview[1000-t_int], 
                          InnerCrop = cut_innercut[1000-t_int], IC_Size_Pow=cut_ic_pow, IC_Grey_P = cut_icgray_p[1000-t_int]
                          )
                  clip_in = normalize(cuts(x_in.add(1).div(2)))
                  image_embeds = model_stat["clip_model"].encode_image(clip_in).float()
                  dists = spherical_dist_loss(image_embeds.unsqueeze(1), model_stat["target_embeds"].unsqueeze(0))
                  dists = dists.view([40, n, -1]) #hardcoded 40 for dango cuts i think? otherwise should be `cutn`
                  losses = dists.mul(model_stat["weights"]).sum(2).mean(0)
                  loss_values.append(losses.sum().item()) # log loss, probably shouldn't do per cutn_batch
                  x_in_grad += torch.autograd.grad(losses.sum() * clip_guidance_scale, x_in)[0] / cutn_batches
            tv_losses = tv_loss(x_in)
            if use_secondary_model is True:
              range_losses = range_loss(out)
            else:
              range_losses = range_loss(out['pred_xstart'])
            sat_losses = torch.abs(x_in - x_in.clamp(min=-1,max=1)).mean()
            loss = tv_losses.sum() * tv_scale + range_losses.sum() * range_scale + sat_losses.sum() * sat_scale
            if init is not None and init_scale:
                init_losses = lpips_model(x_in, init)
                loss = loss + init_losses.sum() * init_scale
            x_in_grad += torch.autograd.grad(loss, x_in)[0]
            grad = -torch.autograd.grad(x_in, x, x_in_grad)[0]
        if clamp_grad:
            magnitude = grad.square().mean().sqrt()
            return grad * magnitude.clamp(max=0.05) / magnitude
        return grad
 
    if model_config['timestep_respacing'].startswith('ddim'):
        sample_fn = diffusion.ddim_sample_loop_progressive
    else:
        sample_fn = diffusion.p_sample_loop_progressive
 
    for i in range(n_batches):
        cur_t = diffusion.num_timesteps - skip_timesteps - 1
        total_steps = cur_t
 
        if model_config['timestep_respacing'].startswith('ddim'):
            samples = sample_fn(
                model,
                (batch_size, 3, side_y, side_x),
                clip_denoised=clip_denoised,
                model_kwargs={},
                cond_fn=cond_fn,
                progress=True,
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
                progress=True,
                skip_timesteps=skip_timesteps,
                init_image=init,
                randomize_class=randomize_class,
            )

        for j, sample in enumerate(samples):
            display.clear_output(wait=True)
            cur_t -= 1
            intermediateStep = False
            if steps_per_checkpoint is not None:
                if j % steps_per_checkpoint == 0 and j > 0:
                  intermediateStep = True
            elif j in intermediate_saves:
              intermediateStep = True
            if j % display_rate == 0 or cur_t == -1 or intermediateStep == True:
                for k, image in enumerate(sample['pred_xstart']):
                    tqdm.write(f'Batch {i}, step {j}, output {k}:')
                    current_time = datetime.now().strftime('%y%m%d-%H%M%S_%f')
                    percent = math.ceil(j/total_steps*100)
                    if n_batches > 0:
                      #if intermediates are saved to the subfolder, don't append a step or percentage to the name
                      if cur_t == -1 and intermediates_in_subfolder is True:
                        filename = f'{batch_name}({batchNum})_{i:04}.png'
                      else:
                        #If we're working with percentages, append it
                        if steps_per_checkpoint is not None:
                          filename = f'{batch_name}({batchNum})_{i:04}-{percent:02}%.png'
                        # Or else, iIf we're working with specific steps, append those
                        else:
                          filename = f'{batch_name}({batchNum})_{i:04}-{j:03}.png'
                    image = TF.to_pil_image(image.add(1).div(2).clamp(0, 1))
                    image.save('progress.png')
                    display.display(display.Image('progress.png'))
                    if steps_per_checkpoint is not None:
                      if j % steps_per_checkpoint == 0 and j > 0:
                        if intermediates_in_subfolder is True:
                          image.save(f'{partialFolder}/{filename}')
                        else:
                          image.save(f'{batchFolder}/{filename}')
                    else:
                      if j in intermediate_saves:
                        if intermediates_in_subfolder is True:
                          image.save(f'{partialFolder}/{filename}')
                        else:
                          image.save(f'{batchFolder}/{filename}')
                    if cur_t == -1:
                      if i == 0:
                        save_settings()
                      image.save(f'{batchFolder}/{filename}')
 
        plt.plot(np.array(loss_values), 'r')

def save_settings():
  setting_list = {
    'text_prompts': text_prompts,
    'image_prompts': image_prompts,
    'clip_guidance_scale': clip_guidance_scale,
    'tv_scale': tv_scale,
    'range_scale': range_scale,
    'sat_scale': sat_scale,
    'cutn': cutn,
    'cutn_batches': cutn_batches,
    'init_image': init_image,
    'init_scale': init_scale,
    'skip_timesteps': skip_timesteps,
    'perlin_init': perlin_init,
    'perlin_mode': perlin_mode,
    'skip_augs': skip_augs,
    'randomize_class': randomize_class,
    'clip_denoised': clip_denoised,
    'clamp_grad': clamp_grad,
    'seed': seed,
    'fuzzy_prompt': fuzzy_prompt,
    'rand_mag': rand_mag,
    'eta': eta,
    'width': width,
    'height': height,
    'diffusion_model': diffusion_model,
    'use_secondary_model': use_secondary_model,
    'timestep_respacing': timestep_respacing,
    'timestep_respacing': timestep_respacing,
    'diffusion_steps': diffusion_steps,
    'ViTB32': ViTB32,
    'ViTB16': ViTB16,
    'RN101': RN101,
    'RN50': RN50,
    'RN50x4': RN50x4,
    'RN50x16': RN50x16,
  }
  print('Settings:', setting_list)
  with open(f"{batchFolder}/{batch_name}({batchNum})_settings.txt", "w+") as f:   #save settings
    json.dump(setting_list, f, ensure_ascii=False, indent=4)

#@title 2.3 Define the secondary diffusion model

def append_dims(x, n):
    return x[(Ellipsis, *(None,) * (n - x.ndim))]


def expand_to_planes(x, shape):
    return append_dims(x, len(shape)).repeat([1, 1, *shape[2:]])


def alpha_sigma_to_t(alpha, sigma):
    return torch.atan2(sigma, alpha) * 2 / math.pi


def t_to_alpha_sigma(t):
    return torch.cos(t * math.pi / 2), torch.sin(t * math.pi / 2)


@dataclass
class DiffusionOutput:
    v: torch.Tensor
    pred: torch.Tensor
    eps: torch.Tensor


class ConvBlock(nn.Sequential):
    def __init__(self, c_in, c_out):
        super().__init__(
            nn.Conv2d(c_in, c_out, 3, padding=1),
            nn.ReLU(inplace=True),
        )


class SkipBlock(nn.Module):
    def __init__(self, main, skip=None):
        super().__init__()
        self.main = nn.Sequential(*main)
        self.skip = skip if skip else nn.Identity()

    def forward(self, input):
        return torch.cat([self.main(input), self.skip(input)], dim=1)


class FourierFeatures(nn.Module):
    def __init__(self, in_features, out_features, std=1.):
        super().__init__()
        assert out_features % 2 == 0
        self.weight = nn.Parameter(torch.randn([out_features // 2, in_features]) * std)

    def forward(self, input):
        f = 2 * math.pi * input @ self.weight.T
        return torch.cat([f.cos(), f.sin()], dim=-1)


class SecondaryDiffusionImageNet(nn.Module):
    def __init__(self):
        super().__init__()
        c = 64  # The base channel count

        self.timestep_embed = FourierFeatures(1, 16)

        self.net = nn.Sequential(
            ConvBlock(3 + 16, c),
            ConvBlock(c, c),
            SkipBlock([
                nn.AvgPool2d(2),
                ConvBlock(c, c * 2),
                ConvBlock(c * 2, c * 2),
                SkipBlock([
                    nn.AvgPool2d(2),
                    ConvBlock(c * 2, c * 4),
                    ConvBlock(c * 4, c * 4),
                    SkipBlock([
                        nn.AvgPool2d(2),
                        ConvBlock(c * 4, c * 8),
                        ConvBlock(c * 8, c * 4),
                        nn.Upsample(scale_factor=2, mode='bilinear', align_corners=False),
                    ]),
                    ConvBlock(c * 8, c * 4),
                    ConvBlock(c * 4, c * 2),
                    nn.Upsample(scale_factor=2, mode='bilinear', align_corners=False),
                ]),
                ConvBlock(c * 4, c * 2),
                ConvBlock(c * 2, c),
                nn.Upsample(scale_factor=2, mode='bilinear', align_corners=False),
            ]),
            ConvBlock(c * 2, c),
            nn.Conv2d(c, 3, 3, padding=1),
        )

    def forward(self, input, t):
        timestep_embed = expand_to_planes(self.timestep_embed(t[:, None]), input.shape)
        v = self.net(torch.cat([input, timestep_embed], dim=1))
        alphas, sigmas = map(partial(append_dims, n=v.ndim), t_to_alpha_sigma(t))
        pred = input * alphas - v * sigmas
        eps = input * sigmas + v * alphas
        return DiffusionOutput(v, pred, eps)


class SecondaryDiffusionImageNet2(nn.Module):
    def __init__(self):
        super().__init__()
        c = 64  # The base channel count
        cs = [c, c * 2, c * 2, c * 4, c * 4, c * 8]

        self.timestep_embed = FourierFeatures(1, 16)
        self.down = nn.AvgPool2d(2)
        self.up = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=False)

        self.net = nn.Sequential(
            ConvBlock(3 + 16, cs[0]),
            ConvBlock(cs[0], cs[0]),
            SkipBlock([
                self.down,
                ConvBlock(cs[0], cs[1]),
                ConvBlock(cs[1], cs[1]),
                SkipBlock([
                    self.down,
                    ConvBlock(cs[1], cs[2]),
                    ConvBlock(cs[2], cs[2]),
                    SkipBlock([
                        self.down,
                        ConvBlock(cs[2], cs[3]),
                        ConvBlock(cs[3], cs[3]),
                        SkipBlock([
                            self.down,
                            ConvBlock(cs[3], cs[4]),
                            ConvBlock(cs[4], cs[4]),
                            SkipBlock([
                                self.down,
                                ConvBlock(cs[4], cs[5]),
                                ConvBlock(cs[5], cs[5]),
                                ConvBlock(cs[5], cs[5]),
                                ConvBlock(cs[5], cs[4]),
                                self.up,
                            ]),
                            ConvBlock(cs[4] * 2, cs[4]),
                            ConvBlock(cs[4], cs[3]),
                            self.up,
                        ]),
                        ConvBlock(cs[3] * 2, cs[3]),
                        ConvBlock(cs[3], cs[2]),
                        self.up,
                    ]),
                    ConvBlock(cs[2] * 2, cs[2]),
                    ConvBlock(cs[2], cs[1]),
                    self.up,
                ]),
                ConvBlock(cs[1] * 2, cs[1]),
                ConvBlock(cs[1], cs[0]),
                self.up,
            ]),
            ConvBlock(cs[0] * 2, cs[0]),
            nn.Conv2d(cs[0], 3, 3, padding=1),
        )

    def forward(self, input, t):
        timestep_embed = expand_to_planes(self.timestep_embed(t[:, None]), input.shape)
        v = self.net(torch.cat([input, timestep_embed], dim=1))
        alphas, sigmas = map(partial(append_dims, n=v.ndim), t_to_alpha_sigma(t))
        pred = input * alphas - v * sigmas
        eps = input * sigmas + v * alphas
        return DiffusionOutput(v, pred, eps)

"""# 3. Diffusion and CLIP model settings"""

diffusion_model = "512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]

use_secondary_model = True #@param {type: 'boolean'}

timestep_respacing = '250' #@param ['25','50','100','150','250','500','1000','ddim25','ddim50', 'ddim75', 'ddim100','ddim150','ddim250','ddim500','ddim1000']  
diffusion_steps = 1000 #@param {type: 'number'}
"""
ViTB32 = True #@param{type:"boolean"}
ViTB16 = True #@param{type:"boolean"}
RN101 = False #@param{type:"boolean"}
RN50 = True #@param{type:"boolean"}
RN50x4 = False #@param{type:"boolean"}
RN50x16 = False #@param{type:"boolean"}
SLIPB16 = False #@param{type:"boolean"}
SLIPL16 = False #@param{type:"boolean"}
#@markdown *RN50x16 for A100 only*
"""
ViTB32 = True #@param{type:"boolean"}
ViTB16 = True #@param{type:"boolean"}
RN101 = False #@param{type:"boolean"}
RN50 = False #@param{type:"boolean"}
RN50x4 = True #@param{type:"boolean"}
RN50x16 = False #@param{type:"boolean"}
SLIPB16 = False #@param{type:"boolean"}
SLIPL16 = False #@param{type:"boolean"}

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
        'use_checkpoint': True,
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
        'use_checkpoint': True,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })

secondary_model_ver = 2
model_default = model_config['image_size']

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load(f'{model_path}/{diffusion_model}.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

if secondary_model_ver == 2:
    secondary_model = SecondaryDiffusionImageNet2()
    secondary_model.load_state_dict(torch.load(f'{model_path}/secondary_model_imagenet_2.pth', map_location='cpu'))
secondary_model.eval().requires_grad_(False).to(device)

clip_models = []
if ViTB32 is True: clip_models.append(clip.load('ViT-B/32', jit=False)[0].eval().requires_grad_(False).to(device)) 
if ViTB16 is True: clip_models.append(clip.load('ViT-B/16', jit=False)[0].eval().requires_grad_(False).to(device) ) 
if RN50 is True: clip_models.append(clip.load('RN50', jit=False)[0].eval().requires_grad_(False).to(device))
if RN50x4 is True: clip_models.append(clip.load('RN50x4', jit=False)[0].eval().requires_grad_(False).to(device)) 
if RN50x16 is True: clip_models.append(clip.load('RN50x16', jit=False)[0].eval().requires_grad_(False).to(device)) 
if RN101 is True: clip_models.append(clip.load('RN101', jit=False)[0].eval().requires_grad_(False).to(device)) 

if SLIPB16:
  SLIPB16model = SLIP_VITB16(ssl_mlp_dim=4096, ssl_emb_dim=256)
  #next 2 lines needed so torch.load handles posix paths on Windows
  import pathlib          
  pathlib.PosixPath = pathlib.WindowsPath
  sd = torch.load(f'{model_path}/slip_base_100ep.pt')
  real_sd = {}
  for k, v in sd['state_dict'].items():
    real_sd['.'.join(k.split('.')[1:])] = v
  del sd
  SLIPB16model.load_state_dict(real_sd)
  SLIPB16model.requires_grad_(False).eval().to(device)

  clip_models.append(SLIPB16model)

if SLIPL16:
  SLIPL16model = SLIP_VITL16(ssl_mlp_dim=4096, ssl_emb_dim=256)
  #next 2 lines needed so torch.load handles posix paths on Windows
  import pathlib          
  pathlib.PosixPath = pathlib.WindowsPath
  sd = torch.load(f'{model_path}/slip_large_100ep.pt')
  real_sd = {}
  for k, v in sd['state_dict'].items():
    real_sd['.'.join(k.split('.')[1:])] = v
  del sd
  SLIPL16model.load_state_dict(real_sd)
  SLIPL16model.requires_grad_(False).eval().to(device)

  clip_models.append(SLIPL16model)

normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)

"""# 4. Settings"""

#@markdown ####**Basic Settings:**

clip_guidance_scale = 25000 #@param{type: 'number'}
tv_scale =  0#@param{type: 'number'}
range_scale = 150  #@param{type: 'number'}
sat_scale = 0  #@param{type: 'number'}
cutn = 16  #param{type: 'number'}
cutn_batches = 1  #@param{type: 'number'}

init_image = '' #@param{type: 'string'}
init_scale =   200#@param{type: 'number'}
skip_timesteps = 0  #@param{type: 'number'}

#@markdown Size must be multiple of 64. Leave as `model_default` for default sizes. 
width = 704#@param{type: 'raw'}
height = 1024#@param{type: 'raw'}

#@markdown ---

#@markdown ####**Saving:**
batch_name = 'Test' #@param{type: 'string'}
batchFolder = f'{outDirPath}/{batch_name}'
partialFolder = f'{batchFolder}/partials'

intermediate_saves =  5#@param{type: 'raw'}
intermediates_in_subfolder = True #@param{type: 'boolean'}
#@markdown Intermediate steps will save a copy at your specified intervals. You can either format it as a single integer or a list of specific steps 

#@markdown A value of `2` will save a copy at 33% and 66%. 0 will save none.

#@markdown A value of `[5, 9, 34, 45]` will save at steps 5, 9, 34, and 45. (Make sure to include the brackets)

cut_overview = [40]*400+[20]*600     
cut_innercut =[0]*400 + [20]*600
cut_ic_pow = 1
cut_icgray_p = [0.2]*400+[0]*900

#@markdown ---

#@markdown ####**Advanced Settings:**
#@markdown *Perlin init will replace your init, so uncheck if using one.*

perlin_init = True  #@param{type: 'boolean'}
perlin_mode = 'mixed' 

skip_augs = False #@param{type: 'boolean'}
randomize_class = True #@param{type: 'boolean'}
clip_denoised = False #@param{type: 'boolean'}
clamp_grad = True #@param{type: 'boolean'}

seed = 'random_seed' #@param{type: 'string'}

fuzzy_prompt = False #@param{type: 'boolean'}
rand_mag = 0.05  #@param{type: 'number'}
eta =   1#@param{type: 'number'}

if type(intermediate_saves) is not list:
  steps_per_checkpoint = math.floor((diffusion.num_timesteps - skip_timesteps - 1) // (intermediate_saves+1))
  steps_per_checkpoint = steps_per_checkpoint if steps_per_checkpoint > 0 else 1
  print(f'Will save every {steps_per_checkpoint} steps')
else:
  steps_per_checkpoint = None


if init_image == '':
  init_image = None

side_x = width;
side_y = height;

"""
#Make folder for batch
batchFolder = f'{outDirPath}/{batch_name}'
createPath(batchFolder)
partialFolder = f'{batchFolder}/partials'
createPath(partialFolder)
"""

"""##Prompts"""

text_prompts = [
    "A beautiful photo-realistic render of a street scene set in columbia from 'bioshock infinite' by the artist of 'dishonored' CEDRYC PYARNVEYNY and jules verne",
]

image_prompts = [ 
    # 'mona.jpg',
]

"""# 5. Diffuse!"""

#@title Do the Run!

display_rate = 2 #@param{type: 'number'}
n_batches =  1#@param{type: 'number'}
batch_size = 1 

batchNum = len(glob(batchFolder+"/*.txt"))

while path.isfile(f"{batchFolder}/{batch_name}({batchNum})_settings.txt") is True or path.isfile(f"{batchFolder}/{batch_name}-{batchNum}_settings.txt") is True:
  batchNum += 1

if seed == 'random_seed':
    seed = random.randint(0, 2**32)
else:
  seed = int(seed)

gc.collect()
torch.cuda.empty_cache()
try:    
    do_run()
except KeyboardInterrupt:
    pass
finally:
    print('seed', seed)
    gc.collect()
    torch.cuda.empty_cache()