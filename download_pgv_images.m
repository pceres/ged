function fitness_crop = download_pgv_images(pgvroot,gedcom,SID,dest_folder,varargin)
%
% fitness_crop = download_pgv_images(pgvroot,gedcom,SID,dest_folder)
%
% % fitness_crop: [0..49] 0 --> all 4 borders have no cut; 10.x: one border
% %                       is cut; ...
%
% % es.:
% % before launching be sure that:
% % 1) you logged into the PhpGedView website indicated in input
% % 2) Firefox is open and with maximized window, the upper left part must
%      be visible
% % 3) the Firefox window:
% %    - has no message bars (es. Sync)
% %    - has no sidebar (history, etc.)
% %    - has only the following toolbars: Menu Bar, Navigation Toolbar, Bookmark Toolbar
%
% fitness_crop = download_pgv_images('http://ars.altervista.org/PhpGedView/','caposele','I0000','/home/ceres/')
% % or
% fitness_crop = download_pgv_images('http://ars.altervista.org/PhpGedView/','caposele',{'I0000','I18'},'/home/ceres/')
%
% todo: check I902, image is too big


%
% input management
%

% dest_folder management
if ~exist('dest_folder','var')
    dest_folder = pwd;
end
if ~strcmp(dest_folder(end),filesep)
    % add ending '/' if needed
    dest_folder = [dest_folder filesep];
end

if ~exist('SID','var')
    % default params for debug
    pgvroot = 'http://localhost/work/PhpGedView/';
    gedcom = 'caposele';
    SID = 'I0000';
    dest_folder = pwd;
elseif iscell(SID)
    % multiple SID list, just iterate on them
    fitness_crop = zeros(size(SID));
    for i_img = 1:length(SID)
        fitness_crop_i = download_pgv_images(pgvroot,gedcom,SID{i_img},dest_folder,  i_img,length(SID));
        fitness_crop(i_img) = fitness_crop_i;
    end
    return
end

% multiple SID parameters
if (nargin > 4)
    i_item   = varargin{1};
    num_item = varargin{2};
else
    i_item   = NaN;
    num_item = NaN;
end


%
% parameters
%

debug_level = 1; % 0: no output; 1: only text msgs; 2: graphs
crc_module = 9999;
filename_arc = 'archivio_img_crc.mat';


%
% code
%

% retrieve graph for SID (warning: session-less operation, so recent people
% are hidden (shown as "private"), and a change of their names is not
% detected
str_pgv_img = struct('pgvroot',pgvroot,'gedcom',gedcom,'SID',SID);
fullname_arc = [dest_folder filesep filename_arc];
str_SID = load_str_SID(fullname_arc);
url_pgvtext = [pgvroot 'treenav.php?ged=' gedcom '&rootid=' SID];
text = urlread(url_pgvtext);

crc_new = get_graph_crc(text,crc_module,pgvroot);

filename = [dest_folder SID2filename(SID)];
if exist(filename,'file')
    img_old = imread(filename);
    img_crc_new = get_crc(img_old(:),crc_module);
else
    img_crc_new = NaN;
end

[flg_rebuild fitness_crop] = needs_rebuild(str_SID,SID,crc_new,img_crc_new,i_item,num_item,debug_level);

filename_out = filename; % rewrite the image
if flg_rebuild
    [img_new flg_ok fitness_crop] = rebuild_img(str_pgv_img,filename_out,debug_level);
    if flg_ok
        img_crc_new = get_crc(img_new(:),crc_module);
        update_archive(fullname_arc,str_SID,SID,crc_new,img_crc_new,fitness_crop);
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function crc = get_graph_crc(text0,module,pgvroot)

% only crc the useful part with genealogical data
text = regexp(text0,'<div id="out_nav".*','match');
text = text{1};

% remove reference to the pgv url
text = strrep(text,pgvroot,'<pgvroot>');

crc = get_crc(text,module);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function crc = get_crc(vect,module)

crc = mod(sum(vect),module);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_SID = load_str_SID(filename)

if exist(filename,'file')
    z = load(filename);
else
    z = struct();
end
if isfield(z,'str_SID')
    str_SID = z.str_SID;
else
    str_SID = struct();
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_rebuild fitness_crop_old] = needs_rebuild(str_SID,SID,crc_new,img_crc_new,i_item,num_item,debug_level)

