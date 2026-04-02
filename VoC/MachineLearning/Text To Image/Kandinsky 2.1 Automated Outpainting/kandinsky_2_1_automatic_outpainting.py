# Kandinsky 2.1 Automatic Outpainting + Batching in Google Drive + Dynamic Prompting.ipynb
# Original file is located at https://colab.research.google.com/drive/1e9jGVEGnvSaHqKdjzehhzSz-d4kRRYVh

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
from kandinsky2 import get_kandinsky2
import os
import random
from PIL import Image
import time
import numpy as np
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt")
    parser.add_argument("--outpainting_prompt")
    parser.add_argument("--num_steps", type=int)
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--guidance_scale", type=int)
    parser.add_argument("--w", type=int)
    parser.add_argument("--h", type=int)
    parser.add_argument("--outw", type=int)
    parser.add_argument("--outh", type=int)
    parser.add_argument("--prior_cf_scale", type=int)
    parser.add_argument("--prior_steps", type=str)
    parser.add_argument("--sampler", type=str)
    parser.add_argument("--model_version", type=str)
    parser.add_argument("--position", type=str)
    parser.add_argument("--image_file", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write(f"Loading models ...\n")
sys.stdout.flush()

# Models
if args2.model_version=='2':
    model = get_kandinsky2('cuda', task_type='text2img', cache_dir='../../.cache/kandinsky2', use_flash_attention=False)
    model_inpaint = get_kandinsky2('cuda', task_type='inpainting', use_flash_attention=False)
else:
    model = get_kandinsky2('cuda', task_type='text2img', cache_dir='../../.cache/kandinsky2', model_version='2.1', use_flash_attention=False)
    model_inpaint = get_kandinsky2('cuda', task_type='inpainting', model_version='2.1', use_flash_attention=False)

#@title Settings & Prompt 
batch_name = "Batch" #@param {type:"string"}
width_height = [args2.w, args2.h] #@param {type: 'raw'}
text_prompt = args2.prompt #@param {type:"string"}
num_steps = args2.num_steps #@param {type:"integer"}
batch_size = 1 #@param {type:"integer"}
guidance_scale = args2.guidance_scale #@param {type:"number"}
sampler = args2.sampler #'p_sampler' #@param {type:"string"}
prior_cf_scale = args2.prior_cf_scale #@param {type:"number"}
prior_steps = args2.prior_steps #@param {type:"string"}

w, h = width_height

#@title Automatic Outpainting Checkbox
automatic_outpainting = True #@param {type:"boolean"}

if automatic_outpainting:
    outpaint_width_height = [args2.outw, args2.outh] #@param {type: 'raw'}
    outpaint_prompt = args2.outpainting_prompt #@param {type:"string"}
    new_w, new_h = outpaint_width_height
    main_image_position = args2.position #'center' #@param ["left", "center", "right"]

#@title Images Generation
import os
import random
import numpy as np
from PIL import Image
#from IPython.display import display, clear_output
import time

def generate_dynamic_prompt(prompt):
    while "{" in prompt and "}" in prompt:
        start = prompt.index("{")
        end = prompt.index("}")
        options_str = prompt[start + 1:end]
        options = options_str.split("|")
        choice = random.choice(options).strip()
        prompt = prompt[:start] + choice + prompt[end + 1:]
    return prompt

output_folder = "./"
os.makedirs(output_folder, exist_ok=True)

num_images = batch_size  # The total number of images to generate

for i in range(num_images):
    dynamic_prompt = generate_dynamic_prompt(text_prompt)
    print(f"Generating image {i + 1} with prompt: {dynamic_prompt}")  # Print the generated prompt
    main_images = model.generate_text2img(dynamic_prompt, num_steps=num_steps,
                                     batch_size=1, guidance_scale=guidance_scale,
                                     h=h, w=w, sampler=sampler, prior_cf_scale=prior_cf_scale,
                                     prior_steps=prior_steps)

    # Save main generated image to Google Drive
    main_img_filename = f"{dynamic_prompt.replace(',', '').replace(' ', '_')}_main_{i}.png"
    main_img_path = os.path.join(output_folder, main_img_filename)
    main_image = main_images[0]
    #main_image.save(main_img_path)
    #print(f"Main image {i + 1} saved to Google Drive at: {main_img_path}")

    sys.stdout.write("Saving image ...\n")
    sys.stdout.flush()
    main_image.save(args2.image_file)
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

    # Display main image
    #display(main_image)

    if automatic_outpainting:
        print(f"Outpainting image {i + 1} with prompt: {outpaint_prompt}")
        # Create the mask
        mask = np.zeros((new_h, new_w), dtype=np.float32)

        if main_image_position == 'left':
            mask[:, :w] = 1  # preserve the left part
            paste_position = (0, 0)
        elif main_image_position == 'center':
            mask[:, (new_w-w)//2:(new_w+w)//2] = 1  # preserve the center part
            paste_position = ((new_w-w)//2, 0)
        else:  # 'right'
            mask[:, -w:] = 1  # preserve the right part
            paste_position = (new_w - w, 0)

        # Create a canvas with the main image and outpaint_prompt on the sides
        canvas = Image.new('RGB', (new_w, new_h))
        canvas.paste(main_image, paste_position)
        
        # Generate the outpainted image
        outpaint_images = model_inpaint.generate_inpainting(outpaint_prompt, canvas, mask, num_steps=num_steps,
                                          batch_size=1, guidance_scale=guidance_scale,
                                          h=new_h, w=new_w, sampler=sampler,  # here, w should be new_w
                                          prior_cf_scale=prior_cf_scale, prior_steps=prior_steps)

        # Save outpainted image to Google Drive
        outpaint_img_filename = f"{dynamic_prompt.replace(',', '').replace(' ', '_')}_outpaint_{i}.png"
        outpaint_img_path = os.path.join(output_folder, outpaint_img_filename)
        outpaint_image = outpaint_images[0]
        #outpaint_image.save(outpaint_img_path)
        #print(f"Outpainted image {i + 1} saved to Google Drive at: {outpaint_img_path}")

        sys.stdout.write("Saving image ...\n")
        sys.stdout.flush()
        outpaint_image.save(args2.image_file)
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()

        # Display outpainted image
        #display(outpaint_image)
    
"""
    # Clear output after every 10 images (or image pairs if outpainting is enabled)
    if (i + 1) % 10 == 0:
        time.sleep(1)
        clear_output(wait=True)
"""