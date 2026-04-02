import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from parler_tts import ParlerTTSForConditionalGeneration
from transformers import AutoTokenizer, AutoFeatureExtractor, set_seed
import scipy

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_text", type=str)
    parser.add_argument("--description", type=str)
    parser.add_argument("--model", type=str)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--output_wav", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Setting up ParlerTTSForConditionalGeneration ...\n")
sys.stdout.flush()

repo_id = args2.model #"parler-tts/parler-tts-mini-v1"
model = ParlerTTSForConditionalGeneration.from_pretrained(repo_id).to("cuda")

sys.stdout.write("Setting up AutoTokenizer ...\n")
sys.stdout.flush()

tokenizer = AutoTokenizer.from_pretrained(repo_id, padding_side="left")

sys.stdout.write("Setting up AutoFeatureExtractor ...\n")
sys.stdout.flush()

feature_extractor = AutoFeatureExtractor.from_pretrained(repo_id)

sys.stdout.write("Tokenizing inputs ...\n")
sys.stdout.flush()

input_text = [args2.input_text]
description = [args2.description]

inputs = tokenizer(description, return_tensors="pt", padding=True).to("cuda")
prompt = tokenizer(input_text, return_tensors="pt", padding=True).to("cuda")

sys.stdout.write("Generating speech ...\n")
sys.stdout.flush()

set_seed(args2.seed)
generation = model.generate(
    input_ids=inputs.input_ids,
    attention_mask=inputs.attention_mask,
    prompt_input_ids=prompt.input_ids,
    prompt_attention_mask=prompt.attention_mask,
    do_sample=True,
    return_dict_in_generate=True,
)

sys.stdout.write(f"Saving {args2.output_wav} ...\n")
sys.stdout.flush()

audio_chunk = generation.sequences[0, :generation.audios_length[0]]
scipy.io.wavfile.write(args2.output_wav, rate=feature_extractor.sampling_rate, data=audio_chunk.cpu().numpy().squeeze())

sys.stdout.write("Done\n")
sys.stdout.flush()


