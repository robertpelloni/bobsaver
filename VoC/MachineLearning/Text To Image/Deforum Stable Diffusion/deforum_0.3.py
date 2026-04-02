# Deforum_Stable_Diffusion.ipynb
# Original file is located at https://colab.research.google.com/github/deforum/stable-diffusion/blob/main/Deforum_Stable_Diffusion.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

models_path = "./"
output_path = "./"

sys.path.append('./taming')
sys.path.append('./CLIP')
sys.path.append('./stable-diffusion')
sys.path.append('./k-diffusion')
sys.path.append('./taming-transformers')
sys.path.append('./pytorch3d-lite')
sys.path.append('./AdaBins')
sys.path.append('./MiDaS')

import os
#@markdown **Python Definitions**
import json
#from IPython import display
import math, os, pathlib, shutil, subprocess, sys, time
import cv2
import numpy as np
import pandas as pd
import random
import requests
import torch, torchvision
import torch.nn as nn
import torchvision.transforms as T
import torchvision.transforms.functional as TF
from contextlib import contextmanager, nullcontext
from einops import rearrange, repeat
from itertools import islice
from omegaconf import OmegaConf
from PIL import Image
from pytorch_lightning import seed_everything
from skimage.exposure import match_histograms
from torchvision.utils import make_grid
from tqdm import tqdm, trange
from types import SimpleNamespace
from torch.cuda.amp import autocast
import py3d_tools as p3d
from helpers import save_samples, sampler_fn
from infer import InferenceHelper
from k_diffusion import sampling
from k_diffusion.external import CompVisDenoiser
from ldm.util import instantiate_from_config
from ldm.models.diffusion.ddim import DDIMSampler
from ldm.models.diffusion.plms import PLMSSampler
from midas.dpt_depth import DPTDepthModel
from midas.transforms import Resize, NormalizeImage, PrepareForNet
import argparse





sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--prompt", type=str, help="the prompt to render")
    parser.add_argument("--negative_prompt", type=str, help="negative prompt")
    parser.add_argument("--H", type=int, help="image height, in pixel space")
    parser.add_argument("--W", type=int, help="image width, in pixel space")
    parser.add_argument("--ckpt", type=str, help="path to checkpoint of model")
    parser.add_argument("--sampler", type=str, help="plms, ddim, k_lms, etc")
    parser.add_argument("--animation_mode", type=str, help="the prompt to render")
    parser.add_argument("--grid_columns", type=int, help="columns in the grid (default: n_samples)")
    parser.add_argument("--scale",  type=float, help="unconditional guidance scale: eps = eps(x, empty) + scale * (eps(x, cond) - eps(x, empty))")
    parser.add_argument("--n_batch", type=int, help="how many single images to batch")
    parser.add_argument("--show_grid", type=int, help="creates grid of images")
    parser.add_argument("--save_samples", type=int, help="save individual images")
    parser.add_argument("--max_frames", type=int, help="how many frames to create")
    parser.add_argument("--init_img", type=str, help="path to the input image")
    parser.add_argument("--strength", type=float, help="strength for noising/unnoising. 1.0 corresponds to full destruction of information in init image")
    parser.add_argument("--ddim_eta", type=float, help="ddim eta (eta=0.0 corresponds to deterministic sampling")
    parser.add_argument("--input_video", type=str, help="video to process")
    parser.add_argument("--extract_nth_frame", type=int)
    parser.add_argument("--use_depth_warping", type=int)
    parser.add_argument("--midas_weight", type=float)
    parser.add_argument("--near_plane", type=float)
    parser.add_argument("--far_plane", type=float)
    parser.add_argument("--fov", type=float)
    parser.add_argument("--padding_mode", type=str)
    parser.add_argument("--sampling_mode", type=str)
    parser.add_argument("--color_coherence", type=str)
    parser.add_argument("--embedding_type", type=str, help=".bin or .pt")
    parser.add_argument("--embedding_path", type=str, help="Path to a pre-trained embedding manager checkpoint")
    parser.add_argument('--seamless',action='store_true',default=False,help='Change the model to seamless tiling (circular) mode',)
    parser.add_argument("--border", type=str)

    

    parser.add_argument("--outdir", type=str, default="outputs/txt2img-samples", help="dir to write results to")
    parser.add_argument("--skip_grid", action='store_true', help="do not save a grid, only individual samples. Helpful when evaluating lots of samples")
    parser.add_argument("--skip_save", action='store_true', help="do not save individual samples. For speed measurements.")
    parser.add_argument("--ddim_steps", type=int, help="number of ddim sampling steps")
    parser.add_argument("--fixed_code", action='store_true', help="if enabled, uses the same starting code across samples ")
    parser.add_argument("--C", type=int, help="latent channels")
    parser.add_argument("--f", type=int, help="downsampling factor")
    parser.add_argument("--from-file", type=str, help="if specified, load prompts from this file")
    parser.add_argument("--config", type=str, default="configs/stable-diffusion/v1-inference.yaml", help="path to config which constructs model")
    parser.add_argument("--seed", type=int, help="the seed (for reproducible sampling)")
    parser.add_argument("--precision", type=str, help="evaluate at this precision")
    parser.add_argument("--dynamic_threshold",  type=float, help="?")
    parser.add_argument("--static_threshold",  type=float, help="?")
    parser.add_argument("--seed_behavior", type=str)
   

    
    parser.add_argument("--image_file", type=str)
    parser.add_argument("--frame_dir", type=str)
    
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device)
print(torch.cuda.get_device_properties(device))
sys.stdout.flush()










def sanitize(prompt):
    whitelist = set('abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ')
    tmp = ''.join(filter(whitelist.__contains__, prompt))
    return '_'.join(prompt.split(" "))

def anim_frame_warp_2d(prev_img_cv2, args, anim_args, keys, frame_idx):
    angle = keys.angle_series[frame_idx]
    zoom = keys.zoom_series[frame_idx]
    translation_x = keys.translation_x_series[frame_idx]
    translation_y = keys.translation_y_series[frame_idx]

    center = (args.W // 2, args.H // 2)
    trans_mat = np.float32([[1, 0, translation_x], [0, 1, translation_y]])
    rot_mat = cv2.getRotationMatrix2D(center, angle, zoom)
    trans_mat = np.vstack([trans_mat, [0,0,1]])
    rot_mat = np.vstack([rot_mat, [0,0,1]])
    xform = np.matmul(rot_mat, trans_mat)

    return cv2.warpPerspective(
        prev_img_cv2,
        xform,
        (prev_img_cv2.shape[1], prev_img_cv2.shape[0]),
        borderMode=cv2.BORDER_WRAP if anim_args.border == 'wrap' else cv2.BORDER_REPLICATE
    )

def anim_frame_warp_3d(prev_img_cv2, anim_args, keys, frame_idx, adabins_helper, midas_model, midas_transform):
    TRANSLATION_SCALE = 1.0/200.0 # matches Disco
    translate_xyz = [
        -keys.translation_x_series[frame_idx] * TRANSLATION_SCALE, 
        keys.translation_y_series[frame_idx] * TRANSLATION_SCALE, 
        -keys.translation_z_series[frame_idx] * TRANSLATION_SCALE
    ]
    rotate_xyz = [
        math.radians(keys.rotation_3d_x_series[frame_idx]), 
        math.radians(keys.rotation_3d_y_series[frame_idx]), 
        math.radians(keys.rotation_3d_z_series[frame_idx])
    ]
    rot_mat = p3d.euler_angles_to_matrix(torch.tensor(rotate_xyz, device=device), "XYZ").unsqueeze(0)
    result = transform_image_3d(prev_img_cv2, adabins_helper, midas_model, midas_transform, rot_mat, translate_xyz, anim_args)
    torch.cuda.empty_cache()
    return result

def add_noise(sample: torch.Tensor, noise_amt: float):
    return sample + torch.randn(sample.shape, device=sample.device) * noise_amt

def download_depth_models():
    def wget(url, outputdir):
        print(subprocess.run(['wget', url, '-P', outputdir], stdout=subprocess.PIPE).stdout.decode('utf-8'))
    if not os.path.exists(os.path.join(models_path, 'dpt_large-midas-2f21e586.pt')):
        print("Downloading dpt_large-midas-2f21e586.pt...")
        wget("https://github.com/intel-isl/DPT/releases/download/1_0/dpt_large-midas-2f21e586.pt", models_path)
    if not os.path.exists('pretrained/AdaBins_nyu.pt'):
        print("Downloading AdaBins_nyu.pt...")
        os.makedirs('pretrained', exist_ok=True)
        wget("https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/AdaBins_nyu.pt", 'pretrained')

def get_output_folder(output_path, batch_folder):
    out_path = os.path.join(output_path,time.strftime('%Y-%m'))
    if batch_folder != "":
        out_path = os.path.join(out_path, batch_folder)
    os.makedirs(out_path, exist_ok=True)
    return out_path

def load_depth_model(optimize=True):
    midas_model = DPTDepthModel(
        path=f"{models_path}/dpt_large-midas-2f21e586.pt",
        backbone="vitl16_384",
        non_negative=True,
    )
    normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])

    midas_transform = T.Compose([
        Resize(
            384, 384,
            resize_target=None,
            keep_aspect_ratio=True,
            ensure_multiple_of=32,
            resize_method="minimal",
            image_interpolation_method=cv2.INTER_CUBIC,
        ),
        normalization,
        PrepareForNet()
    ])

    midas_model.eval()    
    if optimize:
        if device == torch.device("cuda"):
            midas_model = midas_model.to(memory_format=torch.channels_last)
            midas_model = midas_model.half()
    midas_model.to(device)

    return midas_model, midas_transform

