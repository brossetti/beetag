function queenbee(filepath, stime, etime)
%QUEENBEE Wrapper for bee tag functions
%   Detailed explanation goes here

%% Parse Input
[path,name,~] = fileparts(filepath);
force = false;
training = false;

%% Prep Video

% get video handle
vid = VideoReader(filepath, 'CurrentTime', stime);

% set end time
etime = vid.Duration - etime;

%% Preprocess Video
ppvidpath = fullfile(path,[name '_preprocessed.avi']);
backgroundpath = fullfile(path,[name '_background.png']);
if exist(ppvidpath, 'file') && exist(backgroundpath, 'file') && ~force
    disp('Preprocessed video and background image exist');
    disp('Getting video handle...');
    ppvid = VideoReader(ppvidpath);
    
    disp('Getting background image...');
    background = imread(backgroundpath);
else
    disp('Preprocessing video and generating background image...');
    [ppvid, background] = vidpreproc(vid, etime, path);
end

%% Detect Tags
tapath = fullfile(path,'tags', 'tag_annotations.mat');
if exist(tapath, 'file') && ~force
    disp('Tag images exist');
    disp('Getting annotation file...');
    load(tapath);
else
    disp('Detecting tags...');
    annotations = tagextract(ppvid, background, path);
end

%% Read Tags
if isfield(annotations, 'digits') && ~force
    disp('OCR data exists')
else
    disp('Reading tags...');
    annotations = tagocr(annotations, path);
end

%% Filter/Process Results
if isfield(annotations, 'trackid') && ~force
    disp('Track ID exists')
else
    disp('Filtering results...');
    annotations = tagfilter(annotations, path);
end

%% Tag Editor
disp('Starting tag editor...');
tageditor(annotations, ppvid, path);


end

