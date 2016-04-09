%% Get Input Paths
rootdir = '/Users/blair/Desktop/test/';
ext = '.tif';
files = dir([rootdir '*' ext]);
dirIdx = [files.isdir];
files = {files(~dirIdx).name}';
numImg = length(files);

%built full file path
for i = 1:numImg
    files{i} = fullfile(rootdir,files{i});
end

mkdir(rootdir, 'good');
mkdir(rootdir, 'bad');

%sort
for i = 1:numImg
    %read image
    img = imread(files{i});
    [~, name, ~] = fileparts(files{i});
    
    %prompt
    disp([name ':'])
    imshow(imresize(img,10))
    w = waitforbuttonpress;
    
    if w
        p = get(gcf, 'CurrentCharacter');
        
        switch int8(p)
            case 27
                disp('exiting...')
                close all
                break
            case 28
                movefile(files{i}, fullfile(rootdir,'bad'));
                disp('bad')
            case 29
                movefile(files{i}, fullfile(rootdir,'good'));
                disp('good')
            case 30
                img = rot90(img, 2);
                imshow(imresize(img,10))
                pause(0.5);
                imwrite(img, fullfile(rootdir,'good', [name '.tif']));
                delete(files{i});
                disp('good')
            
        end

    end

end

%get list of good images
files = dir(fullfile(rootdir,'good',['*' ext]));
dirIdx = [files.isdir];
files = {files(~dirIdx).name}';
renamedIdx = cell2mat(cellfun(@(x) all(isstrprop(x(1:3),'digit')), files, 'UniformOutput', false));
files = files(~renamedIdx);
numImg = length(files);

%built full file path
for i = 1:numImg
    files{i} = fullfile(rootdir, 'good', files{i});
end

%rename
for i = 1:numImg
    %read image
    img = imread(files{i});
    [path, name, ext] = fileparts(files{i});
    
    %prompt
    imshow(imresize(img,10))
    commandwindow
    dgts = input([name ':']);
    
    while dgts ~= 0 && numel(num2str(dgts)) ~= 3
        commandwindow
        dgts = input([name ':']);
    end
    
    if dgts == 0
        disp('exiting...')
        close all
        break
    else 
        movefile(files{i},fullfile(path, [num2str(dgts) '_' name ext]))
    end

end
