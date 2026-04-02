# 🌋 Hypertron v1 🌋
# Original file is located at https://colab.research.google.com/drive/10fa8X6EsfZfda1dfhJ_BtfPZ7Te1WGoX

"""
The styles of made-up, not real, artists can be found [here](https://docs.google.com/spreadsheets/d/1nMq-TjBj3t6us-npLRoLFq0VtgpVwdXCKTcQgnxKgTQ/edit?usp=sharing).

Keywords cheatsheet can be found [here](https://imgur.com/a/SnSIQRu) (made by kingdomakrillic).

A short guide to prompt engineering can be found [here](https://docs.google.com/document/d/1qy5fdeThu7pIikulQuWpmKvYBiv9wMshIHcrBr-VldA/edit?usp=sharing).
"""


"""
if imagenet_cin:
  !curl -L -o imagenet_cin.yaml -C - 'https://app.koofr.net/links/90cbd5aa-ef70-4f5e-99bc-f12e5a89380e?path=%2F2021-04-03T19-39-50_cin_transformer%2Fconfigs%2F2021-04-03T19-39-50-project.yaml' #ImageNet (cIN)
  !curl -L -o imagenet_cin.ckpt -C - 'https://app.koofr.net/content/links/90cbd5aa-ef70-4f5e-99bc-f12e5a89380e/files/get/last.ckpt?path=%2F2021-04-03T19-39-50_cin_transformer%2Fcheckpoints%2Flast.ckpt' #ImageNet (cIN)
"""

import os
import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP')
sys.path.append('./taming-transformers')

import os
import argparse
import math
from pathlib import Path
import sys
import pandas as pd
#from IPython import display
from base64 import b64encode
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn
import torch.optim as optim
from torch import optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
#from tqdm.notebook import tqdm
from CLIP import clip
import kornia.augmentation as K
import numpy as np
import subprocess
import imageio
from PIL import ImageFile, Image
ImageFile.LOAD_TRUNCATED_IMAGES = True
import hashlib
from PIL.PngImagePlugin import PngImageFile, PngInfo
import json
#import IPython
#from IPython.display import Markdown, display, Image, clear_output
import urllib.request
import random
from random import randint
import os
import random
import cv2





sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--flavor', type=str, help='Flavor.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 





"""### Download and set things up"""

# Commented out IPython magic to ensure Python compatibility.
#@title <font color="lightgreen" size="+3">←</font> <font size="+2">🎡</font> Installing and initializing libraries **[RUN ME]** <font size="+2">🎡</font>
#@markdown This cell could take a while since it downloads several libraries. Select CLIPIT if you plan to generate pixel art as well or to use CLIPIT. "Video" if you plan on creating a video. Don't download any if you don't **need** them.
#@markdown If you have to restart the notebook and you have already downloaded everything, uncheck `Main_Libraries`.

#@markdown After running this cell, restart the runtime and run it again. Silly Colab. 

#Woohoo, getting technical and looking behind the curtains, huh? Well, I have a little game for you.
#I've hidden Hamilton references all over the place, go find them and if you don't know Hamilton,
#go watch Hamilton and if you don't, that's bad.

Main_Libraries = True #@param {type:"boolean"}
Download_CLIPIT = False #@param {type:"boolean"}
Download_Video = False #@param {type:"boolean"}
Download_Super_Res = False #@param {type:"boolean"}
Download_Super_Slomo = False #!param {type:"boolean"}



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

    input = input.view([n * c, 1, h, w])

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

    input = input.view([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)

def lerp(a, b, f):
    return (a * (1.0 - f)) + (b * f);

class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


replace_grad = ReplaceGrad.apply
#You want to read something spicy? Read The Reynolds Pamphlet and cringe at Hamilton ruining his life.


class ClampWithGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input, min, max):
        ctx.min = min
        ctx.max = max
        ctx.save_for_backward(input)
        return input.clamp(min, max)

    @staticmethod
    def backward(ctx, grad_in):
        input, = ctx.saved_tensors
        return grad_in * (grad_in * (input - input.clamp(ctx.min, ctx.max)) >= 0), None, None


clamp_with_grad = ClampWithGrad.apply


def vector_quantize(x, codebook):
    d = x.pow(2).sum(dim=-1, keepdim=True) + codebook.pow(2).sum(dim=1) - 2 * x @ codebook.T
    indices = d.argmin(-1)
    x_q = F.one_hot(indices, codebook.shape[0]).to(d.dtype) @ codebook
    return replace_grad(x_q, x)


class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))

    def forward(self, input):
        input_normed = F.normalize(input.unsqueeze(1), dim=2)
        embed_normed = F.normalize(self.embed.unsqueeze(0), dim=2)
        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()


#def parse_prompt(prompt):
#    vals = prompt.rsplit(':', 2)
#    vals = vals + ['', '1', '-inf'][len(vals):]
#    return vals[0], float(vals[1]), float(vals[2])

def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 1)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])


class EMATensor(nn.Module):
    """implmeneted by Katherine Crowson"""
    def __init__(self, tensor, decay):
        super().__init__()
        self.tensor = nn.Parameter(tensor)
        self.register_buffer('biased', torch.zeros_like(tensor))
        self.register_buffer('average', torch.zeros_like(tensor))
        self.decay = decay
        self.register_buffer('accum', torch.tensor(1.))
        self.update()
    
    @torch.no_grad()
    def update(self):
        if not self.training:
            raise RuntimeError('update() should only be called during training')

        self.accum *= self.decay
        self.biased.mul_(self.decay)
        self.biased.add_((1 - self.decay) * self.tensor)
        self.average.copy_(self.biased)
        self.average.div_(1 - self.accum)

    def forward(self):
        if self.training:
            return self.tensor
        return self.average


