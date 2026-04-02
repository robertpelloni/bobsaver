#360Diffusion_Beta.ipynb
#Original file is located at https://colab.research.google.com/github/sadnow/360Diffusion/blob/main/360Diffusion_Public.ipynb

#by sadnow  https://twitter.com/sadly_existent

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
import torch
import time
#import gc
import io
import math
import sys
#from IPython import display
import lpips
from PIL import Image, ImageOps
import requests
import torch
from torch import nn
from torch.nn import functional as F
import torchvision.transforms as T
import torchvision.transforms.functional as TF
sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')
import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
#from datetime import datetime
import numpy as np
import random
import os

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
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutouts', type=int, help='Number of cutouts')
  parser.add_argument('--guidance_scale', type=int, help='Guidance scale.')
  parser.add_argument('--cutout_batches', type=int, help='Cut batches.')
  parser.add_argument('--tv_scale', type=int, help='TV scale.')
  parser.add_argument('--range_scale', type=int, help='Range scale.')
  parser.add_argument('--saturation_scale', type=int, help='Saturation scale.')
  parser.add_argument('--checkpoint', type=int, help='Use checkpoints.  Slower but less VRAM.')
  parser.add_argument('--ddim', type=int, help='ddim iterations.')
  parser.add_argument('--use256', type=int, help='Use the 256x256 res diffusion model.')
  parser.add_argument('--denoised', type=int, help='CLIP denoised.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--init_scale', type=int, help='Init scale.')
  parser.add_argument('--skip_timesteps', type=int, help='Seed image skip timesteps.')
  parser.add_argument('--clip_model', type=str, help='CLIP model.', default=None)
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



itt=1

# a100_support = False #@param {type:"boolean"}

enable_error_checking = False #saves ram


#diffusion_model = "512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]
#@title Choose model here:
if args.use256==0:
    diffusion_model = "512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]
else:
    diffusion_model = "256x256_diffusion_uncond"

_drive_location = './' #@param{type:"string"}

#####################################################################
##@title Google Drive & Download diffusion model

model_path = './'

# Check the GPU status
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

#@title  { form-width: "100px" }

# https://gist.github.com/adefossez/0646dbe9ed4005480a2407c62aac8869

def add_command(var,string):
  var = (var + string + ' ')
  return var

def image_resize(filepath,width):
  from PIL import Image
  basewidth = width
  img = Image.open(filepath)
  wpercent = (basewidth/float(img.size[0]))
  hsize = int((float(img.size[1])*float(wpercent)))
  #img = img.resize((basewidth,hsize), Image.ANTIALIAS)
  if width == 1024: img = img.resize((basewidth,hsize), Image.LANCZOS)
  else: img = img.resize((basewidth,hsize), Image.BICUBIC)
  img.save(filepath)

def interp(t):
    return 3 * t**2 - 2 * t ** 3

def perlin(width, height, scale=10, device=None):
    gx, gy = torch.randn(2, width + 1, height + 1, 1, 1, device=device)
    xs = torch.linspace(0, 1, scale + 1)[:-1, None].to(device)
    ys = torch.linspace(0, 1, scale + 1)[None, :-1].to(device)
    wx = 1 - interp(xs)
    wy = 1 - interp(ys)
    dots = 0
    dots += wx * wy * (gx[:-1, :-1] * xs + gy[:-1, :-1] * ys)
    dots += (1 - wx) * wy * (-gx[1:, :-1] * (1 - xs) + gy[1:, :-1] * ys)
    dots += wx * (1 - wy) * (gx[:-1, 1:] * xs - gy[:-1, 1:] * (1 - ys))
    dots += (1 - wx) * (1 - wy) * (-gx[1:, 1:] * (1 - xs) - gy[1:, 1:] * (1 - ys))
    return dots.permute(0, 2, 1, 3).contiguous().view(width * scale, height * scale)

def perlin_ms(octaves, width, height, grayscale, device=device):
    out_array = [0.5] if grayscale else [0.5, 0.5, 0.5]
    # out_array = [0.0] if grayscale else [0.0, 0.0, 0.0]
    for i in range(1 if grayscale else 3):
        scale = 2 ** len(octaves)
        oct_width = width
        oct_height = height
        for oct in octaves:
            p = perlin(oct_width, oct_height, scale, device)
            out_array[i] += p * oct
            scale //= 2
            oct_width *= 2
            oct_height *= 2
    return torch.cat(out_array)

