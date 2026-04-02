# nshepperd Stylegan3.ipynb
# Original file is located at https://colab.research.google.com/drive/1eYlenR1GHPZXt-YuvXabzO9wfh9CWY36

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP')
sys.path.append('./stylegan3')

import os

import io
import os, time
import pickle
import shutil
import numpy as np
from PIL import Image
import torch
import torch.nn.functional as F
import requests
import torchvision.transforms as transforms
import torchvision.transforms.functional as TF
from CLIP.clip import clip
from tqdm.notebook import tqdm
from torchvision.transforms import Compose, Resize, CenterCrop, ToTensor, Normalize
from IPython.display import display
from einops import rearrange
import dnnlib
import legacy
import argparse
import glob,re

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--network', type=str, help='Network name.')
  parser.add_argument('--outdir', type=str, help='Directory to save output image to.')
  args = parser.parse_args()
  return args

args=parse_args();




device = torch.device('cuda:0')
#print('Using device:', device, file=sys.stderr)

def norm1(prompt):
    "Normalize to the unit sphere."
    return prompt / prompt.square().sum(dim=-1,keepdim=True).sqrt()

def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)

class MakeCutouts(torch.nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        for _ in range(self.cutn):
            size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(F.adaptive_avg_pool2d(cutout, self.cut_size))
        return torch.cat(cutouts)

make_cutouts = MakeCutouts(224, 32, 0.5)

def embed_image(image):
  n = image.shape[0]
  cutouts = make_cutouts(image)
  embeds = clip_model.embed_cutout(cutouts)
  embeds = rearrange(embeds, '(cc n) c -> cc n c', n=n)
  return embeds

def embed_url(url):
  #image = Image.open(fetch(url)).convert('RGB')
  image = Image.open(url).convert('RGB')
  return embed_image(TF.to_tensor(image).to(device).unsqueeze(0)).mean(0).squeeze(0)

class CLIP(object):
  def __init__(self):
    clip_model = "ViT-B/32"
    self.model, _ = clip.load(clip_model)
    self.model = self.model.requires_grad_(False)
    self.normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                          std=[0.26862954, 0.26130258, 0.27577711])

  @torch.no_grad()
  def embed_text(self, prompt):
      "Normalized clip text embedding."
      return norm1(self.model.encode_text(clip.tokenize(prompt).to(device)).float())

  def embed_cutout(self, image):
      "Normalized clip image embedding."
      return norm1(self.model.encode_image(self.normalize(image)))

#base_url = "https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan3/versions/1/files/"
#model_name = "stylegan3-r-metfacesu-1024x1024.pkl"
#model_name = "stylegan3-t-afhqv2-512x512.pkl"
#network_url = base_url + model_name
network_url = args.network

#with open(fetch_model(network_url), 'rb') as fp:
#  G = pickle.load(fp)['G_ema'].to(device)

sys.stdout.write('Loading networks from "%s"...' % network_url)
sys.stdout.flush()
with dnnlib.util.open_url(network_url, cache_dir=".\..\.cache") as f:
    G= legacy.load_network_pkl(f)['G_ema'].to(device) # type: ignore




# # Fix the coordinate grid to w_avg
# shift = G.synthesis.input.affine(G.mapping.w_avg.unsqueeze(0))
# G.synthesis.input.affine.bias.data.add_(shift.squeeze(0))
# G.synthesis.input.affine.weight.data.zero_()

zs = torch.randn([10000, G.mapping.z_dim], device=device)
w_stds = G.mapping(zs, None).std(0)

sys.stdout.write("Loading CLIP model ...\n")
sys.stdout.flush()

clip_model = CLIP()

# target = clip_model.embed_text("smug")
target = clip_model.embed_text(args.prompt)
# target = embed_url("https://4.bp.blogspot.com/-uw859dFGsLc/Va5gt-bU9bI/AAAAAAAA4gM/dcaWzX0ZxdI/s1600/Lubjana+dragon+1.jpg")
# target = embed_url("nexus.png")
steps = args.iterations
seed = args.seed


tf = Compose([
  Resize(224),
  lambda x: torch.clamp((x+1)/2,min=0,max=1),
  ])

