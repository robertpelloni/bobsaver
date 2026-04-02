# Masked Prompts VQGANCLIP_zquantize_MSEReg public.ipynb
# Original file is located at https://colab.research.google.com/drive/1B9hPy1-6qhnRL3JNusFmfyWoYvjiJ1jq

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import argparse
from collections import defaultdict
import random
import argparse
import math
from pathlib import Path
import sys

sys.path.append('./taming-transformers')

#from IPython import display
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
#from tqdm.notebook import tqdm
import numpy as np
from CLIP import clip
import kornia.augmentation as K





sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update rate')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--init_image', type=str, help='Init image.')
  parser.add_argument('--prompt_key_image', type=str, help='Init image.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

"""
#uncommenting this makes it SUPER SLOW?!!!
if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 
"""    




# Commented out IPython magic to ensure Python compatibility.
def noise_gen(shape):
    n, c, h, w = shape
    noise = torch.zeros([n, c, 1, 1])
    for i in reversed(range(5)):
        h_cur, w_cur = h // 2**i, w // 2**i
        noise = F.interpolate(noise, (h_cur, w_cur), mode='bicubic', align_corners=False)
        noise += torch.randn([n, c, h_cur, w_cur]) / 5
    return noise


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
    

# def replace_grad(fake, real):
#     return fake.detach() - real.detach() + real


class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


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

replace_grad = ReplaceGrad.apply

clamp_with_grad = ClampWithGrad.apply
# clamp_with_grad = torch.clamp

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
        
        input_normed = F.normalize(input.unsqueeze(1), dim=2)#(input / input.norm(dim=-1, keepdim=True)).unsqueeze(1)# 
        embed_normed = F.normalize((self.embed).unsqueeze(0), dim=2)#(self.embed / self.embed.norm(dim=-1, keepdim=True)).unsqueeze(0)#

        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()


def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])

def one_sided_clip_loss(input, target, labels=None, logit_scale=100):
    input_normed = F.normalize(input, dim=-1)
    target_normed = F.normalize(target, dim=-1)
    logits = input_normed @ target_normed.T * logit_scale
    if labels is None:
        labels = torch.arange(len(input), device=logits.device)
    return F.cross_entropy(logits, labels)

class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))

    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        cutout_coords=[]
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          size = int(min_size_width*torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound, 1.)) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
          #we now add sample points from the curout region to use in looking up spatial prompts
          cutout_coords.append([offsetx,offsetx + size,offsety,offsety + size])
                                
        
        cutouts = torch.cat(cutouts, dim=0)

        # if args.use_augs:
        #   cutouts = augs(cutouts)

        # if args.noise_fac:
        #   facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, args.noise_fac)
        #   cutouts = cutouts + facs * torch.randn_like(cutouts)
        

        return clamp_with_grad(cutouts, 0, 1), cutout_coords


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
    elif config.model.target == 'taming.models.vqgan.GumbelVQ':
        model = vqgan.GumbelVQ(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model

def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)

class TVLoss(nn.Module):
    def forward(self, input):
        input = F.pad(input, (0, 1, 0, 1), 'replicate')
        x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
        y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
        diff = x_diff**2 + y_diff**2 + 1e-8
        return diff.mean(dim=1).sqrt().mean()