if isnan(i_item)
    msg_item = '';
else
    msg_item = sprintf(' (%03d/%03d)',i_item,num_item);
end

disp_my(sprintf('\n%s%s :',SID,msg_item),debug_level)

if isfield(str_SID,SID)
    crc_old     = str_SID.(SID).crc;
    img_crc_old = str_SID.(SID).img_crc;
    fitness_crop_old = str_SID.(SID).fitness_crop;
else
    crc_old     = NaN;
    img_crc_old = NaN;
    fitness_crop_old = NaN;
end

flg_rebuild = 0;
if (crc_old ~= crc_new)
    flg_rebuild = 1;
    disp_my(sprintf('Different CRC for data for id %s: %d --> %d',SID,crc_old,crc_new),debug_level)
else
    disp_my(sprintf('No CRC change in data for id %s: %d',SID,crc_new),debug_level)
end

if (img_crc_old ~= img_crc_new)
    flg_rebuild = 1;
    disp_my(sprintf('Need to rebuild image for id %s',SID),debug_level)
else
    disp_my(sprintf('Unchanged image for id %s',SID),debug_level)
end
disp_my(sprintf('Current fitness_crop is %.2f',fitness_crop_old),debug_level)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = SID2filename(SID)

filename = [SID '.jpg'];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img4 flg_ok fitness_crop] = rebuild_img(str_pgv_img,filename_out,debug_level)

jpg_quality = 95;
temp_folder = 'snapshot';

pgvroot = str_pgv_img.pgvroot;
gedcom = str_pgv_img.gedcom;
SID = str_pgv_img.SID;

[path name ext] = fileparts(filename_out);
dest_folder = [path filesep];
filename = [name ext];

disp_my(sprintf('Rebuilding image %s for id %s...',filename,SID),debug_level)

% download the image file
url_format = [pgvroot 'treenav.php?ged=' gedcom '&rootid=<PID> '];
filename_dwnl = [dest_folder temp_folder filesep filename '.bmp']; % use a bitmap format to avoid loss of information
[img url flg_fullscreen flg_ok] = download_pgv_images_i(SID,url_format,filename_dwnl);
if flg_ok
    % crop the image:
    
    disp_my(sprintf('\t%s %s',SID,url),debug_level)
    disp_my(sprintf('\tDownloaded %s',filename_dwnl),debug_level)
    
    if (debug_level >= 2)
        image(img);
        hold on
        h = gcf;
    else
        h = [];
    end
    
    % check for fullscreen (same cords as in static_crop for full screen)
    kx1 = 0.0208; % 40
    ky1 = 0.0528; % 57
    kx2 = 0.9911; % 1903
    kx2_ = kx1+(kx2-kx1)*0.1; % don't take the whole line, as there could be a part of a big graph, just take the left part
    tmp_debug_level = debug_level;
    ok = check_point_to_point_all_white(img,kx1,ky1,kx2_,ky1,h,tmp_debug_level);
    if (~ok == flg_fullscreen)
        % fullscreen mode not coherent with request! Fix it
        fprintf(1,'\t*** Fullscreen mode not coherent with request! Fixing it\n')
        flg_fullscreen = ~flg_fullscreen;
    end
    
    [img3 result_whiteness result_delta_coord] = crop_img(img,flg_fullscreen,debug_level);
    fitness_crop = sum(1-result_whiteness)+sum(result_whiteness<1)*10;
    disp_my(sprintf('\tCropped %s (fitness %.2f)',filename,fitness_crop),debug_level)
    
    img3_2 = center_img(img3,result_delta_coord,debug_level);
    
    imwrite(img3_2,filename_out,'jpeg','mode','lossy','quality',jpg_quality);
    img4 = imread(filename_out); % reload the image to get the real data
