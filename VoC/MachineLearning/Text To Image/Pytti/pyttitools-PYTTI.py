import sys
sys.path.append('./pytti-core/src')

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
from pathlib import Path
import pandas as pd
import subprocess
import pytti
from omegaconf import OmegaConf
import math
import mmc
import mmc.loaders
import argparse
import numpy as np
import random

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--scenes', type=str)
  parser.add_argument('--scene_prefix', type=str)
  parser.add_argument('--scene_suffix', type=str)
  parser.add_argument('--seed', type=int)
  parser.add_argument('--seed_image', type=str)
  parser.add_argument('--direct_image_prompts', type=str)
  parser.add_argument('--direct_init_weight', type=str)
  parser.add_argument('--pixel_size', type=int)
  parser.add_argument('--init_image', type=str)
  parser.add_argument('--semantic_init_weight', type=str)
  parser.add_argument('--video_path', type=str)
  parser.add_argument('--frame_stride', type=int)
  parser.add_argument('--reencode_each_frame', type=int)
  parser.add_argument('--input_audio', type=str)
  parser.add_argument('--input_audio_offset', type=int)
  parser.add_argument('--f_center', type=int)
  parser.add_argument('--f_width', type=int)
  parser.add_argument('--order', type=int)
  parser.add_argument('--ViTB32', type=int)
  parser.add_argument('--ViTB16', type=int)
  parser.add_argument('--ViTL14', type=int)
  parser.add_argument('--ViTL14_336px', type=int)
  parser.add_argument('--RN50', type=int)
  parser.add_argument('--RN101', type=int)
  parser.add_argument('--RN50x4', type=int)
  parser.add_argument('--RN50x16', type=int)
  parser.add_argument('--RN50x64', type=int)
  parser.add_argument('--model1', type=str)
  parser.add_argument('--model2', type=str)
  parser.add_argument('--model3', type=str)
  parser.add_argument('--translate_x', type=str)
  parser.add_argument('--translate_y', type=str)
  parser.add_argument('--translate_z_3d', type=str)
  parser.add_argument('--rotate_3d', type=str)
  parser.add_argument('--rotate_2d', type=str)
  parser.add_argument('--zoom_x_2d', type=str)
  parser.add_argument('--zoom_y_2d', type=str)
  parser.add_argument('--lock_camera', type=int)
  parser.add_argument('--field_of_view', type=int)
  parser.add_argument('--near_plane', type=float)
  parser.add_argument('--far_plane', type=float)
  parser.add_argument('--direct_stabilization_weight', type=str)
  parser.add_argument('--semantic_stabilization_weight', type=str)
  parser.add_argument('--depth_stabilization_weight', type=str)
  parser.add_argument('--edge_stabilization_weight', type=str)
  parser.add_argument('--flow_stabilization_weight', type=str)
  parser.add_argument('--flow_long_term_samples', type=int)
  parser.add_argument('--border_mode', type=str)
  parser.add_argument('--sampling_mode', type=str)
  parser.add_argument('--infill_mode', type=str)
  parser.add_argument('--image_model', type=str)
  parser.add_argument('--vqgan_model', type=str)
  parser.add_argument('--animation_mode', type=str)
  parser.add_argument('--steps_per_scene', type=int)
  parser.add_argument('--steps_per_frame', type=int)
  parser.add_argument('--interpolation_steps', type=int)
  parser.add_argument('--learning_rate', type=float)
  parser.add_argument('--default_learning_rate', type=int)
  parser.add_argument('--reset_lr_each_frame', type=int)
  parser.add_argument('--pixel_szie', type=int)
  parser.add_argument('--smoothing_weight', type=float)
  parser.add_argument('--random_initial_palette', type=int)
  parser.add_argument('--palette_size', type=int)
  parser.add_argument('--palettes', type=int)
  parser.add_argument('--gamma', type=float)
  parser.add_argument('--hdr_weight', type=float)
  parser.add_argument('--palette_normalization_weight', type=float)
  parser.add_argument('--target_palette', type=str)
  parser.add_argument('--lock_palette', type=int)
  parser.add_argument('--show_palette', type=int)
  parser.add_argument('--cutouts', type=int)
  parser.add_argument('--cut_pow', type=float)
  parser.add_argument('--cutout_border', type=float)
  parser.add_argument('--gradient_accumulation_steps', type=int)
  parser.add_argument('--pre_animation_steps', type=int)
  parser.add_argument('--frames_per_second', type=int)
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  


  args = parser.parse_args()
  return args

