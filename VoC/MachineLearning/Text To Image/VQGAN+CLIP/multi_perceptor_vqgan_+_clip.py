# Multi Perceptor VQGAN + CLIP [Public]
# Original file is located at https://colab.research.google.com/drive/1peZ98vBihDD9A1v7JdH5VvHDUuW5tcRK
# by [@remi_durant](https://twitter/remi_durant)

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./clip')
sys.path.append('./taming-transformers')

import os
import argparse
import math
from pathlib import Path
from IPython import display
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
import numpy as np
import os.path
from os import path
from CLIP import clip
import kornia
import kornia.augmentation as K
from torch.utils.checkpoint import checkpoint
from fastprogress.fastprogress import master_bar, progress_bar
import random
import gc

#In Script Movement
sys.path.append('../')
from image_warping import do_image_warping
from torchvision.transforms import functional as TF

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
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--clip_model_1', type=str, help='CLIP model 1 to load.')
  parser.add_argument('--clip_model_2', type=str, help='CLIP model 2 to load.')
  parser.add_argument('--clip_1_weight', type=float, help='CLIP 1 weight.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  parser.add_argument('--r', type=float, help='In script movement. Rotation in degrees.')
  parser.add_argument('--z', type=int, help='In script movement. Zoom in pixels.')
  parser.add_argument('--px', type=int, help='In script movement. Pan X in pixels.')
  parser.add_argument('--py', type=int, help='In script movement. Pan Y in pixels.')
  parser.add_argument('--w', type=int, help='In script movement. Warp in pixels.')
  args = parser.parse_args()
  return args

args2=parse_args();

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
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            size = int(min_size_width*torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound, 1.)) # replace .5 with a result for 224 the default large size is .95
          
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))

        cutouts = torch.cat(cutouts, dim=0)

        return clamp_with_grad(cutouts, 0, 1)


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
  
import io
import base64
def image_to_data_url(img, ext):  
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format=ext)
    img_byte_arr = img_byte_arr.getvalue()
    # ext = filename.split('.')[-1]
    prefix = f'data:image/{ext};base64,'
    return prefix + base64.b64encode(img_byte_arr).decode('utf-8')
 

def update_random( seed, purpose ):
  if seed == -1:
    seed = random.seed()
    seed = random.randrange(1,99999)
    
  #print( f'Using seed {seed} for {purpose}')
  random.seed(seed)
  torch.manual_seed(seed)
  np.random.seed(seed)

def clear_memory():
  gc.collect()
  torch.cuda.empty_cache()

# %mkdir /content/vids

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))


#if gpu.name.startswith('A100'):
#  torch.backends.cudnn.enabled = False
#  print('Finished setup for A100')

