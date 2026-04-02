# Optimized ruDALLE
# Original file is located at https://colab.research.google.com/drive/1euIMG8E6kSFA2nU58LqrVsq6nbXjqELY


#!pip install rudalle==0.0.1rc1 > /dev/null

"""## Imports"""
import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./ru-dalle-optimized')

from rudalle.pipelines import generate_images, show, super_resolution, cherry_pick_by_clip
from rudalle import get_rudalle_model, get_tokenizer, get_vae, get_realesrgan, get_ruclip
from rudalle.utils import seed_everything
import torch
import torchvision
import transformers
import more_itertools
import numpy as np
import matplotlib.pyplot as plt
from rudalle import utils
import argparse
import inspect
from functools import partial
import torch
import torch.nn.functional as F
from rudalle.dalle.utils import divide, split_tensor_along_last_dim
#from deep_translator import GoogleTranslator

global itt_start #value the iteration loop counter starts at

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  args = parser.parse_args()
  return args

args=parse_args();

#@title ruDALLE generation
#from tqdm.auto import tqdm

#text = 'синий кот' # blue cat

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
device = 'cuda' #without this specific setting/string the rest of the script runs slower?!! so somewhere in ruDALL-E it needs 'cuda' and not "cuda:0" like most other Text-to-Image scripts.
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

"""
sys.stdout.write("Translating prompt to Russian ...\n")
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


"""## Creating models"""

#set cache dir location under user home directory
import os
homepath = os.path.expanduser(os.getenv('USERPROFILE'))
#cachepath = homepath+'/.cache'
cachepath = '../../.cache'
#print(f'cachepath={cachepath}')

sys.stdout.write("Getting ruDALL-E ...\n")
sys.stdout.flush()


dalle = get_rudalle_model('Malevich', pretrained=True, fp16=True, device=device, cache_dir=cachepath)

try:
    realesrgan, tokenizer, ruclip, ruclip_processor
except NameError:
    #realesrgan = get_realesrgan('x4', device=device)
    sys.stdout.write("Getting tokenizer ...\n")
    sys.stdout.flush()
    tokenizer = get_tokenizer(cache_dir=cachepath)
    sys.stdout.write("Getting vae ...\n")
    sys.stdout.flush()
    vae = get_vae(cache_dir=cachepath).to(device)
    sys.stdout.write("Getting ruclip ...\n")
    sys.stdout.flush()
    ruclip, ruclip_processor = get_ruclip('ruclip-vit-base-patch32-v5', cache_dir=cachepath)
    ruclip = ruclip.to(device)

"""## Monkey patch"""


def generate_images(text, tokenizer, dalle, vae, top_k, top_p, images_num, temperature=1.0, bs=8, seed=None,
                    use_cache=True):
    global itt
    # TODO docstring
    if seed is not None:
        utils.seed_everything(seed)

    vocab_size = dalle.get_param('vocab_size')
    text_seq_length = dalle.get_param('text_seq_length')
    image_seq_length = dalle.get_param('image_seq_length')
    total_seq_length = dalle.get_param('total_seq_length')
    device = dalle.get_param('device')

    text = text.lower().strip()
    input_ids = tokenizer.encode_text(text, text_seq_length=text_seq_length)
    pil_images, scores = [], []
    for chunk in more_itertools.chunked(range(images_num), bs):
        chunk_bs = len(chunk)
        with torch.no_grad():
            attention_mask = torch.tril(torch.ones((chunk_bs, 1, total_seq_length, total_seq_length), device=device))
            out = input_ids.unsqueeze(0).repeat(chunk_bs, 1).to(device)
            has_cache = False
            sample_scores = []
            for i in range(len(input_ids), total_seq_length):
                sys.stdout.write(f'Iteration {itt}\n')
                sys.stdout.flush()
                
                logits, has_cache = dalle(out[:i], attention_mask,
                                          has_cache=has_cache, use_cache=use_cache, return_loss=False)
                logits = logits[:, -1, vocab_size:]
                logits /= temperature
                filtered_logits = transformers.top_k_top_p_filtering(logits, top_k=top_k, top_p=top_p)
                probs = torch.nn.functional.softmax(filtered_logits, dim=-1)
                sample = torch.multinomial(probs, 1)
                sample_scores.append(probs[torch.arange(probs.size(0)), sample.transpose(0, 1)])
                out = torch.cat((out, sample), dim=-1)
                itt+=1
            codebooks = out[:, -image_seq_length:]
            images = vae.decode(codebooks)
            pil_images += utils.torch_tensors_to_pil_list(images)
            scores += torch.cat(sample_scores).sum(0).detach().cpu().numpy().tolist()
            
    return pil_images, scores


