# https://gist.github.com/AmericanPresidentJimmyCarter/873985638e1f3541ba8b00137e7dacd9

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch

from optimum.quanto import freeze, qfloat8, qint4, quantize
import os.path
from diffusers import FlowMatchEulerDiscreteScheduler, AutoencoderKL
from diffusers.models.transformers.transformer_flux import FluxTransformer2DModel
from diffusers import FluxPipeline,FluxImg2ImgPipeline
from diffusers.utils import load_image
from transformers import CLIPTextModel, CLIPTokenizer,T5EncoderModel, T5TokenizerFast
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--steps", type=int, help="iterations")
    parser.add_argument("--H", type=int, help="image height, in pixel space")
    parser.add_argument("--W", type=int, help="image width, in pixel space")
    parser.add_argument("--image_file", type=str, help="output image file")
    parser.add_argument("--init_image", type=str)
    parser.add_argument("--init_image_strength", type=float)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()


dtype = torch.bfloat16

bfl_repo = "black-forest-labs/FLUX.1-schnell"

sys.stdout.write("Setting up scheduler ...\n")
sys.stdout.flush()

scheduler = FlowMatchEulerDiscreteScheduler.from_pretrained(bfl_repo, subfolder="scheduler")

sys.stdout.write("Setting up text_encoder ...\n")
sys.stdout.flush()

text_encoder = CLIPTextModel.from_pretrained("openai/clip-vit-large-patch14", torch_dtype=dtype)

sys.stdout.write("Setting up tokenizer ...\n")
sys.stdout.flush()

tokenizer = CLIPTokenizer.from_pretrained("openai/clip-vit-large-patch14", torch_dtype=dtype)

sys.stdout.write("Setting up text_encoder_2 ...\n")
sys.stdout.flush()

text_encoder_2 = T5EncoderModel.from_pretrained(bfl_repo, subfolder="text_encoder_2", torch_dtype=dtype)

sys.stdout.write("Setting up tokenizer_2 ...\n")
sys.stdout.flush()

tokenizer_2 = T5TokenizerFast.from_pretrained(bfl_repo, subfolder="tokenizer_2", torch_dtype=dtype)

sys.stdout.write("Setting up vae ...\n")
sys.stdout.flush()

vae = AutoencoderKL.from_pretrained(bfl_repo, subfolder="vae", torch_dtype=dtype)

if os.path.isfile('models\\transformer.pt'):

    sys.stdout.write("Loading transformer ...\n")
    sys.stdout.flush()

    transformer = torch.load('models\\transformer.pt')
    transformer.eval()
    
else:
    sys.stdout.write("Setting up transformer ...\n")
    sys.stdout.flush()

    transformer = FluxTransformer2DModel.from_pretrained(bfl_repo, subfolder="transformer", torch_dtype=dtype)

    sys.stdout.write("Quantize transformer ...\n")
    sys.stdout.flush()

    quantize(transformer, weights=qfloat8)

    sys.stdout.write("Freeze transformer ...\n")
    sys.stdout.flush()

    freeze(transformer)
    
    sys.stdout.write("Saving transformer ...\n")
    sys.stdout.flush()

    torch.save(transformer, 'models\\transformer.pt')


if os.path.isfile('models\\text_encoder_2.pt'):

    sys.stdout.write("Loading text_encoder_2 ...\n")
    sys.stdout.flush()

    text_encoder_2 = torch.load('models\\text_encoder_2.pt')
    text_encoder_2.eval()
    
else:
    
    sys.stdout.write("Quantize text_encoder_2 ...\n")
    sys.stdout.flush()

    quantize(text_encoder_2, weights=qfloat8)

    sys.stdout.write("Freeze text_encoder_2 ...\n")
    sys.stdout.flush()

    freeze(text_encoder_2)

    sys.stdout.write("Saving text_encoder_2 ...\n")
    sys.stdout.flush()

    torch.save(text_encoder_2, 'models\\text_encoder_2.pt')


if args2.init_image != None:

    sys.stdout.write("Setting up image to image pipeline ...\n")
    sys.stdout.flush()

    pipe = FluxImg2ImgPipeline(
        scheduler=scheduler,
        text_encoder=text_encoder,
        tokenizer=tokenizer,
        text_encoder_2=text_encoder_2,
        tokenizer_2=tokenizer_2,
        vae=vae,
        transformer=transformer,
    ).to("cuda")

    sys.stdout.write("Generating ...\n")
    sys.stdout.flush()

    generator = torch.Generator(pipe.device).manual_seed(args2.seed)
    image = pipe(
        image=load_image(args2.init_image),
        strength=args2.init_image_strength,
        prompt=args2.prompt, 
        width=args2.W,
        height=args2.H,
        num_inference_steps=args2.steps, 
        generator=generator,
        guidance_scale=3.5,
    ).images[0]

else:

    sys.stdout.write("Setting up pipe ...\n")
    sys.stdout.flush()

    pipe = FluxPipeline(
        scheduler=scheduler,
        text_encoder=text_encoder,
        tokenizer=tokenizer,
        text_encoder_2=text_encoder_2,
        tokenizer_2=tokenizer_2,
        vae=vae,
        transformer=transformer,
    ).to("cuda")

    #https://gist.github.com/AmericanPresidentJimmyCarter/873985638e1f3541ba8b00137e7dacd9
    #pipe.load_lora_weights("./pytorch_lora_weights.safetensors")
    #pipe.load_lora_weights("./ArtNouveau_Flux_LoRA.safetensors")
    #pipe.fuse_lora(lora_scale=0.125)
    #pipe.unload_lora_weights()

    #pipe.load_lora_weights(lora_path=".", weight_name="ArtNouveau_Flux_LoRA.safetensors", adapter_name="lora", pretrained_model_name_or_path_or_dict=".\ArtNouveau_Flux_LoRA.safetensors")
    #pipe.set_adapters("lora", 0.5)

    pipe.enable_model_cpu_offload()

    sys.stdout.write("Generating ...\n")
    sys.stdout.flush()

    generator = torch.Generator(pipe.device).manual_seed(args2.seed)
    image = pipe(
        prompt=args2.prompt, 
        width=args2.W,
        height=args2.H,
        num_inference_steps=args2.steps, 
        generator=generator,
        guidance_scale=3.5,
    ).images[0]


sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

image.save(args2.image_file)

sys.stdout.write("Done\n")
sys.stdout.flush()
