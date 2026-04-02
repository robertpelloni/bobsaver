from __future__ import absolute_import, division, print_function, unicode_literals

import tensorflow as tf

print(" ")
print("*** Detected devices list ***")
print(" ")
from tensorflow.python.client import device_lib
print(device_lib.list_local_devices())

print(" ")
print("*** Detected TensorFlow version ***")
print(" ")
print(tf.version.VERSION)

print(" ")
print("*** Detected keras version ***")
print(" ")
print(tf.keras.__version__)
print(" ")
