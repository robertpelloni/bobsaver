# Original file is located at https://colab.research.google.com/drive/1nmtcbQsE8sTjfLJ1u3Y4d6vi9ZTAvQph

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP_JAX')
sys.path.append('./jax-guided-diffusion')
sys.path.append('./v-diffusion-jax')

import os

if os.path.exists("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.2/bin"):
    os.add_dll_directory("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.2/bin")

from PIL import Image
from braceexpand import braceexpand
from dataclasses import dataclass
from functools import partial
from subprocess import Popen, PIPE
import functools
import io
import math
import re
import requests
import time
import json
import pandas as pd
import shutil
import cv2

import numpy as np
import jax
import jax.numpy as jnp
import jax.scipy as jsp
import jaxtorch
from jaxtorch import PRNG, Context, Module, nn, init
#from tqdm import tqdm

from IPython import display
from torchvision import datasets, transforms, utils
from torchvision.transforms import functional as TF
import torch.utils.data
import torch

from diffusion_models.common import DiffusionOutput, Partial, make_partial, blur_fft, norm1, LerpModels
from diffusion_models.lazy import LazyParams
from diffusion_models.schedules import cosine, ddpm, ddpm2, spliced
from diffusion_models.perceptor import get_clip, clip_size, normalize

from diffusion_models.aesthetic import AestheticLoss, AestheticExpected
from diffusion_models.secondary import secondary1_wrap, secondary2_wrap
from diffusion_models.antijpeg import anti_jpeg_cfg, jpeg_classifier, jpeg_classifier_wrap, jpeg_classifier_params
from diffusion_models.pixelart import pixelartv4_wrap, pixelartv6_wrap
from diffusion_models.pixelartv7 import pixelartv7_ic_attn
from diffusion_models.cc12m_1 import cc12m_1_wrap, cc12m_1_cfg_wrap, cc12m_1_classifier_wrap
from diffusion_models.openai import openai_256, openai_512, openai_512_finetune
from diffusion_models.kat_models import danbooru_128, wikiart_128, wikiart_256, imagenet_128
from diffusion_models import sampler

import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations')
  parser.add_argument('--max_frames', type=int, help='1 is single image, more is a movie')
  parser.add_argument('--sizex', type=int, help='Image width')
  parser.add_argument('--sizey', type=int, help='Image height')
  parser.add_argument('--model', type=str, help='Main model')
  parser.add_argument('--secondary', type=int, help='Use secondary model')
  parser.add_argument('--antijpeg', type=int, help='Anti-JPEG')
  parser.add_argument('--antijpegguidance', type=float, help='Anti-JPEG Guidance Scale')
  parser.add_argument('--model1', type=int, help='Use CLIP model 1')
  parser.add_argument('--model2', type=int, help='Use CLIP model 2')
  parser.add_argument('--model3', type=int, help='Use CLIP model 3')
  parser.add_argument('--samplemode', type=str, help='Sample mode')
  parser.add_argument('--eta', type=float, help='ETA')
  parser.add_argument('--cutn', type=int, help='Cutouts')
  parser.add_argument('--cutbatches', type=int, help='Cutout batches')
  parser.add_argument('--cutpow', type=float, help='Cutout power')
  parser.add_argument('--cutgrey', type=float, help='Cut grey probability')
  parser.add_argument('--cutflip', type=float, help='Cut flip probability')
  parser.add_argument('--aestheticlossscale', type=float, help='Aesthetic loss scale')

  parser.add_argument('--prevguidancescale', type=float, help='Prev frame guidance scale')
  parser.add_argument('--prevcfgguidancescale', type=float, help='Prev frame CFG guidance scale')
  parser.add_argument('--prevstartingnoise', type=float, help='Prev frame starting noise')
  parser.add_argument('--prevendingnoise', type=float, help='Prev frame ending noise')
  parser.add_argument('--prevskippercent', type=float, help='Prev frame skip percentage as float')
  parser.add_argument('--prevmseweight', type=float, help='Prev frame MSE weight')
  
  parser.add_argument('--init', type=str, help='Init image')
  parser.add_argument('--initweight', type=int, help='Init image weight')
  parser.add_argument('--startnoise', type=float, help='Init image start noise')
  parser.add_argument('--endnoise', type=float, help='Init image end noise')
  parser.add_argument('--skippercent', type=float, help='Skip percent')

  parser.add_argument('--guidancescale', type=float, help='Guidance scale')
  parser.add_argument('--tvscale', type=float, help='TV scale')
  parser.add_argument('--rangescale', type=float, help='Range scale')
  parser.add_argument('--meanscale', type=float, help='Mean scale')
  parser.add_argument('--variationscale', type=float, help='Variation scale')

  parser.add_argument('--openai512weight', type=float, help='Lerp weight')
  parser.add_argument('--openai256weight', type=float, help='Lerp weight')
  parser.add_argument('--openaifinetuneweight', type=float, help='Lerp weight')
  parser.add_argument('--pixelartv4weight', type=float, help='Lerp weight')
  parser.add_argument('--pixelartv6weight', type=float, help='Lerp weight')
  parser.add_argument('--pixelartv7weight', type=float, help='Lerp weight')
  parser.add_argument('--cc12mweight', type=float, help='Lerp weight')
  parser.add_argument('--cc12mcfgweight', type=float, help='Lerp weight')
  parser.add_argument('--wikiartweight', type=float, help='Lerp weight')
  parser.add_argument('--danbooruweight', type=float, help='Lerp weight')
  parser.add_argument('--imagenet128weight', type=float, help='Lerp weight')
  parser.add_argument('--secondary2weight', type=float, help='Lerp weight')

  parser.add_argument('--vertical_symmetry', type=int, help='Vertical symmetry enabled')
  parser.add_argument('--vertical_symmetry_scale', type=int, help='Vertical symmetry scale')
  parser.add_argument('--horizontal_symmetry', type=int, help='Horizontal symmetry enabled')
  parser.add_argument('--horizontal_symmetry_scale', type=int, help='Horizontal symmetry scale')
  parser.add_argument('--transformationschedule', type=str, help='Symmetry transformation schedule')

  parser.add_argument('--huemincuts', type=int, help='Use Huemin cuts')

  parser.add_argument('--image_file', type=str, help='Output image name')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory')

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



DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()









#@markdown Mount to Google Drive
googleDrive = False #@param {type:"boolean"}
modelsOnDrive = False #@param {type:"boolean"}
initImageFolder = False #@param {type:"boolean"}
promptFolder = False #@param {type:"boolean"}

outputFolder = "AI" #@param {type:"string"}
v2 = "nshepv2g/"
outputFolderStatic = outputFolder


devices = jax.devices()
n_devices = len(devices)
sys.stdout.write(f'Using device:{devices}\n')
sys.stdout.flush()

# Drive location for caching model parameters
model_location = './models'

#os.makedirs(model_location, exist_ok=True)

# Drive location for inits
if initImageFolder:
  init_location = outputFolderStatic+"nshepv2g/"+"init/"
  os.makedirs(init_location, exist_ok=True)
else:
  init_location = ''

# Drive location for prompt
if promptFolder:
  prompt_location = outputFolderStatic+"nshepv2g/"+"prompts/"
  os.makedirs(prompt_location, exist_ok=True)

# make video output folder path
videoOutputFolder = outputFolder+"videos/"

# Define necessary functions

def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')

def fetch_model(url_or_path):
    basename = os.path.basename(url_or_path)
    local_path = os.path.join(model_location, basename)
    if os.path.exists(local_path):
        return local_path
    else:
        os.makedirs(f'{model_location}/tmp', exist_ok=True)
        sys.stdout.write(f'Attempting to download {url_or_path}\n')
        sys.stdout.flush()
        Popen(['curl', url_or_path, '-o -ssl-no-revoke', f'{model_location}/tmp/{basename}']).wait()
        os.rename(f'{model_location}/tmp/{basename}', local_path)
        return local_path
        
LazyParams.fetch = fetch_model

def grey(image):
    [*_, c, h, w] = image.shape
    return jnp.broadcast_to(image.mean(axis=-3, keepdims=True), image.shape)

