function [status result] = build_family(struct_search,str_archivio,relax_factor_self,relax_factor,soap_struct) %#ok<INUSL> % used in eval
%
% Author  : Pasquale CERES
% Version : $Revision: 1.7 $
% Date    : $Date: 2010/05/23 20:50:24 $
% 
%
% given a certain amount of info about one person (a struct with info
% nome,cogn, pad_nome, ecc.), find the person in file, and locate its
% parents and brothers
%
% [status result] = build_family(struct_search,str_archivio,relax_factor_self,relax_factor,soap_struct)
%
%
% Input:
%   struct_search       : struct search in the ged.m format (es. struct('nome','vincenzo','cogn','russomanno')  )
%   str_archivio        : file archive, loaded by go.m
%   relax_factor_self   : ged find_person relax_factor to be used for self
%   relax_factor        : ged find_person relax_factor to be used for all other searches
%   soap_struct         : soap struct (es. struct('wsdl_url',wsdl_url) ); % [] -> no SOAP activity
%
% Output:
%   result: struct with fields
%       soap_struct   : struct with soap session info
%       result_XXX    : results for each type of link
%       str_PID_links : struct with pgv PID's for each link (one for each
%           field). Field names are PID_xxx, with xxx='self', 'frat', 'con', 'cgnt',
%           'pad', 'mad', 'figl'. PID_xxx is a cell array, allowing multiple
%           matches (for example for a person that has been entered twice on
%           the pgv site. So PID associated to father will be in
%           result.str_PID_links.PID_pad = {PID1, PID2, ...}, with PID a string
%
% es:
%
% [status result] = build_family(struct('nome','vincenzo','pad_nome','antonio','cogn','russomanno','mad_nome','lucia','mad_cogn','chiaravallo','int_nasc_a',1867),str_archivio,.1,.3,[]);
%
% wsdl_url  = 'http://localhost/work/PhpGedView/genservice.php?wsdl';
% [status result] = build_family(struct('id_file','37938'),str_archivio,0,.25,struct('wsdl_url',wsdl_url));
%
%
% %
% % TODO
% %
%
%
% build_family_recurse(str_archivio,'40635','ancestors') --> la ricerca come self per ID 27140 viene iterata più e più volte
%
% build_family_recurse(str_archivio,'57458','ancestors_strict') --> ID 46479 viene indicato come padre di 46597, senza motivo
%
% build_family_recurse(str_archivio,'60802','ancestors')
% id duplicato 60802, ma non viene visualizzato messaggio di errore (mentre
% con build_family sì
%
% [status result] = build_family(struct('id_file','37885'),str_archivio,0,.15,struct('wsdl_url',wsdl_url));
%
% 46514: il PID I4143 viene associato a 2 fratelli (ID 46644 e 46430): si
% dovrebbe filtrare in modo da lasciare una sola associazione per ciascun
% PID
%
%
% 29066 -->  build_family_recurse indica come padre 29241 GIUSEPPA  CERES,
%   anche se build family funziona correttamente
%
% build_family_recurse(str_archivio,'26232','ancestors_strict'): 
% 1) perché non
% vengono individuati come presenti su pgv gli ID intermedi (es. 26257)?
% 2) Perché non si individua la moglie ID 37576) ANNA  IANNUZZO?
%
% 45538 --> come mai si individuano 2 coniugi, di cui si visualizza solo
% quello corretto (ma vengono restituiti entrambi)?
%
% build_family_recurse(str_archivio,'33849','ancestors')
% gli ID dopo synoptic non sono corretti, a partire da quello per l'ID
% 33849
%


status = 1;
result = struct();

eval_fcn = @evalc;

% disable interaction if the function is called from another function
str_dbstack = dbstack;
interactive = strcmp(mfilename,str_dbstack(end).name);


% parameters
params.min_age_to_have_a_child = 15; % [year] età minima per avere un figlio
params.max_age_to_have_a_child = 65; % [year] età massima per avere un figlio
params.con_nasc_min_delta = -15; % [year] quanti anni prima puo' essere nato il coniuge
params.con_nasc_max_delta = +15; % [year] quanti anni dopo puo' essere nato il coniuge

