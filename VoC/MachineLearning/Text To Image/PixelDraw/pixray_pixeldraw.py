# Pixray PixelDraw
# Original file is located at https://colab.research.google.com/github/dribnet/clipit/blob/master/demos/PixelDrawer.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append("./pixray")
sys.path.append('./taming-transformers')
sys.path.append('./diffvg')
sys.path.append('./diffvg/pydiffvg')

import pixray
import argparse

quality = "normal" #@param ["draft", "normal", "better", "best"]

aspect="square"

prompts = "Sydney Skyline. #pixelart" #@param {type:"string"}

use = "pixel" #@param ["vqgan", "pixel", "clipdraw"]

# these are good settings for pixeldraw
pixray.reset_settings()
pixray.add_settings(prompts=prompts, aspect=aspect)
pixray.add_settings(quality="better", scale=2.5)
pixray.add_settings(drawer=use)
pixray.add_settings(display_clear=True)
pixray.add_settings(output="Progress.png")

#### YOU CAN ADD YOUR OWN CUSTOM SETTING HERE ####
# this is the example of how to run longer with less frequent display
# pixray.add_settings(iterations=500, display_every=50)

sys.stdout.write("Applying settings ...\n")
sys.stdout.flush()

settings = pixray.apply_settings()

sys.stdout.write("Initializing ...\n")
sys.stdout.flush()

pixray.do_init(settings)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

pixray.do_run(settings)

