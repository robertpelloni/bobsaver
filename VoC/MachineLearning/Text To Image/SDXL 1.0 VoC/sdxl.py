# script by Jason Rampe https://softology/pro

import sys

sys.path.append('.\diffusers')

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import datetime

script_start = datetime.datetime.now()

import os
from pytorch_lightning import seed_everything
from diffusers import DiffusionPipeline
from diffusers import StableDiffusionXLPipeline
from diffusers import StableDiffusionXLImg2ImgPipeline
from diffusers.utils import load_image
from diffusers import DDIMScheduler, DDPMScheduler, DEISMultistepScheduler, DPMSolverMultistepScheduler, DPMSolverSDEScheduler, DPMSolverSinglestepScheduler, EulerAncestralDiscreteScheduler, EulerDiscreteScheduler, HeunDiscreteScheduler, KDPM2AncestralDiscreteScheduler, KDPM2DiscreteScheduler, LMSDiscreteScheduler, PNDMScheduler, UniPCMultistepScheduler
from diffusers import StableDiffusionXLControlNetPipeline, ControlNetModel, UniPCMultistepScheduler
from diffusers.utils import load_image
import torch
import argparse
import PIL
from PIL import Image, ImageEnhance
import random
import numpy as np
from tweening import linear, easeInOutQuad, easeInOutCubic, easeInOutQuart, easeInOutQuint, easeInOutPoly, easeInOutSine, easeInOutExpo, easeInOutCirc, easeInOutElastic
import cv2
from scipy.ndimage.filters import median_filter
from color_matcher import ColorMatcher
from color_matcher.io_handler import load_img_file, save_img_file, FILE_EXTS
from color_matcher.normalizer import Normalizer

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--model", type=str, help="safetensors filename")
    parser.add_argument("--lora", type=str, help="safetensors filename")
    parser.add_argument("--lora_weight", type=float, help="lora weight")
    parser.add_argument("--img2img_model", type=str, help="safetensors filename")
    parser.add_argument("--scheduler", type=str, help="which scheduler to use")
    #parser.add_argument("--img2img", type=int, help="use the refining img2img pass 0 no 1 yes") # no longer used, refine is always on
    parser.add_argument("--seed", type=int, help="the seed (for reproducible sampling)")
    parser.add_argument("--steps", type=int, help="steps")
    parser.add_argument("--render_every", type=int, help="render every n frames, otherwise just do the zoom - should be 1 by default")
    parser.add_argument("--width", type=int, help="width")
    parser.add_argument("--height", type=int, help="height")
    parser.add_argument("--guidance_scale", type=float, help="guidance scale")
    parser.add_argument("--num_images_per_prompt", type=int, help="images per prompt")
    parser.add_argument("--image_file", type=str)
    parser.add_argument("--process_video", type=str, help="path to the video frames to process")
    parser.add_argument("--process_video_in_script_prompts", type=int, help="0 no 1 yes - use the prompts with frame numbers from the in script movie area of the dialog")

    parser.add_argument("--init_image", type=str)
    parser.add_argument("--init_image_strength", type=float)
    parser.add_argument("--frame_dir", type=str)
    parser.add_argument("--offload", type=int, help="CPU offloading 0 no 1 yes")
    #in script movie settings
    parser.add_argument("--in_script_movie", type=int, help="0 no 1 yes")
    parser.add_argument("--rotate", type=str, help="rotate string")
    parser.add_argument("--zoom", type=str, help="zoom string")
    parser.add_argument("--zoom_method", type=str, help="zoom method")
    parser.add_argument("--zoom_factor", type=float, help="zoom compensation factor")
    parser.add_argument("--panx", type=str, help="pan X amount")
    parser.add_argument("--pany", type=str, help="pan Y amount")
    parser.add_argument("--contrast", type=float, help="contrast")
    parser.add_argument("--sharpness", type=float, help="0=blur, 1=same, 2=sharp")
    parser.add_argument("--sharpness_radius", type=int, help="sharpness radius - default 5")
    parser.add_argument("--sharpness_method", type=str, help="Gaussian or Laplacian")
    parser.add_argument("--noise", type=int, help="noise amount between 0 and 255")
    parser.add_argument("--correct_noise", type=int, help="0 no 1 yes")
    parser.add_argument("--blur_noise", type=int, help="0 no 1 yes")
    parser.add_argument("--blur_noise_amount", type=int, help="blur noise kernel radius")
    parser.add_argument("--auto_color", type=int, help="0 no 1 yes")
    parser.add_argument("--auto_contrast", type=int, help="0 no 1 yes")
    parser.add_argument("--equalize", type=int, help="0 no 1 yes")
    parser.add_argument("--hard_cuts", type=int, help="0 no 1 yes")
    parser.add_argument("--randomize_seed", type=int, help="0 no 1 yes")
    parser.add_argument("--zoom_after_sharpen", type=int, help="0 no 1 yes")
    parser.add_argument("--total_frames", type=int, help="how many frames to generate for the movie")
    parser.add_argument("--red_scale", type=float, help="1=no change <1=darken red >1 brighten red")
    parser.add_argument("--green_scale", type=float, help="1=no change <1=darken green >1 brighten green")
    parser.add_argument("--blue_scale", type=float, help="1=no change <1=darken blue >1 brighten blue")
    parser.add_argument("--tween", type=str, help="tween method to use")
    parser.add_argument("--controlnet", type=int, help="0 no 1 yes")
    parser.add_argument("--color_matching", type=int, help="0 no 1 yes")
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

seed_everything(args2.seed)

prompts = [
#VOC START - DO NOT DELETE
    "0:roses",
    "120:daisies",
    "240:tulips",
#VOC FINISH - DO NOT DELETE
]

#sys.stdout.write(f"DEBUG - prompts count = {len(prompts)}\n")
#sys.stdout.flush()

prompts_frames = []
prompts_prompts = []

for i in range(len(prompts)):
    s = prompts[i].split(":")
    prompts_frames.append(s[0])
    prompts_prompts.append(s[1])

#sys.stdout.write(f"DEBUG - prompts_frames = {prompts_frames}\n")
#sys.stdout.write(f"DEBUG - prompts_prompts = {prompts_prompts}\n")
#sys.stdout.flush()

#returns the prompt for the current frame
def set_prompt(fnum,current_prompt):
    new_prompt = current_prompt
    for i in range(len(prompts)):
        if int(prompts_frames[i]) == fnum:
            new_prompt = prompts_prompts[i]
    #sys.stdout.write(f"DEBUG - new_prompt = {new_prompt}\n")
    #sys.stdout.flush()
    return new_prompt

##############################################################################################################################################################
# process video
##############################################################################################################################################################

