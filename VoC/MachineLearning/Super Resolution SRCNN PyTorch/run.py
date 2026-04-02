import argparse

import numpy as np
import os
import torch
import torchvision.transforms as transforms
from PIL import Image

parser = argparse.ArgumentParser(description='SRCNN run parameters')
parser.add_argument('--model', type=str, required=True)
parser.add_argument('--input_image', type=str, required=True)
parser.add_argument('--output_image', type=str, required=True)
parser.add_argument('--zoom_factor', type=int, required=True)
parser.add_argument('--cuda', action='store_true')
args = parser.parse_args()

img = Image.open(args.input_image).convert('YCbCr')
img = img.resize((int(img.size[0]*args.zoom_factor), int(img.size[1]*args.zoom_factor)), Image.BICUBIC)  # first, we upscale the image via bicubic interpolation
y, cb, cr = img.split()

img_to_tensor = transforms.ToTensor()
input = img_to_tensor(y).view(1, -1, y.size[1], y.size[0])  # we only work with the "Y" channel

device = torch.device("cuda:0" if (torch.cuda.is_available() and args.cuda) else "cpu")
#print(device)
model = torch.load(args.model).to(device)
input = input.to(device)

out = model(input)
out = out.cpu()
out_img_y = out[0].detach().numpy()
out_img_y *= 255.0
out_img_y = out_img_y.clip(0, 255)
out_img_y = Image.fromarray(np.uint8(out_img_y[0]), mode='L')

out_img = Image.merge('YCbCr', [out_img_y, cb, cr]).convert('RGB')  # we merge the output of our network with the upscaled Cb and Cr from before
                                                                    # before converting the result in RGB

#needs to add zoom to the filename part and not the directory
#out_img.save(f"zoomed_{args.image}")
#out_img.save(f"{args.image}")

fname=f"{args.input_image}"
zoom=f"{args.zoom_factor}"
head, tail = os.path.split(fname)
filename, file_extension = os.path.splitext(tail)
#out_img.save(head+'/'+filename+' SRCNN zoomed x'+zoom+file_extension)
out_img.save(args.output_image)
