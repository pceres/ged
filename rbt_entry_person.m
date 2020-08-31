function rbt_entry_person(str_archivio,id)
% rbt_entry_person(str_archivio,56762)
% result = ged('record2msg',str_archivio,56762,'oneline')

ind = strmatch(num2str(id),str_archivio.archivio(:,str_archivio.indici_arc.id_file));
if isempty(ind)
    error('ID %d not found!',id)
else
    record = str_archivio.archivio(ind,:);
    
    input('TODO: record to str struct!')
    
    str.name        = 'Nome';
    str.surname     = 'Cognome';
    str.nickname    = 'Soprannome';
    str.sex         = 1; % 1 --> M; 2 --> F; 3 --> Unknown
    str.birth_date  = '31 OCT 2020';
    str.birth_place = 'Caposele, Avellino, Campania, ITA';
    str.marr_date   = '30 NOV 2020';
    str.marr_place  = 'Lioni, Avellino, Campania, ITA';
    str.death_date  = '31 DEC 2020';
    str.death_place = 'Teora, Avellino, Campania, ITA';
    
    enter_data(str)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enter_data(str)
% str.name        = 'Nome';
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

flg_is_married = check_pixel(robot,kx,ky,tgt,thr);


%%
kx = 0.1; % don't take start of edit field to avoid text already present
ky = 0.24;
tgt = [0.7098    0.7529    0.8706]; % white color for edit field
thr = 1e-3;
flg_is_blue = check_pixel(robot,kx,ky,tgt,thr);

kx = 0.1; % don't take start of edit field to avoid text already present
ky = 0.27;
tgt = [0.8196    0.8510    0.9333]; % white color for edit field
thr = 1e-3;
flg_is_light_blue = check_pixel(robot,kx,ky,tgt,thr);

kx = 0.26; % don't take start of edit field to avoid text already present
ky = 0.27;
tgt = [0.9333    0.9137    0.6471]; % white color for edit field
thr = 1e-3;
flg_is_yellow = check_pixel(robot,kx,ky,tgt,thr);

if flg_is_blue && flg_is_light_blue && flg_is_yellow
    %compatible with entry for person, may proceed...
    
    %%
    str_nome.kx  = 0.26;
    str_nome.ky  = 0.296;
    str_nome.txt = str.name;
    edit_field(robot,str_nome.kx,str_nome.ky,str_nome.txt)
    
    %%
    str_cogn.kx  = 0.26;
    str_cogn.ky  = 0.36;
    str_cogn.txt = str.surname;
    edit_field(robot,str_cogn.kx,str_cogn.ky,str_cogn.txt)
    
    %%
    str_nick.kx  = 0.26;
    str_nick.ky  = 0.424;
    str_nick.txt = str.nickname;
    edit_field(robot,str_nick.kx,str_nick.ky,str_nick.txt)
    
    %%
    str_sex.kx = 0.26;
    str_sex.ky = 0.58;
    str_sex.dky = 0.014;
    str_sex.n = str.sex;
    select_item(robot,str_sex.kx,str_sex.ky,str_sex.dky,str_sex.n);
    
    
    
    %%
    str_birth_date.kx  = 0.26;
    str_birth_date.ky  = 0.638;
    str_birth_date.txt = str.birth_date;
    edit_field(robot,str_birth_date.kx,str_birth_date.ky,str_birth_date.txt)
    
    %%
    str_birth_place.kx  = 0.26;
    str_birth_place.ky  = 0.68;
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
        
    %%
    str_2nd_date.kx  = 0.26;
    str_2nd_date.ky  = 0.766;
    edit_field(robot,str_2nd_date.kx,str_2nd_date.ky,str_2nd_date.txt)
    
    %%
    str_2nd_place.kx  = 0.26;
    str_2nd_place.ky  = 0.805;
    edit_field(robot,str_2nd_place.kx,str_2nd_place.ky,str_2nd_place.txt)
    
    %%
    str_death_date.kx  = 0.26;
    str_death_date.ky  = 0.894;
    edit_field(robot,str_death_date.kx,str_death_date.ky,str_death_date.txt)
    
    %%
    str_death_place.kx  = 0.26;
    str_death_place.ky  = 0.934;
    edit_field(robot,str_death_place.kx,str_death_place.ky,str_death_place.txt)
else
    error('incompatible with entry for single unmarried person')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function select_item(robot,kx,ky,dky,n)

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('mouse_move',{robot,width*kx, height*ky});


robot_wrapper('mouse_click',{robot,'left'});
%pause(0.03)

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
function [flg_in_target color] = check_pixel(robot,kx,ky,tgt,thr)

imgfile = 'temp.jpg';

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

robot_wrapper('save_snapshot',{robot,imgfile});
img=imread(imgfile);

x=round(width*kx);
y=round(height*ky);
%image(img);
%hold on
%plot(x,y,'ro')
dots = img(y,x,:);
dotr = double(dots(:,:,1))/255;
dotg = double(dots(:,:,2))/255;
dotb = double(dots(:,:,3))/255;
color = [dotr dotg dotb];
%disp(color);
err = sum(abs(tgt-color));
if err < thr
    flg_in_target = 1;
else
    flg_in_target = 0;
end

robot_wrapper('mouse_move',{robot,width*kx, height*ky});