if args2.process_video is not None:

    sys.stdout.write("Getting source frame images ...\n")
    sys.stdout.flush()

    from os import listdir
    from os.path import isfile, join
    onlyfiles = [os.path.join(args2.process_video, f) for f in listdir(args2.process_video) if isfile(join(args2.process_video, f))]
    #print(onlyfiles)
    
    sys.stdout.write(f"Setting up {args2.img2img_model} StableDiffusionXLImg2ImgPipeline with {args2.scheduler} ...\n")
    sys.stdout.flush()
    pipe2 = StableDiffusionXLImg2ImgPipeline.from_single_file(f"./{args2.img2img_model}", torch_dtype=torch.float16, use_safetensors=True, variant="fp16", add_watermarker=False)
    
    if args2.scheduler == 'DDIMScheduler':
        pipe2.scheduler = DDIMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DDPMScheduler':
        pipe2.scheduler = DDPMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DEISMultistepScheduler':
        pipe2.scheduler = DEISMultistepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverMultistepScheduler':
        pipe2.scheduler = DPMSolverMultistepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverSDEScheduler':
        pipe2.scheduler = DPMSolverSDEScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverSinglestepScheduler':
        pipe2.scheduler = DPMSolverSinglestepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'EulerAncestralDiscreteScheduler':
        pipe2.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'EulerDiscreteScheduler':
        pipe2.scheduler = EulerDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'HeunDiscreteScheduler':
        pipe2.scheduler = HeunDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'KDPM2AncestralDiscreteScheduler':
        pipe2.scheduler = KDPM2AncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'KDPM2DiscreteScheduler':
        pipe2.scheduler = KDPM2DiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'LMSDiscreteScheduler':
        pipe2.scheduler = LMSDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'PNDMScheduler':
        pipe2.scheduler = PNDMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'UniPCMultistepScheduler':
        pipe2.scheduler = UniPCMultistepScheduler.from_config(pipe2.scheduler.config)
    if args2.offload == 0:
        pipe2.to("cuda")
    else:
        pipe2.enable_model_cpu_offload()

    """
    #does not work - 
    if args2.lora is not None:
        sys.stdout.write(f"Loading LoRA weights from {args2.lora} ...\n")
        sys.stdout.flush()
        #pipe2.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora}", adapter_name="lora_adapter")
        pipe2.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora}", adapter_name="lora_adapter", low_cpu_mem_usage=False, ignore_mismatched_sizes=True)
        sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight} ...\n")
        sys.stdout.flush()
        pipe2.fuse_lora(lora_scale=args2.lora_weight)
    """
    
    prompt = set_prompt(0,args2.prompt)

    sys.stdout.write("Processing frame images ...\n")
    sys.stdout.flush()

    for i in range(len(onlyfiles)):

        frames=i+1
        start = datetime.datetime.now()

        sys.stdout.write("")
        sys.stdout.write(f"\nProcessing frame {i+1}/{len(onlyfiles)} ...\n")
        sys.stdout.flush()

        seed_everything(args2.seed)
        torch.random.manual_seed(args2.seed)

        sys.stdout.write("Loading init image ...\n")
        sys.stdout.flush()
        initimage = load_image(onlyfiles[i]).convert("RGB")
        sys.stdout.write("Refining init image ...\n")
        sys.stdout.flush()
        
        if args2.process_video_in_script_prompts == 0:
            prompt = args2.prompt
        if args2.process_video_in_script_prompts == 1:
            prompt = set_prompt(frames,prompt)
        sys.stdout.write(f'\nPrompt = "{prompt}"\n')

        #this was supposed to help keep temporal smoothness - it didn't
        #seed_everything(args2.seed)

        images = pipe2(prompt=args2.prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=initimage,num_inference_steps=args2.steps,strength=args2.init_image_strength, target_size=(args2.width,args2.height)).images[0]

        sys.stdout.flush()
        sys.stdout.write('Saving progress ...\n')
        sys.stdout.flush()
        images.save(args2.image_file)
        sys.stdout.flush()
        sys.stdout.write('Progress saved\n')
        sys.stdout.flush()

        #save next movie FRA frame
        sys.stdout.flush()
        sys.stdout.write('Saving movie frame ...\n')
        sys.stdout.flush()

        if args2.frame_dir is not None:
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
            images.save(save_name)

        sys.stdout.flush()
        sys.stdout.write('Frame saved')
        sys.stdout.flush()

        end = datetime.datetime.now()
        if frames == 1:
            overall_start = datetime.datetime.now()
        if frames > 1:
            average_frame_time = (end-overall_start)/(frames-1)
            elapsed_time = end - script_start
            time_left = average_frame_time*(len(onlyfiles)-frames+1)
            sys.stdout.write(f'\nTime last frame = {end-start}')
            sys.stdout.write(f'\n   Time elapsed = {elapsed_time}')
            sys.stdout.write(f'\n Time remaining = {time_left}\n')

    sys.exit()

#parameters for functions here https://huggingface.co/docs/diffusers/api/pipelines/stable_diffusion/stable_diffusion_xl

