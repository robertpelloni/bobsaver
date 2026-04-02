# V-Majesty Diffusion
# Original file is located at https://colab.research.google.com/github/multimodalart/MajestyDiffusion/blob/main/v.ipynb

# git clone https://github.com/apolinario/Multi-Modal-Comparators --branch windows-hack

"""
# required models
!wget -O $model_path/secondary_model_imagenet_2.pth https://the-eye.eu/public/AI/models/v-diffusion/secondary_model_imagenet_2.pth
!wget -O $model_path/ava_vit_l_14_336_linear.pth https://multimodal.art/models/ava_vit_l_14_336_linear.pth
!wget -O $model_path/sa_0_4_vit_l_14_linear.pth https://multimodal.art/models/sa_0_4_vit_l_14_linear.pth
!wget -O $model_path/ava_vit_l_14_linear.pth https://multimodal.art/models/ava_vit_l_14_linear.pth
!wget -O $model_path/ava_vit_b_16_linear.pth http://batbot.tv/ai/models/v-diffusion/ava_vit_b_16_linear.pth
!wget -O $model_path/sa_0_4_vit_b_32_linear.pth https://multimodal.art/models/sa_0_4_vit_b_32_linear.pth
!wget -O $model_path/openimages_512x_png_embed224.npz https://github.com/nshepperd/jax-guided-diffusion/raw/8437b4d390fcc6b57b89cedcbaf1629993c09d03/data/openimages_512x_png_embed224.npz
!wget -O $model_path/imagenet_512x_jpg_embed224.npz https://github.com/nshepperd/jax-guided-diffusion/raw/8437b4d390fcc6b57b89cedcbaf1629993c09d03/data/imagenet_512x_jpg_embed224.npz
!wget -O $model_path/cc12m_1_cfg.pth https://the-eye.eu/public/AI/models/v-diffusion/cc12m_1_cfg.pth
!wget -O $model_path/cc12m_1.pth https://the-eye.eu/public/AI/models/v-diffusion/cc12m_1.pth
!wget -O $model_path/yfcc_2.pth https://the-eye.eu/public/AI/models/v-diffusion/yfcc_2.pth
!wget -O $model_path/openimages.pth https://set.zlkj.in/models/diffusion/512x512_diffusion_uncond_openimages_epoch28_withfilter.pt
!wget -O $model_path/wikiart_256.pth https://the-eye.eu/public/AI/models/v-diffusion/wikiart_256.pth
!wget -O $model_path/nshep_danbooru.pth https://set.zlkj.in/models/diffusion/danbooru/cc12m-danbooru-adam-lr5-1645.pt
!wget -O $model_path/danbooru_128.pth https://the-eye.eu/public/AI/models/v-diffusion/danbooru_128.pth
"""

save_outputs_to_google_drive = False
save_models_to_google_drive = False

model_path = "./"
outputs_path = "./"

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

sys.path.append('./guided-diffusion')
sys.path.append('./Multi-Modal-Comparators')
sys.path.append('.')
sys.path.append('v-diffusion-pytorch')
sys.path.append('./ResizeRight/')

from subprocess import Popen, PIPE
import mmc
import mmc.loaders
import os
from dataclasses import dataclass
from functools import partial
import gc
import io
import math
import sys
import random
import numpy as np
from piq import brisque
from itertools import product
import lpips
from PIL import Image, ImageOps
import requests
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision import transforms as T
from torchvision.transforms import functional as TF
#from tqdm.auto import tqdm
from numpy import nan
from fairscale.nn.checkpoint import checkpoint_wrapper
from resize_right import resize
import clip
from diffusion import sampling, get_model, get_models, utils
from pytorch_lit import LitModule
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
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')

  parser.add_argument('--imagenet_openimages', type=int)
  parser.add_argument('--yfcc_2', type=int)
  #parser.add_argument('--cc12m_1_cfg', type=int)
  parser.add_argument('--cc12m_1', type=int)
  parser.add_argument('--wikiart_256', type=int)
  parser.add_argument('--nshep_danbooru', type=int)
  parser.add_argument('--danbooru_128', type=int)
  
  parser.add_argument('--ViT_B32', type=int)
  parser.add_argument('--ViT_B16', type=int)
  parser.add_argument('--ViT_L14', type=int)
  parser.add_argument('--ViT_L14_336px', type=int)
  parser.add_argument('--RN50x4', type=int)
  parser.add_argument('--RN50x16', type=int)
  parser.add_argument('--RN50x64', type=int)
  parser.add_argument('--ViT_B16_plus', type=int)
  parser.add_argument('--ViT_B32_laion2b', type=int)
  parser.add_argument('--cloob_ViT_B16', type=int)
  parser.add_argument('--model1', type=str)
  parser.add_argument('--model2', type=str)
  parser.add_argument('--model3', type=str)

  parser.add_argument('--RGB_min', type=float)
  parser.add_argument('--RGB_max', type=float)
  parser.add_argument('--cutn_batches', type=int)
  parser.add_argument('--unified_cutouts', type=int)
  parser.add_argument('--ns_cutn', type=int)
  parser.add_argument('--schedule_clip_guidance', type=int)
  parser.add_argument('--flip_aug', type=int)
  parser.add_argument('--cut_ic_pow', type=float)
  parser.add_argument('--step_enhance', type=int)
  parser.add_argument('--mid_point', type=float)
  parser.add_argument('--steps_pow', type=float)
  parser.add_argument('--cfg_scale', type=float)
  parser.add_argument('--symmetric_loss_scale', type=float)
  parser.add_argument('--grad_center', type=int)
  parser.add_argument('--mag_mul', type=float)
  parser.add_argument('--clamp_start', type=int)
  parser.add_argument('--experimental_aesthetic_embeddings', type=int)
  parser.add_argument('--experimental_aesthetic_embeddings_weight', type=float)
  parser.add_argument('--experimental_aesthetic_embeddings_score', type=int)
  parser.add_argument('--image_prompts', type=str)
  parser.add_argument('--clip_guidance_scale', type=int)
  parser.add_argument('--aesthetic_loss_scale', type=int)
  parser.add_argument('--augment_cuts', type=int)
  parser.add_argument('--use_secondary_model', type=int)
  parser.add_argument('--init_image', type=str)
  parser.add_argument('--init_mask', type=str)
  parser.add_argument('--mask_scale', type=int)
  parser.add_argument('--init_scale', type=int)
  parser.add_argument('--starting_timestep', type=float)
  parser.add_argument('--activate_upscaler', type=int)
  parser.add_argument('--upscale_model', type=str)
  parser.add_argument('--upscale_steps', type=int)
  parser.add_argument('--upscale_starting_timestep', type=float)
  parser.add_argument('--multiply_image_size_by', type=int)
  parser.add_argument('--cc', type=int)
  parser.add_argument('--grad_scale', type=float)

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

itt=0
















#@title Define Necessary functions
# Define necessary functions
class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


replace_grad = ReplaceGrad.apply

def divide_chunks(l, n):
      
    # looping till length l
    for i in range(0, len(l), n): 
        yield l[i:i + n]
        
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
    if prompt.startswith('http://') or prompt.startswith('https://') or prompt.startswith("E:") or prompt.startswith("C:") or prompt.startswith("D:"):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    return vals[0], float(vals[1])


