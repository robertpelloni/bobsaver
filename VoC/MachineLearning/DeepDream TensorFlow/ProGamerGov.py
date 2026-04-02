# https://github.com/ProGamerGov/Protobuf-Dreamer/blob/master/pb_dreamer.py

# Adapted by github.com/jnordberg from https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/tutorials/deepdream
# Adapted by github.com/ProGamerGov from https://github.com/jnordberg/dreamcanvas
# wget https://storage.googleapis.com/download.tensorflow.org/models/inception5h.zip
# unzip -d model inception5h.zip

#next 2 lines set do not log/show info and warning messages
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import imageio
import numpy as np
import sys
import tensorflow.compat.v1 as tf
import time
from io import BytesIO
from PIL import Image

# ignore all info and warning messages
# os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 
# tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)

# Check for a GPU
"""
if not tf.test.gpu_device_name():
    sys.stdout.write('No GPU found. Please use a GPU.')
    sys.stdout.flush()	
    exit()
else:
    sys.stdout.write('GPU Device Detected: {}\n\n'.format(tf.test.gpu_device_name()))
    sys.stdout.flush()	
"""

sys.stdout.write('Parsing arguments ...\n')
sys.stdout.flush()

# passed arguments
input_img = str(sys.argv[1])
output_name = str(sys.argv[2])
channel_value = int(sys.argv[3]) # 139
layer_name = str(sys.argv[4]) # 'mixed4d_3x3_bottleneck_pre_relu'
iter_value = int(sys.argv[5]) # 10
octave_value = int(sys.argv[6]) # 4
octave_scale_value = float(sys.argv[7]) # 1.4
step_size = float(sys.argv[8]) # 1.5
tile_size = int(sys.argv[9]) # 512
model_path = sys.argv[10] # full path to inception5h.py
verbose = 1
input_img = imageio.imread(input_img, pilmode="RGB")

sys.stdout.write('Loading model ...\n')
sys.stdout.flush()

model_fn = os.path.join(os.path.dirname(os.path.realpath(__file__)), model_path)
# creating TensorFlow session and loading the model
sys.stdout.write('Setting up TensorFlow ...\n')
sys.stdout.flush()
graph = tf.Graph()
sess = tf.InteractiveSession(graph=graph)
with tf.gfile.FastGFile(model_fn, 'rb') as f:
    graph_def = tf.GraphDef()
    graph_def.ParseFromString(f.read())
t_input = tf.placeholder(np.float32, name='input') # define the input tensor
imagenet_mean = 117.0
t_preprocessed = tf.expand_dims(t_input-imagenet_mean, 0)
tf.import_graph_def(graph_def, {'input':t_preprocessed})

def T(layer):
    '''Helper for getting layer output tensor'''
    return graph.get_tensor_by_name("import/%s:0"%layer)

def tffunc(*argtypes):
    '''Helper that transforms TF-graph generating function into a regular one.
    See "resize" function below.
    '''
    placeholders = list(map(tf.placeholder, argtypes))
    def wrap(f):
        out = f(*placeholders)
        def wrapper(*args, **kw):
            return out.eval(dict(zip(placeholders, args)), session=kw.get('session'))
        return wrapper
    return wrap

# Helper function that uses TF to resize an image
def resize(img, size):
    img = tf.expand_dims(img, 0)
    return tf.image.resize_bilinear(img, size)[0,:,:,:]
resize = tffunc(np.float32, np.int32)(resize)

def calc_grad_tiled(img, t_grad, tile_size=512):
    '''Compute the value of tensor t_grad over the image in a tiled way.
    Random shifts are applied to the image to blur tile boundaries over
    multiple iterations.'''
    sz = tile_size
    h, w = img.shape[:2]
    sx, sy = np.random.randint(sz, size=2)
    img_shift = np.roll(np.roll(img, sx, 1), sy, 0)
    grad = np.zeros_like(img)
    for y in range(0, max(h-sz//2, sz),sz):
        for x in range(0, max(w-sz//2, sz),sz):
            sub = img_shift[y:y+sz,x:x+sz]
            g = sess.run(t_grad, {t_input:sub})
            grad[y:y+sz,x:x+sz] = g
    return np.roll(np.roll(grad, -sx, 1), -sy, 0)

def render_deepdream(t_grad, img0, iter_n=10, step=1.5, octave_n=4, octave_scale=1.4):
    # split the image into a number of octaves
    img = img0
    octaves = []
    for i in range(octave_n-1):
        hw = img.shape[:2]
        lo = resize(img, np.int32(np.float32(hw)/octave_scale))
        hi = img-resize(lo, hw)
        img = lo
        octaves.append(hi)

    # generate details octave by octave
    for octave in range(octave_n):
        if octave>0:
            hi = octaves[-octave]
            img = resize(img, hi.shape[:2])+hi
        for i in range(iter_n):
            #g = calc_grad_tiled(img, t_grad)
            g = calc_grad_tiled(img, t_grad, tile_size)
            img += g*(step / (np.abs(g).mean()+1e-7))
            sys.stdout.write('Octave {} Iteration {}\n'.format(octave+1,i+1))
            sys.stdout.flush()

    return Image.fromarray(np.uint8(np.clip(img/255.0, 0, 1)*255))

last_layer = None
last_grad = None
last_channel = None
def render(img, layer='mixed4d_3x3_bottleneck_pre_relu', channel=139, iter_n=10, step=1.5, octave_n=4, octave_scale=1.4):
    global last_layer, last_grad, last_channel
    if last_layer == layer and last_channel == channel:
        t_grad = last_grad
    else:
        t_obj = T(layer)[:,:,:,channel]
        t_score = tf.reduce_mean(t_obj) # defining the optimization objective
        t_grad = tf.gradients(t_score, t_input)[0] # behold the power of automatic differentiation!
        last_layer = layer
        last_grad = t_grad
        last_channel = channel
    img0 = np.float32(img)
    return render_deepdream(t_grad, img0, iter_n, step, octave_n, octave_scale)
	
sys.stdout.write('Processing image ...\n')
sys.stdout.flush()
	
output_img = render(input_img, layer=layer_name, channel=channel_value, iter_n=iter_value, step=step_size, octave_n=octave_value, octave_scale=octave_scale_value)

sys.stdout.write('Saving image ...\n')
sys.stdout.flush()
imageio.imsave(output_name, output_img)

sys.stdout.write('Done\n')
sys.stdout.flush()
