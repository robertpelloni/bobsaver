import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffsynth import ModelManager, SDImagePipeline, SDVideoPipeline, ControlNetConfigUnit, VideoData, save_video, save_frames
from diffsynth.extensions.RIFE import RIFEInterpolater
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="prompt")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--height", type=int, help="initial image height, in pixel space")
    parser.add_argument("--width", type=int, help="initial image width, in pixel space")
    parser.add_argument("--numframes", type=int, help="how many frames to create")
    parser.add_argument("--fps", type=int, help="source video fps")
    parser.add_argument("--output_file", type=str)
    parser.add_argument("--model", type=str)
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading models ...\n")
sys.stdout.flush()

# Load models
model_manager = ModelManager(torch_dtype=torch.float16, device="cuda")
model_manager.load_models([
    f"models/stable_diffusion/{args2.model}",#"models/stable_diffusion/dreamshaper_8.safetensors",
    "models/AnimateDiff/mm_sd_v15_v2.ckpt",
    "models/RIFE/flownet.pkl"
])

sys.stdout.write("Creating image pipeline ...\n")
sys.stdout.flush()

# Text -> Image
pipe_image = SDImagePipeline.from_model_manager(model_manager)
torch.manual_seed(0)
image = pipe_image(
    prompt = args2.prompt, #"lightning storm, sea",
    negative_prompt = args2.negative_prompt, #"",
    cfg_scale=7.5,
    num_inference_steps=30, height=args2.height, width=args2.width,
)

sys.stdout.write("Creating video pipeline ...\n")
sys.stdout.flush()

# Text + Image -> Video (6GB VRAM is enough!)
pipe = SDVideoPipeline.from_model_manager(model_manager)
output_video = pipe(
    prompt = args2.prompt, #"lightning storm, sea",
    negative_prompt = args2.negative_prompt, #"",
    cfg_scale=7.5,
    num_frames=args2.numframes, #64,
    num_inference_steps=10, height=args2.height, width=args2.width,
    animatediff_batch_size=16, animatediff_stride=1, input_frames=[image]*64, denoising_strength=0.9,
    vram_limit_level=0,
)

sys.stdout.write("Creating video ...\n")
sys.stdout.flush()

# Video -> Video with high fps
interpolater = RIFEInterpolater.from_model_manager(model_manager)
output_video = interpolater.interpolate(output_video, num_iter=3)

sys.stdout.write("Saving video ...\n")
sys.stdout.flush()

# Save images and video
save_video(output_video, f"{args2.output_file}.mp4", fps=args2.fps)

sys.stdout.write("Done\n")
sys.stdout.flush()

