# ImageColorizerColab.ipynb
# Original file is located at https://colab.research.google.com/github/jantic/DeOldify/blob/master/ImageColorizerColab.ipynb

import os

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./DeOldify')


#NOTE:  This must be the first call in order to work properly!
from DeOldify.deoldify import device
from DeOldify.deoldify.device_id import DeviceId
#choices:  CPU, GPU0...GPU7
device.set(device=DeviceId.GPU0)
import torch
import fastai
from DeOldify.deoldify.visualize import *
import warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*?Your .*? set is empty.*?")

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--image_file', type=str, help='Input image name.')
  parser.add_argument('--model', type=str, help='Artistic or Stable.')
  args = parser.parse_args()
  return args

args=parse_args();

sys.stdout.write(f"Loading {args.model} colorizer model ...\n")
sys.stdout.flush()

if args.model=='Artistic':
    colorizer = get_image_colorizer(artistic=True)
else:
    colorizer = get_image_colorizer(artistic=False)

source_url = args.image_file
render_factor = 35
watermarked = False

sys.stdout.write("Colorizing image ...\n")
sys.stdout.flush()

image_path = colorizer.plot_transformed_image(path=source_url, render_factor=render_factor, compare=True, watermarked=watermarked)

sys.stdout.write("Done\n")
sys.stdout.flush()
