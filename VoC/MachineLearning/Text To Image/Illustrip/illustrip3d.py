# IllusTrip3D.ipynb
# Original file is located at https://colab.research.google.com/github/eps696/aphantasia/blob/master/IllusTrip3D.ipynb

"""
required model
https://drive.google.com/uc?id=1lvyZZbC9NLcS8a__YPcUP7rDiIpbRpoF
OR
https://www.dropbox.com/s/r1zyrfypixviwa8/AdaBins_nyu.pt
save to
./pretrained/AdaBins_nyu.pt
"""

work_dir = './'

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./clip')
sys.path.append('./aphantasia')
sys.path.append('./AdaBins')
sys.path.append('./pytorch_wavelets')
sys.path.append('./pytorch_wavelets/pytorch_wavelets')

import os
import io
import time
import math
import random
import imageio
import numpy as np
import PIL
from base64 import b64encode
import shutil
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision
from torchvision import transforms as T
from torch.autograd import Variable
from IPython.display import HTML, Image, display, clear_output
from IPython.core.interactiveshell import InteractiveShell
InteractiveShell.ast_node_interactivity = "all"
import ipywidgets as ipy
from CLIP import clip
from sentence_transformers import SentenceTransformer
import kornia
import lpips
from clip_fft import to_valid_rgb, fft_image, rfft2d_freqs, img2fft, pixel_image, un_rgb
from utils import basename, file_list, img_list, img_read, txt_clean, plot_text, old_torch
from utils import slice_imgs, derivat, pad_up_to, slerp, checkout, sim_func, latent_anima
import transforms
from progress_bar import ProgressIPy as ProgressBar
import cv2
import matplotlib.pyplot as plt
import argparse



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')

  parser.add_argument('--zoom', type=float, help='Zoom.')
  parser.add_argument('--shift', type=float, help='Shift.')
  parser.add_argument('--rotate', type=float, help='Rotate.')
  parser.add_argument('--colors', type=float, help='Colors.')
  parser.add_argument('--contrast', type=float, help='Contrast.')
  parser.add_argument('--sharpness', type=float, help='Sharpness.')
  parser.add_argument('--distort', type=float, help='Distort.')
  parser.add_argument('--samples', type=float, help='Samples.')
  parser.add_argument('--learningrate', type=float, help='Learning rate.')
  args = parser.parse_args()
  return args

args2=parse_args();

