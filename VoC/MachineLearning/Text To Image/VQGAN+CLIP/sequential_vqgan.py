# Sequential VQGAN+CLIP (z+quantize).ipynb
# Original file is located at https://colab.research.google.com/drive/1CcibxlLDng2yzcjLwwwSADRcisc1qVCs

# Generate images and videos from sequential text phrases with VQGAN and CLIP (z + quantize method with augmentations).

# made by Jakeukalane # 2767 and Avengium (Angel) # 3715
 
import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
import math
from pathlib import Path
import sys
 
sys.path.append('./taming-transformers')
from IPython import display
from base64 import b64encode
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from tqdm.notebook import tqdm
 
from CLIP.clip import clip
import kornia.augmentation as K
import numpy as np
import imageio
from PIL import ImageFile, Image
import json
ImageFile.LOAD_TRUNCATED_IMAGES = True




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
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--movement1', type=str, help='Movement.')
  parser.add_argument('--movement2', type=str, help='Movement.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--useaugs', type=bool, help='Use augments.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

args = argparse.Namespace(
    prompts=[args2.prompt],
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
 
    input = input.view([n * c, 1, h, w])
 
    if dh < h:
        kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
        pad_h = (kernel_h.shape[0] - 1) // 2
        input = F.pad(input, (0, 0, pad_h, pad_h), 'reflect')
        input = F.conv2d(input, kernel_h[None, None, :, None])
 
    if dw < w:
        kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
        pad_w = (kernel_w.shape[0] - 1) // 2
        input = F.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
        input = F.conv2d(input, kernel_w[None, None, None, :])
 
    input = input.view([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)
 
 
class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward
 
    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)
 
 
replace_grad = ReplaceGrad.apply
 
 
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
 
 
def vector_quantize(x, codebook):
    d = x.pow(2).sum(dim=-1, keepdim=True) + codebook.pow(2).sum(dim=1) - 2 * x @ codebook.T
    indices = d.argmin(-1)
    x_q = F.one_hot(indices, codebook.shape[0]).to(d.dtype) @ codebook
    return replace_grad(x_q, x)
 
 
class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))
 
    def forward(self, input):
        input_normed = F.normalize(input.unsqueeze(1), dim=2)
        embed_normed = F.normalize(self.embed.unsqueeze(0), dim=2)
        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()
 
 
def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    
    # watch out for errant : in text
    txt = vals[0]
    try:
        weight = float(vals[1])
    except:
        weight = 1
    try:
        stop = float(vals[2])
    except:
        stop = -inf
        
        
    return txt, weight, stop
 
 
class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.augs = nn.Sequential(
            K.RandomHorizontalFlip(p=0.5),
            # K.RandomSolarize(0.01, 0.01, p=0.7),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
            K.RandomPerspective(0.2,p=0.4),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7))
        self.noise_fac = 0.1
 
 
    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        for _ in range(self.cutn):
            size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        batch = self.augs(torch.cat(cutouts, dim=0))
        if self.noise_fac:
            facs = batch.new_empty([self.cutn, 1, 1, 1]).uniform_(0, self.noise_fac)
            batch = batch + facs * torch.randn_like(batch)
        return batch
 
 
def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = vqgan.VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.eval().requires_grad_(False)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model
 

def freeze_image(base, generated, mask):
  # reset part of the generated image back to a base image
  # areas of mask that are 0 will use the base image, 
  # 1 will use the generated image
  base.paste(generated,(0,0),mask)
  return base
 
def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)


# learning rate functions
def lrs_constant(lr0,lr1,step_switch,step):
  return lr0

def lrs_linear(lr0,lr1,step_switch,step):
  delta = lr1 - lr0
  pct = min(step/step_switch,1)
  lr = lr0 + delta*pct
  return lr

def lrs_cosine(lr0,lr1,step_switch,step):
  delta = lr0 - lr1
  pct = min(step/step_switch,1)
  x = np.pi * pct
  rate = (np.cos(x)+1)/2
  lr = delta*rate + lr1
  return lr

def lrs_step(lr0,lr1,step_switch,step):
  if step >= step_switch:
    lr = lr0
  else:
    lr = lr1
  return lr

