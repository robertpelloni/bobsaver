import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import scripts.control_utils as cu
import torch
from PIL import Image

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputimage", type=str, help="image to process")
    parser.add_argument("--outputimage", type=str, help="image to save")
    parser.add_argument("--prompt", type=str, help="prompt")
    parser.add_argument("--negativeprompt", type=str, help="negative prompt")
    parser.add_argument("--cannyordepth", type=str, help="canny or depth to specify which method to use")
    parser.add_argument("--model", type=str, help="sdxl or sd21")
    parser.add_argument("--controlscale", type=float, help="control scale")
    parser.add_argument("--ddimsteps", type=int, help="ddim steps")
    parser.add_argument("--cannylow", type=int, help="canny low threshold")
    parser.add_argument("--cannyhigh", type=int, help="canny high threshold")
    parser.add_argument("--size", type=int, help="image x and y sizes")
    parser.add_argument("--numsamples", type=int, help="number of images")
    parser.add_argument("--seed", type=int, help="random seed")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Getting ready ...\n")
sys.stdout.flush()

if args2.model == 'sdxl':
    path_to_config = f'configs/inference/sdxl/sdxl_encD_{args2.cannyordepth}_48m.yaml'
if args2.model == 'sd21':
    path_to_config = f'configs/inference/sd/sd21_encD_{args2.cannyordepth}_14m.yaml'
model = cu.create_model(path_to_config).to('cuda')

image_path = args2.inputimage

canny_high_th = args2.cannyhigh
canny_low_th = args2.cannylow
size = args2.size
num_samples=args2.numsamples

image = cu.get_image(image_path, size=size)
guidancetype=None
if args2.cannyordepth == 'canny':
    edges = cu.get_canny_edges(image, low_th=canny_low_th, high_th=canny_high_th)
    guidancetype=edges
if args2.cannyordepth == 'depth':
    depth = cu.get_midas_depth(image, max_resolution=size)
    guidancetype=depth

sys.stdout.write("Generating image(s) ...\n")
sys.stdout.flush()

if args2.model == 'sdxl':
    samples, controls = cu.get_sdxl_sample(
        guidance=guidancetype,
        ddim_steps=args2.ddimsteps,
        num_samples=num_samples,
        model=model,
        seed=args2.seed,
        shape=[4, size // 8, size // 8],
        control_scale=args2.controlscale,
        prompt=args2.prompt,
        n_prompt=args2.negativeprompt,
    )

if args2.model == 'sd21':
    samples, controls = cu.get_sd_sample(
        guidance=guidancetype,
        ddim_steps=args2.ddimsteps,
        num_samples=num_samples,
        model=model,
        seed=args2.seed,
        shape=[4, size // 8, size // 8],
        control_scale=args2.controlscale,
        prompt=args2.prompt,
        n_prompt=args2.negativeprompt,
    )

sys.stdout.write("Saving output ...\n")
sys.stdout.flush()
Image.fromarray(cu.create_image_grid(samples)).save(args2.outputimage)

sys.stdout.write("Done\n")
sys.stdout.flush()
