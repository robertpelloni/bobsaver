# script by Jason Rampe https://softology/pro

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import datetime

script_start = datetime.datetime.now()

#from pytorch_lightning import seed_everything
#from diffusers import DiffusionPipeline
#from diffusers import AutoPipelineForImage2Image
from diffusers.utils import load_image, make_image_grid
#from diffusers import DDIMScheduler, DDPMScheduler, DEISMultistepScheduler, DPMSolverMultistepScheduler, DPMSolverSDEScheduler, DPMSolverSinglestepScheduler, EulerAncestralDiscreteScheduler, EulerDiscreteScheduler, HeunDiscreteScheduler, KDPM2AncestralDiscreteScheduler, KDPM2DiscreteScheduler, LMSDiscreteScheduler, PNDMScheduler, UniPCMultistepScheduler
#from diffusers import  KolorsPipeline, KolorsImg2ImgPipeline
from diffusers import AutoPipelineForText2Image, AutoPipelineForImage2Image
import torch
import argparse
import numpy as np
import cv2
import PIL
from PIL import Image, ImageEnhance
from tweening import linear, easeInOutQuad, easeInOutCubic, easeInOutQuart, easeInOutQuint, easeInOutPoly, easeInOutSine, easeInOutExpo, easeInOutCirc, easeInOutElastic
from scipy.ndimage.filters import median_filter
from color_matcher import ColorMatcher
from color_matcher.io_handler import load_img_file, save_img_file, FILE_EXTS
from color_matcher.normalizer import Normalizer

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="Prompt")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--guidance_scale", type=float, help="Guidance scale, default is 3.0")
    parser.add_argument("--w", type=int, help="Image width")
    parser.add_argument("--h", type=int, help="Image height")
    parser.add_argument("--steps", type=int, help="iterations")
    parser.add_argument("--render_every", type=int, help="render every n frames, otherwise just do the zoom - should be 1 by default")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--image_file", type=str)
    parser.add_argument("--process_video", type=str, help="path to the video frames to process")
    
    parser.add_argument("--model", type=str, help="model version v2 or v2.5")
    parser.add_argument("--lora", type=str, help="safetensors filename")
    parser.add_argument("--lora_weight", type=float, help="lora weight")
    parser.add_argument("--img2img_model", type=str, help="safetensors filename")
    parser.add_argument("--scheduler", type=str, help="which scheduler to use")
    #parser.add_argument("--img2img", type=int, help="use the refining img2img pass 0 no 1 yes") # no longer used, refine is always on
    parser.add_argument("--num_images_per_prompt", type=int, help="images per prompt")
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
    parser.add_argument("--blur_noise_amount", type=int, help="blur kernel size")
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
    parser.add_argument("--hidiffusion", type=int, help="0 no 1 yes")
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

if args2.offload == 0:
    sys.stdout.flush()
    sys.stdout.write('Offload = 0\n')
    sys.stdout.flush()
else:
    sys.stdout.flush()
    sys.stdout.write('Offload = 1\n')
    sys.stdout.flush()

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
        #result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4, borderMode = cv2.BORDER_REFLECT)
        #result = cv2.warpAffine(img, rot_mat, img.shape[1::-1], flags=cv2.INTER_LANCZOS4, borderMode = cv2.BORDER_TRANSPARENT)
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
    """Return a sharpened version of the image, using an unsharp mask."""
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

