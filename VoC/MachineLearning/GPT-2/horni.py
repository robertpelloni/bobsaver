# dungeon.ipynb
# Original file is located at https://colab.research.google.com/github/finetuneanon/gpt-neo_dungeon/blob/master/gpt-neo_dungeon.ipynb

# requires the following tar files to he dopwnloaded and extracted under subfolders "gpt-neo-2.7B-horni" and "gpt-neo-2.7B-horni-ln"
# [2.7B-horni-ln](https://mega.nz/file/rQcWCTZR#tCx3Ztf_PMe6OtfgI95KweFT5fFTcMm7Nx9Jly_0wpg) [[Google Drive](https://drive.google.com/file/d/1M1JY459RBIgLghtWDRDXlD4Z5DAjjMwg/view?usp=sharing)] 5GB, for light novel styled output
# [2.7B-horni](https://mega.nz/file/6BNykLJb#B6gxK3TnCKBpeOF1DJMXwaLc_gcTcqMS0Lhzr1SeJmc) [[Google Drive](https://drive.google.com/file/d/1-Jj_hlyNCQxuSnK7FFBXREGnRSMI5MoF/view?usp=sharing)] 5GB, for NSFW styled output

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

from transformers import GPTNeoForCausalLM, AutoTokenizer
import tarfile
import codecs
import torch
import threading
import time
import subprocess

from IPython.display import HTML, display
import ipywidgets as widgets

tail_free_sampling, top_k, top_p, temperature, number_generated_tokens, repetition_penalty, repetition_penalty_range, repetition_penalty_slope, number_show_last_actions = 0.95, 60, 0.9, 0.8, 40, 1.25, 300, 3.33, 15
prevent_square_brackets, prevent_angle_brackets, prevent_curly_brackets = True, True, True
enable_top_k, enable_top_p, enable_tfs = False, False, True
bad_words_ids = None
initialized = 0
last_free_edit = ""
last_prompt = ""
warn_timeout = False
warn_time = -1
#threading.Thread(target=warn_timeout_thread).start()

actions = []
memory = ("", torch.zeros((1, 0)).long())
lmi = ["", torch.zeros((1, 0)).long()]
an = ("", torch.zeros((1, 0)).long())
an_depth = 5 # original 3
history = None

#@title Model setup
#@markdown horni was finetuned for one epoch on about 800MB worth of random blocks of text from literotica. Do not use the horni model if you dislike NSFW outputs. horni-ln uses horni as a base and was finetuned for one epoch on 579MB of text from a light novel dataset.

#print("Setting up model, this will take a few minutes. Don't interrupt this cell even takes a long while, or you can be left with broken, half unpacked files.")

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()


model_name = "2.7B-horni-ln" #@param ["2.7B-horni-ln", "2.7B-horni", "EleutherAI/gpt-neo-2.7B"]
model_gdrive = "/content/drive/MyDrive/gpt-neo-2.7B-horni-ln.tar" #@param {type:"string"}
use_gdrive = False #@param {type:"boolean"}
#@markdown If you download errors, the google drive downloads might be over their daily download quota. In that case, right-click, select "interrupt execution", download the checkpoint from mega yourself, upload to your google drive, tick use_gdrive and put the correct filename, e.g. `gpt-neo-2.7B-horni-ln.tar` and restart the cell.
#@markdown
#@markdown Warnings about certain attention bias parameters being uninitialized or about the google drive already having been mounted can be ignored.

custom_models = ["2.7B-horni", "2.7B-horni-ln"]

model_types = {"2.7B-horni": "https://drive.google.com/uc?id=1-Jj_hlyNCQxuSnK7FFBXREGnRSMI5MoF",
               "2.7B-horni-ln": "https://drive.google.com/uc?id=1M1JY459RBIgLghtWDRDXlD4Z5DAjjMwg"}

model = None
tokenizer = None
pipeline = None
checkpoint = None

if model_name in custom_models:
  checkpoint = torch.load("gpt-neo-" + model_name + "/pytorch_model.bin", map_location="cuda:0")
  model = GPTNeoForCausalLM.from_pretrained("gpt-neo-" + model_name, state_dict=checkpoint).half().to("cuda").eval()
  for k in list(checkpoint.keys()):
    del checkpoint[k]
  del checkpoint
