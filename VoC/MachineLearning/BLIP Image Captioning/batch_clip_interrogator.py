# clip-interrogator.ipynb
# Original file is located at https://colab.research.google.com/github/pharmapsychotic/clip-interrogator/blob/main/clip_interrogator.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP')
sys.path.append('./BLIP')

import os

#the next line should allow sys.stdout to handle unicode characters
sys.stdout.reconfigure(encoding='utf-8')

import clip
import gc
import io
import math
import numpy as np
import pandas as pd
import requests
import torch
import torchvision.transforms as T
import torchvision.transforms.functional as TF
from PIL import Image
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms.functional import InterpolationMode
from models.blip import blip_decoder
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--image', type=str, help='Image to generate caption for.')
  parser.add_argument('--ViTB32', type=int)
  parser.add_argument('--ViTB16', type=int)
  parser.add_argument('--ViTL14', type=int)
  parser.add_argument('--ViTL14_336px', type=int)
  parser.add_argument('--RN101', type=int)
  parser.add_argument('--RN50', type=int)
  parser.add_argument('--RN50x4', type=int)
  parser.add_argument('--RN50x16', type=int)
  parser.add_argument('--RN50x64', type=int)
  parser.add_argument('--ViTH14', type=int)
  parser.add_argument('--ViTG14', type=int)
  args = parser.parse_args()
  return args

args2=parse_args();


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)


sys.stdout.write("Loading BLIP ...\n")
sys.stdout.flush()

blip_image_eval_size = 384
blip_model = blip_decoder(pretrained='model_large_caption.pth', image_size=384, vit='large', med_config = './BLIP/configs/med_config.json')
blip_model.eval()
blip_model = blip_model.to(device)


def generate_caption(pil_image):
    gpu_image = transforms.Compose([
        transforms.Resize((blip_image_eval_size, blip_image_eval_size), interpolation=InterpolationMode.BICUBIC),
        transforms.ToTensor(),
        transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
    ])(image).unsqueeze(0).to(device)

    with torch.no_grad():
        caption = blip_model.generate(gpu_image, sample=False, num_beams=3, max_length=20, min_length=5)
    return caption[0]

def load_list(name):
    #with open(f"/content/clip-interrogator/data/{name}.txt", 'r', encoding='utf-8', errors='replace') as f:
    with open(f"./data/{name}.txt", 'r', encoding='utf-8', errors='replace') as f:
        items = [line.strip() for line in f.readlines()]
    return items

def rank(model, image_features, text_array, top_count=1):
    top_count = min(top_count, len(text_array))
    text_tokens = clip.tokenize([text for text in text_array]).cuda()
    with torch.no_grad():
        text_features = model.encode_text(text_tokens).float()
    text_features /= text_features.norm(dim=-1, keepdim=True)

    similarity = torch.zeros((1, len(text_array))).to(device)
    for i in range(image_features.shape[0]):
        similarity += (100.0 * image_features[i].unsqueeze(0) @ text_features.T).softmax(dim=-1)
    similarity /= image_features.shape[0]

    top_probs, top_labels = similarity.cpu().topk(top_count, dim=-1)  
    return [(text_array[top_labels[0][i].numpy()], (top_probs[0][i].numpy()*100)) for i in range(top_count)]

def interrogate(image, models):
    caption = generate_caption(image)
    if len(models) == 0:
        print(f"\n\n{caption}")
        return

    table = []
    bests = [[('',0)]]*5
    for model_name in models:
        sys.stdout.write(f"Interrogating with {model_name}...\n")
        sys.stdout.flush()


        model, preprocess = clip.load(model_name)
        model.cuda().eval()

        images = preprocess(image).unsqueeze(0).cuda()
        with torch.no_grad():
            image_features = model.encode_image(images).float()
        image_features /= image_features.norm(dim=-1, keepdim=True)

        ranks = [
            rank(model, image_features, mediums),
            rank(model, image_features, ["by "+artist for artist in artists]),
            rank(model, image_features, trending_list),
            rank(model, image_features, movements),
            rank(model, image_features, flavors, top_count=3)
        ]

        for i in range(len(ranks)):
            confidence_sum = 0
            for ci in range(len(ranks[i])):
                confidence_sum += ranks[i][ci][1]
            if confidence_sum > sum(bests[i][t][1] for t in range(len(bests[i]))):
                bests[i] = ranks[i]

        row = [model_name]
        for r in ranks:
            row.append(', '.join([f"{x[0]} ({x[1]:0.1f}%)" for x in r]))

        table.append(row)

        del model
        gc.collect()
    #display(pd.DataFrame(table, columns=["Model", "Medium", "Artist", "Trending", "Movement", "Flavors"]))

    flaves = ', '.join([f"{x[0]}" for x in bests[4]])
    medium = bests[0][0][0]
    """
    if caption.startswith(medium):
        sys.stdout.write(f"\n{caption} {bests[1][0][0]}, {bests[2][0][0]}, {bests[3][0][0]}, {flaves}\n")
        sys.stdout.write("or with | characters separating prompt parts\n")
        sys.stdout.write(f"{caption} | {bests[1][0][0]} | {bests[2][0][0]} | {bests[3][0][0]} | {flaves}\n")
        sys.stdout.flush()
    else:
        sys.stdout.write(f"\n{caption}, {medium} {bests[1][0][0]}, {bests[2][0][0]}, {bests[3][0][0]}, {flaves}\n")
        sys.stdout.write("or with | characters separating prompt parts\n")
        sys.stdout.write(f"{caption} | {medium} {bests[1][0][0]} | {bests[2][0][0]} | {bests[3][0][0]} | {flaves}\n")
        sys.stdout.flush()
    """
    if caption.startswith(medium):
        return f"{caption} {bests[1][0][0]}, {bests[2][0][0]}, {bests[3][0][0]}, {flaves}"
    else:
        return f"{caption}, {medium} {bests[1][0][0]}, {bests[2][0][0]}, {bests[3][0][0]}, {flaves}"
    

