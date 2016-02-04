"""
Image Utilities

A collection of functions for handling and annotating images
"""
from sys import exc_info
from PIL import Image
from matplotlib import pyplot as plt
from matplotlib.image import AxesImage

def imread(path):
    '''Reads in and returns an image from a defined path'''

    try: 
        image = Image.open(path)
    except IOError as e:
	print "I/O error({0}): {1}".format(e.errno, e.strerror)
        raise

    return image

class ImageClicker(object):

    def __init__(self, image, clicklim):
        self.image = image
        self.clicklim = clicklim
        self.nclicks = 0
        self.coords = [None]*clicklim

        fig = plt.figure()
        fig.canvas.set_window_title('Click (X,Y) Coordinates')
        ax = plt.axes([0,0,1,1]) 
        plt.imshow(image, picker=True)
        plt.axis('off')

        self.bid = fig.canvas.mpl_connect('pick_event', self.on_pick)

        plt.show()


    def on_pick(self,event):
        artist = event.artist
        if isinstance(artist, AxesImage):
            mouseevent = event.mouseevent
            self.coords[self.nclicks] = (mouseevent.xdata, mouseevent.ydata)
            print "Coordinate %d: %s" % (self.nclicks, self.coords[self.nclicks])

            if self.nclicks < (self.clicklim - 1):
                self.nclicks += 1
            else:
                print "disconnecting console coordinate printout..."
                plt.disconnect(self.bid)


# Testing
if __name__ == "__main__":
    image = imread('/Users/blair/Desktop/bee/Photos/IMG_0324.JPG')
    clickim = ImageClicker(image, 4)

    print "end"
