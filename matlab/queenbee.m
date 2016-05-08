function queenbee(filepath, varargin)
%QUEENBEE Wrapper function for bee tag processing pipeline
%   Main wrapper function for the bee tag processing pipeline. Given the
%   the path to a video file, this function will perform the following
%   sequential steps: video preprocessing, tag detection, tag ocr, track
%   assignment, and open a tag editor. Each step is performed by a separate
%   function that can be called independent of this pipeline.
%
%   SYNTAX
%   queenbee(filename)
%   queenbee(filename, stime)
%   queenbee(filename, stime, etime)
%   queenbee(_, Name, Value)
%   
%   DESCRIPTION
%   queenbee(filename) reads the video file specified by filename, and
%   enters the data into the bee tag processing pipeline.
%
%   queenbee(filename, stime) additionally specifies a start time for the
%   video file in seconds. Only the video data after stime will be entered
%   into the bee tag processing pipeline.
%
%   queenbee(filename, stime, etime) additionally specifies an end time for 
%   the video file in seconds. etime is relative to the end of the video
%   file. Only video data between stime and etime will be entered into the
%   bee tag processing pipeline.
%
%   queenbee(_, Name, Value) specifies format-specific options using one or 
%   more name-value pair arguments, in addition to any of the input 
%   arguments in the previous syntaxes.
%
%   NAME-VALUE PAIR ARGUMENTS
%   'Output' - output directory path
%   filename (default) | string
%   Directory where pipeline data will be written. A preprocessed video,
%   background image, and tag directory will be storied in the specified
%   output directory. The tag directory will contain the individual tag
%   images and the annotation.mat file. By default, the output directory
%   path is set to the directory containing video specified by filename.
%   Data Types: char
%
%   'Force' - run all pipeline steps
%   false (default) | true
%   Require wrapper function to perform all bee tag processing steps
%   regardless of existing data. By default, this function skips any step
%   if there is evidence that the step has been run previously. When set
%   to true, any existing data will be overwritten as the pipeline is
%   performed.
%   Data Types: boolean
%
%   'Editor' - open GUI tag annotation editor
%   true (default) | false
%   Opens the tag annotation editor GUI after the bee tag processing
%   pipeline has completed. Set this value to false when running this
%   function in headless mode.
%   Data Types: boolean
%
%   DEPENDENCIES
%   vidpreproc.m, tagextract.m, extractregion.m, tagocr.m, tagpreproc.m,
%   multipad.m, tagtracker.m, tageditor.m, tagvidgen.m, classifer.mat,
%   ./tessdata
%
%   AUTHOR
%   Blair J. Rossetti
%
%   DATE LAST MODIFIED
%   2016-05-10

%% Parse Input
% set defaults
p = inputParser;
defaultStime = 0;
defaultEtime = 0;
defaultForce = false;
defaultEditor = true;

% set input types
addRequired(p,'filepath', @(x) exist(char(x), 'file') == 2);
addOptional(p,'stime', defaultStime, @isnumeric);
addOptional(p,'etime', defaultEtime, @isnumeric);
addParameter(p,'Output', [], @(x) exist(char(x), 'file') == 7);
addParameter(p,'Force', defaultForce, @islogical);
addParameter(p,'Editor', defaultEditor, @islogical);

% parse and assign variables
parse(p, filepath, varargin{:});
filepath = p.Results.filepath;
stime = p.Results.stime;
etime = p.Results.etime;
outpath = p.Results.Output;
force = p.Results.Force;
editor = p.Results.Editor;

% check/assign output path
if isempty(p.Results.Output)
    [outpath, name, ~] = fileparts(filepath);
else
    [~ ,name, ~] = fileparts(filepath);
end


%% Prep Video
% get video handle
vid = VideoReader(filepath, 'CurrentTime', stime);

% set end time
etime = vid.Duration - etime;

% check times
if stime > etime
    error('start time must be before end time')
end

%% Preprocess Video
ppvidpath = fullfile(outpath, [name '_preprocessed.mj2']);
backgroundpath = fullfile(outpath, [name '_background.png']);
if exist(ppvidpath, 'file') && exist(backgroundpath, 'file') && ~force
    disp('Preprocessed video and background image exist');
    disp('- getting video handle...');
    ppvid = VideoReader(ppvidpath);
    
    disp('- getting background image...');
    background = imread(backgroundpath);
elseif exist(backgroundpath, 'file') && ~force
    disp('No preprocessed video, but background image exist');
    disp('- getting background image...');
    background = imread(backgroundpath);
    
    disp('- checking if dimensions match...');
    if size(background, 1) == vid.Height
        disp('- using raw video...');
        ppvid = vid;
    else
        disp('- preprocessing video and regenerating background image...');
        [ppvid, background] = vidpreproc(vid, etime, outpath);
    end
else    
    disp('Preprocessing video and generating background image...');
    [ppvid, background] = vidpreproc(vid, etime, outpath);
end

%% Detect Tags
tapath = fullfile(outpath,'tags', 'tag_annotations.mat');
if exist(tapath, 'file') && ~force
    disp('Tag images exist');
    disp('- getting annotation file...');
    load(tapath);
else
    disp('Detecting tags...');
    annotations = tagextract(ppvid, background, outpath);
end

%% Read Tags
if isfield(annotations, 'digits') && ~force
    disp('OCR data exists');
    disp('- skipping process...');
else
    disp('Reading tags...');
    annotations = tagocr(annotations, outpath);
end

%% Define Track
if isfield(annotations, 'trackid') && ~force
    disp('Tracks exist');
    disp('- skipping process')
else
    disp('Defining tracks...');
    annotations = tagtracker(annotations, outpath);
end

%% Tag Editor
if editor
    disp('Starting tag editor...');
    tageditor(annotations, ppvid, outpath);
else
    disp('Done');
end

end %function
