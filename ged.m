function result = ged(action,varargin)
%
% Author  : Pasquale CERES
% Version : $Revision: 1.7 $
% Date    : $Date: 2010/05/23 20:50:24 $
% 
% % read a csv
% result = ged('read_csv','file.csv');
% 
% % check fields
% result = ged('check',result);
% 
% % show items
% result = ged('show_items',result);
% 
% % show report
% result = ged('show_report',str_archivio,result);
% 
% % find person
% % - without soap output
% result = ged('find_person',struct('cogn','barbone','int_mort_a',[1840 1850]),str_archivio,0.25,[]); % just output the result
%
% % - with soap output (thisd value in ranges is the tolerance)
% username = 'uploader';password=input(['Password for user ' username ':'],'s');gedcom = 'caposele';compression = 'none';data_type = 'GEDCOM';
% wsdl_url  = 'http://localhost/work/PhpGedView/genservice.php?wsdl';
% class_instance=eval(createClassFromWsdl(wsdl_url));result_out = Authenticate(class_instance,username,password,gedcom,compression,data_type); SID = result_out.SID
% result = ged('find_person',struct('pad_nome','lorenzo','cogn','di masi','int_mort_a',[1890 1910 0]),str_archivio,0.25,struct('wsdl_url',wsdl_url,'SID',SID,'class_instance',class_instance)); % try to link the results to the PGV people
%
% % record to msg
% mode = 'verbose'; % allowed modes: {'oneline','verbose'}
% result = ged('record2msg',str_archivio,48856,mode);
%
% strfielddist
% val = ged('strfielddist','ANGELO MARIA','ANGIOLO')  --> val [0..1]  0->identical
%
% % determine sex from name
% sex = ged('determine_sex','PAOLO') % --> sex = {'M','F'} )
%
% 
% % prepare find_person reports
% result_self = ged('find_person',struct('pad_nome','lorenzo','cogn','di masi','int_mort_a',[1890 1910 1]),str_archivio,0.25,[]);
% flg_quiet = 0;
% result = ged('show_report_with_soap',str_archivio,result_self,flg_quiet);
%
%
%
% bulk=[];for i=1:length(str_archivio.archivio),d2=strdist(ks1,ks2,2,1);bulk(end+1,:)=[d2(1),length(ks1),length(ks2)];end
%
% to compress the output of ged:
% \s+\n\s+[0-9]+\) fit: [0-9\.]+\n      ->   "" (empty string)
%

switch action
    case 'read_csv'
        filename = varargin{1};

        result = struct();

        [status tabella info] = read_file(filename);
        result.status = status;
        result.tabella = tabella;
        result.info = info;

    case 'table2archive'
        header  = varargin{1};
        tabella = varargin{2};

        result = struct();

        [status archivio liste indici] = crea_archivio(header,tabella);
        result.status   = status;
        result.archivio = archivio;
        result.liste    = liste;
        result.indici   = indici;

    case 'check'
        archivio = varargin{1};

        result = struct();

        [status report archivio_ok] = check_archivio(archivio);
        result.status = status;
        result.report = report;
        result.archivio_ok = archivio_ok;

    case 'show_items'
        items        = varargin{1};

        result = struct();

        show_items(items);

    case 'show_report'
        str_archivio = varargin{1};
        result_in    = varargin{2};

        result = struct();

        [status items] = prepare_report(str_archivio,result_in); % prepare items to be shown by show_items
        show_items(items);
        result.status = status;
        result.items  = items;

    case 'show_report_with_soap'
        str_archivio    = varargin{1}; % archive read from csv file
        result_in       = varargin{2}; % output of ged('find_person') command: struct with fields mask_id (vector of id_file), mask_fit (vector of corresponding fitness), result_soap (pgv matches, if present), struct_search (input of find_person ged command)
        flg_quiet       = varargin{3}; % 1 --> show output

        result = struct();
        
        [items_new items] = show_report_with_soap(str_archivio,result_in,flg_quiet);
        result.items_new = items_new;
        result.items     = items;

    case 'archive2table'
        header = varargin{1};
        archivio = varargin{2};

        result = struct();

        [status tabella] = archivio_2_tabella(archivio,header);
        result.status  = status;
        result.tabella = tabella;

    case 'write_archive'
        header = varargin{1};
        archivio = varargin{2};
        filename = varargin{3};
        new_line = varargin{4};

        [status tabella] = archivio_2_tabella(archivio,header);

        if (status)
            status = write_file(filename,header,tabella,new_line);
            fprintf(1,'Ho aggiustato il file %s\n',filename)
        end
        result.status = status;

    case 'find_person'
        person_rec   = varargin{1};
        str_archivio = varargin{2};
        relax_factor = varargin{3}; % 0  -> only exact matches
        soap_struct  = varargin{4}; % [] -> no SOAP activity

        archivio = str_archivio.archivio;
        [status result] = find_person(person_rec,archivio,relax_factor);

        result.status  = status;

        if isempty(soap_struct)
            result.result_soap = struct([]);
        else
            records = archivio(result.mask_id,:);
            result_soap = uploader('search',{str_archivio,soap_struct,records});
            result.result_soap = result_soap;
        end
        flg_quiet = 0; % show output
        show_report_with_soap(str_archivio,result,flg_quiet);

    case 'strfielddist'
        ks1   = varargin{1};
        ks2   = varargin{2};

        val = strfielddist(ks1,ks2);
        
        result = val;
        
    case 'record2msg'
        % return a string describing record with ID id_file
        str_archivio = varargin{1};
        id_file = varargin{2};
        mode = varargin{3};
        
        archivio = str_archivio.archivio;
        
        ind_record = strmatch(num2str(id_file),archivio(:,str_archivio.indici_arc.id_file),'exact');
        record = archivio(ind_record,:);
        result = record2msg(record,mode);
        
    case 'determine_sex'
        % determine sex from name ( sex = {'M','F'} )
        ks_nome = varargin{1};
        
        result = determine_sex(ks_nome);

    otherwise
        error('Unknown action %s!',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function msg = record2msg(record,mode)
% mode:
%   'oneline': most important fields in one line
%   'verbose': show all fields

indici = indici_archivio();

switch mode
    case 'oneline'
        msg = sprintf('%s) %s %s %s - b:%s,%s (%s, %s %s) - m:%s,%s (%s %s) - d:%s,%s - note: %s',record{indici.id_file},record{indici.nome},record{indici.nome_2},record{indici.cogn},record{indici.nasc_Nr},record{indici.nasc},record{indici.pad_nome},record{indici.mad_nome},record{indici.mad_cogn},record{indici.matr_Nr},record{indici.matr},record{indici.con_nome},record{indici.con_cogn},record{indici.mort_Nr},record{indici.mort},record{indici.note});
    case 'verbose'
        fields = fieldnames(indici);
        ks_format = '';
        for i_record = 1:length(fields)
            field = fields{i_record};
            val=record{indici.(field)};
            vals{i_record}=val; %#ok<AGROW>
            if ischar(val)
                fmt_i = '%s';
            else
                fmt_i = '%f';
            end
            ks_format = [ks_format sprintf('%15s',field) ': ' fmt_i '\n']; %#ok<AGROW>
        end
        msg = sprintf(ks_format,vals{:});
    otherwise
        error('Unknown format mode "%s"! Allowed modes are: {''oneline'',''verbose''}',mode)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status result] = find_person(record,archivio,relax_factor)
% relax_factor : [0..1] fitness normalizzato

indici = indici_archivio();

status = 1;
% result = {};

lista = fieldnames(record); % lista alfanumerica

