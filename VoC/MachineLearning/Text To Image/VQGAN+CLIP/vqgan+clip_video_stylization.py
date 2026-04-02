# VQGAN+CLIP Video Stylization.ipynb
# Original file is located at https://colab.research.google.com/drive/1q3rSNfmo-6d4eIltmsJgtD7tz52mR2k7

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#@title Imports and some useful functions
import argparse
import math
from pathlib import Path
 
sys.path.append('./taming-transformers')
from IPython import display
from base64 import b64encode
from omegaconf import OmegaConf
from PIL import Image
from taming.models import cond_transformer, vqgan
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
#from tqdm.notebook import tqdm
 
from CLIP.clip import clip
import kornia.augmentation as K
import numpy as np
import imageio
from PIL import ImageFile, Image
import json
import torchvision
ImageFile.LOAD_TRUNCATED_IMAGES = True

 
sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to stylize video with')
  parser.add_argument('--source_frames', type=str, help='Directory containing source frames')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts.')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--frame_count', type=int, help='How many source frames are there')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to use.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to use.')
  parser.add_argument('--clip_weight', type=float, help='Factor for how much the resulting image matches the source video frames.')
  parser.add_argument('--lrate', type=float, help='Learning rate.')
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
 
 
class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))
 
    def forward(self, input):
        input_normed = F.normalize(input.unsqueeze(1), dim=2)
        embed_normed = F.normalize(self.embed.unsqueeze(0), dim=2)
        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()
 
 
def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])
 
 
class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow
        self.augs = nn.Sequential(
            K.RandomHorizontalFlip(p=0.5),
            # K.RandomSolarize(0.01, 0.01, p=0.7),
            K.RandomSharpness(0.3,p=0.4),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
            K.RandomPerspective(0.2,p=0.4),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7))
        self.noise_fac = 0.1
 
 
    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        for _ in range(self.cutn):
            size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        batch = self.augs(torch.cat(cutouts, dim=0))
        if self.noise_fac:
            facs = batch.new_empty([self.cutn, 1, 1, 1]).uniform_(0, self.noise_fac)
            batch = batch + facs * torch.randn_like(batch)
        return batch
 
 
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
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model
 
 
def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)

#@title Setting things up for the content loss
# From https://gist.github.com/alper111/8233cdb0414b4cb5853f2f730ab95a49
class VGGPerceptualLoss(torch.nn.Module):
    def __init__(self, resize=True):
        super(VGGPerceptualLoss, self).__init__()
        blocks = []
        blocks.append(torchvision.models.vgg16(pretrained=True).features[:4].eval())
        blocks.append(torchvision.models.vgg16(pretrained=True).features[4:9].eval())
        blocks.append(torchvision.models.vgg16(pretrained=True).features[9:16].eval())
        blocks.append(torchvision.models.vgg16(pretrained=True).features[16:23].eval())
        for bl in blocks:
            for p in bl:
                p.requires_grad = False
        self.blocks = torch.nn.ModuleList(blocks)
        self.transform = torch.nn.functional.interpolate
        self.resize = resize
        self.register_buffer("mean", torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1))

    def forward(self, input, target, feature_layers=[0, 1, 2, 3], style_layers=[]):
        if input.shape[1] != 3:
            input = input.repeat(1, 3, 1, 1)
            target = target.repeat(1, 3, 1, 1)
        input = (input-self.mean) / self.std
        target = (target-self.mean) / self.std
        if self.resize:
            input = self.transform(input, mode='bilinear', size=(224, 224), align_corners=False)
            target = self.transform(target, mode='bilinear', size=(224, 224), align_corners=False)
        loss = 0.0
        x = input
        y = target
        for i, block in enumerate(self.blocks):
            x = block(x)
            y = block(y)
            if i in feature_layers:
                loss += torch.nn.functional.l1_loss(x, y)
            if i in style_layers:
                act_x = x.reshape(x.shape[0], x.shape[1], -1)
                act_y = y.reshape(y.shape[0], y.shape[1], -1)
                gram_x = act_x @ act_x.permute(0, 2, 1)
                gram_y = act_y @ act_y.permute(0, 2, 1)
                loss += torch.nn.functional.l1_loss(gram_x, gram_y)
        return loss

sys.stdout.write("Setting up content loss ...\n")
sys.stdout.flush()

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

content_loss = VGGPerceptualLoss()
content_loss.to(device)

#print('VGG network for content loss initialized')