artists = load_list('artists')
flavors = load_list('flavors')
mediums = load_list('mediums')
movements = load_list('movements')
sites = ['Artstation', 'behance', 'cg society', 'cgsociety', 'deviantart', 'dribble', 'flickr', 'instagram', 'pexels', 'pinterest', 'pixabay', 'pixiv', 'polycount', 'reddit', 'shutterstock', 'tumblr', 'unsplash', 'zbrush central']
trending_list = [site for site in sites]
trending_list.extend(["trending on "+site for site in sites])
trending_list.extend(["featured on "+site for site in sites])
trending_list.extend([site+" contest winner" for site in sites])

#@title Interrogate!

#@markdown 

#@markdown #####**Image:**

image_path_or_url = args2.image #"https://cdnb.artstation.com/p/assets/images/images/032/142/769/large/ignacio-bazan-lazcano-book-4-final.jpg" #@param {type:"string"}

#@markdown 

sys.stdout.write("Loading CLIP ...\n")
sys.stdout.flush()

#@markdown #####**CLIP models:**
if args2.ViTB32 == 1:
    ViTB32 = True #@param{type:"boolean"}
else:
    ViTB32 = False #@param{type:"boolean"}

if args2.ViTB16 == 1:
    ViTB16 = True #@param{type:"boolean"}
else:
    ViTB16 = False #@param{type:"boolean"}

if args2.ViTL14 == 1:
    ViTL14 = True #@param{type:"boolean"}
else:
    ViTL14 = False #@param{type:"boolean"}

if args2.ViTL14_336px == 1:
    ViTL14_336px = True #@param{type:"boolean"}
else:
    ViTL14_336px = False #@param{type:"boolean"}

if args2.RN101 == 1:
    RN101 = True #@param{type:"boolean"}
else:
    RN101 = False #@param{type:"boolean"}

if args2.RN50 == 1:
    RN50 = True #@param{type:"boolean"}
else:
    RN50 = False #@param{type:"boolean"}

if args2.RN50x4 == 1:
    RN50x4 = True #@param{type:"boolean"}
else:
    RN50x4 = False #@param{type:"boolean"}

if args2.RN50x16 == 1:
    RN50x16 = True #@param{type:"boolean"}
else:
    RN50x16 = False #@param{type:"boolean"}

if args2.RN50x64 == 1:
    RN50x64 = True #@param{type:"boolean"}
else:
    RN50x64 = False #@param{type:"boolean"}

if args2.ViTH14 == 1:
    ViTH14 = True #@param{type:"boolean"}
else:
    ViTH14 = False #@param{type:"boolean"}

if args2.ViTG14 == 1:
    ViTG14 = True #@param{type:"boolean"}
else:
    ViTG14 = False #@param{type:"boolean"}

models = []
if ViTB32: models.append('ViT-B/32')
sys.stdout.flush()
if ViTB16: models.append('ViT-B/16')
sys.stdout.flush()
if ViTL14: models.append('ViT-L/14')
sys.stdout.flush()
if ViTL14_336px: models.append('ViT-L/14@336px')
sys.stdout.flush()
if RN101: models.append('RN101')
sys.stdout.flush()
if RN50: models.append('RN50')
sys.stdout.flush()
if RN50x4: models.append('RN50x4')
sys.stdout.flush()
if RN50x16: models.append('RN50x16')
sys.stdout.flush()
if RN50x64: models.append('RN50x64')
sys.stdout.flush()
if ViTH14: models.append('ViT-H-14')
sys.stdout.flush()
if ViTG14: models.append('ViT-g-14')
sys.stdout.flush()

if str(image_path_or_url).startswith('http://') or str(image_path_or_url).startswith('https://'):
    image = Image.open(requests.get(image_path_or_url, stream=True).raw).convert('RGB')
else:
    image = Image.open(image_path_or_url).convert('RGB')

sys.stdout.write("Captioning image ...\n")
sys.stdout.flush()

cap = interrogate(image, models=models)

sys.stdout.write(f"Image caption = {cap}\n")
sys.stdout.flush()
