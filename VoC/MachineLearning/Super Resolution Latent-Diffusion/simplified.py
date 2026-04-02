# Simplefied latent-diffusion upscaling.ipynb
# Original file is located at https://colab.research.google.com/drive/1xm1x942Ex0a-VuLkl6qRySlnGeuOexyM

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append(".")
sys.path.append('./taming-transformers')
sys.path.append('./latent-diffusion')

from taming.models import vqgan # checking correct import from taming
import torch
import numpy as np
import IPython.display as d
from PIL import Image
import os
import gc

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str, help='Input image')
  parser.add_argument('--output_image', type=str, help='Output image')
  args = parser.parse_args()
  return args

args=parse_args();


# Commented out IPython magic to ensure Python compatibility.
#@title Download Model

# %cd 'latent-diffusion'
from notebook_helpers import get_model
diffMode = 'superresolution'
model = get_model(diffMode)
# %cd ..

#@title I/O

#path = 'Biscuit.png'
#output_path = 'Biscuit_x4.png'
path = args.input_image #'horror.png'
output_path = args.output_image #'horror_x4.png'

#@title Simple Run

from notebook_helpers import run
custom_steps = 100
logs = run(model["model"], path, diffMode, custom_steps)

sample = logs["sample"]
sample = sample.detach().cpu()
sample = torch.clamp(sample, -1., 1.)
sample = (sample + 1.) / 2. * 255
sample = sample.numpy().astype(np.uint8)
sample = np.transpose(sample, (0, 2, 3, 1))
#print(sample.shape)
a = Image.fromarray(sample[0])
#display(a)
a.save(output_path)

"""
#@title Advanced Run

from notebook_helpers import run

diffusion_steps = 100
pre_downsample = 'None' #['None', '1/2', '1/4']
post_downsample = 'None' #['None', 'Original Size', '1/2', '1/4']

gc.collect()
torch.cuda.empty_cache()

im_og = Image.open(path)
width_og, height_og = im_og.size

#Downsample Pre
if pre_downsample == '1/2':
  downsample_rate = 2
elif pre_downsample == '1/4':
  downsample_rate = 4
else:
  downsample_rate = 1

width_downsampled_pre = width_og//downsample_rate
height_downsampled_pre = height_og//downsample_rate
if downsample_rate != 1:
  print(f'Downsampling from [{width_og}, {height_og}] to [{width_downsampled_pre}, {height_downsampled_pre}]')
  im_og = im_og.resize((width_downsampled_pre, height_downsampled_pre), Image.LANCZOS)
  im_og.save('temp.png')
  filepath = 'temp.png'

logs = run(model["model"], filepath, diffMode, diffusion_steps)

sample = logs["sample"]
sample = sample.detach().cpu()
sample = torch.clamp(sample, -1., 1.)
sample = (sample + 1.) / 2. * 255
sample = sample.numpy().astype(np.uint8)
sample = np.transpose(sample, (0, 2, 3, 1))
print(sample.shape)
a = Image.fromarray(sample[0])

#Downsample Post
if post_downsample == '1/2':
  downsample_rate = 2
elif post_downsample == '1/4':
  downsample_rate = 4
else:
  downsample_rate = 1

width, height = a.size
width_downsampled_post = width//downsample_rate
height_downsampled_post = height//downsample_rate
if downsample_rate != 1:
  print(f'Downsampling from [{width}, {height}] to [{width_downsampled_post}, {height_downsampled_post}]')
  a = a.resize((width_downsampled_post, height_downsampled_post), Image.LANCZOS)
elif post_downsample == 'Original Size':
  print(f'Downsampling from [{width}, {height}] to Original Size [{width_og}, {height_og}]')
  a = a.resize((width_og, height_og), Image.LANCZOS)

display(a)
a.save(output_path)
"""
print(f'Processing finished!')