import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import torch_optimizer as optim
import random
import PIL
from PIL import Image
import math
import gc


import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--size', type=int, help='Image width and height.', default=512)
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  #parser.add_argument('--output_brightness', type=float, help='Brightnesss adjustment for displayed image.')
  parser.add_argument('--output_gamma', type=float, help='Gamma adjustment for displayed image.')
  parser.add_argument('--output_contrast', type=float, help='Contrast adjustment for displayed image.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
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




device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

torch.set_grad_enabled(False)

def clear_mem():
    torch.cuda.empty_cache()
    gc.collect()

ToTensor = T.ToTensor()
ToImage  = T.ToPILImage()

def OpenImage(x, resize=None, convert="RGB"):
    if resize:
        return ToTensor(Image.open(x).convert(convert).resize(resize)).unsqueeze(0).to(device)
    else:
        return ToTensor(Image.open(x).convert(convert)).unsqueeze(0).to(device)

import warnings
warnings.filterwarnings('ignore')


from CLIP.clip import clip
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
torch.set_grad_enabled(False)


sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor.eval().float().requires_grad_(False);

CLIP_Normalization = T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

def diff_abs(x, y=0.0001):
    return torch.sqrt(x*x+y)

def diff_relu(x, y=0.0001):
    return (torch.sqrt(x*x+y)+x)*0.5

def diff_clamp(x, y=0.0001):
    return diff_relu(1-diff_relu(1-x, y), y)

def sign_pow(x, y):
    return torch.pow(torch.abs(x), y) * torch.sign(x)

color_correlation_svd_sqrt = torch.tensor([[0.26, 0.09, 0.02],[0.27, 0.00, -0.05],[0.27, -0.09, 0.03]])
max_norm_svd_sqrt = torch.max(torch.linalg.norm(color_correlation_svd_sqrt, dim=0))
color_correlation_normalized = (color_correlation_svd_sqrt / max_norm_svd_sqrt).to(device)

def linear_decorrelate_color(tensor):
    t_permute = tensor.permute(0, 2, 3, 1)
    t_permute = torch.matmul(t_permute, color_correlation_normalized.T)
    tensor = t_permute.permute(0, 3, 1, 2)
    return tensor

def linear_decorrelate_color_inverse(tensor):
    t_permute = tensor.permute(0, 2, 3, 1)
    t_permute = torch.matmul(t_permute, torch.pinverse(color_correlation_normalized).T)
    tensor = t_permute.permute(0, 3, 1, 2)
    return tensor

def quick_avg_down(x, repeats=5):
    b,c,h,w = x.shape
    for _ in range(repeats):
        x = TF.gaussian_blur(x, 3, 2/math.pi)
        x = F.avg_pool2d(x, 2, 2, 0, count_include_pad=False)
    x = F.interpolate(x, (h,w), mode='bicubic', align_corners=False)
    return x

def pseudo_gaussian(x):
    x = torch.exp(-0.5*(x*3)**2)
    return x

gradient = torch.linspace(-1,1,3).unsqueeze(0).tile(3,1).unsqueeze(0)
gradient = torch.cat([gradient, gradient.rot90(1,(-2,-1))]).unsqueeze(1).to(device)

def gradient_conv(x):
    x = TF.pad(x, 1, padding_mode='reflect')
    x = F.conv2d(x, gradient)
    return x

def gradient_filter(x):
    b, c, h, w = x.shape
    x = x.reshape(b*c, 1, h, w)
    x = TF.pad(x, 1, padding_mode='reflect')
    x = F.conv2d(x, gradient)
    b2, c2, h2, w2 = x.shape
    x = x.permute(0,2,3,1)
    x = x.reshape(b, c, h2, w2, 2)
    return x

def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean([1, 2, 3])

def highpass_loss(x, kernel, sigma):
    x = x - TF.gaussian_blur(x, kernel, sigma)
    x = pseudo_gaussian(x*0.5+0.5).sub(0.5).mul(2) * 0.25 + x * 0.75
    x = (x**2).mean([1,2,3])
    return x

def symmetric_nn_loss(img):
    rolls = []
    width = 3
    for x in range(width):
        for y in range(width):
            roll = torch.roll(img, (x-width//2,y-width//2), dims=(-2,-1)).unsqueeze(0)
            rolls.append(roll)
    del roll
    rolls = torch.cat(rolls, 0)
    pair_0 = (rolls[0]-rolls[8]).pow(2)
    pair_1 = (rolls[1]-rolls[7]).pow(2)
    pair_2 = (rolls[2]-rolls[6]).pow(2)
    pair_3 = (rolls[3]-rolls[5]).pow(2)
    loss = (pair_0 + pair_1 + pair_2 + pair_3) / 4
    return loss

def get_grid(x, center=[0.0, 0.0], angle=0.0, translate=[0.0, 0.0], scale=1.0, shear=[0.0, 0.0]):
    matrix = TF._get_inverse_affine_matrix(center, angle, translate, scale, shear)
    matrix = torch.tensor(matrix).reshape(1,2,3)
    grid = F.affine_grid(matrix, x[0,None].shape, align_corners=False)
    return grid

def funny_img(x, center=[0.0, 0.0], angle=0.0, translate=[0.0, 0.0], scale=1.0, shear=[0.0, 0.0], rand=0.01, bend=1.0):
    center = torch.tensor(center).to(device)
    angle_0 = torch.tensor(random.random()*angle*2-angle).float().to(device)
    angle_1 = torch.tensor(random.random()*angle*2-angle).float().to(device)
    angle_2 = torch.tensor(random.random()*360).float().to(device)
    translate = torch.tensor(translate).to(device)
    scale = torch.tensor(scale).to(device)
    shear = torch.tensor(shear).to(device)
    grid_0 = get_grid(x, center, angle_0, translate, scale, shear)
    grid_1 = get_grid(x, center, angle_1, translate, scale, shear) * torch.rand(1,1,1,2).mul(0.1).add(0.9) + torch.rand(1,1,1,2) * 1/32
    blob = F.interpolate(torch.randn(1,2,8,8).tanh(), (x.shape[-2], x.shape[-1]), mode='bicubic', align_corners=False).permute(0,2,3,1)
    angle_2 = angle_2 * (math.pi/180)
    ang_x = math.cos(angle_2)
    ang_y = math.sin(angle_2)
    ang = torch.tensor([ang_x, ang_y]).reshape(1,1,1,2)
    gradient = F.affine_grid(torch.tensor([1.0, 0.0, 0.0, -0.0, 1.0, 0.0]).reshape(1,2,3).float(), x[0,None].shape, align_corners=True)
    gradient = (gradient * ang).sum(-1, keepdim=True)
    grid_mix = torch.lerp(grid_0, grid_1, gradient*bend).to(device)
    grid_mix = torch.lerp(grid_mix, blob.to(device), rand).tile(x.shape[0],1,1,1)
    x = F.grid_sample(x, grid_mix, align_corners=False, padding_mode='reflection')
    return x

def soft_clip(x, gain=1.0, mix=1.0):
    return torch.lerp(x, x.mul(gain).tanh().div(gain), mix)

def triangle_blur(x, kernel_size=3, pow=1.0):
    padding = (kernel_size-1) // 2
    b,c,h,w = x.shape
    kernel = torch.linspace(-1,1,kernel_size+2)[1:-1].abs().neg().add(1).reshape(1,1,1,kernel_size).pow(pow).to(device)
    kernel = kernel / kernel.sum()
    x = x.reshape(b*c,1,h,w)
    x = F.pad(x, (padding,padding,padding,padding), mode='reflect')
    x = F.conv2d(x, kernel)
    x = F.conv2d(x, kernel.permute(0,1,3,2))
    x = x.reshape(b,c,h,w)
    return x

prompt = perceptor.encode_text(clip.tokenize(args.prompt).to(device))
img_root = linear_decorrelate_color_inverse(torch.rand(1,3,args.size,args.size).to(device)).detach().requires_grad_(True)
optimizer = optim.Yogi([img_root], lr=1/32)
video_frames = None

torch.set_grad_enabled(True)

augments = T.Compose([
    T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
    T.Pad(8, padding_mode='reflect'),
    T.RandomCrop(args.size),
    T.Lambda(lambda x: TF.resize(x, random.randint(256,640))),
    T.Pad(64, padding_mode='reflect'),
    T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
    T.Lambda(lambda x: funny_img(x, angle=22.5, scale=random.random()*0.5+0.75, shear=torch.rand(2).mul(0.3).sub(0.15), rand=0.025, bend=0.5)),
    T.RandomCrop(224),
    T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
    T.RandomChoice([
        T.Lambda(lambda x: x),
        T.Lambda(lambda x: x),
        T.GaussianBlur(3, (0.32, 0.64)),
        T.GaussianBlur(5, (0.64, 1.27)),
        T.GaussianBlur(7, (0.95, 1.91)),
        T.Lambda(lambda x: quick_avg_down(x, random.randint(2,5))),
    ]),
    T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
    T.ColorJitter(0.1,0.1,0.1,0.1), # original
    #T.ColorJitter(0.5,0.1,0.0,0.0), # brighter resulting image - brightness, contrast, saturation, hue
    T.Lambda(lambda x: x + torch.randn_like(x) * 0.01),
    #T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711)),  # original - commenting this seems to give brighter/clearer images?!
])

batch_size = 1
steps = args.iterations
soft_clip_gain = 4

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt=1
for i in range(steps):

    sys.stdout.write(f'Iteration {itt}\n')
    sys.stdout.flush()

    x = diff_clamp(linear_decorrelate_color(img_root), 0.0001)**2

    with torch.no_grad():
        x_clamp = linear_decorrelate_color(img_root).clamp(0,1)**2
        if video_frames == None:
            video_frames = (x_clamp.permute(0,2,3,1).clamp(0,1)*255).byte().cpu()
        else:
            video_frames = torch.cat([video_frames, (x_clamp.permute(0,2,3,1).clamp(0,1)*255).byte().cpu()])

    loss = 0.0
    mask_loss = 0.0
    for l in range(batch_size):
        x_aug = torch.cat([augments(x) for _ in range(8)])
        x_enc = perceptor.encode_image(x_aug[torch.arange(0,6,2)])
        loss += torch.cosine_similarity(x_enc, prompt, -1).pow(2).neg().add(1).mean() / batch_size
    with torch.no_grad():
        loss.backward()
        grad_downscale = round(5*(max(1-i/(100),0))**0.5)
        img_root.grad = quick_avg_down(img_root.grad, grad_downscale)
        img_root_grad_norm = (img_root.grad / img_root.grad.norm(dim=0).mean().add(1e-8))
        img_root.grad = soft_clip(img_root_grad_norm, soft_clip_gain, min(grad_downscale, 1.0))
        optimizer.step()
        optimizer.zero_grad()
        img_root[:] = torch.lerp(triangle_blur(img_root, 5, 2), img_root, 0.50)
        if itt % args.update == 0:
            sys.stdout.flush()
            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()
            #ToImage(linear_decorrelate_color(img_root).clamp(0,1).pow(2)[0]).save('Progress.png')
            img2 = ToImage(linear_decorrelate_color(img_root).clamp(0,1).pow(2)[0])

            #tweak output brightness - only brightens the display
            #img2 = torchvision.transforms.functional.adjust_brightness(img2,args.output_brightness)
            
            #https://rdrr.io/github/mlverse/torchvision/man/transform_adjust_gamma.html
            img2 = torchvision.transforms.functional.adjust_gamma(img2,args.output_gamma,1)

            img2 = torchvision.transforms.functional.adjust_contrast(img2,args.output_contrast)
            
            img2.save(args.image_file)
            
            if args.frame_dir is not None:
                import os
                file_list = []
                for file in os.listdir(args.frame_dir):
                    if file.startswith("FRA"):
                        if file.endswith("png"):
                            if len(file) == 12:
                                file_list.append(file)
                if file_list:
                    last_name = file_list[-1]
                    count_value = int(last_name[3:8])+1
                    count_string = f"{count_value:05d}"
                else:
                    count_string = "00001"
                save_name = args.frame_dir+"\FRA"+count_string+".png"
                img2.save(save_name)
            
            
            
            sys.stdout.flush()
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()
    itt = itt+1