"""# Setting parameters and getting things ready

First we need to break our video into frames which the system will use as targets. Here's how you can do this using ffmpeg. replace `/content/demo_video.mp4` with the path to your video (upload it through the side panel).
"""

#!mkdir -p guide_frames
#!ffmpeg -v 0 -i /content/demo_video.mp4 guide_frames/img%04d.png > /dev/null # Modify for your video. Use `-ss 1 -t 3 ` to only convert a 3-second clip starting from 1 second in

"""Now we can set a few parameters and set it running!"""

# The most important parameter: what prompt shall we use with CLIP?
# style_prompt = "An oil painting of psychedelic jellyfish in bright colours"
style_prompt = args.prompt

# Some other parameters to play with
max_iter = args.iterations*args.frame_count # This determines the length of your clip (which will be max_iter//save_every frames long)
width = args.sizex
height = args.sizey
display_progress_every = args.update # How often should it show an image in the cell output?
save_every = args.iterations # How often should it save an image for the output animation
advance_frame_every = args.iterations # How many iterations should it spend on each video frame
initialize_with_first_frame = True # If true, starts by encoding the first frame. If false, begins with noise.
cl_weight = args.clip_weight # How much should we consider the content loss. Higher -> more closely follows the video 

# Some additional paramemets
step_size = 0.1 # The 'learning rate', or how much we modify z each iteration
cutn = args.cutn # CLIP runs on multiple cutouts from the main image (this seems to improve results). Lower -> more speed
cut_pow = args.cut_power

framecount = 1

"""# Running the code"""

#@title getting the model ready
# Set device
#device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
#print('Using device:', device)

# Load models

vqgan_config=f'{args.vqgan_model}.yaml'
vqgan_checkpoint=f'{args.vqgan_model}.ckpt'

sys.stdout.write("Loading VQGAN model "+vqgan_checkpoint+" ...\n")
sys.stdout.flush()

model = load_vqgan_model(vqgan_config, vqgan_checkpoint).to(device)

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

# Setup ??
cut_size = perceptor.visual.input_resolution
e_dim = model.quantize.e_dim
f = 2**(model.decoder.num_resolutions - 1)
make_cutouts = MakeCutouts(cut_size, cutn, cut_pow=cut_pow)
n_toks = model.quantize.n_e
toksX, toksY = width // f, height // f
sideX, sideY = toksX * f, toksY * f
z_min = model.quantize.embedding.weight.min(dim=0).values[None, :, None, None]
z_max = model.quantize.embedding.weight.max(dim=0).values[None, :, None, None]

sys.stdout.write("Setting initial image ...\n")
sys.stdout.flush()

#@title Run it!
# Init
if initialize_with_first_frame:
  # encode the first frame to give us starting z
  #pil_image = Image.open('./content/guide_frames/img0001.png').convert('RGB')
  pil_image = Image.open(args.source_frames+'img0001.png').convert('RGB')
  pil_image = pil_image.resize((width, height), Image.LANCZOS)
  z, *_ = model.encode(TF.to_tensor(pil_image).to(device).unsqueeze(0) * 2 - 1)
else:
  # Use noise 
  one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
  z = one_hot @ model.quantize.embedding.weight
  z = z.view([-1, toksY, toksX, e_dim]).permute(0, 3, 1, 2)

z_orig = z.clone()
z.requires_grad_(True)
opt = optim.Adam([z], lr=step_size)

# create the prompts
pMs = []

#text
txt, weight, stop = parse_prompt(style_prompt)
embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
pMs.append(Prompt(embed, weight, stop).to(device))
# << space to add more

# Set up content target
#pil_image = Image.open('./content/guide_frames/img0001.png').convert('RGB')
pil_image = Image.open(args.source_frames+'img0001.png').convert('RGB')
pil_image = pil_image.resize((width, height), Image.LANCZOS)
target = TF.to_tensor(pil_image).to(device).unsqueeze(0)


def synth(z):
    z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)
    return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

@torch.no_grad()
def checkin(i, losses):
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
    out = synth(z)
    TF.to_pil_image(out[0].cpu()).save('Progress.png')
    #display.display(display.Image('progress.png'))
    
    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    