class MakeCutouts(nn.Module):
    def __init__(self, cut_size,
                 Overview=4, 
                 WholeCrop = 0, WC_Allowance = 10, WC_Grey_P=0.2,
                 InnerCrop = 0, IC_Size_Pow=0.5, IC_Grey_P = 0.2
                 ):
        super().__init__()
        self.cut_size = cut_size
        self.Overview = Overview
        self.WholeCrop= WholeCrop
        self.WC_Allowance = WC_Allowance
        self.WC_Grey_P = WC_Grey_P
        self.InnerCrop = InnerCrop
        self.IC_Size_Pow = IC_Size_Pow
        self.IC_Grey_P = IC_Grey_P
        self.augs = T.Compose([
            #T.RandomHorizontalFlip(p=0.5),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomAffine(degrees=0, 
                           translate=(0.05, 0.05), 
                           #scale=(0.9,0.95),
                           fill=-1,  interpolation = T.InterpolationMode.BILINEAR, ),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            #T.RandomPerspective(p=1, interpolation = T.InterpolationMode.BILINEAR, fill=-1,distortion_scale=0.2),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomGrayscale(p=0.1),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.ColorJitter(brightness=0.05, contrast=0.05, saturation=0.05),
        ])

    def forward(self, input):
        gray = transforms.Grayscale(3)
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        l_size = max(sideX, sideY)
        output_shape = [1,3,self.cut_size,self.cut_size] 
        output_shape_2 = [1,3,self.cut_size+2,self.cut_size+2]
        pad_input = F.pad(input,((sideY-max_size)//2+round(max_size*0.055),(sideY-max_size)//2+round(max_size*0.055),(sideX-max_size)//2+round(max_size*0.055),(sideX-max_size)//2+round(max_size*0.055)), **padargs)
        cutouts_list = []
        
        if self.Overview>0:
            cutouts = []
            cutout = resize(pad_input, out_shape=output_shape)
            if self.Overview in [1,2,4]:
                if self.Overview>=2:
                    cutout=torch.cat((cutout,gray(cutout)))
                if self.Overview==4:
                    cutout = torch.cat((cutout, TF.hflip(cutout)))
            else:
                output_shape_all = list(output_shape)
                output_shape_all[0]=self.Overview
                cutout = resize(pad_input, out_shape=output_shape_all)
                if aug: cutout=self.augs(cutout)
            cutouts_list.append(cutout)
            
        if self.InnerCrop >0:
            cutouts=[]
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
            cutouts_tensor = torch.cat(cutouts)
            cutouts=[]
            cutouts_list.append(cutouts_tensor)
        cutouts=torch.cat(cutouts_list)
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


def range_loss(input, range_min, range_max):
    return (input - input.clamp(range_min,range_max)).pow(2).mean([1, 2, 3])

def symmetric_loss(x):
    w = x.shape[3]
    diff = (x - torch.flip(x,[3])).square().mean().sqrt()/(x.shape[2]*x.shape[3]/1e4)
    return(diff)
def displayImage(image):
  # image = unnormalize_image(image)
  size = image.size()

  width = size[0] * size[3] + (size[0]-1) * 4
  image_row = torch.zeros( size=(3, size[2], width), dtype=torch.uint8 )

  nw = 0
  for n in range(size[0]):
    image_row[:,:,nw:nw+size[3]] = (image[n,:].clamp(0, 1) * 255).to(torch.uint8)
    nw += size[3] + 4

  jpeg_data = torch.ops.image.encode_png(image_row.cpu(), 6)
  image = display.Image(bytes(jpeg_data))
  display.display( image )

def unitwise_norm(x):
    if len(x.squeeze().shape) <= 1:
        dim = None
        keepdim = False
    elif len(x.shape) in (2, 3):
        dim = 1
        keepdim = True
    elif len(x.shape) == 4:
        dim = (1, 2, 3)
        keepdim = True
    else:
        raise ValueError(f'got a parameter with shape not in (1, 2, 3, 4) {x}')
    return x.norm(dim = dim, keepdim = keepdim, p = 2)

#@title Define the secondary diffusion model
# Define the secondary diffusion model

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

 
secondary_model = SecondaryDiffusionImageNet2()
secondary_model.load_state_dict(torch.load(f'{model_path}/secondary_model_imagenet_2.pth', map_location='cpu'))
secondary_model = secondary_model.eval().requires_grad_(False).to("cuda") 

from functools import partial

from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
model_config = model_and_diffusion_defaults()
model_config.update({
    'attention_resolutions': '32,16,8',
    'class_cond': False,
    'diffusion_steps': 1000,
    'rescale_timesteps': True,
    'timestep_respacing':"16,48,72", #24,48,6'8，16，64 8,12,16,32',#'16,24,32,64',  # Modify this value to decrease the number of                                 # timesteps.
    'image_size': 512,
    'learn_sigma': True,
    'noise_schedule': 'linear',
    'num_channels': 256,
    'num_head_channels': 64,
    'num_res_blocks': 2,
    'resblock_updown': True,
    'use_fp16': True,
    'use_scale_shift_norm': True,
    'use_checkpoint': True
})

def wrapped_openai(x, t):
    x = x
    t = t
    return openai(x, t * 1000)[:, :3]

def cfg_model_fn(x, t):
    """The CFG wrapper function."""
    n = x.shape[0]
    x_in = x.repeat([target_embeds["ViT-B-16--openai"].shape[0]+1, 1, 1, 1])
    t_in = t.repeat([target_embeds["ViT-B-16--openai"].shape[0]+1])
    clip_embed_repeat = target_embeds["ViT-B-16--openai"].repeat([n, 1])
    clip_embed_in = torch.cat([torch.zeros_like(clip_embed_repeat[0].unsqueeze(0)), clip_embed_repeat])
    v_all = model["cc12m_1_cfg"](x_in, t_in, clip_embed_in)
    v_uncond = v_all[0].unsqueeze(0)
    v_cond = v_all[1:].mean(0).squeeze(0)
    v = v_uncond + (v_cond - v_uncond) * cfg_scale
    v = v.mean(0).squeeze(0)
    return v

has_loaded_custom = False
#model["cc12m_1_cfg"]=cfg_model_fn

"""## Initial Options"""

#@title Choose your diffusion models
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)


model_list = []
model = {}
pace = []
def load_diffusion_models(reload=True):
  global model_list
  global model
  global pace
  global openai
  if(reload==True):
    #@markdown <small>`imagenet_openimages` and `yfcc_2` work well with images > 256x256<small>
    if args.imagenet_openimages == 1:
        imagenet_openimages = True #@param {type:"boolean"}
    else:
        imagenet_openimages = False #@param {type:"boolean"}
    if args.yfcc_2 == 1:
        yfcc_2 = True #@param {type:"boolean"}
    else:
        yfcc_2 = False #@param {type:"boolean"}
    #@markdown <small>The `cc12m_1` family of models require ViT-B/16 CLIP-Guidance, work best 256x256, but you can use yfcc2 or imagenet to upscale<small>
    """
    if args.cc12m_1_cfg == 1:
        cc12m_1_cfg = True #@param {type:"boolean"}
    else:
        cc12m_1_cfg = False #@param {type:"boolean"}
    """
    cc12m_1_cfg = False #@param {type:"boolean"}

    if args.cc12m_1 == 1:
        cc12m_1 = True #@param {type:"boolean"}
    else:
        cc12m_1 = False #@param {type:"boolean"}
    if args.wikiart_256 == 1:
        wikiart_256 = True #@param {type:"boolean"}
    else:
        wikiart_256 = False #@param {type:"boolean"}
    if args.nshep_danbooru == 1:
        nshep_danbooru = True #@param {type:"boolean"}
    else:
        nshep_danbooru = False #@param {type:"boolean"}
    if args.danbooru_128 == 1:
        danbooru_128 = True #@param {type:"boolean"}
    else:
        danbooru_128 = False #@param {type:"boolean"}
    model_list = []
    model = {}
  else:
    cc12m_1_cfg = False
    cc12m_1 = False
    yfcc_2 = False
    imagenet_openimages = False
    wikiart_256 = False
    nshep_danbooru = False
    danbooru_128 = False
  pace = []
  
  if(cc12m_1_cfg or 'cc12m_1_cfg' in model_list):
    if 'cc12m_1_cfg' not in model_list:
      model_list.append("cc12m_1_cfg")
  if(cc12m_1 or 'cc12m_1' in model_list):
    if 'cc12m_1' not in model_list:
      model_list.append("cc12m_1")
  if(yfcc_2 or 'yfcc_2' in model_list):
    if 'yfcc_2' not in model_list:
      model_list.append("yfcc_2")
  if(imagenet_openimages or 'openimages' in model_list):
    if 'openimages' not in model_list:
      model_list.append("openimages")
  if(wikiart_256 or 'wikiart_256' in model_list):
    if 'wikiart_256' not in model_list:
      model_list.append("wikiart_256")
  if(nshep_danbooru or 'nshep_danbooru' in model_list):
    if 'nshep_danbooru' not in model_list:
      model_list.append("nshep_danbooru")
  if(danbooru_128 or 'danbooru_128' in model_list):
    if 'danbooru_128' not in model_list:
      model_list.append("danbooru_128")

  ##@markdown #### Use Pytorch Light Intefence Toolkit
  ##@markdown #####(allow for bigger things, reduces VRAM usage, have to use cfg or secondary model if activated)
  use_LIT = False 
  
  if use_LIT:
      for model_name in model_list:
          checkpoint = f"{model_path}/"+model_name+".pth"
          if model_name != "openimages":
              if(model_name == 'nshep_danbooru'):
                model[model_name] = get_model('cc12m_1')()
              else:
                model[model_name] = get_model(model_name)()
              #model[model_name].load_state_dict(torch.load(checkpoint, map_location='cpu'))
              #lmodel[model_name] = model[model_name].half()
              model[model_name] = model[model_name].to(device).eval().requires_grad_(False)
              model[model_name] = LitModule.from_params("models/"+model_name,
                                        lambda: model[model_name],
                                        device="cuda")
          elif model_name == "openimages":
              openai, diffusion = create_model_and_diffusion(**model_config)
              openai.load_state_dict(torch.load(f"{model_path}/openimages.pth", map_location='cpu'))
              openai.requires_grad_(False).eval().to(device)

              for name, param in openai.named_parameters():
                  if 'qkv' in name or 'norm' in name or 'proj' in name:
                      param.requires_grad_()
              if model_config['use_fp16']:
                  openai.convert_to_fp16()
              openai = LitModule.from_params("models/openimages",
                                        lambda: openai,
                                        device="cuda")
              model["openimages"] = wrapped_openai
  else:
      for model_name in model_list:
          checkpoint = f"{model_path}/"+model_name+".pth"
          if model_name != "openimages":
              if(model_name == 'nshep_danbooru'):
                model[model_name] = get_model('cc12m_1')()
              else:
                model[model_name] = get_model(model_name)()
              model[model_name].load_state_dict(torch.load(checkpoint, map_location='cpu'), strict=False)
              model[model_name] = checkpoint_wrapper(model[model_name], offload_to_cpu=True)
              #model[model_name].load_state_dict(torch.load("models/v-diffusion/merged_model.pth", map_location='cpu'))
              model[model_name] = model[model_name].half()
              model[model_name] = model[model_name].to(device).eval().requires_grad_(False)
          elif model_name == "openimages":
              openai, diffusion = create_model_and_diffusion(**model_config)
              openai.load_state_dict(torch.load(f"{model_path}/openimages.pth", map_location='cpu'))
              openai.requires_grad_(False).eval().to(device)
              for name, param in openai.named_parameters():
                  if 'qkv' in name or 'norm' in name or 'proj' in name:
                      param.requires_grad_()
              if model_config['use_fp16']:
                  openai.convert_to_fp16()
              model["openimages"] = wrapped_openai
              
  if "cc12m_1_cfg" in model_list:
      model["cc12m_1_cfg"]=cfg_model_fn

          
  normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                      std=[0.26862954, 0.26130258, 0.27577711])
  
  for model_name in model_list:
    if(model_name != 'wikiart_256'):
      pace.append({"model_name": model_name, "guided": True, "mag_adjust": 1})
    else:
      pace.append({"model_name": model_name, "guided": True, "mag_adjust": 1.5})
