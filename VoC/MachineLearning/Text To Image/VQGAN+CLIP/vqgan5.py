# Text2Image_VQGAN.ipynb
# Original file is located at https://colab.research.google.com/github/eps696/aphantasia/blob/master/CLIP_VQGAN.ipynb

resume = False #@param {type:"boolean"}

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./taming-transformers')

import os
import io
import time
from math import exp
import random
import imageio
import numpy as np
import PIL
from collections import OrderedDict
from base64 import b64encode

import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision
from torch.autograd import Variable

#from IPython.display import HTML, Image, display, clear_output
#from IPython.core.interactiveshell import InteractiveShell
#InteractiveShell.ast_node_interactivity = "all"
#import ipywidgets as ipy

#import warnings
#warnings.filterwarnings("ignore")

from CLIP.clip import clip
from sentence_transformers import SentenceTransformer
import kornia
import lpips

import argparse


sys.stdout.write("\nParsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--image', type=str, help='Input image to seed with.', default=None)
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to use.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to use.')
  parser.add_argument('--lrate', type=float, help='Learning rate.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
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

VQGAN_model = args.vqgan_model

"""Type some `text` and/or upload some image to start.  
Describe `style`, which you'd like to apply to the imagery.  
Put to `subtract` the topics, which you would like to avoid in the result.  
`invert` the whole criteria, if you want to see "the totally opposite".

Options for non-English languages (use only one of them!):  
`multilang` = use multi-language model, trained with ViT  
`translate` = use Google translate (works with any visual model)
"""

text = args.prompt
style = ""
subtract = ""
multilang = False
translate = False
invert = False
upload_image = False

"""### Settings

Select CLIP visual `model` (results do vary!). I prefer ViT for consistency (and it's the only native multi-language option).  
`align` option is about composition. `uniform` looks most adequate, `overscan` can make semi-seamless tileable texture.  
`aug_transform` applies some augmentations, inhibiting image fragmentation & "graffiti" printing (slower, yet recommended).  
`sync` value adds LPIPS loss between the output and input image (if there's one), allowing to "redraw" it with controlled similarity.  
Decrease `samples` or resolution if you face OOM.  

Generation video and final parameters snapshot are saved automatically.  
NB: Requests are cumulative (start near the end of the previous run). To start generation from scratch, re-run General setup.
"""

#@title Generate

#!rm -rf $tempdir
#os.makedirs(tempdir, exist_ok=True)

sideX = args.sizex
sideY =  args.sizey
model = args.clip_model #'ViT-B/32' #@param ['ViT-B/32', 'RN101', 'RN50x4', 'RN50']
align = 'uniform' #@param ['central', 'uniform', 'overscan']
aug_transform = True #@param {type:"boolean"}
sync =  0.4 #@param {type:"number"}
#@markdown > Training
steps = args.iterations #@param {type:"integer"}
samples = args.cutn #@param {type:"integer"}
learning_rate = args.lrate #@param {type:"number"}
save_freq = args.update #@param {type:"integer"}





def slice_imgs(imgs, count, size=224, transform=None, align='uniform', micro=1.):
    def map(x, a, b):
        return x * (b-a) + a

    rnd_size = torch.rand(count)
    if align == 'central': # normal around center
        rnd_offx = torch.clip(torch.randn(count) * 0.2 + 0.5, 0., 1.)
        rnd_offy = torch.clip(torch.randn(count) * 0.2 + 0.5, 0., 1.)
    else: # uniform
        rnd_offx = torch.rand(count)
        rnd_offy = torch.rand(count)
    
    sz = [img.shape[2:] for img in imgs]
    sz_max = [torch.min(torch.tensor(s)) for s in sz]
    if align == 'overscan': # add space
        sz = [[2*s[0], 2*s[1]] for s in list(sz)]
        imgs = [pad_up_to(imgs[i], sz[i], type='centr') for i in range(len(imgs))]

    sliced = []
    for i, img in enumerate(imgs):
        cuts = []
        sz_max_i = sz_max[i]
        sz_min_i = size if torch.rand(1) < micro else 0.8*sz_max[i]
        for c in range(count):
            csize = map(rnd_size[c], sz_min_i, sz_max_i).int()
            offsetx = map(rnd_offx[c], 0, sz[i][1] - csize).int()
            offsety = map(rnd_offy[c], 0, sz[i][0] - csize).int()
            cut = img[:, :, offsety:offsety + csize, offsetx:offsetx + csize]
            cut = F.interpolate(cut, (size,size), mode='bicubic', align_corners=False) # bilinear
            if transform is not None: 
                cut = transform(cut)
            cuts.append(cut)
        sliced.append(torch.cat(cuts, 0))
    return sliced

def pad_up_to(x, size, type='centr'):
    sh = x.shape[2:][::-1]
    if list(x.shape[2:]) == list(size): return x
    padding = []
    for i, s in enumerate(size[::-1]):
        if 'side' in type.lower():
            padding = padding + [0, s-sh[i]]
        else: # centr
            p0 = (s-sh[i]) // 2
            p1 = s-sh[i] - p0
            padding = padding + [p0,p1]
    y = tile_pad(x, padding, symm = ('symm' in type.lower()))
    return y

def basename(file):
    return os.path.splitext(os.path.basename(file))[0]

def img_list(path, subdir=None):
    if subdir is True:
        files = [os.path.join(dp, f) for dp, dn, fn in os.walk(path) for f in fn]
    else:
        files = [os.path.join(path, f) for f in os.listdir(path)]
    files = [f for f in files if os.path.splitext(f.lower())[1][1:] in ['jpg', 'jpeg', 'png', 'ppm', 'tif']]
    return sorted([f for f in files if os.path.isfile(f)])

def img_read(path):
    img = imread(path)
    # 8bit to 256bit
    if (img.ndim == 2) or (img.shape[2] == 1):
        img = np.dstack((img,img,img))
    # rgba to rgb
    if img.shape[2] == 4:
        img = img[:,:,:3]
    return img
    
def plot_text(txt, size=224):
    fig = plt.figure(figsize=(1,1), dpi=size)
    fontsize = size//len(txt) if len(txt) < 15 else 8
    plt.text(0.5, 0.5, txt, fontsize=fontsize, ha='center', va='center', wrap=True)
    plt.axis('off')
    fig.tight_layout(pad=0)
    fig.canvas.draw()
    img = np.frombuffer(fig.canvas.tostring_rgb(), dtype=np.uint8)
    img = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))
    return img