% indici corrispondenti
%lista_num = [];
num     = length(lista);
lista_num = zeros([1 num]);
lista_ks{num} = '';
for i=1:num
    tag = lista{i};

    if ~isfield(indici,tag)
        list_fields = fieldnames(indici);
        msg = sprintf('\nCampi disponibili:\n%s\n\nCampo non gestito: %s\n',sprintf('%s,',list_fields{:}),tag);
        error(msg) %#ok<SPERR>
    else
        lista_num(i) = indici.(tag);
    end
    lista_ks{i}  = upper(record.(tag));
end


num_rec = size(archivio,1);

% soglia = interp1(...
%     [0    1    2    3    5    8    50 ],...
%     [0.50 0.50 0.35 0.27 0.20 0.10 0.1],...
%     num); % fit medio, più vincoli ci sono, più si abbassa la soglia di fitness
% soglia2 = num*(soglia*relax_factor); % fit totale (somma dei fit per ciascuna regola)
soglia2 = relax_factor;


% inizio calcoli intensivi...
v_somma(num_rec) = 0;
for i_rec = 1:num_rec
    v_somma(i_rec) = for_body_find_person(archivio(i_rec,:),indici,num,lista_num,lista_ks,soglia2);
end
% ...fine calcoli intensivi

% prepara output
ind_ok = find(v_somma<=soglia2);
num_ok = length(ind_ok);
mask_id  = zeros(1,num_ok);
mask_fit = zeros(1,num_ok);
count_ok = 0;
for i_rec = ind_ok
    count_ok = count_ok+1;
    
    somma = v_somma(i_rec);
    
    mask_id(count_ok)  = i_rec;
    mask_fit(count_ok) = somma;
end

% ordina in base al fit
[temp ind] = sort(mask_fit);
mask_id  = mask_id(ind);
mask_fit = mask_fit(ind);

result = struct();
result.mask_id  = mask_id;
result.mask_fit = mask_fit;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function somma = for_body_find_person(record_i,indici,num,lista_num,lista_ks,soglia2)

%%% debug_i = 0;
% list_debug = {'56433','43825','43706','60310'};
% if ismember(record_i{indici.id_file},list_debug)
%     fprintf(1,'\n--- %4s) %s %s ---\n',record_i{indici.id_file},record_i{indici.nome},record_i{indici.cogn})
%     debug_i = 1;
% end

somma = 0;
% val_empty = 1/num; % initial value for empty fields
thr = 0.14; % target fitness when num_empty field are present, and the others are perfect matches
matr_num_ko = [
    1   2   3   4   5   6   7   8   9   10  20  % total number of fields
    0   0   1   1   2   3   3   4   5   5   8   % allowed number of empty fields to achieve thr fitness
    ];
num_ko = floor(interp1(matr_num_ko(1,:),matr_num_ko(2,:),num,'linear','extrap')); % initial value for empty fields (doubled at every empty field)
val_empty = thr*num/(2^num_ko-1);
for i_field = 1:num
    if (somma <= soglia2)
        indice_tag = lista_num(i_field);
        
        ks1 = lista_ks{i_field};
        ks2 = record_i{indice_tag};
        
        if (isempty(ks2) || isnan(ks2(1)) )
            % % campo vuoto, lo considero, ma penalizzo molto leggermente
            % val = 1/num;
            % % campo vuoto, lo penalizzo molto
            % val = 1;
            % % campo vuoto, lo penalizzo in funzione di quanti campi di
            % % ricerca ci sono, e di quanti campi vuoti ha il record
            val = val_empty;
            val_empty = min(1,val_empty*2); % each empty field doubles the vote (worst match)
        else
            % gestisci campi particolari
            switch (indice_tag)
                case indici.nome
                    % per il campo 'nome' considera anche il campo nome_2 (secondo nome)
                    ks_nome_2 = record_i{indici.nome_2};
                    if (~isempty(ks_nome_2))
                        ks2 = [ks2 ' ' ks_nome_2]; %#ok<AGROW>
                    end
            end
            
            % case insensitive
            ks2 = upper(ks2);
            
            
            if (ischar(ks1))
                val = strfielddist(ks1,ks2);
            else
                % scalar -> range with one year tolerance
                if (length(ks1) == 1)
                    ks1 = ks1+[-1 +1]*0.5; % this range allows to have only one match, with relax factor 0
                end
                
                % range: il numero deve essere all'interno              
                if (length(ks1) >= 2)
                    if (length(ks1) > 3)
                         error('Unmanaged length for!')
                         %                 val = 1;
                    elseif (length(ks1) == 3)
                        % il terzo parametro indica la tolleranza sui match
                        % all'esterno della finestra
                        peso = ks1(3);
                        ks1 = ks1(1:2);
                    else
                        peso = 3;
                    end
                    
                    if (ks2 >= min(ks1) && (ks2 <= max(ks1)) )
                        % interno finestra --> fitness massima (0)
                        val = 0;
                    else
                        % viene raggiunto il fitness peggiore (1) a una
                        % distanza dal centro della finestra pari
                        % all'estensione della finestra/peso
                        val = abs(ks2-mean(ks1))/abs(diff(ks1))/peso;
                        val = min(val,1);
                    end
                else
                    error('Unmanaged length for!')
                    %                 val = 1;
                end
            end
        end
        %%% show_field_fitness(ks1,ks2,val,debug_i) % show fitness of the field, for debug
        
        flag_i = val/num; % fitness normalizzata
        somma = somma+flag_i;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_field_fitness(ks1,ks2,val,debug_i)

if debug_i
    list     = {ks1,ks2};
    list_out = list; % preallocation for performance
    for i=1:2
        ks = list{i};

        if ischar(ks)
            ks_msg = ks;
        elseif isnan(ks)
            ks_msg = 'NaN';
        else
            ks_msg = num2str(ks);
            if length(ks) > 1
                ks_msg = ['[' ks_msg ']']; %#ok<AGROW>
            end
        end
        list_out{i} = ks_msg;
    end

    msg = sprintf('%-s - %s : %.3f',list_out{:},val);
    disp(msg)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status tabella] = archivio_2_tabella(archivio,header)

indici = indici_csv(header);
indici_arc = indici_archivio();

status = 1;
tabella = {};

lista = fieldnames(indici);
lista2 = {};
for i=1:length(lista)
    lista2{i} = indici.(lista{i});
end

[lista_tag{1:length(header)}] = deal('');
for i_field = 1:length(header)
    tag = header{i_field};

    ind = find(strcmp(tag,lista2));
    if (length(ind) ~= 1)
        status = 0;
        fprintf(1,'Missing field %s\n',tag)
        return;
    end
    lista_tag{i_field} = lista{ind};
    ind_tag(i_field) = indici_arc.(lista{ind});
end

tabella = repmat({''},length(archivio),length(header));
for i_record = 1:length(archivio)
    record = archivio(i_record,ind_tag);
    tabella(i_record,:) = record;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status items] = prepare_report(str_archivio,result)

status = 1;

num_ok = length(result.mask_id);
items = repmat({[]},1,num_ok);
count_ok = 0;
for ind = 1:num_ok
    count_ok = count_ok+1;
    
    i_rec = result.mask_id(ind);
    somma = result.mask_fit(ind);
    
    record_i = str_archivio.archivio(i_rec,:);
    ks = record2msg(record_i,'oneline'); % prepare a string with the main info from the record (ID, birth, marriage and death date, etc)
    
    head = sprintf('fit: %f - row: %5d',somma,i_rec);
    msgs = {ks};
    
    item = struct('id',i_rec);
    item.head = head;
    item.msgs = msgs;
    items{count_ok} = item;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_items(items)

for ind = 1:length(items)
    item = items{ind};
    
    head = item.head;
    msgs = item.msgs;

    disp(' ');
    fprintf(1,'%4d) %s\n',ind,head);
    padding = repmat(' ',1,4);
    for j = 1:length(msgs)
        disp([padding msgs{j}]);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [items_new items] = show_report_with_soap(str_archivio,result,flg_quiet)

