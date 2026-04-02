# CLIP Guided k-diffusion.ipynb
# Original file is located at https://colab.research.google.com/drive/1w0HQqxOKCk37orHATPxV8qb0wb4v-qa0

# %pip install git+https://github.com/crowsonkb/k-diffusion

"""If the "Restart runtime" button appears above, please click it to restart the runtime, then continue below."""

#@title Select the diffusion model

#model_name = "openai_imagenet_512" #@param ["openai_imagenet_256", "openai_imagenet_512"]

# Download the 256x256 diffusion model (only run if you picked openai_imagenet_256)

#!curl -OL 'https://openaipublic.blob.core.windows.net/diffusion/jul-2021/256x256_diffusion_uncond.pt'

# Download the 512x512 diffusion model (only run if you picked openai_imagenet_512)

#!curl -OL --http1.1 'https://the-eye.eu/public/AI/models/512x512_diffusion_unconditional_ImageNet/512x512_diffusion_uncond_finetune_008100.pt'

# Imports

import os
import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./guided-diffusion')

import gc
import io
import math
import sys
import clip
import k_diffusion as K
import lpips
from PIL import Image
import requests
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms, utils
from torchvision.transforms import functional as TF
from tqdm.notebook import tqdm
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
import argparse








sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--seed', type=int)
  parser.add_argument('--iterations', type=int)
  parser.add_argument('--update', type=int)
  parser.add_argument('--model', type=str)
  parser.add_argument('--clip_model', type=str)
  parser.add_argument('--clip_guidance_scale', type=int)
  parser.add_argument('--tv_scale', type=int)
  parser.add_argument('--range_scale', type=int)
  parser.add_argument('--cutn', type=int)
  parser.add_argument('--cutpow', type=float)
  parser.add_argument('--nbatches', type=int)
  parser.add_argument('--init_image', type=str)
  parser.add_argument('--sigma_start', type=int)
  parser.add_argument('--init_scale', type=int)
  parser.add_argument('--image_file', type=str)
  parser.add_argument('--frame_dir', type=str)
  args = parser.parse_args()
  return args

args3=parse_args();

