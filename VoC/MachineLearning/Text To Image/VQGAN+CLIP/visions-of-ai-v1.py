# Visions of AI - by Jason Rampe
# Based on AIAIART Lesson #3 from Jonathan Whitaker at https://colab.research.google.com/drive/1qnV7PT1aSwomXvRmdoY_pgcR2ruvm6Of

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.append('./taming-transformers')

import os
import torch 
import random
import numpy as np
from PIL import Image
import torch.nn.functional as F
import torchvision
from CLIP import clip
from torchvision import transforms
from omegaconf import OmegaConf
from taming.models import cond_transformer, vqgan
import argparse

#required NudeNet imports
sys.path.append('../../NSFW/NudeNet')
import argparse
import os
import cv2
import tarfile
import logging
import numpy as np
import onnxruntime
from video_utils import get_interest_frames_from_video
from image_utils import load_images
from PIL import Image as pil_image

#In Script Movement
sys.path.append('../')
from image_warping import do_image_warping
from torchvision.transforms import functional as TF

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--sizex', type=int, help='Image width.')
  parser.add_argument('--sizey', type=int, help='Image height.')
  parser.add_argument('--iterations', type=int, help='Iterations')
  parser.add_argument('--learning_rate', type=float, help='Learning rate.')
  parser.add_argument('--update', type=int, help='Update every n iterations.')
  parser.add_argument('--cutn', type=int, help='Number of cutouts')
  parser.add_argument('--clip_model', type=str, help='CLIP model to load.')
  parser.add_argument('--vqgan_model', type=str, help='VQGAN model to load.')
  parser.add_argument('--seed_image', type=str, help='Initial seed image.', default=None)
  parser.add_argument('--enhance_nsfw', type=int, help='Enhance features that rate well in NudeNet')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')
  parser.add_argument('--r', type=float, help='In script movement. Rotation in degrees.')
  parser.add_argument('--z', type=int, help='In script movement. Zoom in pixels.')
  parser.add_argument('--px', type=int, help='In script movement. Pan X in pixels.')
  parser.add_argument('--py', type=int, help='In script movement. Pan Y in pixels.')
  parser.add_argument('--w', type=int, help='In script movement. Warp in pixels.')
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


###############################################################################################################################
# Start of NudeNet
###############################################################################################################################

class Classifier:
    """
    Class for loading model and running predictions.
    For example on how to use take a look the if __name__ == '__main__' part.
    """

    nsfw_model = None

    def __init__(self):
        """
        model = Classifier()
        """
        url = "https://github.com/notAI-tech/NudeNet/releases/download/v0/classifier_model.onnx"
        home = os.path.expanduser("~")
        model_folder = os.path.join(home, ".NudeNet/")
        if not os.path.exists(model_folder):
            os.mkdir(model_folder)

        #model_path = os.path.join(model_folder, os.path.basename(url))

        #if not os.path.exists(model_path):
        #    print("Downloading the checkpoint to", model_path)
        #    pydload.dload(url, save_to_path=model_path, max_time=None)

        #self.nsfw_model = onnxruntime.InferenceSession(model_path)
        self.nsfw_model = onnxruntime.InferenceSession('../../NSFW/NudeNet/classifier_model.onnx')
        

    def classify_video(
        self,
        video_path,
        batch_size=4,
        image_size=(256, 256),
        categories=["unsafe", "safe"],
    ):
        frame_indices = None
        frame_indices, frames, fps, video_length = get_interest_frames_from_video(
            video_path
        )
        logging.debug(
            f"VIDEO_PATH: {video_path}, FPS: {fps}, Important frame indices: {frame_indices}, Video length: {video_length}"
        )

        frames, frame_names = load_images(frames, image_size, image_names=frame_indices)

        if not frame_names:
            return {}

        preds = []
        model_preds = []
        while len(frames):
            _model_preds = self.nsfw_model.run(
                [self.nsfw_model.get_outputs()[0].name],
                {self.nsfw_model.get_inputs()[0].name: frames[:batch_size]},
            )[0]
            model_preds.append(_model_preds)
            preds += np.argsort(_model_preds, axis=1).tolist()
            frames = frames[batch_size:]

        probs = []
        for i, single_preds in enumerate(preds):
            single_probs = []
            for j, pred in enumerate(single_preds):
                single_probs.append(
                    model_preds[int(i / batch_size)][int(i % batch_size)][pred]
                )
                preds[i][j] = categories[pred]

            probs.append(single_probs)

        return_preds = {
            "metadata": {
                "fps": fps,
                "video_length": video_length,
                "video_path": video_path,
            },
            "preds": {},
        }

        for i, frame_name in enumerate(frame_names):
            return_preds["preds"][frame_name] = {}
            for _ in range(len(preds[i])):
                return_preds["preds"][frame_name][preds[i][_]] = probs[i][_]

        return return_preds

    def classify(
        self,
        image_paths=[],
        batch_size=4, #originally 4
        image_size=(256,256),
        categories=["unsafe", "safe"],
    ):
        """
        inputs:
            image_paths: list of image paths or can be a string too (for single image)
            batch_size: batch_size for running predictions
            image_size: size to which the image needs to be resized
            categories: since the model predicts numbers, categories is the list of actual names of categories
        """
        if not isinstance(image_paths, list):
            image_paths = [image_paths]

        loaded_images, loaded_image_paths = load_images(
            image_paths, image_size, image_names=image_paths
        )

        if not loaded_image_paths:
            return {}

        preds = []
        model_preds = []
        while len(loaded_images):
            _model_preds = self.nsfw_model.run(
                [self.nsfw_model.get_outputs()[0].name],
                {self.nsfw_model.get_inputs()[0].name: loaded_images[:batch_size]},
            )[0]
            model_preds.append(_model_preds)
            preds += np.argsort(_model_preds, axis=1).tolist()
            loaded_images = loaded_images[batch_size:]

        probs = []
        for i, single_preds in enumerate(preds):
            single_probs = []
            for j, pred in enumerate(single_preds):
                single_probs.append(
                    model_preds[int(i / batch_size)][int(i % batch_size)][pred]
                )
                preds[i][j] = categories[pred]

            probs.append(single_probs)

        images_preds = {}

        for i, loaded_image_path in enumerate(loaded_image_paths):
            if not isinstance(loaded_image_path, str):
                loaded_image_path = i

            images_preds[loaded_image_path] = {}
            for _ in range(len(preds[i])):
                images_preds[loaded_image_path][preds[i][_]] = float(probs[i][_])

        return images_preds

