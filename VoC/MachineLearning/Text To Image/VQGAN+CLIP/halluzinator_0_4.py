# Halluzinator 0.4.ipynb
# Original file is located at https://colab.research.google.com/drive/1AHnwCTTddvvv49mhQMa6bXv5h7Z9SLcV

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import cv2
import numpy as np
import re
import torch
from torchvision import transforms
import gc
import json
from pprint import pprint
from base64 import b64encode, b64decode
import PIL
import copy
import random
import imageio
import ipywidgets as ipy
import sys
import glob
import math
from PIL import Image

sys.path.append('./taming-transformers')

scaler = 2 #@param {type:"slider", min:1, max:3, step:1}

from CLIP.clip import clip
import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image size.')
  parser.add_argument('--sizey', type=int, help='Image size.')
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--speed', type=int, help='Movement speed.')
  parser.add_argument('--movement1', type=str, help='Movement.')
  parser.add_argument('--movement2', type=str, help='Movement.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--useaugs', type=bool, help='Use augments.')
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





sys.stdout.write("Loading CLIP model ViT-B/32 ...\n")
sys.stdout.flush()

clip.available_models()
clip_model = 'ViT-B/32'

perceptor, preprocess = clip.load(clip_model, jit=False)
perceptor = perceptor.eval().requires_grad_(False);
perceptor_size = 224

tensor_size = 1 + int(49 * scaler**2)
perceptor.visual.scale = perceptor_size * scaler
perceptor.visual.positional_embedding = torch.nn.Parameter(torch.nn.functional.upsample(perceptor.visual.positional_embedding.T.unsqueeze(0), (tensor_size), mode='linear', align_corners=True).squeeze(0).T)


device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', device)
print(torch.cuda.get_device_properties(device))
DEVICE = device

import yaml
from omegaconf import OmegaConf
from taming.models.vqgan import VQModel, GumbelVQ
from taming.models.cond_transformer import Net2NetTransformer
def load_config(config_path, display=False):
  config = OmegaConf.load(config_path)
  if display:
    print(yaml.dump(OmegaConf.to_container(config)))
  return config

def load_vqgan(config, checkpoint_path):
  if config.model.target == 'taming.models.vqgan.VQModel':
    model = VQModel(**config.model.params)
    model.eval().requires_grad_(False)
    model.init_from_ckpt(checkpoint_path)
  elif config.model.target == 'taming.models.vqgan.GumbelVQ':
    model = GumbelVQ(**config.model.params)
    model.eval().requires_grad_(False)
    model.init_from_ckpt(checkpoint_path)
  elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
    parent_model = Net2NetTransformer(**config.model.params)
    parent_model.eval().requires_grad_(False)
    parent_model.init_from_ckpt(checkpoint_path)
    model = parent_model.first_stage_model
  del model.loss
  return model

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


sys.stdout.write("Loading VQGAN model "+args.vqgan_model+" ...\n")
sys.stdout.flush()

cfg_vqgan= load_config(f'{args.vqgan_model}.yaml', display=False)
model_vqgan= load_vqgan(cfg_vqgan,f'{args.vqgan_model}.ckpt').to(DEVICE)

"""#settings and state

"""

xsheet = ""#@param {type:"string"}
#@markdown If you have xsheet, ignore the rest
#save_path='/content/frames'#@param {type:"string"}
save_path='.'#@param {type:"string"}
fps = 24 #@param {type:"number"}
width = args.sizex#@param {type:"number"}
height = args.sizey#@param {type:"number"}
img_gen = ""#@param {type:"string"}
gs = { # dictionary of states and their changes
	"settings" : {},
	"states": []
} 
state = {}
interactive = xsheet == ''
#torch.manual_seed(random_seed)
#np.random.seed(random_seed)

#if not os.path.exists(save_path):
#  !mkdir {save_path}

def init_state():
  global state
  state = {
    "prompts":[],
    "weights":[1,0],
    "lr":0.1,
    "burnin": 1,
    "cutn": 16,
    "decay": 0.0,
    "index": 0,
    "moves": [],
    "noise": 0.0,
    "incs": [],
    "prompts": ['',''],
    "slerp_val": 0.35
  }