[status items] = prepare_report(str_archivio,result);

num_ok = length(items);
items_new = items;
if ( isfield(result,'result_soap') && ~isempty(result.result_soap) && isfield(result.result_soap,'list_found') )
    list_pgv_info = result.result_soap.list_found;
    if ( length(list_pgv_info) == num_ok )
        
        for i=1:num_ok
            pgv_info = list_pgv_info{i};
            if ~isempty(pgv_info)
                % some pgv link found, update the header
                head = items{i}.head;
                
                p = result.result_soap.list_found{i};
                [v_fitness ind] = sort([p.fitness]);
                p = p(ind);
                p_i = p(1); % take the best match
                
                result_pgvurl = uploader('prepare_pgv_links',{result.result_soap.soap_struct.wsdl_url,p_i.PID,p_i.childFamilies,p_i.spouseFamilies});
                msgs_pgv = sprintf('%.4f\t%5s - %25s  n: %-12s  m: %-12s (%s,%s,%s) (di %s e %s) ("%s")',p_i.fitness,p_i.PID,p_i.gedcomName,p_i.birthDate,p_i.deathDate,result_pgvurl.individual_atab,result_pgvurl.child_family_atab,result_pgvurl.spouse_family_atab,p_i.pad_nome_gedcom,p_i.mad_nome_gedcom,p_i.query);
                
                head = sprintf('%s  -->  %s',head,msgs_pgv);
                items_new{i}.head = head;
            end
        end
        
    else
        error('Todo: different length of two vectors (%d and %d)!',length(list_pgv_info),num_ok)
    end
end

if ( ~flg_quiet )
    show_items(items_new);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status report archivio] = check_archivio(archivio)

status = 1;
report = {};

for i_record = 1:size(archivio,1)
    if (rem(i_record,1000) == 0)
        fprintf(1,'%d/%d...\n',i_record/1000,floor(size(archivio,1)/1000))
    end
%i_record
    record = archivio(i_record,:);
    [items, record, changed] = check_record(i_record,record);
    if (changed)
        archivio(i_record,:) = record;
    end

    report((end+1):(end+length(items))) = items;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [items record changed] = check_record(i_record,record)

indici = indici_archivio;

init_flag = i_record == 1;

items = {};

head = sprintf('%s %s (riga %d, ID_FILE %s):',record{indici.nome},record{indici.cogn},i_record+1,record{indici.id_file});

item = struct('id',i_record);
item.head = head;

% verifica che nei campi non ci siano lettere minuscole
err_code = 1;
items = check_minuscole(record,indici,items,item,err_code,init_flag);

% verifica i formati delle date
err_code = 2;
[record, items, changed_2] = check_date(record,indici,items,item,err_code,init_flag);

% verifica i formati numerici
err_code = 3;
[record, items, changed_3] = check_numeri(record,indici,items,item,err_code,init_flag);

% verifica la coerenza tra le date
err_code = 4;
[record, items, changed_4] = check_date_coherence(record,indici,items,item,err_code,init_flag);


if (changed_2 || changed_3 || changed_4)
    changed = 1;
    disp(sprintf('Modifico il record n. %d',i_record))
else
    changed = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function items = check_minuscole(record,indici,items,item,err_code,init_flag)

lista = {'nome','nome_2','cogn','pad_nome','mad_nome','mad_cogn','con_nome','con_cogn','nasc_luo','mort_luo','note','prof'};

persistent v_ind_tag

if (init_flag)
    for i=1:length(lista)
        v_ind_tag(i) = indici.(lista{i});
    end
end

len_lista = length(lista);
for i=1:len_lista;
    tag = lista{i};
    ind_tag = v_ind_tag(i);
    
    ks = record{ind_tag};
    if ismember(setdiff(ks,upper(ks)),'a':'z') % se c'e' qualche lettera minuscola
        %if ~strcmp(ks,upper(ks))
        item.err_code = err_code;
        item.msgs = {sprintf('err.%d: lettere minuscole nel campo %s: %s',err_code,tag,ks)};
        items{end+1} = item;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [record items changed] = check_date(record,indici,items,item,err_code,init_flag)

lista_ref = {'nasc','matr_civ','matr_rel','matr','mort','pad_nasc','mad_nasc'}; % all possible date fields

persistent v_ind_tag lista

if (init_flag)
    lista = intersect(fieldnames(indici),lista_ref);
    for i=1:length(lista)
        v_ind_tag(i) = indici.(lista{i});
    end
end

changed = 0;
for i=1:length(lista);
    tag = lista{i};
    ind_tag = v_ind_tag(i);

    ks = record{ind_tag};

    g = NaN;
    m = NaN;
    a = NaN;
    if (isempty(ks))
        ok = 1;
    else
        [ok g m a val_num_ok] = get_date_values(ks); % recupera i valori numerici dalla data
        if (~ok)
            numero = str2double(ks);
            flg_only_year = ~isnan(numero) && (numero>1500) && (numero<2017); % detetc single year date (es. '1798')
            if (flg_only_year)
                % data degenere: è presente solo l'anno (es. '1818')
                fprintf(1,'record id %s - Formato data degenere, con solo anno, senza giorno e mese: %s\n',record{indici.id_file},ks)
                ok = 1;
            elseif ( ~isnan(numero) )
                % prova a verificare se la data e' nella forma "-29675" invece di "10/01/1818"
                ks_corrected = datestr(datenum('0 jan 1900')+numero-1,'mm/dd/yyyy');
                z=regexp(ks_corrected,'([0-9]{2})/([0-9]{2})/([0-9]{4})','tokens');
                if (~isempty(z))
                    g = str2double(z{1}{1});
                    m = str2double(z{1}{2});
                    a = str2double(z{1}{3});

                    ok = (g<=12);
                    if (ok)
                        changed = 1;
                        record{indici.(tag)} = ks_corrected;
                    end
                else
                    ok=0;
                end
            end
            % disp(sprintf('%s: %d --> %s %d',ks,numero,ks_corrected,ok))
        end
    end

    if ~ok
        item.msgs = {sprintf('err.%d: formato data errata nel campo %s: %s',err_code,tag,record{indici.(tag)})};
        items{end+1} = item;
    end

    if (~isnan(g) && ~isnan(m) && ~isnan(a) && isfield(indici,['int_' tag '_num']))
        % verifica che giorno, mese e anno sia coerente con la data
        % completa, se esistono i corrispondenti campi numerici

        tag_g   = ['int_' tag '_g'];
        tag_m   = ['int_' tag '_m'];
        tag_a   = ['int_' tag '_a'];
        tag_num = ['int_' tag '_num'];

        val_g = NaN;
        val_m = NaN;
        val_a = NaN;
        val_num = NaN;
        if (~isnan(record{indici.(tag_g)}))
            val_g = record{indici.(tag_g)};
            val_m = record{indici.(tag_m)};
            val_a = record{indici.(tag_a)};
            val_num = record{indici.(tag_num)};
        end

        % verifica la coerenza
        if ( ((val_g ~= g) && ~isnan(val_g)) || ((val_m ~= m) && ~isnan(val_m)) || ((val_a ~= a) && (~isnan(val_a))) || ...
           ((abs(val_num-val_num_ok)>1e-4) && ~isnan(val_num)) )

            item.msgs = {sprintf('err.%d: giorno-mese-anno (%02d-%02d-%d) non coerenti con la data nel campo %s: %s (%.4f)',err_code,val_g,val_m,val_a,tag,ks,val_num_ok)};
            items{end+1} = item;

            changed = 1;
        end

        % imposta comunque i valori numerici coerenti con la data
        record{indici.(tag_g)}   = g;
        record{indici.(tag_m)}   = m;
        record{indici.(tag_a)}   = a;
        record{indici.(tag_num)} = val_num_ok;

        % e resetta i valori originari, se modificati
        if (changed)
            tag_g2   = [tag '_g'];
            tag_m2   = [tag '_m'];
            tag_a2   = [tag '_a'];
            tag_num2 = [tag '_num'];

            record{indici.(tag_g2)}   = num2str(record{indici.(tag_g)});
            record{indici.(tag_m2)}   = num2str(record{indici.(tag_m)});
            record{indici.(tag_a2)}   = num2str(record{indici.(tag_a)});
            record{indici.(tag_num2)} = num2str(record{indici.(tag_num)},'%.11f');
        end

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ok g m a val_num] = get_date_values(ks)