class GaussianBlur2d(nn.Module):
    def __init__(self, sigma, window=0, mode='reflect', value=0):
        super().__init__()
        self.mode = mode
        self.value = value
        if not window:
            window = max(math.ceil((sigma * 6 + 1) / 2) * 2 - 1, 3)
        if sigma:
            kernel = torch.exp(-(torch.arange(window) - window // 2)**2 / 2 / sigma**2)
            kernel /= kernel.sum()
        else:
            kernel = torch.ones([1])
        self.register_buffer('kernel', kernel)

    def forward(self, input):
        n, c, h, w = input.shape
        input = input.view([n * c, 1, h, w])
        start_pad = (self.kernel.shape[0] - 1) // 2
        end_pad = self.kernel.shape[0] // 2
        input = F.pad(input, (start_pad, end_pad, start_pad, end_pad), self.mode, self.value)
        input = F.conv2d(input, self.kernel[None, None, None, :])
        input = F.conv2d(input, self.kernel[None, None, :, None])
        return input.view([n, c, h, w])

class EMATensor(nn.Module):
    """implmeneted by Katherine Crowson"""
    def __init__(self, tensor, decay):
        super().__init__()
        self.tensor = nn.Parameter(tensor)
        self.register_buffer('biased', torch.zeros_like(tensor))
        self.register_buffer('average', torch.zeros_like(tensor))
        self.decay = decay
        self.register_buffer('accum', torch.tensor(1.))
        self.update()
    
    @torch.no_grad()
    def update(self):
        if not self.training:
            raise RuntimeError('update() should only be called during training')

        self.accum *= self.decay
        self.biased.mul_(self.decay)
        self.biased.add_((1 - self.decay) * self.tensor)
        self.average.copy_(self.biased)
        self.average.div_(1 - self.accum)

    def forward(self):
        if self.training:
            return self.tensor
        return self.average

"""# ARGS"""

args = argparse.Namespace(
    
    #spatial_prompts is a list of tuples (color, blindfold_prob, prompt_string)
    #color: tuple (R,G,B) 0-255.  The mask is made by the closest key-color so you don't need to be exact
    #blindfold: False or a float probability if how often to apply the blindfold (e.g. 0.9 means it will get blindfolded most of the time)
    #   The blindfolding is to prevent that prompt from seeing other parts of the image which may influence. It isn't a hard blindfold, 
    #   rather the rest of the image is heavily blurred and noise is applied. It will still get some color information as a result


    # spatial_prompts=[
    #     ( (255,0,0), 0.8, '''the essence of spring'''),
    #     ( (0,255,0), 0.8, '''the essence of summer'''),
    #     ( (0,0,255), 0.8, '''the essence of autum'''),
    #     ( (255,255,0), 0.8, '''the essence of winter'''),
    #     ( (0,255,255), 0.8, '''magic energy ball'''),
    # ],
##DO NOT EDIT THIS LINE##
    spatial_prompts=[
        ( (255,0,0), 0.2, '''a massive, dark, steampunk building filling the picture. a mass of steampunk. gray and black machine.'''),
        ( (0,255,0), 0.5, '''a beautiful lush tree on a steampunk ledge'''),
        ( (0,0,255), 0.7, '''a single small sliver of glowing moon in a blue sky'''),
        ( (0,0,0), 0.9, '''clear skies above. nothing but blue.'''),
    ],
##DO NOT EDIT THIS LINE##

    #for consistent style cues, this gets appended to the end of each spatial prompt. Can be None
    append_to_prompts = '', #'trending on artstation', 

    #optional start image (set to None if not using)
    #local path or URL
    init_image= args2.init_image, #'tower-init.png',
    init_weight= 0.5,

    #This is how the prompt mask is defined. It is an RBG image
    #local path or URL. defaults to init image if set to None
    prompt_key_image = args2.prompt_key_image, #'tower-mask.png',
    #prompt_key_image = 'https://i.ibb.co/sFZHfMB/fourmask.png', #four quadrants. red,green,blue,yellow,  cyan center dot
    #prompt_key_image = 'https://i.ibb.co/Xph568j/map.png',#two halves. left=red right=green


    #Balance these for memory constraints

    #output image size
    size=[args2.sizex,args2.sizey],#[671,512],
    # cutouts / crops (more cutn, higher quality)
    cutn=12,#16
    accum_grad_steps=5, #effectively make cutn bigger
    cut_pow=1,

    #how much to dilate the masks to cause overlap
    dilate_masks = 9,

    #set this to False to revert to normal VQGAN+CLIP (using the prompt below)
    use_spatial_prompts=True,
    prompts=["not used unless use_spatial_prompts is False"],

    cont=False, #Don't reset z. Allows beginning from previous spot/z with new prompts
    
    max_iter= args2.iterations,

    # clip model settings
    clip_model='ViT-B/32',
    vqgan_config='vqgan_imagenet_f16_16384.yaml',         
    vqgan_checkpoint='vqgan_imagenet_f16_16384.ckpt',
    step_size=0.1,
    
    
    # display
    display_freq=args2.update,
    #seed=159,    #RANDOM SEED
    use_augs = False,#these are not replicated with masks, don't use with spatial prompts
    noise_fac= 0.1,
    ema_val = 0.99,

    record_generation=False, #set to True if you want video

    # noise and other constraints
    use_noise = None,
    constraint_regions = False,#
    
    
    # add noise to embedding
    noise_prompt_weights = None,
    noise_prompt_seeds = [149],#

    # mse settings
    mse_withzeros = True,
    mse_decay_rate = 50,
    mse_epoches = 5,
    mse_quantize = True,

    # end itteration
    max_itter = -1,
)

mse_decay = 0
if args.init_weight:
  mse_decay = args.init_weight / args.mse_epoches

# <AUGMENTATIONS>
augs = nn.Sequential(
    
    K.RandomHorizontalFlip(p=0.5),
    K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
    K.RandomPerspective(0.2,p=0.4, ),
    K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),

    )

noise = noise_gen([1, 3, args.size[0], args.size[1]])
image = TF.to_pil_image(noise.div(5).add(0.5).clamp(0, 1)[0])
image.save('init3.png')

if args.use_spatial_prompts:
    assert not args.use_augs
    if not args.prompt_key_image:
        args.prompt_key_image = args.init_image
    
    #append style prompt to all spatial prompts
    if args.append_to_prompts:
        new_prompts = []
        for color,blind,prompt in args.spatial_prompts:
            if prompt[-1]==' ':
                prompt+=args.append_to_prompts
            elif prompt[-1]=='.' or prompt[-1]=='|' or prompt[-1]==',':
                prompt+=" "+args.append_to_prompts
            else:
                prompt+=". "+args.append_to_prompts
            new_prompts.append( (color,blind,prompt) )
        args.spatial_prompts = new_prompts

"""# Constraints"""

from PIL import Image, ImageDraw

if args.constraint_regions and args.init_image:
  
  device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

  toksX, toksY = args.size[0] // 16, args.size[1] // 16

  pil_image = Image.open(fetch(args.init_image)).convert('RGB')
  pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)

  width, height = pil_image.size

  d = ImageDraw.Draw(pil_image)
  for i in range(0,width,16):
      d.text((i+4,0), f"{int(i/16)}", fill=(50,200,100))
  for i in range(0,height,16):
      d.text((4,i), f"{int(i/16)}", fill=(50,200,100))

  pil_image = TF.to_tensor(pil_image)

  print(pil_image.shape)
  for i in range(pil_image.shape[1]):
    for j in range(pil_image.shape[2]):
      if i%16 == 0 or j%16 ==0:
        pil_image[:,i,j] = 0

  # select region
  c_h = [16,32]
  c_w = [0,40]

  c_hf = [i*16 for i in c_h]
  c_wf = [i*16 for i in c_w]

  pil_image[0,c_hf[0]:c_hf[1],c_wf[0]:c_wf[1]] = 0

  TF.to_pil_image(pil_image.cpu()).save('progress.png')
  #display.display(display.Image('progress.png'))

  z_mask = torch.zeros([1, 256, int(height/16), int(width/16)]).to(device)
  z_mask[:,:,c_h[0]:c_h[1],c_w[0]:c_w[1]] = 1

