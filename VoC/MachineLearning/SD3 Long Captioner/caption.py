import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import requests
import torch
import flash_attn
import numpy as np
import re
from PIL import Image
from transformers import PaliGemmaForConditionalGeneration, PaliGemmaProcessor, pipeline
from transformers import AutoProcessor, AutoModelForCausalLM


#device = "cuda:0" if torch.cuda.is_available() else "cpu"

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", type=str)
    parser.add_argument("--task", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Initializing long captioner ...\n")
sys.stdout.flush()

# VLM Captioner
vlm_model = PaliGemmaForConditionalGeneration.from_pretrained("gokaygokay/sd3-long-captioner-v2").to(device).eval()
vlm_processor = PaliGemmaProcessor.from_pretrained("gokaygokay/sd3-long-captioner-v2")

# Helper function for caption modification
def modify_caption(caption: str) -> str:
    prefix_substrings = [
        ('captured from ', ''),
        ('captured at ', '')
    ]
    pattern = '|'.join([re.escape(opening) for opening, _ in prefix_substrings])
    replacers = {opening: replacer for opening, replacer in prefix_substrings}
    
    def replace_fn(match):
        return replacers[match.group(0)]
    
    return re.sub(pattern, replace_fn, caption, count=1, flags=re.IGNORECASE)

# VLM Captioner function
def create_captions_rich(image):
    prompt = "caption en"
    model_inputs = vlm_processor(text=prompt, images=image, return_tensors="pt").to(device)
    input_len = model_inputs["input_ids"].shape[-1]

    with torch.inference_mode():
        generation = vlm_model.generate(**model_inputs, repetition_penalty=1.10, max_new_tokens=256, do_sample=False)
        generation = generation[0][input_len:]
        decoded = vlm_processor.decode(generation, skip_special_tokens=True)

    return modify_caption(decoded)

sys.stdout.write("Captioning image ...\n")
sys.stdout.flush()

#url = "https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/transformers/tasks/car.jpg?download=true"
#image = Image.open(requests.get(url, stream=True).raw)
image = Image.open(args2.image)
prompt = create_captions_rich(image)

sys.stdout.write(f"\n{prompt}\n")
sys.stdout.flush()