def load_img(path, shape):
    if path.startswith('http://') or path.startswith('https://'):
        image = Image.open(requests.get(path, stream=True).raw).convert('RGB')
    else:
        image = Image.open(path).convert('RGB')

    image = image.resize(shape, resample=Image.LANCZOS)
    image = np.array(image).astype(np.float16) / 255.0
    image = image[None].transpose(0, 3, 1, 2)
    image = torch.from_numpy(image)
    return 2.*image - 1.

def load_mask_img(path, shape):
    # path (str): Path to the mask image
    # shape (list-like len(4)): shape of the image to match, usually latent_image.shape
    mask_w_h = (shape[-1], shape[-2])
    if path.startswith('http://') or path.startswith('https://'):
        mask_image = Image.open(requests.get(path, stream=True).raw).convert('RGBA')
    else:
        mask_image = Image.open(path).convert('RGBA')
    mask = mask_image.resize(mask_w_h, resample=Image.LANCZOS)
    mask = mask.convert("L")
    return mask

def maintain_colors(prev_img, color_match_sample, mode):
    if mode == 'Match Frame 0 RGB':
        return match_histograms(prev_img, color_match_sample, multichannel=True)
    elif mode == 'Match Frame 0 HSV':
        prev_img_hsv = cv2.cvtColor(prev_img, cv2.COLOR_RGB2HSV)
        color_match_hsv = cv2.cvtColor(color_match_sample, cv2.COLOR_RGB2HSV)
        matched_hsv = match_histograms(prev_img_hsv, color_match_hsv, multichannel=True)
        return cv2.cvtColor(matched_hsv, cv2.COLOR_HSV2RGB)
    else: # Match Frame 0 LAB
        prev_img_lab = cv2.cvtColor(prev_img, cv2.COLOR_RGB2LAB)
        color_match_lab = cv2.cvtColor(color_match_sample, cv2.COLOR_RGB2LAB)
        matched_lab = match_histograms(prev_img_lab, color_match_lab, multichannel=True)
        return cv2.cvtColor(matched_lab, cv2.COLOR_LAB2RGB)


def make_callback(sampler_name, dynamic_threshold=None, static_threshold=None, mask=None, init_latent=None, sigmas=None, sampler=None, masked_noise_modifier=1.0):  
    # Creates the callback function to be passed into the samplers
    # The callback function is applied to the image at each step
    def dynamic_thresholding_(img, threshold):
        # Dynamic thresholding from Imagen paper (May 2022)
        s = np.percentile(np.abs(img.cpu()), threshold, axis=tuple(range(1,img.ndim)))
        s = np.max(np.append(s,1.0))
        torch.clamp_(img, -1*s, s)
        torch.FloatTensor.div_(img, s)

    # Callback for samplers in the k-diffusion repo, called thus:
    #   callback({'x': x, 'i': i, 'sigma': sigmas[i], 'sigma_hat': sigmas[i], 'denoised': denoised})
    def k_callback_(args_dict):
        
        sys.stdout.write(f"Iteration {args_dict['i']+1}\n")
        sys.stdout.flush()
        
        if dynamic_threshold is not None:
            dynamic_thresholding_(args_dict['x'], dynamic_threshold)
        if static_threshold is not None:
            torch.clamp_(args_dict['x'], -1*static_threshold, static_threshold)
        if mask is not None:
            init_noise = init_latent + noise * args_dict['sigma']
            is_masked = torch.logical_and(mask >= mask_schedule[args_dict['i']], mask != 0 )
            new_img = init_noise * torch.where(is_masked,1,0) + args_dict['x'] * torch.where(is_masked,0,1)
            args_dict['x'].copy_(new_img)

    # Function that is called on the image (img) and step (i) at each step
    def img_callback_(img, i):
        
        sys.stdout.write(f"Iteration {i+1}\n")
        sys.stdout.flush()
        
        # Thresholding functions
        if dynamic_threshold is not None:
            dynamic_thresholding_(img, dynamic_threshold)
        if static_threshold is not None:
            torch.clamp_(img, -1*static_threshold, static_threshold)
        if mask is not None:
            i_inv = len(sigmas) - i - 1
            init_noise = sampler.stochastic_encode(init_latent, torch.tensor([i_inv]*batch_size).to(device), noise=noise)
            is_masked = torch.logical_and(mask >= mask_schedule[i], mask != 0 )
            new_img = init_noise * torch.where(is_masked,1,0) + img * torch.where(is_masked,0,1)
            img.copy_(new_img)
            
              
    if init_latent is not None:
        noise = torch.randn_like(init_latent, device=device) * masked_noise_modifier
    if sigmas is not None and len(sigmas) > 0:
        mask_schedule, _ = torch.sort(sigmas/torch.max(sigmas))
    elif len(sigmas) == 0:
        mask = None # no mask needed if no steps (usually happens because strength==1.0)
    if sampler_name in ["plms","ddim"]: 
        # Callback function formated for compvis latent diffusion samplers
        if mask is not None:
            assert sampler is not None, "Callback function for stable-diffusion samplers requires sampler variable"
            batch_size = init_latent.shape[0]

        callback = img_callback_
    else: 
        # Default callback function uses k-diffusion sampler variables
        callback = k_callback_

    return callback

def prepare_mask(mask_file, mask_shape, mask_brightness_adjust=1.0, mask_contrast_adjust=1.0):
    # path (str): Path to the mask image
    # shape (list-like len(4)): shape of the image to match, usually latent_image.shape
    # mask_brightness_adjust (non-negative float): amount to adjust brightness of the iamge, 
    #     0 is black, 1 is no adjustment, >1 is brighter
    # mask_contrast_adjust (non-negative float): amount to adjust contrast of the image, 
    #     0 is a flat grey image, 1 is no adjustment, >1 is more contrast
                            
    mask = load_mask_img(mask_file, mask_shape)

    # Mask brightness/contrast adjustments
    if mask_brightness_adjust != 1:
        mask = TF.adjust_brightness(mask, mask_brightness_adjust)
    if mask_contrast_adjust != 1:
        mask = TF.adjust_contrast(mask, mask_contrast_adjust)

    # Mask image to array
    mask = np.array(mask).astype(np.float32) / 255.0
    mask = np.tile(mask,(4,1,1))
    mask = np.expand_dims(mask,axis=0)
    mask = torch.from_numpy(mask)

    if args.invert_mask:
        mask = ( (mask - 0.5) * -1) + 0.5
    
    mask = np.clip(mask,0,1)
    return mask