% timestamp for csv file
result.csvfile_crc = sum([str_archivio.filedata.date str_archivio.filename]);


%% search self

struct_search_self = struct_search;
eval_fcn('result_self = ged(''find_person'',struct_search_self,str_archivio,relax_factor_self,soap_struct);');
result_self.struct_search = struct_search_self;
if ~isempty(result_self.result_soap)
    result.soap_struct = result_self.result_soap.soap_struct; % just keep one copy for all soap results, then remove other copies
else
    result.soap_struct = []; % no soap activity, so no session info
end
result.result_self = prune_soap_result(result_self);

if ~result_self.status
    disp('Error inside find_person for self!')
    status = 0;
    return
else
    
    mask_id     = result.result_self.mask_id;
    mask_fit    = result.result_self.mask_fit;
    if (length(mask_fit)>1) && ~check_same_person(str_archivio,mask_id)
        flg_quiet = 0;
        disp('Too many records matching:')
        disp(' ')
        ged('show_report_with_soap',str_archivio,result_self,flg_quiet);
        disp(' ')
        disp('Improve search struct or reduce relax_factor!')
        status = 0;
        return
    elseif isempty(mask_fit)
        disp('No matching record!')
        status = 0;
        return
    end
    
    family_info = struct(); % struct with family info
    
    %% search for brothers
    [struct_search_frat family_info] = prepare_search_struct('frat',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_frat,'frat',eval_fcn,{str_archivio,relax_factor,soap_struct});
    
    %% search for father
    [struct_search_pad family_info] = prepare_search_struct('pad',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_pad,'pad',eval_fcn,{str_archivio,relax_factor,soap_struct});
    result.result_pad = filter_out(str_archivio,relax_factor,'pad',result.result_pad,'M',params.min_age_to_have_a_child);
    
    %% search for mother
    [struct_search_mad family_info] = prepare_search_struct('mad',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_mad,'mad',eval_fcn,{str_archivio,relax_factor,soap_struct});
    result.result_mad = filter_out(str_archivio,relax_factor,'mad',result.result_mad,'F',params.min_age_to_have_a_child);
    
    %% search for children
    [struct_search_figl family_info] = prepare_search_struct('figl',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_figl,'figl',eval_fcn,{str_archivio,relax_factor,soap_struct});
    
    %% search for spouse (wife/husband)
    [struct_search_con family_info] = prepare_search_struct('con',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_con,'con',eval_fcn,{str_archivio,relax_factor,soap_struct});
    result.result_con = filter_out(str_archivio,relax_factor,'con',result.result_con,family_info.con_sex,params.min_age_to_have_a_child);
    
    %% search for brothers in law (cognati)
    [struct_search_cgnt family_info] = prepare_search_struct('cgnt',str_archivio,params,result,family_info,interactive);
    result = perform_search(result,struct_search_cgnt,'cgnt',eval_fcn,{str_archivio,relax_factor,soap_struct});
    result.result_pad = filter_out(str_archivio,relax_factor,'pad',result.result_pad,'',params.min_age_to_have_a_child);
    
    %% show report
    show_report(result,str_archivio)
    
    %% determine PID's for each link, if possible
    if ~isempty(soap_struct)
        str_PID_links = prepare_PID_links_struct(result);
        result.str_PID_links = str_PID_links;
    else
        result.str_PID_links = [];
    end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_i_new = filter_out(str_archivio,relax_factor,link_type,result_i,sex_ok,min_age)