############################################################################################
############################################################################################


class MakeCutoutsCustom(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = nn.Sequential(
          K.RandomHorizontalFlip(p=Random_Horizontal_Flip),
          K.RandomSharpness(Random_Sharpness,p=Random_Sharpness_P),
          K.RandomGaussianBlur((Random_Gaussian_Blur),(Random_Gaussian_Blur_W,Random_Gaussian_Blur_W),p=Random_Gaussian_Blur_P),
          K.RandomGaussianNoise(p=Random_Gaussian_Noise_P),
          K.RandomElasticTransform(kernel_size=(Random_Elastic_Transform_Kernel_Size_W, Random_Elastic_Transform_Kernel_Size_H), sigma=(Random_Elastic_Transform_Sigma), p=Random_Elastic_Transform_P),
          K.RandomAffine(degrees=Random_Affine_Degrees, translate=Random_Affine_Translate, p=Random_Affine_P, padding_mode='border'),
          K.RandomPerspective(Random_Perspective,p=Random_Perspective_P),
          K.ColorJitter(hue=Color_Jitter_Hue, saturation=Color_Jitter_Saturation, p=Color_Jitter_P),)
          #K.RandomErasing((0.1, 0.7), (0.3, 1/0.4), same_on_batch=True, p=0.2),)

    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow
    
    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        noise_fac = 0.1
        
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          randsize = torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound,1.)
          size_mult = randsize ** self.cut_pow
          size = int(min_size_width * (size_mult.clip(lower_bound, 1.))) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        
        
        cutouts = torch.cat(cutouts, dim=0)
        cutouts = clamp_with_grad(cutouts, 0, 1)

        #if args.use_augs:
        cutouts = self.augs(cutouts)
        if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
        return cutouts

class MakeCutoutsCumin(nn.Module):
    #from https://colab.research.google.com/drive/1ZAus_gn2RhTZWzOWUpPERNC0Q8OhZRTZ
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = nn.Sequential(
          #K.RandomHorizontalFlip(p=0.5),
          #K.RandomSharpness(0.3,p=0.4),
          #K.RandomGaussianBlur((3,3),(10.5,10.5),p=0.2),
          #K.RandomGaussianNoise(p=0.5),
          #K.RandomElasticTransform(kernel_size=(33, 33), sigma=(7,7), p=0.2),
          K.RandomAffine(degrees=15, translate=0.1, p=0.7, padding_mode='border'),
          K.RandomPerspective(0.7,p=0.7),
          K.ColorJitter(hue=0.1, saturation=0.1, p=0.7),
          K.RandomErasing((.1, .4), (.3, 1/.3), same_on_batch=True, p=0.7),)
            
    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow
    
    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        noise_fac = 0.1
        
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          randsize = torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound,1.)
          size_mult = randsize ** self.cut_pow
          size = int(min_size_width * (size_mult.clip(lower_bound, 1.))) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        
        
        cutouts = torch.cat(cutouts, dim=0)
        cutouts = clamp_with_grad(cutouts, 0, 1)

        #if args.use_augs:
        cutouts = self.augs(cutouts)
        if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
        return cutouts


class MakeCutoutsHolywater(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = nn.Sequential(
          #K.RandomHorizontalFlip(p=0.5),
          #K.RandomSharpness(0.3,p=0.4),
          #K.RandomGaussianBlur((3,3),(10.5,10.5),p=0.2),
          #K.RandomGaussianNoise(p=0.5),
          #K.RandomElasticTransform(kernel_size=(33, 33), sigma=(7,7), p=0.2),
          K.RandomAffine(degrees=180, translate=0.5, p=0.2, padding_mode='border'),
          K.RandomPerspective(0.6,p=0.9),
          K.ColorJitter(hue=0.03, saturation=0.01, p=0.1),
          K.RandomErasing((.1, .7), (.3, 1/.4), same_on_batch=True, p=0.2),)

    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow
    
    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        noise_fac = 0.1
        
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          randsize = torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound,1.)
          size_mult = randsize ** self.cut_pow
          size = int(min_size_width * (size_mult.clip(lower_bound, 1.))) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        
        
        cutouts = torch.cat(cutouts, dim=0)
        cutouts = clamp_with_grad(cutouts, 0, 1)

        #if args.use_augs:
        cutouts = self.augs(cutouts)
        if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
        return cutouts


class MakeCutoutsGinger(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = augs
        '''
        nn.Sequential(
          K.RandomHorizontalFlip(p=0.5),
          K.RandomSharpness(0.3,p=0.4),
          K.RandomGaussianBlur((3,3),(10.5,10.5),p=0.2),
          K.RandomGaussianNoise(p=0.5),
          K.RandomElasticTransform(kernel_size=(33, 33), sigma=(7,7), p=0.2),
          K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
          K.RandomPerspective(0.2,p=0.4, ),
          K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),)
'''

    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        noise_fac = 0.1
        
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          randsize = torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound,1.)
          size_mult = randsize ** self.cut_pow
          size = int(min_size_width * (size_mult.clip(lower_bound, 1.))) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        
        
        cutouts = torch.cat(cutouts, dim=0)
        cutouts = clamp_with_grad(cutouts, 0, 1)

        #if args.use_augs:
        cutouts = self.augs(cutouts)
        if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
        return cutouts