args2=parse_args();

"""
if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    np.random.seed(args2.seed)
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 
"""






mount_gdrive = False # @param{type:"boolean"}
drive_mounted = False
gdrive_fpath = '.'
model_default = None
random_seed = None
seed = random_seed
all  = math.inf
derive_from_init_aspect_ratio = -1
path_to_default = 'config/default.yaml'
params = OmegaConf.load(path_to_default)



# In[ ]:
#get_ipython().run_cell_magic('capture', '', '#@title 1.3 Install everything else\n#@markdown Run this cell on a fresh runtime to install the libraries and modules.\n\n#@markdown This may take a few minutes. \n\nfrom os.path import exists as path_exists\nif path_exists(gdrive_fpath):\n  %cd {gdrive_fpath}\n\ndef install_pip_deps():\n    !pip install kornia pytorch-lightning transformers\n    !pip install jupyter loguru einops PyGLM ftfy regex tqdm hydra-core exrex\n    !pip install seaborn adjustText bunch matplotlib-label-lines\n    !pip install --upgrade gdown\n\ndef instal_gh_deps():\n  # not sure the "upgrade" arg does anything here, just feels like a good idea\n  !pip install --upgrade git+https://github.com/pytti-tools/AdaBins.git\n  !pip install --upgrade git+https://github.com/pytti-tools/GMA.git\n  !pip install --upgrade git+https://github.com/pytti-tools/taming-transformers.git\n  !pip install --upgrade git+https://github.com/openai/CLIP.git\n  !pip install --upgrade git+https://github.com/pytti-tools/pytti-core.git\n\ntry:\n    import pytti\nexcept:\n    install_pip_deps()\n    instal_gh_deps()\n\n# Preload unopinionated defaults\n# makes it so users don\'t have to run every setup cell\nfrom omegaconf import OmegaConf\n\n!python -m pytti.warmup\n\npath_to_default = \'config/default.yaml\'\nparams = OmegaConf.load(path_to_default)\n\n\n# setup for step 2\n\nimport math\n\nmodel_default = None\nrandom_seed = None\nseed = random_seed\nall  = math.inf\nderive_from_init_aspect_ratio = -1\n\n########################\n\ntry:\n    import mmc\nexcept:\n    # install mmc\n    !git clone https://github.com/dmarx/Multi-Modal-Comparators\n    !pip install poetry\n    !cd Multi-Modal-Comparators; cp pyproject.toml.INSTALL-ALL pyproject.toml; poetry build\n    !cd Multi-Modal-Comparators; pip install dist/mmc*.whl\n    \n    # optional final step:\n    #poe napm_installs\n    !python Multi-Modal-Comparators/src/mmc/napm_installs/__init__.py\n# suppress mmc warmup outputs\nimport mmc.loaders\n')


# # Step 2: Configure Experiment
# 
# Edit the parameters, or load saved parameters, then run the model.
# 
# * https://pytti-tools.github.io/pytti-book/SceneDSL.html
# * https://pytti-tools.github.io/pytti-book/Settings.html
# 
# To input previously used settings or settings generated using tools such as https://pyttipanna.xyz/ , jump down to cell 4.1

# In[ ]:


# @title Prompt Settings { display-mode: 'form' } 

scenes = args2.scenes # @param{type:"string"}
scene_suffix = args2.scene_suffix # @param{type:"string"}
scene_prefix = args2.scene_prefix # @param{type:"string"}

params.scenes = scenes
params.scene_prefix = scene_prefix 
params.scene_suffix = scene_suffix


direct_image_prompts = args2.direct_image_prompts # @param{type:"string"}
init_image = args2.init_image # @param{type:"string"}
direct_init_weight = args2.direct_init_weight # @param{type:"string"}
semantic_init_weight = args2.semantic_init_weight # @param{type:"string"}

params.direct_image_prompts = direct_image_prompts
params.init_image = init_image
params.direct_init_weight = direct_init_weight
params.semantic_init_weight = semantic_init_weight


interpolation_steps = args2.interpolation_steps #0 # @param{type:"number"}
steps_per_scene = args2.steps_per_scene # @param{type:"raw"}
steps_per_frame = args2.steps_per_frame # @param{type:"number"}
save_every = steps_per_frame  # @param{type:"raw"}

params.interpolation_steps = interpolation_steps
params.steps_per_scene = steps_per_scene
params.steps_per_frame = steps_per_frame
params.save_every = save_every


# In[ ]:


