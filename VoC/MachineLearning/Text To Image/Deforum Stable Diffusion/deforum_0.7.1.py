# Deforum Stable Diffusion v0.7.1
# https://github.com/deforum/deforum-stable-diffusion

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#sys.path.append('./CLIP')
#sys.path.append('./deforum-stable-diffusion-071')
#sys.path.append('./deforum-stable-diffusion-071/src')

sys.path.append('./src/CLIP')
sys.path.append('./src')

import subprocess, os, sys
sub_p_res = subprocess.run(['nvidia-smi', '--query-gpu=name,memory.total,memory.free', '--format=csv,noheader'], stdout=subprocess.PIPE).stdout.decode('utf-8')
print(f"{sub_p_res[:-1]}")
import subprocess, time, gc, os, sys

"""
def setup_environment():
    try:
        ipy = get_ipython()
    except:
        ipy = 'could not get_ipython'
    
    if 'google.colab' in str(ipy):
        start_time = time.time()
        packages = [
            'xformers==0.0.24',
            'einops==0.4.1 pytorch-lightning==1.7.7 torchdiffeq==0.2.3 torchsde==0.2.5',
            'ftfy timm transformers open-clip-torch omegaconf torchmetrics==0.11.4',
            'safetensors kornia accelerate jsonmerge matplotlib resize-right',
            'scikit-learn numpngw pydantic'
        ]
        for package in packages:
            print(f"..installing {package}")
            subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + package.split())
        if not os.path.exists("deforum-stable-diffusion"):
            subprocess.check_call(['git', 'clone', '-b', '0.7.1', 'https://github.com/deforum-art/deforum-stable-diffusion.git'])
        else:
            print(f"..deforum-stable-diffusion already exists")
        with open('deforum-stable-diffusion/src/k_diffusion/__init__.py', 'w') as f:
            f.write('')
        sys.path.extend(['deforum-stable-diffusion/','deforum-stable-diffusion/src',])
        end_time = time.time()
        print(f"..environment set up in {end_time-start_time:.0f} seconds")
    else:
        sys.path.extend(['src'])
        print("..skipping setup")

setup_environment()
"""

