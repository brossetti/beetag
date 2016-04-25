function [ annotations ] = tagfilter(annotations, outpath)
%TAGFILTER Filters/processes tag annotations to define tracked objects
% 

% parameters
t = 1;

% initialize obj structure with objects in first frame
times = unique([annotations.time]);

for i = 1:find([annotations.time] == times(1), 1, 'last')
    annotations(i).objid = i;
end


%loop through each time point
for i = times(2:end)
    % get tags in time point
    tagIdx = find([annotations.time] == i);
    
    % get obj within 1 sec of current time
    objIdx = find([annotations.time] > i-t & [annotations.time] < i);

    % create new obj if none found else detect match
    if isempty(objIdx)
        for j = tagIdx
            annotations(j).objid = max([annotations.objid])+1;
        end
    else
        % get last frame of each obj
        objs = annotations(objIdx);
        [~, objIdx] = unique(flip([objs.objid]));
        objIdx = length(objs)-objIdx+1;
        objs = objs(objIdx);
        
        % create feature matrix for objs
        objMat = [objs.centroid, objs.area];
        
        % create feature matrix for current tags
        tagIdx = find([annotations.time] == i);
        tags = annotations(tagIdx);
        tagMat = [tags.centroid, tags.area];
        
        % match features
        idxPair = matchFeatures(objMat, tagMat, 'Unique', true);
        
        % assign unmatched tags
        umIdx = true(length(tags), 1);
        umIdx(idxPair(:,2)) = false;
        umIdx = find(umIdx);
        
        objnum = max([annotations.objid]);
        for j = umIdx
            tags(j).objid = objnum;
            objnum = objnum + 1;
        end
        
        % assign matched tags
        if ~isempty(idxPair)
            tags(idxPair(:,2)).objid = objs(idxPair(:,1)).objid;
        end
        
        annotations(tagIdx).objid = tags.objid;
        
        
    end
    

end %for

end %function