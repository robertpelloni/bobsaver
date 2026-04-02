# Dance_Diffusion
# Original file is located at https://colab.research.google.com/github/Harmonai-org/sample-generator/blob/main/Dance_Diffusion.ipynb

"""

# Instructions

## Before anything else
- Run the "Setup" section
- Sign in to the Google Drive account you want to save your models in
- Select the model you want to sample from in the "Model settings" section, this determines the length and sound of your samples

## For random sample generation
- Choose the number of random samples you would like Dance Diffusion to generate for you 
- Choose the number of diffusion steps you would like Dance Diffusion to execute
- Make sure the "skip_for_run_all" checkbox is unchecked
- Run the cell under the "Generate new sounds" header

## To regenerate your own sounds
- Enter the path to an audio file you want to regenerate, or upload when prompted
- Make sure the "skip_for_run_all" checkbox is unchecked
- Run the cell under the "Regenerate your own sounds" header

## To interpolate between two different sounds
- Enter the paths to two audio files you want to interpolate between, or upload them when prompted
- Make sure the "skip_for_run_all" checkbox is unchecked
- Run the cell under the "Interpolate between sounds" header

"""
import sys

sys.path.append('./v-diffusion-pytorch')
sys.path.append('./sample-generator')

root_path = '.'
initDirPath = f'{root_path}/init_audio'
outDirPath = f'{root_path}/audio_out'
model_path = f'{root_path}/models'

# libraries = f'{root_path}/libraries'
# createPath(libraries)

#@title Install dependencies
#!git clone https://github.com/harmonai-org/sample-generator
#!git clone --recursive https://github.com/crowsonkb/v-diffusion-pytorch
#!pip install /content/sample-generator
#!pip install /content/v-diffusion-pytorch
#!pip install ipywidgets==7.7.1

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#@title Imports and definitions
import os
from prefigure.prefigure import get_all_args
from contextlib import contextmanager
from copy import deepcopy
import math
from pathlib import Path
#from google.colab import files
import gc
from diffusion import sampling
import torch
from torch import optim, nn
from torch.nn import functional as F
from torch.utils import data
from tqdm import trange
from einops import rearrange
import torchaudio
from audio_diffusion.models import DiffusionAttnUnet1D
import numpy as np
import scipy
#import soundfile as sf
import random
import matplotlib.pyplot as plt
#from IPython.display import display
#import IPython.display as ipd
from audio_diffusion.utils import Stereo, PadCrop
from glob import glob
import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--model", type=str, help="model file, no path, no extension")
    parser.add_argument("--custom_ckpt_path", type=str, help="custom model file, no path, no extension")

    parser.add_argument("--task", type=int, help="which audio task to run")
    parser.add_argument("--wave_file_1", type=str, help="user audio file to generate audio from")
    parser.add_argument("--wave_file_2", type=str, help="user audio file to generate audio from")
    parser.add_argument("--output_path", type=str, help="directory where generated audio files will be saved to")
    parser.add_argument("--file_prefix", type=str, help="start of wav file names")
    parser.add_argument("--steps", type=int)
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--sample_length_mult", type=int)
    parser.add_argument("--noise_level", type=float)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()















#@title Model code
class DiffusionUncond(nn.Module):
    def __init__(self, global_args):
        super().__init__()

        self.diffusion = DiffusionAttnUnet1D(global_args, n_attn_layers = 4)
        self.diffusion_ema = deepcopy(self.diffusion)
        self.rng = torch.quasirandom.SobolEngine(1, scramble=True)

import matplotlib.pyplot as plt
#import IPython.display as ipd

def plot_and_hear(audio, sr):
    """
    #original function had only the next 2 lines
    display(ipd.Audio(audio.cpu().clamp(-1, 1), rate=sr))
    plt.plot(audio.cpu().t().numpy())
    """

    dump = audio.cpu()
    
    filename=f"{args2.output_path}{args2.file_prefix}.wav"
    #add number to filename for duplicates
    if os.path.exists(filename):
        i = 1
        tmp = filename[:-4]
        while os.path.exists(f"{tmp} {i:04d}.wav"):
            i += 1
        filename = f"{tmp} {i:04d}.wav"
    
    print(f'Saving {filename}...', flush=True)
    torchaudio.save(filename, dump, sr)    
    print(f'Saved {filename}', flush=True)
  
