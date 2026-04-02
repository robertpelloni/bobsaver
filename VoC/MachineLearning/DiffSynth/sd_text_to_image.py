import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffsynth import ModelManager, SDImagePipeline, ControlNetConfigUnit
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--height", type=int, help="initial image height, in pixel space")
    parser.add_argument("--width", type=int, help="initial image width, in pixel space")
    parser.add_argument("--image_file", type=str)
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
model_manager.load_textual_inversions("models/textual_inversion")
model_manager.load_models([
    f"models/stable_diffusion/{args2.model}",
    "models/ControlNet/control_v11f1e_sd15_tile.pth",
    "models/ControlNet/control_v11p_sd15_lineart.pth"
])
pipe = SDImagePipeline.from_model_manager(
    model_manager,
    [
        ControlNetConfigUnit(
            processor_id="tile",
            model_path=rf"models/ControlNet/control_v11f1e_sd15_tile.pth",
            scale=0.5
        ),
        ControlNetConfigUnit(
            processor_id="lineart",
            model_path=rf"models/ControlNet/control_v11p_sd15_lineart.pth",
            scale=0.7
        ),
    ]
)

prompt = args2.prompt #"masterpiece, best quality, solo, long hair, wavy hair, silver hair, blue eyes, blue dress, medium breasts, dress, underwater, air bubble, floating hair, refraction, portrait,"
negative_prompt = args2.negative_prompt #"worst quality, low quality, monochrome, zombie, interlocked fingers, Aissist, cleavage, nsfw,"

sys.stdout.write(f"Generating {args2.width}x{args2.height} initial image ...\n")
sys.stdout.flush()

torch.manual_seed(args2.seed)
image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=7.5, clip_skip=1,
    height=args2.height, width=args2.width, num_inference_steps=80,
)
sys.stdout.write("Saving initial image ...\n")
sys.stdout.write(f"{args2.image_file} x1.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x1.jpg")

sys.stdout.write(f"Generating {args2.width*2}x{args2.height*2} upscaled x2 image ...\n")
sys.stdout.flush()

image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=7.5, clip_skip=1,
    input_image=image.resize((args2.width*2, args2.height*2)), controlnet_image=image.resize((args2.width*2, args2.height*2)),
    height=args2.height*2, width=args2.width*2, num_inference_steps=40, denoising_strength=0.7,
)
sys.stdout.write("Saving upscaled x2 image ...\n")
sys.stdout.write(f"{args2.image_file} x2.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x2.jpg")

sys.stdout.write(f"Generating {args2.width*4}x{args2.height*4} upscaled x4 image ...\n")
sys.stdout.flush()

image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=7.5, clip_skip=1,
    input_image=image.resize((args2.width*4, args2.height*4)), controlnet_image=image.resize((args2.width*4, args2.height*4)),
    height=args2.height*4, width=args2.width*4, num_inference_steps=20, denoising_strength=0.7,
)
sys.stdout.write("Saving upscaled x4 image ...\n")
sys.stdout.write(f"{args2.image_file} x4.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x4.jpg")

sys.stdout.write(f"Generating {args2.width*8}x{args2.height*8} upscaled x8 image ...\n")
sys.stdout.flush()

image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=7.5, clip_skip=1,
    input_image=image.resize((args2.width*8, args2.height*8)), controlnet_image=image.resize((args2.width*8, args2.height*8)),
    height=args2.height*8, width=args2.width*8, num_inference_steps=10, denoising_strength=0.5,
    tiled=True, tile_size=128, tile_stride=64
)
sys.stdout.write("Saving upscaled x8 image ...\n")
sys.stdout.write(f"{args2.image_file} x8.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x8.jpg")

sys.stdout.write("Done\n")
sys.stdout.flush()
