# CLIP Prior + VQGAN (MSE method)
# Original file is located at https://colab.research.google.com/drive/1yOpCY9eXvzELHppvh-o0DevhxVYOGr5i

"""
!curl -L https://models.rivershavewings.workers.dev/clip_prior_6_6370000.pth > clip_prior_6_6370000.pth
!curl -L 'https://heibox.uni-heidelberg.de/d/a7530b09fed84f80a887/files/?p=%2Fconfigs%2Fmodel.yaml&dl=1' > vqgan_imagenet_f16_16384.yaml
!curl -L 'https://heibox.uni-heidelberg.de/d/a7530b09fed84f80a887/files/?p=%2Fckpts%2Flast.ckpt&dl=1' > vqgan_imagenet_f16_16384.ckpt
"""


"""### Import Dependencies"""

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
from concurrent import futures
import gc
import sys
import math

sys.path.append('./taming-transformers')

from kornia import augmentation as K
from IPython import display
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
from taming.modules.diffusionmodules.model import Decoder
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from tqdm import tqdm

from CLIP import clip

sys.path.append('./ResizeRight')
from resize_right import resize, interp_methods

sys.path.append('./v-diffusion-pytorch')
from diffusion import sampling, utils as diff_utils





sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--seed', type=int)
  parser.add_argument('--iterations', type=int)
  parser.add_argument('--update', type=int)
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--cond_scale', type=float)
  parser.add_argument('--no_prior', type=int)
  parser.add_argument('--best_of_n', type=int)
  parser.add_argument('--init', type=str)
  parser.add_argument('--ema_decay', type=float)
  parser.add_argument('--mse_weight', type=float)
  parser.add_argument('--mse_steps', type=int)
  parser.add_argument('--mask_url', type=str)
  parser.add_argument('--invert_mask', type=int)
  parser.add_argument('--soft_mask', type=int)
  parser.add_argument('--step_size', type=float)
  parser.add_argument('--cutn', type=int)
  parser.add_argument('--cut_pow', type=float)
  parser.add_argument('--image_file', type=str)
  parser.add_argument('--frame_dir', type=str)
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


DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()

















"""### Model Code"""

class SelfAttention(nn.Module):
    def __init__(self, d_model, n_heads=1):
        super().__init__()
        assert d_model % n_heads == 0
        self.n_heads = n_heads
        self.norm_in = nn.LayerNorm(d_model)
        self.qkv = nn.Linear(d_model, d_model * 3)
        self.out = nn.Linear(d_model, d_model)
        self.norm_out = nn.LayerNorm(d_model)

    def forward(self, x, padding_mask=None):
        n, s, d = x.shape
        head_size = d // self.n_heads
        x = self.norm_in(x)
        q, k, v = self.qkv(x).view([*x.shape[:-1], 3, self.n_heads, head_size]).unbind(-3)
        attn_logits = torch.einsum('...thd,...Thd->...htT', q, k) / head_size**0.5
        if padding_mask is not None:
            mask = padding_mask[:, None, None, :]
            attn_logits = torch.where(mask, attn_logits, attn_logits.new_tensor(-1e30))
        attn_weights = attn_logits.softmax(-1)
        attn = torch.einsum('...htT,...Thd->...thd', attn_weights, v)
        attn_vec = attn.reshape(x.shape)
        return self.norm_out(self.out(attn_vec))


class FeedForward(nn.Module):
    def __init__(self, d_model, d_ff):
        super().__init__()
        self.norm_in = nn.LayerNorm(d_model)
        self.linear_1 = nn.Linear(d_model, d_ff)
        self.act = nn.GELU()
        self.linear_2 = nn.Linear(d_ff, d_model)
        self.norm_out = nn.LayerNorm(d_model)

    def forward(self, x):
        x = self.norm_in(x)
        x = self.linear_1(x)
        x = self.act(x)
        x = self.linear_2(x)
        x = self.norm_out(x)
        return x