def load_to_device(path, sr):
    audio, file_sr = torchaudio.load(path)
    if sr != file_sr:
      audio = torchaudio.transforms.Resample(file_sr, sr)(audio)
    audio = audio.to(device)
    return audio

def get_alphas_sigmas(t):
    """Returns the scaling factors for the clean image (alpha) and for the
    noise (sigma), given a timestep."""
    return torch.cos(t * math.pi / 2), torch.sin(t * math.pi / 2)

def get_crash_schedule(t):
    sigma = torch.sin(t * math.pi / 2) ** 2
    alpha = (1 - sigma ** 2) ** 0.5
    return alpha_sigma_to_t(alpha, sigma)

def t_to_alpha_sigma(t):
    """Returns the scaling factors for the clean image and for the noise, given
    a timestep."""
    return torch.cos(t * math.pi / 2), torch.sin(t * math.pi / 2)

def alpha_sigma_to_t(alpha, sigma):
    """Returns a timestep, given the scaling factors for the clean image and for
    the noise."""
    return torch.atan2(sigma, alpha) / math.pi * 2

#@title Args
sample_size = 65536 
sample_rate = 48000   
latent_dim = 0             

class Object(object):
    pass

args = Object()
args.sample_size = sample_size
args.sample_rate = sample_rate
args.latent_dim = latent_dim

"""# Model settings

Select the model you want to sample from:
---
Model name | Description | Sample rate | Output samples
--- | --- | --- | ---
glitch-440k |Trained on clips from samples provided by [glitch.cool](https://glitch.cool) | 48000 | 65536
jmann-small-190k |Trained on clips from Jonathan Mann's [Song-A-Day](https://songaday.world/) project | 48000 | 65536
jmann-large-580k |Trained on clips from Jonathan Mann's [Song-A-Day](https://songaday.world/) project | 48000 | 131072
maestro-150k |Trained on piano clips from the [MAESTRO](https://magenta.tensorflow.org/datasets/maestro) dataset | 16000 | 65536
unlocked-250k |Trained on clips from the [Unlocked Recordings](https://archive.org/details/unlockedrecordings) dataset | 16000 | 65536
honk-140k |Trained on recordings of the Canada Goose from [xeno-canto](https://xeno-canto.org/) | 16000 | 65536
"""

from urllib.parse import urlparse
import hashlib
#@title Create the model
model_name = args2.model #"glitch-440k" #@param ["glitch-440k", "jmann-small-190k", "jmann-large-580k", "maestro-150k", "unlocked-250k", "honk-140k", "custom"]

#@markdown ###Custom options

#@markdown If you have a custom fine-tuned model, choose "custom" above and enter a path to the model checkpoint here

#@markdown These options will not affect non-custom models
custom_ckpt_path = f'{model_path}/{args2.custom_ckpt_path}.ckpt' #''#@param {type: 'string'}

custom_sample_rate = sample_rate #16000 #@param {type: 'number'}
custom_sample_size = sample_size #65536 #@param {type: 'number'}

models_map = {

    "gwf-440k": {'downloaded': True,
                         'sha': "48caefdcbb7b15e1a0b3d08587446936302535de74b0e05e0d61beba865ba00a", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/gwf-440k.ckpt"],
                         'sample_rate': 48000,
                         'sample_size': 65536
                         },
    "jmann-small-190k": {'downloaded': True,
                         'sha': "1e2a23a54e960b80227303d0495247a744fa1296652148da18a4da17c3784e9b", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/jmann-small-190k.ckpt"],
                         'sample_rate': 48000,
                         'sample_size': 65536
                         },
    "jmann-large-580k": {'downloaded': True,
                         'sha': "6b32b5ff1c666c4719da96a12fd15188fa875d6f79f8dd8e07b4d54676afa096", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/jmann-large-580k.ckpt"],
                         'sample_rate': 48000,
                         'sample_size': 131072
                         },
    "maestro-uncond-150k": {'downloaded': True,
                         'sha': "49d9abcae642e47c2082cec0b2dce95a45dc6e961805b6500204e27122d09485", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/maestro-uncond-150k.ckpt"],
                         'sample_rate': 16000,
                         'sample_size': 65536
                         },
    "unlocked-uncond-250k": {'downloaded': True,
                         'sha': "af337c8416732216eeb52db31dcc0d49a8d48e2b3ecaa524cb854c36b5a3503a", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/unlocked-uncond-250k.ckpt"],
                         'sample_rate': 16000,
                         'sample_size': 65536
                         },
    "honk-140k": {'downloaded': True,
                         'sha': "a66847844659d287f55b7adbe090224d55aeafdd4c2b3e1e1c6a02992cb6e792", 
                         'uri_list': ["https://model-server.zqevans2.workers.dev/honk-140k.ckpt"],
                         'sample_rate': 16000,
                         'sample_size': 65536
                         },
}

