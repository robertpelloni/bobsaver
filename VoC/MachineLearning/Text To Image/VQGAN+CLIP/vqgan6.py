# Mse regulized Modified_VQGANCLIP_zquantize public.ipynb
# Original file is located at https://colab.research.google.com/drive/1gFn9u3oPOgsNzJWEFmdK-N9h_y65b8fj

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
import math
from pathlib import Path

sys.path.append('./taming-transformers')

#from IPython import display
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
import numpy as np
from CLIP.clip import clip
import kornia.augmentation as K

#In Script Movement
sys.path.append('../')
from image_warping import do_image_warping
from torchvision.transforms import functional as TF

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--msezeros', type=bool, help='MSE with zeros.')
  parser.add_argument('--msequantize', type=bool, help='MSE quantize.')
  parser.add_argument('--msedecayrate', type=int, help='MSE decay rate.')
  parser.add_argument('--mseepochs', type=int, help='MSE epochs.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  parser.add_argument('--r', type=float, help='In script movement. Rotation in degrees.')
  parser.add_argument('--z', type=int, help='In script movement. Zoom in pixels.')
  parser.add_argument('--px', type=int, help='In script movement. Pan X in pixels.')
  parser.add_argument('--py', type=int, help='In script movement. Pan Y in pixels.')
  parser.add_argument('--w', type=int, help='In script movement. Warp in pixels.')
  args = parser.parse_args()
  return args

args2=parse_args();

args = argparse.Namespace(
    #prompts=["a photo-realistic and beautiful painting of an old man sitting on a chair next to a giant iceberg and looking at a green lush landscape."],
    prompts=[args2.prompt],
    size=[args2.sizex, args2.sizey], 
    init_image= args2.seed_image,
    init_weight= 0.5,
    steps=args2.iterations,
    # clip model settings
    clip_model=args2.clip_model,
    vqgan_config=f'{args2.vqgan_model}.yaml',
    vqgan_checkpoint=f'{args2.vqgan_model}.ckpt',
    step_size=args2.learning_rate,
    # cutouts / crops
    cutn=args2.cutn,
    cut_pow=args2.cut_power,
    # display
    display_freq=args2.update,
    seed=args2.seed,
    use_augs = True,
    noise_fac= 0.1,
    ema_val = 0.99,
    record_generation=True,
    # noise and other constraints
    use_noise = None,
    constraint_regions = False,#
    # add noise to embedding
    noise_prompt_weights = None,
    noise_prompt_seeds = [14575],#
    # mse settings
    mse_withzeros = args2.msezeros,
    mse_decay_rate = args2.msedecayrate,
    mse_epoches = args2.mseepochs,
    mse_quantize = args2.msequantize,
)


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









# Commented out IPython magic to ensure Python compatibility.
def noise_gen(shape):
    n, c, h, w = shape
    noise = torch.zeros([n, c, 1, 1])
    for i in reversed(range(5)):
        h_cur, w_cur = h // 2**i, w // 2**i
        noise = F.interpolate(noise, (h_cur, w_cur), mode='bicubic', align_corners=False)
        noise += torch.randn([n, c, h_cur, w_cur]) / 5
    return noise


def sinc(x):
    return torch.where(x != 0, torch.sin(math.pi * x) / (math.pi * x), x.new_ones([]))


def lanczos(x, a):
    cond = torch.logical_and(-a < x, x < a)
    out = torch.where(cond, sinc(x) * sinc(x/a), x.new_zeros([]))
    return out / out.sum()


def ramp(ratio, width):
    n = math.ceil(width / ratio + 1)
    out = torch.empty([n])
    cur = 0
    for i in range(out.shape[0]):
        out[i] = cur
        cur += ratio
    return torch.cat([-out[1:].flip([0]), out])[1:-1]


def resample(input, size, align_corners=True):
    n, c, h, w = input.shape
    dh, dw = size

    input = input.view([n * c, 1, h, w])

    if dh < h:
        kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
        pad_h = (kernel_h.shape[0] - 1) // 2
        input = F.pad(input, (0, 0, pad_h, pad_h), 'reflect')
        input = F.conv2d(input, kernel_h[None, None, :, None])

    if dw < w:
        kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
        pad_w = (kernel_w.shape[0] - 1) // 2
        input = F.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
        input = F.conv2d(input, kernel_w[None, None, None, :])

    input = input.view([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)
    

# def replace_grad(fake, real):
#     return fake.detach() - real.detach() + real


class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


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

replace_grad = ReplaceGrad.apply

clamp_with_grad = ClampWithGrad.apply
# clamp_with_grad = torch.clamp

def vector_quantize(x, codebook):
    d = x.pow(2).sum(dim=-1, keepdim=True) + codebook.pow(2).sum(dim=1) - 2 * x @ codebook.T
    indices = d.argmin(-1)
    x_q = F.one_hot(indices, codebook.shape[0]).to(d.dtype) @ codebook
    return replace_grad(x_q, x)


class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))

    def forward(self, input):
        
        input_normed = F.normalize(input.unsqueeze(1), dim=2)#(input / input.norm(dim=-1, keepdim=True)).unsqueeze(1)# 
        embed_normed = F.normalize((self.embed).unsqueeze(0), dim=2)#(self.embed / self.embed.norm(dim=-1, keepdim=True)).unsqueeze(0)#

        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()


