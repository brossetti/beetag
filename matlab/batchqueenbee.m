function batchqueenbee(d, ext)
% This function runs queenbee for all avi files in a given directory or 
% subdirectory

% get all avi files
disp('getting file list...');
files = dirwalk(d);
files = files(~cellfun(@isempty,regexp(files,[ext '$'])));
disp('starting video processing...');

% loop through files
parfor i = 1:length(files)
   % print current file
   fprintf('Processing %s\n', files{i});
   try
       % create a directory for results
       [path, name, ~] = fileparts(files{i});
       rdir = fullfile(path, [name '_results']);
       mkdir(rdir);
       
       % run queenbee
       queenbee(files{i}, 30, 30, 'Output', rdir, 'Editor', false, 'Force', true, 'Quiet', true);
   catch
       fprintf('%s failed\n', files{i});
       err = lasterror;
       disp(err);
       disp(err.message);
       disp(err.stack);
       disp(err.identifier);
   end
end
end

function files = dirwalk(root)

% get contents of current directory
dirData = dir(root);

% find any subdirectories
dirIndex = [dirData.isdir];

% get list of files
files = {dirData(~dirIndex).name}';

% build full file paths
if ~isempty(files)
files = cellfun(@(x) fullfile(root,x),...  
                   files,'UniformOutput',false);
end

% get list of subdirectories
subDirs = {dirData(dirIndex).name}; 
validIndex = ~ismember(subDirs,{'.','..'});

% recursively call function to walk subdirectories
for i = find(validIndex)
    dirpath = fullfile(root, subDirs{i});
    files = [files; dirwalk(dirpath)];
end

end