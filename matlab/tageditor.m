function tageditor(annotations, vid)

% SIMPLE_GUI2 Select a data set from the pop-up menu, then
% click one of the plot-type push buttons. Clicking the button
% plots the selected data in the axes.

%  set figure dimensions
set(0,'units','pixels');
ss = get(0,'screensize');   % screen size
sar = ss(4)/ss(3);          % screen aspect ratio
far = 3/4;                  % figure aspect ratio
fds = 2/3;                  % figure downscale

if far > sar
    % set dimensions based on screen width
    w = fds*ss(3);
    h = w*far;
else
    % set dimensions based on screen height
    h = fds*ss(4);
    w = h/far;    
end

fdims = [floor(ss(3)/2-w/2), floor(ss(4)/2-h/2), w, h];

f = figure('Visible','off','Position', fdims, 'Name', 'Tag Editor',...
    'NumberTitle','off', 'Toolbar', 'none');

% set figure panels
pvid = uipanel(f, 'Title', 'Video', 'Position', [0.005, 0.7+0.0025, 0.99, 0.3-0.0075]);
axvid = axes(pvid);
ptags = uipanel(f, 'Title', 'Tags', 'Position', [0.005, 0.005, 0.7-0.0075, 0.7-0.0075]);
ptracks = uipanel(f, 'Title', 'Tracks', 'Position', [0.7+0.0025, 0.005, 0.15-0.005, 0.7-0.0075]);
peditor = uipanel(f, 'Title', 'Editor', 'Position', [0.85+0.0025, 0.005, 0.15-0.0075, 0.7-0.0075]);

% add tracks listbox
tracks = unique([annotations.trackid]);
tracknames = arrayfun(@(x) ['track ' num2str(x)], tracks, 'UniformOutput', false);
htracks = uicontrol(ptracks, 'Style', 'listbox', 'String', tracknames, ...
          'Units', 'normalized', 'Position', [0.01, 0.01, .98, .98], ...    
          'Max', 2, 'Min', 0, 'Value', 1, ...
          'Callback', @tracks_Callback);

% add tag table
tagdata = tracks2cell(annotations, tracks(1));
htags = uitable(ptags, 'Data', tagdata, ...
        'Units', 'normalized', 'Position', [0.01, 0.01, .98, .98], ...
        'RowName', [], ...
        'ColumnName', {'Track', 'Tag', 'Time', 'X', 'Y', 'Digits'}, ...
        'ColumnEditable', logical([1 0 0 0 0 1]), ...
        'CellSelectionCallback', @tags_SelectionCallback);

wtable = htags.Extent(3)*f.Position(3); 
htags.ColumnWidth = {floor(wtable/size(tagdata,2))-1};

% store gui data
gdata.annotations = annotations;
gdata.vid = vid;
gdata.axvid = axvid;
gdata.tracks = tracks;
gdata.tracknames = tracknames;
gdata.htracks = htracks;
gdata.tagdata = tagdata;
gdata.htags = htags;
guidata(f, gdata);

% add video frame
showframe(1, gdata);

% display initial state
f.Visible = 'on';

end

%% Functions\Callbacks

function tracks_Callback(hObject, eventdata)
    % get data
    gdata = guidata(hObject);
    idx = hObject.Value;
    
    % create/display new table
    gdata.tagdata = tracks2cell(gdata.annotations, idx);
    gdata.htags.Data = gdata.tagdata;
    
    % display first video frame
    showframe(1, gdata);
    
    % reassign guidata
    guidata(hObject, gdata);
end %tracks_Callback

function tags_SelectionCallback(hObject, eventdata)
    % get data
    gdata = guidata(hObject);
    row = eventdata.Indices(1,1);
    
    % display video frame
    showframe(row, gdata);
    
    % reassign guidata
    guidata(hObject, gdata);
end %tags_Callback

function data = tracks2cell(x, t)
    idx = ismember([x.trackid], t);
    data = struct2cell(x(idx));
    data = squeeze(data([17, 3, 5, 8, 8, 12], :, :))';
    data(:,4) = arrayfun(@(y) {y{:}(1)}, data(:,4));
    data(:,5) = arrayfun(@(y) {y{:}(2)}, data(:,5));
end %tracks2cell

function showframe(idx, gdata)
    % get data
    [tagid, time] = gdata.tagdata{idx,2:3};
    
    % get data for frame
    framedata = gdata.annotations([gdata.annotations.time] == time);
    
    % get indices
    idx = strcmp(tagid, {framedata.tagid});
    
    % get frame
    gdata.vid.CurrentTime = time;
    frame = readFrame(gdata.vid);
    
    % add bboxes
    frame = insertShape(frame,'rectangle', framedata(idx).bbox, 'Color', 'green');
    frame = insertShape(frame,'rectangle', vertcat(framedata(~idx).bbox), 'Color', 'yellow');
    
    % display
    image(gdata.axvid, frame);
    axis off;
    
end %showframe