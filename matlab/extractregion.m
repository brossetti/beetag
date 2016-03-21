function [ image ] = extractregion( image, pts )
%EXTRACTREGION Extracts region based on coordinates of bounding ellipse
%   This function extracts a tag according to coordinates of its bounding
%   ellipse. The coordinates should be a 4x2 matrix of (x,y) pairs starting
%   at a long-axis vertex and moving clockwise to the next verticies.

refpts = [0, 46; 85, 0; 170, 46; 85, 92];

tform = estimateGeometricTransform(pts,refpts,'projective');
image = imwarp(image,tform,'cubic', 'OutputView', imref2d([92,170]));

end