def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])

def one_sided_clip_loss(input, target, labels=None, logit_scale=100):
    input_normed = F.normalize(input, dim=-1)
    target_normed = F.normalize(target, dim=-1)
    logits = input_normed @ target_normed.T * logit_scale
    if labels is None:
        labels = torch.arange(len(input), device=logits.device)
    return F.cross_entropy(logits, labels)

class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

        self.av_pool = nn.AdaptiveAvgPool2d((self.cut_size, self.cut_size))
        self.max_pool = nn.AdaptiveMaxPool2d((self.cut_size, self.cut_size))

    def set_cut_pow(self, cut_pow):
      self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        cutouts_full = []
        
        min_size_width = min(sideX, sideY)
        lower_bound = float(self.cut_size/min_size_width)
        
        for ii in range(self.cutn):
            
            
          # size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
          size = int(min_size_width*torch.zeros(1,).normal_(mean=.8, std=.3).clip(lower_bound, 1.)) # replace .5 with a result for 224 the default large size is .95
          # size = int(min_size_width*torch.zeros(1,).normal_(mean=.9, std=.3).clip(lower_bound, .95)) # replace .5 with a result for 224 the default large size is .95

          offsetx = torch.randint(0, sideX - size + 1, ())
          offsety = torch.randint(0, sideY - size + 1, ())
          cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
          cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))

        
        cutouts = torch.cat(cutouts, dim=0)

        # if args.use_augs:
        #   cutouts = augs(cutouts)

        # if args.noise_fac:
        #   facs = cutouts.new_empty([cutouts.shape[0], 1, 1, 1]).uniform_(0, args.noise_fac)
        #   cutouts = cutouts + facs * torch.randn_like(cutouts)
        

        return clamp_with_grad(cutouts, 0, 1)


def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = vqgan.VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.eval().requires_grad_(False)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    elif config.model.target == 'taming.models.vqgan.GumbelVQ':
        model = vqgan.GumbelVQ(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model

def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)

class TVLoss(nn.Module):
    def forward(self, input):
        input = F.pad(input, (0, 1, 0, 1), 'replicate')
        x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
        y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
        diff = x_diff**2 + y_diff**2 + 1e-8
        return diff.mean(dim=1).sqrt().mean()

