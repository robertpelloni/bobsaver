import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from omni_zero import OmniZeroSingle
import torch
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"

    parser = argparse.ArgumentParser()

    parser.add_argument("--base_image", type=str, help="image to process")
    parser.add_argument("--composition_image", type=str, help="composition image")
    parser.add_argument("--style_image", type=str, help="style image")
    parser.add_argument("--identity_image", type=str, help="identity image")
    parser.add_argument("--output_image", type=str, help="identity image")

    args = parser.parse_args()
    return args

args2=parse_args();

device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
print('Using device:', device, flush=True)
print(torch.cuda.get_device_properties(device), flush=True)
sys.stdout.flush()

def main():
    
    omni_zero = OmniZeroSingle(
        base_model="frankjoshua/albedobaseXL_v13",
    )

    base_image=args2.base_image #"https://github.com/okaris/omni-zero/assets/1448702/2ca63443-c7f3-4ba6-95c1-2a341414865f"
    composition_image=args2.composition_image #"https://github.com/okaris/omni-zero/assets/1448702/2ca63443-c7f3-4ba6-95c1-2a341414865f"
    style_image=args2.style_image #"https://github.com/okaris/omni-zero/assets/1448702/64dc150b-f683-41b1-be23-b6a52c771584"
    identity_image=args2.identity_image #"https://github.com/okaris/omni-zero/assets/1448702/ba193a3a-f90e-4461-848a-560454531c58"

    images = omni_zero.generate(
        seed=42,
        prompt="A person",
        negative_prompt="blurry, out of focus",
        guidance_scale=3.0,
        number_of_images=1,
        number_of_steps=10,
        base_image=base_image,
        base_image_strength=0.15,
        composition_image=composition_image,
        composition_image_strength=1.0,
        style_image=style_image,
        style_image_strength=1.0,
        identity_image=identity_image,
        identity_image_strength=1.0,
        depth_image=None,
        depth_image_strength=0.5, 
    )

    for i, image in enumerate(images):
        image.save(f"{args2.output_image}")

if __name__ == "__main__":
    main()