# colab_clip_guided_diff_hq.ipynb
# Original file is located at https://colab.research.google.com/github/afiaka87/clip-guided-diffusion/blob/main/colab_clip_guided_diff_hq.ipynb

# https://openaipublic.blob.core.windows.net/diffusion/jul-2021/256x256_diffusion_uncond.pt
# https://gist.githubusercontent.com/yrevar/942d3a0ac09ec9e5eb3a/raw/238f720ff059c1f82f368259d1ca4ffa5dd8f9f5/imagenet1000_clsidx_to_labels.txt

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import math
from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF

sys.path.append('./CLIP')
sys.path.append('./guided-diffusion')

from CLIP.clip import clip
from guided_diffusion.script_util import create_model_and_diffusion, model_and_diffusion_defaults
import kornia.augmentation as K
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cutpower', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--gaussiannoise', type=bool, help='Gaussian noise.')
  parser.add_argument('--motionblur', type=bool, help='Motion blur.')
  parser.add_argument('--grayscale', type=bool, help='Grayscale.')
  parser.add_argument('--sharpness', type=bool, help='Sharpness.')
  parser.add_argument('--perspective', type=bool, help='Perspective.')
  parser.add_argument('--erasing', type=bool, help='Erasing.')
  parser.add_argument('--affine', type=bool, help='Affine.')
  parser.add_argument('--solarize', type=bool, help='Solarize.')
  parser.add_argument('--channelshuffle', type=bool, help='Channel shuffle.')
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




#@markdown Tested with varying degrees of success:
#@markdown Gaussian noise will favor objects positioned in the center of the image.
gaussian_noise = args.gaussiannoise #@param{type: 'boolean'}
motion_blur = args.motionblur #@param {type: 'boolean'}
grayscale = args.grayscale #@param {type: 'boolean'}
sharpness = args.sharpness #@param{type: 'boolean'}
perspective = args.perspective #@param {type: 'boolean'}
#thin_plate_spline = args.thinplatespline #@param {type: 'boolean'}
erasing = args.erasing #@param {type: 'boolean'}
# Untested:
#elastic_transform = args.elastictransform #@{type: 'boolean'}
affine = args.affine #@{type: 'boolean'}
solarize = args.solarize #@{type: 'boolean'}
channel_shuffle = args.channelshuffle #@ {type: 'boolean'}

# used by everything except for channel and grasycale
augment_chance = 0.6 #@param {type: 'number'}
channel_chance = 0.1  #@param {type: 'number'}
grayscale_chance = 0.1 #@param {type: 'number'}

cutn_power =  args.cutpower#@param {type: 'number'}

class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=cutn_power):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

        # Parametrization of the augmentations and new augmentations taken from <https://github.com/nerdyrodent/VQGAN-CLIP>, thanks to @nerdyrodent.
        augment_list = []
        #if elastic_transform:
        #    augment_list.append(K.RandomElasticTransform(same_on_batch=False, p=augment_chance))
        
        if gaussian_noise:
            augment_list.append(K.RandomGaussianNoise(mean=0.4578275, std=0.26130258,same_on_batch=False, p=augment_chance))
        if perspective:
            augment_list.append(K.RandomPerspective(distortion_scale=0.1,same_on_batch=False, p=augment_chance))
        if motion_blur:
            augment_list.append(K.RandomMotionBlur(3, 15, 0.5, same_on_batch=False,p=augment_chance))
        #if thin_plate_spline:
        #    augment_list.append(K.RandomThinPlateSpline(scale=0.1, align_corners=True, same_on_batch=False, p=augment_chance))
        if sharpness:
            augment_list.append(K.RandomSharpness(sharpness=0.5, same_on_batch=False, p=augment_chance))
        if grayscale:
            augment_list.append(K.RandomGrayscale(same_on_batch=False, p=grayscale_chance))
        if channel_shuffle:
            augment_list.append(K.RandomChannelShuffle(p=channel_chance))
        if affine:
            augment_list.append(K.RandomAffine(degrees=15, translate=0.1, p=augment_chance, padding_mode='border'))
        if erasing:
            augment_list.append(K.RandomErasing((.1, .4), (.3, 1/.3), same_on_batch=True, p=augment_chance))
        if solarize:
            augment_list.append(K.RandomSolarize(0.01, 0.01, p=augment_chance))
                
        self.augs = nn.Sequential(*augment_list)

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
            cutout = F.interpolate(cutout, (self.cut_size, self.cut_size),
                                   mode='bilinear', align_corners=False)
            cutouts.append(cutout)
        return self.augs(torch.cat(cutouts))

