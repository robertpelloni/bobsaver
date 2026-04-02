# script by Jason Rampe https://softology/pro

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from diffusers import KolorsPipeline, KolorsImg2ImgPipeline
from diffusers.utils import load_image
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="Prompt")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--guidance_scale", type=float, help="Guidance scale, default is 5.0")
    parser.add_argument("--w", type=int, help="Image width")
    parser.add_argument("--h", type=int, help="Image height")
    parser.add_argument("--steps", type=int, help="iterations")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--init_image", type=str)
    parser.add_argument("--init_image_strength", type=float)
    parser.add_argument("--image_file", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

if args2.init_image != None:
    #setup img2img model
    sys.stdout.write(f"Setting up Img2ImgPipeline ...\n")
    sys.stdout.flush()

    pipe2 = KolorsImg2ImgPipeline.from_pretrained(
        "Kwai-Kolors/Kolors-diffusers",
        torch_dtype=torch.float16,
        variant="fp16"
    ).to("cuda")

    sys.stdout.write("Generating image ...\n")
    sys.stdout.flush()

    image = pipe2(
        prompt=args2.prompt,
        negative_prompt=args2.negative_prompt,
        guidance_scale=args2.guidance_scale,
        num_inference_steps=args2.steps,
        width=args2.w,
        height=args2.h,
        image=load_image(args2.init_image),
        strength=args2.init_image_strength,
        generator=torch.Generator(pipe2.device).manual_seed(args2.seed),
    ).images[0]

else:
    sys.stdout.write("Setting up pipeline ...\n")
    sys.stdout.flush()

    pipe = KolorsPipeline.from_pretrained(
        "Kwai-Kolors/Kolors-diffusers", 
        torch_dtype=torch.float16, 
        variant="fp16"
    ).to("cuda")

    sys.stdout.write("Generating image ...\n")
    sys.stdout.flush()

    image = pipe(
        prompt=args2.prompt,
        negative_prompt=args2.negative_prompt,
        guidance_scale=args2.guidance_scale, #5.0,
        num_inference_steps=args2.steps, #50,
        width=args2.w,
        height=args2.h,
        generator=torch.Generator(pipe.device).manual_seed(args2.seed),
    ).images[0]


sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

image.save(args2.image_file)

sys.stdout.write("Done\n")
sys.stdout.flush()

