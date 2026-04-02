# ES2000_MathRock_Diffusion.ipynb
# Original file is located at https://colab.research.google.com/github/ethansmith2000/MathRock-Diffusion/blob/main/ES2000_MathRock_Diffusion.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
sys.path.append('./MiDaS')
sys.path.append('./AdaBins')
sys.path.append('./guided-diffusion-ethansmith2000')
sys.path.append('./pytorch3d-lite')
sys.path.append('./disco-diffusion-5-5')
sys.path.append('./ResizeRight')

import subprocess, os, sys, ipykernel

is_colab = False
google_drive = False
save_models_to_google_drive = False
save_clipmodels_to_google_drive = False
#print("Google Colab not detected.")
#multipip_res = subprocess.run(['pip', 'install', 'ipywidgets>=7,<8'], stdout=subprocess.PIPE).stdout.decode('utf-8')

root_path = os.getcwd()

import os
def createPath(filepath):
    os.makedirs(filepath, exist_ok=True)

initDirPath = f'{root_path}/init_images'
createPath(initDirPath)
outDirPath = f'{root_path}/images_out'
createPath(outDirPath)

libraries = f'{root_path}/libraries'
createPath(libraries)

#@title ### 1.3 Install, import dependencies and set up runtime devices

import pathlib, shutil, os, sys

useCPU = False #@param {type:"boolean"}

PROJECT_DIR = os.path.abspath(os.getcwd())
USE_ADABINS = True

root_path = os.getcwd()
model_path = './'

from CLIP import clip
import open_clip
from guided_diffusion.script_util import create_model_and_diffusion
from resize_right import resize
import py3d_tools
from midas.dpt_depth import DPTDepthModel
import disco_xform_utils as dxf

import torch
from dataclasses import dataclass
from functools import partial
import cv2
import pandas as pd
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
from types import SimpleNamespace
from torch import nn
from torch.nn import functional as F
import torchvision.transforms as T
import torchvision.transforms.functional as TF
#from tqdm.notebook import tqdm
from CLIP import clip
from resize_right import resize
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
import random
from ipywidgets import Output
import hashlib
from functools import partial

from IPython.display import Image as ipyimg
from numpy import asarray
from einops import rearrange, repeat
import torch, torchvision
import time
from omegaconf import OmegaConf

# AdaBins stuff
if USE_ADABINS:
    from infer import InferenceHelper
    MAX_ADABINS_AREA = 500000

import torch

import argparse








sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--seed', type=int)
  parser.add_argument('--iterations', type=int)
  parser.add_argument('--sizex', type=int)
  parser.add_argument('--sizey', type=int)
  parser.add_argument('--batch_name', type=str)
  parser.add_argument('--update', type=int)
  parser.add_argument('--diffusion_model', type=str)
  parser.add_argument('--use_secondary_model', type=str)
  parser.add_argument('--switch_timestep', type=int)
  parser.add_argument('--animation_mode', type=str)
  parser.add_argument('--init_image', type=str)
  parser.add_argument('--init_scale', type=int)
  parser.add_argument('--skip_steps', type=int)
  parser.add_argument('--diffusion_sampling_mode', type=str)
  parser.add_argument('--custom_path', type=str)
  parser.add_argument('--use_checkpoint', type=int)

  parser.add_argument('--ViTB32', type=int)
  parser.add_argument('--ViTB16', type=int)
  parser.add_argument('--ViTL14', type=int)
  parser.add_argument('--ViTL14_336', type=int)
  parser.add_argument('--RN101', type=int)
  parser.add_argument('--RN50', type=int)
  parser.add_argument('--RN50x4', type=int)
  parser.add_argument('--RN50x16', type=int)
  parser.add_argument('--RN50x64', type=int)

  parser.add_argument('--ViTB32_laion2b_e16', type=int)
  parser.add_argument('--ViTB32_laion400m_e31', type=int)
  parser.add_argument('--ViTB32_laion400m_32', type=int)
  parser.add_argument('--ViTB32quickgelu_laion400m_e31', type=int)
  parser.add_argument('--ViTB32quickgelu_laion400m_e32', type=int)
  parser.add_argument('--ViTB16_laion400m_e31', type=int)
  parser.add_argument('--ViTB16_laion400m_e32', type=int)
  parser.add_argument('--RN50_yffcc15m', type=int)
  parser.add_argument('--RN50_cc12m', type=int)
  parser.add_argument('--RN50_quickgelu_yfcc15m', type=int)
  parser.add_argument('--RN50_quickgelu_cc12m', type=int)
  parser.add_argument('--RN101_yfcc15m', type=int)
  parser.add_argument('--RN101_quickgelu_yfcc15m', type=int)
  parser.add_argument('--clip_guidance_scale', type=str)
  parser.add_argument('--tv_scale', type=int)
  parser.add_argument('--range_scale', type=int)
  parser.add_argument('--sat_scale', type=int)
  parser.add_argument('--cutn_batches', type=str)
  parser.add_argument('--skip_augs', type=int)

  parser.add_argument('--video_init_steps', type=int)
  parser.add_argument('--video_init_clip_guidance_scale', type=float)
  parser.add_argument('--video_init_tv_scale', type=float)
  parser.add_argument('--video_init_range_scale', type=float)
  parser.add_argument('--video_init_sat_scale', type=float)
  parser.add_argument('--video_init_cutn_batches', type=int)
  parser.add_argument('--video_init_skip_steps', type=int)
  parser.add_argument('--video_init_path', type=str)
  parser.add_argument('--extract_nth_frame', type=int)
  parser.add_argument('--persistent_frame_output_in_batch_folder', type=int)
  parser.add_argument('--video_init_seed_continuity', type=int)
  parser.add_argument('--video_init_flow_warp', type=int)
  parser.add_argument('--video_init_flow_blend', type=float)
  parser.add_argument('--video_init_check_consistency', type=int)
  parser.add_argument('--video_init_blend_mode', type=str)
  parser.add_argument('--key_frames', type=int)
  parser.add_argument('--max_frames', type=int)
  parser.add_argument('--video_init_frames_scale', type=int)
  parser.add_argument('--video_init_frames_skip_steps', type=str)
  
  parser.add_argument('--midas_weight', type=float)
  parser.add_argument('--near_plane', type=int)
  parser.add_argument('--far_plane', type=int)
  parser.add_argument('--fov', type=int)

  parser.add_argument('--turbo_mode', type=int)
  parser.add_argument('--turbo_steps', type=str)
  parser.add_argument('--turbo_preroll', type=int)

  parser.add_argument('--vr_mode', type=int)
  parser.add_argument('--vr_eye_angle', type=float)
  parser.add_argument('--vr_ipd', type=float)

  parser.add_argument('--frames_scale', type=int)
  parser.add_argument('--frames_skip_steps', type=str)

  parser.add_argument('--perlin_init', type=int)
  parser.add_argument('--perlin_mode', type=str)

  parser.add_argument('--eta', type=float)
  parser.add_argument('--clamp_grad', type=int)
  parser.add_argument('--clamp_max', type=str)

  parser.add_argument('--randomize_class', type=int)
  parser.add_argument('--clip_denoised', type=int)
  parser.add_argument('--fuzzy_prompt', type=int)
  parser.add_argument('--rand_mag', type=float)

  parser.add_argument('--cut_overview', type=str)
  parser.add_argument('--cut_innercut', type=str)
  parser.add_argument('--cut_ic_pow', type=str)
  parser.add_argument('--cut_icgray_p', type=str)
  parser.add_argument('--cut_easing_fn', type=str)

  parser.add_argument('--resume_run', type=int)
  parser.add_argument('--run_to_resume', type=str)
  parser.add_argument('--resume_from_frame', type=str)
  parser.add_argument('--retain_overwritten_frames', type=int)

  parser.add_argument('--use_vertical_symmetry', type=int)
  parser.add_argument('--use_horizontal_symmetry', type=int)
  parser.add_argument('--transformation_percent', type=float)

  parser.add_argument('--n_batches', type=int)
  parser.add_argument('--force_flow_generation', type=int)
    
  parser.add_argument('--image_file', type=str)
  parser.add_argument('--frame_dir', type=str)

  parser.add_argument('--save_updates_as_frames', type=int)

  args = parser.parse_args()
  return args

args3=parse_args();

