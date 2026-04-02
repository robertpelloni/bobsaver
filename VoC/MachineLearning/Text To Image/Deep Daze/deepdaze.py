# simple front end script to execute the imagine DeepDaze API
# python deepdaze.py --input_phrase "A happy face" --image_width 512 --seed 0 --epochs 1

from deep_daze import Imagine
import argparse

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_phrase', type=str, help='Text to generate image from.')
  parser.add_argument('--optimizer', type=str, help='Optimizer.')
  parser.add_argument('--image_width', type=int, help='Output image width.')
  parser.add_argument('--batch_size', type=int, help='Batch size.')
  parser.add_argument('--seed', type=int, help='Image random seed.')
  parser.add_argument('--epochs', type=int, help='Number of epochs.')
  parser.add_argument('--iterations', type=int, help='Number of iterations.')
  parser.add_argument('--num_layers', type=int, help='Number of layers.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--averaging_weight', type=float, help='Averaging weight.')
  parser.add_argument('--overwrite', type=bool, help='Overwrite existing image.')
  parser.add_argument('--gradient_accumulate_every', type=bool, help='Gradient accumulate every.')
  parser.add_argument('--center_bias', type=bool, help='Center bias.')
  parser.add_argument('--save_every', type=int, help='Save after n iterations')
  parser.add_argument('--model_name', type=str, help='CLIP model name.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args=parse_args();

imagine = Imagine(
    text = args.input_phrase,
    epochs = args.epochs,
    iterations = args.iterations,
    seed = args.seed,
    image_width = args.image_width,
    save_every = args.save_every,
    batch_size = args.batch_size,
    lr = args.learning_rate,
    averaging_weight = args.averaging_weight,
    num_layers = args.num_layers,
    optimizer = args.optimizer,
    center_bias = args.center_bias,
    gradient_accumulate_every = args.gradient_accumulate_every,
    model_name = args.model_name,
    image_file = args.image_file,
    frame_dir = args.frame_dir,
)
imagine()