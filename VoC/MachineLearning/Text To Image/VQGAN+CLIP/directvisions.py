# Copy of DirectVisions.ipynb
# Original file is located at https://colab.research.google.com/drive/127lKSsQjx-UDDUSvIkLL6mREfZ0KQu5D

# Jens Goldberg / [Aransentin](https://https://twitter.com/aransentin)

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import sys, os, random, shutil, math
import torch, torchvision
from IPython import display
import numpy as np
from PIL import Image
from CLIP import clip
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
  parser.add_argument('--cutouts', type=int, help='Cutout count.')
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
    
    
"""    
texts = (
    {
        "text": str(args.prompt),
        "weight": 1.0
    },{ # Trying to reduce text
        "text":"text",
        "weight":-1.0
    }
)
"""    

texts = (
    {
        "text": str(args.prompt),
        "weight": 1.0
    },{ # Helps reduce pixelation, but also smoothes images overall
        "text":"pixelated",
        "weight":-0.5
    },{ # Trying to reduce text
        "text":"text signature font writing",
        "weight":-0.5
    }
)

#Image prompts
images = []

images_n = 1
chroma_fraction = 1
sigmoid_params = True # If you change this you'll have to change the learning rates too... No great way around that.

# Todo: Make this work right with chroma_fraction. Currently only bicubic and bilinear do
# Bilinear and bicubic resize in param space, lanczos and esrgan in image space
# ESRGAN doesn't currently work
upscaling_mode = args.upscaling #"bilinear" , "bicubic" "lanczos"

# Gaussian noise is normal noise in the sigmoid YCoCv space. Uniform noise is in the RGB space.
init_type = args.initnoise #"uniform" #"gaussian" # "uniform"

#Params for uniform init noise
init_gamma = 1.0 # contrast
init_gain = 1.0 # Brightness

# Params for gaussian init noise
chroma_noise_scale = 0.0 # Saturation (0 - 2 is safe but you can go as high as you want)
luma_noise_mean = 0.0 # Brightness (-3 to 3 seems safe but around 0 seems to work better)
luma_noise_scale = 0.0 # Contrast (0-2 is safe but you can go as high as you want)
init_noise_clamp = 8.0 # Turn this down if you're getting persistent super bright or dark spots.

warmup_its = 50

itt=0

cutouts = args.cutouts

