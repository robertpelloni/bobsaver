# knnvc_demo.ipynb
# Original file is located at https://colab.research.google.com/github/bshall/knn-vc/blob/master/knnvc_demo.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch, torchaudio
import os
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=str)
    parser.add_argument("--output", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()



knn_vc = torch.hub.load('bshall/knn-vc', 'knn_vc', prematched=True, trust_repo=True, pretrained=True, device='cuda')

# path to 16kHz, single-channel, source waveform
src_wav_path = args2.source
# list of paths to all reference waveforms (each must be 16kHz, single-channel) from the target speaker
ref_wav_paths = ['D:\zoe 16khz.wav',]

query_seq = knn_vc.get_features(src_wav_path)
matching_set = knn_vc.get_matching_set(ref_wav_paths)

out_wav = knn_vc.match(query_seq, matching_set, topk=4)

torchaudio.save(args2.output, out_wav[None], 16000)
