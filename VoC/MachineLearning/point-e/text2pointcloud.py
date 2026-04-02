import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import torch
from tqdm.auto import tqdm

from point_e.diffusion.configs import DIFFUSION_CONFIGS, diffusion_from_config
from point_e.diffusion.sampler import PointCloudSampler
from point_e.util.pc_to_mesh import marching_cubes_mesh
from point_e.models.download import load_checkpoint
from point_e.models.configs import MODEL_CONFIGS, model_from_config
from point_e.util.plotting import plot_point_cloud

import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--prompt', type=str)
  parser.add_argument('--grid_size', type=int)
  args = parser.parse_args()
  return args

args2=parse_args();

device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
print('Using device:', device)

print('creating base model...')
base_name = 'base40M-textvec'
base_model = model_from_config(MODEL_CONFIGS[base_name], device)
base_model.eval()
base_diffusion = diffusion_from_config(DIFFUSION_CONFIGS[base_name])

print('creating upsample model...')
upsampler_model = model_from_config(MODEL_CONFIGS['upsample'], device)
upsampler_model.eval()
upsampler_diffusion = diffusion_from_config(DIFFUSION_CONFIGS['upsample'])

print('downloading base checkpoint...')
base_model.load_state_dict(load_checkpoint(base_name, device))

print('downloading upsampler checkpoint...')
upsampler_model.load_state_dict(load_checkpoint('upsample', device))


# In[ ]:


sampler = PointCloudSampler(
    device=device,
    models=[base_model, upsampler_model],
    diffusions=[base_diffusion, upsampler_diffusion],
    num_points=[1024, 4096 - 1024],
    aux_channels=['R', 'G', 'B'],
    guidance_scale=[3.0, 0.0],
    model_kwargs_key_filter=('texts', ''), # Do not condition the upsampler at all
)


# In[ ]:


# Set a prompt to condition on.
prompt = args2.prompt

# Produce a sample from the model.
samples = None
for x in tqdm(sampler.sample_batch_progressive(batch_size=1, model_kwargs=dict(texts=[prompt]))):
    samples = x


# In[ ]:


pc = sampler.output_to_point_clouds(samples)[0]
fig = plot_point_cloud(pc, grid_size=3, fixed_bounds=((-0.75, -0.75, -0.75),(0.75, 0.75, 0.75)))



print('creating SDF model...')
name = 'sdf'
model = model_from_config(MODEL_CONFIGS[name], device)
model.eval()

print('loading SDF model...')
model.load_state_dict(load_checkpoint(name, device))

# Plot the point cloud as a sanity check.
fig = plot_point_cloud(pc, grid_size=2)

import skimage.measure as measure

# Produce a mesh (with vertex colors)
mesh = marching_cubes_mesh(
    pc=pc,
    model=model,
    batch_size=4096,
    grid_size=args2.grid_size, # increase to 128 for resolution used in evals
    progress=True,
)

# Write the mesh to a PLY file to import into some other program.
print('saving mesh.ply ...',flush=True)
with open('mesh.ply', 'wb') as f:
    mesh.write_ply(f)
   
"""
# Write the pointcloud to a PLY file to import into some other program.
print('saving pointcloud...',flush=True)
with open('pointcloud.ply', 'wb') as f:
    mesh.vertices.export_ply(f, binary=True, normals=True, colors=True)    
"""

# Write the pointcloud to a PLY file to import into some other program.
print('saving pointcloud.xyz ...',flush=True)
import numpy as np
rgb_scale = 255
xyz = np.concatenate([pc.coords, 
                      rgb_scale * np.array([pc.channels["R"], 
                                            pc.channels["G"], 
                                            pc.channels["B"]
                                           ]
                                          ).T
                     ], axis=1)
np.savetxt("pointcloud.xyz", xyz)

print('done',flush=True)
