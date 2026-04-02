#front end to https://github.com/Hvass-Labs/TensorFlow-Tutorials/blob/master/14_DeepDream.ipynb
from Pedersen2 import model, load_image, save_image, recursive_optimize

#next 2 lines set do not log/show info and warning messages
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import sys
import numpy as np

#scale the passed array values to between x_min and x_max
def scale(X, x_min, x_max):
    range = x_max - x_min
    res = (X - X.min()) / X.ptp() * range + x_min
    # go half-way towards the desired scaled result to help decrease frames brightness "strobing"?
    # res = (X + res) / 2
    res = X + (res - X) / 5
    return res

#arguments passed in
sourceimage = str(sys.argv[1])
layernumber = int(sys.argv[2])
iterations = int(sys.argv[3])
stepsize = float(sys.argv[4])
rescalefactor = float(sys.argv[5])
passes = int(sys.argv[6])
outputimage = str(sys.argv[7])

layer_tensor = model.layer_tensors[layernumber]
file_name = sourceimage
img_result = load_image(filename='{}'.format(file_name))

img_result = recursive_optimize(layer_tensor=layer_tensor, image=img_result,
                 num_iterations=iterations, step_size=stepsize, rescale_factor=rescalefactor,
                 num_repeats=passes, blend=0.2)

#auto adjust brightness
img_result = scale(img_result, 0, 255)

save_image(img_result,outputimage)

print("DeepDream processing complete")