#@markdown If you're having issues with model downloads, check this to compare the SHA:
check_model_SHA = False #@param{type:"boolean"}

def get_model_filename(diffusion_model_name):
    model_uri = models_map[diffusion_model_name]['uri_list'][0]
    model_filename = os.path.basename(urlparse(model_uri).path)
    return model_filename

def download_model(diffusion_model_name, uri_index=0):
    if diffusion_model_name != 'custom':
        model_filename = get_model_filename(diffusion_model_name)
        model_local_path = os.path.join(model_path, model_filename)
        if os.path.exists(model_local_path) and check_model_SHA:
            print(f'Checking {diffusion_model_name} File', flush=True)
            with open(model_local_path, "rb") as f:
                bytes = f.read() 
                hash = hashlib.sha256(bytes).hexdigest()
                print(f'SHA: {hash}', flush=True)
            if hash == models_map[diffusion_model_name]['sha']:
                print(f'{diffusion_model_name} SHA matches', flush=True)
                models_map[diffusion_model_name]['downloaded'] = True
            else:
                print(f"{diffusion_model_name} SHA doesn't match. Will redownload it.", flush=True)
        elif os.path.exists(model_local_path) and not check_model_SHA or models_map[diffusion_model_name]['downloaded']:
            #print(f'{diffusion_model_name} already downloaded. If the file is corrupt, enable check_model_SHA.', flush=True)
            models_map[diffusion_model_name]['downloaded'] = True

        if not models_map[diffusion_model_name]['downloaded']:
            for model_uri in models_map[diffusion_model_name]['uri_list']:
                wget(model_uri, model_local_path)
                with open(model_local_path, "rb") as f:
                  bytes = f.read() 
                  hash = hashlib.sha256(bytes).hexdigest()
                  print(f'SHA: {hash}', flush=True)
                if os.path.exists(model_local_path):
                    models_map[diffusion_model_name]['downloaded'] = True
                    return
                else:
                    print(f'{diffusion_model_name} model download from {model_uri} failed. Will try any fallback uri.', flush=True)
            print(f'{diffusion_model_name} download failed.')

if model_name == "custom":
  ckpt_path = custom_ckpt_path
  args.sample_size = custom_sample_size
  args.sample_rate = custom_sample_rate
else:
  model_info = models_map[model_name]
  download_model(model_name)
  ckpt_path = f'{model_path}/{get_model_filename(model_name)}'
  args.sample_size = model_info["sample_size"]
  args.sample_rate = model_info["sample_rate"]

print("Loading model...", flush=True)
model = DiffusionUncond(args)
model.load_state_dict(torch.load(ckpt_path)["state_dict"])
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = model.requires_grad_(False).to(device)
print("Model loaded", flush=True)

# # Remove non-EMA
del model.diffusion

model_fn = model.diffusion_ema

"""# Generate new sounds

Feeding white noise into the model to be denoised creates novel sounds in the "space" of the training data.
"""

#@markdown How many audio clips to create
batch_size = args2.batch_size # 16#@param {type:"number"}
#@markdown Number of steps (100 is a good start, more steps trades off speed for quality)
steps = args2.steps #100 #@param {type:"number"}
#@markdown Check the box below to skip this section when running all cells
skip_for_run_all = False #@param {type: "boolean"}
#@markdown Multiplier on the default sample length from the model, allows for longer audio clips at the expense of VRAM
sample_length_mult = args2.sample_length_mult #4#@param {type:"number"}

