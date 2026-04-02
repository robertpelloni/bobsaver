# deep-daze Fourier Feature Map
# Original notebook https://colab.research.google.com/gist/afiaka87/e018dfa86d8a716662d30c543ce1b78e/text2image-siren.ipynb

import os
import sys
import time
import random
import imageio
import numpy as np
import PIL
from skimage import exposure
from base64 import b64encode
from tqdm import trange, tqdm
import random
import torch
import torch.nn as nn
import torchvision
from IPython.display import HTML, Image, display, clear_output
from IPython.core.interactiveshell import InteractiveShell
import ipywidgets as ipy
from CLIP.clip import clip
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_phrase', type=str, help='Text to generate image from.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--seed', type=int, help='Image random seed.')
  parser.add_argument('--iterations', type=int, help='Number of iterations.')
  parser.add_argument('--save_every', type=int, help='Save after n iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate')
  parser.add_argument('--samples', type=int, help='Samples')
  parser.add_argument('--siren_layers', type=int, help='Siren layers')
  parser.add_argument('--siren_hidden_features', type=int, help='Siren hidden features')
  parser.add_argument('--use_fourier_maps', type=bool, help='Use fourier maps')
  parser.add_argument('--uniform_symmetries', type=bool, help='Uniform symmetries')
  parser.add_argument('--fourier_maps', type=int, help='Fourier maps')
  parser.add_argument('--fourier_scale', type=float, help='Fourier scale')
  parser.add_argument('--clip_model', type=str, help='CLIP model to use.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();

sys.stdout.write("Loading "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model,jit=False)

workdir = ''
tempdir = os.path.join(workdir, '')

# Libs

class SineLayer(nn.Module):
  def __init__(self, in_features, out_features, bias=True, is_first=False, omega_0=30):
    super().__init__()
    self.omega_0 = omega_0
    self.is_first = is_first
    self.in_features = in_features
    self.linear = nn.Linear(in_features, out_features, bias=bias)
    self.init_weights()
  
  def init_weights(self):
    with torch.no_grad():
      if self.is_first:
        lim = 1 / self.in_features
      else:
        lim = np.sqrt(6 / self.in_features) / self.omega_0
      self.linear.weight.uniform_(-lim, lim)
      
  def forward(self, input):
    return torch.sin(self.omega_0 * self.linear(input))
    
class Siren(nn.Module):
  def __init__(self, in_features, hidden_features, hidden_layers, out_features, outermost_linear=True, 
                first_omega_0=30, hidden_omega_0=30.):
    super().__init__()
      
    self.net = []
    self.net.append(SineLayer(in_features, hidden_features, is_first=True, omega_0=first_omega_0))

    for i in range(hidden_layers):
      self.net.append(SineLayer(hidden_features, hidden_features, is_first=False, omega_0=hidden_omega_0))

    if outermost_linear:
      final_linear = nn.Linear(hidden_features, out_features)
      with torch.no_grad():
        lim = np.sqrt(6 / hidden_features) / hidden_omega_0
        final_linear.weight.uniform_(-lim, lim)
      self.net.append(final_linear)
    else:
      self.net.append(SineLayer(hidden_features, out_features, is_first=False, omega_0=hidden_omega_0))
    
    self.net = nn.Sequential(*self.net)
  
  def forward(self, coords):
    coords = coords.clone().detach().requires_grad_(True)
    output = self.net(coords.cuda())
    return output.view(1, sideY, sideX, 3).permute(0, 3, 1, 2)#.sigmoid_()

def get_mgrid(sideX, sideY):
  tensors = [np.linspace(-1, 1, num=sideY), np.linspace(-1, 1, num=sideX)]
  mgrid = np.stack(np.meshgrid(*tensors), axis=-1)
  mgrid = mgrid.reshape(-1, 2) # dim 2
  return mgrid

# Preprocessing coords with Fourier feature mapping
def fourierfm(xy, map=256, fourier_scale=4, mapping_type='gauss'):

  def input_mapping(x, B): # feature mappings
    x_proj = (2.*np.pi*x) @ B
    y = np.concatenate([np.sin(x_proj), np.cos(x_proj)], axis=-1)
    #print(' mapping input:', x.shape, 'output', y.shape)
    return y

  if mapping_type == 'gauss': # Gaussian Fourier feature mappings
    B = np.random.randn(2, map) 
    B *= fourier_scale # scale Gauss
  else: # basic
    B = np.eye(2).T

  xy = input_mapping(xy, B)
  return xy

def slice_imgs(imgs, count, transform=None, uniform=False, micro=None):
  def map(x, a, b):
    return x * (b-a) + a

  rnd_size = torch.rand(count)
  if uniform is True:
    rnd_offx = torch.rand(count)
    rnd_offy = torch.rand(count)
  else: # normal around center
    rnd_offx = torch.clip(torch.randn(count) * 0.2 + 0.5, 0, 1) 
    rnd_offy = torch.clip(torch.randn(count) * 0.2 + 0.5, 0, 1)
  
  sz = [img.shape[2:] for img in imgs]
  sz_min = [np.min(s) for s in sz]
  if uniform is True:
    sz = [[2*s[0], 2*s[1]] for s in list(sz)]
    imgs = [pad_up_to(imgs[i], sz[i], type='centr') for i in range(len(imgs))]

  sliced = []
  for i, img in enumerate(imgs):
    cuts = []
    for c in range(count):
      if micro is True: # both scales, micro mode
        csize = map(rnd_size[c], 64, max(224, 0.25*sz_min[i])).int()
      elif micro is False: # both scales, macro mode
        csize = map(rnd_size[c], 0.5*sz_min[i], 0.98*sz_min[i]).int()
      else: # single scale
        csize = map(rnd_size[c], 64, 0.98*sz_min[i]).int()
      offsetx = map(rnd_offx[c], 0, sz[i][1] - csize).int()
      offsety = map(rnd_offy[c], 0, sz[i][0] - csize).int()
      cut = img[:, :, offsety:offsety + csize, offsetx:offsetx + csize]
      cut = torch.nn.functional.interpolate(cut, (224,224), mode='bicubic')
      if transform is not None: 
        cut = transform(cut)
      cuts.append(cut)
    sliced.append(torch.cat(cuts, 0))
  return sliced

# Tiles an array around two points, allowing for pad lengths greater than the input length
# adapted from https://discuss.pytorch.org/t/symmetric-padding/19866/3
def tile_pad(xt, padding):
  h, w = xt.shape[-2:]
  left, right, top, bottom = padding

  def tile(x, minx, maxx):
    rng = maxx - minx
    mod = np.remainder(x - minx, rng)
    out = mod + minx
    return np.array(out, dtype=x.dtype)

  x_idx = np.arange(-left, w+right)
  y_idx = np.arange(-top, h+bottom)
  x_pad = tile(x_idx, -0.5, w-0.5)
  y_pad = tile(y_idx, -0.5, h-0.5)
  xx, yy = np.meshgrid(x_pad, y_pad)
  return xt[..., yy, xx]

def pad_up_to(x, size, type='centr'):
  sh = x.shape[2:][::-1]
  if list(x.shape[2:]) == list(size): return x
  padding = []
  for i, s in enumerate(size[::-1]):
    if 'side' in type.lower():
      padding = padding + [0, s-sh[i]]
    else: # centr
      p0 = (s-sh[i]) // 2
      p1 = s-sh[i] - p0
      padding = padding + [p0,p1]
  y = tile_pad(x, padding)
  return y

text = args.input_phrase
#Optional Prompts
fine_details = ""
subtract = ""
#Other CLIP Options 
invert = False
sign = 1. if invert is True else -1
sideX = args.sizex
sideY = args.sizey

#Symmetries
uniform = args.uniform_symmetries # originally True
#Training
steps = args.iterations
save_freq = args.save_every
learning_rate = args.learning_rate # original .00008
samples = args.samples # original 64
#Network
siren_layers = args.siren_layers # original 16
siren_hidden_features = args.siren_hidden_features # original 256
use_fourier_feat_map = args.use_fourier_maps
fourier_maps = args.fourier_maps # original 128
fourier_scale = args.fourier_scale # original 2 - 1 gives larger sized features - the default of 2 tends to give multiple small objects

out_name = text.replace(' ', '_')

mgrid = get_mgrid(sideY, sideX) # [262144,2]
if use_fourier_feat_map:
  mgrid = fourierfm(mgrid, fourier_maps, fourier_scale, 'gauss')
mgrid = torch.from_numpy(mgrid.astype(np.float32)).cuda()

model = Siren(mgrid.shape[-1], siren_hidden_features, siren_layers, 3).cuda()

norm_in = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

if len(text) > 2:
  #print(' macro:', text)
  tx = clip.tokenize(text)
  txt_enc = perceptor.encode_text(tx.cuda()).detach().clone()

if len(fine_details) > 0:
  #print(' micro:', fine_details)
  tx2 = clip.tokenize(fine_details)
  txt_enc2 = perceptor.encode_text(tx2.cuda()).detach().clone()

if len(subtract) > 0:
  #print(' without:', subtract)
  tx0 = clip.tokenize(subtract)
  txt_enc0 = perceptor.encode_text(tx0.cuda()).detach().clone()

sys.stdout.write("Setting optimizer ...\n")
sys.stdout.flush()

optimizer = torch.optim.Adam(model.parameters(), learning_rate)

def displ(img, fname=None):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1,2,0))  
  img = exposure.equalize_adapthist(np.clip(img, -1., 1.))
  img = np.clip(img*255, 0, 255).astype(np.uint8)
  if fname is not None:
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()
    
    imageio.imsave(args.image_file, np.array(img))
  
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
      imageio.imsave(save_name, np.array(img))
    
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

