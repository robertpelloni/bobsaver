# based on code from https://github.com/Skuldur/Classical-Piano-Composer
# to use this script pass in;
# 1. the directory with midi files
# 2. the directory you want your models to be saved to
# 3. the model filename prefix
# 4. how many total epochs you want to train for
# eg python -W ignore "C:\\LSTM Composer\\lstm_music_train.py" "C:\\LSTM Composer\\Bach\\" "C:\\LSTM Composer\\" "Bach" 500

import glob
import pickle
import numpy
import sys
import keras
import matplotlib.pyplot as plt

from music21 import converter, instrument, note, chord
from datetime import datetime
from keras.models import Sequential
from keras.layers.normalization import BatchNormalization
from keras.layers import Dense
from keras.layers import Dropout
from keras.layers import CuDNNLSTM
from keras.layers import Activation
from keras.utils import np_utils
from keras.callbacks import TensorBoard
from shutil import copyfile

import os
import tensorflow as tf

# ignore all info and warning messages
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 
tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)

# Check for a GPU
if not tf.test.gpu_device_name():
    sys.stdout.write('No GPU found. Please use a GPU.')
    sys.stdout.flush()	
    exit()
else:
    sys.stdout.write('GPU Device Detected: {}\n\n'.format(tf.test.gpu_device_name()))
    sys.stdout.flush()	

# name of midi file directory, model directory, model file prefix, and epochs
mididirectory = str(sys.argv[1])
modeldirectory = str(sys.argv[2])
modelfileprefix = str(sys.argv[3])
modelepochs = int(sys.argv[4])

notesfile = modeldirectory + modelfileprefix + '.notes'

# callback to save model and plot stats every 25 epochs
class CustomSaver(keras.callbacks.Callback):
	def __init__(self):
		self.epoch = 0	
	# This function is called when the training begins
	def on_train_begin(self, logs={}):
		# Initialize the lists for holding the logs, losses and accuracies
		self.losses = []
		self.acc = []
		self.logs = []
	def on_epoch_end(self, epoch, logs={}):
		# Append the logs, losses and accuracies to the lists
		self.logs.append(logs)
		self.losses.append(logs.get('loss'))
		self.acc.append(logs.get('acc')*100)
		# save model and plt every 50 epochs
		if (epoch+1) % 25 == 0:
			sys.stdout.write("\nAuto-saving model and plot after {} epochs to ".format(epoch+1)+"\n"+modeldirectory + modelfileprefix + "_" + str(epoch+1).zfill(3) + ".model\n"+modeldirectory + modelfileprefix + "_" + str(epoch+1).zfill(3) + ".png\n\n")
			sys.stdout.flush()
			self.model.save(modeldirectory + modelfileprefix + '_' + str(epoch+1).zfill(3) + '.model')
			copyfile(notesfile,modeldirectory + modelfileprefix + '_' + str(epoch+1).zfill(3) + '.notes');
			N = numpy.arange(0, len(self.losses))
			# Plot train loss, train acc, val loss and val acc against epochs passed
			plt.figure(figsize=(18,8))
			plt.subplots_adjust(hspace=0.7)
			plt.subplot(2, 1, 1)
			# plot loss values
			plt.plot(N, self.losses, label = "train_loss")
			#plt.title("Loss [Epoch {}]".format(epoch+1))
			plt.xlabel('Epoch')
			plt.ylabel('Loss')
			plt.grid(True)
			plt.subplot(2, 1, 2)
			# plot accuracy values
			plt.plot(N, self.acc, label = "train_acc")
			#plt.title("Accuracy % [Epoch {}]".format(epoch+1))
			plt.xlabel("Epoch")
			plt.ylabel("Accuracy %")
			plt.grid(True)
			plt.savefig(modeldirectory + modelfileprefix + '_' + str(epoch+1).zfill(3) + '.png')
			plt.close()
			
# train the neural network
def train_network():

	sys.stdout.write("Reading midi files...\n\n")
	sys.stdout.flush()

	notes = get_notes()

	# get amount of pitch names
	n_vocab = len(set(notes))

	sys.stdout.write("\nPreparing note sequences...\n")
	sys.stdout.flush()

	network_input, network_output = prepare_sequences(notes, n_vocab)

	sys.stdout.write("\nCreating CuDNNLSTM neural network model...\n")
	sys.stdout.flush()

	model = create_network(network_input, n_vocab)

	sys.stdout.write("\nTraining CuDNNLSTM neural network model...\n\n")
	sys.stdout.flush()

	train(model, network_input, network_output)

# get all the notes and chords from the midi files
def get_notes():

	# remove existing data file if it exists
	if os.path.isfile(notesfile):
		os.remove(notesfile)
	
	notes = []

	for file in glob.glob("{}/*.mid".format(mididirectory)):
		midi = converter.parse(file)

		sys.stdout.write("Parsing %s ...\n" % file)
		sys.stdout.flush()

		notes_to_parse = None

		try: # file has instrument parts
			s2 = instrument.partitionByInstrument(midi)
			notes_to_parse = s2.parts[0].recurse() 
		except: # file has notes in a flat structure
			notes_to_parse = midi.flat.notes

		for element in notes_to_parse:
			if isinstance(element, note.Note):
				notes.append(str(element.pitch))
			elif isinstance(element, chord.Chord):
				notes.append('.'.join(str(n) for n in element.normalOrder))

	with open(notesfile,'wb') as filepath:
		pickle.dump(notes, filepath)

	return notes

