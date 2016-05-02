%% Read in Images
files{1} = getpaths('~/Desktop/bee/svm/good/', '.tif');
files{2} = getpaths('~/Desktop/bee/svm/blurred/', '.tif');
files{3} = getpaths('~/Desktop/bee/svm/bad/', '.tif');

numFiles = cellfun(@length,files);

%% Divide Images into Training and Testing Set
trIdx = logical([]);
labels = single([]);
for i = 1:3
    idx = randi([1 numFiles(i)], [numFiles(i), 1]) < numFiles(i)/2;
    trIdx = [trIdx; idx];                       %#ok<AGROW>
    labels = [labels; ones(numFiles(i),1)*i];   %#ok<AGROW>
end

%% Combine File Paths
files = [files{1}; files{2}; files{3}];

%% Train SVM
cellSize = [4 4];
hogFeatureSize = 3024;
trFiles = files(trIdx);
trLabels = labels(trIdx);
trFeatures  = zeros(sum(trIdx), hogFeatureSize, 'single');

for i = 1:sum(trIdx)
    img = rgb2gray(imread(trFiles{i}));
    img = imresize(img, [30 60]);
    trFeatures(i, :) = extractHOGFeatures(img, 'CellSize', cellSize);
end

% fitcecoc uses SVM learners and a 'One-vs-One' encoding scheme.
classifier = fitcecoc(trFeatures, trLabels);

%% Test Model
tsFiles = files(~trIdx);
tsLabels = labels(~trIdx);
tsFeatures  = zeros(sum(~trIdx), hogFeatureSize, 'single');

for i = 1:sum(~trIdx)
    img = rgb2gray(imread(tsFiles{i}));
    img = imresize(img, [30 60]);
    tsFeatures(i, :) = extractHOGFeatures(img, 'CellSize', cellSize);
end

% Make class predictions using the test features.
predictedLabels = predict(classifier, tsFeatures);

% Tabulate the results using a confusion matrix.
confMat = confusionmat(tsLabels, predictedLabels);