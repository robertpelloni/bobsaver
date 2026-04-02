import numpy as np
import matplotlib.pyplot as plt
import os
import cv2
import random
import pickle

TRAINDATADIR = "C:/code/Delphi/Chaos/TensorFlow/SCA2D/Train/"
TESTDATADIR = "C:/code/Delphi/Chaos/TensorFlow/SCA2D/Test/"
CATEGORIES = ["Bad","Good"]

IMG_SIZE = 128;
	
# create the training data
training_data = []
testing_data = []

def create_training_data():
	for category in CATEGORIES:
		# path to Good and Bad directories
		path = os.path.join(TRAINDATADIR, category)
		# print(path)
		class_num = CATEGORIES.index(category)
		for img in os.listdir(path):
			# print(img)
			print(os.path.join(path,img))
			# just in case any of the source images are invalid
			# this can happen when using the publically available sets like
			# kaggle cats and dogs
			try:
				img_array = cv2.imread(os.path.join(path,img), cv2.IMREAD_GRAYSCALE)
				
				# print(img_array)
				# plt.imshow(img_array, cmap="gray")
				# plt.show()

				# resize input image
				new_array = cv2.resize(img_array, (IMG_SIZE, IMG_SIZE))

				# plt.imshow(new_array, cmap="gray")
				# plt.show()
				training_data.append([new_array, class_num])
			except Exception as e:
				pass
				
print("Creating the training data")
create_training_data()
print("Training completed. Length of training_data is")
print(len(training_data))
print("Shuffling data")
random.shuffle(training_data)
print("First 10 training_data labels")
for sample in training_data[:10]:
	print(sample[1])
	
print("Packing data ready to feed into TensorFlow")
X = []
y = []
for features, label in training_data:
	X.append(features)
	y.append(label)
# reshape for TensorFlow
# for the future, if using RGB instead of grayscale the last 1 needs to be changed to a 3
X = np.array(X).reshape(-1, IMG_SIZE, IMG_SIZE, 1)

print("Saving training data")

pickle_out = open("C:/code/Delphi/Chaos/TensorFlow/X.pickle","wb")
pickle.dump(X, pickle_out)
pickle_out.close()

pickle_out = open("C:/code/Delphi/Chaos/TensorFlow/y.pickle","wb")
pickle.dump(y, pickle_out)
pickle_out.close()

# print("Test loading saved training data")
# pickle_in = open("C:/code/Delphi/Chaos/TensorFlow/X.pickle","rb")
# X = pickle.load(pickle_in);
# print(X[1])

###########################################################################################################################

def create_testing_data():
	for category in CATEGORIES:
		# path to Good and Bad directories
		path = os.path.join(TESTDATADIR, category)
		# print(path)
		class_num = CATEGORIES.index(category)
		for img in os.listdir(path):
			# print(img)
			print(os.path.join(path,img))
			# just in case any of the source images are invalid
			# this can happen when using the publically available sets like
			# kaggle cats and dogs
			try:
				img_array = cv2.imread(os.path.join(path,img), cv2.IMREAD_GRAYSCALE)

				# print(img_array)
				# plt.imshow(img_array, cmap="gray")
				# plt.show()

				# resize input image
				new_array = cv2.resize(img_array, (IMG_SIZE, IMG_SIZE))
				
				# plt.imshow(new_array, cmap="gray")
				# plt.show()
				testing_data.append([new_array, class_num])
			except Exception as e:
				pass
				
print("Creating the testing data")
create_testing_data()
print("Training completed. Length of testing_data is")
print(len(testing_data))
print("Shuffling data")
random.shuffle(testing_data)
print("First 10 testing_data labels")
for sample in testing_data[:10]:
	print(sample[1])
	
print("Packing data ready to feed into TensorFlow")
X_Test = []
y_Test = []
for features, label in testing_data:
	X_Test.append(features)
	y_Test.append(label)
# reshape for TensorFlow
# for the future, if using RGB instead of grayscale the last 1 needs to be changed to a 3
X_Test = np.array(X_Test).reshape(-1, IMG_SIZE, IMG_SIZE, 1)

print("Saving testing data")

pickle_out = open("C:/code/Delphi/Chaos/TensorFlow/X_Test.pickle","wb")
pickle.dump(X_Test, pickle_out)
pickle_out.close()

pickle_out = open("C:/code/Delphi/Chaos/TensorFlow/y_Test.pickle","wb")
pickle.dump(y_Test, pickle_out)
pickle_out.close()

# print("Test loading saved training data")
# pickle_in = open("C:/code/Delphi/Chaos/TensorFlow/X.pickle","rb")
# X = pickle.load(pickle_in);
# print(X[1])

print("Done. Ready for training and testing.")