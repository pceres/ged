function build_family_recurse(str_archivio,wsdl_url,id_file,direction)
%***************************************************************************************************
%
% FUNCTION : build_family_recurse.m
% AUTHOR   : Pasquale CERES (pasquale.ceres@fptpowertrain.crf.it)
% VERSION  : $Id$
% COMMIT   : $Hash$
%
%***************************************************************************************************
%
%
% build_family_recurse(str_archivio,wsdl_url,id_file,direction)
%
%
% input:
%   str_archivio : archive struct, with fields:
%       archivio  : matrix cell array archive as loaded by 'go.m'
%       indici_arc: headers for archivio cell array
%       filename  : filename of the csv source file
%   wsdl_url     : url of the wsdl page (es. 'http://localhost/work/PhpGedView/genservice.php?wsdl')
%   id_file      : string with ID inside the file to identify the person
%   direction    : {'all','ancestors','ancestors_strict','descendants','descendants_strict'}
%       'all'                : follow all links        
%       'ancestors_strict'   : follow only father and mother links
%       'ancestors'          : follow ancestors links, and brothers, wife/husband       
%       'descendants_strict' : follow only children links
%       'descendants'        : follow descendants links, and brothers, wife/husband        
%
% % es.
% build_family_recurse(str_archivio,'http://localhost/work/PhpGedView/genservice.php?wsdl','29095','ancestors_strict')
%
% id_file = '43691';
% id_file = '28957';


% analisi sensitività con id_file 29095
% vx=[.05 .08 .1 .125 .15 .185 .20 .25],vy=[41.530 41.530 34.604 54.756 55.268 77.154 88.756 299.464],figure(1),plot(vx,vy,'.-'),xlabel('threshold\_search [adim]'),ylabel('build\_family result size [kB]'),grid on
threshold_search = 0.1;
threshold_accept = 0.09;

% prepare logfile
logfile = 'logfile_bfr.txt';            % logfile with selected info, displayed by disp_log
logfile_full = 'logfile_bfr_full.txt';  % logfile with verbose info, saved by diary command
if exist(logfile,'file')
    delete(logfile)
end
diary off
if exist(logfile_full,'file')
    delete(logfile_full)
end
diary(logfile_full)

queue_id_file = {str2double(id_file)}; % list of id_file's on which build_family has to be run (start with id_file)...
queue_path = {[]};                     % ...and list of paths to the corresponding id_file (start with root path)
list_id_file_pgv = [];  % list of id_file with a pgv link that can be reached by id_file
clear network;
while ~isempty(queue_id_file)
    % id_file and path to be analysed (the first in the list, that are then removed)
    id_file_i = queue_id_file{1};
    path = queue_path{1};
    queue_id_file = queue_id_file(2:end);
    queue_path = queue_path(2:end);
    
    [bf_status bf_result bf_text] = build_family_fast(str_archivio,wsdl_url,num2str(id_file_i),threshold_search); % run build_family as fast as possible (using buffer)
    str_links = analyse_result(str_archivio,bf_result,bf_text,threshold_accept,path,direction); % prune uncertain links, and determine a struct with all links for id_file
    network(id_file_i) = str_links; %#ok<AGROW>  % increase the network
    [queue_id_file queue_path list_links list_PID_new list_id_file_pgv] = add_future_links(queue_id_file,queue_path,id_file_i,str_links,path,list_id_file_pgv); % grow list of next analysises
    
    report_links(str_archivio,list_links,list_PID_new,network,logfile)
end

diary off % close the diary file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function disp_log(logfile,msg)

fid = fopen(logfile,'a');
fwrite(fid,msg,'char');
fwrite(fid,sprintf('\n'),'char');
fclose(fid);

disp(msg)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function report_links(str_archivio,list_links,list_PID_new,network,logfile)

for i_link = 1:length(list_links)
    full_path = list_links{i_link};
    
    disp_log(logfile,' ')
    disp_log(logfile,' ')
    disp_log(logfile,'**  Trovato un link:')
    disp_log(logfile,' ')
    
    id_file_0 = full_path(end);
    PID_0 = list_PID_new{i_link};
    msg_0 = sprintf('%-6s %s',PID_0,ged('record2msg',str_archivio,id_file_0));
    disp_log(logfile,msg_0)
    for i_hop = (length(full_path)-1):-2:1
        code = full_path(i_hop);
        id_file_i = full_path(i_hop-1);
        
        type = code2type(code);
        PID_i = get_pid_from_network(network,id_file_i);
        msg_i = sprintf('%-6s %s',PID_i,ged('record2msg',str_archivio,id_file_i));
        
        disp_log(logfile,type)
        disp_log(logfile,msg_i)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PID = get_pid_from_network(network,id_file)

PID = '';
if length(network) >= id_file
    network_i = network(id_file);
    
    if ~isempty(network_i.soap_self) && ~isempty(network_i.soap_self{1})
        PID = network_i.soap_self{1}.PID;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [queue_id_file queue_path list_links list_PID_new list_id_file_pgv] = add_future_links(queue_id_file,queue_path,id_file,str_links,path,list_id_file_pgv)