result_i_new = result_i;
if ( ~isempty(result_i) && ~isempty(sex_ok) )
    mask_id  =result_i.mask_id;
    mask_fit =result_i.mask_fit;
    indici_arc = str_archivio.indici_arc;
    for i_record = 1:length(mask_id)
        record_i = str_archivio.archivio(mask_id(i_record),:);
        fit_i = mask_fit(i_record);
        
        % sex check
        ks_id_file = record_i{indici_arc.id_file};
        ks_nome = record_i{indici_arc.nome};
        sex = ged('determine_sex',ks_nome);
        if isempty(sex)
            delta_fit = 0;
            msg = '???';
        elseif strcmp(sex_ok,sex)
            delta_fit = 0;
            msg = 'ok ';
        else
            delta_fit = 0.2;
            msg = '***';
        end
        if (delta_fit>0)
            % make fitness worse due to wrong sex
            fit_i = min(1,fit_i+0.2);
            mask_fit(i_record) = fit_i;
            disp(ged('record2msg',str_archivio,ks_id_file))
            fprintf(1,'%s : %s (ID %s) is %s ("%s" should be %s)\n\n',msg,ks_nome,ks_id_file,sex,link_type,sex_ok)
        end
        
        % min age check
        int_nasc_a = record_i{indici_arc.int_nasc_a};
        int_mort_a = record_i{indici_arc.int_mort_a};
        eta_mort = int_mort_a-int_nasc_a;
        if ( ~isempty(min_age) && ~isnan(eta_mort) && (eta_mort<min_age) )
            % make fitness worse due to wrong sex
            fit_i = min(1,fit_i+0.3);
            mask_fit(i_record) = fit_i;
            msg = '***';
            disp(ged('record2msg',str_archivio,ks_id_file))
            fprintf(1,'%s : %s (ID %s) died at age %d (it should be at least %d)\n\n',msg,ks_nome,ks_id_file,eta_mort,min_age)
        end
    end
    % update fitness, and remove unfit ones
    ind_ok = (mask_fit<=relax_factor);
    result_i_new.mask_id  = mask_id(ind_ok);
    result_i_new.mask_fit = mask_fit(ind_ok);
    if (isfield(result_i_new,'result_soap') && ~isempty(result_i_new.result_soap) )
        result_i_new.result_soap.list_found = result_i_new.result_soap.list_found(ind_ok);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = perform_search(result,struct_search,ks_result_type,eval_fcn,params_find_person) %#ok<INUSD> % params_find_person usato in evalc

tag_result_type = ['result_' ks_result_type];

if isempty(struct_search)
    result_i = struct('mask_id',[],'mask_fit',[]);
    result_i.struct_search = struct_search;
    result.(tag_result_type) = result_i;
else
    for i_con = 1:length(struct_search)
        struct_search_i = struct_search(i_con);
        eval_fcn('result_i = ged(''find_person'',struct_search_i,params_find_person{:});');
    end
    result_i.struct_search = struct_search_i;
    result.(tag_result_type)(i_con) = prune_soap_result(result_i);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_PID_links = prepare_PID_links_struct(result)
% determine PID's for each link, if possible (must be called in case od
% SOAP activity)

disp(' ')
disp('Synoptic:')

str_PID_links = struct();
list_field=fieldnames(result);
for i_field=1:length(list_field)
    field=list_field{i_field};
    if strfind(field,'result_')
        link_type = field(8:end);
        result_type=result.(field);
        if ( ~isempty(result_type) && ~isempty([result_type.mask_id]) )
            
            if length(result_type)==1
                list_found=result_type.result_soap.list_found;
            else
                % result_type è un vettore di array (per i cognati)
                list_found={};
                for i=1:length(result_type)
                    if isempty(result_type(i).result_soap)
                        list_found_i = {};
                    else
                        list_found_i=result_type(i).result_soap.list_found;
                    end
                    list_found{end+1}=list_found_i; %#ok<AGROW>
                end
            end
        else
            list_found={};
        end
        list_PID = {};
        ks_PID = '';
        for i1=1:length(list_found)
            pers=list_found{i1};
            if ( ~isempty(pers) && iscell(pers) )
                % serve per gestire result_cgnt
                pers = pers{1};
            end
            if ( isempty(pers) )
                ks_PID_i = '-';
                list_PID_i = {};
            elseif length(pers)>1
                ks = sprintf('%s/',pers.PID);
                ks_PID_i = ['(' ks(1:end-1) ')'];
                [list_PID_i{1:length(pers)}] = deal(pers.PID); %#ok<AGROW>
            else
                ks_PID_i = pers.PID;
                list_PID_i = {pers.PID};
            end
            list_PID{i1} = list_PID_i; %#ok<AGROW>
            ks_PID = [ks_PID ', ' ks_PID_i]; %#ok<AGROW>
        end
        str_PID_links.(['PID_' link_type]) = list_PID;
        fprintf(1,'%s: %s\n',field,ks_PID(3:end))
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_i = prune_soap_result(result_i)

