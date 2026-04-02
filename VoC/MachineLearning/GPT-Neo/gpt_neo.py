# Original file is located at https://colab.research.google.com/drive/1KDNsA0EpofIMEpd64hJCpxGhpa2lEOsi

import sys

sys.path.append('./transformers')

import os

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#Import Hugging Face's Transformers
from transformers import pipeline
# This is to log our outputs in a nicer format
from pprint import pprint
import argparse


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--model', type=str, help='Text to generate image from.')
  parser.add_argument('--min_length', type=int, help='Minimum length.')
  parser.add_argument('--max_length', type=int, help='Maximum length.')
  parser.add_argument('--temperature', type=float, help='Temperature.')
  args = parser.parse_args()
  return args

args=parse_args();


sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

# If you want to use the more powerful model: swap 'gpt-neo-1.3B' with 'gpt-neo-2.7B' (beware, it'll be slower and more likely to crash in Colab)
generator = pipeline('text-generation', model=f'EleutherAI/gpt-neo-{args.model}', device=0)

"""## Your first completion

GPT-Neo / GPT-3 are relatively simple to use. You simply pass in a text input (often called a "prompt") and the model will complete the rest of the text. 

You can change how much text is produced with the `max_length` and `min_length` parameters.

You can change how "creative" the model is with the `temperature` parameter. A temperature of 1 would lead to the most unique/creative outputs, and 0 would lead to the most deterministic outputs.

Let's get started by having GPT-Neo complete a very basic sentence for us.

You can edit the inputs either in the cell or the input line to the right of the cell. Make sure you press SHIFT + Enter or the Play button to run the cell!
"""

#@title Your first completion

prompt = args.prompt #"My name is Zack and I like to"#@param {type: "string"}
min_length = args.min_length #50#@param {type: "number"}
max_length = args.max_length #70#@param {type: "number"}
temperature = args.temperature #.7#@param {type: "number"}

sys.stdout.write("Generating text ...\n\n")
sys.stdout.flush()

output = generator(prompt, do_sample=True, min_length=min_length, max_length=max_length, temperature=temperature)
#print()
#print()
sys.stdout.write("\n")
sys.stdout.flush()
pprint(output[0]['generated_text'])

"""## Code Generation

Let's have GPT-Neo write some code! In the prompt, I'm instructing GPT-Neo to produce React Code for a to-do app.
This one might take a while longer to run. Reducing the `max_length` can help improve speed if your notebook crashes.
Let's see how it does:

#@title Code generation

prompt = "Below is React code for a to-do list app:"#@param {type: "string"}
min_length = 150#@param {type: "number"}
max_length = 250#@param {type: "number"}
temperature = .8#@param {type: "number"}
output = generator(prompt, do_sample=True, max_length=max_length, temperature=temperature)
print()
print()
pprint(output[0]['generated_text'])

## Conclusion

Thanks for reading along! This tutorial is being actively updated with more playground examples. Last update: 4/7/21 4:20 PM EST

[Find me doing silly things on Twitter @wenquai](https://twitter.com/wenquai)

And check out the company I work at, [CopyAI](https://www.copy.ai/)! We use Generate Pretrained Transformers to give humans writing superpowers ⚡. We're hiring!

"""