"""### Actually do the run..."""

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

  

if not args.cont:
    ##########
    #initialize the image

    tv_loss = TVLoss() 

    model = load_vqgan_model(args.vqgan_config, args.vqgan_checkpoint).to(device)
    perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
    mse_weight = args.init_weight

    cut_size = perceptor.visual.input_resolution
    print('cut_size = {}'.format(cut_size))
    # e_dim = model.quantize.e_dim

    if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
        e_dim = 256
        n_toks = model.quantize.n_embed
        z_min = model.quantize.embed.weight.min(dim=0).values[None, :, None, None]
        z_max = model.quantize.embed.weight.max(dim=0).values[None, :, None, None]
    else:
        e_dim = model.quantize.e_dim
        n_toks = model.quantize.n_e
        z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
        z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]


    make_cutouts = MakeCutouts(cut_size, args.cutn, cut_pow=args.cut_pow)

    f = 2**(model.decoder.num_resolutions - 1)
    toksX, toksY = args.size[0] // f, args.size[1] // f
    

    if args2.seed is not None:
        torch.manual_seed(args2.seed)

    if args.init_image:
        pil_image = Image.open(args.init_image).convert('RGB')
        pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)
        pil_image = TF.to_tensor(pil_image)
        if args.use_noise:
            pil_image = pil_image + args.use_noise * torch.randn_like(pil_image) 
        z, *_ = model.encode(pil_image.to(device).unsqueeze(0) * 2 - 1)

    else:
        
        one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()

        if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
            z = one_hot @ model.quantize.embed.weight
        else:
            z = one_hot @ model.quantize.embedding.weight
        z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)


    z = EMATensor(z, args.ema_val)

    if args.mse_withzeros and not args.init_image:
        z_orig = torch.zeros_like(z.tensor)
    else:
        z_orig = z.tensor.clone()


    opt = optim.Adam(z.parameters(), lr=args.step_size, weight_decay=0.00000000)

    normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                    std=[0.26862954, 0.26130258, 0.27577711])

