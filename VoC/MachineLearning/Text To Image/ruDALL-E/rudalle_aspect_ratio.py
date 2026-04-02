# Original file is located at https://colab.research.google.com/drive/124zC1w2qHR1ijfEPQVvLccLRBLD_3duG

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

sys.path.insert(0, './ru-dalle-aspect-ratio-1')
sys.path.insert(0, './ru-dalle-aspect-ratio-2')

from rudalle_aspect_ratio import RuDalleAspectRatio, get_rudalle_model
from rudalle import get_vae, get_tokenizer
from rudalle.pipelines import show

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str, help='Text to generate image from.')
  parser.add_argument('--model', type=str, help='Model.')
  parser.add_argument('--aspect', type=str, help='Aspect ratio.')
  parser.add_argument('--seed', type=int, help='Random seed.')
  parser.add_argument('--numimages', type=int, help='Images count')
  parser.add_argument('--topk', type=int, help='Top K')
  parser.add_argument('--topp', type=float, help='Top P')
  parser.add_argument('--image_file', type=str, help='Output image name.')
  parser.add_argument('--save_dir', type=str, help='Image save directory.')
  args = parser.parse_args()
  return args

args=parse_args();

device = 'cuda'
dalle = get_rudalle_model(args.model, fp16=True, device=device)
#dalle = get_rudalle_model('Malevich', fp16=True, device=device)
vae, tokenizer = get_vae().to(device), get_tokenizer()
sys.stdout.write(f'Using device: {device}')
sys.stdout.flush()

"""
# Vertical Image Generation 9:16

text = "красивый букет цветов" #@param {type:"string"}
aspect_ratio = "9:16" #@param {type: "string"}
images_num = 4 #@param {type: "integer"}
top_k = 512 #@param {type:"slider", min:128, max:4096, step:128}
top_p = 0.975 #@param {type:"slider", min:0.5, max:1, step:0.005}
seed = 7777 #@param {type: "integer"}

a, b = aspect_ratio.split(":")
aspect_ratio = int(a)/int(b)
rudalle_ar = RuDalleAspectRatio(
    dalle=dalle, vae=vae, tokenizer=tokenizer,
    aspect_ratio=aspect_ratio, bs=4, device=device
    ,window=128, image_size=256
)
_, result_pil_images = rudalle_ar.generate_images(text, top_k, top_p, images_num, seed=seed)
show(result_pil_images, 1 if aspect_ratio > 1 else 4)

# Horizontal Image Generation 32:9

text = "готический квартал" #@param {type:"string"}
aspect_ratio = "32:9" #@param {type: "string"}
images_num = 4 #@param {type: "integer"}
top_k = 1024 #@param {type:"slider", min:128, max:4096, step:128}
top_p = 0.975 #@param {type:"slider", min:0.5, max:1, step:0.005}
seed = 7777 #@param {type: "integer"}

a, b = aspect_ratio.split(":")
aspect_ratio = int(a)/int(b)
rudalle_ar = RuDalleAspectRatio(
    dalle=dalle, vae=vae, tokenizer=tokenizer,
    aspect_ratio=aspect_ratio, bs=4, device=device
)
_, result_pil_images = rudalle_ar.generate_images(text, top_k, top_p, images_num, seed=seed)
show(result_pil_images, 1 if aspect_ratio > 1 else 4)
"""

#text = "красивый букет цветов" #@param {type:"string"}
#text = "осенний пейзаж" #autumn landscape
#text = "футуристический городской пейзаж" #futuristic cityscape
#text = "высокие деревья" #tall trees
#text = "Высокое здание" #tall building

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

aspect_ratio = args.aspect #"21:9" #@param {type: "string"}
images_num = args.numimages #4 #@param {type: "integer"}
top_k = args.topk #512 #@param {type:"slider", min:128, max:4096, step:128}
top_p = args.topp #0.975 #@param {type:"slider", min:0.5, max:1, step:0.005}
seed = args.seed #8888 #@param {type: "integer"}

a, b = aspect_ratio.split(":")
aspect_ratio = int(a)/int(b)
rudalle_ar = RuDalleAspectRatio(
    dalle=dalle, vae=vae, tokenizer=tokenizer,
    aspect_ratio=aspect_ratio, bs=args.numimages, device=device, image_name=args.image_file
)
_, result_pil_images = rudalle_ar.generate_images(text, top_k, top_p, images_num, seed=seed)

show(result_pil_images,1 if aspect_ratio > 1 else 4, save_dir = args.save_dir, show=False, image_name=args.image_file)







