import torch
import argparse 
from utils import *
from PIL import Image, ImageDraw, ImageFont

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Model checkpoint
srgan_checkpoint = "./checkpoint_srgan.pth"

# Load model
srgan_generator = torch.load(srgan_checkpoint)['generator'].to(device)
srgan_generator.eval()

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str,
    help='Input image filename.')
  parser.add_argument('--output_image', type=str,
    help='Output image filename.')
  args = parser.parse_args()
  return args

def perform_sr(img, halve=False):
    #original image
    hr_img = Image.open(img, mode="r")
    hr_img = hr_img.convert('RGB')
    # Super-resolution (SR) with SRGAN
    sr_img_srgan = srgan_generator(convert_image(hr_img, source='pil', target='imagenet-norm').unsqueeze(0).to(device))
    sr_img_srgan = sr_img_srgan.squeeze(0).cpu().detach()
    sr_img_srgan = convert_image(sr_img_srgan, source='[-1, 1]', target='pil')
    # Save results
    sr_img_srgan.save(args.output_image);

if __name__ == '__main__':
    args=parse_args();
    perform_sr(args.input_image)
