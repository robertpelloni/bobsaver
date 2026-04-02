# Pixel MultiColors + CLIP [Public]
# Original file is located at https://colab.research.google.com/drive/17c-13cl_VQKpHq2rDrnFVi6ZT-CHeZNn
# by [@remi_durant](https://twitter/remi_durant)

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch 
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
import torch.optim as optim
import kornia
import kornia.augmentation as K
from CLIP import clip
from torchvision import transforms
import warnings
from PIL import Image
import numpy as np
import math
from matplotlib import pyplot as plt
from IPython.display import HTML
from base64 import b64encode
import io
import base64
from IPython import display
from torchvision.transforms import functional as TF
import torch
import random
import numpy as np
import torch
import math
import torchvision
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--clipmodel', type=str, help='CLIP Model.')
  parser.add_argument('--iterations', type=int, help='Max iterations.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--size', type=int, help='Image width and height.')
  parser.add_argument('--colorchannels', type=int, help='How many color channels.')
  parser.add_argument('--usehsv', type=int, help='Use HSV.')
  parser.add_argument('--cutn', type=int, help='Cutouts.')
  parser.add_argument('--cutpow', type=float, help='Cutout power.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--pixellearningrate', type=float, help='Pixel learning rate.')
  parser.add_argument('--colorlearningrate', type=float, help='Color learning rate.')
  parser.add_argument('--brightness', type=float, help='Display brightness.')
  parser.add_argument('--contrast', type=float, help='Display contrast.')
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


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))


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

class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.augs = nn.Sequential(
            #K.RandomGaussianNoise(mean=0.0, std=0.5, p=0.1),
            K.RandomHorizontalFlip(p=0.5),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
            K.RandomPerspective(0.2,p=0.4),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),
            K.RandomGrayscale(p=0.1),
        )
        self.noise_fac = 0.02 

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
        batch = self.augs(torch.cat(cutouts, dim=0))
        if self.noise_fac:
            facs = batch.new_empty([self.cutn, 1, 1, 1]).uniform_(0, self.noise_fac)
            batch = batch + facs * torch.randn_like(batch)
        return batch

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

class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward
 
    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)
 
def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])

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

def resample(input, size, align_corners=True, no_scale=False):
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
    if no_scale:
      return input

    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)

replace_grad = ReplaceGrad.apply 
clamp_with_grad = ClampWithGrad.apply

sys.stdout.write("Loading "+args.clipmodel+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clipmodel, jit=False)[0].eval().requires_grad_(False).to(device)
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
cut_size = perceptor.visual.input_resolution


def image_to_data_url(img, ext):  
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format=ext)
    img_byte_arr = img_byte_arr.getvalue()
    # ext = filename.split('.')[-1]
    prefix = f'data:image/{ext};base64,'
    return prefix + base64.b64encode(img_byte_arr).decode('utf-8')
 
def display_img(out, fmt='jpeg'):
   with torch.no_grad():
     imgdata = image_to_data_url(TF.to_pil_image(out[0].cpu()), fmt)
     display.display(display.HTML(f'<img src="{imgdata}" />'))

def to_pil(tensor):
  with torch.no_grad():
        return Image.fromarray((tensor.detach().cpu().squeeze().expand(3,-1,-1).permute([1, 2, 0]) * 255).numpy().astype(np.uint8))

def dot_batch(v1,n):
  return v1[...,0] * n[...,0] + v1[...,1] * n[...,1]

def dbg_print(name, tensor, print_tensor=False):
  print(f'{name}: {tensor.shape} {tensor.names}')
  if (print_tensor): print(tensor)

class UnsqueezeDimsToMatch(nn.Module):
    def __init__(self, at=1, ndims=5):
        super().__init__()
        self.at = at
        self.ndims = ndims

    def forward(self, ten, ndims=None ):
        needdims = ( ndims or self.ndims ) - ten.ndim
        if (needdims > 0 ):
            s = list(ten.shape)
            s[self.at:self.at] = [1] * needdims
            return ten.view( *s)
        else:
            return ten