has_upscaled = False
load_diffusion_models()

#@title Choose your perceptor models

# suppress mmc warmup outputs


import mmc.loaders



clip_load_list = []
#@markdown #### Open AI CLIP models
if args.ViT_B32==1:
    ViT_B32 = True
else:
    ViT_B32 = False

if args.ViT_B16==1:
    ViT_B16 = True
else:
    ViT_B16 = False

if args.ViT_L14==1:
    ViT_L14 = True
else:
    ViT_L14 = False

if args.ViT_L14_336px==1:
    ViT_L14_336px = True
else:
    ViT_L14_336px = False

#RN101 = False #@param {type:"boolean"}
#RN50 = False #@param {type:"boolean"}

if args.RN50x4==1:
    RN50x4 = True
else:
    RN50x4 = False

if args.RN50x16==1:
    RN50x16 = True
else:
    RN50x16 = False

if args.RN50x64==1:
    RN50x64 = True
else:
    RN50x64 = False

#@markdown #### OpenCLIP models

if args.ViT_B16_plus==1:
    ViT_B16_plus = True
else:
    ViT_B16_plus = False

if args.ViT_B32_laion2b==1:
    ViT_B32_laion2b = True
else:
    ViT_B32_laion2b = False
    
#@markdown #### Multilangual CLIP models 
"""
if args.clip_farsi==1:
    clip_farsi = True
else:
    clip_farsi = False
    
if args.clip_korean==1:
    clip_korean = True
else:
    clip_korean = False
#@markdown #### CLOOB models

if args.cloob_ViT_B16==1:
    cloob_ViT_B16 = True
else:
    cloob_ViT_B16 = False
"""    

# @markdown Load even more CLIP and CLIP-like models (from [Multi-Modal-Comparators](https://github.com/dmarx/Multi-Modal-Comparators))
model1 = args.model1 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}
model2 = args.model2 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}
model3 = args.model3 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}

if ViT_B32: 
  clip_load_list.append("[clip - mlfoundations - ViT-B-32--openai]")
if ViT_B16: 
  clip_load_list.append("[clip - mlfoundations - ViT-B-16--openai]")
if ViT_L14: 
  clip_load_list.append("[clip - mlfoundations - ViT-L-14--openai]")
if RN50x4: 
  clip_load_list.append("[clip - mlfoundations - RN50x4--openai]")
if RN50x64: 
  clip_load_list.append("[clip - mlfoundations - RN50x64--openai]")
if RN50x16: 
  clip_load_list.append("[clip - mlfoundations - RN50x16--openai]")
if ViT_L14_336px:
  clip_load_list.append("[clip - mlfoundations - ViT-L-14-336--openai]")
if ViT_B16_plus:
  clip_load_list.append("[clip - mlfoundations - ViT-B-16-plus-240--laion400m_e32]")
if ViT_B32_laion2b:
  clip_load_list.append("[clip - mlfoundations - ViT-B-32--laion2b_e16]")
"""
if clip_farsi:
  clip_load_list.append("[clip - sajjjadayobi - clipfa]")
if clip_korean:
  clip_load_list.append("[clip - navervision - kelip_ViT-B/32]")
if cloob_ViT_B16:
  clip_load_list.append("[cloob - crowsonkb - cloob_laion_400m_vit_b_16_32_epochs]")
"""

if model1:
  clip_load_list.append(model1)
if model2:
  clip_load_list.append(model2)
