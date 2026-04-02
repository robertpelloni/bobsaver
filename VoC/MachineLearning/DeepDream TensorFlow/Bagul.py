# https://github.com/darshanbagul/HalluciNetwork

#next 2 lines set do not log/show info and warning messages
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import numpy as np
from functools import partial
import PIL.Image
import tensorflow.compat.v1 as tf
import matplotlib.pyplot as plt
import sys

# ignore all info and warning messages
# os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 
# tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)

# Check for a GPU
# if not tf.test.gpu_device_name():
if not tf.config.list_physical_devices():
    sys.stdout.write('No GPU found. Please use a GPU.')
    sys.stdout.flush()	
    exit()
else:
    sys.stdout.write('GPU Device Detected: {}\n\n'.format(tf.test.gpu_device_name()))
    sys.stdout.flush()	

#arguments passed in
sourceimage = str(sys.argv[1])
layername = sys.argv[2]
iterations = int(sys.argv[3])
stepsize = float(sys.argv[4])
rescalefactor = float(sys.argv[5])
passes = int(sys.argv[6])
outputimage = str(sys.argv[7])

def load_image(filename):
    image = PIL.Image.open(filename)
    return np.float32(image)

def save_image(image, filename):
    # Ensure the pixel-values are between 0 and 255.
    image = np.clip(image, 0.0, 255.0)
    # Convert to bytes.
    image = image.astype(np.uint8)
    # Write the image-file in jpeg-format.
    with open(filename, 'wb') as file:
        PIL.Image.fromarray(image).save(file, 'png')

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

def T(layer, graph):
    '''Helper for getting layer output tensor'''
    return graph.get_tensor_by_name("import/%s:0"%layer)
	
def calc_grad_tiled(sess, img, t_grad, t_input, tile_size=512):
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

def showarray(a, layer, img_name):
    a = np.uint8(np.clip(a, 0, 1)*255)
    fig1 = plt.gcf()
    plt.imshow(a)
    # plt.show()
    plt.draw()
    fig1.savefig(img_name + '_' + layer + '.jpg', dpi=100)

	
def deep_dream(img_name, inception_layer):

    sys.stdout.write('Loading source image ...\n')
    sys.stdout.flush()
    # start with a gray image with a little noise
    # img_noise = np.random.uniform(size=(224,224,3)) + 100.0
    file_name = sourceimage
    img_noise = load_image(filename='{}'.format(file_name))	

    model_fn = 'inception5h.pb'
  
    sys.stdout.write('Loading model ...\n')
    sys.stdout.flush()
    # Creating Tensorflow session and loading the model
    graph = tf.Graph()
    sess = tf.InteractiveSession(graph=graph)
    with tf.gfile.FastGFile(os.path.join('', model_fn), 'rb') as f:
        graph_def = tf.GraphDef()
        graph_def.ParseFromString(f.read())
    t_input = tf.placeholder(np.float32, name='input') # define the input tensor
    imagenet_mean = 117.0
    t_preprocessed = tf.expand_dims(t_input-imagenet_mean, 0)
    tf.import_graph_def(graph_def, {'input':t_preprocessed})
    
    #layers = [op.name for op in graph.get_operations() if op.type=='Conv2D' and 'import/' in op.name]
    #feature_nums = [int(graph.get_tensor_by_name(name+':0').get_shape()[-1]) for name in layers]
    
    # print('Number of layers', len(layers))
    # print('Total number of feature channels:', sum(feature_nums))
  
    def resize(img, size):
    	img = tf.expand_dims(img, 0)
    	return tf.image.resize_bilinear(img, size)[0,:,:,:]
    
    resize = tffunc(np.float32, np.int32)(resize)

    def render_deepdream(t_obj, img0, layer, img_name, iter_n=iterations, step=stepsize, octave_n=passes, octave_scale=rescalefactor):
        t_score = tf.reduce_mean(t_obj) # defining the optimization objective
        t_grad = tf.gradients(t_score, t_input)[0] # behold the power of automatic differentiation!

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
                sys.stdout.write('Octave {} Iteration {}\n'.format(octave+1,i+1))
                sys.stdout.flush()
                g = calc_grad_tiled(sess, img, t_grad, t_input)
                img += g*(step / (np.abs(g).mean()+1e-7))

        save_image(img,outputimage)	

    img0 = PIL.Image.open(img_name)
    img0 = np.float32(img0)
     
    sys.stdout.write('DeepDreaming ...\n')
    sys.stdout.flush()
    # apply gradient ascent
    render_deepdream(tf.square(T(inception_layer, graph)), img0, inception_layer,img_name)
    
	  
  
if __name__ == '__main__':
    image_loc = sourceimage
    inception_layer = layername
    deep_dream(image_loc, inception_layer)
    print("DeepDream processing complete")