"""
def run():
  torch.manual_seed(seed)
  timestring = time.strftime('%Y%m%d%H%M%S')
  q = (G.mapping(torch.randn([1,G.mapping.z_dim], device=device), None, truncation_psi=0.2) - G.mapping.w_avg) / w_stds
  q.requires_grad_()

  w_ema = torch.zeros([1,16,512]).to(device)
  opt = torch.optim.AdamW([q], lr=0.03, betas=(0.0,0.999))
  #loop = tqdm(range(steps))
  for i in range(args.iterations): #loop:

    sys.stdout.write("Iteration {}/{} ...".format(i+1,args.iterations)+"\n")
    sys.stdout.flush()

    opt.zero_grad()
    w = q * w_stds
    image = G.synthesis(w + G.mapping.w_avg, noise_mode='const')
    embed = embed_image(image.add(1).div(2))
    loss = spherical_dist_loss(embed, target).mean()
    loss.backward()
    opt.step()
    #loop.set_postfix(loss=loss.item(), q_magnitude=q.std().item())

    w_ema = w_ema * 0.9 + w * 0.1
    image = G.synthesis(w_ema + G.mapping.w_avg, noise_mode='const')

    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    pil_image = TF.to_pil_image(image[0].add(1).div(2).clamp(0,1))
    pil_image.save(args.outdir+'Progress.jpg')

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    
    #1 second delay to give VoC enough time to handle the saved frame
    time.sleep(1)
"""


def run():
  torch.manual_seed(seed)
  timestring = time.strftime('%Y%m%d%H%M%S')

  # Init
  # Method 1: sample 32 inits and choose the one closest to prompt  with torch.no_grad():
  
  qs = []
  losses = []
  for _ in range(8):
    q = (G.mapping(torch.randn([4,G.mapping.z_dim], device=device), None, truncation_psi=0.7) - G.mapping.w_avg) / w_stds
    images = G.synthesis(q * w_stds + G.mapping.w_avg)
    embeds = embed_image(images.add(1).div(2))
    loss = spherical_dist_loss(embeds, target).mean(0)
    i = torch.argmin(loss)
    qs.append(q[i])
    losses.append(loss[i])
  qs = torch.stack(qs)
  losses = torch.stack(losses)
  print(losses)
  print(losses.shape, qs.shape)
  i = torch.argmin(losses)
  q = qs[i].unsqueeze(0)

  # Method 2: Random init depending only on the seed.
  # this ignores the above Method 1 and uses a random init
  # without this, using the same seed and a different prompt gives different starting images
  # which is annoying if you find a good starting image and want to try different prompts
  
  q = (G.mapping(torch.randn([1,G.mapping.z_dim], device=device), None, truncation_psi=0.7) - G.mapping.w_avg) / w_stds
  q.requires_grad_()

  q_ema = q
  #opt = torch.optim.AdamW([q], lr=0.03, betas=(0.0,0.999))
  opt = torch.optim.AdamW([q], lr=0.03, betas=(0.0,0.999))
  for i in range(args.iterations): #loop:

    sys.stdout.write("Iteration {}/{} ...".format(i+1,args.iterations)+"\n")
    sys.stdout.flush()

    opt.zero_grad()
    w = q * w_stds
    image = G.synthesis(w + G.mapping.w_avg, noise_mode='const')
    embed = embed_image(image.add(1).div(2))
    loss = spherical_dist_loss(embed, target).mean()
    loss.backward()
    opt.step()

    q_ema = q_ema * 0.9 + q * 0.1
    image = G.synthesis(q_ema * w_stds + G.mapping.w_avg, noise_mode='const')

    pil_image = TF.to_pil_image(image[0].add(1).div(2).clamp(0,1))
    
    #auto-increment frame file number FRA00000.PNG, FRA00001.PNG etc
    currentImages = glob.glob(args.outdir+"\FRA?????.png")
    numList = [0]
    for img in currentImages:
        i2 = os.path.splitext(img)[0]
        try:
            num = re.findall('[0-9]+$', i2)[0]
            numList.append(int(num))
        except IndexError:
            pass
    numList = sorted(numList)
    newNum = numList[-1]+1
    saveName = args.outdir+'\FRA%05d.png' % newNum
    #print("Saving %s" % saveName)
    pil_image.save(saveName)


sys.stdout.write("Starting ...\n")
sys.stdout.flush()

run()