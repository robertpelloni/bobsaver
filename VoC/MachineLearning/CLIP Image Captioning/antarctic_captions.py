# Antarctic-Captions
# Original file is located at https://colab.research.google.com/drive/1FwGEVKXvmpeMvAYqGr4z7Nt3llaZz-F8
# By: dzryk (discord, https://twitter.com/dzryk, https://github.com/dzryk)

# model checkpoint and cache from https://the-eye.eu/public/AI/models/antarctic-captions/

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import argparse
import io
import numpy as np
import torch
import torch.nn as nn
import requests
import pytorch_lightning as pl
#import matplotlib.pyplot as plt
import torchvision.transforms.functional as F

from CLIP.clip import clip
from PIL import Image
from pytorch_lightning.callbacks import ModelCheckpoint
from torchvision.utils import make_grid

sys.path.append('./antarctic_captions')

import model
import utils


import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--image', type=str, help='Image to generate captions for.')
  parser.add_argument('--topp', type=float, help='topp')
  parser.add_argument('--temperature', type=float, help='temperature')
  args = parser.parse_args()
  return args

args2=parse_args();


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)

# Helper functions
def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')

def load_image(img, preprocess):
    img = Image.open(fetch(img))
    return img, preprocess(img).unsqueeze(0).to(device)

def show(imgs):
    if not isinstance(imgs, list):
        imgs = [imgs]
    #fix, axs = plt.subplots(ncols=len(imgs), squeeze=False)
    for i, img in enumerate(imgs):
        img = img.detach()
        img = F.to_pil_image(img)
        #axs[0, i].imshow(np.asarray(img))
        #axs[0, i].set(xticklabels=[], yticklabels=[], xticks=[], yticks=[])

def display_grid(imgs):
    reshaped = [F.to_tensor(x.resize((256, 256))) for x in imgs]
    show(make_grid(reshaped))
    
def clip_rescoring(args, net, candidates, x):
    textemb = net.perceiver.encode_text(
        clip.tokenize(candidates).to(args.device)).float()
    textemb /= textemb.norm(dim=-1, keepdim=True)
    similarity = (100.0 * x @ textemb.T).softmax(dim=-1)
    _, indices = similarity[0].topk(args.num_return_sequences)
    return [candidates[idx] for idx in indices[0]]

def loader(args):
    sys.stdout.write("Loading postcache.txt ...\n")
    sys.stdout.flush()
    
    cache = []
    with open(args.textfile) as f:
        for line in f:
            cache.append(line.strip())

    sys.stdout.write("Loading postcache.npy ...\n")
    sys.stdout.flush()

    cache_emb = np.load(args.embfile)

    sys.stdout.write("Loading -epoch=05-vloss=2.163.ckpt ...\n")
    sys.stdout.flush()

    net = utils.load_ckpt(args)
    net.cache = cache
    net.cache_emb = torch.tensor(cache_emb).to(args.device)

    sys.stdout.write("Loading ViT-B/16 CLIP model ...\n")
    sys.stdout.flush()

    preprocess = clip.load(args.clip_model, jit=False)[1]
    return net, preprocess
    
def caption_image(path, args, net, preprocess):
    captions = []
    img, mat = load_image(path, preprocess)
    table, x = utils.build_table(mat.to(device), 
                          perceiver=net.perceiver,
                          cache=net.cache,
                          cache_emb=net.cache_emb,
                          topk=args.topk,
                          return_images=True)
    table = net.tokenizer.encode(table[0], return_tensors='pt').to(device)
    out = net.model.generate(table,
                             do_sample=args.do_sample,
                             num_beams=args.num_beams,
                             temperature=args.temperature,
                             top_p=args.top_p,
                             num_return_sequences=args.num_return_sequences)
    candidates = []
    for seq in out:
        candidates.append(net.tokenizer.decode(seq, skip_special_tokens=True))
    captions = clip_rescoring(args, net, candidates, x[None,:])
    for c in captions[:args.display]:
        print(c)
    display_grid([img])
    return captions

# Settings
#filedir='the-eye.eu/public/AI/models/antarctic-captions/'
filedir='.'
args = argparse.Namespace(
    #ckpt=f'{filedir}/-epoch=05-vloss=2.163.ckpt',
    #textfile=f'{filedir}/postcache.txt',
    #embfile=f'{filedir}/postcache.npy',
    ckpt='-epoch=05-vloss=2.163.ckpt',
    textfile='postcache.txt',
    embfile='postcache.npy',
    clip_model='ViT-B/16',
    topk=10,
    num_return_sequences=1000,
    num_beams=1,
    temperature=args2.temperature,
    top_p=args2.topp,
    display=5,
    do_sample=True,
    device=device
)

#sys.stdout.write("Loading checkpoint and preprocessor ...\n")
#sys.stdout.flush()

# Load checkpoint and preprocessor
net, preprocess = loader(args)

sys.stdout.write("Generating captions ...\n\n")
sys.stdout.flush()

img = args2.image
captions = caption_image(img, args, net, preprocess)