if not interactive:
  with open(xsheet) as json_file:
    xsh = json.load(json_file)
    json_file.close()
  gs["settings"] = xsh["settings"]
else:
  gs["settings"]["fps"] = fps
  gs["settings"]["start"] = 0
  gs["settings"]["width"] = width
  gs["settings"]["height"] = height
  gs["settings"]["img_gen"] = img_gen
init_state()

print(f'{"Interactive" if interactive else "Automatic"} mode')

interval = args.update


"""# init"""

count = 0
inpaint = False

losses = [] 
images = []
rotate = False
angle = 0
firstrun = True

preview_frames = 50
img_gen = gs["settings"]["img_gen"]
fps = gs["settings"]["fps"]
sideH = gs["settings"]["height"]
sideW =  gs["settings"]["width"]
start_img_scale = 5
# %cd /content
DEVICE = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
frame_count = 0

resize = transforms.Resize((sideH,sideW)) 

def img2tensor(img_path):
  imgfile = imageio.imread(img_path)
  im = torch.tensor(imgfile).unsqueeze(0).permute(0, 3, 1, 2)[:,:3]
  return im
 
def numpy2tensor(imgArray):
  im = torch.unsqueeze(transforms.ToTensor()(imgArray), 0)   
  return im  

def img2t(img_path):
  if img_path == '':
    return None
  imgfile = PIL.Image.open(img_path)
  return numpy2tensor(imgfile)

def generate_starter_img():
  """
  # 45 random circles
  canvas = np.zeros((sideH, sideW, 3), dtype="uint8")
  for _ in range(45):
    radius = np.random.randint(5, high=sideW//5)
    color = np.random.randint(0, high=256, size=(3,)).tolist()
    center_yx = np.random.randint(0, high=sideH, size=(2,))
    cv2.circle(canvas, tuple(center_yx), radius, color, -1)
    cv2.imwrite("img_gen.jpg", canvas)
  """
  #random noise
  data = np.random.randint(0, 256, (sideH,sideW,3), dtype=np.uint8)
  im = Image.fromarray(data)

  im.save("img_gen.jpg")  
  
  return img2t("img_gen.jpg") 