##############################################################################################################################################################
# single image
##############################################################################################################################################################
if args2.in_script_movie == 0:

    if args2.init_image is None:
        sys.stdout.write(f"Setting up StableDiffusionXLPipeline with {args2.scheduler} ...\n")
        sys.stdout.flush()
        pipe = StableDiffusionXLPipeline.from_single_file(f"./{args2.model}", torch_dtype=torch.float16, use_safetensors=True, variant="fp16", add_watermarker=False)
        #pipe = StableDiffusionXLPipeline.from_pretrained("etri-vilab/koala-700m", torch_dtype=torch.float16)    

        #for i in pipe.scheduler.config:
        #    print (i) # this will print all keys
        #    print (pipe.scheduler.config[i]) # this will print all values

        if args2.scheduler == 'DDIMScheduler':
            pipe.scheduler = DDIMScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'DDPMScheduler':
            pipe.scheduler = DDPMScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'DEISMultistepScheduler':
            pipe.scheduler = DEISMultistepScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'DPMSolverMultistepScheduler':
            pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'DPMSolverSDEScheduler':
            pipe.scheduler = DPMSolverSDEScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'DPMSolverSinglestepScheduler':
            pipe.scheduler = DPMSolverSinglestepScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'EulerAncestralDiscreteScheduler':
            pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'EulerDiscreteScheduler':
            pipe.scheduler = EulerDiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'HeunDiscreteScheduler':
            pipe.scheduler = HeunDiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'KDPM2AncestralDiscreteScheduler':
            pipe.scheduler = KDPM2AncestralDiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'KDPM2DiscreteScheduler':
            pipe.scheduler = KDPM2DiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'LMSDiscreteScheduler':
            pipe.scheduler = LMSDiscreteScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'PNDMScheduler':
            pipe.scheduler = PNDMScheduler.from_config(pipe.scheduler.config)
        if args2.scheduler == 'UniPCMultistepScheduler':
            pipe.scheduler = UniPCMultistepScheduler.from_config(pipe.scheduler.config)

        if args2.offload == 0:
            pipe.to("cuda")
        else:
            pipe.enable_model_cpu_offload()
        
        if args2.lora is not None:
            sys.stdout.write(f"Loading LoRA weights from {args2.lora} ...\n")
            sys.stdout.flush()
            pipe.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora}", adapter_name="lora_adapter")
            sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight} ...\n")
            sys.stdout.flush()
            pipe.fuse_lora(lora_scale=args2.lora_weight)
        
    #if args2.img2img == 1 or args2.init_image is not None:
    if args2.img2img_model is not None or args2.init_image is not None:
        sys.stdout.write(f"Setting up {args2.img2img_model} StableDiffusionXLImg2ImgPipeline with {args2.scheduler} ...\n")
        sys.stdout.flush()
        pipe2 = StableDiffusionXLImg2ImgPipeline.from_single_file(f"./{args2.img2img_model}", torch_dtype=torch.float16, use_safetensors=True, variant="fp16", add_watermarker=False)

        if args2.scheduler == 'DDIMScheduler':
            pipe2.scheduler = DDIMScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'DDPMScheduler':
            pipe2.scheduler = DDPMScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'DEISMultistepScheduler':
            pipe2.scheduler = DEISMultistepScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'DPMSolverMultistepScheduler':
            pipe2.scheduler = DPMSolverMultistepScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'DPMSolverSDEScheduler':
            pipe2.scheduler = DPMSolverSDEScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'DPMSolverSinglestepScheduler':
            pipe2.scheduler = DPMSolverSinglestepScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'EulerAncestralDiscreteScheduler':
            pipe2.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'EulerDiscreteScheduler':
            pipe2.scheduler = EulerDiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'HeunDiscreteScheduler':
            pipe2.scheduler = HeunDiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'KDPM2AncestralDiscreteScheduler':
            pipe2.scheduler = KDPM2AncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'KDPM2DiscreteScheduler':
            pipe2.scheduler = KDPM2DiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'LMSDiscreteScheduler':
            pipe2.scheduler = LMSDiscreteScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'PNDMScheduler':
            pipe2.scheduler = PNDMScheduler.from_config(pipe2.scheduler.config)
        if args2.scheduler == 'UniPCMultistepScheduler':
            pipe2.scheduler = UniPCMultistepScheduler.from_config(pipe2.scheduler.config)

        if args2.offload == 0:
            pipe2.to("cuda")
        else:
            pipe2.enable_model_cpu_offload()

    if args2.init_image is None:
    #if args2.img2img_model is not None or args2.init_image is not None:
        if args2.img2img_model is None:
            sys.stdout.write("Generating image ...\n")
            sys.stdout.flush()
            images = pipe(prompt=args2.prompt,negative_prompt=args2.negative_prompt,width=args2.width,height=args2.height,num_inference_steps=args2.steps,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt).images[0]
        else:
            sys.stdout.write("Generating image ...\n")
            sys.stdout.flush()
            latents = pipe(prompt=args2.prompt,negative_prompt=args2.negative_prompt,width=args2.width,height=args2.height,num_inference_steps=args2.steps,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt,output_type='latent').images
            sys.stdout.write("Refining image ...\n")
            sys.stdout.flush()
            images = pipe2(prompt=args2.prompt,negative_prompt=args2.negative_prompt,num_images_per_prompt=args2.num_images_per_prompt, image=latents,num_inference_steps=args2.steps,strength=args2.init_image_strength).images[0]
    else:
        sys.stdout.write("Loading init image ...\n")
        sys.stdout.flush()
        initimage = load_image(args2.init_image).convert("RGB")
        sys.stdout.write("Refining init image ...\n")
        sys.stdout.flush()
        images = pipe2(prompt=args2.prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=initimage,num_inference_steps=args2.steps,strength=args2.init_image_strength, target_size=(args2.width,args2.height)).images[0]
    
    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()
    images.save(args2.image_file)
    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()

    sys.exit()

##############################################################################################################################################################
# movie
##############################################################################################################################################################

def zoom_at_square(img, zoom=1, angle=0, coord=None):
    cy, cx = [ i/2 for i in img.shape[:-1] ] if coord is None else coord[::-1]
    rot_mat = cv2.getRotationMatrix2D((cx,cy), angle, zoom)
    #result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LINEAR)
    if args2.zoom_method == "INTER_NEAREST":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_NEAREST)
    if args2.zoom_method == "INTER_LINEAR":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LINEAR)
    if args2.zoom_method == "INTER_AREA":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_AREA)
    if args2.zoom_method == "INTER_CUBIC":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_CUBIC)
    if args2.zoom_method == "INTER_LANCZOS4":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4)
    return result

def zoom_at(img, zoom=1, angle=0, coord=None):

    #rotate first

    cy, cx = [ i/2 for i in img.shape[:-1] ] if coord is None else coord[::-1]
    rot_mat = cv2.getRotationMatrix2D((cx,cy), angle, 1.0)
    if args2.zoom_method == "INTER_NEAREST":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_NEAREST)
    if args2.zoom_method == "INTER_LINEAR":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LINEAR)
    if args2.zoom_method == "INTER_AREA":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_AREA)
    if args2.zoom_method == "INTER_CUBIC":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_CUBIC)
    if args2.zoom_method == "INTER_LANCZOS4":
        result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4)

    #then zoom

    (original_height, original_width) = img.shape[:2]

    sys.stdout.write(f'        Original width {original_width}\n')
    sys.stdout.write(f'        Original height {original_height}\n')
    sys.stdout.flush()

    max_size = max(original_width,original_height)

    #sys.stdout.write(f'        Max size {max_size}\n')
    #sys.stdout.flush()

    if original_width > original_height:
        aspect_ratio = float(original_height) / float(original_width)

        sys.stdout.write(f'        Aspect ratio {aspect_ratio}\n')
        sys.stdout.flush()
        
        new_width = int(max_size * zoom)
        new_height = int(new_width * aspect_ratio * args2.zoom_factor) # the zoom_factor multilplier compensates for the horizontal axis stretching too much compared to vertical, so this stretches the vertical more than calculated

    else:
        aspect_ratio = float(original_width) / float(original_height)

        sys.stdout.write(f'        Aspect ratio {aspect_ratio}\n')
        sys.stdout.flush()
        
        new_height = int(max_size * zoom)
        new_width =  int(new_height * aspect_ratio * args2.zoom_factor) # the zoom_factor multilplier compensates for the horizontal axis stretching too much compared to vertical, so this stretches the vertical more than calculated

    sys.stdout.write(f'        New width {new_width}\n')
    sys.stdout.write(f'        New height {new_height}\n')
    sys.stdout.flush()

    new_dimensions = (new_width, new_height)
    if args2.zoom_method == "INTER_NEAREST":
        result2 = cv2.resize(result, new_dimensions, interpolation= cv2.INTER_NEAREST)
    if args2.zoom_method == "INTER_LINEAR":
        result2 = cv2.resize(result, new_dimensions, interpolation= cv2.INTER_LINEAR)
    if args2.zoom_method == "INTER_AREA":
        result2 = cv2.resize(result, new_dimensions, interpolation= cv2.INTER_AREA)
    if args2.zoom_method == "INTER_CUBIC":
        result2 = cv2.resize(result, new_dimensions, interpolation= cv2.INTER_CUBIC)
    if args2.zoom_method == "INTER_LANCZOS4":
        result2 = cv2.resize(result, new_dimensions, interpolation= cv2.INTER_LANCZOS4)

    xoffset = int((new_width-original_width)/2)
    yoffset = int((new_height-original_height)/2)

    sys.stdout.write(f'        X offset {xoffset}\n')
    sys.stdout.write(f'        Y offset {yoffset}\n')
    sys.stdout.flush()

    result = result2[yoffset:yoffset+original_height, xoffset:xoffset+original_width]
    return result

