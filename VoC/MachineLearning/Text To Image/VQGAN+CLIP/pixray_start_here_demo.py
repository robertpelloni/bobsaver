# Pixray Start Here Demo
# Original file is located at  https://colab.research.google.com/github/dribnet/clipit/blob/master/demos/Start_Here.ipynb

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append("./pixray")
sys.path.append('./taming-transformers')

import os

import pixray
import argparse


quality = "normal" #@param ["draft", "normal", "better", "best"]

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
  parser.add_argument('--cutn', type=int, help='Cutouts.')
  parser.add_argument('--quality', type=str, help='Quality.')
  parser.add_argument('--scale', type=str, help='Scale.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--vqgan_checkpoint', type=str, help='VQGAN model to load.')
  parser.add_argument('--optimizer', type=str, help='Optimizer.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  args = parser.parse_args()
  return args

args=parse_args();

if args.sizex==args.sizey:
    aspect = "square"
else:
    aspect = "widescreen" #@param ["widescreen", "square"]

pixray.reset_settings()
pixray.add_settings(    prompts=args.prompts, 
                        aspect=aspect, 
                        quality=args.quality, 
                        init_image=args.seed_image, 
                        size=[args.sizex,args.sizey], 
                        iterations=args.iterations, 
                        num_cuts=args.cutn,
                        save_every=args.update, 
                        vqgan_config=args.vqgan_model, 
                        vqgan_checkpoint=args.vqgan_checkpoint,
                        scale=args.scale,
                        seed=args.seed,
                        output="Progress.png")

# Optional: you could put extra settings here...

# Apply these settings and run
settings = pixray.apply_settings()
pixray.do_init(settings)
pixray.do_run(settings)