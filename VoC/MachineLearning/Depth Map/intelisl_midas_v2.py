# intelisl_midas_v2.ipynb
# Original file is located at https://colab.research.google.com/github/pytorch/pytorch.github.io/blob/master/assets/hub/intelisl_midas_v2.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import argparse
import cv2
import torch
import urllib.request
import matplotlib.pyplot as plt


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str, help='Input image.')
  parser.add_argument('--output_image', type=str, help='Output image.')
  parser.add_argument('--grayscale', type=int, help='Output image in grayscale.')
  args = parser.parse_args()
  return args

args=parse_args();


#url, filename = ("https://github.com/pytorch/hub/raw/master/images/dog.jpg", "dog.jpg")
#urllib.request.urlretrieve(url, filename)
filename = args.input_image

sys.stdout.write("Loading DPT_Large model ...\n")
sys.stdout.flush()

model_type = "DPT_Large"     # MiDaS v3 - Large     (highest accuracy, slowest inference speed)
#model_type = "DPT_Hybrid"   # MiDaS v3 - Hybrid    (medium accuracy, medium inference speed)
#model_type = "MiDaS_small"  # MiDaS v2.1 - Small   (lowest accuracy, highest inference speed)

midas = torch.hub.load("intel-isl/MiDaS", model_type)

"""Move model to GPU if available"""

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
midas.to(device)
midas.eval()

"""Load transforms to resize and normalize the image for large or small model"""

sys.stdout.write("Processing ...\n")
sys.stdout.flush()

midas_transforms = torch.hub.load("intel-isl/MiDaS", "transforms")

if model_type == "DPT_Large" or model_type == "DPT_Hybrid":
    transform = midas_transforms.dpt_transform
else:
    transform = midas_transforms.small_transform

"""Load image and apply transforms"""

img = cv2.imread(filename)
img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

input_batch = transform(img).to(device)

"""Predict and resize to original resolution"""

with torch.no_grad():
    prediction = midas(input_batch)

    prediction = torch.nn.functional.interpolate(
        prediction.unsqueeze(1),
        size=img.shape[:2],
        mode="bicubic",
        align_corners=False,
    ).squeeze()

output = prediction.cpu().numpy()

"""Show result"""

sys.stdout.write("Saving output ...\n")
sys.stdout.flush()

import matplotlib
if args.grayscale==1:
    matplotlib.image.imsave(args.output_image, output, cmap='gray')
else:
    matplotlib.image.imsave(args.output_image, output)

sys.stdout.write("Done\n")
sys.stdout.flush()