% for id_file reachable by path, analyse links in str_links, and grow the list

list_fields = fieldnames(str_links);

list_links = {};
list_PID_new = {};
for i_field = 1:length(list_fields)
    link_type = list_fields{i_field};
    if regexp(link_type,'^id')
        list_id = str_links.(link_type);
        if ~isempty(list_id)
            type = link_type(4:end);
            if ~strcmp(type,'self') % self is not a link, skip it
                code = type2code(type);
                soap_list = str_links.(['soap_' type]);
                
                if ( (~isempty(path)) && (code==3) && (path(end)==code) )
                    % drop links with multiple 'frat' links one after the other
                    continue
                end
                
                path_new = [path id_file code];
                
                for i_pers = 1:length(list_id)
                    id_file_new = list_id(i_pers);
                    
                    if ismember(id_file_new,path_new(1:2:end))
                        % drop paths that pass twice in the same person
                        continue
                    end
                    
                    if ismember(id_file_new,list_id_file_pgv)
                        % drop path that leads to a id_file_new that has
                        % already been reached by a previous path
                        continue
                    end
                    
                    queue_id_file = [queue_id_file num2cell(id_file_new)]; %#ok<AGROW>
                    queue_path = [queue_path {path_new}]; %#ok<AGROW>
                    
                    soap_pers = soap_list{i_pers};
                    if ~isempty(soap_pers)
                        % id_file_new has a soap link, add the new path
                        % (path + id_file_new)
                        
                        soap_list_i = soap_list{i_pers};
                        if isempty(soap_list_i)
                            PID_new = '';
                        else
                            PID_new = soap_list_i.PID;
                        end
                        

                        full_path = [path_new id_file_new];
                        list_links(end+1) = {full_path}; %#ok<AGROW>
                        list_id_file_pgv = [list_id_file_pgv id_file_new]; %#ok<AGROW>
                        list_PID_new{end+1} = PID_new; %#ok<AGROW>
                    end
                end
            end
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function type = code2type(code)

list_code_type = get_list_code_type();

type = list_code_type{code};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function code = type2code(type)

list_code_type = get_list_code_type();

code = strmatch(type,list_code_type,'exact');
if isempty(code)
    error('wrong type %s',type)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_code_type = get_list_code_type()

list_code_type = {
    'pad'
    'mad'
    'frat'
    'figl'
    'con'
    'cgnt'
    };


    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [id_list_num id_list_soap] = extract(str_archivio,bf_result,link_type,singularity,threshold_accept)
% filter out match with a low fitness, and extract a list of ID_file, of
% correspondind SOAP results, and corresponding PID (from pgv site)

result_temp = bf_result.(['result_' link_type]);
str_PID_links = bf_result.str_PID_links;
list_PID = str_PID_links.(['PID_' link_type]);
if isempty(result_temp)
    id_list_num = [];
    id_list_soap = {};
    
else
    mask_fit = result_temp.mask_fit;
    
    ind_ok = find(mask_fit<threshold_accept);
    records = str_archivio.archivio(result_temp.mask_id,:);
    id_list_num = str2double(records(ind_ok,str_archivio.indici_arc.id_file)');
    if isfield(result_temp,'result_soap')
        id_list_soap = result_temp.result_soap.list_found(ind_ok);
    else
        id_list_soap = {};
    end
    id_list_PID = list_PID(ind_ok); % dovrebbe contenere le parentele del PID self (padre, madre, ecc.), in modo da incrociarle con i match trovati da find_person
end

switch singularity
    case 'single'
        if (length(id_list_num)>1)
            ks_temp = num2str(id_list_num,'%d,');
            fprintf(1,'\n\n****\n**** There should be a single match of type "%s", found %d (%s)!!! Dropping all matches\n****\n\n',link_type,length(id_list_num),ks_temp(1:end-1))
            
            % it is better to drop all matches
            id_list_num = [];
            id_list_soap = {};
        end
    case 'multiple'
        % none
    otherwise
        error('unmanaged singularity %s',singularity)
end

%id_list = cellfun(@num2str,num2cell(id_list_num),'UniformOutput',0);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_links = analyse_result(str_archivio,bf_result,bf_text,threshold_accept,path,direction)

disp(bf_text)

[id_self soap_self] = extract(str_archivio,bf_result,'self','single',threshold_accept);
[id_pad soap_pad] = extract(str_archivio,bf_result,'pad','single',threshold_accept);
[id_mad soap_mad] = extract(str_archivio,bf_result,'mad','single',threshold_accept);
[id_frat soap_frat] = extract(str_archivio,bf_result,'frat','multiple',threshold_accept);
[id_con soap_con] = extract(str_archivio,bf_result,'con','multiple',threshold_accept);
[id_figl soap_figl] = extract(str_archivio,bf_result,'figl','multiple',threshold_accept);
%[id_cgnt soap_cgnt] = extract(str_archivio,bf_result,'cgnt','multiple',threshold_accept);

fprintf('self: %s\n',num2str(id_self))
fprintf('padre: %s\n',num2str(id_pad))
fprintf('madre: %s\n',num2str(id_mad))
fprintf('fratelli: %s\n',num2str(id_frat))
fprintf('coniuge: %s\n',num2str(id_con))
fprintf('figli: %s\n',num2str(id_figl))
%fprintf('cognati: %s\n',num2str(id_cgnt))

str_links = struct();
str_links.id_self   = id_self;
str_links.soap_self = soap_self;

list_directions = {'all','ancestors','descendants','ancestors_strict','descendants_strict'};
if ~ismember(direction,list_directions)
    error('Unmanaged direction %s! Allowed ones are: %s',direction,sprintf('"%s",',list_directions{:}))
end    
    
if ismember(direction,{'all','ancestors','descendants'})
    str_links.id_frat   = id_frat;
    str_links.soap_frat = soap_frat;
    str_links.id_con    = id_con;
    str_links.soap_con  = soap_con;
    %str_links.id_cgnt   = id_cgnt;
    %str_links.soap_cgnt = soap_cgnt;
end
if ismember(direction,{'all','ancestors','ancestors_strict'})
    str_links.id_pad    = id_pad;
    str_links.soap_pad  = soap_pad;
    str_links.id_mad    = id_mad;
    str_links.soap_mad  = soap_mad;
end
if ismember(direction,{'all','descendants','descendants_strict'})
    str_links.id_figl   = id_figl;
    str_links.soap_figl = soap_figl;
end

str_links.path = path;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bf_status bf_result bf_text] = build_family_fast(str_archivio,wsdl_url,id_file,threshold) %#ok<INUSL>

