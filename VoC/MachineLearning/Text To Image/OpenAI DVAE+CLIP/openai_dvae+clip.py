# OpenAI dVAE+CLIP.ipynb
# Original file is located at https://colab.research.google.com/drive/10DzGECHlEnL4oeqsN-FWCkIe_sq3wVqt

import argparse
import math
from pathlib import Path
import sys

sys.path.append('./DALL-E')

import dall_e
from IPython import display
from PIL import Image
import torch
from torch import nn, optim
from torch.nn import functional as F
from torchvision import transforms
from torchvision.transforms import functional as TF
from tqdm.notebook import tqdm

from CLIP.clip import clip


sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--batch_size', type=int, help='Number of batches.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--tau', type=float, help='Tau.')
  parser.add_argument('--weight_decay', type=float, help='Weight decay.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--cut_power', type=float, help='Cut power.')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--noise', type=bool, help='Sample outputs - True=noisy images.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  args = parser.parse_args()
  return args

args2=parse_args();

"""## Settings for this run:"""

args = argparse.Namespace(
    prompts=[args2.prompt],
    image_prompts=[],
    noise_prompt_seeds=[],
    noise_prompt_weights=[],
    size=[args2.sizex, args2.sizey],
    init_image=args2.seed_image,
    tv_weight=0.,
    clip_model=args2.clip_model,
    step_size=args2.learning_rate,
    weight_decay=0.,
    noise_scale=1.,
    cutn=args2.cutn,
    cut_pow=args2.cut_power,
    display_freq=args2.update,
    sample_outputs=args2.noise,
    seed=args2.seed,
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

DEAD_CODES = [2, 3, 6, 85, 136, 151, 185, 192, 376, 385, 412, 430, 509, 548, 555, 564, 576, 579, 582, 608, 630, 688, 713, 748, 766, 798, 800, 801, 816, 855, 862, 864, 867, 917, 950, 977, 991, 1001, 1022, 1052, 1054, 1072, 1098, 1102, 1116, 1120, 1122, 1128, 1146, 1152, 1161, 1175, 1192, 1222, 1240, 1268, 1278, 1325, 1355, 1369, 1373, 1388, 1399, 1419, 1480, 1496, 1510, 1517, 1526, 1568, 1574, 1701, 1723, 1745, 1763, 1772, 1807, 1828, 1867, 1877, 1901, 1904, 1906, 1910, 1918, 1920, 1921, 1936, 1966, 1975, 1985, 2025, 2035, 2044, 2045, 2084, 2097, 2125, 2147, 2176, 2191, 2241, 2245, 2321, 2322, 2334, 2335, 2355, 2367, 2437, 2480, 2503, 2588, 2623, 2636, 2651, 2664, 2666, 2674, 2689, 2695, 2718, 2739, 2758, 2767, 2776, 2822, 2827, 2828, 2841, 2845, 2864, 2873, 2899, 3015, 3018, 3033, 3042, 3080, 3088, 3094, 3110, 3137, 3147, 3157, 3182, 3204, 3234, 3246, 3281, 3344, 3354, 3357, 3365, 3395, 3400, 3409, 3431, 3450, 3498, 3525, 3547, 3556, 3569, 3596, 3618, 3630, 3640, 3655, 3727, 3735, 3758, 3787, 3796, 3818, 3856, 3889, 3905, 3906, 3917, 3928, 3929, 3931, 3935, 3961, 4023, 4057, 4063, 4068, 4098, 4102, 4122, 4133, 4163, 4185, 4246, 4250, 4254, 4320, 4324, 4351, 4371, 4376, 4380, 4403, 4404, 4414, 4417, 4458, 4463, 4470, 4555, 4557, 4558, 4564, 4567, 4587, 4603, 4612, 4638, 4650, 4669, 4711, 4757, 4761, 4787, 4828, 4865, 4886, 4908, 4910, 4954, 4956, 4989, 5002, 5025, 5030, 5032, 5084, 5087, 5136, 5190, 5212, 5221, 5271, 5296, 5316, 5349, 5388, 5414, 5437, 5441, 5488, 5502, 5607, 5616, 5656, 5665, 5776, 5789, 5823, 5854, 5879, 5900, 5966, 5996, 6026, 6028, 6032, 6050, 6051, 6079, 6084, 6115, 6127, 6173, 6178, 6213, 6250, 6302, 6324, 6341, 6347, 6379, 6390, 6402, 6432, 6446, 6455, 6491, 6512, 6542, 6584, 6597, 6629, 6644, 6658, 6702, 6711, 6718, 6725, 6772, 6779, 6874, 6888, 6916, 6942, 7050, 7069, 7100, 7114, 7126, 7128, 7204, 7228, 7268, 7288, 7310, 7331, 7335, 7338, 7341, 7348, 7368, 7385, 7403, 7458, 7471, 7513, 7550, 7553, 7555, 7558, 7579, 7597, 7632, 7635, 7641, 7669, 7678, 7731, 7774, 7789, 7802, 7809, 7813, 7832, 7862, 7878, 7904, 7927, 7937, 7943, 7947, 8024, 8042, 8051, 8104, 8130, 8161, 8169, 8180, 8182]

def sinc(x):
    return torch.where(x != 0, torch.sin(math.pi * x) / (math.pi * x), x.new_ones([]))


def lanczos(x, a):
    cond = torch.logical_and(-a < x, x < a)
    out = torch.where(cond, sinc(x) * sinc(x/a), x.new_zeros([]))
    return out / out.sum()


def ramp(ratio, width):
    n = math.ceil(width / ratio + 1)
    out = torch.empty([n])
    cur = 0
    for i in range(out.shape[0]):
        out[i] = cur
        cur += ratio
    return torch.cat([-out[1:].flip([0]), out])[1:-1]


def resample(input, size, align_corners=True):
    n, c, h, w = input.shape
    dh, dw = size

    input = input.view([n * c, 1, h, w])

    if dh < h:
        kernel_h = lanczos(ramp(dh / h, 2), 2).to(input.device, input.dtype)
        pad_h = (kernel_h.shape[0] - 1) // 2
        input = F.pad(input, (0, 0, pad_h, pad_h), 'reflect')
        input = F.conv2d(input, kernel_h[None, None, :, None])

    if dw < w:
        kernel_w = lanczos(ramp(dw / w, 2), 2).to(input.device, input.dtype)
        pad_w = (kernel_w.shape[0] - 1) // 2
        input = F.pad(input, (pad_w, pad_w, 0, 0), 'reflect')
        input = F.conv2d(input, kernel_w[None, None, None, :])

    input = input.view([n, c, h, w])
    return F.interpolate(input, size, mode='bicubic', align_corners=align_corners)
    

class ReplaceGrad(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x_forward, x_backward):
        ctx.shape = x_backward.shape
        return x_forward

    @staticmethod
    def backward(ctx, grad_in):
        return None, grad_in.sum_to_size(ctx.shape)


replace_grad = ReplaceGrad.apply


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


class Prompt(nn.Module):
    def __init__(self, embed, weight=1., stop=float('-inf')):
        super().__init__()
        self.register_buffer('embed', embed)
        self.register_buffer('weight', torch.as_tensor(weight))
        self.register_buffer('stop', torch.as_tensor(stop))

    def forward(self, input):
        input_normed = F.normalize(input.unsqueeze(1), dim=2)
        embed_normed = F.normalize(self.embed.unsqueeze(0), dim=2)
        dists = input_normed.sub(embed_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2)
        dists = dists * self.weight.sign()
        return self.weight.abs() * replace_grad(dists, torch.maximum(dists, self.stop)).mean()


def parse_prompt(prompt):
    vals = prompt.rsplit(':', 2)
    vals = vals + ['', '1', '-inf'][len(vals):]
    return vals[0], float(vals[1]), float(vals[2])


def tv_loss(input):
    """L2 total variation loss, as in Mahendran et al."""
    input = F.pad(input, (0, 1, 0, 1), 'replicate')
    x_diff = input[..., :-1, 1:] - input[..., :-1, :-1]
    y_diff = input[..., 1:, :-1] - input[..., :-1, :-1]
    return (x_diff**2 + y_diff**2).mean()


class MakeCutouts(nn.Module):
    def __init__(self, cut_size, cutn, cut_pow=1.):
        super().__init__()
        self.cut_size = cut_size
        self.cutn = cutn
        self.cut_pow = cut_pow

    def forward(self, input):
        sideY, sideX = input.shape[2:4]
        max_size = min(sideX, sideY)
        min_size = min(sideX, sideY, self.cut_size)
        cutouts = []
        for _ in range(self.cutn):
            size = int(torch.rand([])**self.cut_pow * (max_size - min_size) + min_size)
            offsetx = torch.randint(0, sideX - size + 1, ())
            offsety = torch.randint(0, sideY - size + 1, ())
            cutout = input[:, :, offsety:offsety + size, offsetx:offsetx + size]
            cutouts.append(resample(cutout, (self.cut_size, self.cut_size)))
        return clamp_with_grad(torch.cat(cutouts, dim=0), 0, 1)


def unmap_pixels(x, logit_laplace_eps=0.1):
    return clamp_with_grad((x - logit_laplace_eps) / (1 - 2 * logit_laplace_eps), 0, 1)


def resize_image(image, out_size):
    ratio = image.size[0] / image.size[1]
    area = min(image.size[0] * image.size[1], out_size[0] * out_size[1])
    size = round((area * ratio)**0.5), round((area / ratio)**0.5)
    return image.resize(size, Image.LANCZOS)

"""### Actually do the run..."""

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)

