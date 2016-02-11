"""
Image Utilities

A collection of functions for handling and annotating images
"""
import numpy as np
from PIL import Image
from matplotlib import pyplot as plt
from matplotlib.image import AxesImage
from matplotlib.patches import Polygon
from scipy.spatial import ConvexHull


class ImageClicker(object):
    """Class for clickable images"""

    def __init__(self, image, clicklim):
        self.image = image
        self.clicklim = clicklim
        self.nclicks = 0
        self.coords = [None]*clicklim

        self.fig = plt.figure()
        self.fig.canvas.set_window_title('Click (X,Y) Coordinates')
        plt.axes([0,0,1,1])
        plt.imshow(image, picker=True)
        plt.axis('image')

        self.bid = self.fig.canvas.mpl_connect('pick_event', self.on_pick)

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
                self.bbox = fitrect(self.coords)
                p = Polygon(self.bbox, facecolor=(0,0,1,0.25), edgecolor=(1,0,0,0.75))
                plt.gca().add_artist(p)
                plt.draw()


def fitrect(points):
    """Finds the minimum bounding rectangle"""
    #determine convex hull of points
    hull = ConvexHull(points)
    pts = hull.points[hull.vertices]

    #determine unit edge direction
    vects = np.diff(np.vstack((pts, pts[0])), axis=0)
    norms = np.linalg.norm(vects, axis=1)
    uvects = np.dot(np.diag(1/norms),vects)
    nvects = np.fliplr(uvects)*(-1,1)

    #find MBR
    def minmax(x): return np.vstack((x.min(axis=0),x.max(axis=0)))
    x = minmax(np.dot(pts, np.transpose(uvects)))
    y = minmax(np.dot(pts, np.transpose(nvects)))

    areas = (y[0,:]-y[1,:])*(x[0,:]-x[1,:])
    idx = np.argmin(areas)

    #define the rectangle
    xys = np.column_stack((x[[0,1,1,0,0],idx], y[[0,0,1,1,0],idx]))
    rect  = np.dot(xys, np.vstack((uvects[idx,:],nvects[idx,:])))

    return rect.astype(int)


def read(path):
    """Reads in and returns an image from a defined path"""

    try: 
        image = Image.open(path)
    except IOError as e:
        print "I/O error({0}): {1}".format(e.errno, e.strerror)
        raise

    return image


def write(image, path):
    """Writes an image to a file at the defined path"""

    try:
        image.save(path)
    except IOError as e:
        print "I/O error({0}): {1}".format(e.errno, e.strerror)
        raise


def rotocrop(image, rect):
    """Crops rotated rectangles from an image"""
    #remove duplicate row
    pts = rect[0:4,:]

    #check if rect is level
    if len(np.unique(pts[:,0])) == 2:
        left = np.min(pts[:,0])
        upper = np.min(pts[:,1])
        right = np.max(pts[:,0])
        lower = np.max(pts[:,1])
        region = image.crop((left, upper, right, lower))

        return region

    #reorder vertice based on location
    idx = np.argsort(pts[:,1])
    idx[2], idx[3] = idx[3], idx[2]
    pts = pts[idx,:]

    #determine width and height
    vects = np.diff(pts[0:3,:], axis=0)
    norms = np.linalg.norm(vects, axis=1)

    #determine rotation and (w,h)
    angle = np.arctan2(vects[0,1],vects[0,0]) * 180 / np.pi
    if angle > 90:
        angle -= 180

    #extract major bounding box
    left = np.min(pts[:,0])
    upper = np.min(pts[:,1])
    right = np.max(pts[:,0])
    lower = np.max(pts[:,1])
    bbox = image.crop((left, upper, right, lower))

    #rotate and recrop
    region = bbox.rotate(angle,expand=True)
   
    #final crop
    rwh = region.size
    if np.argmin(rwh) != np.argmin(norms):
        norms = norms[::-1].astype(int)
    else:
        norms = norms.astype(int)
    left = rwh[0]/2 - norms[0]/2
    upper = rwh[1]/2 - norms[1]/2
    right = rwh[0] - left
    lower = rwh[1] - upper
    region = region.crop((left, upper, right, lower))

    return region


# Testing
if __name__ == "__main__":
    from matplotlib.patches import Polygon

    image = read('/Users/blair/Desktop/bee/Photos/IMG_0324.JPG')
    clickim = ImageClicker(image, 4)

    region = rotocrop(image, rect)

    region.show()

    print "done"
