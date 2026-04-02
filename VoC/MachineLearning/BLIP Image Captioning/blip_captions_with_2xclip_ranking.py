# BLIP Captions with 2xCLIP ranking.ipynb
# Original file is located at https://colab.research.google.com/drive/1fKxiDMa-9uu1A6XiYjxTbYxSagvbZ8Fb

# git clone https://github.com/christophschuhmann/BLIP/
# model_url = 'https://storage.googleapis.com/sfr-vision-language-research/BLIP/models/model_large_caption.pth'
# pip install fairscale==0.4.4

# pip install grammar-check #https://pypi.org/project/grammar-check/
# pip install clip-anytorch 
# pip install transformers==4.15.0 timm==0.4.12 fairscale==0.4.4

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('.\CLIP')
sys.path.append('.\BLIP')

import os

import torch
import sys
from PIL import Image
import requests
import torch
from torchvision import transforms
from torchvision.transforms.functional import InterpolationMode
import sys
from PIL import Image
import numpy as np
import torch
import clip
from models.blip import blip_decoder
#import glob
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--image', type=str, help='Image to generate caption for.')
  args = parser.parse_args()
  return args

args2=parse_args();


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)


rep_pen=1.4

def cos_sim_2d(x, y):
    norm_x = x / np.linalg.norm(x, axis=1, keepdims=True)
    norm_y = y / np.linalg.norm(y, axis=1, keepdims=True)
    return np.matmul(norm_x, norm_y.T)

def clip_rank(image_pil,text_list, clip_model="ViT-L/14"):

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model, preprocess = clip.load(clip_model, device=device)
    #model2, preprocess2 = clip.load("RN50x64", device=device)

    similarities= []
    image = preprocess(image_pil).unsqueeze(0).to(device)
    #image2 = preprocess2(image_pil).unsqueeze(0).to(device)

    with torch.no_grad():
        image_features = model.encode_image(image).cpu().detach().numpy()
        #image_features2 = model2.encode_image(image2).cpu().detach().numpy()

        
    with torch.no_grad():
      
      #print(cos_sim_2d(text_features, image_features))
      for txt in text_list:
        text = clip.tokenize(txt ).to(device)
        text_features = model.encode_text(text).cpu().detach().numpy()


        #text_features2 = model2.encode_text(text).cpu().detach().numpy()
        sim_= float(cos_sim_2d(text_features, image_features)[0]) 

        #sim_= float(cos_sim_2d(text_features, image_features)[0]) + float(cos_sim_2d(text_features2, image_features2)[0])
        similarities.append(sim_)
    return similarities




image_size = 384
transform = transforms.Compose([
    transforms.Resize((image_size,image_size),interpolation=InterpolationMode.BICUBIC),
    transforms.ToTensor(),
    transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
    ]) 

#model_url = 'https://storage.googleapis.com/sfr-vision-language-research/BLIP/models/model_large_caption.pth'
    
sys.stdout.write("Loading model_large_caption.pth ...\n")
sys.stdout.flush()

model = blip_decoder(pretrained='model_large_caption.pth', image_size=384, vit='large')
model.eval()
model = model.to(device)


#files= glob.glob("/content/image-photo/*.jpg")
#for f in files[:40]:

sys.stdout.write("Loading image ...\n")
sys.stdout.flush()

f=args2.image
    
raw_image = Image.open(f).convert('RGB')   
w,h = raw_image.size

#display(raw_image.resize((200,int(200* h/w))))
image = transform(raw_image).unsqueeze(0).to(device)     

sys.stdout.write("Captioning image 1/4 ...\n")
sys.stdout.flush()

captions = []

for topP in [0.1,  0.2, 0.3, 0.4, 0.5,0.6, 0.7]:
  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=True, max_length=30, min_length=10,top_p=topP,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)

sys.stdout.write("Captioning image 2/4 ...\n")
sys.stdout.flush()

for beam_n in [1,2,3,4,5,6,7,8]:
  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=False, num_beams=beam_n, max_length=30, min_length=10,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)

sys.stdout.write("Captioning image 3/4 ...\n")
sys.stdout.flush()

for topP in [0.1,  0.2, 0.3, 0.4, 0.5,0.6, 0.7]:
  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=True, max_length=45, min_length=30,top_p=topP,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)

sys.stdout.write("Captioning image 4/4 ...\n")
sys.stdout.flush()

for beam_n in [1,2,3,4,5,6,7,8]:
  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=False, num_beams=beam_n, max_length=45, min_length=30,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)


sys.stdout.write("Determining best caption ...\n")
sys.stdout.flush()

"""
for topP in [0.1,  0.2, 0.3, 0.4, 0.5,0.6, 0.7,0.8]:
  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=True, max_length=60, min_length=45,top_p=topP,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)

for beam_n in [1,2,3,4,5,6]:

  #[0.05,0.1, 0.15, 0.2,0.25, 0.3,0.35, 0.4, 0.45, 0.5,0.55, 0.6,0.65, 0.7,0.75, 0.8,0.85, 0.9, 0.95]

  with torch.no_grad():

      caption = model.generate(image, sample=False, num_beams=beam_n, max_length=60, min_length=45,repetition_penalty=rep_pen)
      #def generate(self, image, sample=False, num_beams=3, max_length=30, min_length=10, top_p=0.9, repetition_penalty=1.0)
      captions.append(caption)
"""
best_cannidates=[]
sims= clip_rank(raw_image,captions)
argmax_ = np.argmax(np.asarray(sims))
#print("Caption with highest sim")
#print (captions[argmax_][0])
best_cannidates.append(captions[argmax_][0])
#print(sims[argmax_])
del sims[argmax_]
del captions[argmax_]
argmax_ = np.argmax(np.asarray(sims))
#print("Caption with 2nd highest sim")
#print (captions[argmax_][0])
best_cannidates.append(captions[argmax_][0])
#print(sims[argmax_])
del sims[argmax_]
del captions[argmax_]
argmax_ = np.argmax(np.asarray(sims))
#print("Caption with 3nd highest sim")
#print (captions[argmax_][0])
best_cannidates.append(captions[argmax_][0])
del sims[argmax_]
del captions[argmax_]
argmax_ = np.argmax(np.asarray(sims))
#print("Caption with 3nd highest sim")
#print (captions[argmax_][0])
best_cannidates.append(captions[argmax_][0])
#print(sims[argmax_])

sims= clip_rank(raw_image,best_cannidates,clip_model="RN50x64")

argmax_ = np.argmax(np.asarray(sims))
print("Best caption after ranking with CLIP ViT-L/14 and RESNET50x64 is")
print (best_cannidates[argmax_])