# @title Misc Run Initialization { display-mode: 'form' } 


#@markdown Check this box to pick up where you left off from a previous run, e.g. if the google colab runtime timed out
resume = False #@param{type:"boolean"}
params.resume = resume

seed = args2.seed #random_seed #@param{type:"raw"}

params.seed = seed
if params.seed is None:
    params.seed = random.randint(-0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff)


# ## Image Settings

# In[ ]:


# @title General Image Settings { display-mode: 'form' } 

#@markdown Use `image_model` to select how the model will encode the image
image_model = args2.image_model #"VQGAN" #@param ["VQGAN", "Limited Palette", "Unlimited Palette"]
params.image_model = image_model

#@markdown image_model | description | strengths | weaknesses
#@markdown --- | -- | -- | --
#@markdown  VQGAN | classic VQGAN image | smooth images | limited datasets, slow, VRAM intesnsive 
#@markdown  Limited Palette | pytti differentiable palette | fast,  VRAM scales with `palettes` | pixel images
#@markdown  Unlimited Palette | simple RGB optimization | fast, VRAM efficient | pixel images

vqgan_model = args2.vqgan_model #"imagenet" #@param ["imagenet", "coco", "wikiart", "sflckr", "openimages"]
params.vqgan_model = vqgan_model

#@markdown The output image resolution will be `width` $\times$ `pixel_size` by height $\times$ `pixel_size` pixels.
#@markdown The easiest way to run out of VRAM is to select `image_model` VQGAN without reducing
#@markdown `pixel_size` to $1$.
#@markdown For `animation_mode: 3D` the minimum resoultion is about 450 by 400 pixels.


width = args2.sizex // args2.pixel_size # 180 # @param {type:"raw"}
height =  args2.sizey // args2.pixel_size #112 # @param {type:"raw"}

params.width = width
params.height = height

#@markdown the default learning rate is `0.1` for all the VQGAN models
#@markdown except openimages, which is `0.15`. For the palette modes the
#@markdown default is `0.02`. 
if args2.default_learning_rate == 1:
    learning_rate =  model_default #@param{type:"raw"}
else:
    learning_rate =  args2.learning_rate #model_default #@param{type:"raw"}

if args2.reset_lr_each_frame == 1:
    reset_lr_each_frame = True #@param{type:"boolean"}
else:
    reset_lr_each_frame = False #@param{type:"boolean"}

params.learning_rate = learning_rate
params.reset_lr_each_frame = reset_lr_each_frame


# In[ ]:


# @title Advanced Color and Appearance options { display-mode: 'form', run: 'auto' } 

pixel_size = args2.pixel_size #4#@param{type:"number"}
smoothing_weight = args2.smoothing_weight # 0.02#@param{type:"number"}

params.pixel_size = pixel_size
params.smoothing_weight = smoothing_weight


#@markdown "Limited Palette" specific settings:

if args2.random_initial_palette == 1:
    random_initial_palette = True#@param{type:"boolean"}
else:
    random_initial_palette = False#@param{type:"boolean"}


palette_size = args2.palette_size #6#@param{type:"number"}
palettes = args2.palettes #9#@param{type:"number"}

params.random_initial_palette = random_initial_palette
params.palette_size = palette_size
params.palettes = palettes


gamma = args2.gamma #1#@param{type:"number"}
hdr_weight = args2.hdr_weight #0.01#@param{type:"number"}
palette_normalization_weight = args2.palette_normalization_weight #0.2#@param{type:"number"}
target_palette = args2.target_palette #""#@param{type:"string"}

if args2.lock_palette == 1:
    lock_palette = True #@param{type:"boolean"}
else:
    lock_palette = False #@param{type:"boolean"}

if args2.show_palette == 1:
    show_palette = True #@param{type:"boolean"}
else:
    show_palette = False #@param{type:"boolean"}

params.gamma = gamma
params.hdr_weight = hdr_weight
params.palette_normalization_weight = palette_normalization_weight
params.target_palette = target_palette
params.lock_palette = lock_palette
params.show_palette = show_palette


# ## Perceptor Settings

# In[ ]:


# @title Perceptor Models { display-mode: 'form', run: 'auto' } 

#@markdown Quality settings from Dribnet's CLIPIT (https://github.com/dribnet/clipit).
#@markdown Selecting too many will use up all your VRAM and slow down the model.
#@markdown I usually use ViTB32, ViTB16, and RN50 if I get a A100, otherwise I just use ViT32B.

