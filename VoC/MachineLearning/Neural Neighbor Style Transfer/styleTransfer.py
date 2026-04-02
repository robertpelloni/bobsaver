import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
os.environ['TORCH_HOME'] = '..\.cache'

# Core Imports
import time
import argparse
import random

# External Dependency Imports
from imageio import imwrite
import torch
import numpy as np

# Internal Project Imports
from pretrained.vgg import Vgg16Pretrained
from utils import misc as misc
from utils.misc import load_path_for_pytorch
from utils.stylize import produce_stylization

# Fix Random Seed
random.seed(0)
np.random.seed(0)
torch.manual_seed(0)

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

# Define command line parser and get command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--content_path'   , type=str, default=None, required=True)
parser.add_argument('--style_path'     , type=str, default=None, required=True)
parser.add_argument('--output_path'    , type=str, default=None, required=True)
parser.add_argument('--no_flip'        , action='store_true'                  )
parser.add_argument('--content_loss'   , action='store_true'                  )
parser.add_argument('--dont_colorize'  , type=int                             )
parser.add_argument('--alpha'          , type=float, default=0.75             )
parser.add_argument('--iterations'     , type=int                             )
parser.add_argument('--scales'         , type=int                             )
parser.add_argument('--learning_rate'  , type=float                           )
args = parser.parse_args()

# Interpret command line arguments
content_path = args.content_path
style_path = args.style_path
output_path = args.output_path
max_scls =args.scales

flip_aug = (not args.no_flip)
content_loss = args.content_loss
misc.USE_GPU = True
content_weight = 1. - args.alpha

# Error checking for arguments
# error checking for paths deferred to imageio
assert (0.0 <= content_weight) and (content_weight <= 1.0), "alpha must be between 0 and 1"
assert torch.cuda.is_available() or (not misc.USE_GPU), "attempted to use gpu when unavailable"

# Define feature extractor
cnn = misc.to_device(Vgg16Pretrained())

phi = lambda x, y, z: cnn.forward(x, inds=y, concat=z)

#work out largest dimension of content image (image to be processed by style transfer)
from imageio import imread
x = imread(content_path).astype(np.float32)
x_dims = x.shape
largest_dimension = max(x_dims[0],x_dims[1])
#sys.stdout.write(f"\nLargest content image dimension is {largest_dimension}\n")
#sys.stdout.flush()

#largest of image sizes must be at least 512 pixels for this script to work
#for smaller images this is detected and adjusted for here
if largest_dimension<512:
    largest_dimension=max(largest_dimension,512)

# Load images
#content_im_orig = misc.to_device(load_path_for_pytorch(content_path, target_size=1024)).unsqueeze(0)
content_im_orig = misc.to_device(load_path_for_pytorch(content_path, target_size=largest_dimension)).unsqueeze(0)
#content_im_orig = misc.to_device(load_path_for_pytorch(content_path)).unsqueeze(0)

#style_im_orig = misc.to_device(load_path_for_pytorch(style_path, target_size=1024)).unsqueeze(0)
style_im_orig = misc.to_device(load_path_for_pytorch(style_path, target_size=largest_dimension)).unsqueeze(0)
#style_im_orig = misc.to_device(load_path_for_pytorch(style_path)).unsqueeze(0)

if args.dont_colorize==0:
    dontcolorize=False
else:
    dontcolorize=True

# Run Style Transfer
torch.cuda.synchronize()

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

start_time = time.time()
output = produce_stylization(content_im_orig, style_im_orig, phi,
                            max_iter=args.iterations,
                            lr=args.learning_rate,
                            content_weight=content_weight,
                            max_scls=max_scls,
                            flip_aug=flip_aug,
                            content_loss=content_loss,
                            dont_colorize=dontcolorize)
torch.cuda.synchronize()
#print('Done! total time: {}'.format(time.time() - start_time))

# Convert from pyTorch to numpy, clip to valid range
new_im_out = np.clip(output[0].permute(1, 2, 0).detach().cpu().numpy(), 0., 1.)

# Save stylized output
save_im = (new_im_out * 255).astype(np.uint8)
imwrite(output_path, save_im)

# Free gpu memory in case something else needs it later
if misc.USE_GPU:
    torch.cuda.empty_cache()
