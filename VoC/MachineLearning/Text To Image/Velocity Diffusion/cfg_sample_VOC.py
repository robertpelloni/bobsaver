#!/usr/bin/env python3

"""Classifier-free guidance sampling from a diffusion model."""

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import argparse
from functools import partial
from pathlib import Path

from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from tqdm import trange

from CLIP import clip
from diffusion import get_model, get_models, sampling, utils


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompts', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Iterations per update')
  parser.add_argument('--cutn', type=int, help='Cutouts')
  parser.add_argument('--cutpower', type=int, help='Cut power')
  parser.add_argument('--eta', type=float, help='ETA')
  parser.add_argument('--n', type=int, help='Number of images')
  parser.add_argument('--clip-guidance-scale', type=int, help='CLIP guidance scale')
  parser.add_argument('--model', type=str, help='Diffusion model to load.')
  parser.add_argument('--method', type=str, help='Method.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--starting_timestep', type=float, help='Like skip timesteps but floating point befault 0.9', default=None)
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args3 = parser.parse_args()
  return args3

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






MODULE_DIR = Path(__file__).resolve().parent


def parse_prompt(prompt, default_weight=3.):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 2)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 1)
    vals = vals + ['', default_weight][len(vals):]
    return vals[0], float(vals[1])


def resize_and_center_crop(image, size):
    fac = max(size[0] / image.size[0], size[1] / image.size[1])
    image = image.resize((int(fac * image.size[0]), int(fac * image.size[1])), Image.LANCZOS)
    return TF.center_crop(image, size[::-1])


def main():
    """
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument('prompts', type=str, default=[args2.prompts], nargs='*',
                   help='the text prompts to use')
    p.add_argument('--images', type=str, default=[], nargs='*', metavar='IMAGE',
                   help='the image prompts')
    p.add_argument('--batch-size', '-bs', type=int, default=1,
                   help='the number of images per batch')
    p.add_argument('--checkpoint', type=str,
                   help='the checkpoint to use')
    p.add_argument('--device', type=str,
                   help='the device to use')
    p.add_argument('--eta', type=float, default=0.,
                   help='the amount of noise to add during sampling (0-1)')
    p.add_argument('--init', type=str,
                   help='the init image')
    p.add_argument('--method', type=str, default='plms',
                   choices=['ddpm', 'ddim', 'prk', 'plms', 'pie', 'plms2'],
                   help='the sampling method to use')
    p.add_argument('--model', type=str, default='cc12m_1_cfg', choices=['cc12m_1_cfg'],
                   help='the model to use')
    p.add_argument('-n', type=int, default=1,
                   help='the number of images to sample')
    p.add_argument('--seed', type=int, default=0,
                   help='the random seed')
    p.add_argument('--size', type=int, nargs=2,
                   help='the output image size')
    p.add_argument('--starting-timestep', '-st', type=float, default=0.9,
                   help='the timestep to start at (used with init images)')
    p.add_argument('--steps', type=int, default=50,
                   help='the number of timesteps')
    args = p.parse_args()
    """

    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
    print('Using device:', device)
    print(torch.cuda.get_device_properties(device))

    model = get_model(args2.model)()
    _, side_y, side_x = model.shape
    #if args.size:
    #    side_x, side_y = args.size
    side_x = args2.sizex
    side_y = args2.sizey
    
    #checkpoint = args2.model
    #if not checkpoint:
    #    checkpoint = MODULE_DIR / f'checkpoints/{args.model}.pth'
    checkpoint = MODULE_DIR / f'checkpoints/{args2.model}.pth'
    model.load_state_dict(torch.load(checkpoint, map_location='cpu'))
    if device.type == 'cuda':
        model = model.half()
    model = model.to(device).eval().requires_grad_(False)
    clip_model_name = model.clip_model if hasattr(model, 'clip_model') else 'ViT-B/16'
    clip_model = clip.load(clip_model_name, jit=False, device=device)[0]
    clip_model.eval().requires_grad_(False)
    normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                     std=[0.26862954, 0.26130258, 0.27577711])

    if args2.seed_image:
        init = Image.open(utils.fetch(args2.seed_image)).convert('RGB')
        init = resize_and_center_crop(init, (side_x, side_y))
        init = utils.from_pil_image(init).to(device)[None].repeat([args2.n, 1, 1, 1])

    zero_embed = torch.zeros([1, clip_model.visual.output_dim], device=device)
    target_embeds, weights = [zero_embed], []

    for prompt in args2.prompts:
        txt, weight = parse_prompt(prompt)
        target_embeds.append(clip_model.encode_text(clip.tokenize(txt).to(device)).float())
        weights.append(weight)

    """
    for prompt in args2.images:
        path, weight = parse_prompt(prompt)
        img = Image.open(utils.fetch(path)).convert('RGB')
        clip_size = clip_model.visual.input_resolution
        img = resize_and_center_crop(img, (clip_size, clip_size))
        batch = TF.to_tensor(img)[None].to(device)
        embed = F.normalize(clip_model.encode_image(normalize(batch)).float(), dim=-1)
        target_embeds.append(embed)
        weights.append(weight)
    """
    
    weights = torch.tensor([1 - sum(weights), *weights], device=device)

    #torch.manual_seed(args.seed)

    def cfg_model_fn(x, t):
        n = x.shape[0]
        n_conds = len(target_embeds)
        x_in = x.repeat([n_conds, 1, 1, 1])
        t_in = t.repeat([n_conds])
        clip_embed_in = torch.cat([*target_embeds]).repeat_interleave(n, 0)
        vs = model(x_in, t_in, clip_embed_in).view([n_conds, n, *x.shape[1:]])
        v = vs.mul(weights[:, None, None, None, None]).sum(0)
        return v

    def run(x, steps):
        if args2.method == 'ddpm':
            return sampling.sample(cfg_model_fn, x, steps, 1., {})
        if args2.method == 'ddim':
            return sampling.sample(cfg_model_fn, x, steps, args.eta, {})
        if args2.method == 'prk':
            return sampling.prk_sample(cfg_model_fn, x, steps, {})
        if args2.method == 'plms':
            return sampling.plms_sample(cfg_model_fn, x, steps, {})
        if args2.method == 'pie':
            return sampling.pie_sample(cfg_model_fn, x, steps, {})
        if args2.method == 'plms2':
            return sampling.plms2_sample(cfg_model_fn, x, steps, {})
        assert False

    def run_all(n, batch_size):
        x = torch.randn([n, 3, side_y, side_x], device=device)
        t = torch.linspace(1, 0, args2.iterations + 1, device=device)[:-1]
        steps = utils.get_spliced_ddpm_cosine_schedule(t)
        if args2.seed_image:
            steps = steps[steps < args.starting_timestep]
            alpha, sigma = utils.t_to_alpha_sigma(steps[0])
            x = init * alpha + x * sigma
        for i in trange(0, n, batch_size):
            cur_batch_size = min(n - i, batch_size)
            outs = run(x[i:i+cur_batch_size], steps)
            for j, out in enumerate(outs):
                utils.to_pil_image(out).save(f'out_{i + j:05}.png')

    """
    try:
        run_all(args2.n, args2.batch_size)
    except KeyboardInterrupt:
        pass
    """
    run_all(args2.n,1)

if __name__ == '__main__':
    main()
