function [ img ] = tagpreproc(img)
%TAGPREPROC Bee tag preprocessing
%   Cleans bee tag images for use in OCR
close all
plt = true;

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

%% Background Subtraction

for i = 1:c
    tmp = 255-img(:,:,i);
    tmp = histeq(tmp);

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

%% Convert to Grayscale
img = rgb2gray(img);

%% Denoise
% img = wiener2(img, [2 2]);

% wavelet denoising
% [thr,sorh,keepapp] = ddencmp('den','wv', img);
% xd = wdencmp('gbl',img,'sym4',2,thr,sorh,keepapp);
% img = mat2gray(xd);

%% Binarize
% img = imbinarize(img);

% mask = zeros(size(img));
% mask(2:h-1,2:w-1) = 1;
% img = activecontour(img,logical(mask)); 

%% Morphological Operations
% img = imopen(img, strel('square',2));

% display
if plt
    subplot(row,col,2)
    imshow(imresize(img, 10, 'nearest'))
end
end