def show(pil_images, nrow=4):
    sys.stdout.flush()
    sys.stdout.write('Saving progress ...\n')
    sys.stdout.flush()

    imgs = torchvision.utils.make_grid(utils.pil_list_to_torch_tensors(pil_images), nrow=nrow)
    if not isinstance(imgs, list):
        imgs = [imgs.cpu()]
    fix, axs = plt.subplots(ncols=len(imgs), squeeze=False, figsize=(14, 14))
    for i, img in enumerate(imgs):
        img = img.detach()
        img = torchvision.transforms.functional.to_pil_image(img)
        img.save('./Progress.png')
        axs[0, i].imshow(np.asarray(img))
        axs[0, i].set(xticklabels=[], yticklabels=[], xticks=[], yticks=[])
    #plt.savefig('./savefig.png')
    #torchvision.utils.save_image(imgs,'./grid.png')

    sys.stdout.flush()
    sys.stdout.write('Progress saved\n')
    sys.stdout.flush()


@torch.jit.script
def gelu_impl(x):
    """OpenAI's gelu implementation."""
    return 0.5 * x * (1.0 + torch.tanh(0.7978845608028654 * x * (1.0 + 0.044715 * x * x)))


def gelu(x):
    return gelu_impl(x)


def dalle_layer_forward(self, hidden_states, ltor_mask, has_cache, use_cache):
    # hidden_states: [b, s, h]
    # ltor_mask: [1, 1, s, s]

    # Layer norm at the begining of the transformer layer.
    # output = hidden_states
    # att_has_cache, mlp_has_cache = True, True
    layernorm_output = self.input_layernorm(hidden_states)

    # Self attention.
    attention_output, att_has_cache = self.attention(
        layernorm_output, ltor_mask, has_cache=has_cache, use_cache=use_cache)  # if False else layernorm_output, True

    if self.cogview_sandwich_layernorm:
        attention_output = self.before_first_addition_layernorm(
            attention_output, has_cache=has_cache, use_cache=use_cache)

    # Residual connection.
    layernorm_input = hidden_states + attention_output

    # Layer norm post the self attention.
    layernorm_output = self.post_attention_layernorm(
        layernorm_input, has_cache=has_cache, use_cache=use_cache)

    # MLP.
    mlp_output, mlp_has_cache = self.mlp(layernorm_output,
                                    has_cache=has_cache,
                                    use_cache=use_cache)  # if False else layernorm_output, True

    if self.cogview_sandwich_layernorm:
        mlp_output = self.before_second_addition_layernorm(
            mlp_output, has_cache=has_cache, use_cache=use_cache)

    # Second residual connection.
    output = layernorm_input + mlp_output

    return output, att_has_cache and mlp_has_cache


# def patch_full(self, func_name)
#     orig = getattr(self, func_name)
#     def patched(x):
#         return orig(x)
#     setattr(self, func_name, patched)


def dalle_sa_forward(self, hidden_states, ltor_mask, has_cache=False, use_cache=False,):
    # hidden_states: [b, s, h]
    # ltor_mask: [1, 1, s, s]
    # Attention heads. [b, s, hp]
    if has_cache and use_cache:
        mixed_x_layer = self.query_key_value(hidden_states[:, -1:, :])
    else:
        mixed_x_layer = self.query_key_value(hidden_states)

    (mixed_query_layer,
        mixed_key_layer,
        mixed_value_layer) = split_tensor_along_last_dim(mixed_x_layer, 3)

    query_layer = self._transpose_for_scores(mixed_query_layer)
    key_layer = self._transpose_for_scores(mixed_key_layer)
    value_layer = self._transpose_for_scores(mixed_value_layer)

    if use_cache and has_cache:
        value_layer = torch.cat((self.past_value, value_layer), dim=-2)
        query_layer = torch.cat((self.past_query, query_layer), dim=-2)
        key_layer = torch.cat((self.past_key, key_layer), dim=-2)
        # attention_scores = self.past_attentions
        attention_scores = self._calculate_attention_scores(
            query_layer=query_layer, key_layer=key_layer, ltor_mask=ltor_mask
        )
        # t = value_layer.shape[-2]
        # attenton_scores = attention_scores.expand(attention_scores.shape[:2] + (t, t))
    else:
        attention_scores = self._calculate_attention_scores(
            query_layer=query_layer, key_layer=key_layer, ltor_mask=ltor_mask
        )
        self.past_attentions = attention_scores

    if use_cache:
        self.past_query = query_layer
        self.past_key = key_layer
        self.past_value = value_layer
        has_cache = True
    else:
        has_cache = False

    # Attention probabilities. [b, np, s, s]
    attention_probs = torch.nn.Softmax(dim=-1)(attention_scores)

    # This is actually dropping out entire tokens to attend to, which might
    # seem a bit unusual, but is taken from the original Transformer paper.
    attention_probs = self.attention_dropout(attention_probs)

    # Context layer.
    # [b, np, s, hn]
    context_layer = torch.matmul(attention_probs, value_layer)

    # [b, s, np, hn]
    context_layer = context_layer.permute(0, 2, 1, 3).contiguous()

    new_context_layer_shape = context_layer.size()[:-2] + (self.hidden_size,)
    # [b, s, hp]
    context_layer = context_layer.view(*new_context_layer_shape)

    # Output. [b, s, h]
    output = self.dense(context_layer)
    output = self.output_dropout(output)
    return output, has_cache