if model3:
  clip_load_list.append(model3)


i = 0
from mmc.multimmc import MultiMMC
from mmc.modalities import TEXT, IMAGE
temp_perceptor = MultiMMC(TEXT, IMAGE)

def get_mmc_models(clip_load_list):
  mmc_models = []
  for model_key in clip_load_list:
      if not model_key:
          continue
      arch, pub, m_id = model_key[1:-1].split(' - ')
      mmc_models.append({
          'architecture':arch,
          'publisher':pub,
          'id':m_id,
          })
  return mmc_models
mmc_models = get_mmc_models(clip_load_list)

import mmc
from mmc.registry import REGISTRY

import mmc.loaders  # force trigger model registrations

from mmc.mock.openai import MockOpenaiClip

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])


def load_clip_models(mmc_models):
  clip_model, clip_size, clip_tokenize, clip_normalize= {},{},{},{}
  clip_list = []
  for item in mmc_models:
      print("Loaded ", item["id"])
      clip_list.append(item["id"])
      model_loaders = REGISTRY.find(**item)
      for model_loader in model_loaders:
          clip_model_loaded = model_loader.load()
          clip_model[item["id"]] = MockOpenaiClip(clip_model_loaded)
          clip_size[item["id"]] = clip_model[item["id"]].visual.input_resolution
          clip_tokenize[item["id"]] = clip_model[item["id"]].preprocess_text()
          if(item["architecture"] == 'cloob'):
            clip_normalize[item["id"]] = clip_model[item["id"]].normalize
          else:
            clip_normalize[item["id"]] = normalize
  return clip_model, clip_size, clip_tokenize, clip_normalize, clip_list


def full_clip_load(clip_load_list):
  torch.cuda.empty_cache()
  gc.collect()
  try:
    del clip_model, clip_size, clip_tokenize, clip_normalize, clip_list
  except:
    pass
  mmc_models = get_mmc_models(clip_load_list)
  clip_model, clip_size, clip_tokenize, clip_normalize, clip_list = load_clip_models(mmc_models)
  return clip_model, clip_size, clip_tokenize, clip_normalize, clip_list

clip_model, clip_size, clip_tokenize, clip_normalize, clip_list = full_clip_load(clip_load_list)

torch.cuda.empty_cache()
gc.collect()

"""## More setup stuff"""

# @title Setup cond_model and cond_sample
#from IPython.display import display
#import ipywidgets as widgets
import threading

#from tqdm.auto import trange

def make_cond_model_fn(model, cond_fn):
    def cond_model_fn(x, t, **extra_args):
        
        with torch.enable_grad():
            x = x.detach().requires_grad_()
            with torch.cuda.amp.autocast():
                if lerp:
                    v=torch.zeros_like(x)
                    for j in pace:
                        if j["model_name"]=="cc12m_1_cfg" or j["model_name"]=="cc12m_1" or j["model_name"]=="nshep_danbooru":
                            extra_args_in = extra_args
                        else:
                            extra_args_in= {}
                        v += model[j["model_name"]](x, t, **extra_args_in)

                    v = v/len(pace)
                else:
                    v = model[pace[i%len(pace)]["model_name"]](x, t, **extra_args_in)
                alphas, sigmas = utils.t_to_alpha_sigma(t)
                pred = x * alphas[:, None, None, None] - v * sigmas[:, None, None, None]
                cond_grad = cond_fn(x, t, pred, **extra_args).detach()
                v = v.detach() - cond_grad * (sigmas[:, None, None, None] / alphas[:, None, None, None])
        return v
    return cond_model_fn

def cond_clamp(image): 
    #if t >=0:
        mag=image.square().mean().sqrt()
        mag = (mag*cc).clamp(1.6,100)
        image = image.clamp(-mag, mag)
        return(image)


@torch.no_grad()
def cond_sample(model, x, steps, eta_schedule, extra_args, cond_fn):
    """Draws guided samples from a model given starting noise."""
    global clamp_max
    global itt
    ts = x.new_ones([x.shape[0]])
    # Create the noise schedule
    alphas, sigmas = utils.t_to_alpha_sigma(steps)

    # The sampling loop
    for i in range(len(steps)):
    
        sys.stdout.write(f"Iteration {i}\n")
        sys.stdout.flush()
        itt=i

        #if stop_flag: break
        if pace[i%len(pace)]["model_name"]=="cc12m_1_cfg" or pace[i%len(pace)]["model_name"]=="cc12m_1" or pace[i%len(pace)]["model_name"]=="nshep_danbooru":
            extra_args_in = extra_args
        else:
            extra_args_in= {}

        # Get the model output
        with torch.enable_grad():
            x = x.detach().requires_grad_()
            with torch.cuda.amp.autocast():
                if lerp:
                    v=torch.zeros_like(x)
                    for j in pace:
                        if j["model_name"]=="cc12m_1_cfg" or j["model_name"]=="cc12m_1" or j["model_name"]=="nshep_danbooru":
                            extra_args_in = extra_args
                        else:
                            extra_args_in= {}
                        v += model[j["model_name"]](x, ts * steps[i], **extra_args_in)
                        
                    v = v/len(pace)
                else:
                    v = model[pace[i%len(pace)]["model_name"]](x, ts * steps[i], **extra_args_in)
            v = cond_clamp(v)
        if torch.isnan(v).any(): continue
        
        if use_secondary_model:
            with torch.no_grad():
                if steps[i] < 1 and pace[i%len(pace)]["guided"]:
                    pred = x * alphas[i] - v * sigmas[i]
                    cond_grad = cond_fn(x, ts * steps[i],pred, **extra_args).detach()
                    v = v.detach() - cond_grad * (sigmas[i] / alphas[i]) * pace[i%len(pace)]["mag_adjust"]
                else:
                    v = v.detach()
                    pred = x * alphas[i] - v * sigmas[i]
                    clamp_max=torch.tensor([0])

        else:
            if steps[i] < 1 and pace[i%len(pace)]["guided"]:
                with torch.enable_grad():
                    pred = x * alphas[i] - v * sigmas[i]
                    cond_grad = cond_fn(x, ts * steps[i],pred, **extra_args).detach()
                    v = v.detach() - cond_grad * (sigmas[i] / alphas[i]) * pace[i%len(pace)]["mag_adjust"]
            else:
                with torch.no_grad():
                    v = v.detach()
                    pred = x * alphas[i] - v * sigmas[i]
                    clamp_max=torch.tensor([0])

        mag = pred.square().mean().sqrt()
        #print(mag)
        if torch.isnan(mag):
            print("ERROR2")
            continue
            
        # Predict the noise and the denoised image
        pred = x * alphas[i] - v * sigmas[i]
        eps = x * sigmas[i] + v * alphas[i]

        # If we are not on the last timestep, compute the noisy image for the
        # next timestep.
        if i < len(steps) - 1:
            # If eta > 0, adjust the scaling factor for the predicted noise
            # downward according to the amount of additional noise to add
            if eta_schedule[i] >=0:
                ddim_sigma = eta_schedule[i] * (sigmas[i + 1]**2 / sigmas[i]**2).sqrt() * \
                    (1 - alphas[i]**2 / alphas[i + 1]**2).sqrt()
            else:
                ddim_sigma = -eta_schedule[i]*sigmas[i+1]
            adjusted_sigma = (sigmas[i + 1]**2 - ddim_sigma**2).sqrt()

            # Recombine the predicted noise and predicted denoised image in the
            # correct proportions for the next step
            x = pred * alphas[i + 1] + eps * adjusted_sigma
            x = cond_clamp(x)


            # Add the correct amount of fresh noise
            if eta_schedule[i]:
                x += torch.randn_like(x) * ddim_sigma
            
         #######   x = sample_a_step(model, x.detach(), steps2, i//2, eta, extra_args)


    # If we are on the last timestep, output the denoised image
    return pred