class Gauss(nn.Module):
  def __init__(self,sigma=1):
      super().__init__()
      self.sigma = sigma

  def forward(self, input):
    return torch.exp( input**2 / ( -2.0 * self.sigma ** 2 ) )

def NTremix( tensor, target_dims, align='left', squeeze=True ):
  
  # remove extra dimensions
  if ( squeeze ):
    tensor = tensor.squeeze()
    
  # add missing dimensions
  dim0 = tensor.names[0]
  target_set = set(target_dims)
  missing = [(dim0,tensor.size(dim0))]
  missing += [(v,1) for v in (target_set - set(tensor.names)) if v != Ellipsis]

  tensor = tensor.unflatten( dim0, missing )

  # align to target
  if (Ellipsis not in target_set):
    if align == 'left':
      target_dims = list(target_dims) + [...] 
    elif align == 'right':
      target_dims = [...] + list(target_dims)

  tensor = tensor.align_to( *target_dims )

  return tensor

def NTstack(tensors, name, dim=0 ):
  names = set(tensors[0].names)
  tensors[0].names = None
  for t in tensors[1:]:
    if ( names != set(t.names) ):
      print('Failed')
    t.names = None
  
  out = torch.stack( tensors, dim=dim )
  names =  list(names)
  names.insert(dim, name)
  out.names = names

  return out

def NTsum(tensor, name, keepdim=False):
  dim = tensor.names.index(name)
  return tensor.sum(dim, keepdim)

def NTindex(tensor, index):
  names = tensor.names
  tensor.names = None
  tensor = tensor[index]
  tensor.names = names
  return tensor.clone()
  
class RemixTensor(nn.Module):
  def __init__(self, target_dims, align='left', squeeze=True ):
    super().__init__()
    self.target_dims = target_dims
    self.align = align
    self.squeeze = squeeze

  def forward(self, tensor):
    return NTremix(tensor, self.target_dims, self.align, self.squeeze)

# adapted from gist https://gist.github.com/vadimkantorov/ac1b097753f217c5c11bc2ff396e0a57
# which was ported from https://github.com/pvigier/perlin-numpy/blob/master/perlin2d.py

