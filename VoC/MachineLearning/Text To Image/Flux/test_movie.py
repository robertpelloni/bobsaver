# script by Jason Rampe https://softology/pro

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
from flux_pipeline import FluxImg2ImgPipeline
import numpy as np
import PIL
import cv2
from color_matcher import ColorMatcher
from color_matcher.io_handler import load_img_file, save_img_file, FILE_EXTS
from color_matcher.normalizer import Normalizer
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="Prompt")
    parser.add_argument("--guidance_scale", type=float, help="Guidance scale, default is 3.0")
    parser.add_argument("--w", type=int, help="Image width")
    parser.add_argument("--h", type=int, help="Image height")
    parser.add_argument("--steps", type=int, help="iterations")
    parser.add_argument("--render_every", type=int, help="render every n frames, otherwise just do the zoom - should be 1 by default")
    parser.add_argument("--seed", type=int, help="random seed")
    parser.add_argument("--frame_dir", type=str)
    
    parser.add_argument("--zoom", type=str, help="zoom string")
    parser.add_argument("--zoom_method", type=str, help="zoom method")
    parser.add_argument("--zoom_factor", type=float, help="zoom compensation factor")
    
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

#pipe = FluxImg2ImgPipeline.from_pretrained("black-forest-labs/FLUX.1-schnell", torch_dtype=torch.bfloat16)
pipe = FluxImg2ImgPipeline.from_pretrained("black-forest-labs/FLUX.1-schnell", torch_dtype=torch.bfloat16)
#pipe = FluxImg2ImgPipeline.from_pretrained("sayakpaul/FLUX.1-merged", torch_dtype=torch.bfloat16)
pipe.enable_model_cpu_offload()

max_frames = 100
output_dir = 'output'
#os.makedirs(output_dir, exist_ok=True)
image = None
seed = 0

for i in range(max_frames):

    sys.stdout.write(f'Generating frame {i} of {max_frames}\n')
    sys.stdout.write(f'Seed {seed}\n')
    sys.stdout.flush()

    if i==0:
        steps = 4
    else:
        steps = 40

    prompt = "cat sushi"
    generator = torch.Generator().manual_seed(seed)
    out = pipe(
        image=image,
        prompt=prompt,
        generator=generator,
        guidance_scale=3.5,
        strength=0.15,
        height=1024,
        width=1024,
        num_inference_steps=steps,
        max_sequence_length=256,
    ).images[0]

    sys.stdout.write('Saving frame\n')
    sys.stdout.flush()

    #save first frame for color matching
    if i==0:
        #args2.color_matching == 1:
        """
        #run one equalize histogram pass on the image to combat the tendency to be too darken
        #NO - too bright
        numpy_array = np.array(images)
        img_yuv = cv2.cvtColor(numpy_array, cv2.COLOR_BGR2YUV)
        # equalize the histogram of the Y channel
        img_yuv[:,:,0] = cv2.equalizeHist(img_yuv[:,:,0])
        # convert the YUV image back to RGB format
        numpy_array = cv2.cvtColor(img_yuv, cv2.COLOR_YUV2BGR)
        images = PIL.Image.fromarray(numpy_array)
        """
        output_path = os.path.join(output_dir,"first_frame.png")
        sys.stdout.write(f'Saving first frame {output_path}\n')
        sys.stdout.flush()
        out.save(output_path)

    #save frame
    output_path = os.path.join(output_dir, f"FRA{i:05d}.PNG")
    sys.stdout.write(f'Saving frame {output_path}\n')
    sys.stdout.flush()
    out.save(output_path)

    sys.stdout.write('Processing frame\n')
    sys.stdout.flush()

    #process frame
    numpy_array = np.array(out)
    numpy_array = zoom_at_square(numpy_array, zoom=1.05)
    
    #if args2.color_matching == 1:
    sys.stdout.flush()
    sys.stdout.write('Color matching ...\n')
    sys.stdout.flush()
    #color match frame to first frame
    img_ref = load_img_file(os.path.join(output_dir,"first_frame.png"))
    img_src = load_img_file(output_path)
    obj = ColorMatcher(src=img_src, ref=img_ref, method='HM-MVGD-HM')
    img_res = obj.main()
    mg_res = Normalizer(img_res).uint8_norm()
    save_img_file(img_res, output_path)
    
    
    #convert numpy array back to a pillow image
    image = PIL.Image.fromarray(numpy_array)
    #image_path = os.path.join(output_dir, f"zoomed_image_{i:05d}.jpg")
    #image.save(image_path)
    seed = seed + 1
