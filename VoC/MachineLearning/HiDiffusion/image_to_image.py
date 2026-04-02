import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import numpy as np
from PIL import Image
from diffusers import ControlNetModel, StableDiffusionXLControlNetImg2ImgPipeline, DDIMScheduler
from hidiffusion import apply_hidiffusion, remove_hidiffusion
import cv2 
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

sys.stdout.write("Loading controlnet ...\n")
sys.stdout.flush()

controlnet = ControlNetModel.from_pretrained(
    "diffusers/controlnet-canny-sdxl-1.0", torch_dtype=torch.float16, variant="fp16"
).to("cuda")

sys.stdout.write("Loading scheduler ...\n")
sys.stdout.flush()

scheduler = DDIMScheduler.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="scheduler")

sys.stdout.write("Setting up pipeline ...\n")
sys.stdout.flush()

pipe = StableDiffusionXLControlNetImg2ImgPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    controlnet=controlnet,
    scheduler = scheduler,
    torch_dtype=torch.float16,
).to("cuda")

# Apply hidiffusion with a single line of code.
apply_hidiffusion(pipe)

pipe.enable_model_cpu_offload()
pipe.enable_xformers_memory_efficient_attention()

sys.stdout.write("Loading image ...\n")
sys.stdout.flush()

path = args2.input_image
ori_image = Image.open(path)
# get canny image

sys.stdout.write("Getting canny image ...\n")
sys.stdout.flush()

image = np.array(ori_image)
image = cv2.Canny(image, 50, 120)
image = image[:, :, None]
image = np.concatenate([image, image, image], axis=2)
canny_image = Image.fromarray(image)

controlnet_conditioning_scale = 0.5  # recommended for good generalization
prompt = args2.prompt #"Lara Croft with brown hair, and is wearing a tank top, a brown backpack. The room is dark and has an old-fashioned decor with a patterned floor and a wall featuring a design with arches and a dark area on the right side, muted color, high detail, 8k high definition award winning"
negative_prompt = args2.negative_prompt #"underexposed, poorly drawn hands, duplicate hands, overexposed, bad art, beginner, amateur, abstract, disfigured, deformed, close up, weird colors, watermark"

sys.stdout.write("Processing image ...\n")
sys.stdout.flush()

image = pipe(prompt,
    image=ori_image,
    control_image=canny_image,
    height=args2.h,
    width=args2.w,
    strength=0.99,
    num_inference_steps=50,
    controlnet_conditioning_scale=controlnet_conditioning_scale,
    guidance_scale=12.5,
    negative_prompt = negative_prompt,
    eta=1.0
).images[0]

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

image.save(args2.target_image)

sys.stdout.write("Done\n")
sys.stdout.flush()

