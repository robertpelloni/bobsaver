# Quick CLIP Guided Diffusion HQ 256x256 and 512x512.ipynb
# Original file is located at https://colab.research.google.com/drive/1FuOobQOmDJuG7rGsMWfQa883A9r4HxEO


import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))


model_path = './'

import gc
import io
import math
import sys
from IPython import display
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
from datetime import datetime
import kornia.color as KC
import numpy as np
import matplotlib.pyplot as plt
import random
import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--guidancescale', type=int, help='CLIP guidance scale')
  parser.add_argument('--tvscale', type=int, help='TV scale')
  parser.add_argument('--rangescale', type=int, help='Range scale')
  parser.add_argument('--saturationscale', type=int, help='Saturation scale')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cutnbatches', type=int, help='Number of cutout batches')
  parser.add_argument('--cutpower', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--image_prompt', type=str, help='Prompt image.', default=None)
  parser.add_argument('--model512', type=int, help='Use the 512x512 model rather than the 256x256 model.')
  parser.add_argument('--ddim', type=int, help='ddim iterations.')
  parser.add_argument('--fuzzy_prompt', type=int, help='Fuzzy prompt.')
  parser.add_argument('--clip_denoised', type=int, help='CLIP denoised.')
  parser.add_argument('--initscale', type=int, help='Init scale')
  parser.add_argument('--skiptimesteps', type=int, help='Skip timesteps')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();


if args.model512 == 1:
    diffusion_model = "512x512_diffusion_uncond_finetune_008100" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]
else:
    diffusion_model = "256x256_diffusion_uncond" #@param ["256x256_diffusion_uncond", "512x512_diffusion_uncond_finetune_008100"]



