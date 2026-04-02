from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation, Flatten, Conv2D, MaxPooling2D
from keras.callbacks import TensorBoard
from keras.layers.normalization import BatchNormalization
import pickle
import time
import datetime
from datetime import datetime
import os
import matplotlib.pyplot as plt

# TensorBoard logging and callback
now = datetime.now() # current date and time
NAME = "CA2D-{}".format(now.strftime("%Y-%m-%d-%H-%M-%S"))
# tensorboard = TensorBoard(log_dir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\{}".format(NAME), histogram_freq=1, write_grads=1, write_images=1)
# tensorboard = TensorBoard(log_dir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\{}".format(NAME), histogram_freq=1)
tensorboard = TensorBoard(log_dir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\{}".format(NAME))
# to see the logs/graphs, open a command prompt and type
# tensorboard --logdir="C:\\code\\Delphi\\Chaos\\TensorFlow\\Logs\\"
# then open localhost:6006 to see graphs etc

print("Loading training data")
X = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/X.pickle","rb"))
y = pickle.load(open("C:/code/Delphi/Chaos/TensorFlow/y.pickle","rb"))

# normalize the image data
print("Normalizing training data")
X = X/255.0

print("Creating the model")
model = Sequential()

'''
# Version 1
# ORIGINAL MODEL from https://www.youtube.com/watch?v=WvoLTXIjBYU&list=PLQVvvaa0QuDfhTox0AjmQ6tvTgMBZBEXN&index=3
model.add(Conv2D(64, (3,3), input_shape = X.shape[1:]))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Conv2D(64, (3,3)))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Flatten())
model.add(Dense(64))
model.add(Activation("relu"))

model.add(Dense(1))
model.add(Activation("sigmoid"))
'''

'''
# Version 2
# Original model from sentdex videos
# https://youtu.be/WvoLTXIjBYU
# Adding dropouts to stop overfitting

model.add(Conv2D(64, (3,3), input_shape = X.shape[1:]))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))
model.add(Dropout(0.4))

model.add(Conv2D(64, (3,3)))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))
model.add(Dropout(0.4))

model.add(Flatten())

model.add(Dense(64))
model.add(Activation("relu"))
model.add(Dropout(0.4))

model.add(Dense(1))
model.add(Activation("sigmoid"))
'''

'''
# Version 3
# https://towardsdatascience.com/applied-deep-learning-part-4-convolutional-neural-networks-584bc134c1e2
model.add(Conv2D(32, (3,3), input_shape = X.shape[1:]))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Conv2D(64, (3,3)))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Conv2D(128, (3,3)))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Conv2D(128, (3,3)))
model.add(Activation("relu"))
model.add(MaxPooling2D(pool_size=(2,2)))

model.add(Flatten())
model.add(Dropout(0.5))
model.add(Dense(512))
model.add(Activation("relu"))
model.add(Dense(1))
model.add(Activation("sigmoid"))
'''


# Version 4
# TRY THIS MODEL TOO with 2 CONV2D in a row ?? http://www.dsimb.inserm.fr/~ghouzam/personal_projects/Simpson_character_recognition.html
model.add(Conv2D(32, (3,3), input_shape = X.shape[1:]))
model.add(Conv2D(32, (3,3)))
model.add(Activation("relu"))
# BatchNormalization better than Dropout? https://www.kdnuggets.com/2018/09/dropout-convolutional-networks.html
# model.add(BatchNormalization())
model.add(MaxPooling2D(pool_size=(2,2)))
model.add(Dropout(0.25))

model.add(Conv2D(64, (3,3)))
model.add(Conv2D(64, (3,3)))
model.add(Activation("relu"))
# BatchNormalization better than Dropout? https://www.kdnuggets.com/2018/09/dropout-convolutional-networks.html
# model.add(BatchNormalization())
model.add(MaxPooling2D(pool_size=(2,2)))
model.add(Dropout(0.25))

model.add(Conv2D(128, (3,3)))
model.add(Conv2D(128, (3,3)))
model.add(Activation("relu"))
# BatchNormalization better than Dropout? https://www.kdnuggets.com/2018/09/dropout-convolutional-networks.html
# model.add(BatchNormalization())
model.add(MaxPooling2D(pool_size=(2,2)))
model.add(Dropout(0.5))

model.add(Flatten())

model.add(Dense(64))
model.add(BatchNormalization())
model.add(Activation("relu"))

model.add(Dense(32))
model.add(BatchNormalization())
model.add(Activation("relu"))

model.add(Dense(16))
model.add(BatchNormalization())
model.add(Activation("relu"))

model.add(Dense(1))
model.add(Activation("sigmoid"))


print("Compiling the model")
model.compile(loss="binary_crossentropy",optimizer="adam",metrics=["accuracy"])

print("Training the model")
history = model.fit(X, y, batch_size=10, epochs=20, validation_split=0.3, callbacks=[tensorboard])

print("Training complete.  Model summary;")
model.summary()

# evaluate the model
print("Model evaluation at the end of training")
train_acc = model.evaluate(X, y, verbose=0)
print(model.metrics_names)
print(train_acc)

print("Saving the model")
model.save("C:/code/Delphi/Chaos/TensorFlow/CA2D.model")

# more graph options here https://www.kaggle.com/amarjeet007/visualize-cnn-with-keras#notebook-container

plt.subplots_adjust(hspace=0.7)
plt.subplot(2, 1, 1)

# https://keras.io/visualization/
# Plot training & validation accuracy values
plt.plot(history.history['acc'])
plt.plot(history.history['val_acc'])
plt.title('Model accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['acc', 'val_acc'], loc='lower right')
# plt.ion() # makes the plot non-blocking so python code continues once plot is shown
# plt.show()

plt.subplot(2, 1, 2)

# Plot training & validation loss values
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['loss', 'val_loss'], loc='upper right')
# plt.ion() # makes the plot non-blocking so python code continues once plot is shown
plt.show()

print("Done.  Model is ready to be used for predictions.")