########################
#Get prompts set up

if not args.use_spatial_prompts:
  print('using prompts: ', args.prompts)
  all_prompts = args.prompts
else:

  #Make prompt masks
  prompt_key_image = Image.open(args.prompt_key_image).convert('RGB')
  prompt_key_image = np.asarray(prompt_key_image)

  #Set up color->prompt map
  color_to_prompt_idx={}
  all_prompts=[]
  blindfold=[]
  for i,(color_key,blind,prompt) in enumerate(args.spatial_prompts):
    all_prompts.append(prompt)
    blindfold.append(blind)
    color_to_prompt_idx[color_key] = i
  
  color_to_prompt_idx_orig = dict(color_to_prompt_idx)

  #init the masks
  prompt_masks = torch.FloatTensor(
      len(args.spatial_prompts),
      1, #color channel
      prompt_key_image.shape[0],
      prompt_key_image.shape[1]).fill_(0)

  #go pixel by pixel and assign it to one mask, based on closest color
  for y in range(prompt_key_image.shape[0]):
      for x in range(prompt_key_image.shape[1]):
          key_color = tuple(prompt_key_image[y,x])

          if key_color not in color_to_prompt_idx:
            min_dist=999999
            best_idx=-1
            for color,idx in color_to_prompt_idx_orig.items():
              dist = abs(color[0]-key_color[0])+abs(color[1]-key_color[1])+abs(color[2]-key_color[2])
              #print('{} - {} = {}'.format(color,key_color,dist))
              if dist<min_dist:
                min_dist = dist
                best_idx=idx
            color_to_prompt_idx[key_color]=best_idx #store so we don't need to compare again
            idx = best_idx
          else:
            idx = color_to_prompt_idx[key_color]

          prompt_masks[idx,0,y,x]=1

  prompt_masks = prompt_masks.to(device)

  #dilate masks to prevent possible disontinuity artifacts
  if args.dilate_masks:
    struct_ele = torch.FloatTensor(1,1,args.dilate_masks,args.dilate_masks).fill_(1).to(device)
    prompt_masks = F.conv2d(prompt_masks,struct_ele,padding='same')

  #resize masks to output size
  prompt_masks = F.interpolate(prompt_masks,(toksY * 16, toksX * 16))

  #make binary
  prompt_masks[prompt_masks>0.1]=1

  #rough display
  #if prompt_masks.size(0)>=3:
    #print('first 3 masks')
    #TF.to_pil_image(prompt_masks[0:3,0].cpu()).save('ex-masks.png')   
    #display.display(display.Image('ex-masks.png')) 
    #if prompt_masks.size(0)>=6:
      #print('next 3 masks')
      #TF.to_pil_image(prompt_masks[3:6,0].cpu()).save('ex-masks.png')   
      #display.display(display.Image('ex-masks.png')) 
  
  if any(blindfold):
      #Set up blur used in blindfolding
      k=13
      blur_conv = torch.nn.Conv2d(3,3,k,1,'same',bias=False,padding_mode='reflect',groups=3)
      for param in blur_conv.parameters():
          param.requires_grad = False
      blur_conv.weight[:] = 1/(k**2)

      blur_conv = blur_conv.to(device)
  else:
      blur_conv = None

  num_prompts = len(all_prompts)

