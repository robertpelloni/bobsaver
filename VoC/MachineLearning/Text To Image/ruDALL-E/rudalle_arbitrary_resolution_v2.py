# ruDALLE arbitrary resolution v2.0
# Original file is located at https://colab.research.google.com/drive/1JznXpirarS-zAZqXGOWRWDgFxLdL_xAU

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./ru-dalle-arbitrary')

from rudalle.pipelines import generate_images, show, super_resolution, cherry_pick_by_clip
from rudalle import get_rudalle_model, get_tokenizer, get_vae, get_realesrgan, get_ruclip
from rudalle.utils import seed_everything
import rudalle.dalle
import torch
from glob import glob
from os.path import join
import cv2
import torch
import torchvision
import transformers
import more_itertools
import numpy as np
import matplotlib.pyplot as plt
from tqdm.auto import tqdm
from PIL import Image
from rudalle import utils
from math import sqrt, log
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch import einsum
from einops import rearrange
from taming.modules.diffusionmodules.model import Encoder, Decoder
from functools import partial
#from deep_translator import GoogleTranslator
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Iterations per update')
  parser.add_argument('--sizex', type=int, help='Width')
  parser.add_argument('--sizey', type=int, help='Height')
  parser.add_argument('--num_images', type=int, help='1 for Malevich, 4 or more for Enojich')
  parser.add_argument('--model', type=str, help='Malevich or Emojich.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();

if args.seed is not None:
    sys.stdout.write(f'Setting seed to {args.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args.seed)
    import random
    random.seed(args.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args.seed)
    torch.cuda.manual_seed(args.seed)
    torch.cuda.manual_seed_all(args.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 
    torch.backends.cudnn.enabled = False    


device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
device = 'cuda' #without this specific setting/string the rest of the script runs slower?!! so somewhere in ruDALL-E it needs 'cuda' and not "cuda:0" like most other Text-to-Image scripts.
print('Using device:', device)
print(torch.cuda.get_device_properties(device))




rudalle.dalle.MODELS["Emojich"] = dict(
    description='Emojich is a 1.3 billion params model from the family GPT3-like, '
                'it generates emoji-style images with the brain of ◾ Malevich.',
    model_params=dict(
        num_layers=24,
        hidden_size=2048,
        num_attention_heads=16,
        embedding_dropout_prob=0.1,
        output_dropout_prob=0.1,
        attention_dropout_prob=0.1,
        image_tokens_per_dim=32,
        text_seq_length=128,
        cogview_sandwich_layernorm=True,
        cogview_pb_relax=True,
        vocab_size=16384 + 128,
        image_vocab_size=8192,
    ),
    repo_id='sberbank-ai/rudalle-Emojich',
    filename='pytorch_model.bin',
    authors='SberAI',
    full_description='',  # TODO
)

#set cache dir location under user home directory
import os
homepath = os.path.expanduser(os.getenv('USERPROFILE'))
#cachepath = homepath+'/.cache'
cachepath = '../../.cache'

#print(f'cachepath={cachepath}')

sys.stdout.write("Getting tokenizer ...\n")
sys.stdout.flush()

tokenizer = get_tokenizer(cache_dir=cachepath)

sys.stdout.write("Getting ruDALL-E ...\n")
sys.stdout.flush()

dalle = get_rudalle_model(args.model, pretrained=True,
                           fp16=device == "cuda",
                           device=device,
                           cache_dir=cachepath
                          )

# realesrgan = get_realesrgan('x4', device=device)
vae = get_vae(dwt=False,cache_dir=cachepath).to(device)
# ruclip, ruclip_processor = get_ruclip('ruclip-vit-base-patch32-v5')
# ruclip = ruclip.to(device)

#import os
#os.environ["CUDA_LAUNCH_BLOCKING"] = "1"  # easier debugging

"""## settings"""

#@markdown # Settings
#@markdown ## General settings
#@markdown random seed (set to positive to use)
seed = args.seed #@param {type: "integer"}
#@markdown text prompt (russian)
#text = '\u043B\u044E\u0434\u0438'  #@param {type: "string"}

"""
sys.stdout.write("Translating prompt text to Russian ...\n")
sys.stdout.flush()
text = GoogleTranslator(source='auto', target='ru').translate(args.prompt)
"""

from googletrans import Translator
translator = Translator()
detected_language = translator.detect(args.prompt)
if "lang=ru" in str(detected_language):
    sys.stdout.write("Prompt detected as Russian so no need to translate.\n")
    sys.stdout.flush()
    text = args.prompt
else:
    sys.stdout.write("Translating English prompt to Russian ...\n")
    sys.stdout.flush()
    text = translator.translate(args.prompt, dest='ru').text


#@markdown the model to use

#@markdown Malevich is the default model and is really good for normal-looking or realistic images
#@markdown Emojich was trained on emojis, it gets 3D or stylized right but is more limited in its generations. Only makes things on a white background

model_name = args.model #"Emojich" #@param {type: "string"} ["Emojich", "Malevich"]

#@markdown live preview, you get an animation of the generation process 
live_preview = True #@param {type: "boolean"}
#@markdown ## Image settings
#@markdown image size (width/height in tokens, px / 8)
w = args.sizex//8 #32  #@param {type: "number"}
h = args.sizey//8 #64  #@param {type: "number"}
#@markdown number of pictures to generate

images_num = args.num_images#@param {type: "integer"}
#@markdown increase for more pictures at the expense of speed
num_resolutions = 1  #@param {type: "integer"}
#@markdown ## Video settings
#@markdown save video or just generate the pictures
save_video = False  #@param {type: "boolean"}
#@markdown show one picture in the video 
one_picture = False  #@param {type: "boolean"}
# if save_video:  doesn't work
#@markdown fps of the resulting video
fps = 90  #@param {type: "integer"}
#@markdown ---
#@markdown run this cell when the notebook runs out of memory, if it doesn't help restart the runtime
#if save_video:
#    print("estimated video length (seconds): ", h * w / fps)


def generate_images(text, tokenizer, dalle, vae, top_k, top_p, images_num, image_prompts=None, temperature=1.0, bs=8,
                    seed=None, use_cache=True, w=32, h=48, display_intermediate=False, save_state=None):
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
    grid = None
    pil_images_ = []
    cache = None
    past_cache = None

    if save_state is not None:
        pil_images, grid, pil_images_, _ = save_state

    """
    if display_intermediate:
        from ipywidgets import Output
        from IPython.display import display, clear_output
        out_area = Output()
        display(out_area)
    """
    sys.stdout.flush()
    
    try:
        for chunk_i, chunk in enumerate(more_itertools.chunked(range(images_num), bs)):
            chunk_bs = len(chunk)
            pil_images_ = [[] for _ in chunk]
            with torch.no_grad():
                attention_mask = torch.tril(torch.ones((chunk_bs, 1, total_seq_length, total_seq_length), device=device))
                input_ids_ = input_ids.unsqueeze(0).repeat(chunk_bs, 1).to(device)
                grid = torch.zeros((chunk_bs, h, w)).long().cuda()
                if save_state and chunk_i == 0:
                    grid = save_state[1]
                has_cache = False
                sample_scores = []
                total_iterations=total_seq_length-real*real+w*h
                #for idx in range(max(input_ids_.shape[1], save_state[-1] if save_state else 0), total_seq_length-real*real+w*h):
                for idx in range(input_ids_.shape[1], total_iterations):
                    idx -= text_seq_length
                    y = idx // w
                    x = idx % w
                    x_from = max(0, min(w-real, x-real//2))
                    y_from = max(0, y-real//2)
                    xs = []
                    for row in range(y_from, min(h, y)):
                        for col in range(x_from, min(x_from+real, w)):
                            xs.append((row, col))
                    for col in range(x_from, x):
                        xs.append((y, col))
                    outs = []
                    for i in range(len(chunk)):
                        outs_ = []
                        for row, col in xs:
                            outs_.append(grid[i, row, col].item())
                        outs.append(outs_)
                    if cache is not None:
                        cache = list(map(list, cache.values()))
                        for i, e in enumerate(cache):
                            for j, c in enumerate(e):
                                t = cache[i][j]
                                t, c = t[..., :text_seq_length, :], t[..., text_seq_length:, :]
                                cache[i][j] = t
                        cache = dict(zip(range(len(cache)), cache))
                    outs = torch.from_numpy(np.asarray(outs)).long().to(device)
                    ln = input_ids_.shape[1] + outs.shape[1]
                    logits, cache = dalle(torch.cat((input_ids_, outs),
                                                        dim=1), attention_mask[..., -ln-1:, -ln-1:],
                                            cache=cache, use_cache=True, return_loss=False)
                    logits = logits[:, -1, vocab_size:]
                    logits /= temperature
                    filtered_logits = transformers.top_k_top_p_filtering(logits, top_k=top_k, top_p=top_p)
                    probs = torch.nn.functional.softmax(filtered_logits, dim=-1)
                    sample = torch.multinomial(probs, 1)
                    for i, e in enumerate(sample):
                        s = sample[i]
                        grid[i, y, x] = s.item()

                    """
                    imgs = vae.decode(grid.view((chunk_bs, -1)))
                    images = utils.torch_tensors_to_pil_list(imgs)
                    for j, e in enumerate(images):
                        pil_images_[j].append(e) 
                    """

                    sys.stdout.write(f"Iteration {idx+1} ...\n")
                    sys.stdout.flush()

                    if (idx+1) % args.update==0 or idx==total_iterations-input_ids_.shape[1]-1:
                        sys.stdout.flush()
                        sys.stdout.write('Saving progress ...\n')
                        sys.stdout.flush()

                        imgs = vae.decode(grid.view((chunk_bs, -1)))
                        images = utils.torch_tensors_to_pil_list(imgs)
                        for j, e in enumerate(images):
                            pil_images_[j].append(e) 
                        
                        images[-1].save(args.image_file)
    
                        if args.frame_dir is not None:
                            file_list = []
                            for file in os.listdir(args.frame_dir):
                                if file.startswith("FRA"):
                                    if file.endswith("png"):
                                        if len(file) == 12:
                                            file_list.append(file)
                            if file_list:
                                last_name = file_list[-1]
                                count_value = int(last_name[3:8])+1
                                count_string = f"{count_value:05d}"
                            else:
                                count_string = "00001"
                            save_name = args.frame_dir+"\FRA"+count_string+".png"
                            images[-1].save(save_name)

                        sys.stdout.flush()
                        sys.stdout.write('Progress saved\n')
                        sys.stdout.flush()    

                    pil_images += pil_images_
    # except Exception as e:
    #     print(e)
    #     pass
    except KeyboardInterrupt:
        pil_images += pil_images_
    return pil_images, (pil_images, grid, pil_images_, idx + text_seq_length)

"""## generation by ruDALLE"""

# Commented out IPython magic to ensure Python compatibility.
#@title set seed
# %load_ext autoreload
# %autoreload 2

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

if seed > 0:
    seed_everything(seed)

#@title the generation itself

# prepare decoder for generation
def decode(self, img_seq):
    b, n = img_seq.shape
    one_hot_indices = torch.nn.functional.one_hot(img_seq, num_classes=self.num_tokens).float()
    z = (one_hot_indices @ self.model.quantize.embed.weight)
    z = rearrange(z, 'b (h w) c -> b c h w', h=h
                  # int(sqrt(n))
                  )
    img = self.model.decode(z)
    img = (img.clamp(-1., 1.) + 1) * 0.5
    return img
vae.decode = partial(decode, vae)

#@markdown you can continue generating if it stopped in the middle
continue_save = True  #@param {type: "boolean"}
#@markdown turn this checkbox off if you changed the settings
pil_images = []
scores = []

for top_k, top_p, images_num_ in [
    (2048, 0.995, 3),
    (1536, 0.99, 3),
    (1024, 0.99, 3),
    (1024, 0.98, 3),
    (512, 0.97, 3),
    (384, 0.96, 3),
    (256, 0.95, 3),
    (128, 0.95, 3), 
][:num_resolutions]:
    try:
        save_state
    except:
        save_state = None
    _pil_images, save_state = generate_images(
        text, tokenizer, dalle, vae, top_k=top_k, images_num=images_num, top_p=top_p,
        h=h, w=w, use_cache=True, save_state=save_state if continue_save else None,
        display_intermediate=live_preview)
    pil_images += _pil_images

"""
#@title show the results
from IPython.display import display
for i, pil_img in enumerate(pil_images):
    pil_img[-1].save(f"sample_{i}.png")
    display(pil_img[-1])
"""
