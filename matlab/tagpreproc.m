function [ img ] = tagpreproc(img)
%TAGPREPROC Bee tag preprocessing
%   Cleans bee tag images for use in OCR
plt = false;

% display for testing
if plt
    close all
    figure
    row=1;
    col=2;
    subplot(row,col,1)
    imshow(imresize(img, 10, 'nearest'))
end

%% Parameters
rbr = 5;    %rolling ball radius
cp = 2;     %crop padding

%% Check Image Type
[h, w, c] = size(img);

%% Wavelet Denoise
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

%% Sharpen
img = imsharpen(img, 'Threshold', 0.7);

%% Convert to Grayscale
if c > 1
    img = rgb2gray(img);
end

%% Define Digit Regions
mask = mat2gray(sum(img,2)*sum(img,1));
mask = imbinarize(mask);
mask = bwmorph(mask, 'hbreak', Inf);
mask = bwmorph(mask, 'spur', Inf);

%% Filter Regions
cc = bwconncomp(mask);
stats = regionprops(cc, 'Area', 'PixelList');

% filter small regions
areaIdx = [stats.Area] > 20;

% get list of pixels
pxList = cat(1, stats(areaIdx).PixelList);

% get crop coordinates
minmax = @(x) [min(x) max(x)];
ccorr = minmax(pxList);

%% Crop to Coordinates
ccorr(1:2) = ccorr(1:2) - cp;
ccorr(3:4) = ccorr(3:4) + cp;
ccorr(ccorr < 1 ) = 1;
if ccorr(3) > w
    ccorr(3) = w;
end
if ccorr(4) > h
    ccorr(4) = h;
end
img = img(ccorr(2):ccorr(4),ccorr(1):ccorr(3));


%% Deblur

% PSF = fspecial('gaussian',7,10);
% INITPSF = ones(size(PSF));
% img = deconvblind(img,INITPSF);

%% Denoise
% img = wiener2(img, [2 2]);

% wavelet denoising
% [thr,sorh,keepapp] = ddencmp('den','wv', img);
% xd = wdencmp('gbl',img,'sym4',2,thr,sorh,keepapp);
% img = mat2gray(xd);

%% Morphological Operations
% img = imopen(img, strel('line',2,0));
% img = imopen(img, strel('disk',2));

% img = imopen(img, strel('line',2,90));

%% Create Mask
% img = imopen(img,strel('rectangle',[3 5]));
% img = imbinarize(img);
% mask = activecontour(img,logical(mask)); 


%% Apply Mask
% img = img.*uint8(mask);

%% Crop to Digits
% plotprof(img)
% plotprof(imresize(edge(img,'Sobel',[],'vertical'),10,'nearest'))
% pause(2)

% xderr = diff(sum(img,2));
% yderr = diff(sum(img,1));
% % [~, x1] = max(xderr);
% % [~, x2] = min(xderr);
% [~, x1] = findpeaks(xderr, 'MinPeakProminence', 1e2);
% [~, x2] = findpeaks(max(xderr)-xderr, 'MinPeakProminence', 1e2);
% [~, y1] = findpeaks(yderr, 'MinPeakProminence', 1e2);
% [~, y2] = findpeaks(max(yderr)-yderr, 'MinPeakProminence', 1e2);
% % img = img(x1(1):x2(end), y1(1):y2(end));


%% Separate Connected Digits
% [~, gaps] = findpeaks(sum(imcomplement(img),1), 'MinPeakProminence', 1e3);
% img(:, gaps) = 0;

% display
if plt
    subplot(row,col,2)
    imshow(imresize(img, 10, 'nearest'))
    pause(2)
end
end

function plotprof(img)
subplot(2,2,1)
imshow(imresize(img,10,'nearest'));
subplot(2,2,2)
findpeaks(diff(sum(img,2)),'MinPeakProminence', 10);
camroll(-90)
subplot(2,2,3)
findpeaks(diff(sum(img,1)),'MinPeakProminence', 10);
end

