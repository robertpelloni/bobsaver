# improving (?) of Aleph2Image (delta): CLIP+DALL-E decoder.ipynb
# original colab https://colab.research.google.com/drive/1NGM9L8qP0gwl5z5GAuB_bd0wTNsxqclG

import torch
import numpy as np
import torch
import torchvision
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import sys
import kornia
import PIL
import matplotlib.pyplot as plt
import os
import random
import imageio
from IPython import display
from IPython.core.interactiveshell import InteractiveShell
import glob
import io
import requests
import argparse
from CLIP import clip
from dall_e import map_pixels, unmap_pixels, load_model

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--size', type=int, help='Image width and height.', default=512)
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--interpolation', type=str, help='Interpolation method.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts.')
  parser.add_argument('--resize_factor', type=float, help='Resize factor.')
  parser.add_argument('--rotation_angle', type=float, help='Rotation angle.')
  parser.add_argument('--inject_randomness', type=bool, help='Inject randomness.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
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
    resize_factor=args2.resize_factor,
    rotation_angle=args2.rotation_angle,
    inject_randomness=args2.inject_randomness,
    learning_rate_multiplier=args2.learning_rate_multiplier,
    learning_rate=args2.learning_rate,
    interpolation=args2.interpolation,
    clip_model=args2.clip_model,
    image_file=args2.image_file,
    frame_dir=args2.frame_dir,
)

text_input=args.text_input;

im_shape = [args.size, args.size, 3]
sideX, sideY, channels = im_shape
batch_size = 1
target_image_size = sideX

# Load the CLIP model
sys.stdout.write("Loading "+args.clip_model+" ...\n")
sys.stdout.flush()
perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor = perceptor.eval()

def displ(img, pre_scaled=True):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  
  imageio.imwrite(args.image_file, np.array(img))
  
  if args.frame_dir is not None:
      import os
      file_list = []
      for file in os.listdir(args.frame_dir):
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
      save_name = args.frame_dir+"\FRA"+count_string+".png"
      imageio.imwrite(save_name, np.array(img))
  
  return display.Image('progress.png')

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

sys.stdout.write("Loading decoder.pkl ...\n")
sys.stdout.flush()
model = load_model("decoder.pkl", 'cuda')

"""# Latent coordinate"""

class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()
        hots = torch.nn.functional.one_hot((torch.arange(0, 8192).to(torch.int64)), num_classes=8192)
        rng = torch.zeros(batch_size, 64*64, 8192).uniform_()
        for b in range(batch_size):
          for i in range(64*64):
            rng[b,i] = hots[[np.random.randint(8191)]]
        rng = rng.permute(0, 2, 1)
        self.normu = torch.nn.Parameter(rng.cuda().view(batch_size, 8192, 64 * 64))

    def forward(self):
      #                                                                                                    tau=2. originally - no idea why?!  changing it 
      normu = torch.nn.functional.gumbel_softmax(self.normu.reshape(batch_size, int(8192/(2)), -1), dim=1, tau=2.).flatten()[:8192* 64* 64].view(batch_size, 8192, 64, 64)
      return normu

sys.stdout.write("Getting ready ...\n")
sys.stdout.flush()

lats = Pars().cuda()
mapper = [lats.normu]
optimizer = torch.optim.Adam([{'params': mapper, 'lr': args.learning_rate}]) # was .01

tx = clip.tokenize(text_input)
t = perceptor.encode_text(tx.cuda()).detach().clone()

nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
# augs = torch.nn.Sequential(kornia.augmentation.ColorJitter(.1,.1,.1,.1, p=.5)).cuda()
augs = kornia.augmentation.RandomRotation(args.rotation_angle).cuda() # originally 30 degrees
# augs = kornia.augmentation.RandomAffine(degrees=args.rotation_angle, scale=[1.01,1.01]).cuda() # originally 30 degrees

"""
with torch.no_grad():
  al = unmap_pixels(torch.sigmoid(model(lats()).cpu().float())).numpy()
  for allls in al:
    displ(allls[:3])
"""

"""# Train"""

def augment(out, cutn=args.cutn): # originally 16
  p_s = []
  for ch in range(cutn):
    '''
    #original size code from Delta v2 version
    sizey = int(torch.zeros(1,).uniform_(0.5, args.resize_factor)*sideY) # originally .99
    sizex = int(torch.zeros(1,).uniform_(0.5, args.resize_factor)*sideX) # originally .99
    offsetx = torch.randint(0, sideX - sizex, ())
    offsety = torch.randint(0, sideY - sizey, ())
    apper = out[:, :, offsetx:offsetx + sizex, offsety:offsety + sizey]
    '''
    #next 4 lines from Aleph2Image Gamma version - doesn't seem to make much/any difference
    size = int(sideX*torch.zeros(1,).normal_(mean=.8, std=.3).clip(.5, args.resize_factor))
    offsetx = torch.randint(0, sideX - size, ())
    offsety = torch.randint(0, sideX - size, ())
    apper = out[:, :, offsetx:offsetx + size, offsety:offsety + size]
    
    # apper = TF.adjust_hue(apper, np.random.uniform(-.1, .1))
    # apper = TF.rotate(apper, np.random.uniform(-30, 30))
    # apper = TF.rotate(apper, np.random.uniform(-180, 180))
    
    #inject randomness was enabled in original script, but images seem to be sharper with it disabled
    if args.inject_randomness == True:
      apper = apper + .1*torch.rand(1,1,1,1).cuda()*torch.randn_like(apper, requires_grad=True) # originally .1*
    
    apper = torch.nn.functional.interpolate(apper, (224,224), mode=args.interpolation) # originally bilinear

    p_s.append(apper)
  into = augs(torch.cat(p_s, 0))
  return into

def checkin(loss):
  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()

  with torch.no_grad():
    alnot = unmap_pixels(torch.sigmoid(model(lats())[:, :3]).float())
    for allls in alnot.cpu():
      displ(allls)
      break

  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()

def ascend_txt():
  out = unmap_pixels(torch.sigmoid(model(lats())[:, :3].float()))
  into = augment(out)
  into = nom((into))
  iii = perceptor.encode_image(into)
  lat_l = 0
  return [lat_l, 10*-torch.cosine_similarity(t, iii).view(-1, batch_size).T.mean(1)] # originally 10*

def train(i):
  loss1 = ascend_txt()
  loss = loss1[0] + loss1[1]
  loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  # increase optimizer learning rate as iterations continue - if set to 1.0 then the learning rate remains constant
  for g in optimizer.param_groups:
    g['lr'] = g['lr']*args.learning_rate_multiplier
    #but not greater than 0.12
    g['lr'] = min(g['lr'], .12) # originally .12
  sys.stdout.write("Iteration {} loss {}".format(itt,loss)+"\n")
  sys.stdout.flush()
  if itt % args.display_freq == 0:
    for g in optimizer.param_groups:
      checkin(loss1)

sys.stdout.write("Starting...\n")
sys.stdout.flush()
itt = 1
for asatreat in range(args.iterations):
  train(itt)
  itt+=1
