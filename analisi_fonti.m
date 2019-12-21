function result = analisi_fonti(action,params)
% 
% result = analisi_fonti(action,params)
% 
%
% % es.
%
% % locate a record by type and date (default action in case of missing
% % inputs)
% result = analisi_fonti('search',{});
% 
% % open an image:
% result = analisi_fonti('open_image',{'imgB0002234',1});
% 
% % check for different images with the same name:
% result = analisi_fonti('check_conflicts',{});
%
% % index analysis (parameter is a regexp filter to match volumes)
% result = analisi_fonti('analyse',{'San Lorenzo'});
% result = analisi_fonti('analyse',{'Anagrafe'});
% result = analisi_fonti('analyse',{'LDS'});
%
% % change image name format and numbering
% result = analisi_fonti('reformat_images',{fullpath_and_format,img_fmt_new,start_num})
% result = analisi_fonti('reformat_images',{'/home/ceres/Desktop/work/genealogia_fonti/Salerno_cellulare/20150818_*.jpg','P*.JPG',8181658})
% % returns result.matr_rename = {oldfile1,newfile1;oldfile2,newfile2;...}
%
% % create num_spaces spaces between two adjacent images (fullpath points
% % to the first image to be shifted)
% result = analisi_fonti('insert_space',{fullpath,num_spaces})
% result = analisi_fonti('insert_space',{'/home/ceres/Desktop/work/genealogia_fonti/Salerno_cellulare/P8181659.JPG',2});
% 


result = [];

filename = '/mnt/win_d/phpgedview/usbdisk_genealogia/analisi_cd.txt';

if ~exist('action','var')
    % default action
    action = 'search';
end