#attempted tweak settings to speed up time
stages = (
        {
        #stage 1
        "dim": (args.sizey // 128, args.sizex // 128, ),
        "cuts": cutouts,
        "cycles": 200, #500, #200,
        "lr_luma": 0.05,
        "decay_luma": 0,
        "lr_chroma": 0.03, #0.03, # Chroma LR in first cycle controls saturation of the final image
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.00,
        "checkin_interval": 50,
      },{
        #stage 2
        "dim": (args.sizey // 64, args.sizex // 64, ),
        "cuts": cutouts,
        "cycles": 200, #500, #200,
        "lr_luma": 0.05,
        "decay_luma": 0,
        "lr_chroma": 0.03, #0.03, # Chroma LR in first cycle controls saturation of the final image
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.01,
        "checkin_interval": 50,
        "init_noise": 0.25 # Scale of uniform noise to add at the start of this iteration
      },{
        #stage 3
        "dim": (args.sizey // 32, args.sizex // 32, ),
        "cuts": cutouts,
        "cycles": 200, #500, #300,
        "lr_luma": 0.05,
        "decay_luma": 0,
        "lr_chroma": 0.02, #0.02, # Chroma LR in first cycle controls saturation of the final image
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.1,
        "checkin_interval": 50,
        "init_noise": 0.2
      },{
        #stage 4
        "dim":  (args.sizey // 16, args.sizex // 16, ),
        "cuts": cutouts,
        "cycles": 200, #500, #300,
        "lr_luma": 0.05,
        "decay_luma": 0,
        "lr_chroma": 0.02, #0.02, # Chroma LR in first cycle controls saturation of the final image
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.20,
        "checkin_interval": 50,
        "init_noise": 0.2
      },{
        #stage 5
        "dim":  (args.sizey // 8, args.sizex // 8, ),
        "cuts": cutouts,
        "cycles": 300, #700, #300,
        "lr_luma": 0.03,
        "decay_luma": 0,
        "lr_chroma": 0.015, #0.015,
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.25,
        "checkin_interval": 100,
        "init_noise": 0.2
    },{
        #stage 6
        "dim": (args.sizey // 4, args.sizex // 4, ),
        "cuts": cutouts,
        "cycles": 500, #1000, #300,
        "lr_luma": 0.03,
        "decay_luma": 0,
        "lr_chroma": 0.01, #0.01,
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 0.60,
        "checkin_interval": 100,
        "init_noise": 0.2
    }, 
    {
        #stage 7
        "dim": (args.sizey // 2, args.sizex // 2, ),
        "cuts": cutouts,
        "cycles": 500, #1000, #400,
        "lr_luma": 0.03,
        "decay_luma": 0,
        "lr_chroma": 0.007, #0.007,
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 3.0,
        "checkin_interval": 100,
        "init_noise": 0.15
    },
    {
        #stage 8
        "dim": (args.sizey, args.sizex, ),
        "cuts": cutouts,
        "cycles": 500, #1000, #500,
        "lr_luma": 0.02,
        "decay_luma": 0.0,
        "lr_chroma": 0.002, #0.002,
        "decay_chroma": 0.0,
        "noise": 0.2,
        "denoise": 1.0,
        "checkin_interval": 100
    },
)

bilinear = torchvision.transforms.functional.InterpolationMode.BILINEAR
bicubic = torchvision.transforms.functional.InterpolationMode.BICUBIC

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

def getClipTokens(image, cuts, noise, do_checkin, perceptor):
    im = normalize_image(image)
    cut_data = torch.zeros(cuts, 3, perceptor["size"], perceptor["size"])
    for c in range(cuts):
      angle = random.uniform(-20.0, 20.0)
      img = torchvision.transforms.functional.rotate(im, angle=angle, expand=True, interpolation=bilinear)

      padv = im.size()[2] // 8
      img = torch.nn.functional.pad(img, pad=(padv, padv, padv, padv))

      size = img.size()[2:4]
      mindim = min(*size)

      if mindim <= perceptor["size"]-32:
        width = mindim - 1
      else:
        width = random.randint( perceptor["size"]-32, mindim-1 )

      oy = random.randrange(0, size[0]-width)
      ox = random.randrange(0, size[1]-width)
      img = img[:,:,oy:oy+width,ox:ox+width]

      img = torch.nn.functional.interpolate(img, size=(perceptor["size"], perceptor["size"]), mode='bilinear', align_corners=False)
      cut_data[c] = img

    cut_data += noise * torch.randn_like(cut_data, requires_grad=False)

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
  size = image.size()
  image = (image[0].clamp(0, 1) * 255).to(torch.uint8)
  png_data = torch.ops.image.encode_png(image.cpu(), 6)
  open(filename, "wb").write(bytes(png_data))


def paramsToImage(param_luma, param_chroma):
  if chroma_fraction == 1:
    CoCg = param_chroma
  else:
    CoCg = torch.nn.functional.interpolate(param_chroma, size=(param_luma.size()[2:4]), mode='bilinear', align_corners=False)
  if sigmoid_params:
    luma = torch.sigmoid(param_luma)
    CoCg = torch.sigmoid(CoCg) * 2 - 1
  else:
    luma = param_luma
  Co = CoCg[:,0]
  Cg = CoCg[:,1]

  tmp = luma - Cg/2
  G = Cg + tmp
  B = tmp - Co/2
  R = B + Co
  im_torch = torch.cat((R, G, B), dim=1)#.clamp(0,1)
  return im_torch

def imageToParams(image):
  image = image#.clamp(0,1)
  R, G, B = image[:,0:1], image[:,1:2], image[:,2:3]
  luma = R * 0.25 + G * 0.5 + B * 0.25
  Co = R  - B
  tmp = B + Co / 2
  Cg = G - tmp
  luma = tmp + Cg / 2

  nsize = luma.size()[2:4]
  if chroma_fraction == 1:
    chroma =  torch.cat([Co,Cg], dim=1)
  else:
    chroma = torch.nn.functional.interpolate(torch.cat((Co,Cg), dim=1), size=(nsize[0]//chroma_fraction, nsize[1]//chroma_fraction), mode='bilinear', align_corners=False)
  if sigmoid_params:
    chroma = torch.logit((chroma / 2.0 + 0.5), eps=1e-8)
    luma = torch.logit(luma, eps=1e-8)
  return luma, chroma 

def lossClip(image, cuts, noise, do_checkin):
  losses = []

  max_loss = 0.0
  for text in texts:
    max_loss += abs(text["weight"]) * len(perceptors)
  for img in images:
    max_loss += abs(img["weight"]) * len(perceptors)

  for perceptor in perceptors:
    clip_tokens = getClipTokens(image, cuts, noise, do_checkin, perceptor)
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

def cycle(c, stage, optimizer, param_luma, param_chroma):
  global itt
  
  do_checkin = (c+1) % stage["checkin_interval"] == 0

  sys.stdout.write("Iteration {} /2600 Stage {}/{} Cycle {}/{} Pixels {}x{}".format(itt+1,stage["n"]+1,len(stages),c+1,stage["cycles"],stage["dim"][0],stage["dim"][1])+"\n")
  sys.stdout.flush()

  with torch.enable_grad():
    image = paramsToImage(param_luma, param_chroma)

    losses = []
    losses += lossClip( image, stage["cuts"], stage["noise"], do_checkin )
    losses += [lossTV( image, stage["denoise"] )]

    loss_total = sum(losses).sum()
    optimizer.zero_grad(set_to_none=True)
    loss_total.backward(retain_graph=False)
    if c <= warmup_its:
      optimizer.param_groups[0]["lr"] = stage["lr_luma"] * c / warmup_its
      optimizer.param_groups[1]["lr"] = stage["lr_chroma"] * c / warmup_its
    optimizer.step()

  if do_checkin:
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    TV = losses[-1].sum().item()
    #print( "Cycle:", str(stage["n"]) + ":" + str(c), "CLIP Loss:", loss_total.item() - TV, "TV loss:", TV)
    nimg = paramsToImage(param_luma, param_chroma)

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

def sinc(x):
    return torch.where(x != 0, torch.sin(math.pi * x) / (math.pi * x), x.new_ones([]))

def lanczos(x, a):
    cond = torch.logical_and(-a < x, x < a)
    out = torch.where(cond, sinc(x) * sinc(x/a), x.new_zeros([]))
    return out / out.sum()

def ramp(ratio, width):
    n = math.ceil(width / ratio + 1)
    out = torch.empty([n])
    cur = 0
    for i in range(out.shape[0]):
        out[i] = cur
        cur += ratio
    return torch.cat([-out[1:].flip([0]), out])[1:-1]

def resample(input, size, align_corners=True):
    n, c, h, w = input.shape
    dh, dw = size

    input = input.reshape([n * c, 1, h, w])

    kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
    pad_h = (kernel_h.shape[0] - 1) // 2
    input = torch.nn.functional.pad(input, (0, 0, pad_h, pad_h), 'reflect')
    input = torch.nn.functional.conv2d(input, kernel_h[None, None, :, None])

    kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
    pad_w = (kernel_w.shape[0] - 1) // 2
    input = torch.nn.functional.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
    input = torch.nn.functional.conv2d(input, kernel_w[None, None, None, :])

    input = input.reshape([n, c, h, w])
    return torch.nn.functional.interpolate(input, size, mode='bicubic', align_corners=align_corners)

def main():
  global itt
  
  if init_type == "uniform":
    channels = 3
    image = torch.rand(size = (1,channels,stages[0]['dim'][0], stages[0]['dim'][1]))
    image = torch.pow(image, init_gamma) * init_gain
    luma, chroma = imageToParams(image)
  elif init_type == "gaussian":
    luma = torch.randn(size = (1,1,stages[0]['dim'][0], stages[0]['dim'][1]))  * luma_noise_scale + luma_noise_mean
    chroma = torch.randn(size = (1,2,stages[0]['dim'][0], stages[0]['dim'][1])) * chroma_noise_scale
    luma = luma.clamp(-init_noise_clamp, init_noise_clamp)
    chroma = chroma.clamp(-init_noise_clamp, init_noise_clamp)

  param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True)
  param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True )

  params = (
    {"params":param_luma, "lr":stages[0]["lr_luma"], "weight_decay":stages[0]["decay_luma"]},
    {"params":param_chroma, "lr":stages[0]["lr_chroma"], "weight_decay":stages[0]["decay_chroma"]},
  )
  optimizer = torch.optim.AdamW(params)

  sys.stdout.write("Starting ...\n")
  sys.stdout.flush()

  for n, stage in enumerate(stages):
    stage["n"] = n
    if n > 0:
      if stage['dim'][0] != param_luma.shape[2]:
        if upscaling_mode == "lanczos":
          luma = resample(param_luma, ( stage['dim'][0], stage['dim'][1] ))
          chroma = resample(param_chroma, ( stage['dim'][0], stage['dim'][1] )) 
          param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True )
          param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True )
        else:
          param_luma = torch.nn.parameter.Parameter(torch.nn.functional.interpolate(param_luma.data, size=( stage['dim'][0], stage['dim'][1] ), mode=upscaling_mode, align_corners=False), requires_grad=True ).cuda()
          param_chroma = torch.nn.parameter.Parameter(torch.nn.functional.interpolate(param_chroma.data, size=( stage['dim'][0]//chroma_fraction, stage['dim'][1]//chroma_fraction ), mode=upscaling_mode, align_corners=False), requires_grad=True ).cuda()
      if "init_noise" in stage:
        param_luma += torch.randn_like(param_luma) * stage["init_noise"]
        param_chroma += torch.randn_like(param_chroma) * stage["init_noise"]
      params = (
        {"params":param_luma, "lr":stage["lr_luma"], "weight_decay":stage["decay_luma"]},
        {"params":param_chroma, "lr":stage["lr_chroma"], "weight_decay":stage["decay_chroma"]}
      )
      
      optimizer = torch.optim.AdamW(params)

    for c in range(stage["cycles"]):
      cycle( c, stage, optimizer, param_luma, param_chroma)
      itt += 1

for _ in range(images_n):
  main()