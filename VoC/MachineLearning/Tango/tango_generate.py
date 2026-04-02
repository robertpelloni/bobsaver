import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import soundfile as sf
from tango import Tango
import torch 
import os

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str)
    parser.add_argument("--output", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Initializing Tango ...\n")
sys.stdout.flush()

tango = Tango("declare-lab/tango")
prompt = args2.prompt #"An audience cheering and clapping"

sys.stdout.write("Generating audio ...\n")
sys.stdout.flush()

audio = tango.generate(prompt, steps=200, disable_progress=False)

sys.stdout.write("Saving audio ...\n")
sys.stdout.flush()

sf.write(args2.output, audio, samplerate=16000)

sys.stdout.write("Done\n")
sys.stdout.flush()
