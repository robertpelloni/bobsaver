import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from transformers import T5Tokenizer, T5ForConditionalGeneration
import argparse
import torch

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="Prompt")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()


sys.stdout.write("Setting tokenizer ...\n")
sys.stdout.flush()

tokenizer = T5Tokenizer.from_pretrained("google/flan-t5-small")

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

model = T5ForConditionalGeneration.from_pretrained("roborovski/superprompt-v1", device_map="auto")

sys.stdout.write("Running tokenizer ...\n")
sys.stdout.flush()

input_text = args2.prompt
input_ids = tokenizer(input_text, return_tensors="pt").input_ids.to("cuda")

outputs = model.generate(input_ids, max_new_tokens=1000)
print(tokenizer.decode(outputs[0]))

sys.stdout.write("Done\n")
sys.stdout.flush()

