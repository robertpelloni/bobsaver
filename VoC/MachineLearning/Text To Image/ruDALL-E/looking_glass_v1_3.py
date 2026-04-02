import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./ru-dalle-looking-glass')

#force cache into the correct .cache folder under the user home directory
import os
from pathlib import Path
home = str(Path.home())
os.environ['TORCH_HOME'] = home

from rudalle.pipelines import generate_images, show, super_resolution, cherry_pick_by_clip
from rudalle import get_rudalle_model, get_tokenizer, get_vae, get_realesrgan, get_ruclip
from rudalle.utils import seed_everything
import multiprocessing
import torch
import os
from psutil import virtual_memory
import multiprocessing
import torch
import os
from psutil import virtual_memory
from functools import reduce
import torch.nn.functional as F
from rudalle.dalle.utils import exists, is_empty
from einops import rearrange
import io
import os
import PIL
from PIL import Image
import random
import numpy as np
import torch
import torchvision
import transformers
import more_itertools
import numpy as np
import matplotlib.pyplot as plt
#from tqdm import tqdm
import pandas as pd
from torch.utils.data import Dataset
from tqdm import tqdm
from dataclasses import dataclass, field
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import gc
import csv
from math import sqrt, log
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch import einsum
from einops import rearrange
from taming.modules.diffusionmodules.model import Encoder, Decoder
from rudalle import utils
from functools import partial
#from deep_translator import GoogleTranslator
from torch.utils.data import Dataset, DataLoader
from transformers import  AdamW, get_linear_schedule_with_warmup
import glob
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--size', type=int, help='Width and height')
  parser.add_argument('--epochs', type=int, help='Epochs')
  parser.add_argument('--train_type', type=int, help='1=single image 2-image directory')
  parser.add_argument('--single_image', type=str, help='Single image to train on.')
  parser.add_argument('--similarity', type=str, help='How close to source images the result images are.')
  parser.add_argument('--images_count', type=int, help='How many images to output.')
  parser.add_argument('--model_file', type=str, help='Specify a pre-trained model pt file to use.')
  parser.add_argument('--model', type=str, help='Model.')
  parser.add_argument('--image_directory', type=str, help='Directory of images to train on.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args3 = parser.parse_args()
  return args3

args2=parse_args();

if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 
    
    
    
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
device = 'cuda' #without this specific setting/string the rest of the script runs slower?!! so somewhere in ruDALL-E it needs 'cuda' and not "cuda:0" like most other Text-to-Image scripts.
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

#set cache dir location under user home directory
import os
homepath = os.path.expanduser(os.getenv('USERPROFILE'))
#cachepath = homepath+'/.cache'
cachepath = '../../.cache'
#print(f'cachepath={cachepath}')

sys.stdout.write("Getting ruDALL-E ...\n")
sys.stdout.flush()

model = get_rudalle_model(args2.model, pretrained=True, fp16=True, device=device, cache_dir=cachepath)

sys.stdout.write("Getting vae ...\n")
sys.stdout.flush()

vae = get_vae(cache_dir=cachepath).to('cuda')

sys.stdout.write("Getting tokenizer ...\n")
sys.stdout.flush()

tokenizer = get_tokenizer(cache_dir=cachepath)

"""## Parameters"""

#@markdown # **PUT YOUR FILENAME HERE**
#@markdown Just put the file name here after uploading it to your file structure and it'll handle the rest.

#@markdown If you want to train on multiple files, put a file glob here (like image_* for image_1.jpg, image_2.jpg...). To grab all images in a folder, use `[FOLDER'S NAME]/*`

if args2.single_image is not None:
    file_selector_glob = args2.single_image #"face.jpg"  # @param {type:"string"}
else:
    file_selector_glob = args2.image_directory #"face.jpg"  # @param {type:"string"}

if args2.model_file is not None:
    file_selector_glob = "./noise.png"

input_files = glob.glob(file_selector_glob, recursive=True)
#print("Input files:", input_files)
#if len(input_files) == 0:
#  print("Your input files are empty! This will error out - make sure your file_selector_glob is formatted correctly!")

#@markdown <br></br>
#@markdown # Finetuning Options
#@markdown The amount of epochs that training occurs for. Turn down if the images are too similar to the base image. Turn up if they're too different. Use this for fine adjustments.
epoch_amt =   args2.epochs #30# @param
#@markdown Universe similarity determines how close to the original images you will receive. High similarity produces alternate versions of an image, low similarity produces "variations on a theme".

#@markdown *Note: Universe similarity may be erratic when blending multiple images.*
universe_similarity = args2.similarity #"Medium"  # @param ["High", "Medium", "Low"]
if universe_similarity == "High":
    learning_rate = 1e-4
elif universe_similarity == "Medium":
    learning_rate = 2e-5
elif universe_similarity == "Low":
    learning_rate = 1e-5
else:
    learning_rate = 1e-5
#@markdown Confidence is how closely the AI will attempt to match the input images. Low confidence will result in something that tries very hard to make an image that looks like your input, high confidence lets it go off the rails a little, and medium confidence is somewhere in the middle. v1.1 and below had "Low" as their default, so that will be what you're used to.
confidence = "Low"  # @param ["High", "Medium", "Low"]
generation_p = 0.999
if confidence == "High":
    generation_p = 0.9
elif confidence == "Medium":
    generation_p = 0.99
elif confidence == "Low":
    generation_p = 0.999
else:
    generation_p = 0.999

"""
#@markdown Input text can influence the end result you get to a minor degree, so you have the option to change it now. Input text **must be in Russian**. Leave this blank to use a default.
input_text = ""  # @param {type:"string"}
if input_text == "":
  input_text = "\u0420\u0438\u0447\u0430\u0440\u0434 \u0414. \u0414\u0436\u0435\u0439\u043C\u0441"
"""

"""
sys.stdout.write("Translating prompt text to Russian ...\n")
sys.stdout.flush()
input_text = GoogleTranslator(source='auto', target='ru').translate(args2.prompt) #@param {type:"string"}
"""
from googletrans import Translator
translator = Translator()
detected_language = translator.detect(args2.prompt)
if "lang=ru" in str(detected_language):
    sys.stdout.write("Prompt detected as Russian so no need to translate.\n")
    sys.stdout.flush()
    input_text = args2.prompt
else:
    sys.stdout.write("Translating English prompt to Russian ...\n")
    sys.stdout.flush()
    input_text = translator.translate(args2.prompt, dest='ru').text
    #check if translation failed
    if input_text == args2.prompt:
        print("Unable to translate the specified prompt to Russian.  Try a different or longer prompt.")
        print("You can also manually translate English to Russian and use the Russian prompt.")
        sys.exit()


class Args():
    def __init__(self):
        self.text_seq_length = model.get_param('text_seq_length')
        self.total_seq_length = model.get_param('total_seq_length')
        self.epochs = epoch_amt
        self.save_dir = ''
        self.model_name = 'lookingglass'
        self.save_every = 2000
        self.prefix_length = 10
        self.bs = 1
        self.clip = 0.24
        self.lr = learning_rate
        self.warmup_steps = 50
        self.wandb = False


torch_args = Args()
#if not os.path.exists(torch_args.save_dir):
#    os.makedirs(torch_args.save_dir)
if not os.path.exists('output'):
    os.makedirs('output')

#@markdown <br></br>
#@markdown #Collage Options
#@markdown The amount of images to generate per collage and the amount of collages to generate. The generator uses batching in order to make up to four images at once - turn on low_mem mode if it crashes while attempting to make 4, 9, or 25 images. Less images are faster.
image_amount = args2.images_count #"1"  # @param [1, 4, 9, 25]
#image_amount = int(image_amount)
collage_amount = 1  # @param {type:"number"}

#@markdown If you *really* want to make a 9 or 25 image collage but have a weak CPU, you can try turning on low mem mode. It will take a *while* though.
low_mem = False  # @param {type:"boolean"}

#@markdown By default, Looking Glass includes your original image(s) somewhere in the collage as "Ground Truth". Check this box to disable that behavior.
skip_gt = True  # @param {type:"boolean"}

#@markdown #Output Resizer
#@markdown If you'd like to change the shape or size of the output from its default 256x256 set "resize" to true.<br>Note that this is **much slower**.<br>Not only is the process itself slower but it forces itself to run with a batch_size of 1, meaning it forces you into low_mem mode, which makes pictures take a while. Buyer beware.
"""
do_resize = True  # @param {type:"boolean"}
if do_resize:
    low_mem = True
width =   1024# @param {type:"number"}
height =   1024# @param {type:"number"}
"""

width = args2.size #256 @param {type:"number"}
height = args2.size #256 @param {type:"number"}
do_resize = False
if args2.size>256:
    do_resize = True  # @param {type:"boolean"}
    low_mem = True

token_width = round(width / 8)
token_height = round(height / 8)

#@markdown <br></br>
#@markdown #Stretchsizing
#@markdown A more crude form of image resizing that squishes your initial image down to 256x256, and then expands the output images back to your original image's aspect ratio. May result in artifacts, but runs much faster than Output Resizing.
#@markdown <br>CURRENTLY INCOMPATIBLE WITH OUTPUT RESIZING. I WILL FIX THIS EVENTUALLY I'M JUST LAZY.
do_stretchsize = False  # @param {type:"boolean"}

ss_size_parent = input_files[0]
if do_stretchsize:
    ss_realesrgan = get_realesrgan("x2", device=device)


#@markdown <br><br>
#@markdown #Upscaling
#@markdown Uses realesrgan to upscale your images at the end. That's it! Set to x1 to disable. Not recommended to be combined w/ Stretchsizing.
rurealesrgan_multiplier = "x1"  # @param ["x1", "x2", "x4", "x8"]
if rurealesrgan_multiplier != "x1":
    realesrgan = get_realesrgan(rurealesrgan_multiplier, device=device)

import re
original_folder = re.sub(r'[/*?]', '-', file_selector_glob)
print("Identifier", original_folder)

#@title Stretchsize processing
original_file = ''
st_width = 256
st_height = 256
if do_stretchsize:
  new_input_files = []
  #@markdown `do_stretchsize` disables `do_resize`
  do_resize = False
  #@markdown `do_stretchsize` always does `skip_gt`
  skip_gt = True

  for image_path in input_files:
    __, image_name = os.path.split(image_path)
    im = Image.open(image_path)
    st_width, st_height = im.size
    if st_width > st_height:
      im1 = im.resize((st_width, st_width))
    else:
      im1 = im.resize((st_height, st_height))
    stretched_path = os.path.join("stretchsize", image_name)
    im1.save(stretched_path)
    new_input_files.append(stretched_path)
  print("Input files:", new_input_files)
  input_files = new_input_files
  try:
    im = Image.open(ss_size_parent)
    st_width, st_height = im.size
  except:
    st_width, st_height = 256

#@title
# Write data_desc csv

with open('data_desc.csv', 'w', newline='', encoding="utf-8") as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=',')
    csvwriter.writerow(['', 'name', 'caption'])
    for i, filepath in enumerate(input_files):
      csvwriter.writerow([i, filepath, input_text])

