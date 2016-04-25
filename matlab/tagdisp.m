function tagdisp(annotations, outpath)
%TAGDISP Graphics generator for bee tag images
close all

r = 1;
c = 2;

rzshow = @(x) imshow(imresize(x, 15, 'nearest'));
annotations = annotations([annotations.blurred] == 0);
for i = 1:length(annotations)
    % read image
%     img = imread(annotations(i).filepath);
    img = imread(fullfile('~/Desktop/tags',annotations(i).filename));
    % plot raw image
    subplot(r,c,1)
    rzshow(img);
    title('Raw Image');

    % flip image depending on orientation
    if annotations(i).orientation == 2
        img = rot90(img,2);
    end
    
    % plot oriented image with bboxes
    img = insertShape(img,'rectangle', annotations(i).cropbbox, 'Color', 'yellow');
%     img = insertShape(img,'rectangle', annotations(i).digitbboxes, 'Color', 'green');
    subplot(r,c,2)
    rzshow(img);
    title(annotations(i).digits);
    pause(2);
end

end