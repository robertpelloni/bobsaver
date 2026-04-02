import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

from transformers import AutoProcessor, SeamlessM4Tv2Model
import torchaudio
import scipy
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_text", type=str, help="Text to translate")
    parser.add_argument("--input_audio", type=str, help="Audio to translate")
    parser.add_argument("--input_language", type=str, help="Language for input, blank for auto-detect")

    parser.add_argument("--output_text", type=int, help="0 = no, 1 = yes")
    parser.add_argument("--output_audio", type=int, help="0 = no, 1 = yes")
    parser.add_argument("--output_language", type=str, help="Language for output")
    
    parser.add_argument("--output_audio_from_audio", type=str, help="Output filename for audio output from audio")
    parser.add_argument("--output_text_from_audio", type=str, help="Output filename for text output from audio")
    parser.add_argument("--output_audio_from_text", type=str, help="Output filename for audio output from audio")
    parser.add_argument("--output_text_from_text", type=str, help="Output filename for text output from audio")
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading AutoProcessor ...\n")
sys.stdout.flush()

processor = AutoProcessor.from_pretrained("facebook/seamless-m4t-v2-large")

sys.stdout.write("Loading SeamlessM4Tv2Model ...\n")
sys.stdout.flush()

model = SeamlessM4Tv2Model.from_pretrained("facebook/seamless-m4t-v2-large")

def writeStringToFile(text, file_path):
    """
    Writes a string to a text file.

    Args:
        text (str): The string to be written to the file.
        file_path (str): The path to the output text file.
    """
    try:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(text)
        print(f"Text written to '{file_path}'.")
    except Exception as e:
        print(f"Error: {e}")

# from text
if args2.input_text is not None:
    sys.stdout.write("Translating text ...\n")
    sys.stdout.flush()
    text_inputs = processor(text = args2.input_text, src_lang=args2.input_language, return_tensors="pt")
    audio_array_from_text = model.generate(**text_inputs, tgt_lang=args2.output_language)[0].cpu().numpy().squeeze()
    if args2.output_audio is 1:
        sys.stdout.write(f"Saving output audio to {args2.output_audio_from_text} ...\n")
        sys.stdout.flush()
        sample_rate = model.config.sampling_rate
        scipy.io.wavfile.write(args2.output_audio_from_text, rate=sample_rate, data=audio_array_from_text)
    if args2.output_text is 1:
        sys.stdout.write(f"Saving output text to {args2.output_text_from_text}...\n")
        sys.stdout.flush()
        output_tokens = model.generate(**text_inputs, tgt_lang=args2.output_language, generate_speech=False)
        translated_text_from_text = processor.decode(output_tokens[0].tolist()[0], skip_special_tokens=True)
        writeStringToFile(translated_text_from_text, args2.output_text_from_text)

# from audio
if args2.input_audio is not None:
    sys.stdout.write("Translating audio ...\n")
    sys.stdout.flush()
    audio, orig_freq =  torchaudio.load(args2.input_audio)
    audio =  torchaudio.functional.resample(audio, orig_freq=orig_freq, new_freq=16_000) # must be a 16 kHz waveform array
    audio_inputs = processor(audios=audio, return_tensors="pt")
    audio_array_from_audio = model.generate(**audio_inputs, tgt_lang=args2.output_language)[0].cpu().numpy().squeeze()
    if args2.output_audio is 1:
        sys.stdout.write(f"Saving output audio to {args2.output_audio_from_audio} ...\n")
        sys.stdout.flush()
        sample_rate = model.config.sampling_rate
        scipy.io.wavfile.write(args2.output_audio_from_audio, rate=sample_rate, data=audio_array_from_audio)
    if args2.output_text is 1:
        sys.stdout.write(f"Saving output text to {args2.output_text_from_audio}...\n")
        sys.stdout.flush()
        output_tokens = model.generate(**audio_inputs, tgt_lang=args2.output_language, generate_speech=False)
        translated_text_from_text = processor.decode(output_tokens[0].tolist()[0], skip_special_tokens=True)
        #how do we save the text to a txt file here???!!
        writeStringToFile(translated_text_from_text, args2.output_text_from_audio)

sys.stdout.write("Done\n")