z=regexp(ks,'([0-9]{2})/([0-9]{2})/([0-9]{4})','tokens');
if (~isempty(z))
    g = (ks(1)-double('0'))*10+ks(2)-double('0');
    m = (ks(4)-double('0'))*10+ks(5)-double('0');
    a = (ks(7)-double('0'))*1000+(ks(8)-double('0'))*100+(ks(9)-double('0'))*10+(ks(10)-double('0'));

    val_num = (((g-1)/31+m-1)/12+a);

    vect=datevec(now);
    year_now = vect(1);
    
    res = datevec(datenum(a,m,g));
    ok = isequal(res(1:3),[a m g]) && (g >= 1 && g <= 31) && (m >= 1 && m <= 12) && (a >= 1500 && a <= year_now);
else
    ok = 0;
    g = NaN;
    m = NaN;
    a = NaN;
    val_num = NaN;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [record items changed] = check_numeri(record,indici,items,item,err_code,init_flag)

persistent v_ind_tag v_ind_tag_src

lista =     {'id_file','nasc_Nr','matr_Nr','mort_Nr','eta',...
             'nasc_a','nasc_m','nasc_g','nasc_num','matr_a','matr_m','matr_g','matr_num',...
             'mort_a','mort_m','mort_g','mort_num'};
lista_src = {''      ,''      ,''      ,''       ,''      ,...
             'nasc'  ,'nasc'  ,'nasc'  ,'nasc'   ,'matr'  ,'matr'  ,'matr'  ,'matr'   ,...
             'mort'  ,'mort'  ,'mort'  ,'mort'   };

if (init_flag)
    for i=1:length(lista)
        v_ind_tag(i) = indici.(lista{i});
        tag_src = lista_src{i};     % nome campo sorgente con la data
        if (~isempty(tag_src))
            val = indici.(lista_src{i});
        else
            val = NaN;
        end
        v_ind_tag_src(i) = val;
    end
end

changed = 0;
len_lista = length(lista);
for i=1:len_lista
    ind_tag = v_ind_tag(i);

    ok = 0;
    if (isempty(record{ind_tag}))
        % campo vuoto
        ind_tag_src = v_ind_tag_src(i);
        if (~isnan(ind_tag_src))
            ind_tag_src = v_ind_tag_src(i);
            ks_src      = record{ind_tag_src};  % campo sorgente con la data
            if (~isempty(ks_src))
                [ok_date g m a num] = get_date_values(ks_src);
                if (ok_date)
                    tag_src = lista_src{i};     % nome campo sorgente con la data
                    record{indici.([tag_src '_a'])}   = num2str(a);
                    record{indici.([tag_src '_m'])}   = num2str(m);
                    record{indici.([tag_src '_g'])}   = num2str(g);
                    record{indici.([tag_src '_num'])} = num2str(num);

                    changed = 1;

                    item.msgs = {sprintf('err.%d: aggiunto formato numerico per la data %s',err_code,tag_src)};
                    items{end+1} = item;
                end
            end
        end

        ok = 1;
    else
        ks = record{ind_tag};
        z=regexp(ks,'([0-9\.]+)','match');
        if (isempty(z))
            z=regexp(ks,'^\s*([0-9\.\+\-]+)\s*$','tokens');
            if (~isempty(z))
                ks_numero = z{1}{1};
            end
        else
            ks_numero = z{1};
        end
        if (~isempty(z))
            ks_corrected = ks_numero;
            if (~isempty(ks_corrected))
                ok = 1;
                if (~strcmp(ks,ks_corrected))
                    fprintf(1,'record id %s, %s --> %s ???\n',record{indici.id_file},ks,ks_corrected)
                    % changed = 1;
                    % tag = lista{i};
                    % record{indici.(tag)} = ks_corrected;
                end
            end
        end
    end

    if (ok == 0)
        tag = lista{i};
        item.msgs = {sprintf('err.%d: formato numerico errato nel campo %s: %s',err_code,tag,record{indici.(tag)})};
        items{end+1} = item; %#ok<AGROW>
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [record items changed] = check_date_coherence(record,indici,items,item,err_code,init_flag) %#ok<INUSD>

ok = 1;
changed = 0;

nasc_num = record{indici.int_nasc_num};
matr_num = record{indici.int_matr_num};
mort_num = record{indici.int_mort_num};

if (~isnan(nasc_num))
    if ( (~isnan(matr_num)) && (nasc_num > matr_num) )
        ok = 0;
    end
    if ( (~isnan(mort_num)) && (nasc_num > mort_num) )
        ok = 0;
    end
end
if (~isnan(matr_num))
    if ( (~isnan(mort_num)) && (matr_num > mort_num) )
        ok = 0;
    end
end

if ~ok
    item.msgs = {sprintf('err.%d: date incoerenti (B:%s M:%s D:%s)',err_code,record{indici.nasc},record{indici.matr},record{indici.mort})};
    items{end+1} = item;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [indici file_type] = indici_csv(header)

indici = struct();

% file_type 1: file 6..9
% IDElenco;N-Atto nø;Cognome;Nome;Secondo nome;Paese;Data di nascita;Nomepadre;Data di nascitaP;MestiereP;EtaP;CognomeM;NomeM;Data di nascitaM;MestiereM;EtaM;Domicilio;ChiesaBat;Data di battesimo;M-Atto nø;Mestiere;Eta;Data di matrimonio;Cognomeconiuge;Nomeconiuge;Paeseconiuge;Data di nascitaconiuge;Etaconiuge;Mestiereconiuge;Nome padre coniuge;Cognome mamma coniuge;Nome mamma coniuge;Mo-Atto nø;Paesedel decesso;Data di morte;Mo-Eta;LinkFotografia

% file_type 2: file 10...
% IDElenco;N-Atto nø;Cognome;Nome;Secondo nome;Paese;Data di nascita;Nomepadre;Data di nascitaP;MestiereP;EtaP;CognomeM;NomeM;Data di nascitaM;MestiereM;EtaM;Domicilio;ChiesaBat;Data di battesimo;M-Atto nø;Mestiere;Eta;Data di matrimonio;Cognomeconiuge;Nomeconiuge;Paeseconiuge;Data di nascitaconiuge;Etaconiuge;Mestiereconiuge;Nome padre coniuge;Cognome mamma coniuge;Nome mamma coniuge;Mo-Atto nø;Paesedel decesso;Data di morte;Mo-Eta;LinkFotografia;SposoPrecedente;SposaPrecedente;Note
% Giorno nascita;Mese nascita;Anno nascita;Data nascita;Giorno matrimonio;Mese matrimonio;Anno matrimonio;Data matrimonio;Giorno morte;Mese morte;Anno morte;Data morte