result_i = rmfield(result_i,'status');

result_soap = result_i.result_soap;
if ~isempty(result_soap)
    result_soap = rmfield(result_soap,'err_code');
    result_soap = rmfield(result_soap,'err_msg');
    result_soap = rmfield(result_soap,'soap_struct');
    
    list_found = result_soap.list_found;
    for i1 = 1:length(list_found)
        list_found_i = list_found{i1};
        if ~isempty(list_found_i)
            list_found_i = rmfield(list_found_i,'result_F');
            list_found_i = rmfield(list_found_i,'msgs_pgv');
            list_found{i1} = list_found_i;
        end
    end
    result_soap.list_found = list_found;
    
    result_i.result_soap = result_soap;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_report(result,str_archivio)

flg_quiet = 0;

result_self = sort_report(result.result_self,'birth_date',str_archivio);
result_pad  = sort_report(result.result_pad,'fitness',str_archivio);
result_mad  = sort_report(result.result_mad,'fitness',str_archivio);
result_frat = sort_report(result.result_frat,'birth_date',str_archivio);
result_cgnt = result.result_cgnt; % no sorting by birth date
if ~isempty(result.result_con)
    for i_con = 1:length(result.result_con)
        result_con(i_con)  = sort_report(result.result_con(i_con),'fitness',str_archivio); %#ok<AGROW>
        result_figl(i_con) = sort_report(result.result_figl(i_con),'birth_date',str_archivio); %#ok<AGROW>
    end
else
    % empty results
    result_con  = result.result_con;
    result_figl = result.result_figl;
end


% self
ks_struct_search_self = struct_to_string(result_self.struct_search);
fprintf(1,'*** self ***    ( %s )\n',ks_struct_search_self)

if ~isempty(result.soap_struct)
    result_self.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
end
ged('show_report_with_soap',str_archivio,result_self,flg_quiet);

disp(' ')


% father
ks_struct_search_pad = struct_to_string(result_pad.struct_search);
fprintf(1,'*** padre ***    ( %s )\n',ks_struct_search_pad)

if ~isempty(result.soap_struct)
    result_pad.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
end
ged('show_report_with_soap',str_archivio,result_pad,flg_quiet);

disp(' ')


% mother
ks_struct_search_mad = struct_to_string(result_mad.struct_search);
fprintf(1,'*** madre ***    ( %s )\n',ks_struct_search_mad)

if ~isempty(result.soap_struct)
    result_mad.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
end
ged('show_report_with_soap',str_archivio,result_mad,flg_quiet);

disp(' ')


% brothers
ks_struct_search_frat = struct_to_string(result_frat.struct_search);
fprintf(1,'*** fratelli ***    ( %s )\n',ks_struct_search_frat)

if ~isempty(result.soap_struct)
    result_frat.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
end
ged('show_report_with_soap',str_archivio,result_frat,flg_quiet);

disp(' ')

% cognati
for i_cgnt = 1:length(result_cgnt)
    
    % cognato
    result_cgnt_i = result_cgnt(i_cgnt);
    
    ks_struct_search_cgnt = struct_to_string(result_cgnt_i.struct_search);
    fprintf(1,'*** cognato n. %d ***    ( %s )\n',i_cgnt,ks_struct_search_cgnt)
    
    if ~isempty(result.soap_struct)
        result_cgnt_i.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
    end
    ged('show_report_with_soap',str_archivio,result_cgnt_i,flg_quiet);
    
    disp(' ')
end

% there can be more than one wife/husband
for i_con = 1:length(result_con)
    
    % wife/husband
    result_con_i = result_con(i_con);
    ks_struct_search_con = struct_to_string(result_con_i.struct_search);
    fprintf(1,'*** coniuge %d° matrimonio ***    ( %s )\n',i_con,ks_struct_search_con)
    
    if ~isempty(result.soap_struct)
        result_con_i.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
    end
    ged('show_report_with_soap',str_archivio,result_con_i,flg_quiet);
    
    disp(' ')
    
    
    % children
    result_figl_i = result_figl(i_con);
    ks_struct_search_figl = struct_to_string(result_figl_i.struct_search);
    fprintf(1,'*** figli %d° matrimonio ***    ( %s )\n',i_con,ks_struct_search_figl)
    
    if ~isempty(result.soap_struct)
        result_figl_i.result_soap.soap_struct = result.soap_struct; % add soap info to allow url preparation
    end
    ged('show_report_with_soap',str_archivio,result_figl_i,flg_quiet);
    
    disp(' ')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_sorted = sort_report(result,criteria,str_archivio)