class MakeCutoutsZynth(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = nn.Sequential(
        K.RandomHorizontalFlip(p=0.5),
        # K.RandomSolarize(0.01, 0.01, p=0.7),
        K.RandomSharpness(0.3,p=0.4),
        K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
        K.RandomPerspective(0.2,p=0.4),
        K.ColorJitter(hue=0.01, saturation=0.01, p=0.7))


    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        noise_fac = 0.1
        
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          randsize = torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound,1.)
          size_mult = randsize ** self.cut_pow
          size = int(min_size_width * (size_mult.clip(lower_bound, 1.))) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        
        
        cutouts = torch.cat(cutouts, dim=0)
        cutouts = clamp_with_grad(cutouts, 0, 1)

        #if args.use_augs:
        cutouts = self.augs(cutouts)
        if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
        return cutouts

class MakeCutoutsWyvern(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow, augs):
        super().__init__()
        self.cut_size = cut_size
        #tqdm.write(f'cut size: {self.cut_size}')
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.noise_fac = 0.1
        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))
        self.augs = augs

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
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        return clamp_with_grad(torch.cat(cutouts, dim=0), 0, 1)

def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = vqgan.VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.eval().requires_grad_(False)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    elif config.model.target == 'taming.models.vqgan.GumbelVQ':
        model = vqgan.GumbelVQ(**config.model.params)
        #print(config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model

def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, PIL.Image.LANCZOS)

BUF_SIZE = 65536
def get_digest(path, alg=hashlib.sha256):
  hash = alg()
  print(path)
  with open(path, 'rb') as fp:
    while True:
      data = fp.read(BUF_SIZE)
      if not data: break
      hash.update(data)
  return b64encode(hash.digest()).decode('utf-8')

flavordict = {
    "cumin": MakeCutoutsCumin,
    "holywater": MakeCutoutsHolywater,
    "ginger": MakeCutoutsGinger,
    "zynth": MakeCutoutsZynth,
    "wyvern": MakeCutoutsWyvern,
}

@torch.jit.script
def gelu_impl(x):
    """OpenAI's gelu implementation."""
    return 0.5 * x * (1.0 + torch.tanh(0.7978845608028654 * x * (1.0 + 0.044715 * x * x)))


def gelu(x):
    return gelu_impl(x)


class ModelHost:
  def __init__(self, args):
    self.args = args
    self.model, self.perceptor = None, None
    self.make_cutouts = None
    self.alt_make_cutouts = None
    self.imageSize = None
    self.prompts = None
    self.opt = None
    self.normalize = None
    self.z, self.z_orig, self.z_min, self.z_max = None, None, None, None
    self.metadata = None
    self.mse_weight = 0
    self.normal_flip_optim = None
    self.usealtprompts = False

  def setup_metadata(self, seed):
    metadata = {k:v for k,v in vars(self.args).items()}
    del metadata['max_iterations']
    del metadata['display_freq']
    metadata['seed'] = seed
    if (metadata['init_image']):
      path = metadata['init_image']
      digest = get_digest(path)
      metadata['init_image'] = (path, digest)
    if (metadata['image_prompts']):
      prompts = []
      for prompt in metadata['image_prompts']:
        path = prompt
        digest = get_digest(path)
        prompts.append((path,digest))
      metadata['image_prompts'] = prompts
    self.metadata = metadata

  def setup_model(self, x):
    i = x
    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
    print('Using device:', device)
    print(torch.cuda.get_device_properties(device))

    sys.stdout.write("Loading VQGAN model "+args.vqgan_model+" ...\n")
    sys.stdout.flush()

    model = load_vqgan_model(f'{args.vqgan_model}.yaml', f'{args.vqgan_model}.ckpt').to(device)
    
    sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
    sys.stdout.flush()

    #[0].eval().requires_grad_(False)
    perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
    #[0].eval().requires_grad_(True)

    cut_size = perceptor.visual.input_resolution
    
    if self.args.is_gumbel:
      e_dim = model.quantize.embedding_dim
    else:
      e_dim = model.quantize.e_dim
        
    f = 2**(model.decoder.num_resolutions - 1)
   
    make_cutouts = flavordict[flavor](cut_size, args.mse_cutn, cut_pow=args.mse_cut_pow,augs=args.augs)

    #make_cutouts = MakeCutouts(cut_size, args.mse_cutn, cut_pow=args.mse_cut_pow,augs=args.augs)
    if args.altprompts:
        self.usealtprompts = True
        self.alt_make_cutouts = flavordict[flavor](cut_size, args.mse_cutn, cut_pow=args.alt_mse_cut_pow,augs=args.altaugs)
        #self.alt_make_cutouts = MakeCutouts(cut_size, args.mse_cutn, cut_pow=args.alt_mse_cut_pow,augs=args.altaugs)
    
    if self.args.is_gumbel:
      n_toks = model.quantize.n_embed
    else:
      n_toks = model.quantize.n_e

    toksX, toksY = args.size[0] // f, args.size[1] // f
    sideX, sideY = toksX * f, toksY * f

    if self.args.is_gumbel:
        z_min = model.quantize.embed.weight.min(dim=0).values[None, :, None, None]
        z_max = model.quantize.embed.weight.max(dim=0).values[None, :, None, None]
    else:
        z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
        z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]
    
    from PIL import Image
    import cv2