#if not skip_for_run_all:
if args2.task==0:
  torch.cuda.empty_cache()
  gc.collect()

  # Generate random noise to sample from
  print("Generating random noise to sample from ...", flush=True)
  noise = torch.randn([batch_size, 2, args.sample_size]).to(device)

  t = torch.linspace(1, 0, steps + 1, device=device)[:-1]
  step_list = get_crash_schedule(t)

  print("Generating samples from the noise ...", flush=True)
  # Generate the samples from the noise
  generated = sampling.iplms_sample(model_fn, noise, step_list, {})

  print("Hard clipping the generated audio ...", flush=True)
  # Hard-clip the generated audio
  generated = generated.clamp(-1, 1)

  print("Putting the results together ...", flush=True)
  # Put the demos together
  generated_all = rearrange(generated, 'b d n -> d (b n)')

  print("All samples", flush=True)
  plot_and_hear(generated_all, args.sample_rate)
  
  for ix, gen_sample in enumerate(generated):
    plot_and_hear(gen_sample.cpu(),args.sample_rate)
  #  print(f'sample #{ix + 1}', flush=True)
  #  display(ipd.Audio(gen_sample.cpu(), rate=args.sample_rate))
#else:
#  print("Skipping section, uncheck 'skip_for_run_all' to enable", flush=True)

"""# Regenerate your own sounds
By adding noise to an audio file and running it through the model to be denoised, new details will be created, pulling the audio closer to the "sonic space" of the model. The more noise you add, the more the sound will change.

The effect of this is a kind of "style transfer" on the audio. For those familiar with image generation models, this is analogous to an "init image".
"""

#@markdown Enter a path to an audio file you want to alter, or leave blank to upload a file (.wav or .flac)
file_path = args2.wave_file_1 #"" #@param{type:"string"}

#@markdown Total number of steps (100 is a good start, more steps trades off speed for quality)
steps = args2.steps #100#@param {type:"number"}

#@markdown How much (0-1) to re-noise the original sample. Adding more noise (a higher number) means a bigger change to the input audio
noise_level = args2.noise_level #0.6#@param {type:"number"}

#@markdown Multiplier on the default sample length from the model, allows for longer audio clips at the expense of VRAM
sample_length_mult = args2.sample_length_mult #4#@param {type:"number"}

#@markdown How many variations to create
batch_size = args2.batch_size #4 #@param {type:"number"}

#@markdown Check the box below to skip this section when running all cells
skip_for_run_all = True #@param {type: "boolean"}

effective_length = args.sample_size * sample_length_mult

#if not skip_for_run_all:
if args2.task==1:
  torch.cuda.empty_cache()
  gc.collect()

  if file_path == "":
    print("No file path provided, please upload a file", flush=True)
    uploaded = files.upload()
    file_path = list(uploaded.keys())[0]

  augs = torch.nn.Sequential(
    PadCrop(effective_length, randomize=True),
    Stereo()
  )

  audio_sample = load_to_device(file_path, args.sample_rate)

  audio_sample = augs(audio_sample).unsqueeze(0).repeat([batch_size, 1, 1])

  print("Initial audio sample", flush=True)
  plot_and_hear(audio_sample[0], args.sample_rate)

  t = torch.linspace(0, 1, steps + 1, device=device)
  step_list = get_crash_schedule(t)
  step_list = step_list[step_list < noise_level]

  alpha, sigma = t_to_alpha_sigma(step_list[-1])
  noised = torch.randn([batch_size, 2, effective_length], device='cuda')
  noised = audio_sample * alpha + noised * sigma

  generated = sampling.iplms_sample(model_fn, noised, step_list.flip(0)[:-1], {})

  print("Regenerated audio samples", flush=True)
  plot_and_hear(rearrange(generated, 'b d n -> d (b n)'), args.sample_rate)

  for ix, gen_sample in enumerate(generated):
    plot_and_hear(gen_sample.cpu(),args.sample_rate)
    #print(f'sample #{ix + 1}', flush=True)
    #display(ipd.Audio(gen_sample.cpu(), rate=args.sample_rate))

#else:
#  print("Skipping section, uncheck 'skip_for_run_all' to enable", flush=True)

