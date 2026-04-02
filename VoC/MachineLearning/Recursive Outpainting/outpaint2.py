import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from torchvision import transforms
import numpy as np
import cv2
import PIL
from diffusers import DPMSolverMultistepScheduler
from diffusers.utils import load_image
from pipeline_stable_diffusion_xl_differential_img2img import StableDiffusionXLDifferentialImg2ImgPipeline


def zoom_at_square(img, zoom=1, angle=0, coord=None):
    cy, cx = [ i/2 for i in img.shape[:-1] ] if coord is None else coord[::-1]
    rot_mat = cv2.getRotationMatrix2D((cx,cy), angle, zoom)
    result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4)
    return result

pipeline = StableDiffusionXLDifferentialImg2ImgPipeline.from_pretrained(
    "SG161222/RealVisXL_V4.0", torch_dtype=torch.float16, variant="fp16"
).to("cuda")
pipeline.scheduler = DPMSolverMultistepScheduler.from_config(pipeline.scheduler.config, use_karras_sigmas=True)


def preprocess_image(image):
    image = image.convert("RGB")
    image = transforms.CenterCrop((image.size[1] // 64 * 64, image.size[0] // 64 * 64))(image)
    image = transforms.ToTensor()(image)
    image = image * 2 - 1
    image = image.unsqueeze(0).to("cuda")
    return image


def preprocess_map(map):
    map = map.convert("L")
    map = transforms.CenterCrop((map.size[1] // 64 * 64, map.size[0] // 64 * 64))(map)
    map = transforms.ToTensor()(map)
    map = map.to("cuda")
    return map


image = preprocess_image(
    load_image(
        "https://huggingface.co/datasets/OzzyGT/testing-resources/resolve/main/differential/20240329211129_4024911930.png?download=true"
    )
)

mask = preprocess_map(
    load_image(
        "https://huggingface.co/datasets/OzzyGT/testing-resources/resolve/main/differential/gradient_mask.png?download=true"
    )
)

prompt = "a pear"
negative_prompt = "blurry"

image = pipeline(
    prompt=prompt,
    negative_prompt=negative_prompt,
    guidance_scale=7.5,
    num_inference_steps=25,
    original_image=image,
    image=image,
    strength=1.0,
    map=mask,
).images[0]

image.save("result.png")