def sample_from_cv2(sample: np.ndarray) -> torch.Tensor:
    sample = ((sample.astype(float) / 255.0) * 2) - 1
    sample = sample[None].transpose(0, 3, 1, 2).astype(np.float16)
    sample = torch.from_numpy(sample)
    return sample

def sample_to_cv2(sample: torch.Tensor) -> np.ndarray:
    sample_f32 = rearrange(sample.squeeze().cpu().numpy(), "c h w -> h w c").astype(np.float32)
    sample_f32 = ((sample_f32 * 0.5) + 0.5).clip(0, 1)
    sample_int8 = (sample_f32 * 255).astype(np.uint8)
    return sample_int8

@torch.no_grad()
def transform_image_3d(prev_img_cv2, adabins_helper, midas_model, midas_transform, rot_mat, translate, anim_args):
    # adapted and optimized version of transform_image_3d from Disco Diffusion https://github.com/alembics/disco-diffusion 

    w, h = prev_img_cv2.shape[1], prev_img_cv2.shape[0]

    # predict depth with AdaBins    
    use_adabins = anim_args.midas_weight < 1.0 and adabins_helper is not None
    if use_adabins:
        sys.stdout.write(f"Estimating depth of {w}x{h} image with AdaBins...\n")
        sys.stdout.flush()
        MAX_ADABINS_AREA = 500000
        MIN_ADABINS_AREA = 448*448

        # resize image if too large or too small
        img_pil = Image.fromarray(cv2.cvtColor(prev_img_cv2, cv2.COLOR_RGB2BGR))
        image_pil_area = w*h
        resized = True
        if image_pil_area > MAX_ADABINS_AREA:
            scale = math.sqrt(MAX_ADABINS_AREA) / math.sqrt(image_pil_area)
            depth_input = img_pil.resize((int(w*scale), int(h*scale)), Image.LANCZOS) # LANCZOS is good for downsampling
            sys.stdout.write(f"  resized to {depth_input.width}x{depth_input.height}\n")
            sys.stdout.flush()
        elif image_pil_area < MIN_ADABINS_AREA:
            scale = math.sqrt(MIN_ADABINS_AREA) / math.sqrt(image_pil_area)
            depth_input = img_pil.resize((int(w*scale), int(h*scale)), Image.BICUBIC)
            sys.stdout.write(f"  resized to {depth_input.width}x{depth_input.height}\n")
            sys.stdout.flush()
        else:
            depth_input = img_pil
            resized = False

        # predict depth and resize back to original dimensions
        try:
            _, adabins_depth = adabins_helper.predict_pil(depth_input)
            if resized:
                adabins_depth = torchvision.transforms.functional.resize(
                    torch.from_numpy(adabins_depth), 
                    torch.Size([h, w]),
                    interpolation=torchvision.transforms.functional.InterpolationMode.BICUBIC
                )
            adabins_depth = adabins_depth.squeeze()
        except:
            sys.stdout.write(f"  exception encountered, falling back to pure MiDaS\n")
            sys.stdout.flush()
            use_adabins = False
        torch.cuda.empty_cache()

    if midas_model is not None:
        # convert image from 0->255 uint8 to 0->1 float for feeding to MiDaS
        img_midas = prev_img_cv2.astype(np.float32) / 255.0
        img_midas_input = midas_transform({"image": img_midas})["image"]

        # MiDaS depth estimation implementation
        sys.stdout.write(f"Estimating depth of {w}x{h} image with MiDaS...\n")
        sys.stdout.flush()
        sample = torch.from_numpy(img_midas_input).float().to(device).unsqueeze(0)
        if device == torch.device("cuda"):
            sample = sample.to(memory_format=torch.channels_last)  
            sample = sample.half()
        midas_depth = midas_model.forward(sample)
        midas_depth = torch.nn.functional.interpolate(
            midas_depth.unsqueeze(1),
            size=img_midas.shape[:2],
            mode="bicubic",
            align_corners=False,
        ).squeeze()
        midas_depth = midas_depth.cpu().numpy()
        torch.cuda.empty_cache()

        # MiDaS makes the near values greater, and the far values lesser. Let's reverse that and try to align with AdaBins a bit better.
        midas_depth = np.subtract(50.0, midas_depth)
        midas_depth = midas_depth / 19.0

        # blend between MiDaS and AdaBins predictions
        if use_adabins:
            depth_map = midas_depth*anim_args.midas_weight + adabins_depth*(1.0-anim_args.midas_weight)
        else:
            depth_map = midas_depth

        depth_map = np.expand_dims(depth_map, axis=0)
        depth_tensor = torch.from_numpy(depth_map).squeeze().to(device)
    else:
        depth_tensor = torch.ones((h, w), device=device)

    pixel_aspect = 1.0 # aspect of an individual pixel (so usually 1.0)
    near, far, fov_deg = anim_args.near_plane, anim_args.far_plane, anim_args.fov
    persp_cam_old = p3d.FoVPerspectiveCameras(near, far, pixel_aspect, fov=fov_deg, degrees=True, device=device)
    persp_cam_new = p3d.FoVPerspectiveCameras(near, far, pixel_aspect, fov=fov_deg, degrees=True, R=rot_mat, T=torch.tensor([translate]), device=device)

    # range of [-1,1] is important to torch grid_sample's padding handling
    y,x = torch.meshgrid(torch.linspace(-1.,1.,h,dtype=torch.float32,device=device),torch.linspace(-1.,1.,w,dtype=torch.float32,device=device))
    z = torch.as_tensor(depth_tensor, dtype=torch.float32, device=device)
    xyz_old_world = torch.stack((x.flatten(), y.flatten(), z.flatten()), dim=1)

    xyz_old_cam_xy = persp_cam_old.get_full_projection_transform().transform_points(xyz_old_world)[:,0:2]
    xyz_new_cam_xy = persp_cam_new.get_full_projection_transform().transform_points(xyz_old_world)[:,0:2]

    offset_xy = xyz_new_cam_xy - xyz_old_cam_xy
    # affine_grid theta param expects a batch of 2D mats. Each is 2x3 to do rotation+translation.
    identity_2d_batch = torch.tensor([[1.,0.,0.],[0.,1.,0.]], device=device).unsqueeze(0)
    # coords_2d will have shape (N,H,W,2).. which is also what grid_sample needs.
    coords_2d = torch.nn.functional.affine_grid(identity_2d_batch, [1,1,h,w], align_corners=False)
    offset_coords_2d = coords_2d - torch.reshape(offset_xy, (h,w,2)).unsqueeze(0)

    image_tensor = torchvision.transforms.functional.to_tensor(Image.fromarray(prev_img_cv2)).to(device)
    new_image = torch.nn.functional.grid_sample(
        image_tensor.add(1/512 - 0.0001).unsqueeze(0), 
        offset_coords_2d, 
        mode=anim_args.sampling_mode, 
        padding_mode=anim_args.padding_mode, 
        align_corners=False
    )

    # convert back to cv2 style numpy array 0->255 uint8
    result = rearrange(
        new_image.squeeze().clamp(0,1) * 255.0, 
        'c h w -> h w c'
    ).cpu().numpy().astype(np.uint8)
    return result