% file_type 3: file 10_rc_20120911
% IDElenco;N-Atto nø;Cognome;Nome;Secondo nome;Paese;Data di nascita;Nomepadre;Data di nascitaP;MestiereP;EtaP;CognomeM;NomeM;Data di nascitaM;MestiereM;EtaM;Domicilio;ChiesaBat;Data di battesimo;M-Atto nø;Mestiere;Eta;Data di matrimonio;Cognomeconiuge;Nomeconiuge;Paeseconiuge;Data di nascitaconiuge;Etaconiuge;Mestiereconiuge;Nome padre coniuge;Cognome mamma coniuge;Nome mamma coniuge;Mo-Atto nø;Paesedel decesso;Data di morte;Mo-Eta;LinkFotografia;SposaPrecedente;SposoPrecedente;
% Data di matrimonio religioso;Note;NonnoPaterno;NonnoMaterno;Giorno nascita;Mese nascita;Anno nascita;Data nascita;Giorno matrimonio;Mese matrimonio;Anno matrimonio;Data matrimonio;Giorno morte;Mese morte;Anno morte;Data morte



if strmatch('Data di sepoltura',header,'exact')
    file_type = 4; % per il file con aggiunta la data della sepoltura, e di emigrazione
elseif strmatch('Data di matrimonio religioso',header,'exact')
    file_type = 3; % per il file con aggiunta la data del matrimonio religioso (18/09/2012-...)
elseif strmatch('IDElenco',header,'exact')
    file_type = 2; % per il file aggiornato (23/05/2010-18/09/2012)
else
    file_type = 1; % per il file vecchio (prima del 23/05/2010)
end

switch (file_type)
    
    case 4 % da file10_rc_20140718 in poi
        indici.id_file  = 'IDElenco';
        indici.nome     = 'Nome';
        indici.cogn     = 'Cognome';
        indici.nome_2   = 'Secondo nome';
        indici.pad_nome = 'Nomepadre';
        indici.pad_nasc = 'Data di nascitaP';
        indici.mad_nome = 'NomeM';
        indici.mad_cogn = 'CognomeM';
        indici.mad_nasc = 'Data di nascitaM';
        indici.con_nome = 'Nomeconiuge';
        indici.con_cogn = 'Cognomeconiuge';
        indici.nasc     = 'Data di nascita';
        indici.nasc_luo = 'Paese';
        indici.nasc_Nr  = 'N-Atto nø';
        indici.matr_civ = 'Data di matrimonio';
        indici.matr_rel = 'Data di matrimonio religioso';
        indici.matr     = 'Data di matrimonio principale'; % data matrimonio civile se presente, altrimenti religioso (uso la stessa colonna del file)
        indici.matr_Nr  = 'M-Atto nø';
        indici.mort     = 'Data di morte';
        indici.mort_luo = 'Paesedel decesso';
        indici.mort_Nr  = 'Mo-Atto nø';
        indici.eta      = 'Mo-Eta'; % eta' al decesso
        indici.prof     = 'Mestiere';
        indici.nasc_a   = 'Anno nascita';
        indici.nasc_m   = 'Mese nascita';
        indici.nasc_g   = 'Giorno nascita';
        indici.nasc_num = 'Data nascita';
        indici.matr_a   = 'Anno matrimonio';
        indici.matr_m   = 'Mese matrimonio';
        indici.matr_g   = 'Giorno matrimonio';
        indici.matr_num = 'Data matrimonio';
        indici.mort_a   = 'Anno morte';
        indici.mort_m   = 'Mese morte';
        indici.mort_g   = 'Giorno morte';
        indici.mort_num = 'Data morte';
        indici.pad_prof = 'MestiereP';
        indici.pad_eta  = 'EtaP';
        indici.mad_prof = 'MestiereM';
        indici.mad_eta  = 'EtaM';
        indici.domic    = 'Domicilio';
        indici.batt_chi = 'ChiesaBat';
        indici.batt     = 'Data di battesimo';
        indici.con_orig = 'Paeseconiuge';
        indici.con_nasc = 'Data di nascitaconiuge';
        indici.con_eta  = 'Etaconiuge';
        indici.con_prof = 'Mestiereconiuge';
        indici.con_pad_nome = 'Nome padre coniuge';
        indici.con_mad_cogn = 'Cognome mamma coniuge';
        indici.con_mad_nome = 'Nome mamma coniuge';
        indici.matr_eta     = 'Eta'; % eta' al matrimonio
        indici.photo        = 'LinkFotografia';
        indici.con_prec_M   = 'SposoPrecedente';
        indici.con_prec_F   = 'SposaPrecedente';
        indici.note         = 'Note';
        indici.pad_pad      = 'NonnoPaterno';
        indici.mad_pad      = 'NonnoMaterno';
        indici.sep          = 'Data di sepoltura';
        indici.emig         = 'Emigrazione'; % data di emigrazione

    case 3 % da file10_rc_20120911 in poi
        indici.id_file  = 'IDElenco';
        indici.nome     = 'Nome';
        indici.cogn     = 'Cognome';
        indici.nome_2   = 'Secondo nome';
        indici.pad_nome = 'Nomepadre';
        indici.pad_nasc = 'Data di nascitaP';
        indici.mad_nome = 'NomeM';
        indici.mad_cogn = 'CognomeM';
        indici.mad_nasc = 'Data di nascitaM';
        indici.con_nome = 'Nomeconiuge';
        indici.con_cogn = 'Cognomeconiuge';
        indici.nasc     = 'Data di nascita';
        indici.nasc_luo = 'Paese';
        indici.nasc_Nr  = 'N-Atto nø';
        indici.matr_civ = 'Data di matrimonio';
        indici.matr_rel = 'Data di matrimonio religioso';
        indici.matr     = 'Data di matrimonio principale'; % data matrimonio civile se presente, altrimenti religioso (uso la stessa colonna del file)
        indici.matr_Nr  = 'M-Atto nø';
        indici.mort     = 'Data di morte';
        indici.mort_luo = 'Paesedel decesso';
        indici.mort_Nr  = 'Mo-Atto nø';
        indici.eta      = 'Mo-Eta'; % eta' al decesso
        indici.prof     = 'Mestiere';
        indici.nasc_a   = 'Anno nascita';
        indici.nasc_m   = 'Mese nascita';
        indici.nasc_g   = 'Giorno nascita';
        indici.nasc_num = 'Data nascita';
        indici.matr_a   = 'Anno matrimonio';
        indici.matr_m   = 'Mese matrimonio';
        indici.matr_g   = 'Giorno matrimonio';
        indici.matr_num = 'Data matrimonio';
        indici.mort_a   = 'Anno morte';
        indici.mort_m   = 'Mese morte';
        indici.mort_g   = 'Giorno morte';
        indici.mort_num = 'Data morte';
        indici.pad_prof = 'MestiereP';
        indici.pad_eta  = 'EtaP';
        indici.mad_prof = 'MestiereM';
        indici.mad_eta  = 'EtaM';
        indici.domic    = 'Domicilio';
        indici.batt_chi = 'ChiesaBat';
        indici.batt     = 'Data di battesimo';
        indici.con_orig = 'Paeseconiuge';
        indici.con_nasc = 'Data di nascitaconiuge';
        indici.con_eta  = 'Etaconiuge';
        indici.con_prof = 'Mestiereconiuge';
        indici.con_pad_nome = 'Nome padre coniuge';
        indici.con_mad_cogn = 'Cognome mamma coniuge';
        indici.con_mad_nome = 'Nome mamma coniuge';
        indici.matr_eta     = 'Eta'; % eta' al matrimonio
        indici.photo        = 'LinkFotografia';
        indici.con_prec_M   = 'SposoPrecedente';
        indici.con_prec_F   = 'SposaPrecedente';
        indici.note         = 'Note';
        indici.pad_pad      = 'NonnoPaterno';
        indici.mad_pad      = 'NonnoMaterno';
                
    case 2 % da file6 in poi
        indici.id_file  = 'IDElenco';
        indici.nome     = 'Nome';
        indici.cogn     = 'Cognome';
        indici.nome_2   = 'Secondo nome';
        indici.pad_nome = 'Nomepadre';
        indici.pad_nasc = 'Data di nascitaP';
        indici.mad_nome = 'NomeM';
        indici.mad_cogn = 'CognomeM';
        indici.mad_nasc = 'Data di nascitaM';
        indici.con_nome = 'Nomeconiuge';
        indici.con_cogn = 'Cognomeconiuge';
        indici.nasc     = 'Data di nascita';
        indici.nasc_luo = 'Paese';
        indici.nasc_Nr  = 'N-Atto nø';
        indici.matr     = 'Data di matrimonio';
        indici.matr_Nr  = 'M-Atto nø';
        indici.mort     = 'Data di morte';
        indici.mort_luo = 'Paesedel decesso';
        indici.mort_Nr  = 'Mo-Atto nø';
        indici.eta      = 'Mo-Eta'; % eta' al decesso
        indici.prof     = 'Mestiere';
        indici.nasc_a   = 'Anno nascita';
        indici.nasc_m   = 'Mese nascita';
        indici.nasc_g   = 'Giorno nascita';
        indici.nasc_num = 'Data nascita';
        indici.matr_a   = 'Anno matrimonio';
        indici.matr_m   = 'Mese matrimonio';
        indici.matr_g   = 'Giorno matrimonio';
        indici.matr_num = 'Data matrimonio';
        indici.mort_a   = 'Anno morte';
        indici.mort_m   = 'Mese morte';
        indici.mort_g   = 'Giorno morte';
        indici.mort_num = 'Data morte';
        indici.pad_prof = 'MestiereP';
        indici.pad_eta  = 'EtaP';
        indici.mad_prof = 'MestiereM';
        indici.mad_eta  = 'EtaM';
        indici.domic    = 'Domicilio';
        indici.batt_chi = 'ChiesaBat';
        indici.batt     = 'Data di battesimo';
        indici.con_orig = 'Paeseconiuge';
        indici.con_nasc = 'Data di nascitaconiuge';
        indici.con_eta  = 'Etaconiuge';
        indici.con_prof = 'Mestiereconiuge';
        indici.con_pad_nome= 'Nome padre coniuge';
        indici.con_mad_cogn= 'Cognome mamma coniuge';
        indici.con_mad_nome= 'Nome mamma coniuge';
        indici.matr_eta = 'Eta'; % eta' al matrimonio
        indici.photo    = 'LinkFotografia';
        
        if strmatch('Note',header,'exact') % da file6 in poi
            indici.con_prec_M   = 'SposoPrecedente';
            indici.con_prec_F   = 'SposaPrecedente';
            indici.note         = 'Note';
            indici.pad_pad      = 'NonnoPaterno';
            indici.mad_pad      = 'NonnoMaterno';
        end            
        
        
    case 1 % file vecchio (fino a file5)
        indici.id_file  = 'IDElenco indirizzi';
        indici.nome     = 'Nome';
        indici.cogn     = 'Cognome';
        indici.pad_nome = 'Nome del papà';
        indici.pad_nasc = 'Data di nascita del papà';
        indici.mad_nome = 'Nome della mamma';
        indici.mad_cogn = 'Cognome della mamma';
        indici.mad_nasc = 'Data di nascita della mamma';
        indici.con_nome = 'Nome coniuge';
        indici.con_cogn = 'Cognome coniuge';
        indici.nasc     = 'Data di nascita';
        indici.nasc_luo = 'Luogo di nascita';
        indici.nasc_Nr  = 'Atto di nascita N°';
        indici.matr     = 'Data di matrimonio';
        indici.matr_Nr  = 'Atto di matrimonio N°';
        indici.mort     = 'Data di morte';
        indici.mort_luo = 'Luogo di morte';
        indici.mort_Nr  = 'Atto di morte N°';
        indici.eta      = 'Età';
        indici.note     = 'Note';
        indici.prof     = 'Professione';
        indici.nasc_No  = 'Numero d''ordine nascita';
        indici.matr_No  = 'Numero d''ordine matrimonio';
        indici.mort_No  = 'Numero d''ordine morte';
        indici.nasc_a   = 'Anno nascita';
        indici.nasc_m   = 'Mese nascita';
        indici.nasc_g   = 'Giorno nascita';
        indici.nasc_num = 'Data nascita';
        indici.matr_a   = 'Anno matrimonio';
        indici.matr_m   = 'Mese matrimonio';
        indici.matr_g   = 'Giorno matrimonio';
        indici.matr_num = 'Data matrimonio';
        indici.mort_a   = 'Anno morte';
        indici.mort_m   = 'Mese morte';
        indici.mort_g   = 'Giorno morte';
        indici.mort_num = 'Data morte';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function indici = indici_archivio(allfields)

