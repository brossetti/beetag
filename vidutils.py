"""
Video Utilities

A collection of functions for handling and annotating videos
"""
import numpy as np
import cv2


def read(path, start=0, stop=0, gray=True):
    """ Reads in a video file and returns contents from start to stop
    :param path: relative or absolute path to video file
    :param start: start time from beginning of video in seconds
    :param stop: stop time from end of video in seconds
    :param gray: return grayscale
    :return: numpy matrix of video data and dictionary containing video information
    """

    # initialize video dictionary
    vidinfo = {'Name': path}

    # open video file and extract frames
    cap = cv2.VideoCapture(path)
    vidinfo['Width'] = int(cap.get(3))
    vidinfo['Height'] = int(cap.get(4))
    vidinfo['FPS'] = cap.get(5)
    frame_count = int(cap.get(7))

    start_idx = int(start * vidinfo['FPS'])
    stop_idx = int(frame_count - stop * vidinfo['FPS'] - 1)

    # trim start
    for i in range(start_idx):
        cap.grab()

    # read first frame to get video information
    ret, frame = cap.read()
    vidinfo['Type'] = frame.dtype
    vidinfo['Gray'] = gray

    # initialize matrix for rgb or gray
    if gray:
        vidmat = np.zeros((vidinfo['Height'], vidinfo['Width'], stop_idx-start_idx+1), dtype=vidinfo['Type'])
    else:
        vidmat = np.zeros((vidinfo['Height'], vidinfo['Width'], stop_idx-start_idx+1, 3), dtype=vidinfo['Type'])

    # get frames until stop or end
    for i in range(1, stop_idx-start_idx+1):

        # read gray or rgb
        if  gray:
            ret, frame = cap.read()
            vidmat[:, :, i] = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            if not ret:
                break
        else:
            ret, vidmat[:, :, i] = cap.read()

        #display
        cv2.imshow('frame',vidmat[:, :, i])
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

    return vidmat, vidinfo


def active_region(video):
    """
    :param video: numpy matrix of video data
    :return: 3-dimensional matrix of active video region
    """

    # calculate variance over frame dimension
    varim = np.var(video, axis=2)

    # threshold variance image
    ret, thresh_im = cv2.threshold(varim, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)

    return thresh_im