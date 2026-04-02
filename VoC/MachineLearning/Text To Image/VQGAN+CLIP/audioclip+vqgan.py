# AudioCLIP + VQGAN (Public Release)
# Original file is located at https://colab.research.google.com/drive/10T6RRABbjv0AAngq1nGyH-j6jx8i2wZ3
# model https://github.com/AndreyGuzhov/AudioCLIP/releases/download/v0.1/AudioCLIP-Full-Training.pt
# pip install pytorch-ignite 0.4.6
# pip install visdom 0.1.8.9
# pip install librosa 0.8.1

# !git clone https://github.com/russelldc/AudioCLIP
# !wget https://github.com/AndreyGuzhov/AudioCLIP/releases/download/v0.1/bpe_simple_vocab_16e6.txt.gz -O 'AudioCLIP/assets/bpe_simple_vocab_16e6.txt.gz'


import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./taming-transformers')
sys.path.append('./AudioCLIP')

import os
from audioclip import AudioCLIP
import torch
import torch.nn as nn
import torchvision.transforms as T
import torchvision.transforms.functional as TF
from datetime import datetime
from omegaconf import OmegaConf
import sys
from taming.models.vqgan import VQModel
import torch.nn.functional as F
import math
import imageio
import PIL
import gc
from IPython import display
import kornia.augmentation as K
import os
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--update', type=int, help='Update after x steps.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--cutouts', type=int, help='Num cutouts')
  parser.add_argument('--learning_rate', type=float, help='Learning rate')
  parser.add_argument('--seed_image', type=str, help='Seed image name.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model.')
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

DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE
print(torch.cuda.get_device_properties(device))


torch.set_grad_enabled(False)


sys.stdout.write("Loading AudioCLIP model ...\n")
sys.stdout.flush()


perceptor = AudioCLIP(pretrained='AudioCLIP-Full-Training.pt').cuda()
perceptor.eval()
perceptor_size = 224

torch.set_grad_enabled(True)

