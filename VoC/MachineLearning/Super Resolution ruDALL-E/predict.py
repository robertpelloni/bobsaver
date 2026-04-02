# https://github.com/CJWBW/rudalle-sr

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append("ru-dalle")

import torch
import tempfile
import numpy as np
from pathlib import Path
from PIL import Image
from rudalle.realesrgan.model import RealESRGAN
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str, help='Input image filename.')
  parser.add_argument('--output_image', type=str, help='Output image filename.')
  parser.add_argument('--scale', type=int, help='Scale factor 2, 4, or 8')
  args = parser.parse_args()
  return args

args=parse_args();

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)



scale = args.scale

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

model = RealESRGAN(device, scale)
model.load_weights(f"RealESRGAN_x{scale}.pth")

image = args.input_image

sys.stdout.write(f"Upscaling x{str(args.scale)} ...\n")
sys.stdout.flush()

input_image = Image.open(str(image))     
input_image = input_image.convert('RGB')
with torch.no_grad():
    sr_image = model.predict(np.array(input_image))

sys.stdout.write("Saving output ...\n")
sys.stdout.flush()

sr_image.save(args.output_image)

sys.stdout.write("Done\n")
sys.stdout.flush()
