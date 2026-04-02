# pharmapsychotic_AnimationPreview.ipynb
# Original file is located at https://colab.research.google.com/github/pharmapsychotic/ai-notebooks/blob/main/pharmapsychotic_AnimationPreview.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

"""

#@title Check GPU
!nvidia-smi -L

#@title Install libraries
!git clone https://github.com/alembics/disco-diffusion.git
!git clone https://github.com/shariqfarooq123/AdaBins.git
!git clone https://github.com/isl-org/MiDaS.git
!git clone https://github.com/MSFTserver/pytorch3d-lite.git
!pip install timm tqdm
"""


import os
import shutil
import subprocess
import sys

sys.path.append('.\disco-diffusion-5-5')
sys.path.append('.\pytorch3d-lite')
sys.path.append('.\AdaBins')
sys.path.append('.\MiDaS')

model_path = '.'

"""
if not os.path.exists(os.path.join(model_path, 'model-small-70d6b9c8.pt')):
    wget("https://github.com/isl-org/MiDaS/releases/download/v2_1/model-small-70d6b9c8.pt", model_path)
"""

import cv2
import math
import numpy as np
import pandas as pd
import requests
import torch
from base64 import b64encode
from IPython import display
from ipywidgets import Output
from PIL import Image, ImageDraw, ImageOps
from torch import nn
from torch.nn import functional as F
#from tqdm import tqdm
import disco_xform_utils as dxf
import py3d_tools as p3dT
import torchvision.transforms as T
import torchvision.transforms.functional as TF


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

#@title Setup

def fetch(url_or_path):
    if str(url_or_path).startswith('http://') or str(url_or_path).startswith('https://'):
        r = requests.get(url_or_path)
        r.raise_for_status()
        fd = io.BytesIO()
        fd.write(r.content)
        fd.seek(0)
        return fd
    return open(url_or_path, 'rb')

def parse_key_frames(string, prompt_parser=None):
    """Given a string representing frame numbers paired with parameter values at that frame,
    return a dictionary with the frame numbers as keys and the parameter values as the values.

    Parameters
    ----------
    string: string
        Frame numbers paired with parameter values at that frame number, in the format
        'framenumber1: (parametervalues1), framenumber2: (parametervalues2), ...'
    prompt_parser: function or None, optional
        If provided, prompt_parser will be applied to each string of parameter values.
    
    Returns
    -------
    dict
        Frame numbers as keys, parameter values at that frame number as values

    Raises
    ------
    RuntimeError
        If the input string does not match the expected format.
    
    Examples
    --------
    >>> parse_key_frames("10:(Apple: 1| Orange: 0), 20: (Apple: 0| Orange: 1| Peach: 1)")
    {10: 'Apple: 1| Orange: 0', 20: 'Apple: 0| Orange: 1| Peach: 1'}

    >>> parse_key_frames("10:(Apple: 1| Orange: 0), 20: (Apple: 0| Orange: 1| Peach: 1)", prompt_parser=lambda x: x.lower()))
    {10: 'apple: 1| orange: 0', 20: 'apple: 0| orange: 1| peach: 1'}
    """
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

def get_inbetweens(key_frames, integer=False):
    """Given a dict with frame numbers as keys and a parameter value as values,
    return a pandas Series containing the value of the parameter at every frame from 0 to max_frames.
    Any values not provided in the input dict are calculated by linear interpolation between
    the values of the previous and next provided frames. If there is no previous provided frame, then
    the value is equal to the value of the next provided frame, or if there is no next provided frame,
    then the value is equal to the value of the previous provided frame. If no frames are provided,
    all frame values are NaN.

    Parameters
    ----------
    key_frames: dict
        A dict with integer frame numbers as keys and numerical values of a particular parameter as values.
    integer: Bool, optional
        If True, the values of the output series are converted to integers.
        Otherwise, the values are floats.
    
    Returns
    -------
    pd.Series
        A Series with length max_frames representing the parameter values for each frame.
    
    Examples
    --------
    >>> max_frames = 5
    >>> get_inbetweens({1: 5, 3: 6})
    0    5.0
    1    5.0
    2    5.5
    3    6.0
    4    6.0
    dtype: float64

    >>> get_inbetweens({1: 5, 3: 6}, integer=True)
    0    5
    1    5
    2    5
    3    6
    4    6
    dtype: int64
    """
    key_frame_series = pd.Series([np.nan for a in range(max_frames)])

    for i, value in key_frames.items():
        key_frame_series[i] = value
    key_frame_series = key_frame_series.astype(float)
    
    interp_method = interp_spline

    if interp_method == 'Cubic' and len(key_frames.items()) <=3:
      interp_method = 'Quadratic'
    
    if interp_method == 'Quadratic' and len(key_frames.items()) <= 2:
      interp_method = 'Linear'
      
    
    key_frame_series[0] = key_frame_series[key_frame_series.first_valid_index()]
    key_frame_series[max_frames-1] = key_frame_series[key_frame_series.last_valid_index()]
    # key_frame_series = key_frame_series.interpolate(method=intrp_method,order=1, limit_direction='both')
    key_frame_series = key_frame_series.interpolate(method=interp_method.lower(),limit_direction='both')
    if integer:
        return key_frame_series.astype(int)
    return key_frame_series

TRANSLATION_SCALE = 1.0/200.0

def do_3d_step(img_filepath, frame_num, midas_model, midas_transform):
    translation_x = translation_x_series[frame_num]
    translation_y = translation_y_series[frame_num]
    translation_z = translation_z_series[frame_num]
    rotation_3d_x = rotation_3d_x_series[frame_num]
    rotation_3d_y = rotation_3d_y_series[frame_num]
    rotation_3d_z = rotation_3d_z_series[frame_num]
    translate_xyz = [-translation_x*TRANSLATION_SCALE, translation_y*TRANSLATION_SCALE, -translation_z*TRANSLATION_SCALE]
    rotate_xyz_degrees = [rotation_3d_x, rotation_3d_y, rotation_3d_z]
    rotate_xyz = [math.radians(rotate_xyz_degrees[0]), math.radians(rotate_xyz_degrees[1]), math.radians(rotate_xyz_degrees[2])]
    rot_mat = p3dT.euler_angles_to_matrix(torch.tensor(rotate_xyz, device=device), "XYZ").unsqueeze(0)
    next_step_pil = transform_image_3d(img_filepath, midas_model, midas_transform, device,
                                            rot_mat, translate_xyz, near_plane, far_plane,
                                            fov, padding_mode=padding_mode,
                                            sampling_mode=sampling_mode, midas_weight=midas_weight)
    return next_step_pil