# prepare the sequences used by the neural network
def prepare_sequences(notes, n_vocab):
	sequence_length = 100

	# get all pitch names
	pitchnames = sorted(set(item for item in notes))

	 # create a dictionary to map pitches to integers
	note_to_int = dict((note, number) for number, note in enumerate(pitchnames))

	network_input = []
	network_output = []

	# create input sequences and the corresponding outputs
	for i in range(0, len(notes) - sequence_length, 1):
		sequence_in = notes[i:i + sequence_length] # needs to take into account if notes in midi file are less than required 100 ( mod ? )
		sequence_out = notes[i + sequence_length]  # needs to take into account if notes in midi file are less than required 100 ( mod ? )
		network_input.append([note_to_int[char] for char in sequence_in])
		network_output.append(note_to_int[sequence_out])

	n_patterns = len(network_input)

	# reshape the input into a format compatible with CuDNNLSTM layers
	network_input = numpy.reshape(network_input, (n_patterns, sequence_length, 1))
	# normalize input
	network_input = network_input / float(n_vocab)

	network_output = np_utils.to_categorical(network_output)

	return (network_input, network_output)

# create the structure of the neural network
def create_network(network_input, n_vocab):

	'''
	""" create the structure of the neural network """
	model = Sequential()
	model.add(CuDNNLSTM(512, input_shape=(network_input.shape[1], network_input.shape[2]), return_sequences=True))
	model.add(Dropout(0.3))
	model.add(CuDNNLSTM(512, return_sequences=True))
	model.add(Dropout(0.3))
	model.add(CuDNNLSTM(512))
	model.add(Dense(256))
	model.add(Dropout(0.3))
	model.add(Dense(n_vocab))
	model.add(Activation('softmax'))
	model.compile(loss='categorical_crossentropy', optimizer='rmsprop',metrics=["accuracy"])
	'''
	
	'''
	# too big?  overfits a lot - this was original model from softology lstm composer blog post
	model = Sequential()
	
	model.add(CuDNNLSTM(512, input_shape=(network_input.shape[1], network_input.shape[2]), return_sequences=True))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(CuDNNLSTM(256))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(Dense(128, activation="relu"))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(Dense(n_vocab))
	model.add(Activation('softmax'))
	model.compile(loss='categorical_crossentropy', optimizer='adam',metrics=["accuracy"])
	'''
	
	'''
	# too small?  never gets above 40% accuracy
	model = Sequential()
	
	model.add(CuDNNLSTM(128, input_shape=(network_input.shape[1], network_input.shape[2]), return_sequences=True))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(CuDNNLSTM(64))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(Dense(32, activation="relu"))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(Dense(n_vocab))
	model.add(Activation('softmax'))
	model.compile(loss='categorical_crossentropy', optimizer='adam',metrics=["accuracy"])
	'''
	
	'''
	# medium still overfits on softology - need to try bigger midi sets with this one
	model = Sequential()
	
	model.add(CuDNNLSTM(256, input_shape=(network_input.shape[1], network_input.shape[2]), return_sequences=True))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(CuDNNLSTM(128))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(Dense(64, activation="relu"))
	model.add(Dropout(0.3))
	model.add(BatchNormalization())
	
	model.add(Dense(n_vocab))
	model.add(Activation('softmax'))
	model.compile(loss='categorical_crossentropy', optimizer='adam',metrics=["accuracy"])
	'''
	
	model = Sequential()
	
	model.add(CuDNNLSTM(512, input_shape=(network_input.shape[1], network_input.shape[2]), return_sequences=True))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(CuDNNLSTM(256))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(Dense(128, activation="relu"))
	model.add(Dropout(0.2))
	model.add(BatchNormalization())
	
	model.add(Dense(n_vocab))
	model.add(Activation('softmax'))
	model.compile(loss='categorical_crossentropy', optimizer='adam',metrics=["accuracy"])

	return model

# train the neural network
def train(model, network_input, network_output):
	
	# saver = CustomSaver()
	# history = model.fit(network_input, network_output, epochs=modelepochs, batch_size=50, callbacks=[tensorboard])
	history = model.fit(network_input, network_output, epochs=modelepochs, batch_size=50, callbacks=[CustomSaver()])

	# evaluate the model
	print("\nModel evaluation at the end of training")
	train_acc = model.evaluate(network_input, network_output, verbose=0)
	print(model.metrics_names)
	print(train_acc)
	
	# save trained model
	model.save(modeldirectory + modelfileprefix + '_' + str(modelepochs) + '.model')

	# delete temp notes file
	os.remove(notesfile)
	
if __name__ == '__main__':
	train_network()