class Pars(torch.nn.Module):
  def __init__(self, img=None, interpolate=False):
    super(Pars, self).__init__()
    with torch.no_grad():
      if inpaint:
        assert img != None, "Inpaint initial image not provided."
        x = img2t(img)
        x = x.to(DEVICE)  
        o_i1 = model_vqgan.encoder(preprocess_vqgan(x)) # [1, 256, 32, 32]
        o_i2 = model_vqgan.quant_conv(o_i1)
        self.normu = torch.nn.Parameter(o_i2.cuda().clone().view(1, 256, sideH//16 * sideW//16)) #[1, 256, 1024]
        self.reset_mask()
      else:
        if img == None:
          img = generate_starter_img()
        img = resize(img)  
        img = img.to(DEVICE)
        z, _, [_, _, indices] = model_vqgan.encode(preprocess_vqgan(img))
        if interpolate: 
          z = slerp(lats.normu, z, state["slerp_val"])       
        self.normu = torch.nn.Parameter(z.cuda())  
        
  def reset_mask(self):
    self.ignore = torch.empty(0,).long().cuda()
    self.keep = torch.empty(0,).long().cuda()
    self.keep_indices = torch.empty(0,).long().cuda()

  def forward(self):
    if inpaint:
      mask = torch.ones(self.normu.shape, requires_grad=False).cuda()
      mask[:, :, self.ignore] = 1
      normu = self.normu * mask
      normu.scatter_(2, self.ignore.unsqueeze(0).unsqueeze(0).expand(-1, 256, -1), self.keep.detach())
      return normu.view(1, -1, sideH//16, sideW//16)
    else:
      #return self.normu.clip(-5,5).cuda()
      return self.normu.cuda()
     
def model(x):
  o_i3 = model_vqgan.post_quant_conv(x)
  i = model_vqgan.decoder(o_i3)
  return i

lats = []
optimizer = None

def init(img=None,interpolate=True):
  global lats
  global optimizer
  lats = Pars(img).cuda()
  optimizer = torch.optim.AdamW([{'params': [lats.normu],'lr': 0.1}]) 
  
input_image = img2t(gs["settings"]["img_gen"]) if gs["settings"]["img_gen"] != '' else None
init(input_image)

"""#methods"""

canvas_html = """
<canvas width=%d height=%d style="background: url('nbextensions/latest.jpg')"></canvas>
<button>Save mask</button>
<script>
var canvas = document.querySelector('canvas')
var ctx = canvas.getContext('2d')
ctx.lineWidth = %d
var button = document.querySelector('button')
var mouse = {x: 0, y: 0}

canvas.addEventListener('mousemove', function(e) {
  mouse.x = e.pageX - this.offsetLeft
  mouse.y = e.pageY - this.offsetTop
})
canvas.onmousedown = () => {
  ctx.beginPath()
  ctx.moveTo(mouse.x, mouse.y)
  canvas.addEventListener('mousemove', onPaint)
}
canvas.onmouseup = () => {
  canvas.removeEventListener('mousemove', onPaint)
}
var onPaint = () => {
  ctx.lineTo(mouse.x, mouse.y)
  ctx.stroke()
}
var data = new Promise(resolve => {
  button.onclick = () => {
    resolve(canvas.toDataURL('image/png'))
  }
})
</script>
"""

def draw(filename='paint_area.png', w=sideW, h=sideH, line_width=32):
  outpic.clear_output()
  with outpic:
    display(HTML(canvas_html % (w, h, line_width)))
  data = output.eval_js('data')
  binary = b64decode(data.split(',')[1])
  with open(filename, 'wb') as f:
    f.write(binary)
  return len(binary)

def set_paint_area(draw_it=True):
 
  #img_path = f"{save_path}/{frame_count-1:05}.jpg"
  init(img_path)
  #npth = '/usr/local/share/jupyter/nbextensions/latest.jpg'
  #npth = 'latest.jpg'
  #!cp {img_path} {npth}

  lats.normu.data = lats.normu.scatter(2, lats.ignore.unsqueeze(0).unsqueeze(0).expand(-1, 256, -1),
                                       lats.keep.detach())
  if draw_it:                              
    _ = draw()

  drawn = torch.nn.functional.interpolate(torch.tensor(imageio.imread('/content/paint_area.png')).
                                          unsqueeze(0).permute(0, 3, 1, 2),
                                          (sideH//16, sideW//16),
                                          mode='nearest')[:,3:4,:,:]
  ed = []
  zs = []
  for inx, kj in enumerate(drawn.view(-1, 1)):
    if kj.sum() < 1:
      zs.append(inx)
    else:
      ed.append(inx)
  lats.ignore = torch.tensor(zs).long().cuda()
  lats.keep = lats.normu[:, :, lats.ignore].detach()

  lats.keep_indices = torch.tensor(ed).long().cuda()
  '''
  if len(ed) > 0:
      lats.normu.data[:, :, torch.tensor(ed).cuda()] = torch.randn_like(
          lats.normu.data[:, :, torch.tensor(ed).cuda()])
  '''  
def reset_paint_area():
  global inpaint
  lats.reset_mask()
  inpaint = False
  init(numpy2tensor(images[-1]))   

def displ(img):
  sys.stdout.flush()
  sys.stdout.write("Saving progress ...\n")
  sys.stdout.flush()

  global frame_count
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1, 2, 0))
  images.append(img)
  
  img = (img*255).astype(np.uint8)
  imageio.imwrite(args.image_file, img)
  
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
      imageio.imwrite(save_name, img)
  
  
  #imageio.imwrite(f"{save_path}/{frame_count:05}.jpg", np.array(img))
  frame_count += 1
  cam_off = all(m == 'off' for m in state["moves"]) or state["moves"] == []
  if frame_count > 1 and not cam_off and not inpaint:  
    camera_movement(img)

  sys.stdout.flush()
  sys.stdout.write("Progress saved\n")
  sys.stdout.flush()

   
def move_cam(img,m,inc):
  if m == 'off':
    pass
  elif m == 'rotate':
    img = rotate_img(img,inc)  
  elif m == 'warp':
    img = warp(img,inc)    
  elif m == 'zoom_in':
    img = zoom_in(img,inc) 
  elif m == 'zoom_out':
    img = zoom_out(img,inc)  
  elif m[:3] == 'pan':
    img = pan(img,m,inc)
  return img    

def camera_movement(img):
  for i,m in enumerate(state["moves"]):
    img = move_cam(img,m,state["incs"][i])
  init(numpy2tensor(img),interpolate=True)

epsilon = 1e-7
def slerp(low, high, val):
  low_norm = low/torch.norm(low, dim=1, keepdim=True)
  high_norm = high/torch.norm(high, dim=1, keepdim=True)
  omega = (low_norm*high_norm).sum(1)
  omega = torch.acos(torch.clamp(omega, -1 + epsilon, 1 - epsilon))
  so = torch.sin(omega)
  res = (torch.sin((1.0-val)*omega)/so).unsqueeze(1)*low + (torch.sin(val*omega)/so).unsqueeze(1) * high
  return res  

def crop(img, dx, dy, h, w):
  return img[dy:dy+h, dx:dx+w]

def centre_crop(img,inc):
  h,w = img.shape[:2]
  d = max(2,inc//2)
  return img[d: h - d, d: w - d]  

def get_new_dims(change_in_width,h,w):
  ratio = (w + change_in_width) / w
  return (w + change_in_width, int(h * ratio))

def warp(img,inc):  
  h,w = img.shape[:2]
  pts1 = np.float32([[0, 0], [inc, h - inc], [w - inc, h - inc], [w, 0]])
  pts2 = np.float32([[0, 0], [0, h], [w, h], [w, 0]])
  matrix = cv2.getPerspectiveTransform(pts1, pts2)
  result = cv2.warpPerspective(img, matrix, (w, h), borderMode=cv2.BORDER_REPLICATE)
  return result  

def zoom_in(img,inc):
  h,w = img.shape[:2]
  new_w,new_h = get_new_dims(inc, h,w)
  img = cv2.resize(img, (new_w, new_h), cv2.INTER_LANCZOS4)
  return centre_crop(img,inc)
  
def zoom_out(img,inc):  
  bdr = cv2.copyMakeBorder(img,inc,inc,inc,inc,cv2.BORDER_REPLICATE)
  #bdr = blur(bdr)
  return cv2.resize(bdr, dsize=(sideH, sideW), interpolation=cv2.INTER_CUBIC)

def pan(img,move,inc):
  h,w = img.shape[:2]
  ret = img
  if move == 'pan_right':
    # cv2.copyMakeBorder(im=img,top=0,bottom=inc,left=0,right=0,cv2.BORDER_REPLICATE)
    border = cv2.copyMakeBorder(img,0,inc,0,0,cv2.BORDER_REPLICATE)
    border_crop = crop(border, 0, 0, h, inc) # crop(img, dx, dy, h, w): img[dy:dy+h, dx:dx+w]
    img_crop = crop(img, 0, 0, h, w - inc)
    ret = np.concatenate((border_crop,img_crop), axis = 1)
  elif move == 'pan_up':
    border = cv2.copyMakeBorder(img,inc,0,0,0,cv2.BORDER_REPLICATE)
    border_crop = crop(border, 0, 0, inc, w)
    img_crop =crop(img, 0, 0,h - inc, w)
    ret = np.concatenate((border_crop,img_crop))
  elif move == 'pan_down':
    border = cv2.copyMakeBorder(img,0,0,inc,0,cv2.BORDER_REPLICATE)
    border_crop = crop(border, 0, inc, inc, w)
    img_crop = crop(img, 0, inc ,h -inc, w)
    ret = np.concatenate((img_crop, border_crop))
  elif move == 'pan_left': 
    border = cv2.copyMakeBorder(img,0,0,0,inc,cv2.BORDER_REPLICATE)
    border_crop =crop(border, h - inc, 0, h, inc)
    img_crop =crop(img, inc, 0, h, w - inc)
    ret = np.concatenate((img_crop, border_crop), axis = 1)
  return ret

padding = int(max(sideH,sideW)/4) 

def rotate_img(img,inc):
  PIL_img = PIL.Image.fromarray(img.astype('uint8'), 'RGB')
  img = transforms.functional.pad(img=PIL_img, padding=padding, padding_mode='reflect')
  img = transforms.functional.rotate(img, -inc, resample=PIL.Image.BILINEAR)
  img = transforms.functional.crop(img, padding, padding, sideH, sideW)
  return np.asarray(img)

def edit(frame):
  global gs
  global images
  global frame_count
  print(f"{len(images)} images before edit")
  images = images[:frame+1]
  print(f"{len(images)} images after edit")
  gs["states"] = [s for s in gs["states"] if s["index"] <= frame]
  frame_count = frame
  init(numpy2tensor(images[-1]))    

def get_html_video(video):
  data_url = "data:video/mp4;base64," + b64encode(open(video,'rb').read()).decode()
  return f'<video controls><source src="{data_url}" type="video/mp4"></video>' 

def encode_prompt(txt):
  if '/' in txt:
    return encode_target_img(txt)
  else:
    tx = clip.tokenize(txt)
    return perceptor.encode_text(tx.cuda()).detach().clone()

def encode_target_img(img_enc_path):
  img_enc = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(img_enc_path)).unsqueeze(0).permute(0, 3, 1, 2),
                                             (224*scaler, 224*scaler)) / 255).cuda()[:,:3]
  img_enc = nom(img_enc)
  return perceptor.encode_image(img_enc.cuda()).detach().clone()

