import nltk

nltk.download('omw-1.4')
nltk.download('wordnet')

import sys
from nltk.corpus import wordnet
import argparse

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--phrase', type=str, help='Phrase to get synonyms for.')
  args = parser.parse_args()
  return args

args=parse_args();

#split source phrase
words = args.phrase.split()
for w in words:
    if len(w)<3:
        sys.stdout.write(f"\n***{w} ")
    else:
        #get synonyms
        wcount=0
        for syn in wordnet.synsets(w):
            sys.stdout.write(f"\n{syn}\n")
            sys.stdout.flush()
            sys.stdout.write("***")
            for name in syn.lemma_names():
                #could use the following replace to convert underscaores to spaces, but VoC handles this
                #sys.stdout.write(f"{name.replace('_', ' ')} ")
                sys.stdout.write(f"{name.replace('_', ' ')} ")
                wcount+=1
            #the next break ensures only the first main synonym set is returned
            break
        #if no synonyms found just use original word
        if wcount==0:
            sys.stdout.write(f"\n***{w} ")

sys.stdout.write("\n")
sys.stdout.flush()
