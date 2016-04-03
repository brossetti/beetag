%% Set Parameters
training = true;
% rootdir = '/Users/blair/Desktop/bee/AnnotatedTags/tags9621/good/';
rootdir = '/Users/blair/Desktop/bee/tags/';
ext = '.tif';
lang = '/Users/blair/dev/beetag/matlab/training/dgt/dgt/tessdata/dgt.traineddata';

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

for i = 1:numImg
    %read image
    img = imread(files{i});
    [~, name, ~] = fileparts(files{i});
    
    %get ground truth digits if in training mode
    if training
        digits = name(1:3);
    end
    
    %preprocess
    img = tagpreproc(img);
%     imwrite(img, fullfile('/Users/blair/Desktop/bee/tags/TrainingFramesSelected_grayclean/',[name '.tif']));
    
    %process tag and rotated tag
    results = cell(1,2);
    
    for j = 1:2
        %ocr
%         results{j}.ocr = ocr(img, 'CharacterSet', '0123456789', 'TextLayout', 'Block');
        results{j}.ocr = ocr(img, 'Language', lang, 'TextLayout', 'Block');

        %keep at most 3 digits by confidence level
        conf = results{j}.ocr.CharacterConfidences;
        conf(isnan(conf)) = 0;      %convert NaN to 0 for correct sorting
        
        if length(conf) > 2            
            %sort digits by confidence level
            [~,idx] = sort(conf, 'descend');
            idx = sort(idx(1:3), 'ascend');
            results{j}.DigitConfidences = conf(idx);
            
            %compute average confidence
            results{j}.AverageConfidence = mean(conf(idx));
            
            %get and clean digits with highest confidence
            text = results{j}.ocr.Text(idx);
            text = strtrim(text);
            text(text == ' ') = ''; 
        else
            %add digit confidence
            results{j}.DigitConfidences = padarray(conf, 3-length(conf),'post');

            %compute average confidence
            results{j}.AverageConfidence = mean(results{j}.DigitConfidences);
            
            %clean digits
            text = strtrim(results{j}.ocr.Text);
            text(text == ' ') = ''; 
        end
        
        %add extracted digits
        results{j}.Digits = text; 
        
        %flip image
        img = rot90(img,2);
    end

    %determine best orientation
    if results{1}.AverageConfidence >= results{2}.AverageConfidence
        orIdx = 1;
        
        %flip image back
        img = rot90(img,2);
    else
        orIdx = 2;
    end
    text = results{orIdx}.Digits;
 
    %print results
    if training
        fprintf('Actual: %3s | OCR: %3s | Conf: (%f, %f, %f)\n', digits, text, results{orIdx}.DigitConfidences)
        if strcmp(digits,text)
            passed = passed + 1;
        end
    else
        fprintf('File %s: %s\n', name, text)
    end
end

if training
    fprintf('Accuracy = %.3f\n', passed/numImg*100);
end