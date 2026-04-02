# riffusion
# Original file is located at https://colab.research.google.com/drive/1FhH3HlN8Ps_Pr9OR6Qcfbfz7utDvICl0

import os

import sys

sys.path.append('./riffusion-inference/riffusion')

from diffusers import DiffusionPipeline
from audio import wav_bytes_from_spectrogram_image
from io import BytesIO
from IPython.display import Audio

pipeline = DiffusionPipeline.from_pretrained("riffusion/riffusion-model-v1")
pipeline = pipeline.to("cuda")

import gradio as gr

def predict(prompt, negative_prompt):
    spec = pipeline(
        prompt,
        negative_prompt=negative_prompt,
        width=768,
    ).images[0]
    wav = wav_bytes_from_spectrogram_image(spec)
    with open("output.wav", "wb") as f:
        f.write(wav[0].getbuffer())
    return 'output.wav'

gr.Interface(
    predict,
    inputs=["text", "text"],
    outputs=gr.outputs.Audio(type='filepath'),
    title="Riffusion",
).launch(share=False, debug=True)