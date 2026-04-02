# Deforum_Stable_Diffusion.ipynb
# Original file is located at https://colab.research.google.com/github/deforum-art/deforum-stable-diffusion/blob/main/Deforum_Stable_Diffusion.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./CLIP')
sys.path.append('./deforum-stable-diffusion-06')
sys.path.append('./deforum-stable-diffusion-06/src')

#sys.path.append('./stable-diffusion-0.4')
#sys.path.append('./taming')
#sys.path.append('./k-diffusion')
#sys.path.append('./taming-transformers')
#sys.path.append('./pytorch3d-lite')
#sys.path.append('./AdaBins')
#sys.path.append('./MiDaS')

import os
import torch
import gc
import time
import random
import clip
#from IPython import display
from types import SimpleNamespace
from helpers.save_images import get_output_folder
from helpers.settings import load_args
from helpers.render import render_animation, render_input_video, render_image_batch, render_interpolation
from helpers.model_load import make_linear_decode, load_model, get_model_output_paths
from helpers.aesthetics import load_aesthetics_model
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
    parser.add_argument("--diffusion_cadence", type=int)
    parser.add_argument("--save_depth_maps", type=int)
    parser.add_argument("--border", type=str)
    parser.add_argument("--prompt_weighting", type=int)
    parser.add_argument("--normalize_prompt_weights", type=int)
    parser.add_argument("--log_weighted_subprompts", type=int)
    parser.add_argument("--overwrite_extracted_frames", type=int)

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

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

















sys.stdout.write("Getting ready ...\n")
sys.stdout.flush()

#@markdown **Path Setup**

def Root():
    return locals()
root = Root()
root = SimpleNamespace(**root)

root.models_path = "." #@param {type:"string"}
root.output_path = "." #@param {type:"string"}
#root.mount_google_drive = False #@param {type:"boolean"}
#root.models_path_gdrive = "/content/drive/MyDrive/AI/models" #@param {type:"string"}
#root.output_path_gdrive = "/content/drive/MyDrive/AI/StableDiffusion" #@param {type:"string"}

#@markdown **Model Setup**
root.model_config = "v1-inference-deforum-06.yaml" #@param ["custom","v1-inference.yaml"]
root.model_checkpoint = args2.ckpt #"sd-v1-4.ckpt" # "v1-5-pruned-emaonly.ckpt" #@param ["custom","v1-5-pruned.ckpt","v1-5-pruned-emaonly.ckpt","sd-v1-4-full-ema.ckpt","sd-v1-4.ckpt","sd-v1-3-full-ema.ckpt","sd-v1-3.ckpt","sd-v1-2-full-ema.ckpt","sd-v1-2.ckpt","sd-v1-1-full-ema.ckpt","sd-v1-1.ckpt", "robo-diffusion-v1.ckpt","wd-v1-3-float16.ckpt"]
root.custom_config_path = "" #@param {type:"string"}
root.custom_checkpoint_path = "" #@param {type:"string"}
root.half_precision = True

#sys.stdout.write("Loading model ...\n")
#sys.stdout.flush()

root.models_path, root.output_path = get_model_output_paths(root)
root.model, root.device = load_model(root)

"""# Settings"""

def DeforumAnimArgs():

    #@markdown ####**Animation:**
    animation_mode = args2.animation_mode #'None' #@param ['None', '2D', '3D', 'Video Input', 'Interpolation'] {type:'string'}
    max_frames = args2.max_frames #1000 #@param {type:"number"}
    border = args2.border #'replicate' #@param ['wrap', 'replicate'] {type:'string'}

    #@markdown ####**Motion Parameters:**
#VOC START 2 - DO NOT DELETE
    angle = "0:(0)"
    zoom = "0:(1.04)"
    angle = "0:(0)"
    zoom = "0:(1.04)"
    translation_x = "0:(0)"
    translation_y = "0:(0)"
    translation_z = "0:(4)"
    rotation_3d_x = "0:(0)"
    rotation_3d_y = "0:(0)"
    rotation_3d_z = "0:(0)"
    flip_2d_perspective = False
    perspective_flip_theta = "0:(0)"
    perspective_flip_phi = "0:(t%15)"
    perspective_flip_gamma = "0:(0)"
    perspective_flip_fv = "0:(53)"
    noise_schedule = "0:(0.02)"
    strength_schedule = "0:(0.85)"
    contrast_schedule = "0: (1.0)"
