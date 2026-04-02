import os.path as osp
import glob
import cv2
import numpy as np
import torch
import RRDBNet_arch as arch
import argparse 

model_path = 'models/RRDB_PSNR_x4.pth'  # models/RRDB_ESRGAN_x4.pth OR models/RRDB_PSNR_x4.pth
device = torch.device('cuda')  # if you want to run on CPU, change 'cuda' -> cpu
# device = torch.device('cpu')

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str,
    help='Input image filename.')
  parser.add_argument('--output_image', type=str,
    help='Output image filename.')
  args = parser.parse_args()
  return args


def perform_sr(img):
    model = arch.RRDBNet(3, 3, 64, 23, gc=32)
    model.load_state_dict(torch.load(model_path), strict=True)
    model.eval()
    model = model.to(device)
    img = cv2.imread(img, cv2.IMREAD_COLOR)
    img = img * 1.0 / 255
    img = torch.from_numpy(np.transpose(img[:, :, [2, 1, 0]], (2, 0, 1))).float()
    img_LR = img.unsqueeze(0)
    img_LR = img_LR.to(device)
    with torch.no_grad():
        output = model(img_LR).data.squeeze().float().cpu().clamp_(0, 1).numpy()
    output = np.transpose(output[[2, 1, 0], :, :], (1, 2, 0))
    output = (output * 255.0).round()
    cv2.imwrite(args.output_image, output)

if __name__ == '__main__':
    args=parse_args();
    perform_sr(args.input_image)
    