def create_perlin_noise(octaves=[1, 1, 1, 1], width=2, height=2, grayscale=True):
    out = perlin_ms(octaves, width, height, grayscale)
    if grayscale:
        out = TF.resize(size=(side_x, side_y), img=out.unsqueeze(0))
        out = TF.to_pil_image(out.clamp(0, 1)).convert('RGB')
    else:
        out = out.reshape(-1, 3, out.shape[0]//3, out.shape[1])
        out = TF.resize(size=(side_x, side_y), img=out)
        out = TF.to_pil_image(out.clamp(0, 1).squeeze())

    out = ImageOps.autocontrast(out)
    return out

#################################################################################################################
def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')


def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    return vals[0], float(vals[1])

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

    input = input.reshape([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)

class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, skip_augs=False):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.skip_augs = skip_augs
        self.augs = T.Compose([
            T.RandomHorizontalFlip(p=0.5),
            T.RandomAffine(degrees=15, translate=(0.1, 0.1)),
            T.RandomPerspective(distortion_scale=0.4, p=0.7),
            T.RandomGrayscale(p=0.15),
        ])


    def forward(self, input):
        input = T.Pad(input.shape[2]//4, fill=0)(input)
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)

        cutouts = []
        for ch in range(cutn):
            if ch > cutn - cutn//4:
                cutout = input.clone()
            else:
                size = int(max_size * torch.zeros(1,).normal_(mean=.8, std=.3).clip(float(self.cut_size/max_size), 1.))
                offsetx = torch.randint(0, abs(sideX - size + 1), ())
                offsety = torch.randint(0, abs(sideY - size + 1), ())
                cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]

            if not self.skip_augs:
                cutout = self.augs(cutout)
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
            del cutout

        cutouts = torch.cat(cutouts, dim=0)
        return cutouts


def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)


def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])


def range_loss(input):
    return (input - input.clamp(-1, 1)).pow(2).mean([1, 2, 3])

###
# NEWEST PERLIN NOISE EDITS
def unitwise_norm(x, norm_type=2.0):
    if x.ndim <= 1:
        return x.norm(norm_type)
    else:
        # works for nn.ConvNd and nn,Linear where output dim is first in the kernel/weight tensor
        # might need special cases for other weights (possibly MHA) where this may not be true
        return x.norm(norm_type, dim=tuple(range(1, x.ndim)), keepdim=True)
def adaptive_clip_grad(parameters, clip_factor=0.01, eps=1e-3, norm_type=2.0):
    if isinstance(parameters, torch.Tensor):
        parameters = [parameters]
    for p in parameters:
        if p.grad is None:
            continue
        p_data = p.detach()
        g_data = p.grad.detach()
        max_norm = unitwise_norm(p_data, norm_type=norm_type).clamp_(min=eps).mul_(clip_factor)
        grad_norm = unitwise_norm(g_data, norm_type=norm_type)
        clipped_grad = g_data * (max_norm / grad_norm.clamp(min=1e-6))
        new_grads = torch.where(grad_norm < max_norm, g_data, clipped_grad)
        p.grad.detach().copy_(new_grads)

def regen_perlin(): #NEWEST PERLIN UPDATE
    if perlin_mode == 'color':
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, False)
    elif perlin_mode == 'gray':
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, True)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
    else:
        init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
        init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)

    init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device).unsqueeze(0).mul(2).sub(1)
    del init2
    return init

##########################################################################################################