class TransformerEncoderLayer(nn.Module):
    def __init__(self, d_model, d_ff, n_heads):
        super().__init__()
        self.attn = SelfAttention(d_model, n_heads)
        self.ff = FeedForward(d_model, d_ff)

    def __call__(self, x, padding_mask=None):
        x = x + self.attn(x, padding_mask)
        x = x + self.ff(x)
        return x


class FourierFeatures(nn.Module):
    def __init__(self, in_features, out_features, std=1.):
        super().__init__()
        assert out_features % 2 == 0
        self.register_buffer('weight', torch.randn([out_features // 2, in_features]) * std)

    def forward(self, input):
        f = 2 * math.pi * input @ self.weight.T
        return torch.cat([f.cos(), f.sin()], dim=-1)

    
class CLIPDiffusionPrior(nn.Module):
    def __init__(self, embed_dim, feats_dim, d_model, n_layers):
        super().__init__()
        n_tokens = 4 + 77  # partially noised input embedding, timestep, unsafe, output prediction, text features
        self.x_t_proj = nn.Linear(embed_dim, d_model)
        self.timestep_embed = nn.Sequential(
            FourierFeatures(1, d_model, std=5),
            nn.Linear(d_model, d_model),
        )
        self.unsafe_embed = nn.Embedding(3, d_model)
        self.out_proj = nn.Linear(d_model, embed_dim)
        self.feats_in_proj = nn.Linear(feats_dim, d_model)
        self.register_buffer('null_text', clip.tokenize(''))
        self.register_buffer('null_unsafe', torch.tensor([2]))
        self.pos_embed = nn.Parameter(torch.randn([n_tokens, d_model]) / d_model**0.5)
        self.layers = nn.ModuleList([TransformerEncoderLayer(d_model, d_model * 4, d_model // 64) for _ in range(n_layers)])

    @staticmethod
    def preprocess(embed):
        return F.normalize(embed, dim=-1) * embed.shape[-1]**0.5

    def get_param_groups(self):
        matmuls = []
        non_matmuls = []
        for name, param in self.named_parameters():
            if name.startswith('layers') and 'weight' in name and 'norm' not in name:
                matmuls.append(param)
            else:
                non_matmuls.append(param)
        return matmuls, non_matmuls

    def forward(self, x_t, t, feats, feats_padding_mask, unsafe):
        n = x_t.shape[0]
        x_t_token = self.x_t_proj(x_t)[:, None]
        t_token = self.timestep_embed(t[:, None])[:, None]
        unsafe_token = self.unsafe_embed(unsafe)[:, None]
        out_token = torch.zeros_like(x_t_token)
        feats_tokens = self.feats_in_proj(feats)
        tokens = torch.cat([x_t_token, t_token, unsafe_token, out_token, feats_tokens], dim=1)
        padding_mask = torch.cat([feats_padding_mask.new_full([n, 4], True), feats_padding_mask], dim=1)
        x = tokens + self.pos_embed
        for layer in self.layers:
            x = layer(x, padding_mask)
        return self.out_proj(x[:, 3])
    
def encode_text_with_feats(self, text):
    x = self.token_embedding(text).type(self.dtype)  # [batch_size, n_ctx, d_model]

    x = x + self.positional_embedding.type(self.dtype)
    x = x.permute(1, 0, 2)  # NLD -> LND
    x = self.transformer(x)
    x = x.permute(1, 0, 2)  # LND -> NLD
    x = self.ln_final(x).type(self.dtype)

    return x


def make_padding_mask(text):
    eot_mask = text == 49407
    padding_mask = (torch.cumsum(eot_mask, dim=-1) == 0) | eot_mask
    
    return padding_mask


def pred_to_v(model):
    def model_fn(x, t, *args, **kwargs):
        alphas, sigmas = diff_utils.t_to_alpha_sigma(t)
        pred = model(x, t, *args, **kwargs)
        v = (x * alphas[:, None] - pred) / sigmas[:, None]
        return v
    return model_fn

"""### Model Code 2 & Utils"""

class EMATensor(nn.Module):
    """implmeneted by Katherine Crowson"""
    def __init__(self, tensor, decay):
        super().__init__()
        self.tensor = nn.Parameter(tensor)
        self.register_buffer('biased', torch.zeros_like(tensor))
        self.register_buffer('average', torch.zeros_like(tensor))
        self.decay = decay
        self.register_buffer('accum', torch.tensor(1.))
        self.update()
    
    @torch.no_grad()
    def update(self):
        if not self.training:
            raise RuntimeError('update() should only be called during training')

        self.accum *= self.decay
        self.biased.mul_(self.decay)
        self.biased.add_((1 - self.decay) * self.tensor)
        self.average.copy_(self.biased)
        self.average.div_(1 - self.accum)

    def forward(self):
        if self.training:
            return self.tensor
        return self.average


class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


replace_grad = ReplaceGrad.apply


class ClampWithGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input, min, max):
        ctx.min = min
        ctx.max = max
        ctx.save_for_backward(input)
        return input.clamp(min, max)

    @staticmethod
    def backward(ctx, grad_in):
        input, = ctx.saved_tensors
        return grad_in * (grad_in * (input - input.clamp(ctx.min, ctx.max)) >= 0), None, None


clamp_with_grad = ClampWithGrad.apply


def vector_quantize(x, codebook):
    d = x.pow(2).sum(dim=-1, keepdim=True) + codebook.pow(2).sum(dim=1) - 2 * x @ codebook.T
    indices = d.argmin(-1)
    x_q = F.one_hot(indices, codebook.shape[0]).to(d.dtype) @ codebook
    return replace_grad(x_q, x)


def spherical_dist(x, y):
    x_normed = F.normalize(x, dim=-1)
    y_normed = F.normalize(y, dim=-1)
    return x_normed.sub(y_normed).norm(dim=-1).div(2).arcsin().pow(2).mul(2)


class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))

    def forward(self, input):
        dists = spherical_dist(input.unsqueeze(1), self.embed.unsqueeze(0))
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()


def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])


def clamp(x, min_value, max_value):
    return max(min(x, max_value), min_value)


class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        # self.cut_pow = cut_pow
        self.augs = transforms.Compose([
            K.RandomHorizontalFlip(p=0.5),
            K.RandomAffine(degrees=15, translate=0.1, p=0.8, padding_mode='border', resample='bilinear'),
            K.RandomPerspective(0.4, p=0.7, resample='bilinear'),
            K.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1, p=0.7),
            K.RandomGrayscale(p=0.15),
        ])

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        long_size, short_size = max(sideX, sideY), min(sideX, sideY)
        min_size = min(short_size, self.cut_size)
        pad_x, pad_y = long_size - sideX, long_size - sideY
        input_zero_padded = F.pad(input, (pad_x, pad_x, pad_y, pad_y), 'constant')
        input_mask = F.pad(torch.zeros_like(input), (pad_x, pad_x, pad_y, pad_y), 'constant', 1.)
        input_padded = input_zero_padded + input_mask * input.mean(dim=[2, 3], keepdim=True)
        cutouts = []
        for cn in range(self.cutn):
            if cn >= self.cutn - self.cutn // 4:
                size = long_size
            else:
                size = clamp(int(short_size * torch.zeros([]).normal_(mean=.8, std=.3)), min_size, long_size)
            # size = int(torch.rand([])**self.cut_pow * (short_size - min_size) + min_size)
            offsetx = torch.randint(min(0, sideX - size), abs(sideX - size) + 1, ()) + pad_x
            offsety = torch.randint(min(0, sideY - size), abs(sideY - size) + 1, ()) + pad_y
            cutout = input_padded[:, :, offsety:offsety + size, offsetx:offsetx + size]
            # cutouts.append(F.adaptive_avg_pool2d(cutout, self.cut_size))
            cutouts.append(resize(cutout, out_shape=(self.cut_size, self.cut_size),by_convs=True, pad_mode='reflect'))
        return self.augs(torch.cat(cutouts))