#VOC FINISH 2 - DO NOT DELETE


    #@markdown ####**Coherence:**
    color_coherence = args2.color_coherence #'Match Frame 0 LAB' #@param ['None', 'Match Frame 0 HSV', 'Match Frame 0 LAB', 'Match Frame 0 RGB'] {type:'string'}
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
    video_init_path = args2.input_video #'/content/video_in.mp4'#@param {type:"string"}
    extract_nth_frame = args2.extract_nth_frame #1#@param {type:"number"}
    overwrite_extracted_frames = args2.overwrite_extracted_frames #True #@param {type:"boolean"}
    if args2.use_mask_video==1:
        use_mask_video = True #@param {type:"boolean"}
    else:
        use_mask_video = False #@param {type:"boolean"}
    video_mask_path = args2.video_mask_path #'/content/video_in.mp4'#@param {type:"string"}

    #@markdown ####**Interpolation:**
    if args2.interpolate_key_frames==1:
        interpolate_key_frames = True #@param {type:"boolean"}
    else:
        interpolate_key_frames = False #@param {type:"boolean"}
    interpolate_x_frames = args2.interpolate_x_frames #4 #@param {type:"number"}
    
    #@markdown ####**Resume Animation:**
    resume_from_timestring = False #@param {type:"boolean"}
    resume_timestring = "20220829210106" #@param {type:"string"}

    outdir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    frame_dir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    image_file = args2.image_file

    return locals()

#sys.stdout.write("Prompts ...\n")
#sys.stdout.flush()

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

override_settings_with_file = False #@param {type:"boolean"}
custom_settings_file = "Settings.txt"#@param {type:"string"}

#sys.stdout.write("DeforumArgs ...\n")
#sys.stdout.flush()

def DeforumArgs():
    #@markdown **Image Settings**
    W = args2.W
    H = args2.H
    #W, H = map(lambda x: x - x % 64, (W, H))  # resize to integer multiple of 64

    #@markdown **Sampling Settings**
    seed = args2.seed #-1 #@param
    sampler = args2.sampler #'euler_ancestral' #@param ["klms","dpm2","dpm2_ancestral","heun","euler","euler_ancestral","plms", "ddim"]
    steps = args2.ddim_steps #80 #@param
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

    #@markdown **Prompt Settings**
    if args2.prompt_weighting==1:
        prompt_weighting = True #@param {type:"boolean"}
    else:
        prompt_weighting = False #@param {type:"boolean"}

    if args2.normalize_prompt_weights==1:
        normalize_prompt_weights = True #@param {type:"boolean"}
    else:
        normalize_prompt_weights = False #@param {type:"boolean"}

    if args2.log_weighted_subprompts==1:
        log_weighted_subprompts = False #@param {type:"boolean"}
    else:
        log_weighted_subprompts = False #@param {type:"boolean"}

    #@markdown **Batch Settings**
    n_batch = args2.n_batch #1 #@param
    batch_name = "StableFun" #@param {type:"string"}
    filename_format = "{timestring}_{index}_{prompt}.png" #@param ["{timestring}_{index}_{seed}.png","{timestring}_{index}_{prompt}.png"]
    seed_behavior = args2.seed_behavior #"iter" #@param ["iter","fixed","random"]
    make_grid = True #@param {type:"boolean"}
    grid_rows = args2.grid_columns #2 #@param 
    outdir = args2.frame_dir #get_output_folder(root.output_path, batch_name)
    image_file = args2.image_file

    #@markdown **Init Settings**
    if args2.init_img is not None:
        use_init = True #@param {type:"boolean"}
    else:
        use_init = False #@param {type:"boolean"}

    strength = args2.strength #0.0 #@param {type:"number"}
    strength_0_no_init = True # Set the strength to 0 automatically when no init image is used
    init_image = args2.init_img #"https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
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
    #init_mse_scale = 0 #@param {type:"number"}
    #init_mse_image = "https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
    #blue_scale = 0 #@param {type:"number"}
    init_mse_scale = args2.init_mse_scale #0 #@param {type:"number"}
    init_mse_image = args2.init_mse_image #"https://cdn.pixabay.com/photo/2022/07/30/13/10/green-longhorn-beetle-7353749_1280.jpg" #@param {type:"string"}
    blue_scale = args2.blue_scale #0 #@param {type:"number"}
    
    #@markdown **Conditional Gradient Settings**
    gradient_wrt = args2.gradient_wrt #'x0_pred' #@param ["x", "x0_pred"]
    gradient_add_to = args2.gradient_add_to #'both' #@param ["cond", "uncond", "both"]
    decode_method = args2.decode_method #'linear' #@param ["autoencoder","linear"]
    grad_threshold_type = args2.grad_threshold_type #'dynamic' #@param ["dynamic", "static", "mean", "schedule"]
    clamp_grad_threshold = args2.clamp_grad_threshold #0.2 #@param {type:"number"}
    clamp_start = args2.clamp_start #0.2 #@param
    clamp_stop = args2.clamp_stop #0.01 #@param
    grad_inject_timing = args2.grad_inject_timing #None
    
    #@markdown **Speed vs VRAM Settings**
    cond_uncond_sync = True #@param {type:"boolean"}

    n_samples = 1 # doesnt do anything
    precision = 'autocast' 
    C = 4
    f = 8

    prompt = ""
    timestring = ""
    init_latent = None
    init_sample = None
    init_c = None

    embedding_type = args2.embedding_type #".pt" #@param [".bin",".pt"]
    embedding_path = args2.embedding_path #"/content/drive/MyDrive/AI/models/Seraphim_MATRIXMANE.pt" #@param {type:"string"}


    return locals()

