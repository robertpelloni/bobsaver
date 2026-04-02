# LatentReVisions
# Original file is located at https://colab.research.google.com/drive/1claTgq5y-Kt1qJd9AaCzAZf4P0OteNsy

# Feel free to send correspondence to [@advadnoun](https://twitter.com/advadnoun) on Twitter. This notebook is for non-commercial use unless specified. If you do use this for a non-commercial project, just link to my twtter profile :)

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import numpy as np
import torchvision
import torchvision.transforms.functional as TF
import kornia

import PIL
import matplotlib.pyplot as plt

import shutil
import os
import random
import imageio
from IPython import display

import glob

sys.path.append('./taming-transformers')




import yaml
import torch
from omegaconf import OmegaConf
from taming.models.vqgan import VQModel

from CLIP import clip


import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--update', type=int, help='Iterations per update.')
  parser.add_argument('--cutouts', type=int, help='Cutout count.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
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
    
    







optional_path_to_a_starter_image = ''#@param {type:"string"}

text_input = args.prompt
w0 = 3.1 #@param {type:"slider", min:-5, max:5, step:0.1}

text_to_add = "" #@param {type:"string"}
w1 = -0.1 #@param {type:"slider", min:-5, max:5, step:0.1}
img_enc_path = "" #@param {type:"string"}
w2 = 1.2 #@param {type:"slider", min:-5, max:5, step:0.1}
ne_img_enc_path = "" #@param {type:"string"}
w3 = 0.3 #@param {type:"slider", min:-5, max:5, step:0.1}

# How to weight the 2 texts (w0 and w1) and the images (w3 & w3)

im_shape = [args.sizey, args.sizex, 3]
sideX, sideY, channels = im_shape
batch_size = 1

DEVICE = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', DEVICE)
print(torch.cuda.get_device_properties(device))















#load the model
sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor.eval().requires_grad_(False);

clip.available_models()

perceptor.visual.input_resolution

scaler = 1

def displ(img, pre_scaled=True):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  if not pre_scaled:
    img = scale(img, 48*4, 32*4)
  
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
  
  
  return display.Image('Progress.png')

def gallery(array, ncols=2):
    nindex, height, width, intensity = array.shape
    nrows = nindex//ncols
    assert nindex == nrows*ncols
    # want result.shape = (height*nrows, width*ncols, intensity)
    result = (array.reshape(nrows, ncols, height, width, intensity)
              .swapaxes(1,2)
              .reshape(height*nrows, width*ncols, intensity))
    return result

def card_padded(im, to_pad=3):
  return np.pad(np.pad(np.pad(im, [[1,1], [1,1], [0,0]],constant_values=0), [[2,2], [2,2], [0,0]],constant_values=1),
            [[to_pad,to_pad], [to_pad,to_pad], [0,0]],constant_values=0)

def get_all(img):
  img = np.transpose(img, (0,2,3,1))
  cards = np.zeros((img.shape[0], sideX+12, sideY+12, 3))
  for i in range(len(img)):
    cards[i] = card_padded(img[i])
  #print(img.shape)
  cards = gallery(cards)
  imageio.imwrite(str(3) + '.png', np.array(cards))
  return display.Image(str(3)+'.png')


def load_config(config_path, display=False):
  config = OmegaConf.load(config_path)
  #if display:
  #  print(yaml.dump(OmegaConf.to_container(config)))
  return config

def load_vqgan(config, ckpt_path=None):
  model = VQModel(**config.model.params)
  if ckpt_path is not None:
    sd = torch.load(ckpt_path, map_location="cpu")["state_dict"]
    missing, unexpected = model.load_state_dict(sd, strict=False)
  return model.eval()

def preprocess_vqgan(x):
  x = 2.*x - 1.
  return x

def custom_to_pil(x):
  x = x.detach().cpu()
  x = torch.clamp(x, -1., 1.)
  x = (x + 1.)/2.
  x = x.permute(1,2,0).numpy()
  x = (255*x).astype(np.uint8)
  x = Image.fromarray(x)
  if not x.mode == "RGB":
    x = x.convert("RGB")
  return x

def reconstruct_with_vqgan(x, model):
  # could also use model(x) for reconstruction but use explicit encoding and decoding here
  z, _, [_, _, indices] = model.encode(x)
  #print(f"VQGAN: latent shape: {z.shape[2:]}")
  xrec = model.decode(z)
  return xrec
  


sys.stdout.write("Loading VQGAN model "+args.vqgan_model+" ...\n")
sys.stdout.flush()

config16384 = load_config(args.vqgan_model+".yaml", display=False)
model16384 = load_vqgan(config16384, ckpt_path=args.vqgan_model+".ckpt").to(DEVICE).eval().requires_grad_(False);




# solid_color = Image.new('RGB', (448, 448), "#dddddd").save("solid_color.jpg")
# img_root = encode_with_vqgan_full("solid_color.jpg", imagesize)


with torch.no_grad():
    if optional_path_to_a_starter_image != '':
      x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(optional_path_to_a_starter_image)).unsqueeze(0).permute(0, 3, 1, 2)[:,:3], (sideX, sideY)) / 255).cuda()
    else:
      x = torch.nn.functional.interpolate(.5*torch.rand(size=(batch_size, 3, sideX//1, sideY//1)).cuda(), (sideX, sideY), mode='bilinear')
      x = kornia.augmentation.RandomGaussianBlur((7, 7), (14, 14), p=1)(x)
    x = (x * 2 - 1)
    o_i1 = model16384.encoder(x)
    o_i2 = model16384.quant_conv(o_i1)
    # o_i3 = model16384.post_quant_conv(o_i2)

text_other = '''incoherent, confusing, cropped, watermarks'''


class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()
        self.normu = torch.nn.Parameter(o_i2.cuda().clone().view(batch_size, 256, sideX//16 * sideY//16))
        self.ignore = torch.empty(0,).long().cuda()
        self.keep = torch.empty(0,).long().cuda()
        self.keep_indices = torch.empty(0,).long().cuda()

    def forward(self):
      mask = torch.ones(self.normu.shape, requires_grad=False).cuda()
      mask[:, :, self.ignore] = 1
      normu = self.normu * mask
      normu.scatter_(2, self.ignore.unsqueeze(0).unsqueeze(0).expand(-1, 256, -1), self.keep.detach())
      return normu.clip(-6, 6).view(1, -1, sideX//16, sideY//16)
      

def model(x):
  o_i2 = x
  o_i3 = model16384.post_quant_conv(o_i2)
  i = model16384.decoder(o_i3)
  return i


dec = .1

lats = Pars().cuda()
mapper = [lats.normu]
optimizer = torch.optim.AdamW([{'params': mapper, 'lr': .5}], weight_decay=dec)
eps = 0

t = 0
if text_input != '':
  tx = clip.tokenize(text_input)
  t = perceptor.encode_text(tx.cuda()).detach().clone()

text_add = 0
if text_to_add != '':
  text_add = clip.tokenize(text_to_add)
  text_add = perceptor.encode_text(text_add.cuda()).detach().clone()

t_not = clip.tokenize(text_other)
t_not = perceptor.encode_text(t_not.cuda()).detach().clone()


nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

img_enc = 0
if img_enc_path != '':
  img_enc = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_enc_path)).unsqueeze(0).permute(0, 3, 1, 2), (224, 224)) / 255).cuda()[:,:3]
  img_enc = nom(img_enc)
  img_enc = perceptor.encode_image(img_enc.cuda()).detach().clone()

ne_img_enc = 0
if ne_img_enc_path != '':
  ne_img_enc = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(ne_img_enc_path)).unsqueeze(0).permute(0, 3, 1, 2), (224, 224)) / 255).cuda()[:,:3]
  ne_img_enc = nom(ne_img_enc)
  ne_img_enc = perceptor.encode_image(ne_img_enc.cuda()).detach().clone()



