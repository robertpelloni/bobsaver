# VQGAN+CLIP Video with Optical Flow
# Original file is located at https://colab.research.google.com/drive/1n8n5oar7LiQFiKfIw77sgRkovETPSTRa

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./VQGAN-CLIP-Video')
sys.path.append('./VQGAN-CLIP-Video/taming-transformers')

import os
import argparse
import torch
from dream import Dream
from os.path import exists
from dream import cv2
from dream import save_img
from dream import reduce_res
from dream import np
from dream import get_opflow_image
from dream import PIL
from dream import trange
from dream import glob

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompts', type=str, help='Text to generate image from.')
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--fps', type=int, help='FPS of output video.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--cutn', type=int, help='Cutouts.')
  parser.add_argument('--cutpow', type=float, help='Cut power.')
  parser.add_argument('--step_size', type=float, help='Step size (learning rate).')
  parser.add_argument('--input_video', type=str, help='Input video.')
  parser.add_argument('--output_video', type=str, help='Output video.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model.')
  parser.add_argument('--clip_model', type=str, help='CLIP model.')
  args3 = parser.parse_args()
  return args3

args2=parse_args();

if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 





ckpt_dir = ""

vqgan_model = args2.vqgan_model #"vqgan_imagenet_f16_1024" #"imagenet_1024" #@param ["imagenet_1024", "imagenet_16384", "coco", "sflckr"]
is_colab_pro = False #@param {type:"boolean"}

vqgan_options = {
  "imagenet_1024": ["1-7QlixzWxZAO8ktGFqvxrZ_JzapzI5hH", "1-8mSOBsutfkE95piiGf4ZuVX0zkAwzkn"],
  "imagenet_16384": ["1_1q5zxEBx17AyTALEhGqhSsS7tyCJ4fe", "1-0D4pbu7NHrvWzTfbw4hiA1Sno75Z2_C"],
  "coco": ["1-9gq1a4yGOKC3rDw-X9NBe5_JVcKcLPG", "1-CPBZXsCgCv-Z6Uy4Sf4lKeyqG_C5i-Y"],
  "sflckr": ["1iIgSRV4H6og3l2myXPRE043ULoPlqn8w", "1-1vMpPmB6QZhGzriXG9iI6WeFZLl7VP2"],
}

yaml, ckpt = ckpt_dir + "%s.yaml"%vqgan_model, ckpt_dir + "%s.ckpt"%vqgan_model

sys.stdout.write(f'Loading {args2.vqgan_model} model ...\n')
sys.stdout.flush()


dream = Dream(True)
dream.cook([yaml, ckpt], cut_n=args2.cutn, cut_pow=args2.cutpow, clip_model=args2.clip_model)

"""Run the cell above once when it's initial googlecolab run or you want to change the VQGAN model"""

# @title Dream  { display-mode: "form" }
#@markdown You can see output frames in /content/output folder.

#@markdown ---

#@markdown Describe how deepdream should look like. Each scene ( | ... | ) can be weighted: "deepdream:3 | dogs:-1"
#text_prompts = "trending on artstation | lovecraftian horror | deepdream | vibrant colors | 4k | made by Edvard Munch" #@param {type:"string"}
text_prompts = args2.prompts #"airbrush by h r giger" #@param {type:"string"}

#@markdown ---

#@markdown Video paths.
vid_path = args2.input_video #'Shining2.mp4' #@param {type:"string"}
output_vid_path = args2.output_video #'Shining2_processed.mp4' #@param {type:"string"}
#@markdown ---

#@markdown Play around with these settings, finding optimal settings may vary video to video. Set both to 0 for more chaotic experience.
frame_weight = 10#@param {type:"number"}
previous_frame_weight =  0.1#@param {type:"number"}
#@markdown ---

#@markdown Usual VQGAN+CLIP settings
step_size = args2.step_size #0.15 #@param {type:"slider", min:0, max:1, step:0.05}
iter_n =  args2.iterations #5#@param {type:"number"}
#@markdown ---

#@markdown Dream more intense on first frame of the video. 
do_wait_first_frame = True #@param {type:"boolean"}
wait_step_size = args2.step_size #0.15 #@param {type:"slider", min:0, max:1, step:0.05}
wait_iter_n = args2.iterations*3 #15#@param {type:"number"}
#@markdown ---

