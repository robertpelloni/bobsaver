# Pixel_direct.ipynb
# Original file is located at https://colab.research.google.com/drive/1F9ZOZnpV3uBPRDSESaAXYwzNZJQRJT75

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import torch.nn.functional as F
import torch.nn as nn
from torchvision.transforms import Normalize
import tqdm
import matplotlib.pyplot as plt
import kornia.augmentation as K
from CLIP.clip import clip
from PIL import Image
from torchvision.transforms import functional as TF
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--pixel_size', type=int, help='Size of pixels.')
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





H = args.sizey // args.pixel_size;
W = args.sizex // args.pixel_size;
UPSCALE_SIZE = (args.sizey, args.sizex)

class MakeCutouts(nn.Module):
    """
    Cutout and augmentation
    Augmentation mostly based on mse regularized version of VQGANCLIP
    """
    def __init__(self, cut_size, repeat_n, crop_scale_min=0.5):
        super().__init__()
        self.cut_size = cut_size
        self.repeat_n = repeat_n
        self.augs = nn.Sequential(
            K.RandomResizedCrop((cut_size, cut_size), scale=(crop_scale_min, 1.0), ratio=(0.95, 1.05)),
            K.RandomHorizontalFlip(p=0.5),
            K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'), # padding_mode=2
            K.RandomPerspective(0.2, p=0.4),
            K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),
            Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))
        )
        
    def forward(self, input):
        # N, C, H, W
        # repeat along batch
        rep_im = input.expand(self.repeat_n, -1, -1, -1)
        # rep_im = input.repeat(self.repeat_n, 1, 1, 1)
        aug_im = self.augs(rep_im)
        return aug_im

# Load CLIP model

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

#perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

clip_model, _pil_transform = clip.load(args.clip_model, jit=False, device='cuda')
clip_model = clip_model.eval().requires_grad_(False)

# cutout module
n_px = clip_model.visual.input_resolution
n_cutouts = 8
cutout = MakeCutouts(n_px, n_cutouts, crop_scale_min=0.75)

# make text embedding
query_texts = ['Piet Mondrian #pixelart']
text_feats = F.normalize(clip_model.encode_text(clip.tokenize(query_texts).to('cuda')).float(), dim=1)

"""## Main Code"""

N_ITER = args.iterations

query_texts = [args.prompt]
text_feats = F.normalize(clip_model.encode_text(clip.tokenize(query_texts).to('cuda')).float(), dim=1)
pix = (torch.randn(1, 3, H, W) - 1).to('cuda').requires_grad_(True)
optimizer = torch.optim.Adam([pix], lr=1e-1)
losses = []


sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt = 1
for i in range(args.iterations):
    image = torch.sigmoid(pix)
    up_image = F.interpolate(image, size=UPSCALE_SIZE, mode='nearest')
    im_cutouts = cutout(up_image)
    image_feats = F.normalize(clip_model.encode_image(im_cutouts).float(), dim=1)
    cos_sim = torch.sum(text_feats.unsqueeze(0) * image_feats.unsqueeze(1), dim=-1)
    loss = (1 - cos_sim).mean()
    #pbar.set_postfix(dict(epoch=i, loss=loss.item()))
    losses.append(loss.item())
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    sys.stdout.write("Iteration {}".format(itt)+"\n")
    sys.stdout.flush()
    
    if itt % args.update == 0:
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()
        
        TF.to_pil_image(up_image[0].clamp(0, 1)).save(args.image_file)
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
            TF.to_pil_image(up_image[0].clamp(0, 1)).save(save_name)

        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
    
    itt+=1
#plt.imshow(image.permute(0, 2, 3, 1)[0].detach().cpu())