if args3.seed is not None:
    sys.stdout.write(f'Setting seed to {args3.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args3.seed)
    import random
    random.seed(args3.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args3.seed)
    torch.cuda.manual_seed(args3.seed)
    torch.cuda.manual_seed_all(args3.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 


DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()

#@title ### 1.4 Define Midas functions

from midas.dpt_depth import DPTDepthModel
from midas.midas_net import MidasNet
from midas.midas_net_custom import MidasNet_small
from midas.transforms import Resize, NormalizeImage, PrepareForNet

# Initialize MiDaS depth model.
# It remains resident in VRAM and likely takes around 2GB VRAM.
# You could instead initialize it for each frame (and free it after each frame) to save VRAM.. but initializing it is slow.
default_models = {
    "midas_v21_small": f"{model_path}/midas_v21_small-70d6b9c8.pt",
    "midas_v21": f"{model_path}/midas_v21-f6b98070.pt",
    "dpt_large": f"{model_path}/dpt_large-midas-2f21e586.pt",
    "dpt_hybrid": f"{model_path}/dpt_hybrid-midas-501f0c75.pt",
    "dpt_hybrid_nyu": f"{model_path}/dpt_hybrid_nyu-2ce69ec7.pt",}


def init_midas_depth_model(midas_model_type="dpt_large", optimize=True):
    midas_model = None
    net_w = None
    net_h = None
    resize_mode = None
    normalization = None

    print(f"Initializing MiDaS '{midas_model_type}' depth model...")
    # load network
    midas_model_path = default_models[midas_model_type]

    if midas_model_type == "dpt_large": # DPT-Large
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitl16_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode = "minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "dpt_hybrid": #DPT-Hybrid
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitb_rn50_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode="minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "dpt_hybrid_nyu": #DPT-Hybrid-NYU
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitb_rn50_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode="minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "midas_v21":
        midas_model = MidasNet(midas_model_path, non_negative=True)
        net_w, net_h = 384, 384
        resize_mode="upper_bound"
        normalization = NormalizeImage(
            mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        )
    elif midas_model_type == "midas_v21_small":
        midas_model = MidasNet_small(midas_model_path, features=64, backbone="efficientnet_lite3", exportable=True, non_negative=True, blocks={'expand': True})
        net_w, net_h = 256, 256
        resize_mode="upper_bound"
        normalization = NormalizeImage(
            mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        )
    else:
        print(f"midas_model_type '{midas_model_type}' not implemented")
        assert False

    midas_transform = T.Compose(
        [
            Resize(
                net_w,
                net_h,
                resize_target=None,
                keep_aspect_ratio=True,
                ensure_multiple_of=32,
                resize_method=resize_mode,
                image_interpolation_method=cv2.INTER_CUBIC,
            ),
            normalization,
            PrepareForNet(),
        ]
    )

    midas_model.eval()
    
    if optimize==True:
        if DEVICE == torch.device("cuda"):
            midas_model = midas_model.to(memory_format=torch.channels_last)  
            midas_model = midas_model.half()

    midas_model.to(DEVICE)

    print(f"MiDaS '{midas_model_type}' depth model initialized.")
    return midas_model, midas_transform, net_w, net_h, resize_mode, normalization

#@title 1.5 Define necessary functions

# https://gist.github.com/adefossez/0646dbe9ed4005480a2407c62aac8869

import py3d_tools as p3dT
import disco_xform_utils as dxf


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

def regen_perlin():
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
    return init.expand(batch_size, -1, -1, -1)

def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')

def read_image_workaround(path):
    """OpenCV reads images as BGR, Pillow saves them as RGB. Work around
    this incompatibility to avoid colour inversions."""
    im_tmp = cv2.imread(path)
    return cv2.cvtColor(im_tmp, cv2.COLOR_BGR2RGB)

def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    return vals[0], float(vals[1])


def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    vals[1] = eval(vals[1])
    if isinstance(vals[1], int) or isinstance(vals[1], float):
      return vals[0], [ float(x) for x in [float(vals[1])]*1000 ]
    elif isinstance(vals[1], list):
      return vals[0], [ float(x) for x in vals[1] ]
    else:
      raise TypeError("Only strings that evaluate to integers, floats and lists are allowed")

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

cutout_debug = False
padargs = {}

max_size_cuts_replace_overview = False

overview_weight = "[1]*1000"

#random bucket pow or set??
smallcut_size = 0
smallcut_p = 0.35
mediumcut_size = 0.08
mediumcut_p = 0.5
largecut_size = 0.2
largecut_p = 0.7

use_bucketpow = False
use_rand_bucketpow = False

ceiling = 1.0

all_models_same_cuts = False

use_floor = False

adaptive_weight = False

cut_weight_multiplier = ""

manual_weight = False

jaxy_overviews = False

prompt_in_filename = False


def randbucketpow():
  rand = int(torch.rand([]))
  if rand <= smallcut_p:
    size_multiplier = smallcut_size
  elif rand <= mediumcut_p and rand > smallcut_p:
    size_multiplier = mediumcut_size
  elif rand <= largecut_p and rand > mediumcut_p:
    size_multiplier = largecut_size
  elif rand > largecut_p:
    size_multiplier = 2 
  return size_multiplier

class MakeCutoutsES(nn.Module):
    def __init__(self, cut_size, randoffsetx, randoffsety, randsize, randsize2,
                 Overview=4, InnerCrop = 0, IC_Size_Pow=0.5, IC_Grey = 0.2, overview_gray = 0.1, ov_proportion = 0.5, floor = 0.1, bucketcuts = 16
                 ):
        super().__init__()
        self.cut_size = cut_size
        self.Overview = Overview
        self.InnerCrop = InnerCrop
        self.IC_Size_Pow = IC_Size_Pow
        self.IC_Grey = IC_Grey
        self.overview_gray = overview_gray
        self.ov_proportion = ov_proportion
        self.floor = floor
        self.randoffsetx = randoffsetx
        self.randoffsety = randoffsety
        self.randsize = randsize
        self.randsize2 = randsize2
        self.bucketcuts = bucketcuts
        self.sizes = []


        if args.animation_mode == 'None':
          self.ic_augs = T.Compose([
                T.RandomHorizontalFlip(p=0.5),
                T.Lambda(lambda x: x - (pixel_jitter/2) + torch.randn_like(x) * pixel_jitter),
                T.ColorJitter(brightness=col_jitter, contrast=col_jitter, saturation=col_jitter, hue=col_jitter),
              ])
          tmpaugs = [
              T.Lambda(lambda x: x - (pixel_jitter/2) + torch.randn_like(x) * pixel_jitter),
              T.ColorJitter(brightness=col_jitter, contrast=col_jitter, saturation=col_jitter, hue=col_jitter),
          ]
          if (hflip ==True):
            tmpaugs.append(T.RandomHorizontalFlip(p=0.5))
          if (perspective == True):
            tmpaugs.append(T.RandomPerspective(distortion_scale=0.18, p=0.35))
          if (affine == True):
            tmpaugs.append(T.RandomAffine(degrees=degree_tilt, translate=(0.05, 0.05),  interpolation = T.InterpolationMode.BILINEAR))
          
          self.ov_augs = T.Compose(tmpaugs)

        elif args.animation_mode == 'Video Input':
          self.ov_augs = T.Compose([
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
          self.ic_augs = self.ov_augs
        elif  args.animation_mode == '2D' or args.animation_mode == '3D':
          self.ov_augs = T.Compose([
              T.RandomHorizontalFlip(p=0.4),
              T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
              T.RandomAffine(degrees=10, translate=(0.05, 0.05),  interpolation = T.InterpolationMode.BILINEAR),
              T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
              T.RandomGrayscale(p=0.1),
              T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
              T.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.3),
          ])
          self.ic_augs = self.ov_augs
          

    def forward(self, input):
        cutouts = []
        counter = 0
        gray = T.Grayscale(3)
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        floor_size = min_size + (max_size - min_size) * self.floor
        l_size = max(sideX, sideY)
        output_shape = [1,3,self.cut_size,self.cut_size] 
        output_shape_2 = [1,3,self.cut_size+2,self.cut_size+2]
        pad_input = F.pad(input,((sideY-max_size)//2,(sideY-max_size)//2,(sideX-max_size)//2,(sideX-max_size)//2), **padargs)
        cutout = resize(pad_input, out_shape=output_shape)
        bordery = ((sideY - max_size)//2)*2
        borderx = ((sideX - max_size)//2)*2
        border = int(((sideX*sideY)**0.5)*0.11)

        if use_bucketpow:
          for i in range(self.bucketcuts):
            if (i+1)/bucketcuts >= largecut_p:
              cutout = resize(pad_input, out_shape=output_shape)
              if (torch.rand([]) < self.overview_gray):
                cutout = gray(cutout)
            else:
              if (i+1)/bucketcuts <= smallcut_p:
                size = int(smallcut_size*(max_size - min_size) + min_size)
              elif (i+1)/bucketcuts <= mediumcut_p and (i+1)/bucketcuts > smallcut_p:
                size = int(mediumcut_size*(max_size - min_size) + min_size)
              elif (i+1)/bucketcuts < largecut_p and (i+1)/bucketcuts > mediumcut_p:
                size = int(largecut_size*(max_size - min_size) + min_size) 
              offsetx = int((self.randoffsetx[counter])*(sideX - size + 1))
              offsety = int((self.randoffsety[counter])*(sideY - size + 1))
              cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
              if (torch.rand([]) < self.IC_Grey):
                cutout = gray(cutout)
              cutout = resize(cutout, out_shape=output_shape)
            if not skip_augs:
              cutouts.append(self.ic_augs(cutout))
            else: 
              cutouts.append(cutout)
            counter += 1
            if adaptive_weight:
              self.sizes.append(max(sideX,sideY)**2)
            
        else:
          if self.Overview > 0:
            #cutout = resize(pad_input, out_shape=output_shape)
            for j in range(int(math.ceil(self.Overview*self.ov_proportion))):
                randborderx = int(self.randoffsetx[counter]*border)
                randbordery = int(self.randoffsety[counter]*border)
                if jaxy_overviews:
                  my_pad = F.pad(input,(math.ceil(bordery * self.randsize2[counter]) + 20 + math.ceil(randbordery * self.randsize[counter]),math.floor(bordery * (1 - self.randsize2[counter])) + 20 + math.floor((border - randbordery)*self.randsize[counter]),math.ceil(borderx * self.randsize2[counter]) + 20 + math.ceil(randborderx * self.randsize[counter]),math.floor(borderx * (1-self.randsize2[counter])) + 20 + math.floor((border - randborderx)*self.randsize[counter])), **padargs)
                  cutout = resize(my_pad, out_shape=output_shape)
                elif jaxy_overviews2:
                  my_pad = F.pad(input,((sideY-max_size)//2 + 20 + math.ceil(randbordery * self.randsize[counter]),(sideY-max_size)//2 + 20 + math.floor((90 - randbordery)*self.randsize[counter]),(sideX-max_size)//2 + 20 + math.ceil(randborderx * self.randsize[counter]),(sideX-max_size)//2 + 20 + math.floor((90 - randborderx)*self.randsize[counter])), **padargs)
                  cutout = resize(my_pad, out_shape=output_shape)
                elif zoom_out_overviews:
                  my_pad = F.pad(input,((sideY-max_size)//2 + 10 + math.ceil(border * self.randsize[counter]),(sideY-max_size)//2 + 10 + math.floor(border*self.randsize[counter]),(sideX-max_size)//2 + 10 + math.ceil(border * self.randsize[counter]),(sideX-max_size)//2 + 10 + math.floor(border*self.randsize[counter])), **padargs) 
                  cutout = resize(my_pad, out_shape=output_shape)
                else:
                  cutout = resize(pad_input, out_shape=output_shape)
                if (torch.rand([]) < self.overview_gray):
                    cutout = gray(cutout)
                if not skip_augs:
                    cutouts.append(self.ov_augs(cutout))
                else: 
                    cutouts.append(cutout)
                counter += 1
                if adaptive_weight:
                  self.sizes.append(max(sideX,sideY)**2)
            for k in range(int(math.floor(self.Overview*(1-self.ov_proportion)))):
              if (self.randsize[counter] < 0.8):
                size = max_size
              else:
                size = int((max_size - min_size)*0.7 + min_size)
              offsetx = int((self.randoffsetx[counter])*(sideX - size + 1))
              offsety = int((self.randoffsety[counter])*(sideY - size + 1))
              cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
              if (torch.rand([]) < self.overview_gray):
                  cutout = gray(cutout)
              cutout = resize(cutout, out_shape=output_shape)
              if not skip_augs:
                  cutouts.append(self.ic_augs(cutout))
              else: 
                  cutouts.append(cutout)
              counter += 1
              if adaptive_weight:
                self.sizes.append(size**2)

            if cutout_debug:
                if is_colab:
                    TF.to_pil_image(cutouts[0].clamp(0, 1).squeeze(0)).save("/content/cutout_overview0.jpg",quality=99)
                else:
                    TF.to_pil_image(cutouts[0].clamp(0, 1).squeeze(0)).save("cutout_overview0.jpg",quality=99)

                                
          if self.InnerCrop >0:
              for i in range(self.InnerCrop):
                  if use_floor:
                    size = int(self.randsize[counter]**self.IC_Size_Pow * ceiling * (max_size - floor_size) + floor_size)
                  else:
                    size = int(self.randsize[counter]**self.IC_Size_Pow * ceiling * (max_size - min_size) + min_size)  
                  offsetx = int((self.randoffsetx[counter])*(sideX - size + 1))
                  offsety = int((self.randoffsety[counter])*(sideY - size + 1))
                  cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
                  if (torch.rand([]) < self.IC_Grey):
                      cutout = gray(cutout)
                  cutout = resize(cutout, out_shape=output_shape)
                  if not skip_augs:
                      cutouts.append(self.ic_augs(cutout))
                  else: 
                      cutouts.append(cutout)
                  counter += 1
                  if adaptive_weight:
                    self.sizes.append(size**2)

              if cutout_debug:
                  if is_colab:
                      TF.to_pil_image(cutouts[-1].clamp(0, 1).squeeze(0)).save("/content/cutout_InnerCrop.jpg",quality=99)
                  else:
                      TF.to_pil_image(cutouts[-1].clamp(0, 1).squeeze(0)).save("cutout_InnerCrop.jpg",quality=99)
        cutouts = torch.cat(cutouts)
        return cutouts

def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)     

def symm_loss(im,lpm):
    h = int(im.shape[3]/2)
    h1,h2 = im[:,:,:,:h],im[:,:,:,h:]
    h2 = TF.hflip(h2)
    return lpm(h1,h2) 

def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])

def range_loss(input):
    return (input - input.clamp(-1, 1)).pow(2).mean([1, 2, 3])

stop_on_next_loop = False  # Make sure GPU memory doesn't get corrupted from cancelling the run mid-way through, allow a full frame to complete
TRANSLATION_SCALE = 1.0/200.0

def do_3d_step(img_filepath, frame_num, midas_model, midas_transform):
  if args.key_frames:
    translation_x = args.translation_x_series[frame_num]
    translation_y = args.translation_y_series[frame_num]
    translation_z = args.translation_z_series[frame_num]
    rotation_3d_x = args.rotation_3d_x_series[frame_num]
    rotation_3d_y = args.rotation_3d_y_series[frame_num]
    rotation_3d_z = args.rotation_3d_z_series[frame_num]
    print(
        f'translation_x: {translation_x}',
        f'translation_y: {translation_y}',
        f'translation_z: {translation_z}',
        f'rotation_3d_x: {rotation_3d_x}',
        f'rotation_3d_y: {rotation_3d_y}',
        f'rotation_3d_z: {rotation_3d_z}',
    )

  translate_xyz = [-translation_x*TRANSLATION_SCALE, translation_y*TRANSLATION_SCALE, -translation_z*TRANSLATION_SCALE]
  rotate_xyz_degrees = [rotation_3d_x, rotation_3d_y, rotation_3d_z]
  print('translation:',translate_xyz)
  print('rotation:',rotate_xyz_degrees)
  rotate_xyz = [math.radians(rotate_xyz_degrees[0]), math.radians(rotate_xyz_degrees[1]), math.radians(rotate_xyz_degrees[2])]
  rot_mat = p3dT.euler_angles_to_matrix(torch.tensor(rotate_xyz, device=device), "XYZ").unsqueeze(0)
  print("rot_mat: " + str(rot_mat))
  next_step_pil = dxf.transform_image_3d(img_filepath, midas_model, midas_transform, DEVICE,
                                          rot_mat, translate_xyz, args.near_plane, args.far_plane,
                                          args.fov, padding_mode=args.padding_mode,
                                          sampling_mode=args.sampling_mode, midas_weight=args.midas_weight)
  return next_step_pil

def symmetry_transformation_fn(x):
    if args.use_horizontal_symmetry:
        [n, c, h, w] = x.size()
        x = torch.concat((x[:, :, :, :w//2], torch.flip(x[:, :, :, :w//2], [-1])), -1)
        print("horizontal symmetry applied")
    if args.use_vertical_symmetry:
        [n, c, h, w] = x.size()
        x = torch.concat((x[:, :, :h//2, :], torch.flip(x[:, :, :h//2, :], [-2])), -2)
        print("vertical symmetry applied")
    return x

def resize_transformation_fn(image):
  if args.resize_mid_run:
    image = resize(image, out_shape=[1,3,newy,newx])
    side_x = newx
    side_y = newy
  return image

def do_run():
  seed = args.seed
  print(range(args.start_frame, args.max_frames))

  if (args.animation_mode == "3D") and (args.midas_weight > 0.0):
      midas_model, midas_transform, midas_net_w, midas_net_h, midas_resize_mode, midas_normalization = init_midas_depth_model(args.midas_depth_model)
  for frame_num in range(args.start_frame, args.max_frames):
      if stop_on_next_loop:
        break
      
      #display.clear_output(wait=True)

      # Print Frame progress if animation mode is on
      """
      if args.animation_mode != "None":
        batchBar = tqdm(range(args.max_frames), desc ="Frames")
        batchBar.n = frame_num
        batchBar.refresh()
      """
      
      # Inits if not video frames
      if args.animation_mode != "Video Input":
        if args.init_image in ['','none', 'None', 'NONE']:
          init_image = None
        else:
          init_image = args.init_image
        init_scale = args.init_scale
        skip_steps = args.skip_steps

      if args.animation_mode == "2D":
        if args.key_frames:
          angle = args.angle_series[frame_num]
          zoom = args.zoom_series[frame_num]
          translation_x = args.translation_x_series[frame_num]
          translation_y = args.translation_y_series[frame_num]
          print(
              f'angle: {angle}',
              f'zoom: {zoom}',
              f'translation_x: {translation_x}',
              f'translation_y: {translation_y}',
          )
        
        if frame_num > 0:
          seed += 1
          if resume_run and frame_num == start_frame:
            img_0 = cv2.imread(batchFolder+f"/{batch_name}({batchNum})_{start_frame-1:04}.png")
          else:
            img_0 = cv2.imread('prevFrame.png')
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

          cv2.imwrite('prevFrameScaled.png', img_0)
          init_image = 'prevFrameScaled.png'
          init_scale = args.frames_scale
          skip_steps = args.calc_frames_skip_steps

      if args.animation_mode == "3D":
        if frame_num > 0:
          seed += 1    
          if resume_run and frame_num == start_frame:
            img_filepath = batchFolder+f"/{batch_name}({batchNum})_{start_frame-1:04}.png"
            if turbo_mode and frame_num > turbo_preroll:
              shutil.copyfile(img_filepath, 'oldFrameScaled.png')
          else:
            img_filepath = '/content/prevFrame.png' if is_colab else 'prevFrame.png'

          next_step_pil = do_3d_step(img_filepath, frame_num, midas_model, midas_transform)
          next_step_pil.save('prevFrameScaled.png')

          ### Turbo mode - skip some diffusions, use 3d morph for clarity and to save time
          if turbo_mode:
            if frame_num == turbo_preroll: #start tracking oldframe
              next_step_pil.save('oldFrameScaled.png')#stash for later blending          
            elif frame_num > turbo_preroll:
              #set up 2 warped image sequences, old & new, to blend toward new diff image
              old_frame = do_3d_step('oldFrameScaled.png', frame_num, midas_model, midas_transform)
              old_frame.save('oldFrameScaled.png')
              if frame_num % int(turbo_steps) != 0: 
                print('turbo skip this frame: skipping clip diffusion steps')
                filename = f'{args.batch_name}({args.batchNum})_{frame_num:04}.png'
                blend_factor = ((frame_num % int(turbo_steps))+1)/int(turbo_steps)
                print('turbo skip this frame: skipping clip diffusion steps and saving blended frame')
                newWarpedImg = cv2.imread('prevFrameScaled.png')#this is already updated..
                oldWarpedImg = cv2.imread('oldFrameScaled.png')
                blendedImage = cv2.addWeighted(newWarpedImg, blend_factor, oldWarpedImg,1-blend_factor, 0.0)
                cv2.imwrite(f'{batchFolder}/{filename}',blendedImage)
                next_step_pil.save(f'{img_filepath}') # save it also as prev_frame to feed next iteration
                ######################################################################
                #Save next VoC FRAnnnnn.PNG frame file
                ######################################################################
                file_list = []
                for file in os.listdir(args3.frame_dir):
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
                voc_frame_filename = args3.frame_dir+"\FRA"+count_string+".png"
                cv2.imwrite(voc_frame_filename,blendedImage)
                sys.stdout.write(f'DEBUG SAVE 1 - VOC FRAME SAVED AS {voc_frame_filename}\n')
                sys.stdout.flush()
                ######################################################################
                if vr_mode:
                  generate_eye_views(TRANSLATION_SCALE,batchFolder,filename,frame_num,midas_model, midas_transform)
                continue
              else:
                #if not a skip frame, will run diffusion and need to blend.
                oldWarpedImg = cv2.imread('prevFrameScaled.png')
                cv2.imwrite(f'oldFrameScaled.png',oldWarpedImg)#swap in for blending later 
                print('clip/diff this frame - generate clip diff image')

          init_image = 'prevFrameScaled.png'
          init_scale = args.frames_scale
          skip_steps = args.calc_frames_skip_steps

      if  args.animation_mode == "Video Input":
        init_scale = args.video_init_frames_scale
        skip_steps = args.calc_frames_skip_steps
        if not video_init_seed_continuity:
          seed += 1
        if video_init_flow_warp:
          if frame_num == 0: 
            skip_steps = args.video_init_skip_steps
            init_image = f'{videoFramesFolder}/{frame_num+1:04}.jpg'
          if frame_num > 0: 
            prev = PIL.Image.open(batchFolder+f"/{batch_name}({batchNum})_{frame_num-1:04}.png")
            
            frame1_path = f'{videoFramesFolder}/{frame_num:04}.jpg'
            frame2 = PIL.Image.open(f'{videoFramesFolder}/{frame_num+1:04}.jpg')
            flo_path = f"/{flo_folder}/{frame1_path.split('/')[-1]}.npy"
            
            init_image = 'warped.png'
            print(video_init_flow_blend)
            weights_path = None
            if video_init_check_consistency:
                # TBD
                pass
 
            warp(prev, frame2, flo_path, blend=video_init_flow_blend, weights_path=weights_path).save(init_image)
            
        else:
          init_image = f'{videoFramesFolder}/{frame_num+1:04}.jpg'


      loss_values = []
  
      if seed is not None:
          np.random.seed(seed)
          random.seed(seed)
          torch.manual_seed(seed)
          torch.cuda.manual_seed_all(seed)
          torch.backends.cudnn.deterministic = True
  
      target_embeds, weights = [], []
      

      if args.prompts_series is not None and frame_num >= len(args.prompts_series):
        frame_prompt = args.prompts_series[-1]
      elif args.prompts_series is not None:
        frame_prompt = args.prompts_series[frame_num]
      else:
        frame_prompt = []
      
      print(args.image_prompts_series)
      if args.image_prompts_series is not None and frame_num >= len(args.image_prompts_series):
        image_prompt = args.image_prompts_series[-1]
      elif args.image_prompts_series is not None:
        image_prompt = args.image_prompts_series[frame_num]
      else:
        image_prompt = []

      print(f'Frame {frame_num} Prompt: {frame_prompt}')

      model_stats = []
      temp_weight = []
      for clip_model in clip_models:
            model_stat = {"clip_model":None,"target_embeds":[],"make_cutouts":None,"weights":[]}
            model_stat["clip_model"] = clip_model
            
            for prompt in frame_prompt:
                txt, weight = parse_prompt(prompt)
                txt = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()
                
                if args.fuzzy_prompt:
                    for i in range(25):
                        model_stat["target_embeds"].append((txt + torch.randn(txt.shape).cuda() * args.rand_mag).clamp(0,1))
                        model_stat["weights"].append(weight)
                else:
                    model_stat["target_embeds"].append(txt)
                    model_stat["weights"].append(weight)
        
            if image_prompt:
              randomx = torch.rand(16)
              randomy = torch.rand(16)
              randomsize = torch.rand(16)
              randomsize2 = torch.rand(16)
              model_stat["make_cutouts"] = MakeCutoutsES(clip_model.visual.input_resolution,
                            randoffsetx = randomx,
                            randoffsety = randomy,
                            randsize = randomsize,
                            randsize2 = randomsize2,
                            Overview = 8, 
                            InnerCrop = 8,
                            bucketcuts = 0,
                            IC_Size_Pow=0.24,
                            IC_Grey = 0.0,
                            overview_gray = 0.0,
                            ov_proportion = 1.0,
                            floor = 0.0) 
              for prompt in image_prompt:
                  path, weight = parse_prompt(prompt)
                  img = Image.open(fetch(path)).convert('RGB')
                  img = TF.resize(img, min(side_x, side_y, *img.size), T.InterpolationMode.LANCZOS)
                  batch = model_stat["make_cutouts"](TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
                  #passes = 4
                  #total = model_stat["make_cutouts"](TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
                  #for i in range(passes):
                    #batch = model_stat["make_cutouts"](TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
                    #total = total + batch
                  #embed = clip_model.encode_image(normalize(total)).float()
                  embed = clip_model.encode_image(normalize(batch)).float()
                  if fuzzy_prompt:
                      for i in range(25):
                          model_stat["target_embeds"].append((embed + torch.randn(embed.shape).cuda() * rand_mag).clamp(0,1))
                          weights.extend([weight / 16] * 16)
                  else:
                      model_stat["target_embeds"].append(embed)
                      model_stat["weights"].extend([weight / 16] * 16)
        
            model_stat["target_embeds"] = torch.cat(model_stat["target_embeds"])
            # model_stat["weights"] = torch.tensor(model_stat["weights"], device=device)
            # if model_stat["weights"].sum().abs() < 1e-3:
            #     raise RuntimeError('The weights must not sum to 0.')
            # model_stat["weights"] /= model_stat["weights"].sum().abs()
            model_stats.append(model_stat)
  
      init = None
      if init_image is not None:
          init = Image.open(fetch(init_image)).convert('RGB')
          init = init.resize((args.side_x, args.side_y), Image.LANCZOS)
          init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
      
      if args.perlin_init:
          if args.perlin_mode == 'color':
              init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
              init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, False)
          elif args.perlin_mode == 'gray':
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
              x_is_NaN = False
              x = x.detach().requires_grad_()
              n = x.shape[0]
              t_int = int(t.item()) + 1
              if args.use_secondary_model[1000-t_int] is True:
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
              for i in range(args.cutn_batches[1000 - t_int]):
              #for i in range(args.cutn_batches):
                randomx = torch.rand((args.cut_overview[1000-t_int]+args.cut_innercut[1000-t_int]))
                randomy = torch.rand((args.cut_overview[1000-t_int]+args.cut_innercut[1000-t_int]))
                randomsize = torch.rand((args.cut_overview[1000-t_int]+args.cut_innercut[1000-t_int]))
                randomsize2 = torch.rand((args.cut_overview[1000-t_int]+args.cut_innercut[1000-t_int]))
                for model_stat in model_stats:
                 #errors on last step without +1, need to find source
                    #when using SLIP Base model the dimensions need to be hard coded to avoid AttributeError: 'VisionTransformer' object has no attribute 'input_resolution'
                    try:
                        input_resolution=model_stat["clip_model"].visual.input_resolution
                    except:
                        input_resolution=224

                    cuts = MakeCutoutsES(input_resolution,
                            randoffsetx = randomx,
                            randoffsety = randomy,
                            randsize = randomsize,
                            randsize2 = randomsize2,
                            Overview = args.cut_overview[1000-t_int], 
                            InnerCrop = args.cut_innercut[1000-t_int],
                            bucketcuts = args.bucket_cuts,
                            IC_Size_Pow=args.cut_ic_pow[1000-t_int],
                            IC_Grey = args.ic_gray_p[1000-t_int],
                            overview_gray = args.ov_gray_p[1000-t_int],
                            ov_proportion = args.percent_overview[1000-t_int],
                            floor = args.floor_size[1000-t_int]
                            )
                    
                    clip_in = normalize(cuts(x_in.add(1).div(2)))
                    image_embeds = model_stat["clip_model"].encode_image(clip_in).float()
                    dists = spherical_dist_loss(image_embeds.unsqueeze(1), model_stat["target_embeds"].unsqueeze(0))
                    if (use_bucketpow or use_rand_bucketpow):
                      dists = dists.view([args.bucket_cuts, n, -1])
                    else:
                      dists = dists.view([args.cut_overview[1000-t_int]+args.cut_innercut[1000-t_int], n, -1])
                    if manual_weight and not (use_bucketpow or use_rand_bucketpow):
                      dists[:args.cut_overview[1000-t_int]] *= args.overview_weight[1000-t_int]
                    elif adaptive_weight:
                      normalizer = 0
                      if (use_bucketpow or use_rand_bucketpow):
                        for i in range(args.bucket_cuts):
                          dists[i] *= (cuts.sizes[i]/(224**2))**(args.cut_weight_multiplier[1000-t_int])
                          normalizer += (cuts.sizes[i]/(224**2))**(args.cut_weight_multiplier[1000-t_int])
                      else:
                        for i in range((args.cut_innercut[1000-t_int])+(args.cut_overview[1000-t_int])):
                          dists[i] *= (cuts.sizes[i]/(224**2))**(args.cut_weight_multiplier[1000-t_int]) #maybe should make clip_model size? but also maybe better to give greater weight to bigger models
                          normalizer += (cuts.sizes[i]/(224**2))**(args.cut_weight_multiplier[1000-t_int])
                    
                    step_weights = []
                    for i in range(0, len(model_stat["weights"])):
                      step_weights += [model_stat["weights"][i][1000-t_int]]
                      
                    if np.absolute(np.sum(step_weights)) < 1e-3: raise RuntimeError('The weights must not sum to 0.')
                    step_weights_divisor = np.absolute(np.sum(step_weights))
                    step_weights = [item / step_weights_divisor for item in step_weights]
                    step_weights = torch.tensor(step_weights, device=device)

                    #losses = dists.mul(model_stat["weights"]).sum(2).mean(0)
                    losses = dists.mul(step_weights).sum(2).mean(0)
                    if manual_weight and not (use_bucketpow or use_rand_bucketpow):
                      if normalizeloss:
                        losses = losses/(((args.cut_overview[1000-t_int])*(args.overview_weight[1000-t_int])+(args.cut_innercut[1000-t_int]))/((args.cut_innercut[1000-t_int])+(args.cut_overview[1000-t_int])))
                    elif adaptive_weight:
                      if (use_bucketpow or use_rand_bucketpow):
                        losses = losses/(normalizer/args.bucket_cuts)         
                      else:             
                        losses = losses/(normalizer/((args.cut_innercut[1000-t_int])+(args.cut_overview[1000-t_int])))
                    loss_values.append(losses.sum().item()) # log loss, probably shouldn't do per cutn_batch
                    x_in_grad += torch.autograd.grad(losses.sum() * args.clip_guidance_scale[1000 - t_int], x_in)[0] / args.cutn_batches[1000 - t_int]
              #range_losses = range_loss(out['pred_xstart'])
              sat_losses = torch.abs(x_in - x_in.clamp(min=-1,max=1)).mean()
              if not args.use_secondary_model[1000-t_int]:      
                tv_losses = tv_loss(x_in)
                if range_scale != 0:
                    range_losses = range_loss(out['pred_xstart'])
                    loss = tv_losses.sum() * tv_scale + range_losses.sum() * range_scale + sat_losses.sum() * sat_scale
                else:
                  loss = tv_losses.sum() * tv_scale + sat_losses.sum() * sat_scale
              else:
                loss = sat_losses.sum() * sat_scale
              if (init is not None and init_scale and perlin_init is False):
                  init_losses = lpips_model(x_in, init)
                  loss = loss + init_losses.sum() * init_scale
              if args.symmetry_loss and np.array(t.cpu())[0] > 10*args.symm_switch:
                  sloss = symm_loss(x_in,lpips_model)
                  loss = loss + sloss.sum() * args.sloss_scale
              x_in_grad += torch.autograd.grad(loss, x_in)[0]
              if torch.isnan(x_in_grad).any()==False:
                  grad = -torch.autograd.grad(x_in, x, x_in_grad)[0]
              else:
                # print("NaN'd")
                x_is_NaN = True
                grad = torch.zeros_like(x)
          if args.clamp_grad and x_is_NaN == False:
              magnitude = grad.square().mean().sqrt()
              return grad * magnitude.clamp(max=args.clamp_max[1000 - t_int]) / magnitude  #min=-0.02, min=-clamp_max, 
          return grad      

      if args.diffusion_sampling_mode == 'ddim':
          sample_fn = diffusion.ddim_sample_loop_progressive
      elif args.diffusion_sampling_mode == 'plms':
          sample_fn = diffusion.plms_sample_loop_progressive
      elif args.diffusion_sampling_mode == 'iplms':
          sample_fn = diffusion.iplms_sample_loop_progressive
      elif args.diffusion_sampling_mode == 'plms-ddim':
          sample_fn = diffusion.PLMS_to_DDIM_sample_loop_progressive
      elif args.diffusion_sampling_mode == 'iplms-ddim':
          sample_fn = diffusion.IPLMS_to_DDIM_sample_loop_progressive

      image_display = Output()
      for i in range(args.n_batches):
          #if args.animation_mode == 'None':
            #display.clear_output(wait=True)
            #batchBar = tqdm(range(args.n_batches), desc ="Batches")
            #batchBar.n = i
            #batchBar.refresh()
          print('')
          #display.display(image_display)
          #gc.collect()
          torch.cuda.empty_cache()
          cur_t = diffusion.num_timesteps - skip_steps - 1
          total_steps = cur_t

          if perlin_init:
              init = regen_perlin()

          if args.diffusion_sampling_mode == 'ddim':
              samples = sample_fn(
                  model,
                  (batch_size, 3, side_y, side_x),
                  clip_denoised=clip_denoised,
                  model_kwargs={},
                  cond_fn=cond_fn,
                  progress=True,
                  skip_timesteps=skip_steps,
                  init_image=init,
                  randomize_class=randomize_class,
                  eta=eta,
                  transformation_fn=resize_transformation_fn,
                  transformation_percent=args.transformation_percent
              )
          elif args.diffusion_sampling_mode == 'plms':
              samples = sample_fn(
                  model,
                  (batch_size, 3, side_y, side_x),
                  clip_denoised=clip_denoised,
                  model_kwargs={},
                  cond_fn=cond_fn,
                  progress=True,
                  skip_timesteps=skip_steps,
                  init_image=init,
                  randomize_class=randomize_class,
                  order=2,
              )
          elif args.diffusion_sampling_mode == 'iplms':
              samples = sample_fn(
                  model,
                  (batch_size, 3, side_y, side_x),
                  clip_denoised=clip_denoised,
                  model_kwargs={},
                  cond_fn=cond_fn,
                  progress=True,
                  skip_timesteps=skip_steps,
                  init_image=init,
                  randomize_class=randomize_class,
                  order=2,
              )
          else:
              samples = sample_fn(
                  model,
                  (batch_size, 3, side_y, side_x),
                  clip_denoised=clip_denoised,
                  model_kwargs={},
                  cond_fn=cond_fn,
                  progress=True,
                  switch_timestep=switch_timestep,
                  skip_timesteps=skip_steps,
                  init_image=init,
                  randomize_class=randomize_class,
                  order=2,
              )
          
          ######################################################################
          # Work out the VoC FRAnnnnn.PNG filename for this frame
          ######################################################################
          if args3.frame_dir != None:
            file_list = []
            for file in os.listdir(args3.frame_dir):
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
            voc_frame_filename = args3.frame_dir+"\FRA"+count_string+".png"
            sys.stdout.write(f'DEBUG VOC FRAME FILENAME FOR THIS FRAME IS {voc_frame_filename}\n')
            sys.stdout.flush()
            ######################################################################

          # with run_display:
          # display.clear_output(wait=True)
          itt = 0
          
          for j, sample in enumerate(samples):    
            sys.stdout.write(f'Iteration {itt}\n')
            sys.stdout.flush()
            itt+=1

            cur_t -= 1
            intermediateStep = False
            if args.steps_per_checkpoint is not None:
                if j % steps_per_checkpoint == 0 and j > 0:
                  intermediateStep = True
            elif j in args.intermediate_saves:
              intermediateStep = True
            with image_display:
              if j % args.display_rate == 0 or cur_t == -1 or intermediateStep == True:
                  if prompt_in_filename:
                    tempname = str(frame_prompt[0])
                    tempname = tempname.replace(" ", "_")
                    name = tempname[:42]
                  else:
                    name = args.batch_name
                  for k, image in enumerate(sample['pred_xstart']):
                      # tqdm.write(f'Batch {i}, step {j}, output {k}:')
                      current_time = datetime.now().strftime('%y%m%d-%H%M%S_%f')
                      percent = math.ceil(j/total_steps*100)
                      if args.n_batches > 0:
                        #if intermediates are saved to the subfolder, don't append a step or percentage to the name
                        if cur_t == -1 and args.intermediates_in_subfolder is True:
                          save_num = f'{frame_num:04}' if animation_mode != "None" else i
                          filename = f'{name}({args.batchNum})_{save_num}.png'
                        else:
                          #If we're working with percentages, append it
                          if args.steps_per_checkpoint is not None:
                            filename = f'{name}({args.batchNum})_{i:04}-{percent:02}%.png'
                          # Or else, iIf we're working with specific steps, append those
                          else:
                            filename = f'{name}({args.batchNum})_{i:04}.png'
                      image = TF.to_pil_image(image.add(1).div(2).clamp(0, 1))
                      if j % args.display_rate == 0 or cur_t == -1:
                        sys.stdout.flush()
                        sys.stdout.write('Saving progress ...\n')
                        sys.stdout.flush()

                        #image.save('progress.png')
                        #display.clear_output(wait=True)
                        #display.display(display.Image('progress.png'))

                        image.save(args3.image_file)
                        
                        #save image updates as movie frames
                        if args3.save_updates_as_frames == 1:
                            file_list = []
                            for file in os.listdir(args3.frame_dir):
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
                            voc_frame_filename = args3.frame_dir+"\FRA"+count_string+".png"
                            image.save(voc_frame_filename)
                        
                        sys.stdout.flush()
                        sys.stdout.write('Progress saved\n')
                        sys.stdout.flush()
                        
                      if args.steps_per_checkpoint is not None:
                        if j % args.steps_per_checkpoint == 0 and j > 0:
                          if args.intermediates_in_subfolder is True:
                            image.save(f'{partialFolder}/{filename}')
                          else:
                            image.save(f'{batchFolder}/{filename}')

                            #Save next VoC FRAnnnnn.PNG frame file
                            shutil.copyfile(f'{batchFolder}/{filename}',voc_frame_filename)
                      else:
                        if j in args.intermediate_saves:
                          if args.intermediates_in_subfolder is True:
                            image.save(f'{partialFolder}/{filename}')
                          else:
                            image.save(f'{batchFolder}/{filename}')

                            #Save next VoC FRAnnnnn.PNG frame file
                            shutil.copyfile(f'{batchFolder}/{filename}',voc_frame_filename)
                      if cur_t == -1:
                        """
                        if frame_num == 0:
                          try:
                            save_settings()
                          except:
                            print('Could not save settings, oh well...')
                        """
                        if args.animation_mode != "None":
                          image.save('prevFrame.png')
                        image.save(f'{batchFolder}/{filename}')
                        
                        #Save next VoC FRAnnnnn.PNG frame file
                        if args3.frame_dir != None: shutil.copyfile(f'{batchFolder}/{filename}',voc_frame_filename)

                        
                        if args.animation_mode == "None":
                          print('Incrementing seed by one.')
                          seed = seed + 1
                          np.random.seed(seed)
                          random.seed(seed)
                          torch.manual_seed(seed)
                          torch.cuda.manual_seed_all(seed)
                          torch.backends.cudnn.deterministic = True
                        
                        if args.animation_mode == "3D":
                          # If turbo, save a blended image
                          if turbo_mode and frame_num > 0:
                            # Mix new image with prevFrameScaled
                            blend_factor = (1)/int(turbo_steps)
                            newFrame = cv2.imread('prevFrame.png') # This is already updated..
                            prev_frame_warped = cv2.imread('prevFrameScaled.png')
                            blendedImage = cv2.addWeighted(newFrame, blend_factor, prev_frame_warped, (1-blend_factor), 0.0)
                            cv2.imwrite(f'{batchFolder}/{filename}',blendedImage)

                            #Save next VoC FRAnnnnn.PNG frame file
                            shutil.copyfile(f'{batchFolder}/{filename}',voc_frame_filename)

                          else:
                            image.save(f'{batchFolder}/{filename}')

                            #Save next VoC FRAnnnnn.PNG frame file
                            shutil.copyfile(f'{batchFolder}/{filename}',voc_frame_filename)

                          if vr_mode:
                            generate_eye_views(TRANSLATION_SCALE, batchFolder, filename, frame_num, midas_model, midas_transform)

                        # if frame_num != args.max_frames-1:
                        #   display.clear_output()
          
          plt.plot(np.array(loss_values), 'r')

def generate_eye_views(trans_scale,batchFolder,filename,frame_num,midas_model, midas_transform):
   for i in range(2):
      theta = vr_eye_angle * (math.pi/180)
      ray_origin = math.cos(theta) * vr_ipd / 2 * (-1.0 if i==0 else 1.0)
      ray_rotation = (theta if i==0 else -theta)
      translate_xyz = [-(ray_origin)*trans_scale, 0,0]
      rotate_xyz = [0, (ray_rotation), 0]
      rot_mat = p3dT.euler_angles_to_matrix(torch.tensor(rotate_xyz, device=device), "XYZ").unsqueeze(0)
      transformed_image = dxf.transform_image_3d(f'{batchFolder}/{filename}', midas_model, midas_transform, DEVICE,
                                                      rot_mat, translate_xyz, args.near_plane, args.far_plane,
                                                      args.fov, padding_mode=args.padding_mode,
                                                      sampling_mode=args.sampling_mode, midas_weight=args.midas_weight,spherical=True)
      eye_file_path = batchFolder+f"/frame_{frame_num:04}" + ('_l' if i==0 else '_r')+'.png'
      transformed_image.save(eye_file_path)

def save_settings():
    setting_list = {
      'text_prompts': text_prompts,
      'image_prompts': image_prompts,
      'clip_guidance_scale': str(clip_guidance_scale),
      'tv_scale': tv_scale,
      'range_scale': range_scale,
      'sat_scale': sat_scale,
      'symmetry_loss':symmetry_loss,
      'sloss_scale':symm_loss_scale,
      'symm_switch':symm_switch,
      'cutn_batches': str(cutn_batches),
      'max_frames': max_frames,
      'interp_spline': interp_spline,
      'init_image': init_image,
      'init_scale': init_scale,
      'skip_steps': skip_steps,
      'frames_scale': frames_scale,
      'frames_skip_steps': frames_skip_steps,
      'perlin_init': perlin_init,
      'perlin_mode': perlin_mode,
      'skip_augs': skip_augs,
      'randomize_class': randomize_class,
      'clip_denoised': clip_denoised,
      'clamp_grad': clamp_grad,
      'clamp_max': str(clamp_max),
      'seed': seed,
      'fuzzy_prompt': fuzzy_prompt,
      'rand_mag': rand_mag,
      'eta': eta,
      'width': width_height[0],
      'height': width_height[1],
      'diffusion_model': diffusion_model,
      'use_secondary_model': str(use_secondary_model),
      'steps': steps,
      'diffusion_steps': diffusion_steps,
      'diffusion_sampling_mode': diffusion_sampling_mode,
      'ViTB32': ViTB32,
      'ViTB16': ViTB16,
      'ViTL14': ViTL14,
      'ViTL14_336px': ViTL14_336px,
      'RN101': RN101,
      'RN50': RN50,
      'RN50x4': RN50x4,
      'RN50x16': RN50x16,
      'RN50x64': RN50x64,
      'ViTB32_laion2b_e16': ViTB32_laion2b_e16,
      'ViTB32_laion400m_e31': ViTB32_laion400m_e31,
      'ViTB32_laion400m_32': ViTB32_laion400m_32,
      'ViTB32quickgelu_laion400m_e31': ViTB32quickgelu_laion400m_e31,
      'ViTB32quickgelu_laion400m_e32': ViTB32quickgelu_laion400m_e32,
      'ViTB16_laion400m_e31': ViTB16_laion400m_e31,
      'ViTB16_laion400m_e32': ViTB16_laion400m_e32,
      'RN50_yffcc15m': RN50_yffcc15m,
      'RN50_cc12m': RN50_cc12m,
      'RN50_quickgelu_yfcc15m': RN50_quickgelu_yfcc15m,
      'RN50_quickgelu_cc12m': RN50_quickgelu_cc12m,
      'RN101_yfcc15m': RN101_yfcc15m,
      'RN101_quickgelu_yfcc15m': RN101_quickgelu_yfcc15m,
      'cut_overview': str(cut_overview),
      'cut_innercut': str(cut_innercut),
      'cut_ic_pow': str(cut_ic_pow),
      'cut_icgray_p': str(ic_gray_p),
      'ov_gray': str(ov_gray_p),
      'percent_overview': str(percent_overview),
      'overview_weight': str(overview_weight),
      'floor': str(floor_size),
      'user_floor': use_floor,
      'adaptive_weight': adaptive_weight,
      'cut_weight_multiplier': str(cut_weight_multiplier),
      'ceiling': ceiling,
      'all_models_same_cuts': all_models_same_cuts,
      'use_floor': use_floor,
      'key_frames': key_frames,
      'max_frames': max_frames,
      'angle': angle,
      'zoom': zoom,
      'translation_x': translation_x,
      'translation_y': translation_y,
      'translation_z': translation_z,
      'rotation_3d_x': rotation_3d_x,
      'rotation_3d_y': rotation_3d_y,
      'rotation_3d_z': rotation_3d_z,
      'midas_depth_model': midas_depth_model,
      'midas_weight': midas_weight,
      'near_plane': near_plane,
      'far_plane': far_plane,
      'fov': fov,
      'padding_mode': padding_mode,
      'sampling_mode': sampling_mode,
      'video_init_path':video_init_path,
      'extract_nth_frame':extract_nth_frame,
      'video_init_seed_continuity': video_init_seed_continuity,
      'turbo_mode':turbo_mode,
      'turbo_steps':turbo_steps,
      'turbo_preroll':turbo_preroll,
      'use_horizontal_symmetry':use_horizontal_symmetry,
      'use_vertical_symmetry':use_vertical_symmetry,
      'transformation_percent':transformation_percent,
      #video init settings
      'video_init_steps': video_init_steps,
      'video_init_clip_guidance_scale': video_init_clip_guidance_scale,
      'video_init_tv_scale': video_init_tv_scale,
      'video_init_range_scale': video_init_range_scale,
      'video_init_sat_scale': video_init_sat_scale,
      'video_init_cutn_batches': video_init_cutn_batches,
      'video_init_skip_steps': video_init_skip_steps,
      'video_init_frames_scale': video_init_frames_scale,
      'video_init_frames_skip_steps': video_init_frames_skip_steps,
      #warp settings
      'video_init_flow_warp':video_init_flow_warp,
      'video_init_flow_blend':video_init_flow_blend,
      'video_init_check_consistency':video_init_check_consistency,
      'video_init_blend_mode':video_init_blend_mode
    }
    # print('Settings:', setting_list)
    with open(f"{batchFolder}/{batch_name}({batchNum})_settings.txt", "w+", encoding="utf-8") as f:   #save settings
        json.dump(setting_list, f, ensure_ascii=False, indent=4)

#@title 1.6 Define the secondary diffusion model

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

"""# 2. Diffusion and CLIP model settings"""

#@markdown ####**Models Settings (note: For pixel art, the best is pixelartdiffusion_expanded):**
diffusion_model = args3.diffusion_model #"512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100", "portrait_generator_v001", "pixelartdiffusion_expanded", "pixel_art_diffusion_hard_256", "pixel_art_diffusion_soft_256", "pixelartdiffusion4k", "watercolordiffusion_2", "watercolordiffusion", "PulpSciFiDiffusion", "custom"]

use_secondary_model = args3.use_secondary_model #"[False]*400+[False]*600" #@param {type: 'string'}
diffusion_sampling_mode = args3.diffusion_sampling_mode #'ddim' #@param ['ddim','plms','iplms','plms-ddim','iplms-ddim']
switch_timestep = args3.switch_timestep #80 #@param {type:'integer'}

#switch_timestep =  89#@param{type: 'raw'}
#@markdown #####**Custom model:**
custom_path = args3.custom_path #'/content/drive/MyDrive/deep_learning/ddpm/ema_0.9999_058000.pt'#@param {type: 'string'}

#@markdown #####**CLIP settings:**
if args3.use_checkpoint == 1:
    use_checkpoint = True #@param {type: 'boolean'}
else:
    use_checkpoint = False #@param {type: 'boolean'}

if args3.ViTB32 == 1:
    ViTB32 = True #@param{type:"boolean"}
else:
    ViTB32 = False #@param{type:"boolean"}

if args3.ViTB16 == 1:
    ViTB16 = True #@param{type:"boolean"}
else:
    ViTB16 = False #@param{type:"boolean"}

if args3.ViTL14 == 1:
    ViTL14 = True #@param{type:"boolean"}
else:
    ViTL14 = False #@param{type:"boolean"}

if args3.ViTL14_336 == 1:
    ViTL14_336px = True #@param{type:"boolean"}
else:
    ViTL14_336px = False #@param{type:"boolean"}

if args3.RN101 == 1:
    RN101 = True #@param{type:"boolean"}
else:
    RN101 = False #@param{type:"boolean"}

if args3.RN50 == 1:
    RN50 = True #@param{type:"boolean"}
else:
    RN50 = False #@param{type:"boolean"}

if args3.RN50x4 == 1:
    RN50x4 = True #@param{type:"boolean"}
else:
    RN50x4 = False #@param{type:"boolean"}

if args3.RN50x16 == 1:
    RN50x16 = True #@param{type:"boolean"}
else:
    RN50x16 = False #@param{type:"boolean"}

if args3.RN50x64 == 1:
    RN50x64 = True #@param{type:"boolean"}
else:
    RN50x64 = False #@param{type:"boolean"}

#@markdown #####**OpenCLIP settings:** openclip models can still be used, but have been commented out to take less space
if args3.ViTB32_laion2b_e16 == 1:
    ViTB32_laion2b_e16 = True #@param{type:"boolean"}
else:
    ViTB32_laion2b_e16 = False #@param{type:"boolean"}

if args3.ViTB32_laion400m_e31 == 1:
    ViTB32_laion400m_e31 = True #@param{type:"boolean"}
else:
    ViTB32_laion400m_e31 = False #@param{type:"boolean"}

if args3.ViTB32_laion400m_32 == 1:
    ViTB32_laion400m_32 = True #@param{type:"boolean"}
else:
    ViTB32_laion400m_32 = False #@param{type:"boolean"}

if args3.ViTB32quickgelu_laion400m_e31 == 1:
    ViTB32quickgelu_laion400m_e31 = True #@param{type:"boolean"}
else:
    ViTB32quickgelu_laion400m_e31 = False #@param{type:"boolean"}

if args3.ViTB32quickgelu_laion400m_e32 == 1:
    ViTB32quickgelu_laion400m_e32 = True #@param{type:"boolean"}
else:
    ViTB32quickgelu_laion400m_e32 = False #@param{type:"boolean"}

if args3.ViTB16_laion400m_e31 == 1:
    ViTB16_laion400m_e31 = True #@param{type:"boolean"}
else:
    ViTB16_laion400m_e31 = False #@param{type:"boolean"}

if args3.ViTB16_laion400m_e32 == 1:
    ViTB16_laion400m_e32 = True #@param{type:"boolean"}
else:
    ViTB16_laion400m_e32 = False #@param{type:"boolean"}

if args3.RN50_yffcc15m == 1:
    RN50_yffcc15m = True #@param{type:"boolean"}
else:
    RN50_yffcc15m = False #@param{type:"boolean"}

if args3.RN50_cc12m == 1:
    RN50_cc12m = True #@param{type:"boolean"}
else:
    RN50_cc12m = False #@param{type:"boolean"}

if args3.RN50_quickgelu_yfcc15m == 1:
    RN50_quickgelu_yfcc15m = True #@param{type:"boolean"}
else:
    RN50_quickgelu_yfcc15m = False #@param{type:"boolean"}

if args3.RN50_quickgelu_cc12m == 1:
    RN50_quickgelu_cc12m = True #@param{type:"boolean"}
else:
    RN50_quickgelu_cc12m = False #@param{type:"boolean"}

if args3.RN101_yfcc15m == 1:
    RN101_yfcc15m = True #@param{type:"boolean"}
else:
    RN101_yfcc15m = False #@param{type:"boolean"}

if args3.RN101_quickgelu_yfcc15m == 1:
    RN101_quickgelu_yfcc15m = True #@param{type:"boolean"}
else:
    RN101_quickgelu_yfcc15m = False #@param{type:"boolean"}


VITL14open = False #param{type:"boolean"}
VITH14open = False #param{type:"boolean"}
VITG14open = False #param{type:"boolean"}

#@markdown If you're having issues with model downloads, check this to compare SHA's:
check_model_SHA = False #@param{type:"boolean"}

"""
diff_model_map = {
    '256x256_diffusion_uncond': { 'downloaded': False, 'sha': 'a37c32fffd316cd494cf3f35b339936debdc1576dad13fe57c42399a5dbc78b1', 'uri_list': ['https://openaipublic.blob.core.windows.net/diffusion/jul-2021/256x256_diffusion_uncond.pt', 'https://www.dropbox.com/s/9tqnqo930mpnpcn/256x256_diffusion_uncond.pt'] },
    '512x512_diffusion_uncond_finetune_008100': { 'downloaded': False, 'sha': '9c111ab89e214862b76e1fa6a1b3f1d329b1a88281885943d2cdbe357ad57648', 'uri_list': ['https://huggingface.co/lowlevelware/512x512_diffusion_unconditional_ImageNet/resolve/main/512x512_diffusion_uncond_finetune_008100.pt', 'https://the-eye.eu/public/AI/models/512x512_diffusion_unconditional_ImageNet/512x512_diffusion_uncond_finetune_008100.pt'] },
    'portrait_generator_v001': { 'downloaded': False, 'sha': 'b7e8c747af880d4480b6707006f1ace000b058dd0eac5bb13558ba3752d9b5b9', 'uri_list': ['https://huggingface.co/felipe3dartist/portrait_generator_v001/resolve/main/portrait_generator_v001_ema_0.9999_1MM.pt'] },
    'pixelartdiffusion_expanded': { 'downloaded': False, 'sha': 'a73b40556634034bf43b5a716b531b46fb1ab890634d854f5bcbbef56838739a', 'uri_list': ['https://huggingface.co/KaliYuga/PADexpanded/resolve/main/PADexpanded.pt'] },
    'pixel_art_diffusion_hard_256': { 'downloaded': False, 'sha': 'be4a9de943ec06eef32c65a1008c60ad017723a4d35dc13169c66bb322234161', 'uri_list': ['https://huggingface.co/KaliYuga/pixel_art_diffusion_hard_256/resolve/main/pixel_art_diffusion_hard_256.pt'] },
    'pixel_art_diffusion_soft_256': { 'downloaded': False, 'sha': 'd321590e46b679bf6def1f1914b47c89e762c76f19ab3e3392c8ca07c791039c', 'uri_list': ['https://huggingface.co/KaliYuga/pixel_art_diffusion_soft_256/resolve/main/pixel_art_diffusion_soft_256.pt'] },
    'pixelartdiffusion4k': { 'downloaded': False, 'sha': 'a1ba4f13f6dabb72b1064f15d8ae504d98d6192ad343572cc416deda7cccac30', 'uri_list': ['https://huggingface.co/KaliYuga/pixelartdiffusion4k/resolve/main/pixelartdiffusion4k.pt'] },
    'watercolordiffusion_2': { 'downloaded': False, 'sha': '49c281b6092c61c49b0f1f8da93af9b94be7e0c20c71e662e2aa26fee0e4b1a9', 'uri_list': ['https://huggingface.co/KaliYuga/watercolordiffusion_2/resolve/main/watercolordiffusion_2.pt'] },
    'watercolordiffusion': { 'downloaded': False, 'sha': 'a3e6522f0c8f278f90788298d66383b11ac763dd5e0d62f8252c962c23950bd6', 'uri_list': ['https://huggingface.co/KaliYuga/watercolordiffusion/resolve/main/watercolordiffusion.pt'] },
    'PulpSciFiDiffusion': { 'downloaded': False, 'sha': 'b79e62613b9f50b8a3173e5f61f0320c7dbb16efad42a92ec94d014f6e17337f', 'uri_list': ['https://huggingface.co/KaliYuga/PulpSciFiDiffusion/resolve/main/PulpSciFiDiffusion.pt'] },
    'secondary': { 'downloaded': False, 'sha': '983e3de6f95c88c81b2ca7ebb2c217933be1973b1ff058776b970f901584613a', 'uri_list': ['https://huggingface.co/spaces/huggi/secondary_model_imagenet_2.pth/resolve/main/secondary_model_imagenet_2.pth', 'https://the-eye.eu/public/AI/models/v-diffusion/secondary_model_imagenet_2.pth', 'https://ipfs.pollinations.ai/ipfs/bafybeibaawhhk7fhyhvmm7x24zwwkeuocuizbqbcg5nqx64jq42j75rdiy/secondary_model_imagenet_2.pth'] },
}

kaliyuga_pixel_art_model_names = ['pixelartdiffusion_expanded', 'pixel_art_diffusion_hard_256', 'pixel_art_diffusion_soft_256', 'pixelartdiffusion4k', 'PulpSciFiDiffusion']
kaliyuga_watercolor_model_names = ['watercolordiffusion', 'watercolordiffusion_2']
kaliyuga_pulpscifi_model_names = ['PulpSciFiDiffusion']
diffusion_models_256x256_list = ['256x256_diffusion_uncond'] + kaliyuga_pixel_art_model_names + kaliyuga_watercolor_model_names + kaliyuga_pulpscifi_model_names
"""

from urllib.parse import urlparse

def get_model_filename(diffusion_model_name):
    #model_uri = diff_model_map[diffusion_model_name]['uri_list'][0]
    #model_filename = os.path.basename(urlparse(model_uri).path)
    model_filename = diffusion_model_name+'.pt'
    return model_filename

"""
def download_model(diffusion_model_name, uri_index=0):
    if diffusion_model_name != 'custom':
        model_filename = get_model_filename(diffusion_model_name)
        model_local_path = os.path.join(model_path, model_filename)
        if os.path.exists(model_local_path) and check_model_SHA:
            print(f'Checking {diffusion_model_name} File')
            with open(model_local_path, "rb") as f:
                bytes = f.read() 
                hash = hashlib.sha256(bytes).hexdigest()
            if hash == diff_model_map[diffusion_model_name]['sha']:
                print(f'{diffusion_model_name} SHA matches')
                diff_model_map[diffusion_model_name]['downloaded'] = True
            else:
                print(f"{diffusion_model_name} SHA doesn't match. Will redownload it.")
        elif os.path.exists(model_local_path) and not check_model_SHA or diff_model_map[diffusion_model_name]['downloaded']:
            print(f'{diffusion_model_name} already downloaded. If the file is corrupt, enable check_model_SHA.')
            diff_model_map[diffusion_model_name]['downloaded'] = True

        if not diff_model_map[diffusion_model_name]['downloaded']:
            for model_uri in diff_model_map[diffusion_model_name]['uri_list']:
                wget(model_uri, model_path)
                if os.path.exists(model_local_path):
                    diff_model_map[diffusion_model_name]['downloaded'] = True
                    return
                else:
                    print(f'{diffusion_model_name} model download from {model_uri} failed. Will try any fallback uri.')
            print(f'{diffusion_model_name} download failed.')


# Download the diffusion model(s)
# download_model(diffusion_model)
if "True" in use_secondary_model:
    download_model('secondary')

model_config = model_and_diffusion_defaults()
if diffusion_model == '512x512_diffusion_uncond_finetune_008100':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': not useCPU,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == '256x256_diffusion_uncond':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': not useCPU,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'portrait_generator_v001':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
else:  # E.g. A model finetuned by KaliYuga
    model_config.update({
          'attention_resolutions': '16',
          'class_cond': False,
          'diffusion_steps': 1000,
          'rescale_timesteps': True,
          'timestep_respacing': 'ddim100',
          'image_size': 256,
          'learn_sigma': True,
          'noise_schedule': 'linear',
          'num_channels': 128,
          'num_heads': 1,
          'num_res_blocks': 2,
          'use_checkpoint': use_checkpoint,
          'use_fp16': True,
          'use_scale_shift_norm': False,
      })
"""

if diffusion_model != 'custom_256x256' and diffusion_model != 'custom_512x512' :
    from os.path import exists
    if not exists(diffusion_model+'.pt'):
        sys.stdout.write(f"Custom diffusion model {diffusion_model} not found\n")
        sys.stdout.flush()
    else:
        sys.stdout.write(f"Using custom diffusion model {diffusion_model}.pt\n")
        sys.stdout.flush()

model_config = model_and_diffusion_defaults()
if diffusion_model == '512x512_diffusion_uncond_finetune_008100':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': not useCPU,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == '256x256_diffusion_uncond':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': not useCPU,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'architecture':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'comics_faces':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'deep_space':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
     })     
elif diffusion_model == 'fantasy':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'floral':
  model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })      
elif diffusion_model == 'great_magazine_art':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })    
elif diffusion_model == 'handpainted':
    model_config.update({
        'attention_resolutions': '32,16,8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,  
    })
elif diffusion_model == 'isometric':
  model_config.update({
        'attention_resolutions': '32,16,8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'liminal_spaces':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'liminal_source':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'lithography':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
   })
elif diffusion_model == 'medieval_art':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'nes_160k':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'nes_350k':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'nes_200k':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'ngpx2022':
  model_config.update({
      'attention_resolutions': '32, 16, 8',
      'class_cond': False,
      'rescale_timesteps': True,
      'image_size': 256,
      'learn_sigma': True,
      'noise_schedule': 'linear',
      'num_channels': 256,
      'num_head_channels': 64,
      'num_res_blocks': 2,
      'resblock_updown': True,
      'use_checkpoint': use_checkpoint,
      'use_fp16': True,
      'use_scale_shift_norm': True,
  })
elif diffusion_model == "paintpour_v1.0":
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': not useCPU,
        'use_scale_shift_norm': True,
  })
elif diffusion_model.startswith("paintpour_v1."):
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000, #No need to edit this, it is taken care of later.
        'rescale_timesteps': True,
        'timestep_respacing': 250, #No need to edit this, it is taken care of later.
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
  })
elif diffusion_model.startswith("pixelart"):
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
  })
elif diffusion_model == 'portrait_generator_v1':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'portrait_generator_v1_5':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'portrait_diffusion_v2':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'portrait_diffusion_v2_5':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'pulp_scifi':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'retro_movie_posters':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'simpsons':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
     })
