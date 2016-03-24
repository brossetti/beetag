function [ image ] = extractregion( image, pts )
%EXTRACTREGION Extracts region based on coordinates of bounding ellipse
%   This function extracts a tag according to coordinates of its bounding
%   ellipse. The coordinates should be a 4x2 matrix of (x,y) pairs starting
%   at a long-axis vertex and moving clockwise to the next verticies.

% determine rect dimensions
[dists, Idx] = sort(pdist(pts, 'euclidean'), 'ascend');
h = floor(dists(2));
w = floor(dists(4));

% set reference points
% refpts = [ 0,0; 0,h; w,h; w,0];
refpts = [ w, 0; w,h; 0,h; 0,0];

% cycle pts to start with short edge
if find(Idx == 1) > 2
    pts = pts([2,3,4,1],:);
end

tform = fitgeotrans(pts,refpts,'projective');
image = imwarp(image,tform,'cubic', 'OutputView', imref2d([h, w]));

end

