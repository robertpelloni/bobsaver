# CLIPRGB-ImStack.ipynb
# Original file is located at https://colab.research.google.com/drive/1MCC2IwAaRNCTBUzghuG41ypAkxjJvGtq

# @johnowhitaker

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
import torch.optim as optim

import kornia.augmentation as K
from CLIP import clip
from torchvision import transforms

from PIL import Image
import numpy as np
import math

import torchvision

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--size', type=int, help='Image width and height.', default=512)
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cutpower', type=float, help='Cut power.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--brightness', type=float, help='Display brightness.')
  parser.add_argument('--contrast', type=float, help='Display contrast.')
  parser.add_argument('--sharpness', type=float, help='Display sharpness.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
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




#import warnings
#warnings.filterwarnings('ignore') # Some pytorch functions give warnings about behaviour changes that I don't want to see over and over again :)

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
            K.RandomHorizontalFlip(p=0.5),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
            K.RandomPerspective(0.2,p=0.4),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7))
        self.noise_fac = 0.1 

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
 
 
replace_grad = ReplaceGrad.apply

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
cut_size = perceptor.visual.input_resolution
cutn=args.cutn #was 64
cut_pow=args.cutpower
make_cutouts = MakeCutouts(cut_size, cutn, cut_pow=cut_pow)

"""# ImStack

This section defines the ImStack class, which represents an image as a series of stacked layers at different resolutions. Feel free to dig into the code and let me know if anything is unclear :)
"""

class ImStack(nn.Module):
  """ This class represents an image as a series of stacked arrays, where each is 1/2
  the resolution of the next. This is useful eg when trying to create an image to minimise
  some loss - parameters in the early (small) layers can have an affect on the overall 
  structure and shapes while those in later layers act as residuals and fill in fine detail.
  """

  def __init__(self, n_layers=4, base_size=32, scale=2,
               init_image=None, out_size=256, decay=0.7):
    """Constructs the Image Stack

    Args:
        n_layers: How many layers in the stack
        base_size: The size of the smallest layer
        scale: how much larger each subsequent layer is
        init_image: Pass in a PIL image if you don't want to start from noise
        out_size: The output size. Works best if output size ~= base_size * (scale ** (n_layers-1))
        decay: When initializing with noise, decay controls scaling of later layers (avoiding too miuch high-frequency noise)

    """
    super().__init__()
    self.n_layers = n_layers
    self.base_size = base_size
    self.sig = nn.Sigmoid()
    self.layers = []

    for i in range(n_layers):
        side = base_size * (scale**i)
        tim = torch.randn((3, side, side)).to(device)*(decay**i)
        self.layers.append(tim)

    self.scalers = [nn.Upsample(scale_factor=out_size/(l.shape[1]), mode='bilinear', align_corners=False) for l in self.layers]
    
    self.preview_scalers = [nn.Upsample(scale_factor=224/(l.shape[1]), mode='bilinear', align_corners=False) for l in self.layers]
    
    if init_image != None: # Given a PIL image, decompose it into a stack
      downscalers = [nn.Upsample(scale_factor=(l.shape[1]/out_size), mode='bilinear', align_corners=False) for l in self.layers]
      final_side = base_size * (scale ** n_layers)
      im = torch.tensor(np.array(init_image.resize((out_size, out_size)))/255).clip(1e-03, 1-1e-3) # Between 0 and 1 (non-inclusive)
      im = im.permute(2, 0, 1).unsqueeze(0).to(device) # torch.log(im/(1-im))
      for i in range(n_layers):self.layers[i] *= 0 # Sero out the layers
      for i in range(n_layers):
        side = base_size * (scale**i)
        out = self.forward()
        residual = (torch.logit(im) - torch.logit(out))
        Image.fromarray((torch.logit(residual).detach().cpu().squeeze().permute([1, 2, 0]) * 255).numpy().astype(np.uint8)).save(f'residual{i}.png')
        self.layers[i] = downscalers[i](residual).squeeze()
    
    for l in self.layers: l.requires_grad = True

  def forward(self):
    """Sums the stacked layers (upsampling them all to out_size) and then runs the result through a sigmoid funtion."""
    im = self.scalers[0](self.layers[0].unsqueeze(0))
    for i in range(1, self.n_layers):
      im += self.scalers[i](self.layers[i].unsqueeze(0))
    return self.sig(im)

  def preview(self, n_preview=2):
    """Useful if you want to optimise the first few layers first"""
    im = self.preview_scalers[0](self.layers[0].unsqueeze(0))
    for i in range(1, n_preview):
      im += self.preview_scalers[i](self.layers[i].unsqueeze(0))
    return self.sig(im)
  
  def to_pil(self):
    """Return it as a PIL Image (useful for saving, transforming, viewing etc)"""
    return Image.fromarray((self.forward().detach().cpu().squeeze().permute([1, 2, 0]) * 255).numpy().astype(np.uint8))

  def preview_pil(self):
    return Image.fromarray((self.preview().detach().cpu().squeeze().permute([1, 2, 0]) * 255).numpy().astype(np.uint8))

  def save(self, fn):
    self.to_pil().save(fn)

  """
  def plot_layers(self):
    #View the layers in the stack - nice to build intuition about what's happening.
    fig, axs = plt.subplots(1, self.n_layers, figsize=(15, 5))
    for i in range(self.n_layers):
      im = (self.sig(self.layers[i].unsqueeze(0)).detach().cpu().squeeze().permute([1, 2, 0]) * 255).numpy().astype(np.uint8)
      axs[i].imshow(im)
  """

"""We make an imagestack like so:"""

ims = ImStack()