def checkin(num):
  with torch.no_grad():
    img = model(mgrid).cpu().numpy()[0]
  displ(img, os.path.join(tempdir, '%03d.jpg' % num))

def train(i):
  img_out = model(mgrid)
  imgs_sliced = slice_imgs([img_out], samples, norm_in, uniform)
  out_enc = perceptor.encode_image(imgs_sliced[-1])
  loss = 0
  if len(text) > 0: # input text
      loss += sign * 100*torch.cosine_similarity(txt_enc, out_enc, dim=-1).mean()
  if len(subtract) > 0: # subtract text
      loss += -sign * 100*torch.cosine_similarity(txt_enc0, out_enc, dim=-1).mean()
  if len(fine_details) > 0: # input text for micro details
      imgs_sliced = slice_imgs([img_out], samples, norm_in, uniform=uniform, micro=True)
      out_enc2 = perceptor.encode_image(imgs_sliced[-1])
      loss += sign * 100*torch.cosine_similarity(txt_enc2, out_enc2, dim=-1).mean()
      del out_enc2; torch.cuda.empty_cache()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  sys.stdout.write("Iteration {}".format(i)+"\n")
  sys.stdout.flush()
  
  if i % save_freq == 0:
    checkin(i // save_freq)

outpic = ipy.Output()
outpic

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
for i in range(steps):
  train(itt)
  itt+=1
