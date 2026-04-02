import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import torch
import whisper
from whisper.utils import get_writer
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--audio", type=str, help="audio file to run speeech recognition on")
    parser.add_argument("--model", type=str, help="tiny, base, small, medium, large")
    parser.add_argument("--task", type=str, help="transcribe, translate")
    parser.add_argument("--output", type=str, help="none, all, txt, vtt, srt, tsv, json")
    parser.add_argument("--output_directory", type=str, help="directory to output files into")
    parser.add_argument("--output_file", type=str, help="path to output file without extension")
    parser.add_argument("--language", type=str, help="source audio language")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write(f"Loading {args2.model} model ...\n")
sys.stdout.flush()

model = whisper.load_model(args2.model)

if args2.task == "transcribe":

	sys.stdout.write("Running speech recognition ...\n")
	sys.stdout.flush()

	if args2.language == '':
		result = model.transcribe(args2.audio, verbose=True)
	else:
		result = model.transcribe(args2.audio, verbose=True, language=args2.language)

	sys.stdout.write("Detected speech;\n\n")
	sys.stdout.flush()

	print(result["text"].encode('utf-8'))

	if args2.output != 'none':
		sys.stdout.write("\nSaving output ...\n")
		sys.stdout.flush()

		# Save output
		output_format=args2.output
		whisper.utils.get_writer(
			output_format=args2.output,
			output_dir=args2.output_directory
		)(
			result,
			str(args2.output_file) + str(args2.output),
			options=dict(
				highlight_words=False,
				max_line_count=None,
				max_line_width=None,
			)
		)
	


if args2.task == "translate":

	sys.stdout.write("Translating audio ...\n")
	sys.stdout.flush()

	if args2.language == '':
		options = dict(beam_size=5, best_of=5,  verbose=True)
	else:
		options = dict(language=args2.language, beam_size=5, best_of=5,  verbose=True)

	translate_options = dict(task="translate", **options)
	translation = model.transcribe(args2.audio, **translate_options)

	sys.stdout.write("Translated audio in English;\n\n")
	sys.stdout.flush()

	print(translation["text"].encode('utf-8'))

	if args2.output != 'none':
		sys.stdout.write("\nSaving output ...\n")
		sys.stdout.flush()

		# Save output
		output_format=args2.output
		whisper.utils.get_writer(
			output_format=args2.output,
			output_dir=args2.output_directory
		)(
			translation,
			str(args2.output_file) + str(args2.output),
			options=dict(
				highlight_words=False,
				max_line_count=None,
				max_line_width=None,
			)
		)