if args3.seed is not None:
    sys.stdout.write(f'Setting seed to {args3.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args3.seed)
    import random
    random.seed(args3.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args3.seed)
    torch.cuda.manual_seed(args3.seed)
    torch.cuda.manual_seed_all(args3.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 


DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()

model_name = args3.model #"openai_imagenet_512" #@param ["openai_imagenet_256", "openai_imagenet_512"]














# Define necessary functions

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


class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

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
            cutouts.append(F.adaptive_avg_pool2d(cutout, self.cut_size))
        return torch.cat(cutouts)


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


class GuidedDenoiserWithGrad(nn.Module):
    def __init__(self, model, cond_fn):
        super().__init__()
        self.inner_model = model
        self.cond_fn = cond_fn
        self.orig_denoised = None

    def forward(self, x, sigma, **kwargs):
        with torch.enable_grad():
            x = x.detach().requires_grad_()
            denoised = self.inner_model(x, sigma, **kwargs)
            self.orig_denoised = denoised.detach()
            cond_grad = self.cond_fn(x, sigma, denoised=denoised, **kwargs)
        cond_denoised = denoised + cond_grad * K.utils.append_dims(sigma ** 2, x.ndim)
        return cond_denoised

# Model settings

model_config = model_and_diffusion_defaults()
model_config.update({
    'attention_resolutions': '32, 16, 8',
    'class_cond': False,
    'diffusion_steps': 1000,
    'rescale_timesteps': True,
    'timestep_respacing': '1000',
    'learn_sigma': True,
    'noise_schedule': 'linear',
    'num_channels': 256,
    'num_head_channels': 64,
    'num_res_blocks': 2,
    'resblock_updown': True,
    'use_checkpoint': False,
    'use_fp16': True,
    'use_scale_shift_norm': True,
})
if model_name == 'openai_imagenet_256':
    model_config['image_size'] = 256
    model_path = './256x256_diffusion_uncond_kdiffusion.pt'
elif model_name == 'openai_imagenet_512':
    model_config['image_size'] = 512
    model_path = './512x512_diffusion_uncond_finetune_008100.pt'

# Load models

#device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
#print('Using device:', device)

sys.stdout.write('Loading diffusion model ...\n')
sys.stdout.flush()


model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load(model_path, map_location='cpu'))
model.requires_grad_(False).eval().to(device)
if model_config['use_fp16']:
    model.convert_to_fp16()

sys.stdout.write(f'Loading clip model {args3.clip_model} ...\n')
sys.stdout.flush()

clip_model = clip.load('ViT-B/16', jit=False)[0].eval().requires_grad_(False).to(device)
#clip_model = clip.load(args3.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
lpips_model = lpips.LPIPS(net='vgg').to(device)

#prompts = ['A mysterious orb by Ernst Fuchs']
#prompts = ['a portrait of a beautiful young girl in a garden at dusk']
prompts = [args3.prompt]

image_prompts = []
batch_size = 1
n_steps = args3.iterations  # The number of timesteps to use
clip_guidance_scale = args3.clip_guidance_scale  # Controls how much the image should look like the prompt.
tv_scale = args3.tv_scale              # Controls the smoothness of the final output.
range_scale = args3.range_scale            # Controls how far out of range RGB values are allowed to be.
cutn = args3.cutn                   # The number of random crops per step.
                            # Good values are 16 for 256x256 and 64-128 for 512x512.
cut_pow = args3.cutpow
n_batches = args3.nbatches
seed = None

# This can be an URL or Colab local path and must be in quotes.
init_image = args3.init_image
sigma_start = args3.sigma_start   # The starting noise level when using an init image.
                   # Higher values make the output look more like the init.
init_scale = args3.init_scale  # This enhances the effect of the init image, a good value is 1000.


"""### Actually do the run..."""

sys.stdout.write('Starting ...\n')
sys.stdout.flush()

def do_run():
    make_cutouts = MakeCutouts(clip_size, cutn, cut_pow)
    side_x = side_y = model_config['image_size']

    target_embeds, weights = [], []

    for prompt in prompts:
        txt, weight = parse_prompt(prompt)
        target_embeds.append(clip_model.encode_text(clip.tokenize(txt).to(device)).float())
        weights.append(weight)

    for prompt in image_prompts:
        path, weight = parse_prompt(prompt)
        img = Image.open(fetch(path)).convert('RGB')
        img = TF.resize(img, min(side_x, side_y, *img.size), transforms.InterpolationMode.LANCZOS)
        batch = make_cutouts(TF.to_tensor(img)[None].to(device))
        embed = clip_model.encode_image(normalize(batch)).float()
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
        init = init.resize((side_x, side_y), Image.Resampling.LANCZOS)
        init = TF.to_tensor(init).to(device)[None] * 2 - 1

    def cond_fn(x, sigma, denoised, **kwargs):
        n = x.shape[0]

        # Anti-grain hack for the 256x256 ImageNet model
        fac = sigma / (sigma ** 2 + 1) ** 0.5
        denoised_in = x.lerp(denoised, fac)

        clip_in = normalize(make_cutouts(denoised_in.add(1).div(2)))
        image_embeds = clip_model.encode_image(clip_in).float()
        dists = spherical_dist_loss(image_embeds[:, None], target_embeds[None])
        dists = dists.view([cutn, n, -1])
        losses = dists.mul(weights).sum(2).mean(0)
        tv_losses = tv_loss(denoised_in)
        range_losses = range_loss(denoised)
        loss = losses.sum() * clip_guidance_scale + tv_losses.sum() * tv_scale + range_losses.sum() * range_scale
        if init is not None and init_scale:
            init_losses = lpips_model(denoised_in, init)
            loss = loss + init_losses.sum() * init_scale
        return -torch.autograd.grad(loss, x)[0]

    model_wrap = K.external.OpenAIDenoiser(model, diffusion, device=device)
    sigmas = model_wrap.get_sigmas(n_steps)
    if init is not None:
        sigmas = sigmas[sigmas <= sigma_start]
    model_guided = GuidedDenoiserWithGrad(model_wrap, cond_fn)

    def callback(info):
        itt = info['i']
        sys.stdout.write(f'Iteration {itt}\n')
        sys.stdout.flush()
    
        if info['i'] % args3.update == 0:

            sys.stdout.flush()
            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()

            denoised = model_guided.orig_denoised
            nrow = math.ceil(denoised.shape[0] ** 0.5)
            grid = utils.make_grid(denoised, nrow, padding=0)
            #tqdm.write(f'Step {info["i"]} of {len(sigmas) - 1}, sigma {info["sigma"]:g}:')
            #display.display(K.utils.to_pil_image(grid))
            K.utils.to_pil_image(grid).save(args3.image_file)
            #tqdm.write(f'')

            sys.stdout.flush()
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()

    if seed is not None:
        torch.manual_seed(seed)

    for i in range(n_batches):
        x = torch.randn([1, 3, side_y, side_x], device=device) * sigmas[0]
        if init is not None:
            x += init
        #samples = K.sampling.sample_heun(model_guided, x, sigmas, second_order=False, s_churn=20, callback=callback)
        samples = K.sampling.sample_heun(model_guided, x, sigmas, s_churn=20, callback=callback)

    tqdm.write('Done!')
    for i, out in enumerate(samples):
        #filename = f'out_{i}.png'
        filename=args3.image_file
        #size = len(filename)
        #filename=filename[:size - 4]
        #filename=filename+f'{i}.png'
        K.utils.to_pil_image(out).save(filename)
        #display.display(display.Image(filename))


gc.collect()
do_run()