# @title Setup cond_fn 
clamp_start_=0

def centralized_grad(x, use_gc=True, gc_conv_only=False):
    if use_gc:
        if gc_conv_only:
            if len(list(x.size())) > 3:
                x.add_(-x.mean(dim=tuple(range(1, len(list(x.size())))), keepdim=True))
        else:
            if len(list(x.size())) > 1:
                x.add_(-x.mean(dim=tuple(range(1, len(list(x.size())))), keepdim=True))
    return x

def cond_fn(x, t, x_in, clip_embed=[]):
    t2 = t
    t=1000-t*1000
    t=round(t[0].item())
    with torch.enable_grad():
        global test, clamp_start_, clamp_max
        n = x.shape[0]
        if use_secondary_model:                 
            x = x.detach().requires_grad_()
            x_in_second = secondary_model(x, t2.repeat([n])).pred
            if use_original_as_clip_in: x_in = replace_grad(x_in, (1-use_original_as_clip_in)*x_in_second+use_original_as_clip_in*x_in)
            else : x_in = x_in_second
        display_handling(x_in,t)
        n = x_in.shape[0]
        clip_guidance_scale = clip_guidance_index[t]
        make_cutouts = {}
        x_in_grad = torch.zeros_like(x_in)
        for i in clip_list:
            #make_cutouts[i] = MakeCutouts(clip_size[i],
            make_cutouts[i] = MakeCutouts(clip_size[i][0] if type(clip_size[i]) is tuple else clip_size[i],
             Overview= cut_overview[t], 
             InnerCrop = cut_innercut[t], 
             IC_Size_Pow=cut_ic_pow, 
             IC_Grey_P = cut_icgray_p[t]
             )
            cutn = cut_overview[t]+cut_innercut[t]
        for j in range(cutn_batches):
            losses=0
            for i in clip_list:
                clip_in = clip_normalize[i](make_cutouts[i](x_in.add(1).div(2)).to("cuda"))
                image_embeds = clip_model[i].encode_image(clip_in).float().unsqueeze(0).expand([target_embeds[i].shape[0],-1,-1])
                target_embeds_temp = target_embeds[i]
                if i == 'ViT-B-32--openai' and experimental_aesthetic_embeddings:
                  aesthetic_embedding = torch.from_numpy(np.load(f'aesthetic-predictor/vit_b_32_embeddings/rating{experimental_aesthetic_embeddings_score}.npy')).to(device) 
                  aesthetic_query = target_embeds_temp + aesthetic_embedding * experimental_aesthetic_embeddings_weight
                  target_embeds_temp = (aesthetic_query) / torch.linalg.norm(aesthetic_query)
                if i == 'ViT-L-14--openai' and experimental_aesthetic_embeddings:
                  aesthetic_embedding = torch.from_numpy(np.load(f'aesthetic-predictor/vit_l_14_embeddings/rating{experimental_aesthetic_embeddings_score}.npy')).to(device) 
                  aesthetic_query = target_embeds_temp + aesthetic_embedding * experimental_aesthetic_embeddings_weight
                  target_embeds_temp = (aesthetic_query) / torch.linalg.norm(aesthetic_query)  
                target_embeds_temp = target_embeds_temp.unsqueeze(1).expand([-1,cutn*n,-1])
                dists = spherical_dist_loss(image_embeds, target_embeds_temp)
                dists = dists.mean(1).mul(weights[i].squeeze()).mean()
                losses+=dists*clip_guidance_scale * (2 if i in ["ViT-L-14-336--openai", "RN50x64--openai", "ViT-B-32--laion2b_e16"] else (.4 if "cloob" in i else 1))
                if i == "ViT-L-14-336--openai" and aes_scale !=0:
                    aes_loss = (aesthetic_model_336(F.normalize(image_embeds, dim=-1))).mean() 
                    losses -= aes_loss * aes_scale 
                if i == "ViT-L-14--openai" and aes_scale !=0:
                    aes_loss = (aesthetic_model_224(F.normalize(image_embeds, dim=-1))).mean() 
                    losses -= aes_loss * aes_scale 
                if i == "ViT-B-16--openai" and aes_scale !=0:
                    aes_loss = (aesthetic_model_16(F.normalize(image_embeds, dim=-1))).mean() 
                    losses -= aes_loss * aes_scale 
                if i == "ViT-B-32--openai" and aes_scale !=0:
                    aes_loss = (aesthetic_model_32(F.normalize(image_embeds, dim=-1))).mean()
                    losses -= aes_loss * aes_scale
                #losses += dists
                #losses = losses / len(clip_list)                
                #gc.collect()
 
        tv_losses = tv_loss(x_in).sum() * tv_scales[0] +\
            tv_loss(F.interpolate(x_in, scale_factor= 1/2)).sum()* tv_scales[1] + \
            tv_loss(F.interpolate(x_in, scale_factor = 1/4)).sum()* tv_scales[2] + \
            tv_loss(F.interpolate(x_in, scale_factor = 1/8)).sum()* tv_scales[3] 
        range_scale= range_index[t]
        range_losses = range_loss(x_in,RGB_min,RGB_max).sum() * range_scale
        loss =  tv_losses  + range_losses + losses
        if symmetric_loss_scale != 0: loss +=  symmetric_loss(x_in) * symmetric_loss_scale
        if init_image is not None and init_scale:
            lpips_loss = (lpips_model(x_in, init) * init_scale).squeeze().mean()
            #print(lpips_loss)
            loss += lpips_loss
        loss.backward()
        grad = -x.grad
        grad = torch.nan_to_num(grad, nan=0.0, posinf=0, neginf=0)
        if grad_center: grad = centralized_grad(grad, use_gc=True, gc_conv_only=False)
        mag = grad.square().mean().sqrt()
        if mag==0 or torch.isnan(mag):
            print("ERROR")
            print(t)
            return(grad)
        if t>=0:
            if active_function == "softsign":
                grad = F.softsign(grad*grad_scale/mag)
            if active_function == "tanh":
                grad = (grad/mag*grad_scale).tanh()
            if active_function=="clamp":
                grad = grad.clamp(-mag*grad_scale*2,mag*grad_scale*2)
        if grad.abs().max()>0:
            grad=grad/grad.abs().max()*mag_mul
            magnitude = grad.square().mean().sqrt()
        else:
            return(grad)
        clamp_max = clamp_index[t]
        #print(magnitude, end = "\r")
        grad = grad* magnitude.clamp(max= clamp_max) /magnitude#0.2
        grad = grad.detach()
    return grad

def null_fn(x_in):
    return(torch.zeros_like(x_in))

def display_handling(x_in,t):
    global progress
    global itt
    #filename = f'{outputs_path}/{taskname}_N.jpg'
    filename = args.image_file
    if torch.isnan(x_in).any(): return()
    if itt % args.update != 0: return()

    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    TF.to_pil_image(x_in[0].add(1).div(2).clamp(0, 1)).save(filename,quality=99)
    """
    settings = generate_settings_file(add_prompts=True, add_dimensions=True)
    text_file = open(f"{outputs_path}/{taskname}_N.cfg", "w")
    text_file.write(settings)
    text_file.close()
    textprogress.value = f'{taskname},  step {round(t*1000)}'
    file = open(filename, "rb")
    image=file.read()
    progress.value = image 
    file.close()
    """

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

# @title Load aesthetic model
aesthetic_model_336 = torch.nn.Linear(768,1).cuda()
aesthetic_model_336.load_state_dict(torch.load(f"{model_path}/ava_vit_l_14_336_linear.pth"))

