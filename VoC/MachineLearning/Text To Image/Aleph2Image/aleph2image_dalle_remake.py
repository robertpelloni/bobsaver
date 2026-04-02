# Public copy of Aleph2Image_dalle_remake.ipynb
# Original file is located at https://colab.research.google.com/drive/17ZSyxCyHUnwI1BgZG22-UFOtCWFvqQjy

import torch
import io
from adamp import AdamP
import numpy as np
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import torch.nn.functional as F
import PIL
import random
import imageio
from IPython import display
from CLIP import clip
import gc
from dall_e import load_model
from datetime import datetime
from math import sqrt, ceil, floor
import kornia.augmentation as K
import argparse
import sys

DEVICE = torch.device('cuda:0')

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--size', type=int, help='Image width and height.', default=512)
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

args = argparse.Namespace(
    text_input=args2.prompt,
    size=args2.size,
    batch_size=args2.batch_size,
    seed=args2.seed,
    update=args2.update,
    display_freq=args2.update,
    learning_rate=args2.learning_rate,
    iterations=args2.iterations,
    cutn=args2.cutn,
    tau=args2.tau,
    weight_decay=args2.weight_decay,
    clip_model=args2.clip_model,
    image_file=args2.image_file,
    frame_dir=args2.frame_dir,
)

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

# Load the model
sys.stdout.write("Loading "+args.clip_model+" ...\n")
sys.stdout.flush()
perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor = perceptor.eval().requires_grad_(False)

'''
if clip_model == 'RN50x4':
    perceptor_size = 288
else:
    perceptor_size = 224
'''
perceptor_size = 224

sys.stdout.write("Loading decoder.pkl ...\n")
sys.stdout.flush()
model = load_model('decoder.pkl', 'cuda')

"""# Params"""

im_shape = [args.size, args.size]
# im_shape = [800, 1024]
sideY, sideX = im_shape

batch_size = args.batch_size #was originally 4 - cutting down to 1 makes it much faster, allows bigger cutout numbers, and seems to give the same output quality
num_rows = floor(sqrt(batch_size))
num_cols = ceil(sqrt(batch_size))

"""
#original code
K.RandomHorizontalFlip(p=0.5), # not sure if this is always useful
K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
K.RandomPerspective(0.7,p=0.7),
K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),
# K.RandomSharpness(0.3, p=0.2),
"""
augs = torch.nn.Sequential(
    K.RandomHorizontalFlip(p=0.5), # not sure if this is always useful
    K.RandomAffine(degrees=30, translate=0.1, p=0.8, padding_mode='border'),
    K.RandomPerspective(0.7,p=0.7),
    K.ColorJitter(hue=0.01, saturation=0.01, p=0.7),
    
    # K.RandomSharpness(0.3, p=0.2),
    # K.GaussianBlur((31, 31), (30.5, 30.5)),
    
    #K.RandomAffine(degrees=0, scale=[1.1,1.1], p=1.0),
    
).cuda()

to_tensor = T.ToTensor()

nom = T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

"""# Latent coordinate"""

