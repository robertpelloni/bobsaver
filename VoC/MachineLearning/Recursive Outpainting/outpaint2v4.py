# script by Jason Rampe
# https://softology.pro

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from torchvision import transforms
import shutil
import numpy as np
import cv2
import PIL
from diffusers import DPMSolverMultistepScheduler
from diffusers.utils import load_image
from pipeline_stable_diffusion_xl_differential_img2img import StableDiffusionXLDifferentialImg2ImgPipeline
import argparse
import datetime

script_start = datetime.datetime.now()

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--seed", type=int, help="the seed (for reproducible sampling)")
    parser.add_argument("--init_image", type=str, help="the seed image - otherwise build init image from prompt")
    parser.add_argument("--frame_dir", type=str)
    parser.add_argument("--zoom_factor", type=float)
    parser.add_argument("--border_size", type=int, help="mask border size in pixels")
    parser.add_argument("--noise", type=int, help="noise amount between 0 and 255")
    parser.add_argument("--steps", type=int, help="steps for outpainting")
    parser.add_argument("--total_frames", type=int, help="how many frames to create")
    parser.add_argument("--increment_seed_each_frame", type=int, help="0=no 1=yes")

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()


















def zoom_at_square(img, zoom=1, angle=0, coord=None):
    cy, cx = [ i/2 for i in img.shape[:-1] ] if coord is None else coord[::-1]
    rot_mat = cv2.getRotationMatrix2D((cx,cy), angle, zoom)
    result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4)
    return result

sys.stdout.write("Setting up pipeline ...\n")
sys.stdout.flush()

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


prompt = args2.prompt #"a highly detailed painting of a surrealist landscape by dali and beksinski"
negative_prompt = args2.negative_prompt #"blurry"

seed_value= args2.seed

if args2.init_image is None:
    sys.stdout.flush()
    sys.stdout.write('Generating first frame ...\n')
    sys.stdout.flush()

    #generate first frame - needs a temp mask
    #create image
    numpy_array = np.zeros(shape=(1024,1024,3), dtype=np.uint8)
    #fully black image
    cv2.rectangle(numpy_array, (0, 0), (1023, 1023), (0, 0, 0), -1)
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
    image = preprocess_image(load_image("mask.png"))

    generator = torch.Generator(device="cuda").manual_seed(seed_value)
    image = pipeline(
        prompt=prompt,
        negative_prompt=negative_prompt,
        guidance_scale=7.5,
        num_inference_steps=args2.steps,
        original_image=image,
        image=image,
        strength=1.0,
        map=mask,
        generator=generator,
    ).images[0]

    image.save("result.png")
else:
    sys.stdout.flush()
    sys.stdout.write('Loading first frame ...\n')
    sys.stdout.flush()
    shutil.copyfile(args2.init_image,"result.png")


image = preprocess_image(load_image("result.png"))











sys.stdout.flush()
sys.stdout.write('Generating mask image ...\n')
sys.stdout.flush()

#border_size=350
border_size=args2.border_size#100
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






total_frames=args2.total_frames
frames=0
#run until user kills the script from VoC
while (frames<(total_frames)):

    frames=frames+1

    sys.stdout.flush()
    sys.stdout.write(f'Generating frame {frames} ...\n')
    sys.stdout.flush()

    if args2.increment_seed_each_frame==1:
        seed_value=seed_value+1
    
    #zoom image
    sys.stdout.flush()
    sys.stdout.write(f'Zooming ...\n')
    sys.stdout.flush()
    numpy_array = np.array(load_image("result.png"))
    numpy_array = zoom_at_square(numpy_array, zoom=args2.zoom_factor)

    #noise
    sys.stdout.flush()
    sys.stdout.write(f'Adding noise ...\n')
    sys.stdout.flush()
    noise = np.zeros(numpy_array.shape,np.uint8)
    cv2.randu(noise, -args2.noise/2, args2.noise/2)
    numpy_array = cv2.add(numpy_array, noise)
    
    image = PIL.Image.fromarray(numpy_array)
    image.save("result.png")
    
    sys.stdout.flush()
    sys.stdout.write(f'Outpainting ...\n')
    sys.stdout.flush()

    image = preprocess_image(
        load_image(
            "result.png"
        )
    )

    generator = torch.Generator(device="cuda").manual_seed(seed_value)
    image = pipeline(
        prompt=prompt,
        negative_prompt=negative_prompt,
        guidance_scale=7.5,
        num_inference_steps=args2.steps, #25
        original_image=image,
        image=image,
        strength=1.0, #1.0
        map=mask,
        generator=generator,
    ).images[0]

    image.save("result.png")

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

    end = datetime.datetime.now()

    if frames == 1:
        overall_start = datetime.datetime.now()
    if frames > 1:
        average_frame_time = (end-overall_start)/(frames-1)
        elapsed_time = end - script_start
        time_left = average_frame_time*(args2.total_frames-frames+1)
        sys.stdout.write('\n')
        sys.stdout.write(f'\nTime last frame = {end-start}')
        sys.stdout.write(f'\n   Time elapsed = {elapsed_time}')
        sys.stdout.write(f'\n Time remaining = {time_left}\n')
        sys.stdout.write('\n')
    
    start = datetime.datetime.now()






