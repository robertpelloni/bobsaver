# testy.ipynb
# Original file is located at https://colab.research.google.com/drive/1xqzUi2iXQXDqXBHQGP9Mqt2YrYW6cx-J

#!pip install -e ./taming-transformers
#!pip install ipywidgets omegaconf>=2.0.0 pytorch-lightning>=1.0.8 torch-fidelity einops

import sys
sys.path.append(".")
sys.path.append('./taming-transformers')
sys.path.append('./latent-diffusion')
from taming.models import vqgan # checking correct import from taming

"""2. Define the Task (currently only superresolution is available, other tasks are coming soon)

"""

# Commented out IPython magic to ensure Python compatibility.
# %cd latent-diffusion
import ipywidgets as widgets
from IPython.display import display

mode = widgets.Select(options=['superresolution'],
    value='superresolution', description='Task:')
display(mode)

"""3. Download model checkpoint ( takes ~ 3 Min) and load model

"""

from notebook_helpers import get_model
model = get_model(mode.value)

"""4. Optional step: Upload your own conditioning image for superresolution (height and width have to take values in [128, 192, 256])"""

from notebook_helpers import get_custom_cond
get_custom_cond(mode.value)

"""4. Select conditioning from available examples or the uploaded custom conditioning"""

from notebook_helpers import get_cond_options, get_cond
dir, options = get_cond_options(mode.value)
cond_choice = widgets.RadioButtons(
        options=options,
        description='Select conditioning:',
        disabled=False
    )
display(cond_choice)

"""5. Run Model"""

from notebook_helpers import run
import os
custom_steps = 100
cond_choice_path = os.path.join(dir, cond_choice.value)
logs = run(model["model"], cond_choice_path, mode.value, custom_steps)

"""6. Display Sample"""

import torch
import numpy as np
import IPython.display as d
from PIL import Image

sample = logs["sample"]
sample = sample.detach().cpu()
sample = torch.clamp(sample, -1., 1.)
sample = (sample + 1.) / 2. * 255
sample = sample.numpy().astype(np.uint8)
sample = np.transpose(sample, (0, 2, 3, 1))
print(sample.shape)
a = Image.fromarray(sample[0])
display(a)