import os

# ignore all info and warning messages
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import tensorflow.compat.v1 as tf
tf.disable_v2_behavior()
tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)

import cv2
import sys
import tensorflow.keras.models

modelpath = str(sys.argv[1])
imagepath = str(sys.argv[2])

# print('Arguments:', len(sys.argv))
# print('List:', str(sys.argv))
# print("")
# print("modelpath = ")
# print(modelpath)
# print("")
# print("imagepath = ")
# print(imagepath)

CATEGORIES = ["Bad", "Good", "Unsure"]

def prepare(filepath):
	IMG_SIZE = 128;
	img_array = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
	# normalize grayscale values! VERY IMPORTANT for prediction accuracy
	img_array = img_array/255.0
	new_array = cv2.resize(img_array, (IMG_SIZE, IMG_SIZE))
	return new_array.reshape(-1, IMG_SIZE, IMG_SIZE, 1)

model = tensorflow.keras.models.load_model(os.path.join(modelpath,"CA2D.model"))

pred = -1;

prediction = model.predict([prepare(imagepath)])
if prediction[0]<=0.2:
	pred = 0
if prediction[0]>=0.95:
	pred = 1
if prediction[0]>0.2 and prediction<0.95:
	pred = 2
	
print("")
res = "Probability {}".format(prediction)
print(res)
print("")
res = "{}".format(CATEGORIES[pred])
print(res)
