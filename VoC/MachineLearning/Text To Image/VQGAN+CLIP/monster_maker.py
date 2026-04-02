# Monster Maker
# Original file is located at https://colab.research.google.com/drive/1ZbLnt5fLS_BDfpQY-9Dh_T40pLjfqSAC

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./taming-transformers')

import subprocess
import kornia
import torch
import numpy as np
import torchvision
import torchvision.transforms.functional as TF
import PIL
import os
import random
import imageio
import PIL
import glob
import cv2
import os
from CLIP.clip import clip
import torch
import argparse
import yaml
import torch
from omegaconf import OmegaConf
from taming.models.vqgan import VQModel
from IPython import display
from torchvision import transforms

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--size', type=int, help='Image size.')
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--useaugs', type=bool, help='Use augments.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

args = argparse.Namespace(
    prompts=[args2.prompt],
    size=args2.size, 
    init_image= args2.seed_image,
    iterations=args2.iterations,
    learning_rate=args2.learning_rate,
    batch_size=args2.batch_size,
    clip_model=args2.clip_model,
    vqgan_config=f'{args2.vqgan_model}.yaml',
    vqgan_checkpoint=f'{args2.vqgan_model}.ckpt',
    cutn=args2.cutn,
    display_freq=args2.update,
    seed=args2.seed,
    use_augs = args2.useaugs,
)

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

global baseImage
global RandomCropLarge
global resizeIncrease
global cropCoords
global resizeCount
global bigcounter
global firstRun

Iterations =  args.iterations
LearningRate = args.learning_rate
Augs = args.use_augs
cutn=args.cutn
text_inputs=args.prompts
batch_size = args.batch_size
img_size = args.size

vResizeIncrease = 0.03 #@param {type:"number"}
hResizeIncrease = 0  #@param {type:"number"}
cropCoords = []
resizeCount = 6
bigcounter = 0
count = 0
sideX = img_size
sideY = img_size
resize = transforms.Resize((img_size,img_size))
start_img_random = False 
variable_name = "" 
start_img_scale = 24
learning_rate = LearningRate
decay = 0.02
up_noise = 0.1

# seed image
RandomCropLarge = False
if args.init_image != None:
  RandomCropLarge = True
if (RandomCropLarge == True):
  sys.stdout.write("Loading seed image ...\n")
  sys.stdout.flush()
  global baseImage
  baseImage = PIL.Image.open(args.init_image)
  baseImage = np.asarray(baseImage)

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor = perceptor.eval()

def displ(img, coord=False):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  img_arr = (np.array(img)*255).astype(np.uint8)
  #imageio.imwrite('Progress.png', img_arr)
  imageio.imsave(args2.image_file, img_arr)
  
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
      imageio.imsave(save_name, img_arr)

  
  
  #imageio.getwriter.close
  latentCoord(img_arr)
  return display.Image(str(3)+'.png')

def numpy2tensor(imgArray):
  im = torch.unsqueeze(transforms.ToTensor()(imgArray), 0)   
  return im

def load2tensor(imgfile):
  imgfile = PIL.Image.open(imgfile)
  im = torch.unsqueeze(transforms.ToTensor()(imgfile), 0)   
  return im

def get_blends(iterations):
  midpoint = int(iterations/2)
  x = np.linspace(0,1,midpoint)
  ease = CubicEaseInOut(1,0)
  y_right = list(map(ease, x))
  y_left = [y for y in reversed(y_right)]
  return y_left + y_right

def zoom_img(img, zoom):  
  print(f"zoom : {zoom}")
  return transforms.functional.affine(img, 0, (0, 0), 1 + zoom, 0) #/*, resample=PIL.Image.BILINEAR)

def encode_inputs(inputs):
  encoded_inputs = []
  for txt in inputs:
    tx = clip.tokenize(txt)
    t = perceptor.encode_text(tx.cuda()).detach().clone()
    encoded_inputs.append(t)
  return encoded_inputs

def starter_image():
  return get_random_crop(baseImage, img_size, img_size)
 
def speckly_crop(oldArray):
  global cropCoords
  global baseImage
  if (len(cropCoords) > 0):
    reverse_crop(oldArray, cropCoords[0], cropCoords[1], cropCoords[2], cropCoords[3])
  print ('THESE ARE THE COORDS' + str(cropCoords))
  imarray = get_random_crop(baseImage, img_size, img_size)
  cropCoords = [imarray[1], imarray[2], imarray[3], imarray[4]]
  return imarray[0]

