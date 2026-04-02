# CLIP Pseudo Slime Mold
# By hotgrits
# https://discord.com/channels/729741769192767510/730484623028519072/850857930881892372

# === Get all of these very important things
# ===
import torch
import torchvision.transforms as T
import torchvision.transforms.functional as TF
import PIL
from PIL import Image
from IPython import display
import sys
import argparse

ToTensor = T.ToTensor()
ToImage  = T.ToPILImage()

from CLIP.clip import clip

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"  
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_phrase', type=str, help='Text to generate image from.')
  parser.add_argument('--image_size', type=int, help='Output image width.')
  parser.add_argument('--seed', type=int, help='Image random seed.')
  parser.add_argument('--iterations', type=int, help='Number of iterations.')
  parser.add_argument('--save_every', type=int, help='Save after n iterations.')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--num_cutouts', type=int, help='Number of cutouts.')
  parser.add_argument('--cutout_ratio', type=float, help='Cutout resize ratio.')
  parser.add_argument('--translation_ratio', type=float, help='Cutout translation ratio.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to use.')
  parser.add_argument('--channels_first', type=bool, help='Diff augment channels first.')
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

sys.stdout.write("Loading "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor, preprocess = clip.load(args.clip_model, jit=False)
perceptor.eval().float().requires_grad_(False);

CLIP_Normalization = T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))

sys.stdout.write("Starting ...\n")
sys.stdout.flush()


#@markdown Differentiable Augmentation for Data-Efficient GAN Training<br>
#@markdown Shengyu Zhao, Zhijian Liu, Ji Lin, Jun-Yan Zhu, and Song Han<br>
#@markdown https://arxiv.org/pdf/2006.10738<br>
#@markdown Code is inside this cell.
 
import torch
import torch.nn.functional as F

 
def DiffAugment(x, policy='', channels_first=args.channels_first):
    if policy:
        if not channels_first:
            x = x.permute(0, 3, 1, 2)
        for p in policy.split(','):
            for f in AUGMENT_FNS[p]:
                x = f(x)
        if not channels_first:
            x = x.permute(0, 2, 3, 1)
        x = x.contiguous()
    return x
 
 
def rand_brightness(x):
    x2 = x + (torch.rand(x.size(0), 1, 1, 1, dtype=x.dtype, device=x.device) - 0.5)
    return x2 #x * 0.66 + x2 * 0.34
 
 
def rand_saturation(x):
    x_mean = x.mean(dim=1, keepdim=True)
    x2 = (x - x_mean) * (torch.rand(x.size(0), 1, 1, 1, dtype=x.dtype, device=x.device) * 2) + x_mean
    return x2 #x * 0.66 + x2 * 0.34
 
 
def rand_contrast(x):
    x_mean = x.mean(dim=[1, 2, 3], keepdim=True)
    x2 = (x - x_mean) * (torch.rand(x.size(0), 1, 1, 1, dtype=x.dtype, device=x.device) + 0.5) + x_mean
    return x2 #x * 0.66 + x2 * 0.34
 
 
def rand_translation(x, ratio=args.translation_ratio):#was 0.125
    shift_x, shift_y = int(x.size(2) * ratio + 0.5), int(x.size(3) * ratio + 0.5)
    translation_x = torch.randint(-shift_x, shift_x + 1, size=[x.size(0), 1, 1], device=x.device)
    translation_y = torch.randint(-shift_y, shift_y + 1, size=[x.size(0), 1, 1], device=x.device)
    grid_batch, grid_x, grid_y = torch.meshgrid(
        torch.arange(x.size(0), dtype=torch.long, device=x.device),
        torch.arange(x.size(2), dtype=torch.long, device=x.device),
        torch.arange(x.size(3), dtype=torch.long, device=x.device),
    )
    grid_x = torch.clamp(grid_x + translation_x + 1, 0, x.size(2) + 1)
    grid_y = torch.clamp(grid_y + translation_y + 1, 0, x.size(3) + 1)
    x_pad = F.pad(x, [1, 1, 1, 1, 0, 0, 0, 0])
    x = x_pad.permute(0, 2, 3, 1).contiguous()[grid_batch, grid_x, grid_y].permute(0, 3, 1, 2).contiguous()
    return x
 
 