#@markdown Weights of how previous deepdreamed frame should effect current frame.
blendflow = 0.6#@param {type:"slider", min:0, max:1, step:0.05}
blendstatic =  0.6#@param {type:"slider", min:0, max:1, step:0.05}
#@markdown ---
#@markdown Video resolution and fps
w = 1920#@param {type:"number"}
h = 1080#@param {type:"number"}
fps =  args2.fps #24#@param {type:"number"}
#@markdown ---
#@markdown Make a test run.
is_test = False #@param {type:"boolean"}
test_finish_at = 24#@param {type:"number"}
#@markdown ---
#@markdown Get all frames from video, can be set to False if video didn't change. 
video_to_frames = True #@param {type:"boolean"}

sys.stdout.write("Extracting frames from video ...\n")
sys.stdout.flush()

if(video_to_frames):
    #!rm -r -f ./input/*.jpg
    vidcap = cv2.VideoCapture(vid_path)
    success,image = vidcap.read()
    index = 1
    last_frame_file=''
    while success:
        sys.stdout.write(f'Extracting frame {index}\n')
        sys.stdout.flush()
        last_frame_file="./input/%04d.jpg" % index
        cv2.imwrite(last_frame_file, image)
        success, image = vidcap.read()
        index += 1
    #set output width and height auto-set to source width and height rather than a fixed value as above
    img2 = cv2.imread(last_frame_file, cv2.IMREAD_UNCHANGED)
    h, w = img2.shape[:2]
    
sys.stdout.write(f'Frame dimensions are {w} by {h}\n')
sys.stdout.flush()


x, y = reduce_res((w, h), max_res_value=dream.resLimit)
img_arr = sorted(glob('input/*.jpg'))

np_img = np.float32(PIL.Image.open(img_arr[0]))
np_img = cv2.resize(np_img, dsize=(x, y), interpolation=cv2.INTER_CUBIC)
h, w, c = np_img.shape

frame = None

range_to=len(img_arr)

sys.stdout.write(f'Processing {range_to} extracted frames ...\n')
sys.stdout.flush()

if do_wait_first_frame:
    frame = dream.deepdream(np_img, text_prompts, [x, y], iter_n=wait_iter_n, step_size=step_size, init_weight=frame_weight)
else:
    frame = dream.deepdream(np_img, text_prompts, [x, y], iter_n=iter_n, step_size=step_size, init_weight=frame_weight)

frame = cv2.resize(frame, dsize=(x, y), interpolation=cv2.INTER_CUBIC)
save_img(frame, 'output/%04d.jpg'%0)

#img_range = trange(len(img_arr[:test_finish_at]), desc="Dreaming") if is_test else trange(len(img_arr), desc="Dreaming")
prev_frame = None
#for i in img_range:  
for i in range(range_to):  
    if previous_frame_weight != 0:
        prev_frame = np.copy(frame)

    img = img_arr[i]
    np_prev_img = np_img
    np_img = np.float32(PIL.Image.open(img))
    np_img = cv2.resize(np_img, dsize=(x, y), interpolation=cv2.INTER_CUBIC)
    frame = cv2.resize(frame, dsize=(x, y), interpolation=cv2.INTER_CUBIC)
    
    frame_flow_masked, background_masked = get_opflow_image(np_prev_img, frame, np_img, blendflow, blendstatic)
    frame = frame_flow_masked + background_masked
    frame = dream.deepdream(frame, text_prompts, [x, y], iter_n=iter_n, init_weight=frame_weight, step_size=step_size, image_prompts=prev_frame, image_prompt_weight=previous_frame_weight)
    
    save_img(frame, 'output/%04d.jpg'%i)

    sys.stdout.write(f'Iteration {i+1}\n')
    sys.stdout.flush()


mp4_fourcc = cv2.VideoWriter_fourcc(*'MP4V')
out = cv2.VideoWriter(output_vid_path, mp4_fourcc, fps, (w, h))
filelist = sorted(glob('output/*.jpg'))

for i in trange(len(filelist), desc="Generating Video"):
    img = cv2.imread(filelist[i])
    img = cv2.resize(img, dsize=(w, h), interpolation=cv2.INTER_CUBIC)
    out.write(img)
out.release()
