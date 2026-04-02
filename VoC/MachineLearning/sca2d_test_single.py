import cv2
import os
import keras.models

CATEGORIES = ["Bad", "Good", "Unsure"]

def prepare(filepath):
	IMG_SIZE = 128;
	img_array = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
	# normalize grayscale values! VERY IMPORTANT for prediction accuracy
	img_array = img_array/255.0
	new_array = cv2.resize(img_array, (IMG_SIZE, IMG_SIZE))
	return new_array.reshape(-1, IMG_SIZE, IMG_SIZE, 1)

model = keras.models.load_model("C:/code/Delphi/Chaos/TensorFlow/SCA2D.model")

pred = -1;

prediction = model.predict([prepare(os.path.join("C:/code/Delphi/Chaos/TensorFlow/","TestSCA.JPG"))])
if prediction[0]<=0.2:
	pred = 0
if prediction[0]>=0.95:
	pred = 1
if prediction[0]>0.2 and prediction<0.95:
	pred = 2
	
print("")
res = "Image {} Probability {} Prediction {}".format("C:/code/Delphi/Chaos/TensorFlow/TestSCA.JPG",prediction,CATEGORIES[pred])
print(res)
print("")
res = "{}".format(CATEGORIES[pred])
print(res)
