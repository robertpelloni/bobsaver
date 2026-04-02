import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffsynth import ModelManager, SDVideoPipeline, ControlNetConfigUnit, VideoData, save_video, save_frames
from diffsynth.extensions.RIFE import RIFESmoother
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--source_video", type=str, help="video to toonify")
    parser.add_argument("--prompt", type=str, help="prompt")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="random seed")
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
model_manager.load_textual_inversions("models/textual_inversion")
model_manager.load_models([
    "models/stable_diffusion/flat2DAnimerge_v45Sharp.safetensors",
    "models/AnimateDiff/mm_sd_v15_v2.ckpt",
    "models/ControlNet/control_v11p_sd15_lineart.pth",
    "models/ControlNet/control_v11f1e_sd15_tile.pth",
    "models/RIFE/flownet.pkl"
])

sys.stdout.write("Creating pipeline ...\n")
sys.stdout.flush()

pipe = SDVideoPipeline.from_model_manager(
    model_manager,
    [
        ControlNetConfigUnit(
            processor_id="lineart",
            model_path="models/ControlNet/control_v11p_sd15_lineart.pth",
            scale=0.5
        ),
        ControlNetConfigUnit(
            processor_id="tile",
            model_path="models/ControlNet/control_v11f1e_sd15_tile.pth",
            scale=0.5
        )
    ]
)

sys.stdout.write("Loading smoother ...\n")
sys.stdout.flush()

smoother = RIFESmoother.from_model_manager(model_manager)

sys.stdout.write("Loading video ...\n")
sys.stdout.flush()

# Load video (we only use 60 frames for quick testing)
# The original video is here: https://www.bilibili.com/video/BV19w411A7YJ/
video = VideoData(
    video_file=args2.source_video,
    #height=1024, width=1024
    )
input_video = video #[video[i] for i in range(40*60, 41*60)]

sys.stdout.write("Toon shading video ...\n")
sys.stdout.flush()

# Toon shading (20G VRAM)
torch.manual_seed(args2.seed)
output_video = pipe(
    #prompt="best quality, perfect anime illustration, light, a girl is dancing, smile, solo",
    #negative_prompt="verybadimagenegative_v1.3",
    prompt=args2.prompt,
    negative_prompt=args2.negative_prompt,
    cfg_scale=3, clip_skip=2,
    controlnet_frames=input_video, num_frames=len(input_video),
    num_inference_steps=10, #height=1024, width=1024,
    animatediff_batch_size=32, animatediff_stride=16,
    vram_limit_level=0,
)

sys.stdout.write("Smoothing video ...\n")
sys.stdout.flush()

output_video = smoother(output_video)

# Save video
sys.stdout.write(f"Saving {args2.output_file} ...\n")
sys.stdout.flush()

save_video(output_video, args2.output_file, fps=args2.fps)

sys.stdout.write("Done\n")
sys.stdout.flush()

