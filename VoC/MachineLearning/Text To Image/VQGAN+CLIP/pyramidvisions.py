# PyramidVisions.ipynb
# Original file is located at https://colab.research.google.com/drive/1dpAS_wK34y7c6s-CatAFmBtbkjGT_erM

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from CLIP import clip
import torch_optimizer as optim
import sys, os, random, shutil, math
import torch, torchvision
from IPython import display
import numpy as np
from PIL import Image
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
  parser.add_argument('--scaling', type=str, help='Scaling.')
  parser.add_argument('--optimizer', type=str, help='Optimizer.')
  parser.add_argument('--sharpness', type=float, help='Display only sharpness.')
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
    
    

# Input prompts. Each prompt has "text" and a "weight"
# Weights can be negatives, useful for discouraging specific artifacts
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



cluster = None#"beautiful detailed epic vivid amazing incredible awe-inspiring"
cluster_weight = 1.0
if cluster is not None:
  cluster = cluster.split()
  for word in cluster:
    texts.append({"text":word, "weight":cluster_weight / float(len(cluster))})

itt=0

#Image prompts
images = []

# Number of times to run
images_n = 1

# Params for gaussian init noise
chroma_noise_scale = 0.5 # Saturation (0 - 2 is safe but you can go as high as you want)
luma_noise_mean = 0.0 # Brightness (-3 to 3 seems safe but around 0 seems to work better)
luma_noise_scale = 1.0 # Contrast (0-2 is safe but you can go as high as you want)
init_noise_clamp = 8.0 # Turn this down if you're getting persistent super bright or dark spots.

# High-frequency to low-frequency initial noise ratio. 
chroma_noise_persistence = 0.75
luma_noise_persistence = 0.75

# This doesn't seem to matter too much except for 'Nearest', which results in very crisp but pixelated images
# Lanczos is most advanced but also uses the largest kernel so has the biggest problem with image borders
# Bilinear is fastest (outside of nearest) but can introduce star-like artifacts
pyramid_scaling_mode = args.scaling #"lanczos" # "lanczos" #'bicubic' "nearest" "bilinear"

# AdamW is real basic and gets the job done
# RAdam seems to work *extremely well* but seems to introduce some color instability?, use 0.5x lr
# Yogi is just really blurry for some reason, use 5x + lr
# Ranger works great. use 3-4x LR
optimizer_type = args.optimizer #"Ranger" # "AdamW", "AccSGD","Ranger","RangerQH","RangerVA","AdaBound","AdaMod","Adafactor","AdamP","AggMo","DiffGrad","Lamb","NovoGrad","PID","QHAdam","QHM","RAdam","SGDP","SGDW","Shampoo","SWATS","Yogi"

initial_image = None #None #trying a seed image causes script to crash

# Resample image prompt vectors every iterations
# Slows things down a lot for very little benefit, don't bother
resample_image_prompts = False

#Add an extra pyramid layer with dims (1, 1) to control global avg color
add_global_color = True

# Optimizer settings for different training steps
stages = (
            { #First stage does rough detail.
        "cuts": args.cutouts,
        "cycles": args.iterations // 2, # was 2/3 of iterations
        "lr_luma": 1.5e-1, #1e-2 for RAdam #3e-2 for adamw
        "decay_luma": 1e-5,
        "lr_chroma": 7.5e-2, #5e-3 for RAdam #1.5e-2 for adamw
        "decay_chroma": 1e-5,
        "noise": 0.2,
        "denoise": 0.5,
        "checkin_interval": args.update,
        "pyramid_lr_min" : 0.2, # Percentage of small scale detail
    }, { # 2nd stage does fine detail and
        "cuts": args.cutouts,
        "cycles": args.iterations // 2, # was 1/3 of iterations
        "lr_luma": 1.0e-1,
        "decay_luma": 1e-5,
        "lr_chroma": 7.0e-2,
        "decay_chroma": 1e-5,
        "noise": 0.2,
        "denoise": 1.0,
        "checkin_interval": args.update,
        "pyramid_lr_min" : 1
    },
)

# Size of the smallest pyramid layer
if args.sizex<args.sizey:
  aspect_ratio = (4*args.sizey/args.sizex,4)#(3, 4)
elif args.sizey<args.sizex:
  aspect_ratio = (4,4*args.sizex/args.sizey)#(4, 3)
else:
  aspect_ratio = (4,4)#(3, 4)



# Max dim of the final output image.
max_dim = max(args.sizex,args.sizey)


