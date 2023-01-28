function rbt_entry_person(str_archivio,id_record)
% rbt_entry_person(str_archivio,56762)
% result = ged('record2msg',str_archivio,56762,'oneline')
%
% tested on:
% - Slackware 15+ (Current)
% - Firefox 109.0
% - resolution 2048x1152
%
% Before using ensure that:
% 1) Firefox zoom level is 0 (neutral)
% 2) Firefox find tab in the lower part of the page is not visible
% 3) Firefox upper menu shown are:
%    - menu (file, edit, ecc.);
%    - page tabs;
%    - address;
%    - preferred toolbar
% 

debug = 0; % set to 1 to enable debug messages and plots

screensize = get(0,'screensize');
%width  = screensize(3);
height = screensize(4);

switch height
    case 1080
        screen_type = 1; % [1,2] 1 --> Slackware 15 on laptop (1920x1080); 2 --> Slackware 15 on VNC (1280x1024)
    case 1024
        screen_type = 2; % [1,2] 1 --> Slackware 15 on laptop (1920x1080); 2 --> Slackware 15 on VNC (1280x1024)
    case 1152
        screen_type = 3; % [1,2,3] 1 --> Slackware 15+ on laptop (2048x1152);
    otherwise
        error('Unrecognized screen height %d!',height)
end

fprintf(1,'\nFilling field for record %d\n\n',id_record)
disp(ged('record2msg',str_archivio,id_record,'oneline'))

ind_record = strmatch(num2str(id_record),str_archivio.archivio(:,str_archivio.indici_arc.id_file));
%%
if isempty(ind_record)
    error('id %d not found!',id_record)
else
    result_tmp = uploader('analyse_record',{str_archivio,id_record});
    str_record_info = result_tmp.str_record_info;
    
    %%
    str.name        = str_record_info.ks_givn;
    str.prefix_surname = str_record_info.ks_prefix_surn;
    str.surname     = str_record_info.ks_surn;
    str.nickname    = ''; % no nickname recorded in file
    str.sex         = strmatch(str_record_info.sex,{'M','F',''},'exact'); % 1 --> M; 2 --> F; 3 --> Unknown
    str.birth_date  = str_record_info.ks_nasc;
    str.birth_place = str_record_info.ks_nasc_luo;
    str.marr_date   = str_record_info.ks_matr;
    str.marr_place  = str_record_info.ks_matr_luo;
    str.death_date  = str_record_info.ks_mort;
    str.death_place = str_record_info.ks_mort_luo;
    
    enter_data(str,debug,screen_type)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enter_data(str,debug,screen_type)
% str.name        = 'Nome';
% str.prefix_surname = 'Prefisso del cognome'; % es. DEL, DI, DELLA
% str.surname     = 'Cognome';
% str.nickname    = 'Soprannome';
% str.sex         = 1; % 1 --> M; 2 --> F; 3 --> Unknown
% str.birth_date  = '31 OCT 2020';
% str.birth_place = 'Caposele, Avellino, Campania, ITA';
% str.marr_date   = '30 NOV 2020';
% str.marr_place  = 'Lioni, Avellino, Campania, ITA';
% str.death_date  = '31 DEC 2020';
% str.death_place = 'Teora, Avellino, Campania, ITA';
%
% screen_type [1,2]  1 --> Slackware 15 on laptop; 2 --> Slackware 15 on VNC (1280x1024)


robot = robot_wrapper('init');

dy_popup = 0.025; % delta y between popupoptions (0.014 on old Firefox)
ks_source = 'S16'; % default source


%% try to get focus to the form page
screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

kx_focus = 0.1;
ky_focus = 0.3;
robot_wrapper('mouse_move',{robot,width*kx_focus, height*ky_focus});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.004);

robot_wrapper('key_press',{robot,'^({HOME})'});
pause(0.2);

%% analyse the page to detect the Name field vertical coordinate
[flg_error_page flg_ancestor ky_name ky_sex  ky_birth_date] = detect_ky(robot,debug);