#-------
    working_dir = self.args.folder_name
    
    if self.args.init_image != "":
        img_0 = cv2.imread(init_image)
        z, *_ = model.encode(TF.to_tensor(img_0).to(device).unsqueeze(0) * 2 - 1)
    elif not os.path.isfile(f'{working_dir}/steps/{i:04d}.png'):
        one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
        if self.args.is_gumbel:
            z = one_hot @ model.quantize.embed.weight
        else:
            z = one_hot @ model.quantize.embedding.weight
        z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)
    else:
        if save_all_iterations:
            img_0 = cv2.imread(
                f'{working_dir}/steps/{i:04d}_{iterations_per_frame}.png')
        else:
            # Hack to prevent colour inversion on every frame
            img_temp = cv2.imread(f'{working_dir}/steps/{i}.png')
            imageio.imwrite('inverted_temp.png', img_temp)
            img_0 = cv2.imread('inverted_temp.png')
        center = (1*img_0.shape[1]//2, 1*img_0.shape[0]//2)
        trans_mat = np.float32(
            [[1, 0, translation_x],
            [0, 1, translation_y]]
        )
        rot_mat = cv2.getRotationMatrix2D( center, angle, zoom )

        trans_mat = np.vstack([trans_mat, [0,0,1]])
        rot_mat = np.vstack([rot_mat, [0,0,1]])
        transformation_matrix = np.matmul(rot_mat, trans_mat)

        img_0 = cv2.warpPerspective(
            img_0,
            transformation_matrix,
            (img_0.shape[1], img_0.shape[0]),
            borderMode=cv2.BORDER_WRAP
        )
        z, *_ = model.encode(TF.to_tensor(img_0).to(device).unsqueeze(0) * 2 - 1)
        
        def save_output(i, img, suffix='zoomed'):
          filename = \
              f"{working_dir}/steps/{i:04}{'_' + suffix if suffix else ''}.png"
          imageio.imwrite(filename, np.array(img))

        save_output(i, img_0)
#-------
    if args.init_image:
        pil_image = Image.open(args.init_image).convert('RGB')
        pil_image = pil_image.resize((sideX, sideY), Image.LANCZOS)
        z, *_ = model.encode(TF.to_tensor(pil_image).to(device).unsqueeze(0) * 2 - 1)
    else:
        one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
        if self.args.is_gumbel:
          z = one_hot @ model.quantize.embed.weight
        else:
          z = one_hot @ model.quantize.embedding.weight
        z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)
    z = EMATensor(z, args.ema_val)
    
    if args.mse_with_zeros and not args.init_image:
        z_orig = torch.zeros_like(z.tensor)
    else:
        z_orig = z.tensor.clone()
    z.requires_grad_(True)
    #opt = optim.AdamW(z.parameters(), lr=args.mse_step_size, weight_decay=0.00000000)
    if self.normal_flip_optim == True:
      if randint(1,2) == 1:
        opt = torch.optim.AdamW(z.parameters(), lr=args.step_size, weight_decay=0.00000000)
        print(f"Using AdamW")
        #opt = Ranger21(z.parameters(), lr=args.step_size, weight_decay=0.00000000)
        #print(f"Using Ranger21")
      else:
        opt = optim.DiffGrad(z.parameters(), lr=args.step_size, weight_decay=0.00000000)
        print(f"Using DiffGrad")
    else:
      opt = torch.optim.AdamW(z.parameters(), lr=args.step_size, weight_decay=0.00000000)

    self.cur_step_size =args.mse_step_size

    normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                    std=[0.26862954, 0.26130258, 0.27577711])

    pMs = []
    altpMs = []

    for prompt in args.prompts:
        txt, weight, stop = parse_prompt(prompt)
        embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
        pMs.append(Prompt(embed, weight, stop).to(device))
    
    for prompt in args.altprompts:
        txt, weight, stop = parse_prompt(prompt)
        embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
        altpMs.append(Prompt(embed, weight, stop).to(device))
    
    from PIL import Image
    #Being obsessed with your legacy is kind of stupid to be honest.
    for prompt in args.image_prompts:
        path, weight, stop = parse_prompt(prompt)
        img = resize_image(Image.open(path).convert('RGB'), (sideX, sideY))
        batch = make_cutouts(TF.to_tensor(img).unsqueeze(0).to(device))
        embed = perceptor.encode_image(normalize(batch)).float()
        pMs.append(Prompt(embed, weight, stop).to(device))

    for seed, weight in zip(args.noise_prompt_seeds, args.noise_prompt_weights):
        gen = torch.Generator().manual_seed(seed)
        embed = torch.empty([1, perceptor.visual.output_dim]).normal_(generator=gen)
        pMs.append(Prompt(embed, weight).to(device))
        if(self.usealtprompts):
          altpMs.append(Prompt(embed, weight).to(device))

    self.model, self.perceptor = model, perceptor
    self.make_cutouts = make_cutouts
    self.imageSize = (sideX, sideY)
    self.prompts = pMs
    self.altprompts = altpMs
    self.opt = opt
    self.normalize = normalize
    self.z, self.z_orig, self.z_min, self.z_max = z, z_orig, z_min, z_max
    self.setup_metadata(args2.seed)
    self.mse_weight = self.args.init_weight

  def synth(self, z):
      if self.args.is_gumbel:
          z_q = vector_quantize(z.movedim(1, 3), self.model.quantize.embed.weight).movedim(3, 1)
      else:
          z_q = vector_quantize(z.movedim(1, 3), self.model.quantize.embedding.weight).movedim(3, 1)
      return clamp_with_grad(self.model.decode(z_q).add(1).div(2), 0, 1)

  def add_metadata(self, path, i):
    imfile = PngImageFile(path)
    meta = PngInfo()
    step_meta = {'iterations':i}
    step_meta.update(self.metadata)
    #meta.add_itxt('vqgan-params', json.dumps(step_meta), zip=True)
    imfile.save(path, pnginfo=meta)
    #Hey you. This one's for Glooperpogger#7353 on Discord (Gloop has a gun), they are a nice snek

  @torch.no_grad()
  def checkin(self, i, losses, x):
      losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
      """
      if i < args.mse_end:
        tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
      else:
        tqdm.write(f'i: {i-args.mse_end} ({i}), loss: {sum(losses).item():g}, losses: {losses_str}')
      tqdm.write(f'cutn: {self.make_cutouts.cutn}, cut_pow: {self.make_cutouts.cut_pow}, step_size: {self.cur_step_size}')
      """
      out = self.synth(self.z.average)
      #if i == self.args.max_iterations:
      sys.stdout.flush()
      sys.stdout.write("Saving progress ...\n")
      sys.stdout.flush()

      batchpath = "./"
      TF.to_pil_image(out[0].cpu()).save(args2.image_file)
      if args2.frame_dir is not None:
          import os
          file_list = []
          for file in os.listdir(args2.frame_dir):
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
          save_name = args2.frame_dir+"\FRA"+count_string+".png"
          TF.to_pil_image(out[0].cpu()).save(save_name)
      

      sys.stdout.flush()
      sys.stdout.write("Progress saved\n")
      sys.stdout.flush()

  def unique_index(self, batchpath):
      i = 0
      while i < 10000:
          if os.path.isfile(batchpath+"/"+str(i)+".png"):
              i = i+1
          else:
              return batchpath+"/"+str(i)+".png"

  def ascend_txt(self, i):
      out = self.synth(self.z.tensor)
      iii = self.perceptor.encode_image(self.normalize(self.make_cutouts(out))).float()
      

      result = []
      if self.args.init_weight and self.mse_weight > 0:
          result.append(F.mse_loss(self.z.tensor, self.z_orig) * self.mse_weight / 2)

      for prompt in self.prompts:
          result.append(prompt(iii))
          
      if self.usealtprompts:
        iii = self.perceptor.encode_image(self.normalize(self.alt_make_cutouts(out))).float()
        for prompt in self.altprompts:
          result.append(prompt(iii))
      
      img = np.array(out.mul(255).clamp(0, 255)[0].cpu().detach().numpy().astype(np.uint8))[:,:,:]
      img = np.transpose(img, (1, 2, 0))
      im_path = 'Progress.png'
      imageio.imwrite(im_path, np.array(img))
      self.add_metadata(im_path, i)
      return result

  def train(self, i,x):
      self.opt.zero_grad()
      mse_decay = self.args.mse_decay
      mse_decay_rate = self.args.mse_decay_rate
      lossAll = self.ascend_txt(i)

      sys.stdout.write("Iteration {}".format(i)+"\n")
      sys.stdout.flush()
    
      """
      if i < args.mse_end and i % args.mse_display_freq == 0:
        self.checkin(i, lossAll, x)
      if i == args.mse_end:
        self.checkin(i,lossAll,x)
      if i > args.mse_end and (i-args.mse_end) % args.display_freq == 0:
        self.checkin(i, lossAll, x)
      """
      if i % args2.update == 0:
        self.checkin(i, lossAll, x)
      
      loss = sum(lossAll)
      loss.backward()
      self.opt.step()
      with torch.no_grad():
          if self.mse_weight > 0 and self.args.init_weight and i > 0 and i%mse_decay_rate == 0:
              if self.args.is_gumbel:
                self.z_orig = vector_quantize(self.z.average.movedim(1, 3), self.model.quantize.embed.weight).movedim(3, 1)
              else:
                self.z_orig = vector_quantize(self.z.average.movedim(1, 3), self.model.quantize.embedding.weight).movedim(3, 1)
              if self.mse_weight - mse_decay > 0:
                  self.mse_weight = self.mse_weight - mse_decay
                  print(f"updated mse weight: {self.mse_weight}")
              else:
                  self.mse_weight = 0
                  self.make_cutouts = flavordict[flavor](self.perceptor.visual.input_resolution, args.cutn, cut_pow=args.cut_pow, augs = args.augs)
                  if self.usealtprompts:
                      self.alt_make_cutouts = flavordict[flavor](self.perceptor.visual.input_resolution, args.cutn, cut_pow=args.alt_cut_pow, augs = args.altaugs)
                  self.z = EMATensor(self.z.average, args.ema_val)
                  self.new_step_size =args.step_size
                  self.opt = optim.Adagrad(self.z.parameters(), lr=args.step_size, weight_decay=0.00000000)
                  print(f"updated mse weight: {self.mse_weight}")
          if i > args.mse_end:
              if args.step_size != args.final_step_size and args.max_iterations > 0:
                progress = (i-args.mse_end)/(args.max_iterations)
                self.cur_step_size = lerp(step_size, final_step_size,progress)
                for g in self.opt.param_groups:
                  g['lr'] = self.cur_step_size
          #self.z.copy_(self.z.maximum(self.z_min).minimum(self.z_max))

  def run(self,x):
    itt = 1
    try:
        #pbar = range(int(args.max_iterations + args.mse_end))
        for i in range(args2.iterations):
          self.train(itt,x)
          
          if i > 0 and i%args.mse_decay_rate==0 and self.mse_weight > 0:
            self.z = EMATensor(self.z.average, args.ema_val)
            self.opt = torch.optim.Adagrad(self.z.parameters(), lr=args.mse_step_size, weight_decay=0.00000000)
            #self.opt = optim.Adgarad(self.z.parameters(), lr=args.mse_step_size, weight_decay=0.00000000)
          """
          if i >= args.max_iterations + args.mse_end:
            pbar.close()
            break
          """
          self.z.update()
          itt += 1
          #pbar.update()
    except KeyboardInterrupt:
        pass
    return i