def dalle_mlp_forward_(self, hidden_states, has_cache=False, use_cache=False):
    if has_cache and use_cache:
        t = hidden_states.shape[1]
        hidden_states = hidden_states[:, -1:]

    # [b, s, 4hp]
    x = self.dense_h_to_4h(hidden_states)
    x = gelu(x)
    # [b, s, h]
    x = self.dense_4h_to_h(x)
    if use_cache:
        if has_cache:
            self.past_x[:, t-1:] = x
            x = self.past_x[:, :t]
        else:
            self.past_x = x.clone().repeat((1, (1024+128)//128, 1))  # hack
        has_cache = True
    else:
        has_cache = False
    output = self.dropout(x)
    return output, has_cache


def dalle_mlp_forward(self, hidden_states, has_cache=False, use_cache=False):
    if has_cache and use_cache:
        hidden_states = hidden_states[:, self.past_x.shape[1]:]

    # [b, s, 4hp]
    x = self.dense_h_to_4h(hidden_states)
    x = gelu(x)
    # [b, s, h]
    x = self.dense_4h_to_h(x)
    if use_cache:
        # Can be simplified, but I won't for readability's sake
        if has_cache:
            x = torch.cat((self.past_x, x), dim=1)
            self.past_x = x
        else:
            self.past_x = x
        has_cache = True
    else:
        has_cache = False
    output = self.dropout(x)
    return output, has_cache


def ln_forward(self, input, has_cache=False, use_cache=False):
    if has_cache and use_cache:
        input = input[:, self.past_output.shape[1]:]
    
    output = F.layer_norm(
        input, self.normalized_shape, self.weight, self.bias, self.eps)
    
    if use_cache:
        # Can be simplified, but I won't for readability's sake
        if has_cache:
            output = torch.cat((self.past_output, output), dim=1)
            self.past_output = output
        else:
            self.past_output = output
        has_cache = True
    else:
        has_cache = False
    return output  # , has_cache


for layer in dalle.module.transformer.layers:
    layer.attention.forward = partial(dalle_sa_forward, layer.attention)
    layer.forward = partial(dalle_layer_forward, layer)
    layer.mlp.forward = partial(dalle_mlp_forward, layer.mlp)
    for ln in [layer.before_first_addition_layernorm,
              layer.post_attention_layernorm,
              layer.before_second_addition_layernorm]:
        # print(inspect.getsource(ln.forward))
        ln.forward = partial(ln_forward, ln)

"""## Generation by ruDALLE"""

num_resolutions =  1 #@param {type:"integer"}

sys.stdout.write(f'Setting seed to {args.seed} ...\n')
sys.stdout.flush()

seed_everything(args.seed)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=0
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
    (64, 0.92, 1)
][-num_resolutions:]:
    _pil_images, _scores = generate_images(text, tokenizer, dalle, vae, top_k=top_k, images_num=images_num, top_p=top_p)
    pil_images += _pil_images
    scores += _scores

#show([pil_image for pil_image, score in sorted(zip(pil_images, scores), key=lambda x: -x[1])] , 6)

"""### auto-cherry-pick by ruCLIP"""

top_images, clip_scores = cherry_pick_by_clip(pil_images, text, ruclip, ruclip_processor, device=device, count=1)
show(top_images, 1)

"""## super resolution"""
#sr_images = super_resolution(top_images, realesrgan)
#show(sr_images, 1)