def get_augs():
  augs = torch.nn.Sequential(
    transforms.RandomHorizontalFlip(),
    #transforms.RandomCrop((sideW,sideH)),
    transforms.RandomAffine(np.random.randint(0, 180)),
    transforms.RandomVerticalFlip()
  ).cuda()
  return augs

augs = get_augs()
# true an tried values
mean = 0.35
std = 0.8
clamp_min = 0.1
clamp_max = 0.99
def augment(into, cutn=32):
  pd = sideH//2
  into = torch.nn.functional.pad(into, (pd,pd,pd,pd), mode='constant', value=0)
  into = augs(into)
  p_s = []
  for ch in range(cutn):
    size = int(torch.normal(mean, std, ()).clip(clamp_min, clamp_max) * sideH)
    if ch > cutn - cutn//4:
      size = int(sideH*1.4)
    high = int(abs(sideH*2 - size))  
    high = high if high>0 else 1
    offsetx = torch.randint(0, high, ())
    offsety = torch.randint(0, high, ())
    apper = into[:, :, offsetx:offsetx + size, offsety:offsety + size]
    apper = torch.nn.functional.interpolate(apper, (int(perceptor_size *scaler), int(perceptor_size *scaler)), mode='bilinear', align_corners=True)
    p_s.append(apper)
  into = torch.cat(p_s, 0)
  into = into + state["noise"]*torch.rand((into.shape[0], 1, 1, 1)).cuda()*torch.randn_like(into, requires_grad=False)
  return into