aesthetic_model_224 = torch.nn.Linear(768,1).cuda()
aesthetic_model_224.load_state_dict(torch.load(f"{model_path}/ava_vit_l_14_linear.pth"))

aesthetic_model_16 = torch.nn.Linear(512,1).cuda()
aesthetic_model_16.load_state_dict(torch.load(f"{model_path}/ava_vit_b_16_linear.pth"))

aesthetic_model_32 = torch.nn.Linear(512,1).cuda()
aesthetic_model_32.load_state_dict(torch.load(f"{model_path}/sa_0_4_vit_b_32_linear.pth"))

lpips_model = lpips.LPIPS(net='vgg').to(device)

# @title Main functions

#Make ETA schedule proportional to number of steps
def eta_schedule_proportional(eta_index):
  list_mul_eta = list_mul_to_array(eta_index)
  import re
  multipliers = re.findall("\*(\d+)", list_mul_eta)
  multiplied = re.findall("\[(\d+\.\d+)]", list_mul_eta)
  int_multipliers = [int(numeric_string) for numeric_string in multipliers]
  sum_totals = sum(int_multipliers)
  if(sum_totals != step):
    proportion = step/sum_totals
    new_multiplication_string = ''
    i = 0
    for multiplier in int_multipliers:
      new_multiplier = math.ceil(multiplier*proportion)
      new_multiplication_string += f' [{multiplied[i]}]*{new_multiplier} +'
      i+=1
  else:
    return(eta_index)  
  return(eval(new_multiplication_string[1:-2]))

#Convert a giant array into a string to be used in settigns
def list_mul_to_array(list_mul):
  i = 0
  mul_count = 0
  mul_string = ''
  full_list = list_mul
  full_list_len = len(full_list)
  for item in full_list:
    if(i == 0):
      last_item = item
    if(item == last_item):
      mul_count+=1
    if(item != last_item or full_list_len == i+1):
      mul_string = mul_string + f' [{last_item}]*{mul_count} +'
      mul_count=1
    last_item = item
    i+=1
  clean_string = mul_string[1:-2]
  if(not clean_string):
    clean_string = "[]"
  return(clean_string)

def generate_settings_file(add_prompts=False, add_dimensions=False):
  
  if(add_prompts):
    prompts_list = f'''
    prompts = {prompts}
    image_prompts = {image_prompts}
    '''
  else:
    prompts_list = ''

  if(add_dimensions):
    dimensions = f'''width = {width}
  	height = {height}
    '''
  else:
    dimensions = ''
  settings = f'''
    #This settings file can be loaded back to V-Majesty Diffusion.
    #If you like your setting consider sharing it to the settings library at https://github.com/multimodalart/MajestyDiffusion
    [model_list]
    model_list = {model_list}
    
    [clip_list]
    perceptors = {clip_load_list}
    
    [basic_settings]
    #Perceptor things
    {prompts_list}
    {dimensions}
    clip_guidance_scale = {clip_guidance_scale}
    step = {step}
    aesthetic_loss_scale = {aesthetic_loss_scale}
    augment_cuts={augment_cuts}

    #Init image settings
    starting_timestep = {starting_timestep}
    init_scale = {init_scale} 
    mask_scale = {mask_scale}

    [advanced_settings]
    #Add CLIP Guidance and all the flavors or just run normal Latent Diffusion
    
    use_secondary_model={use_secondary_model}
    use_original_as_clip_in={use_original_as_clip_in}
    lerp={lerp}
    #Cut settings
    cut_overview = {list_mul_to_array(cut_overview)}
    cut_innercut = {list_mul_to_array(cut_innercut)}
    cut_ic_pow = {cut_ic_pow}
    cut_icgray_p = {list_mul_to_array(cut_icgray_p)}
    cutn_batches = {cutn_batches}
    sat_index = {list_mul_to_array(sat_index)}   
    range_index = {list_mul_to_array(range_index)}
    eta_index = {list_mul_to_array(eta_index)}
    active_function = "{active_function}"
    tv_scales = {list_mul_to_array(tv_scales)}
    tv_scale_2 = {list_mul_to_array(tv_scale_2)}
    n_batches = {n_batches}
    unified_cutouts = {unified_cutouts}
    ns_cutn = {ns_cutn}
    step_enhance={step_enhance}
    mid_point = {mid_point}
    steps_pow = {steps_pow}
    #cfg_scale only for cc12m_cfg
    cfg_scale = {cfg_scale}
    #If you uncomment this line you can schedule the CLIP guidance across the steps. Otherwise the clip_guidance_scale will be used
    clip_guidance_schedule = {list_mul_to_array(clip_guidance_index)}
    
    #Apply symmetric loss (force simmetry to your results)
    symmetric_loss_scale = {symmetric_loss_scale} 

    #Grad and mag advanced settings
    grad_center = {grad_center}
    #Lower value result in more coherent and detailed result, higher value makes it focus on more dominent concept
    grad_scale={grad_scale} 
    mag_mul = {mag_mul}
    clamp_start_={clamp_start_}
    clamp_index = {list_mul_to_array(clamp_index)}
    
    #More settings
    RGB_min = {RGB_min}
    RGB_max = {RGB_max}
    #How to pad the image with cut_overview
    padargs = {padargs} 
    flip_aug={flip_aug}
    cc = {cc}
    #Experimental aesthetic embeddings, work only with OpenAI ViT-B/32 and ViT-L/14
    experimental_aesthetic_embeddings = {experimental_aesthetic_embeddings}
    #How much you want this to influence your result
    experimental_aesthetic_embeddings_weight = {experimental_aesthetic_embeddings_weight}
    #9 are good aesthetic embeddings, 0 are bad ones
    experimental_aesthetic_embeddings_score = {experimental_aesthetic_embeddings_score}

    #Internal upscaler settings
    activate_upscaler = {activate_upscaler}
    upscale_model = "{upscale_model}"
    multiply_image_size_by = {multiply_image_size_by}
    '''
  return(settings)