import torch
import random
import clip
from IPython import display
from types import SimpleNamespace
from helpers.save_images import get_output_folder
from helpers.settings import load_args
from helpers.render import render_animation, render_input_video, render_image_batch, render_interpolation
from helpers.model_load import make_linear_decode, load_model, get_model_output_paths
from helpers.aesthetics import load_aesthetics_model
from helpers.prompts import Prompts

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
    #parser.add_argument("--config", type=str, help="model config")
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
    parser.add_argument("--diffusion_cadence", type=int)
    parser.add_argument("--save_depth_maps", type=int)
    parser.add_argument("--border", type=str)
    parser.add_argument("--overwrite_extracted_frames", type=int)

    parser.add_argument("--frame_start_number", type=int, help="frame start number - used for self-driven")
    parser.add_argument("--self_driven_caption", type=int, help="should self driven frames be captioned with current prompt")
    
    parser.add_argument("--use_mask", type=int)
    parser.add_argument("--mask_file", type=str)
    parser.add_argument("--invert_mask", type=int)
    parser.add_argument("--mask_brightness_adjust", type=float)
    parser.add_argument("--mask_contrast_adjust", type=float)
    parser.add_argument("--use_mask_video", type=int)
    parser.add_argument("--video_mask_path", type=str)
    parser.add_argument("--interpolate_key_frames", type=int)
    parser.add_argument("--interpolate_x_frames", type=int)

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

    parser.add_argument("--mean_scale",  type=float, help="?")
    parser.add_argument("--var_scale",  type=float, help="?")
    parser.add_argument("--exposure_scale",  type=float, help="?")
    parser.add_argument("--exposure_target",  type=float, help="?")
    parser.add_argument("--colormatch_scale",  type=float, help="?")
    parser.add_argument("--colormatch_image", type=str)
    parser.add_argument("--colormatch_n_colors",  type=int, help="?")
    parser.add_argument("--ignore_sat_weight",  type=float, help="?")
    parser.add_argument("--clip_name", type=str)
    parser.add_argument("--clip_scale",  type=float, help="?")
    parser.add_argument("--aesthetics_scale",  type=float, help="?")
    parser.add_argument("--cutn",  type=int, help="?")
    parser.add_argument("--cut_pow",  type=float, help="?")
    parser.add_argument("--init_mse_scale",  type=float, help="?")
    parser.add_argument("--init_mse_image", type=str)
    parser.add_argument("--blue_scale", type=float)
    
    parser.add_argument("--gradient_wrt", type=str)
    parser.add_argument("--gradient_add_to", type=str)
    parser.add_argument("--decode_method", type=str)
    parser.add_argument("--grad_threshold_type", type=str)
    parser.add_argument("--clamp_grad_threshold",  type=float, help="?")
    parser.add_argument("--clamp_start",  type=float, help="?")
    parser.add_argument("--clamp_stop",  type=float, help="?")

    parser.add_argument("--grad_inject_timing", type=str)

    parser.add_argument("--hybrid_generate_inputframes",  type=int, help="?")
    parser.add_argument("--hybrid_use_first_frame_as_init_image",  type=int, help="?")
    parser.add_argument("--hybrid_motion",  type=str, help="?")
    parser.add_argument("--hybrid_motion_use_prev_img",  type=int, help="?")
    parser.add_argument("--hybrid_flow_method",  type=str, help="?")
    parser.add_argument("--hybrid_composite",  type=int, help="?")
    parser.add_argument("--hybrid_comp_mask_type",  type=str, help="?")
    parser.add_argument("--hybrid_comp_mask_inverse",  type=int, help="?")
    parser.add_argument("--hybrid_comp_mask_equalize",  type=str, help="?")
    parser.add_argument("--hybrid_comp_mask_auto_contrast",  type=int, help="?")
    parser.add_argument("--hybrid_comp_save_extra_frames",  type=int, help="?")
    parser.add_argument("--hybrid_use_video_as_mse_image",  type=int, help="?")

    parser.add_argument("--kernel_schedule", type=str)
    parser.add_argument("--sigma_schedule", type=str)
    parser.add_argument("--amount_schedule", type=str)
    parser.add_argument("--threshold_schedule", type=str)

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()















# %%
# !! {"metadata":{
# !!   "cellView": "form",
# !!   "id": "tQPlBfq9fIj8"
# !! }}
#@markdown **Path Setup**

def PathSetup():
    models_path = "models" #@param {type:"string"}
    configs_path = "configs" #@param {type:"string"}
    output_path = "outputs" #@param {type:"string"}
    mount_google_drive = False #@param {type:"boolean"}
    models_path_gdrive = "/content/drive/MyDrive/AI/models" #@param {type:"string"}
    output_path_gdrive = "/content/drive/MyDrive/AI/StableDiffusion" #@param {type:"string"}
    return locals()

root = SimpleNamespace(**PathSetup())
root.models_path, root.output_path = get_model_output_paths(root)

# %%
# !! {"metadata":{
# !!   "cellView": "form",
# !!   "id": "232_xKcCfIj9"
# !! }}
#@markdown **Model Setup**

def ModelSetup():
    map_location = "cuda" #@param ["cpu", "cuda"]
    model_config = args2.config #"v1-inference.yaml" #@param ["custom","v2-inference.yaml","v2-inference-v.yaml","v1-inference.yaml"]
    model_checkpoint =  args2.ckpt #"Protogen_V2.2.ckpt" #@param ["custom","v2-1_768-ema-pruned.ckpt","v2-1_512-ema-pruned.ckpt","768-v-ema.ckpt","512-base-ema.ckpt","Protogen_V2.2.ckpt","v1-5-pruned.ckpt","v1-5-pruned-emaonly.ckpt","sd-v1-4-full-ema.ckpt","sd-v1-4.ckpt","sd-v1-3-full-ema.ckpt","sd-v1-3.ckpt","sd-v1-2-full-ema.ckpt","sd-v1-2.ckpt","sd-v1-1-full-ema.ckpt","sd-v1-1.ckpt", "robo-diffusion-v1.ckpt","wd-v1-3-float16.ckpt"]
    custom_config_path = "" #@param {type:"string"}
    custom_checkpoint_path = "" #@param {type:"string"}
    return locals()