# Number of layers at different resolutions combined into the final image
# "optimal" number is log2(max_dim / max(aspect_ratio))
# Going below that can make things kinda pixelated but still works fine
# Seems like you can really go as high as you want tho. Not sure if it helps but you *can*
optimal_pyramid_steps = int(math.log2(max_dim / max(aspect_ratio))*2)  # NOTE the *2 is just to bump the "optimal" value higher, it also matches the hard coded value for 512x512 which was 14
#sys.stdout.write(f'{optimal_pyramid_steps} pyramid steps\n')
#sys.stdout.flush()
pyramid_steps = optimal_pyramid_steps #original was 14, now set based on image size using above formula

#Calculate layer dims
pyramid_lacunarity = (max_dim / max(aspect_ratio))**(1.0/(pyramid_steps-1))
scales = [pyramid_lacunarity**step for step in range(pyramid_steps)]
dims = []
if add_global_color:
  dims.append([1,1])
for step in range(pyramid_steps):
  scale = pyramid_lacunarity**step
  #dim = [int(round(aspect_ratio[0] * scale)), int(round(aspect_ratio[1] * scale))]
  dim = [int(round(aspect_ratio[0] * scale)), int(round(aspect_ratio[1] * scale))]
  # Ensure that no two levels have the same dims
  if len(dims) > 0:
    if dim[0] <= dims[-1][0]:
      dim[0] = dims[-1][0]+1
    if dim[1] <= dims[-1][1]:
      dim[1] = dims[-1][1]+1
  dims.append(dim)
#print(dims) # [[1, 1], [3, 4], [5, 6], [7, 9], [11, 14], [17, 22], [25, 34], [39, 52], [59, 79], [91, 121], [139, 186], [214, 285], [327, 436], [501, 668], [768, 1024]]

display_size = [i * 160 for i in aspect_ratio]
pyramid_steps = len(dims)
for stage in stages:
  if "lr_scales" not in stage:
    if "lr_persistence" in stage:
      persistence = stage["lr_persistence"]
    elif "pyramid_lr_min" in stage:
      persistence = stage["pyramid_lr_min"]**(1.0/float(pyramid_steps-1))
    else:
      persistence = 1.0  
    lrs = [persistence**i for i in range(pyramid_steps)]
    sum_lrs = sum(lrs)
    stage["lr_scales"] = [rate / sum_lrs for rate in lrs]
    #print(persistence, stage["lr_scales"])

debug_clip_cuts = False

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
  CoCg = torch.zeros_like(params_chroma[-1])
  luma = torch.zeros_like(params_luma[-1])
  for i in range(len(params_luma)):
    if pyramid_scaling_mode == "lanczos":
      CoCg += resample(params_chroma[i], params_chroma[-1].shape[2:])
      luma += resample(params_luma[i], params_luma[-1].shape[2:])
    else:
      if pyramid_scaling_mode == "nearest" or (params_luma[i].shape[2] == 1 and params_luma[i].shape[3] == 1):
        CoCg += torch.nn.functional.interpolate(params_chroma[i], size=params_chroma[-1].shape[2:], mode="nearest")
        luma += torch.nn.functional.interpolate(params_luma[i], size=params_luma[-1].shape[2:], mode="nearest")
      else:
        CoCg += torch.nn.functional.interpolate(params_chroma[i], size=params_chroma[-1].shape[2:], mode=pyramid_scaling_mode, align_corners=True)
        luma += torch.nn.functional.interpolate(params_luma[i], size=params_luma[-1].shape[2:], mode=pyramid_scaling_mode, align_corners=True)

  luma = torch.sigmoid(luma)
  CoCg = torch.sigmoid(CoCg) * 2 - 1
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
  chroma =  torch.cat([Co,Cg], dim=1)
  chroma = torch.logit((chroma / 2.0 + 0.5), eps=1e-8)
  luma = torch.logit(luma, eps=1e-8)
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