augs = torch.nn.Sequential(
    torchvision.transforms.RandomHorizontalFlip(),
    torchvision.transforms.RandomAffine(24, (.1, .1), fill=0)
).cuda()


up_noise = .11



itt = 0

"""

def augment(into, cutn=32):

  into = torch.nn.functional.pad(into, (sideX//2, sideX//2, sideX//2, sideX//2), mode='constant', value=0)


  into = augs(into)

  p_s = []
  for ch in range(cutn):
    # size = torch.randint(int(.5*sideX), int(1.9*sideX), ())
    size = int(torch.normal(1.2, .3, ()).clip(.43, 1.9) * sideX)
    
    if ch > cutn - 4:
      size = int(sideX*1.4)
    offsetx = torch.randint(0, int(sideX*2 - size), ())
    offsety = torch.randint(0, int(sideX*2 - size), ())
    apper = into[:, :, offsetx:offsetx + size, offsety:offsety + size]
    apper = torch.nn.functional.interpolate(apper, (int(224*scaler), int(224*scaler)), mode='bilinear', align_corners=True)
    p_s.append(apper)
  into = torch.cat(p_s, 0)

  into = into + up_noise*torch.rand((into.shape[0], 1, 1, 1)).cuda()*torch.randn_like(into, requires_grad=False)

  return into
"""

