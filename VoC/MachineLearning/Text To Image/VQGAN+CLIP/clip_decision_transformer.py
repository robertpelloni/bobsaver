# CLIP Decision Transformer.ipynb
# Original file is located at https://colab.research.google.com/drive/1dFV3GCR5kasYiAl8Bl4fBlLOCdCfjufI

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
from pathlib import Path
from IPython import display
from omegaconf import OmegaConf
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from transformers import top_k_top_p_filtering
from tqdm.notebook import trange
import time

sys.path.append('./taming-transformers')

from CLIP.clip import clip
from taming.models import vqgan

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to stylize video with')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to use.')
  parser.add_argument('--batch_size', type=int, help='Batch size')
  parser.add_argument('--save_count', type=int, help='Top n to save from batch')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--temperature', type=float, help='Temperature.')
  parser.add_argument('--top_p', type=float, help='Temperature.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

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



class CausalTransformerEncoder(nn.TransformerEncoder):
    def forward(self, src, mask=None, src_key_padding_mask=None, cache=None):
        output = src

        if self.training:
            if cache is not None:
                raise ValueError("cache parameter should be None in training mode")
            for mod in self.layers:
                output = mod(output, src_mask=mask, src_key_padding_mask=src_key_padding_mask)

            if self.norm is not None:
                output = self.norm(output)

            return output

        new_token_cache = []
        compute_len = src.shape[0]
        if cache is not None:
            compute_len -= cache.shape[1]
        for i, mod in enumerate(self.layers):
            output = mod(output, compute_len=compute_len)
            new_token_cache.append(output)
            if cache is not None:
                output = torch.cat([cache[i], output], dim=0)

        if cache is not None:
            new_cache = torch.cat([cache, torch.stack(new_token_cache, dim=0)], dim=1)
        else:
            new_cache = torch.stack(new_token_cache, dim=0)

        return output, new_cache


class CausalTransformerEncoderLayer(nn.TransformerEncoderLayer):
    def forward(self, src, src_mask=None, src_key_padding_mask=None, compute_len=None):
        if self.training:
            return super().forward(src, src_mask, src_key_padding_mask)

        if compute_len is None:
            src_last_tok = src
        else:
            src_last_tok = src[-compute_len:, :, :]

        attn_mask = src_mask if compute_len > 1 else None
        tmp_src = self.self_attn(src_last_tok, src, src, attn_mask=attn_mask,
                                 key_padding_mask=src_key_padding_mask)[0]
        src_last_tok = src_last_tok + self.dropout1(tmp_src)
        src_last_tok = self.norm1(src_last_tok)

        tmp_src = self.linear2(self.dropout(self.activation(self.linear1(src_last_tok))))
        src_last_tok = src_last_tok + self.dropout2(tmp_src)
        src_last_tok = self.norm2(src_last_tok)
        return src_last_tok


class CLIPToImageTransformer(nn.Module):
    def __init__(self, clip_dim, seq_len, n_toks):
        super().__init__()
        self.clip_dim = clip_dim
        d_model = 1024
        self.clip_in_proj = nn.Linear(clip_dim, d_model, bias=False)
        self.clip_score_in_proj = nn.Linear(1, d_model, bias=False)
        self.in_embed = nn.Embedding(n_toks, d_model)
        self.out_proj = nn.Linear(d_model, n_toks)
        layer = CausalTransformerEncoderLayer(d_model, d_model // 64, d_model * 4,
                                              dropout=0, activation='gelu')
        self.encoder = CausalTransformerEncoder(layer, 24)
        self.pos_emb = nn.Parameter(torch.zeros([seq_len + 1, d_model]))
        self.register_buffer('mask', self._generate_causal_mask(seq_len + 1), persistent=False)

    @staticmethod
    def _generate_causal_mask(size):
        mask = (torch.triu(torch.ones([size, size])) == 1).transpose(0, 1)
        mask = mask.float().masked_fill(mask == 0, float('-inf')).masked_fill(mask == 1, float(0))
        mask[0, 1] = 0
        return mask

    def forward(self, clip_embed, clip_score, input=None, cache=None):
        if input is None:
            input = torch.zeros([len(clip_embed), 0], dtype=torch.long, device=clip_embed.device)
        clip_embed_proj = self.clip_in_proj(F.normalize(clip_embed, dim=1) * self.clip_dim**0.5)
        clip_score_proj = self.clip_score_in_proj(clip_score)
        embed = torch.cat([clip_embed_proj.unsqueeze(0),
                           clip_score_proj.unsqueeze(0),
                           self.in_embed(input.T)])
        embed_plus_pos = embed + self.pos_emb[:len(embed)].unsqueeze(1)
        mask = self.mask[:len(embed), :len(embed)]
        out, cache = self.encoder(embed_plus_pos, mask, cache=cache)
        return self.out_proj(out[1:]).transpose(0, 1), cache

"""## Settings for this run:"""

args = argparse.Namespace(
    #prompt='Alien Friend by Odilon Redon',
    prompt=args2.prompt,
    batch_size=args2.batch_size, # originally 16
    clip_score=0.475, # originally 0.475
    half=True,
    k=args2.save_count,
    n=args2.iterations, # original 128
    output='out',
    seed=args2.seed,
    temperature=args2.temperature, # original 1.0
    top_k=0,
    top_p=args2.top_p, # original 0.95,
)

"""### Actually do the run..."""

device = torch.device('cuda:0')
print('Using device:', device)

dtype = torch.half if args.half else torch.float

sys.stdout.write("Loading CLIP model "+args2.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args2.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])
                                 
