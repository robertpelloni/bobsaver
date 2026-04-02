# Aleph2Image (Delta)
# https://colab.research.google.com/drive/1oA1fZP7N1uPBxwbGIvOEXbTsq2ORa9vb

import argparse
import numpy as np
import torch
import torchvision
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import sys
import PIL
import matplotlib.pyplot as plt
import os
import random
import imageio
from IPython import display
from IPython.core.interactiveshell import InteractiveShell
import glob
from CLIP import clip
import io
import requests
import PIL
from dall_e import map_pixels, unmap_pixels, load_model

#InteractiveShell.ast_node_interactivity = "all"

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--size', type=int, help='Image width and height.', default=512)
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--learning_rate_multiplier', type=float, help='Learning rate multiplier.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

args = argparse.Namespace(
    text_input=args2.prompt,
    size=args2.size,
    display_freq=args2.update,
    iterations=args2.iterations,
    cutn=args2.cutn,
    learning_rate_multiplier=args2.learning_rate_multiplier,
    clip_model=args2.clip_model
)

text_input=args.text_input;

# Load the model
sys.stdout.write("Loading "+args.clip_model+" ...")
sys.stdout.flush()
perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor = perceptor.eval()



"""# Params"""

# probably don't mess with this unless you're changing generator size
im_shape = [args.size, args.size, 3]
sideX, sideY, channels = im_shape
batch_size = 1 # originally 1

"""# Define"""

def displ(img, pre_scaled=True):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  #if not pre_scaled:
  #  img = scale(img, 48*4, 32*4)
  
  imageio.imwrite(args2.image_file, np.array(img))
  
  if args2.frame_dir is not None:
      import os
      file_list = []
      for file in os.listdir(args2.frame_dir):
          if file.startswith("FRA"):
              if file.endswith("png"):
                  if len(file) == 12:
                      file_list.append(file)
      if file_list:
          last_name = file_list[-1]
          count_value = int(last_name[3:8])+1
          count_string = f"{count_value:05d}"
      else:
          count_string = "00001"
      save_name = args2.frame_dir+"\FRA"+count_string+".png"
      imageio.imwrite(save_name, np.array(img))
  
  return #display.Image('progress.png')

"""# Generator"""

target_image_size = sideX

def preprocess(img):
    s = min(img.size)
    
    if s < target_image_size:
        raise ValueError(f'min dim for image {s} < {target_image_size}')
        
    r = target_image_size / s
    s = (round(r * img.size[1]), round(r * img.size[0]))
    img = TF.resize(img, s, interpolation=PIL.Image.LANCZOS)
    img = TF.center_crop(img, output_size=2 * [target_image_size])
    img = torch.unsqueeze(T.ToTensor()(img), 0)
    return map_pixels(img)


sys.stdout.write("\nLoading DALL-E decoder ...")
sys.stdout.flush()
model = load_model("decoder.pkl", 'cuda')
sys.stdout.write("\nLoading DALL-E encoder ...")
sys.stdout.flush()
encoder = load_model("encoder.pkl", 'cuda')

sys.stdout.write("\nGetting ready...\n")
sys.stdout.flush()

oi = encoder(map_pixels(.2*torch.nn.functional.interpolate(torch.rand(1, 3, sideX//4, sideY//4), (sideX, sideY))).cuda())

"""# Latent coordinates"""

class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()

        hots = torch.nn.functional.one_hot((torch.arange(0, 8192).to(torch.int64)), num_classes=8192)
        rng = torch.zeros(batch_size, 64*64, 8192).uniform_()**torch.zeros(batch_size, 64*64, 8192).uniform_(.1,1)
        for b in range(batch_size):
          for i in range(64**2):
            rng[b,i] = hots[[np.random.randint(8191)]]
        rng = rng.permute(0, 2, 1)
        self.normu = torch.nn.Parameter(rng.cuda().view(batch_size, 8192, 64, 64))

    def forward(self):
      normu = torch.softmax(hadies*self.normu.reshape(batch_size, 8192//2, -1), dim=1).view(batch_size, 8192, 64, 64)
      return normu

lats = Pars().cuda()
mapper = [lats.normu]
#optimizer = torch.optim.Adam([{'params': mapper, 'lr': 0.05}]) # originally 0.05
# Adam can also be AdamW, Adamax, ASGD, RMSprop (sharper?), Rprop (white out), 
optimizer = torch.optim.Adam([{'params': mapper, 'lr': 0.05}]) # originally 0.05

tx = clip.tokenize(text_input)
t = perceptor.encode_text(tx.cuda()).detach().clone()

nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

will_it = False
hadies = 1.

"""
with torch.no_grad():
  al = unmap_pixels(torch.sigmoid(model(lats()).cpu().float())).numpy()
  for allls in al:
    displ(allls[:3])
"""

"""# Train"""

def checkin(loss):
  global hadies

  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()
  
  with torch.no_grad():
    
    al = unmap_pixels(torch.sigmoid(model(lats())[:, :3]).cpu().float()).numpy()
    for allls in al:
      displ(allls)
      break
  
  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()

def ascend_txt():
  out = unmap_pixels(torch.sigmoid(model(lats())[:, :3].float()))
  cutn = args.cutn # improves quality - original 64
  p_s = []
  for ch in range(cutn):
    size = int(sideX*torch.zeros(1,).uniform_(.8, 0.99)) # originally 0.99
    offsetx = torch.randint(0, sideX - size, ())
    offsety = torch.randint(0, sideX - size, ())
    apper = out[:, :, offsetx:offsetx + size, offsety:offsety + size]
    #apper = torch.nn.functional.interpolate(apper, (224,224), mode='bilinear')
    apper = torch.nn.functional.interpolate(apper, (224,224), mode='nearest') # nearest gives sharper less blurry results
    p_s.append(apper)
  into = torch.cat(p_s, 0)
  into = into + .2 * random.random() * torch.randn_like(into)
  #into = into + .1 * random.random() * torch.randn_like(into)
  into = nom((into))
  iii = perceptor.encode_image(into)
  lat_l = 0
  return [lat_l, 10*-torch.cosine_similarity(t, iii).view(-1, batch_size).T.mean(1)]

def train(i):
  loss1 = ascend_txt()
  loss = loss1[0] + loss1[1]
  loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  
  for g in optimizer.param_groups:
    g['lr'] = g['lr']*args.learning_rate_multiplier # originally 1.005 - 1.001 or even 1.0001 smooths out the results
 
  sys.stdout.write("Iteration {} loss {}".format(itt,loss)+"\n")
  sys.stdout.flush()
  if itt % args.display_freq == 0:
    checkin(loss1)


sys.stdout.write("Starting...\n")
sys.stdout.flush()
itt = 1
for asatreat in range(args.iterations):
  train(itt)
  itt+=1