display_interval = 3 #TODO UI
def checkin():
  alnot = (model(lats()).cpu().clip(-1, 1) + 1) / 2 # [1, 3, 512, 512]
  if rotate:
    alnot = rotate_img(alnot)
  allls = alnot[0].cpu()
  displ(allls.detach().numpy()) #[3, 512, 512]
  """
  if count%display_interval == 0:
    outpic.clear_output()
    with outpic:
      display(Image('view.jpg'))
      if interactive:
       print(f'{it}/{total_count}')
  """
    
nom = transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

def format_image(x):
  x = torch.tanh(x+x**5*0.5)
  x = (x + 1.)/2.
  return x

def ascend_txt(t):
  out = format_image(model(lats()))
  out = augment(out)
  normalized = nom(out)
  encoded = perceptor.encode_image(normalized) #[32, 512]
  return 10*-torch.cosine_similarity(t, encoded, -1) 

def train(t):
  loss = ascend_txt(t).mean()
  losses.append(loss.item())
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()
  #if count % state["burnin"] == 0:
  #  checkin()
  
def encode_prompts():
  t = 0
  for i,prompt in enumerate(state["prompts"]):
    enc = encode_prompt(prompt)
    t += enc * state["weights"][i]
    #print(f'{prompt} * {state["weights"][i]}')
  return t