def reverse_crop(imgArray, y, x, crop_height, crop_width):
    global baseImage
    global resizeCount
    global hResizeIncrease
    global vResizeIncrease
    global bigcounter
    clone = baseImage.copy()
    clone[y: y + crop_height, x: x + crop_width,:] = imgArray[0:crop_height,0:crop_width,:]
    print ('RESIZE' + str(count) + str(resizeCount))
    if (count > resizeCount):
      print ('RESIZED')
      h, w, _ = clone.shape
      if (hResizeIncrease != 0):
        h = int(h * (1 + hResizeIncrease))
      if (vResizeIncrease != 0):
        w = int(w * (1 + vResizeIncrease))
      clone = cv2.resize(baseImage, dsize=(h, w), interpolation=cv2.INTER_CUBIC)
      resizeCount = resizeCount * 2
      bigcounter += 1

    baseImage = clone

def get_random_crop(image, crop_height, crop_width):
    max_x = image.shape[1] - crop_width  +1 #+1 needed to avoid errors
    max_y = image.shape[0] - crop_height +1 #+1 needed to avoid errors
    x = np.random.randint(0, max_x)
    y = np.random.randint(0, max_y)
    print ('CROPPED')
    crop = image[y: y + crop_height, x: x + crop_width]
    return [crop, y, x, crop_height, crop_width]
 
def noisy(noise_typ,image):
   if noise_typ == "gauss":
      row,col,ch= image.shape
      mean = 0
      var = 0.1
      sigma = var**0.5
      gauss = np.random.normal(mean,sigma,(row,col,ch))
      gauss = gauss.reshape(row,col,ch)
      noisy = image + gauss
      return noisy
   elif noise_typ == "s&p":
      row,col,ch = image.shape
      s_vs_p = 0.5
      amount = 0.004
      out = np.copy(image)
      # Salt mode
      num_salt = np.ceil(amount * image.size * s_vs_p)
      coords = [np.random.randint(0, i - 1, int(num_salt))
              for i in image.shape]
      out[coords] = 1

      # Pepper mode
      num_pepper = np.ceil(amount* image.size * (1. - s_vs_p))
      coords = [np.random.randint(0, i - 1, int(num_pepper))
              for i in image.shape]
      out[coords] = 0
      return out

"""# Generator"""

sys.path.append(".")

DEVICE = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', DEVICE)
print(torch.cuda.get_device_properties(device))

def load_config(config_path, display=False):
  config = OmegaConf.load(config_path)
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
  z, _, [_, _, indices] = model.encode(x)
  #print(f"VQGAN: latent shape: {z.shape[2:]}")
  xrec = model.decode(z)
  return xrec

sys.stdout.write("Loading VQGAN model "+args.vqgan_checkpoint+" ...\n")
sys.stdout.flush()

config16384 = load_config(args.vqgan_config, display=False)
model16384 = load_vqgan(config16384, ckpt_path=args.vqgan_checkpoint).to(DEVICE)

sys.stdout.write('Starting ...\n')
sys.stdout.flush()

def latentCoord(imgArray):
  if hasattr(imgArray, "__len__"):
    if (RandomCropLarge == True):
      imgArray = speckly_crop(imgArray)
    image_input = numpy2tensor(imgArray)
  else:
    if os.path.exists("/content/img_gen.jpg") == False:
      image_input = None
    else:
      image_input = load2tensor("img_gen.jpg")
  init(image_input)

class Pars(torch.nn.Module):
    def __init__(self, input=None):
        super(Pars, self).__init__()
        if input == None:
          if start_img_random == True:
            img = torch.rand(1, 3,start_img_scale,start_img_scale)
          else:  
            img = torch.Tensor(1,3,start_img_scale,start_img_scale).normal_(mean=0.3, std=0.7).clamp_(-1,1) 
        else:
          img = input
        img = resize(img)  
        DEVICE = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        img = 2.*img - 1.
        img = img.to(DEVICE)
        z, _, [_, _, indices] = model16384.encode(img)
        self.normu = torch.nn.Parameter(z.cuda())
        
    def forward(self):
        return self.normu.clip(-5,5).cuda()
      

def model(x):
  o_i2 = x
  o_i3 = model16384.post_quant_conv(o_i2)
  i = model16384.decoder(o_i3)
  return i

lats = []
mapper = []
optimizer = None

