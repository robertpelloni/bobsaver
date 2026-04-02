# Script by Jason Rampe https://softology.pro/
# Based on https://github.com/huggingface/diffusers/discussions/7581

import sys

sys.stdout.flush()
sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import numpy as np
import torch
from tqdm import tqdm
from diffusers import AutoencoderKL, EulerDiscreteScheduler, StableDiffusionXLPipeline
from diffusers.utils.torch_utils import randn_tensor
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, help="model")
    parser.add_argument("--fp16", type=int, help="model is fp16 0=no 1=yes")
    parser.add_argument("--slerp", type=int, help="use slerp vs lerp 0=no 1=yes")
    parser.add_argument("--num_interpolation_steps", type=int, help="steps to interpolate between prompts")
    parser.add_argument("--seed", type=int, help="the seed (for reproducible sampling)")
    parser.add_argument("--width", type=int, help="image width")
    parser.add_argument("--height", type=int, help="image height")
    parser.add_argument("--guidance_scale", type=float, help="guidance scale")
    parser.add_argument("--num_inference_steps", type=int, help="inference steps")
    parser.add_argument("--frame_dir", type=str, help="output directory for frame files")
    parser.add_argument("--lora", type=str)
    parser.add_argument("--lora_weight", type=float)
    parser.add_argument("--lora2", type=str)
    parser.add_argument("--lora_weight2", type=float)
    parser.add_argument("--lora3", type=str)
    parser.add_argument("--lora_weight3", type=float)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()


# based on https://huggingface.co/learn/cookbook/stable_diffusion_interpolation#example-3-interpolation-between-multiple-prompts 
# and https://gist.github.com/karpathy/00103b0037c5aaea32fe1da1af553355
def slerp(v0, v1, num, t0=0, t1=1):
    # convert them to full precision if not the dot product overflows
    v0 = v0.detach().cpu().numpy().astype(np.float32)
    v1 = v1.detach().cpu().numpy().astype(np.float32)
    def interpolation(t, v0, v1, DOT_THRESHOLD=0.9995):
        if args2.slerp == 1:
            """helper function to spherically interpolate two arrays v1 v2"""
            dot = np.sum(v0 * v1 / (np.linalg.norm(v0) * np.linalg.norm(v1)))
            if np.abs(dot) > DOT_THRESHOLD:
                v2 = (1 - t) * v0 + t * v1
            else:
                theta_0 = np.arccos(dot)
                sin_theta_0 = np.sin(theta_0)
                theta_t = theta_0 * t
                sin_theta_t = np.sin(theta_t)
                s0 = np.sin(theta_0 - theta_t) / sin_theta_0
                s1 = sin_theta_t / sin_theta_0
                v2 = s0 * v0 + s1 * v1
        else:
            v2 = (1 - t) * v0 + t * v1
        return v2

    t = np.linspace(t0, t1, num)

    v3 = torch.tensor(np.array([interpolation(t[i], v0, v1) for i in range(num)]), dtype=torch.float16)

    return v3


sys.stdout.flush()
sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

vae = AutoencoderKL.from_pretrained("madebyollin/sdxl-vae-fp16-fix", torch_dtype=torch.float16).to("cuda")

sys.stdout.flush()
sys.stdout.write("Creating pipeline ...\n")
sys.stdout.flush()

pipeline = StableDiffusionXLPipeline.from_pretrained(
    args2.model, torch_dtype=torch.float16, variant="fp16", vae=vae
).to("cuda")

pipeline.scheduler = EulerDiscreteScheduler.from_config(pipeline.scheduler.config, timestep_spacing="trailing")

if args2.lora is not None:
    sys.stdout.write(f"Loading LoRA weights from {args2.lora} ...\n")
    sys.stdout.flush()
    pipeline.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora}", adapter_name="lora_adapter")
    sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight} ...\n")
    sys.stdout.flush()
    pipeline.fuse_lora(lora_scale=args2.lora_weight)

if args2.lora2 is not None:
    sys.stdout.write(f"Loading LoRA weights from {args2.lora2} ...\n")
    sys.stdout.flush()
    pipeline.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora2}", adapter_name="lora_adapter2")
    sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight2} ...\n")
    sys.stdout.flush()
    pipeline.fuse_lora(lora_scale=args2.lora_weight2)

