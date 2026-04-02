# SlideShowVisions V1.ipynb
# Original file is located at https://colab.research.google.com/drive/1IihC4ZJvCh_tOgBVd900BzHX-ulPEFsa

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
import numpy as np
import torchvision
import torchvision.transforms.functional as TF
import kornia
import PIL
import matplotlib.pyplot as plt
import os
import imageio
import glob
import argparse
import sys
from os import listdir, path
import string
import shutil
import yaml
import torch
from omegaconf import OmegaConf
from CLIP.clip import clip

sys.path.append(".")
sys.path.append('./taming-transformers')
from taming.models.vqgan import VQModel


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--scaler', type=float, help='Scaler.')
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
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



#@title Start Here :) { display-mode: "form" }
text_input0 = args.prompt #"A fairy-tale forest by Kay Nielsen." #@param {type:"string"}
w0 = 1 #@param {type:"slider", min:-5, max:5, step:0.1}
text_input1 = "trending on artstation" #@param {type:"string"}
w1 = 0.5 #@param {type:"slider", min:-5, max:5, step:0.1}
img_enc_path2 = "" #@param {type:"string"}
w2 = 0 #@param {type:"slider", min:-5, max:5, step:0.1}
img_enc_path3 = "" #@param {type:"string"}
w3 = 0 #@param {type:"slider", min:-5, max:5, step:0.1}
path_to_starting_image = args.seed_image #@param {type:"string"}
path_to_auto_save = "" #@param {type:"string"}
path_to_auto_run = ""  #@param {type:"string"}

# How to weight the 2 texts (w0 and w1) and the images (w3 & w3)

im_shape = [args.sizey, args.sizex, 3] #for some reason X and Y are flipped in this script?
sideX, sideY, channels = im_shape
batch_size = 1

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', device)
print(torch.cuda.get_device_properties(device))
DEVICE = device

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor.eval()

clip.available_models()

perceptor.visual.input_resolution


scaler = args.scaler

def displ(img, pre_scaled=True):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  if not pre_scaled:
    img = scale(img, 48*4, 32*4)

  img = np.array(img)
  img = (255.0 * img).astype(np.uint8)
  imageio.imwrite(str(3) + '.png', np.array(img))
  return display.Image(str(3)+'.png')

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

config16384 = load_config(args.vqgan_model+'.yaml', display=False)
model16384 = load_vqgan(config16384, ckpt_path=args.vqgan_model+'.ckpt').to(DEVICE)


class Pars(torch.nn.Module):
    def __init__(self, o_i2, batch_size, sideX, sideY):
        super(Pars, self).__init__()
        self.sideX = sideX
        self.sideY = sideY
        # if optional_path_to_a_starter_image != '':
        self.normu = torch.nn.Parameter(o_i2.cuda().clone().view(batch_size, 256, sideX//16 * sideY//16))
        
        self.ignore = torch.empty(0,).long().cuda()

        self.keep = torch.empty(0,).long().cuda()

        self.keep_indices = torch.empty(0,).long().cuda()

    def forward(self):
      # can't remember if this is necessary lmao
      mask = torch.ones(self.normu.shape, requires_grad=False).cuda()
      if len(self.ignore) > 0:
        mask[:, :, self.ignore] = 1       
        normu = self.normu * mask
        normu.scatter_(2, self.ignore.unsqueeze(0).unsqueeze(0).expand(-1, 256, -1), self.keep.detach())
      else:
        normu = self.normu

      return normu.clip(-6, 6).view(1, -1, self.sideX//16, self.sideY//16) 

# Decode latents; [-1,1] out
def decode(x):
  # o_i1 = model16384.encoder(x)
  # o_i1 = x
  # o_i2 = model16384.quant_conv(o_i1)
  o_i2 = x
  o_i3 = model16384.post_quant_conv(o_i2)
  i = model16384.decoder(o_i3)
  return i
  
def enc_image(img_path):
  global nom
  img_path = img_path.strip()
  #print(img_path)
  imgenc = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_path)).unsqueeze(0).permute(0, 3, 1, 2), (224, 224)) / 255).cuda()[:,:3]
  imgenc = nom(imgenc)
  return perceptor.encode_image(imgenc.cuda()).detach().clone()