def init(img=None):
  global lats
  global mapper
  global optimizer
  
  #torch.manual_seed(203492934)
  lats = Pars(img).cuda()
  mapper = [lats.normu]
  optimizer = torch.optim.AdamW([{'params': mapper, 'lr': learning_rate}], weight_decay = decay)
  
  with torch.no_grad():
    alnot = (model(lats()).cpu().clip(-1, 1) + 1) / 2

itt = 0
nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
text_not = '''disconnected, confusing, cropped'''
t_not = clip.tokenize(text_not)
t_not = perceptor.encode_text(t_not.cuda()).detach().clone()
dec = .07
latentCoord(None)

augs = torch.nn.Sequential(
    kornia.augmentation.RandomHorizontalFlip(),
    kornia.augmentation.ColorJitter(hue=.01, saturation=.01, p=.7),
    kornia.augmentation.RandomAffine(degrees=30, translate=.1, p=.8, padding_mode='zeros'),
    ).cuda()

iterations = Iterations
zoom_offset = 0
encoded_txts = encode_inputs(text_inputs)
blending=False
from easing_functions import *
blends = get_blends(iterations) 
global indexCounter
indexCounter = 0

def augment(into):
  if (Augs == True):
    into = augs(into)

  p_s = []
  for ch in range(cutn):
    size = torch.randint(int(.5*sideX), int(.98*sideX), ())
    if ch < 4:
      size = sideX-32
    offsetx = torch.randint(0, sideX - size, ())
    offsety = torch.randint(0, sideX - size, ())
    apper = into[:, :, offsetx:offsetx + size, offsety:offsety + size]
    apper = torch.nn.functional.interpolate(apper, (224,224), mode='bilinear', align_corners=True)
    p_s.append(apper)
  into = torch.cat(p_s, 0)
  into = into + up_noise*random.random()*torch.randn_like(into, requires_grad=False)
  return into

def checkin(loss):
  sys.stdout.flush()
  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()

  global up_noise
  global indexCounter
  
  with torch.no_grad():
    alnot = model(lats()).float()
    alnot = augment((((alnot).clip(-1, 1) + 1) / 2))
    alnot = (model(lats()).cpu().clip(-1, 1) + 1) / 2
    if (indexCounter > iterations):
      indexCounter = 0;
    indexCounter += 1
    for allls in alnot.cpu():
      latentCoordTest = False
      if (indexCounter % 1 == 0):
        latentCoordTest = True
        displ(allls, latentCoordTest)
  sys.stdout.flush()
  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()
    
def ascend_txt(idx):
  global zoom_offset
  out = model(lats())
  out = augment((out.clip(-1, 1) + 1) / 2)
  
   
  if blending:
    b1 = itt
    b2 = int((itt + iterations/2) % iterations)
    if idx > 0:
      offset = -1
    elif idx == 0:
      offset = len(encoded_txts)-1 #summary
    if itt > iterations/2:
      offset = 1 
    t = blends[b1] * encoded_txts[idx] + blends[b2] * encoded_txts[idx + offset]
    print(f"{blends[b1]:.2f} * {text_inputs[idx]} + {blends[b2]:.2f} * {text_inputs[idx + offset]}")  

  else:
    t = encoded_txts[idx]  

  global up_noise
  out = model(lats())
  into = augment((out.clip(-1, 1) + 1) / 2)
  into = nom(into)
  iii = perceptor.encode_image(into)
  lat_l = 0

  return [2*torch.cosine_similarity(t_not, iii).mean(), 10*-torch.cosine_similarity(t, iii).view(-1, batch_size).T.mean(1)]
  
def train(i,iters):
  sys.stdout.write("Iteration {}".format(iters)+"\n")
  sys.stdout.flush()

  global up_noise

  loss1 = ascend_txt(i)
  loss = loss1[0] + loss1[1]
  loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  
  for g in optimizer.param_groups:
    g['lr'] *= .995
    g['lr'] = max(g['lr'], .1)

  if torch.abs(lats()).max() > 4:
    for g in optimizer.param_groups:
      g['weight_decay'] = dec
  else:
    for g in optimizer.param_groups:
      g['weight_decay'] = 0
  
  if iters != 0:
    if iters % args.display_freq == 0:
      checkin(loss1)
  
def loop():
  global itt
  global encoded_txts
  itt = 1
  iloop = 1
  encoded_txts = encode_inputs(text_inputs)
  for itt in range(iterations): 
    #sys.stdout.write("Calling train with iterations {}".format(iloop)+"\n")
    #sys.stdout.flush()
    train(0,iloop)
    itt+=1
    iloop+=1

loop()