"""# ui"""



lo30 = ipy.Layout(width='30%')

noise_slider = ipy.FloatSlider(
    value=0.0,
    min=0.0,
    max=1.0,
    step=0.1,
    description='noise:',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.1f',
)
decay_slider = ipy.FloatSlider(
    value=0.1,
    min=0.00,
    max=1.00,
    step=0.01,
    description='decay',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.1f',
)
lr_slider = ipy.FloatSlider(
    value= state["lr"],
    min=0.00,
    max=1.00,
    step=0.01,
    description='lr',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.2f',
)
cutn_slider = ipy.IntSlider(
    value=32,
    min=0,
    max=128,
    step=4,
    description='cutn',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='d'
)

mean_slider = ipy.FloatSlider(
    value=0.35,
    min=0.00,
    max=1.00,
    step=0.01,
    description='mean',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.2f',
)
std_slider = ipy.FloatSlider(
    value=0.80,
    min=0.00,
    max=1.00,
    step=0.01,
    description='std',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.2f',
)
clamp_min_slider = ipy.FloatSlider(
    value=0.43,
    min=0.00,
    max=2.00,
    step=0.01,
    description='clamp_min',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.2f',
)
clamp_max_slider = ipy.FloatSlider(
    value=1.90,
    min=0.00,
    max=4.00,
    step=0.01,
    description='clamp_max',
    disabled=False,
    continuous_update=False,
    orientation='vertical',
    readout=True,
    readout_format='.2f',
)
px_pf_slider = ipy.IntSlider(
    value=1,
    min=1,
    max=10,
    step=1,
    description='Movement speed',
    disabled=False,
    continuous_update=True,
    orientation='Horizontal',
    readout=True,
    readout_format='d'
)

sliders = ipy.HBox([noise_slider,lr_slider,decay_slider,cutn_slider])

frame_txt = ipy.BoundedIntText(
    value=0,
    min=0,
    max=999999999999,
    step=1,
    description='Frame',
    disabled=False
)
frame_chk = ipy.Checkbox(
    value=False,
    description='Use frame',
    disabled=False,
    indent=False
)
paint_chk = ipy.Checkbox(
    value=False,
    description='Set mask',
    disabled=False,
    indent=False
)

reset_chk = ipy.Checkbox(
    value=False,
    description='Remove mask',
    disabled=False,
    indent=False
)
frame_h = ipy.HBox([frame_chk,frame_txt,paint_chk,reset_chk])
interval_txt = ipy.BoundedIntText(
    value= interval,
    min=0,
    max=5000,
    step=1,
    description='Interval',
    disabled=False
)
burnin_slider = ipy.IntSlider(
    value= state["burnin"],
    min=1,
    max=10,
    step=1,
    description='Burnin',
    disabled=False,
    continuous_update=True,
    orientation='Horizontal',
    readout=True,
    readout_format='d'
)
slerp_slider = ipy.FloatSlider(
    value=0.35,
    min=0.00,
    max=1.00,
    step=0.01,
    description='slerp',
    disabled=False,
    continuous_update=False,
    orientation='Horizontal',
    readout=True,
    readout_format='.2f',
)

frame_controls = ipy.HBox([interval_txt,ipy.VBox([burnin_slider, slerp_slider])])
v = ipy.VBox(children=[frame_h,frame_controls])
options=['off', 'warp','zoom_in', 'zoom_out', 'pan_left', 'pan_right','pan_up','pan_down','rotate']
cam_dd = ipy.Dropdown(
    options=options,
    value=args.movement1,
    description='Move1',
    disabled=False
)
cam_dd_2 = ipy.Dropdown(
    options=options,
    value=args.movement2,
    description='Move2',
    disabled=False
)
px_pf_slider = ipy.IntSlider(
    value=args.speed, #originally 1
    min=1,
    max=30,
    step=1,
    description='speed1',
    disabled=False,
    continuous_update=True,
    orientation='Horizontal',
    readout=True,
    readout_format='d'
)
px_pf_slider_2 = ipy.IntSlider(
    value=1,
    min=1,
    max=30,
    step=1,
    description='speed2',
    disabled=False,
    continuous_update=True,
    orientation='Horizontal',
    readout=True,
    readout_format='d'
)
rotate_chk = ipy.Checkbox(
    value=False,
    description='Rotate',
    disabled=False,
    indent=False
)
angle_txt = ipy.BoundedIntText(
    value=angle,
    min=0,
    max=360,
    step=1,
    description='Angle',
    disabled=False
)

