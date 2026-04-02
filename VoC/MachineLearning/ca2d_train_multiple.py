from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation, Flatten, Conv2D, MaxPooling2D
from keras.callbacks import TensorBoard
import pickle
import time
import datetime
from datetime import datetime
import os

print("Loading training data")
X = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/X.pickle","rb"))
y = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/y.pickle","rb"))

# normalize the image data
print("Normalizing training data")
X = X/255.0

# parameters to loop through
dense_layers = [0, 1, 2]
layer_sizes = [32, 64, 128]
conv_layers = [1, 2, 3]

# once trained and you have an idea of good parameters, the loops can be twekaed, eg
# if 0 dense layers and 3 conv layers always "win" then test those with larger layer sizes...
# dense_layers = [0]
# layer_sizes = [64, 128, 256]
# conv_layers = [3]

for dense_layer in dense_layers:
	for layer_size in layer_sizes:
		for conv_layer in conv_layers:
			now = datetime.now()
			NAME = "{}-conv-{}-nodes-{}-dense-{}".format(conv_layer, layer_size, dense_layer,now.strftime("%Y-%m-%d-%H-%M-%S"))
			# TensorBoard logging and callback
			# to see the logs/graphs, open a command prompt and type
			# tensorboard --logdir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\"
			# then open localhost:6006 in a browser to see graphs etc
			tensorboard = TensorBoard(log_dir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\{}".format(NAME))
			print("Creating model name {}".format(NAME))

			model = Sequential()

			model.add(Conv2D(layer_size, (3,3), input_shape = X.shape[1:]))
			model.add(Activation("relu"))
			model.add(MaxPooling2D(pool_size=(2,2)))

			for l in range(conv_layer-1):
				model.add(Conv2D(layer_size, (3,3)))
				model.add(Activation("relu"))
				model.add(MaxPooling2D(pool_size=(2,2)))

			model.add(Flatten())
			for l in range(dense_layer):
				model.add(Dense(layer_size))
				model.add(Activation("relu"))

			model.add(Dense(1))
			model.add(Activation("sigmoid"))

			print("Compiling the model")
			model.compile(loss="binary_crossentropy",optimizer="adam",metrics=["accuracy"])

			print("Training the model")
			model.fit(X, y, batch_size=50, epochs=20, validation_split=0.3, callbacks=[tensorboard])

			print("Saving the model")
			model.save("C:/code/Delphi/Chaos/TensorFlow/{}.model".format(NAME))

print("Done.  Models have been trained.  See tensorboard for stats of best model.")
