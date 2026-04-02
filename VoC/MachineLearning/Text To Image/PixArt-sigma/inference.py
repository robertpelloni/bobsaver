import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
from diffusers import  Transformer2DModel, PixArtSigmaPipeline
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--model", type=str, help="model name")
    parser.add_argument("--style", type=str, help="style name")
    parser.add_argument("--negativeprompt", type=str, help="negative prompt")
    parser.add_argument("--output", type=str, help="output image filename")
    parser.add_argument("--width", type=int, help="image width")
    parser.add_argument("--height", type=int, help="image height")
    parser.add_argument("--dalle3", type=int, help="use DALL-E 3 Consistency Decoder, 1=yes, 0=no")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--guidance_scale", type=float, help="guidance scale")
    parser.add_argument("--steps", type=int, help="iterations")

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

weight_dtype = torch.float16

sys.stdout.write("Loading transformer ...\n")
sys.stdout.flush()

transformer = Transformer2DModel.from_pretrained(
    args2.model,
    subfolder='transformer', 
    torch_dtype=weight_dtype,
    use_safetensors=True,
)

sys.stdout.write("Loading pipe ...\n")
sys.stdout.flush()


pipe = PixArtSigmaPipeline.from_pretrained(
    "PixArt-alpha/pixart_sigma_sdxlvae_T5_diffusers",
    transformer=transformer,
    torch_dtype=weight_dtype,
    use_safetensors=True,
)
pipe.to(device)

# Enable memory optimizations.
# pipe.enable_model_cpu_offload()

prompt = args2.prompt

sys.stdout.write("Generating image ...\n")
sys.stdout.flush()

image = pipe(
    prompt,
    negative_prompt=args2.negativeprompt,
    height=args2.height,
    width=args2.width,
    guidance_scale=args2.guidance_scale,
    num_inference_steps=args2.steps
    ).images[0]

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()
image.save(args2.output)
sys.stdout.write("Done\n")
sys.stdout.flush()