def add_noise(img):

	# Getting the dimensions of the image
	row , col = img.shape
	
	# Randomly pick some pixels in the
	# image for coloring them white
	# Pick a random number between 300 and 10000
	number_of_pixels = random.randint(300, 10000)
	for i in range(number_of_pixels):
		
		# Pick a random y coordinate
		y_coord=random.randint(0, row - 1)
		
		# Pick a random x coordinate
		x_coord=random.randint(0, col - 1)
		
		# Color that pixel to white
		img[y_coord][x_coord] = 255
		
	# Randomly pick some pixels in
	# the image for coloring them black
	# Pick a random number between 300 and 10000
	number_of_pixels = random.randint(300 , 10000)
	for i in range(number_of_pixels):
		
		# Pick a random y coordinate
		y_coord=random.randint(0, row - 1)
		
		# Pick a random x coordinate
		x_coord=random.randint(0, col - 1)
		
		# Color that pixel to black
		img[y_coord][x_coord] = 0
		
	return img

#@markdown >`prompts` is the list of prompts to give to the AI, separated by `|`. With more than one, it will attempt to mix them together. You can add weights to different parts of the prompt by adding a `p:x` at the end of a prompt (before a `|`) where `p` is the prompt and `x` is the weight.
prompts = args2.prompt #"A fantasy landscape, by Greg Rutkowski. A lush mountain.:10 | Trending on ArtStation, unreal engine.: 4K HD, realism.:6.3" #@param {type:"string"}
width =  args2.sizex #480#@param {type:"number"}
height = args2.sizey #336 #@param {type:"number"}
model = "ImageNet 16384" #@param ['ImageNet 16384', 'ImageNet 1024', "Gumbel 8192", "Sber Gumbel", "imagenet_cin", 'WikiArt 1024', 'WikiArt 16384', 'COCO-Stuff', 'FacesHQ', 'S-FLCKR']