root.__dict__.update(ModelSetup())
root.model, root.device = load_model(root, load_on_run_all=True, check_sha256=True, map_location=root.map_location)








# %%
# !! {"metadata":{
# !!   "id": "6JxwhBwtWM_t"
# !! }}
"""
# Settings
"""

# %%
# !! {"metadata":{
# !!   "cellView": "form",
# !!   "id": "E0tJVYA4WM_u"
# !! }}
def DeforumAnimArgs():

    #@markdown ####**Animation:**
    animation_mode = args2.animation_mode #'None' #@param ['None', '2D', '3D', 'Video Input', 'Interpolation'] {type:'string'}
    max_frames = args2.max_frames #1000 #@param {type:"number"}
    border = args2.border #'replicate' #@param ['wrap', 'replicate'] {type:'string'}

    #@markdown ####**Motion Parameters:**
#VOC START 2 - DO NOT DELETE
    angle = "0:(0)"
    zoom = "0:(1.04)"
    translation_x = "0:(0)"
    translation_y = "0:(0)"
    translation_z = "0:(2)"
    rotation_3d_x = "0:(0)"
    rotation_3d_y = "0:(0)"
    rotation_3d_z = "0:(0)"
    flip_2d_perspective = False
    perspective_flip_theta = "0:(0)"
    perspective_flip_phi = "0:(t%15)"
    perspective_flip_gamma = "0:(0)"
    perspective_flip_fv = "0:(53)"
    noise_schedule = "0:(0.1)"
    strength_schedule = "0:(0.6)"
    contrast_schedule = "0:(1.0)"
    hybrid_comp_alpha_schedule = "0:(1)"
    hybrid_comp_mask_blend_alpha_schedule = "0:(0.5)"
    hybrid_comp_mask_contrast_schedule = "0:(1)"
    hybrid_comp_mask_auto_contrast_cutoff_high_schedule = "0:(100)"
    hybrid_comp_mask_auto_contrast_cutoff_low_schedule = "0:(0)"
