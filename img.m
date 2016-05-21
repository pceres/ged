function img(pgvroot,gedcom,SID)
%
% function img(pgvroot,gedcom,SID)
%
% % es.:
% img('http://ars.altervista.org/PhpGedView/','caposele','I0000')
%

if ~exist('SID','var')
    pgvroot = 'http://ars.altervista.org/PhpGedView/';
    gedcom = 'caposele';
    %SID = 'I18'; % Alex
    SID = 'I0000'; % io
    %SID = 'I10391'; % padre di Elisa Curcio
end

debug_level = 2; % 0: no output; 1: only text msgs; 2: graphs

str_pgv_img = struct('pgvroot',pgvroot,'gedcom',gedcom,'SID',SID);


crc_module = 9999;

filename_arc = 'archivio.mat';
str_SID = load_str_SID(filename_arc);

url_pgvtext = [pgvroot 'treenav.php?ged=' gedcom '&rootid=' SID];
text0 = urlread(url_pgvtext);
text = regexp(text0,'<div id="out_nav".*','match'); % only crc the useful part with genealogical data
text = text{1};

crc_new = round(rand*crc_module);
%crc_new = get_crc(text,crc_module);

filename = SID2filename(SID);
if exist(filename,'file')
    img_old = imread(filename);
    img_crc_new = get_crc(img_old(:),crc_module);
else
    img_crc_new = NaN;
end

flg_rebuild = needs_rebuild(str_SID,SID,crc_new,img_crc_new,debug_level);

filename_out = filename; % rewrite the image

if flg_rebuild
    img_new = rebuild_img(str_pgv_img,filename_out,debug_level);
    img_crc_new = get_crc(img_new(:),crc_module);
    
    update_archive(filename_arc,str_SID,SID,crc_new,img_crc_new);
end




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
function flg_rebuild = needs_rebuild(str_SID,SID,crc_new,img_crc_new,debug_level)

if isfield(str_SID,SID)
    crc_old     = str_SID.(SID).crc;
    img_crc_old = str_SID.(SID).img_crc;
else
    crc_old     = NaN;
    img_crc_old = NaN;
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = SID2filename(SID)

filename = [SID '.jpg'];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img4 = rebuild_img(str_pgv_img,filename_out,debug_level)

jpg_quality = 95;
dest_folder = 'snapshot';

pgvroot = str_pgv_img.pgvroot;
gedcom = str_pgv_img.gedcom;
SID = str_pgv_img.SID;

filename = SID2filename(SID);

disp_my(sprintf('Rebuilding image %s for id %s...',filename,SID),debug_level)

% download the image file
url_format = [pgvroot 'treenav.php?ged=' gedcom '&rootid=<PID> '];
url = download_pgv_images(SID,url_format);

% save fullscreen snapshot and get the image
filename_dwnl = [dest_folder filesep filename];
img = save_img_snapshot(filename_dwnl);
disp_my(sprintf('\t%s %s',SID,url),debug_level)
disp_my(sprintf('\tDownloaded %s',filename_dwnl),debug_level)

[img3 result_whiteness] = crop_img(img,debug_level);
fitness_crop = sum(1-result_whiteness)+sum(result_whiteness<1)*10;
disp_my(sprintf('\tCropped %s (fitness %.2f)',filename,fitness_crop),debug_level)

imwrite(img3,filename_out,'jpeg','mode','lossy','quality',jpg_quality);
img4 = imread(filename_out); % reload the image to get the real data



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
function [img3 result_whiteness] = crop_img(img,debug_level)

if (debug_level >= 2)
    image(img)
end

img2 = static_crop(img,debug_level);

[img3 result_whiteness] = smart_crop(img2,debug_level);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img2 = static_crop(img,debug_level)

height = size(img,1); % 1080
width  = size(img,2); % 1920

