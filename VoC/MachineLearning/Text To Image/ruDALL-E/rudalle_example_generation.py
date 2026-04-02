# ruDALLE-example-generation.ipynb
# Original file is located at https://colab.research.google.com/drive/1wGE-046et27oHvNlBNPH07qrEQNE04PQ

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./ru-dalle')

import multiprocessing
import torch
from psutil import virtual_memory
from rudalle.pipelines import generate_images, show, super_resolution, cherry_pick_by_clip
from rudalle import get_rudalle_model, get_tokenizer, get_vae, get_realesrgan, get_ruclip
from rudalle.utils import seed_everything
from deep_translator import GoogleTranslator

import argparse

global itt_start #value the iteration loop counter starts at

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  args = parser.parse_args()
  return args

args=parse_args();

#text = 'синий кот' # blue cat
sys.stdout.write("Translating prompt to Russian ...\n")
sys.stdout.flush()
text = GoogleTranslator(source='auto', target='ru').translate(args.prompt)



sys.stdout.write("Preparing DALL-E ...\n")
sys.stdout.flush()

device = 'cuda'
dalle = get_rudalle_model('Malevich', pretrained=True, fp16=True, device=device)

realesrgan = get_realesrgan('x4', device=device)
tokenizer = get_tokenizer()
vae = get_vae().to(device)
ruclip, ruclip_processor = get_ruclip('ruclip-vit-base-patch32-v5')
ruclip = ruclip.to(device)


pil_images = []
scores = []

sys.stdout.write(f'Setting seed to {args.seed} ...\n')
sys.stdout.flush()

seed_everything(args.seed)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

"""
for top_k, top_p, images_num in [
    (2048, 0.995, 3),
    (1536, 0.99, 3),
    (1024, 0.99, 3),
    (1024, 0.98, 3),
    (512, 0.97, 3),
    (384, 0.96, 3),
    (256, 0.95, 3),
    (128, 0.95, 3), 
]:
"""

itt_start=0
for top_k, top_p, images_num in [
    (2048, 0.995, 1),
    (1536, 0.99, 1),
    (1024, 0.99, 1),
    (1024, 0.98, 1),
    (512, 0.97, 1),
    (384, 0.96, 1),
    (256, 0.95, 1),
    (128, 0.95, 1), 
]:

    _pil_images, _scores = generate_images(text, tokenizer, dalle, vae, top_k=top_k, itt_start=itt_start, images_num=images_num, top_p=top_p)
    pil_images += _pil_images
    scores += _scores
    itt_start+=1024 // 8

#auto-cherry-pick by ruCLIP
top_images, clip_scores = cherry_pick_by_clip(pil_images, text, ruclip, ruclip_processor, device=device, count=1)
show(top_images, 1)