# Original file is located at https://colab.research.google.com/github/multimodalart/latent-diffusion-notebook/blob/main/Latent_Diffusion_LAION_400M_model_text_to_image.ipynb

# LAION model https://ommer-lab.com/files/latent-diffusion/nitro/txt2img-f8-large/model.ckpt

# Setup stuff
"""

#@title Installation
!git clone https://github.com/crowsonkb/latent-diffusion.git
!git clone https://github.com/CompVis/taming-transformers
!pip install -e ./taming-transformers
!pip install omegaconf>=2.0.0 pytorch-lightning>=1.0.8 torch-fidelity einops
!pip install transformers

"""

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

sys.path.append(".")
sys.path.append('./taming-transformers')
sys.path.append('./latent-diffusion')

from taming.models import vqgan
import torch
from omegaconf import OmegaConf
from ldm.util import instantiate_from_config
#@title Import stuff
import argparse, os, sys, glob
import torch
import numpy as np
from omegaconf import OmegaConf
from PIL import Image
#from tqdm.auto import tqdm, trange
#tqdm_auto_model = __import__("tqdm.auto", fromlist=[None]) 
#sys.modules['tqdm'] = tqdm_auto_model
from einops import rearrange
from torchvision.utils import make_grid
import transformers
import gc
from ldm.util import instantiate_from_config
from ldm.models.diffusion.ddim import DDIMSampler
from ldm.models.diffusion.plms import PLMSSampler



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--batches', type=int, help='Batch count.')
  parser.add_argument('--plms', type=int, help='Use plms sampling.')
  parser.add_argument('--ETA', type=float, help='ETA. 0=plms othewise DDIM')
  parser.add_argument('--diversity_scale', type=float, help='Diversity scale.')
  parser.add_argument('--images_per_batch', type=int, help='Images per batch.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
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


DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
print(torch.cuda.get_device_properties(device))





def load_model_from_config(config, ckpt):
    print(f"Loading model from {ckpt}")
    pl_sd = torch.load(ckpt)#, map_location="cpu")
    sd = pl_sd["state_dict"]
    model = instantiate_from_config(config.model)
    m, u = model.load_state_dict(sd, strict=False)
    model.cuda()
    model.eval()
    return model


def get_model():
    config = OmegaConf.load("./latent-diffusion/configs/latent-diffusion/cin256-v2.yaml")  
    model = load_model_from_config(config, "model.ckpt")
    return model


#@title Load necessary functions
def load_model_from_config(config, ckpt, verbose=False):
    print(f"Loading model from {ckpt}")
    pl_sd = torch.load(ckpt, map_location="cpu")
    sd = pl_sd["state_dict"]
    model = instantiate_from_config(config.model)
    m, u = model.load_state_dict(sd, strict=False)
    if len(m) > 0 and verbose:
        print("missing keys:")
        print(m)
    if len(u) > 0 and verbose:
        print("unexpected keys:")
        print(u)

    model.cuda()
    model.eval()
    return model

def run(opt):

    sys.stdout.write("Loading LAION_400M model ...\n")
    sys.stdout.flush()

    config = OmegaConf.load("./latent-diffusion/configs/latent-diffusion/txt2img-1p4B-eval.yaml")  
    model = load_model_from_config(config, "model.ckpt")  # TODO: check path
    model = model.to(device)

    sys.stdout.write("Setting up sampler ...\n")
    sys.stdout.flush()

    if opt.plms:
        opt.ddim_eta = 0
        sampler = PLMSSampler(model)
    else:
        sampler = DDIMSampler(model)
    
    os.makedirs(opt.outdir, exist_ok=True)
    outpath = opt.outdir

    prompt = opt.prompt


    sample_path = os.path.join(outpath, "samples")
    os.makedirs(sample_path, exist_ok=True)
    base_count = len(os.listdir(sample_path))

    sys.stdout.write("Starting ...\n")
    sys.stdout.flush()

    all_samples=list()
    with torch.no_grad():
        with model.ema_scope():
            uc = None
            if opt.scale > 0:
                uc = model.get_learned_conditioning(opt.n_samples * [""])
            for n in range(opt.n_iter):
                c = model.get_learned_conditioning(opt.n_samples * [prompt])
                shape = [4, opt.H//8, opt.W//8]
                samples_ddim, _ = sampler.sample(S=opt.ddim_steps,
                                                 conditioning=c,
                                                 batch_size=opt.n_samples,
                                                 shape=shape,
                                                 verbose=False,
                                                 unconditional_guidance_scale=opt.scale,
                                                 unconditional_conditioning=uc,
                                                 eta=opt.ddim_eta)

                x_samples_ddim = model.decode_first_stage(samples_ddim)
                x_samples_ddim = torch.clamp((x_samples_ddim+1.0)/2.0, min=0.0, max=1.0)

                for x_sample in x_samples_ddim:
                    x_sample = 255. * rearrange(x_sample.cpu().numpy(), 'c h w -> h w c')
                    
                    #Image.fromarray(x_sample.astype(np.uint8)).save(os.path.join(sample_path, f"{base_count:04}.png"))
                    imgfile = args2.image_file
                    imgfile = imgfile.removesuffix('.png')
                    imgfile = imgfile + f" {base_count:04}.png"
                    Image.fromarray(x_sample.astype(np.uint8)).save(imgfile)
                    
                    base_count += 1
                all_samples.append(x_samples_ddim)


    # additionally, save as grid
    grid = torch.stack(all_samples, 0)
    grid = rearrange(grid, 'n b c h w -> (n b) c h w')
    grid = make_grid(grid, nrow=opt.n_samples)

    # to image
    grid = 255. * rearrange(grid, 'c h w -> h w c').cpu().numpy()
    
    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()
   
    #Image.fromarray(grid.astype(np.uint8)).save(os.path.join(outpath, f'{prompt.replace(" ", "-")}.png'))
    Image.fromarray(grid.astype(np.uint8)).save(args2.image_file)
    #display(Image.fromarray(grid.astype(np.uint8)))
    #print(f"Your samples are ready and waiting four you here: \n{outpath} \nEnjoy.")

    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()
   
"""# Do the run"""

#@title Parameters

Prompt = args2.prompt
Steps = args2.iterations #50 #@param {type:"integer"}
ETA = args2.ETA #@param{type:"integer"}
Iterations = args2.batches #2 #@param{type:"integer"}
Width=args2.sizex #256 #@param{type:"integer"}
Height=args2.sizey #256 #@param{type:"integer"}
Samples_in_parallel=args2.images_per_batch #4 #@param{type:"integer"}
Diversity_scale=args2.diversity_scale #5.0 #@param {type:"number"}
if args2.plms == 1:
    PLMS_sampling=True #@param {type:"boolean"}
else:
    PLMS_sampling=False #@param {type:"boolean"}

args = argparse.Namespace(
    prompt = Prompt, 
    outdir='outputs',
    ddim_steps = Steps,
    ddim_eta = ETA,
    n_iter = Iterations,
    W=Width,
    H=Height,
    n_samples=Samples_in_parallel,
    scale=Diversity_scale,
    plms=PLMS_sampling
)
run(args)