else
    img4 = [];
    fitness_crop = NaN;
    disp_my(sprintf('Aborting download for id %s...',SID),debug_level)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img = save_img_snapshot(filename_dwnl)

robot = robot_wrapper('init');

dest_folder = fileparts(filename_dwnl);
if ( ~isempty(dest_folder) && ~exist(dest_folder,'dir') )
    mkdir(dest_folder)
end

robot_wrapper('save_snapshot',{robot,filename_dwnl});
img = imread(filename_dwnl);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img3 result_whiteness result_delta_coord] = crop_img(img,flg_fullscreen,debug_level)

img2 = static_crop(img,flg_fullscreen,debug_level);

[img3 result_whiteness result_delta_coord] = smart_crop(img2,debug_level);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img2 = static_crop(img,flg_fullscreen,debug_level)

% this removes the areas that are surely not good, such as the left and
% right sides

height = size(img,1); % 1080
width  = size(img,2); % 1920

if flg_fullscreen
    x1 = round(width*0.0208); % 40
    %    y1 = round(height*0.0528);% 57
    y1 = round(height*0.0019);% 2
    x2 = round(width*0.9911); % 1903
    %y2 = round(height*0.9296);% 1004 needed if the sync message is shown in the lower part of the screen
    %y2 = round(height*0.9204);% 994 needed if no sync message is shown (viewPort=600px)
    y2 = round(height*0.9981);% 994 needed if no sync message is shown (viewPort=1080px)
else
    x1 = round(width*0.0208); % 40
    y1 = round(height*0.1759);% 190
    x2 = round(width*0.9911); % 1903
    %y2 = round(height*0.9296);% 1004 needed if the sync message is shown in the lower part of the screen
    y2 = round(height*0.9630);% 1040 needed if no sync message is shown
end

img2 = img(y1:y2,x1:x2,:);

if (debug_level >= 2)
    image(img);
    axis image
    hold on
    plot(x1,y1,'ro');
    plot(x2,y2,'ro');
    fill([x1 x1 x2 x2],[y1 y2 y2 y1],[1 0 0],'FaceAlpha',0.1,'EdgeAlpha',0);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img3 result_whiteness result_delta_coord] = smart_crop(img2,debug_level)
% result_whiteness : [left right up down]

if (debug_level >= 2)
    h = figure;
    image(img2);
    axis image
    hold on
else
    h = [];
end

width  = size(img2,2);
height = size(img2,1);

result_k = zeros(1,4)*NaN;
result_whiteness = zeros(1,4)*NaN;
for i_dir = 1:4
    switch i_dir
        case 1
            dir_tag = 'left';
            kx1_ref = 0;
            kx2_ref = 0.5;
            ky1_ref = 0;
            ky2_ref = 1;
        case 2
            dir_tag = 'right';
            kx1_ref = 1;
            kx2_ref = 0.5;
            ky1_ref = 0;
            ky2_ref = 1;
        case 3
            dir_tag = 'up';
            kx1_ref = result_k(1);   % left border
            kx2_ref = result_k(2); % right border
            ky1_ref = 0;
            ky2_ref = 0.5;
        case 4
            dir_tag = 'down';
            kx1_ref = result_k(1);   % left border
            kx2_ref = result_k(2); % right border
            ky1_ref = 1;
            ky2_ref = 0.5;
        otherwise
            disp('todo')
    end
    
    [k whiteness] = detect_border(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,h,debug_level);
    result_k(i_dir) = k;
    result_whiteness(i_dir) = whiteness;
end

result_coord = round([result_k(1:2)*width result_k(3:4)*height]);

borderx = 25;
bordery = 25;