prompts = [
#VOC START - DO NOT DELETE
    "0:hyperrealistic surrealist alien biomechanical imagery by Giger",
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

    #image = None
    
    #setup base model for initial pass
    sys.stdout.write(f"Setting up AutoPipelineForText2Image ...\n")
    sys.stdout.flush()
    
    """
    pipe = KolorsPipeline.from_pretrained(
        "Kwai-Kolors/Kolors-diffusers",
        torch_dtype=torch.float16,
        variant="fp16"
        )
    if args2.offload == 0:
        pipe.to("cuda")
    else:
        pipe.enable_model_cpu_offload()
    """
    
    pipe = AutoPipelineForText2Image.from_pretrained(
        "kandinsky-community/kandinsky-3",
        variant="fp16",
        torch_dtype=torch.float16
        )
    if args2.offload == 0:
        pipe.to("cuda")
    else:
        pipe.enable_model_cpu_offload()
    
    #prompt = set_prompt(0,args2.prompt)
    prompt = set_prompt(0,args2.prompt)

    #generate initial frame

    sys.stdout.flush()
    sys.stdout.write('Generating initial image ...\n')
    sys.stdout.write(f'"{prompt}"\n')
    sys.stdout.flush()
    
    #generator = torch.Generator().manual_seed(args2.seed)
    images = pipe(
        prompt=prompt,
        negative_prompt=args2.negative_prompt,
        guidance_scale=args2.guidance_scale, #5.0,
        num_inference_steps=args2.steps, #50,
        width=args2.w,
        height=args2.h,
        generator=torch.Generator(pipe.device).manual_seed(args2.seed),
    ).images[0]

    #save first frame for color matching
    if args2.color_matching == 1:
        images.save(args2.frame_dir+"first_frame.png")
        #images = load_image(args2.frame_dir+"first_frame.png")
    lastprompt = set_prompt(1,prompt)

    #steps = int(args2.steps*(1/args2.init_image_strength))
    steps = args2.steps

    sys.stdout.flush()
    sys.stdout.write('Deleting AutoPipelineForText2Image ...\n')
    sys.stdout.flush()
    del pipe
    #clear VRAM before loading upscale model
    sys.stdout.flush()
    sys.stdout.write('Clearing VRAM cache ...\n')
    sys.stdout.flush()
    torch.cuda.empty_cache()

    #setup img2img model
    sys.stdout.write(f"Setting up AutoPipelineForImage2Image ...\n")
    sys.stdout.flush()
    
    """
    pipe2 = KolorsImg2ImgPipeline.from_pretrained(
        "Kwai-Kolors/Kolors-diffusers",
        torch_dtype=torch.float16,
        variant="fp16"
        )
    """
    
    pipe2 = AutoPipelineForImage2Image.from_pretrained(
        "kandinsky-community/kandinsky-3",
        variant="fp16",
        torch_dtype=torch.float16
        )
    
    if args2.offload == 0:
        pipe2.to("cuda")
    else:
        pipe2.enable_model_cpu_offload()


    frames=1
    #run until user kills the script from VoC
    while (frames<(args2.total_frames)):

        #process image
        sys.stdout.flush()
        sys.stdout.write('Image processing ...\n')
        sys.stdout.flush()

        #opencv needs the image converted to a numpy array for processing
        #sys.stdout.write(f"type(images)={type(images)}\n")
        #sys.stdout.flush()
        numpy_array = np.array(images)
        #sys.stdout.write(f"type(numpy_array)={type(numpy_array)}\n")
        #sys.stdout.flush()
        #numpy_array = images

        #rotate
        if rotate_amounts[frames-1] != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Rotate {rotate_amounts[frames-1]}...\n')
            sys.stdout.flush()
            M = cv2.getRotationMatrix2D((args2.w // 2, args2.h // 2), rotate_amounts[frames-1], 1.0)
            numpy_array = cv2.warpAffine(numpy_array, M, (args2.w, args2.h))

        #pan x
        if panx_amounts[frames-1] != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Pan X {panx_amounts[frames-1]}...\n')
            sys.stdout.flush()
            tx = panx_amounts[frames-1]
            ty = 0
            translation_matrix = np.array([[1, 0, tx],[0, 1, ty]], dtype=np.float32)
            numpy_array = cv2.warpAffine(src=numpy_array, M=translation_matrix, dsize=(args2.w, args2.h))

        #pan y
        if pany_amounts[frames-1] != 0:
            sys.stdout.flush()
            sys.stdout.write(f'    Pan Y {pany_amounts[frames-1]}...\n')
            sys.stdout.flush()
            tx = 0
            ty = pany_amounts[frames-1]
            translation_matrix = np.array([[1, 0, tx],[0, 1, ty]], dtype=np.float32)
            numpy_array = cv2.warpAffine(src=numpy_array, M=translation_matrix, dsize=(args2.w, args2.h))

        #zoom before sharpening
        if args2.zoom_after_sharpen == 0:
            #if args2.zoom != "0:1":
            if zoom_amounts[frames-1] != 1:
                sys.stdout.flush()
                sys.stdout.write(f'    Zoom {zoom_amounts[frames-1]} ...\n')
                sys.stdout.flush()
                if args2.w == args2.h:
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
            #numpy_array = unsharp_mask(numpy_array,amount=args2.sharpness)
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
                if args2.w == args2.h:
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
        
        sys.stdout.flush()
        #sys.stdout.write('Generating frame ...\n')
        sys.stdout.write(f'"{prompt}"\n')
        sys.stdout.flush()
        #feed processed image in as init for next frame
        if frames % args2.render_every == 0:
            initimage = images
            if args2.hard_cuts == 0:
                if args2.randomize_seed == 1:
                    seed = args2.seed+frames
                else:
                    seed = args2.seed
                sys.stdout.write(f'Seed {seed}\n')
                sys.stdout.flush()
                images = pipe2(
                    prompt=prompt,
                    negative_prompt=args2.negative_prompt,
                    guidance_scale=args2.guidance_scale,
                    num_inference_steps=steps,
                    #width=args2.w,
                    #height=args2.h,
                    image=images,
                    strength=args2.init_image_strength,
                    generator=torch.Generator(pipe2.device).manual_seed(seed),
                ).images[0]
            else:
                if prompt == lastprompt:
                   if args2.randomize_seed == 1:
                       seed = args2.seed+frames
                   else:
                       seed = args2.seed
                   sys.stdout.write(f'Seed {seed}\n')
                   sys.stdout.flush()
                   images = pipe2(
                       prompt=prompt,
                       negative_prompt=args2.negative_prompt,
                       guidance_scale=args2.guidance_scale,
                       num_inference_steps=steps,
                       width=args2.w,
                       height=args2.h,
                       image=images,
                       strength=args2.init_image_strength,
                       generator=torch.Generator(pipe2.device).manual_seed(seed),
                   ).images[0]
                else:
                   #reset seed back to original when doing a hard cut
                   #torch.random.manual_seed(args2.seed)
                   seed = args2.seed
                   sys.stdout.write(f'Seed {seed}\n')
                   sys.stdout.flush()
                   images = pipe2(
                       prompt=prompt,
                       negative_prompt=args2.negative_prompt,
                       guidance_scale=args2.guidance_scale,
                       num_inference_steps=steps,
                       width=args2.w,
                       height=args2.h,
                       image=images,
                       strength=args2.init_image_strength,
                       generator=torch.Generator(pipe2.device).manual_seed(seed),
                   ).images[0]
                  
                   lastprompt=prompt
        else:
            sys.stdout.write('\n')
            sys.stdout.write('Skipping rendering this frame\n')
            sys.stdout.flush()
