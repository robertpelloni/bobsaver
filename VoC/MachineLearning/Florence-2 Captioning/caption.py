import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import requests
import torch
import flash_attn
import numpy as np
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

sys.stdout.write("Initializing Florence model ...\n")
sys.stdout.flush()

# Initialize Florence model
florence_model = AutoModelForCausalLM.from_pretrained('microsoft/Florence-2-base', trust_remote_code=True).to(device).eval()
florence_processor = AutoProcessor.from_pretrained('microsoft/Florence-2-base', trust_remote_code=True)

# Florence caption function
def florence_caption(image):
    # Convert image to PIL if it's not already
    if not isinstance(image, Image.Image):
        image = Image.fromarray(image)
    
    inputs = florence_processor(text=args2.task, images=image, return_tensors="pt").to(device)
    generated_ids = florence_model.generate(
        input_ids=inputs["input_ids"],
        pixel_values=inputs["pixel_values"],
        max_new_tokens=1024,
        early_stopping=False,
        do_sample=False,
        num_beams=3,
    )
    generated_text = florence_processor.batch_decode(generated_ids, skip_special_tokens=False)[0]
    parsed_answer = florence_processor.post_process_generation(
        generated_text,
        task=args2.task,#"<MORE_DETAILED_CAPTION>",
        image_size=(image.width, image.height)
    )
    return parsed_answer[args2.task]

sys.stdout.write("Captioning image ...\n")
sys.stdout.flush()

#url = "https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/transformers/tasks/car.jpg?download=true"
#image = Image.open(requests.get(url, stream=True).raw)
image = Image.open(args2.image)
prompt = florence_caption(image)

sys.stdout.write(f"\n{prompt}\n")
sys.stdout.flush()