class Pars(torch.nn.Module):
    def __init__(self):
        super(Pars, self).__init__()
        hots = F.one_hot((torch.arange(0, 8192).to(torch.int64)), num_classes=8192)
        rng = torch.zeros(batch_size, sideX//8*sideY//8, 8192).uniform_()

        for b in range(batch_size):
            for i in range(sideX//8 * sideY//8):
                rng[b,i] = hots[[np.random.randint(8191)]]

        rng = rng.permute(0, 2, 1)
        self.normu = torch.nn.Parameter(rng.cuda().reshape(batch_size, 8192//2, -1))
        self.normu = torch.nn.Parameter(torch.sinh(2*torch.arcsinh(self.normu)).to(DEVICE))   

    def forward(self):
        normu = torch.nn.functional.gumbel_softmax(self.normu.reshape(batch_size, 8192//2, -1), tau=tau, dim=1)[:8192* sideX//8*sideY//8].view(batch_size, 8192, sideX//8, sideY//8)
        return normu

"""# Train"""

def image_grid(imgs, rows, cols):
    w, h = imgs[0].size
    grid = PIL.Image.new('RGB', size=(cols * w, rows * h))
    grid_w, grid_h = grid.size
    
    for i, img in enumerate(imgs):
        grid.paste(img, box=(i % cols * w, i//cols * h))

    return grid

def save_image(img, num=0):    
    pil_img = PIL.ImageOps.autocontrast(img)

    # Save individual image with timestamp
    current_time = datetime.now().strftime('%y%m%d-%H%M%S_%f')
    #img_filename = f'{out_folder}/aleph_output{str(num)}_{current_time}.jpg'
    img_filename = 'progress.jpg'
    
    pil_img.save(args.image_file, quality=95, subsampling=0)
   
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
        pil_img.save(save_name, quality=95, subsampling=0)
    
    
    
    
    
def rerank_img_list_cosine(img):
    img_in = to_tensor(img).unsqueeze(0).to(DEVICE)
    img_in = nom(TF.resize(img_in, (perceptor_size, perceptor_size)))
    img_enc = perceptor.encode_image(img_in)
    score = torch.cosine_similarity(t, img_enc, -1)
    return score

# From RiversHaveWings' v+q notebook
class ClampWithGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input, min, max):
        ctx.min = min
        ctx.max = max
        ctx.save_for_backward(input)
        return input.clamp(min, max)

    @staticmethod
    def backward(ctx, grad_in):
        input, = ctx.saved_tensors
        return grad_in * (grad_in * (input - input.clamp(ctx.min, ctx.max)) >= 0), None, None

clamp_with_grad = ClampWithGrad.apply

def format_image(x):
    x = torch.tanh(x+x**5*0.5)
    x = (x + 1.) / 4
    return x

def checkin(loss):
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()
    with torch.no_grad():
        out = model(lats().cuda())
        al = clamp_with_grad(out[:, :3], 0, 1)
        img_list = []
        batch_num = 0
        for allls in al:
            pil_img = T.ToPILImage()(allls.squeeze())
            img_list.append(pil_img)
            save_image(pil_img, batch_num)
            batch_num += 1
            break
            
        if itt % args.update == 0 or itt == 1:
            if len(img_list) > 1 and sort_grid:
                img_list.sort(reverse=True, key=rerank_img_list_cosine)
            img_grid = image_grid(img_list, num_rows, num_cols)

            #display.clear_output(wait=True)
            #display.display(img_grid)
    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

def augment(into, cutn=32):
    sideY, sideX = into.shape[2:4]
    max_size = min(sideX, sideY)
    min_size = min(sideX, sideY, perceptor_size)
    cutouts = []
    for ch in range(cutn):
        if ch > cutn - cutn//4:
            size = max_size
        else:
            size = int(torch.rand([])**1 * (max_size - min_size) + min_size)

        offsetx = torch.randint(0, sideX - size + 1, ())
        offsety = torch.randint(0, sideY - size + 1, ())
        cutout = into[:, :, offsety:offsety + size, offsetx:offsetx + size]
        cutout = torch.nn.functional.interpolate(cutout, (perceptor_size, perceptor_size), mode='bilinear', align_corners=True)
        cutouts.append(cutout)
        del cutout

    cutouts = torch.cat(cutouts, dim=0)
    cutouts = augs(cutouts.double()).half()
    cutouts += up_noise * torch.rand((cutouts.shape[0], 1, 1, 1), device=DEVICE) * torch.randn_like(cutouts, requires_grad=False)

    return cutouts

def ascend_txt():
    out = model(lats().cuda())[:, :3]
    into = nom(clamp_with_grad(augment(out, sample_cuts), 0, 1))

    iii = perceptor.encode_image(into.to(DEVICE))
    grad = torch.cosine_similarity(t, iii, -1).mean() * main_weight
    
    if use_moddedloss:
      out = clamp_with_grad(out, 0, 1)
      grad += -torch.abs(1-torch.std(out, dim=1).mean().pow(2).sum() + torch.mean(torch.mean(out)).mean()).pow(2).sum() + 4*torch.max(torch.square(out).mean(), torch.tensor(1.).cuda()).pow(2).sum()

    return -grad
    
def train():
    global up_noise

    loss = ascend_txt()
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    
    if use_searing:
        if itt == 25:
            optimizer.param_groups[0]['lr'] = simmer_rate
            optimizer.param_groups[0]['weight_decay'] = .05
        elif itt >= 25:
            optimizer.param_groups[0]['lr'] = max(optimizer.param_groups[0]['lr']*.995, .01)
    elif use_anneal:
        for g in optimizer.param_groups:
            g['lr'] *= 0.995
            # g['weight_decay'] *= 0.995
        up_noise *= 0.995

    sys.stdout.write("Iteration {} loss {}".format(itt,loss)+"\n")
    sys.stdout.flush()
    if itt % args.update == 0:
        checkin(loss)

def create_optimizer():
    global optimizer

    # optimizer = torch.optim.AdamW([{'params': mapper, 'lr': learning_rate}], weight_decay=dec, amsgrad=True)
    optimizer = AdamP([{'params': mapper, 'lr': learning_rate}], weight_decay=dec, nesterov=True)

tau = args.tau # default 1.873
learning_rate = args.learning_rate
dec = args.weight_decay

lats = Pars().cuda()
mapper = [lats.normu]
create_optimizer()
itt = 1

text_input = [args.text_input]

tx = clip.tokenize(text_input)
t = perceptor.encode_text(tx.cuda()).detach().clone()
if len(text_input) > 1:
    t = t.sum(dim=0)
    t = t / t.norm(dim=-1, keepdim=True)

main_weight = 10

sort_grid = True # default True

# learning rate strategies
use_anneal = False
use_searing = False
simmer_rate = 0.1

up_noise = 0.15
sample_cuts = args.cutn # default 32 - higher cuts can mean better quality, at the cost of speed and VRAM
train_iterations = 300
use_moddedloss = False # default False - seems to help sometimes, but can darken the scene

# If you wanna reset the learning rate, but not the whole generation, just to "give it a kick"
# optimizer.param_groups[0]['lr'] = 0.1
# optimizer.param_groups[0]['weight_decay'] = .05

sys.stdout.write("Starting...\n")
sys.stdout.flush()
itt = 1
for i in range(args.iterations):
  train()
  itt+=1
