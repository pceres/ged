function fix_csv_file(fix_type,enable_write)
%
% fix_csv_file(fix_type,enable_write)
%
% fix_type:
%   0 : just load the dst csv, make it available as table_fix, and do a few checks
%   1 : take lines with only "M" or "G" directly from src file
%   2 : change ";0;" into ";.;" in dst file
%   3 : find ";0;" in dst file
%   4 : find duplicated ids in dst file (to be used as input in fix_type=5)
%   5 : *** increment one out of 2 duplicated id's in dst file
%   6 : reset dd/mm/yyyy to original yyyy when needed
%   7 : crosscheck date with single month and day columns
%   8 : *** move marriage date in 1748-1809 range into "Data di
%           matrimonio religioso" column
%
% enable_write: [0,1] 1-> enable writing dst file if fixed
%
% % es. per analisi mestieri
% fix_csv_file(0,0)
% clc,list_indici = table_fix(1,:);ind_prof=find(~cellfun('isempty',regexp(list_indici,'Mestiere')));list_indici(ind_prof);for i_prof = 1:length(ind_prof),tag_field = list_indici{ind_prof(i_prof)};col=ind_prof(i_prof);vett = table_fix(2:end,col);fprintf(1,'%s (col. %d):\n',tag_field,col),vett_unique = unique(vett),end
%


if ~exist('fix_type','var') || isempty(fix_type)
    fprintf(1,'Usage:\nfix_death_age(fix_type)\n\nfix_type:\n\t1) fix "G;..." into "G,25;..."\n\t2) fix ";0;" into original ";.;"\n\n')
    error('Check usage.')
end

if ~ismember(enable_write,[0,1])
    error('enable_write must be either 0 or 1')
end

tag = 'file10_rc_20170114';
work_folder     = ['archivio/file10/' tag '_/'];
csvfile_src     = 'file10.csv.ok';              % best in class, official file
csvfile_dst     = [tag '_.csv'];    % proposed update, read only
csvfile_fix     = [tag '_ok.csv'];  % proposed update, rewritten by the script


switch fix_type
    case 0 % just load the file csvfile_dst, make it available as table_fix
        file_src = '';
        file_dst = [work_folder csvfile_dst];
        file_fix = '';
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 0;
        
    case 1 % take lines with only "M" or "G" directly from source file
        file_src = [work_folder csvfile_src];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = ';[MG];';
        str_fix.pat_substr_ok = '^(.+);[MG];';
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 1;
        
    case 2 % change ";0;" into ";.;" in destination file (but renamed as fix file)
        file_src = [work_folder csvfile_src];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = ';0;';
        str_fix.pat_substr_ok = ['^(.+?)' str_fix.pat_bad];
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 1;
        
    case 3 % find ";0;" in file
        file_src = [work_folder csvfile_dst];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = ';0;';
        % str_fix.pat_substr_ok = '^(.+?){30}.*?;0;';
        str_fix.pat_substr_ok = ['^(.+?)' str_fix.pat_bad];
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 0;
        
    case 4 % find duplicated ids in destination file
        file_src = [work_folder csvfile_dst];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        str_fix.flg_check_close = 0;
        flg_write = 1;
        
    case 5 % increment one out of 2 duplicated id's in destination file (based on previous test!!!)
        file_src = [work_folder csvfile_dst];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        % str_fix.list_split_id = {'55034','55174','55196','56422','56445','56531','56675'}; % param needed for fix_type 5 (empty if no duplicated id)
        str_fix.list_split_id = {'56846'}; % param needed for fix_type 5 (empty if no duplicated id)
        flg_write = 1;
        
    case 6 % reset dd/mm/yyyy to original yyyy when needed
        file_src = [work_folder csvfile_src];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 1;
        
    case 7 % crosscheck date with single month and day columns
        file_src = [work_folder csvfile_src];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        flg_write = 1;
        
    case 8 % move marriage date in 1748-1809 range into "Data di matrimonio religioso" column
        file_src = [work_folder csvfile_src];
        file_dst = [work_folder csvfile_dst];
        file_fix = [work_folder csvfile_fix];
        str_fix.pat_bad = '';
        str_fix.pat_substr_ok = '';
        str_fix.lines_dst_to_correct = [1 inf];
        str_fix.marriage_year_range = [1748 1809];
        flg_write = 1;
        
    otherwise
        error('errore!')
end