def ascend_txt(target=None):
    global i
    global framecount
    global itt

    # Get im and embed
    out = synth(z)
    iii = perceptor.encode_image(normalize(make_cutouts(out))).float()

    # Calculate loss(es) on prompts
    result = []
    for prompt in pMs:
        result.append(prompt(iii))

    # Content loss
    #original method
    result.append(cl_weight * content_loss(out, target, feature_layers=[2, 3]))
    #alternate method, needs a lower cl_weight, no real noticable improvment
    #result.append(cl_weight * content_loss(out, target, feature_layers=[0, 1, 2, 3]))
    

    # Store im if needed
    
    if i % save_every == 0:
      sys.stdout.flush()
      sys.stdout.write("Saving next frame ...\n")
      sys.stdout.flush()
      
      img = np.array(out.mul(255).clamp(0, 255)[0].cpu().detach().numpy().astype(np.uint8))[:,:,:]
      img = np.transpose(img, (1, 2, 0))
      #filename = f"steps/{int(i/save_every):04}.png"
      filename = "Frame.png"
      imageio.imwrite(filename, np.array(img))
    
      sys.stdout.flush()
      sys.stdout.write("Frame saved\n")
      sys.stdout.flush()
      
      framecount=framecount+1
      itt=0
      
    
    return result

def train(i, target=None):
    opt.zero_grad()
    lossAll = ascend_txt(target)
    if i % display_progress_every == 0:
        checkin(i, lossAll)
    loss = sum(lossAll)
    loss.backward()
    opt.step()
    with torch.no_grad():
        z.copy_(z.maximum(z_min).minimum(z_max))

i = 0
itt =0
try:
    #with tqdm() as pbar:
        while True:
            sys.stdout.write(f"Total {i}/{max_iter} Frame {framecount} Iteration {itt}\n")
            sys.stdout.flush()
            train(i, target)
            if i%advance_frame_every == 0:
              fname = f'{args.source_frames}img{1+(i//advance_frame_every):04}.png'
              sys.stdout.write("Setting initial image to "+fname+"\n")
              sys.stdout.flush()
              
              # Update the image target with the appropriate video frame
              #pil_image = Image.open(f'./content/guide_frames/img{1+(i//advance_frame_every):04}.png').convert('RGB')
              pil_image = Image.open(f'{args.source_frames}img{1+(i//advance_frame_every):04}.png').convert('RGB')
              
              pil_image = pil_image.resize((width, height), Image.LANCZOS)
              target = TF.to_tensor(pil_image).to(device).unsqueeze(0)

            if i == max_iter:
                break
            i += 1
            itt += 1
            #pbar.update()
except KeyboardInterrupt:
    pass

"""# Creating a video with the result

Run this code to take the images we saved in the `steps` folder and turn them into a video. `-r` specifies the framerate - here I use 10fps but you can customise that as you please :)
"""

#!ffmpeg -v 0 -i steps/%04d.png -r 10 video_out.mp4

"""# Things to explore

- Experiment starting with the frist frame of the video (`initialize_with_first_frame=True`) and changing the content loss weight `cl_weight`. 
- Mess with `advance_frame_every` to give it more iterations to match each video frame (useful for capturing fast motion).
- Try including the subject matter of the video in the prompt

If you're curious and want to see a video while the code is still running, open the terminal and paste an ffmpeg command (like `ffmpeg -v 0 -i steps/%04d.png -r 50 video_progress_50fps.mp4`) - this won't stop the main thread and lets you download and view a video made from whatever frames have already been generated.

Some other points of interet for the technical folk:

In `ascend_txt` we calculate the content loss as `cl_weight * content_loss(out, target, feature_layers=[2, 3])`. You could try using `feature_layers=[0, 1, 2, 3]` for example (see the content loss code for more inspiration). Note that using more layers gives a bigger value so you'll want to make cl_weight smaller to keep it in a useful range compared to the loss from CLIP.

You could work on adding more text prompts and some image prompts for CLIP to use. For each, just add

`#text(s)
txt, weight, stop = parse_prompt("Phychoactive rainbow colorful jellyfish oil painting trending on artstation")
embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
pMs.append(Prompt(embed, weight, stop).to(device))`

for a text prompt or 

`path, weight, stop = parse_prompt('/content/prompt_image.png')
img = resize_image(Image.open(path).convert('RGB'), (sideX, sideY))
batch = make_cutouts(TF.to_tensor(img).unsqueeze(0).to(device))
embed = perceptor.encode_image(normalize(batch)).float()
pMs.append(Prompt(embed, weight, stop).to(device))`

for an image. Paste the code after # << space to add more in the 'Run It' cell.


You can also choose to only start advancing the target video frames after, say, 100 iterations. This stops you loosing the first few video frames in the noise when starting without an init image.
"""