#@title Utility Functions
def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)


def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])

# from github.com/mehdidc/feed_forward_vqgan_clip
def tokenize_lines(line_separated, out="tokenized.pkl"):
    """Save each line of `line_separated` as a CLIP embed. Save CLIP embeds to single file for usage later on. """
    texts = line_separated.splitlines()
    T = clip.tokenize(texts, truncate=True)
    torch.save(T, out)

def tokenize_imagenet():
    #!wget --continue --quiet "https://gist.githubusercontent.com/yrevar/942d3a0ac09ec9e5eb3a/raw/238f720ff059c1f82f368259d1ca4ffa5dd8f9f5/imagenet1000_clsidx_to_labels.txt" 
    imgnet_idx_lbl = open('imagenet1000_clsidx_to_labels.txt').read().splitlines()
    clean_captions = []
    for idx_label in imgnet_idx_lbl:
        imgnet_lbl = re.sub(r'\d+: ', '', line).replace(" '","").replace(" '","").replace("  ", " ").replace("'", '').split(',') # get rid of 'digit: ' then get rid of weird spaces then ' then ,
        if imgnt_lbl[1] is '':
            clean_captions.append(imgnt_lbl[0])
        else:
            clean_captions.append(imgnt_lbl[1])

 
def imagenet_class_line_to_caption():
    #!wget --continue --quiet "https://gist.githubusercontent.com/yrevar/942d3a0ac09ec9e5eb3a/raw/238f720ff059c1f82f368259d1ca4ffa5dd8f9f5/imagenet1000_clsidx_to_labels.txt" 
    imagenet_class_labels = open('imagenet1000_clsidx_to_labels.txt').read().splitlines()
    line = random.choice(imagenet_class_labels)
    labels_in_line = re.sub(r'\d+: ', '', line).replace(" '","").replace(" '","").replace("  ", " ").replace("'", '').split(',') # get rid of 'digit: ' then get rid of weird spaces then ' then ,
    print("prompt will be ignored and a random class will be chosen instead. Set `random_imagenet_class` to False and re-run this cell if that is not desired.")
    if labels_in_line[1] is '':
        return labels_in_line[0]
    return " ".join(labels_in_line)

#@title Model settings
#@markdown `diffusion_steps` - Total number of steps for diffusion. Increase for slower runtime but greater quality.
diffusion_steps =  max(1000,args.iterations)#@param {type: 'integer'}

#@markdown `timestep_respacing` - less than or equal to `diffusion_steps`.  
#@markdown Map sampling to a lower number of steps. Decrease for faster runtimes with decrease in quality. 
#@markdown (optional) use `ddim` sampling.
#timestep_respacing = "250" #@param ["25", "50", "100", "250", "500", "1000", "ddim25", "ddim100", "ddim250", "ddim500"] {allow-input: true}
timestep_respacing = str(args.iterations)

model_config = model_and_diffusion_defaults()
model_config.update({
    'attention_resolutions': '32, 16, 8',
    'class_cond': False,
    'diffusion_steps': diffusion_steps,
    'rescale_timesteps': True,
    'timestep_respacing': timestep_respacing,
    'image_size': 256,
    'learn_sigma': True,
    'noise_schedule': 'linear',
    'num_channels': 256,
    'num_head_channels': 64,
    'num_res_blocks': 2,
    'resblock_updown': True,
    'use_fp16': True,
    'use_scale_shift_norm': True,
})

