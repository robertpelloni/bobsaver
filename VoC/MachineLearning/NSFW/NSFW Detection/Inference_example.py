import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

#import matplotlib.pyplot as plt
import os
import numpy as np
import torch
from torch import nn
import torch.nn.functional as F
from torchvision import transforms, models
from PIL import Image
from torch.autograd import Variable
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--input_image', type=str, help='Image to classify.')
  args = parser.parse_args()
  return args

args=parse_args();



# In[7]:


#image directory
#data_dir = 'images/'

test_transforms = transforms.Compose([transforms.Resize(224),
                                      transforms.CenterCrop(224),
                                      transforms.ToTensor(),
                                      transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                                          std=[0.229, 0.224, 0.225])
                                     ])


# In[8]:


sys.stdout.write("Loading model ...\n")
sys.stdout.flush()

#model loading
model = models.resnet50()
model.fc = nn.Sequential(nn.Linear(2048, 512),
                                 nn.ReLU(),
                                 nn.Dropout(0.2),
                                 nn.Linear(512, 10),
                                 nn.LogSoftmax(dim=1))
model.load_state_dict(torch.load('ResNet50_nsfw_model.pth'))
model.eval()


# In[9]:


#prediction function
def predict_image(image):
    image_tensor = test_transforms(image).float()
    image_tensor = image_tensor.unsqueeze_(0)

    if torch.cuda.is_available():
        image_tensor.cuda()

    input = Variable(image_tensor)
    output = model(input)
    index = output.data.numpy().argmax()
    return index


# In[10]:


#model classes
classes=['drawings', 'hentai', 'neutral', 'porn', 'sexy']


"""
#load images
entries = os.listdir(data_dir)

fig=plt.figure(figsize=(10,10))
i=0
for entry in entries:
    i+=1
    image = Image.open(data_dir+entry)
    
    #prediction
    index = predict_image(image)
    
    sub = fig.add_subplot(1, len(entries), i)
    sub.set_title(classes[index])
    plt.axis('off')
    plt.imshow(image)
plt.show()
"""

sys.stdout.write("Predicting ...\n")
sys.stdout.flush()

image = Image.open(args.input_image)
index = predict_image(image)
sys.stdout.write(f"Image classified as {classes[index]}\n")
sys.stdout.flush()


# In[ ]:




