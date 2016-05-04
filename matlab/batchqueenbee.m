function batchqueenbee(d)
% This function runs queenbee for all avi files in a given directory or 
% subdirectory

% get all avi files
files = getAllFiles(d);

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
       disp('failed');
   end
end
end

function fileList = getAllFiles(dirName)

  dirData = dir(dirName);      %# Get the data for the current directory
  dirIndex = [dirData.isdir];  %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
  if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
                       fileList,'UniformOutput',false);
  end
  subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = [fileList; getAllFiles(nextDir)];  %# Recursively call getAllFiles
  end

end