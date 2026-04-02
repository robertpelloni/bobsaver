# RuDOLPH Hyper-Modal Transformer .ipynb
# Original file is located at https://colab.research.google.com/drive/1gmTDA13u709OXiAeXWGm7sPixRhEJCga

# pip install rudolph==0.0.1rc0

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from rudalle import get_tokenizer, get_vae
from rudalle.utils import seed_everything
from rudolph.model import get_rudolph_model, ruDolphModel, FP16Module
from rudolph.pipelines import generate_codebooks, self_reranking_by_image, self_reranking_by_text, show, generate_captions, generate_texts, zs_clf
from rudolph import utils
#from deep_translator import GoogleTranslator
from PIL import Image
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--bs', type=int, help='Batch size')
  parser.add_argument('--images', type=int, help='Number of images to generate.')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--frame_dir', type=str, help='Save frame file directory.')

  args = parser.parse_args()
  return args

args=parse_args();


device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print("device:", device.type)
print(torch.cuda.get_device_properties(device))

device = 'cuda'

#set cache dir location under user home directory
import os
homepath = os.path.expanduser(os.getenv('USERPROFILE'))
#cachepath = homepath+'/.cache/ruDOLPH'
cachepath = '../../.cache'

"""
sys.stdout.write("Translating prompt text to Russian ...\n")
sys.stdout.flush()
text = GoogleTranslator(source='auto', target='ru').translate(args.prompt)
"""
from googletrans import Translator
translator = Translator()
detected_language = translator.detect(args.prompt)
if "lang=ru" in str(detected_language):
    sys.stdout.write("Prompt detected as Russian so no need to translate.\n")
    sys.stdout.flush()
    text = args.prompt
else:
    sys.stdout.write("Translating English prompt to Russian ...\n")
    sys.stdout.flush()
    text = translator.translate(args.prompt, dest='ru').text


sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

model = get_rudolph_model('350M', fp16=True, device='cuda', cache_dir=cachepath)

sys.stdout.write("Loading tokenizer ...\n")
sys.stdout.flush()

tokenizer = get_tokenizer(cache_dir=cachepath)

sys.stdout.write("Loading vae ...\n")
sys.stdout.flush()

vae = get_vae(dwt=False,cache_dir=cachepath).to(device)


images_num = args.images
bs = args.bs

seed_everything(args.seed)

sys.stdout.write("Generating codebooks ...\n")
sys.stdout.flush()

codebooks = []

for top_k, top_p, images_num in [
    (2048, 0.995, images_num),
    (1024, 0.99, images_num),
    (768, 0.98, images_num),
    (512, 0.97, images_num),
    (384, 0.96, images_num),
    (256, 0.95, images_num),
    (128, 0.92, images_num),
]:
    codebooks.append(
        generate_codebooks(text, tokenizer, model, top_k=top_k, images_num=images_num, top_p=top_p, bs=bs, seed=args.seed)
    )

"""
#original code above used 7 passes, this just uses 1
for top_k, top_p, images_num in [
    (1024, 0.99, images_num),
]:
    codebooks.append(
        generate_codebooks(text, tokenizer, model, top_k=top_k, images_num=images_num, top_p=top_p, bs=bs, seed=args.seed)
    )
"""



codebooks = torch.cat(codebooks)

sys.stdout.write("Codebooks shape\n")
print(codebooks.shape)
sys.stdout.flush()

sys.stdout.write("Ranking images ...\n")
sys.stdout.flush()

ppl_text, ppl_image = self_reranking_by_text(
    text,
    codebooks,
    tokenizer,
    model,
    bs=bs,
)

with torch.no_grad():
    images = vae.decode(codebooks[ppl_text.argsort()[:25]])
 
sys.stdout.write("Showing images ...\n")
sys.stdout.flush()

pil_images = utils.torch_tensors_to_pil_list(images)
#show(pil_images, 5)
for i in range(args.images):
    #im = Image.fromarray((pil_images[i]*255).astype(np.uint8))
    im = pil_images[i]
    filename = f'{args.image_file} {i+1}.png'
    im.save(filename)
    #sys.stdout.write(f"Saved {filename}\n")
    sys.stdout.write(f"Saved image {i+1}/{args.images}\n")
    sys.stdout.flush()

sys.stdout.write("Done")
sys.stdout.flush()


