function [ img ] = tagpreproc(img)
%TAGPREPROC Bee tag preprocessing
%   Cleans bee tag images for use in OCR
close all
plt = false;

% display for testing
if plt
    figure
    row=1;
    col=2;
    subplot(row,col,1)
    imshow(imresize(img, 10, 'nearest'))
end

%% Parameters
rbr = 5;    %rolling ball radius

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

if plt
    subplot(row,col,2)
    imshow(imresize(img, 10, 'nearest'))
    pause(1)
end
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

%% Binarize
% mask = imbinarize(img);

% mask = zeros(size(img));
% mask(2:h-5,2:w-5) = 1;
% img = activecontour(img,logical(mask)); 

%% Filter Regions
% cc = bwconncomp(img);
% stats = regionprops(cc, 'BoundingBox', 'Orientation',...
%     'Eccentricity', 'ConvexHull', 'ConvexArea', 'Image');
% 
% % filter regions with big holes
% % solidityIdx = [stats.Solidity] > 0.85;
% 
% % filter regions with incorrect aspect ratio
% bbox = vertcat(stats.BoundingBox);
% w = bbox(:,3);
% h = bbox(:,4);
% aspect = w./h;
% aspectIdx = aspect > 0.3 & aspect < 0.75;
% 
% % filter regions that are too round
% % eccentricityIdx = [stats.Eccentricity] < 0.95;
% 
% % process filters
% filterIdx = find(aspectIdx);
% img = ismember(labelmatrix(cc), filterIdx);

% display
if plt
    subplot(row,col,2)
    imshow(imresize(img, 10, 'nearest'))
    pause(2)
end
end


