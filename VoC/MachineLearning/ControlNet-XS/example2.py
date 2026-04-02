import scripts.control_utils as cu
import torch
from PIL import Image

path_to_config = 'configs/inference/sd/sd21_encD_depth_14m.yaml'
model = cu.create_model(path_to_config).to('cuda')

size = 768
image_path = 'Scarlett.png'


image = cu.get_image(image_path, size=size)
depth = cu.get_midas_depth(image, max_resolution=size)
num_samples = 2

samples, controls = cu.get_sd_sample(
    guidance=depth,
    ddim_steps=10,
    num_samples=num_samples,
    model=model,
    shape=[4, size // 8, size // 8],
    control_scale=0.95,
    prompt='a happy clown',
    n_prompt='low quality, bad quality, sketches'
)


Image.fromarray(cu.create_image_grid(samples)).save('Scarlett_clown_sd21.png')