sys.stdout.write("Loading decoder ...\n")
sys.stdout.flush()

decoder = dall_e.load_model('decoder.pkl', device).eval().requires_grad_(False)

sys.stdout.write("Loading encoder ...\n")
sys.stdout.flush()

encoder = dall_e.load_model('encoder.pkl', device).eval().requires_grad_(False)

sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

sys.stdout.write("Initializing ...\n")
sys.stdout.flush()

cut_size = perceptor.visual.input_resolution
f = 8
make_cutouts = MakeCutouts(cut_size, args.cutn, cut_pow=args.cut_pow)
n_toks = decoder.vocab_size
toksX, toksY = args.size[0] // f, args.size[1] // f
sideX, sideY = toksX * f, toksY * f

logit_bias = torch.zeros([n_toks])
for code in DEAD_CODES:
    logit_bias[code] = -100
logit_bias = logit_bias.to(device)

if args.init_image:
    pil_image = Image.open(args.init_image).convert('RGB')
    pil_image = pil_image.resize((sideX, sideY), Image.LANCZOS)
    image = TF.to_tensor(pil_image).to(device).unsqueeze(0)
    logits = encoder(dall_e.map_pixels(image))[0].flatten(1).T
else:
    logits = torch.randn([toksY * toksX, n_toks], device=device)