#@markdown quality | CLIP models
#@markdown --- | --
#@markdown  draft | ViTB32 
#@markdown  normal | ViTB32, ViTB16 
#@markdown  high | ViTB32, ViTB16, RN50
#@markdown  best | ViTB32, ViTB16, RN50x4

# To do: change this to a multi-select

if args2.ViTB32 == 1:
    ViTB32 = True #@param{type:"boolean"}
else:
    ViTB32 = False #@param{type:"boolean"}

if args2.ViTB16 == 1:
    ViTB16 = True #@param{type:"boolean"}
else:
    ViTB16 = False #@param{type:"boolean"}

if args2.ViTL14 == 1:
    ViTL14 = True #@param{type:"boolean"}
else:
    ViTL14 = False #@param{type:"boolean"}

if args2.ViTL14_336px == 1:
    ViTL14_336px  = True #@param{type:"boolean"}
else:
    ViTL14_336px  = False #@param{type:"boolean"}

if args2.RN50 == 1:
    RN50 = True #@param{type:"boolean"}
else:
    RN50 = False #@param{type:"boolean"}

if args2.RN101 == 1:
    RN101 = True #@param{type:"boolean"}
else:
    RN101 = False #@param{type:"boolean"}

if args2.RN50x4 == 1:
    RN50x4 = True #@param{type:"boolean"}
else:
    RN50x4 = False #@param{type:"boolean"}

if args2.RN50x16 == 1:
    RN50x16 = True #@param{type:"boolean"}
else:
    RN50x16 = False #@param{type:"boolean"}

if args2.RN50x64 == 1:
    RN50x64 = True #@param{type:"boolean"}
else:
    RN50x64 = False #@param{type:"boolean"}


params.ViTB32 = ViTB32
params.ViTB16 = ViTB16
params.ViTL14 = ViTL14
params.ViTL14_336px = ViTL14_336px
params.RN50 = RN50
params.RN101 = RN101
params.RN50x4 = RN50x4
params.RN50x16 = RN50x16
params.RN50x64 = RN50x64



# In[ ]:


# @title MMC Perceptors { display-mode: 'form' } 

#@markdown This cell loads perceptor models via https://github.com/dmarx/multi-modal-comparators. Some model comparisons [here](https://t.co/iShJpm5GjL)

# @markdown Select up to three models