elif diffusion_model == 'textiles':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
     })
elif diffusion_model == 'ukiyoe_portraits':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'watercolor':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
   })
elif diffusion_model == 'watercolor_2':
    model_config.update({
        'attention_resolutions': '16',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 1,
        'num_res_blocks': 2,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': False,
    })
elif diffusion_model == 'custom_256x256':
    # settings for a model not specified above
    # these settings are used when the user selects "custom" for diffusion_model and specifies a custom_path to their own model.pt file
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == 'custom_512x512':
    # settings for a model not specified above
    # these settings are used when the user selects "custom" for diffusion_model and specifies a custom_path to their own model.pt file
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
else:
    # settings for a model not specified above
    # these settings are used when the user selects "custom" for diffusion_model and specifies a custom_path to their own model.pt file
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': 1000,
        'rescale_timesteps': True,
        'timestep_respacing': 'ddim100',
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 128,
        'num_heads': 4,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint': use_checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })

model_default = model_config['image_size']

if "True" in use_secondary_model:
    secondary_model = SecondaryDiffusionImageNet2()
    secondary_model.load_state_dict(torch.load(f'{model_path}/secondary_model_imagenet_2.pth', map_location='cpu'))
    secondary_model.eval().requires_grad_(False).to(device)

clip_models = []
if ViTB32: clip_models.append(clip.load('ViT-B/32', jit=False)[0].eval().requires_grad_(False).to(device))
if ViTB16: clip_models.append(clip.load('ViT-B/16', jit=False)[0].eval().requires_grad_(False).to(device))
if ViTL14: clip_models.append(clip.load('ViT-L/14', jit=False)[0].eval().requires_grad_(False).to(device))
if ViTL14_336px: clip_models.append(clip.load('ViT-L/14@336px', jit=False)[0].eval().requires_grad_(False).to(device))
if RN50: clip_models.append(clip.load('RN50', jit=False)[0].eval().requires_grad_(False).to(device))
if RN50x4: clip_models.append(clip.load('RN50x4', jit=False)[0].eval().requires_grad_(False).to(device))
if RN50x16: clip_models.append(clip.load('RN50x16', jit=False)[0].eval().requires_grad_(False).to(device))
if RN50x64: clip_models.append(clip.load('RN50x64', jit=False)[0].eval().requires_grad_(False).to(device))
if RN101: clip_models.append(clip.load('RN101', jit=False)[0].eval().requires_grad_(False).to(device))

normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)

"""# Custom model settings 
Modify in accordance with your training settings and run the cell
"""

#@markdown ####**Custom Model Settings:**
if diffusion_model == 'custom':
  model_config.update({
          'attention_resolutions': '16',
          'class_cond': False,
          'diffusion_steps': 1000,
          'rescale_timesteps': True,
          'timestep_respacing': 'ddim100',
          'image_size': 256,
          'learn_sigma': True,
          'noise_schedule': 'linear',
          'num_channels': 128,
          'num_heads': 1,
          'num_res_blocks': 2,
          'use_checkpoint': use_checkpoint,
          'use_fp16': True,
          'use_scale_shift_norm': False,
      })

"""# 3. Settings"""

side_x = args3.sizex;
side_y = args3.sizey;

#@markdown ####**Basic Settings:**
batch_name = args3.batch_name #'MathRock' #@param{type: 'string'}
prompt_in_filename = False#@param{type:'boolean'}
steps = args3.iterations #250 #@param [25,50,100,150,250,500,1000]{type: 'raw', allow-input: true}
width_height = [args3.sizex, args3.sizey] #@param{type: 'raw'}
clip_guidance_scale = args3.clip_guidance_scale #"[10000]*1000" #@param{type: 'string'}
tv_scale = args3.tv_scale #59000#@param{type: 'number'}
#@markdown setting range_scale to 0 now disables it (as it is not known to currently work), this appears to save a pinch of time
range_scale = args3.range_scale #0#@param{type: 'number'}
sat_scale = args3.sat_scale #20500#@param{type: 'number'}
cutn_batches = args3.cutn_batches #"[3]*1000" #str(args3.cutn_batches) #"[3]*1000"#@param{type: 'string'}
if args3.skip_augs == 1:
    skip_augs = True#@param{type: 'boolean'}
