# CLIP + CPPN
# Original file is located at https://colab.research.google.com/drive/1ZBaqtW6yrhId546SjUUj2Ns-SKtIWGe_

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch.nn as nn
import numpy as np
import matplotlib.pyplot as plt
from numpy.core.numeric import False_
from torch._C import LongStorageBase
import sys, os, random, shutil, math
import torch, torchvision
from IPython import display
import numpy as np
from PIL import Image
from CLIP import clip
import torch_optimizer as optim
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--usern50', type=int, help='Use the RN50x16 model.')
  parser.add_argument('--usevit16', type=int, help='Use the ViT-B/16 model.')
  parser.add_argument('--usevit32', type=int, help='Use the ViT-B/32 model.')
  parser.add_argument('--upscaling', type=str, help='Upscaling method.')
  parser.add_argument('--initnoise', type=str, help='Initial noise type.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--update', type=int, help='Steps per update.')
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
    





def weights_init(m):
    classname = m.__class__.__name__
    if classname.find('Linear') != -1:
        nn.init.xavier_normal_(m.weight.data, gain=1)
        if m.bias is not None:
            m.bias.data.fill_(0)

class Residual(nn.Module):
  def __init__(self, c):
    super(Residual, self).__init__()
    self.blocks = nn.Linear(c, c)

  def forward(self, x):
    return x + self.blocks(x)