###############################################################################################################################
# End of NudeNet
###############################################################################################################################




def load_vqgan_model(config_path, checkpoint_path):
    config = OmegaConf.load(config_path)
    if config.model.target == 'taming.models.vqgan.VQModel':
        model = vqgan.VQModel(**config.model.params)
        model.eval().requires_grad_(False)
        model.init_from_ckpt(checkpoint_path)
    elif config.model.target == 'taming.models.cond_transformer.Net2NetTransformer':
        parent_model = cond_transformer.Net2NetTransformer(**config.model.params)
        parent_model.eval().requires_grad_(False)
        parent_model.init_from_ckpt(checkpoint_path)
        model = parent_model.first_stage_model
    else:
        raise ValueError(f'unknown model type: {config.model.target}')
    del model.loss
    return model

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

def vector_quantize(x, codebook):
  d = x.pow(2).sum(dim=-1, keepdim=True) + codebook.pow(2).sum(dim=1) - 2 * x @ codebook.T
  indices = d.argmin(-1)
  x_q = F.one_hot(indices, codebook.shape[0]).to(d.dtype) @ codebook
  return replace_grad(x_q, x)

def synth(z):
  z_q = vector_quantize(z.movedim(1, 3), model.quantize.embedding.weight).movedim(3, 1)
  return clamp_with_grad(model.decode(z_q).add(1).div(2), 0, 1)

def rand_z(width, height):
  f = 2**(model.decoder.num_resolutions - 1)
  toksX, toksY = width // f, height // f
  n_toks = model.quantize.n_e
  one_hot = F.one_hot(torch.randint(n_toks, [toksY * toksX], device=device), n_toks).float()
  z = one_hot @ model.quantize.embedding.weight
  z = z.view([-1, toksY, toksX, model.quantize.e_dim]).permute(0, 3, 1, 2)
  return z

# Create a transform - this will map the image data to the same range as that seen by CLIP during training
normalize = transforms.Normalize(mean=[0.48145466, 0.4578275, 0.40821073],std=[0.26862954, 0.26130258, 0.27577711])

def clip_loss(im_embed, text_embed):
  im_normed = F.normalize(im_embed.unsqueeze(1), dim=2)
  text_normed = F.normalize(text_embed.unsqueeze(0), dim=2)
  dists = im_normed.sub(text_normed).norm(dim=2).div(2).arcsin().pow(2).mul(2) # Squared Great Circle Distance
  return dists.mean()

def numpy2tensor(imgArray):
  im = torch.unsqueeze(transforms.ToTensor()(imgArray), 0)   
  return im  





device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)
print(torch.cuda.get_device_properties(device))

sys.stdout.write("Loading VQGAN model "+args.vqgan_model+" ...\n")
sys.stdout.flush()

model = load_vqgan_model(f'{args.vqgan_model}.yaml', f'{args.vqgan_model}.ckpt').to(device)
    
sys.stdout.write("Loading CLIP model "+args.clip_model+" ...\n")
sys.stdout.flush()

perceptor = clip.load(args.clip_model, jit=False)[0].eval().requires_grad_(False).to(device)

prompt_text = args.prompt
width = args.sizex
height = args.sizey
lr = args.learning_rate
n_iter = args.iterations
crops_per_iteration = args.cutn

sys.stdout.write("Composing transforms ...\n")
sys.stdout.flush()

# The transforms to get variations of our image
"""
tfms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomAffine(5),
    transforms.ColorJitter(),
    transforms.GaussianBlur(5),
])
"""