else:
    skip_augs = False#@param{type: 'boolean'}



#@markdown ---

"""
#Get corrected sizes
side_x = (width_height[0]//64)*64;
side_y = (width_height[1]//64)*64;
if side_x != width_height[0] or side_y != width_height[1]:
    print(f'Changing output size to {side_x}x{side_y}. Dimensions must by multiples of 64.')
"""

#Update Model Settings
timestep_respacing = f'ddim{steps}'
diffusion_steps = (1000//steps)*steps if steps < 1000 else steps
model_config.update({
    'timestep_respacing': timestep_respacing,
    'diffusion_steps': diffusion_steps,
})


#Make folder for batch
batchFolder = f'{outDirPath}/{batch_name}'
createPath(batchFolder)

#markdown ###**resize mid run**
resize_mid_run = False#param{type:'boolean'}
transformation_percent = [0.3]#param
newx = 768#param{type:'number'}
newy = 960#param{type:'number'}

"""### Animation Settings"""

#@markdown ####**Animation Mode:**
animation_mode = args3.animation_mode #'None' #@param ['None', '2D', '3D', 'Video Input'] {type:'string'}
#@markdown *For animation, you probably want to turn `cutn_batches` to 1 to make it quicker.*

#@markdown ####**Video Init Basic Settings:**
video_init_steps = args3.video_init_steps #100 #@param [25,50,100,150,250,500,1000]{type: 'raw', allow-input: true}
video_init_clip_guidance_scale = args3.video_init_clip_guidance_scale #1000 #@param{type: 'number'}
video_init_tv_scale = args3.video_init_tv_scale #0.1#@param{type: 'number'}
video_init_range_scale = args3.video_init_range_scale #150#@param{type: 'number'}
video_init_sat_scale = args3.video_init_sat_scale #300#@param{type: 'number'}
video_init_cutn_batches = args3.video_init_cutn_batches #4#@param{type: 'number'}
video_init_skip_steps = args3.video_init_skip_steps #50 #@param{type: 'integer'}


#@markdown ---

#@markdown ####**Video Input Settings:**
video_init_path = args3.video_init_path
extract_nth_frame = args3.extract_nth_frame #2 #@param {type: 'number'}

if args3.persistent_frame_output_in_batch_folder == 1:
    persistent_frame_output_in_batch_folder = True #True #@param {type: 'boolean'}
else:
    persistent_frame_output_in_batch_folder = False #True #@param {type: 'boolean'}
if args3.video_init_seed_continuity == 1:
    video_init_seed_continuity = True #False #@param {type: 'boolean'}
else:
    video_init_seed_continuity = False #False #@param {type: 'boolean'}

#@markdown #####**Video Optical Flow Settings:**
if args3.video_init_flow_warp == 1:
    video_init_flow_warp = True #@param {type: 'boolean'}
else:
    video_init_flow_warp = False #@param {type: 'boolean'}
# Call optical flow from video frames and warp prev frame with flow
video_init_flow_blend =  0.999#@param {type: 'number'} #0 - take next frame, 1 - take prev warped frame
video_init_check_consistency = False #Insert param here when ready
video_init_blend_mode = "optical flow" #@param ['None', 'linear', 'optical flow']

if args3.video_init_flow_warp == 1:
    video_init_flow_warp = True #@param {type: 'boolean'}
else:
    video_init_flow_warp = True #@param {type: 'boolean'}
# Call optical flow from video frames and warp prev frame with flow
video_init_flow_blend = args3.video_init_flow_blend # 0.999#@param {type: 'number'} #0 - take next frame, 1 - take prev warped frame
if args3.video_init_check_consistency == 1:
    video_init_check_consistency = True #False #Insert param here when ready
else:
    video_init_check_consistency = False #False #Insert param here when ready
video_init_blend_mode = args3.video_init_blend_mode #"optical flow" #@param ['None', 'linear', 'optical flow']










# Call optical flow from video frames and warp prev frame with flow
if animation_mode == "Video Input":
    if persistent_frame_output_in_batch_folder or (not is_colab): #suggested by Chris the Wizard#8082 at discord
        videoFramesFolder = f'{batchFolder}/videoFrames'
    else:
        videoFramesFolder = f'/content/videoFrames'
    createPath(videoFramesFolder)
    print(f"Exporting Video Frames (1 every {extract_nth_frame})...")
    try:
        for f in pathlib.Path(f'{videoFramesFolder}').glob('*.jpg'):
            f.unlink()
    except:
        print('')
    vf = f'select=not(mod(n\,{extract_nth_frame}))'
    if os.path.exists(video_init_path):
        subprocess.run(['ffmpeg', '-i', f'{video_init_path}', '-vf', f'{vf}', '-vsync', 'vfr', '-q:v', '2', '-loglevel', 'error', '-stats', f'{videoFramesFolder}/%04d.jpg'], stdout=subprocess.PIPE).stdout.decode('utf-8')
    else: 
        print(f'\nWARNING!\n\nVideo not found: {video_init_path}.\nPlease check your video path.\n')
    #!ffmpeg -i {video_init_path} -vf {vf} -vsync vfr -q:v 2 -loglevel error -stats {videoFramesFolder}/%04d.jpg


#@markdown ---

#@markdown ####**2D Animation Settings:**
#@markdown `zoom` is a multiplier of dimensions, 1 is no zoom.
#@markdown All rotations are provided in degrees.

if args3.key_frames == 1:
    key_frames = True #@param {type:"boolean"}
else:
    key_frames = False #@param {type:"boolean"}
max_frames = args3.max_frames #10000#@param {type:"number"}

if animation_mode == "Video Input":
    max_frames = len(glob(f'{videoFramesFolder}/*.jpg'))

interp_spline = 'Linear' #Do not change, currently will not look good. param ['Linear','Quadratic','Cubic']{type:"string"}

#VOC START - DO NOT DELETE
angle = "0:(0)"
zoom = "0:(1.01)"
translation_x = "0:(0)"
translation_y = "0:(0)"
translation_z = "0:(3)"
rotation_3d_x = "0:(0)"
rotation_3d_y = "0:(0)"
rotation_3d_z = "0:(0)"
#VOC FINISH - DO NOT DELETE

midas_depth_model = "dpt_large"#@param {type:"string"}

midas_weight = args3.midas_weight #0.3#@param {type:"number"}
near_plane = args3.near_plane #200#@param {type:"number"}
far_plane = args3.far_plane #10000#@param {type:"number"}
fov = args3.fov #40#@param {type:"number"}

padding_mode = 'border'#@param {type:"string"}
sampling_mode = 'bicubic'#@param {type:"string"}

#======= TURBO MODE
#@markdown ---
#@markdown ####**Turbo Mode (3D anim only):**
#@markdown (Starts after frame 10,) skips diffusion steps and just uses depth map to warp images for skipped frames.
#@markdown Speeds up rendering by 2x-4x, and may improve image coherence between frames.
#@markdown For different settings tuned for Turbo Mode, refer to the original Disco-Turbo Github: https://github.com/zippy731/disco-diffusion-turbo

if args3.turbo_mode == 1:
    turbo_mode = True #@param {type:"boolean"}
else:
    turbo_mode = False #@param {type:"boolean"}
turbo_steps = args3.turbo_steps #"3" #@param ["2","3","4","5","6"] {type:"string"}
turbo_preroll = args3.turbo_preroll #10 # frames


#insist turbo be used only w 3d anim.
if turbo_mode and animation_mode != '3D':
    print('=====')
    print('Turbo mode only available with 3D animations. Disabling Turbo.')
    print('=====')
    turbo_mode = False

#@markdown ---

#@markdown ####**Coherency Settings:**
#@markdown `frame_scale` tries to guide the new frame to looking like the old one. A good default is 1500.
frames_scale = 1500 #@param{type: 'integer'}
#@markdown `frame_skip_steps` will blur the previous frame - higher values will flicker less but struggle to add enough new detail to zoom into.
frames_skip_steps = '60%' #@param ['40%', '50%', '60%', '70%', '80%'] {type: 'string'}

#@markdown ####**Video Init Coherency Settings:**
#@markdown `frame_scale` tries to guide the new frame to looking like the old one. A good default is 1500.
frames_scale = args3.frames_scale #1500 #@param{type: 'integer'}
#@markdown `frame_skip_steps` will blur the previous frame - higher values will flicker less but struggle to add enough new detail to zoom into.
frames_skip_steps = args3.frames_skip_steps #'60%' #@param ['40%', '50%', '60%', '70%', '80%'] {type: 'string'}

#======= VR MODE
#@markdown ---
#@markdown ####**VR Mode (3D anim only):**
#@markdown Enables stereo rendering of left/right eye views (supporting Turbo) which use a different (fish-eye) camera projection matrix.   
#@markdown Note the images you're prompting will work better if they have some inherent wide-angle aspect
#@markdown The generated images will need to be combined into left/right videos. These can then be stitched into the VR180 format.
#@markdown Google made the VR180 Creator tool but subsequently stopped supporting it. It's available for download in a few places including https://www.patrickgrunwald.de/vr180-creator-download
#@markdown The tool is not only good for stitching (videos and photos) but also for adding the correct metadata into existing videos, which is needed for services like YouTube to identify the format correctly.
#@markdown Watching YouTube VR videos isn't necessarily the easiest depending on your headset. For instance Oculus have a dedicated media studio and store which makes the files easier to access on a Quest https://creator.oculus.com/manage/mediastudio/
#@markdown 
#@markdown The command to get ffmpeg to concat your frames for each eye is in the form: `ffmpeg -framerate 15 -i frame_%4d_l.png l.mp4` (repeat for r)

if args3.vr_mode == 1:
    vr_mode = True #@param {type:"boolean"}
else:
    vr_mode = False #@param {type:"boolean"}
#@markdown `vr_eye_angle` is the y-axis rotation of the eyes towards the center
vr_eye_angle = args3.vr_eye_angle #0.5 #@param{type:"number"}
#@markdown interpupillary distance (between the eyes)
vr_ipd = args3.vr_ipd #5.0 #@param{type:"number"}


#insist VR be used only w 3d anim.
if vr_mode and animation_mode != '3D':
    print('=====')
    print('VR mode only available with 3D animations. Disabling VR.')
    print('=====')
    vr_mode = False


def parse_key_frames(string, prompt_parser=None):
    """Given a string representing frame numbers paired with parameter values at that frame,
    return a dictionary with the frame numbers as keys and the parameter values as the values.

    Parameters
    ----------
    string: string
        Frame numbers paired with parameter values at that frame number, in the format
        'framenumber1: (parametervalues1), framenumber2: (parametervalues2), ...'
    prompt_parser: function or None, optional
        If provided, prompt_parser will be applied to each string of parameter values.
    
    Returns
    -------
    dict
        Frame numbers as keys, parameter values at that frame number as values

    Raises
    ------
    RuntimeError
        If the input string does not match the expected format.
    
    Examples
    --------
    >>> parse_key_frames("10:(Apple: 1| Orange: 0), 20: (Apple: 0| Orange: 1| Peach: 1)")
    {10: 'Apple: 1| Orange: 0', 20: 'Apple: 0| Orange: 1| Peach: 1'}

    >>> parse_key_frames("10:(Apple: 1| Orange: 0), 20: (Apple: 0| Orange: 1| Peach: 1)", prompt_parser=lambda x: x.lower()))
    {10: 'apple: 1| orange: 0', 20: 'apple: 0| orange: 1| peach: 1'}
    """
    import re
    pattern = r'((?P<frame>[0-9]+):[\s]*[\(](?P<param>[\S\s]*?)[\)])'
    frames = dict()
    for match_object in re.finditer(pattern, string):
        frame = int(match_object.groupdict()['frame'])
        param = match_object.groupdict()['param']
        if prompt_parser:
            frames[frame] = prompt_parser(param)
        else:
            frames[frame] = param

    if frames == {} and len(string) != 0:
        raise RuntimeError('Key Frame string not correctly formatted')
    return frames

def get_inbetweens(key_frames, integer=False):
    """Given a dict with frame numbers as keys and a parameter value as values,
    return a pandas Series containing the value of the parameter at every frame from 0 to max_frames.
    Any values not provided in the input dict are calculated by linear interpolation between
    the values of the previous and next provided frames. If there is no previous provided frame, then
    the value is equal to the value of the next provided frame, or if there is no next provided frame,
    then the value is equal to the value of the previous provided frame. If no frames are provided,
    all frame values are NaN.

    Parameters
    ----------
    key_frames: dict
        A dict with integer frame numbers as keys and numerical values of a particular parameter as values.
    integer: Bool, optional
        If True, the values of the output series are converted to integers.
        Otherwise, the values are floats.
    
    Returns
    -------
    pd.Series
        A Series with length max_frames representing the parameter values for each frame.
    
    Examples
    --------
    >>> max_frames = 5
    >>> get_inbetweens({1: 5, 3: 6})
    0    5.0
    1    5.0
    2    5.5
    3    6.0
    4    6.0
    dtype: float64

    >>> get_inbetweens({1: 5, 3: 6}, integer=True)
    0    5
    1    5
    2    5
    3    6
    4    6
    dtype: int64
    """
    key_frame_series = pd.Series([np.nan for a in range(max_frames)])

    for i, value in key_frames.items():
        key_frame_series[i] = value
    key_frame_series = key_frame_series.astype(float)
    
    interp_method = interp_spline

    if interp_method == 'Cubic' and len(key_frames.items()) <=3:
      interp_method = 'Quadratic'
    
    if interp_method == 'Quadratic' and len(key_frames.items()) <= 2:
      interp_method = 'Linear'
      
    
    key_frame_series[0] = key_frame_series[key_frame_series.first_valid_index()]
    key_frame_series[max_frames-1] = key_frame_series[key_frame_series.last_valid_index()]
    # key_frame_series = key_frame_series.interpolate(method=intrp_method,order=1, limit_direction='both')
    key_frame_series = key_frame_series.interpolate(method=interp_method.lower(),limit_direction='both')
    if integer:
        return key_frame_series.astype(int)
    return key_frame_series

def split_prompts(prompts):
    prompt_series = pd.Series([np.nan for a in range(max_frames)])
    for i, prompt in prompts.items():
        prompt_series[i] = prompt
    # prompt_series = prompt_series.astype(str)
    prompt_series = prompt_series.ffill().bfill()
    return prompt_series

if key_frames:
    try:
        angle_series = get_inbetweens(parse_key_frames(angle))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `angle` correctly for key frames.\n"
            "Attempting to interpret `angle` as "
            f'"0: ({angle})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        angle = f"0: ({angle})"
        angle_series = get_inbetweens(parse_key_frames(angle))

    try:
        zoom_series = get_inbetweens(parse_key_frames(zoom))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `zoom` correctly for key frames.\n"
            "Attempting to interpret `zoom` as "
            f'"0: ({zoom})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        zoom = f"0: ({zoom})"
        zoom_series = get_inbetweens(parse_key_frames(zoom))

    try:
        translation_x_series = get_inbetweens(parse_key_frames(translation_x))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `translation_x` correctly for key frames.\n"
            "Attempting to interpret `translation_x` as "
            f'"0: ({translation_x})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        translation_x = f"0: ({translation_x})"
        translation_x_series = get_inbetweens(parse_key_frames(translation_x))

    try:
        translation_y_series = get_inbetweens(parse_key_frames(translation_y))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `translation_y` correctly for key frames.\n"
            "Attempting to interpret `translation_y` as "
            f'"0: ({translation_y})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        translation_y = f"0: ({translation_y})"
        translation_y_series = get_inbetweens(parse_key_frames(translation_y))

    try:
        translation_z_series = get_inbetweens(parse_key_frames(translation_z))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `translation_z` correctly for key frames.\n"
            "Attempting to interpret `translation_z` as "
            f'"0: ({translation_z})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        translation_z = f"0: ({translation_z})"
        translation_z_series = get_inbetweens(parse_key_frames(translation_z))

    try:
        rotation_3d_x_series = get_inbetweens(parse_key_frames(rotation_3d_x))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `rotation_3d_x` correctly for key frames.\n"
            "Attempting to interpret `rotation_3d_x` as "
            f'"0: ({rotation_3d_x})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        rotation_3d_x = f"0: ({rotation_3d_x})"
        rotation_3d_x_series = get_inbetweens(parse_key_frames(rotation_3d_x))

    try:
        rotation_3d_y_series = get_inbetweens(parse_key_frames(rotation_3d_y))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `rotation_3d_y` correctly for key frames.\n"
            "Attempting to interpret `rotation_3d_y` as "
            f'"0: ({rotation_3d_y})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        rotation_3d_y = f"0: ({rotation_3d_y})"
        rotation_3d_y_series = get_inbetweens(parse_key_frames(rotation_3d_y))

    try:
        rotation_3d_z_series = get_inbetweens(parse_key_frames(rotation_3d_z))
    except RuntimeError as e:
        print(
            "WARNING: You have selected to use key frames, but you have not "
            "formatted `rotation_3d_z` correctly for key frames.\n"
            "Attempting to interpret `rotation_3d_z` as "
            f'"0: ({rotation_3d_z})"\n'
            "Please read the instructions to find out how to use key frames "
            "correctly.\n"
        )
        rotation_3d_z = f"0: ({rotation_3d_z})"
        rotation_3d_z_series = get_inbetweens(parse_key_frames(rotation_3d_z))

else:
    angle = float(angle)
    zoom = float(zoom)
    translation_x = float(translation_x)
    translation_y = float(translation_y)
    translation_z = float(translation_z)
    rotation_3d_x = float(rotation_3d_x)
    rotation_3d_y = float(rotation_3d_y)
    rotation_3d_z = float(rotation_3d_z)

#@title Install RAFT for Video input animation mode only
#@markdown Run once per session. Doesn't download again if model path exists.
#@markdown Use force download to reload raft models if needed
force_download = False #@param {type:'boolean'}
if animation_mode == 'Video Input':
    try:
        from raft import RAFT
    except:
        if not os.path.exists(os.path.join(PROJECT_DIR, 'RAFT')):
            gitclone('https://github.com/princeton-vl/RAFT', os.path.join(PROJECT_DIR, 'RAFT'))
        sys.path.append(f'{PROJECT_DIR}/RAFT')

    if (not (os.path.exists(f'{root_path}/RAFT/models'))) or force_download:
        createPath(f'{root_path}/RAFT')
        os.chdir(f'{root_path}/RAFT')
        sub_p_res = subprocess.run(['bash', f'{PROJECT_DIR}/RAFT/download_models.sh'], stdout=subprocess.PIPE).stdout.decode('utf-8')
        print(sub_p_res)
        os.chdir(PROJECT_DIR)

#@title Define optical flow functions for Video input animation mode only
if animation_mode == 'Video Input':
    in_path = videoFramesFolder
    flo_folder = f'{in_path}/out_flo_fwd'
    path = f'{PROJECT_DIR}/RAFT/core'
    import sys
    sys.path.append(f'{PROJECT_DIR}/RAFT/core')
    """
    os.chdir(f'{PROJECT_DIR}/RAFT/core')
    print(os.getcwd())
  
    print("Renaming RAFT core's utils.utils to raftutils.utils (to avoid a naming conflict with AdaBins)")
    if not os.path.exists(f'{PROJECT_DIR}/RAFT/core/raftutils'):
        os.rename(f'{PROJECT_DIR}/RAFT/core/utils', f'{PROJECT_DIR}/RAFT/core/raftutils')
        sub_p_res = subprocess.run(['sed', '-i', 's/from utils.utils/from raftutils.utils/g', f'{PROJECT_DIR}/RAFT/core/corr.py'], stdout=subprocess.PIPE).stdout.decode('utf-8')
        sub_p_res = subprocess.run(['sed', '-i', 's/from utils.utils/from raftutils.utils/g', f'{PROJECT_DIR}/RAFT/core/raft.py'], stdout=subprocess.PIPE).stdout.decode('utf-8')
    """
    from raftutils.utils import InputPadder
    from raft import RAFT
    from raftutils import flow_viz
    import numpy as np
    import argparse, PIL, cv2
    from PIL import Image
    from tqdm.notebook import tqdm
    from glob import glob
    import torch
  
    args2 = argparse.Namespace()
    args2.small = False
    args2.mixed_precision = True
  
  
    TAG_CHAR = np.array([202021.25], np.float32)
  
    def writeFlow(filename,uv,v=None):
        """ 
        https://github.com/NVIDIA/flownet2-pytorch/blob/master/utils/flow_utils.py
        Copyright 2017 NVIDIA CORPORATION
  
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at
  
            http://www.apache.org/licenses/LICENSE-2.0
  
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
        
        Write optical flow to file.
        
        If v is None, uv is assumed to contain both u and v channels,
        stacked in depth.
        Original code by Deqing Sun, adapted from Daniel Scharstein.
        """
        nBands = 2
  
        if v is None:
            assert(uv.ndim == 3)
            assert(uv.shape[2] == 2)
            u = uv[:,:,0]
            v = uv[:,:,1]
        else:
            u = uv
  
        assert(u.shape == v.shape)
        height,width = u.shape
        f = open(filename,'wb')
        # write the header
        f.write(TAG_CHAR)
        np.array(width).astype(np.int32).tofile(f)
        np.array(height).astype(np.int32).tofile(f)
        # arrange into matrix form
        tmp = np.zeros((height, width*nBands))
        tmp[:,np.arange(width)*2] = u
        tmp[:,np.arange(width)*2 + 1] = v
        tmp.astype(np.float32).tofile(f)
        f.close()
  
    def load_img(img, size):
        img = Image.open(img).convert('RGB').resize(size)
        return torch.from_numpy(np.array(img)).permute(2,0,1).float()[None,...].cuda()
  
    def get_flow(frame1, frame2, model, iters=20):
        padder = InputPadder(frame1.shape)
        frame1, frame2 = padder.pad(frame1, frame2)
        _, flow12 = model(frame1, frame2, iters=iters, test_mode=True)
        flow12 = flow12[0].permute(1, 2, 0).detach().cpu().numpy()
  
        return flow12
  
    def warp_flow(img, flow):
        h, w = flow.shape[:2]
        flow = flow.copy()
        flow[:, :, 0] += np.arange(w)
        flow[:, :, 1] += np.arange(h)[:, np.newaxis]
        res = cv2.remap(img, flow, None, cv2.INTER_LINEAR)
        return res
  
    def makeEven(_x):
        return _x if (_x % 2 == 0) else _x+1
  
    def fit(img,maxsize=512):
        maxdim = max(*img.size)
        if maxdim>maxsize:
            # if True:
            ratio = maxsize/maxdim
            x,y = img.size
            size = (makeEven(int(x*ratio)),makeEven(int(y*ratio))) 
            img = img.resize(size)
        return img
  
    def warp(frame1, frame2, flo_path, blend=0.5, weights_path=None):
        flow21 = np.load(flo_path)
        frame1pil = np.array(frame1.convert('RGB').resize((flow21.shape[1],flow21.shape[0])))
        frame1_warped21 = warp_flow(frame1pil, flow21)
        # frame2pil = frame1pil
        frame2pil = np.array(frame2.convert('RGB').resize((flow21.shape[1],flow21.shape[0])))
    
        if weights_path:
            # TBD
            pass
        else:
            blended_w = frame2pil*(1-blend) + frame1_warped21*(blend)
  
        return  PIL.Image.fromarray(blended_w.astype('uint8'))
  
    in_path = videoFramesFolder
    flo_folder = f'{in_path}/out_flo_fwd'
  
    temp_flo = in_path+'/temp_flo'
    flo_fwd_folder = in_path+'/out_flo_fwd'
    # TBD flow backwards!
  
    os.chdir(PROJECT_DIR)

#@title Generate optical flow and consistency maps
#@markdown Run once per init video

if animation_mode == "Video Input":
    import gc

    if args3.force_flow_generation == 1:
        force_flow_generation = True #@param {type:'boolean'}
    else:
        force_flow_generation = False #@param {type:'boolean'}

    in_path = videoFramesFolder
    flo_folder = f'{in_path}/out_flo_fwd'

    if not video_init_flow_warp:
        print('video_init_flow_warp not set, skipping')

    if (animation_mode == 'Video Input') and (video_init_flow_warp):
        flows = glob(flo_folder+'/*.*')
        if (len(flows)>0) and not force_flow_generation:
            print(f'Skipping flow generation:\nFound {len(flows)} existing flow files in current working folder: {flo_folder}.\nIf you wish to generate new flow files, check force_flow_generation and run this cell again.')
    
        """
        #this is from 5.5 script - doesn;t work - using code from 5.4 below
        if (len(flows)==0) or force_flow_generation:
            frames = sorted(glob(in_path+'/*.*'));
            if len(frames)<2: 
                print(f'WARNING!\nCannot create flow maps: Found {len(frames)} frames extracted from your video input.\nPlease check your video path.')
            if len(frames)>=2:
        
                raft_model = torch.nn.DataParallel(RAFT(args2))
                raft_model.load_state_dict(torch.load(f'{root_path}/RAFT/models/raft-things.pth'))
                raft_model = raft_model.module.cuda().eval()
        
                for f in pathlib.Path(f'{flo_fwd_folder}').glob('*.*'):
                    f.unlink()
        
                temp_flo = in_path+'/temp_flo'
                flo_fwd_folder = in_path+'/out_flo_fwd'
        
                createPath(flo_fwd_folder)
                createPath(temp_flo)
        
                # TBD Call out to a consistency checker?
        
                framecount = 0
                for frame1, frame2 in tqdm(zip(frames[:-1], frames[1:]), total=len(frames)-1):
        
                    out_flow21_fn = f"{flo_fwd_folder}/{frame1.split('/')[-1]}"
            
                    frame1 = load_img(frame1, width_height)
                    frame2 = load_img(frame2, width_height)
            
                    flow21 = get_flow(frame2, frame1, raft_model)
                    np.save(out_flow21_fn, flow21)
            
                    if video_init_check_consistency:
                        # TBD
                        pass

                del raft_model 
                gc.collect()
        """
        
        if (len(flows)==0) or force_flow_generation:
            frames = sorted(glob(in_path+'/*.*'));
            if len(frames)<2: 
                print(f'WARNING!\nCannot create flow maps: Found {len(frames)} frames extracted from your video input.\nPlease check your video path.')
            if len(frames)>=2:
        
                sys.stdout.write(f'***DEBUG*** Video Input 03\n')
                sys.stdout.flush()

                raft_model = torch.nn.DataParallel(RAFT(args2))
                raft_model.load_state_dict(torch.load(f'{root_path}/RAFT/models/raft-things.pth'))
                raft_model = raft_model.module.cuda().eval()
        
                for f in pathlib.Path(f'{flo_fwd_folder}').glob('*.*'):
                    f.unlink()
        
                temp_flo = in_path+'/temp_flo'
                flo_fwd_folder = in_path+'/out_flo_fwd'
        
                sys.stdout.write(f'*** temp_flo = {temp_flo}\n')
                sys.stdout.write(f'*** flo_fwd_folder = {flo_fwd_folder}\n')

                createPath(flo_fwd_folder)
                createPath(temp_flo)
        
                cc_path = f'{root_path}/flow_tools/check_consistency.py'
        
                framecount = 0
                for frame1, frame2 in tqdm(zip(frames[:-1], frames[1:]), total=len(frames)-1):
        
                    frame1 = frame1.replace('\\','/')
                    frame2 = frame2.replace('\\','/')
        
                    sys.stdout.write(f'*** frame1 = {frame1}\n')
                    sys.stdout.write(f'*** frame2 = {frame2}\n')
                    sys.stdout.flush()

                    out_flow21_fn = f"{flo_fwd_folder}/{frame1.split('/')[-1]}"
            
                    frame1 = load_img(frame1, width_height)
                    frame2 = load_img(frame2, width_height)
            
                    flow21 = get_flow(frame2, frame1, raft_model)

                    sys.stdout.write(f'*** out_flow21_fn = {out_flow21_fn}\n')
                    sys.stdout.write(f'*** flow21 = {flow21}\n')
                    sys.stdout.flush()


                    np.save(out_flow21_fn, flow21)
            
                    if video_init_check_consistency:
                        flow12 = get_flow(frame1, frame2, raft_model)
                        np.save(out_flow21_fn+'_12', flow12.astype('float32'))
                        gc.collect()

                del raft_model 
                gc.collect()
                if video_init_check_consistency:
                    fwd = f"{flo_fwd_folder}/*jpg.npy"
                    bwd = f"{flo_fwd_folder}/*jpg_12.npy"
                    flocmd = f"python {cc_path} --flow_fwd {fwd} --flow_bwd {bwd} --output {flo_fwd_folder}/ --image_output --output_postfix=-21_cc"
                    sys.stdout.write(f'\n*** Executing check_consistency.py\n')
                    sys.stdout.write(f'{flocmd}\n')
                    os.system(flocmd)
                    sys.stdout.write(f'*** Finished executing check_consistency.py\n')
        
        
        
"""### Extra Settings
 Partial Saves, Advanced Settings, Cutn Scheduling
"""

#@markdown ####**Saving:**

intermediate_saves = 0#@param{type: 'raw'}
intermediates_in_subfolder = True #@param{type: 'boolean'}
#@markdown Intermediate steps will save a copy at your specified intervals. You can either format it as a single integer or a list of specific steps 

#@markdown A value of `2` will save a copy at 33% and 66%. 0 will save none.

#@markdown A value of `[5, 9, 34, 45]` will save at steps 5, 9, 34, and 45. (Make sure to include the brackets)


if type(intermediate_saves) is not list:
    if intermediate_saves:
        steps_per_checkpoint = math.floor((steps - skip_steps - 1) // (intermediate_saves+1))
        steps_per_checkpoint = steps_per_checkpoint if steps_per_checkpoint > 0 else 1
        print(f'Will save every {steps_per_checkpoint} steps')
    else:
        steps_per_checkpoint = steps+10
else:
    steps_per_checkpoint = None

if intermediate_saves and intermediates_in_subfolder is True:
    partialFolder = f'{batchFolder}/partials'
    createPath(partialFolder)

#@markdown ---

#@markdown ####**Advanced Settings:**
#@markdown *There are a few extra advanced settings available if you double click this cell.*

if args3.perlin_init == 1:
    perlin_init = True  #@param{type: 'boolean'}
else:
    perlin_init = False  #@param{type: 'boolean'}
perlin_mode = args3.perlin_mode #'mixed' #@param ['mixed', 'color', 'gray']

set_seed = args3.seed #'random_seed' #@param{type: 'string'}
eta = args3.eta #0.8#@param{type: 'number'}
if args3.clamp_grad == 1:
    clamp_grad = True #@param{type: 'boolean'}
else:
    clamp_grad = False #@param{type: 'boolean'}
clamp_max = args3.clamp_max #0.05 #@param{type: 'number'}



### EXTRA ADVANCED SETTINGS:
if args3.randomize_class == 1:
    randomize_class = True
else:
    randomize_class = False
if args3.clip_denoised == 1:
    clip_denoised = True
else:
    clip_denoised = False
if args3.fuzzy_prompt == 1:
    fuzzy_prompt = True
else:
    fuzzy_prompt = False
rand_mag = args3.rand_mag #0.05



#@markdown ---

#markdown ####**Transformation Settings:**
if args3.use_vertical_symmetry == 1:
    use_vertical_symmetry = True #@param {type:"boolean"}
else:
    use_vertical_symmetry = False #@param {type:"boolean"}
if args3.use_horizontal_symmetry == 1:
    use_horizontal_symmetry = True #@param {type:"boolean"}
else:
    use_horizontal_symmetry = False #@param {type:"boolean"}
#transformation_percent = [0.09] #param


#@markdown ####**Symmetry Settings:**
#@markdown *Enable symmetry_loss to mirror left/right side of image until step symm_switch.*

symmetry_loss = False#@param{type: 'boolean'}
symm_loss_scale =  2000#@param
symm_switch = 86#@param
symm_switch = 100.*(1. - (symm_switch/steps)) 
if symmetry_loss:
    print(f"Symmetry ends at {100-symm_switch}%")


#@markdown ---

#markdown ####**Cutn Scheduling:**
#markdown Format: `[40]*400+[20]*600` = 40 cuts for the first 400 /1000 steps, then 20 for the last 600/1000

#markdown cut_overview and cut_innercut are cumulative for total cutn on any given step. Overview cuts see the entire image and are good for early structure, innercuts are your standard cutn.

"""###Cut Settings"""

weighting = 'manual'#param['regular','manual','adaptive']


#VOC START 3 - DO NOT DELETE
cut_overview = "[6]*200+[6]*200+[4]*300+[2]*300"
cut_innercut = "[10]*200+[10]*200+[12]*300+[14]*300"
cut_ic_pow = "[3.5]*250+[4.5]*160+[20]*590"
#VOC FINISH 3 - DO NOT DELETE



overview_weight = "[15]*200+[7]*100+[6]*100+[1.5]*100+[1]*500"#@param{type: 'string'}


#@markdown this setting will set a portion of overview cuts to be executed as max_size cuts instead, scheduled to favor max_size as the run progresses
percent_overview = "[1]*190+[0.8]*70+[0.7]*140+[0.5]*600" #@param{type: 'string'}







 




#@markdown several ways of distributing cut sizes



#@markdown floor size sets a minimum size for cuts to be executed at.
floor_size = "[0]*1000"#@param {type: 'string'}
#floor_size = "[0.1]*150+[0.1]*150+[0.1]*100+[0.05]*100+[0]*500"#param {type: 'string'}

#@markdown ceiling is a maximum size for cuts
ceiling = 1.0#@param{type:'number'}


autofloor = False#@param{type:"boolean"}

basefloor = (((0.1225 * side_x * side_y)-224)/((side_x * side_y)-224))*0.77

tempfloor = f'[{basefloor}]*400+[{basefloor/2}]*100+[0]*500'

if autofloor:
  if (((side_x * side_y)**0.5) > 640):
    floor_size = tempfloor
  else:
    floor_size = "[0]*1000"




ic_gray_p = "[0.2]*400+[0]*600"#@param {type: 'string'}
ov_gray_p = "[0.2]*100+[0.1]*300+[0]*600"#@param {type: 'string'}



cut_weight_multiplier="[0.95]*200+[0.55]*250+[0.0]*550"


overview_type = "jaxy"#@param['variable zoom','jaxy','jaxy2','regular']
if overview_type == "variable zoom":
  zoom_out_overviews = True
  jaxy_overviews = False
  jaxy_overviews2 = False
elif overview_type == "jaxy":
  zoom_out_overviews = False
  jaxy_overviews = True
  jaxy_overviews2 = False
elif overview_type == "jaxy2":
  zoom_out_overviews = False
  jaxy_overviews = False
  jaxy_overviews2 = True
else:
  zoom_out_overviews = False
  jaxy_overviews = False
  jaxy_overviews2 = False

hflip = True#param{type:'boolean'}

#@markdown affine slightly rotates overview cuts, this seems to be useful, but also the most time-consuming augmentation
affine = True#@param{type:'boolean'}


#markdown normalize loss. generally want to normalize, but might be good to inflate the loss early? may need to reduce cgs to compensate
normalizeloss = True#param{type:'boolean'}

col_jitter = 0.09
pixel_jitter = 0.028
degree_tilt = 10

perspective = False


if weighting == 'adaptive':
  adaptive_weight = True
  manual_weight = False
elif weighting == 'manual':
  adaptive_weight = False
  manual_weight = True
else:
  adaptive_weight = False
  manual_weight = False

"""###bucket cuts"""

#@markdown leave this at none to disable, otherwise will use set distributions for all cuts, not yet tested and very experimental
distribution = 'none'#@param['none','random','fixed']

if distribution == 'fixed':
  use_bucketpow = True
  use_rand_bucketpow = False 
elif distribution == 'random':
  use_bucketpow = False
  use_rand_bucketpow = True 
else:
  use_bucketpow = False
  use_rand_bucketpow = False 



bucket_cuts = 16 #@param{type:'integer'}

smallcut_size = 0#@param{type:'number'}
smallcut_p = 0.35 #@param{type:'number'}
mediumcut_size = 0.08 #@param{type:'number'}
mediumcut_p = 0.5 #@param{type:'number'}
largecut_size = 0.2 #@param{type:'number'}
largecut_p = 0.7 #@param{type:'number'}

"""### prompt randomizers"""
"""
import random

randomizers = [
	["artist", "Asher Brown Durand"],
	["artist", "Greg Rutkowski"],
	["artist", "Michael Whelan"],
	["artist", "Chriss Foss"],
	["artist", "Marc Simonetti"],
	["artist", "Anato Finnstark"],
	["artist", "Jean Delville"],
	["artist", "John Harris"],
	["artist", "Simon Stalenhag"],
	["artist", "John Howe"],
	["artist", "James Jean"],
	["artist", "Don Maitz"],
	["artist", "Gediminas Pranckevicius"],
	["artist", "Zdzisław Beksiński"],
	["artist", "Albert Bierstadt"],
	["artist", "Peter Mohrbacher"],
	["artist", "John Atkinson Grimshaw"],
	["artist", "Peter Gric"],
	["artist", "Paul Delvaux"],
	["artist", "Rob Gonsalves"],
	["artist", "Karol Bak"],
	["artist", "Hubert Robert"],
	["artist", "Michael Parkes"],
	["artist", "Andrew Wyeth"],
	["artist", "Rebecca Guay"],
	["artist", "Fairfield Porter"],
	["artist", "Jacek Yerka"],
	["artist", "John Berkey"],
	["artist", "Margaret Macdonald Mackintosh"],
	["artist", "Peter Elson"],
	["artist", "Chris Foss"],
	["artist", "Bob Eggleton"],
	["artist", "Takato Yamamoto"],
	["artist", "Odd Nerdrum"],
	["artist", "Dean Cornwell"],
	["artist", "Robert McCall"],
	["artist", "Edmund Dulac"],
	["artist", "George Inness"],
	["artist", "Rodney Matthews"],
	["artist", "Martin Johnson Heade"],
	["artist", "Lee Madgwick"],
	["artist", "Beksinski"],
	["artist", "Gustave Moreau"],
	["adjective", "beautiful"],
	["adjective", "fascinating"],
	["adjective", "interesting"],
	["adjective", "dire"],
	["adjective", "terrifying"],
	["adjective", "elusive"],
	["adjective", "frantic"],
	["adjective", "serene"],
	["adjective", "evil"],
	["adjective", "festive"],
	["adjective", "mind-bending"],
	["adjective", "complex"],
	["adjective", "simple"],
	["adjective", "extraordinary"],
	["adjective", "masterpiece"],
	["adjective", "tangible"],
	["adjective", "psychotic"],
	["adjective", "warlike"],
	["adjective", "unusual"],
	["site", "trending on ArtStation"],
	["site", "trending on ConceptArtWorld"],
	["site", "trending on Flickr"],
	["site", "trending on Behance"],
	["site", "trending on 500px"],
	["site", "trending on Getty Images"],
	["site", "trending on DeviantArt"],
	["site", "trending on Pixiv"],
	["site", "trending on IllustrationX"],
	["site", "trending on cgsociety"]
]

def randomize(category):
    random.seed()
    choices = []
    for item in randomizers:
        if item[0] == category:
            choices.append(item[1])
    random_choice = random.choice(choices)
    return (random_choice)


def randomize_prompts(prompt):
	newprompt = prompt
	if "_" in newprompt:
		while "_" in newprompt:
			start = newprompt.index('_')
			end = newprompt.index('_',start+1)
			swap = newprompt[(start + 1):end]
			swapped = randomize(swap)
			newprompt = newprompt.replace(f'_{swap}_', swapped, 1)
	return newprompt

prompt_to_randomize = "A _adjective_ painting by _artist_ trending on _site_"#@param {type:'string'}
iterations = 5 #@param {type:'integer'}

for i in range (iterations):
    print('["' + randomize_prompts(prompt_to_randomize) + '"]')
"""

"""### Prompts
`animation_mode: None` will only use the first set. `animation_mode: 2D / Video` will run through them per the set frames and hold on the last one.
"""

# Note: If using a pixelart diffusion model, try adding "#pixelart" to the end of the prompt for a stronger effect. It'll tend to work a lot better!

"""
text_prompt_list = [
    

  ["A beautiful painting of a singular lighthouse, shining its light across a tumultuous sea of blood by greg rutkowski and thomas kinkade, Trending on artstation:[5]*500+[1]*500", "yellow color scheme:[1]*500+[1]*500"],
  #["prompt i want to go after the first"]

# can now run a list of prompts, each prompt goes in a set of brackets, on a new line, and with a comma at the end of the brackets.

]
"""

text_prompt_list = [
#VOC START 2 - DO NOT DELETE
[phrase.strip() for phrase in args3.prompt.split("|") ]
#VOC FINISH 2 - DO NOT DELETE
]






image_prompts = {
    # 0:['ImagePromptsWorkButArentVeryGood.png:2',],
}

"""##Init Image Settings
skip steps are now set with the init image, in this format [imgpath, skipsteps] see below
"""

#similar to prompt list, but no need for brackets here. if number of init images is less than number of prompts, only the first will be used, otherwise, each will go together
#i.e prompt1 with init_image1 followed by prompt2 with init_image2 and so on

#the second number in the brackets indicates how many skip steps

init_image_list = [
# ["/content/pic1.jpeg",50],
#VOC START 4 - DO NOT DELETE
 ["",150],
#VOC FINISH 4 - DO NOT DELETE
]

#@markdown ####**Init Image Settings:**
init_scale = args3.init_scale #0 #@param{type: 'integer'}
skip_steps_no_init = 0 #@param{type: 'integer'}
#@markdown *Make sure you set skip_steps to ~50% of your steps if you want to use an init image.*

#@title #Do the Run!
#@markdown `n_batches` ignored with animation modes.
display_rate = args3.update #param{type: 'number'}
n_batches = args3.n_batches #@param{type: 'number'}


# convert schedules in case of wrong format
def convert_to_schedule(string):
  if "[" not in string:
    newstring = "[" + string + "]*1000"
  else:
    newstring = string

  return newstring



use_secondary_model = convert_to_schedule(use_secondary_model)

clip_guidance_scale = convert_to_schedule(clip_guidance_scale)

cutn_batches = convert_to_schedule(cutn_batches)

clamp_max = convert_to_schedule(clamp_max)




if animation_mode == 'Video Input':
    steps = video_init_steps

#Update Model Settings
timestep_respacing = f'ddim{steps}'
diffusion_steps = (1000//steps)*steps if steps < 1000 else steps
model_config.update({
    'timestep_respacing': timestep_respacing,
    'diffusion_steps': diffusion_steps,
})

batch_size = 1 

def move_files(start_num, end_num, old_folder, new_folder):
    for i in range(start_num, end_num):
        old_file = old_folder + f'/{batch_name}({batchNum})_{i:04}.png'
        new_file = new_folder + f'/{batch_name}({batchNum})_{i:04}.png'
        os.rename(old_file, new_file)

#@markdown ---


resume_run = False #@param{type: 'boolean'}
run_to_resume = 'latest' #@param{type: 'string'}
resume_from_frame = 'latest' #@param{type: 'string'}
retain_overwritten_frames = False #@param{type: 'boolean'}
if retain_overwritten_frames:
    retainFolder = f'{batchFolder}/retained'
    createPath(retainFolder)


skip_step_ratio = int(frames_skip_steps.rstrip("%")) / 100
calc_frames_skip_steps = math.floor(steps * skip_step_ratio)

if animation_mode == 'Video Input':
    frames = sorted(glob(in_path+'/*.*'));
    if len(frames)==0: 
        sys.exit("ERROR: 0 frames found.\nPlease check your video input path and rerun the video settings cell.")
    flows = glob(flo_folder+'/*.*')
    if (len(flows)==0) and video_init_flow_warp:
        sys.exit("ERROR: 0 flow files found.\nPlease rerun the flow generation cell.")

if steps <= calc_frames_skip_steps:
    sys.exit("ERROR: You can't skip more steps than your total steps")

if resume_run:
    if run_to_resume == 'latest':
        try:
            batchNum
        except:
            batchNum = len(glob(f"{batchFolder}/{batch_name}(*)_settings.txt"))-1
    else:
        batchNum = int(run_to_resume)
    if resume_from_frame == 'latest':
        start_frame = len(glob(batchFolder+f"/{batch_name}({batchNum})_*.png"))
        if animation_mode != '3D' and turbo_mode == True and start_frame > turbo_preroll and start_frame % int(turbo_steps) != 0:
            start_frame = start_frame - (start_frame % int(turbo_steps))
    else:
        start_frame = int(resume_from_frame)+1
        if animation_mode != '3D' and turbo_mode == True and start_frame > turbo_preroll and start_frame % int(turbo_steps) != 0:
            start_frame = start_frame - (start_frame % int(turbo_steps))
        if retain_overwritten_frames is True:
            existing_frames = len(glob(batchFolder+f"/{batch_name}({batchNum})_*.png"))
            frames_to_save = existing_frames - start_frame
            print(f'Moving {frames_to_save} frames to the Retained folder')
            move_files(start_frame, existing_frames, batchFolder, retainFolder)
else:
    start_frame = 0
    batchNum = len(glob(batchFolder+"/*.txt"))
    while os.path.isfile(f"{batchFolder}/{batch_name}({batchNum})_settings.txt") or os.path.isfile(f"{batchFolder}/{batch_name}-{batchNum}_settings.txt"):
        batchNum += 1



for i, prompt in enumerate(text_prompt_list):
  print(f'Starting Run: {batch_name}({batchNum}) at frame {start_frame}')

  text_prompts = {0:prompt}
  if (len(init_image_list) >= len(text_prompt_list)):
    init_image = init_image_list[i][0]
    skip_steps = init_image_list[i][1]
  else:
    try:
      init_image = init_image_list[0][0]
      skip_steps = init_image_list[0][1]
    except:
      init_image = None
      skip_steps = skip_steps_no_init
  
  if init_image:
    perlin_init = False

  if set_seed == 'random_seed' or '':
      random.seed()
      seed = random.randint(0, 2**32)
      # print(f'Using seed: {seed}')
  else:
      seed = int(set_seed)


  args = {
      'batchNum': batchNum,
      'prompts_series':split_prompts(text_prompts) if text_prompts else None,
      'image_prompts_series':split_prompts(image_prompts) if image_prompts else None,
      'seed': seed,
      'display_rate':display_rate,
      'n_batches':n_batches if animation_mode == 'None' else 1,
      'batch_size':batch_size,
      'batch_name': batch_name,
      'steps': steps,
      'diffusion_sampling_mode': diffusion_sampling_mode,
      'width_height': width_height,
      'clip_guidance_scale': eval(clip_guidance_scale),
      'tv_scale': tv_scale,
      'range_scale': range_scale,
      'sat_scale': sat_scale,
      'cutn_batches': eval(cutn_batches),
      'init_image': init_image,
      'init_scale': init_scale,
      'skip_steps': skip_steps,
      'side_x': side_x,
      'side_y': side_y,
      'timestep_respacing': timestep_respacing,
      'diffusion_steps': diffusion_steps,
      'animation_mode': animation_mode,
      'video_init_path': video_init_path,
      'extract_nth_frame': extract_nth_frame,
      'video_init_seed_continuity': video_init_seed_continuity,
      'key_frames': key_frames,
      'max_frames': max_frames if animation_mode != "None" else 1,
      'interp_spline': interp_spline,
      'start_frame': start_frame,
      'angle': angle,
      'zoom': zoom,
      'translation_x': translation_x,
      'translation_y': translation_y,
      'translation_z': translation_z,
      'rotation_3d_x': rotation_3d_x,
      'rotation_3d_y': rotation_3d_y,
      'rotation_3d_z': rotation_3d_z,
      'midas_depth_model': midas_depth_model,
      'midas_weight': midas_weight,
      'near_plane': near_plane,
      'far_plane': far_plane,
      'fov': fov,
      'padding_mode': padding_mode,
      'sampling_mode': sampling_mode,
      'angle_series':angle_series,
      'zoom_series':zoom_series,
      'translation_x_series':translation_x_series,
      'translation_y_series':translation_y_series,
      'translation_z_series':translation_z_series,
      'rotation_3d_x_series':rotation_3d_x_series,
      'rotation_3d_y_series':rotation_3d_y_series,
      'rotation_3d_z_series':rotation_3d_z_series,
      'frames_scale': frames_scale,
      'skip_step_ratio': skip_step_ratio,
      'calc_frames_skip_steps': calc_frames_skip_steps,
      'text_prompts': text_prompts,
      'image_prompts': image_prompts,
      'use_secondary_model': eval(use_secondary_model),
      'cut_overview': eval(cut_overview),
      'cut_innercut': eval(cut_innercut),
      'cut_ic_pow': eval(cut_ic_pow),
      'ic_gray_p': eval(ic_gray_p),
      'ov_gray_p': eval(ov_gray_p),
      'percent_overview': eval(percent_overview),
      'floor_size': eval(floor_size),
      'overview_weight':eval(overview_weight),
      'cut_weight_multiplier': eval(cut_weight_multiplier),
      'bucket_cuts': bucket_cuts,
      'ceiling': ceiling,
      'intermediate_saves': intermediate_saves,
      'intermediates_in_subfolder': intermediates_in_subfolder,
      'steps_per_checkpoint': steps_per_checkpoint,
      'perlin_init': perlin_init,
      'perlin_mode': perlin_mode,
      'set_seed': set_seed,
      'eta': eta,
      'clamp_grad': clamp_grad,
      'clamp_max': eval(clamp_max),
      'skip_augs': skip_augs,
      'randomize_class': randomize_class,
      'clip_denoised': clip_denoised,
      'fuzzy_prompt': fuzzy_prompt,
      'rand_mag': rand_mag,
      'turbo_mode':turbo_mode,
      'turbo_steps':turbo_steps,
      'turbo_preroll':turbo_preroll,
      'resize_mid_run': resize_mid_run,
      'use_vertical_symmetry': use_vertical_symmetry,
      'use_horizontal_symmetry': use_horizontal_symmetry,
      'transformation_percent': transformation_percent,
      #video init settings
      'video_init_steps': video_init_steps,
      'video_init_clip_guidance_scale': video_init_clip_guidance_scale,
      'video_init_tv_scale': video_init_tv_scale,
      'video_init_range_scale': video_init_range_scale,
      'video_init_sat_scale': video_init_sat_scale,
      'video_init_cutn_batches': video_init_cutn_batches,
      'video_init_skip_steps': video_init_skip_steps,
      'video_init_frames_scale': args3.video_init_frames_scale,
      'video_init_frames_skip_steps': args3.video_init_frames_skip_steps,
      #warp settings
      'video_init_flow_warp':video_init_flow_warp,
      'video_init_flow_blend':video_init_flow_blend,
      'video_init_check_consistency':video_init_check_consistency,
      'video_init_blend_mode':video_init_blend_mode,
      'symmetry_loss':symmetry_loss,
      'sloss_scale':symm_loss_scale,
      'symm_switch':symm_switch
  }



  if animation_mode == 'Video Input':
      # This isn't great in terms of what will get saved to the settings.. but it should work.
      args['steps'] = args['video_init_steps']
      args['clip_guidance_scale'] = args['video_init_clip_guidance_scale']
      args['tv_scale'] = args['video_init_tv_scale']
      args['range_scale'] = args['video_init_range_scale']
      args['sat_scale'] = args['video_init_sat_scale']
      args['cutn_batches'] = args['video_init_cutn_batches']
      args['skip_steps'] = args['video_init_skip_steps']
      args['frames_scale'] = args['video_init_frames_scale']
      args['frames_skip_steps'] = args['video_init_frames_skip_steps']

  args = SimpleNamespace(**args)

  print('Prepping model...')
  model, diffusion = create_model_and_diffusion(**model_config)
  if diffusion_model == 'custom':
      model.load_state_dict(torch.load(custom_path, map_location='cpu'))
  else:
      model.load_state_dict(torch.load(f'{model_path}/{get_model_filename(diffusion_model)}', map_location='cpu'))
  model.requires_grad_(False).eval().to(device)
  for name, param in model.named_parameters():
      if 'qkv' in name or 'norm' in name or 'proj' in name:
          param.requires_grad_()
  if model_config['use_fp16']:
      model.convert_to_fp16()

  gc.collect()
  torch.cuda.empty_cache()


  try:
      do_run()
      batchNum += 1
  except KeyboardInterrupt:
      pass
  finally:
      print('Seed used:', seed)
      gc.collect()
      torch.cuda.empty_cache()

"""# 5. Create the video"""

import PIL
# @title ### **Create video**
#@markdown Video file will save in the same folder as your images.
from tqdm.notebook import trange
skip_video_for_run_all = True #@param {type: 'boolean'}

if animation_mode == 'Video Input':
    frames = sorted(glob(in_path+'/*.*'));
    if len(frames)==0: 
        sys.exit("ERROR: 0 frames found.\nPlease check your video input path and rerun the video settings cell.")
    flows = glob(flo_folder+'/*.*')
    if (len(flows)==0) and video_init_flow_warp:
        sys.exit("ERROR: 0 flow files found.\nPlease rerun the flow generation cell.")

blend =  0.5#@param {type: 'number'}
video_init_check_consistency = False #@param {type: 'boolean'}
"""
if skip_video_for_run_all == True:
    print('Skipping video creation, uncheck skip_video_for_run_all if you want to run it')

else:
    # import subprocess in case this cell is run without the above cells
    import subprocess
    from base64 import b64encode

    latest_run = batchNum

    folder = batch_name #@param
    run = latest_run #@param
    final_frame = 'final_frame'


    init_frame = 1#@param {type:"number"} This is the frame where the video will start
    last_frame = final_frame#@param {type:"number"} You can change i to the number of the last frame you want to generate. It will raise an error if that number of frames does not exist.
    fps = 12#@param {type:"number"}
    # view_video_in_cell = True #@param {type: 'boolean'}

    frames = []
    # tqdm.write('Generating video...')

    if last_frame == 'final_frame':
        last_frame = len(glob(batchFolder+f"/{folder}({run})_*.png"))
        print(f'Total frames: {last_frame}')

    image_path = f"{outDirPath}/{folder}/{folder}({run})_%04d.png"
    filepath = f"{outDirPath}/{folder}/{folder}({run}).mp4"

    if (video_init_blend_mode == 'optical flow') and (animation_mode == 'Video Input'):
        image_path = f"{outDirPath}/{folder}/flow/{folder}({run})_%04d.png"
        filepath = f"{outDirPath}/{folder}/{folder}({run})_flow.mp4"
        if last_frame == 'final_frame':
            last_frame = len(glob(batchFolder+f"/flow/{folder}({run})_*.png"))
        flo_out = batchFolder+f"/flow"
        createPath(flo_out)
        frames_in = sorted(glob(batchFolder+f"/{folder}({run})_*.png"))
        shutil.copy(frames_in[0], flo_out)
        for i in trange(init_frame, min(len(frames_in), last_frame)):
            frame1_path = frames_in[i-1]
            frame2_path = frames_in[i]
  
            frame1 = PIL.Image.open(frame1_path)
            frame2 = PIL.Image.open(frame2_path)
            frame1_stem = f"{(int(frame1_path.split('/')[-1].split('_')[-1][:-4])+1):04}.jpg"
            flo_path = f"/{flo_folder}/{frame1_stem}.npy"
            weights_path = None
            if video_init_check_consistency:
                # TBD
                pass
            warp(frame1, frame2, flo_path, blend=blend, weights_path=weights_path).save(batchFolder+f"/flow/{folder}({run})_{i:04}.png")
    if video_init_blend_mode == 'linear':
        image_path = f"{outDirPath}/{folder}/blend/{folder}({run})_%04d.png"
        filepath = f"{outDirPath}/{folder}/{folder}({run})_blend.mp4"
        if last_frame == 'final_frame':
            last_frame = len(glob(batchFolder+f"/blend/{folder}({run})_*.png"))
        blend_out = batchFolder+f"/blend"
        createPath(blend_out)
        frames_in = glob(batchFolder+f"/{folder}({run})_*.png")
        shutil.copy(frames_in[0], blend_out)
        for i in trange(1, len(frames_in)):
            frame1_path = frames_in[i-1]
            frame2_path = frames_in[i]
    
            frame1 = PIL.Image.open(frame1_path)
            frame2 = PIL.Image.open(frame2_path)
          
            frame = PIL.Image.fromarray((np.array(frame1)*(1-blend) + np.array(frame2)*(blend)).astype('uint8')).save(batchFolder+f"/blend/{folder}({run})_{i:04}.png")


    cmd = [
        'ffmpeg',
        '-y',
        '-vcodec',
        'png',
        '-r',
        str(fps),
        '-start_number',
        str(init_frame),
        '-i',
        image_path,
        '-frames:v',
        str(last_frame+1),
        '-c:v',
        'libx264',
        '-vf',
        f'fps={fps}',
        '-pix_fmt',
        'yuv420p',
        '-crf',
        '17',
        '-preset',
        'veryslow',
        filepath
    ]

    process = subprocess.Popen(cmd, cwd=f'{batchFolder}', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(stderr)
        raise RuntimeError(stderr)
    else:
        print("The video is ready and saved to the images folder")

    # if view_video_in_cell:
    #     mp4 = open(filepath,'rb').read()
    #     data_url = "data:video/mp4;base64," + b64encode(mp4).decode()
    #     display.HTML(f'<video width=400 controls><source src="{data_url}" type="video/mp4"></video>')
"""