#VOC FINISH 2 - DO NOT DELETE

    #@markdown ####**Sampler Scheduling:**
    enable_schedule_samplers = False #@param {type:"boolean"}
    sampler_schedule = "0:('euler'),10:('dpm2'),20:('dpm2_ancestral'),30:('heun'),40:('euler'),50:('euler_ancestral'),60:('dpm_fast'),70:('dpm_adaptive'),80:('dpmpp_2s_a'),90:('dpmpp_2m')" #@param {type:"string"}

    #@markdown ####**Unsharp mask (anti-blur) Parameters:**
    kernel_schedule = args2.kernel_schedule #"0: (5)"#@param {type:"string"}
    sigma_schedule = args2.sigma_schedule #"0: (1.0)"#@param {type:"string"}
    amount_schedule = args2.amount_schedule #"0: (0.2)"#@param {type:"string"}
    threshold_schedule = args2.threshold_schedule #"0: (0.0)"#@param {type:"string"}

    #@markdown ####**Coherence:**
    color_coherence = args2.color_coherence #'Match Frame 0 LAB' #@param ['None', 'Match Frame 0 HSV', 'Match Frame 0 LAB', 'Match Frame 0 RGB', 'Video Input'] {type:'string'}
    color_coherence_video_every_N_frames = 1 #@param {type:"integer"}
    color_force_grayscale = False #@param {type:"boolean"}
    diffusion_cadence = args2.diffusion_cadence #'1' #@param ['1','2','3','4','5','6','7','8'] {type:'string'}

    #@markdown ####**3D Depth Warping:**
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
    if args2.save_depth_maps == 1:
        save_depth_maps = True #@param {type:"boolean"}
    else:
        save_depth_maps = False #@param {type:"boolean"}

    #@markdown ####**Video Input:**
    video_init_path =args2.input_video #'/content/video_in.mp4'#@param {type:"string"}
    extract_nth_frame = args2.extract_nth_frame #1#@param {type:"number"}
    overwrite_extracted_frames = args2.overwrite_extracted_frames #True #@param {type:"boolean"}
    if args2.use_mask_video==1:
        use_mask_video = True #@param {type:"boolean"}
    else:
        use_mask_video = False #@param {type:"boolean"}
    video_mask_path = args2.video_mask_path #'/content/video_in.mp4'#@param {type:"string"}

    #@markdown ####**Hybrid Video for 2D/3D Animation Mode:**
    if args2.hybrid_generate_inputframes == 1:
        hybrid_generate_inputframes = True #False #@param {type:"boolean"}
    else:
        hybrid_generate_inputframes = False #False #@param {type:"boolean"}

    if args2.hybrid_use_first_frame_as_init_image == 1:
        hybrid_use_first_frame_as_init_image = True #@param {type:"boolean"}
    else:
        hybrid_use_first_frame_as_init_image = False #@param {type:"boolean"}

    hybrid_motion = args2.hybrid_motion #"None" #@param ['None','Optical Flow','Perspective','Affine']

    if args2.hybrid_motion_use_prev_img == 1:
        hybrid_motion_use_prev_img = True #@param {type:"boolean"}
    else:
        hybrid_motion_use_prev_img = False #@param {type:"boolean"}

    hybrid_flow_method = args2.hybrid_flow_method #"DIS Medium" #@param ['DenseRLOF','DIS Medium','Farneback','SF']

    if args2.hybrid_composite == 1:
        hybrid_composite = True #@param {type:"boolean"}
    else:
        hybrid_composite = False #@param {type:"boolean"}

    hybrid_comp_mask_type = args2.hybrid_comp_mask_type #"None" #@param ['None', 'Depth', 'Video Depth', 'Blend', 'Difference']
    
    if args2.hybrid_comp_mask_inverse == 1:
        hybrid_comp_mask_inverse = True #@param {type:"boolean"}
    else:
        hybrid_comp_mask_inverse = False #@param {type:"boolean"}

    hybrid_comp_mask_equalize = args2.hybrid_comp_mask_equalize #"None" #@param  ['None','Before','After','Both']
    
   
    if args2.hybrid_comp_mask_auto_contrast == 1:
        hybrid_comp_mask_auto_contrast = True #@param {type:"boolean"}
    else:
        hybrid_comp_mask_auto_contrast = False #@param {type:"boolean"}
    if args2.hybrid_comp_save_extra_frames == 1:
        hybrid_comp_save_extra_frames = True #@param {type:"boolean"}
    else:
        hybrid_comp_save_extra_frames = False #@param {type:"boolean"}
    if args2.hybrid_use_video_as_mse_image == 1:
        hybrid_use_video_as_mse_image = True #@param {type:"boolean"}
    else:
        hybrid_use_video_as_mse_image = False #@param {type:"boolean"}

    #@markdown ####**Interpolation:**
    if args2.interpolate_key_frames==1:
        interpolate_key_frames = True #@param {type:"boolean"}
    else:
        interpolate_key_frames = False #@param {type:"boolean"}
    interpolate_x_frames = args2.interpolate_x_frames #20 #@param {type:"number"}
    
    #@markdown ####**Resume Animation:**
    resume_from_timestring = False #@param {type:"boolean"}
    resume_timestring = "20220829210106" #@param {type:"string"}

    outdir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    frame_dir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    image_file = args2.image_file

    return locals()

# %%
# !! {"metadata":{
# !!   "id": "i9fly1RIWM_u"
# !! }}
# prompts
prompts = {
#VOC START 3 - DO NOT DELETE
    0: args2.prompt,
#VOC FINISH 3 - DO NOT DELETE
}

