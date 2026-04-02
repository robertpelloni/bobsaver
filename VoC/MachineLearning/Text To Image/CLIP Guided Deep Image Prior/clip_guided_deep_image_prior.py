# CLIP Guided Deep Image Prior.ipynb
# Original file is located at https://colab.research.google.com/drive/1_oqIK8A67EgtJDdfsuJojc5ukNzirdle

# pip install madgrad 1.1

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./deep-image-prior')
sys.path.append('./clip')

from models import *
from utils.sr_utils import *
import clip
import time
import numpy as np
import torch
import torch.optim
from IPython import display
import cv2
from torch.nn import functional as F
import torchvision.transforms.functional as TF
import torchvision.transforms as T
import kornia.augmentation as K
from einops import rearrange
from madgrad import MADGRAD
import imageio
import random
import math
import argparse



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--optimizer', type=str, help='Optimizer.')
  parser.add_argument('--cutouts', type=int, help='Number of cutouts')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--skip_n33d', type=int, help='Skip')
  parser.add_argument('--skip_n33u', type=int, help='Skip')
  parser.add_argument('--skip_n11', type=int, help='Skip')
  parser.add_argument('--num_scales', type=int, help='Scales')
  parser.add_argument('--input_depth', type=int, help='Input depth')
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





device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

"""# Load CLIP"""

sys.stdout.write(f"Loading {args.clip_model} CLIP model ...\n")
sys.stdout.flush()

clip_model = clip.load(args.clip_model, device=device)[0]
clip_model = clip_model.eval().requires_grad_(False)
clip_size = clip_model.visual.input_resolution #224
clip_normalize = T.Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])

class MakeCutouts(torch.nn.Module):
    def __init__(self, cut_size, cutn):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.augs = T.Compose([
            K.RandomHorizontalFlip(p=0.5),
            K.RandomAffine(degrees=15, translate=0.1, p=0.8, padding_mode='border', resample='bilinear'),
            K.RandomPerspective(0.4, p=0.7, resample='bilinear'),
            K.ColorJitter(brightness=0.1, contrast=0.1, saturation=0.1, hue=0.1, p=0.7),
            K.RandomGrayscale(p=0.15),
        ])

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        if sideY != sideX:
            input = K.RandomAffine(degrees=0, shear=10, p=0.5)(input)

        max_size = min(sideX, sideY)
        cutouts = []
        for cn in range(self.cutn):
            if cn > self.cutn - self.cutn//4:
                cutout = input
            else:
                size = int(max_size * torch.zeros(1,).normal_(mean=.8, std=.3).clip(float(self.cut_size/max_size), 1.))
                offsetx = torch.randint(0, sideX - size + 1, ())
                offsety = torch.randint(0, sideY - size + 1, ())
                cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(F.adaptive_avg_pool2d(cutout, self.cut_size))
        cutouts = torch.cat(cutouts)
        cutouts = self.augs(cutouts)
        return cutouts

"""# Optimization loop"""

def spherical_dist_loss(x, y):
    x = F.normalize(x, dim=-1)
    y = F.normalize(y, dim=-1)
    return (x - y).norm(dim=-1).div(2).arcsin().pow(2).mul(2)

def optimize_network(num_iterations, optimizer_type, lr):
    global itt
    itt = 0

    """
    if seed is not None:
        np.random.seed(seed)
        torch.manual_seed(seed)
        random.seed(seed)
    """
    
    sys.stdout.write('Making cutouts ...\n')
    sys.stdout.flush()

    make_cutouts = MakeCutouts(clip_size, cutn)

    sys.stdout.write('Initializing DIP skip network ...\n')
    sys.stdout.flush()

    # Initialize DIP skip network
    input_depth = args.input_depth #32

    """
    #defaults
    net = get_net(
        input_depth, 'skip',
        pad='reflection',
        skip_n33d=128, skip_n33u=128,
        skip_n11=4, num_scales=5,
        upsample_mode='bilinear',
    ).to(device)

    #rivershavewings tweaks
    net = get_net(
        input_depth, 'skip',
        pad='reflection',
        skip_n33d=192, skip_n33u=192,
        skip_n11=4, num_scales=7,
        upsample_mode='bilinear',
        downsample_mode='lanczos2',
    ).to(device)
    """

    net = get_net(
        input_depth, 'skip',
        pad='reflection',
        skip_n33d=args.skip_n33d, skip_n33u=args.skip_n33u,
        skip_n11=args.skip_n11, num_scales=args.num_scales,
        upsample_mode='bilinear',
        downsample_mode='lanczos2',
    ).to(device)

    sys.stdout.write('Initializing input noise ...\n')
    sys.stdout.flush()

    # Initialize input noise
    net_input = torch.zeros([1, input_depth, sideY, sideX], device=device).normal_().div(10).detach()

    sys.stdout.write('Encoding prompt ...\n')
    sys.stdout.flush()

    # Encode text prompt with CLIP
    target_embed = clip_model.encode_text(clip.tokenize(prompt).to(device)).float()

    sys.stdout.write('Setting optimizer ...\n')
    sys.stdout.flush()

    if optimizer_type == 'Adam':
        optimizer = torch.optim.Adam(net.parameters(), lr)
    elif optimizer_type == 'MADGRAD':
        optimizer = MADGRAD(net.parameters(), lr, weight_decay=0.01, momentum=0.9)

    sys.stdout.write('Starting ...\n')
    sys.stdout.flush()

    for _ in range(num_iterations):
        
        optimizer.zero_grad(set_to_none=True)
        out = net(net_input)
        cutouts = make_cutouts(out)
        image_embeds = clip_model.encode_image(clip_normalize(cutouts))
        loss = spherical_dist_loss(image_embeds, target_embed).mean()
        loss.backward()
        optimizer.step()

        itt += 1

        sys.stdout.write(f'Iteration {itt}\n')
        sys.stdout.flush()

        if itt % display_rate == 0:
            with torch.inference_mode():
                image = TF.to_pil_image(out[0].clamp(0, 1))
                if itt % display_rate == 0:
                    sys.stdout.flush()
                    sys.stdout.write('Saving progress ...\n')
                    sys.stdout.flush()

                    image.save(args.image_file)
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
                        image.save(save_name)
                
                    sys.stdout.flush()
                    sys.stdout.write('Progress saved\n')
                    sys.stdout.flush()

        if anneal_lr:
            optimizer.param_groups[0]['lr'] = max(0.00001, .99 * optimizer.param_groups[0]['lr'])


"""# Settings / Generate"""

seed = args.seed
opt_type = args.optimizer #'MADGRAD' # Adam, MADGRAD
lr = args.learning_rate #0.0025 # learning rate
anneal_lr = True # True == lower the learning rate over time

sideX, sideY = args.sizex, args.sizey # Resolution
num_iterations = args.iterations # More can be better, but there are diminishing returns
cutn = args.cutouts #16 # Number of crops of image shown to CLIP, this can affect quality

prompt = args.prompt #'a moody painting of a lonely duckling'

display_rate = args.update # How often the output is displayed.
# If you grab a P100 GPU or better, you'll likely want to set this further apart, like >=20.
# On T4 and K80, the process is slower so you might want to set a faster display_rate (lower number, towards 1-5).

display_augs = False # Display grid of augmented image, for debugging

out = optimize_network(num_iterations, opt_type, lr)

# Save final frame and video to a file
#out.save(f'dip_{timestring}.png', quality=100)