#Embed prompts
pMs = []

if args.noise_prompt_weights and args.noise_prompt_seeds:
  for seed, weight in zip(args.noise_prompt_seeds, args.noise_prompt_weights):
    gen = torch.Generator().manual_seed(seed)
    embed = torch.empty([1, perceptor.visual.output_dim]).normal_(generator=gen)
    pMs.append(Prompt(embed, weight).to(device))

for prompt in all_prompts:
    txt, weight, stop = parse_prompt(prompt)
    embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))
    # pMs[0].embed = pMs[0].embed + Prompt(embed, weight, stop).embed.to(device)


def synth(z, quantize=True):
    if args.constraint_regions:
      z = replace_grad(z, z * z_mask)

    if quantize:
      if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embed.weight).movedim(3, 1)
      else:
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)

    else:
      z_q = z.model

    return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

@torch.no_grad()
def checkin(i, losses):
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    #losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
    out = synth(z.average, True)

    TF.to_pil_image(out[0].cpu()).save(args2.image_file)   
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
        TF.to_pil_image(out[0].cpu()).save(save_name)   
    

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()


def ascend_txt():
    global mse_weight

    out = synth(z.tensor)

    if args.record_generation:
      with torch.no_grad():
        global vid_index
        out_a = synth(z.average, True)
        TF.to_pil_image(out_a[0].cpu()).save(f'./vids/{vid_index}.png')#f'/content/vids/{vid_index}.png')
    vid_index += 1


    cutouts,cutout_coords = make_cutouts(out)

    #TODO divide cutouts into seperate bins based on location to apply different prompts (pM) to

    if args.use_augs:
      cutouts = augs(cutouts)

    if args.noise_fac:
      facs = cutouts.new_empty([args.cutn, 1, 1, 1]).uniform_(0, args.noise_fac)
      cutouts = cutouts + facs * torch.randn_like(cutouts)

    if args.use_spatial_prompts:
        cutouts_detached = cutouts.detach() #used to prevent gradient for unmask parts
        if blur_conv is not None:
            #Get the "blindfolded" image by blurring then addimg more noise
            facs = cutouts.new_empty([cutouts.size(0), 1, 1, 1]).uniform_(0, args.noise_fac)
            cutouts_blurred = blur_conv(cutouts_detached)+ facs * torch.randn_like(cutouts_detached)

        #get mask patches
        cutout_prompt_masks = []
        for (x1,x2,y1,y2) in cutout_coords:
            cutout_mask = prompt_masks[:,:,y1:y2,x1:x2]
            cutout_mask = resample(cutout_mask, (cut_size, cut_size))
            cutout_prompt_masks.append(cutout_mask)
        cutout_prompt_masks = torch.stack(cutout_prompt_masks,dim=1) #-> prompts X cutouts X color X H X W
        
        #apply each prompt, masking gradients
        prompts_gradient_masked_cutouts = []
        for idx,prompt in enumerate(pMs):
            keep_mask = cutout_prompt_masks[idx] #-> cutouts X color X H X W
            #only apply this prompt if one image has a (big enough) part of mask
            if keep_mask.sum(dim=3).sum(dim=2).max()> cut_size*2:
                
                block_mask = 1-keep_mask

                #compose cutout of gradient and non-gradient parts
                if blindfold[idx] and ((not isinstance(blindfold[idx],float)) or blindfold[idx]>random.random()):
                    gradient_masked_cutouts = keep_mask*cutouts + block_mask*cutouts_blurred
                else:
                    gradient_masked_cutouts = keep_mask*cutouts + block_mask*cutouts_detached
                # if vid_index%100==0:
                #     print('prompt {} cut and mask'.format(idx))
                #     TF.to_pil_image(gradient_masked_cutouts[0].cpu()).save('ex-masks.png')   
                #     display.display(display.Image('ex-masks.png')) 
                #     TF.to_pil_image(keep_mask[0].cpu()).save('ex-masks.png')   
                #     display.display(display.Image('ex-masks.png')) 
                prompts_gradient_masked_cutouts.append(gradient_masked_cutouts)
        cutouts = torch.cat(prompts_gradient_masked_cutouts,dim=0)
    iii = perceptor.encode_image(normalize(cutouts)).float()

    result = []

    if args.init_weight:
        
        global z_orig
        
        result.append(F.mse_loss(z.tensor, z_orig) * mse_weight / 2)
        # result.append(F.mse_loss(z, z_orig) * ((1/torch.tensor((i)*2 + 1))*mse_weight) / 2)

        with torch.no_grad():
          if i > 0 and i%args.mse_decay_rate==0 and i <= args.mse_decay_rate*args.mse_epoches:

            if args.mse_quantize:
              z_orig = vector_quantize(z.average.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)#z.average
            else:
              z_orig = z.average.clone()

            if mse_weight - mse_decay > 0 and mse_weight - mse_decay >= mse_decay:
              mse_weight = mse_weight - mse_decay
              print(f"updated mse weight: {mse_weight}")
            else:
              mse_weight = 0
              print(f"updated mse weight: {mse_weight}")

    
    
    if args.use_spatial_prompts:
      for prompt_masked_iii,prompt in zip(torch.chunk(iii,num_prompts,dim=0),pMs):
        result.append(prompt(prompt_masked_iii))
    else:
      for prompt in pMs:
          result.append(prompt(iii))

    return result

