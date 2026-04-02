# Halluzinator 0.4.ipynb
# Original file is located at https://colab.research.google.com/drive/1AHnwCTTddvvv49mhQMa6bXv5h7Z9SLcV

import sys
import cv2
import os
import numpy as np
import re
import torch
from torchvision import transforms
import gc
import json
from pprint import pprint
from base64 import b64encode, b64decode
import PIL
import copy
import random
import imageio
import ipywidgets as ipy
import sys
import glob
import math
from PIL import Image


def custom_to_pil(x):
  x = x.detach().cpu()
  x = torch.clamp(x, -1., 1.)
  x = (x + 1.)/2.
  x = x.permute(1,2,0).numpy()
  x = (255*x).astype(np.uint8)
  x = Image.fromarray(x)
  if not x.mode == "RGB":
    x = x.convert("RGB")
  return x


def img2tensor(img_path):
  imgfile = imageio.imread(img_path)
  im = torch.tensor(imgfile).unsqueeze(0).permute(0, 3, 1, 2)[:,:3]
  return im
 
def numpy2tensor(imgArray):
  im = torch.unsqueeze(transforms.ToTensor()(imgArray), 0)   
  return im  

def img2t(img_path):
  if img_path == '':
    return None
  imgfile = PIL.Image.open(img_path)
  return numpy2tensor(imgfile)

#options=['off', 'warp','zoom_in', 'zoom_out', 'pan_left', 'pan_right','pan_up','pan_down','rotate']

"""
r  = rortation amount
z  = zoom amount
px = pan x amount
py = pan y amount
w  = warp amount
"""
def do_image_warping(img,r,z,px,py,w):
    #print('Inside do_image_warping')
    
    if r !=0:
        img = rotate_img(img,r)  
    
    if z != 0:
        if z>0:
            img = zoom_in(img,z) 
        else:
            img = zoom_out(img,-z) 
    
    if px != 0:
        if px>0:
            img = pan_right(img,px) 
        else:
            img = pan_left(img,-px) 

    if py != 0:
        if py>0:
            img = pan_up(img,py) 
        else:
            img = pan_down(img,-py) 
    
    if w != 0:
        img = warp(img,w)
    
    return img
  
def rotate_img(img,inc):
  h,w = img.shape[:2]
  padding = int(max(h,w)/4) 
  PIL_img = PIL.Image.fromarray(img.astype('uint8'), 'RGB')
  img = transforms.functional.pad(img=PIL_img, padding=padding, padding_mode='reflect')
  img = transforms.functional.rotate(img, -inc, resample=PIL.Image.BILINEAR)
  img = transforms.functional.crop(img, padding, padding, h, w)
  return np.asarray(img)

def zoom_in(img,inc):
  h,w = img.shape[:2]
  img = cv2.resize(img, (w+inc, h+inc), cv2.INTER_LANCZOS4)
  d = inc//2
  cropped_img = img[d:h+d, d:w+d]
  return cropped_img
  
def zoom_out(img,inc):  
  h,w = img.shape[:2]
  bdr = cv2.copyMakeBorder(img,inc//2,inc//2,inc//2,inc//2,cv2.BORDER_REPLICATE)
  return cv2.resize(bdr, dsize=(w,h), interpolation=cv2.INTER_CUBIC)

def pan_up(img,inc):
  h,w = img.shape[:2]
  border = cv2.copyMakeBorder(img,inc,0,0,0,cv2.BORDER_REPLICATE)
  img_crop = border[0:h, 0:w]
  return img_crop

def pan_down(img,inc):
  h,w = img.shape[:2]
  border = cv2.copyMakeBorder(img,0,inc,0,0,cv2.BORDER_REPLICATE)
  img_crop = border[inc:h+inc, 0:w]
  return img_crop

def pan_left(img,inc):
  h,w = img.shape[:2]
  border = cv2.copyMakeBorder(img,0,0,inc,0,cv2.BORDER_REPLICATE)
  img_crop = border[0:h, 0:w]
  return img_crop

def pan_right(img,inc):
  h,w = img.shape[:2]
  border = cv2.copyMakeBorder(img,0,0,0,inc,cv2.BORDER_REPLICATE)
  img_crop = border[0:h, inc:w+inc]
  return img_crop

def warp(img,inc):  
  h,w = img.shape[:2]
  pts1 = np.float32([[0, 0], [inc, h - inc], [w - inc, h - inc], [w, 0]])
  pts2 = np.float32([[0, 0], [0, h], [w, h], [w, 0]])
  matrix = cv2.getPerspectiveTransform(pts1, pts2)
  result = cv2.warpPerspective(img, matrix, (w, h), borderMode=cv2.BORDER_REPLICATE)
  return result  