switch action
    case 'search'
        close all
        
        volume_pat = ''; % use the whole archive, no restrictions on subset of archive (i.e. Church only)
        quiet = 1;
        [matr_source list_stream] = load_index(filename,volume_pat,quiet);
        search_target(matr_source,list_stream,filename);
        
        result.matr_source = matr_source;
        
    case 'analyse'
        close all
        
        volume_pat   = params{1};
        quiet = 0;
        [matr_source list_stream] = load_index(filename,volume_pat,quiet);
        
        result.matr_source = matr_source;
        result.list_stream = list_stream;
        
    case 'open_image'
        image   = params{1};
        verbose = params{2};
        open_image(image,verbose)
        
    case 'check_conflicts'
        flg_check_all_files = 1;
        [list_unique_images list_full_images] = check_conflict(filename,flg_check_all_files);
        
        result.list_unique_images = list_unique_images;
        result.list_full_images   = list_full_images;
        
    case 'insert_space'
        par_struct = assert_params(params,{'img_fullname','num_spaces'});
        img_fullname = par_struct.img_fullname;
        num_spaces   = par_struct.num_spaces;
        
        fcn_insert_space(img_fullname,num_spaces);
        
    case 'reformat_images'
        par_struct = assert_params(params,{'img_fullname','img_fmt_new','start_num'});
        img_fullname = par_struct.img_fullname;
        img_fmt_new  = par_struct.img_fmt_new;
        start_num    = par_struct.start_num;
        
        matr_rename = fcn_reformat_images(img_fullname,img_fmt_new,start_num);
        
        result.matr_rename = matr_rename;
        
    otherwise
        error('Unknown command:%s',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [matr_source list_stream] = load_index(filename,volume_pat,quiet)

list_stream = {
    {'Nati','Battezzati'}
    {'Matrimoni','Pubblicazioni'}
    {'Morti'}
    };

matr_source = parsefile(filename,volume_pat);

for i_stream = 1:length(list_stream)
    analise_sources(matr_source,list_stream{i_stream},quiet);
end

if ~quiet
    flg_check_all_files = 1;
    list_unique_images = check_conflict(filename,flg_check_all_files);
    
    verify_image_coverage(list_unique_images,matr_source)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function search_target(matr_source,list_stream,filename)

[stream_filter datenum_target] = define_target(list_stream);
%stream_filter = list_stream{1};
%datenum_target = datenum('05/01/1853','dd/mm/yyyy');

custom_preference = struct();
custom_preference.ind_blk_preference = [];
custom_preference.v_ind_copy = ones(size(matr_source,1),1)*0+NaN;
match_type = 'range'; % 'none','range','match'
image_proposal_old = '';
while strcmp(match_type,'range')
    [match_type match_addr custom_preference] = search_target_in_list(matr_source,stream_filter,datenum_target,custom_preference);
    if strcmp(match_type,'range')
        image_proposal = probe_image(datenum_target,matr_source,match_addr);
        if strcmp(image_proposal,image_proposal_old)
            error('Si ripresenta sempre la stessa immagine %s... Termino qui\n',image_proposal)
        end
        [datestr_ita datenum_meas flg_finish image_proposal] = test_image(image_proposal,datenum_target);
        matr_source = update_matr_source(matr_source,match_addr,datestr_ita,datenum_meas,image_proposal);
        writefile(filename,matr_source);
        if flg_finish
            [match_type match_addr custom_preference] = search_target_in_list(matr_source,stream_filter,datenum_target,custom_preference);
            match_type = 'match';
        end
        image_proposal_old = image_proposal;
    end
end

switch match_type
    case 'none'
        fprintf(1,'Data non presente tra le fonti disponibili!\n')
    case 'match'
        image_name = matr_source{match_addr(1),4}{match_addr(2),2}{3}{match_addr(3)};
        fprintf(1,'Visualizzazione immagine %s!\n',image_name)
        verbose = 1;
        open_image(image_name,verbose)
    otherwise
        error('todo2')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analise_sources(matr_source,filter_tags,quiet)

if ~quiet
    figure
    hold on
    grid on
    xlabel('time [gg]')
    col = colormap;
end

ind = zeros(size(matr_source,1),1);

colori = {'.','o'};
for i_tag = 1:length(filter_tags)
    tag_i = filter_tags{i_tag};
    ind = ind | strcmp(matr_source(:,3),tag_i);
end
ind = find(ind);

ks=sprintf('%s, ',filter_tags{:});
ks=ks(1:end-2);
if ~quiet
    title(ks)
end

matr_extents = [];
for i_blk = 1:length(ind)
    matr_source_i = matr_source(ind(i_blk),:);
    
    datenum_blk = range_analysis(matr_source_i);
    
    if isempty(datenum_blk)
        %disp(matr_source_i{end})
        %fprintf(1,'No date_image line in block %s, skipping\n',matr_source_i{1})
    elseif (any(diff(datenum_blk)<0))
        for i_item = 1:3
            disp(matr_source_i{i_item})
        end
        disp(datestr(datenum_blk))
        disp(' ')
        disp(datestr(datenum_blk(diff(datenum_blk)<0)))
        error('Le date non sono consecutive!')
    else
        verbose = 0;
        matr_extents = add_extent(matr_extents,datenum_blk,verbose);
        
        ind_tag = strmatch(matr_source_i{3},filter_tags,'exact');
        offset = i_blk/100;
        
        if ~quiet
            plot(datenum_blk,datenum_blk*0+offset,colori{ind_tag})
            
            x1 = min(datenum_blk);
            x2 = max(datenum_blk);
            y1 = 0.01+offset;
            y2 = 0.3+offset;

            ind_col = ceil(i_blk*2/(length(ind)*2)*size(col,1));
            h=patch([x1 x2 x2 x1],[y1 y1 y2 y2],col(ind_col,:));
            set(h,'FaceAlpha',0.3,'EdgeAlpha',0)
        end
    end
end

if ~quiet
    v=(1740:10:1920)';
    vx=datenum([v repmat(1,length(v),2)]);
    set(gca,'XTick',vx)
    set(gca,'XTickLabel',datestr(vx))
    set(gca,'XMinorGrid','off')
    set(gca,'XMinorTick','on')
    
    fprintf(1,'\n\n')
    fprintf(1,'\nIntervalli presenti per %s (da %s a %s):\n',ks,datestr(min(matr_extents(:,1))),datestr(max(matr_extents(:,2))))
    for i_extent = 1:size(matr_extents,1)
        extent_i        = matr_extents(i_extent,:);
        ext_start = extent_i(1);
        ext_end   = extent_i(2);
        delta_ext = ext_end-ext_start;

        fprintf(1,'Da %s a %s (%5d giorni)\n',datestr(ext_start),datestr(ext_end),delta_ext)
        plot(extent_i,extent_i*0+0.1,'g.-')
    end
    
    fprintf(1,'\nIntervalli mancanti per %s (da %s a %s):\n',ks,datestr(min(matr_extents(:,1))),datestr(max(matr_extents(:,2))))
    for i_extent = 2:size(matr_extents,1)
        extent_i        = matr_extents(i_extent,:);
        extent_i_old    = matr_extents(i_extent-1,:);
        gap_start = extent_i_old(2);
        gap_end   = extent_i(1);
        delta_gap = gap_end-gap_start;
        if delta_gap>30
            msg = '*** ';
        else
            msg = '    ';
        end
        fprintf(1,'%sDa %s a %s (%5d giorni)\n',msg,datestr(gap_start),datestr(gap_end),delta_gap)
        plot([gap_start gap_end],extent_i*0+0.1,'r.-')
    end
    fprintf(1,'\n')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function datenum_blk = range_analysis(matr_source_i)

max_gap = 365*1.05;          % [gg]
max_delta_image = 20;   % [adim]

volume_blk = matr_source_i{1};
type_blk   = matr_source_i{3};
data_blk   = matr_source_i{4};

ind_date_image = find(strcmp(data_blk(:,1),'date_image'));

if isempty(ind_date_image)
    datenum_blk = [];
else
    z_tmp=[data_blk{ind_date_image,2}];
    num_cells = length(data_blk{ind_date_image(1),2}); % number of param cells for 'data_image' info
    
    images_blk  = cellcell2cell(z_tmp(3:num_cells:end)');   % image
    datenum_blk = cell2mat(z_tmp(2:num_cells:end)');        % datenum
    
    num_copies = size(images_blk,2); % number of copies (images separated by "-")
    
    
    v_gap = diff(datenum_blk);
    ind_gap = find(v_gap>max_gap);
    tainted = 0;
    for i_gap = 1:length(ind_gap)
        gap = v_gap(ind_gap(i_gap));
        ind1 = ind_gap(i_gap);
        ind2 = ind1+1;
        ks1 = datestr(datenum_blk(ind1));
        ks2 = datestr(datenum_blk(ind2));
        for i_copy = 1:num_copies
            image1 = images_blk{ind1,i_copy};
            image2 = images_blk{ind2,i_copy};
            if ( isempty(image1) || isempty(image2) )
                %fprintf(1,'\tskipping interp between "%s" and "%s"\n',image1,image2)
            else
                ks_num1  = regexp(image1,'[0-9]{4,}','match');
                ks_num2  = regexp(image2,'[0-9]{4,}','match');
                if ( length(ks_num1)~=length(ks_num2) )
                    error('Immagini con formato diverso! (%s,%s)',image1,image2)
                end
                num1  = str2double(ks_num1);
                num2  = str2double(ks_num2);
                delta_image = num2-num1;
                if delta_image>1000
                    disp('ATTENZIONE!')
                end
                if delta_image > max_delta_image
                    tainted = 1;
                    z_image = regexp(image1,'[0-9]{4,}','split');
                    
                    temp=round(linspace(num1,num2,2+floor(gap/max_gap)));
                    v_num = temp(2:end-1);
                    
                    for i_num = 1:length(v_num)
                        num_i = v_num(i_num);
                        ks_num_i = num2str(num_i,['%0' num2str(length(ks_num1{1})) 'd']);
                        image_proposal = [z_image{1} ks_num_i z_image{2}];
                        fprintf(1,'\t--> %d) Big gap between %s (%s) and %s (%s)\n',i_num,ks1,image1,ks2,image2)
                        fprintf(1,'\tdisp([''dd mmm yyyy'' sprintf(''\t'') repmat(sprintf(''\t\t - ''),1,%d) ''%s'']); !IMAGE=%s && NAME=$(find /mnt/win_d/phpgedview/usbdisk_genealogia/ -name $IMAGE.*) && echo $NAME && gimp $NAME &\n\n',i_copy-1,image_proposal,image_proposal)
                    end
                    
                end
            end
        end
    end
    
    if (tainted)
        fprintf(1,'...per volume "%s" (%s)\n\n',volume_blk,type_blk)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_source = parsefile(filename,volume_pat)
% read file with archive info (volumes, dates, etc.), and only consider
% those volumes matching (regexp) volume_pat

text = readfile (filename);

z_volume=regexp(text,'[\-]{6,}[\r\n]+[^\r\n]+[\r\n]+[\-]{6,}');
list_volume{length(z_volume)} = [];
for i_volume = 1:(length(z_volume)-1)
    list_volume{i_volume} = strtrim(text(z_volume(i_volume):(z_volume(i_volume+1)-1)));
end
list_volume{length(z_volume)} = strtrim(text(z_volume(end):end));

count_volume = 0;
matr_source{length(list_volume)} = [];
for i_volume = 1:length(list_volume)
    volume_i = list_volume{i_volume};
    z_volume = regexp(volume_i,'[\-]{6,}[\r\n]+([^\r\n]+)[\r\n]+[\-]{6,}(.*)','tokens');
    alias_volume = z_volume{1}{1};
    
    if isempty(volume_pat) || ~isempty(regexp(alias_volume,volume_pat, 'once'))
        body_volume  = strtrim(z_volume{1}{2});
        
        % fprintf(1,'\n%2d) volume %s:\n',i_volume,alias_volume)
        % disp(body_volume);
        
        count_volume = count_volume+1;
        matr_source{count_volume} = parse_body_volume(alias_volume,body_volume);
    end
end
matr_source((count_volume+1):end) = [];
% consolida cell array
matr_source = cellcell2cell(matr_source);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_source = parse_body_volume(alias_volume,body_volume)

list_blk=regexp(body_volume,'\r?\n\s*\r?\n','split');
matr_source = {};
for i_blk = 1:length(list_blk)
    blk_i = list_blk{i_blk};
    z_blk = regexp(blk_i,'([^\r\n]+)[\r\n]+(.*)','tokens');
    if isempty(z_blk)
        z_blk = regexp(blk_i,'([a-zA-Z]+)[\s]+(.*)','tokens');
        type_blk  = 'inline';
        alias_blk = z_blk{1}{1};
        body_blk  = z_blk{1}{2};
        data_blk  = {[],strtrim(body_blk)};
    else
        if regexp(z_blk{1}{1},'^(\s?[0-9]+ [a-z]+ [0-9]+|indice|copertina|altro)\s+[^\r\n]+')
            type_blk  = 'continue';
            %alias_blk = alias_blk_old;
            body_blk  = blk_i;
        else
            type_blk  = 'block';
            alias_blk = z_blk{1}{1};
            body_blk  = z_blk{1}{2};
        end
        data_blk = parse_block(body_blk);
    end
    
    if ~isequal(alias_blk,strtrim(alias_blk))
        alias_blk = strtrim(alias_blk);
        fprintf(1,'\t**** spazio dopo il nome! (%s)\n',alias_blk)
    end
    
    % fprintf(1,'\t%10s - %s;\n',type_blk,alias_blk)
    
    matr_source(end+1,:) = {alias_volume,type_blk, alias_blk, data_blk}; %#ok<AGROW>
end

% check for image number continuity
check_continuity(matr_source);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_blk = parse_block(body_blk)

list_line = regexp(body_blk,'\r?\n','split');

matr_blk = {};
for i_line = 1:length(list_line)
    line_i = list_line{i_line};
    
    z_line = regexp(line_i,'^(\s?[0-9]+ [a-z]+ [0-9]+)\s+(.+)', 'tokens');
    if ~isempty(z_line)
        type_line = 'date_image';
        date_line = strtrim(z_line{1}{1});
        
        datenum_line = get_datenum(date_line);
        info_line    = regexp(z_line{1}{2},'\s*-\s*','split');
        image_name = info_line{end};
        params_line = {date_line, datenum_line, info_line};
    else
        z=regexp(line_i,'^(\t|\s{4,})+([a-zA-Z0-9_]+)','tokens');
        if ~isempty(z)
            type_line = 'fix';
            fix_line = z{1}{2};
            
            ind_fixed = find(~strcmp(matr_blk(:,1),'fix'),1,'last');
            fixed_line = matr_blk(ind_fixed,:);
            
            image_name = '';            
            params_line = {fix_line,fixed_line};
            % fprintf(1,'fix: %s (%s) for image in date %s\n',fix_line,line_i,fixed_line{2}{1})
        else
            z=regexp(line_i,'^copertina\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)','tokens');
            if ~isempty(z)
                type_line = 'copertina';
                copertina_type  = z{1}{1};
                image_name      = z{1}{2};
                params_line = {copertina_type, image_name};
            else
                z=regexp(line_i,'^indice\s+([0-9_]+)\s+([a-zA-Z0-9_]+)','tokens');
                if ~isempty(z)
                    type_line = 'indice';
                    indice_type = z{1}{1};
                    image_name  = z{1}{2};
                    params_line = {indice_type, image_name};
                else
                    z=regexp(line_i,'^altro\s+\(([a-zA-Z0-9_\s\,/]+)\)\s+([a-zA-Z0-9_\s]+)','tokens');
                    if ~isempty(z)
                        type_line = 'altro';
                        altro_type  = z{1}{1};
                        image_name  = z{1}{2};
                        params_line = {altro_type, image_name};
                    else
                        type_line   = 'unknown';
                        image_name  = '';
                        params_line = {};
                        fprintf(1,'item non riconosciuto --> %s\n',line_i)
                    end
                end
            end
        end
    end
    
    data_line = {type_line, params_line,image_name};
    matr_blk(end+1,:) = data_line; %#ok<AGROW>
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function datenum_line = get_datenum(date_line)
% '24 feb 1748' --> 638499 (using datenum function)

months = {'gen','feb','mar','apr','mag','giu','lug','ago','set','ott','nov','dic'};

z=regexp(date_line,'\s+','split');
month=z{2};
val_month = strmatch(month,months,'exact');
if isempty(val_month)
    error('Unrecognized month %s!',month)
end

val_year = str2double(z{3});
val_day  = str2double(z{1});
datenum_line = datenum(val_year,val_month,val_day);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_continuity(matr_source)
% check for image number continuity

volume_tag = matr_source{1,1};
for i_blk = 2:size(matr_source,1)
    blk_i_old   = matr_source{i_blk-1,4};
    blk_i       = matr_source{i_blk,4};

    type_last  = matr_source{i_blk-1,3};
    type_first = matr_source{i_blk,3};
    
    image_last  = blk_i_old{end,end};
    image_first = blk_i{1,end};
    
    [num_last fmt_image_last] = image2number({image_last});
    [num_first fmt_image_first] = image2number({image_first});
    
    if ( ~isequal(fmt_image_last,fmt_image_first) )
        % fprintf(1,'%s: cambio formato immagine: da %s a %s\n',volume_tag,image_last,image_first)
    else
        gap = num_first-num_last;
        if gap>1
            fprintf(1,'%s: salto di %d immagini tra %s (%s) e %s (%s)\n',volume_tag,gap,image_last,type_last,image_first,type_first)
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function text = readfile(filename)

z = dir(filename);
fid = fopen(filename, 'r');
text = fread(fid, z.bytes, 'uint8=>char')';
fclose(fid);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v_out = cellcell2cell(v_in)
% v_in = {
%   {1xn cell}
%   {1xn cell}
%   {1xn cell}
%   ...
% }
%
% v_out = {m x n}
%

z=cellfun(@(x) x',v_in,'uniformoutput',0)';
v_out  = [z{:}]'; 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [stream_filter datenum_target] = define_target(list_stream)

list_item{length(list_stream)} = [];
for i_stream = 1:length(list_stream)
    ks = sprintf('%s, ',list_stream{i_stream}{:});
    ks = ks(1:end-2);
    list_item{i_stream} = sprintf('%s',ks);
end
question_type = 'select';
question = sprintf('Scegli il tipo di ricerca da fare [1..%d]:',length(list_stream));
error_msg = sprintf('Inserisci un numero compreso tra 1 e %d!',length(list_item));
num = item_selection(question_type,question,list_item,error_msg);
stream_filter = list_stream{num};

% chiedi la data
list_item = {};
question_type = 'date';
question = sprintf('Inserisci la data nel formato dd/mm/yyyy:');
error_msg = sprintf('Il formato deve essere dd/mm/yyyy (ad es. 31/12/2013)!');
date_target = item_selection(question_type,question,list_item,error_msg);
datenum_target = datenum(date_target,'dd/mm/yyyy');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [match_type match_addr custom_preference] = search_target_in_list(matr_source,stream_filter,datenum_target,custom_preference)

match_type = {};
match_addr = [];

% se la data cercata è compresa tra l'ultima data, e l'ultima
% data+max_delta, considera l'ultima immagine come se contenesse la data
max_delta = 120; % [gg] % se la pagina è compatta, ci possono essere diversi mesi in un'unica foto

ind_stream = find(ismember(matr_source(:,3),stream_filter));

matr_blks = matr_source(ind_stream,:);
for i_blk = 1:size(matr_blks,1)
    blk_i = matr_blks(i_blk,:);
    blk_volume = blk_i{1};
    blk_type   = blk_i{3};
    blk_items  = blk_i{4};
    
    pos_blk = ind_stream(i_blk); % posizione di blk_i in matr_source
    
    ind_date_image = strmatch('date_image',blk_items(:,1),'exact');
    lines_date_image = blk_items(ind_date_image,:);
    if ~isempty(lines_date_image)
        data_date_image = cellcell2cell(lines_date_image(:,2));
        
        v_datenum = cell2mat(data_date_image(:,2));
        if ( (datenum_target>=min(v_datenum)) && (datenum_target<=max(v_datenum)+max_delta) )
            fprintf(1,'Trovato blocco %s contenente la data %s in %s\n',blk_type,datestr(datenum_target),blk_volume)
            
            pos_before = find(v_datenum>datenum_target,1)-1;
            
            %scegli copia
            if ~isempty(pos_before)
                sample_images = data_date_image{pos_before,end};
            else
                sample_images = data_date_image{end,end};
            end

            num_copies = length(sample_images);
            if num_copies==1
                ind_copy = 1;
            else
                list_not_empty = setdiff(1:num_copies,find(cellfun('isempty',sample_images)));
                if (length(list_not_empty) == 1)
                    ind_copy = list_not_empty;
                    fprintf(1,'\t%d copies used in block, but only copy %d is available for this range\n',num_copies,ind_copy)
                else
                    list_item = cellfun(@(x) sprintf('Immagini (%s)',x),sample_images,'UniformOutput',0);
                    question_type = 'select';
                    question = sprintf('Scegli l''insieme di immagini da utilizzare [1..%d]:',num_copies);
                    error_msg = sprintf('Inserisci un numero compreso tra 1 e %d!',num_copies);
                    if isnan(custom_preference.v_ind_copy(pos_blk))
                        ind_copy = item_selection(question_type,question,list_item,error_msg);
                    else
                        ind_copy = custom_preference.v_ind_copy(pos_blk);
                    end
                end
            end
            custom_preference.v_ind_copy(pos_blk) = ind_copy; % la scelta è memorizzata per ciascun blocco
            
            ind_match = find(v_datenum==datenum_target,1);
            
            if isempty(pos_before)
                % date is probably in the last image
                line_last  = lines_date_image{end,2};
                date_last  = line_last{1};
                image_last = line_last{3}{ind_copy};
                fprintf(1,'\tL''ultima data nel blocco è %s (%s), probabilmente la data %s è contenuta all''interno.\n',date_last,image_last,datestr(datenum_target))
            else
                % date has an image before, and another after
                image_before = lines_date_image{pos_before,2}{3}{ind_copy};
                image_after  = lines_date_image{pos_before+1,2}{3}{ind_copy};
                
                num_before  = image2number(image_before);
                num_after   = image2number(image_after);
                flg_stop_search = (num_after-num_before<=1);
            end
            if ~isempty(ind_match)
                % date is the first image
                match_addr(end+1,:) = [ind_stream(i_blk) ind_date_image(ind_match) ind_copy]; %#ok<AGROW>
                match_type{end+1}   = 'match'; %#ok<AGROW>
            elseif isempty(pos_before)
                % date is probably in the last image
                match_addr(end+1,:) = [ind_stream(i_blk) ind_date_image(end) ind_copy]; %#ok<AGROW>
                match_type{end+1}   = 'match'; %#ok<AGROW>                
            elseif flg_stop_search
                % date is present in image
                match_addr(end+1,:) = [ind_stream(i_blk) ind_date_image(pos_before) ind_copy]; %#ok<AGROW>
                match_type{end+1}   = 'match'; %#ok<AGROW>
            else
                match_addr(end+1,:) = [ind_stream(i_blk) ind_date_image(pos_before) ind_copy]; %#ok<AGROW>
                match_type{end+1}   = 'range'; %#ok<AGROW>
            end
        end
    end
end

% choose one of the possible matches (cell array to string)
if length(match_type)>1
    if isempty(custom_preference.ind_blk_preference)
        custom_preference.ind_blk_preference = select_match(match_addr,match_type,matr_source);
    end
    match_addr = match_addr(custom_preference.ind_blk_preference,:);
    match_type = match_type{custom_preference.ind_blk_preference};
else
    if isempty(match_type)
        match_type = 'none';
    else
        % only one match, so transform to string
        match_type = match_type{1};
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function answer = item_selection(question_type,question,list_item,error_msg)
% Input routine to get answer from the use
% 
% inputs:
%   question_type : type of text expected by the user (to be validated)
%                   'select'    % choose among a set of choices (1-based integer number)
%                   'date'      % full date (dd/mm/yyyy)
%                   'date_fast' % full date (dd/mm/yyyy) or simplified date without year (dd/mm)
%   question      : question to be asked to the user before asking its input
%   list_item     : list of items to be shown after the question (typically for
%                   'select' question_type)
%   error_msg     : error msg to be shown if the input is not correct and the
%                   question is re-iterated
%

disp(question)
for i_item = 1:length(list_item)
    disp([num2str(i_item) ')' list_item{i_item}])
end
ancora = 1;
while ancora
    answer = input('','s');
    
    if ismember(answer,{'exit','quit'})
        error('Aborted by user')
    end

    switch question_type
        case 'select'
            answer = str2double(answer);
            flg_ok = ~isnan(answer) && ismember(answer,1:length(list_item));
        case {'date','date_fast'}
            if regexp(answer,'^move [\+\-0-9]+$')
                % change image proposal
                flg_ok = 1;
            else
                % check date format
                z = regexp(answer,'([0-9]{1,2})/([0-9]{1,2})/([0-9]{4,4})','tokens');
                if ~isempty(z)
                    % date format is canonical
                    vett = str2double(z{1});
                    flg_ok = ismember(vett(1),1:31) && ismember(vett(2),1:12);
                else
                    z = regexp(answer,'([0-9]{1,2})/([0-9]{1,2})','tokens');
                    if (~isempty(z) && strcmp(question_type,'date_fast'))
                        % date format is missing the year, and it is allowed
                        vett = str2double(z{1});
                        flg_ok = ismember(vett(1),1:31) && ismember(vett(2),1:12);
                    else
                        flg_ok = 0;
                    end
                end
            end
        otherwise
            error('Todo')
    end
    
    if (flg_ok)
        ancora = 0;
    else
        disp(error_msg)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function open_image(image_name,verbose)

% close image viewer
[exit_code text]=system('ps -Al | grep gimp');
z = regexp(text,'[^\s]+','match');
if ~isempty(z)
    pid = z{4};
    cmd = ['!kill ' pid];
    eval(cmd)
end

% reopen with new image
cmd = sprintf('\n\t!IMAGE="%s" && NAME=$(find /mnt/win_d/phpgedview/usbdisk_genealogia/ -name "$IMAGE*") && echo "$NAME" && gimp "$NAME" &',image_name);
eval(cmd)

if verbose
    cmd = sprintf('\n\tIMAGE="%s" && NAME=$(find /mnt/win_d/phpgedview/usbdisk_genealogia/ -name "$IMAGE*") && echo "$NAME" && gwenview "$NAME" &',image_name);
    disp(cmd)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_proposal = probe_image(datenum_target,matr_source,match_addr)

pos_blk  = match_addr(1);
pos_line = match_addr(2);
pos_copy = match_addr(3);

blk_data = matr_source{pos_blk,4};

% approssimazione: bisognerebbe cercare, per l'ind_copy scelta, la prima
% immagine disponibile, sia prima che dopo, in modo da gestire
% correttamente due copie interlacciate (una data con copia1, la successiva
% con copia2,la successiva con copia1, ecc.)
line_data_before = blk_data{pos_line,2};
line_data_after  = blk_data{pos_line+1,2};

if ( (length(line_data_before)<3) || (length(line_data_after)<3) )
    disp(line_data_before)
    disp(line_data_after)
    error('Verifica l''indice: non si riescono ad individuare i due estremi con le date!')
end

num_copy = length(line_data_before{3});

image_before = line_data_before{3}{pos_copy};
image_after  = line_data_after{3}{pos_copy};

date_before = line_data_before{1};
date_after  = line_data_after{1};

datenum_before = line_data_before{2};
datenum_after  = line_data_after{2};

fprintf(1,'%11s --> %s\n',date_before,image_before)
fprintf(1,'%11s --> %s\n',date_after,image_after)

v_ratio = (datenum_target-datenum_before)/(datenum_after-datenum_before);

list_image_proposal = interpolate_image(image_before,image_after,v_ratio,num_copy);
image_proposal = list_image_proposal{1}; % only one image



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_image_proposal = interpolate_image(image1,image2,v_ratio,num_copy)

ks_num1  = regexp(image1,'[0-9]{4,}','match');
ks_num2  = regexp(image2,'[0-9]{4,}','match');
if ( length(ks_num1)~=length(ks_num2) )
    error('Immagini con formato diverso! (%s,%s)',image1,image2)
end
num1  = str2double(ks_num1);
num2  = str2double(ks_num2);
delta_image = num2-num1;

z_image = regexp(image1,'[0-9]{4,}','split');

% delta_image-1 perché sicuramente image2 non contiene la data ricercata
% num1+1 perché conviene saltare l'immagine 1 e tentare con la successiva
v_num = round((num1+1)+((delta_image-1)-1)*v_ratio);

list_image_proposal{length(v_num)} = '';
for i_num = 1:length(v_num)
    num_i = v_num(i_num);
    ks_num_i = num2str(num_i,['%0' num2str(length(ks_num1{1})) 'd']);
    image_proposal = [z_image{1} ks_num_i z_image{2}];
    fprintf(1,'\t--> %d) Big gap between %s and %s\n',i_num,image1,image2)
    fprintf(1,'\tdisp([''dd mmm yyyy'' sprintf(''\t'') repmat(sprintf(''\t\t - ''),1,%d) ''%s'']); !IMAGE=%s && NAME=$(find /mnt/win_d/phpgedview/usbdisk_genealogia/ -name $IMAGE.*) && echo $NAME && gimp $NAME &\n\n',num_copy-1,image_proposal,image_proposal)
    list_image_proposal{i_num} = image_proposal;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [datestr_ita datenum_meas flg_finish image_proposal] = test_image(image_proposal,datenum_target)

flg_got_date = 0;
while ( ~flg_got_date )
    fprintf(1,'Opening image %s...\n',image_proposal)
    
    verbose = 1;
    open_image(image_proposal,verbose)
    
    % chiedi la data di questa immagine
    list_item = {};
    question_type = 'date_fast';
    question = sprintf('Inserisci la prima data nell''immagine, nel formato dd/mm/yyyy:');
    error_msg = sprintf('Il formato deve essere dd/mm/yyyy (ad es. 31/12/2013) o dd/mm (31/12), oppure [quit,exit,move +-N]!');
    answer = item_selection(question_type,question,list_item,error_msg);
    if regexp(answer,'^move [\+\-0-9]+$')
        image_proposal = change_image_proposal(image_proposal,answer);
    else
        if sum(answer=='/')==1
            % missing year (date_fast allows it), just add it from the datenum_target
            ks_year_target = datestr(datenum_target,'yyyy');
            date_meas = [answer '/' ks_year_target];
        else
            date_meas = answer;
        end
        flg_got_date = 1;
    end
end
datenum_meas = datenum(date_meas,'dd/mm/yyyy');

datestr_eng = lower(datestr(datenum_meas,'dd mmm yyyy'));
if (datestr_eng(1)=='0')
    % remove trailing 0
    datestr_eng = datestr_eng(2:end);
end
datestr_ita = datestr_eng2ita(datestr_eng);
fprintf(1,'\t%s\n',datestr_ita)

if ( datenum_meas>datenum_target )
    % l'immagine ha date successive a quella obiettivo, la ricerca continua
    flg_finish = 0;
else
    list_item = {'La data cercata non termina in questa pagina','La data cercata termina in questa pagina'};
    question_type = 'select';
    question = sprintf('scegli (data cercata: %s):',datestr(datenum_target));
    error_msg = sprintf('Devi inserire 1 o 2!');
    num_answer = item_selection(question_type,question,list_item,error_msg);
    flg_finish = num_answer-1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_proposal_new = change_image_proposal(image_proposal,answer)

num=image2number(image_proposal); % number of current image_proposal
z = regexp(answer,'move ([\+\-0-9]+)','tokens');
delta = str2double(z{1}{1});
image_proposal_new = regexprep(image_proposal,num2str(num),num2str(num+delta));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function datestr_ita = datestr_eng2ita(datestr_eng)

month_ita = {'gen','mag','giu','lug','ago','set','ott','dic'};
month_eng = {'jan','may','jun','jul','aug','sep','oct','dec'};

z=regexp(datestr_eng,'\s+','split');
month=z{2};
ind = strmatch(month,month_eng,'exact');
if ~isempty(ind)
    datestr_eng = strrep(datestr_eng,month_eng{ind},month_ita{ind});
end
datestr_ita = datestr_eng;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [matr_source_new flg_updated] = update_matr_source(matr_source,match_addr,datestr_ita,datenum_meas,image_proposal)

flg_updated = 0;
matr_source_new = matr_source;

pos_blk  = match_addr(1);
pos_line = match_addr(2);
pos_copy = match_addr(3);

blk_vol  = matr_source{pos_blk,1};
blk_type = matr_source{pos_blk,3};
blk_data = matr_source{pos_blk,4};

if isequal(datestr_ita,blk_data{pos_line,2}{1})
    fprintf(1,'Data %s (%s,%s) già presente in archivio! Non aggiorno il file\n',datestr_ita,blk_vol,blk_type)
else
    blk_date_image = blk_data(strmatch('date_image',blk_data(:,1),'exact'),:);
    z_temp=cellcell2cell(blk_date_image(:,2));
    z_temp2=cellcell2cell(z_temp(:,3));
    z_temp2 = z_temp2(:); % lista delle foto presenti nel blocco
    if ismember(image_proposal,z_temp2)
        fprintf(1,'L''immagine %s è già presente nel blocco per un''altra data (non per %s)!\n',image_proposal,datestr_ita)
        pause
    else
        num_copies = length(blk_date_image{1,2}{3});
        
        [image_list{1:num_copies}] = deal('');
        image_list{pos_copy} = image_proposal;
        
        line_data = {datestr_ita,datenum_meas,image_list};
        
        line_new = {'date_image',line_data,image_proposal};
        
        blk_data_new = [blk_data(1:pos_line,:); line_new; blk_data(pos_line+1:end,:)];
        
        matr_source_new{pos_blk,4} = blk_data_new;
        flg_updated = 1;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writefile(filename,matr_source)

%filename_new = [filename '.bak'];
filename_new = filename;

text = sprintf('\r\n');

blk_volume_old = '';
for i_blk = 1:size(matr_source,1)
    blk_i = matr_source(i_blk,:);
    blk_volume      = blk_i{1};
    %blk_blocktype   = blk_i{2};
    %blk_type        = blk_i{3};
    %blk_data        = blk_i{4};
    
    % close volume
    if ( (i_blk>1) && ~strcmp(blk_volume,blk_volume_old) )
        text = sprintf('%s\r\n\r\n',text);
    end
    
    % open volume
    if ~strcmp(blk_volume,blk_volume_old)
        text = sprintf('%s--------------------\r\n%s\r\n--------------------\r\n\r\n',text,blk_volume);
    end
    
    % add blocks
    text = write_block(text,blk_i);
    
    blk_volume_old = blk_volume;
end

fid = fopen(filename_new,'w');
fwrite(fid,text,'char');
fclose(fid);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function text = write_block(text,blk_i)

%blk_volume      = blk_i{1};
blk_blocktype   = blk_i{2};
blk_type        = blk_i{3};
blk_data        = blk_i{4};

if strcmp(blk_blocktype,'block')
    text = sprintf('%s%s\r\n',text,blk_type);
end

if strcmp(blk_blocktype,'inline')
    inline_data = blk_data{2};
    text = sprintf('%s%s\t%s\r\n',text,blk_type,inline_data);    
else
    for i_line = 1:size(blk_data,1)
        line_i = blk_data(i_line,:);
        line_type   = line_i{1};
        line_params = line_i{2};
        % line_image  = line_i{3};
        
        switch line_type
            case 'date_image'
                ks_date = line_params{1};
                images  = line_params{3};
                ks_images = sprintf('%8s - ',images{:});
                ks_images = ks_images(1:end-3);
                text = sprintf('%s%11s\t%s\r\n',text,ks_date,ks_images);
            case 'fix'
                fix_image = line_params{1};
                text = sprintf('%s\t\t%s\r\n',text,fix_image);
            case 'altro'
                altro_type  = line_params{1};
                altro_image = line_params{2};
                text = sprintf('%saltro (%s)\t%s\r\n',text,altro_type,altro_image);
            case 'indice'
                indice_type  = line_params{1};
                indice_image = line_params{2};
                text = sprintf('%sindice %s\t%s\r\n',text,indice_type,indice_image);
            case 'copertina'
                copertina_type  = line_params{1};
                copertina_image = line_params{2};
                text = sprintf('%scopertina %s\t%s\r\n',text,copertina_type,copertina_image);            otherwise
                disp(line_type)
        end
    end
end


% close block
text = sprintf('%s\r\n',text);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [num fmt_image] = image2number(image)
% [num fmt_image] = image2number(image)

[ks_num fmt_image] = regexp(image,'[0-9]{4,}','match','split');
num     = str2double(ks_num{1});



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ind_match = select_match(match_addr,match_type,matr_source)

list_item{length(match_type)} = '';
for i_match = 1:length(match_type)
    
    pos_blk  = match_addr(i_match,1);
    pos_line = match_addr(i_match,2);
    pos_copy = match_addr(i_match,3);
    
    blk_i = matr_source(pos_blk,:);
    blk_volume = blk_i{1};
    blk_type   = blk_i{3};
    blk_data   = blk_i{4};
    
    line_data = blk_data{pos_line,2};
    line_date  = line_data{1};
    line_image = line_data{3}{pos_copy};
    list_item{i_match} = sprintf('%13s (%13s): %s (%s)',line_date,line_image,blk_type,blk_volume);
end

question_type = 'select';
question = sprintf('Sono presenti più blocchi contenenti la data cercata.\nDove vuoi continuare la ricerca?');
error_msg = sprintf('Inserisci un numero compreso tra 1 e %d!',length(list_item));
ind_match = item_selection(question_type,question,list_item,error_msg);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_extents = add_extent(matr_extents,datenum_blk,verbose)

min_datenum = min(datenum_blk);
max_datenum = max(datenum_blk);
extent_new = [min_datenum max_datenum];

if verbose
    disp(' ')
end
%fprintf(1,'\tDa %s a %s\n',datestr(min_datenum),datestr(max_datenum))

% check for conflicts
changed = 0;
list_delete = [];
for i_extent = 1:size(matr_extents,1)
    extent_i = matr_extents(i_extent,:);
    
    min_datenum = extent_new(1);
    max_datenum = extent_new(2);

    if verbose
        fprintf(1,'\tFondo blk(%s..%s) con (%s..%s)\n',datestr(min_datenum),datestr(max_datenum),datestr(extent_i(1)),datestr(extent_i(2)))
    end
    
    if (max_datenum<extent_i(1))
        % n1-n2-o1-o2
        if verbose
            fprintf(1,'\tblk(%s..%s) esterno inferiormente a (%s..%s)\n',datestr(min_datenum),datestr(max_datenum),datestr(extent_i(1)),datestr(extent_i(2)))
        end
    elseif (min_datenum>extent_i(2))
        % o1-o2-n1-n2
        if verbose
            fprintf(1,'\tblk(%s..%s) esterno superiormente a (%s..%s)\n',datestr(min_datenum),datestr(max_datenum),datestr(extent_i(1)),datestr(extent_i(2)))
        end
    else
        % c'è sovrapposizione
        list_delete(end+1) = i_extent; %#ok<AGROW> % rimuovi l'intervallo, che verrà fuso
        
        if extent_i(1)>min_datenum
            temp = extent_i;
            extent_i = [min_datenum max_datenum];
            min_datenum = temp(1);
            max_datenum = temp(2);
        end
        
        if (max_datenum>=extent_i(2))
            % o1-n1-o2-n2
            extent_new = [extent_i(1) max_datenum];
            if verbose
                fprintf(1,'\ti blocchi si incrociano\n');
            end
        else
            % o1-n1-n2-o2
            extent_new = extent_i;
            if verbose
                fprintf(1,'\tun blocco contiene l''altro\n');
            end
        end
        % merged extent
        %matr_extents(i_extent,:) = extent_new;
        changed = 1;
        if verbose
            fprintf(1,'Blocco fuso: %s..%s\n',datestr(extent_new(1)),datestr(extent_new(2)));
        end
    end
end

if ~changed
    if verbose
        fprintf(1,'Nuovo blocco(%s..%s)\n',datestr(min_datenum),datestr(max_datenum))
    end
    %matr_extents(end+1,:) = [min_datenum,max_datenum];
end

matr_extents(list_delete,:) = [];
matr_extents(end+1,:) = extent_new;

% riordina
[temp,ind_sort] = sort(matr_extents(:,1));
matr_extents=matr_extents(ind_sort,:);

if verbose
    ks='';for i_ext = 1:size(matr_extents,1),ks_i=datestr(matr_extents(i_ext,:));ks=[ks; repmat('-',1,length(ks_i)); ks_i];end %#ok<AGROW>
    disp(ks)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_unique_images list_full_images] = check_conflict(filename,flg_check_all_files)

root_folder = fileparts(filename);

if flg_check_all_files
    fprintf(1,'Reading all files in root folder %s...\n',root_folder)
    z0=regexpdir(root_folder,'.*');
end

fprintf(1,'Reading only images (jpg,jpeg,tif,tiff) in root folder %s...\n',root_folder)
z=regexpdir(root_folder,'\.([jJ][pP][eE]?[gG]|[tT][iI][fF][fF]?)$');

if flg_check_all_files
    whos z0 z,diff=setdiff(z0,z);
    for i=1:length(diff)
        if ~isdir(diff{i})
            disp(diff{i})
        end
    end
end

z2 = regexp(z,'[^\/]+$','match');
list_images = cellcell2cell(z2);

[list_unique_images ind_unique] =unique(list_images);

if ( length(list_unique_images)~=length(list_images) )
    fprintf(1,'\nElenco dei conflitti sui nomi delle immagini:\n')
    ind_dupl = setdiff(1:length(list_images),ind_unique);
    list_dupl = list_images(ind_dupl);
    for i_dupl = 1:length(list_dupl)
        name_dupl = list_dupl{i_dupl};
        ind_dupls = find(~cellfun('isempty',strfind(z,name_dupl)));
        disp(' ')
        for i_line = 1:length(ind_dupls)
            disp(z{ind_dupls(i_line)});
        end
    end
end
list_full_images = z;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function verify_image_coverage(list_unique_images,matr_source)

list_ind_delete = {};
for i_blk = 1:size(matr_source,1)
    blk_i = matr_source(i_blk,:);
    %blk_volume = blk_i{1};
    blk_blktype= blk_i{2};
    %blk_type   = blk_i{3};
    blk_data   = blk_i{4};
    
    switch blk_blktype
        case 'inline'
            image = blk_data{2};
            image = regexp(image,'[0-9A-Za-z_]+$','match'); % extract last image
            image = image{1};
            ind_image = find(~cellfun('isempty',regexp(list_unique_images,['^' image, '[^\s\.]{0,4}\.[jJ][pP][eE]?[gG]'],'once')));
            list_ind_delete{end+1} = ind_image; %#ok<AGROW>
            
        case {'block','continue'}
            blk_i_start = blk_data(1,:);
            blk_i_end   = blk_data(end,:);

            image_start = get_image(blk_i_start);
            image_end   = get_image(blk_i_end);
            
            image_start = image_start{1};
            image_end   = image_end{1};

            ind_image_start = find(~cellfun('isempty',regexp(list_unique_images,['^' image_start, '[^\s\.]{0,4}\.[jJ][pP][eE]?[gG].*$'],'once')));
            ind_image_end   = find(~cellfun('isempty',regexp(list_unique_images,['^' image_end, '[^\s\.]{0,4}\.[jJ][pP][eE]?[gG].*$'],'once')));
            
            list_ind_delete{end+1} = ind_image_start:ind_image_end; %#ok<AGROW>
            
        otherwise
            error('todo: %s',blk_blktype)
    end
end

list_delete = [];
for i_del = 1:length(list_ind_delete)
    list_delete = [list_delete, list_ind_delete{i_del}]; %#ok<AGROW>
end
list_unique_images(list_delete) = [];

if ~isempty(list_unique_images)
    fprintf(1,'Immagini non indicizzate:\n')
    
    folder = '';
    for i_img = 1:length(list_unique_images)
        image = list_unique_images{i_img};
        if ( isempty(folder) || ~exist([folder filesep image],'file') )
            fullname = locate(image);
            folder = fileparts(fullname);
        else
            fullname = [folder filesep image];
        end
        fprintf(1,'%30s:   %s\n',image,fullname)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_list = get_image(blk_i)

blk_type  = blk_i{1};
blk_data  = blk_i{2};
%blk_image = blk_i{3};

switch blk_type
    case 'date_image'
        image_list = blk_data{3}; % cell array
        
    case {'altro','indice','copertina'}
        image_list = blk_data(2); % cell array
        
    otherwise
        error('blk type todo: %s',blk_type)
end

if length(image_list)>1
    
    list_delete = [];
    for i_img = 1:length(image_list)
        fullname = locate(image_list{i_img});
        if isempty(fullname)
            list_delete(end+1) = i_img; %#ok<AGROW>
        end
    end
    image_list(list_delete) = [];
    if length(image_list) ~= 1
        disp(image_list)
        error('length = 2!')
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fullname = locate(image_name)

if isempty(image_name)
    fullname = '';
else
    cmd = sprintf('\n\tIMAGE="%s" && NAME=$(find /mnt/win_d/phpgedview/usbdisk_genealogia/ -name "$IMAGE*") && echo $NAME',image_name);
    [exit_code text]=system(cmd);
    
    fullname = strtrim(text);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fcn_insert_space(img_fullname,num_spaces)

if ~exist(img_fullname,'file')
    error('File %s does not exist!',img_fullname)
end

[img_path img_name img_ext] = fileparts(img_fullname);
img_name = [img_name img_ext];

[img_num img_fmt] = analyse_img(img_name);
z = dir([img_path filesep img_fmt]);

for i_img = length(z):(-1):1
    img_name_i = z(i_img).name;
    img_num_i = analyse_img(img_name_i);
    if (img_num_i>=img_num)
        img_num_new_i = img_num_i+num_spaces;
        img_name_new_i = strrep(img_fmt,'*',num2str(img_num_new_i));
        movefile([img_path filesep img_name_i],[img_path filesep img_name_new_i]);
        fprintf(1,'*** %s --> %s\n',img_name_i,img_name_new_i)
    else
        fprintf(1,'    %s\n',img_name_i)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_rename = fcn_reformat_images(img_fullname,img_fmt_new,start_num)

[img_path img_name img_ext] = fileparts(img_fullname);
img_fmt = [img_name img_ext];

z = dir([img_path filesep img_fmt]);

if ~isempty(z)
    matr_rename{length(z),2} = [];
    for i_img = 1:length(z)
        img_name_i = z(i_img).name;
        img_num_new_i = start_num+i_img-1;
        img_name_new_i = strrep(img_fmt_new,'*',num2str(img_num_new_i));
        matr_rename(i_img,:) = {img_name_i,img_name_new_i};
        movefile([img_path filesep img_name_i],[img_path filesep img_name_new_i]);
        fprintf(1,'*** %s --> %s\n',img_name_i,img_name_new_i)
    end
else
    matr_rename = {};
    fprintf(1,'No file found with format %s!\n',img_fmt)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [img_num img_fmt] = analyse_img(img_name)

z = regexp(img_name,'[0-9]+','match');
ks_img_num = z{1};
img_num = str2double(ks_img_num);
img_fmt = strrep(img_name,ks_img_num,'*');