vid_index = 0
def train(i):
    if args.accum_grad_steps<2 or i%args.accum_grad_steps==0:
        opt.zero_grad()
    lossAll = ascend_txt()

    sys.stdout.write("Iteration {}".format(i)+"\n")
    sys.stdout.flush()
    
    if i > 0 and i % args.display_freq == 0:
        checkin(i, lossAll)
    
    loss = sum(lossAll)/len(lossAll)
    
    if args.accum_grad_steps>1:
        loss /= args.accum_grad_steps

    loss.backward()
    
    if args.accum_grad_steps<2 or i%args.accum_grad_steps==args.accum_grad_steps-1:
        opt.step()
        z.update()


sys.stdout.write("Starting ...\n")
sys.stdout.flush()

i = 0
try:
    while i <= args.max_iter:

        train(i)

        if i > 0 and i%args.mse_decay_rate==0 and i <= args.mse_decay_rate * args.mse_epoches:
          z = EMATensor(z.average, args.ema_val)
          opt = optim.Adam(z.parameters(), lr=args.step_size, weight_decay=0.00000000)

        i += 1

except KeyboardInterrupt:
    pass

"""# create video"""

##you must have record_generation set to True to make the video
#%cd vids
#
#images = "%d.png"
#video = "./video.mp4"
#!ffmpeg -r 30 -i $images -crf 20 -s 640x512 -pix_fmt yuv420p $video
#%cd ..

#%cd vids
#%rm *.png
#%cd ..

"""delete all frames from folder"""

#%cd vids
#%rm *.png
#%cd ..