"""# Define necessary functions"""

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
    #if prompt.startswith('http://') or prompt.startswith('https://'):
    if ':/' in prompt or ":\\" in prompt:
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', '1'][len(vals):]
    
    #sys.stdout.write("prompt image is "+vals[0]+"\n")
    #sys.stdout.flush()
    
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
    def __init__(self, cut_size, cutn, skip_augs=False, grayscale_cuts=False):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.skip_augs = skip_augs
        """
        self.grayscale_cuts = grayscale_cuts
        self.augs = T.Compose([
            T.RandomHorizontalFlip(p=0.5),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomAffine(degrees=15, translate=(0.1, 0.1)),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomPerspective(distortion_scale=0.4, p=0.7),
            # T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            # T.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1),
        ])
        """
        self.augs = T.Compose([
            T.RandomHorizontalFlip(p=0.5),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomAffine(degrees=15, translate=(0.1, 0.1)),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomPerspective(distortion_scale=0.4, p=0.7),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            T.RandomGrayscale(p=0.15),
            T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
            # T.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1),
        ])

    def forward(self, input):
        input = T.Pad(input.shape[2]//5, fill=0)(input)
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


def unitwise_norm(x):
    if len(x.squeeze().shape) <= 1:
        dim = None
        keepdim = False
    elif len(x.shape) in (2, 3):
        dim = 1
        keepdim = True
    elif len(x.shape) == 4:
        dim = (1, 2, 3)
        keepdim = True
    else:
        raise ValueError(f'got a parameter with shape not in (1, 2, 3, 4) {x}')
    return x.norm(dim = dim, keepdim = keepdim, p = 2)


def adaptive_clip_grad(parameters, clipping = 0.01, eps = 1e-3):
    parameters = [p for p in parameters if p.grad is not None]
    if len(parameters) == 0:
        return
    for p in parameters:
        param_norm = unitwise_norm(p).clamp_(min = eps)
        grad_norm = unitwise_norm(p.grad)
        max_norm = param_norm * clipping
        trigger = grad_norm > max_norm
        clipped_grad = p.grad * (max_norm / grad_norm.clamp(min = 1e-6))
        new_grads = torch.where(trigger, clipped_grad, p.grad)
        p.grad.detach().copy_(new_grads)

def do_run():
    loss_values = []
 
    if seed is not None:
        np.random.seed(seed)
        random.seed(seed)
        torch.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
 
    make_cutouts = MakeCutouts(clip_size, cutn, skip_augs=skip_augs)
    target_embeds, weights = [], []
 
    for prompt in text_prompts:
        txt, weight = parse_prompt(prompt)
        txt = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()
 
        if fuzzy_prompt:
            for i in range(25):
                target_embeds.append((txt + torch.randn(txt.shape).cuda() * rand_mag).clamp(0,1))
                weights.append(weight)
        else:
            target_embeds.append(txt)
            weights.append(weight)
 
    for prompt in image_prompts:
        path, weight = parse_prompt(prompt)
        img = Image.open(fetch(path)).convert('RGB')
        img = TF.resize(img, min(side_x, side_y, *img.size), T.InterpolationMode.LANCZOS)
        batch = make_cutouts(TF.to_tensor(img).to(device).unsqueeze(0).mul(2).sub(1))
        embed = clip_model.encode_image(normalize(batch)).float()
        if fuzzy_prompt:
            for i in range(25):
                target_embeds.append((embed + torch.randn(embed.shape).cuda() * rand_mag).clamp(0,1))
                weights.extend([weight / cutn] * cutn)
        else:
            target_embeds.append(embed)
            weights.extend([weight / cutn] * cutn)
 
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
    
    if perlin_init:
        if perlin_mode == 'color':
            init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
            init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, False)
        elif perlin_mode == 'gray':
           init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, True)
           init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
        else:
           init = create_perlin_noise([1.5**-i*0.5 for i in range(12)], 1, 1, False)
           init2 = create_perlin_noise([1.5**-i*0.5 for i in range(8)], 4, 4, True)
        
        # init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device)
        init = TF.to_tensor(init).add(TF.to_tensor(init2)).div(2).to(device).unsqueeze(0).mul(2).sub(1)
        del init2
 
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
        if clip_grad:
            # adaptive_clip_grad([x])
            magnitude = grad.square().mean().sqrt()
            return grad * magnitude.clamp(max=0.05) / magnitude
        return grad
 
    if model_config['timestep_respacing'].startswith('ddim'):
        sample_fn = diffusion.ddim_sample_loop_progressive
    else:
        sample_fn = diffusion.p_sample_loop_progressive
 
    itt=1
    for i in range(n_batches):
        cur_t = diffusion.num_timesteps - skip_timesteps - 1
 
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
            sys.stdout.write(f'Iteration {itt}\n')
            sys.stdout.flush()
            #display.clear_output(wait=True)
            cur_t -= 1
            #if j % display_rate == 0 or cur_t == -1:
            if itt % args.update == 0 or cur_t == -1:
                for k, image in enumerate(sample['pred_xstart']):
                    sys.stdout.flush()
                    sys.stdout.write('Saving progress ...\n')
                    sys.stdout.flush()
                    #tqdm.write(f'Batch {i}, step {j}, output {k}:')
                    current_time = datetime.now().strftime('%y%m%d-%H%M%S_%f')
                    #filename = f'progress_batch{i:05}_iteration{j:05}_output{k:05}_{current_time}.png'
                    #filename = 'Progress.png'
                    image = TF.to_pil_image(image.add(1).div(2).clamp(0, 1))
                    #image.save('/content/' + filename)
                    
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
                    
                    
                    
                    
                    #display.display(display.Image('/content/' + filename))
                    #if google_drive and cur_t == -1:
                    #    image.save('/content/drive/MyDrive/' + filename)
                    sys.stdout.flush()
                    sys.stdout.write('Progress saved\n')
                    sys.stdout.flush()
            itt+=1
 
        #plt.plot(np.array(loss_values), 'r')

"""# Load Diffusion and CLIP models"""

#timestep_respacing = 'ddim50' # Modify this value to decrease the number of timesteps.
# timestep_respacing = '25'
if args.ddim == 1:
    timestep_respacing = 'ddim'+str(args.iterations) #'ddim100' # Modify this value to decrease the number of timesteps.
else:
    timestep_respacing = str(args.iterations) #'ddim100' # Modify this value to decrease the number of timesteps.
#sys.stdout.write("Timestep respacing is "+timestep_respacing+"\n")
#sys.stdout.flush()