rot = ipy.HBox([rotate_chk,angle_txt])


text_prompt_1 = ipy.Text(
    value = state["prompts"][0],
    placeholder='',
    description='Prompt 1',
    disabled=False
)
rnd_chk_1 = ipy.Checkbox(
    value=False,
    description='random',
    disabled=False,
    indent=False
)
text_prompt_2= ipy.Text(
    value= state["prompts"][1],
    placeholder='',
    description='Prompt 2',
    disabled=False
)
rnd_chk_2 = ipy.Checkbox(
    value=False,
    description='random',
    disabled=False,
    indent=False
)
text_topic= ipy.Text(
    value= state["prompts"][1],
    placeholder='',
    description='img topic',
    disabled=False
)
weight_1 = ipy.BoundedFloatText(
    value = state["weights"][0],
    min=-1.0,
    max=1.0,
    description='Weight1',
    disabled=False
)
weight_2 = ipy.BoundedFloatText(
    value = state["weights"][1],
    min=-1.0,
    max=1.0,
    description='Weight2',
    disabled=False
)

prompt1_h = ipy.HBox([text_prompt_1,weight_1,rnd_chk_1])
prompt2_h = ipy.HBox([text_prompt_2,weight_2,rnd_chk_2,text_topic])

console = ipy.Output()
console.layout.width='400px'
console.layout.height='200px'

outpic = ipy.Output()

left_pane = ipy.VBox([cam_dd,px_pf_slider,cam_dd_2,px_pf_slider_2,sliders])
center= ipy.HBox([outpic,left_pane])
interval_value = 20



"""#  interactive mode"""

#display(center,v)
#display(prompt1_h, prompt2_h,console)
changes = {}

def record(key,value):
  global state
  global changes
  if not key in state or state[key] != value:
    #print(key)
    state[key] = value
    changes[key] = value

record("noise",noise_slider.value)
record("slerp_val",slerp_slider.value)
record("burnin",burnin_slider.value)
record("lr",lr_slider.value)
record("decay",decay_slider.value)
record("cutn",cutn_slider.value)
record("moves",[cam_dd.value, cam_dd_2.value])
record("incs",[px_pf_slider.value,px_pf_slider_2.value])


"""
pw = []
if rnd_chk_1.value:
  pw = get_random_words()
  text_prompt_1.value = f'a very detailed high-definition image of {pw[0]} {pw[1]} in {pw[2]} of {pw[3]}' 
if rnd_chk_2.value:
  if rnd_chk_1.value:
    text_topic.value = pw[1]
  #!wget -q https://loremflickr.com/{width}/{height}/{text_topic.value} -O /content/target.jpg
  text_prompt_2.value = '/content/target.jpg'
"""


#record("prompts",[text_prompt_1.value,text_prompt_2.value])
#record("weights",[weight_1.value,weight_2.value])

text_prompt_1.value = args.prompt
record("prompts",[text_prompt_1.value])
record("weights",[1])

interval = interval_txt.value
it = 0
total_count = interval * state["burnin"]
for g in optimizer.param_groups:
  g['weight_decay'] = state["decay"]
  g['lr'] = state["lr"]

console.clear_output()
with console: # don't print index since it's always 0 in state var
  pprint({x: state[x] for x in state if x != "index"})

if frame_chk.value:
  frame = frame_txt.value
  edit(frame)

if paint_chk.value:
  inpaint = True
  set_paint_area()   

if reset_chk.value:
  reset_paint_area()
  inpaint = False  

if not firstrun:
  if frame_count == 0:
     gs["states"].append(copy.deepcopy(state))
  elif len(changes) > 0:
    changes["index"] = frame_count
    gs["states"].append(copy.deepcopy(changes))
  
