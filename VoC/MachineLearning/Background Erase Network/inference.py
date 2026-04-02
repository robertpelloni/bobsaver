import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import BEN2
from PIL import Image
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_image", type=str, help="image to remove background from")
    parser.add_argument("--output_directory", type=str, help="dir to write results to")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Init pipeline ...\n")
sys.stdout.flush()

model = BEN2.BEN_Base().to(device).eval() #init pipeline

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

model.loadcheckpoints("./BEN2_Base.pth")

sys.stdout.write("Loading input image ...\n")
sys.stdout.flush()

image = Image.open(args2.input_image)

sys.stdout.write("Removing background ...\n")
sys.stdout.flush()

#mask, foreground = model.inference(image)
foreground = model.inference(image)

sys.stdout.write("Saving result ...\n")
sys.stdout.flush()

#mask.save(f"{args2.output_directory}mask.png")
foreground.save(f"{args2.output_directory}foreground.png")

sys.stdout.write("Done\n")
sys.stdout.flush()