class GaussianBlur2d(nn.Module):
    def __init__(self, sigma, window=0, mode='reflect', value=0):
        super().__init__()
        self.mode = mode
        self.value = value
        if not window:
            window = max(math.ceil((sigma * 6 + 1) / 2) * 2 - 1, 3)
        if sigma:
            kernel = torch.exp(-(torch.arange(window) - window // 2)**2 / 2 / sigma**2)
            kernel /= kernel.sum()
        else:
            kernel = torch.ones([1])
        self.register_buffer('kernel', kernel)

    def forward(self, input):
        n, c, h, w = input.shape
        input = input.view([n * c, 1, h, w])
        start_pad = (self.kernel.shape[0] - 1) // 2
        end_pad = self.kernel.shape[0] // 2
        input = F.pad(input, (start_pad, end_pad, start_pad, end_pad), self.mode, self.value)
        input = F.conv2d(input, self.kernel[None, None, None, :])
        input = F.conv2d(input, self.kernel[None, None, :, None])
        return input.view([n, c, h, w])

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

# %mkdir /content/vids


mse_decay = 0
if args.init_weight:
  mse_decay = args.init_weight / args.mse_epoches

# <AUGMENTATIONS>
augs = nn.Sequential(
    
    K.RandomHorizontalFlip(p=0.5),
    K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
    K.RandomPerspective(0.2,p=0.4, ),
    K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),

    )

noise = noise_gen([1, 3, args.size[0], args.size[1]])
image = TF.to_pil_image(noise.div(5).add(0.5).clamp(0, 1)[0])
#image.save('init3.png')

"""# Constraints"""

from PIL import Image, ImageDraw

if args.constraint_regions and args.init_image:
  
  device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
  print('Using device:', device)
  print(torch.cuda.get_device_properties(device))


  toksX, toksY = args.size[0] // 16, args.size[1] // 16

  pil_image = Image.open(args.init_image).convert('RGB')
  pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)

  width, height = pil_image.size

  d = ImageDraw.Draw(pil_image)
  for i in range(0,width,16):
      d.text((i+4,0), f"{int(i/16)}", fill=(50,200,100))
  for i in range(0,height,16):
      d.text((4,i), f"{int(i/16)}", fill=(50,200,100))

  pil_image = TF.to_tensor(pil_image)

  print(pil_image.shape)
  for i in range(pil_image.shape[1]):
    for j in range(pil_image.shape[2]):
      if i%16 == 0 or j%16 ==0:
        pil_image[:,i,j] = 0

  # select region
  c_h = [16,32]
  c_w = [0,40]

  c_hf = [i*16 for i in c_h]
  c_wf = [i*16 for i in c_w]

  pil_image[0,c_hf[0]:c_hf[1],c_wf[0]:c_wf[1]] = 0

  TF.to_pil_image(pil_image.cpu()).save('progress.png')
  display.display(display.Image('progress.png'))

  z_mask = torch.zeros([1, 256, int(height/16), int(width/16)]).to(device)
  z_mask[:,:,c_h[0]:c_h[1],c_w[0]:c_w[1]] = 1

"""### Actually do the run..."""

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

print('Using device:', device)
print('using prompts: ', args.prompts)

tv_loss = TVLoss() 

sys.stdout.write("Loading VQGAN model "+args.vqgan_checkpoint+" ...\n")
sys.stdout.flush()

model = load_vqgan_model(args.vqgan_config, args.vqgan_checkpoint).to(device)

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)
mse_weight = args.init_weight

cut_size = perceptor.visual.input_resolution
# e_dim = model.quantize.e_dim

if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
    e_dim = 256
    n_toks = model.quantize.n_embed
    z_min = model.quantize.embed.weight.min(dim=0).values[None, :, None, None]
    z_max = model.quantize.embed.weight.max(dim=0).values[None, :, None, None]
elif args.vqgan_checkpoint == 'rudalle.ckpt':
    e_dim = 256
    n_toks = model.quantize.n_embed
    z_min = model.quantize.embed.weight.min(dim=0).values[None, :, None, None]
    z_max = model.quantize.embed.weight.max(dim=0).values[None, :, None, None]
else:
    e_dim = model.quantize.e_dim
    n_toks = model.quantize.n_e
    z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
    z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]


make_cutouts = MakeCutouts(cut_size, args.cutn, cut_pow=args.cut_pow)

f = 2**(model.decoder.num_resolutions - 1)
toksX, toksY = args.size[0] // f, args.size[1] // f

if args.seed is not None:
    torch.manual_seed(args.seed)

if args.init_image:
    pil_image = Image.open(args.init_image).convert('RGB')
    pil_image = pil_image.resize((toksX * 16, toksY * 16), Image.LANCZOS)
    pil_image = TF.to_tensor(pil_image)
    if args.use_noise:
      pil_image = pil_image + args.use_noise * torch.randn_like(pil_image) 
    z, *_ = model.encode(pil_image.to(device).unsqueeze(0) * 2 - 1)

else:
    
    one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()

    if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
        z = one_hot @ model.quantize.embed.weight
    elif args.vqgan_checkpoint == 'rudalle.ckpt':
        z = one_hot @ model.quantize.embed.weight
    else:
        z = one_hot @ model.quantize.embedding.weight
    z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)


z = EMATensor(z, args.ema_val)

z.requires_grad_(True)

if args.mse_withzeros and not args.init_image:
  z_orig = torch.zeros_like(z.tensor)
else:
  z_orig = z.tensor.clone()


opt = optim.Adam(z.parameters(), lr=args.step_size, weight_decay=0.00000000)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

pMs = []