% sort by birth date

result_sorted = result;

switch criteria
    case 'birth_date'
        indici_arc = str_archivio.indici_arc;
        ind_records_sort = indici_arc.int_nasc_num; % decimal birth date column
        records=str_archivio.archivio(result.mask_id,:);
        [temp ind] = sort(cell2mat(records(:,ind_records_sort)));

    case 'fitness'
        [temp ind] = sort(result.mask_fit);
        
    otherwise
        error('Unmanaged criteria %s',criteria)
end

result_sorted = sort_result_by_ind(result_sorted,ind);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_sorted = sort_result_by_ind(result_sorted,ind)

list_fields=fieldnames(result_sorted);
for i_field = 1:length(list_fields)
    field = list_fields{i_field};
    field_val = result_sorted.(field);
    if length(field_val)==length(ind)
        % the field is a vector or a cell array: sort it
        field_val=field_val(ind);
        result_sorted.(field)=field_val;
    elseif strcmp(field,'result_soap')
        % the field is struct itself: try to sort its fields
        field_val = sort_result_by_ind(result_sorted.result_soap,ind);
        result_sorted.(field)=field_val;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [struct_search family_info] = prepare_search_struct(search_type,str_archivio,params,result_current,family_info,interactive)

result_self = result_current.result_self;

record_self = str_archivio.archivio(result_self.mask_id,:); % could be a multiple linked record for the same person
indici_arc  = str_archivio.indici_arc;
if size(record_self,1)>1
    % sort by marriage date
    [temp ind]  = sort([record_self{:,indici_arc.int_matr_num}]);
    record_self = record_self(ind,:);
end

% extract from a record (or multiple linked records) the corresponding info
struct_info_fields = records_to_struct(record_self,indici_arc);
nome = struct_info_fields.nome; % nome self
cogn = struct_info_fields.cogn; % cognome self
pad_nome = struct_info_fields.pad_nome; % nome padre
mad_nome = struct_info_fields.mad_nome; % nome madre
mad_cogn = struct_info_fields.mad_cogn; % cognome madre
int_nasc_a = struct_info_fields.int_nasc_a; % anno di nascita
%int_matr_a = struct_info_fields.int_matr_a; % anno di matrimonio
int_mort_a = struct_info_fields.int_mort_a; % anno di morte

