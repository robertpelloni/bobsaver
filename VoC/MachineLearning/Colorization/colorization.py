import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import argparse
import matplotlib.pyplot as plt
from colorizers import *

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

parser = argparse.ArgumentParser()
parser.add_argument('-i','--img_path', type=str, default='nothing.jpg')
parser.add_argument('--use_gpu', action='store_true', help='whether to use GPU')
parser.add_argument('-o','--save_prefix', type=str, default='saved', help='will save into this file with {eccv16.png, siggraph17.png} suffixes')
parser.add_argument('--model', type=str, help='eccv16 or siggraph17')
opt = parser.parse_args()

# load colorizers

sys.stdout.write(f"Loading {opt.model} colorizer model ...\n")
sys.stdout.flush()

if opt.model == 'eccv16':
    colorizer_eccv16 = eccv16(pretrained=True).eval()
    colorizer_eccv16.cuda()
if opt.model == 'siggraph17':
    colorizer_siggraph17 = siggraph17(pretrained=True).eval()
    colorizer_siggraph17.cuda()

# default size to process images is 256x256
# grab L channel in both original ("orig") and resized ("rs") resolutions
img = load_img(opt.img_path)
(tens_l_orig, tens_l_rs) = preprocess_img(img, HW=(256,256))
tens_l_rs = tens_l_rs.cuda()

sys.stdout.write("Colorizing image ...\n")
sys.stdout.flush()

# colorizer outputs 256x256 ab map
# resize and concatenate to original L channel
img_bw = postprocess_tens(tens_l_orig, torch.cat((0*tens_l_orig,0*tens_l_orig),dim=1))

if opt.model == 'eccv16':
    out_img_eccv16 = postprocess_tens(tens_l_orig, colorizer_eccv16(tens_l_rs).cpu())
if opt.model == 'siggraph17':
    out_img_siggraph17 = postprocess_tens(tens_l_orig, colorizer_siggraph17(tens_l_rs).cpu())

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

if opt.model == 'eccv16':
    plt.imsave('result.png', out_img_eccv16)
if opt.model == 'siggraph17':
    plt.imsave('result.png', out_img_siggraph17)

sys.stdout.write("Done\n")
sys.stdout.flush()


"""
plt.imsave('%s_eccv16.png'%opt.save_prefix, out_img_eccv16)
plt.imsave('%s_siggraph17.png'%opt.save_prefix, out_img_siggraph17)

plt.figure(figsize=(12,8))
plt.subplot(2,2,1)
plt.imshow(img)
plt.title('Original')
plt.axis('off')

plt.subplot(2,2,2)
plt.imshow(img_bw)
plt.title('Input')
plt.axis('off')

plt.subplot(2,2,3)
plt.imshow(out_img_eccv16)
plt.title('Output (ECCV 16)')
plt.axis('off')

plt.subplot(2,2,4)
plt.imshow(out_img_siggraph17)
plt.title('Output (SIGGRAPH 17)')
plt.axis('off')
plt.show()
"""