"""# Interpolate between sounds
Diffusion models allow for interpolation between inputs through a process of deterministic noising and denoising. 

By deterministically noising two audio files, interpolating between the results, and deterministically denoising them, we can can create new sounds "between" the audio files provided.
"""

# Interpolation code taken and modified from CRASH
def compute_interpolation_in_latent(latent1, latent2, lambd):
    '''
    Implementation of Spherical Linear Interpolation: https://en.wikipedia.org/wiki/Slerp
    latent1: tensor of shape (2, n)
    latent2: tensor of shape (2, n)
    lambd: list of floats between 0 and 1 representing the parameter t of the Slerp
    '''
    device = latent1.device
    lambd = torch.tensor(lambd)

    assert(latent1.shape[0] == latent2.shape[0])

    # get the number of channels
    nc = latent1.shape[0]
    interps = []
    for channel in range(nc):
    
      cos_omega = latent1[channel]@latent2[channel] / \
          (torch.linalg.norm(latent1[channel])*torch.linalg.norm(latent2[channel]))
      omega = torch.arccos(cos_omega).item()

      a = torch.sin((1-lambd)*omega) / np.sin(omega)
      b = torch.sin(lambd*omega) / np.sin(omega)
      a = a.unsqueeze(1).to(device)
      b = b.unsqueeze(1).to(device)
      interps.append(a * latent1[channel] + b * latent2[channel])
    return rearrange(torch.cat(interps), "(c b) n -> b c n", c=nc) 

#@markdown Enter the paths to two audio files to interpolate between (.wav or .flac)
source_audio_path = args2.wave_file_1 #"" #@param{type:"string"}
target_audio_path = args2.wave_file_2 #"" #@param{type:"string"}

#@markdown Total number of steps (100 is a good start, can go lower for more speed/less quality)
steps = args2.steps #100#@param {type:"number"}

#@markdown Number of interpolated samples
n_interps = 12 #@param {type:"number"}

#@markdown Multiplier on the default sample length from the model, allows for longer audio clips at the expense of VRAM
sample_length_mult = args2.sample_length_mult #1#@param {type:"number"}

#@markdown Check the box below to skip this section when running all cells
skip_for_run_all = True #@param {type: "boolean"}

effective_length = args.sample_size * sample_length_mult

if args2.task==2:

  augs = torch.nn.Sequential(
    PadCrop(effective_length, randomize=True),
    Stereo()
  )

  if source_audio_path == "":
    print("No file path provided for the source audio, please upload a file", flush=True)
    uploaded = files.upload()
    source_audio_path = list(uploaded.keys())[0]

  audio_sample_1 = load_to_device(source_audio_path, args.sample_rate)

  print("Source audio sample loaded", flush=True)

  if target_audio_path == "":
    print("No file path provided for the target audio, please upload a file", flush=True)
    uploaded = files.upload()
    target_audio_path = list(uploaded.keys())[0]

  audio_sample_2 = load_to_device(target_audio_path, args.sample_rate)

  print("Target audio sample loaded", flush=True)

  audio_samples = augs(audio_sample_1).unsqueeze(0).repeat([2, 1, 1])
  audio_samples[1] = augs(audio_sample_2)

  print("Initial audio samples", flush=True)
  plot_and_hear(audio_samples[0], args.sample_rate)
  plot_and_hear(audio_samples[1], args.sample_rate)

  t = torch.linspace(0, 1, steps + 1, device=device)
  step_list = get_crash_schedule(t)

  reversed = sampling.iplms_sample(model_fn, audio_samples, step_list, {}, is_reverse=True)

  latent_series = compute_interpolation_in_latent(reversed[0], reversed[1], [k/n_interps for k in range(n_interps + 2)])

  generated = sampling.iplms_sample(model_fn, latent_series, step_list.flip(0)[:-1], {})

  # Put the demos together
  generated_all = rearrange(generated, 'b d n -> d (b n)')

  print("Full interpolation", flush=True)
  plot_and_hear(generated_all, args.sample_rate)
  for ix, gen_sample in enumerate(generated):
    print(f'sample #{ix + 1}', flush=True)
    #display(ipd.Audio(gen_sample.cpu(), rate=args.sample_rate))
#else:
#  print("Skipping section, uncheck 'skip_for_run_all' to enable", flush=True)