def current_image():
  global lats
  global nOV, wOV
  global rng
  
  if (nOV == 2 and img_enc_path2 != ''):
    #print(lats().shape) # torch.Size([1, 256, 32, 32])
    #print(img_enc.shape)# torch.Size([1, 512])
    #img = decode((img_enc * wOV + lats() * (1-wOV)).cpu().clip(-1, 1))

    x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_enc_path2)).unsqueeze(0).permute(0, 3, 1, 2)[:,:3], (sideX, sideY)) / 255).cuda()  
    x = (x * 2 - 1)
    o_i1 = model16384.encoder(x)
    o_i2 = model16384.quant_conv(o_i1)
    s2 = o_i2.squeeze(0)
    l2 = lats().squeeze(0)
    n = int(len(s2)*wOV);
    for i in range(n):
      #if rng.uniform() < wOV:
      l2[i] = s2[i]

    img = decode(l2.unsqueeze(0)).cpu().clip(-1, 1)
    #img = decode((o_i2 * wOV + lats() * (1-wOV))).cpu().clip(-1, 1)
  elif (nOV == 3 and img_enc_path3 != ''):
    #img = decode((ne_img_enc * wOV + lats() * (1-wOV)).cpu().clip(-1, 1))x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_enc_path)).unsqueeze(0).permute(0, 3, 1, 2)[:,:3], (sideX, sideY)) / 255).cuda()  
    
    x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_enc_path3)).unsqueeze(0).permute(0, 3, 1, 2)[:,:3], (sideX, sideY)) / 255).cuda()  
    x = (x * 2 - 1)
    o_i1 = model16384.encoder(x)
    o_i2 = model16384.quant_conv(o_i1)
    img = decode((o_i2 * wOV + lats() * (1-wOV))).cpu().clip(-1, 1)
  else:
    img = decode(lats()).cpu().clip(-1, 1)

  return (img[0] + 1) / 2
  
def save_image_text(folder, img, text):
  file = path.join(folder, text)
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  img = (255.0 * img).astype(np.uint8)
  imageio.imwrite(file, img)
  return file

save_singles = False
save_cmds = True
def save_cmd(imeh):
  global itt
  global img_cmd
  global path_to_auto_save
  global save_singles, save_cmds

  if path_to_auto_save != '' and save_cmds:
    if save_singles and imeh != 'SINGLES':
      imeh = 'SINGLES '+imeh

    imeh = imeh.replace('/','^')
    file = path.join(path_to_auto_save, str(itt)+'+CMD+'+imeh + '''.png''')
    imageio.imwrite(file, cmd_image)
    
# Interpolate between low and high
def slerp(val, low, high):
    low_norm = low/torch.norm(low, dim=1, keepdim=True)
    high_norm = high/torch.norm(high, dim=1, keepdim=True)
    omega = torch.acos((low_norm*high_norm).sum(1))
    so = torch.sin(omega)
    res = (torch.sin((1.0-val)*omega)/so).unsqueeze(1)*low + (torch.sin(val*omega)/so).unsqueeze(1) * high
    return res.detach().cuda()

def init_text_images():
  global t, text_input0
  global text_add, text_input1
  global t_not
  global img_enc, img_enc_path2
  global ne_img_enc, img_enc_path3
  t = 0
  if text_input0 != '':
    tx = clip.tokenize(text_input0)
    t = perceptor.encode_text(tx.cuda()).detach().clone()

  text_add = 0
  if text_input1 != '':
    text_add = clip.tokenize(text_input1)
    text_add = perceptor.encode_text(text_add.cuda()).detach().clone()

  # for creating t_not
  text_other = '''incoherent, confusing, cropped, watermarks'''
  t_not = clip.tokenize(text_other)
  t_not = perceptor.encode_text(t_not.cuda()).detach().clone()

  img_enc = 0
  if img_enc_path2 != '':
    img_enc = enc_image(img_enc_path2.replace('/content/', ''))

  ne_img_enc = 0
  if img_enc_path3 != '':
    ne_img_enc = enc_image(img_enc_path3.replace('/content/', ''))


local_LOAD_CURRENT = False  # Also considers any image at t=0 to be a LOAD CURRENT if False
copy_rng_seed = True        # Not sure that this has any effect
auto_run_noise_0 = False    # Forces up_noise = 0 during auto_run portion, then reverts to defined value. Acune effect.

