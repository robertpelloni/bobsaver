import sys
sys.path.append('.\CLIP')
import torch
from tqdm import tqdm
from torchvision.transforms import Compose, Resize, CenterCrop, ToTensor, Normalize
import torchvision
import BigGAN_utils.utils as utils
import clip
import torch.nn.functional as F
from DiffAugment_pytorch import DiffAugment
import numpy as np
from fusedream_utils import FuseDreamBaseGenerator, get_G, save_image

parser = utils.prepare_parser()
parser = utils.add_sample_parser(parser)
args = parser.parse_args()

INIT_ITERS = 100
OPT_ITERS = args.iterations

utils.seed_rng(args.seed) 

sentence = args.text

print('Generating:', sentence)
sys.stdout.flush()
G, config = get_G(512) # Choose from 256 and 512
sys.stdout.flush()
generator = FuseDreamBaseGenerator(G, config, 10, clip_mode=args.clip_model) 
sys.stdout.flush()
z_cllt, y_cllt = generator.generate_basis(sentence, init_iters=INIT_ITERS, num_basis=5, image_name=args.image_file, frame_dir=args.frame_dir,update_iters=args.update)
sys.stdout.flush()

z_cllt_save = torch.cat(z_cllt).cpu().numpy()
sys.stdout.flush()
y_cllt_save = torch.cat(y_cllt).cpu().numpy()
sys.stdout.flush()
img, z, y = generator.optimize_clip_score(z_cllt, y_cllt, sentence, latent_noise=True, augment=True, opt_iters=OPT_ITERS, optimize_y=True, image_name=args.image_file, frame_dir=args.frame_dir,update_iters=args.update)
sys.stdout.flush()
score = generator.measureAugCLIP(z, y, sentence, augment=True, num_samples=20)
sys.stdout.flush()
"""
print('AugCLIP score:', score)
import os
if not os.path.exists('./samples'):
    os.mkdir('./samples')
save_image(img, 'samples/fusedream_%s_seed_%d_score_%.4f.png'%(sentence, args.seed, score))
"""
