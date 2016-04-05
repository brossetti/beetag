close all

%% Set Parameters
training = true;
% rootdir = '/Users/blair/Desktop/bee/AnnotatedTags/tags9621/good/';
rootdir = '/Users/blair/Desktop/bee/_TrainingVideos/MVI_9621_tags/bad/';
ext = '.tif';

%% Get Input Paths
files = dir(fullfile(rootdir, ['*' ext]));
dirIdx = [files.isdir];
files = {files(~dirIdx).name}';
numImg = length(files);

%build full file path
for i = 1:numImg
    files{i} = fullfile(rootdir,files{i});
end

%% Process Images
passed = 0;
blurvals = zeros(1,numImg);
for i = 1:numImg
    %read image
    img = imread(files{i});
    [~, name, ~] = fileparts(files{i});
    
    %convert to grayscale
    tmp = img(:,:,3);
    
    %convolve with Laplacian
    convimg = conv2(double(tmp), [0, 1, 0; 1, -4, 1; 0, 1, 0]);
    
    %calculate variance
    blurvals(i) = 1/std(convimg(convimg ~= 0));
    
%     imshow(imresize(tmp, 10, 'nearest'))
%     title(num2str(blurval));
%     pause(2);
end
fprintf('Mean: %f | SD: %f\n', mean(blurvals), std(blurvals));