# https://stackoverflow.com/a/55590133/4237309
def unsharp_mask(image, kernel_size=(args2.sharpness_radius, args2.sharpness_radius), sigma=1.0, amount=1.0, threshold=0):
    #Return a sharpened version of the image, using an unsharp mask.
    blurred = cv2.GaussianBlur(image, kernel_size, sigma)
    sharpened = float(amount + 1) * image - float(amount) * blurred
    sharpened = np.maximum(sharpened, np.zeros(sharpened.shape))
    sharpened = np.minimum(sharpened, 255 * np.ones(sharpened.shape))
    sharpened = sharpened.round().astype(np.uint8)
    if threshold > 0:
        low_contrast_mask = np.absolute(image - blurred) < threshold
        np.copyto(sharpened, image, where=low_contrast_mask)
    return sharpened

#https://www.idtools.com.au/unsharp-masking-with-python-and-opencv/
def unsharp_mask_2(image, sigma, strength):
    # Median filtering
    image_mf = median_filter(image, sigma)
    # Calculate the Laplacian
    lap = cv2.Laplacian(image_mf,cv2.CV_64F)
    #lap = cv2.Laplacian(image_mf, cv2.CV_8U)
    # Calculate the sharpened image
    sharp = image-strength*lap
    # Saturate the pixels in either direction
    sharp[sharp>255] = 255
    sharp[sharp<0] = 0
    return sharp.astype(np.uint8)
    
"""
prompts = [
#VOC START - DO NOT DELETE
    "0:hyperrealistic cronenberg body horror, blood, gore, macabre, susp1r1a",
#VOC FINISH - DO NOT DELETE
]

#sys.stdout.write(f"DEBUG - prompts count = {len(prompts)}\n")
#sys.stdout.flush()

prompts_frames = []
prompts_prompts = []

for i in range(len(prompts)):
    s = prompts[i].split(":")
    prompts_frames.append(s[0])
    prompts_prompts.append(s[1])

#sys.stdout.write(f"DEBUG - prompts_frames = {prompts_frames}\n")
#sys.stdout.write(f"DEBUG - prompts_prompts = {prompts_prompts}\n")
#sys.stdout.flush()

#returns the prompt for the current frame
def set_prompt(fnum,current_prompt):
    new_prompt = current_prompt
    for i in range(len(prompts)):
        if int(prompts_frames[i]) == fnum:
            new_prompt = prompts_prompts[i]
    #sys.stdout.write(f"DEBUG - new_prompt = {new_prompt}\n")
    #sys.stdout.flush()
    return new_prompt
"""

##############################################################################################################################################################
# zoom tweening
##############################################################################################################################################################

zoom_string = args2.zoom
zooms = zoom_string.split(',')
zoom_frames_split = []
zoom_amounts_split = []
#parse the zoom amounts
for i in range(len(zooms)):
    s = zooms[i].split(":")
    zoom_frames_split.append(s[0])
    zoom_amounts_split.append(s[1])
#sys.stdout.write(f"DEBUG - zoom_frames_split = {zoom_frames_split}\n")
#sys.stdout.write(f"DEBUG - zoom_amounts_split = {zoom_amounts_split}\n")
#sys.stdout.flush()
zoom_frames = []
zoom_amounts = []
total_frames = 0
#tween zoom values
for i in range(1,len(zoom_frames_split)):
    start = float(zoom_amounts_split[i-1])
    end = float(zoom_amounts_split[i])
    steps = int(zoom_frames_split[i])-int(zoom_frames_split[i-1])
    distance = float(zoom_amounts_split[i])-float(zoom_amounts_split[i-1])
    #sys.stdout.write(f"DEBUG - tweening {steps} steps between {start} and {end} over a distance of {distance}\n")
    #sys.stdout.flush()
    for j in range(steps):
        if args2.tween == 'linear':
            zoom_amounts.append(start+linear(j/steps)*distance)
        if args2.tween == 'easeInOutQuad':
            zoom_amounts.append(start+easeInOutQuad(j/steps)*distance)
        if args2.tween == 'easeInOutCubic':
            zoom_amounts.append(start+easeInOutCubic(j/steps)*distance)
        if args2.tween == 'easeInOutQuart':
            zoom_amounts.append(start+easeInOutQuart(j/steps)*distance)
        if args2.tween == 'easeInOutQuint':
            zoom_amounts.append(start+easeInOutQuint(j/steps)*distance)
        if args2.tween == 'easeInOutPoly':
            zoom_amounts.append(start+easeInOutPoly(j/steps)*distance)
        if args2.tween == 'easeInOutSine':
            zoom_amounts.append(start+easeInOutSine(j/steps)*distance)
        if args2.tween == 'easeInOutExpo':
            zoom_amounts.append(start+easeInOutExpo(j/steps)*distance)
        if args2.tween == 'easeInOutCirc':
            zoom_amounts.append(start+easeInOutCirc(j/steps)*distance)
        if args2.tween == 'easeInOutElastic':
            zoom_amounts.append(start+easeInOutElastic(j/steps)*distance)
#handle single value specified, ie 0:0, or 0:123
if len(zoom_amounts) == 0:
    zoom_frames.append(0)
    zoom_amounts.append(zoom_amounts_split[0])
