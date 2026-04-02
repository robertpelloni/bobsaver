import sys
import argparse
from PIL import Image
import cv2

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument('--input_video', type=str)
    parser.add_argument('--output_image', type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

cap = cv2.VideoCapture(args2.input_video)
cap.set(cv2.CAP_PROP_POS_FRAMES, cap.get(cv2.CAP_PROP_FRAME_COUNT)-1)
ret, img = cap.read()
cap.release()

rgbimg = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
img = Image.fromarray(rgbimg)

img.save(args2.output_image)