global buf_indici

if (exist('allfields','var') && ~isempty(allfields))
    indici = struct();
    for i = 1:length(allfields)
        indici.(allfields{i})=i;
    end
    buf_indici = indici;
else
    indici = buf_indici;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [status archivio lista indici_strutt] = crea_archivio(header,tabella)

status = 1;

[indici file_type] = indici_csv(header);

% id_file:  'IDElenco'
% nome:     'Nome'
% cogn:     'Cognome'
% nome_2:   'Secondo nome'
% pad_nome: 'Nomepadre'
% pad_nasc: 'Data di nascitaP'
% mad_nome: 'NomeM'
% mad_cogn: 'CognomeM'
% mad_nasc: 'Data di nascitaM'
% con_nome: 'Nomeconiuge'
% con_cogn: 'Cognomeconiuge'
% nasc:     'Data di nascita'
% nasc_luo: 'Paese'
% nasc_Nr:  'N-Atto nø'
% matr_civ: 'Data di matrimonio % civile
% matr_rel: 'Data di matrimonio religioso'
% matr:     'Data di matrimonio principale' % unificato (civile, e se manca allora religioso)
% matr_Nr:  'M-Atto nø'
% mort:     'Data di morte'
% mort_luo: 'Paesedel decesso'
% mort_Nr:  'Mo-Atto nø'
% eta:      'Eta'
% prof:     'Mestiere'
% nasc_a:   'Anno nascita'
% nasc_m:   'Mese nascita'
% nasc_g:   'Giorno nascita'
% nasc_num: 'Data nascita'
% matr_a:   'Anno matrimonio'
% matr_m:   'Mese matrimonio'
% matr_g:   'Giorno matrimonio'
% matr_num: 'Data matrimonio'
% mort_a:   'Anno morte'
% mort_m:   'Mese morte'
% mort_g:   'Giorno morte'
% mort_num: 'Data morte'
% pad_prof: 'MestiereP'
% pad_eta:  'EtaP'
% mad_prof: 'MestiereM'
% mad_eta:  'EtaM'
% domic:    'Domicilio'
% batt_chi: 'ChiesaBat'
% batt:     'Data di battesimo'
% con_orig: 'Paeseconiuge'
% con_nasc: 'Data di nascitaconiuge'
% con_eta:  'Etaconiuge'
% con_prof: 'Mestiereconiuge'
% con_pad_nome: 'Nome padre coniuge'
% con_mad_cogn: 'Cognome mamma coniuge'
% con_mad_nome: 'Nome mamma coniuge'
% matr_eta: 'Mo-Eta'
% photo:    'LinkFotografia'
% con_prec_M:   'SposoPrecedente'
% con_prec_F:   'SposaPrecedente'
% note:     'Note'
% pad_pad:  'NonnoPaterno'
% mad_pad:  'NonnoMaterno'