#make sure the last tweened value is correct
zoom_amounts[len(zoom_amounts)-1] = float(zoom_amounts_split[len(zoom_amounts_split)-1])
#make sure the number of tweened values is enough for the args2.total_frames
if len(zoom_amounts) < args2.total_frames:
    lastzoom = zoom_amounts[len(zoom_amounts)-1]
    for i in range (args2.total_frames-len(zoom_amounts)):
        zoom_amounts.append(float(lastzoom))
#sys.stdout.write(f"DEBUG - {len(zoom_amounts)} zoom_amounts = {zoom_amounts}\n")
#sys.stdout.flush()

##############################################################################################################################################################
# rotate tweening
##############################################################################################################################################################

rotate_string = args2.rotate
rotates = rotate_string.split(',')
rotate_frames_split = []
rotate_amounts_split = []
#parse the rotate amounts
for i in range(len(rotates)):
    s = rotates[i].split(":")
    rotate_frames_split.append(s[0])
    rotate_amounts_split.append(s[1])
#sys.stdout.write(f"DEBUG - rotate_frames_split = {rotate_frames_split}\n")
#sys.stdout.write(f"DEBUG - rotate_amounts_split = {rotate_amounts_split}\n")
#sys.stdout.flush()
rotate_frames = []
rotate_amounts = []
total_frames = 0
#tween rotate values
for i in range(1,len(rotate_frames_split)):
    start = float(rotate_amounts_split[i-1])
    end = float(rotate_amounts_split[i])
    steps = int(rotate_frames_split[i])-int(rotate_frames_split[i-1])
    distance = float(rotate_amounts_split[i])-float(rotate_amounts_split[i-1])
    #sys.stdout.write(f"DEBUG - tweening {steps} steps between {start} and {end} over a distance of {distance}\n")
    #sys.stdout.flush()
    for j in range(steps):
        if args2.tween == 'linear':
            rotate_amounts.append(start+linear(j/steps)*distance)
        if args2.tween == 'easeInOutQuad':
            rotate_amounts.append(start+easeInOutQuad(j/steps)*distance)
        if args2.tween == 'easeInOutCubic':
            rotate_amounts.append(start+easeInOutCubic(j/steps)*distance)
        if args2.tween == 'easeInOutQuart':
            rotate_amounts.append(start+easeInOutQuart(j/steps)*distance)
        if args2.tween == 'easeInOutQuint':
            rotate_amounts.append(start+easeInOutQuint(j/steps)*distance)
        if args2.tween == 'easeInOutPoly':
            rotate_amounts.append(start+easeInOutPoly(j/steps)*distance)
        if args2.tween == 'easeInOutSine':
            rotate_amounts.append(start+easeInOutSine(j/steps)*distance)
        if args2.tween == 'easeInOutExpo':
            rotate_amounts.append(start+easeInOutExpo(j/steps)*distance)
        if args2.tween == 'easeInOutCirc':
            rotate_amounts.append(start+easeInOutCirc(j/steps)*distance)
        if args2.tween == 'easeInOutElastic':
            rotate_amounts.append(start+easeInOutElastic(j/steps)*distance)
#handle single value specified, ie 0:0, or 0:123
if len(rotate_amounts) == 0:
    rotate_frames.append(0)
    rotate_amounts.append(rotate_amounts_split[0])
#make sure the last tweened value is correct
rotate_amounts[len(rotate_amounts)-1] = float(rotate_amounts_split[len(rotate_amounts_split)-1])
#make sure the number of tweened values is enough for the args2.total_frames
if len(rotate_amounts) < args2.total_frames:
    lastrotate = rotate_amounts[len(rotate_amounts)-1]
    for i in range (args2.total_frames-len(rotate_amounts)):
        rotate_amounts.append(float(lastrotate))
#sys.stdout.write(f"DEBUG - {len(rotate_amounts)} rotate_amounts = {rotate_amounts}\n")
#sys.stdout.flush()

##############################################################################################################################################################
# pan x tweening
##############################################################################################################################################################

panx_string = args2.panx
panxs = panx_string.split(',')
panx_frames_split = []
panx_amounts_split = []
#parse the panx amounts
for i in range(len(panxs)):
    s = panxs[i].split(":")
    panx_frames_split.append(s[0])
    panx_amounts_split.append(s[1])
#sys.stdout.write(f"DEBUG - panx_frames_split = {panx_frames_split}\n")
#sys.stdout.write(f"DEBUG - panx_amounts_split = {panx_amounts_split}\n")
#sys.stdout.flush()
panx_frames = []
panx_amounts = []
total_frames = 0
#tween panx values
for i in range(1,len(panx_frames_split)):
    start = float(panx_amounts_split[i-1])
    end = float(panx_amounts_split[i])
    steps = int(panx_frames_split[i])-int(panx_frames_split[i-1])
    distance = float(panx_amounts_split[i])-float(panx_amounts_split[i-1])
    #sys.stdout.write(f"DEBUG - tweening {steps} steps between {start} and {end} over a distance of {distance}\n")
    #sys.stdout.flush()
    for j in range(steps):
        if args2.tween == 'linear':
            panx_amounts.append(start+linear(j/steps)*distance)
        if args2.tween == 'easeInOutQuad':
            panx_amounts.append(start+easeInOutQuad(j/steps)*distance)
        if args2.tween == 'easeInOutCubic':
            panx_amounts.append(start+easeInOutCubic(j/steps)*distance)
        if args2.tween == 'easeInOutQuart':
            panx_amounts.append(start+easeInOutQuart(j/steps)*distance)
        if args2.tween == 'easeInOutQuint':
            panx_amounts.append(start+easeInOutQuint(j/steps)*distance)
        if args2.tween == 'easeInOutPoly':
            panx_amounts.append(start+easeInOutPoly(j/steps)*distance)
        if args2.tween == 'easeInOutSine':
            panx_amounts.append(start+easeInOutSine(j/steps)*distance)
        if args2.tween == 'easeInOutExpo':
            panx_amounts.append(start+easeInOutExpo(j/steps)*distance)
        if args2.tween == 'easeInOutCirc':
            panx_amounts.append(start+easeInOutCirc(j/steps)*distance)
        if args2.tween == 'easeInOutElastic':
            panx_amounts.append(start+easeInOutElastic(j/steps)*distance)
#handle single value specified, ie 0:0, or 0:123
if len(panx_amounts) == 0:
    panx_frames.append(0)
    panx_amounts.append(panx_amounts_split[0])
#make sure the last tweened value is correct
panx_amounts[len(panx_amounts)-1] = float(panx_amounts_split[len(panx_amounts_split)-1])
#make sure the number of tweened values is enough for the args2.total_frames
if len(panx_amounts) < args2.total_frames:
    lastpanx = panx_amounts[len(panx_amounts)-1]
    for i in range (args2.total_frames-len(panx_amounts)):
        panx_amounts.append(float(lastpanx))
