"""
Image Click XY

Allows a user to extract rectangular regions from an image
"""
import argparse
from os import listdir
from os.path import isfile, join, splitext
import matplotlib.pyplot as plt
import imutils as im


parser = argparse.ArgumentParser(description='Image Click XY')
parser.add_argument("impath", type=str, help="path to image file directory")
parser.add_argument("outpath", type=str, help="path to output file directory")
args = parser.parse_args()

# Set impath and outpath
impath = args.impath
outpath = args.outpath

# Get image file list
imfiles = [f for f in listdir(impath) if isfile(join(impath, f))]

# Loop through image files
for imfile in imfiles:

    #read image
    image = im.read(join(impath, imfile))

    #initialize interactive image
    while True:

        clickim = im.ImageClicker(image, 4)

        rect = im.fitrect(clickim.coords)
        region = im.rotocrop(image, rect)

        plt.imshow(region)
        plt.ion()
        plt.show()

        try:
            flag = raw_input('Enter s (save), r (retry), or sr(save and retry): ')
        except TypeError:
            print "Invalid command..."
            continue

        filename = splitext(imfile)[0]
        fulloutpath = join(outpath, filename + '_tag.png')

        fnum = 0

        while isfile(fulloutpath):
            filename = splitext(imfile)[0]
            fulloutpath = join(outpath, filename + '_tag' + str(fnum) +'.png')
            fnum += 1

        if flag == 's':
            im.write(region, fulloutpath)
            plt.ioff()
            plt.close()
            break
        elif flag == 'r':
            plt.ioff()
            plt.close()
            continue
        elif flag == 'sr':
            im.write(region, fulloutpath)
            plt.ioff()
            plt.close()
            continue
        else:
            continue