def do_run():
    global target_embeds, weights, init, makecutouts, progress, textprogress, progress2, batch_num, taskname
    with torch.cuda.amp.autocast():
        #if seed is not None:
        #    torch.manual_seed(seed)
        make_cutouts = {}
        for i in clip_list:
             make_cutouts[i] = MakeCutouts(clip_size[i],Overview=1)
        side_x, side_y = [w,h]
        target_embeds, weights ,zero_embed = {}, {}, {}
        for i in clip_list:
            target_embeds[i] = []
            weights[i]=[]

        
            
        for prompt in prompts:
            txt, weight = parse_prompt(prompt)
            for i in clip_list:
                embeds = clip_model[i].encode_text(clip.tokenize(txt).to(device)).float()
                target_embeds[i].append(embeds)
                weights[i].append(weight)
        for prompt in image_prompts:
            print(f"processing{prompt}",end="\r")
            path, weight = parse_prompt(prompt)
            img = Image.open(fetch(path)).convert('RGB')
            img = TF.resize(img, min(side_x, side_y, *img.size), transforms.InterpolationMode.LANCZOS)
            for i in clip_list:
                batch = make_cutouts[i](TF.to_tensor(img).unsqueeze(0).to(device))
                embed = clip_model[i].encode_image(normalize(batch)).float()
                target_embeds[i].append(embed)
                weights[i].extend([weight])

        #if anti_jpg!=0:
        #    if "ViT-B/32" not in clip_list:
        #      target_embeds["ViT-B/32"] = []
        #      weights["ViT-B/32"] = []
        #    target_embeds["ViT-B/32"].append(torch.tensor([np.load(f"{model_path}/openimages_512x_png_embed224.npz")['arr_0']-np.load(f"{model_path}/imagenet_512x_jpg_embed224.npz")['arr_0']], device = device))
        #    weights["ViT-B/32"].append(anti_jpg)

        #print(weights)
        for i in clip_list:
            target_embeds[i] = torch.cat(target_embeds[i])
            weights[i] = torch.tensor([*weights[i]], device=device)

        init = None
        init_mask = None
        if init_image is not None:
            S = model_config['image_size']
            if mask_scale > 0:
                init = Image.open(fetch(init_image)).convert('RGBA')
                init = init.resize((S, S), Image.BILINEAR)
                init = TF.to_tensor(init).to(device)
                init_mask = init[3] # alpha channel
                init_mask = (init_mask>0.5).to(torch.float32)
                init = init[:3].unsqueeze(0).mul(2).sub(1) # RGB
            else:
                init = Image.open(fetch(init_image)).convert('RGB')
                init = init.resize((S, S), Image.LANCZOS)
                init = TF.to_tensor(init).to(device)
                init = init.unsqueeze(0).mul(2).sub(1)

        cur_t = None

        for i in range(n_batches):
            taskname=taskname_+"_"+str(i)
            #from IPython.display import display
            #import ipywidgets as widgets
            import threading

            t = torch.linspace(1, 0, step + 1, device=device)[:-1]
            if step_enhance:
                t = torch.tensor(np.concatenate([np.arange(1,mid_point,(mid_point-1)/step/0.5),np.arange(mid_point,0,-mid_point/step/0.5)])).to("cuda")
            x = torch.randn([1, 3, side_y, side_x], device=device)
            steps = utils.get_spliced_ddpm_cosine_schedule(t)
            if init_image is not None:
                steps = steps[steps < starting_timestep]
                alpha, sigma = utils.t_to_alpha_sigma(steps[0])
                x = init * alpha + x * sigma
            if "cc12m_1_cfg" in model_list or "cc12m_1" in model_list or "nshep_danbooru" in model_list:
                extra_args = {'clip_embed': target_embeds["ViT-B-16--openai"][0].unsqueeze(0)}
            else:
                extra_args = {}
            """
            progress = widgets.Image(layout = widgets.Layout(max_width = "400px",max_height = "512px"))
            textprogress = widgets.Textarea()
            display(textprogress)
            display(progress)
            """
            if sampling_method == "DDIM":
                cond_sample(model, x, steps, eta_index, extra_args, cond_fn)
            if sampling_method == "PLMS":
                model_fn = make_cond_model_fn(model, cond_fn)
                sampling.plms_sample(model_fn, x, steps, extra_args, callback=None)
            if sampling_method == "PLMS2":
                model_fn = make_cond_model_fn(model, cond_fn)
                sampling.plms2_sample(model_fn, x, steps, extra_args, callback=None)
            if sampling_method == "PIE":
                model_fn = make_cond_model_fn(model, cond_fn)
                sampling.pie_sample(model_fn, x, steps, extra_args, callback=None)
            if sampling_method == "PRK":
                model_fn = make_cond_model_fn(model, cond_fn)
                sampling.prk_sample(model_fn, x, steps, extra_args, callback=None)

"""## Diffuse!

### Advanced settings
"""

RGB_min, RGB_max = [args.RGB_min,args.RGB_max]
n_batches = 1
#cutn_batches seem to be ignored at the moment as gradient caching is being used, so increase your actual cuts
cutn_batches = args.cutn_batches
if args.unified_cutouts==1:
    unified_cutouts = True
else:
    unified_cutouts = False
ns_cutn = args.ns_cutn

#VOC START - DO NOT DELETE
cut_overview = [24]*1000
cut_innercut = [0]*200+[0]* 1000
cut_icgray_p = [0.2]*100+[0]*100+[0]*100+[0]*1000
padargs = {"mode":"constant", "value":-1}
if args.schedule_clip_guidance==1:
    clip_guidance_schedule = [5000]*300 + [1000]*700
tv_scales = [150]*4
tv_scales_2 = [150]*0
clamp_index = 1 * np.array([0.03]*50+[0.04]*200+[0.05]*750)
sat_index = 0 * np.array([10000]*40+[0]*1000)
range_index = [1500000]*100+[0]*1000
eta_index = [1.2]*100
#VOC FINISH - DO NOT DELETE

cut_ic_pow = args.cut_ic_pow

if args.flip_aug==1:
    flip_aug=True
else:
    flip_aug=False

cutout_debug = False

if args.step_enhance==1:
    step_enhance=True
else:
    step_enhance=False
    
mid_point = args.mid_point
steps_pow= args.steps_pow
cfg_scale = args.cfg_scale

symmetric_loss_scale = args.symmetric_loss_scale
if args.grad_center==1:
    grad_center = True
else:
    grad_center = False

mag_mul = args.mag_mul
clamp_start_= args.clamp_start

use_original_as_clip_in=0
lerp=True
sampling_method="DDIM" #PLMS is broken right now

perlin_init=False
#anti_jpg=0.5 #broken

#Experimental aesthetic embeddings, work only with OpenAI ViT-B/32 and ViT-L/14
if args.experimental_aesthetic_embeddings==1:
    experimental_aesthetic_embeddings = True
else:
    experimental_aesthetic_embeddings = False
#How much you want this to influence your result
experimental_aesthetic_embeddings_weight = args.experimental_aesthetic_embeddings_weight
#9 are good aesthetic embeddings, 0 are bad ones
experimental_aesthetic_embeddings_score = args.experimental_aesthetic_embeddings_score

"""### Run!"""

# Prompts
#Amp up your prompt game with prompt engineering, check out this guide: https://matthewmcateer.me/blog/clip-prompt-engineering/
#prompts = ["A Majestic Castle by Studio Ghibli"]
prompts = [args.prompt]

# Image prompts
if args.image_prompts=="":
    image_prompts = []
else:
    image_prompts = [args.image_prompts]

import warnings
warnings.filterwarnings('ignore')
import time
import random
#import threading

torch.cuda.empty_cache()
gc.collect()
#@markdown ### Basic settings 
#@markdown We're still figuring out default settings. Experiment and <a href="https://github.com/multimodalart/majesty-diffusion">share your settings with us</a>
#@markdown Experiment with lower `width` and `height` that is then further upscaled with yfcc and openclip, works great 
width = args.sizex # 512#@param{type: 'integer'}
height = args.sizey # 512#@param{type: 'integer'}
clip_guidance_scale = args.clip_guidance_scale # 2400#@param{type: 'integer'}
step =  args.iterations #100#@param{type: 'integer'}
aesthetic_loss_scale = args.aesthetic_loss_scale #100 #@param{type: 'integer'}

if args.augment_cuts==1:
    augment_cuts=True
else:
    augment_cuts=False

if args.use_secondary_model==1:
    use_secondary_model=True
else:
    use_secondary_model=False

stop_flag = False
batch_num=0
seed = args.seed #int(random.randint(0, 2147483647))
batch_title = "creations"
title = batch_title

#@markdown ---
#@markdown <br>

#@markdown  ### Init image settings
#@markdown `init_image` requires the path of an image to use as init to the model
init_image = args.init_image #None #@param{type: 'string'}
if(init_image == '' or init_image == 'None'):
  init_image = None
#@markdown `init_mask` is a mask same width and height as the original image with the color black indicating where to inpaint
init_mask = args.init_mask #None #@param{type: 'string'}
mask_scale=args.mask_scale
#@markdown `init_scale` controls how much the init image should influence the final result. Experiment with values around `1000`
init_scale = args.init_scale #@param{type: 'integer'}
#@markdown If you are used to `skip_timesteps` for init images, this is it but as a % of noise you would like to add
starting_timestep = args.starting_timestep # 0.9#@param{type: 'number'}

