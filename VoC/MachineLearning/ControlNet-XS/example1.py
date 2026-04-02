import scripts.control_utils as cu
import torch
from PIL import Image

path_to_config = 'configs/inference/sdxl/sdxl_encD_canny_48m.yaml'
model = cu.create_model(path_to_config).to('cuda')

image_path = 'Scarlett.png'

canny_high_th = 250
canny_low_th = 100
size = 768
num_samples=4

image = cu.get_image(image_path, size=size)
edges = cu.get_canny_edges(image, low_th=canny_low_th, high_th=canny_high_th)

samples, controls = cu.get_sdxl_sample(
    guidance=edges,
    ddim_steps=10,
    num_samples=num_samples,
    model=model,
    shape=[4, size // 8, size // 8],
    control_scale=0.95,
    #prompt='cinematic, a female cyborg, newon and wires, photorealistic, highly detailed',
    prompt='a happy friendly clown',
    n_prompt='lowres, bad anatomy, worst quality, low quality',
)

Image.fromarray(cu.create_image_grid(samples)).save('Scarlett_Clown.png')