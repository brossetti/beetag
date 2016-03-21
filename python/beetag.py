"""
Bee Tag Identifier

Provides a detailed summary of bee tags detected in a given video file
"""

import argparse
import numpy as np
from os.path import isfile, join, split, abspath
import vidutils as vid

'''
# Parse arguments
parser = argparse.ArgumentParser(description="Bee Tag Identifier")
parser.add_argument('input', type=str, help="path to input video file")
parser.add_argument('-o', '--outputdir', type=str, default='.', help="path to output directory")
parser.add_argument('--start', type=int, default=0, help="start time from beginning of video in seconds")
parser.add_argument('--stop', type=int, default=0, help="stop time from end of video in seconds")
args = parser.parse_args()

# Sort out input arguments/options
inpath = abspath(args.input)
outpath = abspath(args.outputdir)
start = args.start
stop = args.stop
'''

#testing
''''
inpath = abspath('/Users/blair/Desktop/bee/_TrainingVideos/MVI_9625.AVI')
outpath = abspath('.')
start = 35
stop = 60
'''
inpath = abspath('/Users/blair/Desktop/bee/MVI_0228.AVI')
outpath = abspath('.')
start =1450
stop = 1500

# Read video file
vidmat, vidinfo = vid.read(inpath, start, stop)

# Define active region
bbox, mbr = vid.active_region(vidmat.copy())

# Reduce video to active region
vidmat = vidmat[bbox[1]:bbox[1]+bbox[3], bbox[0]:bbox[0]+bbox[2], :]

# Search active video for tags