diffusion_steps = max(1000,args.iterations)

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
        'use_fp16': True,
        'use_scale_shift_norm': True,
    })
side_x = side_y = model_config['image_size']

sys.stdout.write(f'Loading {diffusion_model}.pt ...\n')
sys.stdout.flush()

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load(f'{model_path}{diffusion_model}.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()


sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

clip_model = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
#clip_model = clip.load('ViT-B/16', jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)

"""# Settings"""

"""
text_prompts = [
    # "an abstract painting of 'ravioli on a plate'",
    # 'cyberpunk witch',
    args.prompt,
]
"""
text_prompts = [ phrase.strip() for phrase in args.prompt.split("|") ]

if args.image_prompt is None:
    image_prompts = [
    ]
else:
    image_prompts = [
    args.image_prompt,
    ]


# 350/50/50/32 and 500/0/0/64 have worked well for 25 timesteps on 256px
# Also, sometimes 1 cutn actually works out fine

clip_guidance_scale = args.guidancescale # 700 - Controls how much the image should look like the prompt.
tv_scale = args.tvscale # 75 - Controls the smoothness of the final output.
range_scale = args.rangescale # 100 - Controls how far out of range RGB values are allowed to be.
sat_scale = args.saturationscale # 100 - Controls how much saturation is allowed. From nshepperd's JAX notebook.
cutn = args.cutn # 32 - Controls how many crops to take from the image.
cutn_batches = args.cutnbatches # 2 - Accumulate CLIP gradient from multiple batches of cuts [Can help with OOM errors / Low VRAM]

if args.seed_image is None:
    init_image = None # None - URL or local path
    init_scale = 0 # 0 - This enhances the effect of the init image, a good value is 1000
    skip_timesteps = 0 # 0 - Controls the starting point along the diffusion timesteps
else:
    init_image = args.seed_image # None - URL or local path
    init_scale = args.initscale # 0 - This enhances the effect of the init image, a good value is 1000
    skip_timesteps = args.skiptimesteps # 0 - Controls the starting point along the diffusion timesteps

perlin_init = False # False - Option to start with random perlin noise
perlin_mode = 'mixed' # 'mixed' ('gray', 'color')

skip_augs = False # False - Controls whether to skip torchvision augmentations
grayscale_cuts = False # False - Controls whether CLIP discriminates a grayscale version of the image
randomize_class = True # True - Controls whether the imagenet class is randomly changed each iteration

#clip_denoised = False # False - Determines whether CLIP discriminates a noisy or denoised image
if args.clip_denoised == 0:
    clip_denoised = False # False - Determines whether CLIP discriminates a noisy or denoised image
    #sys.stdout.write("clip_denoised = False\n")
    #sys.stdout.flush()
else:
    clip_denoised = True # False - Determines whether CLIP discriminates a noisy or denoised image
    #sys.stdout.write("clip_denoised = True\n")
    #sys.stdout.flush()




clip_grad = True # True - Experimental: Using adaptive clip grad in the cond_fn

seed = None

#fuzzy_prompt = True # False - Controls whether to add multiple noisy prompts to the prompt losses
#fuzzy_prompt = True # False - Controls whether to add multiple noisy prompts to the prompt losses
if args.fuzzy_prompt == 0:
    fuzzy_prompt = False
    #sys.stdout.write("fuzzy_prompt = False\n")
    #sys.stdout.flush()
else:
    fuzzy_prompt = True
    #sys.stdout.write("fuzzy_prompt = True\n")
    #sys.stdout.flush()




rand_mag = 0.05 # 0.1 - Controls the magnitude of the random noise
eta = 0.5 # 0.0 - DDIM hyperparameter

"""# Diffuse!"""

seed = args.seed #random.randint(0, 2**32) # Choose a random seed and print it at end of runq for reproduction

display_rate = args.update
n_batches = 1 # 1 - Controls how many consecutive batches of images are generated
batch_size = 1 # 1 - Controls how many images are generated in parallel in a batch


sys.stdout.write("Starting ...\n")
sys.stdout.flush()

do_run()
