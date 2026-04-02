import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import argparse
import torch
import cv2
import numpy as np
import os

from model import Generator



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--input_image', type=str, help='Input image.')
  parser.add_argument('--output_image', type=str, help='Output image.')
  parser.add_argument(
      '--checkpoint',
      type=str,
      default='./pytorch_generator_Paprika.pt',
  )
  parser.add_argument(
      '--input_dir', 
      type=str, 
      default='./samples/inputs',
  )
  parser.add_argument(
      '--output_dir', 
      type=str, 
      default='./samples/results',
  )
  parser.add_argument(
      '--device',
      type=str,
      default='cuda:0',
  )
  parser.add_argument(
      '--upsample_align',
      type=bool,
      default=False,
  )
  parser.add_argument(
      '--x32',
      action="store_true",
  )
  args = parser.parse_args()
  return args

args=parse_args();

if args.seed is not None:
    sys.stdout.write(f'Setting seed to {args.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(args.seed)
    import random
    random.seed(args.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(args.seed)
    torch.cuda.manual_seed(args.seed)
    torch.cuda.manual_seed_all(args.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 


    
def load_image(image_path, x32=False):
    img = cv2.imread(image_path).astype(np.float32)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w = img.shape[:2]

    if x32: # resize image to multiple of 32s
        def to_32s(x):
            return 256 if x < 256 else x - x%32
        img = cv2.resize(img, (to_32s(w), to_32s(h)))

    img = torch.from_numpy(img)
    img = img/127.5 - 1.0
    return img


def test(args):
    device = args.device
    
    sys.stdout.flush()
    sys.stdout.write(f"Loading model {args.checkpoint} ...\n")
    sys.stdout.flush()

    net = Generator()
    net.load_state_dict(torch.load(args.checkpoint, map_location="cpu"))
    net.to(device).eval()
    
    sys.stdout.flush()
    sys.stdout.write(f"Loading {args.input_image} ...\n")
    sys.stdout.flush()

    image = load_image(args.input_image)

    sys.stdout.flush()
    sys.stdout.write("Processing ...\n")
    sys.stdout.flush()

    with torch.no_grad():
        input = image.permute(2, 0, 1).unsqueeze(0).to(device)
        out = net(input, args.upsample_align).squeeze(0).permute(1, 2, 0).cpu().numpy()
        out = (out + 1)*127.5
        out = np.clip(out, 0, 255).astype(np.uint8)

    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    cv2.imwrite(args.output_image, cv2.cvtColor(out, cv2.COLOR_BGR2RGB))

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

    
    
    
    
if __name__ == '__main__':
    test(args)
    
