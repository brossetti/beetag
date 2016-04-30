function [ annotations ] = tagfilter(annotations, outpath)
%TAGFILTER Filters/processes tag annotations to define tracked trackects
% 

% parameters
t = 1;

% initialize track structure with trackects in first frame
times = unique([annotations.time]);

for i = 1:find([annotations.time] == times(1), 1, 'last')
    annotations(i).trackid = i;
end


%loop through each time point
for i = times(2:end)
    % get tags in time point
    tagIdx = find([annotations.time] == i);
    
    % get track within 1 sec of current time
    trackidx = find([annotations.time] > i-t & [annotations.time] < i);

    % create new track if none found else detect match
    if isempty(trackidx)
        for j = tagIdx
            annotations(j).trackid = max([annotations.trackid])+1;
        end
    else
        % get last frame of each track
        tracks = annotations(trackidx);
        [~, trackidx] = unique(flip([tracks.trackid]));
        trackidx = length(tracks)-trackidx+1;
        tracks = tracks(trackidx);
        
        % create feature matrix for tracks
        trackMat = [vertcat(tracks.centroid), vertcat(tracks.area)];
        
        % create feature matrix for current tags
        tagIdx = find([annotations.time] == i);
        tags = annotations(tagIdx);
        tagMat = [vertcat(tags.centroid), vertcat(tags.area)];
        
        % match features
        idxPair = matchFeatures(trackMat, tagMat, 'Unique', true);
        
        % assign unmatched tags
        umIdx = true(length(tags), 1);
        umIdx(idxPair(:,2)) = false;
        umIdx = find(umIdx);
        
        tracknum = max([annotations.trackid]);
        for j = umIdx'
            tags(j).trackid = tracknum;
            tracknum = tracknum + 1;
        end
        
        % assign matched tags
        if ~isempty(idxPair)
            [tags(idxPair(:,2)).trackid] = tracks(idxPair(:,1)).trackid;
        end
        
        [annotations(tagIdx).trackid] = tags.trackid;
        
        
    end %if-else
    

end %for

% save tag annotations
save(fullfile(outpath, 'tags', 'tag_annotations.mat'), 'annotations');

end %function