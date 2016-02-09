"""
Image Utilities

A collection of functions for handling and annotating images
"""
import numpy as np
from sys import exc_info
from PIL import Image
from matplotlib import pyplot as plt
from matplotlib.image import AxesImage
from scipy.spatial import ConvexHull

def imread(path):
    '''Reads in and returns an image from a defined path'''

    try: 
        image = Image.open(path)
    except IOError as e:
	print "I/O error({0}): {1}".format(e.errno, e.strerror)
        raise

    return image

class ImageClicker(object):
    '''Class for clickable images'''

    def __init__(self, image, clicklim):
        self.image = image
        self.clicklim = clicklim
        self.nclicks = 0
        self.coords = [None]*clicklim

        fig = plt.figure()
        fig.canvas.set_window_title('Click (X,Y) Coordinates')
        plt.axes([0,0,1,1]) 
        plt.imshow(image, picker=True)
        plt.axis('image')
        
        self.bid = fig.canvas.mpl_connect('pick_event', self.on_pick)

        plt.show()
         

    def on_pick(self,event):
        artist = event.artist
        if isinstance(artist, AxesImage):
            mouseevent = event.mouseevent
            x = int(mouseevent.xdata)
            y = int(mouseevent.ydata)
            self.coords[self.nclicks] = (x, y)
            plt.plot(x,y,color=(0,1,0,1), marker='+')
            plt.draw()
            print "Coordinate %d: %s" % (self.nclicks, self.coords[self.nclicks])

            if self.nclicks < (self.clicklim - 1):
                self.nclicks += 1
            else:
                print "disconnecting console coordinate printout..."
                plt.disconnect(self.bid)


def fitrect(points):
    '''Finds the minimum bounding rectangle'''
    #determine convex hull of points
    hull = ConvexHull(points)
    pts = hull.points[hull.vertices]

    #determine unit edge direction
    vects = np.diff(np.vstack((pts, pts[0])), axis=0)
    norms = np.linalg.norm(vects, axis=1)
    uvects = np.dot(np.diag(1/norms),vects)
    nvects = np.fliplr(uvects)*(-1,1)

    #find MBR
    minmax = lambda x: np.vstack((x.min(axis=0),x.max(axis=0)))
    x = minmax(np.dot(pts, np.transpose(uvects)))
    y = minmax(np.dot(pts, np.transpose(nvects)))

    areas = (y[0,:]-y[1,:])*(x[0,:]-x[1,:])
    idx = np.argmin(areas)

    #define the rectangle
    xys = np.column_stack((x[[0,1,1,0,0],idx], y[[0,0,1,1,0],idx]))
    rect  = np.dot(xys, np.vstack((uvects[idx,:],nvects[idx,:])))
 
    return rect    

# Testing
if __name__ == "__main__":
    import pdb
    from matplotlib.patches import Polygon
    image = imread('/Users/blair/Desktop/bee/Photos/IMG_0324.JPG')
    clickim = ImageClicker(image, 4)

    print clickim.coords

    rect = fitrect(clickim.coords)

    print(rect)

    fig = plt.figure()
    fig.canvas.set_window_title('Results')
    plt.axes([0,0,1,1])
    plt.imshow(clickim.image)
    plt.axis('image')

    p = Polygon(rect, alpha=0.4)
    plt.gca().add_artist(p)    
    plt.show()
