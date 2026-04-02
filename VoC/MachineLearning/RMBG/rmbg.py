import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from PIL import Image
import matplotlib.pyplot as plt
import torch
from torchvision import transforms
from transformers import AutoModelForImageSegmentation
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_image", type=str, help="image to remove background from")
    parser.add_argument("--output_directory", type=str, help="dir to write results to")
    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

model = AutoModelForImageSegmentation.from_pretrained('briaai/RMBG-2.0', trust_remote_code=True)
torch.set_float32_matmul_precision(['high', 'highest'][0])
model.to('cuda')
model.eval()

# Data settings
image_size = (1024, 1024)
transform_image = transforms.Compose([
    transforms.Resize(image_size),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

sys.stdout.write("Loading image ...\n")
sys.stdout.flush()

image = Image.open(args2.input_image)
input_images = transform_image(image).unsqueeze(0).to('cuda')

sys.stdout.write("Removing background ...\n")
sys.stdout.flush()

# Prediction
with torch.no_grad():
    preds = model(input_images)[-1].sigmoid().cpu()
pred = preds[0].squeeze()
pred_pil = transforms.ToPILImage()(pred)
mask = pred_pil.resize(image.size)
image.putalpha(mask)

sys.stdout.write("Saving image ...\n")
sys.stdout.flush()

image.save(f"{args2.output_directory}no_bg_image.png")

sys.stdout.write("Done\n")
sys.stdout.flush()