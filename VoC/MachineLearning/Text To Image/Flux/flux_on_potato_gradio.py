# First, in your terminal.
#
# $ python3 -m virtualenv env
# $ source env/bin/activate
# $ pip install torch torchvision transformers sentencepiece protobuf accelerate
# $ pip install git+https://github.com/huggingface/diffusers.git
# $ pip install optimum-quanto
# $ pip install gradio

import torch

import gradio as gr

from optimum.quanto import freeze, qfloat8, quantize

from diffusers import FlowMatchEulerDiscreteScheduler, AutoencoderKL
from diffusers.models.transformers.transformer_flux import FluxTransformer2DModel
from diffusers.pipelines.flux.pipeline_flux import FluxPipeline
from transformers import CLIPTextModel, CLIPTokenizer,T5EncoderModel, T5TokenizerFast

dtype = torch.bfloat16

# schnell is the distilled turbo model. For the CFG distilled model, use:
# bfl_repo = "black-forest-labs/FLUX.1-dev"
# revision = "refs/pr/3"
#
# The undistilled model that uses CFG ("pro") which can use negative prompts
# was not released.

bfl_repo = "black-forest-labs/FLUX.1-schnell"

#revision = "refs/pr/1"

#scheduler = FlowMatchEulerDiscreteScheduler.from_pretrained(bfl_repo, subfolder="scheduler", revision=revision)
scheduler = FlowMatchEulerDiscreteScheduler.from_pretrained(bfl_repo, subfolder="scheduler")
text_encoder = CLIPTextModel.from_pretrained("openai/clip-vit-large-patch14", torch_dtype=dtype)
tokenizer = CLIPTokenizer.from_pretrained("openai/clip-vit-large-patch14", torch_dtype=dtype)
#text_encoder_2 = T5EncoderModel.from_pretrained(bfl_repo, subfolder="text_encoder_2", torch_dtype=dtype, revision=revision)
text_encoder_2 = T5EncoderModel.from_pretrained(bfl_repo, subfolder="text_encoder_2", torch_dtype=dtype)
#tokenizer_2 = T5TokenizerFast.from_pretrained(bfl_repo, subfolder="tokenizer_2", torch_dtype=dtype, revision=revision)
tokenizer_2 = T5TokenizerFast.from_pretrained(bfl_repo, subfolder="tokenizer_2", torch_dtype=dtype)
#vae = AutoencoderKL.from_pretrained(bfl_repo, subfolder="vae", torch_dtype=dtype, revision=revision)
vae = AutoencoderKL.from_pretrained(bfl_repo, subfolder="vae", torch_dtype=dtype)
#transformer = FluxTransformer2DModel.from_pretrained(bfl_repo, subfolder="transformer", torch_dtype=dtype, revision=revision)
transformer = FluxTransformer2DModel.from_pretrained(bfl_repo, subfolder="transformer", torch_dtype=dtype)

# Experimental: Try this to load in 4-bit for <16GB cards.
#
# from optimum.quanto import qint4
# quantize(transformer, weights=qint4, exclude=["proj_out", "x_embedder", "norm_out", "context_embedder"])
# freeze(transformer)
quantize(transformer, weights=qfloat8)
freeze(transformer)

quantize(text_encoder_2, weights=qfloat8)
freeze(text_encoder_2)

pipe = FluxPipeline(
    scheduler=scheduler,
    text_encoder=text_encoder,
    tokenizer=tokenizer,
    text_encoder_2=None,
    tokenizer_2=tokenizer_2,
    vae=vae,
    transformer=None,
)
pipe.text_encoder_2 = text_encoder_2
pipe.transformer = transformer
pipe.enable_model_cpu_offload()

def generate(prompt, steps, guidance, width, height, seed):
    if seed == -1:
        seed = torch.seed()
    generator = torch.Generator().manual_seed(int(seed))
    image = pipe(
        prompt=prompt,
        width=width,
        height=height,
        num_inference_steps=steps,
        generator=generator,
        guidance_scale=guidance,
    ).images[0]
    return image

demo = gr.Interface(fn=generate, inputs=["textbox", gr.Number(value=4), gr.Number(value=3.5), gr.Slider(0, 1920, value=1024, step=2), gr.Slider(0, 1920, value=1024, step=2), gr.Number(value=-1)], outputs="image")

demo.launch(server_name="0.0.0.0")