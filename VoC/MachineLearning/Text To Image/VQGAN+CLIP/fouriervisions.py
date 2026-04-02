# FourierVisions.ipynb
# Original file is located at https://colab.research.google.com/drive/1nGNBjhbYnDHSumGPjpFHjDOsaZFAqGgF

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os, random, shutil, math
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
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--update', type=int, help='Iterations per update.')
  parser.add_argument('--cutouts', type=int, help='Cutout count.')
  parser.add_argument('--brightness', type=float, help='Display only brightness.')
  parser.add_argument('--contrast', type=float, help='Display only contrast.')
  parser.add_argument('--gamma', type=float, help='Display only gamma.')
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

images = []

images_n = 1

# Params for gaussian init noise
chroma_noise_scale = 0.00000 # Saturation (0 - 2 is safe but you can go as high as you want)
luma_noise_mean = 0.0 # Brightness (-3 to 3 seems safe but around 0 seems to work better)
luma_noise_scale = 0.00000 # Contrast (0-2 is safe but you can go as high as you want)
init_noise_clamp = 0.0 # Turn this down if you're getting persistent super bright or dark spots.

lr_scale = 100#5e-5
eq_pow = 1
eq_min = 1e-6

itt=0

initial_image = None

resample_image_prompts = False

dims = (args.sizey, args.sizex)
display_size = [args.sizex, args.sizey]

stages = (
            { #First stage does rough detail. It's going to look really coherent but blurry
        "cuts": args.cutouts,
        "cycles": args.iterations // 2,
        "lr_luma": 0.09, #1,
        "decay_luma": 0.0,
        "lr_chroma": 0.4, #0.5,
        "decay_chroma": 0.0,
        "noise": 0.2,
        "denoise": 10.0,
        "checkin_interval": args.update,
    }, { # 2nd stage does fine detail. Going to get much clearer
        "cuts": args.cutouts,
        "cycles": args.iterations // 2,
        "lr_luma": 0.3, #0.5,
        "decay_luma": 0,
        "lr_chroma": 0.2, #0.25,
        "decay_chroma": 0,
        "noise": 0.2,
        "denoise": 9, #1,
        "checkin_interval": args.update,
    },
)

debug_clip_cuts = False

def generate_filter(dims, eq_pow, eq_min):
    eqx = torch.fft.fftfreq(dims[0])
    eqy = torch.fft.fftfreq(dims[1])
    eq = torch.outer(torch.abs(eqx), torch.abs(eqy))
    eq = eq - eq.min()
    eq = 1 - eq / eq.max()
    eq = torch.pow(eq, eq_pow)
    eq = eq * (1-eq_min) + eq_min
    return eq
eq = generate_filter(dims, eq_pow, eq_min)

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

    if debug_clip_cuts and do_checkin:
      displayImage(cut_data)

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

def paramsToImage(params_luma, params_chroma):
  CoCg = torch.fft.irfft2(params_chroma, norm="backward")
  luma = torch.fft.irfft2(params_luma, norm="backward")
  luma = (luma / 2.0 + 0.5).clamp(0,1)
  CoCg = CoCg.clamp(-1,1)
  Co = CoCg[:,0]
  Cg = CoCg[:,1]

  tmp = luma - Cg/2
  G = Cg + tmp
  B = tmp - Co/2
  R = B + Co
  im_torch = torch.cat((R, G, B), dim=1)#.clamp(0,1)
  im_torch = im_torch[:,:,:,:dims[1]]
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
  chroma =  torch.cat([Co,Cg], dim=1)
  chroma = chroma / 2.0 + 0.5
  chroma = torch.logit(chroma, eps=1e-8)
  luma = torch.logit(luma, eps=1e-8)
  chroma = torch.fft.rfft2(chroma)
  luma = torch.fft.rfft2(luma)
  return luma, chroma 

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

def cycle(c, stage, optimizer, params_luma, params_chroma, eq):
  do_checkin = (c+1) % stage["checkin_interval"] == 0

  sys.stdout.write("Iteration {}".format(itt+1)+"\n")
  sys.stdout.flush()

  with torch.enable_grad():
    image = paramsToImage(params_luma, params_chroma)
    optimizer.zero_grad(set_to_none=True)
    losses = lossClip( image, stage["cuts"], stage["noise"], do_checkin )
    losses += [lossTV( image, stage["denoise"] )]
    loss_total = sum(losses).sum()
    loss_total.backward(retain_graph=False)
    optimizer.step()


  if do_checkin:
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    nimg = paramsToImage(params_luma, params_chroma)

    #tweak display image
    nimg = torchvision.transforms.functional.adjust_brightness(nimg,args.brightness)
    nimg = torchvision.transforms.functional.adjust_gamma(nimg,args.gamma,1.0)
    #nimg = torchvision.transforms.functional.adjust_contrast(nimg,args.contrast)
    #nimg = torchvision.transforms.functional.adjust_sharpness(nimg,1.1)

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

def init_optim(params_luma, params_chroma, stage):
  # lr_scales = stage["lr_scales"]
  params = []
  params.append({"params":params_luma, "lr":stage["lr_luma"] * lr_scale, "weight_decay":stage["decay_luma"] * lr_scale})
  params.append({"params":params_chroma, "lr":stage["lr_chroma"] * lr_scale, "weight_decay":stage["decay_chroma"] * lr_scale})
  return torch.optim.AdamW(params)

def main():
  global itt
  param_luma = None
  param_chroma = None
  eq = generate_filter(dims, eq_pow, eq_min)
  if initial_image is not None:
    image = loadImage(initial_image)
    image = torch.nn.functional.interpolate(image, size=dims[-1], mode='bicubic', align_corners=False)
    luma, chroma = imageToParams(image)
    param_luma = torch.nn.parameter.Parameter( luma.double().cuda(), requires_grad=True)
    param_chroma = torch.nn.parameter.Parameter( chroma.double().cuda(), requires_grad=True)
  else:
    luma = torch.randn(size = (1,1,dims[0], dims[1])) * luma_noise_scale * eq
    chroma = torch.randn(size = (1,2,dims[0], dims[1])) * chroma_noise_scale * eq
    luma = luma.clamp(-init_noise_clamp, init_noise_clamp)
    chroma = chroma.clamp(-init_noise_clamp, init_noise_clamp)
    param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True)
    param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True)
  optimizer = init_optim(param_luma, param_chroma, stages[0])

  sys.stdout.write("Starting ...\n")
  sys.stdout.flush()

  for n, stage in enumerate(stages):
    stage["n"] = n
    if n > 0:
      optimizer.param_groups[0]["lr"] = stage["lr_luma"] * lr_scale
      optimizer.param_groups[1]["lr"] = stage["lr_chroma"] * lr_scale
    for c in range(stage["cycles"]):
      cycle( c, stage, optimizer, param_luma, param_chroma, eq)
      itt += 1

for _ in range(images_n):
  main()