#sys.stdout.write(f"DEBUG - {len(panx_amounts)} panx_amounts = {panx_amounts}\n")
#sys.stdout.flush()

##############################################################################################################################################################
# pan y tweening
##############################################################################################################################################################

pany_string = args2.pany
panys = pany_string.split(',')
pany_frames_split = []
pany_amounts_split = []
#parse the pany amounts
for i in range(len(panys)):
    s = panys[i].split(":")
    pany_frames_split.append(s[0])
    pany_amounts_split.append(s[1])
#sys.stdout.write(f"DEBUG - pany_frames_split = {pany_frames_split}\n")
#sys.stdout.write(f"DEBUG - pany_amounts_split = {pany_amounts_split}\n")
#sys.stdout.flush()
pany_frames = []
pany_amounts = []
total_frames = 0
#tween pany values
for i in range(1,len(pany_frames_split)):
    start = float(pany_amounts_split[i-1])
    end = float(pany_amounts_split[i])
    steps = int(pany_frames_split[i])-int(pany_frames_split[i-1])
    distance = float(pany_amounts_split[i])-float(pany_amounts_split[i-1])
    #sys.stdout.write(f"DEBUG - tweening {steps} steps between {start} and {end} over a distance of {distance}\n")
    #sys.stdout.flush()
    for j in range(steps):
        if args2.tween == 'linear':
            pany_amounts.append(start+linear(j/steps)*distance)
        if args2.tween == 'easeInOutQuad':
            pany_amounts.append(start+easeInOutQuad(j/steps)*distance)
        if args2.tween == 'easeInOutCubic':
            pany_amounts.append(start+easeInOutCubic(j/steps)*distance)
        if args2.tween == 'easeInOutQuart':
            pany_amounts.append(start+easeInOutQuart(j/steps)*distance)
        if args2.tween == 'easeInOutQuint':
            pany_amounts.append(start+easeInOutQuint(j/steps)*distance)
        if args2.tween == 'easeInOutPoly':
            pany_amounts.append(start+easeInOutPoly(j/steps)*distance)
        if args2.tween == 'easeInOutSine':
            pany_amounts.append(start+easeInOutSine(j/steps)*distance)
        if args2.tween == 'easeInOutExpo':
            pany_amounts.append(start+easeInOutExpo(j/steps)*distance)
        if args2.tween == 'easeInOutCirc':
            pany_amounts.append(start+easeInOutCirc(j/steps)*distance)
        if args2.tween == 'easeInOutElastic':
            pany_amounts.append(start+easeInOutElastic(j/steps)*distance)
#handle single value specified, ie 0:0, or 0:123
if len(pany_amounts) == 0:
    pany_frames.append(0)
    pany_amounts.append(pany_amounts_split[0])
#make sure the last tweened value is correct
pany_amounts[len(pany_amounts)-1] = float(pany_amounts_split[len(pany_amounts_split)-1])
#make sure the number of tweened values is enough for the args2.total_frames
if len(pany_amounts) < args2.total_frames:
    lastpany = pany_amounts[len(pany_amounts)-1]
    for i in range (args2.total_frames-len(pany_amounts)):
        pany_amounts.append(float(lastpany))
#sys.stdout.write(f"DEBUG - {len(pany_amounts)} pany_amounts = {pany_amounts}\n")
#sys.stdout.flush()

