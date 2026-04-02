# ------------------------------------------------------------------------------------
# Minimal DALL-E
# Copyright (c) 2021 KakaoBrain. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 [see LICENSE for details]
# ------------------------------------------------------------------------------------

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP');

import os
import sys
import argparse
import clip
import numpy as np
from PIL import Image
#sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dalle.models import Dalle
from dalle.utils.utils import set_seed, clip_score
import torch
import time

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

parser = argparse.ArgumentParser()
parser.add_argument('--num_candidates', type=int, default=96)
parser.add_argument('--prompt', type=str, default='A painting of a tree on the ocean')
parser.add_argument('--images', type=int)
parser.add_argument('--softmax-temperature', type=float, default=1.0)
parser.add_argument('--top-k', type=int, default=256)
parser.add_argument('--top-p', type=float, default=None, help='0.0 <= top-p <= 1.0')
parser.add_argument('--seed', type=int, default=0)
parser.add_argument('--image_file', type=str)

args = parser.parse_args()

# Setup
assert args.top_k <= 256, "It is recommended that top_k is set lower than 256."

sys.stdout.write(f"Setting seed to {args.seed} ...\n")
sys.stdout.flush()
set_seed(args.seed)

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
#device = 'cuda:0'
print(torch.cuda.get_device_properties(device))


sys.stdout.write("Loading model minDALL-E/1.3B ...\n")
sys.stdout.flush()
model = Dalle.from_pretrained('minDALL-E/1.3B')  # This will automatically download the pretrained model.
model.to(device=device)

sys.stdout.write("Sampling ...\n")
sys.stdout.flush()

# Sampling
images = model.sampling(prompt=args.prompt,
                        top_k=args.top_k,
                        top_p=args.top_p,
                        softmax_temperature=args.softmax_temperature,
                        num_candidates=args.num_candidates,
                        device=device).cpu().numpy()
images = np.transpose(images, (0, 2, 3, 1))

sys.stdout.write("Ranking images ...\n")
sys.stdout.flush()

# CLIP Re-ranking
model_clip, preprocess_clip = clip.load("ViT-B/32", device=device)
model_clip.to(device=device)
rank = clip_score(prompt=args.prompt,
                  images=images,
                  model_clip=model_clip,
                  preprocess_clip=preprocess_clip,
                  device=device)

sys.stdout.write("Saving images ...\n")
sys.stdout.flush()

# Save images
images = images[rank]
print(rank, images.shape)
if not os.path.exists('./figures'):
    os.makedirs('./figures')
#for i in range(min(16, args.num_candidates)):
for i in range(args.images):
    im = Image.fromarray((images[i]*255).astype(np.uint8))
    filename = f'{args.image_file} {i+1}.png'
    im.save(filename)
    #sys.stdout.write(f"Saved {filename}\n")
    sys.stdout.write(f"Saved image {i+1}/{args.images}\n")
    sys.stdout.flush()

sys.stdout.write("Done")
sys.stdout.flush()
