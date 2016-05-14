function img

pgvroot = 'http://ars.altervista.org/PhpGedView/';
gedcom = 'caposele';
SID = 'I18';
SID = 'I0000';


str_pgv_img = struct('pgvroot',pgvroot,'gedcom',gedcom,'SID',SID);


crc_module = 9999;

filename_arc = 'archivio.mat';
str_SID = load_str_SID(filename_arc);

url_pgvtext = [pgvroot 'treenav.php?ged=' gedcom '&rootid=' SID];
text0 = urlread(url_pgvtext);
text = regexp(text0,'<div id="out_nav".*','match'); % only crc the useful part with genealogical data
text = text{1};
% load archivio_text text

crc_new = round(rand*crc_module)%get_crc(text,crc_module);

filename = SID2filename(SID);
if exist(filename,'file')
    img_old = imread(filename);
    img_crc_new = get_crc(img_old(:),crc_module);
else
    img_crc_new = NaN;
end

flg_rebuild = needs_rebuild(str_SID,SID,crc_new,img_crc_new);

filename_out = filename; % rewrite the image

if flg_rebuild
    img_new = rebuild_img(str_pgv_img,filename_out);
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
function flg_rebuild = needs_rebuild(str_SID,SID,crc_new,img_crc_new)

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
    fprintf('Different CRC for data for id %s: %d --> %d\n',SID,crc_old,crc_new)
else
    fprintf('No CRC change in data for id %s: %d\n',SID,crc_new)
end

if (img_crc_old ~= img_crc_new)
    flg_rebuild = 1;
    fprintf('Need to rebuild image for id %s\n',SID)
else
    fprintf('Unchanged image for id %s\n',SID)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = SID2filename(SID)

filename = [SID '.jpg'];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img4 = rebuild_img(str_pgv_img,filename_out)

jpg_quality = 95;

pgvroot = str_pgv_img.pgvroot;
gedcom = str_pgv_img.gedcom;
SID = str_pgv_img.SID;

filename = SID2filename(SID);

fprintf('Rebuilding image %s for id %s...\n',filename,SID)

% download the image file
list_images = {SID};
url_format = [pgvroot 'treenav.php?ged=' gedcom '&rootid=<PID> '];
list_filename = download_pgv_images(list_images,url_format);

filename_dwnl = ['snapshot' filesep filename];
fprintf('\tDownloaded %s\n',filename_dwnl)

img = imread(filename_dwnl);
debug = 0;
[img3 result_whiteness] = crop_img(img,debug);
fprintf('\tCropped %s\n',filename)

imwrite(img3,filename_out,'jpeg','mode','lossy','quality',jpg_quality);
img4 = imread(filename_out); % reload the image to get the real data



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img3 result_whiteness] = crop_img(img,debug)

if debug
    image(img)
end

debug1 = debug;
img2 = static_crop(img,debug1);

debug2 = debug;
[img3 result_whiteness] = smart_crop(img2,debug2);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img2 = static_crop(img,debug)

height = size(img,1); % 1080
width  = size(img,2); % 1920

x1 = round(width*0.0208); % 40
y1 = round(height*0.1759);% 190
x2 = round(width*0.9885); % 1898
y2 = round(height*0.9296);% 1004

img2 = img(y1:y2,x1:x2,:);

if debug
    image(img);
    axis image
    hold on
    plot(x1,y1,'ro');
    plot(x2,y2,'ro');
    fill([x1 x1 x2 x2],[y1 y2 y2 y1],[1 0 0],'FaceAlpha',0.1,'EdgeAlpha',0);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img3 result_whiteness] = smart_crop(img2,debug)

if debug
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
    
    [k whiteness] = detect_border(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,h,debug);
    result_k(i_dir) = k;
    result_whiteness(i_dir) = whiteness;
end

fitness_crop = sum(1-result_whiteness)+sum(result_whiteness<1)*10

result_coord = round([result_k(1:2)*width result_k(3:4)*height]);

borderx = 25;
bordery = 25;

x1 = max(1,result_coord(1)-borderx);
x2 = min(width,result_coord(2)+borderx);
y1 = max(1,result_coord(3)-bordery);
y2 = min(height,result_coord(4)+bordery);

img3 = img2(y1:y2,x1:x2,:);
if debug
    figure
    image(img3);
    axis image
    hold on
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [k whiteness] = detect_border(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,h,debug)

k_ok = 0;
k_nok = 1;

ancora = 1;
coord_old = inf;

% try to detect full white line
while ancora
    k_ = (k_ok+k_nok)/2;
    tmp_debug = 0;
    if strcmp(dir_tag,'up')
        %         tmp_debug = 1;
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
[ok coord whiteness] = is_line_all_white(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_ok,h,debug);



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
function [ok coord whiteness] = is_line_all_white(img2,dir_tag,kx1_ref,ky1_ref,kx2_ref,ky2_ref,k_,h,debug)

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

if debug
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
function list_filename = download_pgv_images(list_images,url_format)
%
% list_filename = download_pgv_images({'I10396'},'http://ars.altervista.org/PhpGedView/treenav.php?ged=caposele&rootid=<PID>');eval(['!gimp' sprintf(' "%s"',list_filename{:}) ' &'])
%

dest_folder = 'snapshot';

robot = robot_wrapper('init');

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

% give focus to the browser
robot_wrapper('mouse_move',{robot,width*0.20, height*0.105});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.3)

if ~exist(dest_folder,'dir')
    mkdir(dest_folder)
end

list_filename = {};
for i_atl = 1:length(list_images)
%     id       = data{i_atl,str.ind_id};
%     name     = data{i_atl,str.ind_name};
%     % image    = data{i_atl,str.ind_image};
%     id_genea = data{i_atl,str.ind_id_genea};
    id_genea = list_images{i_atl};
    
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
    
    % scroll the window
    robot_wrapper('mouse_move',{robot,width*0.995, height*0.959});
    for i_tmp = 1:4
        robot_wrapper('mouse_click',{robot,'left'});
        pause(0.2)
    end
    
    % move graph a bit to the right
    robot_wrapper('mouse_move',{robot,width*0.01, height*0.47})
    pause(0.2)
    robot_wrapper('mouse_move_with_button_pressed',{robot,'left',width*0.055, height*0.47})
    
    
    %%input('Please position the graph in the middle of the screen, then press ENTER','s')
    
    filename = [dest_folder filesep id_genea '.jpg'];
    robot_wrapper('save_snapshot',{robot,filename});
    list_filename{end+1} = filename; %#ok<AGROW>
    
    fprintf(1,'%6s %s\n',id_genea,url)
end