"""**We gonna generate some <strike>sneakers</strike> EVERYTHING**

## Some definitions and boilerplate
"""


class RuDalleDataset(Dataset):
    clip_filter_thr = 0.24
    def __init__(
            self,
            csv_path,
            tokenizer,
            resize_ratio=0.75,
            shuffle=True,
            load_first=None,
            caption_score_thr=0.6
    ):
        """ tokenizer - object with methods tokenizer_wrapper.BaseTokenizerWrapper """
       
        self.text_seq_length = model.get_param('text_seq_length')
        self.tokenizer = tokenizer
        self.target_image_size = 256
        self.image_size=256
        self.samples = []

        self.image_transform = T.Compose([
                T.Lambda(lambda img: img.convert('RGB') if img.mode != 'RGB' else img),
                T.RandomResizedCrop(
                    self.image_size,
                    scale=(1., 1.), # в train было scale=(0.75., 1.),
                    ratio=(1., 1.)
                ),
                T.ToTensor()
            ])
        
        df = pd.read_csv(csv_path)
        for caption, image_path  in zip(df['caption'], df['name']):
            if len(caption)>10 and len(caption)<100 and os.path.isfile(image_path):
              self.samples.append([image_path, caption])
        if shuffle:
            np.random.shuffle(self.samples)
    
    def __len__(self):
        return len(self.samples)

    def load_image(self, image_path):
        image = PIL.Image.open(image_path)
        return image

    def __getitem__(self, item):
        item = item % len(self.samples)  # infinite loop, modulo dataset size
        image_path, text = self.samples[item]
        try:
          image = self.load_image(image_path)
          image = self.image_transform(image).to(device)
        except Exception as err:  # noqa
            print(err)
            random_item = random.randint(0, len(self.samples) - 1)
            return self.__getitem__(random_item)
        text =  tokenizer.encode_text(text, text_seq_length=self.text_seq_length).squeeze(0).to(device)
        return text, image