def hallucinate():
  t = encode_prompts()
  global count
  start=count
  
  while(True):
    global it
    train(t)  
    count += 1  
    it += 1
    if count > 0 and it >= total_count:
      make_video(start) 
      break
  with console:    
    print(f"count {count} images :{len(images)}")  

video = f"{save_path}/video.mp4"
video_ok=False   

def make_video(start):
  start_number = max(frame_count-preview_frames,0)
  
  global video_ok
  drawtxt = "drawtext=text='%{eif\:n+"+ str(start_number) +"\:d}':x=10:y=10:fontsize=50:box=1"
  ret = subprocess.call([
                         "ffmpeg",
                         "-start_number",
                         f"{start_number:05}",
                         "-y",
                         "-i", 
                         f"{save_path}/%05d.jpg",
                         "-vf",
                         drawtxt,
                         "-c:a",
                         "copy", 
                         video
                        ])
  if ret == 0:
    video_ok=True

outpic.clear_output()  
 
frame_chk.value = False
paint_chk.value = False
reset_chk.value = False
rnd_chk_1.value = False
rnd_chk_2.value = False

if not firstrun:
  hallucinate()
  outpic.clear_output()
  with outpic:
    HTML(get_html_video(video)) if video_ok else print("Sorry! Couldn't make video.")
else:
  with outpic:
    print("Welcome to my hallucination")

firstrun = False

def clean():
  global lats 
  global count
  global images
  global firstrun
  global inpaint
  global frame_count
  global losses
  global gs
  global state
  global changes
  frame_count = 0
  print(count, len(images))  
  count = 0
  rotate = False
  angle = 0
  losses = [] 
  gs["states"] = []
  init_state()
  interval = 20
  changes = {}
  firstrun = True
  cam_dd.value = 'off'
  cam_movement = 'off'
  inpaint = False
  images = []
  init(img2t(gs["settings"]["img_gen"]))
  #!rm {save_path}/*.jpg
  print(count, len(images))  
  gc.collect()
  torch.cuda.empty_cache()

"""# automatic mode"""

#display(outpic,console)

#states = xsh["states"]
idx = 0
count = 0

sys.stdout.write('Starting ...\n')
sys.stdout.flush()


def hallucinate():
  itt = 1
  global count
  t = encode_prompts()
  #while(True):
  for i in range(args.iterations): 
    sys.stdout.write("Iteration {}".format(itt)+"\n")
    sys.stdout.flush()
    train(t)  
    if itt % args.update == 0:
      checkin()
    count += 1
    itt += 1
    
    #if frame_count >= change_frame:
    #  break
  #with console:    
  #  print(f"count {count} images :{len(images)}")  


"""
def set_state(changes):
  global state
  for key in changes.keys():
    if not key in state or state[key] != changes[key]:
      state[key] = changes[key]

while(idx < len(states)):
  #global state
  set_state(states[idx])
  console.clear_output()
  #with console:
  #  pprint(state)
  change_frame = states[idx+1]["index"] if idx+1 < len(states) else gs["settings"]["last_frame"]  
  hallucinate()
  idx += 1
"""


#change_frame = states[idx+1]["index"] if idx+1 < len(states) else gs["settings"]["last_frame"]  
hallucinate()
 

#utils, misc




#graph losses
#plt.plot(losses)

#reset global state
clean()


"""# RIFE interpolation"""

"""
# Commented out IPython magic to ensure Python compatibility.
!git clone https://github.com/hzwer/arXiv2020-RIFE
!gdown --id 1wsQIhHZ3Eg4_AfCXItFKqqyDMB4NS0Yd
!7z e RIFE_trained_model_HDv2.zip
!mkdir /content/arXiv2020-RIFE/train_log
!mv *.pkl /content/arXiv2020-RIFE/train_log/
# %cd /content/arXiv2020-RIFE/
!gdown --id 1i3xlKb7ax7Y70khcTcuePi6E7crO_dFc
!pip3 install -r requirements.txt

# Commented out IPython magic to ensure Python compatibility.
# %cd /content/arXiv2020-RIFE/
!python3 inference_video.py --exp=2 --video={video} --fps=80

!cp /content/frames/render_4X_80fps.mp4 /content/drive/MyDrive/

"""