#@markdown ##def do_run()
def do_run():
    global firstRun,_scale_multiplier,itt
    loss_values = []

    make_cutouts = MakeCutouts(clip_size, cutn, skip_augs=skip_augs)
    target_embeds, weights = [], []

    for prompt in text_prompts:
        txt, weight = parse_prompt(prompt)
        txt = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()
        if fuzzy_prompt:
            for i in range(25):
                # target_embeds.append((txt + torch.randn(txt.shape).cuda() * rand_mag).clamp(0,1))
                target_embeds.append(txt + torch.randn(txt.shape).cuda() * rand_mag)
                weights.append(weight)
        else:
            target_embeds.append(txt)
            weights.append(weight)

    target_embeds = torch.cat(target_embeds)
    weights = torch.tensor(weights, device=device)
    if weights.sum().abs() < 1e-3:
        raise RuntimeError('The weights must not sum to 0.')
    weights /= weights.sum().abs()

    init = None
    if init_image is not None:
        init = Image.open(fetch(init_image)).convert('RGB')
        init = init.resize((side_x, side_y), Image.LANCZOS)
        init = TF.to_tensor(init).to(device).unsqueeze(0).mul(2).sub(1)
    
    cur_t = None

    def cond_fn(x, t, y=None):
        with torch.enable_grad():
            x = x.detach().requires_grad_()
            n = x.shape[0]
            my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
            out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
            fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
            x_in = out['pred_xstart'] * fac + x * (1 - fac)
            x_in_grad = torch.zeros_like(x_in)
            for i in range(cutn_batches):
                clip_in = normalize(make_cutouts(x_in.add(1).div(2)))
                image_embeds = clip_model.encode_image(clip_in).float()
                dists = spherical_dist_loss(image_embeds.unsqueeze(1), target_embeds.unsqueeze(0))
                dists = dists.view([cutn, n, -1])
                losses = dists.mul(weights).sum(2).mean(0)
                loss_values.append(losses.sum().item()) # log loss, probably shouldn't do per cutn_batch
                x_in_grad += torch.autograd.grad(losses.sum() * clip_guidance_scale, x_in)[0] / cutn_batches
            tv_losses = tv_loss(x_in)
            range_losses = range_loss(out['pred_xstart'])
            sat_losses = torch.abs(x_in - x_in.clamp(min=-1,max=1)).mean()
            loss = tv_losses.sum() * tv_scale + range_losses.sum() * range_scale + sat_losses.sum() * sat_scale
            if init is not None and init_scale:
                init_losses = lpips_model(x_in, init)
                loss = loss + init_losses.sum() * init_scale
            x_in_grad += torch.autograd.grad(loss, x_in)[0]
            grad = -torch.autograd.grad(x_in, x, x_in_grad)[0]
        if clamp_grad:
            adaptive_clip_grad([x]) #ADDED WITH PERLIN UPDATE
            magnitude = grad.square().mean().sqrt()
            return grad * magnitude.clamp(max=0.05) / magnitude
        return grad

    if model_config['timestep_respacing'].startswith('ddim'):
        sample_fn = diffusion.ddim_sample_loop_progressive
    else:
        sample_fn = diffusion.p_sample_loop_progressive

    for i in range(n_batches):
        cur_t = diffusion.num_timesteps - skip_timesteps - 1
        
        if perlin_init: 
            init = regen_perlin()

        if model_config['timestep_respacing'].startswith('ddim'):
            samples = sample_fn(
                model,
                (batch_size, 3, side_y, side_x),
                clip_denoised=clip_denoised,
                model_kwargs={},
                cond_fn=cond_fn,
                progress=False,
                skip_timesteps=skip_timesteps,
                init_image=init,
                randomize_class=randomize_class,
                eta=eta,
            )
        else:
            samples = sample_fn(
                model,
                (batch_size, 3, side_y, side_x),
                clip_denoised=clip_denoised,
                model_kwargs={},
                cond_fn=cond_fn,
                progress=False,
                skip_timesteps=skip_timesteps,
                init_image=init,
                randomize_class=randomize_class,
            )

        for j, sample in enumerate(samples):

            sys.stdout.write("Iteration {}".format(itt)+"\n")
            sys.stdout.flush()
    
            cur_t -= 1
            #if j % display_rate == 0 or cur_t == -1:  #Only single iteration has finished
            if itt % display_rate == 0:
                for k, image in enumerate(sample['pred_xstart']):
                    sys.stdout.flush()
                    sys.stdout.write("Saving progress ...\n")
                    sys.stdout.flush()

                    image = TF.to_pil_image(image.add(1).div(2).clamp(0, 1))

                    image.save(args.image_file)
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
                        image.save(save_name)

                    sys.stdout.flush()
                    sys.stdout.write("Progress saved\n")
                    sys.stdout.flush()
            itt+=1