def cycle(c, stage, optimizer, params_luma, params_chroma):
  do_checkin = (c+1) % stage["checkin_interval"] == 0

  sys.stdout.write("Iteration {}".format(itt+1)+"\n")
  sys.stdout.flush()

  with torch.enable_grad():
    losses = []
    image = paramsToImage(params_luma, params_chroma)
    losses += lossClip( image, stage["cuts"], stage["noise"], do_checkin )
    losses += [lossTV( image, stage["denoise"] )]

    loss_total = sum(losses).sum()
    optimizer.zero_grad(set_to_none=True)
    loss_total.backward(retain_graph=False)
    # if c <= warmup_its:
    #   optimizer.param_groups[0]["lr"] = stage["lr_luma"] * c / warmup_its
    #   optimizer.param_groups[1]["lr"] = stage["lr_chroma"] * c / warmup_its
    optimizer.step()


  if do_checkin:
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    #TV = losses[-1].sum().item()
    #print( "Cycle:", str(stage["n"]) + ":" + str(c), "CLIP Loss:", loss_total.item() - TV, "TV loss:", TV)
    nimg = paramsToImage(params_luma, params_chroma)
    #displayImage(torch.nn.functional.interpolate(nimg, size=display_size, mode='nearest'))
    
    #tweak display image
    #nimg = torchvision.transforms.functional.adjust_brightness(nimg,args.brightness)
    #nimg = torchvision.transforms.functional.adjust_gamma(nimg,args.gamma,1.0)
    #nimg = torchvision.transforms.functional.adjust_contrast(nimg,args.contrast)
    if args.sharpness is not 1:
        nimg = torchvision.transforms.functional.adjust_sharpness(nimg,args.sharpness)

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

    # if dh < h:
    kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
    pad_h = (kernel_h.shape[0] - 1) // 2
    input = torch.nn.functional.pad(input, (0, 0, pad_h, pad_h), 'reflect')
    input = torch.nn.functional.conv2d(input, kernel_h[None, None, :, None])

    # if dw < w:
    kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
    pad_w = (kernel_w.shape[0] - 1) // 2
    input = torch.nn.functional.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
    input = torch.nn.functional.conv2d(input, kernel_w[None, None, None, :])

    input = input.reshape([n, c, h, w])
    return torch.nn.functional.interpolate(input, size, mode='bicubic', align_corners=align_corners)

def init_optim(params_luma, params_chroma, stage):
  lr_scales = stage["lr_scales"]
  params = []
  for i in range(len(lr_scales)):
    params.append({"params":params_luma[i], "lr":stage["lr_luma"] * lr_scales[i], "weight_decay":stage["decay_luma"]})
    params.append({"params":params_chroma[i], "lr":stage["lr_chroma"] * lr_scales[i], "weight_decay":stage["decay_chroma"]})
  optimizer = getattr(optim, optimizer_type, None)(params)
  return optimizer

def main():
  global itt
  params_luma = []
  params_chroma = []
  if initial_image is not None:
    for dim in dims:
      luma = torch.zeros((1,1,dim[0], dim[1]))
      chroma = torch.zeros((1,2,dim[0], dim[1]))
      param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True)
      param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True)
      params_luma.append(param_luma)
      params_chroma.append(param_chroma)
    image = loadImage(initial_image)
    image = torch.nn.functional.interpolate(image, size=dims[-1], mode='bicubic', align_corners=False)
    luma, chroma = imageToParams(image)
    param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True)
    param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True)
    params_luma[-1] = param_luma
    params_chroma[-1] = params_chroma
    """
    for dim in dims:
      pix = []
      for channel in range(3):
        pix_c = torch.zeros((1,1,dim[0], dim[1]))
        param_pix = torch.nn.parameter.Parameter( pix_c.cuda(), requires_grad=True)
        pix.append(param_pix)
      params_pyramid.append(pix)
    image = loadImage(initial_image)
    image = torch.nn.functional.interpolate(image, size=dims[-1], mode='bicubic', align_corners=False)
    pix_1, pix_2, pix_3 = imageToParams(image)
    pix = []
    for channel in range(3):
      param_pix = torch.nn.parameter.Parameter( pix.cuda(), requires_grad=True)
      pix.append(param_pix)
    params_pyramid[-1] = pix
    """
  else:
    for i, dim in enumerate(dims):
      luma = (torch.randn(size = (1,1,dim[0], dim[1])) * luma_noise_scale * luma_noise_persistence**i) / len(dims)
      chroma = torch.randn(size = (1,2,dim[0], dim[1])) * chroma_noise_scale * chroma_noise_persistence**i / len(dims)
      luma = luma.clamp(-init_noise_clamp / len(dims), init_noise_clamp / len(dims))
      chroma = chroma.clamp(-init_noise_clamp / len(dims), init_noise_clamp / len(dims))
      param_luma = torch.nn.parameter.Parameter( luma.cuda(), requires_grad=True)
      param_chroma = torch.nn.parameter.Parameter( chroma.cuda(), requires_grad=True)
      params_luma.append(param_luma)
      params_chroma.append(param_chroma)
  params_luma[0] -= luma_noise_mean

  optimizer = init_optim(params_luma, params_chroma, stages[0])

  for n, stage in enumerate(stages):
    stage["n"] = n
    if n > 0:
      for i in range(len(dims)):
        optimizer.param_groups[i*2]["lr"] = stage["lr_luma"] * stage["lr_scales"][i]
        optimizer.param_groups[i*2+1]["lr"] = stage["lr_chroma"] * stage["lr_scales"][i]
    for c in range(stage["cycles"]):
      cycle( c, stage, optimizer, params_luma, params_chroma)
      itt+=1

for _ in range(images_n):
  main()