#@markdown ---
#@markdown <br>

"""
#Get corrected sizes
w = (width//64)*64;
h = (height//64)*64;
if w != width or h != height:
    print(f'Changing output size to {w}x{h}. Dimensions must by multiples of 64.')
#w,h = width,height
"""
w,h = width,height

#@markdown  ### Internal Upscale (upscale the output with a bigger model)
if args.activate_upscaler==1:
    activate_upscaler = True #@param{type: 'boolean'}
else:
    activate_upscaler = False #@param{type: 'boolean'}

upscale_model = args.upscale_model #'yfcc_2' #@param ["yfcc_2", "imagenet_openimages"]
if(upscale_model == 'imagenet_openimages'):
  upscale_model = 'openimages'
upscale_steps = args.upscale_steps #100 #@param{type: 'integer'}
upscale_starting_timestep = args.upscale_starting_timestep #0.8 #@param{type: 'number'}
multiply_image_size_by = args.multiply_image_size_by #2 #@param{type: 'integer'}

#@markdown ---
#@markdown <br>

#@markdown ### Custom saved settings
#@markdown If you choose custom saved settings, the settings set by the preset overrule some of your choices. You can still modify the settings not in the preset. <a href="https://github.com/multimodalart/majesty-diffusion/tree/main/v_settings_library">Check what each preset modifies here</a>
custom_settings = 'path/to/settings.cfg' #@param{type:'string'}
settings_library = 'None (use settings defined above)' #@param ["None (use settings defined above)", "default (optimized for colab free)", "disco_diffusion_defaults"]
if(settings_library != 'None (use settings defined above)'):
  if(settings_library == 'default (optimized for colab free)'):
    custom_settings = f'majesty-diffusion/v_settings_library/default.cfg'
  else:
    custom_settings = f'majesty-diffusion/v_settings_library/{settings_library}.cfg'

is_custom_settings = (custom_settings is not None and custom_settings is not '' and custom_settings != 'path/to/settings.cfg')

#Reload the user selected models after an upscale or after they remove a settings file
if(has_upscaled or (has_loaded_custom and not is_custom_settings)):
  del model
  load_diffusion_models(reload=True)

global_var_scope = globals()
has_loaded_custom = False
if(is_custom_settings):
  has_loaded_custom = True
  print('Loaded ', custom_settings)
  try:
    from configparser import ConfigParser
  except ImportError:
      from ConfigParser import ConfigParser
  import configparser
  
  config = ConfigParser()
  config.read(custom_settings)

  #Load diffusion models from config
  if(config.has_section('model_list')):
    models_incoming_list = config.items('model_list')
    incoming_models = models_incoming_list[0]
    incoming_models = eval(incoming_models[1])
    if((len(incoming_models) != len(model_list)) or not all(elem in incoming_models for elem in model_list)):
      pace = []
      model_list = incoming_models
      load_diffusion_models(reload=False)
  #Load CLIP models from config
  if(config.has_section('clip_list')):
    clip_incoming_list = config.items('clip_list')
    clip_incoming_models = clip_incoming_list[0]
    incoming_perceptors = eval(clip_incoming_models[1])
    if((len(incoming_perceptors) != len(clip_load_list)) or not all(elem in incoming_perceptors for elem in clip_load_list)):
      clip_load_list = incoming_perceptors
      clip_model, clip_size, clip_tokenize, clip_normalize, clip_list = full_clip_load(clip_load_list)

  #Load settings from config and replace variables
  if(config.has_section('basic_settings')):
    basic_settings = config.items('basic_settings')
    for basic_setting in basic_settings:
      global_var_scope[basic_setting[0]] = eval(basic_setting[1])
  
  if(config.has_section('advanced_settings')):
    advanced_settings = config.items('advanced_settings')
    for advanced_setting in advanced_settings:
      global_var_scope[advanced_setting[0]] = eval(advanced_setting[1])

aes_scale = aesthetic_loss_scale
aug=augment_cuts
eta_index=eta_schedule_proportional(eta_index)

try: 
  clip_guidance_schedule
  clip_guidance_index = clip_guidance_schedule
except:
  clip_guidance_index = [clip_guidance_scale]*1000

for cc in [args.cc]:
        for bsq_scale in [.1]:
              for grad_scale in [args.grad_scale]:
                 for active_function in ["softsign"]:
                    torch.manual_seed(seed)
                    random.seed(seed)
                    if grad_scale!=1 and active_function=="NA": continue
                    title2 = title + str(int(time.time()))
                    taskname_ = title2 +"_cc"+str(cc)+"_gs"+str(grad_scale)#+ prompts[0]
                    gc.collect()
                    torch.cuda.empty_cache()
                    do_run()
                    #threading.Thread(target=do_run, args=()).start()

torch.cuda.empty_cache()
gc.collect()
has_upscaled = False
if(activate_upscaler):
  
  sys.stdout.write("Loading upscaling model ...\n")
  sys.stdout.flush()
  
  has_upscaled = True
  already_loaded = upscale_model in model_list
  model_list = []
  pace = []    
  if(upscale_model == 'yfcc_2'):
    model_list.append('yfcc_2')
  elif(upscale_model == 'openimages'):
    model_list.append('openimages')
  
  if(not already_loaded):
    del model
    model = {}
    load_diffusion_models(reload=False)
  else:
    pace.append({"model_name": upscale_model, "guided": True, "mag_adjust": 1})

  sys.stdout.write("Upscaling ...\n")
  sys.stdout.flush()

  #init_image = f"{outputs_path}/{taskname_}_0_N.jpg"
  init_image = args.image_file
  step = upscale_steps 
  starting_timestep = upscale_starting_timestep
  w,h = args.sizex*multiply_image_size_by,args.sizey*multiply_image_size_by
  torch.cuda.empty_cache()
  gc.collect()
  eta_index=eta_schedule_proportional(eta_index)
  for cc in [args.cc]:
        for bsq_scale in [.1]:
              for grad_scale in [args.grad_scale]:
                 for active_function in ["softsign"]:
                    torch.manual_seed(seed)
                    random.seed(seed)
                    if grad_scale!=1 and active_function=="NA": continue
                    title2 = title + str(int(time.time()))
                    taskname_ = title2 +"_cc"+str(cc)+"_gs"+str(grad_scale)#+ prompts[0]
                    gc.collect()
                    torch.cuda.empty_cache()
                    do_run()
torch.cuda.empty_cache()
gc.collect()

#@markdown ### Save current settings
#@markdown If you would like to save your current settings, uncheck `skip_saving` and run this cell. You will get a `v_majesty_custom_settings.cfg` file you can reuse and share. If you like your results, send us a <a href="#">pull request</a> to add your settings to the selectable library
skip_saving = True #@param{type:'boolean'}
if(not skip_saving):
  data = generate_settings_file(add_prompts=False, add_dimensions=True)
  text_file = open("v_majesty_custom_settings.cfg", "w")
  text_file.write(data)
  text_file.close()
  from google.colab import files
  files.download('v_majesty_custom_settings.cfg')
  #print(data)
  print("Downloaded as custom_settings.cfg")

"""### Biases acknowledgment
Despite how impressive being able to turn text into image is, beware to the fact that this model may output content that reinforces or exarcbates societal biases. According to the <a href='https://arxiv.org/abs/2112.10752' target='_blank'>Latent Diffusion paper</a>:<i> \"Deep learning modules tend to reproduce or exacerbate biases that are already present in the data\"</i>. 

The models were trained on mostly non-curated image-text-pairs from the internet (the exception being the the removal of illegal content) and is meant to be used for research purposes, such as this one
"""