#@title

from torch.utils.data import Dataset, DataLoader
st = RuDalleDataset(csv_path='data_desc.csv', tokenizer=tokenizer)
train_dataloader = DataLoader(st, batch_size=torch_args.bs, shuffle=True, drop_last=True)

#Setup logs
torch_args.wandb = False

from transformers import  AdamW, get_linear_schedule_with_warmup
model.train()

sys.stdout.write("Setting optimizer ...\n")
sys.stdout.flush()


optimizer = AdamW(model.parameters(), lr = torch_args.lr)

sys.stdout.write("Setting scheduler ...\n")
sys.stdout.flush()

scheduler = torch.optim.lr_scheduler.OneCycleLR(
    optimizer, max_lr=torch_args.lr, 
    final_div_factor=500,  
    steps_per_epoch=len(train_dataloader), epochs=torch_args.epochs
)

def freeze(
    model,
    freeze_emb=True,
    freeze_ln=False,
    freeze_attn=False,
    freeze_ff=True,
    freeze_other=True,
):
    for name, p in model.module.named_parameters():
        name = name.lower()
        if 'ln' in name or 'norm' in name:
            p.requires_grad = not freeze_ln
        elif 'embeddings' in name:
            p.requires_grad = not freeze_emb
        elif 'mlp' in name:
            p.requires_grad = not freeze_ff
        elif 'attn' in name:
            p.requires_grad = not freeze_attn
        else:
            p.requires_grad = not freeze_other
    return model