# @markdown Model 1
model1 = args2.model1 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - openai - RN50x4]","[clip - openai - RN50x16]","[clip - openai - RN50x64]","[clip - openai - ViT-B/32]","[clip - openai - ViT-B/16]","[clip - openai - ViT-L/14]","[clip - openai - ViT-L/14@336px]","[clip - mlfoundations - RN50--openai]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--openai]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--openai]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--openai]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - RN50x4--openai]","[clip - mlfoundations - RN50x16--openai]","[clip - mlfoundations - ViT-B-32--openai]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--openai]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--openai]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - mlfoundations - ViT-L-14--openai]","[clip - mlfoundations - ViT-L-14-336--openai]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - sajjjadayobi - clipfa]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_16_epochs]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_32_epochs]","[clip - navervision - kelip_ViT-B/32]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}
model2 = args2.model2 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - openai - RN50x4]","[clip - openai - RN50x16]","[clip - openai - RN50x64]","[clip - openai - ViT-B/32]","[clip - openai - ViT-B/16]","[clip - openai - ViT-L/14]","[clip - openai - ViT-L/14@336px]","[clip - mlfoundations - RN50--openai]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--openai]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--openai]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--openai]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - RN50x4--openai]","[clip - mlfoundations - RN50x16--openai]","[clip - mlfoundations - ViT-B-32--openai]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--openai]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--openai]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - mlfoundations - ViT-L-14--openai]","[clip - mlfoundations - ViT-L-14-336--openai]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - sajjjadayobi - clipfa]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_16_epochs]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_32_epochs]","[clip - navervision - kelip_ViT-B/32]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}
model3 = args2.model3 #"" # @param ["[clip - openai - RN50]","[clip - openai - RN101]","[clip - openai - RN50x4]","[clip - openai - RN50x16]","[clip - openai - RN50x64]","[clip - openai - ViT-B/32]","[clip - openai - ViT-B/16]","[clip - openai - ViT-L/14]","[clip - openai - ViT-L/14@336px]","[clip - mlfoundations - RN50--openai]","[clip - mlfoundations - RN50--yfcc15m]","[clip - mlfoundations - RN50--cc12m]","[clip - mlfoundations - RN50-quickgelu--openai]","[clip - mlfoundations - RN50-quickgelu--yfcc15m]","[clip - mlfoundations - RN50-quickgelu--cc12m]","[clip - mlfoundations - RN101--openai]","[clip - mlfoundations - RN101--yfcc15m]","[clip - mlfoundations - RN101-quickgelu--openai]","[clip - mlfoundations - RN101-quickgelu--yfcc15m]","[clip - mlfoundations - RN50x4--openai]","[clip - mlfoundations - RN50x16--openai]","[clip - mlfoundations - ViT-B-32--openai]","[clip - mlfoundations - ViT-B-32--laion400m_e31]","[clip - mlfoundations - ViT-B-32--laion400m_e32]","[clip - mlfoundations - ViT-B-32--laion400m_avg]","[clip - mlfoundations - ViT-B-32-quickgelu--openai]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e31]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_e32]","[clip - mlfoundations - ViT-B-32-quickgelu--laion400m_avg]","[clip - mlfoundations - ViT-B-16--openai]","[clip - mlfoundations - ViT-B-16--laion400m_e31]","[clip - mlfoundations - ViT-B-16--laion400m_e32]","[clip - mlfoundations - ViT-L-14--openai]","[clip - mlfoundations - ViT-L-14-336--openai]","[clip - sbert - ViT-B-32-multilingual-v1]","[clip - sajjjadayobi - clipfa]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_16_epochs]","[cloob - crowsonkb - cloob_laion_400m_vit_b_16_32_epochs]","[clip - navervision - kelip_ViT-B/32]","[clip - facebookresearch - clip_small_25ep]","[simclr - facebookresearch - simclr_small_25ep]","[slip - facebookresearch - slip_small_25ep]","[slip - facebookresearch - slip_small_50ep]","[slip - facebookresearch - slip_small_100ep]","[clip - facebookresearch - clip_base_25ep]","[simclr - facebookresearch - simclr_base_25ep]","[slip - facebookresearch - slip_base_25ep]","[slip - facebookresearch - slip_base_50ep]","[slip - facebookresearch - slip_base_100ep]","[clip - facebookresearch - clip_large_25ep]","[simclr - facebookresearch - simclr_large_25ep]","[slip - facebookresearch - slip_large_25ep]","[slip - facebookresearch - slip_large_50ep]","[slip - facebookresearch - slip_large_100ep]","[clip - facebookresearch - clip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc3m_40ep]","[slip - facebookresearch - slip_base_cc12m_35ep]","[clip - facebookresearch - clip_base_cc12m_35ep]"] {allow-input: true}

##########

params.use_mmc = False
mmc_models = []

for model_key in (model1, model2, model3):
    if not model_key:
        continue
    arch, pub, m_id = model_key[1:-1].split(' - ')
    params.use_mmc = True
    mmc_models.append({
        'architecture':arch,
        'publisher':pub,
        'id':m_id,
        })
params.mmc_models = mmc_models 


# In[ ]:


# @title Cutouts { display-mode: 'form', run: 'auto' } 

#@markdown [Cutouts are how CLIP sees the image.](https://twitter.com/remi_durant/status/1460607677801897990)

cutouts = args2.cutouts #40#@param{type:"number"}
cut_pow = args2.cut_pow #2#@param {type:"number"}
cutout_border = args2.cutout_border # .25#@param {type:"number"}
gradient_accumulation_steps = args2.gradient_accumulation_steps #1 #@param {type:"number"}


params.cutouts = cutouts
params.cut_pow = cut_pow
params.cutout_border = cutout_border
params.gradient_accumulation_steps = gradient_accumulation_steps


# ## Animation Settings

# In[ ]:


# @title General Animation Settings { display-mode: 'form', run: 'auto' } 

animation_mode = args2.animation_mode #"2D" #@param ["off","2D", "3D", "Video Source"]
pre_animation_steps = args2.pre_animation_steps # 0 # @param{type:"number"}
frames_per_second = args2.frames_per_second # 12 # @param{type:"number"}

params.animation_mode = animation_mode
params.pre_animation_steps = pre_animation_steps
params.frames_per_second = frames_per_second


# @markdown NOTE: prompt masks (`prompt:weight_[mask.png]`) may not work correctly on '`wrap`' or '`mirror`' border mode.
border_mode = args2.border_mode #"clamp" # @param ["clamp","mirror","wrap","black","smear"]
sampling_mode = args2.sampling_mode #"bicubic" #@param ["bilinear","nearest","bicubic"]
infill_mode = args2.infill_mode #"wrap" #@param ["mirror","wrap","black","smear"]