"""
#v1
tfms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomHorizontalFlip(),
    transforms.ColorJitter(brightness=.1, hue=.1),
    #transforms.ColorJitter(hue=.5),
    transforms.GaussianBlur(5),
    transforms.RandomAdjustSharpness(3),
    transforms.RandomPerspective(),
    transforms.RandomAffine(5),
    transforms.RandomRotation(5),
])
"""

"""
#v2
tfms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomHorizontalFlip(),
    #transforms.ColorJitter(brightness=.3, hue=.3),
    #transforms.ColorJitter(brightness=.1, hue=.1, saturation=.9, contrast=.5),
    transforms.GaussianBlur(5),
    transforms.RandomAdjustSharpness(3),
    transforms.RandomPerspective(),
    transforms.RandomAffine(25),
    transforms.RandomRotation(25),
])
"""

"""
#v3
tfms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    #transforms.Resize((224,224)),
    #transforms.RandomAdjustSharpness(sharpness_factor=3,p=0),
    transforms.RandomHorizontalFlip(),
    #transforms.RandomVerticalFlip(),
    transforms.RandomRotation(degrees=45),
    #transforms.RandomPerspective(distortion_scale=1.5),
    transforms.RandomAffine(45,scale=(2.0,2.0)),
    #transforms.RandomAffine(15),
    transforms.ColorJitter(brightness=.3, hue=.3, saturation=.9, contrast=.3),
    transforms.GaussianBlur(9),
])
"""

#v4
tfms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    #transforms.Resize(224),
    transforms.RandomHorizontalFlip(),
    transforms.RandomAffine(15),
    transforms.GaussianBlur(3),
])


# The z we'll be optimizing
z = rand_z(width, height)
z.requires_grad=True

# The text target
text_embed = perceptor.encode_text(clip.tokenize(prompt_text).to(device)).float()

# The optimizer - feel free to try different ones here
#optimizer = torch.optim.Adam([z], lr=lr, weight_decay=1e-6)
optimizer = torch.optim.AdamW([z], lr=lr, weight_decay=0)

losses = [] # Keep track of our losses (RMSE values)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

itt = 1

for i in range(n_iter):

  # Reset everything related to gradient calculations
  optimizer.zero_grad()

  # Get the GAN output
  output = synth(z)

  # Calculate our loss across several different random crops/transforms
  loss = 0

  for _ in range(crops_per_iteration):
    image_embed = perceptor.encode_image(tfms(normalize(output)).to(device)).float()
    loss += clip_loss(image_embed, text_embed)/crops_per_iteration
  
  if args.enhance_nsfw==1:
    #add NudeNet unsafe rating to loss - this should (?) help encourage NSFW images
    im_arr = np.array(output.cpu().squeeze().detach().permute(1, 2, 0)*255).astype(np.uint8)
    Image.fromarray(im_arr).save('temp.png')
    m = Classifier()
    classification = str(m.classify('temp.png'));
    #extract the safe and unsafe values
    split1 = classification.split(': {')
    split2 = split1[1].split(', ')
    split3 = split2[0].split(': ')
    split4 = split2[1].split(': ')
    #which of split3 or split4 contains the "unsafe" rating
    cat1=split3[0].strip('\'')
    cat2=split4[0].strip('\'')
    rating = ''
    if cat1 == 'unsafe':
        rating=split3[1].strip('}}')
    if cat2 == 'unsafe':
        rating=split4[1].strip('}}')
    loss += (1.0-float(rating))/2
    #loss = loss/10*1 + (1.0-float(rating))/10*9
  
  # Store loss
  losses.append(loss.detach().item())

  if args.enhance_nsfw==1:
    sys.stdout.write("Iteration {} Loss {} Unsafe {}".format(itt,loss,rating)+"\n")
  else:
    #sys.stdout.write("Iteration {}".format(itt)+"\n")
    sys.stdout.write("Iteration {} Loss {}".format(itt,loss)+"\n")
  sys.stdout.flush()
 
  # Save image
  if itt % args.update == 0:
    sys.stdout.flush()
    sys.stdout.write("Saving progress ...\n")
    sys.stdout.flush()

    im_arr = np.array(output.cpu().squeeze().detach().permute(1, 2, 0)*255).astype(np.uint8)

    Image.fromarray(im_arr).save(args.image_file)
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
        Image.fromarray(im_arr).save(save_name)

    sys.stdout.flush()
    sys.stdout.write("Progress saved\n")
    sys.stdout.flush()
    
    #In Script Movement
    if args.r is not None:
        #do_image_warping(Image.fromarray(im_arr),r,z,px,py,w):  
        #im_arr = do_image_warping(im_arr,-1,4,0,2,10)
        im_arr = do_image_warping(im_arr,args.r,args.z,args.px,args.py,args.w)
        #convert warped image array back into the optimizer for the next iteration
        z, *_ = model.encode(TF.to_tensor(im_arr).to(device).unsqueeze(0) * 2 - 1)
        z.requires_grad_(True)
        optimizer = torch.optim.AdamW([z], lr=lr, weight_decay=0)
    
    
  # Backpropagate the loss and use it to update the parameters
  loss.backward() # This does all the gradient calculations
  optimizer.step() # The optimizer does the update

  itt+=1