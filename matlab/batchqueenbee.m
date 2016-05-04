function batchqueenbee(d, ext)
% This function runs queenbee for all avi files in a given directory or 
% subdirectory

% get all avi files
files = dirwalk(d);
files = files(~cellfun(@isempty,regexp(files,[ext '$'])));

% loop through files
parfor i = 1:length(files)
   try
       % create a directory for results
       [path, name, ~] = fileparts(files{i});
       rdir = fullfile(path, [name '_results']);
       mkdir(rdir);
       
       % run queenbee
       queenbee(files{i}, 10, 10, 'Output', rdir, 'Editor', false);
   catch
       fprintf('%s failed\n', name);
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