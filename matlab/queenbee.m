function queenbee(filepath, stime, etime)
%QUEENBEE Wrapper for bee tag functions
%   Detailed explanation goes here

%% Parse Input
[path,~,~] = fileparts(filepath);

%% Prep Video

% get video handle
vid = VideoReader(filepath, 'CurrentTime', stime);

% set end time
etime = vid.Duration - etime;

%% Preprocess Video
disp('Preprocessing video...');
ppvid = vidpreproc(vid, etime, path);

%% Detect Tags

end

