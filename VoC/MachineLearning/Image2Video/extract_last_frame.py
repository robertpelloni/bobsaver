import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import cv2
import torch
import argparse
import numpy as np
import PIL
from PIL import Image

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=str, help="video to extract last frame from")
    parser.add_argument("--image", type=str, help="image to save last frame to")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading video ...\n")
sys.stdout.flush()

vidcap = cv2.VideoCapture(args2.video)

sys.stdout.write("Getting frame count ...\n")
sys.stdout.flush()

last_frame_num = vidcap.get(cv2.CAP_PROP_FRAME_COUNT) - 1

sys.stdout.write("Seeking to last frame ...\n")
sys.stdout.flush()

vidcap.set(cv2.CAP_PROP_POS_FRAMES, last_frame_num)

sys.stdout.write("Reading last frame ...\n")
sys.stdout.flush()

_, image = vidcap.read()

"""
sys.stdout.write("Auto-coloring last frame ...\n")
sys.stdout.flush()

#histogram equalize colors
b,g,r = cv2.split(image)
b2 = cv2.equalizeHist(b)
g2 = cv2.equalizeHist(g)
r2 = cv2.equalizeHist(r)
image = cv2.merge([b2,g2,r2])

# https://stackoverflow.com/a/55590133/4237309
def unsharp_mask(image, kernel_size=(5, 5), sigma=1.0, amount=1.0, threshold=0):
    #Return a sharpened version of the image, using an unsharp mask.
    blurred = cv2.GaussianBlur(image, kernel_size, sigma)
    sharpened = float(amount + 1) * image - float(amount) * blurred
    sharpened = np.maximum(sharpened, np.zeros(sharpened.shape))
    sharpened = np.minimum(sharpened, 255 * np.ones(sharpened.shape))
    sharpened = sharpened.round().astype(np.uint8)
    if threshold > 0:
        low_contrast_mask = np.absolute(image - blurred) < threshold
        np.copyto(sharpened, image, where=low_contrast_mask)
    return sharpened

sys.stdout.write("Sharpening last frame ...\n")
sys.stdout.flush()
image = unsharp_mask(image,amount=0.3)
"""

sys.stdout.write("Saving last frame ...\n")
sys.stdout.flush()

cv2.imwrite(args2.image,image)

sys.stdout.write("Done\n")
sys.stdout.flush()
