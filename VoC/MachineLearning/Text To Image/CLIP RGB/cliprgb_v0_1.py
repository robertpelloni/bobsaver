# CLIPRGB - V0.1.ipynb
# Original file is located at https://colab.research.google.com/drive/1MiKaFFgau6V5QhIed5tpNdLUiSbof4nI

"""

This is my take on using CLIP to guide optimization of raw RGB values. This was not my idea, but I did implement this myself and I don't know if the progressive resizing has been talked about much. 

This notebook is split into 5 sections:
- Setup: just installing some necessary libraries - run and ignore.
- Imports and Definitions: Some code from the VQGAN+CLIP notebooks that mostly sets up everything we'll need to use CLIP.
- Tutorial: This goes over how this all works with a bit of explanation for the curious
- Progressive Resizing: This is what you'd use if you just wanted to try it out and generate some imagery for yourself
- Closing Thoughts: Some ideas for things to try and my closing thoughts

Have fun and please share what you make or any improvements you can think of! Tag me @johnowhitaker :)

"""

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
import torch.optim as optim
import kornia.augmentation as K
from CLIP.clip import clip
from torchvision import transforms
from PIL import Image
import numpy as np
import math
#from matplotlib import pyplot as plt

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
        for _ in range(cutn):
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

"""# 3 - Tutorial

Let's talk through what's going on here.

CLIP can compare an image to a text prompt and give us some 'loss' - a measure of how far apart they are, which we want to minimise. 

We start with an image made fom random noise. We represent this as a PyTorch tensor. This means that when we compute the loss using CLIP, we can run loss.backward() to calculate the gradient of the loss with respect to each pixel! Then, using an optimizer (for this notebook we'll stick with Stochastic Gradient Descent (SGD) we can update the pixels to (hopefully) reduce the loss. This is repeated a number of times until we end up with something we like :)

For the tutorial part we'll look at each step individually then put them all together - if you want to skip to the end result, jump to 'Progressive Resizing'

### The Starting Image
"""

# Creating a starting image from noise:
w, h = 64, 64
tim = torch.rand((w, h, 3)).to(device)
#plt.imshow(tim.cpu()) # The image we'll work with

# You could also use an existing image:
# im = Image.open('/content/start.png').convert('RGB')
# tim = torch.tensor(np.array(im.resize((w, h)))).to(device) / 255

"""### Using CLIP as a loss

As in some of the VQGAN notebooks, we're not just passing the whole image to CLIP. Instead, `cutn` cutouts are each passed through and the aveage loss is returned. Increase this number for smoother losses but longer iteration times.
"""

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

# Loading the clip model
perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

# Defining some variables
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
cut_size = perceptor.visual.input_resolution
cutn=32
cut_pow=1

# This will handle making the cutouts
make_cutouts = MakeCutouts(cut_size, cutn, cut_pow=cut_pow)

"""To compute the loss, we encode our prompt(s) using CLIP:"""

# Encode the prompt and wrap it in a 'Prompt' object
embed = perceptor.encode_text(clip.tokenize("A ghostly face (oil painting) by Edvard Munch").to(device)).float()
prompt = Prompt(embed, 1, float('-inf')).to(device) # 1 is the weight

"""We then encode our cutous and compare them (this is handled for us by the Prompt class, defined in section 2):"""

# Demo loss calc:
iii = perceptor.encode_image(normalize(make_cutouts(tim.permute([2, 0, 1]).unsqueeze(0).to(device)))).float()
loss = prompt(iii)
loss

"""That loss is what we're going to try to minimise.

### Optimising the image to match some prompts

We define a simple training loop. Each iteration, we calculate the loss, run a backwards pass and updaate the image by calling optimizer.step(). If you've trained a model with PyToorch, this will look quite familiar :)

We also save intermediate images to a folder, 'steps', for later viewing.
"""

# Every few iterations we'll save the progress to a 'steps' folder for later viewing
#!rm -r steps
#!mkdir -p steps

# Tell pytorch to keep track of gradients:
tim.requires_grad=True

# Set up an array to store our losses
losses = []


sys.stdout.write("Creating the optimizer ...\n")
sys.stdout.flush()

# Create the optimizer
optimizer = optim.SGD([tim], lr=5)

for i in range(500):

  # Reset everything related to gradient calculations
  optimizer.zero_grad()

  # Calculate the loss
  iii = perceptor.encode_image(normalize(make_cutouts(tim.clip(0, 1).permute([2, 0, 1]).unsqueeze(0)))).float()
  l = prompt(iii)
  losses.append(float(l.detach().cpu())) # Store it

  # Backpropagate the loss and use it to update the image
  l.backward() 
  optimizer.step() # Update

  # Save progress images every 20 iterations:
  if (i+1)%50 == 0:
    #  Image.fromarray((tim.detach().cpu() * 255).numpy().astype(np.uint8)).save('Progress.png')
    sys.stdout.write(f'{(i+1)}/500...\n')
    sys.stdout.flush()
  
  