#@title Loss Module Definitions
class MultiClipLoss(nn.Module):
    def __init__(self, clip_models, text_prompt, cutn, cut_pow=1., clip_weight=1. ):
        super().__init__()

        # Load Clip
        self.perceptors = []
        for cm in clip_models:
          sys.stdout.write(f"Loading {cm[0]}...\n")
          sys.stdout.flush()
          c = clip.load(cm[0], jit=False)[0].eval().requires_grad_(False).to(device)
          self.perceptors.append( { 'res': c.visual.input_resolution, 'perceptor': c, 'weight': cm[1], 'prompts':[] } )        
        self.perceptors.sort(key=lambda e: e['res'], reverse=True)
        
        # Make Cutouts
        self.max_cut_size = self.perceptors[0]['res']
        self.make_cuts = MakeCutouts(self.max_cut_size, cutn, cut_pow)

        # Get Prompt Embedings
        texts = [phrase.strip() for phrase in text_prompt.split("|")]
        if text_prompt == ['']:
          texts = []

        self.pMs = []
        for prompt in texts:
          txt, weight, stop = parse_prompt(prompt)
          clip_token = clip.tokenize(txt).to(device)
          for p in self.perceptors:
            embed = p['perceptor'].encode_text(clip_token).float()
            embed_normed = F.normalize(embed.unsqueeze(0), dim=2)
            p['prompts'].append({'embed_normed':embed_normed,'weight':torch.as_tensor(weight, device=device),'stop':torch.as_tensor(stop, device=device)})
    
        # Prep Augments
        self.normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])        
        self.augs = nn.Sequential(
            K.RandomHorizontalFlip(p=0.5),
            K.RandomSharpness(0.3,p=0.1),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
            K.RandomPerspective(0.2,p=0.4, ),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),
            K.RandomGrayscale(p=0.15)          
        )
        self.noise_fac = 0.1
        self.clip_weight = clip_weight

    def prepare_cuts(self,img):
      cutouts = self.make_cuts(img)
      cutouts = self.augs(cutouts)
      if self.noise_fac:
          facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, self.noise_fac)
          cutouts = cutouts + facs * torch.randn_like(cutouts)
      cutouts = self.normalize(cutouts)
      return cutouts

    def forward( self, i, img ):
      cutouts = checkpoint( self.prepare_cuts, img )
      loss = []
      
      current_cuts = cutouts
      currentres = self.max_cut_size
      for p in self.perceptors:
          if currentres != p['res']:
              current_cuts = resample(cutouts,(p['res'],p['res']))
              currentres = p['res']

          iii = p['perceptor'].encode_image(current_cuts).float()
          input_normed = F.normalize(iii.unsqueeze(1), dim=2)
          for prompt in p['prompts']:
            dists = input_normed.sub(prompt['embed_normed']).norm(dim=2).div(2).arcsin().pow(2).mul(2)
            dists = dists * prompt['weight'].sign()
            l = prompt['weight'].abs() * replace_grad(dists, torch.maximum(dists, prompt['stop'])).mean()
            loss.append(l * p['weight'])

      return loss

class MSEDecayLoss(nn.Module):
    def __init__(self, init_weight, mse_decay_rate, mse_epoches, mse_quantize ):
        super().__init__()
      
        self.init_weight = init_weight
        self.has_init_image = False
        self.mse_decay = init_weight / mse_epoches if init_weight else 0 
        self.mse_decay_rate = mse_decay_rate
        self.mse_weight = init_weight
        self.mse_epoches = mse_epoches
        self.mse_quantize = mse_quantize

    @torch.no_grad()
    def set_target( self, z_tensor, model ):
        z_tensor = z_tensor.detach().clone()
        if self.mse_quantize:
            z_tensor = vector_quantize(z_tensor.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)#z.average
        self.z_orig = z_tensor
          
    def forward( self, i, z ):
        if not self.init_weight:
          return 0
        if i <= self.mse_decay_rate and not self.has_init_image:
          return 0
        
        return F.mse_loss(z, self.z_orig) * self.mse_weight / 2

    @torch.no_grad()
    def step( self, i ):

        if i % self.mse_decay_rate == 0 and i != 0 and i < self.mse_decay_rate * self.mse_epoches:
            
            if self.mse_weight - self.mse_decay > 0 and self.mse_weight - self.mse_decay >= self.mse_decay:
              self.mse_weight -= self.mse_decay
            else:
              self.mse_weight = 0
            print(f"updated mse weight: {self.mse_weight}")

            return True

        return False
  
class TVLoss(nn.Module):
    def forward(self, input):
        input = F.pad(input, (0, 1, 0, 1), 'replicate')
        x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
        y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
        diff = x_diff**2 + y_diff**2 + 1e-8
        return diff.mean(dim=1).sqrt().mean()


def get_vqgan_model(image_model):
    vqgan_config=f'{image_model}.yaml'
    vqgan_checkpoint=f'{image_model}.ckpt'

    sys.stdout.write(f"Loading {image_model}...\n")
    sys.stdout.flush()

    model = load_vqgan_model(vqgan_config, vqgan_checkpoint).to(device)
    return model

#@title Do the Run

