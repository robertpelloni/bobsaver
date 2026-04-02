# simple front end script to execute the dream BigSleep API

# python bigsleep.py --input_phrase "A happy face" --image_width 512 --seed 0 --epochs 1

from big_sleep import BigSleep, Imagine
import argparse

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_phrase', type=str, help='Text to generate image from.')
  parser.add_argument('--image_size', type=int, help='Output image width.')
  parser.add_argument('--seed', type=int, help='Image random seed.')
  parser.add_argument('--epochs', type=int, help='Number of epochs.')
  parser.add_argument('--iterations', type=int, help='Number of iterations.')
  parser.add_argument('--overwrite', type=bool, help='Overwrite existing image.')
  parser.add_argument('--center_bias', type=bool, help='Center bais.')
  parser.add_argument('--bilinear', type=bool, help='Bilinear.')
  parser.add_argument('--save_every', type=int, help='Save after n iterations.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--ema_decay', type=float, help='Ema Decay.')
  parser.add_argument('--class_temperature', type=float, help='Class temperature.')
  parser.add_argument('--num_cutouts', type=int, help='Number of cutouts.')
  parser.add_argument('--clip_model', type=str, help='CLIP{ model to use.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();

imagine = Imagine(
    text = args.input_phrase,
    epochs = args.epochs,
    #img = 'e:\input.jpg', #image must be jpg and match image_size dimensions - does not seem to be the "input image" but rather a target image the system trains towards?
    iterations = args.iterations,
    seed = args.seed,
    image_size = args.image_size,
    open_folder = False,
    save_every = args.save_every,
    center_bias = args.center_bias,
    bilinear = args.bilinear,
    lr = args.learning_rate,
    ema_decay = args.ema_decay,
    class_temperature = args.class_temperature,
    num_cutouts = args.num_cutouts,
    clip_model = args.clip_model,
    image_file = args.image_file,
    frame_dir = args.frame_dir,
)
imagine()