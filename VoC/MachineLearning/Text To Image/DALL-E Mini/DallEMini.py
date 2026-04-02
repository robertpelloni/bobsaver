# Bare Bones Console Python Dall-E Mini script by RebootTech ( https://twitter.com/RebootTech4 ).
#
# Based on https://colab.research.google.com/github/borisdayma/dalle-mini/blob/main/tools/inference/inference_pipeline.ipynb
#         by Boris Dayma https://twitter.com/borisdayma
# Used generic args parsing library and notices from Softology.pro for easy integration if desired
# Licensed under the Apache License 2.0 license https://github.com/borisdayma/dalle-mini/blob/main/LICENSE



import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import torch
import argparse, os, sys, glob
import torch
import numpy as np
from tqdm import tqdm
from PIL import Image

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

#os.environ['WANDB_SILENT']="true"
os.environ['WANDB_MODE']="dryrun"

def is_float(element):
    try:
        float(element)
        return True
    except ValueError:
        return False

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.', required=True)
  parser.add_argument('--seed', type=int, help='Random seed.', required=True)
#  parser.add_argument('--sizex', type=int, help='Image width.', default=256) -- currently supports 256x256 only
#  parser.add_argument('--sizey', type=int, help='Image height.', default=256)
  parser.add_argument('--batches', type=int, help='Batch count.', default=4)
  parser.add_argument('--updates', type=int, help='Save an generation frame every n generation.', default=1)

  # optional params that should be NoneType if not specified
  parser.add_argument('--cond_scale', type=float, help='Condition_scale.', default=10.0)
  parser.add_argument('--gen_top_k', type=int, help='Limit sampling pool to k words.')
  parser.add_argument('--gen_top_p', type=float, help='Limit sampling pool to p% probability mass percent represented as a decimal between 0 and 1.')
  parser.add_argument('--gen_temp', type=float, help='Apply temperature to softmax. Lower numbers track the prompt better but are less creative. Represented as a decimal between zero and 1.')

  parser.add_argument('--less_vram', type=int, help='Images per batch.', default=4)

  parser.add_argument('--model', type=str)
  parser.add_argument('--images_per_batch', type=int, help='Images per batch.', default=4)
  parser.add_argument('--image_file', type=str, help='Output image name.', required=True)
  parser.add_argument('--frame_dir', type=str, help='Output directory for ungridded indivdual images.', required=True)
  args = parser.parse_args()
  return args

args2=parse_args();

args2.sizex = 256
args2.sizey = 256

sys.stdout.write("Models are cached under ..\\..\\.cache\\artifacts\n")
sys.stdout.write("Downloading stat is always shown even when loading cached models\n")
sys.stdout.flush()

if args2.less_vram == 1:
    #https://github.com/saharmor/dalle-playground/issues/14
    #helps reduce VRAM usage a lot
    #supposedly can be much slower, 3090 tests show same speed, 2080 shows slower performance when enabled
    os.environ["XLA_PYTHON_CLIENT_ALLOCATOR"] = "platform"

# Model references

if args2.batches is None:
    args2.batches = 4
if args2.images_per_batch is None:
    args2.images_per_batch = 4

if args2.cond_scale is None:
    args2.cond_scale = 10.0


n_batches = int(args2.batches)
n_images_per_batch = int(args2.images_per_batch)
n_cond_scale = 10.0
n_sizex = int(args2.sizex)
n_sizey = int(args2.sizey)
n_gen_top_k = None
n_gen_top_p = None
n_gen_temp = None

if is_float(args2.cond_scale):
    float(args2.cond_scale)


if args2.gen_top_k is not None:
    n_gen_top_k = int(args2.gen_top_k)

if args2.gen_top_p is not None:
    n_gen_top_p = float(args2.gen_top_p)

if args2.gen_temp is not None:
    n_gen_temp = float(args2.gen_temp)

prompts = [ phrase.strip() for phrase in args2.prompt.split("|")]

n_predictions = n_batches * n_images_per_batch * len(prompts)

n_images_per_batch = n_images_per_batch * len(prompts)

if args2.updates <= 1:
    args2.updates = 1

if args2.updates > n_predictions:
    args2.updates = n_predictions

# dalle-mega
# DALLE_MODEL = "dalle-mini/dalle-mini/mega-1-fp16:latest"  # can be wandb artifact or 🤗 Hub or local folder or google bucket
DALLE_MODEL = args2.model
DALLE_COMMIT_ID = None

# if the notebook crashes too often you can use dalle-mini instead by uncommenting below line
# DALLE_MODEL = "dalle-mini/dalle-mini/mini-1:v0"

# VQGAN model
VQGAN_REPO = "dalle-mini/vqgan_imagenet_f16_16384"
VQGAN_COMMIT_ID = "e93a26e7707683d349bf5d5c41c5b0ef69b677a9"
import jax
import jax.numpy as jnp

# check how many devices are available
jax.local_device_count()

# Load models & tokenizer
from dalle_mini import DalleBart, DalleBartProcessor
from vqgan_jax.modeling_flax_vqgan import VQModel
from transformers import CLIPProcessor, FlaxCLIPModel