class MPDecoder(Decoder):
    def __init__(self, devices, **kwargs):
        assert len(devices) == 2
        self.devices = devices
        super().__init__(**kwargs)
        self.to(devices[0])
        for module in self.up[0].block[1:]:
            module.to(devices[1])
        self.norm_out.to(devices[1])
        self.conv_out.to(devices[1])

    def forward(self, z):
        # assert z.shape[1:] == self.z_shape[1:]
        self.last_z_shape = z.shape

        # timestep embedding
        temb = None

        # z to block_in
        h = self.conv_in(z)

        # middle
        h = self.mid.block_1(h, temb)
        h = self.mid.attn_1(h)
        h = self.mid.block_2(h, temb)

        # upsampling
        for i_level in reversed(range(self.num_resolutions)):
            for i_block in range(self.num_res_blocks+1):
                if i_level == 0 and i_block == 1:
                    h = h.to(self.devices[1])
                h = self.up[i_level].block[i_block](h, temb)
                if len(self.up[i_level].attn) > 0:
                    h = self.up[i_level].attn[i_block](h)
            if i_level != 0:
                h = self.up[i_level].upsample(h)

        # end
        if self.give_pre_end:
            return h

        h = self.norm_out(h)
        h = h * torch.sigmoid(h)
        h = self.conv_out(h)
        return h