"""## Options:
Mainly what you will have to modify will be `texts:`, there you can place the text (s) you want to generate (separated with `|`). It is a list because you can put more than one text, and so the AI ​​tries to 'mix' the images, giving the same priority to both texts.

For multiple prompts, separate text with || (e.g. a city in the daytime || a city at night.) This will reset the model on the next phrase using the final image of the previous phrase as the input. Due to this, any input image specified below will only be used for the first prompt. Each prompt is processed for max_iterations.

To use an initial image to the model, you just have to upload a file to the Colab environment (in the section on the left), and then modify `initial_image:` putting the exact name of the file. Example: `sample.png`

You can also modify the model by changing the lines that say `model:`. Currently 1024, 16384, WikiArt, S-FLCKR and COCO-Stuff are available. To activate them you have to have downloaded them first, and then you can simply select it.

You can also use `target_images`, which is basically putting one or more images on it that the AI ​​will take as a" target ", fulfilling the same function as putting text on it. To put more than one you have to use `|` as a separator.
"""

# colab form fields can be found here: https://colab.research.google.com/notebooks/forms.ipynb

#@title (Run after from here to make changes)
text_prompt = args2.prompt #@param {type: "string"}
#text2 = "A street at night photorealistic render" #@param {type: "string"}
width =  args2.sizex #400#@param {type: "number"}
height =  args2.sizey #400#@param {type: "number"}
model = "vqgan_imagenet_f16_16384" #@param ["vqgan_imagenet_f16_16384", "vqgan_imagenet_f16_1024", "wikiart_1024", "wikiart_16384", "coco", "faceshq", "sflckr"]
image_range = 50 # @param {type: "number"}
max_iterations =  args2.iterations #@param {type: "number"}
#change_at = 150 # @param {type: "number"}
# @markdown Starting image and target:
start_image = "None" # @param {type: "string"}
target_images = None #@param {type: "string"}

"""##Advanced Options
These options are intended for advanced users.

**learning_rate_1** - the initial learning rate at step = 0 (used to be step_size)

**learning_rate_2** - the final learning rate at step = learning_rate_step_switch

**learning_rate_step_switch** - when to stop changing the learning rate (and stop at learning_rate_2). Set to -1 to equal the max_iterations above.

**learning_rate_scheduler** - how the learning rate changes between the initial and final value.

"""

# colab form fields can be found here: https://colab.research.google.com/notebooks/forms.ipynb
inital_image_weight =  0.# @param {type: "number"}
learning_rate_1 = 0.1 # @param {type: "number"}
learning_rate_2 =  0.01# @param {type: "number"}
learning_rate_step_switch =  -1# @param {type: "number"}
learning_rate_schedule = "constant" #@param ["constant", "linear", "cosine", "step"] {allow-input: false}

seed =  -1#@param {type: "number"}
start_at_prompt =  0#@param {type: "number"}
new_seed_per_prompt = False #@param {type: "boolean"}
reinitialise_model = False #@param {type: "boolean"}

"""##Experimental Options
These are features that are in development and may not work yet - if something odd is happening, turn things off.
"""

# colab form fields can be found here: https://colab.research.google.com/notebooks/forms.ipynb
lock_image = False #@param {type: "boolean"}
# @markdown 'Inifinte zoom' options. 
zoom_on = False #@param {type: "boolean"}
zoom_every_n_frames =  0# @param {type: "number"}
zoom_percent =  0.001# @param {type: "number"}
stabiliser_steps =  1# @param {type: "number"}

#@title Setup parameters
# set up the learning rate scheduler
if learning_rate_schedule == 'constant':
  learning_rate_scheduler = lrs_constant
elif learning_rate_schedule == 'linear':
  learning_rate_scheduler = lrs_linear
elif learning_rate_schedule == 'cosine':
  learning_rate_scheduler = lrs_cosine
elif learning_rate_schedule == 'step':
  learning_rate_scheduler = lrs_step
# default learning rate switch to max it
if learning_rate_step_switch == -1:
  learning_rate_step_switch = max_iterations

step_size = learning_rate_1

"""
# summarise parameters:
print('Notebook settings:')
print('text_prompt',text_prompt)
print('width',width)
print('height',height)
print('model',model)
print('start_image',start_image)
print('target_images',target_images)
print('seed',seed)
print('new_seed_per_prompt',new_seed_per_prompt)
print('max_iterations',max_iterations)
print('inital_image_weight',inital_image_weight)
print('step_size',step_size)
print('zoom_every_n_frames',zoom_every_n_frames)
print('zoom_percent',zoom_percent)
print('stabiliser_steps',stabiliser_steps)
"""

input_images = ""
zoom_every_n_frames = int(zoom_every_n_frames)
if zoom_percent >= 1:
  zoom_percent /= 100
if zoom_on:
  # we want to start again every N frames
  zoom_max_iterations = max_iterations
  max_iterations = zoom_every_n_frames
  first_run_steps = stabiliser_steps
  print('Zoom mode activated')