class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()
        
        if init_image:
            x = (F.interpolate(torch.tensor(imageio.imread(init_image_path)).unsqueeze(0).permute(0, 3, 1, 2), (sideX, sideY)) / 255).cuda()
            z, _, [_, _, indices] = vqgan_model.encode(x)
            self.normu = torch.nn.Parameter(z.cuda().clone())
        elif blocky_random:
            if grayscale_random:
                x = torch.zeros(1, 1, random_size, random_size, device=DEVICE).normal_(mean=.3, std=.7).clamp(0, 1).expand(-1, 3, -1, -1)
            else:
                x = torch.rand(1, 3, random_size, random_size, device=DEVICE).normal_(mean=.3, std=.7).clamp(0, 1).expand(-1, 3, -1, -1)

            x = T.Resize((sideX, sideY))(x)
            z, _, [_, _, indices] = vqgan_model.encode(x)
            self.normu = torch.nn.Parameter(z.cuda().clone())
        else:
            normu = torch.randn(1, 256, sideX//16, sideY//16, device=DEVICE)
            self.normu = torch.nn.Parameter(torch.sinh(1.9 * torch.arcsinh(normu)))

    def forward(self):
        return vqgan_model.decode(self.normu)

nom = T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
augs = torch.nn.Sequential(
#     K.RandomHorizontalFlip(p=0.5),
    K.RandomAffine(degrees=25, translate=0.1, p=0.8, padding_mode='border'),
    K.RandomErasing(p=0.1),
    K.RandomPerspective(distortion_scale=0.7, p=0.7),
).cuda()

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

def diff_relu(x):
    return (torch.sqrt(x*x+0.0001)+x)*0.5
def diff_clamp(x):
    return diff_relu(1-diff_relu(1-x))

def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    del model.loss
    return model

sys.stdout.write("Loading VQGAN model "+args.vqgan_model+" ...\n")
sys.stdout.flush()

vqgan_model = load_vqgan_model(f'{args.vqgan_model}.yaml',f'{args.vqgan_model}.ckpt').to(DEVICE)

"""# Params"""

# Set output resolution here:
sideY, sideX = [args.sizex, args.sizey]

if args.seed_image is None:
    init_image = False
    init_image_path = 'mona.jpg'
else:
    init_image = True
    init_image_path = args.seed_image


# Upload your audio, then update this path to point at it:
audio_path = args.prompt #'AudioCLIP/assets/royaltyfree_retro.wav'
audio_enc = perceptor.create_audio_encoding(audio_path)
audio_enc = audio_enc / audio_enc.norm(dim=-1, keepdim=True)

display_rate = 1

learning_rate = args.learning_rate #0.1
anneal_lr = False
min_learning_rate = 0.001
dec = .0

num_iterations = args.iterations
sample_cuts = args.cutouts #32

main_weight = 10

blocky_random = True
grayscale_random = False
random_size = 64

def augment(into, cutn=32):
    sideY, sideX = into.shape[2:4]
    max_size = min(sideX, sideY)
    min_size = min(sideX, sideY, perceptor_size)
    cutouts = []
    for ch in range(cutn):
        size = int(torch.rand([])**1 * (max_size - min_size) + min_size)
        offsetx = torch.randint(0, sideX - size + 1, ())
        offsety = torch.randint(0, sideY - size + 1, ())
        cutout = into[:, :, offsety:offsety + size, offsetx:offsetx + size]
        cutouts.append(F.interpolate(cutout, (perceptor_size, perceptor_size), mode='bilinear', align_corners=True))
        del cutout
    
    cutouts = torch.cat(cutouts, dim=0)
    cutouts = clamp_with_grad(cutouts, 0, 1)
    cutouts = augs(cutouts)
    return cutouts

def save_image(img, num=0):    
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    #pil_img = PIL.ImageOps.autocontrast(img)
    # Save individual image with timestamp
    #current_time = datetime.now().strftime('%y%m%d-%H%M%S_%f')
    #img_filename = f'{out_folder}/audioclip_output{str(num)}_{current_time}.jpg'
    #pil_img.save(img_filename, quality=95, subsampling=0)

    pil_img = img

    pil_img.save(args.image_file)
    
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
        pil_img.save(save_name)
    

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    
    
    

def checkin():
    with torch.no_grad():
        img_out = clamp_with_grad(lats(), 0, 1)

        batch_num = 0
        for img in img_out:
          pil_img = T.ToPILImage()(img.squeeze())
          save_image(pil_img, batch_num)
          batch_num += 1
            
        """
        if itt % display_rate == 0:
            display.clear_output(wait=True)
            display.display(pil_img)
        """
        
def ascend_txt():
    into = augment(lats(), sample_cuts)
    img_enc = perceptor.encode_image(nom(into))
    return -main_weight * torch.cosine_similarity(audio_enc, img_enc, -1).mean()

def train(i):
    loss = ascend_txt()
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    if anneal_lr:
        optimizer.param_groups[0]['lr'] = max(optimizer.param_groups[0]['lr'] * .995, min_learning_rate)
        optimizer.param_groups[0]['weight_decay'] *= .995

    if i%args.update==0:
        checkin()

    """
    if itt % 1 == 0:
        print('itt', itt, 'loss', loss.detach())
        for g in optimizer.param_groups:
            print(g['lr'], 'lr', g['weight_decay'], 'decay')
    """
    
def loop(range_val):
    global itt
    itt = 1

    for i in range(range_val):
        sys.stdout.write("Iteration {}".format(itt)+"\n")
        sys.stdout.flush()
        train(itt)
        itt += 1

"""# Train"""

out_folder = '.'

lats = Pars().cuda()
optimizer = torch.optim.AdamW(params=[lats.normu], lr=learning_rate, weight_decay=dec)

loop(num_iterations)
