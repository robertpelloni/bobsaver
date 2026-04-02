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

    parser.add_argument("--prompt_1", type=str, help="the prompt to render")
    parser.add_argument("--prompt_2", type=str, help="the prompt to render")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--image_file_1", type=str)
    parser.add_argument("--image_file_2", type=str)
    
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
model_manager.load_models(["models/stable_diffusion_xl_turbo/sd_xl_turbo_1.0_fp16.safetensors"])
pipe = SDXLImagePipeline.from_model_manager(model_manager)

sys.stdout.write(f"Generating image 1/2 ...\n")
sys.stdout.flush()

# Text to image
torch.manual_seed(args2.seed)
image = pipe(
    prompt=args2.prompt_1, #"black car",
    # Do not modify the following parameters!
    cfg_scale=1, height=512, width=512, num_inference_steps=1, progress_bar_cmd=lambda x:x
)
sys.stdout.write("Saving image 1/2 ...\n")
sys.stdout.write(f"{args2.image_file_1}.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file_1}.jpg")

sys.stdout.write(f"Generating image 2/2 ...\n")
sys.stdout.flush()

# Image to image
torch.manual_seed(args2.seed)
image = pipe(
    prompt=args2.prompt_2, #"red car",
    input_image=image, denoising_strength=0.7,
    # Do not modify the following parameters!
    cfg_scale=1, height=512, width=512, num_inference_steps=1, progress_bar_cmd=lambda x:x
)
sys.stdout.write("Saving image 2/2 ...\n")
sys.stdout.write(f"{args2.image_file_2}.jpg\n")
sys.stdout.flush()
image.save(f"{args2.image_file_2}.jpg")

sys.stdout.write(f"Done\n")
sys.stdout.flush()