import transforms
import pytorch_lightning as pl
import yaml
from omegaconf import OmegaConf
from taming.modules.diffusionmodules.model import Decoder
from taming.modules.vqvae.quantize import VectorQuantizer2 as VectorQuantizer
from taming.modules.vqvae.quantize import GumbelQuantize

class VQModel(pl.LightningModule):
  def __init__(self, ddconfig, n_embed, embed_dim, remap=None, sane_index_shape=False, **kwargs_ignore):  # tell vector quantizer to return indices as bhw
    super().__init__()
    self.decoder = Decoder(**ddconfig)
    self.quantize = VectorQuantizer(n_embed, embed_dim, beta=0.25, remap=remap, sane_index_shape=sane_index_shape)
  def decode(self, quant):
    return self.decoder(quant)

class GumbelVQ(VQModel):
  def __init__(self, ddconfig, n_embed, embed_dim, kl_weight=1e-8, remap=None, **kwargs_ignore):
    z_channels = ddconfig["z_channels"]
    super().__init__(ddconfig, n_embed, embed_dim)
    self.quantize = GumbelQuantize(z_channels, embed_dim, n_embed=n_embed, kl_weight=kl_weight, temp_init=1.0, remap=remap)


#workdir = '_out'
#tempdir = os.path.join(workdir, 'ttt')

workdir = '.'
tempdir = '.'


#clear_output()

if resume:
  resumed = files.upload()
  params_pt = list(resumed.values())[0]
  params_pt = torch.load(io.BytesIO(params_pt))

sys.stdout.write("Loading VQGAN model "+VQGAN_model+" ...\n")
sys.stdout.flush()

if VQGAN_model == "gumbel_f8-8192":
  scale_res = 8
else:
  scale_res = 16

def load_config(config_path):
  config = OmegaConf.load(config_path)
  return config

def load_vqgan(config, ckpt_path=None):
  if VQGAN_model == "gumbel_f8-8192":
    model = GumbelVQ(**config.model.params)
  else:
    model = VQModel(**config.model.params)
  if ckpt_path is not None:
    sd = torch.load(ckpt_path, map_location="cpu")["state_dict"]
    missing, unexpected = model.load_state_dict(sd, strict=False)
  return model.eval()

def vqgan_image(model, z):
  x = model.decode(z)
  x = (x+1.)/2.
  return x

class latents(torch.nn.Module):
  def __init__(self, shape):
    super(latents, self).__init__()
    init_rnd = torch.zeros(shape).normal_(0.,4.)
    self.lats = torch.nn.Parameter(init_rnd.cuda())
  def forward(self):
    return self.lats

#config_vqgan = load_config("./content/models_TT/%s.yaml" % VQGAN_model)
#model_vqgan  = load_vqgan(config_vqgan, ckpt_path="./content/models_TT/%s.ckpt" % VQGAN_model).cuda()
config_vqgan = load_config("%s.yaml" % VQGAN_model)
model_vqgan  = load_vqgan(config_vqgan, ckpt_path="%s.ckpt" % VQGAN_model).cuda()

if resume:
  if not isinstance(params_pt, dict):
    params_pt = OrderedDict({'lats': params_pt})
  ps = params_pt['lats'].shape
  size = [s*scale_res for s in ps[2:]]
  lats = latents(ps).cuda()
  _ = lats.load_state_dict(params_pt)
  print(' resumed with size', size)