dx1 = 0;
dx2 = 0;
dy1 = 0;
dy2 = 0;

x1 = result_coord(1)-borderx;
if ( x1<1 )
    dx1 = 1-x1;
    x1  = 1;
end

x2 = result_coord(2)+borderx;
if ( x2>width )
    dx2 = x2-width;
    x2  = width;
end

y1 = result_coord(3)-bordery;
if ( y1<1 )
    dy1 = 1-y1;
    y1  = 1;
end

y2 = result_coord(4)+bordery;
if ( y2>height )
    dy2 = y2-height;
    y2  = height;
end

result_delta_coord = [dx1 dx2 dy1 dy2];

img3 = img2(y1:y2,x1:x2,:);
if (debug_level >= 2)
    figure
    image(img3);
    axis image
    title(sprintf('Delta coord: %s',num2str(result_delta_coord,'%d ')))
    hold on
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [k whiteness] = detect_border(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,h,debug_level)

k_ok = 0;
k_nok = 1;

ancora = 1;
coord_old = inf;

% try to detect full white line
while ancora
    k_ = (k_ok+k_nok)/2;
    tmp_debug = 0;
    if strcmp(dir_tag,'up')
        % tmp_debug = debug_level;
    end
    [ok coord] = is_line_all_white(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_,h,tmp_debug);
    
    if ok
        k_ok = k_;
    else
        k_nok = k_;
    end
    
    ancora = abs(coord_old-coord)>1;
    coord_old = coord;
end

if ismember(dir_tag,{'left','right'})
    k = kx1_ref+k_ok*(kx2_ref-kx1_ref);
else
    k = ky1_ref+k_ok*(ky2_ref-ky1_ref);
end

% redraw for plot
[ok coord whiteness] = is_line_all_white(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_ok,h,debug_level);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [kx1 ky1 kx2 ky2] = get_test_line(dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_)

switch dir_tag
    case {'left','right'}
        % linea verticale parametrizzata in k_ (da kx1_ref a kx2_ref)
        kx1 = kx1_ref+k_*(kx2_ref-kx1_ref);
        kx2 = kx1;
        ky1 = ky1_ref;
        ky2 = ky2_ref;
    case {'up','down'}
        % linea orizzontale parametrizzata in k_ (da ky1_ref a ky2_ref)
        ky1 = ky1_ref+k_*(ky2_ref-ky1_ref);
        ky2 = ky1;
        kx1 = kx1_ref;
        kx2 = kx2_ref;
    otherwise
        error('todo')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ok coord whiteness] = is_line_all_white(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_,h,debug_level)

[kx1 ky1 kx2 ky2] = get_test_line(dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_);

[ok coord whiteness] = check_point_to_point_all_white(img2,kx1,ky1,kx2,ky2,h,debug_level);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ok coord whiteness] = check_point_to_point_all_white(img2,kx1,ky1,kx2,ky2,h,debug_level)

white_thr = 0.95;

height = size(img2,1);
width  = size(img2,2);

x1 = max(1,round(kx1*width));
y1 = max(1,round(ky1*height));
x2 = round(kx2*width);
y2 = round(ky2*height);

if (kx1 == kx2)
    % vertical line
    indy = y1:y2;
    indx = (1:length(indy))*0+x1;
    dots = img2(y1:y2,x1,:);
    coord = x1;
    dotr = double(dots(:,:,1))/255;
    dotg = double(dots(:,:,2))/255;
    dotb = double(dots(:,:,3))/255;