"""## Finetuning"""

#@title Finetuning

def train(model, args: Args, train_dataloader: RuDalleDataset):
    """
    args - arguments for training

    train_dataloader - RuDalleDataset class with text - image pair in batch
    """
    loss_logs = []
    try:
        #progress = tqdm(total=(args2.epochs * len(input_files)), desc='finetuning goes brrr')
        save_counter = 0
        for epoch in range(args2.epochs):
            
            sys.stdout.write(f"Finetuning epoch {epoch+1} ...\n")
            sys.stdout.flush()
            
            for text, images in train_dataloader:
                device = model.get_param('device')
                save_counter += 1
                model.zero_grad()
                attention_mask = torch.tril(
                    torch.ones(
                        (args.bs, 1, args.total_seq_length, args.total_seq_length),
                        device=device
                    )
                )
                image_input_ids = vae.get_codebook_indices(images)

                input_ids = torch.cat((text, image_input_ids), dim=1)
                _, loss = forward(
                    model.module, input_ids, attention_mask.half(),
                    return_loss=True, use_cache=False, gradient_checkpointing=6
                )
                loss = loss["image"]
                # train step
                loss.backward()

                torch.nn.utils.clip_grad_norm_(model.parameters(), args.clip)
                optimizer.step()
                scheduler.step()
                optimizer.zero_grad()
                # save every here
                """
                if save_counter % args.save_every == 0:
                    print(f'Saving checkpoint here {args.model_name}_dalle_{save_counter}.pt')

                    #plt.plot(loss_logs)
                    #plt.show()
                    torch.save(
                        model.state_dict(),
                        os.path.join(args.save_dir, f"{args.model_name}_dalle_{save_counter}.pt")
                    )
                if args.wandb:
                    args.wandb.log({"loss": loss.item()})
                """

                loss_logs += [loss.item()]
                #progress.update()
                #progress.set_postfix({"loss": loss.item()})

        #print(f'Completly tuned and saved here  {args.model_name}__dalle_last.pt')

        #plt.plot(loss_logs)
        #plt.show()

        torch.save(
            model.state_dict(),
            os.path.join(args.save_dir, f"{args.model_name}_dalle_last.pt")
        )

    except KeyboardInterrupt:
        print(f'What for did you stopped? Please change model_path to /{args.save_dir}/{args.model_name}_dalle_Failed_train.pt')
        #plt.plot(loss_logs)
        #plt.show()

        torch.save(
            model.state_dict(),
            os.path.join(args.save_dir, f"{args.model_name}_dalle_Failed_train.pt")
        )
    except Exception as err:
        print(f'Failed with {err}')


