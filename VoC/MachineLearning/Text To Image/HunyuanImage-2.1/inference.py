import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import datetime

script_start = datetime.datetime.now()

os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'

import torch
from hyimage.diffusion.pipelines.hunyuanimage_pipeline import HunyuanImagePipeline
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="Prompt")
    parser.add_argument("--model", type=str, help="Prompt")
    parser.add_argument("--guidance_scale", type=float, help="Guidance scale, default is 3.25")
    parser.add_argument("--w", type=int, help="Image width")
    parser.add_argument("--h", type=int, help="Image height")
    parser.add_argument("--steps", type=int, help="iterations")
    parser.add_argument("--seed", type=int, help="random seed")

    parser.add_argument("--reprompt", type=int, help="0 no 1 yes")
    parser.add_argument("--refiner", type=int, help="0 no 1 yes")
    
    parser.add_argument("--image_file", type=str)
    parser.add_argument("--shift", type=int)
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

if args2.reprompt == 0:
    reprompt=False
if args2.reprompt == 1:
    reprompt=True

if args2.refiner == 0:
    refiner=False
if args2.refiner == 1:
    refiner=True

# Supported model_name: hunyuanimage-v2.1, hunyuanimage-v2.1-distilled
model_name = args2.model
pipe = HunyuanImagePipeline.from_pretrained(model_name=model_name, use_fp8=True)
pipe = pipe.to("cuda")

#prompt = "A cute, cartoon-style anthropomorphic penguin plush toy with fluffy fur, standing in a painting studio, wearing a red knitted scarf and a red beret with the word “Tencent” on it, holding a paintbrush with a focused expression as it paints an oil painting of the Mona Lisa, rendered in a photorealistic photographic style."
prompt = args2.prompt
image = pipe(
    prompt=prompt,
    # Examples of supported resolutions and aspect ratios for HunyuanImage-2.1:
    # 16:9  -> width=2560, height=1536
    # 4:3   -> width=2304, height=1792
    # 1:1   -> width=2048, height=2048
    # 3:4   -> width=1792, height=2304
    # 9:16  -> width=1536, height=2560
    # Please use one of the above width/height pairs for best results.
    width=args2.w,
    height=args2.h,
    
    # Enable prompt enhancement (which may result in higher GPU memory usage)
    use_reprompt=False,#reprompt,  
    use_refiner=True,#refiner,   # Enable refiner model
    # For the distilled model, use 8 steps for faster inference.
    # For the non-distilled model, use 50 steps for better quality.
    num_inference_steps=args2.steps, 
    
    guidance_scale=3.25 if "distilled" in model_name else 3.5,
    shift=4 if "distilled" in model_name else 5,
    seed=args2.seed,
)

image.save(f"{args2.image_file}")