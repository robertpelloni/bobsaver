# Zoetrope 5
# Original file is located at https://colab.research.google.com/drive/1LpEbICv1mmta7Qqic1IcRTsRsq7UKRHM

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import random
from datetime import datetime
import torch
import torch_optimizer as optim
import numpy as np
import noise
import torchvision
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import kornia
import PIL
from PIL import Image, ImageSequence
import os
import random
import imageio
from CLIP.clip import clip

sys.path.append('./taming-transformers')

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--scaler', type=int, help='Scaler')
  parser.add_argument('--cutpower', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--hotgritsstyleloss', type=bool, help='Hotgrits style loss.')
  parser.add_argument('--softhistogram', type=bool, help='Soft histogram.')
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










#@markdown Input your text prompt here and assign it a weight. text_input and text_to_add are two separate prompts with separate weights (w0 and w1). prompt_timer adds a delay on adding the prompt.
text_input = args.prompt #"a beautiful waluigi" #@param {type:"string"}
w0 = 1 #@param {type:"slider", min:-5, max:5, step:0.1}
prompt_timer_text = 0 #@param {type:"integer", min: 0}
#@markdown <br>
text_to_add = "" #@param {type:"string"}
w1 = 0.3 #@param {type:"slider", min:-5, max:5, step:0.1}
prompt_timer_text_to_add = 0 #@param {type:"integer", min: 0}

#@markdown Enable an initial image after uploading to the file structure. Format "image.jpg"
#default_path = '/content/'
default_path = '.'

if args.seed_image==None:
    init_image_path = "."
    init_type = "perlin" #@param ["image", "blocky", "perlin", "constant", "default"] {type:"string"}
else:
    init_image_path = args.seed_image
    init_type = "image" #@param ["image", "blocky", "perlin", "constant", "default"] {type:"string"}

extra_fuzz_strength = 0.3 #@param {type:"slider", min:0, max:1, step:0.01}
grayscale_fuzz = True #@param {type:"boolean"}
init_val = 0.5 #@param {type:"slider", min:0, max:1, step:0.01}
# These alter the starting noise generated for your prompt.
# They are overridden if init_image is checked.
# blocky_random = False # default False
grayscale_random = False #@param {type:"boolean"}
random_size = 2048 #@param {type:"slider", min:2, max:2048, step:1}
perlin_scale = 1 #@param {type:"slider", min:0.1, max:100, step:0.1}
perlin_strength = 0.5 #@param {type:"slider", min:0, max:2, step:0.01}
#How many octaves to use?
perlin_octaves =  9#@param {type:"integer", min: 1}
# How much to decay each octave? (higher = more high freq noise)
perlin_persistence = 0.65 #@param {type:"slider", min:0.1, max:2, step:0.1}
#How mucch to scale each octave
perlin_lacunarity = 2  #@param {type:"slider", min:0.1, max:5, step:0.1}

# init_image = False #@param {type:"boolean"}
#@markdown Enter a comma-space (", ") separated list of image locations as "image.jpg, image2.jpg, image3.jpg" to use image-based prompting.
#@markdown Average mode splits the weight along the images, Stack mode assigns each image the indicated weight.
#@markdown Valid filetypes are .jpg and .png. <br>
#@markdown random_list_encode picks that many images from the list at a time and randomly uses them per epoch.
img_enc_path = "" #@param {type:"string"}
w2 = 0.7 #@param {type:"slider", min:-5, max:5, step:0.1}
img_mode = 'Average' #@param ["Average", "Stack"] {type:"string"}
prompt_timer_img = 0 #@param {type:"integer", min: 0}
random_list_encode =  0#@param {type:"integer", min: 0}
#@markdown <br>
ne_img_enc_path = "" #@param {type:"string"}
w3 = 0 #@param {type:"slider", min:-5, max:5, step:0.1}
ne_img_mode = 'Average' #@param ["Average", "Stack"] {type:"string"}
prompt_timer_ne_img =  0#@param {type:"integer", min: 0}
ne_random_list_encode =  0#@param {type:"integer", min: 0}
#@markdown Enter up to two gifs/mp4s if desired, in each path
gif_img_enc_path = "" #@param {type:"string"}
w4 = 0 #@param {type:"slider", min:-5, max:5, step:0.1}
prompt_timer_gif =  0#@param {type:"integer", min: 0}
#@markdown <br>
gif2_img_enc_path = "" #@param {type:"string"}
w5 = 0 #@param {type:"slider", min:-5, max:5, step:0.1}
prompt_timer_gif2 =  0#@param {type:"integer", min: 0}

channels = 3
#x and y need to be swapped as they get reversed somewhere else in this script
sideX = args.sizey
sideY = args.sizex

im_shape = [sideX, sideY, channels]
#print(im_shape)

batch_size = 1 #@param {type:"slider",min:1, max:16, step:1}

#@markdown #Generation Options:
#@markdown **Learning Schedule**
learning_rate =  3#@param {type:"number"}
min_learning_rate =  0.1#@param {type:"number"}
learning_method = "BOIL" #@param ["DEFAULT", "BOIL", "SEAR", "RANDOM"] {type:"string"}
decay =  0.005#@param {type:"number"}
epsilon =  0#@param {type:"number"}
optimizer_type = "RAdam" #@param ["AdamW", "Ranger21", "AccSGD","AdaBound","AdaMod","Adafactor","AdamP","AggMo","DiffGrad","Lamb","NovoGrad","PID","QHAdam","QHM","RAdam","SGDP","SGDW","Shampoo","SWATS","Yogi"] {type:"string"}
#@markdown Use Lookahead will enable an additional optimizer that attempts to "look ahead" for further image optimization.
use_lookahead = False #@param {type:"boolean"}
#@markdown **Output Options**<br>
#@markdown learning_epochs is the number of times the training loop runs for total_iterations steps. After that many steps, it will reset itself and begin generating from scratch again.
total_iterations =  100#@param {type:"integer"}

optim_cfg = {
              "optimizer_type" : optimizer_type,
              "learning_rate" : learning_rate,
              "min_learning_rate" : min_learning_rate,
              "learning_method": learning_method,
              "decay" : decay,
              "iterations" : total_iterations,
              "use_lookahead" : use_lookahead,
              "epsilon" : epsilon
}
optim_chain = [[optim_cfg]]

learning_epochs = 1#@param {type: "integer"}
save_rate =  args.update#@param {type:"integer"}
display_rate =  args.iterations#@param {type:"integer"}
single_display = False #@param {type:"boolean"}
auto_video = False #@param {type:"boolean"}
out_folder = 'l25v_output' #@param{type:"string"}
# If you need to create the folder:

#@markdown #Augmentation Options:
#@markdown Random rotation degrees
deg = 15 #@param {type:"slider", min:0, max:90, step:1}
#@markdown Mirroring Probabilities
horizontal = 0.1 #@param {type:"slider", min:0.0, max:0.5,step:0.01}
vertical = 0.02 #@param {type:"slider", min:0.0, max:0.5,step:0.01}
#@markdown Augmentation Noise
random_noise = 0 #@param {type:"slider", min:0.0, max:5, step:0.01}
random_erasing = 0 #@param {type:"slider", min:0.0, max:1, step:0.01}
blur_probability = 0.5 #@param {type:"slider", min:0.0, max:1, step:0.01}
#@markdown Augmentations Per Iteration
cutN =   args.cutn#@param {type:"integer", min: 1}
#@markdown Sharpness filter settings (experimental)
sharpen_pre_augment = False #@param {type:"boolean"}
sharpen_post_augment = False #@param {type:"boolean"}
sharpen_every =   1#@param {type:"integer", min: 0}
#@markdown Latent vector augmentation settings (experimental)
lats_nonlinearity = "tanh" #@param ["clip", "tanh", "none"] {type:"string"}
lats_noise =  0 #@param {type:"slider", min:0.0, max:0.1, step:0.001}
lats_scale = 8 #@param {type:"slider", min:1, max:10, step:0.1}

"""# Advanced Params"""


#Advanced Text Prompts
# Every prefix, main prompt, and suffix is multiplied together.
# Example:
# prefixes = ["painting", "photograph"]
# prompt_main = ["of a forest"]
# suffixes = ["by zdzislaw beksinski", ""]
# final results are "painting of a forest by zdzislaw beksinski",
# "photograph of a forest by zdzislaw beksinski", "painting of a forest",
# and "photograph of a forest".
# Advanced text prompts are treated as if they have a weight of 1 for now.
advanced_text_enabled = False #Set to true if you want to use advanced text prompts
prompt_timer_advanced_text = 0
prefixes       = [""]
prompt_main    = [""]
infixes        = [""]
suffixes       = [""]
prompt = []
for i in range(len(prefixes)):
    for j in range(len(prompt_main)):
        for k in range(len(infixes)):
            for l in range(len(suffixes)):
              prompt_merge = prefixes[i] + " " + prompt_main[j] + " " + infixes[k] + " " + suffixes[l]
              prompt.append(prompt_merge)

#text_not
# text_not is a list of stuff that the system attempts to remove from your images
# The default list is '''incoherent, confusing, cropped, watermarks, text, writing'''
# Alter if desired!
text_not = '''incoherent, confusing, cropped, watermarks, text, writing'''

#Warmup & Boil Period
# Computes the required multiplier so that a warmup/boil learning rate reaches
# a rate of multiplying by (mult) every x steps. 
warmup_mult = 2 # 2 = Double the learning rate...
warmup_period = 300 # Every 200 steps.
warmup_amt = warmup_mult**(1/warmup_period)
boil_mult = 0.5 # 0.5 = Halve the learning rate...
boil_period = 100 # Every 100 steps.
boil_amt = boil_mult**(1/boil_period)
#print(warmup_amt)
#print(boil_amt)

#Blue Noise
# Blue Noise is a finer grain form of noise applied as an augmentation.
blue_noise_intensity = 0.05 # default 0.05
blue_noise_percentage = 0.5 # default 1

#Experimental Parameters - possibly buggy! Handle with care!

#Scaler
# It's sort of like zooming out. Unpredictable effects. Play around with it!
# Warning: will fuck up human faces.
# Cannot be used with sharpening.
scaler = args.scaler

#Hotgrits Style Loss
# Uses a different loss function. Play around with it!
use_hotgrits_style_loss = args.hotgritsstyleloss

#Soft Histogram
# It makes a histogram of pixel data to arrange the image by. Play around with it!
use_softhistogram = args.softhistogram

#Chain & Parallel Optimization
# Chains together multiple optimizers, feeding the output of each into the next.
# Enabling this overrides the settings selected in the "params" section
# The optimizer chain is a list of lists.
# If chain_optim is true, it iterates through everything in the list-list one-by-one
# if parallel_optim is true, then it runs every optimizer in a single list at once,
# THEN moves onto the next element in the list-list.
# parallel_optim does nothing without chain_optim also being enabled.
chain_optim = True
if chain_optim:
    optim_chain = [
        [{
            "optimizer_type": "AdamW",
            "learning_rate": 0.02, # originally 0.02
            "min_learning_rate": 0.01, # originally 0.01
            "learning_method": "BOIL",
            "decay": 0.1,
            "iterations": args.iterations // 4,
            "use_lookahead": False,
         },{
            "optimizer_type": "RAdam",
            "learning_rate": 0.01, # originally 0.01
            "min_learning_rate": 0.005, # originally 0.005
            "learning_method": "BOIL",
            "decay": 0.005,
            "iterations": args.iterations // 4,
            "use_lookahead": False,
         }],
         [{
            "optimizer_type" : "Yogi",
            "learning_rate" : 5, # originally 10
            "min_learning_rate" : 5, # originally 10
            "learning_method": "DEFAULT",
            "decay" : 0,
            "epsilon" : 1e-6,
            "iterations": args.iterations // 4,
            "use_lookahead" : True
          }],
          [{
            "optimizer_type" : "RAdam",
            "learning_rate" : 2, # originally 4
            "min_learning_rate" : 1, # originally 1
            "learning_method": "BOIL",
            "decay" : 0.005,
            "epsilon" : 1e-6,
            "iterations": args.iterations // 4,
            "use_lookahead" : True
          }],[{
            "optimizer_type" : "Yogi",
            "learning_rate" : 20, # originally 40
            "min_learning_rate" : 20, # originally 40
            "learning_method": "DEFAULT",
            "decay" : 0,
            "epsilon" : 1e-8,
            "iterations": args.iterations - (args.iterations // 4)*3 ,
            "use_lookahead" : False
          }]
    ]


file_to_transfer = 'image.jpg' # .jpg, .gif, or .mp4s accepted
file_to_transfer = default_path + file_to_transfer

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()


clip_model = args.clip_model
perceptor_size = 224 if clip_model == 'ViT-B/32' else 288

perceptor, preprocess = clip.load(clip_model, jit=False)
_ = perceptor.eval().requires_grad_(False)

if clip_model == 'ViT-B/32' and scaler != 1:
  num = 1 + int(scaler*7)**2
  perceptor.visual.positional_embedding = torch.nn.Parameter(torch.nn.functional.upsample(perceptor.visual.positional_embedding.T.unsqueeze(0), (num), mode='linear', align_corners=True).squeeze(0).T)
  perceptor_size = int(perceptor_size * scaler)
else:
  scaler = 1

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', device)
print(torch.cuda.get_device_properties(device))
DEVICE = device


import yaml
import torch
from omegaconf import OmegaConf
from taming.models import vqgan 
from taming.models.vqgan import VQModel, GumbelVQ

def load_config(config_path):
  config = OmegaConf.load(config_path)
  return config

def load_vqgan(config, ckpt_path=None):
  model = VQModel(**config.model.params)
  if ckpt_path is not None:
    sd = torch.load(ckpt_path, map_location="cpu")["state_dict"]
    missing, unexpected = model.load_state_dict(sd, strict=False)
  return model.eval()

def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = vqgan.VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.vqgan.GumbelVQ':
        model = vqgan.GumbelVQ(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.vqgan.rudalle':
        model = vqgan.GumbelVQ(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.eval().requires_grad_(False)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    del model.loss
    return model

sys.stdout.write("Loading VQGAN model "+args.vqgan_model+"...\n")
sys.stdout.flush()

if args.vqgan_model == "gumbel_f8-8192":
    vqgan_config = load_config("gumbel_f8-8192.yaml");
    vqgan_model = load_vqgan_model("gumbel_f8-8192.yaml","gumbel_f8-8192.ckpt").to(DEVICE)
elif args.vqgan_model == "rudalle":
    vqgan_config = load_config("rudalle.yaml");
    vqgan_model = load_vqgan_model("rudalle.yaml","rudalle.ckpt").to(DEVICE)
else:
    vqgan_config = load_config(args.vqgan_model+'.yaml')
    vqgan_model = load_vqgan(vqgan_config, ckpt_path=args.vqgan_model+'.ckpt').to(DEVICE)


def perlin(x,y,seed=0):
    # permutation table
    np.random.seed(seed)
    p = np.arange(256,dtype=int)
    np.random.shuffle(p)
    p = np.stack([p,p]).flatten()
    # coordinates of the top-left
    xi = x.astype(int)
    yi = y.astype(int)
    # internal coordinates
    xf = x - xi
    yf = y - yi
    # fade factors
    u = fade(xf)
    v = fade(yf)
    # noise components
    n00 = gradient(p[p[xi]+yi],xf,yf)
    n01 = gradient(p[p[xi]+yi+1],xf,yf-1)
    n11 = gradient(p[p[xi+1]+yi+1],xf-1,yf-1)
    n10 = gradient(p[p[xi+1]+yi],xf-1,yf)
    # combine noises
    x1 = lerp(n00,n10,u)
    x2 = lerp(n01,n11,u) # FIX1: I was using n10 instead of n01
    return lerp(x1,x2,v) # FIX2: I also had to reverse x1 and x2 here

def lerp(a,b,x):
    "linear interpolation"
    return a + x * (b-a)

def fade(t):
    "6t^5 - 15t^4 + 10t^3"
    return 6 * t**5 - 15 * t**4 + 10 * t**3

def gradient(h,x,y):
    "grad converts h to the right gradient vector and return the dot product with (x,y)"
    vectors = np.array([[0,1],[0,-1],[1,0],[-1,0]])
    g = vectors[h%4]
    return g[:,:,0] * x + g[:,:,1] * y

from torchvision.transforms.transforms import RandomGrayscale

class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()

        if init_type == "image":
          x = (torch.nn.functional.interpolate(torch.tensor(imageio.imread(init_image_path)).unsqueeze(0).permute(0, 3, 1, 2), (sideX, sideY)) / 255).cuda()
          x = 2. * x - 1.
        elif init_type == "blocky":
            if grayscale_random:
                x = torch.zeros(batch_size, 1, random_size, random_size, device=DEVICE).normal_(mean=.3, std=.7).clamp(-1, 1).expand(-1, 3, -1, -1)
            else:
                x = torch.rand(batch_size, 3, random_size, random_size, device=DEVICE).normal_(mean=.3, std=.7).clamp(-1, 1)
            x = T.Resize((sideX, sideY))(x)
        elif init_type == "perlin":
            x = np.zeros((batch_size, 3, sideX, sideY))
            n_channels = 3
            octave_strength = 1
            octave_scale = perlin_scale
            for i in range(perlin_octaves):
              # pnoise = PerlinNoise(octaves=octave)
              for batch_i in range(batch_size):
                seed_rand = int(random.random() * 1e6)
                for c_i in range(n_channels):
                    if grayscale_random:
                      seed = seed_rand
                    else:
                      seed = c_i + seed_rand
                
                    xlin = np.linspace(0,octave_scale,sideX, endpoint=False)
                    ylin = np.linspace(0,octave_scale,sideY, endpoint=False)
                    xlin,ylin = np.meshgrid(ylin,xlin)
                    x[batch_i, c_i, :, :] += octave_strength * perlin(xlin,ylin,seed=seed)
              octave_strength *= perlin_persistence
              octave_scale *= perlin_lacunarity

            x = torch.tensor(x, dtype=torch.float32, device=DEVICE)
            x -= x.min()
            x /= x.max()
            x = x * 2 - 1
            x *= perlin_strength
        elif init_type == "constant":
            x = torch.full((batch_size, 3, sideX, sideY), init_val, dtype=torch.float32, device=DEVICE)
        else:
            self.normu = .5 * torch.randn(batch_size, 256, sideX//16, sideY//16, device=DEVICE)
            self.normu = torch.nn.Parameter(torch.sinh(1.9 * torch.arcsinh(self.normu)))
        if grayscale_fuzz:
          extra_fuzz = torch.rand(batch_size, 1, sideX, sideY, device=DEVICE).normal_(mean=0, std=0.5).clip(-1,1).expand(-1, 3, -1, -1)
        else:
          extra_fuzz = torch.rand(batch_size, 3, sideX, sideY, device=DEVICE).normal_(mean=0, std=0.5).clip(-1,1)
        x += extra_fuzz * extra_fuzz_strength
        z, _, [_, _, indices] = vqgan_model.encode(x)
        self.normu = torch.nn.Parameter(z.cuda().clone())

    def forward(self):
      # TODO: Parameterize clipping / scaling values?
      lnoise = lats_noise * torch.randn_like(self.normu)
      lnoise -= torch.mean(lnoise)
      if lats_nonlinearity == "tanh":
        return torch.tanh((self.normu + lnoise) / lats_scale) * lats_scale
      elif lats_nonlinearity == "clip":
        return (self.normu + lnoise).clip(-lats_scale, lats_scale)
      else:
        return self.normu + lnoise
      
def model(x):
  o_i2 = x
  o_i3 = vqgan_model.post_quant_conv(o_i2)
  i = vqgan_model.decoder(o_i3)
  return i

class ClampWithGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input, min, max):
        ctx.min = min
        ctx.max = max
        ctx.save_for_backward(input)
        return input.clamp(min, max)

    @staticmethod
    def backward(ctx, grad_in):
        input, = ctx.saved_tensors
        return grad_in * (grad_in * (input - input.clamp(ctx.min, ctx.max)) >= 0), None, None

clamp_with_grad = ClampWithGrad.apply

def enc_augment(into):
    sideY, sideX = into.shape[2:4]
    max_size = min(sideX, sideY)
    min_size = min(sideX, sideY, perceptor_size)
    cutouts = []
    for ch in range(cutN):
        size = int(torch.rand([])**1 * (max_size - min_size) + min_size)
        offsetx = torch.randint(0, sideX - size + 1, ())
        offsety = torch.randint(0, sideY - size + 1, ())
        cutout = into[:, :, offsety:offsety + size, offsetx:offsetx + size]
        cutouts.append(torch.nn.functional.interpolate(cutout, (perceptor_size, perceptor_size), mode='bilinear', align_corners=True))
        del cutout
    cutouts = torch.cat(cutouts, dim=0)
    cutouts = clamp_with_grad(cutouts, 0, 1)
    return cutouts

sharpness = torch.zeros((1,1,sideX//16,sideY//16)).float().to(DEVICE).requires_grad_(True)

t = 0
t_list = []
textList = []
if w0 != 0:
  if text_input != '':
    textList = text_input.split(" | ")
    for i in textList:
      t = 0
      #print(i)
      tx = clip.tokenize(i)
      t = perceptor.encode_text(tx.cuda()).detach().clone()
      t_list.append(t)
      t = 0
textList.reverse()
t_list.reverse()

if len(t_list) > 1:
  learning_epochs = len(t_list)


text_add = 0
if text_to_add != '':
  text_add = clip.tokenize(text_to_add)
  text_add = perceptor.encode_text(text_add.cuda()).detach().clone()

t_not = clip.tokenize(text_not)
t_not = perceptor.encode_text(t_not.cuda()).detach().clone()

advanced_t = 0
if advanced_text_enabled:
  advanced_t = perceptor.encode_text(clip.tokenize(prompt).cuda()).mean(0).unsqueeze(0).detach().clone()

nom = torchvision.transforms.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

img_enc_list = []
if w2 != 0:
  if img_enc_path != '':
    imgList = img_enc_path.split(", ")
    for i in imgList:
      img_enc = 0
      i = default_path + i
      #print(i)
      image = imageio.imread(i)
      if image.shape[-3] == 4:
        image = image[:,:3]
      if len(image.shape) != 3: 
        image = image.unsqueeze(0).tile(3,1,1)
      img_enc = (torch.nn.functional.interpolate(torch.tensor(image).unsqueeze(0).permute(0, 3, 1, 2), (perceptor_size, perceptor_size)) / 255).cuda()[:,:3]
      img_enc = enc_augment(img_enc)
      img_enc = nom(img_enc)
      img_enc = perceptor.encode_image(img_enc.cuda()).detach().clone()
      if img_mode == 'Average':
        if random_list_encode > 0 and random_list_encode < len(imgList):
          img_enc /= random_list_encode
        else:
          img_enc /= len(imgList)
      img_enc_list.append(img_enc)
      img_enc = 0
random.shuffle(img_enc_list)

ne_img_enc_list = []
if w3 != 0:
  if ne_img_enc_path != '':
    imgList = ne_img_enc_path.split(", ")
    for i in imgList:
      ne_img_enc = 0
      image = imageio.imread(i)
      if image.shape[-3] == 4:
        image = image[:,:3]
      if len(image.shape) != 3: 
        image = image.unsqueeze(0).tile(3,1,1)
      ne_img_enc = (torch.nn.functional.interpolate(torch.tensor(image).unsqueeze(0).permute(0, 3, 1, 2), (perceptor_size, perceptor_size)) / 255).cuda()[:,:3]
      ne_img_enc = enc_augment(ne_img_enc)
      ne_img_enc = nom(ne_img_enc)
      ne_img_enc = perceptor.encode_image(ne_img_enc.cuda()).detach().clone()
      if ne_img_mode == 'Average':
        if ne_random_list_encode > 0 and ne_random_list_encode < len(imgList):
          ne_img_enc /= ne_random_list_encode
        else:
          ne_img_enc /= len(imgList)
      ne_img_enc_list.append(ne_img_enc)
      ne_img_enc = 0
random.shuffle(ne_img_enc_list)

gif_img_enc = 0
gifStore = 0
gif2_img_enc = 0
gifStore = 0

cdeg = np.cos(deg * np.pi / 180)
sdeg = np.sin(deg * np.pi / 180)

size = perceptor_size #ViT size
ccrop = 2 * size #double the size for center crop
pad = int(np.ceil(2 * ccrop* abs(cdeg) * abs(sdeg)))
rcrop = int(np.ceil(ccrop * (abs(cdeg) + abs(sdeg)))) # random crop

if deg >= 45:
  pad = size
  rcrop = int(np.ceil(ccrop * np.sqrt(2)))
else:
  pad = int(np.ceil(ccrop * abs(cdeg * sdeg)))
  rcrop = int(np.ceil(ccrop * (abs(cdeg) + abs(sdeg)))) # random crop

pad += pad % 2
rcrop += rcrop % 2

padding = torch.nn.Sequential(torchvision.transforms.Pad(padding=pad, padding_mode='reflect')).cuda()

ToTensor = T.ToTensor()
ToImage  = T.ToPILImage()

def OpenImage(x, resize=None, convert="RGB"):
    if resize:
        return ToTensor(Image.open(x).convert(convert).resize(resize)).unsqueeze(0).cuda()
    else:
        return ToTensor(Image.open(x).convert(convert)).unsqueeze(0).cuda()

#!wget -q https://i.imgur.com/9smB3ey.png -O BlueNoise-Color-1024.png
bluenoise = OpenImage("BlueNoise-Color-1024.png").mul(2).sub(1)

def get_bluenoise(like):
    b, c, h, w = like.shape
    noise = T.RandomCrop((h,w))(bluenoise)
    return noise

def gaussian_sigma(x):
    return 0.3 * ((x - 1) * 0.5 - 1) + 0.8

augs = T.Compose([
   T.RandomCrop(rcrop,pad_if_needed = True, padding_mode = 'reflect'),
   T.RandomAffine(degrees=deg),
   T.CenterCrop(ccrop),
   T.RandomResizedCrop((size, size),scale=(size/ccrop,1.0),ratio=(1.0/1.0, 1.0/1.0), interpolation=3),
   T.RandomOrder([
      T.RandomHorizontalFlip(p=horizontal),
      T.RandomVerticalFlip(p=vertical),
      T.RandomErasing(p=random_erasing,value='random'),
      T.RandomApply(transforms=[T.Lambda(lambda x: x + get_bluenoise(x).mul(blue_noise_intensity))], p=blue_noise_percentage),
      T.RandomApply(transforms=[
                T.RandomChoice([
                    T.GaussianBlur( 3, (gaussian_sigma( 3)*0.75,gaussian_sigma( 3))),
                    T.GaussianBlur( 5, (gaussian_sigma( 5)*0.75,gaussian_sigma( 5))),
                    T.GaussianBlur( 7, (gaussian_sigma( 7)*0.75,gaussian_sigma( 7)))
                ])
            ], p=blur_probability)
      ])
])

jumbo_augs = T.Compose([
   T.RandomCrop(rcrop,pad_if_needed = True, padding_mode = 'reflect'),
   T.CenterCrop(ccrop),
   T.RandomResizedCrop((size, size),scale=(size/ccrop,1.0),ratio=(1.0/1.0, 1.0/1.0), interpolation=3)
])

itt = 0


import time
picked_img = []
picked_ne_img = []
current_epoch = 0


def simplest_cb(img, percent=1):
    out_channels = []
    cumstops = (
        img.shape[0] * img.shape[1] * percent / 200.0,
        img.shape[0] * img.shape[1] * (1 - percent / 200.0)
    )
    for channel in cv2.split(img):
        cumhist = np.cumsum(cv2.calcHist([channel], [0], None, [256], (0,256)))
        low_cut, high_cut = np.searchsorted(cumhist, cumstops)
        lut = np.concatenate((
            np.zeros(low_cut),
            np.around(np.linspace(0, 255, high_cut - low_cut + 1)),
            255 * np.ones(255 - high_cut)
        ))
        out_channels.append(cv2.LUT(channel, lut.astype('uint8')))
    return cv2.merge(out_channels)

def imageshuff():
  random.shuffle(img_enc_list)
  random.shuffle(ne_img_enc_list)
  picked_img.clear()
  picked_ne_img.clear()
  for i in range(random_list_encode):
    picked_img.append(img_enc_list[i])
  for i in range(ne_random_list_encode):
    picked_ne_img.append(ne_img_enc_list[i])

class SoftHistogram(torch.nn.Module):
    def __init__(self, bins, min, max, sigma):
        super(SoftHistogram, self).__init__()
        self.bins = bins
        self.min = min
        self.max = max
        self.sigma = sigma
        self.delta = float(max - min) / float(bins)
        self.centers = float(min) + self.delta * (torch.arange(bins).float() + 0.5)

    def forward(self, x):
        x = torch.unsqueeze(x, 0) - torch.unsqueeze(self.centers.to(DEVICE), 1)
        x = torch.sigmoid(self.sigma * (x + self.delta/2)) - torch.sigmoid(self.sigma * (x - self.delta/2))
        x = x.sum(dim=1)
        return x

SoftHist = SoftHistogram(bins=10, min=0, max=1, sigma=3)

def augment(into, cutn=cutN):
  into = padding(into)
  p_s = []
  p_s = [augs(into) for _ in range(cutn)]
  into = torch.cat(p_s,0)
  into += random_noise * torch.rand((into.shape[0], 1, 1, 1)).cuda() * torch.randn_like(into)
  return into

def displ(img, num=0):
    pil_img = T.ToPILImage()(img.squeeze())

    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()

    outim = pil_img.resize((args.sizex, args.sizey), Image.LANCZOS)
    outim.save(args.image_file, quality=95, subsampling=0)

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
        outim.save(save_name, quality=95, subsampling=0)



    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()

def checkin(loss):
    #if itt % save_rate == 0:
    if total_iters % save_rate == 0:
        with torch.no_grad():
            alnot = (model(lats()).detach().clip(-1, 1) + 1) / 2 #scaling?

            batch_num = 0
            for allls in alnot.detach():
                displ(allls, batch_num)
                batch_num += 1

def ascend_txt():
  out = model(lats())
  if sharpen_pre_augment:
    if itt % sharpen_every == 0:
      sharp_mask   = torchvision.transforms.functional.resize(sharpness,(sideX,sideY))
      highpass     = out - torchvision.transforms.functional.gaussian_blur(out, 3)
      out     = HardTanh(sharp_mask * highpass + out)
  into = augment((out.clip(-1, 1) + 1) / 2)
  if sharpen_post_augment:
    if itt % sharpen_every == 0:
      sharp_mask   = torchvision.transforms.functional.resize(sharpness,(perceptor_size,perceptor_size))
      highpass     = into - torchvision.transforms.functional.gaussian_blur(into, 3)
      into     = HardTanh(sharp_mask * highpass + into)
  into = nom(into)
  iii = perceptor.encode_image(into)

  q = 0
  if itt >= prompt_timer_text:
    if len(t_list) == 1:
      q += w0*t_list[0]
    elif len(t_list) > 1:
      q += w0*t_list[current_epoch]
  if itt >= prompt_timer_text_to_add:
    q += w1*text_add
  if itt >= prompt_timer_img:
    if picked_img:
      for i in picked_img:
        q += w2 * i
    else:
      for i in img_enc_list:
        q += w2 * i
  if itt >= prompt_timer_ne_img:
    if picked_ne_img:
      for i in picked_ne_img:
        q += w3 * i
    else:
      for i in ne_img_enc_list:
        q += w3 * i
  if itt >= prompt_timer_gif:
    q += w4*gif_img_enc
  if itt >= prompt_timer_gif2:
    q += w5*gif2_img_enc
  if advanced_text_enabled and itt >= prompt_timer_advanced_text:
    q += advanced_t
  q = q / q.norm(dim=-1, keepdim=True)


  main_weight = 10
  subtract_weight = 5
  if use_hotgrits_style_loss:
    q_sim = torch.cosine_similarity(q, iii, -1).mean()
    
    loss = main_weight * q_sim
    if subtract_weight:
        loss -= subtract_weight * torch.cosine_similarity(t_not, iii, -1).mean()
    if use_softhistogram:
        loss += (SoftHist(out.reshape(-1)) / (out.shape[-1] * out.shape[-2])).std()
        
    return 1 - loss
  else:
    q_sim = torch.cosine_similarity(q, iii, -1)
    grad1 = -main_weight * q_sim
    if subtract_weight:
        grad1 += subtract_weight * torch.cosine_similarity(t_not, iii, -1).mean()
    if use_softhistogram:
        grad1 -= (SoftHist(out.reshape(-1)) / (out.shape[-1] * out.shape[-2])).std()
    grad = [0, grad1]
    loss = grad[0] + grad[1]
    return loss.mean()

  #all_s = torch.cosine_similarity(q, iii, -1)
  #return [0, -10*all_s + 5 * torch.cosine_similarity(t_not, iii, -1)]

def HardTanh(x):
    x = x*2.0-1.0
    x = torch.tanh(x+x**5*.5)
    x = x*0.5+0.5
    return x

def train(optim_cfg):
  loss = ascend_txt()
  #loss = loss1[0] + loss1[1]
  #loss = loss.mean()
  optimizer.zero_grad()
  loss.backward()
  optimizer.step()

  #uncomment when playing with LR
  opt_0 = optimizer.param_groups[0]

  if optim_cfg["learning_method"] == "BOIL":
    if opt_0['lr'] > 2:
      opt_0['lr'] *= 0.994
    elif opt_0['lr'] <= 2:
      opt_0['lr'] *= 0.994 #0.8
  if optim_cfg["learning_method"] == "SEAR":
    if itt > 25:
      if opt_0['lr'] >= 1:
        opt_0['lr'] = 0.1
    else:
      if itt > 100:
        if opt_0['lr'] >= 0.1:
          opt_0['lr'] = 0.01
  if optim_cfg["learning_method"] == "RANDOM":
    opt_0['lr'] = ((random.random() + random.random()) / 2) + 0.1
    if itt < 20:
      opt_0['lr'] += (30 - itt)
    elif itt > 200:
      opt_0['lr'] *= (600/(itt + 400))
  opt_0['lr'] = max(opt_0['lr'], optim_cfg["min_learning_rate"])

  if torch.abs(lats()).max() > 5:
    for g in optimizer.param_groups:
      g['weight_decay'] = optim_cfg["decay"]
  else:
    for g in optimizer.param_groups:
      g['weight_decay'] = 0

  checkin(loss)

def loop(optim_cfg):
    global itt
    for i in tqdm(range(optim_cfg["iterations"])):
      try:
        train(optim_cfg)
        itt += 1
      except KeyboardInterrupt:
        pass

def get_optimizer(optim_cfg, mapper):
  optim_params = [{'params': mapper, 'lr': optim_cfg["learning_rate"]},{'params': sharpness, 'lr': 0.01}]
  if optim_cfg["optimizer_type"] == "AdamW":
    optimizer_tmp = torch.optim.AdamW(optim_params, weight_decay=optim_cfg["decay"])
  elif optim_cfg["optimizer_type"] == "Ranger21":
    optimizer_tmp = Ranger21(optim_params, learning_rate, weight_decay = optim_cfg["decay"], **ranger21_adv_opts)
  else:
    optimizer_tmp = getattr(optim, optim_cfg["optimizer_type"], None)(optim_params, weight_decay=optim_cfg["decay"])
  if optim_cfg["use_lookahead"]:
    optimizer_tmp = optim.Lookahead(optimizer_tmp)
  optimizer_tmp.zero_grad()
  if "epsilon" in optim_cfg and optim_cfg["epsilon"] != 0:
    optimizer_tmp.param_groups[0]['eps'] = optim_cfg["epsilon"]
  return optimizer_tmp

def train(optim_list):
  loss = ascend_txt()
  #loss = loss1[0] + loss1[1]
  #loss = loss.mean()
  for i in optimizers:
    i.zero_grad()
  loss.backward()
  for i in range(len(optimizers)):
    optimizers[i].step()
    opt_0 = optimizers[i].param_groups[0]
    if optim_cfg["learning_method"] == "BOIL":
      opt_0['lr'] *= boil_amt
    if optim_cfg["learning_method"] == "WARMUP":
      opt_0['lr'] *= warmup_amt
    if optim_cfg["learning_method"] == "SEAR":
      if itt > 25:
        if opt_0['lr'] >= 1:
          opt_0['lr'] = 0.1
      else:
        if itt > 100:
          if opt_0['lr'] >= 0.1:
            opt_0['lr'] = 0.01
    if optim_cfg["learning_method"] == "RANDOM":
      opt_0['lr'] = ((random.random() + random.random()) / 2) + 0.1
      if itt < 20:
        opt_0['lr'] += (30 - itt)
      elif itt > 200:
        opt_0['lr'] *= (600/(itt + 400))
    
    if "WARMUP" in optim_cfg["learning_method"]:
      opt_0['lr'] = min(opt_0['lr'], optim_cfg["min_learning_rate"])
    else:
      opt_0['lr'] = max(opt_0['lr'], optim_cfg["min_learning_rate"])

    if torch.abs(lats()).max() > 5:
      for g in optimizers[i].param_groups:
        g['weight_decay'] = optim_cfg["decay"]
    else:
      for g in optimizers[i].param_groups:
        g['weight_decay'] = 0

  checkin(loss)

def loop(optim_list):
    global itt
    global total_iters
    for i in range(maxits):
        sys.stdout.write(f'Iteration {total_iters}\n')
        sys.stdout.flush()
        train(optim_list)
        itt += 1
        total_iters += 1

def get_optimizer(optim_cfg, mapper):
  optim_params = [{'params': mapper, 'lr': optim_cfg["learning_rate"]},{'params': sharpness, 'lr': 0.01}]
  if optim_cfg["optimizer_type"] == "AdamW":
    optimizer_tmp = torch.optim.AdamW(optim_params, weight_decay=optim_cfg["decay"])
  elif optim_cfg["optimizer_type"] == "Ranger21":
    optimizer_tmp = Ranger21(optim_params, learning_rate, weight_decay = optim_cfg["decay"], **ranger21_adv_opts)
  else:
    optimizer_tmp = getattr(optim, optim_cfg["optimizer_type"], None)(optim_params, weight_decay=optim_cfg["decay"])
  if optim_cfg["use_lookahead"]:
    optimizer_tmp = optim.Lookahead(optimizer_tmp)
  optimizer_tmp.zero_grad()
  if "epsilon" in optim_cfg:
    optimizer_tmp.param_groups[0]['eps'] = optim_cfg["epsilon"]
  return optimizer_tmp

"""# Output"""

sys.stdout.write("Setting up optimizer ...\n")
sys.stdout.flush()

for i in range(learning_epochs):
  imageshuff()
  
  #sys.stdout.write(f'Epoch {i}\n')
  #sys.stdout.flush()
  # Reset the image vector
  lats = Pars().cuda()
  mapper = [lats.normu]
  
  total_iters=1

  sys.stdout.write("Starting ...\n")
  sys.stdout.flush()

  # Usually there will be only one optimizer chain step
  for optim_list in optim_chain:
    combo = ""
    maxits = 0
    for optim_cfg in optim_list:
      combo += optim_cfg["optimizer_type"] + " "
      if optim_cfg["iterations"] > maxits:
        maxits = optim_cfg["iterations"]
    sys.stdout.write("Optimizer changed to "+combo+"\n")
    sys.stdout.flush()
    #print(combo)
    optimizers = [get_optimizer(optim_cfg, mapper) for optim_cfg in optim_list]
    time.sleep(0.25)
    itt = 0
    loop(optim_list)
  
checkin(0)