class CPPN(nn.Module):
  def __init__(self, cfg):
    super(CPPN, self).__init__()
    activation = cfg.get("activation", nn.Tanh)
    self.z_length = cfg.get("z_length", 0)
    self.num_channels = cfg.get("num_channels", 3)
    start_width = cfg.get("hidden_width_start", 128)
    midpoint, mid_width = cfg.get("hidden_width_center", (2, 128))
    end_width = cfg.get("hidden_width_end", 128)
    
    hidden_depth = cfg.get("hidden_depth", 5)
    self.input_dim = self.z_length + 3
    widths = []
    print(start_width, end_width, )
    widths = [start_width + (x * (mid_width - start_width)) // midpoint for x in range(midpoint)] + [mid_width] + \
             [mid_width + (x * (end_width - mid_width)) // (hidden_depth - midpoint-1)  for x in range(1, hidden_depth - midpoint)]
    print(widths)


    modules = [
              nn.Linear(self.input_dim, start_width),
              # nn.BatchNorm1d(start_width),
              activation()
    ]
    for b in range(hidden_depth-1):
        modules += [
                nn.Linear(widths[b], widths[b+1]),
                # nn.BatchNorm1d(widths[b+1]),
                activation()
        ]
    modules += [
              nn.Linear(end_width, 3),
              nn.Sigmoid()
    ]
    self.module_sequential = nn.Sequential(*modules)

    params = sum([np.prod(p.size()) for p in self.parameters()])
    # self.apply(weights_init)
    
  def forward(self, x):
    # x is of dims [width * height, 3 + z_length]
    # We process every pixel as a batch for efficiency
    # Each input contains [x, y, r, latent vector "z"]
    # x and y should be normalized between 0-1 probably? 
    # latent vector "z" should be the same for every pixel in a single image, if used
    return self.module_sequential(x)

def sample_cppn(cppn, n_batch, width, height, scale = None, angle = None, chip_c = None, z = None, debug=False):
  vecs = np.zeros((n_batch, width * height, 3 + cppn.z_length))
  for b in range(n_batch):
    if chip_c is None or b > 0:
      chip_c = np.random.random(2) * (1.0 - padding * 2) + padding - 0.5
    if scale is None or b > 0:
      scale = np.random.random() * (scale_max - scale_min) + scale_min
    if angle is None or b > 0: 
      angle = np.radians((np.random.random() * 2 - 1) * angle_max)
    if z is None or b > 0:
      z = np.random.random(cppn.z_length)
    # Construct pixel coord grid
    xscale = scale * width / max(width, height)
    yscale = scale * height / max(width, height)
    xcoords = np.linspace(-xscale, xscale, width)
    ycoords = np.linspace(-yscale, yscale, height)
    xcoords, ycoords = np.meshgrid(xcoords, ycoords)
    sin_a = math.sin(angle)
    cos_a = math.cos(angle)
    x = cos_a * xcoords - sin_a * ycoords + chip_c[0]
    y = sin_a * xcoords + cos_a * ycoords + chip_c[1]
    # x = x * aspect_ratio[0] / max(aspect_ratio)
    # y = y * aspect_ratio[1] / max(aspect_ratio)
    r = np.square(x) + np.square(y)
    if debug:
      print(x.min().item(), x.max().item())
      print(y.min().item(), y.max().item())
      print(r.min().item(), r.max().item())
      plt.scatter(x.flatten(), y.flatten(), s=1)
      plt.show()
    v = np.stack((y.flatten(), x.flatten(), r.flatten()), 1)
    z = np.tile(z, (width*height, 1))
    vecs[b,:,:] = np.concatenate((v, z), 1)

  vecs = torch.tensor(vecs, dtype=torch.float32).view(n_batch * width * height, -1).cuda()
  # Query the cppn
  image = cppn(vecs).view(n_batch, height, width, cppn.num_channels).moveaxis(3,1)
  
  return image

# Input prompts. Each prompt has "text" and a "weight"
# Weights can be negatives, useful for discouraging specific artifacts
texts = [
    {
        "text":  str(args.prompt),
        "weight": 1.0,
    }
]
"""
,{
    "text": "Beautiful and detailed fantasy painting.",
    "weight": 0.2,
# },{
# #     "text": "Full body.",
# #     "weight": 0.1,
},{ # Improves contrast, object coherence, and adds a nice depth of field effect
    "text": "Rendered in unreal engine, trending on artstation.",
    "weight": 0.2,
# },{
# #     "text": "speedpainting",
# #     "weight": 0.1,
# # },{ # Seems to improve contrast and overall image structure
#     "text": "matte painting, featured on artstation.",
#     "weight": 0.1,
# # },{
# #     "text": "Vivid Colors",
# #     "weight": 0.15,
# },{ # Doesn't seem to do much, but also doesn't seem to hurt. 
#     "text": "confusing, incoherent",
#     "weight": -0.25,
# # },{ # Helps reduce pixelation, but also smoothes images overall. Enable if you're using scaling = 'nearest'
# #     "text":"pixelated",
# #     "weight":-0.25
# },{ # Not really strong enough to remove all signatures... but I'm ok with small ones
#     "text":"text",
#     "weight":-0.5
}
"""


class nnsin(nn.Module):
  def __init__(self):
    super(nnsin, self).__init__()
  
  def forward(self, x):
    return torch.sin(x)

#TODO: test different configs
# Wider in the middle seems to be the best balance of width / depth
# SELU seems to have the least problem with exploding / vanishing gradients
cppn_config = {"z_length": 1, # Length of the z vector. Larger = more output variety, but also can confuse the model early
               "activation": nn.SELU,
               "hidden_width_start":16,
               "hidden_width_center":(4, 512), # (layer, width)
               "hidden_width_end":16,
               "hidden_depth":9
               }

#Image prompts
images = [
          # {
          #     "fpath": "hod.png",
          #     "weight": 0.2,
          #     "cuts": 16,
          #     "noise": 0.0
          # }
          ]

# random seed
# Set to None for random seed
# seed = args.seed

itt=0

scale_min = 0.9
scale_max = 1.1
angle_max = 1
padding = 0.45
# color_space =  "YCoCg" # "RGB"

# Number of times to run
images_n = 1

# AdamW is real basic and gets the job done
# RAdam seems to work *extremely well* but seems to introduce some color instability?, use 0.5x lr
# Yogi is just really blurry for some reason, use 5x + lr
# Ranger works great. use 3-4x LR
optimizer_type = "Ranger" # "AdamW", "AccSGD","Ranger","RangerQH","RangerVA","AdaBound","AdaMod","Adafactor","AdamP","AggMo","DiffGrad","Lamb","NovoGrad","PID","QHAdam","QHM","RAdam","SGDP","SGDW","Shampoo","SWATS","Yogi"

# TODO: pre-optimization pass to teach the model to generate the initial image first
initial_image = None

checkin_samples = 2

# Optimizer settings for different training steps
stages = [
        { #First stage does rough detail.
        "cuts": 2,
        "cycles": 500, #original was 1000
        "lr": 5e-3, #Radam use 1e-2, radam use 1e-4
        "decay": 0.0,
        "noise": 0.1,
        "denoise": 0.0,
        "checkin_interval": args.update
    }, { #First stage does rough detail.
        "cuts": 2,
        "cycles": 1500, #original was 10000!
        "lr": 5e-3, #Radam use 1e-2, radam use 1e-4
        "lr_decay": 0.9999,
        "decay": 0.0,
        "noise": 0.1,
        "denoise": 0.0,
        "checkin_interval": args.update
    }
]

display_size = (args.sizex, args.sizey)

debug_clip_cuts = True

torch.autograd.set_grad_enabled(False)
torch.backends.cudnn.benchmark = True
torch.set_default_tensor_type(torch.cuda.FloatTensor)

def normalize_image(image):
  R = (image[:,0:1] - 0.48145466) /  0.26862954
  G = (image[:,1:2] - 0.4578275) / 0.26130258 
  B = (image[:,2:3] - 0.40821073) / 0.27577711
  return torch.cat((R, G, B), dim=1)

@torch.no_grad()
def loadImage(filename):
  data = open(filename, "rb").read()
  image = torch.ops.image.decode_png(torch.as_tensor(bytearray(data)).cpu().to(torch.uint8), 3).cuda().to(torch.float32) / 255.0
  # image = normalize_image(image)
  return image.unsqueeze(0).cuda()


def getClipTokens(cppn, cuts, noise, do_checkin, perceptor):
    cut_data = sample_cppn(cppn, cuts, perceptor["size"], perceptor["size"])
    cut_data = normalize_image(cut_data)

    cut_data += noise * torch.randn_like(cut_data, requires_grad=False)

    #if debug_clip_cuts and do_checkin:
    #  displayImage(unnormalize_image(cut_data))

    clip_tokens = perceptor['model'].encode_image(cut_data)
    return clip_tokens


def loadPerceptor(name):
  sys.stdout.write("Loading "+name+" ...\n")
  sys.stdout.flush()

  model, preprocess = clip.load(name, device="cuda")

  tokens = []
  imgs = []
  for text in texts:
    tok = model.encode_text(clip.tokenize(text["text"]).cuda())
    tokens.append( tok )

  perceptor = {"model":model, "size": preprocess.transforms[0].size, "tokens": tokens, }
  for img in images:
    image = loadImage(img["fpath"])
    if resample_image_prompts:
      imgs.append(image)
    else:
      tokens = getClipTokens(image, img["cuts"], img["noise"], False, perceptor )
      imgs.append(tokens)
  perceptor["images"] = imgs
  return perceptor

perceptors = []
if args.usevit32 == 1:
    perceptors.append(loadPerceptor("ViT-B/32"))
if args.usevit16 == 1:
    perceptors.append(loadPerceptor("ViT-B/16"))
if args.usern50 == 1:
    perceptors.append(loadPerceptor("RN50x16"))


@torch.no_grad()
def saveImage(image, filename):
  # R = image[:,0:1] * 0.26862954 + 0.48145466
  # G = image[:,1:2] * 0.26130258 + 0.4578275
  # B = image[:,2:3] * 0.27577711 + 0.40821073
  # image = torch.cat((R, G, B), dim=1)
  size = image.size()

  image = (image[0].clamp(0, 1) * 255).to(torch.uint8)
  png_data = torch.ops.image.encode_png(image.cpu(), 6)
  open(filename, "wb").write(bytes(png_data))

# TODO: Use torchvision normalize / unnormalize
def unnormalize_image(image):
  
  R = image[:,0:1] * 0.26862954 + 0.48145466
  G = image[:,1:2] * 0.26130258 + 0.4578275
  B = image[:,2:3] * 0.27577711 + 0.40821073
  
  return torch.cat((R, G, B), dim=1)

@torch.no_grad()
def displayImage(image):
  size = image.size()

  width = size[0] * size[3] + (size[0]-1) * 4
  image_row = torch.zeros( size=(3, size[2], width), dtype=torch.uint8 )

  nw = 0
  for n in range(size[0]):
    image_row[:,:,nw:nw+size[3]] = (image[n,:].clamp(0, 1) * 255).to(torch.uint8)
    nw += size[3] + 4

  jpeg_data = torch.ops.image.encode_png(image_row.cpu(), 6)
  image = display.Image(bytes(jpeg_data))
  display.display( image )

def lossClip(cppn, cuts, noise, do_checkin):
  losses = []

  max_loss = 0.0
  for text in texts:
    max_loss += abs(text["weight"]) * len(perceptors)
  for img in images:
    max_loss += abs(img["weight"]) * len(perceptors)

  for perceptor in perceptors:
    clip_tokens = getClipTokens(cppn, cuts, noise, do_checkin, perceptor)
    for t, tokens in enumerate( perceptor["tokens"] ):
      similarity = torch.cosine_similarity(tokens, clip_tokens)
      weight = texts[t]["weight"]
      if weight > 0.0:
        loss = (1.0 - similarity) * weight
      else:
        loss = similarity * (-weight)
      losses.append(loss / max_loss)

    for img in images:
      for i, prompt_image in enumerate(perceptor["images"]):
        if resample_image_prompts:
          img_tokens = getClipTokens(prompt_image, images[i]["cuts"], images[i]["noise"], False, perceptor)
        else:
          img_tokens = prompt_image
        weight = images[i]["weight"] / float(images[i]["cuts"])
        for token in img_tokens:
          similarity = torch.cosine_similarity(token.unsqueeze(0), clip_tokens)
          if weight > 0.0:
            loss = (1.0 - similarity) * weight
          else:
            loss = similarity * (-weight)
          losses.append(loss / max_loss)
  return losses

def lossTV(image, strength):
  Y = (image[:,:,1:,:] - image[:,:,:-1,:]).abs().mean()
  X = (image[:,:,:,1:] - image[:,:,:,:-1]).abs().mean()
  loss = (X + Y) * 0.5 * strength
  return loss

def cycle(c, stage, optimizer, cppn):
  sys.stdout.write("Iteration {}".format(itt+1)+"\n")
  sys.stdout.flush()

  do_checkin = (c+1) % stage["checkin_interval"] == 0 or c == 0
  with torch.enable_grad():
    losses = []
    losses += lossClip( cppn, stage["cuts"], stage["noise"], do_checkin )
    # losses += [lossTV( image, stage["denoise"] )]

    loss_total = sum(losses).sum()
    optimizer.zero_grad(set_to_none=True)
    loss_total.backward(retain_graph=False)
    # if c <= warmup_its:
    #   optimizer.param_groups[0]["lr"] = stage["lr_luma"] * c / warmup_its
    #   optimizer.param_groups[1]["lr"] = stage["lr_chroma"] * c / warmup_its
    optimizer.step()
    if "lr_decay" in stage:
      for i in range(len(optimizer.param_groups)):
        optimizer.param_groups[i]["lr"] *= stage["lr_decay"]

  if do_checkin:
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    # TV = losses[-1].sum().item()
    #print( "Cycle:", str(stage["n"]) + ":" + str(c), "CLIP Loss:", loss_total.item(), "LR:", optimizer.param_groups[0]["lr"])
    # for name, param in cppn.named_parameters():
    #   print(name, param.min(), param.mean(), param.max())
    nimg = sample_cppn(cppn, checkin_samples, *display_size, 1, 0, [0.0, 0.0])
    #print(nimg.shape, nimg.min().item(), nimg.mean().item(), nimg.max().item())
    #displayImage(nimg)
    
    saveImage(nimg,args.image_file)
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
        saveImage(nimg,save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

    
cppn = CPPN(cppn_config).cuda()
def main():
  global itt
  
  params = [{"params": cppn.module_sequential.parameters(), "lr":stages[0]["lr"], "weight_decay":stages[0]["decay"]}]
  optimizer = getattr(optim, optimizer_type, None)(params)

  for n, stage in enumerate(stages):
    stage["n"] = n
    if n > 0: 
      for i in range(len(optimizer.param_groups)):
        optimizer.param_groups[i]["lr"] = stage["lr"]
        optimizer.param_groups[i]["decay"] = stage["decay"]

    for c in range(stage["cycles"]):
      cycle( c, stage, optimizer, cppn)
      itt+=1

for _ in range(images_n):
  main()

"""

# Regenerate latent vector
z_out = np.random.random(cppn.z_length)

width =  args.sizex #1000#@param {type:"integer"}
height =  args.sizey #1000#@param {type:"integer"}
x = 0 #@param {type:"slider", min:-1, max:1, step:0.1}
y = 0 #@param {type:"slider", min:-1, max:1, step:0.1}
scale = 1 #@param {type:"slider", min:0.1, max:2, step:0.1}
angle = 0 #@param {type:"slider", min:0, max:360, step:0.1}
angle = np.radians(angle)
image = sample_cppn(cppn, 1, width, height, scale, angle, np.array([x, y]), z_out)
#displayImage(image)

saveImage(image, "Progress.png")
"""