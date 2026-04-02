import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
from diffusers import DiffusionPipeline, DPMSolverMultistepScheduler
from diffusers.utils import export_to_video
from PIL import Image

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str)
    parser.add_argument("--negative_prompt", type=str)
    parser.add_argument("--model", type=str)
    parser.add_argument("--inference_steps", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--width", type=int)
    parser.add_argument("--num_frames", type=int)
    parser.add_argument("--guidance_scale", type=float)
    parser.add_argument("--output", type=str)
    parser.add_argument("--output_scaled", type=str)
    parser.add_argument("--upscale", type=int)
    parser.add_argument("--upscale_height", type=int)
    parser.add_argument("--upscale_width", type=int)
    parser.add_argument("--upscale_steps", type=int)
    parser.add_argument("--upscale_strength", type=float)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

pipe = DiffusionPipeline.from_pretrained(args2.model, torch_dtype=torch.float16)

pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
pipe.enable_model_cpu_offload()

sys.stdout.write("Generating video ...\n")
sys.stdout.flush()

video_frames = pipe(args2.prompt, negative_prompt=args2.negative_prompt, num_inference_steps=args2.inference_steps, height=args2.height, width=args2.width, num_frames=args2.num_frames, guidance_scale=args2.guidance_scale).frames

sys.stdout.write("Saving video ...\n")
sys.stdout.flush()

video_path = export_to_video(video_frames, output_video_path=args2.output)

if args2.upscale == 1:

    #clear VRAM before loading upscale model
    del pipe
    torch.cuda.empty_cache()

    sys.stdout.write("Upscaling video x2 ...\n")
    sys.stdout.flush()

    pipe = DiffusionPipeline.from_pretrained("cerspense/zeroscope_v2_XL", torch_dtype=torch.float16)
    pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
    pipe.enable_model_cpu_offload()
    pipe.enable_vae_slicing()
    #next line too slow
    #pipe.unet.enable_forward_chunking(chunk_size=1, dim=1)

    video = [Image.fromarray(frame).resize((args2.upscale_width, args2.upscale_height)) for frame in video_frames]

    video_frames = pipe(args2.prompt, negative_prompt=args2.negative_prompt, video=video, num_inference_steps=args2.upscale_steps, strength=args2.upscale_strength, guidance_scale=args2.guidance_scale).frames

    sys.stdout.write("Saving upscaled video ...\n")
    sys.stdout.flush()

    video_path = export_to_video(video_frames, output_video_path=args2.output_scaled)

sys.stdout.write("Done\n")
sys.stdout.flush()
