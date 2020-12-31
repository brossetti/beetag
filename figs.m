%% open raw video

vid = VideoReader('~/Desktop/bee/MVI_0228.AVI', 'CurrentTime', 25);
etime = vid.Duration - 60*48;

% get video info
stime = vid.CurrentTime;
[~,name, ~] = fileparts(vid.Name);

%% background

ovid = VideoWriter('~/Desktop/background.mp4', 'MPEG-4');
open(ovid)

% calculate mean for background
numFrames = 1;
meanImg = double(readFrame(vid));
[y,x,c]=size(meanImg);
while hasFrame(vid) && vid.CurrentTime <= etime
    frame = double(readFrame(vid));
    meanImg = meanImg + frame;
    numFrames = numFrames + 1;
    
    if mod(numFrames,20) == 0
        tmpmean = meanImg./numFrames;
        tmpmean = insertText(uint8(tmpmean), [0,0], 'Mean', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
        frame = insertText(uint8(frame), [0,0], 'Raw', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
        tmp = imresize(vertcat(frame, tmpmean), 0.5);
        writeVideo(ovid, tmp)
    end
end
meanImg = meanImg./numFrames;
close(ovid)
% reset CurrentTime
vid.CurrentTime = stime;

%% variance

ovid = VideoWriter('~/Desktop/activeregion.mp4', 'MPEG-4');
open(ovid)

% calculate variance for active region
varImg = (double(readFrame(vid)) - meanImg).^2;
numFrames = 1;
while hasFrame(vid) && vid.CurrentTime <= etime
    frame = double(readFrame(vid));
    varImg = varImg + (frame - meanImg).^2;
    numFrames = numFrames + 1;
    
    if mod(numFrames,20) == 0
        tmpvar = varImg./(numFrames-1);
        tmpvar = insertText(uint8(mat2gray(tmpvar)*255), [0,0], 'Variance', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
        frame = insertText(uint8(frame), [0,0], 'Raw', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
        tmp = imresize(vertcat(frame, tmpvar), 0.5);
        writeVideo(ovid, tmp)
    end
    
end
varImg = varImg./(numFrames-1);
close(ovid)
% reset CurrentTime
vid.CurrentTime = stime;


%% active region

orgVarImg = insertText(mat2gray(varImg), [0,y], 'Variance', 'AnchorPoint', 'LeftBottom', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
imwrite(imresize(orgVarImg,0.5), '~/Desktop/variance.jpg');

% convert to grayscale
orgVarImg = varImg;
varImg = rgb2gray(mat2gray(varImg));

% threshold
mask = imbinarize(varImg);
tmpmask = insertText(uint8(mask*255), [0,y], 'Thresholded', 'AnchorPoint', 'LeftBottom', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
imwrite(imresize(tmpmask, 0.5), '~/Desktop/variancemask.jpg');

% clean mask
mask = imdilate(mask,strel('square',3));
mask = imfill(mask, 'holes');

% get bbox of largest object
stats = regionprops(mask,'Area', 'BoundingBox');
[~,idx] = max([stats.Area]);
bbox = round(stats(idx).BoundingBox);

tmpmask = insertText(uint8(mask*255), [0,y], 'Cleaned', 'AnchorPoint', 'LeftBottom', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
tmpmask = insertShape(tmpmask,'rectangle', bbox, 'Color', 'green', 'LineWidth', 4);
imwrite(imresize(tmpmask, 0.5), '~/Desktop/cleanvariancemask.jpg');

%% tag extract

vid = VideoReader('~/Desktop/bee/MVI_0228_preprocessed.mj2', 'CurrentTime', 24.5);

background = rgb2gray(imread('~/Desktop/bee/MVI_0228_background.png'));

% read frame and remove background
frame = readFrame(vid);
tmp = insertText(frame, [0,0], 'Raw', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
imwrite(imresize(tmp, 0.75), '~/Desktop/raw.jpg');
gframe = imadjust(frame(:,:,3));
gframebg = gframe - background;
tmp = insertText(gframebg, [0,0], 'Background Subtracted', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
imwrite(imresize(tmp, 0.75), '~/Desktop/bgndsub.jpg');
    


%% find MSER

% detect MSER regions
[mserRegions, mserConnComp] = detectMSERFeatures(gframebg,...
    'RegionAreaRange',[300 3000],'ThresholdDelta',4);

tmp = insertText(gframebg, [0,0], 'MSER', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
r = tmp(:,:,1);
g = tmp(:,:,2);
b = tmp(:,:,3);

b(mserConnComp.PixelIdxList{1}) = 255;
% r(mserConnComp.PixelIdxList{1}) = 0;
% g(mserConnComp.PixelIdxList{1}) = 0;

g(mserConnComp.PixelIdxList{2}) = 255;
% r(mserConnComp.PixelIdxList{2}) = 0;
% b(mserConnComp.PixelIdxList{2}) = 0;

tmp = cat(3,r,g,b);

imwrite(imresize(tmp, 0.75), '~/Desktop/mser.jpg');


%%
    
% measure MSER properties
mserStats = regionprops(mserConnComp, 'BoundingBox', 'Solidity',...
    'Eccentricity', 'ConvexHull', 'MajorAxisLength',...
    'MinorAxisLength', 'ConvexArea', 'Centroid', 'Area');

% filter regions with big holes
solidityIdx = [mserStats.Solidity] > 0.85;

% filter regions with incorrect aspect ratio
aspect = [mserStats.MinorAxisLength]./[mserStats.MajorAxisLength];
aspectIdx = aspect > 0.3 & aspect < 0.65;

% filter regions that are too round
eccentricityIdx = [mserStats.Eccentricity] < 0.95;

% process filters
filterIdx = solidityIdx & aspectIdx & eccentricityIdx;
mserRegions = mserRegions(filterIdx);
mserStats = mserStats(filterIdx);

% remove overlapping regions
[~,~,bbIdx] = selectStrongestBbox(cell2mat({mserStats.BoundingBox}'), ...
    (1./[mserStats.ConvexArea])', 'OverlapThreshold', 0.3);
mserRegions = mserRegions(bbIdx);
mserStats = mserStats(bbIdx);

tmp = insertText(gframebg, [0,0], 'MSER Filtered', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
r = tmp(:,:,1);
g = tmp(:,:,2);
b = tmp(:,:,3);

g(mserConnComp.PixelIdxList{1}) = 255;

tmp = cat(3,r,g,b);

imwrite(imresize(tmp, 0.75), '~/Desktop/mserfiltered.jpg');

%% mbr
        
% calculate minimum area bounding rectangle

% get convex hull points
pts = mserStats(1).ConvexHull;

% determine unit edge direction
vects = diff(pts);
norms = sqrt(sum(vects.^2,2));
uvects = diag(1./norms)*vects;
nvects = fliplr(uvects);
nvects(:,1) = nvects(:,1)*-1;

% find MBR
minmax = @(x) [min(x,[],1); max(x,[],1)];
x = minmax(pts*uvects');
y = minmax(pts*nvects');

areas = (y(1,:)-y(2,:)).*(x(1,:)-x(2,:));
[~,idx] = min(areas);

% define the rectangle
xys = [x([1,2,2,1,1],idx), y([1,1,2,2,1],idx)];
rect = xys*[uvects(idx,:); nvects(idx,:)];

tmp = insertText(gframebg, [0,0], 'MBR', 'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 32);
pts = rect(1:4,:)';
tmp = insertShape(tmp,'polygon', pts(:)', 'Color', 'green', 'LineWidth', 4);
imwrite(imresize(tmp, 0.75), '~/Desktop/mbr.jpg');

%% extract region
% extract region
tag = extractregion(frame,rect(1:end-1,:));
imwrite(imresize(tag, 10, 'nearest'), '~/Desktop/tag.jpg');

%% tagpreproc

% preprocess tag image
% read image
% img = imread('~/Desktop/bee/_TrainingVideos/tags/MVI_9621_preprocessed_tag000020.tif');
[h,w,c] = size(tag);

% preprocess
% [img, cropbbox] = tagpreproc(img);
[img, cropbbox] = tagpreproc(tag);

imwrite(imresize(img, 10, 'nearest'), '~/Desktop/tagpreproc.jpg');

%% ocr

% set OCR language
lang = 'tessdata/dgt.traineddata';

% process tag and rotated tag   
results = struct.empty(2,0);

for j = 1:2
    % ocr
    results(j).ocr = ocr(img, 'Language', lang, 'TextLayout', 'Block');

    % keep at most 3 digits by confidence level
    conf = results(j).ocr.CharacterConfidences;
    conf(isnan(conf)) = 0;      % convert NaN to 0 for correct sorting

    if length(conf) > 2            
        % sort digits by confidence level
        [~,idx] = sort(conf, 'descend');
        idx = sort(idx(1:3), 'ascend');
        results(j).DigitConfidences = conf(idx);

        % compute average confidence
        results(j).AverageConfidence = mean(conf(idx));

        % get and clean digits with highest confidence
        text = results(j).ocr.Text(idx);
        text = strtrim(text);
        text(text == ' ') = ''; 

        % get bounding boxes
        results(j).BBoxes = results(j).ocr.CharacterBoundingBoxes(idx,:);
    else
        % add digit confidence
        results(j).DigitConfidences = padarray(conf, 3-length(conf),'post');

        % compute average confidence
        results(j).AverageConfidence = mean(results(j).DigitConfidences);

        % clean digits
        text = strtrim(results(j).ocr.Text);
        text(text == ' ') = '';

        % get bounding boxes
        results(j).BBoxes = results(j).ocr.CharacterBoundingBoxes;
    end %if-else

    % add extracted digits
    results(j).Digits = text; 

    % flip image
    img = rot90(img,2);
end %for

% determine best orientation
if results(1).AverageConfidence >= results(2).AverageConfidence
    orIdx = 1;
else
    orIdx = 2;

    % flip crop bbox
    cropbbox = [[w h] - (cropbbox(1:2)+cropbbox(3:4)), cropbbox(3:4)];

    % flip image back
    img = rot90(img,2);
end %if-else

tmp = insertShape(img,'rectangle', results(2).BBoxes, 'Color', 'green');
imwrite(imresize(tmp,10, 'nearest'), '~/Desktop/tagocr2.jpg');

tmp = insertShape(rot90(img,2),'rectangle', results(1).BBoxes, 'Color', 'green');
imwrite(imresize(tmp,10, 'nearest'), '~/Desktop/tagocr1.jpg');

%% wavelet denoise

rbr = 5;    %rolling ball radius
cp = 2;     %crop padding
img = tag;
[h, w, c] = size(img);

% Wavelet Denoise
for i = 1:c
    tmp = img(:,:,i);
    wname = 'fk4';
    level = 5;
    
    % pad image
    [tmp , pads] = multipad(tmp, 2^level, 0);
    
    % denoising parameters
    sorh = 'h';    % Specified soft or hard thresholding
    thrSettings =  repmat(14.5, [3 5]);

    % decompose using SWT2
    wDEC = swt2(double(tmp),level,wname);

    % denoise
    permDir = [1 3 2];
    for j = 1:level
        for kk = 1:3
            idx = (permDir(kk)-1)*level+j;
            thr = thrSettings(kk, j);
            wDEC(:,:,idx) = wthresh(wDEC(:,:,idx), sorh, thr);
        end
    end

    % reconstruct the denoise signal using ISWT2
    tmp = iswt2(wDEC,wname);
    
    % remove pad
    tmp = tmp(pads(1)+1:end-pads(2),pads(3)+1:end-pads(4));
    img(:,:,i) = tmp;
end

imwrite(imresize(img, 10, 'nearest'), '~/Desktop/waveletdenoised.jpg');

%% Background Subtraction
for i = 1:c
    tmp = 255-img(:,:,i);

    % pad image
    wpad = 2*rbr;
    tmp = padarray(tmp, [wpad wpad], 255);
    
    % define background
    background = imopen(tmp,offsetstrel('ball',rbr,rbr));
    
    % remove background
    tmp = tmp-background;
    
    % remove pad
    tmp = tmp(wpad+1:end-wpad,wpad+1:end-wpad);
    
    % adjust intensities
    img(:,:,i) = imadjust(tmp);
end

imwrite(imresize(img, 10, 'nearest'), '~/Desktop/rollingball.jpg');

%% Sharpen
img = imsharpen(img, 'Threshold', 0.7);

% Convert to Grayscale
if c > 1
    img = rgb2gray(img);
end
imwrite(imresize(img, 10, 'nearest'), '~/Desktop/sharpgray.jpg');

%% Define Digit Regions
mask = mat2gray(sum(img,2)*sum(img,1));
imwrite(imresize(mask, 10, 'nearest'), '~/Desktop/digitmask.jpg');
mask1 = mask;

mask = imbinarize(mask);
mask = bwmorph(mask, 'hbreak', Inf);
mask = bwmorph(mask, 'spur', Inf);

imwrite(imresize(double(mask)*255, 10, 'nearest'), '~/Desktop/digitmaskthresh.jpg');
% Filter Regions
cc = bwconncomp(mask);
stats = regionprops(cc, 'Area', 'PixelList');

% filter small regions
areaIdx = [stats.Area] > 20;

% get list of pixels
pxList = cat(1, stats(areaIdx).PixelList);

% get crop coordinates
minmax = @(x) [min(x) max(x)];
ccorr = minmax(pxList);

% Crop to Coordinates
ccorr(1:2) = ccorr(1:2) - cp;
ccorr(3:4) = ccorr(3:4) + cp;
ccorr(ccorr < 1 ) = 1;
if ccorr(3) > w
    ccorr(3) = w;
end
if ccorr(4) > h
    ccorr(4) = h;
end

tmp = insertShape(mask1, 'rectangle', [ccorr(1), ccorr(2), ccorr(3)-ccorr(1), ccorr(4)-ccorr(2)], 'Color', 'green');
imwrite(imresize(tmp, 10, 'nearest'), '~/Desktop/digitcropbox.jpg');


img2 = img(ccorr(2):ccorr(4),ccorr(1):ccorr(3));

imwrite(imresize(img2, 10, 'nearest'), '~/Desktop/croppeddigits.jpg');

%%
