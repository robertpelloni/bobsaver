# ruDALLE arbitrary resolution
# Original file is located at https://colab.research.google.com/drive/1DbqOIUIVBPOrJ4MeaV4YkAlb7ilWQjKZ

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./ru-dalle-arbitrary')

import torch
from rudalle.pipelines import generate_images, show, super_resolution, cherry_pick_by_clip
from rudalle import get_rudalle_model, get_tokenizer, get_vae, get_realesrgan, get_ruclip
from rudalle.utils import seed_everything
import os
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
    


device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
device = 'cuda' #without this specific setting/string the rest of the script runs slower?!! so somewhere in ruDALL-E it needs 'cuda' and not "cuda:0" like most other Text-to-Image scripts.
print('Using device:', device)
print(torch.cuda.get_device_properties(device))


seed = args.seed #@param {type: "integer"}


"""
sys.stdout.write("Translating prompt text to Russian ...\n")
sys.stdout.flush()
text = GoogleTranslator(source='auto', target='ru').translate(args.prompt)
print(f"Russian prompt is {text}\n")
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


#@markdown image size (width/height in tokens, px / 8)
#@markdown width can't be lower than 32
w = args.sizex//8 #64  #@param {type: "number"}
h = args.sizey//8 #32  #@param {type: "number"}

#@markdown increase for more pictures at the expense of speed
num_resolutions = 1  #@param {type: "number"}

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

dalle = get_rudalle_model('Malevich', pretrained=True,
                           fp16=device == "cuda",
                           device=device,
                           cache_dir=cachepath
                          )

# realesrgan = get_realesrgan('x4', device=device)
vae = get_vae(cache_dir=cachepath).to(device)
# ruclip, ruclip_processor = get_ruclip('ruclip-vit-base-patch32-v5')
# ruclip = ruclip.to(device)

#os.environ["CUDA_LAUNCH_BLOCKING"] = "1"

"""## code"""


def generate_images(text, tokenizer, dalle, vae, top_k, top_p, images_num, image_prompts=None, temperature=1.0, bs=8,
                    seed=None, use_cache=True, w=32, h=48):
    # TODO docstring
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
                   
                #for idx in tqdm(range(out.shape[1], total_seq_length-real*real+w*h)):
                total_iterations=total_seq_length-real*real+w*h
                
                #print(f'out.shape[1]={out.shape[1]}')
                #print(f'total_iterations={total_iterations}')
                
                for idx in range(out.shape[1], total_iterations):
                    idx -= text_seq_length
                    y = idx // w
                    x = idx % w
                    x_from = max(0, min(w-real, x-real//2))
                    y_from = max(0, y-real//2)
                    # print(y, y_from, x, x_from, idx, w, h)
                    outs = []
                    xs = []
                    for row in range(y_from, y):
                        for col in range(x_from, min(w, x_from+real)):
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
                                # nc = []
                                # for l, m in xs:
                                #     while (l, m) not in rev_past:
                                #         break  # will pass
                                #         if l <= 0 and m <= 0:
                                #             break
                                #         m -= 1
                                #         if m < 0:
                                #             l -= 1
                                #             m = real - 1
                                #     if (l, m) not in rev_past:
                                #         break
                                #     nc.append(c[..., rev_past[l, m], :])
                                # if nc:
                                #     c = torch.stack(nc, dim=-2)
                                #     # print(c.shape, t.shape, nc[0].shape)
                                #     t = torch.cat((t, c), dim=-2)
                                cache[i][j] = t
                        cache = dict(zip(range(len(cache)), cache))
                    
                    past_cache = xs
                    logits, cache = dalle(torch.cat((input_ids.to(device).ravel(),
                                                        torch.from_numpy(np.asarray(outs)).long().to(device)),
                                                        dim=0).unsqueeze(0), attention_mask,
                                            cache=cache, use_cache=True, return_loss=False)
                    # logits = logits[:, -1, vocab_size:]
                    logits = logits[:, :, vocab_size:].view((-1, logits.shape[-1] - vocab_size))
                    logits /= temperature
                    filtered_logits = transformers.top_k_top_p_filtering(logits, top_k=top_k, top_p=top_p)
                    probs = torch.nn.functional.softmax(filtered_logits, dim=-1)
                    sample = torch.multinomial(probs, 1)
                    sample_scores.append(probs[torch.arange(probs.size(0)), sample.transpose(0, 1)])
                    # out = torch.cat((out, sample), dim=-1)
                    sample, xs = sample[-1:], xs[-1:]
                    # print(sample.item())
                    grid[y, x] = sample.item()
                    # for s, (y, x) in zip(sample, xs):
                        # i = y * w + x
                        # i += 1
                        # grid[i // w, i % w] = s.item()
                    """
                    codebooks = grid.flatten().unsqueeze(0)
                    images = vae.decode(codebooks)
                    pil_images += utils.torch_tensors_to_pil_list(images)
                    """
                    
                    sys.stdout.write(f"Iteration {idx+1} ...\n")
                    sys.stdout.flush()

                    if (idx+1) % args.update==0 or idx==total_iterations-out.shape[1]-1:
                        sys.stdout.flush()
                        sys.stdout.write('Saving progress ...\n')
                        sys.stdout.flush()

                        codebooks = grid.flatten().unsqueeze(0)
                        images = vae.decode(codebooks)
                        pil_images = utils.torch_tensors_to_pil_list(images)
                        
                        pil_images[-1].save(args.image_file)
    
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
                            pil_images[-1].save(save_name)

                        sys.stdout.flush()
                        sys.stdout.write('Progress saved\n')
                        sys.stdout.flush()
                        
                        
                        
                        
                # codebooks = out[:, -image_seq_length:]
                # codebooks = grid.flatten().unsqueeze(0)
                # images = vae.decode(codebooks)
                # pil_images += utils.torch_tensors_to_pil_list(images)
                # scores += torch.cat(sample_scores).sum(0).detach().cpu().numpy().tolist()
    except Exception as e:
        sys.stdout.write("Caught an exception ...\n")
        sys.stdout.flush()
        print(e)
        pass
    except KeyboardInterrupt:
        pass
    return pil_images, scores

#@title adapt the vqgan decoder to a new non-square resolution. uses the global `h` 
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

"""## generation by ruDALLE"""

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

if seed > 0:
    seed_everything(seed)

pil_images = []
scores = []

for top_k, top_p, images_num in [
    (2048, 0.995, 3),
    (1536, 0.99, 3),
    (1024, 0.99, 3),
    (1024, 0.98, 3),
    (512, 0.97, 3),
    (384, 0.96, 3),
    (256, 0.95, 3),
    (128, 0.95, 3), 
][:num_resolutions]:
    images_num = 1
    _pil_images, _scores = generate_images(text, tokenizer, dalle, vae, top_k=top_k, images_num=images_num, top_p=top_p,
                                           h=h, w=w, use_cache=False)
    pil_images += _pil_images
    scores += _scores

"""## results"""

#pil_images[-1].save("sample.png")
#pil_images[-1]
