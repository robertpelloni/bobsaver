# Pixray Panorama demo
# http://localhost:8888/notebooks/Desktop/Pixray_Panorama_Demo.ipynb

"""
from IPython.utils import io
with io.capture_output() as captured:
  # On 2021/10/08, Colab updated its default PyTorch installation to a version that causes
  # problems with diffvg. So, first thing, let's roll back to the older version:
  get_ipython().system('pip install torch==1.9.0+cu102 torchvision==0.10.0+cu102 -f https://download.pytorch.org/whl/torch/ -f https://download.pytorch.org/whl/torchvision/')

  get_ipython().system('git clone https://github.com/openai/CLIP')
  # !pip install taming-transformers
  get_ipython().system('git clone https://github.com/CompVis/taming-transformers.git')
  get_ipython().system('rm -Rf pixray')
  get_ipython().system('git clone https://github.com/dribnet/pixray')
  get_ipython().system('pip install ftfy regex tqdm omegaconf pytorch-lightning')
  get_ipython().system('pip install kornia')
  get_ipython().system('pip install imageio-ffmpeg   ')
  get_ipython().system('pip install einops')
  get_ipython().system('pip install torch-optimizer')
  get_ipython().system('pip install easydict')
  get_ipython().system('pip install braceexpand')
  get_ipython().system('pip install git+https://github.com/pvigier/perlin-numpy')

  # ClipDraw deps
  get_ipython().system('pip install svgwrite')
  get_ipython().system('pip install svgpathtools')
  get_ipython().system('pip install cssutils')
  get_ipython().system('pip install numba')
  get_ipython().system('pip install torch-tools')
  get_ipython().system('pip install visdom')

  get_ipython().system('git clone https://github.com/BachiLi/diffvg')
  get_ipython().run_line_magic('cd', 'diffvg')
  # !ls
  get_ipython().system('git submodule update --init --recursive')
  get_ipython().system('python setup.py install')
  get_ipython().run_line_magic('cd', '..')

output.clear()
"""

import sys

sys.path.append("./pixray")
sys.path.append('./taming-transformers')
sys.path.append('./diffvg')
sys.path.append('./diffvg/pydiffvg')



import shutil
import numpy as np
from PIL import ImageFile, Image, PngImagePlugin


def make_seed_img(from_fn, to_fn='cur_seed.png', delete_pixels = 20, shift_pixels = 240):
    in_img = Image.open(from_fn)
    seed_img_array = np.random.rand(in_img.size[1],in_img.size[0],3) * 255
    seed_img = Image.fromarray(seed_img_array.astype('uint8')).convert('RGB')
    # mask_img = Image.new(mode="RGB", size=(s_x, s_y), color=(0, 0, 0))
    seed_img.paste(in_img.crop((shift_pixels,0,in_img.size[0]-delete_pixels,in_img.size[1])), (0,0))
    seed_img.save(to_fn)
    # seed_img.crop((shift_pixels,0,seed_img.size[0]-delete_pixels,seed_img.size[1]))

result_msg = "setup complete"
import IPython
import os

#@title First Frame Settings

#@markdown Enter a description of what you want to draw - I usually add #pixelart to the prompt.
#@markdown If PixelDraw is not used, it will use VQGAN instead.
#@markdown <br>

#prompts = "snowstorm above the cityscape #pixelart #8bit" #@param {type:"string"}
prompts = "Sydney Australia skyline #pixelart #8bit" #@param {type:"string"}

aspect = "widescreen" ##param ["widescreen", "square"]

do_pixel = True #@param {type:"boolean"}

#@markdown Specify the desired palette ("" for default), here's a few examples:
#@markdown * red     (16 color black to red ramp)
#@markdown * rust\8  (8 color black to rust ramp)
#@markdown * black->red->white (16 color black/red/white ramp)
#@markdown * [#000000, #ff0000, #ffff00, #000080] (four colors)
#@markdown * red->yellow;[black]     (16 colors from ramp and also black)
#@markdown * Named colors can be anything in <a target=”_blank” href="https://xkcd.com/color/rgb/">this lookup table</a>

use_palette = "[#000000, #071008, #0e2011, #153019, #1c4022, #23502a, #2a6033, #31703b, #388044, #3f8f4c, #469f54, #4daf5d, #54bf65, #5bcf6e, #62df76, #69ef7f];black->white" #@param {type:"string"}
#@markdown Use this flag to encourage smoothess:
smoothness = True #@param {type:"boolean"} 

#@markdown Use this flag to encourage color saturation (use it against color fading):
saturation = True #@param {type:"boolean"} 

#@markdown When you have the settings you want, press the play button on the left.
#@markdown The system will save these and start generating images below.

#@markdown When that is done you can change these
#@markdown settings and see if you get different results. Or if you get
#@markdown impatient, just select "Runtime -> Interrupt Execution".
#@markdown Note that the first time you run it may take a bit longer
#@markdown as nessary files are downloaded.