else:
  from transformers.file_utils import cached_path, WEIGHTS_NAME, hf_bucket_url
  archive_file = hf_bucket_url(model_name, filename=WEIGHTS_NAME)
  resolved_archive_file = cached_path(archive_file)
  checkpoint = torch.load(resolved_archive_file, map_location="cuda:0")
  for k in checkpoint.keys():
    checkpoint[k] = checkpoint[k].half()
  model = GPTNeoForCausalLM.from_pretrained(model_name, state_dict=checkpoint).half().to("cuda").eval()
  for k in list(checkpoint.keys()):
    del checkpoint[k]
  del checkpoint
tokenizer = AutoTokenizer.from_pretrained("gpt2")

#@title Sampling settings (DO NOT SKIP)
#@markdown You can modify sampling settings here. Don't forget to run the cell again after changing. The number of generated tokens is subtracted from the context window size, don't set it high.
tail_free_sampling = 0.95 #@param {type:"number"}
top_k = 60 #@param {type:"number"}
top_p = 0.9 #@param {type:"number"}
temperature =  0.8#@param {type:"number"}
number_generated_tokens =  2000#@param {type:"integer"}
repetition_penalty = 2.5 #@param {type:"number"}
repetition_penalty_range = 512 #@param {type:"number"}
repetition_penalty_slope = 3.33 #@param {type:"number"}
number_show_last_actions = 15 #@param {type:"integer"}

#@markdown If tail free sampling is enabled, top_p and top_k should probably not be used.
enable_tfs = False #@param {type:"boolean"}
enable_top_k = True #@param {type:"boolean"}
enable_top_p = True #@param {type:"boolean"}

if not enable_tfs:
  tail_free_sampling = None
if not enable_top_k:
  top_k = None
if not enable_top_p:
  top_p = None

#@markdown Temperatures seem to give results different from those in AID, so play around with it. Even 0.5 can give good results.

#@title Prevent tokens like [, <, > and { from being generated
#thanks STARSTRUCK

prevent_square_brackets = True #@param {type:"boolean"}
prevent_angle_brackets = True #@param {type:"boolean"}
prevent_curly_brackets = True #@param {type:"boolean"}

vocab = tokenizer.get_vocab()
vocab_keys = vocab.keys()
bad_keys = list()
find_keys = lambda char : [key for key in vocab_keys if key.find(char) != -1]

if prevent_square_brackets:
  bad_keys.extend(find_keys("["))
  #bad_keys.extend(find_keys("]"))

if prevent_angle_brackets:
  bad_keys.extend(find_keys("<"))
  bad_keys.extend(find_keys(">"))

if prevent_curly_brackets:
  bad_keys.extend(find_keys("{"))
  #bad_keys.extend(find_keys("}"))

bad_words_ids = list()
bad_keys_final = list()
for key in bad_keys:
  if key == "<|endoftext|>" or key in bad_keys_final:
    continue
  bad_id = vocab[key]
  bad_words_ids.append([bad_id])
  bad_keys_final.append(key)

if len(bad_words_ids) < 1:
  bad_words_ids = None

#print(f"Bad keys: {bad_keys_final} (Count: {len(bad_keys)})")
#print(f"Bad ids: {bad_words_ids}")

#@title Basic sampling

#@markdown Use this cell if you just want to sample from the model in a free form way.

sys.stdout.write("Generating text ...\n")
sys.stdout.flush()

basic_prompt = "The rays of the evening sun falling in through the window bathed the room in a soft, warm light" #@param {type:"string"}

ids = tokenizer(basic_prompt, return_tensors="pt").input_ids.to("cpu")
n_ids = ids.shape[1]
if n_ids < 1:
  n_ids = 1
  ids = torch.tensor([[tokenizer.eos_token_id]])
max_length = n_ids + number_generated_tokens
torch.cuda.empty_cache()
basic_output = model.generate(
    ids.long().cuda(),
    do_sample=True,
    min_length=max_length,
    max_length=max_length,
    temperature=temperature,
    tfs = tail_free_sampling,
    top_k = top_k,
    top_p = top_p,
    repetition_penalty = repetition_penalty,
    repetition_penalty_range = repetition_penalty_range,
    repetition_penalty_slope = repetition_penalty_slope,
    use_cache=True,
    bad_words_ids=bad_words_ids,
    pad_token_id=tokenizer.eos_token_id
).long().to("cpu")
torch.cuda.empty_cache()

print(tokenizer.decode(basic_output[0]))