#text_prompt = 'The Enchanted Garden by James Gurney'#@param {type:'string'}
text_prompt = args2.prompt
vqgan_model = args2.vqgan_model #'vqgan_imagenet_f16_16384'#@param [ "vqgan_imagenet_f16_1024", "vqgan_imagenet_f16_16384", "vqgan_openimages_f16_8192", "coco", "faceshq", "wikiart_1024", "wikiart_16384", "sflckr"]
gen_seed = args2.seed#@param {type:'number'}

if args2.seed_image is None:
    init_image = ''
else:
    init_image = args2.seed_image#@param {type:'string'}


width = args2.sizex #1120#@param {type:'number'}
height = args2.sizey #480#@param {type:'number'}
max_iter = args2.iterations #501 #@param {type:'number'}
ema_val = 0.99
clip_model = args2.clip_model_1 #'ViT-B/32' #@param ["ViT-B/16", "ViT-B/32", "RN50x16", "RN50x4"]
clip_model2 = args2.clip_model_2 #'ViT-B/16' #@param ["None","ViT-B/16", "ViT-B/32", "RN50x16", "RN50x4"]
clip1_weight = args2.clip_1_weight #0.5 #@param {type:"slider", min:0, max:1, step:0.01}
cut_n = args2.cutn #64 #@param {type:'number'}
cut_pow = args2.cut_power #1. #@param {type:'number'}
if clip_model2 == "None":
  clip_model2 = None 

learning_rate = args2.learning_rate#@param {type:'number'}
learning_rate_epoch = 0.2#@param {type:'number'}
mse_weight = 0.5 #@param {type:'number'}
tv_weight = 0.00 #@param {type:'number'}

use_ema_tensor = False #@param {type:'boolean'}
output_as_png = False #@param {type:'boolean'}

#print('Using device:', device)
#print('using prompts: ', text_prompt)

clear_memory()

model = get_vqgan_model( vqgan_model )

if clip_model2:
  clip_models = [[clip_model, clip1_weight], [clip_model2, 1. - clip1_weight]]
else:
  clip_models = [[clip_model, 1.0]]
#print(clip_models)

clip_loss = MultiClipLoss( clip_models, text_prompt, cutn=cut_n, cut_pow=cut_pow )
  
mse_loss = MSEDecayLoss( mse_weight, mse_decay_rate=50, mse_epoches=5, mse_quantize=True )
tv_loss = TVLoss() 

update_random( gen_seed, 'image generation')
    
# Make Z Init
z = 0

f = 2**(model.decoder.num_resolutions - 1)
toksX, toksY = width // f, height // f

if init_image != "":
    if 'http' in init_image:
      req = Request(init_image, headers={'User-Agent': 'Mozilla/5.0'})
      img = Image.open(urlopen(req))
    else:
      img = Image.open(init_image)

    pil_image = img.convert('RGB')
    pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)
    pil_image = TF.to_tensor(pil_image)
    #if args.use_noise:
    #  pil_image = pil_image + args.use_noise * torch.randn_like(pil_image) 
    z, *_ = model.encode(pil_image.to(device).unsqueeze(0) * 2 - 1)
    del pil_image
    del img
    mse_loss.has_init_image = True

else:
    e_dim = model.quantize.e_dim
    n_toks = model.quantize.n_e
    z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
    z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]

    one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
    z = one_hot @ model.quantize.embedding.weight
    z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)
    del z_min
    del z_max
    del one_hot

z = EMATensor(z, ema_val)
mse_loss.set_target( z.tensor, model )

opt = optim.Adam( z.parameters(), lr=learning_rate, weight_decay=0.00000000)

losses = []
mb = master_bar(range(1))
gnames = ['losses']

## optimizer loop

def synth(z, quantize=True, scramble=True):
    z_q = 0
    if quantize:
      z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)
    else:
      z_q = z.model

    out = clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

    return out