def cutout_image(image, offsetx, offsety, size, output_size=224):
    """Computes (square) cutouts of an image given x and y offsets and size."""
    (c, h, w) = image.shape

    scale = jnp.stack([output_size / size, output_size / size])
    translation = jnp.stack([-offsety * output_size / size, -offsetx * output_size / size])
    return jax.image.scale_and_translate(image,
                                         shape=(c, output_size, output_size),
                                         spatial_dims=(1,2),
                                         scale=scale,
                                         translation=translation,
                                         method='lanczos3')

def cutouts_images(image, offsetx, offsety, size, output_size=224):
    f = partial(cutout_image, output_size=output_size)         # [c h w] [] [] [] -> [c h w]
    f = jax.vmap(f, in_axes=(0, 0, 0, 0), out_axes=0)          # [n c h w] [n] [n] [n] -> [n c h w]
    f = jax.vmap(f, in_axes=(None, 0, 0, 0), out_axes=0)       # [n c h w] [k n] [k n] [k n] -> [k n c h w]
    return f(image, offsetx, offsety, size)

@jax.tree_util.register_pytree_node_class
class MakeCutouts(object):
    def __init__(self, cut_size, cutn, cut_pow=1.0, p_grey=0.2, p_mixgrey=None, p_flip=0.5):
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.p_grey = p_grey
        self.p_mixgrey = p_mixgrey
        self.p_flip = p_flip

    def __call__(self, input, key):
        [n, c, h, w] = input.shape
        rng = PRNG(key)

        small_cuts = self.cutn//2
        large_cuts = self.cutn - self.cutn//2

        max_size = min(h, w)
        min_size = min(h, w, self.cut_size)
        cut_us = jax.random.uniform(rng.split(), shape=[small_cuts, n])**self.cut_pow
        sizes = (min_size + cut_us * (max_size - min_size)).clamp(min_size, max_size)
        offsets_x = jax.random.uniform(rng.split(), [small_cuts, n], minval=0, maxval=w - sizes)
        offsets_y = jax.random.uniform(rng.split(), [small_cuts, n], minval=0, maxval=h - sizes)
        cutouts = cutouts_images(input, offsets_x, offsets_y, sizes)

        B1 = 40
        B2 = 40
        lcut_us = jax.random.uniform(rng.split(), shape=[large_cuts, n])
        border = B1 + lcut_us * B2
        lsizes = (max(h,w) + border).astype(jnp.int32)
        loffsets_x = jax.random.uniform(rng.split(), [large_cuts, n], minval=w/2-lsizes/2-border, maxval=w/2-lsizes/2+border)
        loffsets_y = jax.random.uniform(rng.split(), [large_cuts, n], minval=h/2-lsizes/2-border, maxval=h/2-lsizes/2+border)
        lcutouts = cutouts_images(input, loffsets_x, loffsets_y, lsizes)

        cutouts = jnp.concatenate([cutouts, lcutouts], axis=0)

        greyed = grey(cutouts)

        if self.p_mixgrey is not None:
          grey_us = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          grey_rs = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(grey_us < self.p_mixgrey, grey_rs * greyed + (1 - grey_rs) * cutouts, cutouts)

        if self.p_grey is not None:
          grey_us = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(grey_us < self.p_grey, greyed, cutouts)

        if self.p_flip is not None:
          flip_us = jax.random.bernoulli(rng.split(), self.p_flip, [self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(flip_us, jnp.flip(cutouts, axis=-1), cutouts)

        return cutouts

    def tree_flatten(self):
        return ([self.cut_pow, self.p_grey, self.p_mixgrey, self.p_flip], (self.cut_size, self.cutn))

    @staticmethod
    def tree_unflatten(static, dynamic):
        (cut_size, cutn) = static
        return MakeCutouts(cut_size, cutn, *dynamic)

@jax.tree_util.register_pytree_node_class
class MakeCutouts_huemin(object):
    def __init__(self, cut_size, cutn, cut_pow=1.0, p_grey=0.2, p_mixgrey=None, p_flip=0.5):
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.p_grey = p_grey
        self.p_mixgrey = p_mixgrey
        self.p_flip = p_flip

    def __call__(self, input, key):
        [n, c, h, w] = input.shape
        rng = PRNG(key)

        small_cuts = self.cutn//2
        large_cuts = self.cutn - self.cutn//2

        max_size = min(h, w)
        min_size = min(h, w, self.cut_size)

        cut_power = np.random.gamma(1, 1, 1)[0]*self.cut_pow

        cut_us = jax.random.uniform(rng.split(), shape=[small_cuts, n])**cut_power
        sizes = (min_size + cut_us * (max_size - min_size)).clamp(min_size, max_size)
        offsets_x = jax.random.uniform(rng.split(), [small_cuts, n], minval=0, maxval=w - sizes)
        offsets_y = jax.random.uniform(rng.split(), [small_cuts, n], minval=0, maxval=h - sizes)
        cutouts = cutouts_images(input, offsets_x, offsets_y, sizes)

        B1 = np.random.gamma(1, max_size/4, 1)[0]
        B2 = np.random.gamma(1, max_size/4, 1)[0]
        
        lcut_us = jax.random.uniform(rng.split(), shape=[large_cuts, n])
        border = B1 + lcut_us * B2
        lsizes = (max(h,w) + border).astype(jnp.int32)
        loffsets_x = jax.random.uniform(rng.split(), [large_cuts, n], minval=w/2-lsizes/2-border, maxval=w/2-lsizes/2+border)
        loffsets_y = jax.random.uniform(rng.split(), [large_cuts, n], minval=h/2-lsizes/2-border, maxval=h/2-lsizes/2+border)
        lcutouts = cutouts_images(input, loffsets_x, loffsets_y, lsizes)

        cutouts = jnp.concatenate([cutouts, lcutouts], axis=0)

        greyed = grey(cutouts)

        if self.p_mixgrey is not None:
          grey_us = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          grey_rs = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(grey_us < self.p_mixgrey, grey_rs * greyed + (1 - grey_rs) * cutouts, cutouts)

        if self.p_grey is not None:
          grey_us = jax.random.uniform(rng.split(), shape=[self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(grey_us < self.p_grey, greyed, cutouts)

        if self.p_flip is not None:
          flip_us = jax.random.bernoulli(rng.split(), self.p_flip, [self.cutn, n, 1, 1, 1])
          cutouts = jnp.where(flip_us, jnp.flip(cutouts, axis=-1), cutouts)

        return cutouts

    def tree_flatten(self):
        return ([self.cut_pow, self.p_grey, self.p_mixgrey, self.p_flip], (self.cut_size, self.cutn))

    @staticmethod
    def tree_unflatten(static, dynamic):
        (cut_size, cutn) = static
        return MakeCutouts_huemin(cut_size, cutn, *dynamic)

@jax.tree_util.register_pytree_node_class
class MakeCutoutsPixelated(object):
    def __init__(self, make_cutouts, factor=4):
        self.make_cutouts = make_cutouts
        self.factor = factor
        self.cutn = make_cutouts.cutn

    def __call__(self, input, key):
        [n, c, h, w] = input.shape
        input = jax.image.resize(input, [n, c, h*self.factor, w * self.factor], method='nearest')
        return self.make_cutouts(input, key)

    def tree_flatten(self):
        return ([self.make_cutouts], [self.factor])
    @staticmethod
    def tree_unflatten(static, dynamic):
        return MakeCutoutsPixelated(*dynamic, *static)

def spherical_dist_loss(x, y):
    x = norm1(x)
    y = norm1(y)
    return (x - y).square().sum(axis=-1).sqrt().div(2).arcsin().square().mul(2)

# Define combinators.

# These (ab)use the jax pytree registration system to define parameterised
# objects for doing various things, which are compatible with jax.jit.

# For jit compatibility an object needs to act as a pytree, which means implementing two methods:
#  - tree_flatten(self): returns two lists of the object's fields:
#       1. 'dynamic' parameters: things which can be jax tensors, or other pytrees
#       2. 'static' parameters: arbitrary python objects, will trigger recompilation when changed
#  - tree_unflatten(static, dynamic): reconstitutes the object from its parts

# With these tricks, you can simply define your cond_fn as an object, as is done
# below, and pass it into the jitted sample step as a regular argument. JAX will
# handle recompiling the jitted code whenever a control-flow affecting parameter
# is changed (such as cut_batches).

# A wrapper that causes the diffusion model to generate tileable images, by
# randomly shifting the image with wrap around.

def xyroll(x, shifts):
  return jax.vmap(partial(jnp.roll, axis=[1,2]), in_axes=(0, 0))(x, shifts)

@make_partial
def TilingModel(model, x, cosine_t, key):
  rng = PRNG(key)
  [n, c, h, w] = x.shape
  shift = jax.random.randint(rng.split(), [n, 2], -50, 50)
  x = xyroll(x, shift)
  out = model(x, cosine_t, rng.split())
  def unshift(val):
    return xyroll(val, -shift)
  return jax.tree_util.tree_map(unshift, out)

@make_partial
def PanoramaModel(model, x, cosine_t, key):
  rng = PRNG(key)
  [n, c, h, w] = x.shape
  shift = jax.random.randint(rng.split(), [n, 2], 0, [1, w])
  x = xyroll(x, shift)
  out = model(x, cosine_t, rng.split())
  def unshift(val):
    return xyroll(val, -shift)
  return jax.tree_util.tree_map(unshift, out)

"""Models & Parameters"""

# Pixel art model
# There are many checkpoints supported with this model, so maybe better to provide choice in the notebook
pixelartv4_params = LazyParams.pt(
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v4_34.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v4_63.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v4_150.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v5_50.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v5_65.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v5_97.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v5_173.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_344.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_432.pt'
    'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_600.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_700.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_800.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_1000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_2000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-fgood_3000.pt'
    , key='params_ema'
)

pixelartv6_params = LazyParams.pt(
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-1000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-2000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-3000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-4000.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-aug-900.pt'
    # 'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-aug-1300.pt'
    'https://set.zlkj.in/models/diffusion/pixelart/pixelart-v6-aug-3000.pt'
    , key='params_ema'
)

# cc12m_1
cc12m_1_params = LazyParams.pt('https://v-diffusion.s3.us-west-2.amazonaws.com/cc12m_1.pth')

# Losses and cond fn.

def filternone(xs):
  return [x for x in xs if x is not None]

@jax.tree_util.register_pytree_node_class
class CondCLIP(object):
    """Backward a loss function through clip."""
    def __init__(self, perceptor, make_cutouts, cut_batches, *losses):
        self.perceptor = perceptor
        self.make_cutouts = make_cutouts
        self.cut_batches = cut_batches
        self.losses = filternone(losses)
    def __call__(self, x_in, key):
        n = x_in.shape[0]
        def main_clip_loss(x_in, key):
            cutouts = normalize(self.make_cutouts(x_in.add(1).div(2), key)).rearrange('k n c h w -> (k n) c h w')
            image_embeds = self.perceptor.embed_cutouts(cutouts).rearrange('(k n) c -> k n c', n=n)
            return sum(loss_fn(image_embeds) for loss_fn in self.losses)
        num_cuts = self.cut_batches
        keys = jnp.stack(jax.random.split(key, num_cuts))
        main_clip_grad = jax.lax.scan(lambda total, key: (total + jax.grad(main_clip_loss)(x_in, key), key),
                                        jnp.zeros_like(x_in),
                                        keys)[0] / num_cuts
        return main_clip_grad
    def tree_flatten(self):
        return [self.perceptor, self.make_cutouts, self.losses], [self.cut_batches]
    @classmethod
    def tree_unflatten(cls, static, dynamic):
        [perceptor, make_cutouts, losses] = dynamic
        [cut_batches] = static
        return cls(perceptor, make_cutouts, cut_batches, *losses)

@make_partial
def SphericalDistLoss(text_embed, clip_guidance_scale, image_embeds):
    losses = spherical_dist_loss(image_embeds, text_embed).mean(0)
    return (clip_guidance_scale * losses).sum()

@make_partial
def InfoLOOB(text_embed, clip_guidance_scale, inv_tau, lm, image_embeds):
    all_image_embeds = norm1(image_embeds.mean(0))
    all_text_embeds = norm1(text_embed)
    sim_matrix = inv_tau * jnp.einsum('nc,mc->nm', all_image_embeds, all_text_embeds)
    xn = sim_matrix.shape[0]
    def loob(sim_matrix):
      diag = jnp.eye(xn) * sim_matrix
      off_diag = (1 - jnp.eye(xn))*sim_matrix + jnp.eye(xn) * float('-inf')
      return -diag.sum() + lm * jsp.special.logsumexp(off_diag, axis=-1).sum()
    losses = loob(sim_matrix) + loob(sim_matrix.transpose())
    return losses.sum() * clip_guidance_scale.mean() / inv_tau

@make_partial
def CondTV(tv_scale, x_in, key):
    def downscale2d(image, f):
        [c, n, h, w] = image.shape
        return jax.image.resize(image, [c, n, h//f, w//f], method='cubic')

    def tv_loss(input):
        """L2 total variation loss, as in Mahendran et al."""
        x_diff = input[..., :, 1:] - input[..., :, :-1]
        y_diff = input[..., 1:, :] - input[..., :-1, :]
        return x_diff.square().mean([1,2,3]) + y_diff.square().mean([1,2,3])

    def sum_tv_loss(x_in, f=None):
        if f is not None:
            x_in = downscale2d(x_in, f)
        return tv_loss(x_in).sum() * tv_scale
    tv_grad_512 = jax.grad(sum_tv_loss)(x_in)
    tv_grad_256 = jax.grad(partial(sum_tv_loss,f=2))(x_in)
    tv_grad_128 = jax.grad(partial(sum_tv_loss,f=4))(x_in)
    return tv_grad_512 + tv_grad_256 + tv_grad_128

@make_partial
def CondRange(range_scale, x_in, key):
    def range_loss(x_in):
        return jnp.abs(x_in - x_in.clamp(minval=-1,maxval=1)).mean()
    return range_scale * jax.grad(range_loss)(x_in)

@make_partial
def CondHorizontalSymmetry(horizontal_symmetry_scale, x_in, key):
    def horizontal_symmetry_loss(x_in):
        [n, c, h, w] = x_in.shape
        return jnp.abs(x_in[:, :, :, :w//2]-jnp.flip(x_in[:, :, :, w//2:],-1)).mean()
    return horizontal_symmetry_scale * jax.grad(horizontal_symmetry_loss)(x_in)

@make_partial
def CondVerticalSymmetry(vertical_symmetry_scale, x_in, key):
    def vertical_symmetry_loss(x_in):
        [n, c, h, w] = x_in.shape
        return jnp.abs(x_in[:, :, :h//2, :]-jnp.flip(x_in[:, :, h//2:, :],-2)).mean()
    return vertical_symmetry_scale * jax.grad(vertical_symmetry_loss)(x_in)

@make_partial
def CondMean(mean_scale, x_in, key):
    def mean_loss(x_in):
        return jnp.abs(x_in-0.5).mean()
    return mean_scale * jax.grad(mean_loss)(x_in)

@make_partial
def CondVar(var_scale, x_in, key):
    def var_loss(x_in):
        return x_in.var()
    return var_scale * jax.grad(var_loss)(x_in)

@make_partial
def CondMSE(target, mse_scale, x_in, key):
    def mse_loss(x_in):
        return (x_in - target).square().mean()
    return mse_scale * jax.grad(mse_loss)(x_in)

@jax.tree_util.register_pytree_node_class
class MaskedMSE(object):
    # MSE loss. Targets the output towards an image.
    def __init__(self, target, mse_scale, mask, grey=False):
        self.target = target
        self.mse_scale = mse_scale
        self.mask = mask
        self.grey = grey
    def __call__(self, x_in, key):
        def mse_loss(x_in):
            if self.grey:
              return (self.mask * grey(x_in - self.target).square()).mean()
            else:
              return (self.mask * (x_in - self.target).square()).mean()
        return self.mse_scale * jax.grad(mse_loss)(x_in)
    def tree_flatten(self):
        return [self.target, self.mse_scale, self.mask], [self.grey]
    def tree_unflatten(static, dynamic):
        return MaskedMSE(*dynamic, *static)


@jax.tree_util.register_pytree_node_class
class MainCondFn(object):
    # Used to construct the main cond_fn. Accepts a diffusion model which will
    # be used for denoising, plus a list of 'conditions' which will
    # generate gradient of a loss wrt the denoised, to be summed together.
    def __init__(self, diffusion, conditions, blur_amount=None, use='pred'):
        self.diffusion = diffusion
        self.conditions = [c for c in conditions if c is not None]
        self.blur_amount = blur_amount
        self.use = use

    @jax.jit
    def __call__(self, x, cosine_t, key):
        if not self.conditions:
          return jnp.zeros_like(x)

        rng = PRNG(key)
        n = x.shape[0]

        alphas, sigmas = cosine.to_alpha_sigma(cosine_t)

        def denoise(key, x):
            pred = self.diffusion(x, cosine_t, key).pred
            if self.use == 'pred':
                return pred
            elif self.use == 'x_in':
                return pred * sigmas + x * alphas
        (x_in, backward) = jax.vjp(partial(denoise, rng.split()), x)

        total = jnp.zeros_like(x_in)
        for cond in self.conditions:
            total += cond(x_in, rng.split())
        if self.blur_amount is not None:
          blur_radius = (self.blur_amount * sigmas / alphas).clamp(0.05,512)
          total = blur_fft(total, blur_radius.mean())
        final_grad = -backward(total)[0]

        # clamp gradients to a max of 0.2
        magnitude = final_grad.square().mean(axis=(1,2,3), keepdims=True).sqrt()
        final_grad = final_grad * jnp.where(magnitude > 0.2, 0.2 / magnitude, 1.0)
        return final_grad
    def tree_flatten(self):
        return [self.diffusion, self.conditions, self.blur_amount], [self.use]
    def tree_unflatten(static, dynamic):
        return MainCondFn(*dynamic, *static)


@jax.tree_util.register_pytree_node_class
class CondFns(object):
    def __init__(self, *conditions):
        self.conditions = conditions
    def __call__(self, x, t, key):
        rng = PRNG(key)
        total = jnp.zeros_like(x)
        for cond in self.conditions:
          total += cond(x, t, key)
        return total
    def tree_flatten(self):
        return [self.conditions], []
    def tree_unflatten(static, dynamic):
        [conditions] = dynamic
        return CondFns(*conditions)

def clamp_score(score):
  magnitude = score.square().mean(axis=(1,2,3), keepdims=True).sqrt()
  return score * jnp.where(magnitude > 0.1, 0.1 / magnitude, 1.0)

@make_partial
def BlurRangeLoss(scale, x, cosine_t, key):
    def blurred_pred(x, cosine_t):
      alpha, sigma = cosine.to_alpha_sigma(cosine_t)
      blur_radius = (sigma / alpha * 2)
      return blur_fft(x, blur_radius) / alpha.clamp(0.01)
    def loss(x):
        pred = blurred_pred(x, cosine_t)
        diff = pred - pred.clamp(minval=-1,maxval=1)
        return diff.square().sum()
    return clamp_score(-scale * jax.grad(loss)(x))

def process_prompt(clip,all_prompt):
  embeds = []
  expands = all_prompt.split("|")
  for prompt in expands:
    prompt = prompt.strip()
    # check url
    if "https:" in prompt:
      tmp = prompt.split(":")
      # check weight
      if len(tmp) == 2:
        temp_weight = 1
        temp_prompt = prompt
        init_pil = Image.open(fetch(temp_prompt))
        tmp_embed = temp_weight * clip.embed_image(init_pil)
        if len(tmp_embed.shape) != 1:
          tmp_embed = tmp_embed[-1]
        embeds.append(tmp_embed)
        #print("here1")
        #print(tmp_embed.shape)
      if len(tmp) == 3:
        temp_prompt = ":".join(tmp[0:2]).strip()
        temp_weight = float(tmp[2].strip())
        init_pil = Image.open(fetch(temp_prompt))
        tmp_embed = temp_weight * clip.embed_image(init_pil)
        if len(tmp_embed.shape) != 1:
          tmp_embed = tmp_embed[-1]
        embeds.append(tmp_embed)
        #print("here2")
        #print(tmp_embed.shape)
    # if not url
    else:
      # check weight
      if ':' in prompt:
        tmp = prompt.split(":")
        temp_prompt = tmp[0].strip()
        temp_weight = float(tmp[1].strip())
      else:
        temp_prompt = prompt
        temp_weight = 1
      # try path
      try:
        init_pil = Image.open(fetch(temp_prompt))
        tmp_embed = temp_weight * clip.embed_image(init_pil)
        if len(tmp_embed.shape) != 1:
          tmp_embed = tmp_embed[-1]
        embeds.append(tmp_embed)
      except:
        tmp_embed = temp_weight * clip.embed_text(temp_prompt.strip())
        embeds.append(tmp_embed)
        #print("here4")
        #print(tmp_embed.shape)
  return norm1(sum(embeds))

def process_prompts(clip, prompts):
  return jnp.stack([process_prompt(clip, prompt) for prompt in prompts])

def expand(xs, batch_size):
  """Extend or truncate the list of prompts to the batch size."""
  return (xs * batch_size)[:batch_size]

def get_output_folder(outputFolder, choose_diffusion_model, batch_outputFolder, use_batch_outputFolder):
    if googleDrive:
        yearMonth = time.strftime('/%Y-%m/')
        outputFolder = outputFolderStatic+v2+choose_diffusion_model+yearMonth
        if use_batch_outputFolder and not batch_outputFolder == "":
            outputFolder += batch_outputFolder+"/"
        os.makedirs(outputFolder, exist_ok=True)
    return outputFolder

def save_still_settings(local_seed,path,tag):
  setting_list = {
      'seed': local_seed,
      'image_size' : image_size,
      'batch_size' : batch_size,
      'n_batches' : n_batches,
      'steps' : steps,

      'choose_diffusion_model' : choose_diffusion_model,
      'use_secondary_model' : use_secondary_model,
      'use_anti_jpeg' : use_antijpeg,
      'clips' : clips,

      'cutn' : cutn,
      'cut_batches' : cut_batches,
      'cut_pow' : cut_pow,
      'cut_p_mixgrey' : cut_p_mixgrey,
      'cut_p_grey' : cut_p_grey,
      'cut_p_flip' : cut_p_flip,

      'sample_mode' : sample_mode,
      'eta' : eta,
      'starting_noise' : starting_noise,
      'ending_noise' : ending_noise,
      'skip_percent' : skip_percent,

      'ic_cond' : ic_cond,
      'ic_guidance_scale' : ic_guidance_scale,
      'cfg_guidance_scale' : cfg_guidance_scale,
      'aesthetic_loss_scale' : aesthetic_loss_scale,
      'clip_guidance_scale' : clip_guidance_scale,
      'antijpeg_guidance_scale' : antijpeg_guidance_scale,
      'tv_scale' : tv_scale,
      'range_scale' : range_scale,
      'mean_scale' : mean_scale,
      'var_scale' : var_scale,
      'horizontal_symmetry_scale' : horizontal_symmetry_scale,
      'vertical_symmetry_scale' : vertical_symmetry_scale,

      'use_vertical_symmetry' : use_vertical_symmetry,
      'use_horizontal_symmetry' : use_horizontal_symmetry,
      'transformation_schedule' : transformation_schedule,

      'use_init' : use_init,
      'init_image' : init_image,
      'init_weight_mse' : init_weight_mse,

      'max_frames' : max_frames,
      'prev_frame_clip_guidance_scale' : prev_frame_clip_guidance_scale,
      'prev_frame_cfg_guidance_scale' : prev_frame_cfg_guidance_scale,
      'prev_frame_starting_noise' : prev_frame_starting_noise,
      'prev_frame_skip_percent' : prev_frame_skip_percent,
      'prev_frame_weight_mse' : prev_frame_weight_mse,
      'use_prev_frame_image_prompt' : use_prev_frame_image_prompt,

      'key_frames' : key_frames,
      'max_frames' : max_frames,
      'angle' : angle,
      'zoom' : zoom,
      'translation_x' : translation_x,
      'translation_y' : translation_y,

      'all_title' : title

      }
  
  with open(f"{path}{tag}.txt", "w+") as f:
    json.dump(setting_list, f, ensure_ascii=False, indent=4)
  
  return
    
def simple_symmetry(x_in):
  [n, c, h, w] = x_in.shape
  x_in = jnp.concatenate([x_in[:, :, :, :w//2], jnp.flip(x_in[:, :, :, :w//2],-1)], -1)
  return(x_in)

def load_image(url):
    init_array = Image.open(fetch(url)).convert('RGB')
    init_array = init_array.resize(image_size, Image.LANCZOS)
    init_array = jnp.array(TF.to_tensor(init_array)).unsqueeze(0).mul(2).sub(1)
    return init_array

def display_images(images):
  images = images.add(1).div(2).clamp(0, 1)
  images = torch.tensor(np.array(images))
  grid = utils.make_grid(images, 4).cpu()
  display.display(TF.to_pil_image(grid))
  return

if promptFolder:
  # makes template csv files if prompt_location is empty
  if len(os.listdir(prompt_location)) == 0:
    subjects_df = pd.DataFrame({"subject" : ["rifle","sword"]})
    modifiers_df = pd.DataFrame({"modifier" : ["cosmic","void"]})
    artists_df = pd.DataFrame({"artist" : ["steven belledin","dan mumford"]})
    subjects_df.to_csv(prompt_location+"subjects.csv",index=False)
    modifiers_df.to_csv(prompt_location+"modifiers.csv",index=False)
    artists_df.to_csv(prompt_location+"artists.csv",index=False)
    print("creating random prompt csv files")
  else:
    print(f"{len(os.listdir(prompt_location))} files in {prompt_location}")

def filternone(xs):
  return [x for x in xs if x is not None]

class LerpWeightError(Exception):
       pass

"""# Prof. R.J. Lerp Models"""

sys.stdout.write("Setting model lerp weights ...\n")
sys.stdout.flush()


#@markdown Lerp Settings
# Combines the outputs of different models, used if LerpedModels is chosen as the diffusion model.
# The `cond_model` is a secondary model used to help diffuse, `secondary2` is best for speed.
choose_cond_model = "secondary2" #@param ["secondary2", "OpenAI256", "PixelArtv6", "PixelArtv7", "PixelArtv4", "cc12m", "cc12m_cfg", "WikiArt", "Danbooru", "Imagenet128"] 
lerpWeights = []

#---
#The total sum of weights must add up to 1.0.
###### `use_antijpeg` will include the antijpeg model in the lerp, resulting in clearer results. `use_MakeCutoutsPixelated` will use the cutout method meant for the pixelart models.
use_MakeCutoutsPixelated = False #@param {type:"boolean"}

OpenAI512_weight = 0 #@param {type:"number"}
if OpenAI512_weight != 0:
    lerpWeights.append(OpenAI512_weight)

OpenAI256_weight = 0 #@param {type:"number"}
if OpenAI256_weight != 0:
    lerpWeights.append(OpenAI256_weight)

OpenAIFinetune_weight = 0.3 #@param {type:"number"}
if OpenAIFinetune_weight != 0:
    lerpWeights.append(OpenAIFinetune_weight)

PixelArtv4_weight = 0 #@param {type:"number"}
if PixelArtv4_weight != 0:
    lerpWeights.append(PixelArtv4_weight)

PixelArtv6_weight = 0 #@param {type:"number"}
if PixelArtv6_weight != 0:
    lerpWeights.append(PixelArtv6_weight)

PixelArtv7_weight =  0#@param {type:"number"}
if PixelArtv7_weight != 0:
    lerpWeights.append(PixelArtv7_weight)

cc12m_weight = 0 #@param {type:"number"}
if cc12m_weight != 0:
    lerpWeights.append(cc12m_weight)

cc12m_cfg_weight = 0 #@param {type:"number"}
if cc12m_cfg_weight != 0:
    lerpWeights.append(cc12m_cfg_weight)

WikiArt_weight = 0.7 #@param {type:"number"}
if WikiArt_weight != 0:
    lerpWeights.append(WikiArt_weight)

Danbooru_weight = 0 #@param {type:"number"}
if Danbooru_weight != 0:
    lerpWeights.append(Danbooru_weight)

Imagenet128_weight = 0 #@param {type:"number"}
if Imagenet128_weight != 0:
    lerpWeights.append(Imagenet128_weight)

secondary2_weight = 0 #@param {type:"number"}
if secondary2_weight != 0:
    lerpWeights.append(secondary2_weight)

totalWeight = sum(lerpWeights)
if totalWeight != 1.0:
    raise LerpWeightError("Total weights must add up to 1.0.")

"""# Settings"""

#@markdown Output Settings
use_batch_outputFolder = False #@param {type:"boolean"}
batch_outputFolder = "animation_test" #@param {type:"string"}

#@markdown Run Settings
#seed = None #@param {type:"raw"} # if None, uses the current time in seconds.
image_size = (args.sizex,args.sizey) #@param {type:"raw"}
batch_size = 1 #@param {type:"integer"}
n_batches = 1 #@param {type:"integer"}
steps = args.iterations     #@param {type:"raw"} # Number of steps for sampling. Generally, more = better.

#@markdown Diffusion and CLIP Settings
choose_diffusion_model = args.model #"cc12m" #@param ["LerpedModels","OpenAI", "OpenAIFinetune", "OpenAI256", "cc12m_cfg", "cc12m", "PixelArtv4", "WikiArt", "PixelArtv7_ic_attn", "PixelArtv6","Danbooru", "Imagenet"]

if args.secondary==1:
    use_secondary_model = True #@param {type:"boolean"}
else:
    use_secondary_model = False #@param {type:"boolean"}

if args.antijpeg==1:
    use_antijpeg = True #@param {type:"boolean"}
else:
    use_antijpeg = False #@param {type:"boolean"}

if args.model1==1:
    use_vitb32 = True #@param {type:"boolean"}
else:
    use_vitb32 = False #@param {type:"boolean"}

if args.model2==1:
    use_vitb16 = True #@param {type:"boolean"}
else:
    use_vitb16 = False #@param {type:"boolean"}

if args.model3==1:
    use_vitl14 = True #@param {type:"boolean"}
else:
    use_vitl14 = False #@param {type:"boolean"}

clips = ['ViT-B/16' if use_vitb16 else None, 'ViT-B/32' if use_vitb32 else None, 'ViT-L/14' if use_vitl14 else None]
clips = filternone(clips)

#@markdown Cut Settings
cutn =  args.cutn # 16#@param {type:"raw"} # Effective cutn is cut_batches * this
cut_batches = args.cutbatches #2 #@param {type:"raw"} 
cut_pow = args.cutpow #1.0   #@param {type:"raw"} # Affects the size of cutouts. Larger cut_pow -> smaller cutouts (down to the min of 224x244)
cut_p_mixgrey = None #@param {type:"raw"} # Partially greyscale some cuts. Has weird effect.
cut_p_grey = args.cutgrey #0.2     #@param {type:"raw"} # Fully greyscale some cuts. Tends to improve coherence.
cut_p_flip = args.cutflip #0.5     #@param {type:"raw"} # Flip 50% of cuts to make clip effectively horizontally equivariant. Improves coherence.
if args.huemincuts==1:
    use_huemin_cuts = True #False #test@param {type:"boolean"}
else:
    use_huemin_cuts = False #False #test@param {type:"boolean"}

#@markdown Noise Settings
# sample_mode:
#  prk : high quality, 3x slow (eta=0)
#  plms : high quality, about as fast as ddim (eta=0)
#  ddim : traditional, accepts eta for different noise levels which sometimes have nice aesthetic effect
sample_mode = args.samplemode #'ddim' #@param ["ddim", "plms", "prk"]
eta = args.eta #0.8       #@param {type:"raw"} # Only applies to ddim sample loop: 0.0: DDIM | 1.0: DDPM | -1.0: Extreme noise (q_sample)

#@markdown Cond Settings
ic_cond = "None" #@param {type:"string"}
ic_guidance_scale = 0 #@param {type:"raw"} # For pixelartv7_ic_attn
cfg_guidance_scale =  0#@param {type:"raw"} # For cc12m_1_cfg
aesthetic_loss_scale = args.aestheticlossscale #0.0 #@param {type:"raw"} # For aesthetic loss, requires ViT-B/16
clip_guidance_scale = args.guidancescale #80000 #@param {type:"raw"} # Note: with two perceptors, effective guidance scale is ~2x because they are added together.
antijpeg_guidance_scale =  args.antijpegguidance #0 #@param {type:"raw"}
tv_scale = args.tvscale #0  #@param {type:"raw"} # Smooths out the image
range_scale =  args.rangescale #0#@param {type:"raw"} # Tries to prevent pixel values from going out of range
mean_scale =  args.meanscale #0#@param {type:"raw"} # trends towards middle grey
var_scale =  args.variationscale #0#@param {type:"raw"} # lowers image variation


#@markdown Transformation Settings
if args.horizontal_symmetry==1:
    use_vertical_symmetry = True #@param {type:"boolean"}
    vertical_symmetry_scale = args.vertical_symmetry_scale #0#@param {type:"raw"}
else:
    use_vertical_symmetry = False #@param {type:"boolean"}
    vertical_symmetry_scale = 0#@param {type:"raw"}

if args.vertical_symmetry==1:
    use_horizontal_symmetry = True #@param {type:"boolean"}
    horizontal_symmetry_scale =  args.horizontal_symmetry_scale #0#@param {type:"raw"}
else:
    use_horizontal_symmetry = False #@param {type:"boolean"}
    horizontal_symmetry_scale =  0#@param {type:"raw"}

transformation_schedule = args.transformationschedule #"0.1,0.2,0.3" #@param {type:"string"}

#@markdown Init Settings
"""
use_init = False   #@param {type:"boolean"}
init_image = ""      #@param {type:"string"} 
starting_noise = 1.0   #@param {type:"raw"} # Between 0 and 1. When using init image, generally 0.5-0.8 is good. Lower starting noise makes the result look more like the init.
ending_noise = 0.0     #@param {type:"raw"} # Usually 0.0 for high detail. Can set a little higher like 0.05 to end early for smoother looking result.
skip_percent = 0.0   #@param {type:"raw"}
# Diffusion will start with a mixture of this image with noise.
init_weight_mse = 0    #@param {type:"raw"} # MSE loss between the output and the init makes the result look more like the init (should be between 0 and width*height*3).
"""

if args.init == None:
    use_init = False   #@param {type:"boolean"}    init_image = None
    init_image = ""      #@param {type:"string"} 
    init_weight_mse = 0    #@param {type:"raw"} # MSE loss between the output and the init makes the result look more like the init (should be between 0 and width*height*3).
    starting_noise = 1.0   #@param {type:"raw"} # Between 0 and 1. When using init image, generally 0.5-0.8 is good. Lower starting noise makes the result look more like the init.
    ending_noise = 0.0     #@param {type:"raw"} # Usually 0.0 for high detail. Can set a little higher like 0.05 to end early for smoother looking result.
    skip_percent = 0.0   #@param {type:"raw"}
else:
    use_init = True   #@param {type:"boolean"}    init_image = None
    init_image = args.init
    init_weight_mse = args.initweight #0    #@param {type:"raw"} # MSE loss between the output and the init makes the result look more like the init (should be between 0 and width*height*3).
    starting_noise = args.startnoise #1.0   #@param {type:"raw"} # Between 0 and 1. When using init image, generally 0.5-0.8 is good. Lower starting noise makes the result look more like the init.
    ending_noise = args.endnoise #0.0     #@param {type:"raw"} # Usually 0.0 for high detail. Can set a little higher like 0.05 to end early for smoother looking result.
    skip_percent = args.skippercent #0.0   #@param {type:"raw"}







#@markdown Animation Settings
max_frames = args.max_frames #1000 #@param {type:"number"}
prev_frame_clip_guidance_scale = args.prevguidancescale #160000 #@param {type:"raw"} # Note: with two perceptors, effective guidance scale is ~2x because they are added together.
prev_frame_cfg_guidance_scale = args.prevcfgguidancescale #0 #@param {type:"raw"}
prev_frame_starting_noise = args.prevstartingnoise #1.0 #@param{type: 'number'}
prev_frame_ending_noise = args.prevendingnoise #0.0 #@param{type: 'number'}
prev_frame_skip_percent = args.prevskippercent #0.5 #@param{type: 'number'}
prev_frame_weight_mse = args.prevmseweight #100 #@param{type: 'number'}

use_prev_frame_image_prompt = True #@param {type:"boolean"}

#@markdown Keyframe Settings
key_frames = True #@param {type:"boolean"}
max_frames = args.max_frames #1000#@param {type:"number"}

#VOC START - DO NOT DELETE
angle = "0:(0)"
zoom = "0:(1.02)"
translation_x = "0:(0)"
translation_y = "0:(0)"
#VOC FINISH - DO NOT DELETE


#@markdown Prompt
all_title = args.prompt #"scifi trending on artstation:2" #@param {type:"string"}


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
    key_frame_series = key_frame_series.interpolate(limit_direction='both')
    if integer:
        return key_frame_series.astype(int)
    return key_frame_series



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


else:
    angle = float(angle)
    zoom = float(zoom)
    translation_x = float(translation_x)
    translation_y = float(translation_y)

# make sure you dont get an error when you do the run
outputFolder = get_output_folder(outputFolderStatic, choose_diffusion_model, batch_outputFolder, use_batch_outputFolder)

"""# Animate"""

#@markdown Display Rate
use_display_rate = True #@param {type:"boolean"}
display_rate = args.update #@param {type:"integer"}

#@markdown Display Percent
use_display_percent = False #@param {type:"boolean"}
display_percent = "0.6,0.8" #@param {type:"string"}

#@markdown Display Init
use_display_init = False #@param {type:"boolean"}

def config():
    
    vitb32 = lambda: get_clip('ViT-B/32')
    vitb16 = lambda: get_clip('ViT-B/16')
    vitl14 = lambda: get_clip('ViT-L/14')

    if choose_diffusion_model == "LerpedModels":

        sys.stdout.write("Loading lerped models ...\n")
        sys.stdout.flush()
    
        # -- Combine different models to a single output --
        
        modelsToLerp = []
        cond_model = None

        if OpenAI512_weight != 0:
            openai512Lerp = openai_512()
            modelsToLerp.append(openai512Lerp)
        if OpenAI256_weight != 0 or choose_cond_model == "OpenAI256":
            openai256Lerp = openai_256()
            modelsToLerp.append(openai256Lerp) if OpenAI256_weight != 0 else None
            cond_model = openai256Lerp if choose_cond_model == "OpenAI256" else cond_model
        if OpenAIFinetune_weight != 0:
            openaifinetuneLerp = openai_512_finetune()
            modelsToLerp.append(openaifinetuneLerp)
        if PixelArtv4_weight != 0 or choose_cond_model == "PixelArtv4":
            pixelartv4Lerp = pixelartv4_wrap(pixelartv4_params())
            modelsToLerp.append(pixelartv4Lerp) if PixelArtv4_weight != 0 else None
            cond_model = pixelartv4Lerp if choose_cond_model == "PixelArtv4" else cond_model
        if PixelArtv6_weight != 0 or choose_cond_model == "PixelArtv6":
            pixelartv6Lerp = pixelartv6_wrap()
            modelsToLerp.append(pixelartv6Lerp) if PixelArtv6_weight != 0 else None
            cond_model = pixelartv6Lerp if choose_cond_model == "PixelArtv6" else cond_model
        if PixelArtv7_weight != 0 or choose_cond_model == "PixelArtv7":
            cond = jnp.array(TF.to_tensor(Image.open(fetch(ic_cond)).convert('RGB'))) * 2 - 1
            cond = jnp.concatenate([cond]*(image_size[1]//cond.shape[-2]+1), axis=-2)[:, :image_size[1], :]
            cond = jnp.concatenate([cond]*(image_size[0]//cond.shape[-1]+1), axis=-1)[:, :, :image_size[0]]
            cond = cond.broadcast_to([batch_size, 3, image_size[1], image_size[0]])
            pixelartv7Lerp = pixelartv7_ic_attn(cond, ic_guidance_scale)
            modelsToLerp.append(pixelartv7Lerp) if PixelArtv7_weight != 0 else None
            cond_model = pixelartv7Lerp if choose_cond_model == "PixelArtv7" else cond_model
        if cc12m_weight != 0 or choose_cond_model == "cc12m":
            cc12mLerp = cc12m_1_wrap(clip_embed=process_prompts(vitb16(),title).squeeze(0) if ('.png' or '.jpg') in all_title else vitb16().embed_texts(process_prompts(vitb16(),title)))
            modelsToLerp.append(cc12mLerp) if cc12m_weight != 0 else None
            cond_model = cc12mLerp if choose_cond_model == "cc12m" else cond_model
        if cc12m_cfg_weight != 0 or choose_cond_model == "cc12m_cfg":
            cc12m_cfgLerp = cc12m_1_cfg_wrap(clip_embed=process_prompts(vitb16(), title), cfg_guidance_scale=local_cfg_guidance_scale)
            modelsToLerp.append(cc12m_cfgLerp) if cc12m_cfg_weight != 0 else None
            cond_model = cc12m_cfgLerp if choose_cond_model == "cc12m_cfg" else cond_model
        if WikiArt_weight != 0 or choose_cond_model == "WikiArt":
            wikiartLerp = wikiart_256()
            modelsToLerp.append(wikiartLerp) if WikiArt_weight != 0 else None
            cond_model = wikiartLerp if choose_cond_model == "WikiArt" else cond_model
        if Danbooru_weight != 0 or choose_cond_model == "Danbooru":
            danbooruLerp = danbooru_128()
            modelsToLerp.append(danbooruLerp) if Danbooru_weight != 0 else None
            cond_model = danbooruLerp if choose_cond_model == "Danbooru" else cond_model
        if Imagenet128_weight != 0 or choose_cond_model == "Imagenet128":
            Imagenet128Lerp = imagenet_128()
            modelsToLerp.append(Imagenet128Lerp) if Imagenet128_weight != 0 else None
            cond_model = Imagenet128Lerp if choose_cond_model == "Imagenet128" else cond_model
        if secondary2_weight != 0 or choose_cond_model == "secondary2":
            secondary2 = secondary2_wrap()
            modelsToLerp.append(secondary2) if secondary2_weight != 0 else None
            cond_model = secondary2 if choose_cond_model == "secondary2" else cond_model
        if use_antijpeg:
            antiJpegLerp = anti_jpeg_cfg()
            modelsToLerp.append(antiJpegLerp)
            lerpWeights.append(1.0)
            jpeg_classifier_fn = jpeg_classifier_wrap(jpeg_classifier_params(),
                                                      guidance_scale=antijpeg_guidance_scale, # will generally depend on image size
                                                      flood_level=0.7, # Prevent over-optimization
                                                      blur_size=3.0)
            
        diffusion = LerpModels([(model, weight) for model, weight in zip(modelsToLerp, lerpWeights)])

    else:

        sys.stdout.write("Loading models ...\n")
        sys.stdout.flush()
    
        if choose_diffusion_model == 'OpenAI':
          diffusion = openai_512()
        if choose_diffusion_model == 'OpenAI256':
          diffusion = openai_256()
        elif choose_diffusion_model in ('WikiArt', 'Danbooru', 'Imagenet'):
          if choose_diffusion_model == 'WikiArt':
              diffusion = wikiart_256()
          elif choose_diffusion_model == 'Danbooru':
              diffusion = danbooru_128()
          elif choose_diffusion_model == 'Imagenet':
              diffusion = imagenet_128()
        elif 'PixelArt' in choose_diffusion_model:
          # -- pixel art model --
          if choose_diffusion_model == 'PixelArtv7_ic_attn':
              cond = jnp.array(TF.to_tensor(Image.open(fetch(ic_cond)).convert('RGB'))) * 2 - 1
              cond = jnp.concatenate([cond]*(image_size[1]//cond.shape[-2]+1), axis=-2)[:, :image_size[1], :]
              cond = jnp.concatenate([cond]*(image_size[0]//cond.shape[-1]+1), axis=-1)[:, :, :image_size[0]]
              cond = cond.broadcast_to([batch_size, 3, image_size[1], image_size[0]])
              diffusion = pixelartv7_ic_attn(cond, ic_guidance_scale)
          elif choose_diffusion_model == 'PixelArtv6':
              diffusion = pixelartv6_wrap(pixelartv6_params())
          elif choose_diffusion_model == 'PixelArtv4':
              diffusion = pixelartv4_wrap(pixelartv4_params())
              diffusion = pixelartv4_wrap(pixelartv4_params())
        elif choose_diffusion_model == 'cc12m':
          diffusion = cc12m_1_wrap(cc12m_1_params(), clip_embed=process_prompts(vitb16(), title))
        elif choose_diffusion_model == 'cc12m_cfg':
          diffusion = cc12m_1_cfg_wrap(clip_embed=process_prompts(vitb16(), title), cfg_guidance_scale=local_cfg_guidance_scale)
        elif choose_diffusion_model == 'OpenAIFinetune':
            diffusion = openai_512_finetune()

        if use_secondary_model:
          cond_model = secondary2_wrap()
        else:
          cond_model = diffusion

        if use_antijpeg:
          diffusion = LerpModels([(diffusion, 1.0),
                                  (anti_jpeg_cfg(), 1.0)])
          jpeg_classifier_fn = jpeg_classifier_wrap(jpeg_classifier_params(),
                                                      guidance_scale=antijpeg_guidance_scale, # will generally depend on image size
                                                      flood_level=0.7, # Prevent over-optimization
                                                      blur_size=3.0)

    if use_antijpeg and (antijpeg_guidance_scale > 0):
      cond_fn = CondFns(MainCondFn(cond_model, [
        CondCLIP(vitb32(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitb32(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None)
        if use_vitb32 and local_clip_guidance_scale > 0 else None,

        CondCLIP(vitb16(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitb16(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None,
                AestheticExpected(aesthetic_loss_scale) if aesthetic_loss_scale > 0 else None)
        if use_vitb16 and (local_clip_guidance_scale > 0 or aesthetic_loss_scale > 0) else None,

        CondCLIP(vitl14(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitl14(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None)
        if use_vitl14 and local_clip_guidance_scale > 0 else None,

        CondTV(tv_scale) if tv_scale > 0 else None,
        CondMSE(local_init_array, init_weight_mse) if init_weight_mse > 0 else None,
        CondRange(range_scale) if range_scale > 0 else None,
        CondMean(mean_scale) if mean_scale > 0 else None,
        CondVar(var_scale) if var_scale > 0 else None,
        CondHorizontalSymmetry(horizontal_symmetry_scale) if horizontal_symmetry_scale > 0 else None,
        CondVerticalSymmetry(vertical_symmetry_scale) if vertical_symmetry_scale > 0 else None,
      ]), jpeg_classifier_fn)
    else:
      cond_fn = MainCondFn(cond_model, [
        CondCLIP(vitb32(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitb32(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None)
        if use_vitb32 and local_clip_guidance_scale > 0 else None,

        CondCLIP(vitb16(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitb16(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None,
                AestheticExpected(aesthetic_loss_scale) if aesthetic_loss_scale > 0 else None)
        if use_vitb16 and (local_clip_guidance_scale > 0 or aesthetic_loss_scale > 0) else None,

        CondCLIP(vitl14(), make_cutouts, cut_batches,
                SphericalDistLoss(process_prompts(vitl14(), title), local_clip_guidance_scale) if local_clip_guidance_scale > 0 else None)
        if use_vitl14 and local_clip_guidance_scale > 0 else None,

        CondTV(tv_scale) if tv_scale > 0 else None,
        CondMSE(local_init_array, init_weight_mse) if init_weight_mse > 0 else None,
        CondRange(range_scale) if range_scale > 0 else None,
        CondMean(mean_scale) if mean_scale > 0 else None,
        CondVar(var_scale) if var_scale > 0 else None,
        CondHorizontalSymmetry(horizontal_symmetry_scale) if horizontal_symmetry_scale > 0 else None,
        CondVerticalSymmetry(vertical_symmetry_scale) if vertical_symmetry_scale > 0 else None,
      ])

    return diffusion, cond_fn

def sanitize(title):
  return title[:100].replace('/', '_').replace('\\', '_')

@torch.no_grad()
def run_animation(n_frame):
    
    rng = PRNG(jax.random.PRNGKey(int(time.time())))

    for i in range(n_batches):

        ts = schedule
        alphas, sigmas = cosine.to_alpha_sigma(ts)
        print(ts[0], sigmas[0], alphas[0])

        x = jax.random.normal(rng.split(), [batch_size, 3, image_size[1], image_size[0]])

        if local_init_array is not None:
            x = sigmas[0] * x + alphas[0] * local_init_array

        sys.stdout.write("Setting up sampler ...\n")
        sys.stdout.flush()

        # main loop
        if sample_mode == 'ddim':
          sample_loop = partial(sampler.ddim_sample_loop, eta=eta)
        elif sample_mode == 'prk':
          sample_loop = sampler.prk_sample_loop
        elif sample_mode == 'plms':
          sample_loop = sampler.plms_sample_loop

        sys.stdout.write("Starting ...\n")
        sys.stdout.flush()

        for output in sampler.ddim_sample_loop(diffusion, cond_fn, x, schedule, rng.split(), x_fn = x_transformation):
            j = output['step']

            if j<args.iterations: sys.stdout.write(f"Iteration {j+1}\n")
            sys.stdout.flush()
            
            pred = output['pred']
            assert x.isfinite().all().item()

            # display init
            #if (use_display_init and j == 0) and (local_init_array is not None):
            #  display_images(pred)
            
            # rate
            if (((j+1) % display_rate) == 0 and use_display_rate) and (j not in [0,len(schedule)-1] ):
              #display_images(pred)
                
              sys.stdout.flush()
              sys.stdout.write("Saving progress ...\n")
              sys.stdout.flush()

              images = pred.add(1).div(2).clamp(0, 1)
              images = torch.tensor(np.array(images))
              for k in range(batch_size):
                pil_image = TF.to_pil_image(images[k])
                #pil_image.save(f'{outputFolder}{timestring}_{str(n_frame).zfill(len(str(max_frames)))}.png')
                pil_image.save(f'{args.image_file}')

              sys.stdout.flush()
              sys.stdout.write("Progress saved\n")
              sys.stdout.flush()
        
        
              

            # percent
            #if ((j in display_steps) and use_display_percent) and j != len(schedule)-1:
            #  display_images(pred)

        """
        #save samples
        #display_images(pred)
        images = pred.add(1).div(2).clamp(0, 1)
        images = torch.tensor(np.array(images))
        for k in range(batch_size):
          pil_image = TF.to_pil_image(images[k])
          #pil_image.save(f'{outputFolder}{timestring}_{str(n_frame).zfill(len(str(max_frames)))}.png')
          pil_image.save(f'{args.image_file}')
        """

        #save next frame
        if max_frames>1:
            sys.stdout.flush()
            sys.stdout.write("Saving next frame ...\n")
            sys.stdout.flush()

            images = pred.add(1).div(2).clamp(0, 1)
            images = torch.tensor(np.array(images))
            for k in range(batch_size):
                pil_image = TF.to_pil_image(images[k])
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
                pil_image.save(save_name)
        
            sys.stdout.flush()
            sys.stdout.write("Frame saved\n\n")
            sys.stdout.flush()

    return(pred)

# main
try:

  # wip batch titles
  batch_titles = [all_title]*max_frames

  # loop over prompts in batch_titles
  for ii in range(max_frames):

    sys.stdout.write(f"Generating frame {ii+1}/{max_frames}\n")
    sys.stdout.flush()
    
    local_title = batch_titles[ii]
    if ii > 0 and use_prev_frame_image_prompt:
      local_title = local_title + "| firstFrame.png:0.01 | prevFrame.png:0.01"
    
    title = expand([local_title], batch_size)

    if ii == 0:
      # initalize first frame
      timestring = time.strftime('%Y%m%d%H%M%S')
      local_seed = int(time.time())
      #save_still_settings(local_seed,outputFolder,timestring)

      #print(f'Starting run ({timestring}) of ({all_title}) with seed ({local_seed})...')
      #print(f"Loading {choose_diffusion_model}...")

      # init
      if use_init:
        try:
          if type(init_image) is list:
            init_array = sum(load_image(url) for url in init_image) / len(init_image)
          elif type(init_image) is str:
            init_array = jnp.concatenate([load_image(it) for it in braceexpand(init_image)], axis=0)
          else:
            init_array = None
        except:
          init_array = load_image(init_location+init_image)
      
      # local noise and init assignment
      if use_init:
        local_init_array = init_array
      else:
        local_init_array = None
      local_starting_noise = starting_noise
      local_skip_percent = skip_percent
      local_init_weight_mse = init_weight_mse
      local_clip_guidance_scale = clip_guidance_scale
      local_cfg_guidance_scale = cfg_guidance_scale
      local_ending_noise = ending_noise
      local_steps = steps

    # next frame
    if ii > 0:
      #local_init_array = init_array
      local_starting_noise = prev_frame_starting_noise
      local_skip_percent = prev_frame_skip_percent
      local_init_weight_mse = prev_frame_weight_mse
      local_clip_guidance_scale = prev_frame_clip_guidance_scale
      local_cfg_guidance_scale = prev_frame_cfg_guidance_scale
      local_ending_noise = prev_frame_ending_noise
      local_steps = steps

      # key frames
      img_0 = cv2.imread('prevFrame.png')
      if key_frames:
        angle = angle_series[ii]
        zoom = zoom_series[ii]
        translation_x = translation_x_series[ii]
        translation_y = translation_y_series[ii]
        """
        print(f'angle: {angle}')
        print(f'zoom: {zoom}')
        print(f'translation_x: {translation_x}')
        print(f'translation_y: {translation_y}')
        """
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
      cv2.imwrite('prevFrame.png', img_0)
      local_init_array = load_image('prevFrame.png')

    # preperation
    schedule = jnp.linspace(local_starting_noise, local_ending_noise, local_steps+1)
    schedule = spliced.to_cosine(schedule)
    if local_skip_percent > 0:
      skip_steps = int(local_skip_percent*local_steps)
      schedule = schedule[skip_steps:]
      local_steps = local_steps-skip_steps

    if use_display_percent:
      temp = [float(vals) for vals in display_percent.split(",")]
      display_steps = [int(local_steps*percent) for percent in temp]
    else:
      display_steps = []

    sys.stdout.write("Making cutouts ...\n")
    sys.stdout.flush()

    if use_huemin_cuts:
      make_cutouts = MakeCutouts_huemin(clip_size, cutn, cut_pow=cut_pow, p_grey=cut_p_grey, p_flip=cut_p_grey, p_mixgrey=cut_p_mixgrey)
    else:
      make_cutouts = MakeCutouts(clip_size, cutn, cut_pow=cut_pow, p_grey=cut_p_grey, p_flip=cut_p_grey, p_mixgrey=cut_p_mixgrey)
    
    sys.stdout.write("Setting up transformation schedule ...\n")
    sys.stdout.flush()

    # transformation functions
    transformation_percent = [float(vals) for vals in transformation_schedule.split(",")]
    transformation_steps = [int(local_steps*i) for i in transformation_percent]
    t_schedule = [schedule[i] for i in transformation_steps]

    def x_transformation(x,t):
      if use_horizontal_symmetry:
        if t in t_schedule:
          [n, c, h, w] = x.shape
          x = jnp.concatenate([x[:, :, :, :w//2], jnp.flip(x[:, :, :, :w//2],-1)], -1)
          #sys.stdout.write("Horizontal symmetry applied\n")
          sys.stdout.write("Vertical symmetry applied\n")
          sys.stdout.flush()
      if use_vertical_symmetry:
        if t in t_schedule:
          [n, c, h, w] = x.shape
          x = jnp.concatenate([x[:, :, :h//2, :], jnp.flip(x[:, :, :h//2, :],-2)], -2)
          #sys.stdout.write("Vertical symmetry applied\n")
          sys.stdout.write("Horizontal symmetry applied\n")
          sys.stdout.flush()
      return x

    # config run
    diffusion, cond_fn = config()
    
    # run
    pred = run_animation(ii)

    # convert pred to image
    images = pred.add(1).div(2).clamp(0, 1)
    images = torch.tensor(np.array(images))
    pil_image = TF.to_pil_image(images[0])
    pil_image.save('prevFrame.png')
    if ii == 0:
      pil_image.save('firstFrame.png')

    success = True

except:
  import traceback
  traceback.print_exc()
  success = False
assert success