params.border_mode = border_mode
params.sampling_mode = sampling_mode
params.infill_mode = infill_mode


# In[ ]:


# @title Video Input { display-mode: 'form', run: 'auto' } 

video_path = args2.video_path #""# @param{type:"string"}
frame_stride = args2.frame_stride #1 #@param{type:"number"}

if args2.reencode_each_frame == 1:
    reencode_each_frame = True #@param{type:"boolean"}
else:
    reencode_each_frame = False #@param{type:"boolean"}


params.video_path = video_path
params.frame_stride = frame_stride
params.reencode_each_frame = reencode_each_frame


# In[ ]:


# @title Audio Input { display-mode: 'form', run: 'auto' } 

input_audio = args2.input_audio #""# @param{type:"string"}
input_audio_offset = args2.input_audio_offset #0 #@param{type:"number"}

# @markdown Bandpass filter specification

variable_name = 'fAudio'
f_center = args2.f_center #1000 # @param{type:"number"}
f_width = args2.f_width #1990 # @param{type:"number"}
order = args2.order #5 # @param{type:"number"}

if input_audio:
  params.input_audio = input_audio
  params.input_audio_offset = input_audio_offset
  params.input_audio_filters = [{
      'variable_name':variable_name,
      'f_center':f_center,
      'f_width':f_width,
      'order':order
    }]


# In[ ]:


# @title Image Motion Settings  { display-mode: 'form', run: 'auto' } 

# @markdown settings whose names end in `_2d` or `_3d` are specific to those animation modes

# @markdown `rotate_3d` *must* be a `[w,x,y,z]` rotation (unit) quaternion. Use `rotate_3d: [1,0,0,0]` for no rotation.

# @markdown [Learn more about rotation quaternions here](https://eater.net/quaternions).

translate_x = args2.translate_x #"0" # @param{type:"string"}
translate_y = args2.translate_y #"0" # @param{type:"string"}
translate_z_3d = args2.translate_z_3d #"0" # @param{type:"string"}
rotate_3d = args2.rotate_3d #"[1,0,0,0]" # @param{type:"string"}
rotate_2d = args2.rotate_2d #"0" # @param{type:"string"}
zoom_x_2d = args2.zoom_x_2d #"0" # @param{type:"string"}
zoom_y_2d = args2.zoom_y_2d #"0" # @param{type:"string"}

params.translate_x = translate_x
params.translate_y = translate_y
params.translate_z_3d = translate_z_3d
params.rotate_3d = rotate_3d
params.rotate_2d = rotate_2d
params.zoom_x_2d = zoom_x_2d
params.zoom_y_2d = zoom_y_2d



#@markdown  3D camera (only used in 3D mode):
if args2.lock_camera == 1:
    lock_camera   = True # @param{type:"boolean"}
else:
    lock_camera   = True # @param{type:"boolean"}

field_of_view = args2.field_of_view #60 # @param{type:"number"}
near_plane = args2.near_plane #1 # @param{type:"number"}
far_plane = args2.far_plane #10000 # @param{type:"number"}

params.lock_camera = lock_camera
params.field_of_view = field_of_view
params.near_plane = near_plane
params.far_plane = far_plane


# In[ ]:


# @title Stabilization Weights and Perspective { display-mode: 'form', run: 'auto' } 

# @markdown `flow_stabilization_weight` is used for `animation_mode: 3D` and `Video Source`

direct_stabilization_weight = args2.direct_stabilization_weight #"" # @param{type:"string"}
semantic_stabilization_weight = args2.semantic_stabilization_weight #"" # @param{type:"string"}
depth_stabilization_weight = args2.depth_stabilization_weight #"" # @param{type:"string"}
edge_stabilization_weight = args2.edge_stabilization_weight #"" # @param{type:"string"}

params.direct_stabilization_weight = direct_stabilization_weight
params.semantic_stabilization_weight = semantic_stabilization_weight
params.depth_stabilization_weight = depth_stabilization_weight
params.edge_stabilization_weight = edge_stabilization_weight


flow_stabilization_weight = args2.flow_stabilization_weight #"" # @param{type:"string"}
flow_long_term_samples = args2.flow_long_term_samples #1 # @param{type:"number"}

params.flow_stabilization_weight = flow_stabilization_weight
params.flow_long_term_samples = flow_long_term_samples



# ## Output Settings

# In[ ]:


