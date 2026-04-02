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
    #map = transforms.CenterCrop((map.size[1] // 64 * 64, map.size[0] // 64 * 64))(map)
    map = transforms.ToTensor()(map)
    map = map.to("cuda")
    return map


image = preprocess_image(
    load_image(
        "input.png"
    )
)

"""
mask = preprocess_map(
    load_image(
        "https://huggingface.co/datasets/OzzyGT/testing-resources/resolve/main/differential/gradient_mask.png?download=true"
    )
)
"""


sys.stdout.flush()
sys.stdout.write('Generating mask image ...\n')
sys.stdout.flush()

border_size=250
#create image
numpy_array = np.zeros(shape=(1024,1024,3), dtype=np.uint8)
#fully black image
cv2.rectangle(numpy_array, (0, 0), (1023, 1023), (0, 0, 0), -1)
#inner white rectangle
cv2.rectangle(numpy_array, (border_size, border_size), (1023-border_size, 1023-border_size), (255, 255, 255), -1)
#blur mask
ksize = (border_size // 2, border_size // 2) 
numpy_array = cv2.blur(numpy_array, ksize) 
#convert to PIL image
img = PIL.Image.fromarray(numpy_array)
#convert to have an alpha channel
img = img.convert('RGBA')
#loop through image pixels and set alpha based on pixel value - white = no alpha - black = full alpha
for x in range(img.size[0]):
    for y in range(img.size[1]):
        #extract RGB
        pixval = img.getpixel((x,y))
        img.putpixel( (x, y), (pixval[0], pixval[1], pixval[2], pixval[0]) ) 
#save mask
img.save("mask.png")

mask = preprocess_map(load_image("mask.png"))

prompt = "a surrealist landscape"
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