#@markdown
#@markdown *Advanced: you can also edit this cell and add add additional
#@markdown settings, combining settings from different notebooks.*


# Simple setup
import pixray

# these are good settings for pixeldraw
pixray.reset_settings()
pixray.add_settings(prompts=prompts, aspect=aspect)
pixray.add_settings(quality="better", scale=2.5)
pixray.add_settings(display_clear=True)

if do_pixel:
  pixray.add_settings(drawer="pixel")

# palette = None
if use_palette and use_palette!='None':
  pixray.add_settings(target_palette=use_palette)

if smoothness and smoothness!='None':
  pixray.add_settings(smoothness=2.0, smoothness_type='log')

if saturation:
  pixray.add_settings(saturation=1.0)

pixray.add_settings(noise_prompt_seeds=[1,2,3])

#### YOU CAN ADD YOUR OWN CUSTOM SETTING HERE ####
# this is the example of how to run longer with less frequent display
# pixray.add_settings(iterations=500, display_every=50)

settings = pixray.apply_settings()
pixray.do_init(settings)
pixray.do_run(settings)

shutil.copy('./output.png', './very_first_frame.png')


# In[6]:


#@title Make sure you like the first frame, then start this cell to generate all other frames:

shutil.copy('./very_first_frame.png', f'./frame_{0:03d}.png')

delete_from_right_pixels = 20 #@param
shift_pixels = 240 #@param
half_frames2generate = 5 #@param


for frame in range(half_frames2generate):
    shutil.copy('./output.png', f'./frame_{frame:03d}.png')
    make_seed_img(f'./frame_{frame:03d}.png')
    pixray.reset_settings()
    pixray.add_settings(prompts=prompts, aspect=aspect)
    pixray.add_settings(quality="better", scale=2.5)
    pixray.add_settings(display_clear=True)
    pixray.add_settings(init_image='./cur_seed.png')
    if do_pixel:
      pixray.add_settings(drawer="pixel")
    # palette = None
    if use_palette and use_palette!='None':
      pixray.add_settings(target_palette=use_palette)
    if smoothness and smoothness!='None':
      pixray.add_settings(smoothness=2.0, smoothness_type='log')
    if saturation:
      pixray.add_settings(saturation=1.0)
    pixray.add_settings(noise_prompt_seeds=[1,2,3])  

    settings = pixray.apply_settings()
    pixray.do_init(settings)
    pixray.do_run(settings)

    # shutil.copy('./output.png', f'./frame_{frame+1:03d}.png')


# In[7]:


#@title Blend frames into the single image

from glob import glob
# these values are okay for the widescreen aspect only
sidex = 500
sidey = 280


frames = []
for fn in glob('frame_*.png'):
    frames.append( fn )

pano_img = Image.new(mode="RGB", 
                     size=(sidex+shift_pixels*len(frames)-(sidex-shift_pixels), 
                           sidey+0*len(frames)), color=(255, 255, 255))

for idx, fr in enumerate(frames):
    fr_img = Image.open(fr)
    fr_img = fr_img.convert('RGB')
    if not idx:
        pano_img.paste( fr_img , (idx*shift_pixels, 0))
    else:
        pano_img.paste( fr_img.crop((shift_pixels,0,sidex,sidey)), ((idx+1)*shift_pixels, 0))
        for x in range(shift_pixels):
            w = x/shift_pixels
            for y in range(sidey):
                int_c = np.array(pano_img.getpixel((idx*shift_pixels+x,y)))*(1-w)+                        np.array( fr_img.getpixel((x,y)) ) *(w)
                int_c = int_c.astype(int).tolist()
                pano_img.putpixel((idx*shift_pixels+x,y),tuple(int_c))
pano_img.save('pano.png')
pano_img


# In[10]:


#@title Compile the resulting movie clip

from tqdm.notebook import tqdm
from subprocess import Popen, PIPE

out_width = 500 #@param
speed = 3 #@param
fps = 25 #@param

pano_img =  Image.open('pano.png')
pano_img.size


frames = []
for idx, x in enumerate( range(0,pano_img.size[0]-out_width,speed) ):
    frames.append( pano_img.crop( (x,0,x+out_width,pano_img.size[1]) ) )


p = Popen(['ffmpeg',
           '-y',
           '-f', 'image2pipe',
           '-vcodec', 'png',
           '-r', str(fps),
           '-i',
           '-',
           '-vcodec', 'libx264',
           '-r', str(fps),
           '-pix_fmt', 'yuv420p',
           '-crf', '17',
           '-preset', 'veryslow',
           'pano.mp4'], stdin=PIPE)

for im in tqdm(frames):
    im.save(p.stdin, 'png')
p.stdin.close()
p.wait()

from IPython.display import HTML
from base64 import b64encode
mp4 = open('pano.mp4','rb').read()
data_url = "data:video/mp4;base64," + b64encode(mp4).decode()
HTML("""
<video width=400 controls>
      <source src="%s" type="video/mp4">
</video>
""" % data_url)