if args2.lora3 is not None:
    sys.stdout.write(f"Loading LoRA weights from {args2.lora3} ...\n")
    sys.stdout.flush()
    pipeline.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora3}", adapter_name="lora_adapter3")
    sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight3} ...\n")
    sys.stdout.flush()
    pipeline.fuse_lora(lora_scale=args2.lora_weight3)

"""
if args2.lora is None and args2.lora2 is None and args2.lora3 is None :
    sys.stdout.flush()
    sys.stdout.write("Loading 4 step ByteDance/SDXL-Lightning LoRA ...\n")
    sys.stdout.flush()
    pipeline.load_lora_weights(
        "ByteDance/SDXL-Lightning", weight_name="sdxl_lightning_4step_lora.safetensors", adapter_name="lighting"
    )
"""
#always use the 4step LoRA for speed and reduce needed inference steps
sys.stdout.flush()
sys.stdout.write("Loading 4 step ByteDance/SDXL-Lightning LoRA ...\n")
sys.stdout.flush()
pipeline.load_lora_weights(
    "ByteDance/SDXL-Lightning", weight_name="sdxl_lightning_4step_lora.safetensors", adapter_name="lighting"
)



pipeline.set_progress_bar_config(disable=True)


height = args2.height
width = args2.width
num_interpolation_steps = args2.num_interpolation_steps
seed = args2.seed
generator = torch.Generator(device="cpu").manual_seed(seed)

sys.stdout.flush()
sys.stdout.write("Setting prompts ...\n")
sys.stdout.flush()

#VOC START - DO NOT DELETE
prompts=[
    "a rose",
    "a gerbera",
    "a daffodil",
    "a daisy",
    "a tulip",
]
interpolation_steps=[
    0,
    50,
    50,
    50,
    50,
]
#VOC FINISH - DO NOT DELETE

batch_size = len(prompts)

prompts_embeds, _negative_prompts_embeds, pooled_prompts_embeds, _negative_pooled_prompts_embeds = (
    pipeline.encode_prompt(prompts, do_classifier_free_guidance=False)
)

shape = (1, pipeline.unet.config.in_channels, height // pipeline.vae_scale_factor, width // pipeline.vae_scale_factor)
latents = randn_tensor(shape, generator=generator, device=prompts_embeds.device, dtype=prompts_embeds.dtype)

interpolated_prompt_embeds = []
interpolated_pooled_prompt_embeds = []

for i in range(batch_size - 1):
    interpolated_prompt_embeds.append(slerp(prompts_embeds[i], prompts_embeds[i + 1], interpolation_steps[i + 1]))
    interpolated_pooled_prompt_embeds.append(
        slerp(pooled_prompts_embeds[i], pooled_prompts_embeds[i + 1], interpolation_steps[i + 1])
    )

interpolated_prompt_embeds = torch.cat(interpolated_prompt_embeds, dim=0).to(prompts_embeds.device)
interpolated_pooled_prompt_embeds = torch.cat(interpolated_pooled_prompt_embeds, dim=0).to(prompts_embeds.device)

images = []

sys.stdout.flush()
sys.stdout.write("Generating frames ...\n")
sys.stdout.flush()

for prompt_embeds, pooled_prompt_embeds in tqdm(
    zip(
        interpolated_prompt_embeds,
        interpolated_pooled_prompt_embeds,
    ),
    total=len(interpolated_prompt_embeds),
):
    image=pipeline(
        height=height,
        width=width,
        latents=latents,
        prompt_embeds=prompt_embeds[None, ...],
        pooled_prompt_embeds=pooled_prompt_embeds[None, ...],
        guidance_scale=args2.guidance_scale,
        num_inference_steps=args2.num_inference_steps,
        generator=generator,
    ).images[0]

    #save next movie FRA frame
    sys.stdout.flush()
    sys.stdout.write(f'Saving movie frame ...\n')
    sys.stdout.flush()
    import os
    file_list = []
    for file in os.listdir(args2.frame_dir):
        if file.startswith("FRA"):
            if file.endswith("png"):
                if len(file) == 12:
                  file_list.append(file)
    if file_list:
        last_name = file_list[-1]
        count_value = int(last_name[3:8])+1
        count_string = f"{count_value:05d}"
    else:
        count_string = "00001"
    save_name = args2.frame_dir+"\FRA"+count_string+".png"
    image.save(save_name)
    sys.stdout.flush()
    sys.stdout.write(f'Progress saved to {save_name}')
    sys.stdout.flush()
    sys.stdout.write(f'\n\n')

sys.stdout.flush()
sys.stdout.write("Done\n")
sys.stdout.flush()