def augment(into, cutn=32):

  into = torch.nn.functional.pad(into, (sideX//2, sideY//2, sideX//2, sideY//2), mode='constant', value=0)

  into = augs(into)

  p_s = []
  for ch in range(cutn):
    sizeX = int(torch.normal(1.2, .3, ()).clip(.43, 1.9) * sideX)
    sizeY = int(torch.normal(1.2, .3, ()).clip(.43, 1.9) * sideY)
    
    if ch > cutn - 4:
      sizeX = int(sideX*1.4)
      sizeY = int(sideY*1.4)
    offsetx = torch.randint(0, int(sideX*2 - sizeX), ())
    offsety = torch.randint(0, int(sideY*2 - sizeY), ())
    apper = into[:, :, offsetx:offsetx + sizeX, offsety:offsety + sizeY]
    apper = torch.nn.functional.interpolate(apper, (int(224*scaler), int(224*scaler)), mode='bilinear', align_corners=True)
    p_s.append(apper)
  into = torch.cat(p_s, 0)

  into = into + up_noise*torch.rand((into.shape[0], 1, 1, 1)).cuda()*torch.randn_like(into, requires_grad=False)

  return into

def checkin():
  global up_noise

  sys.stdout.flush()
  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()

  with torch.no_grad():
    
    alnot = (model(lats()).cpu().clip(-1, 1) + 1) / 2
    
    for allls in alnot.cpu():
      displ(allls)
  
  sys.stdout.flush()
  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()

def slerp(val, low, high):
    low_norm = low/torch.norm(low, dim=1, keepdim=True)
    high_norm = high/torch.norm(high, dim=1, keepdim=True)
    omega = torch.acos((low_norm*high_norm).sum(1))
    so = torch.sin(omega)
    res = (torch.sin((1.0-val)*omega)/so).unsqueeze(1)*low + (torch.sin(val*omega)/so).unsqueeze(1) * high
    return res.detach().cuda()

def ascend_txt():
  global up_noise
  out = model(lats())


  into = augment((out.clip(-1, 1) + 1) / 2)



  into = nom(into)


  iii = perceptor.encode_image(into)

  q = w0*t + w1*text_add + w2*img_enc + w3*ne_img_enc
  q = q / q.norm(dim=-1, keepdim=True)

  all_s = torch.cosine_similarity(q, iii, -1)

  return [0, -10*all_s + 5 * torch.cosine_similarity(t_not, iii, -1)]
  
sys.stdout.write("Starting\n")
sys.stdout.flush()

def train(i):
  global dec
  global up_noise

  sys.stdout.write("Iteration {}".format(itt)+"\n")
  sys.stdout.flush()


  if itt % args.update == 0 and itt>0:
    checkin()
    
  loss1 = ascend_txt()
  loss = loss1[0] + loss1[1]
  loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  
  if lats.keep_indices.size()[0] != 0:
    if torch.abs(lats().view(batch_size, 256, -1)[:, :, lats.keep_indices]).max() > 5:
      for g in optimizer.param_groups:
        g['weight_decay'] = dec
    else:
      for g in optimizer.param_groups:
        g['weight_decay'] = 0
  

def loop():
  global itt
  for asatreat in range(args.iterations):
    train(itt)
    itt+=1

loop()