def rand_cutout(x, ratio=args.cutout_ratio):#was 0.5
    cutout_size = int(x.size(2) * ratio + 0.5), int(x.size(3) * ratio + 0.5)
    offset_x = torch.randint(0, x.size(2) + (1 - cutout_size[0] % 2), size=[x.size(0), 1, 1], device=x.device)
    offset_y = torch.randint(0, x.size(3) + (1 - cutout_size[1] % 2), size=[x.size(0), 1, 1], device=x.device)
    grid_batch, grid_x, grid_y = torch.meshgrid(
        torch.arange(x.size(0), dtype=torch.long, device=x.device),
        torch.arange(cutout_size[0], dtype=torch.long, device=x.device),
        torch.arange(cutout_size[1], dtype=torch.long, device=x.device),
    )
    grid_x = torch.clamp(grid_x + offset_x - cutout_size[0] // 2, min=0, max=x.size(2) - 1)
    grid_y = torch.clamp(grid_y + offset_y - cutout_size[1] // 2, min=0, max=x.size(3) - 1)
    mask = torch.ones(x.size(0), x.size(2), x.size(3), dtype=x.dtype, device=x.device)
    mask[grid_batch, grid_x, grid_y] = 0
    x = x * mask.unsqueeze(1)
    return x
 
 
AUGMENT_FNS = {
    'color': [rand_brightness, rand_saturation, rand_contrast],
    'translation': [rand_translation],
    'cutout': [rand_cutout],
}

# === Set up your prompt texts
# ===
#prompt = perceptor.encode_text(clip.tokenize(["arkhip kuindzhi, Sunset in the winter", "Konstantin Makovsky, A coast of the sea"]).to(device)).mean(0,True)
prompt = perceptor.encode_text(clip.tokenize([args.input_phrase]).to(device)).mean(0,True)


# === This is an absurdly long collection of prompts that I had hoped would catch the formation of text and let me punish the bad boy for writing on the walls
# === But it doesn't necessarily work all that well.
# ===
textprompt = perceptor.encode_text(clip.tokenize(["word","words","letter","letters","font","fonts","typeface","typefaces","writing","text","logo","logos","branding","brands","phrase","phrases","quotes","quote","words","word","text","font","fonts","alphabet","uppercase letters","uppercase letter","lowercase letters","lowercase letter"]).to(device)).mean(0,True)

# === These two prompts have worked well enough? I guess? For catching the formation of text, but you just can't be certain.
# ===
# textprompt = perceptor.encode_text(clip.tokenize(["watermark", "logo"]).to(device)).mean(0,True)


# === This is a prompt meant to help catch and punish the generation of messes, but does it help? I don't know.
# ===
clusterprompt = perceptor.encode_text(clip.tokenize(["claustrophobia", "claustrophobic", "cramped and messy", "inside a hoarder's apartment", "crowded", "crowds of people", "rush hour crowds"]).to(device)).mean(0,True)

# === Palette list
# ===
lisafrank_0 = torch.tensor([[14,123,210],[255,220,229],[245,233,4],[19,0,52],[224,0,42],[57,163,17]]).float().div(255).to(device)
c64_vic2_0 = torch.tensor([[0,0,0],[255,255,255],[129,51,56],[117,206,200],[142,60,151],[86,172,77],[46,44,155],[237,241,113],[142,80,41],[85,56,0],[196,108,113],[74,74,74],[123,123,123],[169,255,159],[112,109,235],[178,178,178]]).float().div(255).to(device)
random_0 = torch.tensor([[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)],[random.randint(0,255),random.randint(0,255),random.randint(0,255)]]).float().div(255).to(device)
custom_0 = torch.tensor([[0,0,0],[8,0,0],[15,0,0],[22,0,0],[30,0,0],[38,0,0],[45,0,0],[53,0,0],[60,0,0],[68,0,0],[75,0,0],[82,0,0],[90,0,0],[98,0,0],[105,0,0],[113,0,0],[120,0,0],[128,0,0],[135,0,0],[142,0,0],[150,0,0],[158,0,0],[165,0,0],[172,0,0],[180,0,0],[188,0,0],[195,0,0],[203,0,0],[210,0,0],[218,0,0],[225,0,0],[233,0,0],[240,0,0],[248,0,0],[255,0,0],[255,0,0],[255,0,0],[255,4,0],[255,8,1],[255,12,1],[255,16,1],[255,19,1],[255,23,2],[255,27,2],[255,31,2],[255,35,2],[255,39,3],[255,43,3],[255,47,3],[255,50,3],[255,54,4],[255,58,4],[255,62,4],[255,66,4],[255,70,5],[255,74,5],[255,78,5],[255,82,6],[255,85,6],[255,89,6],[255,93,6],[255,97,7],[255,101,7],[255,105,7],[255,109,7],[255,113,8],[255,116,8],[255,120,8],[255,124,8],[255,128,9],[255,132,9],[255,132,9],[255,132,9],[255,136,9],[255,139,8],[255,143,8],[255,146,8],[255,150,8],[255,154,7],[255,157,7],[255,161,7],[255,165,7],[255,168,6],[255,172,6],[255,175,6],[255,179,6],[255,183,5],[255,186,5],[255,190,5],[255,194,4],[255,197,4],[255,201,4],[255,204,4],[255,208,3],[255,212,3],[255,215,3],[255,219,3],[255,222,2],[255,226,2],[255,230,2],[255,233,2],[255,237,1],[255,241,1],[255,244,1],[255,248,1],[255,251,0],[255,255,0],[255,255,0],[255,255,0],[248,251,0],[240,248,0],[232,244,0],[225,240,0],[218,236,0],[210,233,0],[202,229,0],[195,225,0],[188,221,0],[180,218,0],[172,214,0],[165,210,0],[158,206,0],[150,203,0],[142,199,0],[135,195,0],[128,192,0],[120,188,0],[112,184,0],[105,180,0],[98,177,0],[90,173,0],[82,169,0],[75,165,0],[67,162,0],[60,158,0],[52,154,0],[45,150,0],[37,147,0],[30,143,0],[22,139,0],[15,135,0],[7,132,0],[0,128,0],[0,128,0],[0,128,0],[0,124,6],[0,120,12],[0,117,19],[0,113,25],[0,109,31],[0,105,37],[0,102,43],[0,98,49],[0,94,56],[0,90,62],[0,87,68],[0,83,74],[0,79,80],[0,75,86],[0,72,93],[0,68,99],[0,64,105],[0,60,111],[0,56,117],[0,53,124],[0,49,130],[0,45,136],[0,41,142],[0,38,148],[0,34,154],[0,30,161],[0,26,167],[0,23,173],[0,19,179],[0,15,185],[0,11,191],[0,8,198],[0,4,204],[0,0,210],[0,0,210],[0,0,210],[4,0,211],[8,0,213],[11,0,214],[15,0,215],[19,0,217],[23,0,218],[26,0,219],[30,0,221],[34,0,222],[38,0,223],[41,0,225],[45,0,226],[49,0,227],[53,0,229],[56,0,230],[60,0,231],[64,0,232],[68,0,234],[72,0,235],[75,0,236],[79,0,238],[83,0,239],[87,0,240],[90,0,242],[94,0,243],[98,0,244],[102,0,246],[105,0,247],[109,0,248],[113,0,250],[117,0,251],[120,0,252],[124,0,254],[128,0,255],[128,0,255],[128,0,255],[128,0,251],[128,0,248],[128,0,244],[128,0,240],[128,0,236],[128,0,233],[128,0,229],[128,0,225],[128,0,221],[128,0,218],[128,0,214],[128,0,210],[128,0,206],[128,0,203],[128,0,199],[128,0,195],[128,0,192],[128,0,188],[128,0,184],[128,0,180],[128,0,177],[128,0,173],[128,0,169],[128,0,165],[128,0,162],[128,0,158],[128,0,154],[128,0,150],[128,0,147],[128,0,143],[128,0,139],[128,0,135],[128,0,132],[128,0,128],[128,0,128],[128,0,128],[128,0,128],[128,0,128],[128,0,128]]).float().div(255).to(device)

# === Palette selection
# ===
Palette = custom_0

# === The "image" to optimize. The sides, and then the number of colors in the palette. It does that last one automatically.
noise = torch.randn(args.image_size, args.image_size, Palette.shape[0]).to(device).requires_grad_(True)

# === The warpmap / flowmap that helps push pixels around. It's set up for a square right now but I'm sure it could be changed to non-square shapes and sizes.
# === I'm not familiar enough with mesh grids to do this without trial and error though. If you want non-squares, you gotta figure this one out.
# === https://pytorch.org/docs/stable/generated/torch.meshgrid.html#torch.meshgrid
# ===
img_warpmap_size = args.image_size
img_warpmap_base = torch.meshgrid((torch.linspace(-1,1,img_warpmap_size), torch.linspace(-1,1,img_warpmap_size)))
img_warpmap_base = torch.cat(img_warpmap_base, 0).reshape(1,2,img_warpmap_size,img_warpmap_size).permute(0,3,2,1).to(device)
img_warpmap = torch.rand_like(img_warpmap_base).to(device).requires_grad_(True)

# === The number of slices / cuts / crops that are taken from the image to be handed off to CLIP
# === In reality it's 3x this amount, but with a 448x448 image and 32 (*3) it runs just fine on even the little baby GPUs you sometimes get
# ===
slice_count = args.num_cutouts #originally 32

# === The optimizer. Are these the best settings? I don't know. It looks fine.
# === The default settings were 0.1 for img_warpmap and noise, with weight decay of 0.002 as a reminder if you change these and want to go back to the original values.
# ===
optimizer = torch.optim.AdamW([
                {'params': noise},
                {'params': img_warpmap, 'lr': args.learning_rate}
            ], lr=args.learning_rate, weight_decay=0.002)
# === Scheduler that lowers the learn rate by 0.9x every 5 steps of the scheduler, but it's not even enabled so don't worry about it.
# === You can put it back in if you want.
# ===
scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.9)