if args2.seed is not None:
    sys.stdout.write(f'Setting seed to {args2.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args2.seed)
    import random
    random.seed(args2.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args2.seed)
    torch.cuda.manual_seed(args2.seed)
    torch.cuda.manual_seed_all(args2.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 





#shutil.copy('mask.jpg', work_dir)
depth_mask_file = os.path.join(work_dir, 'mask.jpg')

#clear_output()

def save_img(img, fname=None):
  img = np.array(img)[:,:,:]
  img = np.transpose(img, (1,2,0))  
  img = np.clip(img*255, 0, 255).astype(np.uint8)
  if fname is not None:
    imageio.imsave(fname, np.array(img))
    #imageio.imsave('result.jpg', np.array(img))

#@title Load inputs

#@markdown **Content** (either type a text string, or upload a text file):
content = "" #@param {type:"string"}
upload_texts = False #@param {type:"boolean"}

#@markdown **Style** (either type a text string, or upload a text file):
style = "" #@param {type:"string"}
upload_styles = False #@param {type:"boolean"}

#@markdown For non-English languages use Google translation:
translate = False #@param {type:"boolean"}

texts = ['fire','water','lava','snow','fire']
styles = ['oil painting','oil painting','oil painting','oil painting','oil painting']

resume = False #@param {type:"boolean"}
if resume:
  print('Upload file to resume from')
  resumed = files.upload()
  resumed_filename = list(resumed)[0]
  resumed_bytes = list(resumed.values())[0]

tempdir = '.\\'

using_GDrive = False#@param{type:"boolean"}
if using_GDrive:
  import os
  from google.colab import drive

  if not os.path.isdir('/G/MyDrive'): 
      drive.mount('/G', force_remount=True)
  gdir = '/G/MyDrive'

  tempdir = os.path.join(gdir, 'illustrip', workname)
  os.makedirs(tempdir, exist_ok=True)
  print('main dir', tempdir)

#@title Main settings

sideX = args2.sizex #@param {type:"integer"}
sideY = args2.sizey #@param {type:"integer"}
steps = args2.iterations #@param {type:"integer"}
frame_step = 100 #100#@param {type:"integer"}
#@markdown > Config
method = 'RGB' #@param ['FFT', 'RGB']
model = 'ViT-B/32' #@param ['ViT-B/16', 'ViT-B/32', 'RN101', 'RN50x16', 'RN50x4', 'RN50']

# Default settings
if method == 'RGB':
  align = 'overscan'
  colors = 2
  contrast = 1.2
  sharpness = -1.
  aug_noise = 0.
  smooth = False
else:
  align = 'uniform'
  colors = 1.8
  contrast = 1.1
  sharpness = 1.
  aug_noise = 2.
  smooth = True

"""
interpolate_topics = True
style_power = 1.
samples = 200
save_step = 1
learning_rate = 1.
aug_transform = 'custom'
similarity_function = 'cossim'
macro = 0.4
enforce = 0.
expand = 0.
zoom = 0.012
shift = 10
rotate = 0.8
distort = 0.3
animate_them = True
"""

sample_decrease = 1.
DepthStrength = 0.

print(' loading CLIP model..')
model_clip, _ = clip.load(model, jit=old_torch())
modsize = model_clip.visual.input_resolution
xmem = {'ViT-B/16':0.25, 'RN50':0.5, 'RN50x4':0.16, 'RN50x16':0.06, 'RN101':0.33}
if model in xmem.keys():
  sample_decrease *= xmem[model]

clear_output()
print(' using CLIP model', model)


#@title Run this cell to override settings, if needed
#@markdown [to roll back defaults, run "Main settings" cell again]

style_power = 1. #@param {type:"number"}
overscan = True #@param {type:"boolean"}
align = 'overscan' if overscan else 'uniform'
interpolate_topics = True #@param {type:"boolean"}

#@markdown > Look
colors = args2.colors #2 #@param {type:"number"}
contrast = args2.contrast #1.2 #@param {type:"number"}
sharpness = args2.sharpness #0. #@param {type:"number"}

#@markdown > Training
samples = args2.samples #200 #@param {type:"integer"}
save_step = args2.update #@param {type:"integer"}
learning_rate = args2.learningrate #1. #@param {type:"number"}

#@markdown > Tricks
aug_transform = 'custom' #@param ['elastic', 'custom', 'none']
aug_noise = 0. #@param {type:"number"}
macro = 0.4 #@param {type:"number"}
enforce = 0. #@param {type:"number"}
expand = 0. #@param {type:"number"}
similarity_function = 'cossim' #@param ['cossim', 'spherical', 'mixed', 'angular', 'dot']

#@markdown > Motion
zoom = args2.zoom #0.012 #@param {type:"number"}
shift = args2.shift #10 #@param {type:"number"}
rotate = args2.rotate #0.8 #@param {type:"number"}
distort = args2.distort #0.3 #@param {type:"number"}
animate_them = True #@param {type:"boolean"}

#smooth = True #@param {type:"boolean"}
#if method == 'RGB': smooth = False

"""`style_power` controls the strength of the style descriptions, comparing to the main input.  
`overscan` provides better frame coverage (needed for RGB method).  
`interpolate_topics` changes the subjects smoothly, otherwise they're switched by cut, making sharper transitions.  

Decrease **`samples`** if you face OOM (it's the main RAM eater), or just to speed up the process (with the cost of quality).  
`save_step` defines, how many optimization steps are taken between saved frames. Set it >1 for stronger image processing.   

Experimental tricks:  
`aug_transform` applies some augmentations, which quite radically change the output of this method (and slow down the process). Try yourself to see which is good for your case. `aug_noise` augmentation [FFT only!] seems to enhance optimization with transforms.  
`macro` boosts bigger forms.  
`enforce` adds more details by enforcing similarity between two parallel samples.  
`expand` boosts diversity (up to irrelevant) by enforcing difference between prev/next samples.  

Motion section:
`shift` is in pixels, `rotate` in degrees. The values will be used as limits, if you mark `animate_them`.  

`smooth` reduces blinking, but induces motion blur with subtle screen-fixed patterns (valid only for FFT method, disabled for RGB).

## Add 3D depth [optional]
"""

# Commented out IPython magic to ensure Python compatibility.
### deKxi:: This whole cell contains most of whats needed, 
# with just a few changes to hook it up via frame_transform 
# (also glob_step now as global var)

# I highly recommend performing the frame transformations and depth *after* saving,
# (or just the depth warp if you prefer to keep the other affines as they are)
# from my testing it reduces any noticeable stretching and allows the new areas
# revealed from the changed perspective to be filled/detailed 

# pretrained models: Nyu is much better but Kitti is an option too
depth_model = 'nyu' # @ param ["nyu","kitti"]
workdir_depth = "/content"
DepthStrength = 0.01 #@param{type:"number"}
MaskBlurAmt = 33 #@param{type:"integer"}

"""
if DepthStrength > 0:
  depthdir = os.path.join(tempdir, 'depth')
  os.makedirs(depthdir, exist_ok=True)
  print('depth dir', depthdir)
"""

#@markdown NB: depth computing may take up to ~3x more time. Read the comments inside for more info. 

#@markdown Courtesy of [deKxi](https://twitter.com/deKxi)

# Some useful misc funcs used
ToImage  = T.ToPILImage()

def numpy2tensor(imgArray):
  im = torch.unsqueeze(torchvision.transforms.ToTensor()(imgArray), 0)
  return im

def triangle_blur(x, kernel_size=3, pow=1.0):
  padding = (kernel_size-1) // 2
  b,c,h,w = x.shape
  kernel = torch.linspace(-1,1,kernel_size+2)[1:-1].abs().neg().add(1).reshape(1,1,1,kernel_size).pow(pow).cuda()
  kernel = kernel / kernel.sum()
  x = x.reshape(b*c,1,h,w)
  x = F.pad(x, (padding,padding,padding,padding), mode='reflect')
  x = F.conv2d(x, kernel)
  x = F.conv2d(x, kernel.permute(0,1,3,2))
  x = x.reshape(b,c,h,w)
  return x


############ Mask is for blending multi-crop depth 
global mask_blurred

#masksize = (830, 500) # I've hardcoded this but it doesn't have to be this exact number, this is just the max for what works at 16:9 for each crop
masksize = (sideX, sideY) # now set based on image size
mask = cv2.imread(depth_mask_file, cv2.IMREAD_GRAYSCALE)
mask = cv2.resize(mask, masksize)
ch = sideY//2
cw = sideX//2
mask_blur  = cv2.GaussianBlur(mask,(MaskBlurAmt,MaskBlurAmt),0)
mask_blurred = cv2.resize(mask_blur,(cw,ch)) / 255.
############

from infer import InferenceHelper
infer_helper = InferenceHelper(dataset='nyu')
# You can adjust AdaBins' internal depth max and min here, but unsure if it makes a huge difference - haven't tested it too much yet
#infer_helper.max_depth = infer_helper.max_depth * 50
#infer_helper.min_depth = infer_helper.min_depth * 1

# %cd /content/aphantasia/
def depthwarp(img, strength=0, rescale=0, midpoint=0.5, depth_origin=(0,0), clip_range=0, save_depth=False, multicrop=True):
  if strength==0: return img
  img2 = img.clone().detach() # Most of the pre-inference operations will take place on a dummy cloned tensor for simplicity sake 
  
  # Blurring first can somewhat mitigate the inherent noise from pixelgen method. Feel free to change these values if the depthmap is unsatisfactory
  img2 = torch.lerp(img2, triangle_blur((img2), 5, 2), 0.5)

  _, _, H, W = img2.shape
  # This will define the centre/origin point for the depth extrusion
  centre = torch.as_tensor([depth_origin[0],depth_origin[1]]).cpu()

  # Converting the tensor to image in order to perform inference, probably a cleaner way to do this though as this was quick and dirty
  par, imag, _ = pixel_image([1,3,H,W], resume=img2)
  img2 = to_valid_rgb(imag, colors=colors)()
  img2 = img2.detach().cpu().numpy()[0]
  img2 = (np.transpose(img2, (1,2,0))) # convert image back to Height,Width,Channels
  img2 = np.clip(img2*255, 0, 255).astype(np.uint8)
  image = ToImage(img2)
  del img2

  # Resize down for inference
  if H < W: # 500p on either dimension was the limit I found for AdaBins
    r = 500 / float(H)
    dim = (int(W * r), 500)
  else:
    r = 500 / float(W)
    dim = (500, int(H * r))
  image = image.resize(dim,3)

  bin_centres, predicted_depth = infer_helper.predict_pil(image)   
  
  # Resize back to original before (optionally) adding the cropped versions
  predicted_depth = cv2.resize(predicted_depth[0][0],(W,H))

  if multicrop: 
    # This code is very jank as I threw it together as a quick proof-of-concept, and it miraculously worked 
    # There's very likely to be some improvements that can be made

    clone = predicted_depth.copy()
    # Splitting the image into separate crops, probably inefficiently
    TL = torchvision.transforms.functional.crop(image.resize((H,W),3), top=0, left=0, height=cw, width=ch).resize(dim,3)
    TR = torchvision.transforms.functional.crop(image.resize((H,W),3), top=0, left=ch, height=cw, width=ch).resize(dim,3)
    BL = torchvision.transforms.functional.crop(image.resize((H,W),3), top=cw, left=0, height=cw, width=ch).resize(dim,3)
    BR = torchvision.transforms.functional.crop(image.resize((H,W),3), top=cw, left=ch, height=cw, width=ch).resize(dim,3)

    # Inference on crops
    _, predicted_TL = infer_helper.predict_pil(TL)
    _, predicted_TR = infer_helper.predict_pil(TR)
    _, predicted_BL = infer_helper.predict_pil(BL)
    _, predicted_BR = infer_helper.predict_pil(BR)

    # Rescale will increase per object depth difference, but may cause more depth fluctuations if set too high
    # This likely results in the depth map being less "accurate" to any real world units.. not that it was particularly in the first place lol
    if rescale != 0:
      # Histogram equalize requires a range of 0-255, but I'm recombining later in 0-1 hence this mess
      TL = cv2.addWeighted(cv2.equalizeHist(predicted_TL.astype(np.uint8) * 255) / 255., 1-rescale, 
                      predicted_TL.astype(np.uint8),rescale,0)
      TR = cv2.addWeighted(cv2.equalizeHist(predicted_TR.astype(np.uint8) * 255) / 255., 1-rescale, 
                      predicted_TR.astype(np.uint8),rescale,0)
      BL = cv2.addWeighted(cv2.equalizeHist(predicted_BL.astype(np.uint8) * 255) / 255., 1-rescale, 
                      predicted_BL.astype(np.uint8),rescale,0)
      BR = cv2.addWeighted(cv2.equalizeHist(predicted_BR.astype(np.uint8) * 255) / 255., 1-rescale, 
                      predicted_BR.astype(np.uint8),rescale,0)
    # Combining / blending the crops with the original, quite a janky solution admittedly
    TL = clone[0: ch, 0: cw] * (1 - mask_blurred) + cv2.resize(predicted_TL[0][0],(cw,ch)) * mask_blurred
    TR = clone[0: ch, cw: cw+cw] * (1 - mask_blurred) + cv2.resize(predicted_TR[0][0],(cw,ch)) * mask_blurred
    BL = clone[ch: ch+ch, 0: cw] * (1 - mask_blurred) + cv2.resize(predicted_BL[0][0],(cw,ch)) * mask_blurred
    BR = clone[ch: ch+ch, cw: cw+cw] * (1 - mask_blurred) + cv2.resize(predicted_BR[0][0],(cw,ch)) * mask_blurred

    # If you wish to display the depth map for each crop and for the merged version, uncomment these
    #with outpic:
      #plt.imshow(TL, cmap='plasma')
      #plt.show()
      #plt.imshow(TR, cmap='plasma')
      #plt.show()
      #plt.imshow(BL, cmap='plasma')
      #plt.show()
      #plt.imshow(BR, cmap='plasma')
      #plt.show()
    clone[0: ch, 0: cw] = TL
    clone[0: ch, cw: cw+cw] = TR
    clone[ch: ch+ch, 0: cw] = BL
    clone[ch: ch+ch, cw: cw+cw] = BR
    
    # I'm just multiplying the depths currently, but performing a pixel average is possibly a better idea
    predicted_depth = predicted_depth * clone
    predicted_depth /= np.max(predicted_depth) # Renormalize so we don't blow the image out of range

    """
    # Display combined end result
    with outpic: 
      plt.imshow(predicted_depth, cmap='plasma')
      plt.show()
    """
    
  #### Generating a new depth map on each frame can sometimes cause temporal depth fluctuations and "popping". 
  #### This part is just some of my experiments trying to mitigate that
  # Dividing by average
  #ave = np.mean(predicted_depth)
  #predicted_depth = np.true_divide(predicted_depth, ave)
  # Clipping the very end values that often throw the histogram equalize balance off which can mitigate rescales negative effects
  gmin = np.percentile(predicted_depth,0+clip_range)#5
  gmax = np.percentile(predicted_depth,100-clip_range)#8
  clipped = np.clip(predicted_depth, gmin, gmax)

  # Depth is reversed, hence the "1 - x"
  predicted_depth = (1 - ((clipped - gmin) / (gmax - gmin))) * 255

  # Rescaling helps emphasise the depth difference but is less "accurate". The amount gets mixed in via lerp
  if rescale != 0:
    rescaled = numpy2tensor(cv2.equalizeHist(predicted_depth.astype(np.uint8)))
    rescaled = torchvision.transforms.Resize((H,W))(rescaled.cuda())
  
  # Renormalizing again before converting back to tensor
  predicted_depth = predicted_depth.astype(np.uint8) / np.max(predicted_depth.astype(np.uint8))
  dtensor = numpy2tensor(PIL.Image.fromarray(predicted_depth)).cuda()
  #dtensor = torchvision.transforms.Resize((H,W))(dtensor.cuda())

  if rescale != 0: # Mixin amount for rescale, from 0-1
    dtensor = torch.lerp(dtensor, rescaled, rescale)

  if save_depth: # Save depth map out, currently its as its own image but it could just be added as an alpha channel to main image
    global glob_step
    saveddepth = dtensor.detach().clone().cpu().squeeze(0)
    save_img(saveddepth, os.path.join(depthdir, '%05d.jpg' % glob_step))

  dtensor = dtensor.squeeze(0)

  # Building the coordinates, most of this is on CPU since it uses numpy
  xx = torch.linspace(-1, 1, W)
  yy = torch.linspace(-1, 1, H)
  gy, gx = torch.meshgrid(yy, xx)
  grid = torch.stack([gx, gy], dim=-1).cpu()
  d = (centre-grid).cpu()
  # Simple lens distortion that can help mitigate the "stretching" that appears in the periphery
  lens_distortion = torch.sqrt((d**2).sum(axis=-1)).cpu()
  #grid2 = torch.stack([gx, gy], dim=-1)
  d_sum = dtensor[0]

  # Adjust midpoint / move direction
  d_sum = (d_sum - (torch.max(d_sum) * midpoint)).cpu()
  
  # Apply the depth map (and lens distortion) to the grid coordinates
  grid += d * d_sum.unsqueeze(-1) * strength
  del image, bin_centres, predicted_depth

  # Perform the depth warp
  img = torch.nn.functional.grid_sample(img, grid.unsqueeze(0).cuda(), align_corners=True, padding_mode='reflection')
  
  # Reset and perform the lens distortion warp (with reduced strength)
  grid = torch.stack([gx, gy], dim=-1).cpu()
  grid += d * lens_distortion.unsqueeze(-1) * (strength*0.31)
  img = torch.nn.functional.grid_sample(img, grid.unsqueeze(0).cuda(), align_corners=True, padding_mode='reflection')

  return img

"""## Generate"""

#@title Generate

if aug_transform == 'elastic':
  trform_f = transforms.transforms_elastic
  sample_decrease *= 0.95
elif aug_transform == 'custom':
  trform_f = transforms.transforms_custom  
  sample_decrease *= 0.95
else:
  trform_f = transforms.normalize()

if enforce != 0:
  sample_decrease *= 0.5

samples = int(samples * sample_decrease)
print(' using %s method, %d samples' % (method, samples))

if translate:
  translator = Translator()

def enc_text(txt):
  if translate:
    txt = translator.translate(txt, dest='en').text
  emb = model_clip.encode_text(clip.tokenize(txt).cuda()[:77])
  return emb.detach().clone()

# Encode inputs
count = 0 # max count of texts and styles
key_txt_encs = [enc_text(txt) for txt in texts]
count = max(count, len(key_txt_encs))
key_styl_encs = [enc_text(style) for style in styles]
count = max(count, len(key_styl_encs))
assert count > 0, "No inputs found!"

# !rm -rf $tempdir
# os.makedirs(tempdir, exist_ok=True)

opt_steps = steps * save_step # for optimization
glob_steps = count * steps # saving
if glob_steps == frame_step: frame_step = glob_steps // 2 # otherwise no motion

outpic = ipy.Output()
outpic

if method == 'RGB':

  if resume:
    img_in = imageio.imread(resumed_bytes) / 255.
    params_tmp = torch.Tensor(img_in).permute(2,0,1).unsqueeze(0).float().cuda()
    params_tmp = un_rgb(params_tmp, colors=1.)
    sideY, sideX = img_in.shape[0], img_in.shape[1]
  else:
    params_tmp = torch.randn(1, 3, sideY, sideX).cuda() # * 0.01

else: # FFT

  if resume:
    if os.path.splitext(resumed_filename)[1].lower()[1:] in ['jpg','png','tif','bmp']:
      img_in = imageio.imread(resumed_bytes)
      params_tmp = img2fft(img_in, 1.5, 1.) * 2.
    else:
      params_tmp = torch.load(io.BytesIO(resumed_bytes))
      if isinstance(params_tmp, list): params_tmp = params_tmp[0]
    params_tmp = params_tmp.cuda()
    sideY, sideX = params_tmp.shape[2], (params_tmp.shape[3]-1)*2
  else:
    params_shape = [1, 3, sideY, sideX//2+1, 2]
    params_tmp = torch.randn(*params_shape).cuda() * 0.01
  
params_tmp = params_tmp.detach()
# function() = torch.transformation(linear)

# animation
if animate_them:
  if method == 'RGB':
    m_scale = latent_anima([1], glob_steps, frame_step, uniform=True, cubic=True, start_lat=[-0.3])
    m_scale = 1 + (m_scale + 0.3) * zoom # only zoom in
  else:
    m_scale = latent_anima([1], glob_steps, frame_step, uniform=True, cubic=True, start_lat=[0.6])
    m_scale = 1 - (m_scale-0.6) * zoom # ping pong
  m_shift = latent_anima([2], glob_steps, frame_step, uniform=True, cubic=True, start_lat=[0.5,0.5])
  m_angle = latent_anima([1], glob_steps, frame_step, uniform=True, cubic=True, start_lat=[0.5])
  m_shear = latent_anima([1], glob_steps, frame_step, uniform=True, cubic=True, start_lat=[0.5])
  m_shift = (m_shift-0.5) * shift   * abs(m_scale-1.) / zoom
  m_angle = (m_angle-0.5) * rotate  * abs(m_scale-1.) / zoom
  m_shear = (m_shear-0.5) * distort * abs(m_scale-1.) / zoom

def get_encs(encs, num):
  cnt = len(encs)
  if cnt == 0: return []
  enc_1 = encs[min(num,   cnt-1)]
  enc_2 = encs[min(num+1, cnt-1)]
  return slerp(enc_1, enc_2, opt_steps)

def frame_transform(img, size, angle, shift, scale, shear):
  ### deKxi:: Performing depth warp first so the standard affine zoom can remove any funkiness at the edges
  if DepthStrength > 0: 
    # Some quick sine animating, didnt bother hooking them up to latent_anima since I replaced it with a different animation method in my own version
    # d X/Y define the origin point of the depth warp, effectively a "3D pan zoom". Range is '-1 -> 1', with the ends being quite extreme 
    dX = 0.45 * float(math.sin(((glob_step % 114)/114) * math.pi * 2))
    dY = -0.45 * float(math.sin(((glob_step % 166)/166) * math.pi * 2))
    # # Midpointoffset == Movement Direction: 
    #   1 == everything recedes away, 0 == everything moves towards. 
    #   (and oscillating/animating this value is quite visually pleasing IMO)
    midpointOffset = 0.5 + (0.5 * float(math.sin(((glob_step % 70)/70) * math.pi * 2))) 
    depthOrigin = (dX, dY)
    # Perform the warp
    depthAmt = DepthStrength*scale # I like to multiply by zoom amount
    # It might be worth combining shift with dX/Y change as well

    # Rescale combined with clipping end values can improve temporal consistency of depth map
    # but generally speaking the technique itself inherently has that fluctuation due to
    # independently inferred frames. Best combined with a low depth strength to effectively
    # average out the fluctuates

    # ^ Performing a batch of depth inference with some augments and averaging could help
    # alleviate this, but could end up being performance heavy. Was on my test todo list
    # prior to posting publically, but haven't had the time to try it yet
    img = depthwarp(img, strength=depthAmt, rescale=0.5, midpoint=midpointOffset, depth_origin=depthOrigin, clip_range=2, save_depth=False, multicrop=True)

  if old_torch(): # 1.7.1
    img = T.functional.affine(img, angle, shift, scale, shear, fillcolor=0, resample=PIL.Image.BILINEAR)
    img = T.functional.center_crop(img, size)
    img = pad_up_to(img, size)
  else: # 1.8+
    img = T.functional.affine(img, angle, shift, scale, shear, fill=0, interpolation=T.InterpolationMode.BILINEAR)
    img = T.functional.center_crop(img, size) # on 1.8+ also pads
  return img

prev_enc = 0
def process(num):
  global params_tmp, opt_state, params, image_f, optimizer, pbar

  if interpolate_topics:
    txt_encs  = get_encs(key_txt_encs,  num)
    styl_encs = get_encs(key_styl_encs, num)
  else:
    txt_encs  = [key_txt_encs[min(num,  len(key_txt_encs)-1)][0]]  * opt_steps if len(key_txt_encs)  > 0 else []
    styl_encs = [key_styl_encs[min(num, len(key_styl_encs)-1)][0]] * opt_steps if len(key_styl_encs) > 0 else []

  if len(texts)  > 0: print(' ref text: ',  texts[min(num, len(texts)-1)][:80])
  if len(styles) > 0: print(' ref style: ', styles[min(num, len(styles)-1)][:80])

  for ii in range(opt_steps):
    global glob_step ### deKxi:: Making this global since I use it everywhere, but especially for saving the depth images out
    glob_step = num * steps + ii // save_step # saving/transforming
    loss = 0

    txt_enc = txt_encs[ii].unsqueeze(0)

    sys.stdout.write("Iteration {}".format(ii)+"\n")
    sys.stdout.flush()

    # motion: transform frame, reload params
    if ii % save_step == 0:

      # get encoded inputs
      txt_enc  = txt_encs[ii % len(txt_encs)].unsqueeze(0)   if len(txt_encs)  > 0 else None
      styl_enc = styl_encs[ii % len(styl_encs)].unsqueeze(0) if len(styl_encs) > 0 else None
            
      # render test frame
      h, w = sideY, sideX
      
      # transform frame for motion
      scale =       m_scale[glob_step]    if animate_them else 1-zoom
      trans = tuple(m_shift[glob_step])   if animate_them else [0, shift]
      angle =       m_angle[glob_step][0] if animate_them else rotate
      shear =       m_shear[glob_step][0] if animate_them else distort

      if method == 'RGB':
        img_tmp = frame_transform(params_tmp, (h,w), angle, trans, scale, shear)
        params, image_f, _ = pixel_image([1,3,h,w], resume=img_tmp)

      else: # FFT
        if old_torch(): # 1.7.1
          img_tmp = torch.irfft(params_tmp, 2, normalized=True, signal_sizes=(h,w))
          img_tmp = frame_transform(img_tmp, (h,w), angle, trans, scale, shear)
          params_tmp = torch.rfft(img_tmp, 2, normalized=True)
        else: # 1.8+
          if type(params_tmp) is not torch.complex64:
            params_tmp = torch.view_as_complex(params_tmp)
          img_tmp = torch.fft.irfftn(params_tmp, s=(h,w), norm='ortho')
          img_tmp = frame_transform(img_tmp, (h,w), angle, trans, scale, shear)
          params_tmp = torch.fft.rfftn(img_tmp, s=[h,w], dim=[2,3], norm='ortho')
          params_tmp = torch.view_as_real(params_tmp)

        params, image_f, _ = fft_image([1,3,h,w], resume=params_tmp, sd=1.)

      image_f = to_valid_rgb(image_f, colors=colors)
      del img_tmp
      optimizer = torch.optim.Adam(params, learning_rate)
      # optimizer = torch.optim.AdamW(params, learning_rate, weight_decay=0.01, amsgrad=True)
      if smooth is True and num + ii > 0:
        optimizer.load_state_dict(opt_state)

    noise = aug_noise * (torch.rand(1, 1, *params[0].shape[2:4], 1)-0.5).cuda() if aug_noise > 0 else 0.
    img_out = image_f(noise)
    img_sliced = slice_imgs([img_out], samples, modsize, trform_f, align, macro)[0]
    out_enc = model_clip.encode_image(img_sliced)

    if method == 'RGB': # empirical hack
      loss += 1.5 * abs(img_out.mean((2,3)) - 0.45).mean() # fix brightness
      loss += 1.5 * abs(img_out.std((2,3)) - 0.17).sum() # fix contrast

    if txt_enc is not None:
      loss -= sim_func(txt_enc, out_enc, similarity_function)
    if styl_enc is not None:
      loss -= style_power * sim_func(styl_enc, out_enc, similarity_function)
    if sharpness != 0: # mode = scharr|sobel|naive
      loss -= sharpness * derivat(img_out, mode='naive')
      # loss -= sharpness * derivat(img_sliced, mode='scharr')
    if enforce != 0:
      img_sliced = slice_imgs([image_f(noise)], samples, modsize, trform_f, align, macro)[0]
      out_enc2 = model_clip.encode_image(img_sliced)
      loss -= enforce * sim_func(out_enc, out_enc2, similarity_function)
      del out_enc2; torch.cuda.empty_cache()
    if expand > 0:
      global prev_enc
      if ii > 0:
        loss += expand * sim_func(prev_enc, out_enc, similarity_function)
      prev_enc = out_enc.detach().clone()
    del img_out, img_sliced, out_enc; torch.cuda.empty_cache()

    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    
    if ii % save_step == save_step-1:
      params_tmp = params[0].detach().clone()
      if smooth is True:
        opt_state = optimizer.state_dict()

    if ii % save_step == 0:
      sys.stdout.flush()
      sys.stdout.write("Saving progress ...\n")
      sys.stdout.flush()

      with torch.no_grad():
        img = image_f(contrast=contrast).cpu().numpy()[0]

      save_img(img, args2.image_file)
      if args2.frame_dir is not None:
          import os
          file_list = []
          for file in os.listdir(args2.frame_dir):
              if file.startswith("FRA"):
                  if file.endswith("png"):
                      if len(file) == 12:
                          file_list.append(file)
          if file_list:
              last_name = file_list[-1]
              count_value = int(last_name[3:8])+1
              count_string = f"{count_value:05d}"
          else:
              count_string = "00001"
          save_name = args2.frame_dir+"\FRA"+count_string+".png"
          save_img(img,save_name)

      sys.stdout.flush()
      sys.stdout.write("Progress saved\n")
      sys.stdout.flush()

      
  
  params_tmp = params[0].detach().clone()

outpic = ipy.Output()
outpic

pbar = ProgressBar(glob_steps)
for i in range(count):
  process(i)
