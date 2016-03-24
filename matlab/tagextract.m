function [ tagpaths ] = tagextract(vid, background, outpath)
%TAGEXTRACT Detects and extracts bee tags from a preprocessed video
%   Detailed explanation goes here
close all
% Detect MSER regions.
numFrames = 1;
background = rgb2gray(background);

while hasFrame(vid)
    % read frame and remove background
    frame = readFrame(vid);
    gframe = imadjust(rgb2gray(frame));
    gframebg = gframe - background ;

    % detect MSER regions
    [mserRegions, mserConnComp] = detectMSERFeatures(gframebg,...
        'RegionAreaRange',[300 3000],'ThresholdDelta',4);
    
    if ~isempty(mserRegions)
        % measure MSER properties
        mserStats = regionprops(mserConnComp, 'BoundingBox', 'Solidity',...
            'Eccentricity', 'ConvexHull', 'MajorAxisLength',...
            'MinorAxisLength', 'ConvexArea', 'Image');

        % filter regions with big holes
        solidityIdx = [mserStats.Solidity] > 0.80;
        
        % filter regions with incorrect aspect ratio
        aspect = [mserStats.MinorAxisLength]./[mserStats.MajorAxisLength];
        aspectIdx = aspect > 0.35 & aspect < 0.8;
        
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
%         for i = 1:length(mserRegions)
%             % get convex hull points
%             pts = mserStats(i).ConvexHull;
%             
%             % determine unit edge direction
%             vects = diff(pts);
%             norms = sqrt(sum(vects.^2,2));
%             uvects = diag(1./norms)*vects;
%             nvects = fliplr(uvects);
%             nvects(:,1) = nvects(:,1)*-1;
%             
%             % find MBR
%             minmax = @(x) [min(x,[],1); max(x,[],1)];
%             x = minmax(pts*uvects');
%             y = minmax(pts*nvects');
%             
%             areas = (y(1,:)-y(2,:)).*(x(1,:)-x(2,:));
%             [~,idx] = min(areas);
%             
%             % define the rectangle
%             x = x(:,idx);
%             y = y(:,idx);
%             xys = [x([0,1,1,0,0]), y([0,0,1,1,0])];
%         end
    end %if
    
    subplot(2,1,1)
    imshow(frame)
    subplot(2,1,2)
    imshow(gframebg)
    hold on
    plot(mserRegions, 'showPixelList', true,'showEllipses',true)
    hold off
    


%     n = length(mserStats);
%     figure
%     r = floor(sqrt(n));
%     c = ceil(n/r);
%     for i = 1:n
%         subplot(r,c,i)
%         imshow(mserStats(i).Image)
%     end
    
    pause(0.001)
    numFrames = numFrames + 1;
end %while

end %function

