"""
Video Utilities

A collection of functions for handling and annotating videos
"""
import numpy as np
import cv2


def read(path, start, stop, rgb):
    """ Reads in a video file and returns contents from start to stop
    :param path: relative or absolute path to video file
    :param start: start time from beginning of video in seconds
    :param stop: stop time from end of video in seconds
    :param rgb: is video RGB
    :return: video dictionary
    """

    # initialize video dictionary
    video = {'Name': path}

    # open video file and extract frames
    #try:
    cap = cv2.VideoCapture(path)
    video['Width'] = int(cap.get(3))
    video['Height'] = int(cap.get(4))
    video['FPS'] = cap.get(5)
    video['NFrames'] = int(cap.get(7))

    startIdx = int(start*video['FPS'])
    stopIdx = int(video['NFrames']-stop*video['FPS']-1)

    # trim start
    for i in range(startIdx):
        cap.grab()

    # get frames until stop or end
    if rgb:
        video['Data'] = np.zeros((video['Height'], video['Width'], 3, stopIdx-startIdx+1))

        for i in range(stopIdx):
            # Capture frame-by-frame
            ret, video['Data'][:,:,:,i] = cap.read()

            if not ret:
                break
    else:
        video['Data'] = np.zeros((video['Height'], video['Width'], stopIdx-startIdx+1))

        for i in range(stopIdx):
            # Capture frame-by-frame
            ret, video['Data'][:,:,i] = cap.read()

            if not ret:
                break

    #except IOError as e:
    #    print "I/O error({0}): {1}".format(e.errno, e.strerror)
    #    raise

    cap.release()

    return video


def var(path, start, stop):
    """
    :param path: relative or absolute path to video file
    :param start: start time of video in seconds
    :param stop: stop time of video in seconds
    :return: 3-dimensional matrix of video data
    """

    while(True):
        # Capture frame-by-frame
        ret, frame = cap.read()

        # Our operations on the frame come here
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Display the resulting frame
        cv2.imshow('frame',gray)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Release the capture
    cap.release()

    return vidvar