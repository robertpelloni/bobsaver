import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import os

import PIL.Image
from carvekit.api.interface import Interface
from carvekit.ml.wrap.fba_matting import FBAMatting
from carvekit.ml.wrap.u2net import U2NET
from carvekit.pipelines.postprocessing import MattingMethod
from carvekit.pipelines.preprocessing import PreprocessingStub
from carvekit.trimap.generator import TrimapGenerator
import argparse
import torch

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--i', type=str)
  parser.add_argument('--o', type=str)

  args = parser.parse_args()
  return args

args=parse_args();

DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', DEVICE)
device = DEVICE # At least one of the modules expects this name..
sys.stdout.flush()

sys.stdout.write("Getting ready ...\n")
sys.stdout.flush()

u2net = U2NET(device=DEVICE,
              batch_size=1)

fba = FBAMatting(device=DEVICE,
                 input_tensor_size=2048,
                 batch_size=1)

trimap = TrimapGenerator()

preprocessing = PreprocessingStub()

postprocessing = MattingMethod(matting_module=fba,
                               trimap_generator=trimap,
                               device=DEVICE)

interface = Interface(pre_pipe=preprocessing,
                      post_pipe=postprocessing,
                      seg_pipe=u2net)

sys.stdout.write("Opening source image ...\n")
sys.stdout.flush()

image = PIL.Image.open(args.i)

sys.stdout.write("Processing ...\n")
sys.stdout.flush()

cat_wo_bg = interface([image])[0]

sys.stdout.write("Saving result ...\n")
sys.stdout.flush()

cat_wo_bg.save(args.o)

sys.stdout.write("Done\n")
sys.stdout.flush()