neg_prompts = {
    0: "",
}

# can be a string, list, or dictionary
#prompts = [
#    "a beautiful lake by Asher Brown Durand, trending on Artstation",
#    "a beautiful portrait of a woman by Artgerm, trending on Artstation",
#]
#prompts = "a beautiful lake by Asher Brown Durand, trending on Artstation"

# %%
# !! {"metadata":{
# !!   "cellView": "form",
# !!   "id": "XVzhbmizWM_u"
# !! }}
#@markdown **Load Settings**
override_settings_with_file = False #@param {type:"boolean"}
settings_file = "custom" #@param ["custom", "512x512_aesthetic_0.json","512x512_aesthetic_1.json","512x512_colormatch_0.json","512x512_colormatch_1.json","512x512_colormatch_2.json","512x512_colormatch_3.json"]
custom_settings_file = "/content/drive/MyDrive/Settings.txt"#@param {type:"string"}

def DeforumArgs():
    #@markdown **Image Settings**
    W = args2.W
    H = args2.H
    #W, H = map(lambda x: x - x % 64, (W, H))  # resize to integer multiple of 64
    bit_depth_output = 8 #@param [8, 16, 32] {type:"raw"}

    #@markdown **Sampling Settings**
    seed = args2.seed #@param
    sampler = args2.sampler #'euler_ancestral' #@param ["klms","dpm2","dpm2_ancestral","heun","euler","euler_ancestral","plms", "ddim", "dpm_fast", "dpm_adaptive", "dpmpp_2s_a", "dpmpp_2m"]
    steps = args2.ddim_steps #50 #@param
    scale = args2.scale #7 #@param
    ddim_eta = args2.ddim_eta #0.0 #@param
    dynamic_threshold = None
    static_threshold = None   

    #@markdown **Save & Display Settings**
    if args2.save_samples == 1:
        save_samples = True #@param {type:"boolean"}
    else:
        save_samples = False #@param {type:"boolean"}
    save_settings = False #@param {type:"boolean"}
    display_samples = False #@param {type:"boolean"}
    save_sample_per_step = False #@param {type:"boolean"}
    show_sample_per_step = False #@param {type:"boolean"}

    #@markdown **Batch Settings**
    n_batch = args2.n_batch #1 #@param
    n_samples = 1 #@param
    batch_name = "Deforum071" #@param {type:"string"}
    filename_format = "{timestring}_{index}_{prompt}.png" #@param ["{timestring}_{index}_{seed}.png","{timestring}_{index}_{prompt}.png"]
    seed_behavior = args2.seed_behavior #"iter" #@param ["iter","fixed","random","ladder","alternate"]
    seed_iter_N = 1 #@param {type:'integer'}
    make_grid = True #@param {type:"boolean"}
    if n_batch == 1:
        make_grid=False
    grid_rows = args2.grid_columns #2 #@param 
    outdir = args2.frame_dir #get_output_folder(root.output_path, batch_name)

    #@markdown **Init Settings**
    if args2.init_img is not None:
        use_init = True #@param {type:"boolean"}
    else:
        use_init = False #@param {type:"boolean"}
    strength = args2.strength #0.65 #@param {type:"number"}
    strength_0_no_init = True # Set the strength to 0 automatically when no init image is used
    init_image = args2.init_img #"https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
    add_init_noise = False #@param {type:"boolean"}
    init_noise = 0.01 #@param
    # Whiter areas of the mask are areas that change more
    if args2.use_mask==1:
        use_mask = True #@param {type:"boolean"}
    else:
        use_mask = False #@param {type:"boolean"}
    use_alpha_as_mask = False # use the alpha channel of the init image as the mask
    mask_file = args2.mask_file #"https://www.filterforge.com/wiki/images/archive/b/b7/20080927223728%21Polygonal_gradient_thumb.jpg" #@param {type:"string"}
    if args2.invert_mask==1:
        invert_mask = True #@param {type:"boolean"}
    else:
        invert_mask = False #@param {type:"boolean"}
    # Adjust mask image, 1.0 is no adjustment. Should be positive numbers.
    mask_brightness_adjust = args2.mask_brightness_adjust #1.0  #@param {type:"number"}
    mask_contrast_adjust = args2.mask_contrast_adjust #1.0  #@param {type:"number"}
    # Overlay the masked image at the end of the generation so it does not get degraded by encoding and decoding
    overlay_mask = True  # {type:"boolean"}
    # Blur edges of final overlay mask, if used. Minimum = 0 (no blur)
    mask_overlay_blur = 5 # {type:"number"}

    #@markdown **Exposure/Contrast Conditional Settings**
    mean_scale = args2.mean_scale #0 #@param {type:"number"}
    var_scale = args2.var_scale #0 #@param {type:"number"}
    exposure_scale = args2.exposure_scale #0 #@param {type:"number"}
    exposure_target = args2.exposure_target #0.5 #@param {type:"number"}

    #@markdown **Color Match Conditional Settings**
    colormatch_scale = args2.colormatch_scale #0 #@param {type:"number"}
    colormatch_image = args2.colormatch_image #"https://www.saasdesign.io/wp-content/uploads/2021/02/palette-3-min-980x588.png" #@param {type:"string"}
    colormatch_n_colors = args2.colormatch_n_colors #4 #@param {type:"number"}
    ignore_sat_weight = args2.ignore_sat_weight #0 #@param {type:"number"}

    #@markdown **CLIP\Aesthetics Conditional Settings**
    clip_name = args2.clip_name #'ViT-L/14' #@param ['ViT-L/14', 'ViT-L/14@336px', 'ViT-B/16', 'ViT-B/32']
    clip_scale = args2.clip_scale #0 #@param {type:"number"}
    aesthetics_scale = args2.aesthetics_scale #0 #@param {type:"number"}
    cutn = args2.cutn #1 #@param {type:"number"}
    cut_pow = args2.cut_pow #0.0001 #@param {type:"number"}

    #@markdown **Other Conditional Settings**
    init_mse_scale = args2.init_mse_scale #0 #@param {type:"number"}
    init_mse_image = args2.init_mse_image #"https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
    blue_scale = 0 #@param {type:"number"}
    
    #@markdown **Conditional Gradient Settings**
    gradient_wrt = args2.gradient_wrt #'x0_pred' #@param ["x", "x0_pred"]
    gradient_add_to = args2.gradient_add_to #'both' #@param ["cond", "uncond", "both"]
    decode_method = args2.decode_method #'linear' #@param ["autoencoder","linear"]
    grad_threshold_type = args2.grad_threshold_type #'dynamic' #@param ["dynamic", "static", "mean", "schedule"]
    clamp_grad_threshold = args2.clamp_grad_threshold #0.2 #@param {type:"number"}
    clamp_start = args2.clamp_start #0.2 #@param
    clamp_stop = args2.clamp_stop #0.01 #@param
    grad_inject_timing = args2.grad_inject_timing #list(range(1,10)) #@param

    #@markdown **Speed vs VRAM Settings**
    cond_uncond_sync = True #@param {type:"boolean"}
    precision = 'autocast' 
    C = 4
    f = 8

    cond_prompt = ""
    cond_prompts = ""
    uncond_prompt = ""
    uncond_prompts = ""
    timestring = ""
    init_latent = None
    init_sample = None
    init_sample_raw = None
    mask_sample = None
    init_c = None
    seed_internal = 0

    outdir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    frame_dir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    image_file = args2.image_file
   
    return locals()