filename = file_src;
if ~isempty(filename)
    z = dir(filename);
    fid = fopen(filename, 'r');if (fid<1),error('Cannot open file %s',filename);end
    c = fread(fid, z(1).bytes);
    fclose(fid);
    c = char(c');
    lines = regexp(c,'[^\r\n]+','match')';
else
    lines = {};
end
lines_src = lines;

filename = file_dst;
if ~isempty(filename)
    z = dir(filename);
    fid = fopen(filename, 'r');if (fid<1),error('Cannot open file %s',filename);end
    c = fread(fid, z(1).bytes);
    fclose(fid);
    c = char(c');
    lines = regexp(c,'[^\r\n]+','match')';
else
    lines = {};
end
lines_dst = lines;

% find and replace bad lines
lines_fix = replace_bad_lines(lines_src,lines_dst,str_fix,fix_type);

% rework fixed file
table_fix = lines_to_table(lines_fix);
assignin('caller','table_fix',table_fix)
lines_fix = rework_fix_file(fix_type,str_fix,lines_fix,table_fix,lines_src);

% write fixed file
write_fixed_file(lines_fix,lines_dst,file_fix,enable_write,flg_write)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = replace_bad_lines(lines_src,lines_dst,str_fix,fix_type)

% find bad lines
list_bad = find(~cellfun('isempty',regexp(lines_dst,str_fix.pat_bad,'match')));

flg_correct = (list_bad >= min(str_fix.lines_dst_to_correct)) & (list_bad <= max(str_fix.lines_dst_to_correct));
if any(flg_correct == 0)
    fprintf(1,'Some lines to be fixed are outside the allowed range [%d-%d]. They will be skipped.\n',min(lines_dst_to_correct),max(lines_dst_to_correct))
    fprintf(1,'Lines that will be skipped:\n')
    disp(list_bad(~flg_correct)')
    list_bad = list_bad(flg_correct);
    fprintf(1,'\n')
    pause
end

% fix lines
lines_fix = lines_dst;
choplen = 80;
for i_bad=1:length(list_bad)
    ind_dst_bad = list_bad(i_bad);
    ks_bad = lines_dst{ind_dst_bad};
    
    z=regexp(ks_bad,str_fix.pat_substr_ok,'tokens');
    good_text = z{1}{1}; % good initial text before bad text, without ending ; (es. ";M;" or ";G;")
    
    ind_src_ok = strmatch(good_text,lines_src); % same row, but ok!
    if isempty(ind_src_ok) || (length(ind_src_ok)>1)
        disp(ind_src_ok)
        disp('No or too many matches!')
        pause
    end
    %ks_ok = lines_src{ind_src_ok};
    
    ks_ok = fix_line(fix_type,lines_dst{ind_dst_bad},lines_src{ind_src_ok});
    lines_fix{ind_dst_bad} = ks_ok;
    
    ind_show = unique(max(min(length(good_text)+(-choplen:choplen),length(ks_bad)),1));
    fprintf(1,'\n%03d)\n%s\n%s\n',i_bad,ks_bad(ind_show),ks_ok(ind_show(1):end))
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function write_fixed_file(lines_fix,lines_dst,file_fix,enable_write,flg_write)

if isequal(lines_fix,lines_dst)
    fprintf('No fix needed, no output file written.\n')
else
    if enable_write && flg_write
        fid = fopen(file_fix,'wb');
        
        fwrite(fid,lines_fix{1},'char');
        for i=2:length(lines_fix)
            fwrite(fid,sprintf('\n'),'char');
            fwrite(fid,lines_fix{i},'char');
        end
        fwrite(fid,sprintf('\n'),'char');
        
        fclose(fid);
        
        fprintf('Fix applied to %s\n',file_fix)
    else
        fprintf('Write disabled.\n')
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fix_line = fix_line(fix_type,line_bad,line_ok)
%
% fix_type      : type of fix
% line_bad      : bad dst line
% line_ok       : good src line
%

switch fix_type
    case 1 % copy line
        fix_line = line_ok;
        
    case 2 % ";0;" --> ";.;"
        
        if length(regexp(line_bad,';0;'))==1
            fix_line = strrep(line_bad,';0;',';.;');
        else
            fix_line = line_bad;
            
            cells_bad = regexp([line_bad ';'],'[^\;]*;','match');
            cells_ok  = regexp([line_ok ';'],'[^\;]*;','match');
            min_len = min(length(cells_bad),length(cells_ok))-4;
            matr=[cells_bad(1:min_len);cells_ok(1:min_len)];
            
            v_equal = zeros(1,size(matr,2));
            for i=1:size(matr,2)
                ks1=matr{1,i};
                ks2=matr{2,i};
                v_equal(i)=isequal(ks1,ks2);
            end
            
            if ~all(v_equal)
                v_not_equal = ~v_equal;
                
                num_zeros  = sum(strcmp(matr(1,v_not_equal),'0;'));
                num_points = sum(strcmp(matr(2,v_not_equal),'.;'));
                if (num_points == num_zeros) && (num_points>0) % is all diffs are points
                    line = cells_bad;
                    line(v_not_equal) = cells_ok(v_not_equal);
                    
                    ks=[line{:}];
                    fix_line = ks(1:end-1);
                    
                    disp('Fixing!')
                    pause(1)
                end
            end
            
        end
        
    case 3
        fix_line = line_bad;
        
    otherwise
        error('todo')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file(fix_type,str_fix,lines_fix,table_fix,lines_src)
% rework fixed file

switch fix_type
    case 0
        % fix on table (no check with src file)
        lines_fix = rework_fix_file_0(str_fix,lines_fix,table_fix);
        
    case {1 2 3}
        % no fixes on table here on table (no check with src file)
        
    case 4 % find duplicated ids in file9_bis9102011_
        lines_fix = rework_fix_file_4(str_fix,lines_fix,table_fix,lines_src);
        
    case 5 % increment one out of 2 duplicated id's in file9_bis9102011_
        lines_fix = rework_fix_file_5(str_fix,lines_fix,table_fix,lines_src);
        
    case 6 % reset dd/mm/yyyy to original yyyy when needed
        lines_fix = rework_fix_file_6(str_fix,lines_fix,table_fix,lines_src);
        
    case 7 % crosscheck date with single month and day columns
        lines_fix = rework_fix_file_7(str_fix,lines_fix,table_fix,lines_src);
        
    case 8 % move marriage date in 1748-1809 range into "Data di matrimonio religioso" column
        lines_fix = rework_fix_file_8(str_fix,lines_fix,table_fix,lines_src);
        
    otherwise
        error('todo: %d',fix_type)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_0(str_fix,lines_fix,table_fix) %#ok<INUSL>
% checks on file without compares with previous src file

% check for missing name or surname in SposoPrecedente or SposaPrecedente
% (needed two words separated by a space)
check_name_surname_fields(table_fix);

% check for "VEDI ANCHE ID check_note_linksxxx"
check_note_links(table_fix)

% check for sex of spouse (should be the opposite of self)
check_spouse_sex(table_fix)

% check for sex of father and mother (must be 'M' and 'F'), and other relatives
check_parents_sex(table_fix)

% cross-check marriage link
check_marriage_links(table_fix);

% check skipped ID numbers
check_skipped_ID_numbers(table_fix);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_4(str_fix,lines_fix,table_fix,lines_src) %#ok<INUSD>
% find duplicated ids in destination file

ind_delete = [];
[a b c] = unique(table_fix(:,1));
ind=setdiff(1:length(c),b);
for i=1:length(ind)
    fprintf(1,'\n%3d)\n\n',i);
    id=table_fix{ind(i),1};
    ind2=strmatch(id,table_fix(:,1));
    fprintf(1,'\tlines %d - %d\n',ind2(1),ind2(2));
    
    disp(table_fix(ind2,:))
    
    merge_line = {};
    v_ok=[];
    for i2=1:size(table_fix,2);
        ks1=table_fix{ind2(1),i2};
        ks2=table_fix{ind2(2),i2};
        flg_ok = (isempty(ks1) || isempty(ks2)) || isequal(ks1,ks2);
        v_ok(i2)=flg_ok; %#ok<AGROW>
        
        if isempty(ks2)
            merge_line{i2} = ks1; %#ok<AGROW>
        else
            merge_line{i2} = ks2; %#ok<AGROW>
        end
    end
    
    if all(v_ok)
        fprintf(1,'\n\t--> Mergeble\n\n')
        
        if (diff(ind2) == 1) || (str_fix.flg_check_close == 0)
            ks = sprintf('%s;',merge_line{:}); line_merge = ks(1:end-1);
            lines_fix{ind2(1)} = line_merge;
            
            ind_delete(end+1) = ind2(2); %#ok<AGROW>
            
            fprintf(1,'\t ...and merged!\n')
        else
            fprintf(1,'\tbut not merged.\n')
        end
        
    else
        fprintf(1,'\t differenze nelle colonne %s\n\n',num2str(find(~v_ok),'%d, '))
        fprintf(1,'\n\t--> WARNING: Unmergeable!\n\n')
    end
    
end

lines_fix(ind_delete) = []; % remove useless merged lines



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_5(str_fix,lines_fix,table_fix,lines_src) %#ok<INUSD>
% increment one out of 2 duplicated id's in fixed file

indice_id = 1;
ind_min_line = inf;
list_split_id = sort(str_fix.list_split_id);
for i_id=length(list_split_id):-1:1;
    ks_id = list_split_id{i_id};
    ind = strmatch(ks_id,table_fix(:,indice_id),'exact');
    
    fprintf(1,'\n\nUnsplitting: \n')
    disp(table_fix(ind,:))
    
    if length(ind)<2
        fprintf(1,'WARNING! You declared at least two id''s to be merged (%s), but I found at most 1: skipping\n',ks_id)
    else
        ind_start = ind(2);
        
        if ind_start<ind_min_line
            ind_min_line = ind_start;
        end
        
        list_id_inc = ind_start:size(table_fix,1);
        
        vett_id_old = table_fix(list_id_inc,1);
        vett_id_new = vett_id_old;
        for i=1:length(vett_id_new)
            vett_id_new{i} = num2str(str2double(vett_id_old{i})+1);
        end
        
        table_fix(list_id_inc,indice_id) = vett_id_new;
    end
end

if ~isinf(ind_min_line)
    lines_fix_sub = table_to_lines(table_fix(ind_min_line:end,:));
    lines_fix(ind_min_line:end)=lines_fix_sub;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_6(str_fix,lines_fix,table_fix,lines_src) %#ok<INUSL>
% reset dd/mm/yyyy to original yyyy when needed

fmt_ok = '^[0-9]{4}$';
col_max = 39; % last column to be fixed

table_src = lines_to_table(lines_src);

z=regexp(table_src(:,1:col_max),fmt_ok);
ind = find(sum(~cellfun('isempty',z),2)');

for i_line = 1:length(ind)
    ind_src = ind(i_line);
    record_src = table_src(ind_src,:);
    
    ks = sprintf('%s;',record_src{2:6});ks=ks(1:end-1);
    
    ind_fix = find(~cellfun('isempty',regexp(lines_fix,ks)));
    record_fix = table_fix(ind_fix,:);
    if isempty(ind_fix)
        fprintf(1,'No match found in src file, line %d: %s\n',ind_src,ks)
        pause
        continue
    elseif (length(ind_fix)>1)
        %disp([record_src(:,1:col_max);record_fix(:,1:col_max)])
        fprintf(1,'Too many matches found: %s\n',ks)
        
        id_src = str2double(record_src(:,1));
        id_fix = str2double(record_fix(:,1));
        
        ind_best = find(abs(id_fix-id_src)==0); % same id
        if isempty(ind_best)
            ind_best = find(abs(id_fix-id_src)<3); % close id
        end
        
        if length(ind_best)==1
            ind_fix = ind_fix(ind_best);
            record_fix = record_fix(ind_best,:);
            fprintf(1,'\t...but found a good match, proceeding with id %s\n',record_fix{1})
        else
            disp([record_src(:,1:col_max);record_fix(:,1:col_max)])
            continue
        end
    end
    
    %disp([record_src(:,1:col_max);record_fix(:,1:col_max)])
    
    flg_changed = 0;
    for i=1:col_max
        if regexp(record_src{i},fmt_ok) % if field matches the format
            if ~strcmp(record_fix{i},record_src{i}) % if field changed
                disp([record_src(:,1:col_max);record_fix(:,1:col_max)])
                fprintf(1,'%d) %s (%d) -> %s (%d)\n',i,record_src{i},ind_src,record_fix{i},ind_fix)
                
                % if only-year date was completed, ask about what to do
                if regexp(record_fix{i},'[0-9]{2}/[0-9]{2}/[0-9]{4}')
                    temp_vec = datevec(record_fix{i},'dd/mm/yyyy');
                    year_fix = temp_vec(1);
                    
                    if ( year_fix == str2double(record_src{i}) )
                        fprintf(1,'\tOld date "%s" was completed, should I reset it or leave the new one "%s"?\n',record_src{i},record_fix{i})
                        r = input('keep New, or Reset to old date? [N/r] ','s');
                        if isempty(r) || strcmpi(r,'N')
                            fprintf(1,'\t\tLeave new (%s).n',record_fix{i})
                        else
                            fprintf(1,'\t\tReset to old (%s).n',record_src{i})
                            record_fix{i}=record_src{i};
                            flg_changed = 1;
                        end
                    else
                        if ( abs(year_fix - str2double(record_src{i})) <= 1 ) % if year change is less than 2 years, ask before resetting to src value
                            fprintf(1,'\tOld date "%s" was slightly changed, should I reset it or leave the new one "%s"?\n',record_src{i},record_fix{i})
                            r = input('keep New, or Reset to old date? [N/r] ','s');
                        else
                            r = 'r';
                        end
                        
                        if isempty(r) || strcmpi(r,'N')
                            fprintf(1,'\t\tLeave new (%s).n',record_fix{i})
                        else
                            % reset the field to the one from src file
                            fprintf(1,'\t\tReset to old (%s).n',record_src{i})
                            record_fix{i}=record_src{i};
                            flg_changed = 1;
                        end
                    end
                end
            else
                fprintf(1,'%d) %s (%d,%d)\n',i,record_src{i},ind_src,ind_fix)
            end
        end
    end
    
    if flg_changed
        ks = sprintf('%s;',record_fix{:});
        ks = ks(1:end-1);
        
        lines_fix{ind_fix} = ks;
        fprintf(1,'\t\tFixed line %d\n',ind_fix)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_date = merge_multiple_dates(matr_date,ks_id)
% merge multiple columns into one, according the rules:
%   - empty if no marriage available;
%   - the only date possible, if only one is available;
%   - the date more in the left in input matrix, if multiple are available.

ks_date = matr_date(:,1);

num_col = size(matr_date,2);
if ( num_col>1 )
    
    fprintf(1,'\nMerging multiple (%d) date columns into one:\n',num_col)
    fprintf(1,'\t- empty if no marriage available;\n')
    fprintf(1,'\t- the only date possible, if only one is available among civil and religious;\n')
    fprintf(1,'\t- the civil marriage date, if both are available.\n')
    
    max_delta = 90; % [giorni]
    for i=1:size(matr_date,1)
        vett_ks = matr_date(i,:);
        id_i = ks_id{i};
        
        if ~isempty(vett_ks{1})
            % only civil date
            ks_date{i} = vett_ks{1};
            
            if ~isempty(vett_ks{2})
                %fprintf(1,'\tMultiple dates: %s - %s\n',vett_ks{1},vett_ks{2})
                if ( ~isempty(regexp(vett_ks{1},'[0-9]{2,2}/[0-9]{2,2}/[0-9]{4,4}', 'once')) && ~isempty(regexp(vett_ks{2},'[0-9]{2,2}/[0-9]{2,2}/[0-9]{4,4}', 'once')) )
                    vett_num = datenum(vett_ks,'dd/mm/yyyy');
                else
                    disp(vett_ks)
                    fprintf(1,'Not all dates are in the dd/mm/yyyy format! (ID %s)\n',id_i)
                    pause
                    continue
                end
                delta = max(abs(diff(vett_num)));
                if ( delta>max_delta )
                    fprintf(1,'\t\tBig date difference (more than %d days): %s\n',max_delta,sprintf('%s, ',vett_ks{:}))
                end
                % check for swap in one of the two dates
                vett1=datevec(vett_ks{1},'dd/mm/yyyy');
                vett2=datevec(vett_ks{2},'dd/mm/yyyy');
                year1=vett1(1);
                year2=vett2(1);
                if vett2(3)<=12
                    % swap second date
                    num1=datenum(vett_ks{1},'dd/mm/yyyy');
                    num2=datenum([vett2(1) vett2(3) vett2(2) vett2(4:end)]);
                    delta_swap = abs(num1-num2);
                elseif vett1(3)<=12
                    % swap first date
                    num1=datenum([vett1(1) vett1(3) vett1(2) vett1(4:end)]);
                    num2=datenum(vett_ks{2},'dd/mm/yyyy');
                    delta_swap = abs(num1-num2);
                else
                    % no check possible
                    delta_swap = inf;
                end
                if ((year1==year2) && (delta_swap<delta) && (delta_swap<20) )
                    fprintf(1,'\t\t\tATTENTION! Possible swap in day\\month columns: ID %s: %s - %s\n',id_i,vett_ks{1},vett_ks{2})
                end
            end
        else
            % missing civil date
            ks_date{i} = vett_ks{2};
            %fprintf(1,'\tOnly religious date: %s\n',vett_ks{2})
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_7(str_fix,lines_fix,table_fix,lines_src) %#ok<INUSL,INUSD>
% crosscheck date with single month and day columns

ind_giorno_nascita = strmatch('Giorno nascita',table_fix(1,1:end));

% {[date,day,month,year,num_date],caption}
matr_ind = ...
    { 7          ind_giorno_nascita+0+(0:3)   'nascita';
    [23 40]    ind_giorno_nascita+4+(0:3)   'matrimonio';
    35         ind_giorno_nascita+8+(0:3)   'morte';
    };

flg_fixed = 0;
for i_event=1:size(matr_ind,1)
    ind_id      = 1; % ID column is the first
    ind_date    = matr_ind{i_event,1};
    ind_day     = matr_ind{i_event,2}(1);
    ind_month   = matr_ind{i_event,2}(2);
    ind_year    = matr_ind{i_event,2}(3);
    ind_datenum = matr_ind{i_event,2}(4);
    ind_tag     = matr_ind{i_event,3};
    
    fprintf(1,'\n\nVerifica date di %s:\n',ind_tag)
    
    ind_any=find([0;any(~cellfun('isempty',table_fix(2:end,[ind_date ind_day ind_month ind_year])),2)]); % rows with at least one non empty field
    
    ks_id       = table_fix(ind_any,ind_id);
    ks_date     = table_fix(ind_any,ind_date);
    ks_day      = table_fix(ind_any,ind_day);
    ks_month    = table_fix(ind_any,ind_month);
    ks_year     = table_fix(ind_any,ind_year);
    ks_datenum  = table_fix(ind_any,ind_datenum); %#ok<NASGU>
    
    % merge multiple columns into one, according the rules:
    %   - empty if no marriage available
    %   - the only date possible, if only one is available among civil and religious;
    %   - the civil marriage date, if both are available
    ks_date = merge_multiple_dates(ks_date,ks_id);
    
    for i=1:length(ind_any)
        ind_i = ind_any(i);
        
        ks_id_i     = ks_id{i};
        ks_date_i   = ks_date{i};
        ks_day_i    = ks_day{i};
        ks_month_i  = ks_month{i};
        ks_year_i   = ks_year{i};
        
        if (length(ks_day_i)<2)
            ks_day_i    = [repmat('0',1,2-length(ks_day_i)) ks_day_i]; %#ok<AGROW>
        end
        if (length(ks_month_i)<2)
            ks_month_i  = [repmat('0',1,2-length(ks_month_i)) ks_month_i]; %#ok<AGROW>
        end
        
        ks_date2 = [ks_day_i '/' ks_month_i '/' ks_year_i];
        
        if ~isequal(ks_date_i,ks_date2)
            ks_dates = ['ID ' sprintf('%5s',ks_id_i) ': "' ks_date_i,'" <--> "',ks_day_i '/' ks_month_i '/' ks_year_i '"'];
            
            if regexp(ks_date_i,'^1[6789][0-9][0-9]$')
                
                if ( ~isempty(ks_year_i) && ~strcmp(ks_year_i,num2str(ks_date_i)) )
                    error('Year mismatch for record %s: (%s,%s)!',ks_id_i,ks_year_i,num2str(ks_date_i))
                end
                fprintf(1,'\tIncomplete date format, only year: %s\n',ks_dates)
                
            elseif isequal(ks_date2,'00/00/')
                % detect dates with sure days\months (where month and days
                % cannot be changed, as day is greater than 12)
                if ~isempty(regexp(ks_date_i,'[0-9]{2,2}/[0-9]{2,2}/[0-9]{4,4}', 'once')) && ~isequal(ks_date_i,datestr(datevec(ks_date_i,'mm/dd/yyyy'),'mm/dd/yyyy'))
                    vett = datevec(ks_date_i,'dd/mm/yyyy');
                    table_fix(ind_i,[ind_year ind_month ind_day ind_datenum])={num2str(vett(1)) num2str(vett(2)) num2str(vett(3)) num2str(((vett(3)-1)/31+vett(2)-1)/12+vett(1),'%.4f')};
                    flg_fixed = 1;
                    fprintf(1,'\tMissing gg mm yyyy columns: %s\t\tColumns added!\n',ks_dates)
                else
                    % ask the user what to do
                    flg_ask = 1;
                    fprintf(1,'\tMissing gg mm yyyy columns: %s\n',ks_dates)
                    if flg_ask
                        ch = input('Modifico? [S/n]','s');
                        if (ismember(upper(ch),{'S',''}))
                            vett = datevec(ks_date_i,'dd/mm/yyyy');
                            if strcmp(datestr(vett,'dd/mm/yyyy'),ks_date_i)
                                table_fix(ind_i,[ind_year ind_month ind_day ind_datenum])={num2str(vett(1)) num2str(vett(2)) num2str(vett(3)) num2str(((vett(3)-1)/31+vett(2)-1)/12+vett(1),'%.4f')};
                                flg_fixed = 1;
                                table_fix(ind_i,:)
                                fprintf(1,'\t\tColumns added!\n')
                            else
                                % detect ks_date_i='03/13/1913' (wrong format) --> 03/01/1914
                                fprintf(1,'????? Unmanaged: possible wrong format for ID %s: "%s"\n',ks_id_i,ks_date_i)
                            end
                        else
                            fprintf(1,'\t\tSkipped.\n')
                        end
                    end
                end
                
            else
                try
                    num_date_i = datenum(ks_date_i,'dd/mm/yyyy');
                    err_date = 0;
                catch %#ok<CTCH>
                    err_date = 1;
                end
                if err_date
                    fprintf(1,'--> Wrong date format: %s\n',ks_dates)
                else
                    try
                        temp_date2 = datenum(ks_date2,'dd/mm/yyyy');
                    catch %#ok<CTCH>
                        error('Error in parsing date %s.',ks_date2)
                    end
                    diff_day = num_date_i-temp_date2;
                    if abs(diff_day)<=5
                        vett = datevec(ks_date{i},'dd/mm/yyyy');
                        table_fix(ind_i,[ind_year ind_month ind_day])={num2str(vett(1)) num2str(vett(2)) num2str(vett(3))};
                        flg_fixed = 1;
                        fprintf(1,'\tOnly a few days of diff: %s\t\tColumns fixed!\n',ks_dates)
                    else
                        fprintf(1,'????? Unmanaged: %s\n',ks_dates)
                    end
                end
            end
        end
    end
end

if flg_fixed
    lines_fix = table_to_lines(table_fix);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines_fix = rework_fix_file_8(str_fix,lines_fix,table_fix,lines_src) %#ok<INUSL,INUSD>
% move marriage date in 1748-1808 range into "Data di matrimonio religioso"
% column

tag_src = 'Data di matrimonio';
tag_dst = 'Data di matrimonio religioso';

ind_data_matr       = strmatch(tag_src,table_fix(1,1:end),'exact');
ind_data_matr_relig = strmatch(tag_dst,table_fix(1,1:end),'exact');

year_matr_range = [1748 1808]; % year range for which no civil records exist: if present, the marriage date must be a religious one

flg_fixed = 0;

ind_any=find([0;any(~cellfun('isempty',table_fix(2:end,[ind_data_matr ind_data_matr_relig])),2)]); % record con almeno una cella non vuota

ks_date_matr       = table_fix(ind_any,ind_data_matr);
ks_date_matr_relig = table_fix(ind_any,ind_data_matr_relig);

for i=1:length(ind_any)
    ind_i = ind_any(i);
    
    ks_date_matr_i          = ks_date_matr{i};
    ks_date_matr_relig_i    = ks_date_matr_relig{i};
    
    if ~isempty(ks_date_matr_i)
        % data matrimonio presente
        flg_date_ok1 = ~isempty(regexp(ks_date_matr_i,'([0-9]{2})/([0-9]{2})/([0-9]{4})','once'));
        flg_date_ok2 = ~isempty(regexp(ks_date_matr_i,'([0-9]{4})','once'));
        flg_date_ok = flg_date_ok1 || flg_date_ok2;
        if flg_date_ok
            % formato data matrimonio corretto
            if flg_date_ok1
                num_date_matr = datenum(ks_date_matr_i,'dd/mm/yyyy');
            else
                num_date_matr = datenum(ks_date_matr_i,'yyyy');
            end
            temp = datevec(num_date_matr);
            year_date_matr = temp(1);
            if ( (year_date_matr>=year_matr_range(1)) && (year_date_matr<=year_matr_range(2)) )
                % data matrimonio nel range richiesto
                if isempty(ks_date_matr_relig_i)
                    % scambia le celle
                    table_fix(ind_i,[ind_data_matr ind_data_matr_relig])={ks_date_matr_relig_i ks_date_matr_i};
                    flg_fixed = 1;
                    fprintf(1,'\tLine %d: value "%s" moved to column "%s"\n',ind_i,ks_date_matr_i,tag_dst)
                else
                    fprintf(1,'\tLine %d: values present in both columns: "%s" and "%s"\n',ind_i,ks_date_matr_i,ks_date_matr_relig_i)
                    input('Press any key to continue...','s')
                end
            end
        else
            fprintf(1,'\tLine %d: wrong date format: "%s"\n',ind_i,ks_date_matr_i)
            error('b')
        end
    end
end

if flg_fixed
    lines_fix = table_to_lines(table_fix);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function table = lines_to_table(lines)

if ~isempty(lines)
    num_col = sum(lines{1}==';')+1;
    [table{length(lines),num_col}]=deal('');
    fmt = [repmat('([^\;]*);',1,num_col-1) '([^\;]*)'];
    for i=1:length(lines);
        ks=lines{i};
        z=regexp(ks,fmt,'tokens');
        table(i,:)=[z{:}];
    end
else
    table = {};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lines = table_to_lines(table)

[lines{1:size(table,1),1}] = deal('');
for i=1:size(table,1)
    ks=sprintf('%s;',table{i,:});
    lines{i,1} = ks(1:end-1);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_name_surname_fields(table_fix)
% check for missing name or surname in SposoPrecedente or SposaPrecedente
% (needed two words separated by a space)

list_field = {'SposaPrecedente','SposoPrecedente'};

header = table_fix(1,:);
col_list = zeros(1,length(list_field));
ks = '';
for i_col = 1:length(list_field)
    col_list(i_col) = strmatch(list_field{i_col},header,'exact');
    ks = [ks list_field{i_col} ' or ']; %#ok<AGROW>
end
ks = ks(1:end-4);

disp(' ');disp([ks ' missing the Name or Surname (single word in the field)...'])

for col=col_list
    ind_not_empty = find(~cellfun('isempty',table_fix(2:end,col)))+1; % all non empty lines, discarding header
    ind2=find(cellfun('isempty',regexp(table_fix(ind_not_empty,col),'\s')));
    output = table_fix(ind_not_empty(ind2),[1 col]); %#ok<FNDSB>
end
if ~isempty(output)
    disp(output)
else
    fprintf(1,'\tNo error found\n')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_spouse_sex(table_fix)
% check for sex of spouse (should be the opposite of self)

header = table_fix(1,:);
col_id = strmatch('IDElenco',header,'exact');
col_nome = strmatch('Nome',header,'exact');
col_con_nome = strmatch('Nomeconiuge',header,'exact');


disp(' ');disp('Checking sex of spouse...')

for i=2:size(table_fix,1)
    ks_id_file=table_fix{i,col_id};
    ks_nome=table_fix{i,col_nome};
    ks_con_nome=table_fix{i,col_con_nome};
    con_sex=ged('determine_sex',ks_con_nome);
    self_sex=ged('determine_sex',ks_nome);
    if ~isempty(self_sex) && strcmp(self_sex,con_sex)
        msg=' ERRORE!!!';
        
        fprintf(1,'\tID %5s:  %20s (%1s) - %20s (%1s) %s\n',ks_id_file,ks_nome,self_sex,ks_con_nome,con_sex,msg)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_parents_sex(table_fix)
% check for sex of father and mother (must be 'M' and 'F'), and other
% relatives

header = table_fix(1,:);
col_id = strmatch('IDElenco',header,'exact');
col_nome = strmatch('Nome',header,'exact');

matr_sex = {
    'pad'           , 'Nomepadre'           , 'M'
    'mad'           , 'NomeM'               , 'F'
    'con_pad_nome'  , 'Nome padre coniuge'  , 'M'
    'con_mad_nome'  , 'Nome mamma coniuge'  , 'F'
    'pad_pad'       , 'NonnoPaterno'        , 'M'
    'mad_pad'       , 'NonnoMaterno'        , 'M'
    };


disp(' ');disp('Checking sex of parents...')

for i_type = 1:size(matr_sex,1)
    tag_i    = matr_sex{i_type,1};
    header_i = matr_sex{i_type,2};
    sex_ok_i = matr_sex{i_type,3};
    
    col_nome_i = strmatch(header_i,header,'exact');
    
    fprintf(1,'  %s (%s):\n\n',tag_i,header_i)
    for i=2:size(table_fix,1)
        ks_id_file=table_fix{i,col_id};
        ks_nome=table_fix{i,col_nome};
        ks_nome_i=table_fix{i,col_nome_i};
        sex_i=ged('determine_sex',ks_nome_i);
        if ~isempty(sex_i) && ~strcmp(sex_i,sex_ok_i)
            msg=[' ERROR!!! Should be ' sex_ok_i];
            
            fprintf(1,'\tID %5s:  %20s - %20s (%1s) %s\n',ks_id_file,ks_nome,ks_nome_i,sex_i,msg)
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_note_links(table_fix)
% check for missing name or surname in SposoPrecedente or SposaPrecedente
% (needed two words separated by a space)

header = table_fix(1,:);
col = strmatch('Note',header,'exact');
col_id = strmatch('IDElenco',header,'exact');

% fields to be shown
list_field = {'Data di matrimonio','Data di morte'};
col_show_list = zeros(1,length(list_field));
for i_col = 1:length(list_field)
    col_show_list(i_col) = strmatch(list_field{i_col},header,'exact');
end

% fields to be matched
list_field = {'Cognome', 'Nome', 'Nomepadre','CognomeM','NomeM','Data di nascita'};
col_list = zeros(1,length(list_field));
for i_col = 1:length(list_field)
    col_list(i_col) = strmatch(list_field{i_col},header,'exact');
end
thr_sum = length(col_list)*0.8;





disp(' ');disp('Checking note fields')

ind_not_empty = find(~cellfun('isempty',table_fix(2:end,col)))+1; % all non empty lines, discarding header

notes=regexp(table_fix(ind_not_empty,col),'[^-]+','match');

% find links
matr = {};
[matr_link{1:size(table_fix,1),1:3}]=deal('');
for i_row=1:length(notes)
    ind_table = ind_not_empty(i_row);
    notes_i=notes{i_row};
    id=table_fix{ind_table,col_id};
    matr_link(ind_table,:) = {id, '',ind_table};
    for i_note=1:length(notes_i),
        note=strtrim(notes_i{i_note});
        matr(end+1,:) = {ind_table,i_row,i_note,note}; %#ok<AGROW> % note = table_fix{ind_not_empty(i_row),41}
        if regexp(note,'VEDI ANCHE ID [0-9]+')
            % fprintf(1,'%d %d %s\n',i_row,i_note,note)
            links = regexp(note,'[0-9]+','match');
            matr_link{ind_table,2} = links; % update links field
        elseif regexp(note,'(VEDI|ANCHE| ID |[0-9]{5,5})')
            fprintf(1,'%s: check note "%s" (contains keywords VEDI|ANCHE| ID)\n',id,note)
            pause(1)
        end
    end
    %     matr_link{ind_table,1} = id;
end
fprintf(1,'\nAnalyzing %d link notes...\n',size(matr,1))

% check cross links
output = {};
ind_check = find(~cellfun('isempty',matr_link(:,col_id)));
for i_check = 1:size(ind_check,1)
    matr_record = matr_link(ind_check(i_check),:);
    id          = matr_record{1};
    links       = matr_record{2};
    for i_link = 1:length(links)
        link = links{i_link};
        ind_link = strmatch({link},matr_link(:,1));
        msg_out = '';
        msg_type = 0;
        if isempty(ind_link)
            msg_type = 1;
            msg_out = sprintf('Id %s links to %s, that does not link back!',id,link);
        elseif (strcmp(id,link))
            msg_type = 4;
            msg_out = sprintf('Id %s links to itself!',id);
        else
            id_links = matr_link{ind_link,2};   % id of link destination
            ind_table   = matr_link{ind_link,3};% pos in table_fix of link destination
            if ~ismember(id,id_links)
                if isempty(id_links)
                    msg_type = 2;
                    %ks_links = 'no links';
                else
                    msg_type = 3;
                    %ks_links = sprintf('%s,',id_links{:});
                end
                %ks_links = ks_links(1:end-1);
                
                msg_out = sprintf('Id %s links to %s, that does not link back (note for %s: %s)!',id,link,link,table_fix{ind_table,col});
            end
        end
        
        % try to detect linkable record
        if (~isempty(msg_out))
            matr_flag = ones(size(table_fix,1),length(col_list))>0;
            for i_col = 1:length(col_list)
                matr_flag(:,i_col) = strcmp(repmat(table_fix(matr_record{3},col_list(i_col)),size(table_fix,1),1),table_fix(:,col_list(i_col)));
            end
            v_sum = sum(matr_flag,2);
            ind_match = find(v_sum>=thr_sum);
            
            %detect col width
            cols = [col_id col_list col_show_list]; % field columns to be shown
            col_width = cols*NaN;
            for i_col_show=1:length(cols),col_width(i_col_show)=size(strvcat(table_fix(ind_match,cols(i_col_show))),2);end %#ok<VCAT>
            temp=num2cell(col_width');ks_format=sprintf('%%%ds,',temp{:});
            
            switch length(ind_match)
                case 1
                    link_type = 1;
                    msg_match = '*** NO GOOD MATCH!';
                    
                case 2
                    link_type = 2;
                    [match_id ind_ok]= setdiff(table_fix(ind_match,col_id),id);
                    msg_match = sprintf('only one possible match: %s',match_id{1});
                    % show matches
                    temp=table_fix(matr_record{3},cols);
                    msg_match=sprintf('%s\n\t    --->%s',msg_match,sprintf(ks_format,temp{:}));
                    temp=table_fix(ind_match(ind_ok),cols);
                    msg_match=sprintf('%s\n\t\t%s',msg_match,sprintf(ks_format,temp{:}));
                    
                otherwise
                    link_type = 3;
                    % prepare output
                    [match_id ind_temp] = setdiff(table_fix(ind_match,col_id),id);
                    matr_match_ok = [match_id num2cell(v_sum(ind_match(ind_temp))) num2cell(ind_match(ind_temp))];
                    [temp ind_sort]=sort(-v_sum(ind_match(ind_temp)));
                    matr_match_ok = matr_match_ok(ind_sort,:);
                    temp=matr_match_ok(:,1:2)';
                    ks_match=sprintf('%s (%d),',temp{:});
                    ks_match=ks_match(1:end-1);
                    msg_match = sprintf('possible matches: %s',ks_match);
                    % show matches
                    temp=table_fix(matr_record{3},cols);
                    msg_match=sprintf('%s\n\t    --->%s',msg_match,sprintf(ks_format,temp{:}));
                    for i_record=1:size(matr_match_ok,1)
                        temp=table_fix(cell2mat(matr_match_ok(i_record,3)),cols);
                        msg_match=sprintf('%s\n\t\t%s',msg_match,sprintf(ks_format,temp{:}));
                    end
            end
            msg_out = sprintf('%s\n\t%s',msg_out,msg_match);
            output(end+1,:) = {msg_out,msg_type,link_type}; %#ok<AGROW>
        end
    end
end
if ~isempty(output)
    % sort
    [temp,ind_sort]=sort(-sum(cell2mat(output(:,2:3)).*repmat([1 10],size(output,1),1),2));
    output=output(ind_sort,:);
    
    for i=1:size(output,1)
        disp(' ')
        disp(output{i,1})
    end
else
    fprintf(1,'\tNo bad cross links\n')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_marriage_links(table_fix)
% check for missing marriage links: the marriage link (date, name of spouse) must be present for
% two records in the file

% fitness threshold to consider a marriage match valid (0 --> perfect match)
threshold_marriage_fit = 0.15;

% fitness threshold below which an invalid match could be due to a slight mistype
threshold_marriage_fit_2 = 0.25;

% step to show progress during calculations
step = 500;

header = table_fix(1,:);
col = strmatch('Data di matrimonio',header,'exact');
col_id = strmatch('IDElenco',header,'exact');
col_nome = strmatch('Nome',header,'exact');
col_nome2 = strmatch('Secondo nome',header,'exact');
col_cogn = strmatch('Cognome',header,'exact');
col_con_nome = strmatch('Nomeconiuge',header,'exact');
col_con_cogn = strmatch('Cognomeconiuge',header,'exact');

disp(' ');disp('Checking marriage links')

ind_not_empty = find(~cellfun('isempty',table_fix(2:end,col)))+1; % all non empty lines, discarding header

% find links
vett_matr       = table_fix(ind_not_empty,col);
vett_id         = table_fix(ind_not_empty,col_id);
vett_nome       = table_fix(ind_not_empty,col_nome);
vett_nome2      = table_fix(ind_not_empty,col_nome2);
vett_cogn       = table_fix(ind_not_empty,col_cogn);
vett_con_nome   = table_fix(ind_not_empty,col_con_nome);
vett_con_cogn   = table_fix(ind_not_empty,col_con_cogn);

vett_err_code(length(ind_not_empty)) = 0;
vett_fitness(length(ind_not_empty)) = 0;
vett_err_msg{length(ind_not_empty)} = '';
vett_id_con{length(ind_not_empty)} = [];
debug = 0;
for i_row = 1:length(ind_not_empty)
    %ind_table   = ind_not_empty(i_row);
    matr_i      = vett_matr{i_row};
    id          = vett_id{i_row};
    nome        = vett_nome{i_row};
    nome2       = vett_nome2{i_row};
    cogn        = vett_cogn{i_row};
    con_nome    = vett_con_nome{i_row};
    con_cogn    = vett_con_cogn{i_row};
    
    nome_full = strtrim([nome ' ' nome2]);
    
    % enable debug on a single ID
    if strcmp(id,'<disabled>')
        debug = 1;
    end
    
    if (rem(i_row,step)==0)
        fprintf(1,'%d/%d...\n',i_row,length(ind_not_empty))
    end
    
    ind_match = setdiff(strmatch(matr_i,vett_matr,'exact'),i_row); % records whose marriage date matches
    
    if debug
        fprintf('\n\tUnder check ID %s: %s %s married to %s %s on %s\n',id,nome_full,cogn,con_nome,con_cogn,matr_i)
    end
    
    err_code = 0;
    err_msg = 'marriage link ok';
    id_con = NaN;
    if isempty(ind_match)
        % missing marriage link
        err_code = 1;
        fit_best = NaN;
        err_msg = 'missing matching marriage date';
    else
        % one or more marriages in the same date, check if one matches
        matr_val = [];
        for i_match = 1:length(ind_match)
            i_row_ = ind_match(i_match);
            
            %ind_table_  = ind_not_empty(i_row_);
            matr_i_     = vett_matr{i_row_};
            id_         = vett_id{i_row_};
            nome_       = vett_nome{i_row_};
            nome2_      = vett_nome2{i_row_};
            cogn_       = vett_cogn{i_row_};
            con_nome_   = vett_con_nome{i_row_};
            con_cogn_   = vett_con_cogn{i_row_};
            
            nome_full_ = strtrim([nome_ ' ' nome2_]);
            
            if debug
                fprintf('\t\twith ID %s: %s %s married to %s %s on %s\n',id_,nome_full,cogn_,con_nome_,con_cogn_,matr_i_)
            end
            
            v_val_nome_     = ged('strfielddist',nome_full,con_nome_);
            v_val_cogn_     = ged('strfielddist',cogn,con_cogn_);
            v_val_con_nome_ = ged('strfielddist',con_nome,nome_full_);
            v_val_con_cogn_ = ged('strfielddist',con_cogn,cogn_);
            
            matr_val(i_match,:) = [v_val_nome_;v_val_cogn_;v_val_con_nome_;v_val_con_cogn_]; %#ok<AGROW>
        end
        
        if debug
            disp(matr_val)
        end
        
        v_fitness = sum(matr_val,2)/size(matr_val,2);
        [temp ind_best] = sort(v_fitness);
        
        % take the best match
        i_match  = ind_best(1);
        fit_best = temp(1);
        
        i_row_ = ind_match(i_match);
        
        %ind_table_  = ind_not_empty{i_row_};
        matr_i_     = vett_matr{i_row_};
        id_         = vett_id{i_row_};
        nome_       = vett_nome{i_row_};
        nome2_      = vett_nome2{i_row_};
        cogn_       = vett_cogn{i_row_};
        con_nome_   = vett_con_nome{i_row_};
        con_cogn_   = vett_con_cogn{i_row_};
        
        nome_full_ = strtrim([nome_ ' ' nome2_]);
        
        if debug
            fprintf('\t\tbest match found with ID %s: %s %s married to %s %s on %s (fitness %f)\n',id_,nome_full_,cogn_,con_nome_,con_cogn_,matr_i_,fit_best)
        end
        
        if (fit_best < threshold_marriage_fit)
            % marriage match found
            id_con = id_;
        else
            %disp('*** ATTENTION: no valid marriage match found!')
            if fit_best < threshold_marriage_fit_2
                
                if rem(length(ind_match),2)==1
                    % if there is only one match (with additional couples),
                    % show the id corresponding to the best match
                    id_con = id_;
                end
            end
            
            err_code = 2;
            err_msg = 'no valid marriage match';
        end
    end
    
    vett_fitness(i_row)  = fit_best;
    vett_err_code(i_row) = err_code;
    vett_err_msg{i_row}  = err_msg;
    vett_id_con{i_row}   = id_con;
end
vett_fitness  = vett_fitness';
vett_err_code = vett_err_code';
vett_err_msg  = vett_err_msg';
vett_id_con   = vett_id_con';


%% prepare Matlab commands to continue searches
fprintf(1,'\n\n\n%%**************************\n%%*** Prepare Matlab commands to continue searches \n%%**************************\n\n')
diary off
try delete('marriage_link_analysis.m');catch;end %#ok<CTCH>
diary('marriage_link_analysis.m')
for i_code = 1:3
    switch i_code
        case 1
            % threshold_marriage_fit<=fitness<threshold_marriage_fit_2 --> no valid marriage match, but a good fitness, maybe a mistype?
            ind_err_code = find(vett_fitness>=threshold_marriage_fit & vett_fitness<threshold_marriage_fit_2);
            ks_code = 'Medium fitness matches';
        case 2
            % fitness>=threshold_marriage_fit_2 --> no valid marriage match, and a very low fitness
            ind_err_code = find(vett_fitness>=threshold_marriage_fit_2);
            ks_code = 'Low fitness matches';
        case 3
            % fitness==NaN --> no marriage match based on the marriage date
            ind_err_code = find(isnan(vett_fitness));
            ks_code = 'Missing matches';
        otherwise
            error('Error: todo')
    end
    
    fprintf(1,'\n\ndisp('' '');disp('' '');disp(''-- %s --'');disp('' '');disp('' '');\n\n',ks_code)
    for i_match = 1:length(ind_err_code)
        i_row = ind_err_code(i_match);
        
        %ind_table   = ind_not_empty(i_row);
        matr_i      = vett_matr{i_row};
        id          = vett_id{i_row};
        nome        = vett_nome{i_row};
        nome2       = vett_nome2{i_row};
        cogn        = vett_cogn{i_row};
        con_nome    = vett_con_nome{i_row};
        con_cogn    = vett_con_cogn{i_row};
        fitness     = vett_fitness(i_row);
        %err_code    = vett_err_code(i_row);
        %err_msg     = vett_err_msg{i_row};
        %id_con      = vett_id_con{i_row};
        
        nome_full = strtrim([nome ' ' nome2]);
        
        fprintf(1,'\ndisp('' '');disp('' '');disp(''Under check ID %s: %s %s married to %s %s on %s ... (%d matches with the same marriage date, best fit: %f)'')\n',id,str_escape(nome_full),str_escape(cogn),str_escape(con_nome),str_escape(con_cogn),matr_i,length(ind_match),fitness)
        cmd = ['Result = ged(''find_person'',struct  ( ''cogn'',''' str_escape(con_cogn) ''',''nome'',''' str_escape(con_nome) ''',''con_cogn'',''' str_escape(cogn) ''',''con_nome'',''' str_escape(nome_full) ''' ),str_archivio,0.25,[]);'];
        disp(cmd)
    end
end
diary off
edit('marriage_link_analysis.m')


%% show results
fprintf(1,'\n\n\n%%**************************\n%%*** Show results \n%%**************************\n\n')
list_code = unique(vett_err_code);
for i_code = 1:length(list_code)
    err_code_i = list_code(i_code);
    ind_err_code = find(vett_err_code==err_code_i);
    err_msg_i = vett_err_msg{ind_err_code(1)};
    fprintf('\n\n\t***  %s:\n',err_msg_i);
    for i_match = 1:length(ind_err_code)
        i_row = ind_err_code(i_match);
        
        %ind_table   = ind_not_empty(i_row);
        matr_i      = vett_matr{i_row};
        id          = vett_id{i_row};
        nome        = vett_nome{i_row};
        nome2       = vett_nome2{i_row};
        cogn        = vett_cogn{i_row};
        con_nome    = vett_con_nome{i_row};
        con_cogn    = vett_con_cogn{i_row};
        fitness     = vett_fitness(i_row);
        %err_code    = vett_err_code(i_row);
        err_msg     = vett_err_msg{i_row};
        id_con      = vett_id_con{i_row};
        
        fprintf('\t\t%d) %s - ID %s: %s %s %s married to %s %s on %s (--> ID %s, fitness %f)\n',i_match,err_msg,id,nome,nome2,cogn,con_nome,con_cogn,matr_i,id_con,fitness)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_skipped_ID_numbers(table_fix)
% check for skipped (or deleted) ID numbers

ind_v = 3:size(table_fix,1);
ID_v  = str2double(table_fix(3:size(table_fix,1),1));
gap_v = diff(str2double(table_fix(2:end,1)));

max_gap = 1;
ind_gap = find(gap_v>max_gap);
fprintf(1,'Showing gaps larger than %d records:\n',max_gap)
for i=1:length(ind_gap)
    row_i = ind_gap(i);
    gap_i = gap_v(ind_gap(i),end);
    id_i  = ID_v(ind_gap(i),end);
    fprintf(1,'%6d (row %5d): skipped %d ID''s\n',row_i,id_i,gap_i)
end

figure
plot(ind_v,gap_v,'.-'),grid on,

figure
plot(ID_v,gap_v,'.-'),grid on



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks = str_escape(ks_in)
% replace quotes with double quotes

ks = strrep(ks_in,'''','''''');