# Load MiDaS model
from midas.dpt_depth import DPTDepthModel
from midas.midas_net import MidasNet
from midas.midas_net_custom import MidasNet_small
from midas.transforms import Resize, NormalizeImage, PrepareForNet

# Initialize MiDaS depth model.
# It remains resident in VRAM and likely takes around 2GB VRAM.
# You could instead initialize it for each frame (and free it after each frame) to save VRAM.. but initializing it is slow.
default_models = {
    "midas_v21_small": f"{model_path}/model-small-70d6b9c8.pt",
    #"midas_v21": f"{model_path}/midas_v21-f6b98070.pt",
    "dpt_large": f"{model_path}/dpt_large-midas-2f21e586.pt",
    #"dpt_hybrid": f"{model_path}/dpt_hybrid-midas-501f0c75.pt",
    #"dpt_hybrid_nyu": f"{model_path}/dpt_hybrid_nyu-2ce69ec7.pt",
}

def init_midas_depth_model(midas_model_type="dpt_large", optimize=True):
    midas_model = None
    net_w = None
    net_h = None
    resize_mode = None
    normalization = None

    print(f"Initializing MiDaS '{midas_model_type}' depth model...")
    # load network
    midas_model_path = default_models[midas_model_type]

    if midas_model_type == "dpt_large": # DPT-Large
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitl16_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode = "minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "dpt_hybrid": #DPT-Hybrid
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitb_rn50_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode="minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "dpt_hybrid_nyu": #DPT-Hybrid-NYU
        midas_model = DPTDepthModel(
            path=midas_model_path,
            backbone="vitb_rn50_384",
            non_negative=True,
        )
        net_w, net_h = 384, 384
        resize_mode="minimal"
        normalization = NormalizeImage(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    elif midas_model_type == "midas_v21":
        midas_model = MidasNet(midas_model_path, non_negative=True)
        net_w, net_h = 384, 384
        resize_mode="upper_bound"
        normalization = NormalizeImage(
            mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        )
    elif midas_model_type == "midas_v21_small":
        midas_model = MidasNet_small(midas_model_path, features=64, backbone="efficientnet_lite3", exportable=True, non_negative=True, blocks={'expand': True})
        net_w, net_h = 256, 256
        resize_mode="upper_bound"
        normalization = NormalizeImage(
            mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        )
    else:
        print(f"midas_model_type '{midas_model_type}' not implemented")
        assert False

    midas_transform = T.Compose(
        [
            Resize(
                net_w,
                net_h,
                resize_target=None,
                keep_aspect_ratio=True,
                ensure_multiple_of=32,
                resize_method=resize_mode,
                image_interpolation_method=cv2.INTER_CUBIC,
            ),
            normalization,
            PrepareForNet(),
        ]
    )

    midas_model.eval()
    
    if optimize==True:
        if device == torch.device("cuda"):
            midas_model = midas_model.to(memory_format=torch.channels_last)  
            midas_model = midas_model.half()

    midas_model.to(device)

    print(f"MiDaS '{midas_model_type}' depth model initialized.")
    return midas_model, midas_transform, net_w, net_h, resize_mode, normalization


# ======== modified disco_xform_utils ========
import torch, torchvision
import py3d_tools as p3d
import midas_utils
from PIL import Image
import numpy as np
import sys, math

try:
    from infer import InferenceHelper
except:
    print("disco_xform_utils.py failed to import InferenceHelper. Please ensure that AdaBins directory is in the path (i.e. via sys.path.append('./AdaBins') or other means).")
    sys.exit()

MAX_ADABINS_AREA = 500000
MIN_ADABINS_AREA = 448*448

@torch.no_grad()
def transform_image_3d(img_filepath, midas_model, midas_transform, device, rot_mat=torch.eye(3).unsqueeze(0), translate=(0.,0.,-0.04), near=2000, far=20000, fov_deg=60, padding_mode='border', sampling_mode='bicubic', midas_weight = 0.3,spherical=False):
    img_pil = Image.open(open(img_filepath, 'rb')).convert('RGB')
    w, h = img_pil.size
    image_tensor = torchvision.transforms.functional.to_tensor(img_pil).to(device)

    use_adabins = midas_weight < 1.0 and use_depth_warping

    if use_adabins:
        # AdaBins
        """
        predictions using nyu dataset
        """
        #print("Running AdaBins depth estimation implementation...")
        infer_helper = InferenceHelper(dataset='nyu', device=device)

        image_pil_area = w*h
        if image_pil_area > MAX_ADABINS_AREA:
            scale = math.sqrt(MAX_ADABINS_AREA) / math.sqrt(image_pil_area)
            depth_input = img_pil.resize((int(w*scale), int(h*scale)), Image.LANCZOS) # LANCZOS is supposed to be good for downsampling.
        elif image_pil_area < MIN_ADABINS_AREA:
            scale = math.sqrt(MIN_ADABINS_AREA) / math.sqrt(image_pil_area)
            depth_input = img_pil.resize((int(w*scale), int(h*scale)), Image.BICUBIC)
        else:
            depth_input = img_pil
        try:
            _, adabins_depth = infer_helper.predict_pil(depth_input)
            if image_pil_area != MAX_ADABINS_AREA:
                adabins_depth = torchvision.transforms.functional.resize(torch.from_numpy(adabins_depth), image_tensor.shape[-2:], interpolation=torchvision.transforms.functional.InterpolationMode.BICUBIC).squeeze().to(device)
            else:
                adabins_depth = torch.from_numpy(adabins_depth).squeeze().to(device)
            adabins_depth_np = adabins_depth.cpu().numpy()
        except:
            pass

    torch.cuda.empty_cache()

    # MiDaS

    # MiDaS depth estimation implementation
    img_midas = midas_utils.read_image(img_filepath)
    if midas_model and use_depth_warping:
        img_midas_input = midas_transform({"image": img_midas})["image"]
        midas_optimize = True

        #print("Running MiDaS depth estimation implementation...")
        sample = torch.from_numpy(img_midas_input).float().to(device).unsqueeze(0)
        if midas_optimize==True and device == torch.device("cuda"):
            sample = sample.to(memory_format=torch.channels_last)  
            sample = sample.half()
        prediction_torch = midas_model.forward(sample)
    else:
        prediction_torch = torch.zeros((1, h, w), device=device) 
    prediction_torch = torch.nn.functional.interpolate(
            prediction_torch.unsqueeze(1),
            size=img_midas.shape[:2],
            mode="bicubic",
            align_corners=False,
        ).squeeze()
    prediction_np = prediction_torch.clone().cpu().numpy()

    #print("Finished depth estimation.")
    torch.cuda.empty_cache()

    # MiDaS makes the near values greater, and the far values lesser. Let's reverse that and try to align with AdaBins a bit better.
    prediction_np = np.subtract(50.0, prediction_np)
    prediction_np = prediction_np / 19.0

    if use_adabins:
        adabins_weight = 1.0 - midas_weight
        depth_map = prediction_np*midas_weight + adabins_depth_np*adabins_weight
    else:
        depth_map = prediction_np

    depth_map = np.expand_dims(depth_map, axis=0)
    depth_tensor = torch.from_numpy(depth_map).squeeze().to(device)

    pixel_aspect = 1.0 # really.. the aspect of an individual pixel! (so usually 1.0)
    persp_cam_old = p3d.FoVPerspectiveCameras(near, far, pixel_aspect, fov=fov_deg, degrees=True, device=device)
    persp_cam_new = p3d.FoVPerspectiveCameras(near, far, pixel_aspect, fov=fov_deg, degrees=True, R=rot_mat, T=torch.tensor([translate]), device=device)

    # range of [-1,1] is important to torch grid_sample's padding handling
    y,x = torch.meshgrid(torch.linspace(-1.,1.,h,dtype=torch.float32,device=device),torch.linspace(-1.,1.,w,dtype=torch.float32,device=device))
    z = torch.as_tensor(depth_tensor, dtype=torch.float32, device=device)
    xyz_old_world = torch.stack((x.flatten(), y.flatten(), z.flatten()), dim=1)

    # Transform the points using pytorch3d. With current functionality, this is overkill and prevents it from working on Windows.
    # If you want it to run on Windows (without pytorch3d), then the transforms (and/or perspective if that's separate) can be done pretty easily without it.
    xyz_old_cam_xy = persp_cam_old.get_full_projection_transform().transform_points(xyz_old_world)[:,0:2]
    xyz_new_cam_xy = persp_cam_new.get_full_projection_transform().transform_points(xyz_old_world)[:,0:2]

    offset_xy = xyz_new_cam_xy - xyz_old_cam_xy
    # affine_grid theta param expects a batch of 2D mats. Each is 2x3 to do rotation+translation.
    identity_2d_batch = torch.tensor([[1.,0.,0.],[0.,1.,0.]], device=device).unsqueeze(0)
    # coords_2d will have shape (N,H,W,2).. which is also what grid_sample needs.
    coords_2d = torch.nn.functional.affine_grid(identity_2d_batch, [1,1,h,w], align_corners=False)
    offset_coords_2d = coords_2d - torch.reshape(offset_xy, (h,w,2)).unsqueeze(0)

    if spherical:
        spherical_grid = get_spherical_projection(h, w, torch.tensor([0,0], device=device), -0.4,device=device)#align_corners=False
        stage_image = torch.nn.functional.grid_sample(image_tensor.add(1/512 - 0.0001).unsqueeze(0), offset_coords_2d, mode=sampling_mode, padding_mode=padding_mode, align_corners=True)
        new_image = torch.nn.functional.grid_sample(stage_image, spherical_grid,align_corners=True) #, mode=sampling_mode, padding_mode=padding_mode, align_corners=False)
    else:
        new_image = torch.nn.functional.grid_sample(image_tensor.add(1/512 - 0.0001).unsqueeze(0), offset_coords_2d, mode=sampling_mode, padding_mode=padding_mode, align_corners=False)

    img_pil = torchvision.transforms.ToPILImage()(new_image.squeeze().clamp(0,1.))

    torch.cuda.empty_cache()

    return img_pil

def get_spherical_projection(H, W, center, magnitude,device):  
    xx, yy = torch.linspace(-1, 1, W,dtype=torch.float32,device=device), torch.linspace(-1, 1, H,dtype=torch.float32,device=device)  
    gridy, gridx  = torch.meshgrid(yy, xx)
    grid = torch.stack([gridx, gridy], dim=-1)  
    d = center - grid
    d_sum = torch.sqrt((d**2).sum(axis=-1))
    grid += d * d_sum.unsqueeze(-1) * magnitude 
    return grid.unsqueeze(0)


# ======== preview rendering ========

def splat_rect(img, scale):
    img1 = ImageDraw.Draw(img, "RGBA")
    img1.rectangle([(0,0),(img.width,img.height)], fill=(0,0,0,32))
    rw = img.width * scale
    rh = img.height * scale
    x, y = (img.width-rw)/2, (img.height-rh)/2
    shape = [(x, y), (x+rw, y+rh)]
    img1.rectangle(shape, outline="white", width=2)

def do_it():
    if (animation_mode == "3D") and use_depth_warping:
        midas_model, midas_transform, midas_net_w, midas_net_h, midas_resize_mode, midas_normalization = init_midas_depth_model(midas_depth_model)
    else:
        midas_model = None
        midas_transform = None

    #for frame_num in tqdm(range(0, max_frames)):
    for frame_num in range(max_frames):

        sys.stdout.write(f"Rendering frame {frame_num+1} of {max_frames}\n")
        sys.stdout.flush()


        frame_filename = f'frame_{frame_num:04d}.png'
        if use_depth_warping:
            display.clear_output(wait=True)
            print(f"Rendering frame {frame_num+1} of {max_frames}")

        init_image = None
        if animation_mode == "2D":
            angle = angle_series[frame_num]
            zoom = zoom_series[frame_num]
            translation_x = translation_x_series[frame_num]
            translation_y = translation_y_series[frame_num]
            if frame_num > 0:
                img_0 = cv2.imread('prevFrame.png')
                center = (1*img_0.shape[1]//2, 1*img_0.shape[0]//2)
                trans_mat = np.float32([[1, 0, translation_x], [0, 1, translation_y]])
                rot_mat = cv2.getRotationMatrix2D( center, angle, zoom )
                trans_mat = np.vstack([trans_mat, [0,0,1]])
                rot_mat = np.vstack([rot_mat, [0,0,1]])
                transformation_matrix = np.matmul(rot_mat, trans_mat)
                img_0 = cv2.warpPerspective(
                    img_0,
                    transformation_matrix,
                    (img_0.shape[1], img_0.shape[0]),
                    borderMode=cv2.BORDER_WRAP
                )
                cv2.imwrite('prevFrameScaled.png', img_0)
                init_image = 'prevFrameScaled.png'
        elif animation_mode == "3D":
            if frame_num > 0:
                img_filepath = 'prevFrame.png'
                next_step_pil = do_3d_step(img_filepath, frame_num, midas_model, midas_transform)
                next_step_pil.save('prevFrameScaled.png')

                ### Turbo mode - skip some diffusions, use 3d morph for clarity and to save time
                if turbo_mode:
                    if frame_num == turbo_preroll: #start tracking oldframe
                        next_step_pil.save('oldFrameScaled.png')#stash for later blending          
                    elif frame_num > turbo_preroll:
                        #set up 2 warped image sequences, old & new, to blend toward new diff image
                        old_frame = do_3d_step('oldFrameScaled.png', frame_num, midas_model, midas_transform)
                        old_frame.save('oldFrameScaled.png')
                        if frame_num % int(turbo_steps) != 0: 
                            print('turbo skip this frame: skipping clip diffusion steps')
                            #filename = f'{args.batch_name}({args.batchNum})_{frame_num:04}.png'
                            blend_factor = ((frame_num % int(turbo_steps))+1)/int(turbo_steps)
                            print('turbo skip this frame: skipping clip diffusion steps and saving blended frame')
                            newWarpedImg = cv2.imread('prevFrameScaled.png')#this is already updated..
                            oldWarpedImg = cv2.imread('oldFrameScaled.png')
                            blendedImage = cv2.addWeighted(newWarpedImg, blend_factor, oldWarpedImg,1-blend_factor, 0.0)
                            cv2.imwrite(frame_filename, blendedImage)
                            next_step_pil.save(f'{img_filepath}') # save it also as prev_frame to feed next iteration
                            continue
                        else:
                            #if not a skip frame, will run diffusion and need to blend.
                            oldWarpedImg = cv2.imread('prevFrameScaled.png')
                            cv2.imwrite(f'oldFrameScaled.png', oldWarpedImg)#swap in for blending later 
                            print('clip/diff this frame - generate clip diff image')

                init_image = 'prevFrameScaled.png'

        init = Image.open(fetch(init_image)).convert('RGB') if init_image else Image.new("RGB", (width_height[0], width_height[1]))
        image = init

        if frame_num % 5 == 0:
            splat_rect(image, 0.25)

        image.save('prevFrame.png')
        if animation_mode == "2D":
            image.save(frame_filename)
        elif animation_mode == "3D":
            if turbo_mode and frame_num > 0:
                # Mix new image with prevFrameScaled
                blend_factor = (1)/int(turbo_steps)
                newFrame = cv2.imread('prevFrame.png')
                prev_frame_warped = cv2.imread('prevFrameScaled.png')
                blendedImage = cv2.addWeighted(newFrame, blend_factor, prev_frame_warped, (1-blend_factor), 0.0)
                cv2.imwrite(frame_filename, blendedImage)
            else:
                image.save(frame_filename)

    #display.clear_output(wait=True)
    sys.stdout.write("Building video from frames ...\n")
    sys.stdout.flush()
    #print("Creating preview video...")

    # make video
    FPS = 24
    cmd = [
        'ffmpeg',
        '-y',
        '-vcodec', 'png',
        '-r', str(video_fps),
        '-start_number', str(0),
        '-i', f'frame_%04d.png',
        '-frames:v', str(max_frames),
        '-c:v', 'libx264',
        '-vf',
        f'fps={video_fps}',
        '-pix_fmt', 'yuv420p',
        '-crf', '17',
        '-preset', 'veryfast',
        'anim_preview.mp4'
    ]
    # process = subprocess.Popen(cmd, cwd=f'{self.path}', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(stderr)
        raise RuntimeError(stderr)

    # delete the frame images
    for frame_num in range(0, max_frames):
        frame_filename = f'frame_{frame_num:04d}.png'
        os.remove(frame_filename)

    #display.clear_output(wait=True)

"""# Animation preview rendering"""

#@title Animation preview
width_height = [640, 480] #@param{type: 'raw'}
video_fps = 24 #@param {type:"number"}

#@markdown

interp_spline = 'Linear' #Do not change, currently will not look good. param ['Linear','Quadratic','Cubic']{type:"string"}

"""
animation_mode = '2D' #@param ['None', '2D', '3D', 'Video Input'] {type:'string'}
max_frames = 100#@param {type:"number"}
angle = "0:(0.000),30:(0.948),49:(-1.797),62:(-0.801),80:(1.952)"#@param {type:"string"}
zoom = "0:(1.05)"#@param {type:"string"}
translation_x = "0:(0.000),15:(4.148),30:(2.315),36:(-4.501),49:(-6.272),65:(-0.722),78:(-7.293),88:(-3.560),99:(5.817)"#@param {type:"string"}
translation_y = "0:(0.000),6:(6.323),16:(-5.121),27:(6.417),37:(-7.177),53:(-0.339),62:(6.475),77:(-0.370),91:(0.269)"#@param {type:"string"}
translation_z = "0:(0)"#@param {type:"string"}
rotation_3d_x = "0:(0)"#@param {type:"string"}
rotation_3d_y = "0:(0)"#@param {type:"string"}
rotation_3d_z = "0:(0)"#@param {type:"string"}
cam_code = ""#@param {type:"string"}
use_depth_warping = False #@param {type:"boolean"}
midas_depth_model = "midas_v21_small" #@param ['midas_v21_small', 'midas_v21', 'dpt_large', 'dpt_hybrid', 'dpt_hybrid_nyu']
midas_weight = 0.3#@param {type:"number"}
near_plane = 200#@param {type:"number"}
far_plane = 10000#@param {type:"number"}
fov = 40#@param {type:"number"}
padding_mode = 'border'#@param {type:"string"}
sampling_mode = 'bicubic'#@param {type:"string"}
turbo_mode = False #@param {type:"boolean"}
turbo_steps = "3" #@param ["2","3","4","5","6"] {type:"string"}
"""

#VOC START - DO NOT DELETE
animation_mode = '3D'
max_frames = 900
angle = "0:(0)"
zoom = "0:(1.04)"
translation_x = "0:(0),30:(0.815),60:(-0.553),90:(0.257),120:(-0.867),150:(0.017),180:(-0.443),210:(0.094),240:(-0.567),270:(-0.789),300:(0.335),330:(-0.306),360:(-0.993),390:(0.608),420:(-0.743),450:(-0.018),480:(-0.132),510:(0.295),540:(-0.383),570:(-0.179),600:(0.263),630:(0.621),660:(-0.369),690:(0.206),720:(-0.925),750:(-0.480),780:(0.455),810:(0.182),840:(-0.945),870:(-0.615),900:(0.346)"
translation_y = "0:(0),30:(0.630),60:(-0.138),90:(-0.475),120:(0.399),150:(0.733),180:(-0.937),210:(0.785),240:(-0.260),270:(0.274),300:(-0.689),330:(0.491),360:(-0.883),390:(0.632),420:(-0.187),450:(-0.107),480:(0.057),510:(-0.299),540:(0.151),570:(-0.477),600:(0.845),630:(-0.759),660:(0.251),690:(0.307),720:(-0.013),750:(0.182),780:(-0.440),810:(0.515),840:(-0.768),870:(0.932),900:(-0.601)"
translation_z = "0:(0),30:(-0.685),60:(-0.340),90:(-0.422),120:(0.357),150:(-0.887),180:(-0.956),210:(0.256),240:(-0.738),270:(-0.337),300:(0.020),330:(-0.581),360:(0.433),390:(0.588),420:(-0.057),450:(-0.730),480:(0.304),510:(0.743),540:(-0.057),570:(0.394),600:(-0.773),630:(0.587),660:(-0.558),690:(0.524),720:(0.433),750:(-0.763),780:(-0.283),810:(0.301),840:(0.218),870:(-0.027),900:(0.338)"
rotation_3d_x = "0:(0),30:(-0.021),60:(0.129),90:(-0.678),120:(-0.393),150:(-0.318),180:(0.027),210:(-0.063),240:(-0.972),270:(-0.232),300:(0.746),330:(-0.066),360:(0.544),390:(0.919),420:(0.776),450:(-0.696),480:(0.986),510:(-0.598),540:(-0.304),570:(0.464),600:(0.879),630:(0.259),660:(-0.934),690:(0.502),720:(0.393),750:(-0.687),780:(0.229),810:(-0.987),840:(0.976),870:(0.792),900:(-0.058)"
rotation_3d_y = "0:(0),30:(0.246),60:(0.301),90:(-0.547),120:(-0.498),150:(-0.185),180:(0.151),210:(-0.132),240:(0.934),270:(-0.164),300:(0.786),330:(0.156),360:(-0.555),390:(-0.678),420:(-0.291),450:(0.629),480:(-0.537),510:(0.901),540:(-0.233),570:(-0.297),600:(-0.082),630:(0.194),660:(-0.507),690:(0.684),720:(0.535),750:(0.179),780:(-0.237),810:(-0.706),840:(0.572),870:(-0.386),900:(-0.746)"
rotation_3d_z = "0:(0),30:(0.405),60:(-0.426),90:(0.406),120:(-0.843),150:(-0.436),180:(0.723),210:(0.385),240:(-0.259),270:(0.394),300:(-0.607),330:(0.472),360:(-0.106),390:(0.967),420:(-0.920),450:(0.312),480:(-0.624),510:(0.723),540:(0.554),570:(0.776),600:(-0.958),630:(0.015),660:(-0.243),690:(0.037),720:(-0.869),750:(0.711),780:(-0.685),810:(-0.451),840:(0.755),870:(0.730),900:(-0.968)"
cam_code = ""
use_depth_warping = False
midas_depth_model = "dpt_large"
midas_weight = 0.3
near_plane = 200
far_plane = 10000
fov = 40
near_plane = 200
padding_mode = 'border'
sampling_mode = 'bicubic'
cam_code = ""
turbo_mode = False
#VOC FINISH - DO NOT DELETE



turbo_preroll = 10 # frames
if turbo_mode and animation_mode != '3D':
    print('=====')
    print('Turbo mode only available with 3D animations. Disabling Turbo.')
    print('=====')
    turbo_mode = False

if len(cam_code):
    exec(cam_code)


try:
    angle_series = get_inbetweens(parse_key_frames(angle))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `angle` correctly for key frames.\n"
        "Attempting to interpret `angle` as "
        f'"0: ({angle})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    angle = f"0: ({angle})"
    angle_series = get_inbetweens(parse_key_frames(angle))

try:
    zoom_series = get_inbetweens(parse_key_frames(zoom))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `zoom` correctly for key frames.\n"
        "Attempting to interpret `zoom` as "
        f'"0: ({zoom})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    zoom = f"0: ({zoom})"
    zoom_series = get_inbetweens(parse_key_frames(zoom))

try:
    translation_x_series = get_inbetweens(parse_key_frames(translation_x))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `translation_x` correctly for key frames.\n"
        "Attempting to interpret `translation_x` as "
        f'"0: ({translation_x})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    translation_x = f"0: ({translation_x})"
    translation_x_series = get_inbetweens(parse_key_frames(translation_x))

try:
    translation_y_series = get_inbetweens(parse_key_frames(translation_y))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `translation_y` correctly for key frames.\n"
        "Attempting to interpret `translation_y` as "
        f'"0: ({translation_y})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    translation_y = f"0: ({translation_y})"
    translation_y_series = get_inbetweens(parse_key_frames(translation_y))

try:
    translation_z_series = get_inbetweens(parse_key_frames(translation_z))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `translation_z` correctly for key frames.\n"
        "Attempting to interpret `translation_z` as "
        f'"0: ({translation_z})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    translation_z = f"0: ({translation_z})"
    translation_z_series = get_inbetweens(parse_key_frames(translation_z))

try:
    rotation_3d_x_series = get_inbetweens(parse_key_frames(rotation_3d_x))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `rotation_3d_x` correctly for key frames.\n"
        "Attempting to interpret `rotation_3d_x` as "
        f'"0: ({rotation_3d_x})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    rotation_3d_x = f"0: ({rotation_3d_x})"
    rotation_3d_x_series = get_inbetweens(parse_key_frames(rotation_3d_x))

try:
    rotation_3d_y_series = get_inbetweens(parse_key_frames(rotation_3d_y))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `rotation_3d_y` correctly for key frames.\n"
        "Attempting to interpret `rotation_3d_y` as "
        f'"0: ({rotation_3d_y})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    rotation_3d_y = f"0: ({rotation_3d_y})"
    rotation_3d_y_series = get_inbetweens(parse_key_frames(rotation_3d_y))

try:
    rotation_3d_z_series = get_inbetweens(parse_key_frames(rotation_3d_z))
except RuntimeError as e:
    print(
        "WARNING: You have selected to use key frames, but you have not "
        "formatted `rotation_3d_z` correctly for key frames.\n"
        "Attempting to interpret `rotation_3d_z` as "
        f'"0: ({rotation_3d_z})"\n'
        "Please read the instructions to find out how to use key frames "
        "correctly.\n"
    )
    rotation_3d_z = f"0: ({rotation_3d_z})"
    rotation_3d_z_series = get_inbetweens(parse_key_frames(rotation_3d_z))    


do_it()

#mp4 = open('anim_preview.mp4','rb').read()
#data_url = "data:video/mp4;base64," + b64encode(mp4).decode()
#display.display( display.HTML(f'<video controls loop><source src="{data_url}" type="video/mp4"></video>') )

"""<hr>

# Animation Generators

# Random keys
"""

#@markdown ---
#@markdown Generate a random series of key frames<br>
#@markdown Every `frame_delta` frames a random value between `min_value` and `max_value` is used.<br>
#@markdown You can paste the resulting string into any of the camera attributes above
max_frames = 100 #@param {type:"integer"}
frame_delta = 24 #@param {type:"integer"}
frame_delta_variance = 0.5 #@param {type:"number"}
min_value = -2 #@param {type:"number"}
max_value = 2 #@param {type:"number"}

import math
import random

def make_key_frames(frame_delta, value_min, value_max, frame_delta_var=0.5):
    frame = 0
    value = 0
    key_str = ""
    while frame < max_frames:
        key_str += f"{frame}:({value:0.3f}),"
        frame += int(frame_delta + frame_delta_var * (random.random()*2.0-1.0) * frame_delta)
        value = value_min + (value_max - value_min) * random.random()
    key_str = key_str[0:-1] # remove trailing ,
    return key_str

#print(make_key_frames(frame_delta, min_value, max_value, frame_delta_var=frame_delta_variance))

"""# [Wiggle 5.1](https://colab.research.google.com/github/zippy731/wiggle/blob/main/Wiggle_Standalone_5_1.ipynb) by [zippy731](https://twitter.com/zippy731)"""

#======= WIGGLE MODE
#@markdown ---
#@markdown ####**Wiggle:**
#@markdown Generates semirandom keyframes for zoom / spin / translation. 
#@markdown Set ranges below, then run this cell.
#@markdown

#.. can be embedded directly into DD5 notebook.  Copy this code into 
#animation settings tab, just before 'Coherency Settings'
#Then comment out standalone-only code and uncomment 'embedded-only' section.

#standalone-only:
import random
wiggle_frames = 2000#@param {type:"number"}
max_frames = wiggle_frames
#end standalone-only

#embedded-only:
use_wiggle = True #@param {type:"boolean"} 
#wiggle_show_params = True #@param {type:"boolean"} 
#end embedded-only code

#@markdown Wiggle preroll and episodes (frames) and duration variability:
preroll_frames = 12#@param {type:"integer"}
episode_duration = 32#@param {type:"integer"}
wig_time_var = 0.20#@param {type:"number"}
#@markdown Wiggle time phase shares (3 values, sum to 1.0):
wig_ads_input = '0.20,0.40,0.40'#@param {type:"string"}
wig_adsmix = [float(x) for x in wig_ads_input.split(',')]
#@markdown Zoom (2D) and trz (3D) ranges and quiet factor
wig_zoom_min_max = '0.12,0.18'#@param {type:"string"}
wig_zoom_range= [float(x) for x in wig_zoom_min_max.split(',')]
wig_trz_min_max = '8,15'#@param {type:"string"}
wig_trz_range = [int(x) for x in wig_trz_min_max.split(',')]
wig_zoom_quiet_factor = 0.75 #@param {type:"number"}# wig_zoom_quiet_scale_factor//scale of zoom quiet periods, as function of above range
#@markdown angle (2D) trx,try(2D/3D) and rotx,roty,rotz (3D) ranges and quiet factor

wig_angle_min_max = '-3,3'#@param {type:"string"}
wig_angle_range= [float(x) for x in wig_angle_min_max.split(',')]
wig_trx_min_max = '-6,6'#@param {type:"string"}
wig_trx_range= [float(x) for x in wig_trx_min_max.split(',')]
wig_try_min_max = '-3,3'#@param {type:"string"}
wig_try_range= [float(x) for x in wig_try_min_max.split(',')]

wig_rotx_min_max = '-3,3'#@param {type:"string"}
wig_rotx_range= [float(x) for x in wig_rotx_min_max.split(',')]
wig_roty_min_max = '-4,4'#@param {type:"string"}
wig_roty_range= [float(x) for x in wig_roty_min_max.split(',')]
wig_rotz_min_max = '-3,3'#@param {type:"string"}
wig_rotz_range= [float(x) for x in wig_rotz_min_max.split(',')]
wig_motion_quiet_factor=0.2 #@param {type:"number"}
#@markdown GLIDE MODE: tr_x and tr_y yoked to rot_z and rot_x, respectively.
#@markdown *ADDS* to tr_x and tr_y values set above.
# ht @BrokenMindset!
##wig_glide_mode = True #@param {type:"boolean"} 
wig_glide_x_factor = 0.25 #@param {type:"number"}
wig_glide_y_factor = 0.25 #@param {type:"number"}




if use_wiggle:
    #calculate wiggle keyframes, inject into diffusion notebook  

    #calc time ranges   
    episode_count = round((max_frames)/(episode_duration*.8),0)
    wig_attack_range=(round(episode_duration*wig_adsmix[0]*(1-wig_time_var),0),round(episode_duration*wig_adsmix[0]*(1+wig_time_var),0))
    wig_decay_range=(round(episode_duration*wig_adsmix[1]*(1-wig_time_var),0),round(episode_duration*wig_adsmix[1]*(1+wig_time_var),0))
    wig_sustain_range=(round(episode_duration*wig_adsmix[2]*(1-wig_time_var),0),round(episode_duration*wig_adsmix[2]*(1+wig_time_var),0))
    #------------

    episodes = [(0,1.0,0,0,0,0,0,0,0)] #initialize episodes list
    #ep is: (frame,zoom,angle,trx,try,trz,rotx,roty,rotz)
    episode_starts = [0]
    episode_peaks = [0]
    i = 1
    skip_1 = 0
    wig_frame_count = round(preroll_frames,0)
    while i < episode_count:
      #attack: quick ramp to motion
      if wig_time_var == 0:
        skip_1 = wig_attack_range[0]
      else:
        skip_1 = round(random.randrange(wig_attack_range[0],wig_attack_range[1]),0)
      wig_frame_count += int(skip_1)
      zoom_1 = 1+round(random.uniform(wig_zoom_range[0],wig_zoom_range[1]),3)
      trz_1 = round(random.uniform(wig_trz_range[0],wig_trz_range[1]),3)
      angle_1 = round(random.uniform(wig_angle_range[0],wig_angle_range[1]),3)
      rotx_1 = round(random.uniform(wig_rotx_range[0],wig_rotx_range[1]),3) 
      roty_1 = round(random.uniform(wig_roty_range[0],wig_roty_range[1]),3) 
      rotz_1 = round(random.uniform(wig_rotz_range[0],wig_rotz_range[1]),3) 
      trx_1 = round(random.uniform(wig_trx_range[0],wig_trx_range[1]),3)+round((rotz_1*wig_glide_x_factor),3)
      try_1 = round(random.uniform(wig_try_range[0],wig_try_range[1]),3)+round((rotx_1*wig_glide_y_factor),3)


      episodes.append((wig_frame_count,zoom_1,angle_1,trx_1,try_1,trz_1,rotx_1,roty_1,rotz_1))
      episode_starts.append((wig_frame_count))
      #decay: ramp down to element of interest
      if wig_time_var == 0:
        skip_1 = wig_decay_range[0]
      else:
        skip_1 = round(random.randrange(wig_decay_range[0],wig_decay_range[1]),0)
      wig_frame_count += int(skip_1)
      zoom_1 = 1+(round(wig_zoom_quiet_factor*random.uniform(wig_zoom_range[0],wig_zoom_range[1]),3))
      trz_1 = round(wig_zoom_quiet_factor*random.uniform(wig_trz_range[0],wig_trz_range[1]),3)
      angle_1 = round(wig_motion_quiet_factor*random.uniform(wig_angle_range[0],wig_angle_range[1]),3)
      rotx_1 = round(wig_motion_quiet_factor*random.uniform(wig_rotx_range[0],wig_rotx_range[1]),3)
      roty_1 = round(wig_motion_quiet_factor*random.uniform(wig_roty_range[0],wig_roty_range[1]),3)
      rotz_1 = round(wig_motion_quiet_factor*random.uniform(wig_rotz_range[0],wig_rotz_range[1]),3)
      trx_1 = round(wig_motion_quiet_factor*random.uniform(wig_trx_range[0],wig_trx_range[1]),3)+round((rotz_1*wig_glide_x_factor),3)
      try_1 = round(wig_motion_quiet_factor*random.uniform(wig_try_range[0],wig_try_range[1]),3)+round((rotx_1*wig_glide_y_factor),3)
      episodes.append((wig_frame_count,zoom_1,angle_1,trx_1,try_1,trz_1,rotx_1,roty_1,rotz_1))
      episode_peaks.append((wig_frame_count))
      #sustain: pause during element of interest
      if wig_time_var == 0:
        skip_1 = wig_sustain_range[0]
      else:
        skip_1 = round(random.randrange(wig_sustain_range[0],wig_sustain_range[1]),0)
      wig_frame_count += int(skip_1)
      zoom_1 = 1+(round(wig_zoom_quiet_factor*random.uniform(wig_zoom_range[0],wig_zoom_range[1]),3))
      trz_1 = round(wig_zoom_quiet_factor*random.uniform(wig_trz_range[0],wig_trz_range[1]),3)     
      angle_1 = round(wig_motion_quiet_factor*random.uniform(wig_angle_range[0],wig_angle_range[1]),3)
      rotx_1 = round(wig_motion_quiet_factor*random.uniform(wig_rotx_range[0],wig_rotx_range[1]),3)
      roty_1 = round(wig_motion_quiet_factor*random.uniform(wig_roty_range[0],wig_roty_range[1]),3)
      rotz_1 = round(wig_motion_quiet_factor*random.uniform(wig_rotz_range[0],wig_rotz_range[1]),3)
      trx_1 = round(wig_motion_quiet_factor*random.uniform(wig_trx_range[0],wig_trx_range[1]),3)+round((rotz_1*wig_glide_x_factor),3)
      try_1 = round(wig_motion_quiet_factor*random.uniform(wig_try_range[0],wig_try_range[1]),3)+round((rotx_1*wig_glide_y_factor),3)
      episodes.append((wig_frame_count,zoom_1,angle_1,trx_1,try_1,trz_1,rotx_1,roty_1,rotz_1))
      i+=1
    #trim off any episode > max_frames
    cleaned_episodes = [i for i in episodes if i[0] < max_frames]
    episodes = cleaned_episodes
    cleaned_episode_starts = [i for i in episode_starts if i < max_frames]
    episode_starts = cleaned_episode_starts
    cleaned_episode_peaks = [i for i in episode_peaks if i < max_frames]
    episode_peaks = cleaned_episode_peaks

    #build full schedule
    keyframe_frames = [item[0] for item in episodes]

    #Build keyframe strings 
    wig_zoom_string=''
    wig_angle_string=''
    wig_trx_string=''
    wig_try_string=''
    wig_trz_string=''
    wig_rotx_string=''
    wig_roty_string=''
    wig_rotz_string=''
    # iterate thru episodes, generate keyframe strings
    ### reformat as keyframe strings for testing
    i = 0
    while i < len(episodes):
      wig_zoom_string += str(int(episodes[i][0]))+':('+str(episodes[i][1])+'),'
      wig_angle_string += str(round(episodes[i][0],0))+':('+str(episodes[i][2])+'),'
      wig_trx_string += str(round(episodes[i][0],0))+':('+str(episodes[i][3])+'),'
      wig_try_string += str(round(episodes[i][0],0))+':('+str(episodes[i][4])+'),'
      wig_trz_string += str(round(episodes[i][0],0))+':('+str(episodes[i][5])+'),'
      wig_rotx_string += str(round(episodes[i][0],0))+':('+str(episodes[i][6])+'),'
      wig_roty_string += str(round(episodes[i][0],0))+':('+str(episodes[i][7])+'),'
      wig_rotz_string += str(round(episodes[i][0],0))+':('+str(episodes[i][8])+'),'
      i+=1    

    # TODO: get the form to update with these values
    zoom = wig_zoom_string
    angle = wig_angle_string 
    translation_x = wig_trx_string
    translation_y = wig_try_string
    translation_z = wig_trz_string
    rotation_3d_x = wig_rotx_string
    rotation_3d_y = wig_roty_string
    rotation_3d_z = wig_rotz_string

#============= END WIGGLE

# pharmapsychotic: displaying as widgets for easier copy to clipboard action

code_str = ""
code_str += f"(zoom,angle,translation_x,translation_y,translation_z,rotation_3d_x,rotation_3d_y,rotation_3d_z) = "
code_str += f"('{zoom}','{angle}','{translation_x}','{translation_y}','{translation_z}','{rotation_3d_x}','{rotation_3d_y}','{rotation_3d_z}')"

#print("\nCopy and paste the cam_code text above to preview. When you get what you like copy each of the fields into your Disco notebook.\n")

import ipywidgets as widgets
from ipywidgets import Layout, Text

layout = Layout(width='75%')

angle_widget = Text(value=angle, description='angle:', layout=layout)
zoom_widget = Text(value=zoom, description='zoom:', layout=layout)
translation_x_widget = Text(value=translation_x, description='translation_x:', layout=layout)
translation_y_widget = Text(value=translation_y, description='translation_y:', layout=layout)
translation_z_widget = Text(value=translation_z, description='translation_z:', layout=layout)
rotation_3d_x_widget = Text(value=rotation_3d_x, description='rot_3d_x:', layout=layout)
rotation_3d_y_widget = Text(value=rotation_3d_y, description='rot_3d_y:', layout=layout)
rotation_3d_z_widget = Text(value=rotation_3d_z, description='rot_3d_z:', layout=layout)


code_widget = widgets.Textarea(
    value=code_str,
    description='cam_code:',
    layout=Layout(width='75%', height='8em')
)

widgets.VBox([
    angle_widget, zoom_widget, 
    translation_x_widget, translation_y_widget, translation_z_widget,
    rotation_3d_x_widget, rotation_3d_y_widget, rotation_3d_z_widget,
    code_widget
])


sys.stdout.write("Done\n")
sys.stdout.flush()


"""<br>
<br>
<br>
<br>
<br>
<hr>

# Credits and License

This notebook uses code from Disco Diffusion to match the camera animation key frame settings, interpolation, and transformations.
https://github.com/alembics/disco-diffusion


The Wiggle 5.1 section comes from Zippy's notebook with modifications for easier copy/pasting here.
https://github.com/zippy731/wiggle

-- 

Licensed under the MIT License

Copyright (c) 2021 Katherine Crowson 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--

MIT License

Copyright (c) 2019 Intel ISL (Intel Intelligent Systems Lab)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--

Licensed under the MIT License

Copyright (c) 2021 Maxwell Ingham

Copyright (c) 2022 Adam Letts 

Copyright (c) 2022 Alex Spirin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