# @title Output and Storage Location { display-mode: 'form', run: 'auto' } 

# should I move google drive stuff here?

models_parent_dir = '.' #@param{type:"string"}
params.models_parent_dir = models_parent_dir

file_namespace = "default" #@param{type:"string"}
params.file_namespace = file_namespace
if params.file_namespace == '':
  params.file_namespace = 'out'


allow_overwrite = False #@param{type:"boolean"}
base_name = params.file_namespace

params.allow_overwrite = allow_overwrite
params.base_name = base_name


#@markdown `backups` is used for video transfer, so don't lower it if that's what you're doing
backups =  2**(params.flow_long_term_samples+1)+1 #@param {type:"raw"}
params.backups = backups

from pytti.Notebook import get_last_file

import glob
import re

"""
# to do: move this logic into pytti-core
if not params.allow_overwrite and path_exists(f'images_out/{params.file_namespace}'):
  _, i = get_last_file(f'images_out/{params.file_namespace}', 
                        f'^(?P<pre>{re.escape(params.file_namespace)}\\(?)(?P<index>\\d*)(?P<post>\\)?_1\\.png)$')
  if i == 0:
    print(f"WARNING: file_namespace {params.file_namespace} already has images from run 0")
  elif i is not None:
    print(f"WARNING: file_namespace {params.file_namespace} already has images from runs 0 through {i}")
elif glob.glob(f'images_out/{params.file_namespace}/{params.base_name}_*.png'):
  print(f"WARNING: file_namespace {params.file_namespace} has images which will be overwritten")
"""

# In[ ]:


# @title Experiment Monitoring { display-mode: 'form', run: 'auto' } 

display_every = steps_per_frame # @param{type:"raw"}
clear_every = 0 # @param{type:"raw"}
display_scale = 1 # @param{type:"number"}

params.display_every = display_every
params.clear_every = clear_every
params.display_scale = display_scale

show_graphs = False # @param{type:"boolean"}
use_tensorboard = False #@param{type:"boolean"}

params.show_graphs = show_graphs
params.use_tensorboard = use_tensorboard

# needs to be populated or will fail validation
params.approximate_vram_usage=False



# In[ ]:


print("SETTINGS:")
print(OmegaConf.to_container(params))


# # 2.3 Run it!

# In[ ]:


#@markdown Execute this cell to start image generation
from pytti.workhorse import _main as render_frames
import random

if (seed is None) or (params.seed is None):
  params.seed = random.randint(-0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff)

render_frames(params)