torch.set_grad_enabled(True)

# === A good chunk of these functions aren't used anymore but feel free to chop and screw it.
# ===
def HardTanh(x):
    x = x*2.0-1.0
    x = torch.tanh(x+x**5*.5)
    x = x*0.5+0.5
    return x

def faux_clip(x):
    x = torch.tanh(x*1.06014+x**3*-0.249866+x**5*1.27222)
    return x

padded = T.Pad(16, padding_mode='reflect')
random_resized_crop = T.RandomResizedCrop(224, (0.4, 1.0))
random_224crop = torch.nn.Sequential(T.RandomCrop((224)),T.Resize((224,224)),)
random_336crop = torch.nn.Sequential(T.RandomCrop((336)),T.Resize((224,224)),)
random_448crop = torch.nn.Sequential(T.RandomCrop((448)),T.Resize((224,224)),)
jitter_448crop = torch.nn.Sequential(T.Pad(1, padding_mode='reflect'),T.RandomCrop((448)),)
random_rotate = T.RandomAffine(degrees=45)
random_perspective = T.RandomPerspective(0.2, 0.333)

Basic_Augs = torch.nn.Sequential(
    T.Pad(padding=38, padding_mode='edge'),
    T.RandomAffine(degrees=10),
    T.RandomResizedCrop((224,224),scale=(0.2,1.0),ratio=(1.0/1.0, 1.0/1.0)),
    T.Normalize((0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711)),
)