args_dict = DeforumArgs()
anim_args_dict = DeforumAnimArgs()

if override_settings_with_file:
    load_args(args_dict,anim_args_dict,custom_settings_file, verbose=False)

args = SimpleNamespace(**args_dict)
anim_args = SimpleNamespace(**anim_args_dict)

args.timestring = time.strftime('%Y%m%d%H%M%S')
args.strength = max(0.0, min(1.0, args.strength))

# Load clip model if using clip guidance
if (args.clip_scale > 0) or (args.aesthetics_scale > 0):
    sys.stdout.write("Loading CLIP model ...\n")
    sys.stdout.flush()
    root.clip_model = clip.load(args.clip_name, jit=False)[0].eval().requires_grad_(False).to(root.device)
    if (args.aesthetics_scale > 0):
        root.aesthetics_model = load_aesthetics_model(args, root)

#sys.stdout.write("Seed ...\n")
#sys.stdout.flush()

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

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

# dispatch to appropriate renderer
if anim_args.animation_mode == '2D' or anim_args.animation_mode == '3D':
    render_animation(args, anim_args, animation_prompts, root)
elif anim_args.animation_mode == 'Video Input':
    render_input_video(args, anim_args, animation_prompts, root)
elif anim_args.animation_mode == 'Interpolation':
    render_interpolation(args, anim_args, animation_prompts, root)
else:
    render_image_batch(args, prompts, root)

"""# Create Video From Frames"""

"""
skip_video_for_run_all = True #@param {type: 'boolean'}
fps = 12 #@param {type:"number"}
#@markdown **Manual Settings**
use_manual_settings = False #@param {type:"boolean"}
image_path = "/content/drive/MyDrive/AI/StableDiffusion/2022-09/20220903000939_%05d.png" #@param {type:"string"}
mp4_path = "/content/drive/MyDrive/AI/StableDiffu'/content/drive/MyDrive/AI/StableDiffusion/2022-09/sion/2022-09/20220903000939.mp4" #@param {type:"string"}
render_steps = False  #@param {type: 'boolean'}
path_name_modifier = "x0_pred" #@param ["x0_pred","x"]


if skip_video_for_run_all == True:
    print('Skipping video creation, uncheck skip_video_for_run_all if you want to run it')
else:
    import os
    import subprocess
    from base64 import b64encode

    print(f"{image_path} -> {mp4_path}")

    if use_manual_settings:
        max_frames = "200" #@param {type:"string"}
    else:
        if render_steps: # render steps from a single image
            fname = f"{path_name_modifier}_%05d.png"
            all_step_dirs = [os.path.join(args.outdir, d) for d in os.listdir(args.outdir) if os.path.isdir(os.path.join(args.outdir,d))]
            newest_dir = max(all_step_dirs, key=os.path.getmtime)
            image_path = os.path.join(newest_dir, fname)
            print(f"Reading images from {image_path}")
            mp4_path = os.path.join(newest_dir, f"{args.timestring}_{path_name_modifier}.mp4")
            max_frames = str(args.steps)
        else: # render images for a video
            image_path = os.path.join(args.outdir, f"{args.timestring}_%05d.png")
            mp4_path = os.path.join(args.outdir, f"{args.timestring}.mp4")
            max_frames = str(anim_args.max_frames)

    # make video
    cmd = [
        'ffmpeg',
        '-y',
        '-vcodec', 'png',
        '-r', str(fps),
        '-start_number', str(0),
        '-i', image_path,
        '-frames:v', max_frames,
        '-c:v', 'libx264',
        '-vf',
        f'fps={fps}',
        '-pix_fmt', 'yuv420p',
        '-crf', '17',
        '-preset', 'veryfast',
        '-pattern_type', 'sequence',
        mp4_path
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        print(stderr)
        raise RuntimeError(stderr)

    mp4 = open(mp4_path,'rb').read()
    data_url = "data:video/mp4;base64," + b64encode(mp4).decode()
    display.display(display.HTML(f'<video controls loop><source src="{data_url}" type="video/mp4"></video>') )

skip_disconnect_for_run_all = True #@param {type: 'boolean'}

if skip_disconnect_for_run_all == True:
    print('Skipping disconnect, uncheck skip_disconnect_for_run_all if you want to run it')
else:
    from google.colab import runtime
    runtime.unassign()
"""