"""

# # Step 3: Render video
# You can dowload from the notebook, but it's faster to download from your drive.

# In[ ]:


#@title 3.1 Render video
from os.path import exists as path_exists
if path_exists(gdrive_fpath):
  get_ipython().run_line_magic('cd', '{gdrive_fpath}')
  drive_mounted = True
else:
  drive_mounted = False
drive_mounted = False

try:
  from pytti.Notebook import change_tqdm_color
except ModuleNotFoundError:
  if drive_mounted:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('ERROR: please run setup (step 1.3).')
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('WARNING: drive is not mounted.\nERROR: please run setup (step 1.3).')
change_tqdm_color()
  
from tqdm.notebook import tqdm
import numpy as np
from os.path import exists as path_exists
from subprocess import Popen, PIPE
from PIL import Image, ImageFile
from os.path import splitext as split_file
import glob
from pytti.Notebook import get_last_file

ImageFile.LOAD_TRUNCATED_IMAGES = True

try:
  params
except NameError:
  raise RuntimeError("ERROR: no parameters. Please run parameters (step 2.1).")

if not path_exists(f"images_out/{params.file_namespace}"):
  if path_exists(f"/content/drive/MyDrive"):
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError(f"ERROR: file_namespace: {params.file_namespace} does not exist.")
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError(f"WARNING: Drive is not mounted.\nERROR: file_namespace: {params.file_namespace} does not exist.")

#@markdown The first run executed in `file_namespace` is number $0$, the second is number $1$, etc.

latest = -1
run_number = latest#@param{type:"raw"}
if run_number == -1:
  _, i = get_last_file(f'images_out/{params.file_namespace}', 
                       f'^(?P<pre>{re.escape(params.file_namespace)}\\(?)(?P<index>\\d*)(?P<post>\\)?_1\\.png)$')
  run_number = i
base_name = params.file_namespace if run_number == 0 else (params.file_namespace+f"({run_number})")
tqdm.write(f'Generating video from {params.file_namespace}/{base_name}_*.png')

all_frames = glob.glob(f'images_out/{params.file_namespace}/{base_name}_*.png')
all_frames.sort(key = lambda s: int(split_file(s)[0].split('_')[-1]))
print(f'found {len(all_frames)} frames matching images_out/{params.file_namespace}/{base_name}_*.png')

start_frame = 0#@param{type:"number"}
all_frames = all_frames[start_frame:]

fps =  params.frames_per_second#@param{type:"raw"}

total_frames = len(all_frames)

if total_frames == 0:
  #THIS IS NOT AN ERROR. This is the code that would
  #make an error if something were wrong.
  raise RuntimeError(f"ERROR: no frames to render in images_out/{params.file_namespace}")

frames = []


for filename in tqdm(all_frames):
  frames.append(Image.open(filename))

cmd_in = ['ffmpeg', '-y', '-f', 'image2pipe', '-vcodec', 'png', '-r', str(fps), '-i', '-']
cmd_out = ['-vcodec', 'libx264', '-r', str(fps), '-pix_fmt', 'yuv420p', '-crf', '1', '-preset', 'veryslow', f'videos/{base_name}.mp4']
if params.input_audio:
  cmd_in += ['-i', str(params.input_audio), '-acodec', 'libmp3lame']

cmd = cmd_in + cmd_out

p = Popen(cmd, stdin=PIPE)
for im in tqdm(frames):
  im.save(p.stdin, 'png')
p.stdin.close()

print("Encoding video...")
p.wait()
print("Video complete.")


# In[ ]:


#@title 3.2 Download the last exported video
from os.path import exists as path_exists
if path_exists(gdrive_fpath):
  get_ipython().run_line_magic('cd', '{gdrive_fpath}')

try:
  from pytti.Notebook import get_last_file
except ModuleNotFoundError:
  if drive_mounted:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('ERROR: please run setup (step 1.3).')
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('WARNING: drive is not mounted.\nERROR: please run setup (step 1.3).')

try:
  params
except NameError:
  #THIS IS NOT AN ERROR. This is the code that would
  #make an error if something were wrong.
  raise RuntimeError("ERROR: please run parameters (step 2.1).")

from google.colab import files
try:
  base_name = params.file_namespace if run_number == 0 else (params.file_namespace+f"({run_number})")
  filename = f'{base_name}.mp4'
except NameError:
  filename, i = get_last_file(f'videos', 
                       f'^(?P<pre>{re.escape(params.file_namespace)}\\(?)(?P<index>\\d*)(?P<post>\\)?\\.mp4)$')

if path_exists(f'videos/{filename}'):
  files.download(f"videos/{filename}")
else:
  if path_exists(f"/content/drive/MyDrive"):
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError(f"ERROR: video videos/{filename} does not exist.")
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError(f"WARNING: Drive is not mounted.\nERROR: video videos/{filename} does not exist.")


# # Sec. 4: Appendix

# In[ ]:


#@title 4.1 Load settings (optional)
#@markdown copy the `SETTINGS:` output from the **Parameters** cell (tripple click to select the whole
#@markdown line from `{'scenes'...` to `}`) and paste them in a note to save them for later.

#@markdown Paste them here in the future to load those settings again. Running this cell with blank settings won't do anything.
from os.path import exists as path_exists
if path_exists(gdrive_fpath):
  get_ipython().run_line_magic('cd', '{gdrive_fpath}')
  drive_mounted = True
else:
  drive_mounted = False
try:
  from pytti.Notebook import *
except ModuleNotFoundError:
  if drive_mounted:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('ERROR: please run setup (step 1.3).')
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('WARNING: drive is not mounted.\nERROR: please run setup (step 1.3).')
change_tqdm_color()
  
import json, random
try:
  from bunch import Bunch
except ModuleNotFoundError:
  if drive_mounted:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('ERROR: please run setup (step 1.3).')
  else:
    #THIS IS NOT AN ERROR. This is the code that would
    #make an error if something were wrong.
    raise RuntimeError('WARNING: drive is not mounted.\nERROR: please run setup (step 1.3).')

settings = ""#@param{type:"string"}
#@markdown Check `random_seed` to overwrite the seed from the settings with a random one for some variation.
random_seed = False #@param{type:"boolean"}

if settings != '':
  params = load_settings(settings, random_seed)


# ## 4.2 License
# 
# ```
# Licensed under the MIT License
# Copyleft (c) 2021 Henry Rachootin
# Copyright (c) 2022 David Marx
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# ```
"""