"""# Settings & Generation"""

#timestep_respacing = 'ddim25' #@param ['25','50','100','150','250','500','1000','ddim25','ddim50','ddim100','ddim150','ddim250','ddim500','ddim1000']  
#@markdown *Modify this value to decrease the number of iterations/prompt.
# timestep_respacing = '25'
#diffusion_steps = 1000

if args.ddim == 1:
    timestep_respacing = "ddim"+str(args.iterations) #'ddim100' # Modify this value to decrease the number of timesteps.
else:
    timestep_respacing = str(args.iterations) #'ddim100' # Modify this value to decrease the number of timesteps.
# timestep_respacing = '25'
diffusion_steps = max(1000,args.iterations)



if args.checkpoint == 1:
    checkpoint=True
else:
    checkpoint=False


model_config = model_and_diffusion_defaults()
if diffusion_model == '512x512_diffusion_uncond_finetune_008100':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': diffusion_steps,
        'rescale_timesteps': True,
        'timestep_respacing': timestep_respacing,
        'image_size': 512,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint':checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
elif diffusion_model == '256x256_diffusion_uncond':
    model_config.update({
        'attention_resolutions': '32, 16, 8',
        'class_cond': False,
        'diffusion_steps': diffusion_steps,
        'rescale_timesteps': True,
        'timestep_respacing': timestep_respacing,
        'image_size': 256,
        'learn_sigma': True,
        'noise_schedule': 'linear',
        'num_channels': 256,
        'num_head_channels': 64,
        'num_res_blocks': 2,
        'resblock_updown': True,
        'use_checkpoint':checkpoint,
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })

#side_x = side_y = model_config['image_size']
side_x = args.sizex;
side_y = args.sizey;