#@title Load `guided-diffusion` and `clip` models
#@markdown - `ViT-B/32` is quite good.
#@markdown - `RN50x16` uses a ton of VRAM and is only slightly better than `ViT-B/16`
#@markdown - `ViT-B/16` is a tad slower but higher quality.
sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()
clip_model_name = args.clip_model #'ViT-B/16' #@param ["ViT-B/16", "ViT-B/32", "RN50", "RN101", "RN50x4", "RN50x16"]
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

model, diffusion = create_model_and_diffusion(**model_config)
model.load_state_dict(torch.load('256x256_diffusion_uncond.pt', map_location='cpu'))
model.requires_grad_(False).eval().to(device)
for name, param in model.named_parameters():
    if 'qkv' in name or 'norm' in name or 'proj' in name:
        param.requires_grad_()
if model_config['use_fp16']:
    model.convert_to_fp16()

clip_model = clip.load(clip_model_name, jit=False)[0].eval().requires_grad_(False).to(device)
clip_size = clip_model.visual.input_resolution
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

#@title Settings for the run
#prompt = 'a photo of a brick wall covered in lsd psychedelic dripping paint.' #@param {type: 'string'}
prompt = args.prompt
#@markdown `Or...`
random_imagenet_class = False #@param {type: 'boolean'}
if random_imagenet_class is True:
    prompt = imagenet_class_line_to_caption()
#@markdown 
#@markdown `cutn` increasing seems to help for certain prompts but has diminishing returns for many. Uses more VRAM.
cutn =   args.cutn#@param {type: 'integer'}
batch_size =  1#@param {type: 'integer'}
clip_guidance_scale =  1000#@param {type: 'integer'}
tv_scale = 200 #was originally 100, upped to 200 after tweets from rivershavewings mentioned the change to boost detail

print(f"Using prompt: '{prompt}'")
print(f"batch size: {batch_size}, clip_guidance_scale: {clip_guidance_scale}, tv_scale: {tv_scale}, cutn: {cutn}, seed: {args.seed}")

# Commented out IPython magic to ensure Python compatibility.
#@title Actually do the run
display_frequency =  args.update

text_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

make_cutouts = MakeCutouts(clip_size, cutn)

cur_t = diffusion.num_timesteps - 1

def cond_fn(x, t, y=None):
    with torch.enable_grad():
        x = x.detach().requires_grad_()
        n = x.shape[0]
        my_t = torch.ones([n], device=device, dtype=torch.long) * cur_t
        out = diffusion.p_mean_variance(model, x, my_t, clip_denoised=False, model_kwargs={'y': y})
        fac = diffusion.sqrt_one_minus_alphas_cumprod[cur_t]
        x_in = out['pred_xstart'] * fac + x * (1 - fac)
        clip_in = normalize(make_cutouts(x_in.add(1).div(2)))
        image_embeds = clip_model.encode_image(clip_in).float().view([cutn, n, -1])
        dists = spherical_dist_loss(image_embeds, text_embed.unsqueeze(0))
        losses = dists.mean(0)
        tv_losses = tv_loss(x_in)
        loss = losses.sum() * clip_guidance_scale + tv_losses.sum() * tv_scale
        return -torch.autograd.grad(loss, x)[0]

if model_config['timestep_respacing'].startswith('ddim'):
    sample_fn = diffusion.ddim_sample_loop_progressive
else:
    sample_fn = diffusion.p_sample_loop_progressive

samples = sample_fn(
    model,
    (batch_size, 3, model_config['image_size'], model_config['image_size']),
    clip_denoised=False,
    model_kwargs={},
    cond_fn=cond_fn,
    progress=False,
)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
for i, sample in enumerate(samples):
    cur_t -= 1
    sys.stdout.write(f'Iteration {itt}\n')
    sys.stdout.flush()
    if itt % display_frequency == 0 or cur_t == -1:
        for j, image in enumerate(sample['pred_xstart']):
            sys.stdout.flush()
            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()
            filename = args.image_file
            TF.to_pil_image(image.add(1).div(2).clamp(0, 1)).save(filename)
            
            if args.frame_dir is not None:
                import os
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
                TF.to_pil_image(image.add(1).div(2).clamp(0, 1)).save(save_name)

            sys.stdout.flush()
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()
    itt = itt+1
