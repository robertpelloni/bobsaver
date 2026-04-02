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
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Initializing prompt enhancer ...\n")
sys.stdout.flush()

# Prompt Enhancer
enhancer_medium = pipeline("summarization", model="gokaygokay/Lamini-fal-prompt-enchance", device=device)
enhancer_long = pipeline("summarization", model="gokaygokay/Lamini-Prompt-Enchance-Long", device=device)

# Prompt Enhancer function
def enhance_prompt(input_prompt, model_choice):
    if model_choice == "Medium":
        result = enhancer_medium("Enhance the description: " + input_prompt)
        enhanced_text = result[0]['summary_text']
        
    else:  # Long
        result = enhancer_long("Enhance the description: " + input_prompt)
        enhanced_text = result[0]['summary_text']
    
    return enhanced_text

sys.stdout.write("Enhancing prompt ...\n")
sys.stdout.flush()

prompt = enhance_prompt(args2.prompt,"Long")

sys.stdout.write(f"\n{prompt}\n")
sys.stdout.flush()