def generate(args, return_latent=False, return_sample=False, return_c=False):
    seed_everything(args.seed)
    os.makedirs(args.outdir, exist_ok=True)

    if args.sampler == 'plms':
        sampler = PLMSSampler(model)
    else:
        sampler = DDIMSampler(model)

    model_wrap = CompVisDenoiser(model)       
    batch_size = args.n_samples
    prompt = args.prompt
    assert prompt is not None
    data = [batch_size * [prompt]]

    init_latent = None
    if args.init_latent is not None:
        init_latent = args.init_latent
    elif args.init_sample is not None:
        init_latent = model.get_first_stage_encoding(model.encode_first_stage(args.init_sample))
    elif args.use_init and args.init_image != None and args.init_image != '':
        init_image = load_img(args.init_image, shape=(args.W, args.H)).to(device)
        init_image = repeat(init_image, '1 ... -> b ...', b=batch_size)
        #fix for using less VRAM 2/3 next line added
        with torch.cuda.amp.autocast(): # needed for half precision!
            init_latent = model.get_first_stage_encoding(model.encode_first_stage(init_image))  # move to latent space        

    if not args.use_init and args.strength > 0:
        #sys.stdout.write("\nNo init image, but strength > 0. This may give you some strange results.\n")
        sys.stdout.write("\nAuto-setting init strength to 0 because no init image has been specified.\n")
        sys.stdout.flush()
        args.strength=0

    # Mask functions
    mask = None
    if args.use_mask:
        assert args.mask_file is not None, "use_mask==True: An mask image is required for a mask"
        assert args.use_init, "use_mask==True: use_init is required for a mask"
        assert init_latent is not None, "use_mask==True: An latent init image is required for a mask"

        mask = prepare_mask(args.mask_file, 
                            init_latent.shape, 
                            args.mask_contrast_adjust, 
                            args.mask_brightness_adjust)
        
        mask = mask.to(device)
        mask = repeat(mask, '1 ... -> b ...', b=batch_size)
        
    t_enc = int((1.0-args.strength) * args.steps)

    #sys.stdout.write(f"args.strength = {args.strength} args.steps = {args.steps} t_enc = {t_enc}\n")
    #sys.stdout.flush()

    # Noise schedule for the k-diffusion samplers (used for masking)
    k_sigmas = model_wrap.get_sigmas(args.steps)
    k_sigmas = k_sigmas[len(k_sigmas)-t_enc-1:]

    if args.sampler in ['plms','ddim']:
        sampler.make_schedule(ddim_num_steps=args.steps, ddim_eta=args.ddim_eta, ddim_discretize='fill', verbose=False)

    callback = make_callback(sampler_name=args.sampler,
                            dynamic_threshold=args.dynamic_threshold, 
                            static_threshold=args.static_threshold,
                            mask=mask, 
                            init_latent=init_latent,
                            sigmas=k_sigmas,
                            sampler=sampler)    

    results = []
    precision_scope = autocast if args.precision == "autocast" else nullcontext
    with torch.no_grad():
        #with precision_scope("cuda"):
        load_model_from_config#fix for using less VRAM 3/3 - change previous line to this
        with torch.cuda.amp.autocast():
            with model.ema_scope():
                for prompts in data:
                    uc = None
                    if args.scale != 1.0:
                        uc = model.get_learned_conditioning(batch_size * [args2.negative_prompt])
                    if isinstance(prompts, tuple):
                        prompts = list(prompts)
                    c = model.get_learned_conditioning(prompts)

                    if args.init_c != None:
                        c = args.init_c

                    if args.sampler in ["klms","dpm2","dpm2_ancestral","heun","euler","euler_ancestral"]:
                        samples = sampler_fn(
                            c=c, 
                            uc=uc, 
                            args=args, 
                            model_wrap=model_wrap, 
                            init_latent=init_latent, 
                            t_enc=t_enc, 
                            device=device, 
                            cb=callback)
                    else:
                        # args.sampler == 'plms' or args.sampler == 'ddim':
                        if init_latent is not None and args.strength > 0:
                            z_enc = sampler.stochastic_encode(init_latent, torch.tensor([t_enc]*batch_size).to(device))
                        else:
                            z_enc = torch.randn([args.n_samples, args.C, args.H // args.f, args.W // args.f], device=device)
                        if args.sampler == 'ddim':
                            samples = sampler.decode(z_enc, 
                                                     c, 
                                                     t_enc, 
                                                     unconditional_guidance_scale=args.scale,
                                                     unconditional_conditioning=uc,
                                                     img_callback=callback)
                        elif args.sampler == 'plms': # no "decode" function in plms, so use "sample"
                            shape = [args.C, args.H // args.f, args.W // args.f]
                            samples, _ = sampler.sample(S=args.steps,
                                                            conditioning=c,
                                                            batch_size=args.n_samples,
                                                            shape=shape,
                                                            verbose=False,
                                                            unconditional_guidance_scale=args.scale,
                                                            unconditional_conditioning=uc,
                                                            eta=args.ddim_eta,
                                                            x_T=z_enc,
                                                            img_callback=callback)
                        else:
                            raise Exception(f"Sampler {args.sampler} not recognised.")

                    if return_latent:
                        results.append(samples.clone())

                    x_samples = model.decode_first_stage(samples)
                    if return_sample:
                        results.append(x_samples.clone())

                    x_samples = torch.clamp((x_samples + 1.0) / 2.0, min=0.0, max=1.0)

                    if return_c:
                        results.append(c.clone())

                    for x_sample in x_samples:
                        x_sample = 255. * rearrange(x_sample.cpu().numpy(), 'c h w -> h w c')
                        image = Image.fromarray(x_sample.astype(np.uint8))
                        results.append(image)
    return results

#@markdown **Select and Load Model**

sys.stdout.write(f"Loading model {args2.ckpt} ...\n")
sys.stdout.flush()

model_config = "v1-inference.yaml" #@param ["custom","v1-inference.yaml"]
model_checkpoint =  args2.ckpt #"sd-v1-4.ckpt" #@param ["custom","sd-v1-4-full-ema.ckpt","sd-v1-4.ckpt","sd-v1-3-full-ema.ckpt","sd-v1-3.ckpt","sd-v1-2-full-ema.ckpt","sd-v1-2.ckpt","sd-v1-1-full-ema.ckpt","sd-v1-1.ckpt"]
custom_config_path = "" #@param {type:"string"}
custom_checkpoint_path = "" #@param {type:"string"}
embedding_type = args2.embedding_type #".pt" #@param [".bin",".pt"]
embedding_path = args2.embedding_path #"/content/drive/MyDrive/AI/models/Seraphim_MATRIXMANE.pt" #@param {type:"string"}

load_on_run_all = True #@param {type: 'boolean'}
half_precision = True # check
check_sha256 = False #@param {type:"boolean"}

model_map = {
    "sd-v1-4-full-ema.ckpt": {'sha256': '14749efc0ae8ef0329391ad4436feb781b402f4fece4883c7ad8d10556d8a36a'},
    "sd-v1-4.ckpt": {'sha256': 'fe4efff1e174c627256e44ec2991ba279b3816e364b49f9be2abc0b3ff3f8556'},
    "sd-v1-3-full-ema.ckpt": {'sha256': '54632c6e8a36eecae65e36cb0595fab314e1a1545a65209f24fde221a8d4b2ca'},
    "sd-v1-3.ckpt": {'sha256': '2cff93af4dcc07c3e03110205988ff98481e86539c51a8098d4f2236e41f7f2f'},
    "sd-v1-2-full-ema.ckpt": {'sha256': 'bc5086a904d7b9d13d2a7bccf38f089824755be7261c7399d92e555e1e9ac69a'},
    "sd-v1-2.ckpt": {'sha256': '3b87d30facd5bafca1cbed71cfb86648aad75d1c264663c0cc78c7aea8daec0d'},
    "sd-v1-1-full-ema.ckpt": {'sha256': 'efdeb5dc418a025d9a8cc0a8617e106c69044bc2925abecc8a254b2910d69829'},
    "sd-v1-1.ckpt": {'sha256': '86cd1d3ccb044d7ba8db743d717c9bac603c4043508ad2571383f954390f3cea'}
}


import shutil

originalpt = r'stable-diffusion/ldm/modules/embedding_managerpt.py'

originalbin = r'stable-diffusion/ldm/modules/embedding_managerbin.py'

if embedding_type == ".pt":
  file_path = "stable-diffusion/ldm/modules/embedding_manager.py"
  if os.path.isfile(file_path):
    os.remove(file_path)
    shutil.copyfile(originalpt, file_path)
    print('using .pt embedding')
elif embedding_type == ".bin":
  file_path = "stable-diffusion/ldm/modules/embedding_manager.py"
  if os.path.isfile(file_path):
    os.remove(file_path)
    shutil.copyfile(originalbin, file_path)
    print('using .bin embedding')

# config path
ckpt_config_path = custom_config_path if model_config == "custom" else os.path.join(models_path, model_config)
"""
if os.path.exists(ckpt_config_path):
    sys.stdout.write(f"{ckpt_config_path} exists\n")
    sys.stdout.flush()
else:
    ckpt_config_path = "./stable-diffusion/configs/stable-diffusion/v1-inference.yaml"
sys.stdout.write(f"Using config: {ckpt_config_path}\n")
sys.stdout.flush()
"""
# checkpoint path or download
ckpt_path = custom_checkpoint_path if model_checkpoint == "custom" else os.path.join(models_path, model_checkpoint)
ckpt_valid = True
"""
if os.path.exists(ckpt_path):
    sys.stdout.write(f"{ckpt_path} exists\n")
    sys.stdout.flush()
else:
    sys.stdout.write(f"Please download model checkpoint and place in {os.path.join(models_path, model_checkpoint)}\n")
    sys.stdout.flush()
    ckpt_valid = False
if check_sha256 and model_checkpoint != "custom" and ckpt_valid:
    import hashlib
    sys.stdout.write("\n...checking sha256\n")
    sys.stdout.flush()
    with open(ckpt_path, "rb") as f:
        bytes = f.read() 
        hash = hashlib.sha256(bytes).hexdigest()
        del bytes
    if model_map[model_checkpoint]["sha256"] == hash:
        sys.stdout.write("hash is correct\n")
        sys.stdout.flush()
    else:
        sys.stdout.write("hash in not correct\n")
        sys.stdout.flush()
        ckpt_valid = False

#if ckpt_valid:
#    print(f"Using ckpt: {ckpt_path}")
"""

def load_model_from_config(config, ckpt, verbose=False, device='cuda', half_precision=True):
    map_location = "cuda" #@param ["cpu", "cuda"]
    #sys.stdout.write(f"Loading model from {ckpt}\n")
    #sys.stdout.flush()
    pl_sd = torch.load(ckpt, map_location=map_location, weights_only=False)
    """
    if "global_step" in pl_sd:
        sys.stdout.write(f"Global Step: {pl_sd['global_step']}\n")
        sys.stdout.flush()
    """
    sd = pl_sd["state_dict"]
    model = instantiate_from_config(config.model)
    if embedding_path is not None:
        model.embedding_manager.load(embedding_path)
    m, u = model.load_state_dict(sd, strict=False)
    """
    if len(m) > 0 and verbose:
        sys.stdout.write("missing keys:\n")
        sys.stdout.write(m)
        sys.stdout.flush()
    if len(u) > 0 and verbose:
        sys.stdout.write("unexpected keys:\n")
        sys.stdout.write(u)
        sys.stdout.flush()
    """
    if half_precision:
        model = model.half().to(device)
    else:
        model = model.to(device)
    model.eval()
    return model

if load_on_run_all and ckpt_valid:
    
    #seamless
    def patch_conv(cls):
        init = cls.__init__
        def __init__(self, *args, **kwargs):
                return init(self, *args, **kwargs, padding_mode='circular')
        cls.__init__ = __init__
    
    if args2.seamless:
        print(">> changed to seamless tiling mode")
        patch_conv(torch.nn.Conv2d)
        
    local_config = OmegaConf.load(f"{ckpt_config_path}")
    model = load_model_from_config(local_config, f"{ckpt_path}",half_precision=half_precision)
    if args2.embedding_path is not None:
        model.embedding_manager.load(args2.embedding_path)

    #fix for using less VRAM 1/3 - add next line
    model.half()

    device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
    model = model.to(device)

"""# Settings

### Animation Settings
"""

def DeforumAnimArgs():

    #@markdown ####**Animation:**
    animation_mode = args2.animation_mode #'None' #@param ['None', '2D', 'Video Input', 'Interpolation'] {type:'string'}
    max_frames = args2.max_frames #350 #@param {type:"number"}
    border = args2.border #'wrap' #@param ['wrap', 'replicate'] {type:'string'}

    #@markdown ####**Motion Parameters:**
#VOC START 2 - DO NOT DELETE
    angle = "0:(0)"
    zoom = "0:(1.04)"
    angle = "0:(0)"
    zoom = "0:(1.04)"
    translation_x = "0:(0),30:(0.249),60:(-0.118),90:(0.251),120:(-0.001),150:(0.065),180:(-0.062),210:(-0.087),240:(0.236),270:(0.102),300:(-0.063),330:(-0.168),360:(0.076),390:(-0.050),420:(-0.237),450:(0.067),480:(-0.281),510:(0.021),540:(0.030),570:(0.134),600:(-0.178),630:(-0.210),660:(-0.263),690:(0.189),720:(-0.171),750:(-0.275),780:(0.248),810:(-0.040),840:(0.211),870:(0.241),900:(0.175)"
    translation_y = "0:(0),30:(-0.254),60:(-0.272),90:(-0.086),120:(0.263),150:(-0.287),180:(-0.284),210:(0.256),240:(-0.021),270:(0.137),300:(-0.007),330:(0.043),360:(-0.147),390:(0.052),420:(-0.217),450:(0.017),480:(-0.206),510:(0.109),540:(-0.269),570:(0.073),600:(-0.102),630:(0.061),660:(-0.041),690:(0.297),720:(-0.277),750:(0.162),780:(-0.019),810:(0.114),840:(0.042),870:(-0.292),900:(-0.125)"
    translation_z = "0:(5)"
    rotation_3d_x = "0:(0),30:(0.097),60:(-0.261),90:(0.288),120:(0.117),150:(0.039),180:(0.286),210:(-0.246),240:(0.145),270:(0.110),300:(0.267),330:(0.158),360:(-0.022),390:(0.144),420:(-0.047),450:(0.142),480:(-0.113),510:(0.042),540:(-0.058),570:(0.209),600:(0.147),630:(-0.147),660:(0.298),690:(0.205),720:(0.074),750:(-0.294),780:(0.227),810:(0.216),840:(0.051),870:(-0.224),900:(-0.181)"
    rotation_3d_y = "0:(0),30:(0.048),60:(-0.137),90:(0.136),120:(-0.057),150:(0.252),180:(-0.200),210:(0.149),240:(-0.258),270:(0.069),300:(0.056),330:(-0.248),360:(0.089),390:(-0.124),420:(0.110),450:(-0.052),480:(0.157),510:(-0.054),540:(0.031),570:(-0.060),600:(0.259),630:(-0.203),660:(0.122),690:(0.093),720:(-0.114),750:(-0.264),780:(0.074),810:(-0.085),840:(0.197),870:(-0.268),900:(0.224)"
    rotation_3d_z = "0:(0),30:(0.054),60:(0.068),90:(-0.197),120:(0.024),150:(-0.020),180:(0.242),210:(0.045),240:(-0.165),270:(-0.141),300:(0.252),330:(-0.219),360:(0.217),390:(-0.260),420:(-0.262),450:(0.250),480:(-0.033),510:(-0.037),540:(0.027),570:(0.128),600:(0.045),630:(0.012),660:(-0.161),690:(0.248),720:(-0.145),750:(0.281),780:(-0.278),810:(-0.166),840:(0.230),870:(0.095),900:(-0.298)"
    noise_schedule = "0:(0.02)"
    strength_schedule = "0:(0.65)"
    contrast_schedule = "0: (1.0)"
#VOC FINISH 2 - DO NOT DELETE

    #@markdown ####**Coherence:**
    color_coherence = args2.color_coherence #'Match Frame 0 LAB' #@param ['None', 'Match Frame 0 HSV', 'Match Frame 0 LAB', 'Match Frame 0 RGB'] {type:'string'}

    #@markdown #### Depth Warping
    if args2.use_depth_warping == 1:
        use_depth_warping = True #@param {type:"boolean"}
    else:
        use_depth_warping = False #@param {type:"boolean"}
    midas_weight = args2.midas_weight #0.3#@param {type:"number"}
    near_plane = args2.near_plane #200
    far_plane = args2.far_plane #10000
    fov = args2.fov #40#@param {type:"number"}
    padding_mode = args2.padding_mode #'border'#@param ['border', 'reflection', 'zeros'] {type:'string'}
    sampling_mode = args2.sampling_mode #'bicubic'#@param ['bicubic', 'bilinear', 'nearest'] {type:'string'}

    #@markdown ####**Video Input:**
    video_init_path =args2.input_video #'/content/video_in.mp4'#@param {type:"string"}
    extract_nth_frame = args2.extract_nth_frame #1#@param {type:"number"}

    #@markdown ####**Interpolation:**
    interpolate_key_frames = True #@param {type:"boolean"}
    interpolate_x_frames = 4 #@param {type:"number"}
    
    #@markdown ####**Resume Animation:**
    resume_from_timestring = False #@param {type:"boolean"}
    resume_timestring = "20220829210106" #@param {type:"string"}

    return locals()

class DeformAnimKeys():
    def __init__(self, anim_args):
        self.angle_series = get_inbetweens(parse_key_frames(anim_args.angle))
        self.zoom_series = get_inbetweens(parse_key_frames(anim_args.zoom))
        self.translation_x_series = get_inbetweens(parse_key_frames(anim_args.translation_x))
        self.translation_y_series = get_inbetweens(parse_key_frames(anim_args.translation_y))
        self.translation_z_series = get_inbetweens(parse_key_frames(anim_args.translation_z))
        self.rotation_3d_x_series = get_inbetweens(parse_key_frames(anim_args.rotation_3d_x))
        self.rotation_3d_y_series = get_inbetweens(parse_key_frames(anim_args.rotation_3d_y))
        self.rotation_3d_z_series = get_inbetweens(parse_key_frames(anim_args.rotation_3d_z))
        self.noise_schedule_series = get_inbetweens(parse_key_frames(anim_args.noise_schedule))
        self.strength_schedule_series = get_inbetweens(parse_key_frames(anim_args.strength_schedule))
        self.contrast_schedule_series = get_inbetweens(parse_key_frames(anim_args.contrast_schedule))


def get_inbetweens(key_frames, integer=False, interp_method='Linear'):
    key_frame_series = pd.Series([np.nan for a in range(anim_args.max_frames)])

    for i, value in key_frames.items():
        key_frame_series[i] = value
    key_frame_series = key_frame_series.astype(float)
    
    if interp_method == 'Cubic' and len(key_frames.items()) <= 3:
      interp_method = 'Quadratic'    
    if interp_method == 'Quadratic' and len(key_frames.items()) <= 2:
      interp_method = 'Linear'
          
    key_frame_series[0] = key_frame_series[key_frame_series.first_valid_index()]
    key_frame_series[anim_args.max_frames-1] = key_frame_series[key_frame_series.last_valid_index()]
    key_frame_series = key_frame_series.interpolate(method=interp_method.lower(),limit_direction='both')
    if integer:
        return key_frame_series.astype(int)
    return key_frame_series

def parse_key_frames(string, prompt_parser=None):
    import re
    pattern = r'((?P<frame>[0-9]+):[\s]*[\(](?P<param>[\S\s]*?)[\)])'
    frames = dict()
    for match_object in re.finditer(pattern, string):
        frame = int(match_object.groupdict()['frame'])
        param = match_object.groupdict()['param']
        if prompt_parser:
            frames[frame] = prompt_parser(param)
        else:
            frames[frame] = param
    if frames == {} and len(string) != 0:
        raise RuntimeError('Key Frame string not correctly formatted')
    return frames

"""### Prompts
`animation_mode: None` batches on list of *prompts*. `animation_mode: 2D` uses *animation_prompts* key frame sequence
"""

prompts = [
#VOC START 3 - DO NOT DELETE
    args2.prompt,
#VOC FINISH 3 - DO NOT DELETE
]

animation_prompts = {
#VOC START - DO NOT DELETE
    0: args2.prompt,
#VOC FINISH - DO NOT DELETE
}

"""# Run"""

def DeforumArgs():
    
    #@markdown **Image Settings**
    W = args2.W
    H = args2.H
    #W, H = map(lambda x: x - x % 64, (W, H))  # resize to integer multiple of 64

    #@markdown **Sampling Settings**
    seed = args2.seed #@param
    sampler = args2.sampler #'klms' #@param ["klms","dpm2","dpm2_ancestral","heun","euler","euler_ancestral","plms", "ddim"]
    steps = args2.ddim_steps #50 #@param
    scale = args2.scale #7 #@param
    ddim_eta = args2.ddim_eta #@param
    dynamic_threshold = None
    static_threshold = None   

    #@markdown **Save & Display Settings**
    if args2.save_samples == 1:
        save_samples = True #@param {type:"boolean"}
    else:
        save_samples = False #@param {type:"boolean"}

    save_settings = False #@param {type:"boolean"}
    display_samples = False #@param {type:"boolean"}

    #@markdown **Batch Settings**
    n_batch = args2.n_batch #@param
    batch_name = "StableFun" #@param {type:"string"}
    filename_format = "{timestring}_{index}_{prompt}.png" #@param ["{timestring}_{index}_{seed}.png","{timestring}_{index}_{prompt}.png"]
    seed_behavior = args2.seed_behavior #"iter" #@param ["iter","fixed","random"]
    """
    if args2.show_grid == 1:
        make_grid = True
    else:
        make_grid = False
    """
    #always make grid file for preview, it is deleted if grid checkbox unchecked later
    make_grid = True
    grid_rows = args2.grid_columns #2 #@param 
    #outdir = get_output_folder(output_path, batch_name)
    outdir = args2.frame_dir
    
    #@markdown **Init Settings**
    if args2.init_img is not None:
        use_init = True #@param {type:"boolean"}
    else:
        use_init = False #@param {type:"boolean"}

    strength = args2.strength #0.0 #@param {type:"number"}
    init_image = args2.init_img #"https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
    # Whiter areas of the mask are areas that change more
    use_mask = False #@param {type:"boolean"}
    mask_file = "https://www.filterforge.com/wiki/images/archive/b/b7/20080927223728%21Polygonal_gradient_thumb.jpg" #@param {type:"string"}
    invert_mask = False #@param {type:"boolean"}
    # Adjust mask image, 1.0 is no adjustment. Should be positive numbers.
    mask_brightness_adjust = 1.0  #@param {type:"number"}
    mask_contrast_adjust = 1.0  #@param {type:"number"}

    n_samples = 1 # doesnt do anything
    precision = 'autocast' 
    C = 4
    f = 8

    prompt = ""
    timestring = ""
    init_latent = None
    init_sample = None
    init_c = None

    return locals()



def next_seed(args):
    if args.seed_behavior == 'iter':
        args.seed += 1
    elif args.seed_behavior == 'fixed':
        pass # always keep seed the same
    else:
        args.seed = random.randint(0, 2**32)
    return args.seed

def render_image_batch(args):
    args.prompts = {k: f"{v:05d}" for v, k in enumerate(prompts)}
    
    # create output folder for the batch
    os.makedirs(args.outdir, exist_ok=True)
    """
    if args.save_settings or args.save_samples:
        sys.stdout.write(f"Saving to {os.path.join(args.outdir, args.timestring)}_*\n")
        sys.stdout.flush()

    # save settings for the batch
    if args.save_settings:
        filename = os.path.join(args.outdir, f"{args.timestring}_settings.txt")
        with open(filename, "w+", encoding="utf-8") as f:
            json.dump(dict(args.__dict__), f, ensure_ascii=False, indent=4)
    """
    index = 0
    seedlist=[]
    
    # function for init image batching
    init_array = []
    if args.use_init:
        if args.init_image == "":
            raise FileNotFoundError("No path was given for init_image")
        if args.init_image.startswith('http://') or args.init_image.startswith('https://'):
            init_array.append(args.init_image)
        elif not os.path.isfile(args.init_image):
            if args.init_image[-1] != "/": # avoids path error by adding / to end if not there
                args.init_image += "/" 
            for image in sorted(os.listdir(args.init_image)): # iterates dir and appends images to init_array
                if image.split(".")[-1] in ("png", "jpg", "jpeg"):
                    init_array.append(args.init_image + image)
        else:
            init_array.append(args.init_image)
    else:
        init_array = [""]

    # when doing large batches don't flood browser with images
    clear_between_batches = args.n_batch >= 32

    for iprompt, prompt in enumerate(prompts):  
        args.prompt = prompt
        sys.stdout.write(f"Prompt {iprompt+1} of {len(prompts)}\n")
        sys.stdout.write(f"{args.prompt}\n")
        sys.stdout.flush()
      
        all_images = []

        for batch_index in range(args.n_batch):
            #if clear_between_batches and batch_index % 32 == 0: 
            #    display.clear_output(wait=True)            
            sys.stdout.write(f"Batch {batch_index+1} of {args.n_batch}\n")
            sys.stdout.flush()
            
            for image in init_array: # iterates the init images
                args.init_image = image
                results = generate(args)
                for image in results:
                    if args.make_grid:
                        all_images.append(T.functional.pil_to_tensor(image))
                    if args.save_samples:
                        
                        #filename = f"{args.timestring}_{index:05}_{args.seed}.png"
                        #filename = args2.image_file
                        
                        if len(prompts) == 1:
                            filename = f"{args2.image_file[:-4]} {args.seed}.png"
                        else:
                            filename = f"{os.path.dirname(args2.image_file)}\\{args.prompt} {args.seed}.png"
                        
                        #add number to filename for duplicates
                        if os.path.exists(filename):
                            i = 1
                            tmp = filename[:-4]
                            while os.path.exists(f"{tmp} {i:04d}.png"):
                                i += 1
                            filename = f"{tmp} {i:04d}.png"

                        sys.stdout.flush()
                        sys.stdout.write(f'Saving individual image "{filename}"...\n')
                        sys.stdout.flush()

                        image.save(os.path.join(args.outdir, filename))

                        sys.stdout.write('Saved individual image\n')
                        sys.stdout.flush()

                        """
                        if args.filename_format == "{timestring}_{index}_{prompt}.png":
                            filename = f"{args.timestring}_{index:05}_{sanitize(prompt)[:160]}.png"
                        else:
                            filename = f"{args.timestring}_{index:05}_{args.seed}.png"
                        image.save(os.path.join(args.outdir, filename))
                        """
                        
                    #if args.display_samples:
                    #    display.display(image)
                    index += 1
                seedlist.append(args.seed)
                args.seed = next_seed(args)

        #print(len(all_images))
        if args.make_grid and len(prompts)==1:

            if args.n_batch > 1:
                filename=f"{args2.image_file[:-4]} {args2.seed} grid.png"
            else:
                filename=f"{args2.image_file[:-4]} {args2.seed}.png"

            #add number to filename for duplicates
            if os.path.exists(filename):
                i = 1
                tmp = filename[:-4]
                while os.path.exists(f"{tmp} {i:04d}.png"):
                    i += 1
                filename = f"{tmp} {i:04d}.png"

            sys.stdout.flush()
            sys.stdout.write(f'Saving grid image "{filename}" ...\n')
            sys.stdout.flush()

            grid = make_grid(all_images, nrow=int(len(all_images)/args.grid_rows))
            grid = rearrange(grid, 'c h w -> h w c').cpu().numpy()

            #filename = f"{args.timestring}_{iprompt:05d}_grid_{args.seed}.png"

            grid_image = Image.fromarray(grid.astype(np.uint8))
            #grid_image.save(os.path.join(args.outdir, filename))
            grid_image.save(filename)
            
            #grid_count += 1

            sys.stdout.flush()
            sys.stdout.write('Saved grid image\n')
            sys.stdout.write(f'Seeds used :\n{seedlist}')            
            #display.clear_output(wait=True)            
            #display.display(grid_image)


def render_animation(args, anim_args):
    # animations use key framed prompts
    args.prompts = animation_prompts

    # expand key frame strings to values
    keys = DeformAnimKeys(anim_args)

    # resume animation
    start_frame = 0
    if anim_args.resume_from_timestring:
        for tmp in os.listdir(args.outdir):
            if tmp.split("_")[0] == anim_args.resume_timestring:
                start_frame += 1
        start_frame = start_frame - 1

    # create output folder for the batch
    os.makedirs(args.outdir, exist_ok=True)
    sys.stdout.write(f"Saving animation frames to {args.outdir}\n")
    sys.stdout.flush()

    """
    # save settings for the batch
    settings_filename = os.path.join(args.outdir, f"{args.timestring}_settings.txt")
    with open(settings_filename, "w+", encoding="utf-8") as f:
        s = {**dict(args.__dict__), **dict(anim_args.__dict__)}
        json.dump(s, f, ensure_ascii=False, indent=4)
    """
    
    # resume from timestring
    if anim_args.resume_from_timestring:
        args.timestring = anim_args.resume_timestring

    # expand prompts out to per-frame
    prompt_series = pd.Series([np.nan for a in range(anim_args.max_frames)])
    for i, prompt in animation_prompts.items():
        prompt_series[i] = prompt
    prompt_series = prompt_series.ffill().bfill()

    # check for video inits
    using_vid_init = anim_args.animation_mode == 'Video Input'

    # load depth model for 3D
    if anim_args.animation_mode == '3D' and anim_args.use_depth_warping:
        download_depth_models()
        adabins_helper = InferenceHelper(dataset='nyu', device=device)
        midas_model, midas_transform = load_depth_model()
    else:
        adabins_helper, midas_model, midas_transform = None, None, None

    args.n_samples = 1
    prev_sample = None
    color_match_sample = None
    
    # resume animation
    if anim_args.resume_from_timestring:
    	path = os.path.join(args.outdir,f"{args.timestring}_{start_frame-1:05}.png")
    	img = cv2.imread(path)
    	img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    	prev_sample = sample_from_cv2(img)
    
    for frame_idx in range(start_frame,anim_args.max_frames):
        
        sys.stdout.flush()
        sys.stdout.write(f"Rendering animation frame {frame_idx} of {anim_args.max_frames}\n")
        sys.stdout.flush()
        #need this 100ms sleep here to allow VoC to see previous stats as a single line
        time.sleep(0.1)
        
        noise = keys.noise_schedule_series[frame_idx]
        strength = keys.strength_schedule_series[frame_idx]
        contrast = keys.contrast_schedule_series[frame_idx]

        # apply transforms to previous frame
        if prev_sample is not None:

            if anim_args.animation_mode == '2D':
                prev_img = anim_frame_warp_2d(sample_to_cv2(prev_sample), args, anim_args, keys, frame_idx)
            else: # '3D'
                prev_img = anim_frame_warp_3d(sample_to_cv2(prev_sample), anim_args, keys, frame_idx, adabins_helper, midas_model, midas_transform)

            # apply color matching
            if anim_args.color_coherence != 'None':
                if color_match_sample is None:
                    color_match_sample = prev_img.copy()
                else:
                    prev_img = maintain_colors(prev_img, color_match_sample, anim_args.color_coherence)

            # apply scaling
            contrast_sample = prev_img * contrast
            # apply frame noising
            noised_sample = add_noise(sample_from_cv2(contrast_sample), noise)

            # use transformed previous frame as init for current
            args.use_init = True
            #args.init_sample = noised_sample.half().to(device)
            if half_precision:
                args.init_sample = noised_sample.half().to(device)
            else:
                args.init_sample = noised_sample.to(device)
            args.strength = max(0.0, min(1.0, strength))

        # grab prompt for current frame
        args.prompt = prompt_series[frame_idx]
        sys.stdout.write(f"{args.prompt}\n")
        sys.stdout.write(f"{args.timestring}\n")
        sys.stdout.flush()

        # grab init image for current frame
        if using_vid_init:
        #if args2.input_video is not "":
            #init_frame = os.path.join(args.outdir, 'inputframes', f"{frame_idx+1:04}.jpg")            
            init_frame = os.path.join(args2.frame_dir, 'inputframes', f"{frame_idx+1:04}.jpg")            
            sys.stdout.flush()
            sys.stdout.write(f"Using video init frame {init_frame}\n")
            sys.stdout.flush()
            args.init_image = init_frame
        else:
            #sys.stdout.write("NOT USING VIDEO INPUT\n")
            sys.stdout.flush()
        

        # sample the diffusion model
        results = generate(args, return_latent=False, return_sample=True)
        sample, image = results[0], results[1]
    
        sys.stdout.write('Saving progress ...\n')
        sys.stdout.flush()

        #filename = f"{args.timestring}_{index:05}_{args.seed}.png"
        filename = args2.image_file
        image.save(os.path.join(args.outdir, filename))

        #filename = f"{args.timestring}_{frame_idx:05}.png"
        filename = f"FRA{frame_idx+1:05}.png"
        #image.save(os.path.join(args.outdir, filename))
        image.save(os.path.join(args2.frame_dir, filename))
        if not using_vid_init:
            prev_sample = sample
        
        sys.stdout.write('Progress saved\n')
        sys.stdout.flush()

        #display.clear_output(wait=True)
        #display.display(image)

        args.seed = next_seed(args)

def render_input_video(args, anim_args):
    # create a folder for the video input frames to live in
    #video_in_frame_path = os.path.join(args.outdir, 'inputframes') 
    video_in_frame_path = os.path.join(args2.frame_dir, 'inputframes') 
    os.makedirs(os.path.join(args.outdir, video_in_frame_path), exist_ok=True)
    
    # save the video frames from input video
    sys.stdout.write(f"Exporting Video Frames (1 every {anim_args.extract_nth_frame}) frames to {video_in_frame_path}...\n")
    sys.stdout.flush()
    """
    try:
        for f in pathlib.Path(video_in_frame_path).glob('*.jpg'):
            f.unlink()
    except:
        pass
    """
    vf = r'select=not(mod(n\,'+str(anim_args.extract_nth_frame)+'))'
    subprocess.run([
        'ffmpeg', '-i', f'{anim_args.video_init_path}', 
        '-vf', f'{vf}', '-vsync', 'vfr', '-q:v', '2', 
        '-loglevel', 'error', '-stats',  
        os.path.join(video_in_frame_path, '%04d.jpg')
    ], stdout=subprocess.PIPE).stdout.decode('utf-8')

    # determine max frames from length of input frames
    anim_args.max_frames = len([f for f in pathlib.Path(video_in_frame_path).glob('*.jpg')])

    args.use_init = True
    sys.stdout.write(f"Loading {anim_args.max_frames} input frames from {video_in_frame_path} and saving video frames to {args.outdir}\n")
    sys.stdout.flush()
    render_animation(args, anim_args)

def render_interpolation(args, anim_args):
    # animations use key framed prompts
    args.prompts = animation_prompts

    # create output folder for the batch
    os.makedirs(args.outdir, exist_ok=True)
    sys.stdout.write(f"Saving animation frames to {args.outdir}\n")
    sys.stdout.flush()

    """
    # save settings for the batch
    settings_filename = os.path.join(args.outdir, f"{args.timestring}_settings.txt")
    with open(settings_filename, "w+", encoding="utf-8") as f:
        s = {**dict(args.__dict__), **dict(anim_args.__dict__)}
        json.dump(s, f, ensure_ascii=False, indent=4)
    """
    
    # Interpolation Settings
    args.n_samples = 1
    args.seed_behavior = 'fixed' # force fix seed at the moment bc only 1 seed is available
    prompts_c_s = [] # cache all the text embeddings

    sys.stdout.write(f"Preparing for interpolation of the following...\n")
    sys.stdout.flush()

    for i, prompt in animation_prompts.items():

      sys.stdout.write(f"Creating interpolation keyframe {i}...\n")
      sys.stdout.write(f"No output image is shown for this frame\n")
      sys.stdout.flush()

      args.prompt = prompt

      # sample the diffusion model
      results = generate(args, return_c=True)
      c, image = results[0], results[1]
      prompts_c_s.append(c) 
      
      # display.clear_output(wait=True)
      #display.display(image)
      
      args.seed = next_seed(args)

    #display.clear_output(wait=True)
    sys.stdout.write(f"Interpolation start...\n")
    sys.stdout.flush()

    frame_idx = 0

    if anim_args.interpolate_key_frames:
      for i in range(len(prompts_c_s)-1):
        dist_frames = list(animation_prompts.items())[i+1][0] - list(animation_prompts.items())[i][0]
        if dist_frames <= 0:
          sys.stdout.write("key frames duplicated or reversed. interpolation skipped.\n")
          sys.stdout.flush()
          return
        else:
          for j in range(dist_frames):

            sys.stdout.write(f"Interpolating frame {j}...\n")
            sys.stdout.flush()

            # interpolate the text embedding
            prompt1_c = prompts_c_s[i]
            prompt2_c = prompts_c_s[i+1]  
            args.init_c = prompt1_c.add(prompt2_c.sub(prompt1_c).mul(j * 1/dist_frames))

            # sample the diffusion model
            results = generate(args)
            image = results[0]

            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()

            #filename = f"{args.timestring}_{index:05}_{args.seed}.png"
            filename = args2.image_file
            image.save(os.path.join(args.outdir, filename))

            #filename = f"{args.timestring}_{frame_idx:05}.png"
            filename = f"FRA{frame_idx+1:05}.png"
            #image.save(os.path.join(args.outdir, filename))
            image.save(os.path.join(args2.frame_dir, filename))
        
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()

            frame_idx += 1

            #display.clear_output(wait=True)
            #display.display(image)

            args.seed = next_seed(args)

    else:
      for i in range(len(prompts_c_s)-1):
        for j in range(anim_args.interpolate_x_frames+1):

          sys.stdout.write(f"Interpolating frame {j}...\n")
          sys.stdout.flush()

          # interpolate the text embedding
          prompt1_c = prompts_c_s[i]
          prompt2_c = prompts_c_s[i+1]  
          args.init_c = prompt1_c.add(prompt2_c.sub(prompt1_c).mul(j * 1/(anim_args.interpolate_x_frames+1)))

          # sample the diffusion model
          results = generate(args)
          image = results[0]

          sys.stdout.write('Saving progress ...\n')
          sys.stdout.flush()

          #filename = f"{args.timestring}_{index:05}_{args.seed}.png"
          filename = args2.image_file
          image.save(os.path.join(args.outdir, filename))

          #filename = f"{args.timestring}_{frame_idx:05}.png"
          filename = f"FRA{frame_idx+1:05}.png"
          #image.save(os.path.join(args.outdir, filename))
          image.save(os.path.join(args2.frame_dir, filename))
        
          sys.stdout.write('Progress saved\n')
          sys.stdout.flush()

          frame_idx += 1

          #display.clear_output(wait=True)
          #display.display(image)

          args.seed = next_seed(args)

    # generate the last prompt
    args.init_c = prompts_c_s[-1]
    results = generate(args)
    image = results[0]
    filename = f"{args.timestring}_{frame_idx:05}.png"
    image.save(os.path.join(args.outdir, filename))

    #display.clear_output(wait=True)
    #display.display(image)
    args.seed = next_seed(args)

    #clear init_c
    args.init_c = None


args = SimpleNamespace(**DeforumArgs())
anim_args = SimpleNamespace(**DeforumAnimArgs())

args.timestring = time.strftime('%Y%m%d%H%M%S')
args.strength = max(0.0, min(1.0, args.strength))

if args.seed == -1:
    args.seed = random.randint(0, 2**32)
if not args.use_init:
    args.init_image = None
if args.sampler == 'plms' and (args.use_init or anim_args.animation_mode != 'None'):
    sys.stdout.write(f"Init images aren't supported with PLMS yet, switching to KLMS\n")
    sys.stdout.flush()
    args.sampler = 'klms'
if args.sampler != 'ddim':
    args.ddim_eta = 0

if anim_args.animation_mode == 'None':
    anim_args.max_frames = 1
elif anim_args.animation_mode == 'Video Input':
    args.use_init = True

# dispatch to appropriate renderer
if anim_args.animation_mode == '2D' or anim_args.animation_mode == '3D':
    render_animation(args, anim_args)
elif anim_args.animation_mode == 'Video Input':
    render_input_video(args, anim_args)
elif anim_args.animation_mode == 'Interpolation':
    render_interpolation(args, anim_args)
else:
    render_image_batch(args)