if args.noise_prompt_weights and args.noise_prompt_seeds:
  for seed, weight in zip(args.noise_prompt_seeds, args.noise_prompt_weights):
    gen = torch.Generator().manual_seed(seed)
    embed = torch.empty([1, perceptor.visual.output_dim]).normal_(generator=gen)
    pMs.append(Prompt(embed, weight).to(device))

for prompt in args.prompts:
    txt, weight, stop = parse_prompt(prompt)
    embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))
    # pMs[0].embed = pMs[0].embed + Prompt(embed, weight, stop).embed.to(device)


def synth(z, quantize=True):
    if args.constraint_regions:
      z = replace_grad(z, z * z_mask)

    if quantize:
      if args.vqgan_checkpoint == 'vqgan_openimages_f16_8192.ckpt':
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embed.weight).movedim(3, 1)
      elif args.vqgan_checkpoint == 'rudalle.ckpt':
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embed.weight).movedim(3, 1)
      else:
        z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)

    else:
      z_q = z.model

    return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

@torch.no_grad()
def checkin(i, losses):
    global z
    global opt
    
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
    out = synth(z.average, True)
    #TF.to_pil_image(out[0].cpu()).save('progress.png')
    outim=TF.to_pil_image(out[0].cpu()).resize((args2.sizex, args2.sizey), Image.LANCZOS)
    outim.save(args2.image_file)
    
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
        outim.save(save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    
    #In Script Movement - make sure "global z" and "global opt" are defined
    if args2.r is not None:
        #do_image_warping(Image.fromarray(im_arr),r,z,px,py,w):  
        im_arr = np.array(out.cpu().squeeze().detach().permute(1, 2, 0)*255).astype(np.uint8)
        im_arr = do_image_warping(im_arr,args2.r,args2.z,args2.px,args2.py,args2.w)
        #convert warped image array back into the optimizer for the next iteration
        z, *_ = model.encode(TF.to_tensor(im_arr).to(device).unsqueeze(0) * 2 - 1)

        z.requires_grad_(True)
        #opt = optim.Adam([z], lr=args.step_size)
        #opt = optim.Adam(z.parameters(), lr=args.step_size, weight_decay=0.00000000)
        opt = optim.Adam([z], lr=args.step_size, weight_decay=0.00000000)
    

def ascend_txt():
    global mse_weight

    out = synth(z.tensor)

    if args.record_generation:
      with torch.no_grad():
        global vid_index
        out_a = synth(z.average, True)
        #TF.to_pil_image(out_a[0].cpu()).save(f'/content/vids/{vid_index}.png')
        #TF.to_pil_image(out_a[0].cpu()).save('Progress2.png')
        vid_index += 1

    cutouts = make_cutouts(out)

    if args.use_augs:
      cutouts = augs(cutouts)

    if args.noise_fac:
      facs = cutouts.new_empty([args.cutn, 1, 1, 1]).uniform_(0, args.noise_fac)
      cutouts = cutouts + facs * torch.randn_like(cutouts)

    iii = perceptor.encode_image(normalize(cutouts)).float()

    result = []

    if args.init_weight:
        
        global z_orig
        
        result.append(F.mse_loss(z.tensor, z_orig) * mse_weight / 2)
        # result.append(F.mse_loss(z, z_orig) * ((1/torch.tensor((i)*2 + 1))*mse_weight) / 2)

        with torch.no_grad():
          if i > 0 and i%args.mse_decay_rate==0 and i <= args.mse_decay_rate*args.mse_epoches:

            if args.mse_quantize:
              z_orig = vector_quantize(z.average.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)#z.average
            else:
              z_orig = z.average.clone()

            if mse_weight - mse_decay > 0 and mse_weight - mse_decay >= mse_decay:
              mse_weight = mse_weight - mse_decay
              print(f"updated mse weight: {mse_weight}")
            else:
              mse_weight = 0
              print(f"updated mse weight: {mse_weight}")

    for prompt in pMs:
        result.append(prompt(iii))

    return result

vid_index = 0
def train(i):
    opt.zero_grad()
    lossAll = ascend_txt()

    sys.stdout.write("Iteration {}".format(i)+"\n")
    sys.stdout.flush()
    
    if i % args.display_freq == 0:
        checkin(i, lossAll)
    
    loss = sum(lossAll)

    loss.backward()
    opt.step()
    z.update()



sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt = 1
for i in range(args.steps):
    train(itt)
    itt+=1

