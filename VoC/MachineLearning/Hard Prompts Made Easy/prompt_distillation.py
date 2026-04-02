#!/usr/bin/env python
# coding: utf-8

# In[1]:

import os

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import open_clip
from optim_utils import * 
import torch
import mediapy as media
import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--prompt_len', type=int)
  parser.add_argument('--iters', type=int)
  args = parser.parse_args()
  return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()



# ## Load Arguments

# In[2]:


args = argparse.Namespace()
args.__dict__.update(read_json("sample_config.json"))

args.prompt_len = args2.prompt_len
args.iter = args2.iters

args


# ## Load Clip Model

# In[3]:


device = "cuda" if torch.cuda.is_available() else "cpu"
model, _, preprocess = open_clip.create_model_and_transforms(args.clip_model, pretrained=args.clip_pretrain, device=device)


# ## Load Diffusion Model

# In[4]:


from diffusers import DPMSolverMultistepScheduler, StableDiffusionPipeline

model_id = "stabilityai/stable-diffusion-2-1-base"
scheduler = DPMSolverMultistepScheduler.from_pretrained(model_id, subfolder="scheduler")

pipe = StableDiffusionPipeline.from_pretrained(
    model_id,
    scheduler=scheduler,
    torch_dtype=torch.float16,
    revision="fp16",
    )
pipe = pipe.to(device)

image_length = 512


# ## Enter Target Prompt

# In[5]:


target_prompts = [
        args2.prompt,
       ]
print(target_prompts)


# ## Optimize Prompt

# In[6]:


learned_prompt = optimize_prompt(model, preprocess, args, device, target_prompts=target_prompts)

"""
# ## Generate with Stable Diffusion Model

# In[7]:


num_images = 4
guidance_scale = 9
num_inference_steps = 25
seed = 0

set_random_seed(seed)
images = pipe(
    target_prompts[0],
    num_images_per_prompt=num_images,
    guidance_scale=guidance_scale,
    num_inference_steps=num_inference_steps,
    height=image_length,
    width=image_length,
    ).images
print(f"original prompt: {target_prompts[0]}")
media.show_images(images)

set_random_seed(seed)
images = pipe(
    learned_prompt,
    num_images_per_prompt=num_images,
    guidance_scale=guidance_scale,
    num_inference_steps=num_inference_steps,
    height=image_length,
    width=image_length,
    ).images

print(f"learned prompt: {learned_prompt}")
media.show_images(images)


# In[ ]:

"""


