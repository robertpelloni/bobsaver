import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from diffusers import DiffusionPipeline

model_id = 'black-forest-labs/FLUX.1-dev'
#model_id = 'black-forest-labs/FLUX.1-schnell'
adapter_id = 'zouzoumaki/flux-loras'

sys.stdout.write("Creating pipeline ...\n")
sys.stdout.flush()

pipeline = DiffusionPipeline.from_pretrained(model_id)

#neither of the following helps speed
#pipeline.enable_model_cpu_offload()
pipeline.to('cuda')

sys.stdout.write("Loading LoRA weights ...\n")
sys.stdout.flush()

pipeline.load_lora_weights(adapter_id)

prompt = "sks close up"

sys.stdout.write("Generating image ...\n")
sys.stdout.flush()


image = pipeline(
    prompt=prompt,
    num_inference_steps=20,
    generator=torch.Generator(device='cuda').manual_seed(1641421826),
    width=1024,
    height=1024,
    guidance_scale=3.0,
).images[0]

sys.stdout.write("Saving output image ...\n")
sys.stdout.flush()

image.save("output.png", format="PNG")

sys.stdout.write("Done\n")
sys.stdout.flush()

