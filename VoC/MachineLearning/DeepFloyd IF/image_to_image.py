import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

from diffusers import DiffusionPipeline
from diffusers.utils import pt_to_pil
import torch
import argparse
from PIL import Image
from transformers import T5EncoderModel
from diffusers import IFImg2ImgPipeline
from diffusers import IFImg2ImgSuperResolutionPipeline

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--input_image", type=str)
    parser.add_argument("--prompt", type=str, help="the prompt to render")
    #parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--guidance1", type=float)
    parser.add_argument("--guidance2", type=float)
    parser.add_argument("--guidance3", type=float)
    parser.add_argument("--respacing1", type=str)
    parser.add_argument("--respacing2", type=str)
    parser.add_argument("--respacing3", type=str)
    parser.add_argument("--noise", type=float)
    parser.add_argument("--image_file", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

original_image = Image.open(args2.input_image)

sys.stdout.write("Loading T5Encoder model...\n")
sys.stdout.flush()

text_encoder = T5EncoderModel.from_pretrained(
    "DeepFloyd/IF-I-XL-v1.0",
    subfolder="text_encoder", 
    device_map="auto", 
    load_in_8bit=True, 
    variant="8bit"
)

sys.stdout.write("Loading IFImg2ImgPipeline model...\n")
sys.stdout.flush()

pipe = IFImg2ImgPipeline.from_pretrained(
    "DeepFloyd/IF-I-XL-v1.0", 
    text_encoder=text_encoder, 
    unet=None, 
    device_map="auto"
)

sys.stdout.write("Encoding prompt...\n")
sys.stdout.flush()

prompt = args2.prompt

prompt_embeds, negative_embeds = pipe.encode_prompt(prompt)

del text_encoder
del pipe

sys.stdout.write("Loading IFImg2ImgPipeline model...\n")
sys.stdout.flush()

pipe = IFImg2ImgPipeline.from_pretrained(
    "DeepFloyd/IF-I-XL-v1.0", 
    text_encoder=None, 
    variant="fp16", 
    torch_dtype=torch.float16, 
    device_map="auto"
)

generator = torch.Generator().manual_seed(0)

sys.stdout.write("Generating image...\n")
sys.stdout.flush()

image = pipe(
    image=original_image,
    prompt_embeds=prompt_embeds,
    negative_prompt_embeds=negative_embeds, 
    output_type="pt",
    generator=generator,
).images


sys.stdout.write("Saving image...\n")
sys.stdout.flush()
pil_image = pt_to_pil(image)
pil_image[0].save(args2.image_file)
sys.stdout.write("Progress saved\n")
sys.stdout.flush()

del pipe

sys.stdout.write("Loading IFImg2ImgSuperResolutionPipeline model...\n")
sys.stdout.flush()

pipe = IFImg2ImgSuperResolutionPipeline.from_pretrained(
    "DeepFloyd/IF-II-L-v1.0", 
    text_encoder=None, 
    variant="fp16", 
    torch_dtype=torch.float16, 
    device_map="auto"
)

sys.stdout.write("Generating image...\n")
sys.stdout.flush()

image = pipe(
    image=image,
    original_image=original_image,
    prompt_embeds=prompt_embeds,
    negative_prompt_embeds=negative_embeds, 
    generator=generator,
).images

sys.stdout.write("Saving final  image...\n")
sys.stdout.flush()
#pil_image = pt_to_pil(image)
#pil_image.save(args2.image_file)
image[0].save(args2.image_file)
sys.stdout.write("Progress saved\n")
sys.stdout.flush()