def load_vqgan_model(config_path, checkpoint_path, devices):
    assert len(devices) == 2
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        ddconfig = config.model.params.ddconfig
        model = vqgan.VQModel(**config.model.params)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        ddconfig = config.model.params.first_stage_config.params.ddconfig
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    model.to(devices[0])
    mp_decoder = MPDecoder(devices, **ddconfig)
    mp_decoder.load_state_dict(model.decoder.state_dict())
    model.decoder = mp_decoder
    model.requires_grad_(False).eval()
    return model


def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)


def save_image(t, name):
    TF.to_pil_image(t).save(name)


def fetch(url_or_path):
  if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
      r = requests.get(url_or_path)
      r.raise_for_status()
      fd = io.BytesIO()
      fd.write(r.content)
      fd.seek(0)
      return fd
  return open(url_or_path, 'rb')


def parse_prompt(prompt):
    if prompt.startswith('http://') or prompt.startswith('https://'):
        vals = prompt.rsplit(':', 3)
        vals = [vals[0] + ':' + vals[1], *vals[2:]]
    else:
        vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])

"""### Parameters For The Run

"""

prompt = args2.prompt #"the first day of the waters" #@param {type:"string"}
width = args2.sizex #256 #@param {type:"integer"}
height = args2.sizey #256 #@param {type:"integer"}
size = [width, height]

#@markdown the text conditioning scale for sampling from the prior
cond_scale = args2.cond_scale #1. #@param {type:"number"}

#@markdown Do you want to disable the prior? (No unless comparing to baseline VQGAN)
if args2.no_prior == 1:
    no_prior = True #@param {type:"boolean"}
else:
    no_prior = False #@param {type:"boolean"}

#@markdown take the best image embed of n
best_of_n = args2.best_of_n #2 #@param {type:"integer"}

#@markdown URL to the init image (optional)
init = args2.init #"" #@param {type: "string"}

#@markdown the EMA decay coefficient
ema_decay = args2.ema_decay #0.95 #@param {type:"number"}

#@markdown the initial weight for the MSE regularization
mse_weight = args2.mse_weight #0.2 #@param {type:"number"}

#@markdown the number of steps to decay the MSE regularization over
mse_steps = 200 #@param {type: "integer"}

#@markdown URL to the mask to use (optional)
mask_url = "" #@param {type: "string"}

#@markdown Invert the mask?
invert_mask = False #@param {type:"boolean"}

#@markdown use masked init weight instead of a hard mask
soft_mask = False #@param {type:"boolean"}

#@markdown the step size
step_size = args2.step_size #0.15 #@param {type:"number"}

