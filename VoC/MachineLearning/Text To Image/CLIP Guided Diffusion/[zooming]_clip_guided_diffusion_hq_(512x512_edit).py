# [zooming] CLIP Guided Diffusion HQ (512x512 edit).ipynb
# Original file is located at https://colab.research.google.com/drive/1F2M1T2ZQtanFpjBUyId1VaxmqPb4eY5N
# Edited by ian henderson (<https://twitter.com/ianh_>) to do a cool zooming effect


import math
import sys

from IPython import display
import ipywidgets as widgets
from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from tqdm.notebook import tqdm

sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')

import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults

# Define necessary functions

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
            cutout = F.interpolate(cutout, (self.cut_size, self.cut_size),
                                   mode='bilinear', align_corners=False)
            cutouts.append(cutout)
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

# by maedoc on github - https://github.com/ipython/ipython/issues/10045#issuecomment-642640541
def show_gif(fname):
    import base64
    with open(fname, 'rb') as fd:
        b64 = base64.b64encode(fd.read()).decode('ascii')
    return display.HTML(f'<img src="data:image/gif;base64,{b64}" />')

# Model setup
model_config = model_and_diffusion_defaults()
model_config.update({
    "attention_resolutions": "32, 16, 8",
    "class_cond": True,
    "diffusion_steps": 1000,
    "rescale_timesteps": True,
    "timestep_respacing": "250",
    "image_size": 512,
    "learn_sigma": True,
    "noise_schedule": "linear",
    "num_channels": 256,
    "num_head_channels": 64,
    "num_res_blocks": 2,
    "resblock_updown": True,
    "use_fp16": True,
    "use_scale_shift_norm": True,
})
model_config

# Load models

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load('512x512_diffusion.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

clip_model = clip.load('ViT-B/16', jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

"""## Settings for this run:"""

# Pick a class for sampling
model_kwargs = {"y": torch.randint(low=0, high=999, size=(1,), device=device,)} # picks a random Imagenet 2012 class
#model_kwargs["y"] = torch.Tensor([classnumber]).to(int).to(device) # alternatively, uncomment this line, then choose a class from https://gist.github.com/yrevar/942d3a0ac09ec9e5eb3a and put its number where classnumber is

prompt = 'hell'
gif_frames = 40
gif_frame_delay = 40
gif_prequantize = False
# set display_gifs to False if your browser is dying from too many gifs
# you can download progress_NNNNN.gif from the files instead
display_gifs = True
clip_guidance_scale = 900
tv_scale = 200
cutn = 16
n_batches = 1
seed = None

"""### Actually do the run..."""

if seed is not None:
    torch.manual_seed(seed)

text_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

make_cutouts = MakeCutouts(clip_size, cutn)

cur_t = None

def cond_fn(x, t, y=None):
    with torch.enable_grad():
        x = x.detach().requires_grad_()
        n = x.shape[0]
        my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
        out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
        fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
        x_in = out['pred_xstart'] * fac + x * (1 - fac)
        clip_in = normalize(make_cutouts(x_in.add(1).div(2)))
        image_embeds = clip_model.encode_image(clip_in).float().view([cutn, n, -1])
        dists = spherical_dist_loss(image_embeds, text_embed.unsqueeze(0))
        losses = dists.mean(0)
        tv_losses = tv_loss(x_in)
        loss = losses.sum() * clip_guidance_scale + tv_losses.sum() * tv_scale
        return -torch.autograd.grad(loss, x)[0]

if model_config['timestep_respacing'].startswith('ddim'):
    sample_fn = diffusion.ddim_sample_loop_progressive
else:
    sample_fn = diffusion.p_sample_loop_progressive

for i in range(n_batches):
    cur_t = diffusion.num_timesteps - 1

    samples = sample_fn(
      model,
      (1, 3, model_config['image_size'], model_config['image_size']),
      clip_denoised=False,
      model_kwargs=model_kwargs,
      cond_fn=cond_fn,
      progress=True,
    )
    for j, sample in enumerate(samples):
      x = sample['sample']
      n = x.shape[2]
      m = n
      y = x
      while m > 1:
        y = torch.nn.functional.interpolate(y, size=(m, m), mode='nearest')
        x[:,:,(n-m)//2:(n-m)//2+m,(n-m)//2:(n-m)//2+m] = y
        m //= 2
      sample['sample'][0] = x
      cur_t -= 1
      filename_png = f'progress_{i:05}.png'
      filename_gif = f'progress_{i:05}.gif'
      if j % 25 == 0 or cur_t == -1:
        image = sample['pred_xstart'][0]
        img = TF.to_pil_image(image.add(1).div(2).clamp(0, 1)).convert(mode="RGBA")
        img.save(filename_png)
        imgs = []
        for k in range(gif_frames):
          scale = 2 ** (k/gif_frames)
          x = img.transform((512, 512), Image.AFFINE, (1/scale, 0, (1-1/scale)*256, 0, 1/scale, (1-1/scale)*256), resample=Image.BICUBIC)
          img.putalpha(int(255 * k / gif_frames))
          y = img.transform((512, 512), Image.AFFINE, (2/scale, 0, (1-2/scale)*256, 0, 2/scale, (1-2/scale)*256), resample=Image.BICUBIC)
          img.putalpha(int(255))
          frame = Image.alpha_composite(x, y)
          frame = frame.convert(mode="RGB")
          if gif_prequantize:
            if k > 0:
              palette = imgs[0]
            else:
              palette = None
            frame = frame.quantize(palette=palette)
          imgs.append(frame)
        imgs[0].save(filename_gif, save_all=True, append_images=imgs[1:], optimize=False, duration=gif_frame_delay, loop=0)
        tqdm.write(f'Batch {i}, step {j}:')
        if display_gifs:
          display.display(show_gif(filename_gif))
        else:
          display.display(display.Image(filename_png))