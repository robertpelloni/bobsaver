import sys
import cv2
import argparse

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--filename', type=str, help='Movie file to display fps for.')
  parser.add_argument('--save_filename', type=str, help='Filename to save fps value to.')
  args = parser.parse_args()
  return args

args=parse_args();
cap=cv2.VideoCapture(args.filename)
framespersecond= int(cap.get(cv2.CAP_PROP_FPS))
print(f"{framespersecond} fps")

if args.save_filename != None:
    with open(args.save_filename, "w") as text_file:
        text_file.write(f"{framespersecond}")
