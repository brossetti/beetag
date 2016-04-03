function [ tagpaths ] = tagextract(vid, background, outpath)
%TAGEXTRACT Detects and extracts bee tags from a preprocessed video
%   Detailed explanation goes here
close all
plt = true;

% setup output directory
[status, message] = mkdir(outpath, 'tags');
if ~status
    tagpaths = false;
    return
end

% detect MSER regions.
numFrames = 1;
numTags = 0;
% background = background(:,:,3);
background = rgb2gray(background);

while hasFrame(vid)
    % read frame and remove background
    frame = readFrame(vid);
    gframe = imadjust(frame(:,:,3));
%     gframe = imadjust(rgb2gray(frame));
    gframebg = gframe - background;
%     gframebg = gframe - (2*background./3);
%     gframebg = imabsdiff(double(gframe), background) ;
    
    if plt
        subplot(3,1,1)
        imshow(frame)
        subplot(3,1,2)
        imshow(gframebg,[])
    end
    % detect MSER regions
    [mserRegions, mserConnComp] = detectMSERFeatures(gframebg,...
        'RegionAreaRange',[300 3000],'ThresholdDelta',4);
    
    if ~isempty(mserRegions)
        % measure MSER properties
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Solidity',...
            'Eccentricity', 'ConvexHull', 'MajorAxisLength',...
            'MinorAxisLength', 'ConvexArea', 'Image');

        % filter regions with big holes
        solidityIdx = [mserStats.Solidity] > 0.85;
        
        % filter regions with incorrect aspect ratio
        aspect = [mserStats.MinorAxisLength]./[mserStats.MajorAxisLength];
        aspectIdx = aspect > 0.35 & aspect < 0.7;
        
        % filter regions that are too round
        eccentricityIdx = [mserStats.Eccentricity] < 0.95;
        
        % process filters
        filterIdx = solidityIdx & aspectIdx & eccentricityIdx;
        mserRegions = mserRegions(filterIdx);
        mserStats = mserStats(filterIdx);
        
        % remove overlapping regions
        if ~isempty(mserRegions)
            [~,~,bbIdx] = selectStrongestBbox(cell2mat({mserStats.BoundingBox}'),(1./[mserStats.ConvexArea])',...
                'OverlapThreshold', 0.3);
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
            
            % save tag
            numTags = numTags + 1;
            [~, vidName, ~] = fileparts(vid.Name);
            filename = sprintf('%s_%.4f_%05d.tif', vidName, vid.CurrentTime, numFrames);
            tagpaths{numTags} = fullfile(outpath, 'tags', filename);
            imwrite(tag, tagpaths{numTags});
            
            if plt
                subplot(3,1,2)
                hold on
                plot(mserRegions, 'showPixelList', true,'showEllipses',false)
                plot(rect(:,1),rect(:,2),'r')
                hold off
                subplot(3,1,3)
                imshow(tag)
                pause(0.001)
            end
        end
    end %if
   
    if plt
        pause(0.001)
    end
    numFrames = numFrames + 1;
end %while

end %function