# Load dalle-mini
model, params = DalleBart.from_pretrained(
    DALLE_MODEL, revision=DALLE_COMMIT_ID, dtype=jnp.float16, _do_init=False
)

# Load VQGAN
vqgan, vqgan_params = VQModel.from_pretrained(
    VQGAN_REPO, revision=VQGAN_COMMIT_ID, _do_init=False
)

from flax.jax_utils import replicate

params = replicate(params)
vqgan_params = replicate(vqgan_params)

from functools import partial

# model inference
@partial(jax.pmap, axis_name="batch", static_broadcasted_argnums=(3, 4, 5, 6))
def p_generate(
    tokenized_prompt, key, params, top_k, top_p, temperature, condition_scale
):
    return model.generate(
        **tokenized_prompt,
        prng_key=key,
        params=params,
        top_k=top_k,
        top_p=top_p,
        temperature=temperature,
        condition_scale=condition_scale,
    )


# decode image
@partial(jax.pmap, axis_name="batch")
def p_decode(indices, params):
    return vqgan.decode_code(indices, params=params)

import random

# create a random key
seed = int(args2.seed)
#seed = random.randint(0, 2**32 - 1)
key = jax.random.PRNGKey(seed)

from dalle_mini import DalleBartProcessor

processor = DalleBartProcessor.from_pretrained(DALLE_MODEL, revision=DALLE_COMMIT_ID)



tokenized_prompts = processor(prompts)

tokenized_prompt = replicate(tokenized_prompts)

# number of predictions per prompt
# We can customize generation parameters (see https://huggingface.co/blog/how-to-generate)
gen_top_k = n_gen_top_k
gen_top_p = n_gen_top_p
temperature = n_gen_temp
cond_scale = n_cond_scale

from flax.training.common_utils import shard_prng_key
import numpy as np
from PIL import Image
from einops import rearrange
import torchvision.transforms as transforms
from tqdm import trange
from torchvision.utils import make_grid
from torchvision.utils import save_image
from torchvision.transforms import ToPILImage

image_count = 0

#print(f"Prompts: {prompts}\n")
# generate images
torchnp = list()
images = []
imagestst = []
all_samples=list()


# We can customize generation parameters (see https://huggingface.co/blog/how-to-generate)
gen_top_k = None
gen_top_p = None
temperature = None
cond_scale = 10.0

generation_iter = 1

for i in trange(max(n_predictions // jax.device_count(), 1), file=sys.stderr):
    # get a new key
    key, subkey = jax.random.split(key)
    # generate images

    encoded_images = p_generate(
        tokenized_prompt,
        shard_prng_key(subkey),
        params,
        gen_top_k,
        gen_top_p,
        temperature,
        cond_scale,
    )
    # remove BOS
    encoded_images = encoded_images.sequences[..., 1:]
    # decode images
    decoded_images = p_decode(encoded_images, vqgan_params)
    decoded_images = decoded_images.clip(0.0, 1.0).reshape((-1, args2.sizex, args2.sizey, 3))

    for decoded_img in decoded_images:
        # dalle-mini uses pillow.  make_grid uses torchvision..  so we have to convert between the two
        # technically, pillow is probably faster if we can use it.
        torchnp.append(transforms.ToTensor()(np.asarray(decoded_img, dtype=np.float32)))

        sys.stdout.flush()
        sys.stdout.write(f'Iteration {generation_iter}\n')
        sys.stdout.flush()

        # saves single images to output directory
        img = Image.fromarray(np.asarray(decoded_img * 255, dtype=np.uint8))
        images.append(img)

        image_count += 1
        save_name = args2.image_file
        save_name = save_name[:240]
        save_name = save_name[:-4] +f" {image_count}.png"
        img.save(save_name)
        
        generation_iter = generation_iter + 1

grid = make_grid(torchnp, nrow=n_images_per_batch)

#save the final grid image here
sys.stdout.flush()
sys.stdout.write('Saving progress ...\n')
sys.stdout.flush()
save_image(grid, args2.image_file)
sys.stdout.flush()
sys.stdout.write('Progress saved\n')
sys.stdout.flush()

# score images
#        @partial(jax.pmap, axis_name="batch")
#       def p_clip(inputs, params):
#           logits = clip(params=params, **inputs).logits_per_image
#           return logits


#        from flax.training.common_utils import shard

# get clip scores
#        clip_inputs = clip_processor(
#            text=prompts * jax.device_count(),
#            images=images,
#            return_tensors="np",
#            padding="max_length",
#            max_length=77,
#            truncation=True,
#        ).data
#        logits = p_clip(shard(clip_inputs), clip_params)

#        # organize scores per prompt
#        p = len(prompts)
#        logits = np.asarray([logits[:, i::p, i] for i in range(p)]).squeeze()
# logits = rearrange(logits, '1 b p -> p b')

#        logits.shape
#        for i, prompt in enumerate(prompts):
#            print(f"Prompt: {prompt}\n")
#            for idx in logits[i].argsort()[::-1]:
# display(images[idx * p + i])
#                print(f"Score: {jnp.asarray(logits[i][idx], dtype=jnp.float32):.2f}\n")
#            print()

