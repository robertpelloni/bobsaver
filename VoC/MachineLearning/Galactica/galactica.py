import sys
sys.path.append('./galai')

import galai as gal
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--model', type=str)
  args = parser.parse_args()
  return args

args=parse_args();

sys.stdout.write(f'Loading {args.model} model ...\n')
sys.stdout.flush;
model = gal.load_model(args.model)

sys.stdout.write('Working ...\n\n')
sys.stdout.flush;
#output = model.generate(args.prompt)
#sys.stdout.write(str(output))
result=model.generate("Scaled dot product attention:\n\n\\[")
result=model.generate("Scaled dot product attention:\n\n\\[")
sys.stdout.write(result)

sys.stdout.flush;
