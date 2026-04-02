import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffsynth import ModelManager, SDXLImagePipeline
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
model_manager.load_models(["models/stable_diffusion_xl/bluePencilXL_v200.safetensors"])
pipe = SDXLImagePipeline.from_model_manager(model_manager)

prompt = args2.prompt
negative_prompt = args2.negative_prompt

sys.stdout.write(f"Generating {args2.width}x{args2.height} initial image ...\n")
sys.stdout.flush()

torch.manual_seed(args2.seed)
image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=6,
    height=args2.height, width=args2.width, num_inference_steps=60,
)
sys.stdout.write("Saving initial image ...\n")
sys.stdout.write(f"{args2.image_file} x1.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x1.jpg")

image = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    cfg_scale=6,
    input_image=image.resize((args2.width*2, args2.height*2)),
    height=args2.height*2, width=args2.width*2, num_inference_steps=60, denoising_strength=0.5
)
sys.stdout.write("Saving upscaled x2 image ...\n")
sys.stdout.write(f"{args2.image_file} x2.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file} x2.jpg")

sys.stdout.write("Done\n")
sys.stdout.flush()