x1 = round(width*0.0208); % 40
y1 = round(height*0.1759);% 190
x2 = round(width*0.9885); % 1898
%y2 = round(height*0.9296);% 1004 needed if the sync message is shown in the lower part of the screen
y2 = round(height*0.9630);% 1040 needed if no sync message is shown

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
function [img3 result_whiteness] = smart_crop(img2,debug_level)

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

x1 = max(1,result_coord(1)-borderx);
x2 = min(width,result_coord(2)+borderx);
y1 = max(1,result_coord(3)-bordery);
y2 = min(height,result_coord(4)+bordery);

img3 = img2(y1:y2,x1:x2,:);
if (debug_level >= 2)
    figure
    image(img3);
    axis image
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

white_thr = 0.95;

height = size(img2,1);
width  = size(img2,2);

[kx1 ky1 kx2 ky2] = get_test_line(dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_);

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
function str_SID = update_archive(filename,str_SID,SID,crc_new,img_crc_new)

str_SID.(SID).crc       = crc_new;
str_SID.(SID).img_crc   = img_crc_new;

if exist(filename,'file')
    save(filename,'str_SID','-append')
else
    save(filename,'str_SID')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function url = download_pgv_images(id_genea,url_format)
%
% list_filename = download_pgv_images('I10396','http://ars.altervista.org/PhpGedView/treenav.php?ged=caposele&rootid=<PID>');eval(['!gimp' sprintf(' "%s"',list_filename{:}) ' &'])
%

robot = robot_wrapper('init');

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

% give focus to the browser
robot_wrapper('mouse_move',{robot,width*0.20, height*0.105});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.3)

url = strrep(url_format,'<PID>',id_genea);

% give focus to the browser url control
robot_wrapper('mouse_move',{robot,width*0.20, height*0.105});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.2)
robot_wrapper('key_press',{robot,'^(a)'}); % select all
pause(0.2)
robot_wrapper('key_press',{robot,url}); % type the url
pause(0.2)
robot_wrapper('key_press',{robot,sprintf('\n')}); % enter
pause(2) % wait for page load

%robot_wrapper('key_press',{robot,'(F11)'}); % go fullscreen
%pause(0.2)


% scroll the graph upwards
robot_wrapper('mouse_move',{robot,width*0.995, height*0.959}); % upwards
for i_tmp = 1:3
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
end


% scroll the graph upwards
tmp_debug_level = 0;
result_whiteness = get_result_whiteness(tmp_debug_level);
while ( (result_whiteness(3) == 1) && (result_whiteness(4) < 1) ) % while upper border is still white and it is necessary to move the graph upwards...
    % ...move the graph upwards
    robot_wrapper('mouse_move',{robot,width*0.995, height*0.959}); % upwards
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
    result_whiteness = get_result_whiteness(tmp_debug_level);
end
if (result_whiteness(3)<1)
    % if upper border is no longer white, step back 1 step
    robot_wrapper('mouse_move',{robot,width*0.995, height*0.946}); % downwards
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
end

% move the graph a bit to the right
%result_whiteness = get_result_whiteness(tmp_debug_level);
while (result_whiteness(1) < 1) % while left border is not white...
    % ...move the graph to the right
    robot_wrapper('mouse_move',{robot,width*0.01, height*0.47});
    pause(0.2)
    robot_wrapper('mouse_move_with_button_pressed',{robot,'left',width*0.05, height*0.47});
    pause(0.1)
    result_whiteness = get_result_whiteness(tmp_debug_level);
end

%robot_wrapper('key_press',{robot,'(F11)'}); % exit fullscreen
%pause(0.2)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_whiteness = get_result_whiteness(tmp_debug_level)

temp_dwnl = 'temp_img_XYZX$$.jpg';
img = save_img_snapshot(temp_dwnl);
[img3 result_whiteness] = crop_img(img,tmp_debug_level);
delete(temp_dwnl);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function disp_my(ks,debug_level)

if (debug_level > 0)
    disp(ks)
end