#@markdown the number of cutouts
cutn = args2.cutn #64 #@param {type:"integer"}

#@markdown the cutout size power
cut_pow = args2.cut_pow #1. #@param {type:"number"}

#@markdown display image every this many steps
display_freq = args2.update #25 #@param {type:"integer"}

#@markdown the random seed
seed = args2.seed #-1 #@param {type: "integer"}

"""### Load Models"""

devices = [torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')]
devices = devices * 2

vqgan_model = "vqgan_imagenet_f16_16384"

# Can't choose CLIP model because trained for a particular prior
clip_model = "ViT-B/32" 

model = load_vqgan_model(vqgan_model + '.yaml', vqgan_model + '.ckpt', devices)
perceptor = clip.load(clip_model, jit=False)[0]
perceptor.to(devices[1]).eval().requires_grad_(False)
pool = futures.ThreadPoolExecutor()

clip_prior_ckpt = 'clip_prior_6_6370000.pth'
clip_prior = CLIPDiffusionPrior(perceptor.visual.output_dim, 512, 768, 12)
clip_prior.load_state_dict(torch.load(clip_prior_ckpt, map_location='cpu')['model_ema'])
clip_prior = clip_prior.to(devices[0]).eval().requires_grad_(False)

cut_size = perceptor.visual.input_resolution
e_dim = model.quantize.e_dim
f = 2**(model.decoder.num_resolutions - 1)
make_cutouts = MakeCutouts(cut_size, cutn)
n_toks = model.quantize.n_e
toksX, toksY = size[0] // f, size[1] // f
sideX, sideY = toksX * f, toksY * f
z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]

"""### Do The Run"""

