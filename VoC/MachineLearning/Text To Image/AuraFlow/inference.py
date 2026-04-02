import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffusers import AuraFlowPipeline
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--model", type=str)
    parser.add_argument("--height", type=int, help="image height, in pixel space")
    parser.add_argument("--width", type=int, help="image width, in pixel space")
    parser.add_argument("--seed", type=int, help="the seed (for reproducible sampling)")
    parser.add_argument("--steps", type=int, help="steps")
    parser.add_argument("--image_file", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Creating pipeline ...\n")
sys.stdout.flush()


pipeline = AuraFlowPipeline.from_pretrained(
    #"fal/AuraFlow",
    #"fal/AuraFlow-v0.2",
    args2.model,
    torch_dtype=torch.float16
).to("cuda")

sys.stdout.write("Generating pipeline ...\n")
sys.stdout.flush()

image = pipeline(
    prompt=args2.prompt,
    height=args2.height,
    width=args2.width,
    num_inference_steps=args2.steps, 
    generator=torch.Generator().manual_seed(args2.seed),
    guidance_scale=3.5,
).images[0]

sys.stdout.flush()
sys.stdout.write('Saving progress ...\n')
sys.stdout.flush()

image.save(args2.image_file)

sys.stdout.flush()
sys.stdout.write('Progress saved\n')
sys.stdout.flush()
