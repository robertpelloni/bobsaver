# Text2OneLine
# Original file is located at https://colab.research.google.com/drive/14lDz-t_th82QghkPf3c0eUkVYjtAebpm

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./diffvg')
sys.path.append('./diffvg/pydiffvg')

import subprocess
import os
import io
import PIL.Image, PIL.ImageDraw
import base64
import zipfile
import json
import requests
import numpy as np
import matplotlib.pylab as pl
import glob
import numpy as np
import torch
from CLIP import clip
import torch
import torch.nn.functional as F
import torchvision
from torchvision import transforms
from torchvision.datasets import CIFAR100
import argparse
import pydiffvg
import torch
import skimage
import skimage.io
import random
import ttools.modules
import argparse
import math
import torchvision
import torchvision.transforms as transforms




sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--numpaths', type=int, help='Lines count.')
  parser.add_argument('--maxwidth', type=int, help='Maximum line width.')
  parser.add_argument('--normalclip', type=int, help='Normalize CLIP.')
  parser.add_argument('--pointslr', type=float, help='Points learning rate.')
  parser.add_argument('--widthlr', type=float, help='Width learning rate.')
  parser.add_argument('--colorlr', type=float, help='Color learning rate.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args2 = parser.parse_args()
  return args2

args2=parse_args();

if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 













def imread(url, max_size=None, mode=None):
  if url.startswith(('http:', 'https:')):
    r = requests.get(url)
    f = io.BytesIO(r.content)
  else:
    f = url
  img = PIL.Image.open(f)
  if max_size is not None:
    img = img.resize((max_size, max_size))
  if mode is not None:
    img = img.convert(mode)
  img = np.float32(img)/255.0
  return img

def np2pil(a):
  if a.dtype in [np.float32, np.float64]:
    a = np.uint8(np.clip(a, 0, 1)*255)
  return PIL.Image.fromarray(a)

def imwrite(f, a, fmt=None):
  a = np.asarray(a)
  if isinstance(f, str):
    fmt = f.rsplit('.', 1)[-1].lower()
    if fmt == 'jpg':
      fmt = 'jpeg'
    f = open(f, 'wb')
  np2pil(a).save(f, fmt, quality=95)

def imencode(a, fmt='jpeg'):
  a = np.asarray(a)
  if len(a.shape) == 3 and a.shape[-1] == 4:
    fmt = 'png'
  f = io.BytesIO()
  imwrite(f, a, fmt)
  return f.getvalue()

def im2url(a, fmt='jpeg'):
  encoded = imencode(a, fmt)
  base64_byte_string = base64.b64encode(encoded).decode('ascii')
  return 'data:image/' + fmt.upper() + ';base64,' + base64_byte_string


def tile2d(a, w=None):
  a = np.asarray(a)
  if w is None:
    w = int(np.ceil(np.sqrt(len(a))))
  th, tw = a.shape[1:3]
  pad = (w-len(a))%w
  a = np.pad(a, [(0, pad)]+[(0, 0)]*(a.ndim-1), 'constant')
  h = len(a)//w
  a = a.reshape([h, w]+list(a.shape[1:]))
  a = np.rollaxis(a, 2, 1).reshape([th*h, tw*w]+list(a.shape[4:]))
  return a

from torchvision import utils
def show_img(img):
    img = np.transpose(img, (1, 2, 0))
    img = np.clip(img, 0, 1)
    img = np.uint8(img * 254)
    # img = np.repeat(img, 4, axis=0)
    # img = np.repeat(img, 4, axis=1)
    pimg = PIL.Image.fromarray(img, mode="RGB")
    pimg.save(args2.image_file)
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
        pimg.save(save_name)

    #imshow(pimg)

def zoom(img, scale=4):
  img = np.repeat(img, scale, 0)
  img = np.repeat(img, scale, 1)
  return img



# Load the model

sys.stdout.write("Loading ViT-B/32 ...\n")
sys.stdout.flush()

device = torch.device('cuda')
model, preprocess = clip.load('ViT-B/32', device, jit=False)

dscrptn = args2.prompt

line_comlexity = "20" #"20" #@param ["8", "12", "16", "20", "24", "28", "32", "36", "40", "44", "48", "64", "96"]
width = "Normal" #@param ["Extra Thin", "Thin", "Normal", "SemiBold", "Bold", "ExtraBold"]

width_dict = {"Extra Thin": 0.5, "Thin":0.55, "Normal":0.6, "SemiBold":0.7, "Bold":.9, "ExtraBold":1.1}

points = int(line_comlexity)
num_paths = 1
radius = 0.025 #0.02 - 0.1
line_width = width_dict[width]  # from 0.5 to 2
num_augs = 1

prompt = f"Professional one line drawing art of a {dscrptn}. Professional one line sketch of {dscrptn}. minimalistic art tattoo"


n_lines = (points,) *2

neg_prompt = "A badly drawn sketch."
neg_prompt_2 = "Many ugly, messy drawings."
text_input = clip.tokenize(prompt).to(device)
text_input_neg1 = clip.tokenize(neg_prompt).to(device)
text_input_neg2 = clip.tokenize(neg_prompt_2).to(device)
use_negative = True # Use negative prompts?

# Thanks to Katherine Crowson for this. 
# In the CLIPDraw code used to generate examples, we don't normalize images
# before passing into CLIP, but really you should. Turn this to True to do that.
use_normalized_clip = True 

# Calculate features
with torch.no_grad():
    text_features = model.encode_text(text_input)
    text_features_neg1 = model.encode_text(text_input_neg1)
    text_features_neg2 = model.encode_text(text_input_neg2)

pydiffvg.set_print_timing(False)

gamma = 1.0

# ARGUMENTS. Feel free to play around with these, especially num_paths.
args = lambda: None
args.num_paths = num_paths # number of lines =1
args.num_iter = 1601 # number of steps =1000
args.max_width = line_width #0.8 #50 or 0.5

# Use GPU if available
pydiffvg.set_use_gpu(torch.cuda.is_available())
device = torch.device('cuda')
pydiffvg.set_device(device)

canvas_width, canvas_height = args2.sizex, args2.sizey #224, 224  # 224, 224
num_paths = args.num_paths
max_width = args.max_width

# Image Augmentation Transformation
augment_trans = transforms.Compose([
    # transforms.RandomAffine(degrees=(2, 10), translate=(0.02, 0.05), scale=(0.9, 0.95)),                          
    # transforms.RandomPerspective(fill=1, p=1, distortion_scale=0.5),
    transforms.RandomResizedCrop(224, scale=(0.8, 0.9)),
    # transforms.RandomHorizontalFlip(p=0.5),
])

if use_normalized_clip:
    augment_trans = transforms.Compose([
    transforms.RandomPerspective(fill=1, p=1, distortion_scale=0.5),
    transforms.RandomResizedCrop(224, scale=(0.7, 0.9)),
    transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
])


# Initialize Random Curves
shapes = []
shape_groups = []
for i in range(num_paths):
    num_segments = random.randint(n_lines[0], n_lines[1])
    num_control_points = torch.zeros(num_segments, dtype = torch.int32) + 2
    points = []
    p0 = (0.5, 0.5) #(0.5, 0.5) # (random.random(), random.random())
    points.append(p0)
    for j in range(num_segments):
        radius = radius
        p1 = (p0[0] + radius * (random.random() - 0.5), p0[1] + radius * (random.random() - 0.5))
        p2 = (p1[0] + radius * (random.random() - 0.5), p1[1] + radius * (random.random() - 0.5))
        p3 = (p2[0] + radius * (random.random() - 0.5), p2[1] + radius * (random.random() - 0.5))
        points.append(p1)
        points.append(p2)
        points.append(p3)
        p0 = p3
    points = torch.tensor(points)
    points[:, 0] *= canvas_width
    points[:, 1] *= canvas_height
    path = pydiffvg.Path(num_control_points = num_control_points, points = points, stroke_width = torch.tensor(0.2), is_closed = False) # stroke_width = torch.tensor(1.0) or torch.tensor(.05)
    shapes.append(path)
    path_group = pydiffvg.ShapeGroup(shape_ids = torch.tensor([len(shapes) - 1]), fill_color = None, stroke_color = torch.tensor([0.02, 0.02, 0.02, 1.])) # [random.random(), random.random(), random.random(), random.random() # [0.094, 0.310, 0.635, 1.]
    shape_groups.append(path_group)

# Just some diffvg setup
scene_args = pydiffvg.RenderFunction.serialize_scene(\
    canvas_width, canvas_height, shapes, shape_groups)
render = pydiffvg.RenderFunction.apply
img = render(canvas_width, canvas_height, 2, 2, 0, None, *scene_args)
points_vars = []
stroke_width_vars = []
color_vars = []
for path in shapes:
    path.points.requires_grad = True
    points_vars.append(path.points)
    path.stroke_width.requires_grad = True
    stroke_width_vars.append(path.stroke_width)
for group in shape_groups:
    group.stroke_color.requires_grad = False #True
    color_vars.append(group.stroke_color)

# Optimizers
points_optim = torch.optim.Adam(points_vars, lr=1.6)  # 1.0
width_optim = torch.optim.Adam(stroke_width_vars, lr=0.1)
color_optim = torch.optim.Adam(color_vars, lr=0.01)


sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1

# Run the main optimization loop
for t in range(args2.iterations):

    # Anneal learning rate (makes videos look cleaner)
    if t == int(args.num_iter * 0.15):
        for g in points_optim.param_groups:
            g['lr'] = 1.1
    if t == int(args.num_iter * 0.4):
        for g in points_optim.param_groups:
            g['lr'] = 0.8
    if t == int(args.num_iter * 0.8):
        for g in points_optim.param_groups:
            g['lr'] = 0.5
    if t == int(args.num_iter * 0.9):
        for g in points_optim.param_groups:
            g['lr'] = 0.3
    
    points_optim.zero_grad()
    width_optim.zero_grad()
    color_optim.zero_grad()
    scene_args = pydiffvg.RenderFunction.serialize_scene(\
        canvas_width, canvas_height, shapes, shape_groups)
    img = render(canvas_width, canvas_height, 2, 2, t, None, *scene_args)
    img = img[:, :, 3:4] * img[:, :, :3] + torch.ones(img.shape[0], img.shape[1], 3, device = pydiffvg.get_device()) * (1 - img[:, :, 3:4])
    #if t % 5 == 0:
    #    pydiffvg.imwrite(img.cpu(), '/content/res/iter_{}.png'.format(int(t/5)), gamma=gamma)
    img = img[:, :, :3]
    img = img.unsqueeze(0)
    img = img.permute(0, 3, 1, 2) # NHWC -> NCHW

    loss = 0
    NUM_AUGS = num_augs

    # img_augs = []
    # for n in range(NUM_AUGS):
    #     img_augs.append(augment_trans(img))
    # im_batch = torch.cat(img_augs)

    img_augs = [img] * NUM_AUGS
    img_augs = torch.cat(img_augs).to('cuda')
    im_batch = augment_trans(img_augs)

    image_features = model.encode_image(im_batch)
    # for n in range(NUM_AUGS):
    #     loss -= torch.cosine_similarity(text_features, image_features[n:n+1], dim=1)
    #     if use_negative:
    #         loss += torch.cosine_similarity(text_features_neg1, image_features[n:n+1], dim=1) * 0.3
    #         loss += torch.cosine_similarity(text_features_neg2, image_features[n:n+1], dim=1) * 0.3
    # if use_negative:
    #     loss += torch.cosine_similarity(text_features_neg1, image_features[n:n+1], dim=1) * 0.3
    #     loss += torch.cosine_similarity(text_features_neg2, image_features[n:n+1], dim=1) * 0.3

    loss = -torch.cosine_similarity(text_features, image_features, dim=1).sum() / num_augs
    loss += torch.cosine_similarity(text_features_neg1, image_features, dim=1).sum() * 0.2  / num_augs
    loss += torch.cosine_similarity(text_features_neg2, image_features, dim=1).sum() * 0.2  / num_augs





    # Backpropagate the gradients.
    loss.backward()

    # Take a gradient descent step.
    points_optim.step()
    width_optim.step()
    color_optim.step()
    for path in shapes:
        path.stroke_width.data.clamp_(1.0, max_width)
    for group in shape_groups:
        group.stroke_color.data.clamp_(0.0, 1.0)
    
    sys.stdout.write("Iteration {}".format(itt)+"\n")
    sys.stdout.flush()
    
    if itt % args2.update == 0 and itt>0:
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()

        show_img(img.detach().cpu().numpy()[0])
        
        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
        
    itt+=1