"""You can view the stacked image:"""

ims.to_pil()

"""Or separate the layers with:"""

ims = ImStack()
#ims.plot_layers()

"""# Optimization Loop

Here's a commented version of the optimization loop. This is more for the curious minds who want to understand how this is all working - skip to the next section if you want to run it without worrying about the code :)
"""

# The text prompt to use calculating the loss with CLIP
embed = perceptor.encode_text(clip.tokenize('A watercolor landscape with the sun over mountains covered in trees').to(device)).float()
prompt = Prompt(embed, 1, float('-inf')).to(device)

# The ImStack. Layer sizes will be 16, 32, 64, 128, 256 and 512
ims = ImStack(base_size=16, scale=2, n_layers=6, out_size=512, decay=0.4)

# An optimizer (you can try others) with the image layers as parameters
#optimizer = optim.Adam(ims.layers, lr=0.1)
optimizer = optim.Adam(ims.layers, lr=0.1, weight_decay=args.weight_decay)


# Somewhere to track our losses
losses = []

# A basic progress bar (using fastprogress)
"""
bar = progress_bar(range(100))
for i in bar:
  optimizer.zero_grad()
  im = ims() # Get the image from the ImStack
  iii = perceptor.encode_image(normalize(make_cutouts(im))).float() # Encode image (using multiple cutouts)
  l = prompt(iii) # Calculate loss
  losses.append(float(l.detach().cpu())) # Store loss
  l.backward() # Backprop
  optimizer.step() # Update
"""

sys.stdout.write("Optimizer ...\n")
sys.stdout.flush()

for i in range(100):
  optimizer.zero_grad()
  im = ims() # Get the image from the ImStack
  iii = perceptor.encode_image(normalize(make_cutouts(im))).float() # Encode image (using multiple cutouts)
  l = prompt(iii) # Calculate loss
  losses.append(float(l.detach().cpu())) # Store loss
  l.backward() # Backprop
  optimizer.step() # Update
  if (i+1)%10 == 0:
    sys.stdout.write(f'{(i+1)}/100...\n')
    sys.stdout.flush()



#plt.plot(losses)

"""We can see the final image with:"""

ims.to_pil()

"""And view the individual layers:"""

#ims.plot_layers() # Note the finer and finer detail

"""# Making it Better

The above was nice, but we can do better. In this section we add:
- Multiple prompts and the option to add negative prompts
- Live graph for loss and a preview of the most recent image
- Storing intermediate images to make a video of the process
- Training the lower layers for a bit before we bring in the whole stack (to give it time to settle into a better structure before we add fine detail).
"""

# Somewhere to store images that will be used for the video
#!rm -r steps
#!mkdir -p steps

# A list of positive prompts
p_prompts = []
"""
for pr in ['A watercolor landscape with the sun over mountains covered in trees',
           'A watercolor landscape painting by Bob Ross', # yes, I know he used oils :)
           'Beautiful painting of a landscape with muted colors']:
"""
for pr in [args.prompt]:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  p_prompts.append(Prompt(embed, 1, float('-inf')).to(device)) # 1 is the weight

# SOme negative prompts
n_prompts = []
for pr in ["Random noise", 'saturated rainbow RGB deep dream']:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  n_prompts.append(Prompt(embed, 0.5, float('-inf')).to(device)) # 0.5 is the weight

# The ImageStack - trying a different scale and n_layers
ims = ImStack(base_size=20, scale=3, n_layers=4, out_size=args.size, decay=0.4)

#optimizer = optim.Adam(ims.layers, lr=0.1)
optimizer = optim.Adam(ims.layers, lr=0.1, weight_decay=args.weight_decay)
losses = []

# Some fancier progress bar stuff (this is a little hacky since I stole it from another project of mine that wasn't written for public consumption!)
"""
mb = master_bar(range(1))
mb.names=['loss']
mb.graph_fig, axs = plt.subplots(1, 2, figsize=(15, 5)) # For custom display
mb.graph_ax = axs[0]
mb.img_ax = axs[1]
mb.graph_out = display(mb.graph_fig, display_id=True)
"""

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

for i in range(args.iterations):
  optimizer.zero_grad()

  if i < 50: # Save time by skipping the cutouts and focusing on the lower layers 
    im = ims.preview(n_preview=1 + i//20 )
    iii = perceptor.encode_image(normalize(im)).float()
  else:
    im = ims()
    iii = perceptor.encode_image(normalize(make_cutouts(im))).float()
  
  l = 0
  for prompt in p_prompts:
    l += prompt(iii)
  for prompt in n_prompts:
    l -= prompt(iii)

  losses.append(float(l.detach().cpu()))
  l.backward() # Backprop
  optimizer.step() # Update

  # Show progress and loss plot
  #mb.update_graph([[range(len(losses)), losses]])

  sys.stdout.write(f'Iteration {i}\n')
  sys.stdout.flush()

  # View and save images every few iterations
  # save_every = 5
  if i % args.update == 0:
    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()

    img = ims.to_pil()
    #mb.img_ax.imshow(img)
    #mb.graph_out.update(mb.graph_fig)
    #img.save(f'steps/step{len(losses)//save_every:04}.png')

    #tweak display image
    #img = torchvision.transforms.functional.adjust_gamma(img,1.0,1)
    img = torchvision.transforms.functional.adjust_brightness(img,args.brightness)
    img = torchvision.transforms.functional.adjust_contrast(img,args.contrast)
    img = torchvision.transforms.functional.adjust_sharpness(img,args.sharpness)

    img.save(args.image_file)
    
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
        img.save(save_name)
    
    
    
    

    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()