if lock_image:
  zoom_on = False
  first_run_steps = stabiliser_steps
  # generate a simple lock mask for testing
  # change the centre only
  lock_mask = np.zeros((height, width))
  
  msx = int(width/2-100)
  mex = int(width/2+100)
  msy = int(height/2-100)
  mey = int(height/2+100)
  lock_mask[msy:mey,msx:mex] = 1
  lock_mask = Image.fromarray(lock_mask.astype(bool))

  # use some zoom code to set up the switching
  zoom_every_n_frames = 1
  zoom_max_iterations = max_iterations
  max_iterations = 1

else:
  zoom_on = False
  first_run_steps = max_iterations

subsequent_run_steps = max_iterations

# separate prompts by ||
all_text = []
for text in text_prompt.split('||'):
  all_text.append([phrase.strip() for phrase in text.split("|")])
num_prompts = len(all_text)

# if we're zooming, only have a single prompt (for now)
# basically use it a new text prompt
# same for an image mask
if zoom_on or lock_image:
  num_prompts = np.ceil(zoom_max_iterations / zoom_every_n_frames).astype(int)
  all_text = [all_text[0]] * num_prompts

# english -> spanish
textos = text_prompt
ancho =  width
alto =  height
modelo = model
intervalo_imagenes = image_range
imagen_inicial = start_image
imagenes_objetivo = target_images

nombres_modelos={"vqgan_imagenet_f16_16384": 'ImageNet 16384',"vqgan_imagenet_f16_1024":"ImageNet 1024", 
                 "wikiart_1024":"WikiArt 1024", "wikiart_16384":"WikiArt 16384", "coco":"COCO-Stuff", "faceshq":"FacesHQ", "sflckr":"S-FLCKR"}
nombre_modelo = nombres_modelos[modelo]     

if imagen_inicial == "None":
    imagen_inicial = None
if imagenes_objetivo == "None" or not imagenes_objetivo:
    imagenes_objetivo = []
else:
    imagenes_objetivo = imagenes_objetivo.split("|")
    imagenes_objetivo = [image.strip() for image in imagenes_objetivo]

if imagen_inicial or imagenes_objetivo != []:
    input_images = True

textos = [frase.strip() for frase in textos.split("|")]
if textos == ['']:
    textos = []

#@title Validate inputs
# @markdown Check each of the prompts parses correctly before processing.
failed = False
for prompt in all_text:
  try:
    for prompt_part in prompt:
      txt, weight, stop = parse_prompt(prompt_part)
      #print(txt)
  except:
    failed = True
    print('Failed to parse prompt:',prompt)

  # only do it once for zooming or locking
  if zoom_on or lock_image:
    break


# check for the initial image - reset to none if there
import os
if imagen_inicial is not None:
  if not os.path.isfile(imagen_inicial):
    print('WARNING: Initial image',imagen_inicial,'not found - resetting to None')
    imagen_inicial = None

#@title Run the model...

args = argparse.Namespace(
    prompts=all_text[0],
    image_prompts=imagenes_objetivo,
    noise_prompt_seeds=[],
    noise_prompt_weights=[],
    size=[ancho, alto],
    init_image=imagen_inicial,
    init_weight=inital_image_weight,
    #clip_model='ViT-B/32',
    #vqgan_config=f'{modelo}.yaml',
    #vqgan_checkpoint=f'{modelo}.ckpt',
    step_size=step_size,
    cutn=64,
    cut_pow=1.,
    display_freq=intervalo_imagenes,
    seed=seed,
    clip_model=args2.clip_model,
    vqgan_config=f'{args2.vqgan_model}.yaml',
    vqgan_checkpoint=f'{args2.vqgan_model}.ckpt',
)

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

"""
print('Using device:', device)
if textos:
    print('Using text:', all_text[0])
if imagenes_objetivo:
    print('Using image prompts:', imagenes_objetivo)
"""

sys.stdout.write("Loading VQGAN model "+args.vqgan_checkpoint+" ...\n")
sys.stdout.flush()

model = load_vqgan_model(args.vqgan_config, args.vqgan_checkpoint).to(device)

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

cut_size = perceptor.visual.input_resolution
e_dim = model.quantize.e_dim
f = 2**(model.decoder.num_resolutions - 1)
make_cutouts = MakeCutouts(cut_size, args.cutn, cut_pow=args.cut_pow)
n_toks = model.quantize.n_e
toksX, toksY = args2.sizex // f, args2.sizey // f
sideX, sideY = toksX * f, toksY * f
z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]


if args.init_image:
    pil_image = Image.open(args.init_image).convert('RGB')
    pil_image = pil_image.resize((sideX, sideY), Image.LANCZOS)
    z, *_ = model.encode(TF.to_tensor(pil_image).to(device).unsqueeze(0) * 2 - 1)