def rand_perlin_2d(shape, res, fade = lambda t: 6*t**5 - 15*t**4 + 10*t**3):
    delta = (res[0] / shape[0], res[1] / shape[1])
    d = (shape[0] // res[0], shape[1] // res[1])
    
    grid = torch.stack(torch.meshgrid(torch.arange(0, res[0], delta[0]), torch.arange(0, res[1], delta[1])), dim = -1) % 1
    angles = 2*math.pi*torch.rand(res[0]+1, res[1]+1)
    gradients = torch.stack((torch.cos(angles), torch.sin(angles)), dim = -1)
    
    tile_grads = lambda slice1, slice2: gradients[slice1[0]:slice1[1], slice2[0]:slice2[1]].repeat_interleave(d[0], 0).repeat_interleave(d[1], 1)
    dot = lambda grad, shift: (torch.stack((grid[:shape[0],:shape[1],0] + shift[0], grid[:shape[0],:shape[1], 1] + shift[1]  ), dim = -1) * grad[:shape[0], :shape[1]]).sum(dim = -1)
    
    n00 = dot(tile_grads([0, -1], [0, -1]), [0,  0])
    n10 = dot(tile_grads([1, None], [0, -1]), [-1, 0])
    n01 = dot(tile_grads([0, -1],[1, None]), [0, -1])
    n11 = dot(tile_grads([1, None], [1, None]), [-1,-1])
    t = fade(grid[:shape[0], :shape[1]])
    return math.sqrt(2) * torch.lerp(torch.lerp(n00, n10, t[..., 0]), torch.lerp(n01, n11, t[..., 0]), t[..., 1])

def rand_perlin_2d_octaves( desired_shape, octaves=1, persistence=0.5):
    shape = torch.tensor(desired_shape)
    shape = 2 ** torch.ceil( torch.log2( shape ) )
    shape = shape.type(torch.int)
    res = torch.floor( shape / 2 ** octaves ).type(torch.int)
   
    noise = torch.zeros(list(shape))
    frequency = 1
    amplitude = 1
    for _ in range(octaves):
        noise += amplitude * rand_perlin_2d(shape, (frequency*res[0], frequency*res[1]))
        frequency *= 2
        amplitude *= persistence
    
    return noise[:desired_shape[0],:desired_shape[1]]

perlin = rand_perlin_2d_octaves((64, 64), 3)
perlin = perlin.unsqueeze(0).unsqueeze(0)
perlin = ( perlin.clip(-1,1) + 1 ) * 0.5

#display_img( perlin.expand(1,3,-1,-1) )
perlin = None

"""##Then change the prompt and settings and generate some art!"""

#@title Pixel MultiColor Composition Module

class RGBCompositionModel(nn.Module):
    def __init__(self, out_size=512, base_size=64, scale=1.25, stepsize=10, n_channels = 5, upscale_noise=0.05, use_hsv=True):
      super().__init__()

      self.stepsize = stepsize
      self.n_channels = n_channels
      self.upscale_noise = upscale_noise

      channels = torch.rand((1,n_channels,base_size,base_size),device=device)
      for i in range(n_channels):
        perlin = rand_perlin_2d_octaves((base_size, base_size), 2).to(device)
        perlin = ( perlin.clip(-1,1) + 1 ) * 0.5
        channels[0,i,:,:] = perlin

      channels = channels * 1/n_channels
      self.params = nn.Parameter( channels )

      self.use_hsv = use_hsv
      
      colors = torch.rand((3,self.n_channels) , device=device)
      if ( use_hsv ):
        colors[1,:] = 1 - colors[1,:] * 0.1
        colors[2,:] = 1
      self.colors = nn.Parameter( colors )

      self.args = {   
          'base_size' : base_size,
          'scale' : scale,
          'out_size' : out_size 
      }
      self.lasti = 0

    def getSzFor(self, i):
      return int( min( self.args['base_size'] * self.args['scale'] ** i, self.args['out_size'] ) )

    def compose(self, params, colors ):
      out = params

      if self.use_hsv:
        colors = colors.clone()
        colors[0,:] = colors[0,:] * 2.0 * np.pi
        colors = kornia.color.hsv_to_rgb(colors.permute(1,0).unsqueeze(2).unsqueeze(2))
        colors = colors.permute(1,0,2,3)
      else:
        colors = colors.unsqueeze(2).unsqueeze(2)

      out = out * colors
      out = out.permute(1,0,2,3).sum( dim = 0, keepdim=True )

      return clamp_with_grad(out,0,1)

    def forward(self, i):
      return self.compose( self.params, self.colors )

    def preview(self,i,color):
      return self.compose( self.params[:,color,...].unsqueeze(1), self.colors[:,color].unsqueeze(1) )

    @torch.no_grad()
    def upscale(self, fromSz, toSz):
      up = resample(self.params, (toSz,toSz))
      for i in range(self.n_channels):
        perlin = rand_perlin_2d_octaves((toSz, toSz), 5).to(device)
        up[0,i,:,:] += perlin * self.upscale_noise
      self.params = nn.Parameter( up )
      
    @torch.no_grad()
    def step(self,i):
      if ( i == 0 ):
        return False

      last_ii = ( i - 1 ) // self.stepsize
      ii = i // self.stepsize

      sz = self.getSzFor(ii) 
      lastsz = self.getSzFor(last_ii)
      
      if ( sz != lastsz ):
        self.upscale(lastsz, sz)
        return True
        
      if ( i % 100 == 0 ):
        return True

#@title Do the Run!

optimizer = None
ims = None
wvlt = None

#@markdown What do you want to generate
prompts = [args.prompt] #@param
size=args.size #@param  {type:"number"}
num_color_channels = args.colorchannels #@param {type:"number"}
if args.usehsv==1:
    use_hsv = True
else:
    use_hsv = False
max_iterations = args.iterations #@param {type:"number"}
save_run_steps = True #@param {type:"boolean"}

#@markdown Parameters to control how resolution steps up over time
base_size = 16 #@param  {type:"number"}
step_scale = 1.25 #@param  {type:"number"}
step_time = 10 #@param  {type:"number"}
upscale_noise = 0.005 #@param {type:"number"}

#@markdown Control how the optimizer optimizes
pixel_learning_rate=args.pixellearningrate #0.01
color_learning_rate=args.colorlearningrate #0.01 #original was 0.0001
weight_decay=0
tv_weight = 0.05

cutn=args.cutn
cut_pow=args.cutpow

make_cutouts = MakeCutouts(cut_size, cutn, cut_pow=cut_pow)
make_cutouts_smol = MakeCutouts(cut_size, 8, cut_pow=0)

# A list of positive prompts
p_prompts = [] 
for pr in prompts:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  p_prompts.append(Prompt(embed, 1, float('-inf')).to(device)) # 1 is the weight

# Some negative prompts
n_prompts = []
for pr in []:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  n_prompts.append(Prompt(embed, 0.5, float('-inf')).to(device)) # 0.5 is the weight

ims = RGBCompositionModel( out_size=size, base_size=base_size, 
                          n_channels=num_color_channels, scale=step_scale, 
                          stepsize=step_time, use_hsv=use_hsv, upscale_noise=upscale_noise )
  
optimizer = 0
def reset_opt():
  global ims
  global optimizer
  optimizer = optim.Adam( [ 
          { 'params': ims.params }, 
          { 'params': ims.colors, 'lr':color_learning_rate}],
          lr=pixel_learning_rate, weight_decay=weight_decay)
reset_opt()
# An optimizer (you can try others) with the image layers as parameters


# Somewhere to track our losses
losses = []

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
for i in range(max_iterations):
  optimizer.zero_grad( True )
      
  out = ims(i) 
  iii = 0

  if i <= 50:       
    iii = perceptor.encode_image(normalize(make_cutouts_smol(out))).float() # Encode image (using multiple cutouts)
  else:
    iii = perceptor.encode_image(normalize(make_cutouts(out))).float() # Encode image (using multiple cutouts)

  l = 0
  for prompt in p_prompts:
    l += prompt(iii) / len(p_prompts)

  for prompt in n_prompts:
    l -= prompt(iii) / len(n_prompts) 

  l += torch.abs( tv_loss(out).squeeze() ) * tv_weight
  
  if (l.isnan()):
    print('NAN')
    break

  if ( i > 5):
    losses.append(float(l.detach().cpu())) # Store loss
  
  l.backward() # Backprop
  optimizer.step() # Update
  if ( ims.step(i) ):
      reset_opt()

  sys.stdout.write("Iteration {}".format(itt)+"\n")
  sys.stdout.flush()
    
  with torch.no_grad():
    # View and save images every few iterations
    if itt % args.update == 0:
      img = out.detach().cpu().squeeze().permute(1,2,0)
      if save_run_steps:
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()
        
        sz = ims.args['out_size']
        tim = F.interpolate(out.detach(), (sz,sz), mode='nearest')
        pil = TF.to_pil_image(tim.cpu().squeeze())

        #display only tweaks
        pil = torchvision.transforms.functional.adjust_brightness(pil,args.brightness)
        pil = torchvision.transforms.functional.adjust_contrast(pil,args.contrast)
        #pil = torchvision.transforms.functional.equalize(pil)
        
        pil.save(args.image_file)
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
            pil.save(save_name)
        
        sys.stdout.flush()
        sys.stdout.write('Progress saved\n')
        sys.stdout.flush()


        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
  itt+=1

