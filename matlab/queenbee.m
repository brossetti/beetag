function queenbee(filepath, stime, etime)
%QUEENBEE Wrapper for bee tag functions
%   Detailed explanation goes here

%% Parse Input
[path,name,~] = fileparts(filepath);
force = false;

%% Prep Video

% get video handle
vid = VideoReader(filepath, 'CurrentTime', stime);

% set end time
etime = vid.Duration - etime;

%% Preprocess Video
ppvidpath = fullfile(path,[name '_preprocessed.avi']);
backgroundpath = fullfile(path,[name '_background.png']);
if exist(ppvidpath,'file') && exist(backgroundpath,'file') && ~force
    disp('Preprocessing video and background image exist')
    disp('Getting video handle...')
    ppvid = VideoReader(ppvidpath);
    
    disp('Getting background image...')
    background = imread(backgroundpath);
else
    disp('Preprocessing video...');
    [ppvid, background] = vidpreproc(vid, etime, path);
end

%% Detect Tags
tagfiles = tagextract(ppvid, background, path);

end