args_dict = DeforumArgs()
anim_args_dict = DeforumAnimArgs()

if override_settings_with_file:
    load_args(args_dict, anim_args_dict, settings_file, custom_settings_file, verbose=False)

args = SimpleNamespace(**args_dict)
anim_args = SimpleNamespace(**anim_args_dict)

args.timestring = time.strftime('%Y%m%d%H%M%S')
args.strength = max(0.0, min(1.0, args.strength))

# Load clip model if using clip guidance
if (args.clip_scale > 0) or (args.aesthetics_scale > 0):
    root.clip_model = clip.load(args.clip_name, jit=False)[0].eval().requires_grad_(False).to(root.device)
    if (args.aesthetics_scale > 0):
        root.aesthetics_model = load_aesthetics_model(args, root)

if args.seed == -1:
    args.seed = random.randint(0, 2**32 - 1)
if not args.use_init:
    args.init_image = None
if args.sampler == 'plms' and (args.use_init or anim_args.animation_mode != 'None'):
    print(f"Init images aren't supported with PLMS yet, switching to KLMS")
    args.sampler = 'klms'
if args.sampler != 'ddim':
    args.ddim_eta = 0

if anim_args.animation_mode == 'None':
    anim_args.max_frames = 1
elif anim_args.animation_mode == 'Video Input':
    args.use_init = True

