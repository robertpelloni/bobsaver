import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from bark import SAMPLE_RATE, generate_audio
import numpy as np
from scipy.io import wavfile
from pydub import AudioSegment
from scipy.io.wavfile import write as write_wav
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--output_wav", type=str, help="output file")
    parser.add_argument("--history", type=str)
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Generating audio ...\n")
sys.stdout.flush()

#VOC START - DO NOT DELETE
#VOC FINISH - DO NOT DELETE

audio_array = generate_audio(text_prompt, history_prompt=args2.history)
#audio_array = generate_audio(text_prompt, history_prompt="en_speaker_1")

#Audio(audio_array, rate=SAMPLE_RATE)

sys.stdout.write("Saving audio ...\n")
sys.stdout.flush()

write_wav(args2.output_wav, SAMPLE_RATE, audio_array)

sys.stdout.write("Done\n")
sys.stdout.flush()
