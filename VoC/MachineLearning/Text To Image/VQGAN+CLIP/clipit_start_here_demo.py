# CLIPIT Start Here Demo
# Original file is located at https://colab.research.google.com/github/dribnet/clipit/blob/master/demos/Start_Here.ipynb
# https://github.com/dribnet/clipit
# https://github.com/dribnet/clipit/blob/master/demos/README.md

import sys

sys.path.append("clipit")

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os
import argparse
import clipit

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompts', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--aspect', type=str, help='Aspect ratio.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--quality', type=str, help='Quality.')
  parser.add_argument('--scale', type=str, help='Scale.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--vqgan_checkpoint', type=str, help='VQGAN model to load.')
  parser.add_argument('--optimizer', type=str, help='Optimizer.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  args = parser.parse_args()
  return args

args=parse_args();

clipit.reset_settings()
clipit.add_settings(    prompts=args.prompts, 
                        iterations=args.iterations, 
                        seed=args.seed, 
                        learning_rate=args.learning_rate, 
                        init_image=args.seed_image, 
                        aspect=args.aspect, 
                        quality=args.quality, 
                        vqgan_config=args.vqgan_model, 
                        vqgan_checkpoint=args.vqgan_checkpoint, 
                        optimiser=args.optimizer, 
                        size=[args.sizex,args.sizey], 
                        ezsize=args.scale, 
                        #use_pixeldraw=True, 
                        output='Progress.png')

settings = clipit.apply_settings()
clipit.do_init(settings)
clipit.do_run(settings)