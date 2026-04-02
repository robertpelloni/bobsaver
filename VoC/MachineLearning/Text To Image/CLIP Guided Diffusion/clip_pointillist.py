# CLIP Pointillist.ipynb
# Original file is located at https://colab.research.google.com/drive/1XTHi7pv3nT5eSj4qNRAcW8jDOMsLofNJ

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from numpy.core.numeric import False_
from torch._C import LongStorageBase
import sys, os, random, shutil, math
import torch, torchvision
from IPython import display
import numpy as np
from PIL import Image
from CLIP import clip
import torch_optimizer as optim





import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations.')
  parser.add_argument('--update', type=int, help='Iterations per update.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  parser.add_argument('--stage_1_iterations', type=int, help='Stage 1 iterations.')
  parser.add_argument('--stage_2_iterations', type=int, help='Stage 2 iterations.')
  parser.add_argument('--stage_3_iterations', type=int, help='Stage 3 iterations.')
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
    
    


#@title
class Color(object):
    """
    Color class
    """

    def __init__(self, red=0, green=0, blue=0, alpha=None):
        """
        Initialize color
        """
        self.red = int(red)
        self.green = int(green)
        self.blue = int(blue)
        self.alpha = int(alpha)if alpha is not None else None
class OctreeNode(object):
    """
    Octree Node class for color quantization
    """

    def __init__(self, level, parent):
        """
        Init new Octree Node
        """
        self.color = Color(0, 0, 0)
        self.pixel_count = 0
        self.palette_index = 0
        self.children = [None for _ in range(8)]
        # add node to current level
        if level < OctreeQuantizer.MAX_DEPTH - 1:
            parent.add_level_node(level, self)

    def is_leaf(self):
        """
        Check that node is leaf
        """
        return self.pixel_count > 0

    def get_leaf_nodes(self):
        """
        Get all leaf nodes
        """
        leaf_nodes = []
        for i in range(8):
            node = self.children[i]
            if node:
                if node.is_leaf():
                    leaf_nodes.append(node)
                else:
                    leaf_nodes.extend(node.get_leaf_nodes())
        return leaf_nodes

    def get_nodes_pixel_count(self):
        """
        Get a sum of pixel count for node and its children
        """
        sum_count = self.pixel_count
        for i in range(8):
            node = self.children[i]
            if node:
                sum_count += node.pixel_count
        return sum_count

    def add_color(self, color, level, parent):
        """
        Add `color` to the tree
        """
        if level >= OctreeQuantizer.MAX_DEPTH:
            self.color.red += color.red
            self.color.green += color.green
            self.color.blue += color.blue
            self.pixel_count += 1
            return
        index = self.get_color_index_for_level(color, level)
        if not self.children[index]:
            self.children[index] = OctreeNode(level, parent)
        self.children[index].add_color(color, level + 1, parent)

    def get_palette_index(self, color, level):
        """
        Get palette index for `color`
        Uses `level` to go one level deeper if the node is not a leaf
        """
        if self.is_leaf():
            return self.palette_index
        index = self.get_color_index_for_level(color, level)
        if self.children[index]:
            return self.children[index].get_palette_index(color, level + 1)
        else:
            # get palette index for a first found child node
            for i in range(8):
                if self.children[i]:
                    return self.children[i].get_palette_index(color, level + 1)

    def remove_leaves(self):
        """
        Add all children pixels count and color channels to parent node 
        Return the number of removed leaves
        """
        result = 0
        for i in range(8):
            node = self.children[i]
            if node:
                self.color.red += node.color.red
                self.color.green += node.color.green
                self.color.blue += node.color.blue
                self.pixel_count += node.pixel_count
                result += 1
        return result - 1

    def get_color_index_for_level(self, color, level):
        """
        Get index of `color` for next `level`
        """
        index = 0
        mask = 0x80 >> level
        if color.red & mask:
            index |= 4
        if color.green & mask:
            index |= 2
        if color.blue & mask:
            index |= 1
        return index

    def get_color(self):
        """
        Get average color
        """
        return Color(
            self.color.red / self.pixel_count,
            self.color.green / self.pixel_count,
            self.color.blue / self.pixel_count)


class OctreeQuantizer(object):
    """
    Octree Quantizer class for image color quantization
    Use MAX_DEPTH to limit a number of levels
    """

    MAX_DEPTH = 8

    def __init__(self):
        """
        Init Octree Quantizer
        """
        self.levels = {i: [] for i in range(OctreeQuantizer.MAX_DEPTH)}
        self.root = OctreeNode(0, self)

    def get_leaves(self):
        """
        Get all leaves
        """
        return [node for node in self.root.get_leaf_nodes()]

    def add_level_node(self, level, node):
        """
        Add `node` to the nodes at `level`
        """
        self.levels[level].append(node)

    def add_color(self, color):
        """
        Add `color` to the Octree
        """
        # passes self value as `parent` to save nodes to levels dict
        self.root.add_color(color, 0, self)

    def make_palette(self, color_count):
        """
        Make color palette with `color_count` colors maximum
        """
        palette = []
        palette_index = 0
        leaf_count = len(self.get_leaves())
        # reduce nodes
        # up to 8 leaves can be reduced here and the palette will have
        # only 248 colors (in worst case) instead of expected 256 colors
        print("creating palette...")
        for level in range(OctreeQuantizer.MAX_DEPTH - 1, -1, -1):
            if self.levels[level]:
                for node in self.levels[level]:
                    leaf_count -= node.remove_leaves()
                    if leaf_count <= color_count:
                        break
                if leaf_count <= color_count:
                    break
                self.levels[level] = []
        # build palette
        for node in self.get_leaves():
            if palette_index >= color_count:
                break
            if node.is_leaf():
                palette.append(node.get_color())
            node.palette_index = palette_index
            palette_index += 1
        return palette

    def get_palette_index(self, color):
        """
        Get palette index for `color`
        """
        return self.root.get_palette_index(color, 0)

#@title
# Input prompts. Each prompt has "text" and a "weight"
# Weights can be negatives, useful for discouraging specific artifacts
texts = [
    {
        "text": args.prompt, #"Samurai in an autumn forest, detailed fantasy concept art speedpainting artstation",
        "weight": 1.0,
    # },{
    #     "text": "Beautiful and detailed fantasy concept art speedpainting artstation.",
    #     "weight": 0.5,
    # # },{
    # # #     "text": "Full body.",
    # # #     "weight": 0.1,
    # },{ # Improves contrast, object coherence, and adds a nice depth of field effect
    #     "text": "Rendered in unreal engine, trending on artstation.",
    #     "weight": 0.2,
    # },{
    # #     "text": "speedpainting",
    # #     "weight": 0.1,
    # # },{
    # #     "text": "Vivid Colors",
    # #     "weight": 0.15,
    # },{ # Doesn't seem to do much, but also doesn't seem to hurt. 
    #     "text": "confusing, incoherent",
    #     "weight": -0.25,
    # },{ # Helps reduce pixelation, but also smoothes images overall. Enable if you're using scaling = 'nearest'
    #     "text":"pixelated",
    #     "weight":-0.25
    # },{ # Not really strong enough to remove all signatures... but I'm ok with small ones
    #     "text":"text",
    #     "weight":-0.5
    }
]

#Image prompts
images = [
          # {
          #     "fpath": "waste.png",
          #     "weight": 0.2,
          #     "cuts": 16,
          #     "noise": 0.0
          # },{
          #     "fpath": "waste_2.png",
          #     "weight": 0.2,
          #     "cuts": 16,
          #     "noise": 0.0
          # }
          ]


num_points = 1000

min_radius = 1
max_radius = 100
min_softness = 0.01
max_softness = 2

#params for initializing the image
radius_scale = 1 #diversity of initial sizes
radius_shift = -2 # negative = smaller initial points, positive = larger

color_scale = 1.0 #saturation of initial colors
init_alpha_shift = - 1 #negative numbers = more transparent at init

# Put smaller circles on top and larger circles on the bottom at initialization
sort_by_radius = True

# Number of times to run
images_n = 1

# How often to save for the video (can slow things down)
save_interval = args.update

optimizer_type = "Ranger" # "AdamW", "AccSGD","Ranger","RangerQH","RangerVA","AdaBound","AdaMod","Adafactor","AdamP","AggMo","DiffGrad","Lamb","NovoGrad","PID","QHAdam","QHM","RAdam","SGDP","SGDW","Shampoo","SWATS","Yogi"

canvas_size = (args.sizey, args.sizex)

# Learn the color of the canvas
add_global_color = True

# Optimizer settings for different training steps
stages = [
            { #First stage does rough detail. (super-convergence)
        "cuts": 2,
        "cycles": args.stage_1_iterations, #200
        "lr_coords": 10.0,
        "lr_radius": 0.5,
        "radius_decay":1e-6,
        "lr_softness": 0.6,
        "softness_decay": 1e-6,
        "lr_color": 1.0, 
        "color_decay": 1e-6, # decay will bring a value back towards its "average" color
        "noise": 0.2,
        "checkin_interval": 100,
        # "lr_persistence": 0.95, # ratio of small-scale to large-scale detail
        # "pyramid_lr_min" : 1.0, # Percentage of small scale detail
        # "lr_scales": [0.25,0.15,0.15,0.15,0.15,0.05,0.05,0.01,0.01], # manually set lr at each level
    }, { # 2nd stage narrows in 
        "cuts": 2,
        "cycles": args.stage_2_iterations, #1800
        "lr_coords": 1,
        "lr_radius": 0.05,
        "radius_decay":1e-6,
        "lr_softness": 0.2,
        "softness_decay": 1e-6,
        "lr_color": 0.2, 
        "color_decay":1e-6,
        "noise": 0.1,
        "checkin_interval": 100,
        # "lr_persistence": 0.95, # ratio of small-scale to large-scale detail
        # "pyramid_lr_min" : 1.0, # Percentage of small scale detail
        # "lr_scales": [0.25,0.15,0.15,0.15,0.15,0.05,0.05,0.01,0.01], # manually set lr at each level
    },{  # 3rd stage is final polish
        "cuts": 2,
        "cycles": args.stage_3_iterations, #500
        "lr_coords": 0.1,
        "lr_radius": 0.005,
        "radius_decay":1e-8,
        "lr_softness": 0.01,
        "softness_decay": 1e-8,
        "lr_color": 0.02,
        "color_decay":1e-8,
        "noise": 0.01,
        "checkin_interval": 100,
        # "lr_persistence": 0.95, # ratio of small-scale to large-scale detail
        # "pyramid_lr_min" : 1.0, # Percentage of small scale detail
        # "lr_scales": [0.25,0.15,0.15,0.15,0.15,0.05,0.05,0.01,0.01], # manually set lr at each level
    }
]


debug_clip_cuts = False


bilinear = torchvision.transforms.functional.InterpolationMode.BILINEAR
bicubic = torchvision.transforms.functional.InterpolationMode.BICUBIC

torch.autograd.set_grad_enabled(False)
torch.backends.cudnn.benchmark = True
torch.set_default_tensor_type(torch.cuda.FloatTensor)


def normalize_image(image):
  R = (image[:,0:1] - 0.48145466) /  0.26862954
  G = (image[:,1:2] - 0.4578275) / 0.26130258 
  B = (image[:,2:3] - 0.40821073) / 0.27577711
  return torch.cat((R, G, B), dim=1)

@torch.no_grad()
def loadImage(filename):
  data = open(filename, "rb").read()
  image = torch.ops.image.decode_png(torch.as_tensor(bytearray(data)).cpu().to(torch.uint8), 3).cuda().to(torch.float32) / 255.0
  # image = normalize_image(image)
  return image.unsqueeze(0).cuda()

def getClipTokens(image, cuts, noise, do_checkin, perceptor):
    im = normalize_image(image)
    cut_data = torch.zeros(cuts, 3, perceptor["size"], perceptor["size"])
    for c in range(cuts):
      angle = random.uniform(-20.0, 20.0)
      img = torchvision.transforms.functional.rotate(im, angle=angle, expand=True, interpolation=bilinear)

      padv = im.size()[2] // 8
      img = torch.nn.functional.pad(img, pad=(padv, padv, padv, padv))

      size = img.size()[2:4]
      mindim = min(*size)

      if mindim <= perceptor["size"]-32:
        width = mindim - 1
      else:
        width = random.randint( perceptor["size"]-32, mindim-1 )

      oy = random.randrange(0, size[0]-width)
      ox = random.randrange(0, size[1]-width)
      img = img[:,:,oy:oy+width,ox:ox+width]

      img = torch.nn.functional.interpolate(img, size=(perceptor["size"], perceptor["size"]), mode='bilinear', align_corners=False)
      cut_data[c] = img

    cut_data += noise * torch.randn_like(cut_data, requires_grad=False)

    if debug_clip_cuts and do_checkin:
      displayImage(cut_data)

    clip_tokens = perceptor['model'].encode_image(cut_data)
    return clip_tokens


def loadPerceptor(name):
  model, preprocess = clip.load(name, device="cuda")

  tokens = []
  imgs = []
  for text in texts:
    tok = model.encode_text(clip.tokenize(text["text"]).cuda())
    tokens.append( tok )

  perceptor = {"model":model, "size": preprocess.transforms[0].size, "tokens": tokens, }
  for img in images:
    image = loadImage(img["fpath"])
    tokens = getClipTokens(image, img["cuts"], img["noise"], False, perceptor )
    imgs.append(tokens)
  perceptor["images"] = imgs
  return perceptor

perceptors = (
  loadPerceptor("ViT-B/32"),
  loadPerceptor("ViT-B/16"),
  # loadPerceptor("RN50x16"),
)

@torch.no_grad()
def saveImage(image, filename):
  # R = image[:,0:1] * 0.26862954 + 0.48145466
  # G = image[:,1:2] * 0.26130258 + 0.4578275
  # B = image[:,2:3] * 0.27577711 + 0.40821073
  # image = torch.cat((R, G, B), dim=1)
  size = image.size()

  image = (image[0].clamp(0, 1) * 255).to(torch.uint8)
  png_data = torch.ops.image.encode_png(image.cpu(), 6)
  open(filename, "wb").write(bytes(png_data))

# TODO: Use torchvision normalize / unnormalize
def unnormalize_image(image):
  
  R = image[:,0:1] * 0.26862954 + 0.48145466
  G = image[:,1:2] * 0.26130258 + 0.4578275
  B = image[:,2:3] * 0.27577711 + 0.40821073
  
  return torch.cat((R, G, B), dim=1)


def paramsToImage(canvas_color, params_coords, params_colors, params_radius, params_softness):
  cc = torch.nn.functional.sigmoid(canvas_color)
  pixels = cc.repeat((canvas_size[0], canvas_size[1], 1)).permute(2, 0, 1).unsqueeze(0)
  for i in range(num_points):
    softness = torch.nn.functional.sigmoid(params_softness[i]) * (max_softness - min_softness) + min_softness
    radius = torch.nn.functional.sigmoid(params_radius[i]) * (max_radius - min_radius) + min_radius
    color = torch.nn.functional.sigmoid(params_colors[i])
    # print(softness.item(), radius.item(), color[3].item())
    d = distmap(params_coords[i])
    # print(d.min(), d.max())
    alpha = torch.nn.functional.sigmoid((d + radius) / softness) * color[3]
    # print(alpha.min(), alpha.max())
    color_mask = color[:3].repeat((canvas_size[0], canvas_size[1], 1)).permute(2, 0, 1).unsqueeze(0)
    pixels = pixels * (1.0 - alpha) + color_mask * alpha

  return pixels

@torch.no_grad()
def displayImage(image):
  size = image.size()

  width = size[0] * size[3] + (size[0]-1) * 4
  image_row = torch.zeros( size=(3, size[2], width), dtype=torch.uint8 )

  nw = 0
  for n in range(size[0]):
    image_row[:,:,nw:nw+size[3]] = (image[n,:].clamp(0, 1) * 255).to(torch.uint8)
    nw += size[3] + 4

  jpeg_data = torch.ops.image.encode_png(image_row.cpu(), 6)
  image = display.Image(bytes(jpeg_data))
  display.display( image )

def lossClip(image, cuts, noise, do_checkin):
  losses = []

  max_loss = 0.0
  for text in texts:
    max_loss += abs(text["weight"]) * len(perceptors)
  for img in images:
    max_loss += abs(img["weight"]) * len(perceptors)

  for perceptor in perceptors:
    clip_tokens = getClipTokens(image, cuts, noise, do_checkin, perceptor)
    for t, tokens in enumerate( perceptor["tokens"] ):
      similarity = torch.cosine_similarity(tokens, clip_tokens)
      weight = texts[t]["weight"]
      if weight > 0.0:
        loss = (1.0 - similarity) * weight
      else:
        loss = similarity * (-weight)
      losses.append(loss / max_loss)

    for img in images:
      for i, prompt_image in enumerate(perceptor["images"]):
        img_tokens = prompt_image
        weight = images[i]["weight"] / float(images[i]["cuts"])
        for token in img_tokens:
          similarity = torch.cosine_similarity(token.unsqueeze(0), clip_tokens)
          if weight > 0.0:
            loss = (1.0 - similarity) * weight
          else:
            loss = similarity * (-weight)
          losses.append(loss / max_loss)
  return losses

# TV loss... maybe useful someday?
# def lossTV(image, strength):
#   Y = (image[:,:,1:,:] - image[:,:,:-1,:]).abs().mean()
#   X = (image[:,:,:,1:] - image[:,:,:,:-1]).abs().mean()
#   loss = (X + Y) * 0.5 * strength
#   return loss


def cycle(c, stage, optimizer, canvas_color, params_coords, params_colors, params_radius, params_softness):
  do_checkin = (c+1) % stage["checkin_interval"] == 0 or c == 0
  with torch.enable_grad():
    losses = []
    image = paramsToImage(canvas_color, params_coords, params_colors, params_radius, params_softness)
    losses += lossClip( image, stage["cuts"], stage["noise"], do_checkin )
    # losses += [lossTV( image, stage["denoise"] )]
    # losses += [uncertanty * stage["uncertanty_loss_scale"]]

    loss_total = sum(losses).sum()
    optimizer.zero_grad(set_to_none=True)
    loss_total.backward(retain_graph=False)
    optimizer.step()

    sys.stdout.write("Stage {} Iteration {}".format(stage["n"]+1,c+1)+"\n")
    sys.stdout.flush()

  if (c+1) % save_interval == 0:
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()
    
    nimg = paramsToImage(canvas_color, params_coords, params_colors, params_radius, params_softness)
    #saveImage(nimg, f"images/frame_{stage['n']:02}_{c:05}.png")
    saveImage(nimg, args.image_file)
  
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
        saveImage(nimg, save_name)


    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    
  """
  if do_checkin:
    TV = losses[-2].sum().item()
    nimg = paramsToImage(canvas_color, params_coords, params_colors, params_radius, params_softness)
    print( "Cycle:", str(stage["n"]) + ":" + str(c), "CLIP Loss:", losses[0].sum().item())
    displayImage(nimg)
    saveImage(nimg, texts[0]["text"] + f"_{stage['n']}" + ".png" )
  """
  
def distmap(coords):
  ydist = torch.pow(torch.arange(canvas_size[0]) - coords[0], 2)
  xdist = torch.pow(torch.arange(canvas_size[1]) - coords[1], 2)
  d = torch.pow(ydist.view(-1, 1) + xdist, 0.5)
  d = 0.0 - d
  return d

def init_optim(canvas_color, params_coords, params_colors, params_radius, params_softness, stage, optimizer = None):
  if optimizer is None:
    params = [
              {"params": canvas_color, "lr":stage["lr_color"], "weight_decay":stage["color_decay"] if "color_decay" in stage else 0},
              {"params": params_coords, "lr":stage["lr_coords"]},
              {"params": params_colors, "lr":stage["lr_color"], "weight_decay":stage["color_decay"] if "color_decay" in stage else 0},
              {"params": params_radius, "lr":stage["lr_radius"], "weight_decay":stage["radius_decay"] if "radius_decay" in stage else 0},
              {"params": params_softness, "lr":stage["lr_softness"], "weight_decay":stage["softness_decay"] if "softness_decay" in stage else 0},
    ]
    optimizer = getattr(optim, optimizer_type, None)(params)
  else: # If optimizer already exists, just change the LR
    optimizer.param_groups[0]["lr"] = stage["lr_color"]
    optimizer.param_groups[0]["weight_decay"] = stage["color_decay"] if "color_decay" in stage else 0
    optimizer.param_groups[1]["lr"] = stage["lr_coords"]
    optimizer.param_groups[2]["lr"] = stage["lr_color"]
    optimizer.param_groups[2]["weight_decay"] = stage["color_decay"] if "color_decay" in stage else 0
    optimizer.param_groups[3]["lr"] = stage["lr_radius"]
    optimizer.param_groups[3]["weight_decay"] = stage["radius_decay"] if "radius_decay" in stage else 0
    optimizer.param_groups[4]["lr"] = stage["lr_softness"]
    optimizer.param_groups[4]["weight_decay"] = stage["softness_decay"] if "softness_decay" in stage else 0
  return optimizer

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

def main():
  params_coords = []
  params_colors = []
  params_radius = []
  params_softness = []
  for p in range(num_points):
    coords = torch.rand((2)) * torch.tensor(canvas_size)
    param_coord = torch.nn.parameter.Parameter( coords.cuda(), requires_grad=True)
    color = torch.randn((4)) * color_scale #RGBA
    color[3] += init_alpha_shift
    param_color = torch.nn.parameter.Parameter( color.cuda(), requires_grad=True)
    if sort_by_radius:
      radius = torch.tensor(1.0 - p / num_points * 2.0) * radius_scale + radius_shift
    else:
      radius = torch.randn(1) * radius_scale + radius_shift
    param_radius = torch.nn.parameter.Parameter( radius.cuda(), requires_grad=True)
    softness = torch.randn(1) 
    param_softness = torch.nn.parameter.Parameter( softness.cuda(), requires_grad=True)
    params_coords.append(param_coord)
    params_colors.append(param_color)
    params_radius.append(param_radius)
    params_softness.append(param_softness)
  canvas_color = torch.nn.parameter.Parameter(torch.zeros((3)).cuda(), requires_grad=True)

  optimizer = init_optim(canvas_color, params_coords, params_colors, params_radius, params_softness, stages[0])

  for n, stage in enumerate(stages):
    stage["n"] = n
    if n > 0:
      optimizer = init_optim(canvas_color, params_coords, params_colors, params_radius, params_softness, stages[n], optimizer=optimizer)

      
    for c in range(stage["cycles"]):
      cycle( c, stage, optimizer, canvas_color, params_coords, params_colors, params_radius, params_softness)
    
for _ in range(images_n):
  main()