%%
if ~flg_error_page
    % page is ok, do mode specific checks
    
    kx = 0.35; % don't sample at the beginning of edit field to avoid text already present
    ky = 0.640+ky_name; % just in the middle of the death location edit field (if it exists) % 0.684+ky_name on 1920x1080 
    tgt =  [0.9333    0.9137    0.6471]; % yellow color for edit field
    thr = 0.05;
    flg_ask = 0;
    descr = '"Death location" edit field (to detect if marriage fields are present)';
    flg_is_married = check_pixel(robot,kx,ky,tgt,thr,flg_ask,descr,debug); % is the third edit field present?
    
    kx = 0.15; % don't sample at the beginning of edit field to avoid text already present
    ky = 0+ky_name;
    tgt = [0.7098    0.7529    0.8706]; % blue color for edit field
    thr =  0.05; % threshold has to be a little greater
    descr = 'First check point (must be blue if the page is displayed)';
    flg_is_blue = check_pixel(robot,kx,ky,tgt,thr,flg_ask,descr,debug);
    
    kx = 0.15; % don't sample at the beginning of edit field to avoid text already present
    ky = 0.028+ky_name;
    tgt = [0.8196    0.8510    0.9333]; % light blue color for edit field
    thr =  0.05; % threshold has to be a little greater
    descr = 'Second check point (must be light blue if the page is displayed)';
    flg_is_light_blue = check_pixel(robot,kx,ky,tgt,thr,flg_ask,descr,debug);
    
    kx = 0.265; % don't sample at the beginning of edit field to avoid text already present
    ky = 0.028+ky_name;
    tgt = [0.9333    0.9137    0.6471]; % yellow color for edit field
    thr = 0.07; % threshold has to be a little greater
    descr = 'Third check point (must be yellow if the page is displayed)';
    flg_is_yellow = check_pixel(robot,kx,ky,tgt,thr,flg_ask,descr,debug);
    
    pause(0.04);
else
    flg_is_blue         = 0;
    flg_is_light_blue   = 0;
    flg_is_yellow       = 0;
end

