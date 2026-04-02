import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from IPython.display import Video
from deforum_kandinsky import KandinskyV22Img2ImgPipeline, DeforumKandinsky
from diffusers import KandinskyV22PriorPipeline
from transformers import CLIPVisionModelWithProjection
from diffusers.models import UNet2DConditionModel
import imageio.v2 as iio
from PIL import Image
import numpy as np
import torch
import datetime
from tqdm.notebook import tqdm
import ipywidgets as widgets
from IPython import display
import random
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_version", type=float)
    parser.add_argument("--height", type=int)
    parser.add_argument("--width", type=int)
    parser.add_argument("--fps", type=int)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--output", type=str)
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

random.seed(args2.seed)

#  create video from generated frames
def frames2video(frames, output_path="video.mp4", fps=24, display=False):
    writer = iio.get_writer(output_path, fps=fps)
    for frame in tqdm(frames):
        writer.append_data(np.array(frame))
    writer.close()
    if display:
        display.Video(url=output_path)
        
        from diffusers import KandinskyV22PriorPipeline
from deforum_kandinsky import (
    KandinskyV22Img2ImgPipeline, 
    DeforumKandinsky,  
    KandinskyImg2ImgPipeline, 
    DeforumKandinsky
)

# load models
model_version = args2.model_version
device = "cuda"

if model_version == 2.2:
    image_encoder = CLIPVisionModelWithProjection.from_pretrained(
        'kandinsky-community/kandinsky-2-2-prior', 
        subfolder='image_encoder'
        ).to(torch.float16).to(device)

    unet = UNet2DConditionModel.from_pretrained(
        'kandinsky-community/kandinsky-2-2-decoder', 
        subfolder='unet'
        ).to(torch.float16).to(device)

    prior = KandinskyV22PriorPipeline.from_pretrained(
        'kandinsky-community/kandinsky-2-2-prior', 
        image_encoder=image_encoder, 
        torch_dtype=torch.float16
        ).to(device)
    decoder = KandinskyV22Img2ImgPipeline.from_pretrained(
        'kandinsky-community/kandinsky-2-2-decoder', 
        unet=unet, 
        torch_dtype=torch.float16
        ).to(device)

elif model_version == 2.1: 

    image_encoder = CLIPVisionModelWithProjection.from_pretrained(
        "kandinsky-community/kandinsky-2-1-prior", 
        subfolder='image_encoder',
        torch_dtype=torch.float16
        ).to(device)
    unet = UNet2DConditionModel.from_pretrained(
        "kandinsky-community/kandinsky-2-1", 
        subfolder='unet',
        torch_dtype=torch.float16
        ).to(device)
    prior = KandinskyPriorPipeline.from_pretrained(
        "kandinsky-community/kandinsky-2-1-prior", 
        torch_dtype=torch.float16
        ).to(device)
    decoder = KandinskyImg2ImgPipeline.from_pretrained(
        'kandinsky-community/kandinsky-2-1', 
        unet=unet, 
        torch_dtype=torch.float16
        ).to(device)
        
deforum = DeforumKandinsky(
    prior=prior,
    decoder_img2img=decoder,
    device='cuda'
)

animation = deforum(
#VOC START - DO NOT DELETE
#VOC FINISH - DO NOT DELETE
    H=args2.height,
    W=args2.width,
    fps=args2.fps,
    save_samples=False,
)

frames = []

out = widgets.Output()
pbar = tqdm(animation, total=len(deforum))
#display.display(out)

with out:
    for index, item in enumerate(pbar):
        sys.stdout.flush()
        sys.stdout.write(f"Frame {index}")
        sys.stdout.write("\n")
        sys.stdout.flush()
        frame = item["image"]
        frames.append(frame)
        #display.clear_output(wait=True) 
        #display.display(frame)
        for key, value in item.items():
            if not isinstance(value, (np.ndarray, torch.Tensor, Image.Image)):
                print(f"{key}: {value}")
            


#display.clear_output(wait=True) 
frames2video(frames, args2.output, fps=args2.fps)
#display.Video(url="output_2_2.mp4")