elseif (ky1 == ky2)
    % horizontal line
    indx = x1:x2;
    indy = (1:length(indx))*0+y1;
    dots = img2(y1,x1:x2,:);
    coord = y1;
    dotr = double(dots(:,:,1)')/255;
    dotg = double(dots(:,:,2)')/255;
    dotb = double(dots(:,:,3)')/255;
else
    error('todo')
end


y = sqrt(sum([dotr dotg dotb].^2,2))/sqrt(3); % [0..1] 0 --> black, 1 --> white

ind_white = y>white_thr;
ind_non_white = not(ind_white);

whiteness = sum(ind_white)/length(ind_white);

if all(ind_white)
    white_col = 'g';
    ok = 1;
else
    white_col = 'y';
    ok = 0;
end

if (debug_level >= 2)
    figure(h)
    plot(indx(ind_white),indy(ind_white),white_col)
    plot(indx(ind_non_white),indy(ind_non_white),'o-r')
    
    if 0
        figure %#ok<UNRCH>
        x = 1:length(dotr);
        plot(x,dotr,x,dotg,x,dotb,x,y)
        temp = axis;
        temp([3 4])=[0 1];
        axis(temp)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_SID = update_archive(filename,str_SID,SID,crc_new,img_crc_new,fitness_crop_new)

str_SID.(SID).crc           = crc_new;
str_SID.(SID).img_crc       = img_crc_new;
str_SID.(SID).fitness_crop  = fitness_crop_new;

if exist(filename,'file')
    save(filename,'str_SID','-append')
else
    save(filename,'str_SID')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img1 url flg_fullscreen flg_ok] = download_pgv_images_i(id_genea,url_format,filename_dwnl)
%
% [img1 url flg_fullscreen flg_ok] = download_pgv_images_i('I10396','http://ars.altervista.org/PhpGedView/treenav.php?ged=caposele&rootid=<PID>');eval(['!gimp' sprintf(' "%s"',list_filename{:}) ' &'])
%

flg_fullscreen = 1;
img1 = [];
url = strrep(url_format,'<PID>',id_genea);

max_download_retries = 2;

robot = robot_wrapper('init');

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

ancora = 1;
count = 0;
while ancora
    %% give focus to the browser
%    robot_wrapper('mouse_move',{robot,width*0.07, height*0.075}); % no menu, no tab
%    robot_wrapper('mouse_move',{robot,width*0.07, height*0.100}); % no menu, yes tab
    robot_wrapper('mouse_move',{robot,width*0.07, height*0.130}); % yes menu, yes tab
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.3)
    
    % load url
    robot_wrapper('key_press',{robot,'^(a)'}); % select all
    pause(0.2)
    robot_wrapper('key_press',{robot,url}); % type the url
    pause(0.2)
    robot_wrapper('key_press',{robot,sprintf('\n')}); % enter
    pause(2) % wait for page load
    
    %% activate and close search bar
    robot_wrapper('key_press',{robot,'^(f)'}); % activate search bar...
    pause(0.1)
    robot_wrapper('key_press',{robot,'{ESCAPE}'}); % ...and close it
    pause(0.1)
    
    %% check if webpage shown corresponds to the requested PID
    filename_html = [fileparts(which(mfilename)) filesep 'temp$$$.htm'];
    flg_ok = check_SID_in_webpage(robot,id_genea,filename_html);
    count = count+1;
    ancora = ~flg_ok && (count<max_download_retries);
end

if (~flg_ok)
    % impossible to download, just stop
    return
end

%% scroll the graph upwards
if flg_fullscreen
    robot_wrapper('key_press',{robot,'{F11}'}); % go fullscreen
    %pause(0.2)
    pause(1)
    
    k = 0.035;
    pos_mouse_pointer_scroll_up_x = width*0.995;
    pos_mouse_pointer_scroll_up_y = height*(0.959+k);
    pos_mouse_pointer_scroll_down_x = pos_mouse_pointer_scroll_up_x;
    pos_mouse_pointer_scroll_down_y = height*(0.946+k);
else
    pos_mouse_pointer_scroll_up_x = width*0.995; %#ok<UNRCH>
    pos_mouse_pointer_scroll_up_y = height*0.959;
    pos_mouse_pointer_scroll_down_x = pos_mouse_pointer_scroll_up_x;
    pos_mouse_pointer_scroll_down_y = height*0.946;
end

robot_wrapper('mouse_move',{robot,pos_mouse_pointer_scroll_up_x, pos_mouse_pointer_scroll_up_y}); % upwards
for i_tmp = 1:3
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.3)
end

