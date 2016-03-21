"""
Image Click XY

Allows a user to extract rectangular regions from an image
"""
import argparse
from os import listdir
from os.path import abspath, isfile, join, splitext
from sys import exit
import matplotlib.pyplot as plt
import imutils as im


parser = argparse.ArgumentParser(description="Image Click XY")
parser.add_argument('input', type=str, help="path to image file directory")
parser.add_argument('output', type=str, help="path to output file directory")
args = parser.parse_args()

# Set inpath and outpath
inpath = abspath(args.input)
outpath = abspath(args.output)

# Get image file list
imfiles = [f for f in listdir(inpath) if (isfile(join(inpath, f)) and not f.startswith('.'))]

# Loop through image files
for imfile in imfiles:

    # read image
    image = im.read(join(inpath, imfile))

    # begin program
    while True:

        # initialize interactive image
        clickim = im.ImageClicker(image, 4)

        # extract region
        rect = im.fitrect(clickim.coords)
        region = im.rotocrop(image, rect)

        # display region
        plt.imshow(region)
        plt.ion()
        plt.show()

        # prompt user for action
        try:
            flag = raw_input("Enter s (save), r (retry), sr (save and retry), n (next), q (quit), or sq (save and quit): ")
        except TypeError:
            print "Invalid command..."
            continue

        # set filename
        fnum = 1
        filename = splitext(imfile)[0]
        full_outpath = join(outpath, filename + '_tag' + str(fnum) + '.png')

        while isfile(full_outpath):
            filename = splitext(imfile)[0]
            full_outpath = join(outpath, filename + '_tag' + str(fnum) + '.png')
            fnum += 1

        # perform user-defined action
        if flag == 's':
            im.write(region, full_outpath)
            plt.ioff()
            plt.close()
            break
        elif flag == 'r':
            plt.ioff()
            plt.close()
            continue
        elif flag == 'sr':
            im.write(region, full_outpath)
            plt.ioff()
            plt.close()
            continue
        elif flag == 'n':
            plt.ioff()
            plt.close()
            break
        elif flag == 'q':
            plt.ioff()
            plt.close()
            exit("Quit")
        elif flag == 'sq':
            im.write(region, full_outpath)
            plt.ioff()
            plt.close()
            exit("Quit")
        else:
            continue





