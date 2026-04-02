import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffsynth import ModelManager, SDVideoPipeline, ControlNetConfigUnit, VideoData, save_video
from diffsynth.extensions.FastBlend import FastBlendSmoother
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--source_video", type=str, help="video to rerender")
    parser.add_argument("--prompt", type=str, help="prompt")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--model", type=str)
    parser.add_argument("--fps", type=int, help="source video fps")
    parser.add_argument("--output_file", type=str)
    
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
    "models/ControlNet/control_v11f1p_sd15_depth.pth",
    "models/ControlNet/control_v11p_sd15_softedge.pth",
    "models/RIFE/flownet.pkl"
])

sys.stdout.write("Setting up pipeline ...\n")
sys.stdout.flush()

pipe = SDVideoPipeline.from_model_manager(
    model_manager,
    [
        ControlNetConfigUnit(
            processor_id="depth",
            model_path=rf"models/ControlNet/control_v11f1p_sd15_depth.pth",
            scale=0.5
        ),
        ControlNetConfigUnit(
            processor_id="softedge",
            model_path=rf"models/ControlNet/control_v11p_sd15_softedge.pth",
            scale=0.5
        )
    ]
)

sys.stdout.write("Setting up smoother ...\n")
sys.stdout.flush()

smoother = FastBlendSmoother.from_model_manager(model_manager)

sys.stdout.write("Loading video ...\n")
sys.stdout.flush()

# Load video
# Original video: https://pixabay.com/videos/flow-rocks-water-fluent-stones-159627/
#video = VideoData(video_file="data/pixabay100/159627 (1080p).mp4", height=512, width=768)
video = VideoData(video_file=args2.source_video)
input_video = video #[video[i] for i in range(128)]

sys.stdout.write("Rerendering video ...\n")
sys.stdout.flush()

# Rerender
torch.manual_seed(0)
output_video = pipe(
    #prompt="winter, ice, snow, water, river",
    prompt=args2.prompt,
    negative_prompt=args2.negative_prompt, cfg_scale=7,
    input_frames=input_video, controlnet_frames=input_video, num_frames=len(input_video),
    num_inference_steps=10,# height=512, width=768,
    animatediff_batch_size=32, animatediff_stride=16, unet_batch_size=4,
    cross_frame_attention=True,
    smoother=smoother, smoother_progress_ids=[4, 9]
)

sys.stdout.write(f"Saving {args2.output_file} ...\n")
sys.stdout.flush()

# Save images and video
save_video(output_video, args2.output_file, fps=args2.fps)

sys.stdout.write("Done\n")
sys.stdout.flush()