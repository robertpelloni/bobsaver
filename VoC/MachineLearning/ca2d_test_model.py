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

model = keras.models.load_model("C:/code/Delphi/Chaos/Examples/TensorFlow/CA2D.model")

# loop all test images
good_predicted_as_good_count = 0;
good_predicted_as_bad_count = 0;
good_predicted_as_unsure_count = 0;
bad_predicted_as_good_count = 0;
bad_predicted_as_bad_count = 0;
bad_predicted_as_unsure_count = 0;

pred = -1;

print("Predicting good test images")
path = "C:\code\Delphi\Chaos\TensorFlow\CA2D\Test\Good"
for img in os.listdir(path):
	prediction = model.predict([prepare(os.path.join(path,img))])
	if prediction[0]<=0.2:
		pred = 0
		good_predicted_as_bad_count=good_predicted_as_bad_count+1
	if prediction[0]>=0.95:
		pred = 1
		good_predicted_as_good_count=good_predicted_as_good_count+1
	if prediction[0]>0.2 and prediction<0.95:
		pred = 2
		good_predicted_as_unsure_count=good_predicted_as_unsure_count+1
	res = "Image {} Probability {} Prediction {}".format(os.path.join(path,img),prediction,CATEGORIES[pred])
	print(res)
print("Predicting bad test images")
path = "C:\code\Delphi\Chaos\TensorFlow\CA2D\Test\Bad"
for img in os.listdir(path):
	prediction = model.predict([prepare(os.path.join(path,img))])
	if prediction[0]<=0.2:
		pred = 0
		bad_predicted_as_bad_count=bad_predicted_as_bad_count+1
	if prediction[0]>=0.95:
		pred = 1
		bad_predicted_as_good_count=bad_predicted_as_good_count+1
	if prediction[0]>0.2 and prediction<0.95:
		pred = 2
		bad_predicted_as_unsure_count=bad_predicted_as_unsure_count+1
	res = "Image {} Probability {} Prediction {}".format(os.path.join(path,img),prediction,CATEGORIES[pred])
	print(res)

print("")
print("Final test results;")
print("")
print("{} total good images tested".format(good_predicted_as_good_count+good_predicted_as_bad_count+good_predicted_as_unsure_count))
print("{} good images predicted as good".format(good_predicted_as_good_count))
print("{} good images predicted as bad".format(good_predicted_as_bad_count))
print("{} good images predicted as unsure".format(good_predicted_as_unsure_count))
print("good prediction accuracy = {:.2f}%".format(good_predicted_as_good_count/(good_predicted_as_good_count+good_predicted_as_bad_count+good_predicted_as_unsure_count)*100))
print("")
print("{} total bad images tested".format(bad_predicted_as_good_count+bad_predicted_as_bad_count+bad_predicted_as_unsure_count))
print("{} bad images predicted as bad".format(bad_predicted_as_bad_count))
print("{} bad images predicted as good".format(bad_predicted_as_good_count))
print("{} bad images predicted as unsure".format(bad_predicted_as_unsure_count))
print("bad prediction accuracy = {:.2f}%".format(bad_predicted_as_bad_count/(bad_predicted_as_bad_count+bad_predicted_as_good_count+bad_predicted_as_unsure_count)*100))

