%% Get Input Paths
rootdir = '/Users/blair/Desktop/tags9622/';
files = dir([rootdir '*.tif']);
dirIdx = [files.isdir];
files = {files(~dirIdx).name}';
numImg = length(files);

%built full file path
for i = 1:numImg
    files{i} = fullfile(rootdir,files{i});
end

mkdir(rootdir, 'good');
mkdir(rootdir, 'bad');

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