# idk why but this is necessary


class Layer(torch.nn.Module):
    def __init__(self, x, f, *args, **kwargs):
        super(Layer, self).__init__()
        self.x = x
        self.f = f
        self.args = args
        self.kwargs = kwargs

    def forward(self, x):
        return self.f(self.x(x, *self.args, **self.kwargs))


def forward(
        self,
        input_ids,
        attention_mask,
        return_loss=False,
        use_cache=False,
        gradient_checkpointing=False
):
    text = input_ids[:, :self.text_seq_length]
    text_range = torch.arange(self.text_seq_length)
    text_range += (self.vocab_size - self.text_seq_length)
    text_range = text_range.to(self.device)
    text = torch.where(text == 0, text_range, text)
    # some hardcode :)
    text = F.pad(text, (1, 0), value=2)
    text_embeddings = self.text_embeddings(text) + \
        self.text_pos_embeddings(torch.arange(text.shape[1], device=self.device))

    image_input_ids = input_ids[:, self.text_seq_length:]

    if exists(image_input_ids) and not is_empty(image_input_ids):
        image_embeddings = self.image_embeddings(image_input_ids) + \
            self.get_image_pos_embeddings(image_input_ids, past_length=0)
        embeddings = torch.cat((text_embeddings, image_embeddings), dim=1)
    else:
        embeddings = text_embeddings
    # some hardcode :)
    if embeddings.shape[1] > self.total_seq_length:
        embeddings = embeddings[:, :-1]

    alpha = 0.1
    embeddings = embeddings * alpha + embeddings.detach() * (1 - alpha)

    attention_mask = attention_mask[:, :, :embeddings.shape[1], :embeddings.shape[1]]
    t = self.transformer
    layers = []
    layernorms = []
    if not layernorms:
        norm_every = 0
    else:
        norm_every = len(t.layers) // len(layernorms)
    for i in range(len(t.layers)):
        layers.append(Layer(
            t.layers[i],
            lambda x:
                x[0] * layernorms[i // norm_every][0] +
                layernorms[i // norm_every][1] if norm_every and i % norm_every == 0 else x[0],
            torch.mul(attention_mask, t._get_layer_mask(i)[:attention_mask.size(2), :attention_mask.size(3), ]),
            use_cache=False
        ))
    if gradient_checkpointing:  # don't use this under any circumstances
        # actually please do
        # i just spent 3 hours debugging this
        embeddings = torch.utils.checkpoint.checkpoint_sequential(layers, 6, embeddings)
        transformer_output = embeddings
        present_has_cache = False
    else:
        hidden_states = embeddings
        for i in range(len(t.layers)):
            mask = torch.mul(attention_mask, t._get_layer_mask(i)[:attention_mask.size(2), :attention_mask.size(3)])
            hidden_states, present_has_cache = t.layers[i](hidden_states, mask, use_cache=use_cache)
        transformer_output = hidden_states
    transformer_output = self.transformer.final_layernorm(transformer_output)

    logits = self.to_logits(transformer_output)
    if return_loss is False:
        return logits, present_has_cache

    labels = torch.cat((text[:, 1:], image_input_ids), dim=1).contiguous().long()
    logits = rearrange(logits, 'b n c -> b c n')

    text_logits = logits[:, :self.vocab_size, :self.text_seq_length].contiguous().float()
    image_logits = logits[:, self.vocab_size:, self.text_seq_length:].contiguous().float()

    loss_text = F.cross_entropy(
        text_logits,
        labels[:, :self.text_seq_length])
    loss_img = F.cross_entropy(
        image_logits,
        labels[:, self.text_seq_length:])

    loss = (loss_text + self.loss_img_weight * loss_img) / (self.loss_img_weight + 1)
    return loss, {'text': loss_text.data.detach().float(), 'image': loss_img}

# Run training on model
model = freeze(
    model=model,
    freeze_emb=False,
    freeze_ln=False,
    freeze_attn=True,
    freeze_ff=True,
    freeze_other=False
)

if args2.model_file==None:
    sys.stdout.write("Finetuning ...\n")
    sys.stdout.flush()
    #freeze params to 
    train(model, torch_args, train_dataloader)
else:
    sys.stdout.write("Loading pre-trained model ...\n")
    sys.stdout.flush()
    #model_path = os.path.join('/content/'+args.save_path,f"{args.model_name}_dalle_last.pt")
    model_path = args2.model_file
    model = get_rudalle_model('Malevich', pretrained=True, fp16=True, device=device)
    model.load_state_dict(torch.load(model_path)) 
    sys.stdout.write(f'Loaded from {model_path}\n')
    sys.stdout.flush()


"""## Generation"""

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

total_images = 1
current_image = 1

#gc.collect()
#torch.cuda.empty_cache()
#@title 
#@markdown TODO: TURN THIS PART INTO "LOAD FROM PRETRAINED CHECKPOINT"
#load model 
#model_path = os.path.join('/content/'+args.save_path,f"{args.model_name}_dalle_last.pt")
#model = get_rudalle_model('Malevich', pretrained=True, fp16=True, device=device)
#model.load_state_dict(torch.load(model_path)) 
#print(f'Loaded from {model_path}')

vae = get_vae(cache_dir=cachepath).to(device)

def slow_decode(self, img_seq):
    b, n = img_seq.shape
    one_hot_indices = torch.nn.functional.one_hot(img_seq, num_classes=self.num_tokens).float()
    z = (one_hot_indices @ self.model.quantize.embed.weight)
    z = rearrange(z, 'b (h w) c -> b c h w', h=token_height
                  # int(sqrt(n))
                  )
    img = self.model.decode(z)
    img = (img.clamp(-1., 1.) + 1) * 0.5
    return img

if do_resize:
  vae.slow_decode = partial(slow_decode, vae)

#@markdown <b>New image generation function for arbitrary resolution from @nev#4905/[@apeoffire](https://twitter.com/apeoffire)</b>
def slow_generate_images(text, tokenizer, dalle, vae, top_k, top_p, images_num, image_prompts=None, temperature=1.0, bs=8,
                    seed=None, use_cache=True, w=32, h=48):
    global current_mage
    global total_images

    if seed is not None:
        utils.seed_everything(seed)
    vocab_size = dalle.get_param('vocab_size')
    text_seq_length = dalle.get_param('text_seq_length')
    image_seq_length = dalle.get_param('image_seq_length')
    total_seq_length = dalle.get_param('total_seq_length')
    device = dalle.get_param('device')
    real = 32

    text = text.lower().strip()
    input_ids = tokenizer.encode_text(text, text_seq_length=text_seq_length)
    pil_images, scores = [], []
    itt=1
    cache = None
    past_cache = None
    try:
        for chunk in more_itertools.chunked(range(images_num), bs):
            chunk_bs = len(chunk)
            with torch.no_grad():
                attention_mask = torch.tril(torch.ones((chunk_bs, 1, total_seq_length, total_seq_length), device=device))
                out = input_ids.unsqueeze(0).repeat(chunk_bs, 1).to(device)
                grid = torch.zeros((h, w)).long().cuda()
                has_cache = False
                sample_scores = []
                if image_prompts is not None:
                    prompts_idx, prompts = image_prompts.image_prompts_idx, image_prompts.image_prompts
                    prompts = prompts.repeat(chunk_bs, 1)
                for idx in tqdm(range(out.shape[1], total_seq_length-real*real+w*h)):
                    idx -= text_seq_length

                    #sys.stdout.write(f'Iteration {itt} - Image {current_mage} of {total_images}\n')
                    #sys.stdout.flush()
                    sys.stdout.write(f'Iteration {itt}\n')
                    sys.stdout.flush()
                
                    if image_prompts is not None and idx in prompts_idx:
                        out = torch.cat((out, prompts[:, idx].unsqueeze(1)), dim=-1)
                    else:
                        y = idx // w
                        x = idx % w
                        x_from = max(0, min(w-real, x-real//2))
                        y_from = max(0, y-real//2)
                        outs = []
                        xs = []
                        for row in range(y_from, y):
                            for col in range(x_from, x_from+real):
                                outs.append(grid[row, col].item())
                                xs.append((row, col))
                        for col in range(x_from, x):
                            outs.append(grid[y, col].item())
                            xs.append((y, col))
                        rev_xs = {v: k for k, v in enumerate(xs)}
                        if past_cache is not None:
                            cache = list(map(list, cache.values()))
                            rev_past = {v: k for k, v in enumerate(past_cache)}
                            for i, e in enumerate(cache):
                                for j, c in enumerate(e):
                                    t = cache[i][j]
                                    t, c = t[..., :text_seq_length, :], t[..., text_seq_length:, :]
                                    cache[i][j] = t
                            cache = dict(zip(range(len(cache)), cache))
                        past_cache = xs
                        logits, cache = dalle(torch.cat((input_ids.to(device).ravel(),
                                                            torch.from_numpy(np.asarray(outs)).long().to(device)),
                                                            dim=0).unsqueeze(0), attention_mask,
                                                cache=cache, use_cache=True, return_loss=False)
                        logits = logits[:, :, vocab_size:].view((-1, logits.shape[-1] - vocab_size))
                        logits /= temperature
                        filtered_logits = transformers.top_k_top_p_filtering(logits, top_k=top_k, top_p=top_p)
                        probs = torch.nn.functional.softmax(filtered_logits, dim=-1)
                        sample = torch.multinomial(probs, 1)
                        sample_scores.append(probs[torch.arange(probs.size(0)), sample.transpose(0, 1)])
                        sample, xs = sample[-1:], xs[-1:]
                        grid[y, x] = sample.item()
                    itt+=1
    
                codebooks = grid.reshape((1, -1))
                images = slow_decode(vae, codebooks)
                pil_images += utils.torch_tensors_to_pil_list(images)
    except Exception as e:
        print(e)
        pass
    except KeyboardInterrupt:
        pass
    return pil_images, scores


def aspect_crop(image_path, desired_aspect_ratio):
    """
    Return a PIL Image object cropped to desired aspect ratio
    :param str image_path: Path to the image to crop
    :param str desired_aspect_ratio: desired aspect ratio in width:height format
    """

    # compute original aspect ratio
    image = Image.open(image_path)
    width, height = image.size
    original_aspect = float(width) / float(height)

    # convert string aspect ratio into float
    w, h = map(lambda x: float(x), desired_aspect_ratio.split(':'))
    computed_aspect_ratio = w / h
    inverse_aspect_ratio = h / w

    if original_aspect < computed_aspect_ratio:
        # keep original width and change height
        new_height = math.floor(width * inverse_aspect_ratio)
        height_change = math.floor((height - new_height) / 2)
        new_image = image.crop((0, height_change, width, height - height_change))
        return new_image
    elif original_aspect > computed_aspect_ratio:
        # keep original height and change width
        new_width = math.floor(height * computed_aspect_ratio)
        width_change = math.floor((width - new_width) / 2)
        new_image = image.crop((width_change, 0, width - width_change, height))
        return new_image
    elif original_aspect == computed_aspect_ratio:
        return image

#@title Your images will emerge here
#@markdown The output will be saved in the session structure under /output/
#@markdown <br>ONCE YOUR CHECKPOINT IS FINE TUNED YOU CAN PRESS THIS BUTTON MULTIPLE TIMES FOR MORE IMAGES. YOU DON'T NEED TO RESTART EACH TIME.
pil_images = []
scores = []
repeat = 1
rows = 2
insert = 0
amt = 3
if skip_gt:
    amt = 4
if low_mem:
    repeat = 3
    if skip_gt:
        repeat = 4
    amt = 1
if image_amount == 9:
    repeat = 2
    rows = 3
    insert = 4
    amt = 4
    if low_mem:
        repeat = 8
        amt = 1
elif image_amount == 25:
    repeat = 6
    rows = 5
    insert = 12
    amt = 4
    if low_mem:
        repeat = 24
        amt = 1
elif image_amount == 1:
    repeat = 1
    rows = 1
    amt = 1
    skip_gt = True
    insert = 0


def crop_center(pil_img, crop_width, crop_height):
    img_width, img_height = pil_img.size
    return pil_img.crop((
        (img_width - crop_width) // 2,
        (img_height - crop_height) // 2,
        (img_width + crop_width) // 2,
        (img_height + crop_height) // 2
    ))


def crop_max_square(pil_img):
    return crop_center(pil_img, min(pil_img.size), min(pil_img.size))


def generate_images_amt(images_num):
    if do_resize:
        _pil_images, _scores = slow_generate_images(
            input_text, tokenizer, model, vae,
            top_k=2048, images_num=images_num, top_p=generation_p,
            w=token_width, h=token_height
        )
    else:            
      _pil_images, _scores = generate_images(
            input_text, tokenizer, model, vae,
            top_k=2048, images_num=images_num, top_p=generation_p
        )
    return _pil_images


def show_tiled_images(pil_images, nrow=4):
    imgs = torchvision.utils.make_grid(utils.pil_list_to_torch_tensors(pil_images), nrow=nrow)
    if not isinstance(imgs, list):
        imgs = [imgs.cpu()]
    fix, axs = plt.subplots(ncols=len(imgs), squeeze=False, figsize=(14, 14))

    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()

    for i, img in enumerate(imgs):
        img = img.detach()
        img = torchvision.transforms.functional.to_pil_image(img)
        img.save(args2.image_file)
        axs[0, i].imshow(np.asarray(img))
        axs[0, i].set(xticklabels=[], yticklabels=[], xticks=[], yticks=[])

    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()



def save_pil_images(pil_images):
    for k in range(len(pil_images)):
        #output_name = f"lg{k + len(onlyfiles)}_{original_folder}.png"
        #pil_images[k].save(os.path.join("output", output_name))
        #pil_images[k].save('Progress.png')
        file_list = []
        for file in os.listdir(args2.frame_dir):
          if file.startswith(args2.prompt):
            if file.endswith("png"):
              if file.find("[")==-1:
                file_list.append(file)
        if file_list:
          last_name = file_list[-1]
          promptlen=len(args2.prompt)+1
          count_value = int(last_name[promptlen:promptlen+5])+1
          count_string = f"{count_value:05d}"
        else:
          count_string = "00001"
        save_name = args2.frame_dir+"\\"+args2.prompt+" "+count_string+".png"
        pil_images[k].save(save_name)

for i in range(collage_amount):
    for j in range(repeat):

        total_images = repeat
        current_image = j
        #sys.stdout.write(f'Generating image {j+1} of {repeat} ...\n')
        #sys.stdout.flush()

        pil_images += generate_images_amt(amt)
    if skip_gt and image_amount != 4:
        if image_amount != 1:
            pil_images += generate_images_amt(1)

    if do_stretchsize:
        # ESRGAN Upscaling
        pil_images = super_resolution(pil_images, ss_realesrgan)
        for j in range(len(pil_images)):
            pil_images[j] = pil_images[j].resize((st_width, st_height))

    onlyfiles = next(os.walk('output'))[2]
    file_to_train = random.choice(input_files)
    save_pil_images(pil_images)

    if skip_gt is False:
        if do_resize:
            if do_stretchsize:
                raise NotImplementedError("Stretchsize and resize not simultaneously supported")
            else:
                aspect_ratio = (token_width / token_height)
                with Image.open(file_to_train) as im:
                    # Provide the target width and height of the image
                    to_insert = aspect_crop(im, aspect_ratio).resize((width, height), Image.LANCZOS)
        else:
            if do_stretchsize:
                with Image.open(original_file) as im:
                    # Provide the target width and height of the image
                    to_insert = im.copy()
            else:
                with Image.open(file_to_train) as im:
                    # Provide the target width and height of the image
                    to_insert = crop_max_square(im).resize((256, 256), Image.LANCZOS)
        pil_images.insert(insert, to_insert.convert('RGB'))

    if rurealesrgan_multiplier != "x1":
        pil_images = super_resolution(pil_images, realesrgan)
        save_pil_images(pil_images)
    
    #show(pil_images, rows)
    show_tiled_images([pil_image for pil_image in pil_images], rows)

    pil_images = []
    scores = []
