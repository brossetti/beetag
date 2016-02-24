"""
Bee Tag Identifier

Provides a detailed summary of bee tags detected in a given video file
"""

import argparse
import numpy as np
from os.path import isfile, join, split, abspath
from PIL import Image

# Parse arguments
parser = argparse.ArgumentParser(description="Bee Tag Identifier")
parser.add_argument('input', type=str, nargs="+", help="path to input video file", required=True)
parser.add_argument('-o', '--outputdir', type=str, default='.', help="path to output directory")
parser.add_argument('--start', type=int, default=0, help="video start time in seconds")
parser.add_argument('--stop', type=int, default=0, help="video end time in seconds")
args = parser.parse_args()

# Sort out inptu arguments/options
inpath = abspath(args.input)

