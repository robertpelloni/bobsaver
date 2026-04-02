import gradio as gr
import numpy as np
import random
import gc
import json
import torch
import spaces

from diffusers.pipelines import Lumina2Text2ImgPipeline

default_system_prompt = "You are an assistant designed to generate superior images with the superior degree of image-text alignment based on textual prompts or user prompts."
device = "cuda" if torch.cuda.is_available() else "cpu"
model_repo_id = "Alpha-VLLM/Lumina-Image-2.0"

if torch.cuda.is_available():
    torch_dtype = torch.bfloat16
else:
    torch_dtype = torch.float32
    
pipe = Lumina2Text2ImgPipeline.from_pretrained(model_repo_id)
pipe.to(device, torch_dtype)

MAX_SEED = np.iinfo(np.int32).max
MAX_IMAGE_SIZE = 1536

@spaces.GPU(duration=60)
def infer(
    prompt,
    negative_prompt="",
    seed=42,
    randomize_seed=False,
    width=1024,
    height=1024,
    guidance_scale=4.0,
    num_inference_steps=30,
    system_prompt=default_system_prompt,
    cfg_normalization=True,
    cfg_trunc_ratio=1.0,
    max_sequence_length=256,
    dynamic_shifting=True,
    sigmas="Default",
    progress=gr.Progress(track_tqdm=True),
):
    if randomize_seed:
        seed = random.randint(0, MAX_SEED)

    generator = torch.Generator().manual_seed(seed)

    pipe.scheduler.config.use_dynamic_shifting = dynamic_shifting
    pipe.scheduler.config.use_karras_sigmas = sigmas == "Karras"
    pipe.scheduler.config.use_exponential_sigmas = sigmas == "Exponential"
    pipe.scheduler.config.use_beta_sigmas = sigmas == "Beta"
    
    image = pipe(
        prompt=prompt,
        negative_prompt=negative_prompt,
        guidance_scale=guidance_scale,
        num_inference_steps=num_inference_steps,
        width=width,
        height=height,
        generator=generator,
        system_prompt=system_prompt,
        max_sequence_length=max_sequence_length,
        cfg_normalization=cfg_normalization,
        cfg_trunc_ratio=cfg_trunc_ratio,
    ).images[0]

    return image, seed


examples = [
    "A serene photograph capturing the golden reflection of the sun on a vast expanse of water. The sun is positioned at the top center, casting a brilliant, shimmering trail of light across the rippling surface. The water is textured with gentle waves, creating a rhythmic pattern that leads the eye towards the horizon. The entire scene is bathed in warm, golden hues, enhancing the tranquil and meditative atmosphere. High contrast, natural lighting, golden hour, photorealistic, expansive composition, reflective surface, peaceful, visually harmonious.",
]

css = """
#col-container {
    margin: 0 auto;
    max-width: 640px;
}
"""

with gr.Blocks(css=css) as demo:
    with gr.Column(elem_id="col-container"):
        gr.Markdown(" # [Lumina Image v2.0](https://huggingface.co/Alpha-VLLM/Lumina-Image-2.0) by [Alpha-VLLM](https://huggingface.co/Alpha-VLLM)")
        with gr.Row():
            prompt = gr.Text(
                label="Prompt",
                show_label=False,
                lines=2,
                max_lines=4,
                placeholder="Enter your prompt",
                container=False,
            )

            run_button = gr.Button("Run", scale=0, variant="primary")

        result = gr.Image(label="Result", show_label=False)

        with gr.Accordion("Advanced Settings", open=False):
            with gr.Row():
                system_prompt = gr.Text(
                    label="System Prompt",
                    lines=2,
                    max_lines=4,
                    value=default_system_prompt
                )
                
            with gr.Row():
                negative_prompt = gr.Text(
                    label="Negative prompt",
                    lines=2,
                    max_lines=4,
                    placeholder="Enter a negative prompt",
                )

            with gr.Row():
                seed = gr.Slider(
                    label="Seed",
                    minimum=0,
                    maximum=MAX_SEED,
                    step=1,
                    value=0,
                )
                
                randomize_seed = gr.Checkbox(label="Randomize seed", value=True)

            with gr.Row():
                width = gr.Slider(
                    label="Width",
                    minimum=512,
                    maximum=MAX_IMAGE_SIZE,
                    step=32,
                    value=1024, 
                )

                height = gr.Slider(
                    label="Height",
                    minimum=512,
                    maximum=MAX_IMAGE_SIZE,
                    step=32,
                    value=1024,
                )

            with gr.Row():
                guidance_scale = gr.Slider(
                    label="Guidance scale",
                    minimum=0.0,
                    maximum=7.5,
                    step=0.1,
                    value=4.0,
                )

                num_inference_steps = gr.Slider(
                    label="Number of inference steps",
                    minimum=1,
                    maximum=100,
                    step=1,
                    value=30, 
                )

                max_sequence_length = gr.Slider(
                    label="Max Sequence Length",
                    minimum=16,
                    maximum=512,
                    value=256,
                    step=8
                )
                
            with gr.Row():
                cfg_normalization = gr.Checkbox(
                    label="CFG Normalization",
                    value=True
                )
                cfg_trunc_ratio = gr.Slider(
                    label="CFG Truncation Ratio",
                    minimum=0.0,
                    maximum=1.0,
                    step=0.01,
                    value=1.0
                )

            with gr.Row():
                dynamic_shifting = gr.Checkbox(
                    label="Use Dynamic Shifting",
                    value=True
                )
                sigmas = gr.Dropdown(
                    label="Sigmas",
                    choices=[
                        "Default",
                        "Karras",
                        "Exponential",
                        "Beta"
                    ],
                    value="Default"
                )
        
        gr.Examples(examples=examples, inputs=[prompt], outputs=[result, seed], fn=infer, cache_examples=True, cache_mode="lazy")

    gr.on(
        triggers=[run_button.click, prompt.submit],
        fn=infer,
        inputs=[
            prompt,
            negative_prompt,
            seed,
            randomize_seed,
            width,
            height,
            guidance_scale,
            num_inference_steps,
            system_prompt,
            cfg_normalization,
            cfg_trunc_ratio,
            max_sequence_length,
            dynamic_shifting,
            sigmas
        ],
        outputs=[result, seed],
    )

if __name__ == "__main__":
    demo.launch(ssr_mode=False)