if model == "Gumbel 8192":
  is_gumbel = True
elif model == "Sber Gumbel":
  is_gumbel = True
else:
  is_gumbel = False

##@markdown The flavor effects the output greatly. Each has it's own characteristics and depending on what you choose, you'll get a widely different result with the same prompt and seed. Ginger is the default, nothing special. Cumin results more of a painting, while Holywater makes everythng super funky and/or colorful. Custom is a custom flavor, use the utilities above.
flavor = args2.flavor #'holywater' #@param ["ginger", "cumin", "holywater", "zynth", "wyvern", "custom"]
template = 'Balanced' #@param ["none", "Balanced", "Better - Fast", "Better - Slow", "Detailed", "Consistent Creativity", "Realistic", "Smooth", "Subtle MSE", "Hyper Fast Results", "Pixelart", "Movie Poster", "flag", "planet", "creature", "human", "Size: Square", "Size: Landscape", "Size: Poster", "Negative Prompt"]
##@markdown To use initial or target images, upload it on the left in the file browser. You can also use previous outputs by putting its path below, e.g. `batch_01/0.png`. If your previous output is saved to drive, you can use the checkbox so you don't have to type the whole path.
init = 'default noise' #@param ["default noise", "image", "random image", "salt and pepper noise", "salt and pepper noise on init image"]

if args2.seed_image == None:
    init_image = ""#@param {type:"string"}
else:
    init_image = str(args2.seed_image)

if init == "random image":
  url = "https://picsum.photos/" + str(width) + "/" + str(height) + "?blur=" + str(random.randrange(5, 10))
  urllib.request.urlretrieve(url, "Init_Img/Image.png")
  init_image = "Init_Img/Image.png"
elif init == "random image clear":
  url = "https://source.unsplash.com/random/" + str(width) + "x" + str(height)
  urllib.request.urlretrieve(url, "Init_Img/Image.png")
  init_image = "Init_Img/Image.png"
elif init == "random image clear 2":
  url = "https://loremflickr.com/" + str(width) + "/" + str(height)
  urllib.request.urlretrieve(url, "Init_Img/Image.png")
  init_image = "Init_Img/Image.png"
elif init == "salt and pepper noise":
  urllib.request.urlretrieve("https://i.stack.imgur.com/olrL8.png", "Init_Img/Image.png")
  import cv2
  img = cv2.imread('Init_Img/Image.png', 0)
  cv2.imwrite('Init_Img/Image.png', add_noise(img))
  init_image = "Init_Img/Image.png"
