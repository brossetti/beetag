function [ image ] = extractregion( image, pts )
%EXTRACTREGION Extracts region based on coordinates of bounding ellipse
%   This function extracts a tag according to coordinates of its bounding
%   ellipse. The coordinates should be a 4x2 matrix of (x,y) pairs starting
%   at a long-axis vertex and moving clockwise to the next verticies.

% get image size
[y, x, c] = size(image);

% find edge for rotation
[~, idx] = sort(pts(:,2), 'ascend');
idx = idx(1:2);

% compute rotation
theta = atan((pts(idx(1),2)-pts(idx(2),2))/(pts(idx(1),1)-pts(idx(2),1)));

% define tform
if theta == 0
    % use indexing to crop
    minmax = @(x) [min(x) max(x)];
    xys = floor(minmax(pts));
    xys(xys < 1) = 1;
    if xys(3) > x
        xys(3) = x;
    end
    if xys(4) > y
        xys(4) = y;
    end
    image = image(xys(2):xys(4), xys(1):xys(3), :);
    return 
elseif theta < 0
    % rotate on leftmost point
    [~, idx] = min(pts(:,1));
else
    % rotate on topmost point
    idx = idx(1);
end

tform = invert(affine2d([cos(theta), sin(theta), 0; ...
                        -sin(theta), cos(theta), 0; ...
                         pts(idx,1), pts(idx,2), 1]));

% transform points
[w, h] = transformPointsForward(tform, pts(:,1), pts(:,2));
w = floor(max(w));
h = floor(max(h));

image = imwarp(image,tform,'bilinear', 'OutputView', imref2d([h, w]));
end