# Structured Dreaming - Styledreams.ipynb
# Original file is located at https://colab.research.google.com/github/ekgren/StructuredDreaming/blob/main/colabs/Structured_Dreaming_Styledreams.ipynb

# Author: Ariel Ekgren  
# https://github.com/ekgren  
# https://twitter.com/ArYoMo  

"""
!pip install ftfy regex tqdm pyspng ninja imageio-ffmpeg==0.4.3
!git clone https://github.com/ekgren/StructuredDreaming.git
!pip install -e ./StructuredDreaming
!git clone https://github.com/NVlabs/stylegan2-ada-pytorch.git

"""
import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.insert(1, 'stylegan2-ada-pytorch')

import argparse
# Imports
import random
import torch
import torchvision
import PIL
from matplotlib import pyplot as pl
from IPython.display import clear_output

# StructuredDreaming imports
from StructuredDreaming import structure
from StructuredDreaming.structure import clip
from StructuredDreaming.structure import sample
from StructuredDreaming.structure import optim

# Stylegan imports
import dnnlib
import legacy



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--network', type=str, help='Network name.')
  parser.add_argument('--outdir', type=str, help='Directory to save output image to.')
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





# Load models

sys.stdout.write("Loading CLIP model ...\n")
sys.stdout.flush()

perceptor, normalize_image = structure.clip.load('ViT-B/16', jit=False)

# Utils
def display_img(input: torch.Tensor, size: float = 1.):
    """ Assumes tensor values in the range [0, 1] """
    with torch.no_grad():
        batch_size, num_channels, height, width = input.shape
        img = torch.nn.functional.interpolate(input, (int(size*height), int(size*width)), mode='area')
        img_show = img.cpu()[0].transpose(0, 1).transpose(1, 2)
        img_out = (img_show * 255).clamp(0, 255).to(torch.uint8)
        #display(PIL.Image.fromarray(img_out.cpu().numpy(), 'RGB'))
        img = PIL.Image.fromarray(img_out.cpu().numpy(), 'RGB')
        img.save(args.outdir+"Progress.png")
        #pl.show()

def stylegan_to_rgb(input: torch.Tensor) -> torch.Tensor:
    return (input * 127.5 + 128) / 255

#display_img(torch.rand(1, 3, 10, 10, requires_grad=False), 4)

#@title # Prompt and training parameters{ run: "auto" }
#@markdown Write your image prompt in the txt field below.

#@markdown Prompt suggestions:
#@markdown * "portrait painting of android from dystopic future by James Gurney"

#txt = "portrait painting of neon gods by Into the Void" #@param {type:"string"}
txt = args.prompt

# Training parameters
iterations = args.iterations
grad_acc_steps = 1
batch_size = 1
lr = 5e-4
loss_scale = 100.
steps_show = 32
truncation_psi = 0.6
clamp_val = 1e-30

# Sampler
kernel_min = 1
kernel_max = 8

sys.stdout.write("Loading "+args.network+" ...\n")
sys.stdout.flush()

#network_pkl = 'https://nvlabs-fi-cdn.nvidia.com/stylegan2-ada-pytorch/pretrained/ffhq.pkl'
network_pkl = args.network

#@title Train loop {vertical-output: true}
#@markdown Loading and fine-tuning the model.

device = torch.device('cuda')
with dnnlib.util.open_url(network_pkl) as f:
    G = legacy.load_network_pkl(f)['G_ema'].to(device) # type: ignore
for p in G.parameters():
    p.requires_grad = True
c = None

# Training
txt_tok = structure.clip.tokenize(txt)
text_latent = perceptor.encode_text(txt_tok.to(device)).detach()
sampler = torch.jit.script(
              structure.sample.ImgSampleStylegan(kernel_min=kernel_min,
                                                 kernel_max=kernel_max).to(device)
          )
optimizer = structure.optim.ClampSGD(list(G.parameters()),
                                     lr=lr, 
                                     clamp=clamp_val)

im_no = 0

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

for i in range(iterations):

    if (i+1) % 10 == 0:
        sys.stdout.write("Iteration {}/{} ...".format(i+1,iterations)+"\n")
        sys.stdout.flush()

    for j in range(grad_acc_steps):
        optimizer.zero_grad()
        z = torch.randn([1, G.z_dim], device=device)
        img = G(z, c, truncation_psi)
        img = stylegan_to_rgb(img)
        img = sampler(img, size=224, bs=batch_size)
        img = normalize_image(img)
        img_latents = perceptor.encode_image(img)
        loss = torch.cosine_similarity(text_latent, img_latents, dim=-1).mean().neg() * loss_scale
        
        loss.backward()

    optimizer.step()

#@title Generate images from the fine-tuned model

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

with torch.no_grad():
    #clear_output(True)
    z = torch.randn([1, G.z_dim], device=device)
    img = G(z, c, truncation_psi)
    img = stylegan_to_rgb(img)
    display_img(img, 1.)

