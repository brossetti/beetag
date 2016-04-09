function [ blurred ] = blurdetect(img, threshold)
%BLURDETECT Identifies blurred images based on a given threshold
%   For a given grayscale image and threshold value between 0 and 1, tthe
%   value true is returned if the image is blurred and false is returned
%   if the image is not blurred. An image is blurred if the 1/log(variance)
%   of the edge image is below the threshold value.

%% Check Image Properties
if size(img,3) ~= 1
    error('blurdetect: only grayscale images are valid');
end

%% Compute Blur Metric
% median filter to remove noise
img = medfilt2(img);

% convolve with Laplacian
convimg = conv2(double(img), [0, 1, 0; 1, -4, 1; 0, 1, 0]);

% calculate variance
blurval = 1/log(var((convimg(convimg ~= 0))));
    
%% Compare to Threshold
blurred = blurval < threshold;

end