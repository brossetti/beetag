function [ ppvid, background ] = vidpreproc(vid, etime, outpath)
%VIDPREPROC Summary of this function goes here
%   Extract the active region from a given video file and write a
%   preprocessed video file for furthe r analysis

%% Check MATLAB Version
legacy = verLessThan('matlab', '9.0');

%% Video Info
stime = vid.CurrentTime;
[~,name, ~] = fileparts(vid.Name);

%% Calcualte Active Region

% calculate mean and background
numFrames = 1;
meanImg = double(readFrame(vid));

while hasFrame(vid) && vid.CurrentTime <= etime
    meanImg = meanImg + double(readFrame(vid));
    numFrames = numFrames + 1;
end
meanImg = meanImg./numFrames;

% reset CurrentTime
vid.CurrentTime = stime;

% calculate variance
varImg = (double(readFrame(vid)) - meanImg).^2;

while hasFrame(vid) && vid.CurrentTime <= etime
    varImg = varImg + (double(readFrame(vid)) - meanImg).^2;
end
varImg = varImg./(numFrames-1);

% reset CurrentTime
vid.CurrentTime = stime;

% convert to grayscale
varImg = rgb2gray(mat2gray(varImg));

% threshold
if legacy
    mask = im2bw(varImg, graythresh(varImg));
else
    mask = imbinarize(varImg);
end

% clean mask
mask = imdilate(mask,strel('square',3));
mask = imfill(mask, 'holes');

% get bbox of largest object
stats = regionprops(mask,'Area', 'BoundingBox');
[~,idx] = max([stats.Area]);
bbox = round(stats(idx).BoundingBox);

%% Extract Active Region
if bbox(4)/size(varImg,1) < 0.05 || bbox(4)/size(varImg,1) > 0.99
    % create preprocessed video
    ppvidpath = fullfile(outpath,[name '_preprocessed.mj2']);
    ppvid = VideoWriter(ppvidpath,'Archival');
    open(ppvid)
    while hasFrame(vid) && vid.CurrentTime <= etime
        frame = readFrame(vid);
        writeVideo(ppvid, frame(bbox(2):bbox(4),:,:))
    end
    close(ppvid)

    % reset CurrentTime
    vid.CurrentTime = stime;

    % define background image
    background = uint8(meanImg(bbox(2):bbox(4),:,:));
    imwrite(background, fullfile(outpath,[name '_background.png']));
   
    % get preprocessed video handle
    ppvid = VideoReader(ppvidpath);
else
    % define background image
    background = uint8(meanImg);
    imwrite(background, fullfile(outpath,[name '_background.png']));
    
    % use raw video
    ppvid = vid;
end    