con_nome = record_self(:,indici_arc.con_nome); % nome coniuge (cell array verticale, puo' essere multiplo)
con_cogn = record_self(:,indici_arc.con_cogn); % cognome coniuge (cell array verticale, puo' essere multiplo)

self_sex = ged('determine_sex',nome);
family_info.self_sex = self_sex;

switch search_type
    case 'frat'
        % search for brothers
        struct_search = struct('pad_nome',pad_nome,'cogn',cogn,'mad_nome',mad_nome,'mad_cogn',mad_cogn);
        
        % determine range of birth year of brothers based on
        % birth year of self
        if isnumeric(int_nasc_a)
            rng_nasc_brother = int_nasc_a+(params.max_age_to_have_a_child-params.min_age_to_have_a_child)*[-1 1];
            struct_search.int_nasc_a = [rng_nasc_brother 0]; % add a 0 tolerance factor to prevent years outside range
        end
        
    case 'pad'
        % search for father
        struct_search = struct('nome',pad_nome,'cogn',cogn,'con_nome',mad_nome,'con_cogn',mad_cogn);
        
        % filter based on birth years of the first and last brother
        records_frat = str_archivio.archivio(result_current.result_frat.mask_id,:);
        vett_int_nasc_a_frat = cell2mat(records_frat(:,indici_arc.int_nasc_a));
        min_int_nasc_a_frat = min(vett_int_nasc_a_frat);
        max_int_nasc_a_frat = max(vett_int_nasc_a_frat);
        family_info.min_int_nasc_a_frat = min_int_nasc_a_frat;
        family_info.max_int_nasc_a_frat = max_int_nasc_a_frat;
        
        if ~isnan(min_int_nasc_a_frat)
            % determine range of birth year of parents based on
            % birth year of the brothers
            rng_nasc_parent = [max_int_nasc_a_frat-params.max_age_to_have_a_child min_int_nasc_a_frat-params.min_age_to_have_a_child];
            if rng_nasc_parent(1)>rng_nasc_parent(2)
                disp('Brothers''s birth years:')
                disp(vett_int_nasc_a_frat)
                disp('Brother''s year birth range:')
                disp(rng_nasc_parent)
                fprintf(1,'todo: swap range boundaries for int_nasc_a_pad!\n')
                if interactive
                    pause
                end
                % determine range of birth year of parents based on
                % birth year of self
                if isnumeric(int_nasc_a)
                    rng_nasc_parent = int_nasc_a-[params.max_age_to_have_a_child params.min_age_to_have_a_child];
                    struct_search.int_nasc_a = [rng_nasc_parent 0]; % add a 0 tolerance factor to prevent years outside range
                    fprintf(1,'range boundaries [%d %d] for int_nasc_a_pad calculated on int_nasc_a of self (%d)!\n',rng_nasc_parent(1),rng_nasc_parent(2),int_nasc_a)
                else
                    rng_nasc_parent = NaN;
                end
            else
                struct_search.int_nasc_a = [rng_nasc_parent 0]; % add a 0 tolerance factor to prevent years outside range
            end
        else
            rng_nasc_parent = NaN;
        end
        
        family_info.rng_nasc_parent = rng_nasc_parent;
        
    case 'mad'
        % search for mother
        struct_search = struct('nome',mad_nome,'cogn',mad_cogn,'con_nome',pad_nome,'con_cogn',cogn);

        % filtro basato su anni di nascita del primo ed ultimo fratello
        rng_nasc_parent = family_info.rng_nasc_parent;
        
        if ~isnan(rng_nasc_parent)
            struct_search.int_nasc_a = [rng_nasc_parent 0]; % add a 0 tolerance factor to prevent years outside range
        end
        
    case 'figl'
        % search for children
        for i_con = 1:length(con_nome)
            con_nome_i = con_nome{i_con};
            con_cogn_i = con_cogn{i_con};
            switch self_sex
                case 'M'
                    struct_search_i = struct('pad_nome',nome,'cogn',cogn,'mad_nome',con_nome_i,'mad_cogn',con_cogn_i);
                case 'F'
                    struct_search_i = struct('pad_nome',con_nome_i,'cogn',con_cogn_i,'mad_nome',nome,'mad_cogn',cogn);
                otherwise
                    struct_search_i = struct('pad_nome',nome,'cogn',cogn,'mad_nome',con_nome_i,'mad_cogn',con_cogn_i);                  
                    fprintf(1,'**** Unmanaged sex "%s" for name "%s", supposing male sex!\n',self_sex,nome)
            end
            
            if (~isnan(int_nasc_a))
                last_year_for_children = int_nasc_a+params.max_age_to_have_a_child;
                if ~isnan(int_mort_a)
                    % children cannot be born after self's death
                    last_year_for_children = min([last_year_for_children int_mort_a]);
                end
                    
                rng = [int_nasc_a+params.min_age_to_have_a_child last_year_for_children];
                if ( rng(1)>rng(2) )
                    struct_search = struct([]);
                    return
                else
                    struct_search_i.int_nasc_a = [rng 0]; % add a 0 tolerance factor to prevent years outside range
                end
            end
            
            struct_search(i_con) = struct_search_i; %#ok<AGROW>
        end
        
    case 'con'
        % search for wife/husband
        if ( self_sex == 'M' )
            con_sex = 'F';
        elseif ( self_sex == 'F' )
            con_sex = 'M';
        else
            con_sex = '';
        end
        family_info.con_sex = con_sex;
        
        if ( (int_mort_a-int_nasc_a)<params.min_age_to_have_a_child )
            % deceduto prima di raggiungere la maggiroe età
            struct_search = struct([]);
            return
        else
            % senza il check sui nomi dei genitori, venivano dati falsi positivi.
            % ad es., su ID 29490 viene individuato un marito sbagliato, anche se nel nome è
            % indicato "MARIA DI ALESSIO CETRULO"
            con_pad_nome = record_self{indici_arc.con_pad_nome};
            pad_nome = record_self{indici_arc.pad_nome};
            mad_nome = record_self{indici_arc.mad_nome};
            mad_cogn = record_self{indici_arc.mad_cogn};
            
            struct_search = struct('nome',con_nome,'cogn',con_cogn,'con_nome',nome,'con_cogn',cogn, ...
                'pad_nome',con_pad_nome, ...
                'con_pad_nome',pad_nome,'con_mad_nome',mad_nome,'con_mad_cogn',mad_cogn ...
            );

            if (~isnan(int_nasc_a))
                int_nasc_a_con = int_nasc_a+[params.con_nasc_min_delta params.con_nasc_max_delta]; % restringi la data di nascita del coniuge
                struct_search.int_nasc_a = [int_nasc_a_con 0]; % add a 0 tolerance factor to prevent years outside range
            end
        end
        
    case 'cgnt'
        % search for cognato
        records_frat = str_archivio.archivio(result_current.result_frat.mask_id,:);
        struct_search = struct([]);
        for i_frat = 1:size(records_frat)
            
            record_frat_i = records_frat(i_frat,:);
            
            frat_nome = record_frat_i{indici_arc.nome}; % nome self
            frat_cogn = record_frat_i{indici_arc.cogn}; % cognome self
            % pad_nome = struct_info_fields.pad_nome; % nome padre
            % mad_nome = struct_info_fields.mad_nome; % nome madre
            % mad_cogn = struct_info_fields.mad_cogn; % cognome madre
            % int_nasc_a = struct_info_fields.int_nasc_a; % anno di nascita
            % int_matr_a = struct_info_fields.int_matr_a; % anno di matrimonio
            % int_mort_a = struct_info_fields.int_mort_a; % anno di morte
            frat_con_nome = record_frat_i{indici_arc.con_nome}; % nome coniuge del fratello
            frat_con_cogn = record_frat_i{indici_arc.con_cogn}; % cognome coniuge del fratello

            if ~isempty(frat_con_cogn)
                struct_search_cgnt = struct('nome',frat_con_nome,'cogn',frat_con_cogn,'con_nome',frat_nome,'con_cogn',frat_cogn);
%                 if (~isnan(int_nasc_a))
%                     int_nasc_a_cogn = int_nasc_a+[params.con_nasc_min_delta params.con_nasc_max_delta]; % restringi la data di nascita del coniuge
%                     struct_search.int_nasc_a = [int_nasc_a_cogn 0]; % add a 0 tolerance factor to prevent years outside range
%                 end
                if ( exist('struct_search','var') && ~isempty(struct_search) )
                    struct_search(end+1) = struct_search_cgnt; %#ok<AGROW>
                else
                    struct_search = struct_search_cgnt;
                end
            end
            
            
        end
        
    otherwise
        error('Unmanaged search type: %s',search_type)
end

try
struct_search = clean_struct_search(struct_search); % remove empty or NaN fields
catch me
    disp(struct_search)
    disp('*******  TODO: error cleaning struct_search!\n%s',me.message)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_struct_search = struct_to_string(struct_search)

if isempty(struct_search)
    ks_struct_search = '';
else
    list = fieldnames(struct_search);
    
    ks_struct_search = '';
    for i = 1:length(list)
        field = list{i};
        val = struct_search.(field);
        
        if ~ischar(val)
            ks_val = num2str(val); % try as a scalar
            if length(val)>1
                ks_val = ['[ ' ks_val ']']; %#ok<AGROW> % vector
            end
        else
            ks_val = ['''' val ''''];
        end
        ks_struct_search = [ks_struct_search ',''' field ''',' ks_val];  %#ok<AGROW>
    end
    ks_struct_search = ks_struct_search(2:end);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_same = check_same_person(str_archivio,mask_id)

records     = str_archivio.archivio(mask_id,:);
indici_arc  = str_archivio.indici_arc;

flg_same = 0;

link_string = 'VEDI ANCHE ID ';

if size(records,1)>1
    % multiple records, check if multiple marriages for same person
    
    % check for a note linking more records together
    ind_id   = indici_arc.id_file; % id unico per ciascun records (riga)
    ind_note = indici_arc.note;    % nota
    
    if all(cell2mat(regexp(records(:,ind_note),link_string)))
        % all records have a link note ('VEDI ANCHE ID XYZXY')
        if size(records,1)>2
            disp(records)
            error('TODO: unmanaged number of linked records!')
        end
        flg_2_to_1 = isequal(records{2,ind_note},[link_string records{1,ind_id}]);
        flg_1_to_2 = isequal(records{1,ind_note},[link_string records{2,ind_id}]);
        flg_same = flg_2_to_1 && flg_1_to_2;
    end
    
    if ~flg_same
        flg_same_rows = 1;
        % additional check: check for same name and birth date
        matr_to_check = records(:,[indici_arc.nome indici_arc.cogn indici_arc.nasc]);
        for i=2:size(matr_to_check,1)
            if ~isequalwithequalnans(matr_to_check(1,:),matr_to_check(i,:))
                flg_same_rows = 0; % found a mismatch, different people
                break
            end
        end
        if flg_same_rows
            disp(records)
            disp('Found multiple unlinked records!')
            flg_same = 1;
        end
    end
else
    
    flg_same = 1; % single record!
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function struct_info_fields = records_to_struct(records,indici_arc)
% extract from a record (or multiple linked records) the corresponding info

nome        = merge_fields(records(:,indici_arc.nome)); % nome self
cogn        = merge_fields(records(:,indici_arc.cogn)); % cognome self
pad_nome    = merge_fields(records(:,indici_arc.pad_nome)); % nome padre
mad_nome    = merge_fields(records(:,indici_arc.mad_nome)); % nome madre
mad_cogn    = merge_fields(records(:,indici_arc.mad_cogn)); % cognome madre
int_nasc_a  = merge_fields(records(:,indici_arc.int_nasc_a)); % anno di nascita
int_mort_a  = merge_fields(records(:,indici_arc.int_mort_a)); % anno di morte

int_matr_a  = records(:,indici_arc.int_matr_a); % anni di matrimonio (un matrimonio per ciascuna riga)


struct_info_fields = struct();
struct_info_fields.nome = nome; % nome self
struct_info_fields.cogn = cogn; % cognome self
struct_info_fields.pad_nome = pad_nome; % nome padre
struct_info_fields.mad_nome = mad_nome; % nome madre
struct_info_fields.mad_cogn = mad_cogn; % cognome madre
struct_info_fields.int_nasc_a = int_nasc_a; % anno di nascita
struct_info_fields.int_mort_a = int_mort_a; % anno di morte
struct_info_fields.int_matr_a = int_matr_a; % anni di matrimonio



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks = merge_fields(fields)

if length(fields)>1
    if ischar(fields{1})
        list = unique(setdiff(fields,{''}));
    else
        vett = [fields{:}]';
        list = num2cell(unique(vett(~isnan(vett)))); % remove NaN's, and find unique values
        if isempty(list)
            list = {NaN};
        end
    end
    
    if length(list)>1
        disp(fields)
        error('Todo: unmergeable fields!')
    else
        ks = list{1};
    end
else
    ks = fields{1};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function struct_search_out = clean_struct_search(struct_search)
% remove empty or NaN fields

struct_search_out = struct_search;

list = fieldnames(struct_search);
for i_field = 1:length(list)
    field_tag = list{i_field};
    field_val = struct_search.(field_tag);
    
    flg_undefined = ischar(field_val) && ismember(strrep(field_val,'.',''),{'','NN'});
    flg_remove_field = isempty(field_val) || any(isnan(field_val)) || flg_undefined;
    if flg_remove_field
        struct_search_out = rmfield(struct_search_out,field_tag);
    end
end

% if only one field, it is better to remove it, as well, to abort search
list = fieldnames(struct_search_out);
if (length(list)==1)
    struct_search_out = struct([]);
end