elif init == "salt and pepper noise on init image":
  img = cv2.imread(init_image, 0)
  cv2.imwrite('Init_Img/Image.png', add_noise(img))
  init_image = "Init_Img/Image.png"
elif init == "perlin noise":
  #For some reason Colab started crashing from this
  import noise
  import numpy as np
  from PIL import Image
  shape = (width, height)
  scale = 100
  octaves = 6
  persistence = 0.5
  lacunarity = 2.0
  seed = np.random.randint(0,100000)
  world = np.zeros(shape)
  for i in range(shape[0]):
      for j in range(shape[1]):
          world[i][j] = noise.pnoise2(i/scale, j/scale, octaves=octaves, persistence=persistence, lacunarity=lacunarity, repeatx=1024, repeaty=1024, base=seed)
  Image.fromarray(prep_world(world)).convert("L").save("Init_Img/Image.png")
  init_image = "Init_Img/Image.png"
elif init == "black and white":
  url = "https://www.random.org/bitmaps/?format=png&width=300&height=300&zoom=1"
  urllib.request.urlretrieve(url, "Init_Img/Image.png")
  init_image = "Init_Img/Image.png"



seed = -1#@param {type:"number"}
transparent_png = False #@param {type:"boolean"}
##@markdown Only the **prompts**, **width**, **height** and **model** work on pixel art.
use_CLIPIT = False #@param {type:"boolean"}
Pixel_Art = False #@param {type:"boolean"}

#@markdown <font size="+3">⚠</font> **ADVANCED SETTINGS** <font size="+3">⚠</font>
#@markdown ---
#@markdown ---

#@markdown >`folder_name` is the name of the folder you want to output your result(s) to. Previous outputs will NOT be overwritten. By default, it will be saved to the colab's root folder, but the `save_to_drive` checkbox will save it to `MyDrive\VQGAN_Output` instead.
folder_name = "Output"#@param {type:"string"}
save_to_drive = False #@param {type:"boolean"}

clip_model = args2.clip_model #"ViT-B/32" #@param ["ViT-B/32", "ViT-B/16", "RN50x16", "RN50x4", "RN101", "RN50"]

#@markdown >Target images work like prompts, write the name of the image. You can add multiple target images by seperating them with a `|`.
target_images = ""#@param {type:"string"}

#@markdown ><font size="+2">☢</font> Advanced values. Values of cut_pow below 1 prioritize structure over detail, and vice versa for above 1. Step_size affects how wild the change between iterations is, and if final_step_size is not 0, step_size will interpolate towards it over time.
#@markdown >Cutn affects on 'Creativity': less cutout will lead to more random/creative results, sometimes barely readable, while higher values (90+) lead to very stable, photo-like outputs
cutn =  130#@param {type:"number"}
cut_pow = 1#@param {type:"number"}
#@markdown >Step_size is like weirdness. Lower: more accurate/realistic, slower; Higher: less accurate/more funky, faster.
step_size = 0.12#@param {type:"number"}
final_step_size = 0#@param {type:"number"} 
if final_step_size <= 0: final_step_size = step_size

#@markdown ---

#@markdown >EMA maintains a moving average of trained parameters. The number below is the rate of decay (higher means slower).
ema_val =  0.98#@param {type:"number"}

init_image_in_drive = False #@param {type:"boolean"}
if init_image_in_drive and init_image:
    init_image = '/content/drive/MyDrive/VQGAN_Output/' + init_image

images_interval =  args2.update#@param {type:"number"}

#I think you should give "Free Thoughts on the Proceedings of the Continental Congress" a read, really funny and actually well-written, Hamilton presented it in a bad light IMO.

#@markdown >iterations excludes iterations spent during the mse phase, if it is being used. The total iterations will be more if `mse_decay_rate` is more than 0.
iterations = args2.iterations#@param {type:"number"}
batch_size =  1#@param {type:"number"}

#@markdown ---

#@markdown <font size="+1">🔮</font> MSE Regulization. <font size="+1">🔮</font>
#Based off of this notebook: https://colab.research.google.com/drive/1gFn9u3oPOgsNzJWEFmdK-N9h_y65b8fj?usp=sharing - already in credits
use_mse = True #@param {type:"boolean"}
mse_images_interval = images_interval
mse_init_weight =  0.2#@param {type:"number"}
mse_decay_rate =  110#@param {type:"number"}
mse_epoches = iterations
##@param {type:"number"}

#@markdown >Overwrites the usual values during the mse phase if included. If any value is 0, its normal counterpart is used instead.
mse_with_zeros = True #@param {type:"boolean"}
mse_step_size = 0.87 #@param {type:"number"}
mse_cutn =  42#@param {type:"number"}
mse_cut_pow = 0.75 #@param {type:"number"}

#@markdown >normal_flip_optim flips between two optimizers during the normal (not MSE) phase. It can improve quality, but it's kind of experimental, use at your own risk.
normal_flip_optim = True #@param {type:"boolean"}
#@markdown ---

#@markdown >`altprompts` is a set of prompts that take in a different augmentation pipeline, and can have their own cut_pow. At the moment, the default "alt augment" settings flip the picture cutouts upside down before evaluating. This can be good for optical illusion images. If either cut_pow value is 0, it will use the same value as the normal prompts.
altprompts = "" #@param {type:"string"}
alt_cut_pow = 0 #@param {type:"number"}
alt_mse_cut_pow = 0 #@param {type:"number"}
#altprompt_type = "upside-down" #@param ['upside-down', 'as']

