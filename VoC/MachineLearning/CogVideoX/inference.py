import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from diffusers import CogVideoXPipeline
from diffusers.utils import export_to_video
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="prompt")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--output_file", type=str, help="output movie file")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()


prompt = args2.prompt

sys.stdout.write("Creating CogVideoXPipeline ...\n")
sys.stdout.flush()

pipe = CogVideoXPipeline.from_pretrained(
    "THUDM/CogVideoX-5b",
    torch_dtype=torch.bfloat16
)

pipe.enable_model_cpu_offload()
pipe.vae.enable_tiling()

sys.stdout.write("Creating movie ...\n")
sys.stdout.flush()

video = pipe(
    prompt=prompt,
    num_videos_per_prompt=1,
    num_inference_steps=50,
    num_frames=49,
    guidance_scale=6,
    generator=torch.Generator(device="cuda").manual_seed(args2.seed),
).frames[0]

sys.stdout.write(f"Saving {args2.output_file} ...\n")
sys.stdout.flush()

export_to_video(video, args2.output_file, fps=8)

sys.stdout.write("Done\n")
sys.stdout.flush()
