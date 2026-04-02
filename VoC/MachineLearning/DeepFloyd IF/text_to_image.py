import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from diffusers import DiffusionPipeline, IFPipeline, IFSuperResolutionPipeline
from diffusers.utils import pt_to_pil
import torch
import numpy as np
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--guidance1", type=float)
    parser.add_argument("--guidance2", type=float)
    parser.add_argument("--guidance3", type=float)
    parser.add_argument("--respacing1", type=str)
    parser.add_argument("--respacing2", type=str)
    parser.add_argument("--respacing3", type=str)
    parser.add_argument("--noise", type=float)
    parser.add_argument("--image_file", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading stage 1 ...\n")
sys.stdout.flush()

# stage 1
stage_1 = IFPipeline.from_pretrained("DeepFloyd/IF-I-XL-v1.0", variant="fp16", torch_dtype=torch.float16)
stage_1.enable_model_cpu_offload()

sys.stdout.write("Loading stage 2 ...\n")
sys.stdout.flush()

# stage 2
stage_2 = IFSuperResolutionPipeline.from_pretrained("DeepFloyd/IF-II-L-v1.0", text_encoder=None, variant="fp16", torch_dtype=torch.float16)
stage_2.enable_model_cpu_offload()

sys.stdout.write("Loading stage 3 ...\n")
sys.stdout.flush()

# stage 3
#safety_modules = {"feature_extractor": stage_1.feature_extractor, "safety_checker": stage_1.safety_checker, "watermarker": stage_1.watermarker}
safety_modules = {}
stage_3 = DiffusionPipeline.from_pretrained("stabilityai/stable-diffusion-x4-upscaler", **safety_modules, torch_dtype=torch.float16)
stage_3.enable_model_cpu_offload()

prompt = args2.prompt

# text embeds
prompt_embeds, negative_embeds = stage_1.encode_prompt(prompt)

base_seed = args2.seed

for x in range(1):
    generator = torch.manual_seed(base_seed + x)

    sys.stdout.write("Generating stage 1 ...\n")
    sys.stdout.flush()

    image = stage_1(prompt_embeds=prompt_embeds,
                    negative_prompt_embeds=negative_embeds,
                    guidance_scale=args2.guidance1,
                    generator=generator,
                    output_type="pt",
                    height=args2.height//16,
                    width=args2.width//16).images
    #pt_to_pil(image)[0].save("./if_stage_I.png")
    sys.stdout.write("Saving stage 1 image...\n")
    sys.stdout.flush()
    pt_to_pil(image)[0].save(args2.image_file)
    sys.stdout.write("Progress saved\n")

    sys.stdout.write("Generating stage 2 ...\n")
    sys.stdout.flush()

    image = stage_2(image=image,
                    prompt_embeds=prompt_embeds,
                    negative_prompt_embeds=negative_embeds,
                    guidance_scale=args2.guidance2,
                    generator=generator,
                    output_type="pt",
                    height=args2.height//4,
                    width=args2.width//4).images
    #pt_to_pil(image)[0].save("./if_stage_II.png")
    sys.stdout.write("Saving stage 2 image...\n")
    sys.stdout.flush()
    pt_to_pil(image)[0].save(args2.image_file)
    sys.stdout.write("Progress saved\n")

    sys.stdout.write("Generating stage 3 ...\n")
    sys.stdout.flush()

    image = stage_3(prompt=prompt,
                    image=image,
                    generator=generator,
                    guidance_scale=args2.guidance3,
                    noise_level=100).images
    #image[0].save(f"{base_seed + x}.png")
    sys.stdout.write("Saving final image...\n")
    sys.stdout.flush()
    image[0].save(args2.image_file)
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