global build_family_archive list_archive % must be aligned to the list of vars declared in list_matfile_vars below
list_matfile_vars = {'build_family_archive','list_archive'}; % must be aligned to the global vars declared above

debug = 0;

build_family_fast_datafile = 'build_family_fast_datafile.mat';
step_backup = 10; % every step_backup incremental save, do a backup

flg_skipcalc = 0;
if exist(build_family_fast_datafile,'file')
    if isempty(build_family_archive)
        % load data from archive just once, afterwards just work on the global vars
        temp = load(build_family_fast_datafile,list_matfile_vars{:});
        build_family_archive = temp.build_family_archive;   % must be aligned to the list of vars declared in list_matfile_vars
        list_archive = temp.list_archive;                   % must be aligned to the list of vars declared in list_matfile_vars
        clear temp;
    end
    
    if ~isempty(list_archive)
        ind = strmatch(id_file,list_archive(:,1),'exact');
        if ~isempty(ind)
            bf_status = build_family_archive{ind,1};
            bf_result = build_family_archive{ind,2};
            bf_text   = build_family_archive{ind,3};
            csvfile_crc_current = sum([str_archivio.filedata.date str_archivio.filename]);  % crc of current csv file
            flg_unchanged_csvfile = bf_result.csvfile_crc == csvfile_crc_current;           % crc of csv file when bf_result was created
            if ~flg_unchanged_csvfile
                fprintf(1,'Warning: csv file has changed since %s was populated for id_file %s!\n',build_family_fast_datafile,id_file)
            end
            flg_skipcalc = flg_unchanged_csvfile; % skip calculation only if the csv file has not changed (otherwise mask_id inside bf_result is no longer valid)
        end
    end
else
    % create file
    build_family_archive = {};
    list_archive = {};
    save(build_family_fast_datafile,list_matfile_vars{:})
end

if ~flg_skipcalc
    fprintf(1,'\nAnalysing links for ID %s...\n',id_file)
    eval_cmd = '[bf_status bf_result] = build_family(struct(''id_file'',id_file),str_archivio,0,threshold,struct(''wsdl_url'',wsdl_url));';
    if debug
        eval(eval_cmd); %#ok<UNRCH>
        bf_text = '<missing text>';
    else
        bf_text = evalc(eval_cmd);
    end
    if bf_status == 1
        % result is ok
        ind = calculate_ind_for_next_row(list_archive,id_file); % index where new data will be written
        build_family_archive(ind,:) = {bf_status,bf_result,bf_text};
        list_archive(ind,:) = {id_file,threshold,ind};
        % backup if necessary
        if ( rem(size(list_archive,1),step_backup)==0 )
            backup_matfile = [build_family_fast_datafile '.old'];
            save(backup_matfile,list_matfile_vars{:})
        end
        % update archive
        save(build_family_fast_datafile,list_matfile_vars{:},'-append')
    else
        error('Todo!')
    end
else
    % session may be expired, so return empty SID to force new identification
    bf_result.soap_struct.class_instance = [];
    bf_result.soap_struct.SID            = [];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ind = calculate_ind_for_next_row(list_archive,id_file)
% calculate index where new data will be written

if isempty(list_archive)
    ind = 1;
else
    ind = strmatch(id_file,list_archive(:,1),'exact'); % look for id_file already present in archive...
    if isempty(ind)
        % ...if missing, just append
        ind = size(list_archive,1)+1;
    end
end
