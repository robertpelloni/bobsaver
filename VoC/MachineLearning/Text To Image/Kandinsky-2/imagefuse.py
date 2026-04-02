import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
from kandinsky2 import get_kandinsky2
from PIL import Image

import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt")
    parser.add_argument("--num_steps", type=int)
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--guidance_scale", type=int)
    parser.add_argument("--w", type=int)
    parser.add_argument("--h", type=int)
    parser.add_argument("--prior_cf_scale", type=int)
    parser.add_argument("--prior_steps", type=str)
    parser.add_argument("--sampler", type=str)
    parser.add_argument("--model_version", type=str)
    parser.add_argument("--image_file", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write(f"Loading model v{args2.model_version}...\n")
sys.stdout.flush()

if args2.model_version=='2':
    model = get_kandinsky2('cuda', task_type='text2img')
else:
    model = get_kandinsky2('cuda', task_type='text2img', model_version='2.1', use_flash_attention=False)

images_texts = []
weights = []

images = model.mix_images(
    images_texts, 
    weights, 
    num_steps=150,
    batch_size=1, 
    guidance_scale=5,
    h=768, w=768,
    sampler='p_sampler', 
    prior_cf_scale=4,
    prior_steps="5"
)

sys.stdout.write("Saving image(s) ...\n")
sys.stdout.flush()

if len(images)==1:
    images[0].save(args2.image_file, format='png')
else:
    count=0
    for x in images:
        count=count+1
        x.save(args2.image_file[:-4]+' '+str(count)[:1]+'.png', format='png')

sys.stdout.write("Progress saved\n")
sys.stdout.flush()
