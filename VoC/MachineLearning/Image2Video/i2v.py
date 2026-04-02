import sys

sys.stdout.write("\nImports ...\n\n")
sys.stdout.flush()

from modelscope.pipelines import pipeline
from modelscope.outputs import OutputKeys
import torch
import argparse

sys.stdout.write("\nParsing arguments ...\n\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--image_file", type=str, help="the image to convert into a video")
    parser.add_argument("--output_video", type=str, help="output video name")
    parser.add_argument("--cache_directory", type=str, help="full path to .cache\\modelscope\\hub\\damo\\Image-to-Video\\")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("\nCreating image-to-video pipeline ...\n\n")
sys.stdout.flush()

#try and load models from the user local cache, if not found they will download from modelscope
try:
    pipe = pipeline(task='image-to-video', model=args2.cache_directory, model_revision='v1.1.0', device='cuda:0')
except:
    pipe = pipeline(task='image-to-video', model='damo/Image-to-Video', model_revision='v1.1.0', device='cuda:0')

sys.stdout.flush()
sys.stdout.write("\nCreating image-to-video video ...\n")
sys.stdout.write("No stats are shown during video creation.  Check Task Manager for GPU activty.\n\n")
sys.stdout.flush()

output_video_path = pipe(args2.image_file, output_video=args2.output_video)[OutputKeys.OUTPUT_VIDEO]

sys.stdout.write(f"\nCreated {args2.output_video}\n")
sys.stdout.flush()
