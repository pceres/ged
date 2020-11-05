function rbt_entry_person(str_archivio,id_record)
% rbt_entry_person(str_archivio,56762)
% result = ged('record2msg',str_archivio,56762,'oneline')


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
    
    enter_data(str)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enter_data(str)
% str.name        = 'Nome';
% str.prefix_surname = 'Prefisso del cognome' % es. DEL, DI, DELLA
% str.surname     = 'Cognome';
% str.nickname    = 'Soprannome';
% str.sex         = 1; % 1 --> M; 2 --> F; 3 --> Unknown
% str.birth_date  = '31 OCT 2020';
% str.birth_place = 'Caposele, Avellino, Campania, ITA';
% str.marr_date   = '30 NOV 2020';
% str.marr_place  = 'Lioni, Avellino, Campania, ITA';
% str.death_date  = '31 DEC 2020';
% str.death_place = 'Teora, Avellino, Campania, ITA';

robot = robot_wrapper('init');

%%
kx = 0.35; % don't take start of edit field to avoid text already present
ky = 0.894;
tgt = [1.0000    1.0000    0.9922]; % white color for edit field
thr = 1e-3;
flg_ask = 0;
flg_is_married = check_pixel(robot,kx,ky,tgt,thr,flg_ask); % is the third edit field present?


%%
flg_ask = 1;

kx = 0.26; % check for the Antenati (Ancestor) field
ky = 0.235;
tgt = [0.8431    0.8353    0.8392]; % grey color for Ancestor popup list
thr = 1e-3;
flg_is_grey = check_pixel(robot,kx,ky,tgt,thr,flg_ask);
if flg_is_grey
    flg_ancestor = 1;
    disp('Found Ancestor field.')
    dky_ancestor = 0.028;
else
    flg_ancestor = 0;
    dky_ancestor = 0;
end
disp('todo!!!')

kx = 0.1; % don't take start of edit field to avoid text already present
ky = 0.24+dky_ancestor;
tgt = [0.7098    0.7529    0.8706]; % white color for edit field
thr =  0.05; % threshold has to be a little greater
flg_is_blue = check_pixel(robot,kx,ky,tgt,thr,flg_ask);

kx = 0.1; % don't take start of edit field to avoid text already present
ky = 0.27+dky_ancestor;
tgt = [0.8196    0.8510    0.9333]; % white color for edit field
thr =  0.05; % threshold has to be a little greater
flg_is_light_blue = check_pixel(robot,kx,ky,tgt,thr,flg_ask);

kx = 0.26; % don't take start of edit field to avoid text already present
ky = 0.27+dky_ancestor;
tgt = [0.9333    0.9137    0.6471]; % white color for edit field
thr = 0.05; % threshold has to be a little greater
flg_is_yellow = check_pixel(robot,kx,ky,tgt,thr,flg_ask);