# Plot the losses over time  
#plt.plot(losses)

# Making out positive and negative prompts:
p_prompts = []
#for pr in ["A ghostly face (oil painting) by Edvard Munch", "A photorealistic oil painting trending on artstation"]:
for pr in [args.prompt]:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  p_prompts.append(Prompt(embed, 1, float('-inf')).to(device)) # 1 is the weight
n_prompts = []
for pr in ["Random noise", 'rainbow RGB']:
  embed = perceptor.encode_text(clip.tokenize(pr).to(device)).float()
  n_prompts.append(Prompt(embed, 0.5, float('-inf')).to(device)) # 0.5 is the weight - you can play with changing this.


# The different sizes with w, h, n_iter, lr:
# Uncomment out the last two to generate a larger image.
"""
passes = [
         [32, 32, 100, 3],
         [64, 64, 300, 3],
         [128, 128, 300, 3],
         [256, 256, 300, 10],
         [512, 512, 200, 10]
]
"""

iters_per_pass = args.iterations // 7

passes = [
         [args.size // 64, args.size // 64, iters_per_pass, 1],
         [args.size // 32, args.size // 32, iters_per_pass, 3],
         [args.size // 16, args.size // 16, iters_per_pass, 6],
         [args.size // 8, args.size // 8, iters_per_pass, 9],
         [args.size // 4, args.size // 4, iters_per_pass, 12],
         [args.size // 2, args.size // 2, iters_per_pass, 15],
         [args.size, args.size, args.iterations-(iters_per_pass*6), 18]
]

# We'll save all images at the same resolution for easy video generation
save_size = (args.size, args.size)

# The initial image:
tim = torch.rand((128, 128, 3)).to(device)

# The progress bar
#mb = master_bar(passes)
#mb.names=['loss']

# Our losses
losses = []

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
# The outer loop (for each pass in passes...):
for p in passes:

  # Read the params for this pass
  w, h, n_iter, lr = p 

  sys.stdout.write(f'Width {w} Height {h} Iterations {n_iter} Learning rate {lr}\n')
  sys.stdout.flush()

  # tim -> Image -> resize -> tim
  im = Image.fromarray((tim.detach().cpu() * 255).numpy().astype(np.uint8))
  tim = torch.tensor(np.array(im.resize((w, h)))).to(device) / 255

  # Set up the optimizer
  tim.requires_grad=True
  optimizer = optim.SGD([tim], lr=lr)

  # The inner loop (for i in range(n_iter)):
  #for i in progress_bar(range(n_iter), parent=mb):
  for i in range(n_iter):

    sys.stdout.write(f'Iteration {itt}\n')
    sys.stdout.flush()

    # Zero gradients:
    optimizer.zero_grad()

    # Sum losses over all prompts:
    iii = perceptor.encode_image(normalize(make_cutouts(tim.clip(0, 1).permute([2, 0, 1]).unsqueeze(0)))).float()
    l = 0
    for prompt in p_prompts:
      l += prompt(iii)
    for prompt in n_prompts:
      l -= prompt(iii) # Opposite sign for the negative prompts

    losses.append(float(l.detach().cpu())) # Store loss
    l.backward() # Backprop
    optimizer.step() # Update

    # Show progress and loss plot
    #mb.update_graph([[range(len(losses)), losses]])

    # Save progress every 5 iterations:
    if itt%args.update == 0:

      sys.stdout.flush()
      sys.stdout.write('Saving progress ...\n')
      sys.stdout.flush()
      
      Image.fromarray((tim.detach().cpu() * 255).numpy().astype(np.uint8)).resize(save_size).save(args.image_file)

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
          Image.fromarray((tim.detach().cpu() * 255).numpy().astype(np.uint8)).resize(save_size).save(save_name)

      sys.stdout.flush()
      sys.stdout.write('Progress saved\n')
      sys.stdout.flush()
      
    itt = itt+1

"""Note that the above took less time, gave a much more complete output and ended with something higher resolution. Win win win :)

# 5 - Closing Thoughts

I'm sharing this on request, but it's something I threw together on a lazy Sunday so there is lots to be improved! Some things to experiment with:
- Better initializations (random noise tends to mean colorful artifacts)
- Different resizing regimes. Is it better to start at 50px then jumpt to 250px then 1000px? Should we do more stages for fewer iterations each? Who knows - I haven't had time to try more than a handful of experiments :)
- Augmentations, avoiding invalid RGB values (I do clip(0, 1) but there are better ways)
- ... :)
"""