sys.stdout.write("Loading VQGAN model vqgan_imagenet_f16_16384 ...\n")
sys.stdout.flush()

vqgan_config = OmegaConf.load('vqgan_imagenet_f16_16384.yaml')
vqgan_model = vqgan.VQModel(**vqgan_config.model.params).to(device)
vqgan_model.eval().requires_grad_(False)
vqgan_model.init_from_ckpt('vqgan_imagenet_f16_16384.ckpt')
del vqgan_model.loss

clip_dim = perceptor.visual.output_dim
clip_input_res = perceptor.visual.input_resolution
e_dim = vqgan_model.quantize.e_dim
f = 2**(vqgan_model.decoder.num_resolutions - 1)
n_toks = vqgan_model.quantize.n_e
size_x, size_y = args2.sizex, args2.sizey
toks_x, toks_y = size_x // f, size_y // f

model = CLIPToImageTransformer(clip_dim, toks_y * toks_x, n_toks)
ckpt = torch.load('transformer_cond_2_00003_090000_modelonly.pth', map_location='cpu')
model.load_state_dict(ckpt['model'])
del ckpt
model = model.to(device, dtype).eval().requires_grad_(False)

text_embed = perceptor.encode_text(clip.tokenize(args.prompt).to(device)).to(dtype)
text_embed = text_embed.repeat([args.n, 1])
clip_score = torch.ones([text_embed.shape[0], 1], device=device, dtype=dtype) * args.clip_score

@torch.no_grad()
def sample(clip_embed, clip_score, temperature=1., top_k=0, top_p=1.):
    tokens = torch.zeros([len(clip_embed), 0], dtype=torch.long, device=device)
    cache = None
    
    for i in range(toks_y * toks_x):
        if (i+1)%50 == 0:
            sys.stdout.write("Sample iteration {}".format(i+1)+"\n")
            sys.stdout.flush()

        logits, cache = model(clip_embed, clip_score, tokens, cache=cache)
        logits = logits[:, -1] / temperature
        logits = top_k_top_p_filtering(logits, top_k, top_p)
        next_token = logits.softmax(1).multinomial(1)
        tokens = torch.cat([tokens, next_token], dim=1)
    return tokens

def decode(tokens):
    z = vqgan_model.quantize.embedding(tokens).view([-1, toks_y, toks_x, e_dim]).movedim(3, 1)
    return vqgan_model.decode(z).add(1).div(2).clamp(0, 1)

try:
    sys.stdout.write("Starting...\n")
    sys.stdout.flush()

    out_lst, sim_lst = [], []

    for i in range(0, len(text_embed), args.batch_size):
        
        sys.stdout.write("Iteration {}".format(i+1)+"\n")
        sys.stdout.flush()

        tokens = sample(text_embed[i:i+args.batch_size], clip_score[i:i+args.batch_size],
                        temperature=args.temperature, top_k=args.top_k, top_p=args.top_p)
        out = decode(tokens)
        out_lst.append(out)
        out_for_clip = F.interpolate(out, (clip_input_res, clip_input_res),
                                     mode='bilinear', align_corners=False)
        image_embed = perceptor.encode_image(normalize(out_for_clip)).to(dtype)
        sim = torch.cosine_similarity(text_embed[i:i+args.batch_size], image_embed)
        sim_lst.append(sim)

    sys.stdout.write("Iteration {}".format(args2.iterations)+"\n")
    sys.stdout.flush()
    
    out = torch.cat(out_lst)
    sim = torch.cat(sim_lst)
    best_values, best_indices = sim.topk(min(args.k, args.n))

    for i, index in enumerate(best_indices):
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()

        #filename = args.output + f'_{i:03}.png'
        TF.to_pil_image(out[index]).save(args2.image_file)
        
        
        if args2.frame_dir is not None:
            import os
            file_list = []
            for file in os.listdir(args2.frame_dir):
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
            save_name = args2.frame_dir+"\FRA"+count_string+".png"
            TF.to_pil_image(out[index]).save(save_name)
        
        

        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
        
        time.sleep(0.5)
    
    
except KeyboardInterrupt:
    pass