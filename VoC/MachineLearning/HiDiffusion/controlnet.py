import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffusers import StableDiffusionXLControlNetPipeline, ControlNetModel, DDIMScheduler
import numpy as np
import torch
import cv2
from PIL import Image
from hidiffusion import apply_hidiffusion, remove_hidiffusion
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_image", type=str, help="the image to process")
    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--w", type=int, help="image height, in pixel space")
    parser.add_argument("--h", type=int, help="image width, in pixel space")
    parser.add_argument("--target_image", type=str, help="the output processed image")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()








sys.stdout.write("Loading source image ...\n")
sys.stdout.flush()

# load Yoshua_Bengio.jpg in the assets file.
path = args2.input_image
image = Image.open(path)

sys.stdout.write("Generating canny image ...\n")
sys.stdout.flush()

# get canny image
image = np.array(image)
image = cv2.Canny(image, 100, 200)
image = image[:, :, None]
image = np.concatenate([image, image, image], axis=2)
canny_image = Image.fromarray(image)

sys.stdout.write("Loading controlnet model ...\n")
sys.stdout.flush()

# initialize the models and pipeline
controlnet_conditioning_scale = 0.5  # recommended for good generalization
controlnet = ControlNetModel.from_pretrained(
    "diffusers/controlnet-canny-sdxl-1.0", torch_dtype=torch.float16, variant="fp16"
)

sys.stdout.write("Loading scheduler ...\n")
sys.stdout.flush()

scheduler = DDIMScheduler.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="scheduler")

sys.stdout.write("Setting up pipeline ...\n")
sys.stdout.flush()

pipe = StableDiffusionXLControlNetPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0", controlnet=controlnet, torch_dtype=torch.float16,
    scheduler = scheduler
)

sys.stdout.write("Processing image ...\n")
sys.stdout.flush()

# Apply hidiffusion with a single line of code.
apply_hidiffusion(pipe)

pipe.enable_model_cpu_offload()
pipe.enable_xformers_memory_efficient_attention()

prompt = args2.prompt #"The Joker, high face detail, high detail, muted color, 8k"
negative_prompt = args2.negative_prompt #"blurry, ugly, duplicate, poorly drawn, deformed, mosaic."

image = pipe(
    prompt, controlnet_conditioning_scale=controlnet_conditioning_scale, image=canny_image,
    height=args2.h, width=args2.w, guidance_scale=7.5, negative_prompt = negative_prompt, eta=1.0
).images[0]

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

image.save(args2.target_image)

sys.stdout.write("Done\n")
sys.stdout.flush()
