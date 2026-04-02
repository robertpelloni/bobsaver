import sys
import cv2
import argparse

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--filename', type=str, help='Movie file to display fps for.')
  args = parser.parse_args()
  return args

args=parse_args();
cap=cv2.VideoCapture(args.filename)
w=int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
h=int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
print(f"{w}x{h}")