%% scroll the graph upwards

% max number of scroll steps to try to center the image. Once that number
% is reached, scrolling is stopped
max_scroll = 20;

tmp_debug_level = 1;
result_whiteness = get_result_whiteness(flg_fullscreen,tmp_debug_level);
count = 0;
while ( (count<max_scroll) && (result_whiteness(3) == 1) && (result_whiteness(4) < 1) ) % while upper border is still white and it is necessary to move the graph upwards...
    % ...move the graph upwards until bottom side is white
    robot_wrapper('mouse_move',{robot,pos_mouse_pointer_scroll_up_x, pos_mouse_pointer_scroll_up_y}); % upwards
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
    result_whiteness = get_result_whiteness(flg_fullscreen,tmp_debug_level);
    count = count+1;
end
if (count==max_scroll)
    fprintf(1,'\tCould not successfully move the graph upwards!')
end
if ( (count>0) && (result_whiteness(3)<1) )
    % if upper border is no longer white, step back 1 step
    robot_wrapper('mouse_move',{robot,pos_mouse_pointer_scroll_down_x, pos_mouse_pointer_scroll_down_y}); % downwards
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
end

%% move the graph a bit to the right
%result_whiteness = get_result_whiteness(flg_fullscreen,tmp_debug_level);
x_min_drag = 0.025;
x_max_drag = 0.5;
y_min_drag = 0.3;
y_max_drag = 0.7;
delta_right = 0.02;
count = 0;
[result_whiteness img] = get_result_whiteness(flg_fullscreen,tmp_debug_level);
while ( (count<max_scroll) &&  (result_whiteness(1) < 1) ) % while left border is not white...
    % find the right place (white pixel) to click and drag
    [kx, ky] = find_white_pixel(img,x_min_drag,x_max_drag,y_min_drag,y_max_drag);

    % ...move the graph to the right
    robot_wrapper('mouse_move',{robot,width*kx, height*ky});
    pause(0.2)
    robot_wrapper('mouse_move_with_button_pressed',{robot,'left',width*(kx+delta_right), height*ky});
    pause(0.1)
    %tmp_debug_level = 2
    [result_whiteness img] = get_result_whiteness(flg_fullscreen,tmp_debug_level);

    count = count+1;
end
if (count==max_scroll)
    fprintf(1,'\tCould not successfully move the graph to the right!')
end

%% move the graph a bit downward until upper border is white
%result_whiteness = get_result_whiteness(flg_fullscreen,tmp_debug_level);
delta_down = 0.04;
count = 0;
while ( (count<max_scroll) &&  (result_whiteness(3) < 1) ) % while upper border is not white...
    % find the right place (white pixel) to click and drag
    [kx, ky] = find_white_pixel(img,x_min_drag,x_max_drag,y_min_drag,y_max_drag);
    
    % ...move the graph downward
    robot_wrapper('mouse_move',{robot,width*kx, height*ky});
    pause(0.2)
    robot_wrapper('mouse_move_with_button_pressed',{robot,'left',width*kx, height*(ky+delta_down)});
    pause(0.1)
    %tmp_debug_level = 2
    result_whiteness = get_result_whiteness(flg_fullscreen,tmp_debug_level);
    count = count+1;
end
if (count==max_scroll)
    fprintf(1,'\tCould not successfully move the graph downwards!')
end

%% remove a possible wrong focus
robot_wrapper('mouse_move',{robot,pos_mouse_pointer_scroll_down_x-10, pos_mouse_pointer_scroll_down_y-20}); % blank area
robot_wrapper('mouse_click',{robot,'left'}); % click to remove bad focus, if present

img1 = save_img_snapshot(filename_dwnl);

