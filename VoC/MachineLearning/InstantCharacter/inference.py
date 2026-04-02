import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
from PIL import Image
from pipeline import InstantCharacterFluxPipeline
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--initimage", type=str, help="")
    parser.add_argument("--prompt", type=str, help="Prompt")
    parser.add_argument("--output", type=str, help="")
    parser.add_argument("--lora", type=str, help="")
    parser.add_argument("--loratrigger", type=str, help="")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()




# Step 1 Load base model and adapter

ip_adapter_path = 'checkpoints/instantcharacter_ip-adapter.bin'
base_model = 'black-forest-labs/FLUX.1-dev'
image_encoder_path = 'google/siglip-so400m-patch14-384'
image_encoder_2_path = 'facebook/dinov2-giant'
seed = 123456

pipe = InstantCharacterFluxPipeline.from_pretrained(base_model, torch_dtype=torch.bfloat16)

# Step 1.1, To manually configure the CPU offload mode.
# You may selectively designate which layers to employ the offload hook based on the available VRAM capacity of your GPU.
# The following configuration can reach about 22GB of VRAM usage on NVIDIA L20 (Ada arch)

pipe.to("cpu")
pipe._exclude_from_cpu_offload.extend([
    # 'vae',
    'text_encoder',
    # 'text_encoder_2',
])
pipe._exclude_layer_from_cpu_offload.extend([
    "transformer.pos_embed",
    "transformer.time_text_embed",
    "transformer.context_embedder",
    "transformer.x_embedder",
    "transformer.transformer_blocks",
    # "transformer.single_transformer_blocks",
    "transformer.norm_out",
    "transformer.proj_out",
])
pipe.enable_sequential_cpu_offload()

pipe.init_adapter(
    image_encoder_path=image_encoder_path, 
    image_encoder_2_path=image_encoder_2_path, 
    subject_ipadapter_cfg=dict(subject_ip_adapter_path=ip_adapter_path, nb_token=1024), 
    device=torch.device('cuda')
)

# Step 1.2 Optional inference acceleration
# You can set the TORCHINDUCTOR_CACHE_DIR in production environment.

torch._dynamo.reset()
torch._dynamo.config.cache_size_limit = 1024
torch.set_float32_matmul_precision("high")
torch._dynamo.config.capture_scalar_outputs = True
torch._dynamo.config.capture_dynamic_output_shape_ops = True

for layer in pipe.transformer.attn_processors.values():
    layer = torch.compile(
        layer,
        fullgraph=True,
        dynamic=True,
        mode="max-autotune",
        backend='inductor'
    )
pipe.transformer.single_transformer_blocks.compile(
    fullgraph=True,
    dynamic=True,
    mode="max-autotune",
    backend='inductor'
)
pipe.transformer.transformer_blocks.compile(
    fullgraph=True,
    dynamic=True,
    mode="max-autotune",
    backend='inductor'
)
pipe.vae = torch.compile(
    pipe.vae,
    fullgraph=True,
    dynamic=True,
    mode="max-autotune",
    backend='inductor'
)
pipe.text_encoder = torch.compile(
    pipe.text_encoder,
    fullgraph=True,
    dynamic=True,
    mode="max-autotune",
    backend='inductor'
)


# Step 2 Load reference image
#ref_image_path = 'assets/girl.jpg'  # white background
ref_image_path = args2.initimage
ref_image = Image.open(ref_image_path).convert('RGB')

# Step 3 Inference without style
#prompt = "A girl is playing a guitar in street"
prompt = args2.prompt

"""
# warm up for torch.compile
image = pipe(
        prompt=prompt, 
        num_inference_steps=28,
        guidance_scale=3.5,
        subject_image=ref_image,
        subject_scale=0.9,
        generator=torch.manual_seed(seed),
    ).images[0]
"""

if args2.lora is None:
    #sys.stdout.write("Running non LoRA pipeline ...\n")
    #sys.stdout.flush()
    image = pipe(
            prompt=prompt, 
            num_inference_steps=28,
            guidance_scale=3.5,
            subject_image=ref_image,
            subject_scale=0.9,
            generator=torch.manual_seed(seed),
        ).images[0]

if args2.lora is not None:
    #sys.stdout.write("Running LoRA pipeline ...\n")
    #sys.stdout.flush()
    image = pipe.with_style_lora(
            lora_file_path=args2.lora,
            trigger=args2.loratrigger,
            prompt=prompt, 
            num_inference_steps=28,
            guidance_scale=3.5,
            subject_image=ref_image,
            subject_scale=0.9,
            generator=torch.manual_seed(seed),
        ).images[0]

#image.save("flux_instantcharacter.png")
image.save(args2.output)