#@markdown ---

#@markdown # <font size="+3">➰</font> **CLIPIT** <font size="+3">➰</font>

#@markdown ---

use_zoom = False #@param {type:"boolean"}
key_frames = False #@param {type:"boolean"}
text_prompts = "10:(Apple: 1| Orange: 0), 20: (Apple: 0| Orange: 1| Peach: 1)" #@param {type:"string"}
interval =  1#@param {type:"number"}
max_frames = 50#@param {type:"number"}
angle = "10: (0), 30: (10), 50: (0)"#@param {type:"string"}
zoom = "10: (1), 30: (1.2), 50: (1)"#@param {type:"string"}
translation_x = "0: (0)"#@param {type:"string"}
translation_y = "0: (0)"#@param {type:"string"}
iterations_per_frame = "0: (10)"#@param {type:"string"}
save_all_iterations = False#@param {type:"boolean"}

#@markdown ---
#@markdown On an unrelated note, if you get any errors while running this, restart the runtime and run the first cell again. If that doesn't work either, message me on Discord (Philipuss#4066).

model_names={'ImageNet 16384': 'vqgan_imagenet_f16_16384', 'ImageNet 1024': 'vqgan_imagenet_f16_1024', "Gumbel 8192": "gumbel_8192", "Sber Gumbel": "sber_gumbel", 'imagenet_cin': 'imagenet_cin', 'WikiArt 1024': 'wikiart_1024', 'WikiArt 16384': 'wikiart_16384', 'COCO-Stuff': 'coco', 'FacesHQ': 'faceshq', 'S-FLCKR': 'sflckr'}


if use_CLIPIT==False and use_zoom==False:
  mse_decay = 0

  if use_mse == False:
      mse_init_weight = 0.
  else:
      mse_decay = mse_init_weight / mse_epoches
    
  if os.path.isdir('/content/drive') == False:
      if save_to_drive == True or init_image_in_drive == True:
          drive.mount('/content/drive')

  if seed == -1:
      seed = None
  if init_image == "None":
      init_image = None
  if target_images == "None" or not target_images:
      target_images = []
  else:
      target_images = target_images.split("|")
      target_images = [image.strip() for image in target_images]

  prompts = [phrase.strip() for phrase in prompts.split("|")]
  if prompts == ['']:
      prompts = []

  altprompts = [phrase.strip() for phrase in altprompts.split("|")]
  if altprompts == ['']:
      altprompts = []

  if mse_images_interval == 0: mse_images_interval = images_interval
  if mse_step_size == 0: mse_step_size = step_size
  if mse_cutn == 0: mse_cutn = cutn
  if mse_cut_pow == 0: mse_cut_pow = cut_pow
  if alt_cut_pow == 0: alt_cut_pow = cut_pow
  if alt_mse_cut_pow == 0: alt_mse_cut_pow = mse_cut_pow

  augs = nn.Sequential(
            K.RandomHorizontalFlip(p=0.5),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomGaussianBlur((3,3),(4.5,4.5),p=0.3),
            #K.RandomGaussianNoise(p=0.5),
            #K.RandomElasticTransform(kernel_size=(33, 33), sigma=(7,7), p=0.2),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
            K.RandomPerspective(0.2,p=0.4, ),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),)

  altaugs = nn.Sequential(
            K.RandomHorizontalFlip(p=0.5),
            #K.RandomRotation(degrees=90.0),
            K.RandomVerticalFlip(p=1),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomGaussianBlur((3,3),(4.5,4.5),p=0.3),
            #K.RandomGaussianNoise(p=0.5),
            #K.RandomElasticTransform(kernel_size=(33, 33), sigma=(7,7), p=0.2),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
            K.RandomPerspective(0.2,p=0.4, ),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),)

  args = argparse.Namespace(
      prompts=prompts,
      altprompts=altprompts,
      image_prompts=target_images,
      noise_prompt_seeds=[],
      noise_prompt_weights=[],
      size=[width, height],
      init_image=init_image,
      png=transparent_png,
      init_weight= mse_init_weight,
      clip_model=clip_model,
      #vqgan_model=model_names[model],
      vqgan_model=args2.vqgan_model,
      step_size=step_size,
      final_step_size = final_step_size,
      cutn=cutn,
      cut_pow=cut_pow,
      mse_cutn = mse_cutn,
      mse_cut_pow = mse_cut_pow,
      mse_step_size = mse_step_size,
      display_freq=images_interval,
      mse_display_freq = mse_images_interval,
      max_iterations=iterations,
      mse_end = mse_decay_rate * mse_epoches,
      seed=seed,
      folder_name=folder_name,
      save_to_drive=save_to_drive,
      mse_decay_rate = mse_decay_rate,
      mse_decay = mse_decay,
      mse_with_zeros = mse_with_zeros,
      normal_flip_optim = normal_flip_optim,
      ema_val = ema_val,
      augs = augs,
      altaugs = altaugs,
      alt_cut_pow = alt_cut_pow,
      alt_mse_cut_pow = alt_mse_cut_pow,
      is_gumbel = is_gumbel,
  )


  mh = ModelHost(args)
  x= 0

  #sys.stdout.write(f'Image size is {width} by {height}\n')
  sys.stdout.write("Starting ...\n")
  sys.stdout.flush()

  for x in range(batch_size):
      mh.setup_model(x)
      last_iter = mh.run(x)
      x=x+1