if flg_fullscreen
    robot_wrapper('key_press',{robot,'{F11}'}); % exit fullscreen
    pause(0.2)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [kx, ky, ok] = find_white_pixel(img,x1_min_drag,x1_max_drag,y1_min_drag,y1_max_drag)
% find a white pixel (identified  by relative coordinates (0..1) kx and ky)
% in the region x1_min_drag < kx < x1_max_drag & y1_min_drag < ky <
% y1_max_drag of image img

debug_level = 0;
h = NaN;

%h = figure;image(img);axis image,hold on
ok = 0;
count = 0;
while ~ok && count<20
    count = count+1;
    kx = x1_min_drag + (x1_max_drag-x1_min_drag)*rand; % 0.025;
    ky = y1_min_drag + (y1_max_drag-y1_min_drag)*rand; % 0.35;
    plot(size(img,2)*kx, size(img,1)*ky,'ro')
    ok = check_point_to_point_all_white(img,kx,ky,kx,ky,h,debug_level);
end

if ~ok
    disp('could not find a white pixel to click and drag the graph!')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result_whiteness img] = get_result_whiteness(flg_fullscreen,tmp_debug_level)

temp_dwnl = 'temp_img_XYZX$$.jpg';
img = save_img_snapshot(temp_dwnl);
[img3 result_whiteness] = crop_img(img,flg_fullscreen,tmp_debug_level);
delete(temp_dwnl);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function disp_my(ks,debug_level)

if (debug_level > 0)
    disp(ks)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_ok SID] = check_SID_in_webpage(robot,SID_ok,filename_html)

flg_ok  = 0;
SID     = '';

timeout = 5; % [s]

if exist(filename_html,'file')
    delete(filename_html)
end

robot_wrapper('mouse_move',{robot,500,50}); % x starts from left, y starts from top
robot_wrapper('mouse_click',{robot,'left'}); % {'left','middle','right'}
robot_wrapper('key_press',{robot,'^(s)'}); % --> save window
pause(0.2)

robot_wrapper('key_press',{robot,'^(a)'}); % --> select all text
pause(0.01)
robot_wrapper('key_press',{robot,filename_html});
pause(0.01)
robot_wrapper('key_press',{robot,'%(s)'}); % --> save
pause(0.010)
robot_wrapper('key_press',{robot,'%(r)'}); % --> replace, in case the file already exists
pause(0.7) % wait until the page is actually saved and available in tempfile

count = 0;
ancora = 1;
while ancora
    pause(1)
    count = count+1;
    ancora = ~exist(filename_html,'file') && (count<=timeout);
end

if ( ~exist(filename_html,'file') )
    return
end

fid = fopen(filename_html, 'r');
text = fread(fid, 1e6, 'uint8=>char')';
fclose(fid);

delete(filename_html)

z=regexp(text,'treenav.*?rootid=([^&]+).*?changelanguage','tokens');
list_SID = unique([z{:}]');
if length(list_SID)==1
    SID = list_SID{1};
    fprintf(1,'\tDetected SID %s in graph.\n',SID)
    if strcmp(SID,SID_ok)
        flg_ok = 1;
    else
        fprintf(1,'\t\tWrong SID: expected %s.\n',SID_ok)
    end
else
    disp(list_SID)
    disp('Could not find a valid SID!')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img3_2 = center_img(img3,result_delta_coord,debug_level)

dx1 = result_delta_coord(1);
dx2 = result_delta_coord(2);
dy1 = result_delta_coord(3);
dy2 = result_delta_coord(4);

img3_2 = uint8(ones(size(img3,1)+(dy1+dy2),size(img3,2)+(dx1+dx2),size(img3,3))*255); % create a new image with extended size and all white
img3_2(dy1+(1:size(img3,1)),dx1+(1:size(img3,2)),1:size(img3,3))=img3; % and copy inside, in the right place, the image to be centered

if (debug_level >= 2)
    figure
    image(img3_2);
    axis image
end