if (file_type>=3)
    % se necessario, crea colonna 'Data di matrimonio principale' % unificato (civile, e se manca allora religioso)
    ind_matr = strmatch(indici.matr,header,'exact');
    if isempty(ind_matr)
        % la colonna manca, calcolala
        ind_matr_civ = strmatch(indici.matr_civ,header,'exact');
        ind_matr_rel = strmatch(indici.matr_rel,header,'exact');
        if ( isempty(ind_matr_civ) || isempty(ind_matr_rel) )
            error('Missing one of the two types of marriage date (civil or religious).')
        end
        col_matr_civ = tabella(:,ind_matr_civ);
        col_matr_rel = tabella(:,ind_matr_rel);
        
        col_matr = col_matr_civ;
        ind_empty_civ = cellfun('isempty',col_matr);
        col_matr(ind_empty_civ) = col_matr_rel(ind_empty_civ);
        
        % aggiungi colonna calcolata
        header{end+1}       = 'Data di matrimonio principale';
        tabella(:,end+1)    = col_matr;
    end
end


% se necessario, crea colonna 'Note'
if isfield(indici,'note')
    tag_note = indici.note;
else
    tag_note = 'Note';
    indici.note = tag_note;
end
ind_matr = strmatch(tag_note,header,'exact');
if isempty(ind_matr)
    % la colonna manca, calcolala
    col_note = '';
    
    % aggiungi colonna calcolata
    header{end+1}       = 'Note';
    tabella(:,end+1)    = {col_note};
end


fields = fieldnames(indici);

id_field = zeros(1,length(fields));
for i_field = 1:length(fields)
    indice = find(strcmp(indici.(fields{i_field}),header),1);

    if isempty(indice)
        fprintf(1,'Campo %s non trovato!\n',fields{i_field})
        id_field(i_field) = NaN;        
    else
        id_field(i_field) = indice;
    end
end

% crea nomi campi numerici
lista_2num = {'id_file','nasc_Nr','matr_Nr','mort_Nr','eta',...
              'nasc_a','nasc_m','nasc_g','nasc_num','matr_a','matr_m','matr_g','matr_num',...
              'mort_a','mort_m','mort_g','mort_num'};
lista_2num_new = lista_2num;
lista_2num_id = zeros(1,length(lista_2num));
for i_field = 1:length(lista_2num);
    lista_2num_new{i_field} = ['int_' lista_2num{i_field}];

    tag = lista_2num{i_field};
    lista_2num_id(i_field) = find(strcmp(tag,fields));
end

allfields = {fields{:},lista_2num_new{:}};

% crea indici per l'archivio, e rendilo disponibile
indici_strutt = indici_archivio(allfields);

% crea struttura
offset = length(id_field);
[record_new{1:length(allfields)}] = deal(NaN);
archivio{size(tabella,1),length(allfields)} = '';

ind_to = 1:length(id_field);
ind_from = id_field(ind_to);
ind_from_num = id_field(lista_2num_id(1:length(lista_2num)));
ind_not_is_nan = find(~isnan(ind_from));

[record_new0{1:length(allfields)}] = deal(NaN);
bulk_num = ones(size(tabella,1),length(ind_from_num))*NaN;
for i_line = 1:size(tabella,1)

    [v_field{1:length(ind_from)}] = deal('');
    v_field(ind_not_is_nan) = tabella(i_line,ind_from(ind_not_is_nan));
    record_new = record_new0;
    record_new(ind_to) = v_field;

    % crea campi numerici
    ind_not_is_nan_ind = find(~isnan(ind_from_num));
    [v_ks{1:length(ind_from_num)}] = deal('');
    v_ks(ind_not_is_nan_ind) = tabella(i_line,ind_from_num(ind_not_is_nan_ind));

    ind = find(~strcmp('',v_ks));
    for i = ind
        val = str2double(v_ks{i});
        record_new{offset+i} = val;
        bulk_num(i_line,i) = val;
    end

    archivio(i_line,:) = record_new;
end

% crea liste
lista = struct();
for i_field = 1:length(allfields)
    tag = allfields{i_field};
    ks = record_new{i_field};
    tipo_numerico = ( isreal(ks) && ~ischar(ks) );
    if tipo_numerico
        ind = strcmp(lista_2num,tag(5:end));
        lista.(tag) = bulk_num(:,ind);
    else
        lista.(tag) = archivio(:,i_field);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = write_file(filename,header,tabella,new_line)

format = repmat('%s;',1,length(header));
format = [format(1:length(format)-1) new_line];


fid=fopen(filename,'w');

fprintf(fid,format,header{:});

for i_line = 1:size(tabella,1);
    fprintf(fid,format,tabella{i_line,:});
end

fclose(fid);

result = 1;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result tabella info] = read_file(filename)

%  result = 0;
tabella = {};
info = struct;


fid=fopen(filename,'r');
z = textscan(fid,'%s\n','delimiter','\n');
buffer = fscanf(fid,'%c',1000); % leggi 1000 byte
fclose(fid);

header = regexp(z{1}{1},'[^\;]*','match');
num_columns = length(header);

new_line = '\r\n';
if (isempty(regexp(buffer,new_line,'once')))
    new_line = '\n';
end

file0 = textread(filename,'%s','delimiter',';\n','whitespace','\r');
num_records = numel(file0)/num_columns;
if (round(num_records)~=num_records)
    disp(sprintf('Verificare il file %s!',filename))

    file1 = textread(filename,'%s','delimiter','\n','whitespace','\r');

    for i_line = 2:length(file1)
        ks = file1{i_line};

        mask = (ks == ';');
        len = sum(mask)+1;

        ind = [0 find(mask) length(ks)+1];

        fields = {}; fields{len} = '';
        for i=2:length(ind),ind1 = ind(i-1)+1;ind2 = ind(i)-1;if (ind2-ind1 > -1),valore = ks(ind1:ind2);else valore = '';end, fields{i-1} = valore;end

        if (len > num_columns)
            disp(ks)
            error('Verifica la riga %d',i)
        elseif (len < num_columns)
            fields{num_columns} = '';
        end
        tabella(end+1,:) = fields;
    end

    new_filename = [filename '.bak'];
    result = write_file(new_filename,header,tabella,new_line);
    disp(sprintf('Ho aggiustato il file %s, e lo ho salvato in %s',filename,new_filename))

else
    tabella=reshape(file0,num_columns,num_records)';
    tabella = tabella(2:end,:);

    result = 1;
end



info.header         = header;
info.new_line       = new_line;
info.filename       = filename;
info.num_columns    = num_columns;
info.num_records    = num_records;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sex = determine_sex(ks_givn)
% determine sex from name ( sex = {'M','F',''} )

sex = '';

ks_givn = upper(ks_givn);