else:
    one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
    z = one_hot @ model.quantize.embedding.weight
    z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)
z_orig = z.clone()
z.requires_grad_(True)
opt = optim.Adam([z], lr=args.step_size)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

pMs = []

for prompt in args.prompts:
    txt, weight, stop = parse_prompt(prompt)
    embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))

for prompt in args.image_prompts:
    path, weight, stop = parse_prompt(prompt)
    img = resize_image(Image.open(path).convert('RGB'), (sideX, sideY))
    batch = make_cutouts(TF.to_tensor(img).unsqueeze(0).to(device))
    embed = perceptor.encode_image(normalize(batch)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))

for seed, weight in zip(args.noise_prompt_seeds, args.noise_prompt_weights):
    gen = torch.Generator().manual_seed(seed)
    embed = torch.empty([1, perceptor.visual.output_dim]).normal_(generator=gen)
    pMs.append(Prompt(embed, weight).to(device))

def synth(z):
    z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)
    return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

def add_xmp_data(nombrefichero):
    imagen = ImgTag(filename=nombrefichero)
    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'creator', 'VQGAN+CLIP', {"prop_array_is_ordered":True, "prop_value_is_array":True})
    if args.prompts:
        imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'title', " | ".join(args.prompts), {"prop_array_is_ordered":True, "prop_value_is_array":True})
    else:
        imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'title', 'None', {"prop_array_is_ordered":True, "prop_value_is_array":True})
    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'i', str(i), {"prop_array_is_ordered":True, "prop_value_is_array":True})
    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'model', nombre_modelo, {"prop_array_is_ordered":True, "prop_value_is_array":True})
    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'seed',str(seed) , {"prop_array_is_ordered":True, "prop_value_is_array":True})
    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'input_images',str(input_images) , {"prop_array_is_ordered":True, "prop_value_is_array":True})
    #for frases in args.prompts:
    #    imagen.xmp.append_array_item(libxmp.consts.XMP_NS_DC, 'Prompt' ,frases, {"prop_array_is_ordered":True, "prop_value_is_array":True})
    imagen.close()

def add_stegano_data(filename):
    data = {
        "title": " | ".join(args.prompts) if args.prompts else None,
        "notebook": "VQGAN+CLIP",
        "i": i,
        "model": nombre_modelo,
        "seed": str(seed),
        "input_images": input_images
    }
    lsb.hide(filename, json.dumps(data)).save(filename)

@torch.no_grad()
def checkin(i, losses):
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
    out = synth(z)
    #TF.to_pil_image(out[0].cpu()).save('progress.png')
    outim=TF.to_pil_image(out[0].cpu()).resize((args2.sizex, args2.sizey), Image.LANCZOS)
    outim.save(args2.image_file)
    
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
        outim.save(save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()


def ascend_txt():
    global i
    out = synth(z)
    iii = perceptor.encode_image(normalize(make_cutouts(out))).float()

    result = []

    if args.init_weight:
        result.append(F.mse_loss(z, z_orig) * args.init_weight / 2)

    for prompt in pMs:
        result.append(prompt(iii))
    """
    img = np.array(out.mul(255).clamp(0, 255)[0].cpu().detach().numpy().astype(np.uint8))[:,:,:]
    img = np.transpose(img, (1, 2, 0))
    #filename = f"steps/001_{i:04}.png"
    filename = "Progress.png"
    imageio.imwrite(filename, np.array(img))
    add_stegano_data(filename)
    add_xmp_data(filename)
    """
    return result

def train(i):
    opt.zero_grad()
    lossAll = ascend_txt()
    sys.stdout.write("Iteration {}".format(i)+"\n")
    sys.stdout.flush()
    if i % args2.update == 0:
        checkin(i, lossAll)
    loss = sum(lossAll)
    loss.backward()
    opt.step()
    # update lr
    opt.lr = learning_rate_scheduler(learning_rate_1,learning_rate_2,learning_rate_step_switch,i)
    with torch.no_grad():
        z.copy_(z.maximum(z_min).minimum(z_max))

"""
if start_at_prompt <= 1:
  i = 0
  try:
      with tqdm() as pbar:
          while True:
              train(i)
              if i == first_run_steps:
                  break
              i += 1
              pbar.update()
  except KeyboardInterrupt:
      pass

last_run_steps = min(i,first_run_steps)
"""

sys.stdout.write("Starting ...\n")
sys.stdout.flush()
  
itt = 1
for i in range(args2.iterations):
  train(itt)
  itt+=1
  
  