else:
  lats = latents([1, 256, sideY//scale_res, sideX//scale_res]).cuda()

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()


if multilang: model = 'ViT-B/32' # sbert model is trained with ViT

if len(subtract) > 0:
  samples = int(samples * 0.75)
if sync > 0 and upload_image:
  samples = int(samples * 0.5)
print(' using %d samples' % samples)

use_jit = True if float(torch.__version__[:3]) < 1.8 else False
model_clip, _ = clip.load(model, jit=use_jit)
modsize = 288 if model == 'RN50x4' else 224
xmem = {'RN50':0.5, 'RN50x4':0.16, 'RN101':0.33}
if 'RN' in model:
  samples = int(samples * xmem[model])

if multilang:
  model_lang = SentenceTransformer('clip-ViT-B-32-multilingual-v1').cuda()

def enc_text(txt):
  if multilang:
    emb = model_lang.encode([txt], convert_to_tensor=True, show_progress_bar=False)
  else:
    emb = model_clip.encode_text(clip.tokenize(txt).cuda())
  return emb.detach().clone()
        
sign = 1. if invert else -1.
if aug_transform:
  trform_f = transforms.transforms_custom  
  samples = int(samples * 0.95)
else:
  trform_f = transforms.normalize()

if upload_image:
  in_img = list(uploaded.values())[0]
  print(' image:', list(uploaded)[0])
  img_in = torch.from_numpy(imageio.imread(in_img).astype(np.float32)/255.).unsqueeze(0).permute(0,3,1,2).cuda()[:,:3,:,:]
  in_sliced = slice_imgs([img_in], samples, modsize, transforms.normalize(), align, micro=False)[0]
  img_enc = model_clip.encode_image(in_sliced).detach().clone()
  if sync > 0:
    align = 'overscan'
    sim_loss = lpips.LPIPS(net='vgg', verbose=False).cuda()
    sim_size = [sideY//4, sideX//4]
    img_in = F.interpolate(img_in, sim_size).float()
    # img_in = F.interpolate(img_in, (sideY, sideX)).float()
  else:
    del img_in
  del in_sliced; torch.cuda.empty_cache()

if len(text) > 0:
  print(' text:', text)
  if translate:
    translator = Translator()
    text = translator.translate(text, dest='en').text
    print(' translated to:', text) 
  txt_enc = enc_text(text)

if len(style) > 0:
  print(' style:', style)
  if translate:
    translator = Translator()
    style = translator.translate(style, dest='en').text
    print(' translated to:', style) 
  txt_enc2 = enc_text(style)

if len(subtract) > 0:
  print(' without:', subtract)
  if translate:
    translator = Translator()
    subtract = translator.translate(subtract, dest='en').text
    print(' translated to:', subtract) 
  txt_enc0 = enc_text(subtract)

if multilang: del model_lang

optimizer = torch.optim.Adam(lats.parameters(), learning_rate)

def save_img(img, fname=None):
  sys.stdout.flush()
  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()

  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1,2,0))  
  img = np.clip(img*255, 0, 255).astype(np.uint8)
  if fname is not None:
    #imageio.imsave(fname, np.array(img))

    imageio.imsave(args.image_file, np.array(img))

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
        imageio.imsave(save_name, np.array(img))




  sys.stdout.flush()
  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()

def checkout(num):
  with torch.no_grad():
    img = vqgan_image(model_vqgan, lats()).cpu().numpy()[0]
  #save_img(img, os.path.join(tempdir, '%04d.jpg' % num))
  save_img(img, os.path.join(tempdir, 'Progress.jpg'))
  #outpic.clear_output()
  #with outpic:
  #  display(Image('Progress.jpg'))

def train(i):
  loss = 0
  img_out = vqgan_image(model_vqgan, lats())
  img_sliced = slice_imgs([img_out], samples, modsize, trform_f, align)[0]
  out_enc = model_clip.encode_image(img_sliced)

  if len(text) > 0: # input text
    loss += sign * torch.cosine_similarity(txt_enc, out_enc, dim=-1).mean()
  if len(style) > 0: # input text - style
    loss += sign * 0.5 * torch.cosine_similarity(txt_enc2, out_enc, dim=-1).mean()
  if len(subtract) > 0: # subtract text
    loss += -sign * 0.5 * torch.cosine_similarity(txt_enc0, out_enc, dim=-1).mean()
  if upload_image:
      loss += sign * 0.5 * torch.cosine_similarity(img_enc, out_enc, dim=-1).mean()
  if sync > 0 and upload_image: # image composition sync
    prog_sync = (steps - i) / steps 
    loss += prog_sync * sync * sim_loss(F.interpolate(img_out, sim_size).float(), img_in, normalize=True).squeeze()
  del img_out, img_sliced, out_enc; torch.cuda.empty_cache()

  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  
  sys.stdout.write("Iteration {}".format(i)+"\n")
  sys.stdout.flush()

  if i % save_freq == 0:
    checkout(i // save_freq)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt = 1
for i in range(steps):
    train(itt)
    itt+=1

