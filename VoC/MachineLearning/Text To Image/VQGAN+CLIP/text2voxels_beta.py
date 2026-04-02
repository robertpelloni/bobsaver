# text2voxels beta
# Original file is located at https://colab.research.google.com/drive/1y0cR5goZ2go6SlYqVIZy7e7g0cOE3prE

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from CLIP import clip

import random
import torch
import math
import os
import gc
import time
import torch
import random
import numpy as np
import torchvision
from PIL import Image
from math import ceil
from base64 import b64encode
from ipywidgets import Output
from IPython.display import HTML
from more_itertools import chunked
from tqdm.auto import trange, tqdm
from subprocess import Popen, PIPE
from matplotlib import pyplot as plt
from IPython.display import display, clear_output
import argparse



sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--seed', type=int, help='Random seed.')
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


device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

clip_version = "ViT-B/16"  #@param ["ViT-B/16", "ViT-B/32", "RN50", "RN50x4"] {type: "string", allow-input: true}

sys.stdout.write(f"Loading {clip_version} ...\n")
sys.stdout.flush()

model, preprocess = clip.load(clip_version, jit=False)




#@markdown lowering to 0.2 sometimes improves the results
noise_level = 0.5  #@param {type: "number"}


def rand_perlin_2d(shape, res, fade = lambda t: 6*t**5 - 15*t**4 + 10*t**3):
    delta = (res[0] / shape[0], res[1] / shape[1])
    d = (shape[0] // res[0], shape[1] // res[1])
    
    grid = torch.stack(torch.meshgrid(torch.arange(0, res[0], delta[0]), torch.arange(0, res[1], delta[1])), dim = -1) % 1
    angles = 2*math.pi*torch.rand(res[0]+1, res[1]+1)
    gradients = torch.stack((torch.cos(angles), torch.sin(angles)), dim = -1)
    
    tile_grads = lambda slice1, slice2: gradients[slice1[0]:slice1[1], slice2[0]:slice2[1]].repeat_interleave(d[0], 0).repeat_interleave(d[1], 1)
    dot = lambda grad, shift: (torch.stack((grid[:shape[0],:shape[1],0] + shift[0], grid[:shape[0],:shape[1], 1] + shift[1]  ), dim = -1) * grad[:shape[0], :shape[1]]).sum(dim = -1)
    
    n00 = dot(tile_grads([0, -1], [0, -1]), [0,  0])
    n10 = dot(tile_grads([1, None], [0, -1]), [-1, 0])
    n01 = dot(tile_grads([0, -1],[1, None]), [0, -1])
    n11 = dot(tile_grads([1, None], [1, None]), [-1,-1])
    t = fade(grid[:shape[0], :shape[1]])
    return math.sqrt(2) * torch.lerp(torch.lerp(n00, n10, t[..., 0]), torch.lerp(n01, n11, t[..., 0]), t[..., 1])

def rand_perlin_2d_octaves(shape, res, octaves=1, persistence=0.5):
    noise = torch.zeros(shape)
    frequency = 1
    amplitude = 1
    for _ in range(octaves):
        noise += amplitude * rand_perlin_2d(shape, (frequency*res[0], frequency*res[1]))
        frequency *= 2
        amplitude *= persistence
    noise *= random.random() - noise_level  # haha
    noise += random.random() - noise_level  # haha x2
    return noise



model.requires_grad_(False)
# img_url = "https://media.discordapp.net/attachments/730484623028519072/919340782891204618/Untitled12_20211211162701.png?width=1137&height=1137" #@param {type: "string"}
# img_url = "https://upload.wikimedia.org/wikipedia/commons/3/3e/Tree-256x256.png"
img_url = ""
#if img_url:
#    !wget "{img_url}" -O source.png
#@markdown set to zero for no seed
seed = 0  #@param {type: "integer"}
#@markdown ## video settings
#@markdown image size
w = 224  #@param {type: "integer"}  # for CLIP
#@markdown frames per second
fps = 15  #@param {type: "integer"}
out_path = "video.mp4"  #@param {type: "string"}
#@markdown ## text
text = args.prompt #"a cute creature"  #@param ["a white rabbit", "a beautiful bonsai tree", "beautiful pine trees", "a cute creature", "chtulhu is watching", "a frog", "a robot dog. a robot in the shape of a dog", "a carrot", "personal computer", "golden pyramid", "golden snitch", "a new planet ruled by ophanims", "a blue cat", "a burning potato", "an eggplant", "a purple mouse", "a ninja", "a green teapot", "a black rabbit", "an avocado armchair", "smoking a joint", "3D old-school telephone", "a wooden chair", "spider-man figure", "a 3D monkey #pixelart", "a minecraft grass block", "minecraft creeper", "minecraft landscape", "a shining star"] {allow-input: true}
#@markdown make the name of the output video the same as the text
text_out = True  #@param {type: "boolean"}
#@markdown rename the output video if it exists
rename_out = True  #@param {type: "boolean"}
#@markdown ## learning
train_steps =    args.iterations #1000#@param {type: "integer"}
#@markdown stop training after `time_stop` seconds. negative values are ignored

#@markdown stops after two minutes by default.

#@markdown you can stop the generation process manually
time_stop =    -1#@param {type: "number"}
#@markdown note: it breaks if you change these.
grad_acc = 8#@param {type: "integer"}
train_batch =   2#@param {type: "integer"}
lr =   5e-2#@param {type: "number"}
fp16 = False  #@param {type: "boolean"}
# and especially those
#@markdown ## rendering settings
#@markdown size of the box
extent =   1.2#@param {type: "number"}  # 1.28 # 1.3  # 1  # 1.5
#@markdown bilinear interpolation (runs out of memory)
use_weights = False  #@param {type: "boolean"}
#@markdown near and far planes for the camera
near =   1#@param {type: "number"}
far =   5#@param {type: "number"}
#@markdown size of the FOV plane. 1 for 90 degrees, more for more
fov_plane =  1 #@param {type: "number"}
#@markdown side of the box
block_size = 128  #@param {type: "integer"}  # 64
#@markdown density at the edges
mask_value = 0  #@param {type: "number"}
#@markdown default camera offset and angle
offset =   3#@param {type: "number"}
angle = 0  #@param {type: "number"}
#@markdown starting scale for the pyramid
scale_from =   1#@param {type: "integer"}
#@markdown how much the scale grows (exponentially)
scale_decay = 0.2  #@param {type: "number"}  # 0.5
#@markdown raise the scale while training? (not implemented)
scale_schedule = False  #@param. {type: "boolean"}
#@markdown initialization density
start_density = 0.05  #@param {type: "number"}
#@markdown number of raycasting steps
steps = 100  #@param {type: "integer"}
#@markdown background color
bg_color = 0.9  #@param {type: "number"}
#@markdown grayscale rendering (experimental)
grayscale = False  #@param {type: "boolean"}
#@markdown ## objective settings

#@markdown similarity to image prompt. unused
mse_coeff = 0  #@param {type: "number"}
#@markdown L2 regularization. reg_color: regularize RGB apart from density?
reg_coeff = 3  #@param {type: "number"}  # 1
reg_color = True  #@param {type: "boolean"}
#@markdown TV regularization, increase this to 4 or 5 to make the image smoother if it is too noisy
tv_coeff =   3#@param {type: "number"}  # 1050
#@markdown CLIP weight
clip_coeff = 20  #@param {type: "number"}  # 4
#@markdown spherical regularization coefficient. making this higher "shrinks" the shape. this is preferred for making the image more coherent over tau_coeff
spherical_coeff =    35#@param {type: "number"}  # 100
#@markdown weighting for size of the virtual sphere. raise this to make the shape a little bigger
sphere_size =   20#@param {type: "number"}
#@markdown tau regularization from dream fields. tau_target limits the shape's visual size and the coefficient while tau_coeff makes the shape disappear faster
tau_coeff =   5#@param {type: "number"}
tau_target = 0.2  #@param {type: "number"}  # 0.18  # 0.25  # 0.2 * 0.5
#@markdown ranges for random azimuth, altitude and offset shifts (augmentations)
shuffle_ang =   10#@param {type: "number"}  # 1.28  # 10  # 0.1
shuffle_altitude = 0.0  #@param {type: "number"}  # 0.1
shuffle_offset =   0.1#@param {type: "number"}
shuffle_xy =   0.1#@param {type: "number"}  # 1.28  # 10  # 0.1
first_for = 3  #@param {type: "number"}
#@markdown ## timing settings
#@markdown how long to spin before training, showing the empty cube
spin_before = 1  #@param {type: "integer"}
#@markdown how long to spin after training
spin_length = 60  #@param {type: "integer"}
#@markdown how many spins to perform after training
spin_number = 2  #@param {type: "integer"}
#@markdown number of frames to show the still picture for
still_frames = 30  #@param {type: "integer"}
#@markdown how many spins to perform while training
train_spins = 1  #@param {type: "integer"}
#@markdown rotate the visualization while training?
do_rotate = True  #@param {type: "boolean"}
#@markdown skip training when visualizing?
only_spin = False  #@param {type: "boolean"}
#@markdown show how the scene actually looks like or debug images?
spin_quality = True  #@param {type: "boolean"}
#@markdown display the image prompt?
display_img = False  #@param {type: "boolean"}


frames = []


# shape rotator. moves and offsets rays
def prepare(xyd, offset_z, angle_x, angle_y=0, offset_x=0, offset_y=0, batch=1):
    tensorize = lambda x: x.unsqueeze(-1).unsqueeze(-1).unsqueeze(-1) if isinstance(x, torch.Tensor) else x
    xyd = xyd.repeat(batch, 1, 1, 1, 1)
        
    offset_x = tensorize(offset_x)
    offset_y = tensorize(offset_y)
    offset_z = tensorize(offset_z)
    
    xyd[..., 0] += offset_x
    xyd[..., 1] += offset_y
    xyd[..., 2] -= offset_z
    
    a = torch.atan2(xyd[..., 2], xyd[..., 1])
    f = (xyd[..., [1, 2]] ** 2).sum(dim=-1) ** 0.5
    angle_y = tensorize(angle_y)
    a += angle_y
    xyd = torch.stack((xyd[..., 0], torch.cos(a) * f, torch.sin(a) * f), dim=-1)
    
    a = torch.atan2(xyd[..., -1], xyd[..., 0])
    f = (xyd[..., [0, -1]] ** 2).sum(dim=-1) ** 0.5
    angle_x = tensorize(angle_x)
    a += angle_x
    xyd = torch.stack((torch.cos(a) * f, xyd[..., 1], torch.sin(a) * f), dim=-1)
    
    return xyd


# clamp with gradients
def cl(x):
    return torch.relu(1 - torch.relu(1 - x))


# simple 3D voxel renderer. very inefficient, no filtering
@torch.jit.script
def render(color, xyd,
           extent: float = extent,
           bg_color: float = bg_color,
           use_weights: bool = use_weights,
           mask_value: float = mask_value):
    color = torch.nn.functional.pad(color[1:-1, 1:-1, 1:-1],
                                    (0, 0, 1, 1, 1, 1, 1, 1),
                                    value=mask_value)
    color = cl(color)
    # idk how to do bilinear interpolation in 3D so this entire section is just that
    with torch.no_grad():
        xyd = xyd / 2 / extent + 0.5
        xyd = xyd.clamp(0, 1)
        xyd *= torch.tensor(color.shape[:-1]).to(color.device) - 1
        rounds = [xyd]
        weights = [torch.ones_like(xyd[..., -1])]
        for dim in range(xyd.shape[-1] * int(use_weights)):
            new_rounds = []
            new_weights = []
            for r, m in zip(rounds, weights):
                d = r[..., dim] - r[..., dim].floor()
                r1 = r.clone()
                r1[..., dim] = r[..., dim].floor()
                new_rounds.append(r1)
                new_weights.append((1 - d) * m)
                r2 = r.clone()
                r2[..., dim] = r[..., dim].ceil()
                new_rounds.append(r2)
                new_weights.append(d * m)
            rounds = new_rounds
            weights = new_weights
        rounds = torch.stack(rounds, dim=-2).long()
        weights = torch.stack(weights, dim=-1)
        for t in range(rounds.shape[-1]):  # [2, 1]
            rounds[..., :t] *= color.shape[t]
        rounds = rounds.sum(dim=-1)
    # this is the actual renderer
    color = color.view((-1, color.shape[-1]))[rounds.ravel(), :].view(rounds.shape + (color.shape[-1],))
    color = color * weights.unsqueeze(-1)
    color = color.sum(dim=-2)
    density = color[..., -1]  # .clone()
    for i in range(density.shape[-1]-2, 0, -1):
        density = torch.cat((density[..., :i], density[..., i:] * (1 - density[..., i-1]).unsqueeze(-1)), dim=-1)
    # density = density.detach()
    rgb = (color * density.unsqueeze(-1)).sum(dim=-2) + bg_color * (1 - density.sum(dim=-1)).unsqueeze(dim=-1)
    return rgb, density.sum(dim=-1)


# total variation regularizer
def tv(x):
    return ((x[1:] - x[:-1]) ** 2).mean() + ((x[:, 1:] - x[:, :-1]) ** 2).mean() + ((x[:, :, 1:] - x[:, :, :-1]) ** 2).mean()


# blur the image for free pyramids
def interpolate(color, grayscale=grayscale):
    new_color = color.permute(3, 0, 1, 2).unsqueeze(0)
    res = torch.zeros_like(new_color)
    s = block_size / (2 ** scale_from)
    p = 1 / (2 ** scale_from)
    j = 0
    total = 0
    while s > 0:
        scale = 2 ** (scale_decay * j)
        res = res + scale * torch.nn.functional.interpolate(
            torch.nn.functional.interpolate(
                new_color, scale_factor=p, mode="trilinear"),
                size=new_color.shape[-3:], mode="trilinear")
        total += scale
        s, p, j = s // 2, p / 2, j + 1  # binary pyramid
    res = res / total
    res = res[0].permute(1, 2, 3, 0)
    if grayscale:
        res = torch.cat((torch.stack((res[..., :-1].mean(dim=-1),) * 3, dim=-1), res[..., -1:]), dim=-1)
    return res


def setup():
    # bad but it works
    global color, src_array, out_path, xyd
    
    if img_url:
        src = Image.open("source.png").resize((w, w)).convert("RGB")
        src_array = torch.from_numpy(np.asarray(src) / 255).to(device)
    else:
        src_array = torch.zeros((w, w, 3), device=device)
    if text_out:
        out_path = text + ".mp4"
    with torch.no_grad():
        y, x = torch.meshgrid(((torch.arange(w, device=device) / w * 2 - 1) * fov_plane,) * 2)
        z = torch.linspace(near, far, steps, device=device)
        xy = torch.stack((x, y), dim=-1)
        d = z.unsqueeze(0).unsqueeze(0).unsqueeze(-1)
        xyd = torch.cat((xy
                            .unsqueeze(-2).unsqueeze(0)
                            .repeat(1, 1, 1, steps, 1),
                            torch.ones_like(d).unsqueeze(0)
                            .repeat(1, w, w, 1, 1)
    ), dim=-1) * d

    frames = []
    voxels = torch.stack(torch.meshgrid(*((torch.arange(block_size, device=device) / block_size * 2 - 1,) * 3)), dim=-1)
    color = (torch.cat((voxels, voxels[..., -1:]), dim=-1).clone() + 1) / 2
    decolor = lambda color: torch.cat((color[..., :-1], torch.ones_like(color)[..., -1:]), dim=-1)
    color = decolor(color)
    color[..., :3] = torch.rand_like(color[..., :3])
    color[..., -1] *= start_density
    color = torch.nn.Parameter(color.detach(), requires_grad=True)


# forward renderer
def spin(length=spin_length, total=None, start=0,
         progress_bar=False, clear=True, frames=frames,
         spins=1):
    if total is None:
        total = length
    out = Output()
    display(out)
    try:
        angles = list(range(start, start+length))
        #tq = tqdm if progress_bar else lambda x: x
        for i in range(start, start+length):
            i = torch.tensor(i, dtype=torch.float32, device=device)
            i *= np.pi * 2 * spins / total
            # clear_output(wait=True)
            # plt.axis("off")
            with torch.inference_mode():
                res = interpolate(color)
                pics = render(
                    res,
                    prepare(xyd, offset, i, batch=1))[0].cpu().numpy()[..., :3]

            img = Image.fromarray((pics[0] * 255).astype(np.uint8))
            
            sys.stdout.flush()
            sys.stdout.write('Saving progress ...\n')
            sys.stdout.flush()

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

            #sys.stdout.write(f"Saving {save_name} ...\n")
            sys.stdout.flush()
            
            Image.fromarray((pics[0] * 255).astype(np.uint8)).save(args.image_file)
            Image.fromarray((pics[0] * 255).astype(np.uint8)).save(save_name)
            
            sys.stdout.flush()
            sys.stdout.write('Progress saved\n')
            sys.stdout.flush()
            
            """
            # plt.imshow(pic)
            # plt.show()
            # time.sleep(0.01)
            for pic in pics:
                
                frames.append(img)
            with out:
                if clear:
                    clear_output(wait=True)
                plt.axis("off")
                plt.imshow(pics[0, ..., :3])
                plt.show()
            """
    except KeyboardInterrupt:
        pass
    

# trainer
def train(text=text, frames=frames):
    global it, bar
    out = Output()
    display(out)
    with torch.no_grad():
        txt_emb = model.encode_text(clip.tokenize(text).to(device))
        txt_emb = torch.nn.functional.normalize(txt_emb, dim=-1)
    optimizer = torch.optim.Adam([color], lr=lr)
    bar = range(train_steps)
    loss_acc = 0
    acc_n = 0
    losses = []
    start_time = time.time()
    try:
        for it in bar:

            sys.stdout.flush()
            sys.stdout.write(f"Iteration {it+1} ...\n")
            sys.stdout.flush()

            rot = (torch.randn(train_batch, device=device)) * shuffle_ang
            rot_y = (torch.randn(train_batch, device=device)) * shuffle_altitude
            offset_x = torch.randn(train_batch, device=device) * shuffle_xy
            offset_y = torch.randn(train_batch, device=device) * shuffle_xy
            res = interpolate(color)
            with torch.cuda.amp.autocast(enabled=fp16):
                img, d = render(res,  # color,
                    prepare(xyd, offset
                            + torch.rand(train_batch, device=device) * shuffle_offset,
                            rot, rot_y, offset_x=offset_x, offset_y=offset_y,
                            batch=train_batch), bg_color=0)
            img = img[..., :3]
            d = d.unsqueeze(-1)
            back = torch.zeros_like(img)
            s = back.shape
            for i in range(s[0]):
              for j in range(s[-1]):
                n = random.choice([7, 14, 28])
                back[i, ..., j] = rand_perlin_2d_octaves(s[1:-1], (n, n)).clip(-0.5, 0.5) + 0.5
            img = img + back * (1 - d)
            pics = img.detach().cpu().numpy()
            if not spin_quality:
                for pic in pics:
                    frames.append(Image.fromarray((pic * 255).astype(np.uint8)))

                sys.stdout.flush()
                sys.stdout.write('Saving progress ...\n')
                sys.stdout.flush()

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

                #sys.stdout.write(f"Saving {save_name} ...\n")
                sys.stdout.flush()
            
                Image.fromarray((pics[0] * 255).astype(np.uint8)).save(args.image_file)
                Image.fromarray((pics[0] * 255).astype(np.uint8)).save(save_name)
            
                sys.stdout.flush()
                sys.stdout.write('Progress saved\n')
                sys.stdout.flush()

            with out:
                clear_output(wait=True)
                #plt.plot(losses)
                #plt.show()
                if not spin_quality:
                    plt.axis("off")
                    plt.imshow(pics[0, ..., :3])
                    #plt.show()
                else:
                    spin(total=len(bar), start=it * int(do_rotate), length=1,
                         progress_bar=False, clear=False, frames=frames, spins=train_spins)
            img_clip = img.permute(0, 3, 1, 2)
            img_clip = torchvision.transforms.Normalize(
                (0.48145466, 0.4578275, 0.40821073), (0.26862954, 0.26130258, 0.27577711))(img_clip)
            img_emb = model.encode_image(img_clip)
            img_emb = torch.nn.functional.normalize(img_emb, dim=-1)
            x, y, z = torch.meshgrid(*(((torch.arange(block_size) - block_size // 2) / (block_size // 2),) * 3))
            x, y, z = x * sphere_size, y * sphere_size, z * sphere_size
            sphere = (x ** 2 + y ** 2 + z ** 2).unsqueeze(0).repeat(train_batch, 1, 1, 1).to(device)
            sphere = sphere / sphere.max()
            spherical_loss = (sphere * (color[..., -1] ** 2) * torch.sign(color[..., -1])).mean()
            clip_loss = (img_emb - txt_emb).norm(dim=-1).div(2).arcsin().pow(2).mul(2).mean()
            mse_loss = ((img - src_array.unsqueeze(0)) ** 2).mean()
            reg_loss = ((color if reg_color else color[..., -1:]) ** 2).mean()
            tv_loss = tv(res)
            tau_loss = d.mean().clamp(tau_target, 100)
            loss = (
                mse_loss * mse_coeff +
                reg_loss * reg_coeff + 
                tv_loss * tv_coeff + 
                clip_loss * clip_coeff +
                tau_loss * tau_coeff +
                spherical_loss * spherical_coeff)
            loss.backward()
            loss_acc += loss.item()
            acc_n += 1
            acc_n += 1
            """
            bar.set_description(f"loss: {loss_acc / max(acc_n, 1)}"
                                f" mse: {mse_loss.item()} reg: {reg_loss.item()}"
                                f" tv: {tv_loss.item()} clip: {clip_loss.item()}"
                                f" tau: {tau_loss.item()} spherical: {spherical_loss.item()}")
            """
            if it % grad_acc == grad_acc - 1:
                optimizer.step()
                optimizer.zero_grad()
                loss_acc /= grad_acc
                losses.append(loss_acc)
                loss_acc = 0
                acc_n = 0
            if time_stop > 0 and time.time() - start_time > time_stop:
                raise KeyboardInterrupt
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    print(text)
    frames = []
    # starting frame
    if display_img:
        frames = [src] * int(fps * first_for)
    seed = 0

    sys.stdout.write("Setup ...\n")
    sys.stdout.flush()

    setup()

    sys.stdout.write("Spin ...\n")
    sys.stdout.flush()

    spin(spin_before, frames=frames)

    sys.stdout.write("Train ...\n")
    sys.stdout.flush()

    train(text=text, frames=frames)

    spin(spin_length*spin_number, total=spin_length*spin_number,
         start=ceil(it/len(bar)*spin_length)+1, frames=frames,
         spins=spin_number)
    frames += [frames[-1]] * still_frames
