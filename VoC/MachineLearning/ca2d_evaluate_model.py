import cv2
import os
import keras.models
import pickle

CATEGORIES = ["Bad", "Good"]

model = keras.models.load_model("C:/code/Delphi/Chaos/TensorFlow/CA2D.model")

print("Loading testing data")
X_Test = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/X_Test.pickle","rb"))
y_Test = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/y_Test.pickle","rb"))

# normalize the image data
print("Normalizing testing data")
X_Test = X_Test/255.0

print("Evaluating testing data")
results = model.evaluate(X_Test, y_Test, batch_size=50)

print('Evaluation results')
print('test loss, test acc:', results)