path_to_POP_image = ''

cmd_image_path = ''

itt = 0 

dec = .1  # .1=default, .2=color change & blockish, .9=rediculous
lr = args.learning_rate #.5   # .1=slow adapt, .5=default, .7=faster adapt & face removal & complex pattern removal; change values slowly
up_noise = .11

rng = np.random.default_rng()
rng_seed = rng.integers(-0x8000_0000_0000, 0xffff_ffff_ffff)

img_dict = {}
cmd_cursor = 0
cmds = []
cmd_times = []

#load_auto_run_if()

nOV = 0
wOV = 0
prev_wOV = wOV
prev_text_input = ''
prev_w0 = w0
prev_w1 = w1
prev_w2 = w2
prev_w3 = w3
prev_up_noise = up_noise
prev_dec = dec
prev_lr = lr
itt_new = 0
nItt_update_max = 50
do_pop = False
   

#save_init_cmds_if()

# Begining torch commands

torch.cuda.empty_cache()

nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

#torch.manual_seed(rng_seed)
augs = torch.nn.Sequential(
    torchvision.transforms.RandomHorizontalFlip(),
    torchvision.transforms.RandomAffine(24, (.1, .1), fill=0)).cuda() 

with torch.no_grad():
    if path_to_starting_image != None:
      #1 (512, 512, 3)
      #2 torch.Size([1, 3, 512, 512])
      #3 torch.Size([1, 3, 512, 512])
      #enc_image()
      #4 torch.Size([1, 512])
      #model16384.encoder:
      #5 torch.Size([1, 256, 32, 32])
      #lats().shape
      #6 torch.Size([1, 256, 32, 32])

      x = imageio.imread(path_to_starting_image)
      #print('1', x.shape)
      #In Pytorch, the input channel should be in the second dimension.
      x = torch.tensor(x).unsqueeze(0).permute(0, 3, 1, 2)[:,:3]
      #print('2', x.shape)
      x = (torch.nn.functional.interpolate(x, (sideX, sideY)) / 255).cuda()
      #print('3', x.shape)
      x = (x * 2 - 1)
      x = torch.clip(x, -1., 1.)
      print('original')
      #displ(x.squeeze(0).cpu())
      #x = nom(x)
      #y = perceptor.encode_image(x.cuda()).detach().clone()
      #y = enc_image(path_to_starting_image)
      #print('4', y.shape)
      o_i1 = model16384.encoder(x)
      o_i2 = model16384.quant_conv(o_i1)
      img = decode(o_i2).cpu().clip(-1, 1)
      print('decode(encode)')
      #displ(img.squeeze(0).cpu())
      #print('5', o_i2.shape)
    else:
      # Perlin Noise https://gist.github.com/adefossez/0646dbe9ed4005480a2407c62aac8869
      
      x = torch.nn.functional.interpolate(.5*torch.rand(size=(batch_size, 3, sideX//1, sideY//1)).cuda(), (sideX, sideY), mode='bilinear')
      x = kornia.augmentation.RandomGaussianBlur((7, 7), (14, 14), p=1)(x)

      x = (x * 2 - 1)
      o_i1 = model16384.encoder(x)
      o_i2 = model16384.quant_conv(o_i1)
      # o_i3 = model16384.post_quant_conv(o_i2)#
      
lats = Pars(o_i2, batch_size, sideX, sideY).cuda()
#print('6', lats().shape)
mapper = [lats.normu]
optimizer = torch.optim.AdamW([{'params': mapper, 'lr': lr}], weight_decay=dec)

init_text_images() 

# helps bump it out of local minima 
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
    apper = torch.nn.functional.interpolate(apper, (int(224*scaler), int(224*scaler)), mode='bilinear')#, align_corners=True)
    p_s.append(apper)

  into = torch.cat(p_s, 0)
  into = into + up_noise*torch.rand((into.shape[0], 1, 1, 1)).cuda()*torch.randn_like(into, requires_grad=False)

  return into

img_dist_sum = 0
img_dist_count = 1;

def checkin():
  global do_pop
  global text_input0
  global itt
  global cmd_cursor
  global cmd_times, cmds
  global path_to_auto_run
  global pro_saving, last_img, img_dist_count, img_dist_sum

  with torch.no_grad():
    
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    img = current_image()
    save_image_text('.',img,args.image_file)
    
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
        save_image_text('.',img,save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

def ascend_txt():
  global do_pop
  global path_to_POP_image
  global itt_new
  global itt
  global lats
  global lr

  if (do_pop):
    print('''SMASH IT!''', itt, itt_new)
    #x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(path_to_POP_image)).unsqueeze(0).permute(0, 3, 1, 2)[:,:3], (sideX, sideY)) / 255).cuda()  
    #x = (x * 2 - 1)
    #o_i1 = model16384.encoder(x)
    #o_i2 = model16384.quant_conv(o_i1)
    #o_i2 = (o_i2 * .5 + lats() * .5)
    
    #lats.normu = torch.nn.Parameter(o_i2.cuda().clone().view(batch_size, 256, sideX//16 * sideY//16))
    #lats = Pars().cuda()
    #mapper = [lats.normu]
    #optimizer = torch.optim.AdamW([{'params': mapper, 'lr': .5}], weight_decay=dec)
    #out = decode(o_i2)

    lats.normu.data = lats.normu.scatter(2, lats.ignore.unsqueeze(0).unsqueeze(0).expand(-1, 256, -1), lats.keep.detach())

    ed = []
    zs = []
    if path_to_POP_image != '':
      x = torch.nn.functional.interpolate(torch.tensor(imageio.imread(path_to_POP_image)).unsqueeze(0).permute(0, 3, 1, 2), (sideX//16, sideY//16), mode='nearest')/255
      x = (x * 2 - 1)
      x = kornia.augmentation.RandomGaussianBlur((7, 7), (14, 14), p=1)(x)
      #print('x',x.shape)                          # torch.Size([1, 3, 32, 32])
      drawn = x[:,2:3,:,:] 
      #print('drawn.shape',drawn.shape)            # torch.Size([1, 1, 32, 32])
      #print('lats().shape',lats().shape)          # torch.Size([1, 256, 32, 32])
      #print('lats.normu.shape',lats.normu.shape)  # torch.Size([1, 256, 1024])

      for inx, kj in enumerate(drawn.view(-1, 1)):
        if kj.sum() > 0:
          zs.append(inx)  # Ignore
        else:
          ed.append(inx)  # Keep
    else:
      block_size = 2
      for i in range(1024):
        yblock = i//32
        xblock = i//block_size
        if 0 == (xblock % 2):
          if 0 == yblock % 2:
            zs.append(i)
          else:
            ed.append(i)
        else:
          if 0 == yblock % 2:
            ed.append(i)
          else:
            zs.append(i)

    #print('ed=', len(ed), 'zs=',len(zs))
    lats.ignore = torch.tensor(zs).cuda()
    lats.keep_indices = torch.tensor(ed).cuda()

    #print('len(lats.ignore) =', len(lats.ignore))
    if len(lats.ignore) > 0:
      lats.keep = lats.normu[:, :, lats.ignore].detach()

    if len(ed) > 0:
      lats.normu.data[:, :, lats.keep_indices] = torch.randn_like(lats.normu.data[:, :, lats.keep_indices])
      
    mapper = [lats.normu]
    optimizer = torch.optim.AdamW([{'params': mapper, 'lr': lr}], weight_decay=dec)
    
    out = decode(lats())
  else:
    out = decode(lats())

  if do_pop:
    with torch.no_grad():
      al = (out.cpu().clip(-1, 1) + 1) / 2

      if path_to_auto_save != '':
        save_image_text(path_to_auto_save, al[0], str(itt)+'.'+text_input0)

      # al in [0,1]
      for allls in al:
        displ(allls[:3])
        display.display(display.Image(str(3)+'.png'))
        print('\n')

  do_pop = False
  into = augment((out.clip(-1, 1) + 1) / 2)
  into = nom(into)

  iii = perceptor.encode_image(into)

  # q = slerp(.2, t, img_enc)

  q = w0*t + w1*text_add + w2*img_enc + w3*ne_img_enc
  q = q / q.norm(dim=-1, keepdim=True)

  all_s = torch.cosine_similarity(q, iii, -1)

  # all_s = torch.arccos(0 - all_s) / np.pi

  return [0, -10*all_s + 5 * torch.cosine_similarity(t_not, iii, -1)]
  
last_img = None
pro_saving = False
img_save_thresh = 160 # For 512x512
img_reject_thresh = 180
itt_reject = 0
img_save_count = 1;
saved_this_check = False

def train(i):
  global dec
  global up_noise
  global itt_new
  global cmd_cursor
  global cmd_times, cmds
  global path_to_auto_run
  global save_singles
  global last_img, pro_saving, img_save_thresh, img_save_count, img_reject_thresh, itt_reject, saved_this_check

  #if itt % nItt_update_max == 0:
    #print(loss1)
    #print('up_noise', up_noise)
    #for g in optimizer.param_groups:
      #print(g['lr'], 'lr', g['weight_decay'], 'decay')

  pro_saved = False
  if pro_saving:
    with torch.no_grad():
      img = current_image()
      if last_img != None:
        dist = np.linalg.norm(img-last_img)
        if dist > img_reject_thresh:
          itt_reject = itt
          print('Dist adapt', img_save_thresh,int(dist),img_reject_thresh)
          img_save_thresh += 1
          img_reject_thresh += 2
          
        if (dist > img_save_thresh and dist <= img_reject_thresh) or (itt_reject > 0 and itt > itt_reject + 5 ):
          save_image_text(path_to_auto_save, img, str(itt)+'.'+text_input0)
          last_img = img
          pro_saved = True
          print('Saved @'+str(i),' Dist =', int(dist))
          img_save_count += 1
          itt_reject = 0
          saved_this_check = True
      else:
        last_img = img

  if cmd_cursor >= len(cmd_times):
    path_to_auto_run = ''
    #print('train','cmd_cursor = ', str(cmd_cursor),', len = ', str(len(cmd_times)))
    cmd_cursor = 0
  
  diff = itt % 10
  if itt_new > 5 and itt_new < 20 and diff == 0:
    #print('itt=',itt,' itt_new=',itt_new)
    itt_new = 10
    #print('itt_new reset',itt_new)
  
  if itt_new == 10:
    save_singles = False
    
  saving_singles = save_singles and path_to_auto_save != ''

  itt_new_stop = (itt_new == 10 or itt_new == 20 or itt_new == 50)

  itt_stop = (itt % nItt_update_max == 0 or ((itt == 1 or itt == 2 or itt == 5) and not saving_singles))

  cmd_stop = (path_to_auto_run != '' and cmd_times[cmd_cursor] == itt)

  """  
  if itt_stop or itt_new_stop or cmd_stop:
    checkin()
    if pro_saving: 
      if saved_this_check:
        saved_this_check = False
      else:
        if (itt > 20):
          img_save_thresh -= 5
        with torch.no_grad():
          img = current_image()
          save_image_text(path_to_auto_save, img, str(itt)+'.'+text_input0)
  elif (saving_singles or 35 == itt_new or (itt_new > 50 and 25 == itt_new % 50 )) and not pro_saved:
    with torch.no_grad():
      img = current_image()
      save_image_text(path_to_auto_save, img, str(itt)+'.'+text_input0)
  """
  if itt > 0:
    if (itt+1) % args.update == 0:
      checkin()
    
  loss1 = ascend_txt()
  loss = loss1[0] + loss1[1]
  loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  
  #if itt % nItt_update_max == 0:
    #print(loss1)

  # if itt > 400:
  #   for g in optimizer.param_groups:
  #     g['lr'] *= .995
  #     g['lr'] = max(g['lr'], .1)
  #   dec *= .995
 
  if lats.keep_indices.size()[0] != 0:
    if torch.abs(lats().view(batch_size, 256, -1)[:, :, lats.keep_indices]).max() > 5:
      for g in optimizer.param_groups:
        g['weight_decay'] = dec
    else:
      for g in optimizer.param_groups:
        g['weight_decay'] = 0

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

def loop():
  global itt
  global itt_new
  for asatreat in range(args.iterations):
 
    sys.stdout.write("Iteration {}".format(itt+1)+"\n")
    sys.stdout.flush()

    train(itt)
    itt+=1
    itt_new+=1

"""# Image Production Loop (Game Play)"""

loop()
