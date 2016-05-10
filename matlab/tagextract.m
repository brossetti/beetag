function [ annotations ] = tagextract(vid, background, outpath)
%TAGEXTRACT Detects and extracts bee tags regions from a video
%   Detects and extracts bee tag regions from a video given a video handle
%   and background image. A region detector is used to identifiy potential
%   tag regions from the blue channel of background subtracted video 
%   frames. A svm classifier and region properties are used to remove
%   non-tag regions. Properly identified tags are extracted, saved to the
%   tag directory, and relevant annotations are stored in a 
%   tag_annotations.mat files and returned as an array structure.
%
%   SYNTAX
%   [ annotations ] = tagextract(vid, background, outpath)
%
%   DESCRIPTION
%   [ annotations ] = tagextract(vid, background, outpath) searches the
%   video specified by the video handle vid for bee tags. The background 
%   image specified by background is removed from each frame of vid. All
%   output files are saved in the directory specified by outpath. An array
%   structure is returned containing relevant information about any bee
%   tags.
%
%   DEPENDENCIES
%   classifier.mat
%
%   AUTHOR
%   Blair J. Rossetti
%
%   DATE LAST MODIFIED
%   2016-05-10

% set output directory
[status, ~] = mkdir(outpath, 'tags');
if ~status
    annotations = false;
    return
end

% load classifier
load('classifier.mat');

% get video information
[~, vidName, ~] = fileparts(vid.Name);

% detect MSER regions
numFrames = 1;
numTags = 1;
background = rgb2gray(background);

while hasFrame(vid)
    % get current time
    time = vid.CurrentTime;
    
    % read frame and remove background
    frame = readFrame(vid);
    gframe = imadjust(frame(:,:,3));
    gframebg = gframe - background;
    
    % detect MSER regions
    [mserRegions, mserConnComp] = detectMSERFeatures(gframebg,...
        'RegionAreaRange',[300 3000],'ThresholdDelta',4);
    
    if ~isempty(mserRegions)
        % measure MSER properties
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Solidity',...
            'Eccentricity', 'ConvexHull', 'MajorAxisLength',...
            'MinorAxisLength', 'ConvexArea', 'Centroid', 'Area');

        % filter regions with big holes
        solidityIdx = [mserStats.Solidity] > 0.85;
        
        % filter regions with incorrect aspect ratio
        aspect = [mserStats.MinorAxisLength]./[mserStats.MajorAxisLength];
        aspectIdx = aspect > 0.3 & aspect < 0.65;
        
        % filter regions that are too round
        eccentricityIdx = [mserStats.Eccentricity] < 0.95;
        
        % process filters
        filterIdx = solidityIdx & aspectIdx & eccentricityIdx;
        mserRegions = mserRegions(filterIdx);
        mserStats = mserStats(filterIdx);
        
        % remove overlapping regions
        if ~isempty(mserRegions)
            [~,~,bbIdx] = selectStrongestBbox(cell2mat({mserStats.BoundingBox}'), ...
                (1./[mserStats.ConvexArea])', 'OverlapThreshold', 0.3);
            mserRegions = mserRegions(bbIdx);
            mserStats = mserStats(bbIdx);
        end
        
        % calculate minimum area bounding rectangle
        for i = 1:length(mserRegions)
            % get convex hull points
            pts = mserStats(i).ConvexHull;
            
            % determine unit edge direction
            vects = diff(pts);
            norms = sqrt(sum(vects.^2,2));
            uvects = diag(1./norms)*vects;
            nvects = fliplr(uvects);
            nvects(:,1) = nvects(:,1)*-1;
            
            % find MBR
            minmax = @(x) [min(x,[],1); max(x,[],1)];
            x = minmax(pts*uvects');
            y = minmax(pts*nvects');
            
            areas = (y(1,:)-y(2,:)).*(x(1,:)-x(2,:));
            [~,idx] = min(areas);
            
            % define the rectangle
            xys = [x([1,2,2,1,1],idx), y([1,1,2,2,1],idx)];
            rect = xys*[uvects(idx,:); nvects(idx,:)];
            
            % extract region
            tag = extractregion(frame,rect(1:end-1,:));
            
            % rotate to long edge
            if size(tag, 1) > size(tag, 2)
                tag = rot90(tag);
            end
            
            % get HOG features and classify as good, blurred, or bad
            features = extractHOGFeatures(imresize(tag, [30 60]), 'CellSize', [4 4]);
            class = predict(classifier, features);
            if class == 3
                continue
            end
            
            % save tag
            filename = sprintf('%s_tag%06d.tif', vidName, numTags);
            filepath = fullfile(outpath, 'tags', filename);
            imwrite(tag, filepath);
            
            % add annotations
            annotations(numTags).filename = filename;               %#ok<AGROW>
            annotations(numTags).filepath = filepath;               %#ok<AGROW>
            annotations(numTags).tagid = sprintf('%06d', numTags);  %#ok<AGROW>
            annotations(numTags).frame = numFrames;                 %#ok<AGROW>
            annotations(numTags).time = time;                       %#ok<AGROW>
            annotations(numTags).mbr = rect;                        %#ok<AGROW>
            annotations(numTags).bbox = mserStats(i).BoundingBox;   %#ok<AGROW>
            annotations(numTags).centroid = mserStats(i).Centroid;  %#ok<AGROW>
            annotations(numTags).area = mserStats(i).Area;          %#ok<AGROW>
            
            % increment tag counter
            numTags = numTags + 1;
        end %for
    end %if
    
    % increment frame counter
    numFrames = numFrames + 1;
end %while

% save tag annotations
save(fullfile(outpath, 'tags', 'tag_annotations.mat'), 'annotations');

end %function
