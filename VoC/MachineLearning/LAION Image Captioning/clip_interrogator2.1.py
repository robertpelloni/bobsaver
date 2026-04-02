#clip_interrogator v2.1
#Original file is located at https://colab.research.google.com/github/pharmapsychotic/clip-interrogator/blob/main/clip_interrogator.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#@title Setup
import os, subprocess

sys.path.append('BLIP')
sys.path.append('clip-interrogator-2-1')

from clip_interrogator import Config, Interrogator
from PIL import Image
import argparse
import torch

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--image', type=str, help='Image to generate caption for.')
  parser.add_argument('--mode', type=str)
  parser.add_argument('--model', type=str)
  args = parser.parse_args()
  return args

args2=parse_args();


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()




config = Config()
config.blip_num_beams = 64
config.blip_offload = False
config.chunk_size = 2048
config.flavor_intermediate_count = 2048
best_max_flavors=32

ci = Interrogator(config)

ci.config.clip_model_name = args2.model
ci.load_clip_model()

image_url = args2.image
if str(image_url).startswith('http://') or str(image_url).startswith('https://'):
    image = Image.open(requests.get(image_url, stream=True).raw).convert('RGB')
else:
    image = Image.open(image_url).convert('RGB')



if args2.mode == 'best':
    output=ci.interrogate(image, max_flavors=int(best_max_flavors))
if args2.mode == 'classic':
    output=ci.interrogate_classic(image)
if args2.mode == 'fast':
    output=ci.interrogate_fast(image)

sys.stdout.write(f'\n{output}')

"""
#@title Batch process a folder of images 📁 -> 📝

#@markdown This will generate prompts for every image in a folder and either save results 
#@markdown to a desc.csv file in the same folder or rename the files to contain their prompts.
#@markdown The renamed files work well for [DreamBooth extension](https://github.com/d8ahazard/sd_dreambooth_extension)
#@markdown in the [Stable Diffusion Web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui).
#@markdown You can use the generated csv in the [Stable Diffusion Finetuning](https://colab.research.google.com/drive/1vrh_MUSaAMaC5tsLWDxkFILKJ790Z4Bl?usp=sharing)

import csv
import os
from IPython.display import clear_output, display
from PIL import Image
from tqdm import tqdm

folder_path = "/content/my_images" #@param {type:"string"}
prompt_mode = 'best' #@param ["best","fast"]
output_mode = 'rename' #@param ["desc.csv","rename"]
max_filename_len = 128 #@param {type:"integer"}
best_max_flavors = 16 #@param {type:"integer"}


def sanitize_for_filename(prompt: str, max_len: int) -> str:
    name = "".join(c for c in prompt if (c.isalnum() or c in ",._-! "))
    name = name.strip()[:(max_len-4)] # extra space for extension
    return name

ci.config.quiet = True

files = [f for f in os.listdir(folder_path) if f.endswith('.jpg') or f.endswith('.png')] if os.path.exists(folder_path) else []
prompts = []
for idx, file in enumerate(tqdm(files, desc='Generating prompts')):
    if idx > 0 and idx % 100 == 0:
        clear_output(wait=True)

    image = Image.open(os.path.join(folder_path, file)).convert('RGB')
    prompt = inference(image, prompt_mode, best_max_flavors=best_max_flavors)
    prompts.append(prompt)

    print(prompt)
    thumb = image.copy()
    thumb.thumbnail([256, 256])
    display(thumb)

    if output_mode == 'rename':
        name = sanitize_for_filename(prompt, max_filename_len)
        ext = os.path.splitext(file)[1]
        filename = name + ext
        idx = 1
        while os.path.exists(os.path.join(folder_path, filename)):
            print(f'File {filename} already exists, trying {idx+1}...')
            filename = f"{name}_{idx}{ext}"
            idx += 1
        os.rename(os.path.join(folder_path, file), os.path.join(folder_path, filename))

if len(prompts):
    if output_mode == 'desc.csv':
        csv_path = os.path.join(folder_path, 'desc.csv')
        with open(csv_path, 'w', encoding='utf-8', newline='') as f:
            w = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
            w.writerow(['image', 'prompt'])
            for file, prompt in zip(files, prompts):
                w.writerow([file, prompt])

        print(f"\n\n\n\nGenerated {len(prompts)} prompts and saved to {csv_path}, enjoy!")
    else:
        print(f"\n\n\n\nGenerated {len(prompts)} prompts and renamed your files, enjoy!")
else:
    print(f"Sorry, I couldn't find any images in {folder_path}")
"""