@torch.no_grad()
def checkin(i, z, out, losses):
    #global z
    global opt

    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    #losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')

    if use_ema_tensor:
      out = synth( z.average )
    
    """
    display_format='png' if output_as_png else 'jpeg'
    pil = TF.to_pil_image(out[0].cpu())
    pil_data = image_to_data_url(pil, display_format)
    display.display(display.HTML(f'<img src="{pil_data}" />'))
    """

    pil = TF.to_pil_image(out[0].cpu())
    
    pil.save(args2.image_file)
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
        pil.save(save_name)
    
    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

    #In Script Movement - make sure "global z" and "global opt" are defined
    if args2.r is not None:
        #do_image_warping(Image.fromarray(im_arr),r,z,px,py,w):  
        im_arr = np.array(out.cpu().squeeze().detach().permute(1, 2, 0)*255).astype(np.uint8)
        #Image.fromarray(im_arr).save("D:\im_arr_before.png")
        im_arr = do_image_warping(im_arr,args2.r,args2.z,args2.px,args2.py,args2.w)
        #Image.fromarray(im_arr).save("D:\im_arr_after.png")
        #convert warped image array back into the optimizer for the next iteration
        #z, *_ = model.encode(TF.to_tensor(im_arr).to(device).unsqueeze(0) * 2 - 1)
        
        pil_image = Image.fromarray(im_arr)
        pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)
        pil_image = TF.to_tensor(pil_image)
        #if args.use_noise:
        #  pil_image = pil_image + args.use_noise * torch.randn_like(pil_image) 
        z, *_ = model.encode(pil_image.to(device).unsqueeze(0) * 2 - 1)
                
        z.requires_grad_(True)
        z = EMATensor(z, ema_val)
        opt = optim.Adam( z.parameters(), lr=learning_rate, weight_decay=0.00000000)
    
    
def should_checkin(i):
  if i == max_iter: 
    return True 

  schedule = [[50,25],[500,50],[1000,100],[2000,200]]
  for s in schedule:
    if i <= s[0]:
      return i % s[1] == 0
  return i % 500 == 0


def train(i):
    global opt
    global z 
    opt.zero_grad( set_to_none = True )

    out = checkpoint( synth, z.tensor )

    lossAll = []
    lossAll += clip_loss( i,out )

    if 0 < mse_weight:
      msel = mse_loss(i,z.tensor)
      if 0 < msel:
        lossAll.append(msel)
    
    if 0 < tv_weight:
      lossAll.append(tv_loss(out)*tv_weight)
    
    loss = sum([sum(lossAll)])
    loss.backward()

    sys.stdout.write("Iteration {}".format(i)+"\n")
    sys.stdout.flush()
    
    #if should_checkin(i):
    if i % args2.update == 0:
      checkin(i, z, out, lossAll)

    # update graph
    losses.append(loss)
    x = range(len(losses))
    mb.update_graph( [[x,losses]] )

    opt.step()
    if use_ema_tensor:
      z.update()

"""
i = 0
try:
  with tqdm() as pbar:
    while True and i <= max_iter:
      
      if i % 200 == 0:
        clear_memory()

      train(i)

      with torch.no_grad():
          if mse_loss.step(i):
              print('Reseting optimizer at mse epoch')
              mse_loss.set_target(z.tensor,model)
              z = EMATensor(z.tensor, ema_val)
              opt = optim.Adam(z.parameters(), lr=learning_rate_epoch, weight_decay=0.00000000)

      i += 1
      pbar.update()

except KeyboardInterrupt:
    pass
"""

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt = 1
for i in range(args2.iterations):
    train(itt)

    with torch.no_grad():
        if mse_loss.step(itt):
            sys.stdout.write("Resetting optimizer at mse epoch\n")
            sys.stdout.flush()
            mse_loss.set_target(z.tensor,model)
            z = EMATensor(z.tensor, ema_val)
            opt = optim.Adam(z.parameters(), lr=learning_rate_epoch, weight_decay=0.00000000)

    itt+=1
