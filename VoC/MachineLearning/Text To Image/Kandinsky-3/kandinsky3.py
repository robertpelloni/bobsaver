import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
#from kandinsky3 import get_T2I_pipeline
from diffusers import AutoPipelineForText2Image
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt")
    parser.add_argument("--w", type=int)
    parser.add_argument("--h", type=int)
    parser.add_argument("--num_steps", type=int)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--guidance_scale", type=int)
    parser.add_argument("--image_file", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

torch.manual_seed(args2.seed)

sys.stdout.write("Setting up pipeline ...\n")
sys.stdout.flush()

#t2i_pipe = get_T2I_pipeline('cuda', fp16=True)

pipe = AutoPipelineForText2Image.from_pretrained(
    "kandinsky-community/kandinsky-3",
    variant="fp16",
    torch_dtype=torch.float16
    )
#pipe.to("cuda")
pipe.enable_model_cpu_offload()

sys.stdout.write("Generating image ...\n")
sys.stdout.flush()

images = pipe(
    args2.prompt,
    #images_num=args2.batch_size,
    guidance_scale=args2.guidance_scale,
    height=args2.h,
    width=args2.w,
    num_inference_steps=args2.num_steps
).images[0]

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

images.save(args2.image_file, format='png')

sys.stdout.write("Done\n")
sys.stdout.flush()
