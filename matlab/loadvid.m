vid = VideoReader('/home/brosset/Documents/Research/BeeData/MVI_0228.AVI','CurrentTime', 15*16);
stck = uint8(zeros(vid.Height, vid.Width));
i = 1;
counter = 1;
while hasFrame(vid)
    if mod(counter,10000) == 0
        stck(:,:,i:i+2) = readFrame(vid);
        i = i + 3;
    end
    x = readFrame(vid);
    counter = counter + 1;
end

