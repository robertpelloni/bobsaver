import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from basic_pitch.inference import predict_and_save
from basic_pitch import ICASSP_2022_MODEL_PATH, note_creation as infer
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--input_mp3", type=str)
    parser.add_argument("--output_directory", type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

"""
audio_path_list: List of file paths for the audio to run inference on.
output_directory: Directory to output MIDI and all other outputs derived from the model to.
save_midi: True to save midi.
sonify_midi: Whether or not to render audio from the MIDI and output it to a file.
save_model_outputs: True to save contours, onsets and notes from the model prediction.
save_notes: True to save note events.
model_path: Path to load the Keras saved model from. Can be local or on GCS.
onset_threshold: Minimum energy required for an onset to be considered present.
frame_threshold: Minimum energy requirement for a frame to be considered present.
minimum_note_length: The minimum allowed note length in frames.
minimum_freq: Minimum allowed output frequency, in Hz. If None, all frequencies are used.
maximum_freq: Maximum allowed output frequency, in Hz. If None, all frequencies are used.
multiple_pitch_bends: If True, allow overlapping notes in midi file to have pitch bends.
melodia_trick: Use the melodia post-processing step.
debug_file: An optional path to output debug data to. Useful for testing/verification.
sonification_samplerate: Sample rate for rendering audio from MIDI.
"""

predict_and_save(
    [args2.input_mp3],
    args2.output_directory,
#VOC START - DO NOT DELETE
    True,
    False,
    False,
    False,
	ICASSP_2022_MODEL_PATH,
    0.5,
    0.3,
    58,
    None,
    None,
    False,
    True,
	False,
    44100,
    120,
#VOC FINISH - DO NOT DELETE
)