if args2.in_script_movie == 1:

    #setup base model for initial pass
    sys.stdout.write(f"Setting up StableDiffusionXLPipeline with {args2.scheduler} ...\n")
    sys.stdout.flush()
    pipe = StableDiffusionXLPipeline.from_single_file(f"./{args2.model}", torch_dtype=torch.float16, use_safetensors=True, variant="fp16", add_watermarker=False)

    if args2.scheduler == 'DDIMScheduler':
        pipe.scheduler = DDIMScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'DDPMScheduler':
        pipe.scheduler = DDPMScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'DEISMultistepScheduler':
        pipe.scheduler = DEISMultistepScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'DPMSolverMultistepScheduler':
        pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'DPMSolverSDEScheduler':
        pipe.scheduler = DPMSolverSDEScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'DPMSolverSinglestepScheduler':
        pipe.scheduler = DPMSolverSinglestepScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'EulerAncestralDiscreteScheduler':
        pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'EulerDiscreteScheduler':
        pipe.scheduler = EulerDiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'HeunDiscreteScheduler':
        pipe.scheduler = HeunDiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'KDPM2AncestralDiscreteScheduler':
        pipe.scheduler = KDPM2AncestralDiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'KDPM2DiscreteScheduler':
        pipe.scheduler = KDPM2DiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'LMSDiscreteScheduler':
        pipe.scheduler = LMSDiscreteScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'PNDMScheduler':
        pipe.scheduler = PNDMScheduler.from_config(pipe.scheduler.config)
    if args2.scheduler == 'UniPCMultistepScheduler':
        pipe.scheduler = UniPCMultistepScheduler.from_config(pipe.scheduler.config)

    if args2.offload == 0:
        pipe.to("cuda")
    else:
        pipe.enable_model_cpu_offload()

    if args2.lora is not None:
        sys.stdout.write(f"Loading LoRA weights from {args2.lora} ...\n")
        sys.stdout.flush()
        pipe.load_lora_weights(pretrained_model_name_or_path_or_dict=f"./LoRAs/{args2.lora}", adapter_name="lora_adapter")
        sys.stdout.write(f"Fusing LoRA with a weight of {args2.lora_weight} ...\n")
        sys.stdout.flush()
        pipe.fuse_lora(lora_scale=args2.lora_weight)

    #setup img2img pipeline for each frame
    sys.stdout.write(f"Setting up {args2.img2img_model} StableDiffusionXLImg2ImgPipeline with {args2.scheduler} ...\n")
    sys.stdout.flush()
    pipe2 = StableDiffusionXLImg2ImgPipeline.from_single_file(f"./{args2.img2img_model}", torch_dtype=torch.float16, use_safetensors=True, variant="fp16", add_watermarker=False)

    if args2.scheduler == 'DDIMScheduler':
        pipe2.scheduler = DDIMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DDPMScheduler':
        pipe2.scheduler = DDPMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DEISMultistepScheduler':
        pipe2.scheduler = DEISMultistepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverMultistepScheduler':
        pipe2.scheduler = DPMSolverMultistepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverSDEScheduler':
        pipe2.scheduler = DPMSolverSDEScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'DPMSolverSinglestepScheduler':
        pipe2.scheduler = DPMSolverSinglestepScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'EulerAncestralDiscreteScheduler':
        pipe2.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'EulerDiscreteScheduler':
        pipe2.scheduler = EulerDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'HeunDiscreteScheduler':
        pipe2.scheduler = HeunDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'KDPM2AncestralDiscreteScheduler':
        pipe2.scheduler = KDPM2AncestralDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'KDPM2DiscreteScheduler':
        pipe2.scheduler = KDPM2DiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'LMSDiscreteScheduler':
        pipe2.scheduler = LMSDiscreteScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'PNDMScheduler':
        pipe2.scheduler = PNDMScheduler.from_config(pipe2.scheduler.config)
    if args2.scheduler == 'UniPCMultistepScheduler':
        pipe2.scheduler = UniPCMultistepScheduler.from_config(pipe2.scheduler.config)

    if args2.offload == 0:
        pipe2.to("cuda")
    else:
        pipe2.enable_model_cpu_offload()

    prompt = set_prompt(0,args2.prompt)

    #generate initial frame
    sys.stdout.write("Generating image ...\n")
    sys.stdout.flush()
    latents = pipe(prompt=prompt,negative_prompt=args2.negative_prompt,width=args2.width,height=args2.height,num_inference_steps=args2.steps,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt,output_type='latent').images
    sys.stdout.write("Refining image ...\n")
    sys.stdout.flush()
    images = pipe2(prompt=prompt,negative_prompt=args2.negative_prompt,num_images_per_prompt=args2.num_images_per_prompt, image=latents,num_inference_steps=args2.steps,strength=args2.init_image_strength).images[0]
    
    #save first frame for color matching
    if args2.color_matching == 1:
        images.save(args2.frame_dir+"first_frame.png")
    
    #clear VRAM before loading upscale model
    sys.stdout.flush()
    sys.stdout.write('Clearing VRAM cache ...\n')
    sys.stdout.flush()
    del pipe
    torch.cuda.empty_cache()

    if args2.controlnet == 1:
        #setup controlnet pipe here
        base_model_path = "stabilityai/stable-diffusion-xl-base-1.0"
        controlnet_path = "diffusers/controlnet-canny-sdxl-1.0"
        sys.stdout.write(f"\nSetting up ControlNetModel ...\n")
        sys.stdout.flush()
        controlnet = ControlNetModel.from_pretrained(controlnet_path, torch_dtype=torch.float16)
        sys.stdout.write(f"Setting up StableDiffusionXLControlNetPipeline ...\n")
        sys.stdout.flush()
        pipe3 = StableDiffusionXLControlNetPipeline.from_pretrained(base_model_path, controlnet=controlnet, torch_dtype=torch.float16)
        # speed up diffusion process with faster scheduler and memory optimization
        pipe3.scheduler = UniPCMultistepScheduler.from_config(pipe3.scheduler.config)
        # remove following line if xformers is not installed or when using Torch 2.0.
        pipe3.enable_xformers_memory_efficient_attention()
        # memory optimization.
        pipe3.enable_model_cpu_offload()

    lastprompt = set_prompt(1,prompt)

    frames=1
    #run until user kills the script from VoC
    while (frames<(args2.total_frames+1)):

        #reset seed every frame? does this help temporal smoothness?
        #no, distorts/stretches center of frames
        #seed_everything(args2.seed)

        #process image
        sys.stdout.flush()
        sys.stdout.write('Image processing ...\n')
        sys.stdout.flush()

        #opencv needs the image converted to a numpy array for processing
        numpy_array = np.array(images)
        #print(f"***** array dtype = {numpy_array.dtype}")

        #rotate
        if args2.rotate != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Rotate {rotate_amounts[frames-1]}...\n')
            sys.stdout.flush()
            M = cv2.getRotationMatrix2D((args2.width // 2, args2.height // 2), rotate_amounts[frames-1], 1.0)
            numpy_array = cv2.warpAffine(numpy_array, M, (args2.width, args2.height))

        #pan x
        if args2.panx != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Pan X {panx_amounts[frames-1]}...\n')
            sys.stdout.flush()
            tx = panx_amounts[frames-1]
            ty = 0
            translation_matrix = np.array([[1, 0, tx],[0, 1, ty]], dtype=np.float32)
            numpy_array = cv2.warpAffine(src=numpy_array, M=translation_matrix, dsize=(args2.width, args2.height))

        #pan y
        if args2.pany != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Pan Y {pany_amounts[frames-1]}...\n')
            sys.stdout.flush()
            tx = 0
            ty = pany_amounts[frames-1]
            translation_matrix = np.array([[1, 0, tx],[0, 1, ty]], dtype=np.float32)
            numpy_array = cv2.warpAffine(src=numpy_array, M=translation_matrix, dsize=(args2.width, args2.height))

        #zoom before sharpening
        if args2.zoom_after_sharpen == 0:
            if args2.zoom != "0:1":
                sys.stdout.flush()
                sys.stdout.write(f'    Zoom {zoom_amounts[frames-1]} ...\n')
                sys.stdout.flush()
                if args2.width == args2.height:
                    numpy_array = zoom_at_square(numpy_array, zoom=zoom_amounts[frames-1])
                else:
                    numpy_array = zoom_at(numpy_array, zoom=zoom_amounts[frames-1])
        
        #contrast
        if args2.contrast != 1:
            sys.stdout.flush()
            sys.stdout.write(f'    Contrast {args2.contrast} ...\n')
            sys.stdout.flush()
            #https://stackoverflow.com/a/69884067/4237309
            contrast = args2.contrast
            brightness = int(round(255*(1-contrast)/2))
            numpy_array = cv2.addWeighted(numpy_array, contrast, numpy_array, 0, brightness)

        #sharpness
        if args2.sharpness != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    {args2.sharpness_method} Sharpen {args2.sharpness_radius} {args2.sharpness} ...\n')
            sys.stdout.flush()
            if args2.sharpness_method == "Gaussian" :
                numpy_array = unsharp_mask(numpy_array,amount=args2.sharpness)
            if args2.sharpness_method == "Laplacian" :
                numpy_array = unsharp_mask_2(numpy_array,strength=args2.sharpness,sigma=args2.sharpness_radius)

        #add noise
        if args2.noise != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Noise {args2.noise} ...\n')
            sys.stdout.flush()
            
            if args2.correct_noise == 0:
                noise = np.zeros(numpy_array.shape,np.uint8)
                cv2.randu(noise, -args2.noise/2, args2.noise/2)
                if args2.blur_noise == 1:
                    ksize = (args2.blur_noise_amount, args2.blur_noise_amount) 
                    noise = cv2.blur(noise,ksize)
            else:
                noise = np.random.randint(args2.noise, size=(numpy_array.shape)).astype(np.uint8)
                if args2.blur_noise == 1:
                    ksize = (args2.blur_noise_amount, args2.blur_noise_amount) 
                    noise = cv2.blur(noise,ksize)
            
            numpy_array = cv2.add(numpy_array, noise)
            #numpy_array = cv2.normalize(numpy_array,  numpy_array, 0, 255, cv2.NORM_MINMAX)
            
        #auto color equalize histogram RGB channel colors
        if args2.auto_color == 1:
            """
            b,g,r = cv2.split(numpy_array)
            b2 = cv2.equalizeHist(b)
            g2 = cv2.equalizeHist(g)
            r2 = cv2.equalizeHist(r)
            numpy_array = cv2.merge([b2,g2,r2])
            """
            # https://stackoverflow.com/a/38312281/4237309
            img_yuv = cv2.cvtColor(numpy_array, cv2.COLOR_BGR2YUV)
            # equalize the histogram of the Y channel
            img_yuv[:,:,0] = cv2.equalizeHist(img_yuv[:,:,0])
            # convert the YUV image back to RGB format
            numpy_array = cv2.cvtColor(img_yuv, cv2.COLOR_YUV2BGR)
            

        #zoom after sharpening
        if args2.zoom_after_sharpen == 1:
            if args2.zoom != "0:1":
                sys.stdout.flush()
                sys.stdout.write(f'    Zoom {zoom_amounts[frames-1]} ...\n')
                sys.stdout.flush()
                if args2.width == args2.height:
                    numpy_array = zoom_at_square(numpy_array, zoom=zoom_amounts[frames-1])
                else:
                    numpy_array = zoom_at(numpy_array, zoom=zoom_amounts[frames-1])

        #convert numpy array back to a pillow image
        images = PIL.Image.fromarray(numpy_array)

        #scale RGB values
        if args2.red_scale != 1 or args2.green_scale != 1 or args2.blue_scale !=1:
            sys.stdout.flush()
            sys.stdout.write(f'    Scaling RGB [{args2.red_scale},{args2.green_scale},{args2.blue_scale}] ...\n')
            sys.stdout.flush()
            Matrix = ( args2.red_scale, 0, 0, 0, 0, args2.green_scale, 0, 0, 0, 0, args2.blue_scale, 0) 
            images = images.convert("RGB", Matrix)

        #auto-contrast
        if args2.auto_contrast == 1:
            sys.stdout.flush()
            sys.stdout.write('    Auto contrast ...\n')
            sys.stdout.flush()
            images = PIL.ImageOps.autocontrast(images)
        #equalize
        if args2.equalize == 1:
            sys.stdout.flush()
            sys.stdout.write('    Equalize histogram ...\n')
            sys.stdout.flush()
            images = PIL.ImageOps.equalize(images)

        sys.stdout.flush()
        sys.stdout.write('Image processing complete\n')
        sys.stdout.flush()

        sys.stdout.flush()
        sys.stdout.write('Saving progress ...\n')
        sys.stdout.flush()
        images.save(args2.image_file)

        if args2.color_matching == 1:
            sys.stdout.flush()
            sys.stdout.write('Color matching ...\n')
            sys.stdout.flush()
            #color match frame to first frame
            img_ref = load_img_file(args2.frame_dir+"first_frame.png")
            img_src = load_img_file(args2.image_file)
            obj = ColorMatcher(src=img_src, ref=img_ref, method='HM-MVGD-HM')
            img_res = obj.main()
            mg_res = Normalizer(img_res).uint8_norm()
            save_img_file(img_res, args2.image_file)

        sys.stdout.flush()
        sys.stdout.write('Progress saved\n')
        sys.stdout.flush()

        sys.stdout.flush()
        sys.stdout.write('Saving movie frame ...\n')
        sys.stdout.flush()
        #save next movie FRA frame
        if args2.frame_dir is not None:
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

            if args2.color_matching == 0:
                images.save(save_name)
            if args2.color_matching == 1:
                save_img_file(img_res, save_name)
                images = load_image(save_name)

        end = datetime.datetime.now()

        if frames == 1:
            overall_start = datetime.datetime.now()
        if frames > 1:
            average_frame_time = (end-overall_start)/(frames-1)
            elapsed_time = end - script_start
            time_left = average_frame_time*(args2.total_frames-frames+1)
            sys.stdout.write(f'\nTime last frame = {end-start}')
            sys.stdout.write(f'\n   Time elapsed = {elapsed_time}')
            sys.stdout.write(f'\n Time remaining = {time_left}\n')


        start = datetime.datetime.now()
        frames=frames+1
        sys.stdout.write('\n')
        sys.stdout.write(f'Frame {frames}/{args2.total_frames} ...\n')
        sys.stdout.flush()

        prompt = set_prompt(frames,prompt)

        #need to change the random seed each frame for movement in the movies
        if args2.randomize_seed == 1:
            torch.random.manual_seed(args2.seed+frames)

        sys.stdout.flush()
        #sys.stdout.write('Generating frame ...\n')
        sys.stdout.write(f'"{prompt}"\n')
        sys.stdout.flush()
        #feed processed image in as init for next frame
        #initimage = images
        #images = pipe2(prompt=prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=images,num_inference_steps=args2.steps,strength=args2.init_image_strength, target_size=(args2.width,args2.height)).images[0]
        if frames % args2.render_every == 0:
            initimage = images
            if args2.hard_cuts == 0:
                images = pipe2(prompt=prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=images,num_inference_steps=args2.steps,strength=args2.init_image_strength, target_size=(args2.width,args2.height)).images[0]
            else:
                if prompt == lastprompt:
                   images = pipe2(prompt=prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=images,num_inference_steps=args2.steps,strength=args2.init_image_strength, target_size=(args2.width,args2.height)).images[0]
                else:
                   #reset seed back to original when doing a hard cut
                   torch.random.manual_seed(args2.seed)
                   images = pipe2(prompt=prompt,negative_prompt=args2.negative_prompt,guidance_scale=args2.guidance_scale,num_images_per_prompt=args2.num_images_per_prompt, image=images,num_inference_steps=args2.steps,strength=1.0, target_size=(args2.width,args2.height)).images[0]
                   lastprompt=prompt
        else:
            sys.stdout.write('\n')
            sys.stdout.write('Skipping rendering this frame\n')
            sys.stdout.flush()

##############################################################################################################################################################
# controlnet
##############################################################################################################################################################

        if args2.controlnet == 1:
            sys.stdout.write("\nControlNet ...\n")
            sys.stdout.flush()
            control_image = load_image("https://hf.co/datasets/hf-internal-testing/diffusers-images/resolve/main/sd_controlnet/hf-logo.png")
            #prompt = args2.prompt
            #generate image
            generator = torch.manual_seed(0)
            images = pipe3(prompt, num_inference_steps=20, generator=generator, image=control_image).images[0]
            #images.save("./output.png")