# clean up unused memory
gc.collect()
torch.cuda.empty_cache()

# get prompts
cond, uncond = Prompts(prompt=prompts,neg_prompt=neg_prompts).as_dict()

# dispatch to appropriate renderer
if anim_args.animation_mode == '2D' or anim_args.animation_mode == '3D':
    render_animation(root, anim_args, args, cond, uncond)
elif anim_args.animation_mode == 'Video Input':
    render_input_video(root, anim_args, args, cond, uncond)
elif anim_args.animation_mode == 'Interpolation':
    render_interpolation(root, anim_args, args, cond, uncond)
else:
    render_image_batch(root, args, prompts, cond, uncond)

# %%
# !! {"metadata":{
# !!   "id": "gJ88kZ2-WM_v"
# !! }}
"""
# Create Video From Frames
"""

# %%
# !! {"metadata":{
# !!   "cellView": "form",
# !!   "id": "YDoi7at9avqC"
# !! }}
#@markdown **New Version**
skip_video_for_run_all = True #@param {type: 'boolean'}
create_gif = False #@param {type: 'boolean'}

if skip_video_for_run_all == True:
    print('Skipping video creation, uncheck skip_video_for_run_all if you want to run it')
else:

    from helpers.ffmpeg_helpers import get_extension_maxframes, get_auto_outdir_timestring, get_ffmpeg_path, make_mp4_ffmpeg, make_gif_ffmpeg, patrol_cycle

    def ffmpegArgs():
        ffmpeg_mode = "auto" #@param ["auto","manual","timestring"]
        ffmpeg_outdir = "" #@param {type:"string"}
        ffmpeg_timestring = "" #@param {type:"string"}
        ffmpeg_image_path = "" #@param {type:"string"}
        ffmpeg_mp4_path = "" #@param {type:"string"}
        ffmpeg_gif_path = "" #@param {type:"string"}
        ffmpeg_extension = "png" #@param {type:"string"}
        ffmpeg_maxframes = 200 #@param
        ffmpeg_fps = 12 #@param

        # determine auto paths
        if ffmpeg_mode == 'auto':
            ffmpeg_outdir, ffmpeg_timestring = get_auto_outdir_timestring(args,ffmpeg_mode)
        if ffmpeg_mode in ["auto","timestring"]:
            ffmpeg_extension, ffmpeg_maxframes = get_extension_maxframes(args,ffmpeg_outdir,ffmpeg_timestring)
            ffmpeg_image_path, ffmpeg_mp4_path, ffmpeg_gif_path = get_ffmpeg_path(ffmpeg_outdir, ffmpeg_timestring, ffmpeg_extension)
        return locals()

    ffmpeg_args_dict = ffmpegArgs()
    ffmpeg_args = SimpleNamespace(**ffmpeg_args_dict)
    make_mp4_ffmpeg(ffmpeg_args, display_ffmpeg=True, debug=False)
    if create_gif:
        make_gif_ffmpeg(ffmpeg_args, debug=False)
    #patrol_cycle(args,ffmpeg_args)