if flg_is_blue && flg_is_light_blue && flg_is_yellow
    %compatible with entry for person, may proceed...
    
    %% ancestor (nascita, adozione, etc.)
    if flg_ancestor
        str_sex.kx = 0.26;
        str_sex.ky = 0.235;
        str_sex.dky = 0.014;
        str_sex.n = 2; % Nascita (Birth)
        select_item(robot,str_sex.kx,str_sex.ky,str_sex.dky,str_sex.n);
    end
    
    %% name
    str_nome.kx  = 0.26;
    str_nome.ky  = 0.296+dky_ancestor;
    str_nome.txt = str.name;
    edit_field(robot,str_nome.kx,str_nome.ky,str_nome.txt)
    
    %% surname prefix (DEL, DI, es. DEL VECCHIO --> DEL)
    str_prefix_cogn.kx  = 0.26;
    str_prefix_cogn.ky  = 0.325+dky_ancestor;
    str_prefix_cogn.txt = str.prefix_surname;
    edit_field(robot,str_prefix_cogn.kx,str_prefix_cogn.ky,str_prefix_cogn.txt)
    
    %% surname (without prefix, es. DEL VECCHIO --> VECCHIO)
    str_cogn.kx  = 0.26;
    str_cogn.ky  = 0.36+dky_ancestor;
    str_cogn.txt = str.surname;
    edit_field(robot,str_cogn.kx,str_cogn.ky,str_cogn.txt)
    
    %%
    str_nick.kx  = 0.26;
    str_nick.ky  = 0.424+dky_ancestor;
    str_nick.txt = str.nickname;
    edit_field(robot,str_nick.kx,str_nick.ky,str_nick.txt)
    
    %%
    str_sex.kx = 0.26;
    str_sex.ky = 0.58+dky_ancestor;
    str_sex.dky = 0.014;
    str_sex.n = str.sex;
    select_item(robot,str_sex.kx,str_sex.ky,str_sex.dky,str_sex.n);
    
    
    
    %% first group (birth)
    str_birth_date.kx  = 0.26;
    str_birth_date.ky  = 0.638+dky_ancestor;
    str_birth_date.txt = str.birth_date;
    edit_field(robot,str_birth_date.kx,str_birth_date.ky,str_birth_date.txt)
    
    %%
    str_birth_place.kx  = 0.26;
    str_birth_place.ky  = 0.68+dky_ancestor;
    str_birth_place.txt = str.birth_place;
    edit_field(robot,str_birth_place.kx,str_birth_place.ky,str_birth_place.txt)
    
    if flg_is_married
        disp('marriage information required')
        str_2nd_date.txt = str.marr_date;
        str_2nd_place.txt = str.marr_place;
        str_death_date.txt = str.death_date;
        str_death_place.txt = str.death_place;
    else
        disp('no marriage information required')
        str_2nd_date.txt = str.death_date;
        str_2nd_place.txt = str.death_place;
        str_death_date.txt = '';
        str_death_place.txt = '';
    end
        
    %% second group (marriage or death)
    str_2nd_date.kx  = 0.26;
    str_2nd_date.ky  = 0.766+dky_ancestor;
    edit_field(robot,str_2nd_date.kx,str_2nd_date.ky,str_2nd_date.txt)
    
    %%
    str_2nd_place.kx  = 0.26;
    str_2nd_place.ky  = 0.805+dky_ancestor;
    edit_field(robot,str_2nd_place.kx,str_2nd_place.ky,str_2nd_place.txt)
    
    %% third group (death)
    str_death_date.kx  = 0.26;
    str_death_date.ky  = 0.894+dky_ancestor;
    edit_field(robot,str_death_date.kx,str_death_date.ky,str_death_date.txt)
    
    %%
    str_death_place.kx  = 0.26;
    str_death_place.ky  = 0.934+dky_ancestor;
    edit_field(robot,str_death_place.kx,str_death_place.ky,str_death_place.txt)
    
    
    %% source
    
    screenSize = get(0, 'screensize');
    width  = screenSize(3);
    height = screenSize(4);
    
    str_form.kx  = 0.16;
    str_form.ky  = 0.934+dky_ancestor;
    robot_wrapper('mouse_move',{robot,width*str_form.kx, height*str_form.ky});
    
    robot_wrapper('mouse_click',{robot,'left'});
    robot_wrapper('key_press',{robot,'{END}'}); % move to the end of page
    pause(0.3)
    
    % since here we are at the end of page, so the Ancestor offset
    % dky_ancestor must be no longer used
    
    %%
    str_src_link.kx  = 0.04;
    str_src_link.ky  = 0.775;
    robot_wrapper('mouse_move',{robot,width*str_src_link.kx, height*str_src_link.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    
    %%
    str_src_id.kx  = 0.28;
    str_src_id.ky  = 0.81;
    robot_wrapper('mouse_move',{robot,width*str_src_id.kx, height*str_src_id.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    robot_wrapper('key_press',{robot,'^(a)'}); % select all
    robot_wrapper('key_press',{robot,'S16'}); % move to the end of page
    
    %%
    robot_wrapper('mouse_move',{robot,width*str_form.kx, height*str_form.ky});
    robot_wrapper('mouse_click',{robot,'left'});
    
    %%
    str_src_link.kx  = 0.01;
    str_src_link.ky  = 0.79;
    robot_wrapper('mouse_move',{robot,width*str_src_link.kx, height*str_src_link.ky});
    %robot_wrapper('mouse_click',{robot,'left'});
    
else
    imgfile = 'temp.jpg';
    robot_wrapper('save_snapshot',{robot,imgfile});
    img=imread(imgfile);
    image(img);
    
    fprintf(1,'flg_is_blue=%d\nflg_is_light_blue=%d\nflg_is_yellow=%d\n',flg_is_blue,flg_is_light_blue,flg_is_yellow);
    error('incompatible with PGV entry form for a person')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function select_item(robot,kx,ky,dky,n)

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('mouse_move',{robot,width*kx, height*ky});


robot_wrapper('mouse_click',{robot,'left'});
pause(0.03)

robot_wrapper('mouse_move',{robot,width*kx, height*(ky+n*dky)});
robot_wrapper('mouse_click',{robot,'left'});
%pause(0.03)



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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_in_target color] = check_pixel(robot,kx,ky,tgt,thr,flg_ask)

imgfile = 'temp.jpg';

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('save_snapshot',{robot,imgfile});
img=imread(imgfile);

robot_wrapper('mouse_move',{robot,width*kx, height*ky});

x=round(width*kx);
y=round(height*ky);
image(img);
hold on
plot(x,y,'ro')
dots = img(y,x,:);
dotr = double(dots(:,:,1))/255;
dotg = double(dots(:,:,2))/255;
dotb = double(dots(:,:,3))/255;
color = [dotr dotg dotb];
err = sum(abs(tgt-color));
if err < thr
    flg_in_target = 1;
else
    flg_in_target = 0;
    if flg_ask
        fprintf(1,'err=%f\n',err);
        disp(color);
        input('Should I stop here? Enter to go on, Ctrl-C to stop')
    end
end
