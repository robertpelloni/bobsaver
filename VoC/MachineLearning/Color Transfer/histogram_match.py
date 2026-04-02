from skimage import data
from skimage import exposure
from skimage.exposure import match_histograms
import cv2
import argparse

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument("--source", required = True, help = "Path to the source image")
  parser.add_argument("--target", required = True,help = "Path to the target image")
  parser.add_argument("--output", help = "Path to the output image (optional)")
  args = parser.parse_args()
  return args

args=parse_args();

img1 = cv2.imread(args.source)
img2 = cv2.imread(args.target)

image = img1
reference = img2
  
matched = match_histograms(image, reference , multichannel=True)
  
cv2.imwrite(args.output,matched)