def do_run():
    #if seed >= 0: # Change from -1 to use
    #    torch.manual_seed(seed)
    if init:
        pil_image = Image.open(fetch(init)).convert('RGB')
        pil_image = pil_image.resize((toksX * f, toksY * f), Image.LANCZOS)
        z, *_ = model.encode(TF.to_tensor(pil_image).to(devices[0]).unsqueeze(0) * 2 - 1)
    else:
        one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=devices[0]), n_toks)
        z = one_hot.float() @ model.quantize.embedding.weight
        z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)

    def get_mse_weight(i):
        ramp_pos = max(1 - i / mse_steps, 0.)
        return ramp_pos * mse_weight

    z = EMATensor(z, ema_decay)
    opt = optim.Adam(z.parameters(), lr=step_size)

    if mask_url:
        pil_image = Image.open(fetch(mask_url))
        if 'A' in pil_image.getbands():
            pil_image = pil_image.getchannel('A')
        elif 'L' in pil_image.getbands():
            pil_image = pil_image.getchannel('L')
        else:
            print('Mask must have an alpha channel or be one channel', file=sys.stderr)
            sys.exit(1)
        mask = TF.to_tensor(pil_image.resize((toksX, toksY), Image.BILINEAR))
        mask = mask.to(devices[0]).unsqueeze(0)
        if not soft_mask:
            mask = mask.lt(0.5).float()
    else:
        mask = torch.ones([], device=devices[0])
    if invert_mask:
        mask = 1 - mask

    normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                     std=[0.26862954, 0.26130258, 0.27577711])

    pMs = []
    spatial_images = []

    text_toks = clip.tokenize(prompt, truncate=True).to(devices[0])
    text_embed = perceptor.encode_text(text_toks).float()
    text_feats = encode_text_with_feats(perceptor, text_toks).float().repeat([best_of_n, 1, 1])
    text_padding = make_padding_mask(text_toks).repeat([best_of_n, 1])
    unsafe = torch.full([best_of_n], 0, device=devices[0])
    null_feats = encode_text_with_feats(perceptor, clip_prior.null_text).float()
    null_padding = make_padding_mask(clip_prior.null_text)
    null_unsafe = unsafe[:1]


    def cfg_model_fn(x, t, feats, feats_padding_mask, unsafe):
        n = x.shape[0]
        x_in = torch.cat([x, x])
        t_in = torch.cat([t, t])
        feats_in = torch.cat([null_feats.repeat([n, 1, 1]), text_feats])
        padding_in = torch.cat([null_padding.repeat([n, 1]), text_padding])
        unsafe_in = torch.cat([null_unsafe.repeat([n]), unsafe])
        v_uncond, v_cond = pred_to_v(clip_prior)(x_in, t_in, feats_in, padding_in, unsafe_in).chunk(2, dim=0)
        return v_uncond + (v_cond - v_uncond) * cond_scale

    model_fn = cfg_model_fn
    # model_fn = pred_to_v(clip_prior)

    if no_prior:
        target_embed = text_embed
    else:
        noise = torch.randn([best_of_n, text_embed.shape[1]], device=devices[0])
        t = torch.linspace(1, 0, 1000 + 1)[:-1]
        steps = diff_utils.get_spliced_ddpm_cosine_schedule(t)
        extra_args = {'feats': text_feats, 'feats_padding_mask': text_padding, 'unsafe': unsafe}
        target_embeds = sampling.sample(pred_to_v(clip_prior), noise, steps, 1., extra_args)
        target_embeds = target_embeds.view([best_of_n, 1, -1])
        best_embeds = torch.cosine_similarity(target_embeds, text_embed, dim=-1).argmax(0)
        target_embed = target_embeds[best_embeds, torch.arange(1, device=devices[0])]
    pMs.append(Prompt(target_embed))

    def synth(z):
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)
        return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

    @torch.no_grad()
    def checkin(i, losses):

        sys.stdout.flush()
        sys.stdout.write('Saving progress ...\n')
        sys.stdout.flush()

        losses_i = [loss.item() for loss in losses]
        losses_str = ', '.join(f'{loss:g}' for loss in losses_i)
        #tqdm.write(f'i: {i}, loss: {sum(losses_i):g}, losses: {losses_str}')
        out = synth(z.average)
        #save_image(out[0], 'progress.png')
        save_image(out[0], args2.image_file)
        #display.display(display.Image('progress.png'))

        sys.stdout.flush()
        sys.stdout.write('Progress saved\n')
        sys.stdout.flush()

    def ascend_txt(i):
        out = synth(z())
        seed = torch.randint(2**63 - 1, [])

        with torch.random.fork_rng():
            torch.manual_seed(seed)
            iii = perceptor.encode_image(normalize(make_cutouts(out))).float()

        si_embeds = []
        for image, weight, stop in spatial_images:
            with torch.random.fork_rng():
                torch.manual_seed(seed)
                si_embed = perceptor.encode_image(normalize(make_cutouts(image))).float()
            si_embeds.append((si_embed, torch.tensor(weight), torch.tensor(stop)))

        result = []

        mse_weight = get_mse_weight(i)
        diffs = z().pow(2).mean() / 2
        result.append(diffs * mse_weight)

        for prompt in pMs:
            result.append(prompt(iii))

        for embeds, weight, stop in si_embeds:
            dists = spherical_dist(iii, embeds) * weight.sign()
            result.append(weight.abs() * replace_grad(dists, torch.maximum(dists, stop)).mean())

        return result

    def train(i):
        opt.zero_grad()
        loss_all = ascend_txt(i)
        loss_all_d = [loss.to(loss_all[0].device) for loss in loss_all]
        if (i+1) % display_freq == 0:
            checkin(i, loss_all_d)
        loss = sum(loss_all_d)
        loss.backward()
        opt.step()
        with torch.no_grad():
            z.tensor.copy_(z.tensor.maximum(z_min).minimum(z_max))
        z.update()

    """
    i = 0
    try:
        with tqdm() as pbar:
            while True:
                train(i)
                i += 1
                pbar.update()
    except KeyboardInterrupt:
        pass
    """

    for i in range(args2.iterations):
        sys.stdout.write(f'Iteration {i+1}\n')
        sys.stdout.flush()
   
        train(i)

    
    
    
    
gc.collect()
do_run()