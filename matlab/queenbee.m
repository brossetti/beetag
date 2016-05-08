function queenbee(filepath, varargin)
%QUEENBEE Wrapper function for bee tag pipeline
%   Main wrapper function for the bee tag processing pipeline.

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

% parse and assign variabls
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

%% Filter/Process Results
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


end