if ~flg_error_page && flg_is_blue && flg_is_light_blue && flg_is_yellow
    %compatible with entry for person, may proceed...
    
    %% ancestor (nascita, adozione, etc.)
    if flg_ancestor
        str_ancestor.kx = 0.26;
        str_ancestor.ky = -0.03+ky_name;
        str_ancestor.dky = dy_popup;
        str_ancestor.n = 2; % Nascita (Birth)
        select_item(robot,str_ancestor.kx,str_ancestor.ky,str_ancestor.dky,str_ancestor.n);
    end
    
    %% name
    str_nome.kx  = 0.26;
    str_nome.ky  = 0.055+ky_name;
    str_nome.txt = str.name;
    edit_field(robot,str_nome.kx,str_nome.ky,str_nome.txt)
    
    %% surname prefix (DEL, DI, es. DEL VECCHIO --> DEL)
    str_prefix_cogn.kx  = 0.26;
    str_prefix_cogn.ky  = 0.084+ky_name;
    str_prefix_cogn.txt = str.prefix_surname;
    edit_field(robot,str_prefix_cogn.kx,str_prefix_cogn.ky,str_prefix_cogn.txt)
    
    %% surname (without prefix, es. DEL VECCHIO --> VECCHIO)
    str_cogn.kx  = 0.26;
    str_cogn.ky  = 0.120+ky_name;
    str_cogn.txt = str.surname;
    edit_field(robot,str_cogn.kx,str_cogn.ky,str_cogn.txt)
    
    %% nickname
    str_nick.kx  = 0.26;
    str_nick.ky  = 0.178+ky_name; % 0.188+ky_name;
    str_nick.txt = str.nickname;
    edit_field(robot,str_nick.kx,str_nick.ky,str_nick.txt)
    
    %% sex
    str_sex.kx = 0.26;
    str_sex.ky = ky_sex; % 0.34+ky_name;
    str_sex.dky = dy_popup;
    str_sex.n = str.sex;
    select_item(robot,str_sex.kx,str_sex.ky,str_sex.dky,str_sex.n);
    
    
    
    %% first group (birth)
    str_birth_date.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_birth_date.ky  =  0.397+ky_name;
    else
        % VNC
        str_birth_date.ky  =  ky_birth_date-0.007;
    end
    str_birth_date.txt = str.birth_date;
    edit_field(robot,str_birth_date.kx,str_birth_date.ky,str_birth_date.txt)
    
    %%
    str_birth_place.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_birth_place.ky  = 0.441+ky_name;
    else
        % VNC
        str_birth_place.ky  = ky_birth_date+0.031;
    end
    str_birth_place.txt = str.birth_place;
    edit_field(robot,str_birth_place.kx,str_birth_place.ky,str_birth_place.txt)
    
    if flg_is_married
        % there are 3 sets of date/place fields to be entered. 2nd is for
        % marriage, 3rd for death
        disp('marriage information required')
        str_2nd_date.txt = str.marr_date;
        str_2nd_place.txt = str.marr_place;
        str_death_date.txt = str.death_date;
        str_death_place.txt = str.death_place;
    else
        % there are 2 sets of date/place fields to be entered. 2nd is for death        
        disp('no marriage information required')
        str_2nd_date.txt = str.death_date;
        str_2nd_place.txt = str.death_place;
        str_death_date.txt = '';
        str_death_place.txt = '';
    end
    
    %% second group (marriage or death)
    str_2nd_date.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_2nd_date.ky  = 0.527+ky_name;
    else
        % VNC
        str_2nd_date.ky  = ky_birth_date+0.110; % 0.126 on 1920x1080
    end
    edit_field(robot,str_2nd_date.kx,str_2nd_date.ky,str_2nd_date.txt)
    
    %%
    str_2nd_place.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_2nd_place.ky  = 0.566+ky_name;
    else
        % VNC
        str_2nd_place.ky  = ky_birth_date+0.145; % 0.165 on 1920x1080
    end
    edit_field(robot,str_2nd_place.kx,str_2nd_place.ky,str_2nd_place.txt)
    
    %% third group (death)
    str_death_date.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_death_date.ky  = 0.647+ky_name;
    else
        % VNC
        str_death_date.ky  = ky_birth_date+0.225; % 0.255 on 1920x1080
    end
    edit_field(robot,str_death_date.kx,str_death_date.ky,str_death_date.txt)
    
    %%
    str_death_place.kx  = 0.26;
    if screen_type == 1
        % laptop
        str_death_place.ky  = 0.687+ky_name;
    else
        % VNC
        str_death_place.ky  = ky_birth_date+0.265; % 0.295 on 1920x1080
    end
    edit_field(robot,str_death_place.kx,str_death_place.ky,str_death_place.txt)
    
    
    %% source
    
    screenSize = get(0, 'screensize');
    width  = screenSize(3);
    height = screenSize(4);
    
    %% scroll down
    str_form.kx  = 0.16;
    str_form.ky  = 0.695+ky_name;
    robot_wrapper('mouse_move',{robot,width*str_form.kx, height*str_form.ky});
    
    robot_wrapper('mouse_click',{robot,'left'});
    robot_wrapper('key_press',{robot,'{END}'}); % move to the end of page
    pause(0.3)
    
    % since here we are at the end of page, the name field vertical offset
    % ky_name must be no longer used
    
    %% clock on "source" to make the other source fields be shown
    str_src_link.kx  = 0.04;
    if screen_type == 1
        % laptop
        str_src_link.ky  = 0.769; % 0.775 on old Firefox
    else
        % VNC
        str_src_link.ky  = 0.78; % 0.76 on 1920x1080
    end
    robot_wrapper('mouse_move',{robot,width*str_src_link.kx, height*str_src_link.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    
    %% enter source
    str_src_id.kx  = 0.28;
    if screen_type == 1
        % laptop
        str_src_id.ky  = 0.81;
    else
        % VNC
        str_src_id.ky  = 0.816; % 0.79 on 1920x1080
    end
    robot_wrapper('mouse_move',{robot,width*str_src_id.kx, height*str_src_id.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    robot_wrapper('key_press',{robot,'^(a)'}); % select all
    robot_wrapper('key_press',{robot,ks_source}); % insert default source
    
    %% click outside to make the suggestion popup disappear
    robot_wrapper('mouse_move',{robot,width*str_form.kx, height*str_form.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    
    %%
    str_src_link2.kx  = 0.01;
    str_src_link2.ky = str_src_link.ky+0.010; % 0.012 on 1920x1080
    robot_wrapper('mouse_move',{robot,width*str_src_link2.kx, height*str_src_link2.ky});
    %robot_wrapper('mouse_click',{robot,'left'});
    
else
    imgfile = 'temp.jpg';
    robot_wrapper('save_snapshot',{robot,imgfile});
    img=imread(imgfile);
    image(img);
    
    fprintf(1,'flg_is_blue=%d\nflg_is_light_blue=%d\nflg_is_yellow=%d\n',flg_is_blue,flg_is_light_blue,flg_is_yellow);
    error('It seems that the page is not a PGV entry form for a person!')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function select_item(robot,kx,ky,dky,n)

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('mouse_move',{robot,width*kx, height*ky});


robot_wrapper('mouse_click',{robot,'left'});
pause(0.1)

robot_wrapper('mouse_move',{robot,width*kx, height*(ky+n*dky)});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.03)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function edit_field(robot,kx,ky,txt)

if isempty(txt)
    return
end

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('mouse_move',{robot,width*kx, height*ky});
robot_wrapper('mouse_click',{robot,'left'});
%pause(0.03)

robot_wrapper('key_press',{robot,'^(a)'}); % select all
%pause(0.05)
robot_wrapper('key_press',{robot,txt}); % type the text
robot_wrapper('key_press',{robot,'{TAB}'}); % dismiss possible pop up list, and pass to next field



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_in_target color] = check_pixel(robot,kx,ky,tgt,thr,flg_ask,descr,debug)
% tgt: [k_red k_green k_blue], [0..1] target RGB color
% kx, ky: relative coordinates (with respect to full screen size) for pixel
% flg_ask: ask for user interaction in case of pixel color different from target
% thr: [0..1]: max distance between target and measured color

imgfile = 'temp.jpg';

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('save_snapshot',{robot,imgfile});
img=imread(imgfile);

%% check for third field (must be a white pixel)
robot_wrapper('mouse_move',{robot,width*kx, height*ky});

x=round(width*kx);
y=round(height*ky);

if debug
    figure
    image(img);
    hold on
    plot(x,y,'ro')
end
dots = img(y,x,:);
dotr = double(dots(:,:,1))/255;
dotg = double(dots(:,:,2))/255;
dotb = double(dots(:,:,3))/255;
color = [dotr dotg dotb];
err = sum(abs(tgt-color));
if err < thr
    flg_in_target = 1;
    msg = 'Match!';
else
    flg_in_target = 0;
    msg = '*** NO MATCH !!!';
    if flg_ask
        fprintf(1,'err=%f\n',err);
        disp(color);
        input('Should I stop here? Enter to go on, Ctrl-C to stop')
    end
end

if debug
    fprintf(1,'\n%s\n\tx: %d (%.3f) y: %d (%.3f)\n\tRGB [%.4f %.4f %.4f] (target: [%.4f %.4f %.4f])\n\terror %.4f (threshold: %.4f) - %s\n',descr,x,kx,y,ky,color(1),color(2),color(3),tgt(1),tgt(2),tgt(3),err,thr,msg)
    
    % % figure plotting the measured and target color
    % hf = gcf;
    % ky = 0.028+ky_name;figure(100)
    % hold off
    % thickness = 20;
    % plot([0 1],[2 2],'LineWidth',thickness,'Color',tgt)
    % hold on
    % plot([0 1],[1 1],'LineWidth',thickness,'Color',color)
    % axis([0 1 0.5 2.5]);
    % legend({'measure','target'})
    % set(gcf,'Position',[1240 560 560 420])
    % title(msg)
    % figure(hf)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_error_page flg_ancestor ky_name ky_sex ky_birth_date] = detect_ky(robot,debug)

imgfile = 'temp.jpg';

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('save_snapshot',{robot,imgfile});
img=imread(imgfile);


%% detect intervals with blue color

kx1 = 0.15;
tgt = [0.7098 0.7529 0.8706]; % look for blue
descr = 'First blue area';

x1 = round(kx1*width);
dots = img(:,x1,:); % all points;
dotr = double(dots(:,:,1))/255;
dotg = double(dots(:,:,2))/255;
dotb = double(dots(:,:,3))/255;
thr = 3e-2;
[ind_rise_edge ind_fall_edge v_y v_l v_ky v_kl] = analyse_delta_y(dotr,dotg,dotb,tgt,thr);
[temp ind_sort] = sort(ind_rise_edge);

ky_thr = 0.3;
kl_thr = 0.01;
ind_ok_blue = find(v_ky(ind_sort)<ky_thr &  v_kl(ind_sort)>kl_thr);

ky_thr = 0.51;
ind_ok_sex = find(v_ky(ind_sort)>ky_thr &  v_kl(ind_sort)>kl_thr);

switch length(ind_ok_blue)
    case 1
        % only one blue area: Name (Nome) field
        ky_name = v_ky(ind_sort(ind_ok_blue));
        ky_sex  = v_ky(ind_sort(ind_ok_sex(1)));  % Sex field is the first
        ky_birth_date = v_ky(ind_sort(ind_ok_sex(3)));  % Birth date field is the third
        flg_ancestor = 0;
        flg_error_page = 0;
    case 2
        % two blue areas: Ancestors (Antenati) and Name (Nome) fields
        ky_name = v_ky(ind_sort(ind_ok_blue(2))); % Name field is the second one
        ky_sex  = v_ky(ind_sort(ind_ok_sex(1)));  % Sex field is the first
        ky_birth_date = v_ky(ind_sort(ind_ok_sex(3)));  % Birth date field is the third
        flg_ancestor = 1;
        flg_error_page = 0;
    otherwise
        % zero or more than two blue areas: there is an error in the page,
        % maybe is is fully or partially hidden by other windows
        ky_name = NaN; % Name field not detected
        ky_sex  = NaN;
        ky_birth_date = NaN;
        flg_ancestor = NaN;
        flg_error_page = 1;
end
y_name = round(ky_name*height);
y_sex  = round(ky_sex*height);
y_birth_date = round(ky_birth_date*height);


if debug
    fprintf(1,'\n%s\n\tmiddle of largest range (tgt RGB = [%d %d %d] - threshold: %.4f - x1 = %d (kx1=%.4f) )\n\ty_name = %d (ky_name = %.4f)\n',descr,tgt(1),tgt(2),tgt(3),thr,x1,kx1,y_name,ky_name)

    figure(110)
    hold off
    image(img);
    hold on
    plot([1 1]*x1,[1 length(dotr)],'r',ones(length(v_y),1)*x1,v_y,'.k',ones(length(v_y(v_l>0)),1)*x1,v_y(v_l>0),'ok',x1,y_name,'ro',x1,y_sex,'ro',x1,y_birth_date,'ro')
    title(descr)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ind_rise_edge ind_fall_edge v_y v_l v_ky v_kl] = analyse_delta_y(dotr,dotg,dotb,tgt,thr)

screenSize = get(0, 'screensize');
%width  = screenSize(3);
height = screenSize(4);

abserr = abs([dotr dotg dotb]-repmat(tgt,length(dotr),1)); % [0..1]
d = sqrt(sum(abserr.^2,2))/sqrt(3); % [0..1] 0 -> identical colors, 1 -> totally different colors

err = d<=thr;
err_prev = [0; err(1:end-1)];
rise_edge = (err & ~err_prev);
ind_rise_edge = find(rise_edge);
fall_edge = (~err & err_prev);
ind_fall_edge = find(fall_edge)-1;

if ~isempty(ind_fall_edge) && ~isempty(ind_rise_edge) && (ind_fall_edge(1)<ind_rise_edge(1))
    % discard first unmatched falling edge
    ind_fall_edge = ind_fall_edge(2:end);
end

if ~isempty(ind_fall_edge) && ~isempty(ind_rise_edge) && (ind_fall_edge(end)<ind_rise_edge(end))
    % add a virtual falling edge if the line ends in white at the border of the screen
    ind_fall_edge(end+1) = length(dotr);
end

[temp ind_sort] = sort(ind_rise_edge-ind_fall_edge);
ind_rise_edge = ind_rise_edge(ind_sort);
ind_fall_edge = ind_fall_edge(ind_sort);

v_y = round(mean([ind_fall_edge ind_rise_edge],2));
v_l = ind_fall_edge-ind_rise_edge;

v_ky = v_y/height;
v_kl = v_l/height;
