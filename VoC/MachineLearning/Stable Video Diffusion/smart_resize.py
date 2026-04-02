import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

from PIL import Image
import argparse
import time

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument('--input_image', type=str)
    parser.add_argument('--new_width', type=int)
    parser.add_argument('--new_height', type=int)
    parser.add_argument('--output_image', type=str)
    args = parser.parse_args()
    return args

args2=parse_args();

sys.stdout.write("Loading image ...\n")
sys.stdout.flush()

img = Image.open(args2.input_image)
if img.size[0] == args2.new_width and img.size[1] == args2.new_height:
    #do nothing as image is already the correct size
    img.save(args2.output_image)
    print(f'Image size is already {args2.new_width} by {args2.new_height}.  No need to resize')
    sys.stdout.write(f"Saving image to {args2.output_image} ...\n")
    time.sleep(2)
else:
    sys.stdout.write("Resizing image ...\n")
    sys.stdout.flush()

    print(f'Initial image width is {img.size[0]}')
    print(f'Initial image height is {img.size[1]}')
    #resize width
    base_width = args2.new_width
    wpercent = (base_width / float(img.size[0]))
    hsize = int((float(img.size[1]) * float(wpercent)))
    img = img.resize((base_width, hsize), Image.Resampling.LANCZOS)
    print(f'After resizing width, image dimensions is {img.size[0]} by {img.size[1]}')
    #resize height if height is less than args2.new_height
    if img.size[1]<args2.new_height:
        base_height = args2.new_height
        hpercent = (base_height / float(img.size[1]))
        wsize = int((float(img.size[0]) * float(hpercent)))
        img = img.resize((wsize,base_height), Image.Resampling.LANCZOS)
        print(f'After resizing height, image dimensions is {img.size[0]} by {img.size[1]}')
    #at this point one side will be either args2.new_width or args2.new_height and the other will need to be trimmed
    if img.size[0]>args2.new_width:
        print(f'Image width is {img.size[0]} and will be cropped')
        space = (img.size[0]-args2.new_width)//2
        img = img.crop((space,0,space+args2.new_width,args2.new_height))
        print(f'Image width is {img.size[0]} after cropping')
        #img.save(args2.output_image)
    if img.size[1]>args2.new_height:
        print(f'Image height is {img.size[1]} and will be cropped')
        space = (img.size[1]-args2.new_height)//2
        img = img.crop((0,space,args2.new_width,space+args2.new_height))
        print(f'Image height is {img.size[1]} after cropping')
        #img.save(args2.output_image)
    #save result
    print(f'Final image dimensions are {img.size[0]} by {img.size[1]}')
    sys.stdout.write(f"Saving image to {args2.output_image} ...\n")
    sys.stdout.flush()
    img.save(args2.output_image)
    sys.stdout.write("Done\n")
    sys.stdout.flush()
    time.sleep(2)
    