pattern_undefined = '^(DIAMANTE|FELICE|N\.?N\.?)$';
if isempty(regexp(ks_givn,pattern_undefined, 'once'))
    list = regexp(ks_givn,'[A-Z'']+','match');
    if (~isempty(list) && ~strcmp(ks_givn,'NON RIPORTATO') )
        nome = list{1};
        nome = strrep(nome,'''','');
        
        last_letter = nome(end);
        switch last_letter
            case 'A'
                sex = 'F';
                list_e_male = {
                    'ANDREA$'
                    'ANG(E|IO)LO?MARIA$'
                    'BATTISTA$'
                    '^ELIA$'
                    '^EVANGELISTA$'
                    'GEREMIA$'
                    '^GIOS(A|E)(FATT?A)?$'
                    'ISAIA$'
                    'LUCA$'
                    'MATTIA$'
                    '^NICC?OLA$'
                    'T[UO]BB?IA$'
                    'VENTURA$'
                    'ZACCARIA$'
                    };
                for i_pat=1:length(list_e_male)
                    pat = list_e_male{i_pat};
                    if ~isempty(regexp(nome,pat,'once'))
                        sex = 'M';
                    end
                end
            case 'E'
                sex = 'M';
                list_e_female = {
                    'ADELAIDE$'
                    'ADELE$'
                    'AGNESE$'
                    'BEATRICE$'
                    'BRADAMANTE$'
                    '^CELESTE$'
                    'CLOTILDE$'
                    'FEDE$'
                    'GERTRUDE$'
                    'IMPERATRICE$'
                    'IRENE$'
                    '^LOUISE$'
                    'MAT[IE]LDE$'
                    '^RACH([AE]|AE)LE$'
                    'VIOLANTE$'
                    };
                for i_pat=1:length(list_e_female)
                    pat = list_e_female{i_pat};
                    if ~isempty(regexp(nome,pat,'once'))
                        sex = 'F';
                    end
                end
            case 'I'
                sex = 'M';
                list_e_female = {
                    '^NOEMI$'
                    };
                for i_pat=1:length(list_e_female)
                    pat = list_e_female{i_pat};
                    if ~isempty(regexp(nome,pat,'once'))
                        sex = 'F';
                    end
                end
            case 'O'
                sex = 'M';
            otherwise
                sex = 'M';
                list_e_female = {
                    '^CAISER$'
                    '^ESTER$'
                    'JUDITH$'
                    'L(I|EO)NOR$' % ELINOR
                    '^LILLIAN$'
                    'LIZABETH$' % ELIZABETH
                    };
                for i_pat=1:length(list_e_female)
                    pat = list_e_female{i_pat};
                    if ~isempty(regexp(nome,pat,'once'))
                        sex = 'F';
                    end
                end
                
                fprintf(1,'Not sure about sex for name "%s", assuming "%s"\n',ks_givn,sex)
                pause(2)
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = strfielddist(ks1,ks2)

% determina la distanza tra le due stringhe ks1 e ks2, considerando le
% sottostringhe delimitate dallo spazio

persistent weights

debug = 0;

if isempty(weights)
    weights = repmat(cumsum(ones(1,10))*0.01,10,1);
end

krk = 1; % 2 -> calcola i due tipi di distanza (normale e editor distance); 1 -> calcola solo distanza normale
% krk = 1 because editor distance is not needed: ANGIOLO - ANGIOLA gives 1
% as normal distance, and 2 as editor (substitutions weight 2)
cas = 0; % 0 -> case-sensitive; 1 -> ignora la differenza tra minuscole/maiuscole
% cas = 0 because all input strings are already uppercase

if strcmp(ks1,ks2)
    val    = 0;
else
    % split input strings into substrings
    % es.: 'ALFONSINA MARIA' --> {'ALFONSINA','MARIA','ALFONSINAMARIA'}
    [vks1 lvks1] = get_words(ks1);
    [vks2 lvks2] = get_words(ks2);

    if ( (lvks1 > 1) || (lvks2 > 1) )
        md1 = zeros([lvks1 lvks2]);
        for i_1 = 1:lvks1
            for i_2 = 1:lvks2
                ks1_i = vks1{i_1};
                ks2_i = vks2{i_2};
                
                d = strdist(ks1_i,ks2_i,krk,cas);
                weight = (length(ks1_i)+length(ks2_i))/2;

                if (debug)
                    disp(sprintf('(%s-%s): %d %d - %.1f - %f %f',vks1{i_1},vks2{i_2},d(1),d(2),weight,d(1)/weight,d(2)/weight))
                end
                md1(i_1,i_2) = d/weight;
            end
        end
    
        % aggiungi un peso che penalizzi la posizione all'interno della
        % stringa: le prime posiz. sono privilegiate
        md1 = md1 + weights(1:size(md1,1),1:size(md1,2));
    
        % prendi la miglior corrispondenza disponibile
        mean_md = md1;
        
        val = find_min(mean_md); 
        % [val ind_i_2 ind_i_1] = find_min(mean_md); 
        % disp(sprintf('Miglior corrispondenza: %s - %s : %f',vks1{ind_i_1},vks2{ind_i_2},val))
        
    else
        d = strdist(ks1,ks2,krk,cas);
        weight = (length(ks1)+length(ks2))/2;
        val = d/weight;
    end
end

% il range di val e' 0..1
if (val > 1)
    val = 1;
end

%disp(sprintf('\n%16s-%16s:',ks1,ks2))
%disp(sprintf('\t(%1.4f,%1.4f),%2.1f -> %1.4f',d(1),d(2),weight,val))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [val j_min i_min] = find_min(matr)
% trova il minimo di una matrice, e restituisci gli indici corrispondenti

if size(matr,1) > 1
    % more than one row
    if size(matr,2) > 1
        % more than one column -> matrix
        temp = min(matr,[],1);
        [temp j_min]=min(temp);

        temp = min(matr,[],2);
        [temp i_min]=min(temp);

        val = matr(i_min,j_min);
    else
        % horizontal vector at most
        j_min = 1;
        [val i_min] = min(matr);
    end
else
    % only one row
    i_min = 1;
    if (length(matr)>1)
        % horizontal vector
        [val j_min] = min(matr);
    else
        % scalar
        [val j_min] = min(matr);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vks lvks] = get_words(ks)
% restituisci una o piu' sottostringhe
% es.: 'ALFONSINA MARIA' --> {'ALFONSINA','MARIA','ALFONSINAMARIA'}

if any(ks == ' ')
    vks = regexp(ks,'[^\s]+','match');
    min_length = 2;
    vks = vks(cellfun('length',vks)>min_length); % prendi solo sottostringhe piu' lunghe di min_length
    
    lvks = length(vks)+1;
    vks{lvks} = strrep(ks,' ',''); % aggiungi l'intera stringa, senza spazi
else
    vks = {ks};
    lvks = 1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d = strdist(r,b,krk,cas)

%d=strdist(r,b,krk,cas) computes Levenshtein and editor distance 
%between strings r and b with use of Vagner-Fisher algorithm.
%   Levenshtein distance is the minimal quantity of character
%substitutions, deletions and insertions for transformation
%of string r into string b. An editor distance is computed as 
%Levenshtein distance with substitutions weight of 2.
%d=strdist(r) computes numel(r);
%d=strdist(r,b) computes Levenshtein distance between r and b.
%If b is empty string then d=numel(r);
%d=strdist(r,b,krk)computes both Levenshtein and an editor distance
%when krk=2. d=strdist(r,b,krk,cas) computes a distance accordingly 
%with krk and cas. If cas>0 then case is ignored.
%
%Example.
% disp(strdist('matlab'))
%    6
% disp(strdist('matlab','Mathworks'))
%    7
% disp(strdist('matlab','Mathworks',2))
%    7    11
% disp(strdist('matlab','Mathworks',2,1))
%    6     9

switch nargin
   case 1
      d=numel(r);
      return
   case 2
      krk=1;
      bb=b;
      rr=r;
   case 3
       bb=b;
       rr=r;
   case 4
      bb=b;
      rr=r;
      if cas>0
         bb=upper(b);
         rr=upper(r);
      end
end

if krk~=2
   krk=1;
end

d = zeros(1,krk);
luma=numel(bb);
lima=numel(rr);
lu1=luma+1;
li1=lima+1;
dl=zeros([lu1,li1]);
dl(1,:)=0:lima;
dl(:,1)=0:luma;
%Distance
rrnum = double(rr);
bbnum = double(bb);
for krk1=1:krk
    for i=2:lu1
        imeno1 = i-1;
        bbi=bbnum(imeno1);
        for j=2:li1
            jmeno1 = j-1;
            kr=krk1;
            if rrnum(jmeno1)==bbi
                kr=0;
            end

            a1 = dl(imeno1,jmeno1)+kr;
            a2 = dl(imeno1,j)+1;
            a3 = dl(i,jmeno1)+1;
            if a1 < a2
                temp = a1;
            else
                temp = a2;
            end
            if (a3 < temp)
                temp = a3;
            end
            dl(i,j)=temp;
        end
    end
    d(krk1) = dl(lu1,li1);
end