def Shear_Img(img, amount):
    for d in range(img.shape[-1]):
      shear_amount = (d-img.shape[-1])//(img.shape[-1] / (amount+1))
      shear_test = img
      shear_test[:,:,d] = torch.roll(img,int(shear_amount),-1)[:,:,d]
      return shear_test

def Random_Shear(img, amount, prob):
    dice_roll = torch.rand((1,)).item()
    shear_range = torch.rand((1,)).item() * amount
    if dice_roll >= prob:
        return Shear_Img(img, shear_range)
    else:
        return img

def random_grayscale(img, prob):
    dice_roll0 = torch.rand((1,)).item()
    dice_roll1 = torch.rand((1,)).item()
    if dice_roll0 >= prob:
        return torch.lerp(img, TF.rgb_to_grayscale(img), dice_roll1)
    else:
        return img

def Random_Translation(img, amount):
    x = int(torch.rand((1,)).item() * amount - amount//2)
    y = int(torch.rand((1,)).item() * amount - amount//2)
    return torch.roll(img, (x,y), (-1,-2))

def random_crops(img):
    return torch.cat([random_224crop(img), random_336crop(img), random_448crop(img)])

def get_crop_weights(count, min=0):
    return torch.cat([torch.tensor([0.0, 0.5, 1.0]) for _ in range(count)]).to(device) * (1-min) + min

def partial_normalization(img, mix):
    return CLIP_Normalization(img) * mix + img * (1.0-mix)

def partial_autocontrast(img, mix):
    auto = img - img.min()
    auto = auto / (auto.max() + 0.001)
    return auto * mix + img * (1.0-mix)

def low_freq_normalization(img):
    lowpass = TF.gaussian_blur(img)
    return img - lowpass + CLIP_Normalization(lowpass)

vignette = torch.linspace(-1,1,224).unsqueeze(0).tile(224,1).unsqueeze(0)
vignette = torch.cat((vignette, vignette.rot90(1,(-1,-2))))
vignette = torch.sqrt(vignette[0]**2 + vignette[1]**2)
vignette = vignette.clamp(0,1)**4
vignette = vignette.sub(vignette.min())
vignette = 1 - vignette.div(vignette.max())
vignette = vignette.unsqueeze(0).unsqueeze(0).to(device)
vignette448 = TF.resize(vignette, 448)

def noise_vignette(shape):
    return torch.cat([(torch.round(vignette**1 + torch.rand_like(vignette)*0.75).clamp(0,1)) for i in range(shape.shape[0])])

def noise_vignette448():
    return torch.round(vignette448 + torch.rand_like(vignette448)*0.75).clamp(0,1)

def rect_to_polar(input):
    input = input.permute(0,3,1,2)
    x = input[:,0,:,:].unsqueeze(0)
    y = input[:,1,:,:].unsqueeze(0)
    dist = torch.sqrt(torch.square(x)+torch.square(y))
    angl = torch.atan2(x,y)
    output = input
    output[:,0,:,:] = angl[:,0,:,:]
    output[:,1,:,:] = dist[:,0,:,:]
    return output.permute(0,2,3,1)

def polar_to_rect(input, distance_multiplier=1):
    input = input.permute(0,3,1,2)
    angl = input[:,0,:,:].unsqueeze(0)
    #dist = input[:,1,:,:].unsqueeze(0)
    dist = 1.0/448.0
    dist = distance_multiplier * dist
    x = dist * torch.cos(angl * 3.14159265359)
    y = dist * torch.sin(angl * 3.14159265359)
    output = input
    #output[:,1,:,:,] = x[:,0,:,:]
    #output[:,0,:,:,] = y[:,0,:,:]
    output = torch.cat([x[:,0,:,:].unsqueeze(0),y[:,0,:,:].unsqueeze(0)], 1)
    return output.permute(0,2,3,1)

# Value becomes "fake", gradient is from "real"
def replace_grad(fake, real):
    return fake.detach() - real.detach() + real

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

def Random_Normalization(img, prob):
    dice_roll = torch.rand((1,)).item()
    if dice_roll >= prob:
        return CLIP_Normalization(img)
    else:
        return img

def roll_stack(img):
    img_stack = []
    for x in range(3):
        for y in range(3):
            img_stack.append(img.roll((y-1,x-1),(-2,-1)).unsqueeze(0))
    return torch.cat(img_stack)

weights_3x3 = torch.tensor([1.0, 2.0, 1.0, 2.0, 3.0, 2.0, 1.0, 2.0, 1.0]).unsqueeze(-1).unsqueeze(-1).unsqueeze(-1).sqrt().div(3**0.5).to(device)
weights_3x3_neg = weights_3x3
weights_3x3_neg[4] = -1.0
weights_3x3_neg = 0-weights_3x3_neg

def median_filter(img, width=1, circle=False):
    rolls = []
    for x in range(0-width, width+1):
        for y in range(0-width, width+1):
            distance = 0
            if circle == True:
                distance = torch.dist(torch.tensor((x,y)).float(),torch.tensor((0,0)).float())
            if distance <= width or circle == False:
                roll = torch.roll(img, (x,y), dims=(-2,-1)).unsqueeze(0)
                rolls.append(roll)
    del roll
    rolls = torch.cat(rolls, 0)
    median = torch.quantile(rolls, 0.5, dim=0)
    del rolls
    return median

def softmax_filter(img, width=1, circle=False):
    rolls = []
    for x in range(0-width, width+1):
        for y in range(0-width, width+1):
            distance = 0
            if circle == True:
                distance = torch.dist(torch.tensor((x,y)).float(),torch.tensor((0,0)).float())
            if distance <= width or circle == False:
                roll = torch.roll(img, (x,y), dims=(-2,-1)).unsqueeze(0)
                rolls.append(roll)
    del roll
    rolls = torch.cat(rolls, 0)
    softmaxed = torch.nn.functional.softmax(rolls, dim=0)
    del rolls
    return softmaxed.mean(0)

def minmax_filter(img, mode='min', width=1, circle=False):
    rolls = []
    for x in range(0-width, width+1):
        for y in range(0-width, width+1):
            distance = 0
            if circle == True:
                distance = torch.dist(torch.tensor((x,y)).float(),torch.tensor((0,0)).float())
            if distance <= width or circle == False:
                roll = torch.roll(img, (x,y), dims=(-2,-1)).unsqueeze(0)
                rolls.append(roll)
    del roll
    rolls = torch.cat(rolls, 0)
    if mode == 'min':
        output = torch.min(rolls, dim=0).values
    else:
        output = torch.max(rolls, dim=0).values
    del rolls
    return output

expand_or_contract = 'min'
with torch.set_grad_enabled(False):
    old_noise = noise.detach()

# === The actual training loop happens here.
# ===
for i in range(args.iterations):

    # === Warp the image around a bit to let the optimizer push the pixels around and move
    # === This won't actually be used in this step, but it will be added to the image after the optimizer step and will appear in the next step's image
    # ===
    edit_warpmap = polar_to_rect(clamp_with_grad(img_warpmap,-1,1), 1.0) + img_warpmap_base
    sampled_noise = torch.nn.functional.grid_sample(noise.T.unsqueeze(0), edit_warpmap, padding_mode="border", align_corners=True).squeeze(0).T
    del edit_warpmap

    # === CLIP is only going to see this step's non-warped image, but I need the optimizer to know that it has a direct effect on the image
    # === So I'm putting the gradient of the warped image on the non-warped image.
    # === It appears to work well enough despite it sounding silly.
    # ===
    fake_noise = replace_grad(noise, sampled_noise)
    noise_tile0 = (fake_noise.mul(8).softmax(-1) @ Palette.pow(0.5)).pow(2).T.unsqueeze(0)
    del fake_noise
    noise_prep0 = (faux_clip((noise_tile0)*2-1)*0.5+0.5)
    del noise_tile0

    # === Some wild augmentations meant to get crops that were normalized to have a better chance of identifying what's pictured in that crop,
    # === and some crops that were not normalized to have a better chance of recognizing how dark or bright an area is supposed to be.
    # === Also 3 different sizes of crops whose similarities to the prompts are later weighted differently such that the similarity of the
    # === bigger crops is scaled up as the similarity of the smaller crops goes up, and if the similarity of the smaller crops goes down then
    # === the similarity of the bigger crops is scaled down. Maybe this is helpful. Maybe not. It seems to be though.
    # ===
    img_stack0 = torch.cat([partial_autocontrast(random_crops((DiffAugment(padded(Random_Normalization(random_grayscale(noise_prep0,0.333),0.5)), 'color,cutout,translation'))), 0.333) for i in range(slice_count)])
    img_stack0 = img_stack0 * noise_vignette(img_stack0)

    img_stack0_encoded = perceptor.encode_image(img_stack0)
    del img_stack0

    img_stack0_antitext = torch.cosine_similarity(img_stack0_encoded, textprompt)**2 * 4 # These numbers were arbitrary.
    img_stack0_anticluster = torch.cosine_similarity(img_stack0_encoded, clusterprompt)**2 * 1 # These numbers were arbitrary.

    img_stack0_similarity = torch.cosine_similarity(img_stack0_encoded, prompt) - img_stack0_antitext - img_stack0_anticluster
    img_stack0_similarity = ((img_stack0_similarity) * get_crop_weights(slice_count, 0.3)) / (2 - img_stack0_similarity * (get_crop_weights(slice_count).mul(-0.8).add(1.9))).mean()

    loss = (1.0 - img_stack0_similarity).sum()


    loss.backward()
    optimizer.step()
    # === This here is that unused scheduler for slowing down the learning rate. The numbers are arbitrary.
    # ===
    #if i < 5*8:
    #    scheduler.step()
    optimizer.zero_grad()


    with torch.set_grad_enabled(False):
        # === I haven't checked it yet since it was in the heat of the moment while dealing with out of memory issues on a little babby GPU,
        # === But I think detaching the tensors that I'm using in this section cuts down on memory usage? Though, detach should just strip their
        # === gradients, and grad is already disabled in this section. It could have started working again for unrelated reasons after this change.
        # ===

        # === Expand every so often by taking the maximum value in a 3px radius around each pixel, and then fade out over time
        # ===
        if i % 10 == 0:
            minmax_noise = minmax_filter(noise.detach().T * 0.8 + sampled_noise.detach().T * 0.2, 'max', 3, True).T
            old_noise = minmax_noise
            del minmax_noise
                
        # === Without the optimizer knowing, the previous step's image is mixed in as well as the image that was pushed around by the grid sampler / warp map.
        # === I don't trust the optimizer to do what I want if it knew what was going on.
        # === It's worked well so far.
        # ===
        noise[:] = (noise * 0.8 + sampled_noise.detach() * 0.2) * 0.8 + old_noise * 0.2

        # === Update the value for the old image.
        # ===
        old_noise = noise.detach() * 0.1 + old_noise * 0.9

        # === Diffuse the warpmap by blending in some gaussian blur
        # ===
        warp_tmp0 = TF.gaussian_blur(img_warpmap[0].T, 3).T.unsqueeze(0)
        img_warpmap[:] = img_warpmap * 0.95 + warp_tmp0 * 0.05
        del warp_tmp0

        sys.stdout.flush()
        sys.stdout.write("Iteration {}".format(i)+"\n")
        sys.stdout.flush()
        # === Preparing the image to save
        # ===
        img_out0 = noise_prep0
        # === Fitting to (0,1) range by using a gaussian blur to get the min and max so as to avoid outliers. Good enough.
        # ===
        img_out0 -= TF.gaussian_blur(img_out0, 7).min()
        img_out0 /= TF.gaussian_blur(img_out0, 7).max()
        # === Mix in a bit of the non-min/max'd image in case it overshot. Just clip it to (0,1) later.
        # ===
        img_out0 = img_out0 * 0.9 + noise_prep0 * 0.1
        img_out0 = ToImage(img_out0[0].clamp(0,1)).convert("RGB")
        #img_out0.save('output/' + str(i).zfill(8) + '.png')
        #img_out0.save(str(i).zfill(8) + '.png')
        #img_out0.save('progress.png')
        if i % args.save_every == 0:
            sys.stdout.write("Saving progress ...\n")
            sys.stdout.flush()
            #print(loss.item())
            #display.display(img_out0)

            img_out0.save(args.image_file)
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
                img_out0.save(save_name)
            
            
            sys.stdout.write("Progress saved\n")
            sys.stdout.flush()