logits.requires_grad_()
opt = optim.AdamW([logits], lr=args.step_size, weight_decay=args.weight_decay)

normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],
                                 std=[0.26862954, 0.26130258, 0.27577711])

pMs = []

for prompt in args.prompts:
    txt, weight, stop = parse_prompt(prompt)
    embed = perceptor.encode_text(clip.tokenize(txt).to(device)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))

for prompt in args.image_prompts:
    path, weight, stop = parse_prompt(prompt)
    img = resize_image(Image.open(path).convert('RGB'), (sideX, sideY))
    batch = make_cutouts(TF.to_tensor(img)[None].to(device))
    embed = perceptor.encode_image(normalize(batch)).float()
    pMs.append(Prompt(embed, weight, stop).to(device))

for seed, weight in zip(args.noise_prompt_seeds, args.noise_prompt_weights):
    gen = torch.Generator().manual_seed(seed)
    embed = torch.empty([1, perceptor.visual.output_dim]).normal_(generator=gen)
    pMs.append(Prompt(embed, weight).to(device))

def synth(one_hot, sample=False):
    one_hot = one_hot.view([-1, toksY, toksX, n_toks]).permute([0, 3, 1, 2])
    loc, scale = decoder(one_hot).float().chunk(2, dim=1)
    if sample and args.noise_scale:
        im = torch.distributions.Laplace(loc, scale.exp() * args.noise_scale).rsample()
    else:
        im = loc
    return unmap_pixels(im.sigmoid())

@torch.no_grad()
def checkin(i, losses):
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()
    #losses_str = ', '.join(f'{loss.item():g}' for loss in losses)
    #tqdm.write(f'i: {i}, loss: {sum(losses).item():g}, losses: {losses_str}')
    one_hot = F.one_hot(logits.add(logit_bias).argmax(1), n_toks).to(logits.dtype)

    out = synth(one_hot, sample=args.sample_outputs)
    #TF.to_pil_image(out[0].cpu()).save('progress.png')
    outim=TF.to_pil_image(out[0].cpu()).resize((args2.sizex, args2.sizey), Image.LANCZOS)
    
    outim.save(args.image_file)

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
        outim.save(save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()

def ascend_txt():
    probs = logits.add(logit_bias).softmax(1)
    one_hot = F.one_hot(probs.multinomial(1)[..., 0], n_toks).to(logits.dtype)
    one_hot = replace_grad(one_hot, probs)
    out = synth(one_hot, sample=True)
    iii = perceptor.encode_image(normalize(make_cutouts(out))).float()

    result = []

    if args.tv_weight:
        result.append(tv_loss(out) * args.tv_weight / 4)

    for prompt in pMs:
        result.append(prompt(iii))

    return result

def train(i):
    opt.zero_grad()
    lossAll = ascend_txt()
    sys.stdout.write("Iteration {}".format(i)+"\n")
    sys.stdout.flush()
    if i % args.display_freq == 0:
        checkin(i, lossAll)
    loss = sum(lossAll)
    loss.backward()
    opt.step()

sys.stdout.write("Starting...\n")
sys.stdout.flush()

i = 1
while True:
    train(i)
    if i >= args2.iterations:
        break
    i += 1