model, diffusion = create_model_and_diffusion(**model_config)
sys.stdout.write(f"Loading {diffusion_model}.pt ...\n")
sys.stdout.flush()
model.load_state_dict(torch.load(f'{model_path}{diffusion_model}.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

################################################



sys.stdout.write(f"Loading {args.clip_model} ...\n")
sys.stdout.flush()
clip_model = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)



firstRun = True
msg_runtime = ''
_keep_first_upscale = False
_run_upscaler = True
batch_size =  1
clamp_grad = True # True - Experimental: Using adaptive clip grad in the cond_fn
skip_augs = False # False - Controls whether to skip torchvision augmentations
randomize_class = True # True - Controls whether the imagenet class is randomly changed each iteration
#############################################################################################
  # This will be the name of your project folder in Drive.

_batch_genetics = False #future implementation
_init_genetics = False  #not currently implemented
_max_genetic_variance =  0.1
_saturation_scale =  args.saturation_scale

#_enhance_upscale = True #@param{type:"boolean"}

cutn =  args.cutouts#@param{type:"raw"}
  #Controls how many crops to take from the image. Increase for higher quality.
cutn_batches = args.cutout_batches #@param [1,2,4,8,16] {type:"raw"}

  #Accumulate CLIP gradient from multiple batches of cuts [Can help with OOM errors / Low VRAM]
_esrgan_tilesize = "512" #@param[16,32,64,128,256,512,1024]
#_upscale_performance_mode = False
#@markdown `Performance Settings`

#@markdown ---
if args.denoised==0:
    clip_denoised = False # False - Determines whether CLIP discriminates a noisy or denoised image
else:
    clip_denoised = True # False - Determines whether CLIP discriminates a noisy or denoised image

fuzzy_prompt = False #@param{type:"boolean"}
  # False - Controls whether to add multiple noisy prompts to the prompt losses
eta =  0.5
_clip_guidance_scale =  args.guidance_scale#@param {type:"raw"}
_tv_scale =  args.tv_scale#@param {type:"raw"}
_range_scale =  args.range_scale#@param {type:"raw"}
_scale_multiplier = 1 #@param {type:"slider", min:0.1, max:5, step:0.1}

#@markdown ---
_text_prompt =  str(args.prompt) #"Sad panda bear 4k vector art, animated panda, collaboration by Seb Nirak1 and Sam Werczler" #@param {type:"string"} 
_noise_mode = 'gray' #@param ['mixed','gray','color']
_noise_amount = 0.1 #@param {type:"slider", min:0.00, max:1, step:0.01}

if args.seed_image is not None:
    init_image = args.seed_image   # This can be an URL or Colab local path and must be in quotes.
    skip_timesteps = args.skip_timesteps  # 12 Skip unstable steps                  # Higher values make the output look more like the init.
    init_scale = args.init_scale      # This enhances the effect of the init image, a good value is 1000.
else:
    init_image = None   # This can be an URL or Colab local path and must be in quotes.
    skip_timesteps = 6  # 12 Skip unstable steps                  # Higher values make the output look more like the init.
    init_scale = 0      # This enhances the effect of the init image, a good value is 1000.

itt = skip_timesteps

  #This enhances the effect of the init image, a good value is 1000
_image_prompts = "" #@param{type:"string"}
n_batches =  1#@param{type:"raw"}
  #Controls the starting point along the diffusion timesteps

#@markdown `Generation Settings`

#@markdown ---
display_rate =  args.update #@param{type:"raw"}
##@markdown Original Defaults: `clip_guidance_scale 5000`,`tv_scale 150`,`range scale 150`
##@markdown Recommended defaults for init_images (ddim50): `clip_guidance_scale 2000`,`tv_scale 150`,`range scale 50`, `init_scale 1000`, `skip_timesteps 16 (7-9 for ddim25)`
##@markdown There is a possibility that `tv_scale` can be set between `0` to `10000`
##@markdown `skip_timesteps` does a lot for the similarity in `init_settings`
##@markdown Special thanks to many people on the VQLIPSE Discord
##---

#--------------------------------------------------------------------------------------------------------

text_prompts = [
    # "an abstract painting of 'ravioli on a plate'",
    # 'cyberpunk wizard on top of a skyscraper, trending on artstation, photorealistic depiction of a cyberpunk wizard',
    #_text_prompt]
    phrase.strip() for phrase in args.prompt.split("|")]
    # 'cyberpunk wizard',

if diffusion_model == "512x512_diffusion_uncond_finetune_008100": model_size = 512
else: model_size = 256

if _noise_amount > 0: 
  add_random_noise = True
else:
  add_random_noise = False

# if not _init_image == '':  #to prevent noise from messing with init
#   if add_random_noise == True:
#     msg_runtime = msg_runtime + 'Notice: init_images have mixed results when _noise_amount > 0 \n'
#   # _noise_amount = 0
#   # add_random_noise = False
perlin_init = add_random_noise
"""
if init_image is not None: # Can't combine init_image and perlin options
  perlin_init = False
  msg_runtime = msg_runtime + 'NOTICE: You may want to disable _noise_amount when using _init_images \n'
"""
perlin_init = False #LEAVE AS FALSE, otherwise checkpoints and larger resolutions fail

rand_mag = _noise_amount # 0.1 - Controls the magnitude of the random noise

perlin_mode = _noise_mode # 'mixed' ('gray', 'color')

sat_scale = _saturation_scale
  # 0 - Controls how much saturation is allowed. From nshepperd's JAX notebook.

##@markdown `skip_timesteps` best 5 (thx steven), 10 for dd50

###@markdown False - Determines whether CLIP discriminates a noisy or denoised image
# if _diffusion_int == 512: display_rate = 2
# else: display_rate = 1
###@markdown False - Controls whether to add multiple noisy prompts to the prompt losses
###@markdown 0.0 - DDIM hyperparameter

output_folder_images = './' #os.path.join(_drive_location,_project_name)
temp_image_storage = './'  #for non-upscaled images

#---------------------------------------------------------------------------------------
def calculate_scale_multiplier():
  global clip_guidance_scale,tv_scale,range_scale
  clip_guidance_scale = _scale_multiplier * _clip_guidance_scale
  tv_scale = _scale_multiplier * _tv_scale
  range_scale = _scale_multiplier * _range_scale
  return clip_guidance_scale,tv_scale,range_scale
calculate_scale_multiplier()

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

do_run()
