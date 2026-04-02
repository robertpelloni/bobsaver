#!/usr/bin/env python
# coding: utf-8

# In[ ]:

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from shap_e.diffusion.sample import sample_latents
from shap_e.diffusion.gaussian_diffusion import diffusion_from_config
from shap_e.models.download import load_model, load_config
from shap_e.util.notebooks import create_pan_cameras, decode_latent_images, gif_widget
from shap_e.util.image_util import load_image
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()

    parser.add_argument("--image", type=str)
    parser.add_argument("--output", type=str)
    parser.add_argument("--mesh_detail", type=int)
    parser.add_argument("--iterations", type=int)
    parser.add_argument("--render_mode", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading models ...\n")
sys.stdout.flush()

xm = load_model('transmitter', device=device)
model = load_model('image300M', device=device)
diffusion = diffusion_from_config(load_config('diffusion'))

sys.stdout.write("Generating mesh ...\n")
sys.stdout.flush()

batch_size = 1
guidance_scale = 3.0

image = load_image(args2.image)

latents = sample_latents(
    batch_size=batch_size,
    model=model,
    diffusion=diffusion,
    guidance_scale=guidance_scale,
    model_kwargs=dict(images=[image] * batch_size),
    progress=True,
    clip_denoised=True,
    use_fp16=True,
    use_karras=True,
    karras_steps=args2.iterations,
    sigma_min=1e-3,
    sigma_max=160,
    s_churn=0,
)


# In[ ]:


render_mode = args2.render_mode #'nerf' # you can change this to 'stf' for mesh rendering
size = args2.mesh_detail # this is the size of the renders; higher values take longer to render.

cameras = create_pan_cameras(size, device)
"""
for i, latent in enumerate(latents):
    images = decode_latent_images(xm, latent, cameras, rendering_mode=render_mode)
    display(gif_widget(images))
"""

sys.stdout.write("Saving mesh ...\n")
sys.stdout.flush()

# Example of saving the latents as meshes.
from shap_e.util.notebooks import decode_latent_mesh

for i, latent in enumerate(latents):
    with open(args2.output, 'wb') as f:
        decode_latent_mesh(xm, latent).tri_mesh().write_ply(f)

sys.stdout.write("Done\n")
sys.stdout.flush()

