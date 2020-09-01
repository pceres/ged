%***************************************************************************************************
%
% SCRIPT   : uploader.m
% AUTHOR   : Pasquale CERES (pasquale.ceres@fptpowertrain.crf.it)
% VERSION  : $Id$
% COMMIT   : $Hash$
%
%***************************************************************************************************
%
% Tool for automatic mass upload to PhpGedView
%
% result = uploader(action,params);
%
% Input:
%   action: action string
%   params: cell array of params
%
%   action values:
%       'search': search for a record in the str_archivio archive inside
%                 the  PGV site via SOAP query.
%                 params={str_archivio,wsdl_url,list_records}
%                   str_archivio  : archive struct, with fields:
%                       archivio  : matrix cell array archive as loaded by 'go.m'
%                       indici_arc: headers for archivio cell array
%                       filename  : filename of the csv source file
%                   soap_struct, struct with fields:
%                       wsdl_url      : url of the wsdl page (es.
%                                      'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       SID           : session id (empty string, or missing field
%                                       to start new session)
%                   list_records  : list of people to be searched, in
%                                   the form:
%                                   - [record1 record2 ... recordN],
%                                     with recordI as str_archivio.archivio(I,:)
%       'browse': scan the PhpGedView online data, looking for persons or
%                 families whose gedcom data can be updated with data from
%                 flat archive and params = {str_archivio,wsdl_url,list_pid,flg_skip_real_update,arcfile}
%                    str_archivio  : archive struct, with fields:
%                       archivio  : matrix cell array archive as loaded by 'go.m'
%                       indici_arc: headers for archivio cell array
%                       filename  : filename of the csv source file
%                    wsdl_url      : url of the wsdl page (es.
%                                    'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                    list_pid      : list of numeric id's for people in pgv site used to iterate pgv persons in the gedcom
%                    flg_skip_real_update : 1 -> just scan the pgv database, but don't update it
%                    arcfile       : matfile containing variable list_changes, a cell array with
%                                    a record for each upload proposal (see 'interactive_upload' action)
%
%       'interactive_upload': iteratively and interactively upload
%                 previously archived (by 'browse') gedcom update proposals
%                   params = {wsdl_url,arcfile}
%                       str_archivio  : archive struct, with fields:
%                           archivio  : matrix cell array archive as loaded by 'go.m'
%                           indici_arc: headers for archivio cell array
%                           filename  : filename of the csv source file
%                       wsdl_url : url of the wsdl page (es.
%                                  'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       arcfile  : matfile containing variable list_changes, a cell array with
%                                  a record for each row, made up as follows:
%                                   {RID,RID_type,gedcom_old,gedcom_new,chng_time,chng_status,str_info_pgv,str_info_ged}
%                               RID         : gedcom id
%                               RID_type    : gedcom type (P: person, F: family)
%                               gedcom_old  : old gedcom data
%                               gedcom_new  : new proposed updated gedcom data
%                               chng_time   : time of update proposal (to detect those too old)
%                               chng_status : status of proposal (uploading, archived, skipped, discarded)
%                               str_info_pgv: info on the matched person on pgv site
%                               str_info_ged: info on the matched person on flat archive
%                       start_pos : first position in the change_list to
%                                   start to upload
%
%       'create_individual_with_gedcom': create a new individual as described by a
%                 gedcom text
%                   params={soap_struct,gedcom_txt}
%                       soap_struct, struct with fields:
%                           wsdl_url      : url of the wsdl page (es.
%                                          'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                           SID           : session id (empty string, or missing field
%                                           to start new session)
%                   gedcom_txt: multiline string with gedcom record to be uploaded
%
%       'create_individual': create a new individual as described by a
%                            record in the file
%                   params={str_archivio,soap_struct}
%                       str_archivio  : archive struct, with fields:
%                           archivio  : matrix cell array archive as loaded by 'go.m'
%                           indici_arc: headers for archivio cell array
%                           filename  : filename of the csv source file
%                       soap_struct, struct with fields:
%                           wsdl_url      : url of the wsdl page (es.
%                                          'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                           SID           : session id (empty string, or missing field
%                                           to start new session)
%       'prepare_pgv_url': prepare pgv website urls to individual, family
%                          and children
%                   params={wsdl_url,PID,childFamilies,spouseFamilies}
%                       wsdl_url      : url of the wsdl page (es.
%                                       'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       PID           : string with PID from pgv site (es. 'I7854')
%                       childFamilies : cell array of strings with FID (child families) from pgv 
%                                       site (es. 'F1601')
%                       spouseFamilies: cell array of strings with FID  (spouse families) from pgv 
%                                       site (es. {'F1601','F1614'})
%       'normalize_string': normalize the string (for example 'Caposele'
%                           --> 'Caposele, Avellino, Campania, ITA') depending on the string type 
%                   params={ks,type}
%                       ks   : string to be normalized (es. 'Caposele')
%                       type : string type (es. PLAC (place), pgvu (user to
%                              corresponding PGV user, src_txt (event to
%                              corresponding source)
%       'analise_record': analize the record and return a struct with
%                         fields normalized for Gedcom format
%                   params={str_archivio,id_record}
%                       str_archivio  : archive struct, with fields:
%                           id_record : numeric id of the record
%
% es.:
%
% % load the flat archive data in str_archivio
% go
%
% % prepare authentication params, and other settings, in uploader_conf.m
%
% % browse action
% wsdl_url  = 'http://localhost/work/PhpGedView/genservice.php?wsdl';
% list_pid = [0:4200];
% flg_skip_real_update = 1; % 1 -> just scan the pgv database, but don't update it
% arcfile = 'uploader_memory'; % archine matfile
%
% result2 = uploader('search',{str_archivio,struct('wsdl_url',wsdl_url,'SID',''),result.records});
%
%
% result = uploader('browse',{str_archivio,wsdl_url,list_pid,flg_skip_real_update,arcfile});
%
% result = uploader('browse',{str_archivio,'http://localhost/work/PhpGedView/genservice.php?wsdl',[0:4200],1,'uploader_memory'});
%
% load uploader_memory session; list_changes = session.list_changes;
% range=[];for ks=list_changes(:,1)',range(end+1)=str2num(ks{1}(2:end));end;disp(['[' sprintf('%d ',range) ']'])
% result = uploader('browse',{str_archivio,'http://localhost/work/PhpGedView/genservice.php?wsdl',range(find(range>=1,1):end),1,'uploader_memory'});
%
%
% % interactive_upload action
% wsdl_url  = 'http://localhost/work/PhpGedView/genservice.php?wsdl';
% arcfile      = 'uploader_memory'; % filename of matfile with list_changes
%
% result = uploader('interactive_upload',{wsdl_url,arcfile,1});
%cel
% result = uploader('interactive_upload',{'http://localhost/work/PhpGedView/genservice.php?wsdl','uploader_memory',1});
%
%
% % prepare pgv urls
% result = uploader('prepare_pgv_links',{'http://localhost/work/PhpGedView/genservice.php?wsdl','I20','F1234',{'F601','F602'}});
%
% % normalize string
% txt = uploader('normalize_string',{'CAPOSELE','PLAC'}); % --> 'Caposele, Avellino, Campania, ITA'
%
% % analize record
% result = uploader('analyse_record',{str_archivio,56762})
% result.str_record_info % struct with normalized Gedcom fields
%
%
% gedcom_txt=sprintf('0 INDI @I7@\n1 CHAN\n'); % dummy gedcom record
% result = uploader('create_individual_with_gedcom',{struct('wsdl_url',wsdl_url,'SID',''),gedcom_txt});
%
% id_record=32488;famc='F671';fams={};
% result = uploader('create_individual',{struct('wsdl_url',wsdl_url,'SID',''),str_archivio,id_record,famc,fams});
%
% for id_record=[29373 29319],famc='F788';fams={};
% 1, result = uploader('create_individual',{struct('wsdl_url',wsdl_url,'SID',[]),str_archivio,id_record,famc,fams});  end
%



function result = uploader(action,params)

switch action
    case 'search'
        result = uploader_search(params);

    case 'browse'
        result = uploader_browse(params);

    case 'interactive_upload'
        result = uploader_interactive_upload(params);

    case 'create_individual_with_gedcom'
        result = create_individual_with_gedcom(params);

    case 'create_individual'
        result = create_individual(params);
        
    case 'prepare_pgv_links'
        result = prepare_pgv_links(params);
        
    case 'normalize_string'
        result = export_normalize_string(params);
        
    case 'analyse_record'
        result = analyse_record(params);
        
    otherwise
        error('Unknown action "%s"!',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = create_individual(params)
%
% result = create_individual(params);
%
% Input:
%   params={str_archivio,soap_struct}
%                   soap_struct, struct with fields:
%                       wsdl_url      : url of the wsdl page (es.
%                                      'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       SID           : session id (empty string, or missing field
%                                       to start new session)
%                   str_archivio  : archive struct, with fields:
%                       archivio  : matrix cell array archive as loaded by 'go.m'
%                       indici_arc: headers for archivio cell array
%                       filename  : filename of the csv source file
%                   id_record  : id of record from file to be uploaded
%                   famc       : paternal family (only one, or empty string; eg. 'F2031')
%                   fams         = par_struct.fams; % bridal family (cell array, can be multiple, or empty list; eg. {'F2032'}))

result = struct();
err_code    = 0;
err_msg     = '';

% manage input params
par_struct = assert(params,{'soap_struct','str_archivio','id_record','famc','fams'});
str_archivio = par_struct.str_archivio;
soap_struct  = par_struct.soap_struct;
id_record    = par_struct.id_record; % id of record from file to be uploaded
famc         = par_struct.famc; % paternal family (only one, or empty string)
fams         = par_struct.fams; % bridal family (can be multiple, or empty list)

% authenticate on pgv site via soap
wsdl_url = soap_struct.wsdl_url;
if (~isfield(soap_struct,'SID') || isempty(soap_struct.SID) )
    [class_instance, SID] = pgv_authenticate(wsdl_url);
    soap_struct.class_instance  = class_instance;
    soap_struct.SID             = SID;
else
    result_init = pgv_init_class(wsdl_url);
    class_instance  = result_init.class_instance;
    SID             = soap_struct.SID;
end

ind_record = strmatch(num2str(id_record),str_archivio.archivio(:,1),'exact');
if isempty(ind_record)
    error('Record ''%d'' not found in the archive!',id_record)
end

result_tmp = analyse_record({str_archivio,id_record});
str_record_info = result_tmp.str_record_info;
PID = getNewXref(class_instance,SID,'INDI'); % PID of individual to be created
gedcom_txt = prepare_gedcom_str(str_record_info,PID,famc,fams);

result_tmp = uploader('create_individual_with_gedcom',{struct('wsdl_url',wsdl_url,'SID',SID),gedcom_txt});

% prepare output
result.err_code     = err_code;
result.err_msg      = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = create_individual_with_gedcom(params)
%
% result = create_individual_with_gedcom(params);
%
% Input:
%   params={soap_struct,gedcom_txt}
%                   soap_struct, struct with fields:
%                       wsdl_url      : url of the wsdl page (es.
%                                      'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       SID           : session id (empty string, or missing field
%                                       to start new session)
%                   gedcom_txt: multiline string with gedcom record to be uploaded

result = struct();
err_code    = 0;
err_msg     = '';

% manage input params
par_struct = assert(params,{'soap_struct','gedcom_txt'});
soap_struct  = par_struct.soap_struct;
gedcom_txt   = par_struct.gedcom_txt;

% authenticate on pgv site via soap
wsdl_url = soap_struct.wsdl_url;
if (~isfield(soap_struct,'SID') || isempty(soap_struct.SID) )
    [class_instance, SID] = pgv_authenticate(wsdl_url);
    soap_struct.class_instance  = class_instance;
    soap_struct.SID             = SID;
else
    result_init = pgv_init_class(wsdl_url);
    class_instance  = result_init.class_instance;    
    SID             = soap_struct.SID;
end

gedcom_str = tokenize(gedcom_txt);

PID = gedcom_str.data.data(2:end-1); % '@I6760@' --> 'I6780'

% detect list of families linking back to this individual
matr_family_links = get_family_links(gedcom_str);
result = prepare_family_links(class_instance,SID,PID,matr_family_links);
if (result.err_code > 0)
    err_code     = result.err_code;
    err_msg      = result.err_msg;
else
    fprintf(1,'New individual %s created.\n',PID)
    matr_fam_changed = result.matr_fam_changed; % list of family gedcoms to be updated
    
    % add new individual gedcom
    result      = PhpGedViewSoapInterface('appendRecord',{class_instance,SID,gedcom_txt}); % do PGV SOAP request
    pause(3) % this pause is necessary to avoid ending up with an empty person in PGV
    if (result.err_code > 0)
        err_code     = result.err_code;
        err_msg      = result.err_msg;
    else
        % prepare family links
        result = update_family_links(class_instance,SID,PID,matr_fam_changed);
    end
end

% prepare output
result.err_code     = err_code;
result.err_msg      = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XrefNew = getNewXref(class_instance,SID,type)
% return the Xref for the new gedcom record (eg. 'I6742', or 'F2431')
% 
% type = {'INDI', 'FAM', 'SOUR', 'REPO', 'NOTE', 'OBJE', 'OTHER'}

XrefNew = '';

if ismember(type,{'INDI','FAM'})
    % try to see if the last Xref is an empty record that can be reused
    result      = PhpGedViewSoapInterface('getXref',{class_instance,SID,'last',type});
    XrefLast = result.result_out; % PID of individual (or family, or other type) to be created
    switch type
        case 'INDI'
            result      = PhpGedViewSoapInterface('getPersonByID',{class_instance,SID,XrefLast});
            person = result.result_out;
            gedcom = person.gedcom;
            
        case 'FAM'
            result      = PhpGedViewSoapInterface('getFamilyByID',{class_instance,SID,XrefLast});
            family = result.result_out;
            gedcom = family.gedcom;
    end
    
    % detect an empty individual or family record
    flg_empty_gedcom = regexp(gedcom,'0 @[^\n]+\n1 CHAN\n2 DATE [^\n]+\n3 TIME [^\n]+\n2 _PGVU [^\n]+');
    if flg_empty_gedcom
        XrefNew = XrefLast;
    end
end

if isempty(XrefNew)
    result      = PhpGedViewSoapInterface('getXref',{class_instance,SID,'new',type});
    XrefNew = result.result_out; % PID of individual (or family, or other type) to be created
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gedcom_txt = prepare_gedcom_str(str_record_info,PID,famc,fams)
% assemble gedcom text to be uploaded starting from one line, for example (lines will be 
% converted into one single multiline string):
%
% gedcom_lines = {
%     '0 @I6769@ INDI'
%     
%     '1 NAME Francesco /Ceres/'
%     '2 GIVN Francesco'
%     '2 SURN Ceres'
%     
%     '1 SEX M'
%     
%     '1 BIRT'
%     '2 DATE 28 NOV 1857'
%     '2 PLAC Caposele, Avellino, Campania, ITA'
%     '2 SOUR @S16@'
%     '3 PAGE 1857: 188'
%     '3 DATA'
%     '4 TEXT registro nati anagrafe Caposele'
%     
%     '1 DEAT'
%     '2 DATE 08 DEC 1862'
%     '2 PLAC Caposele, Avellino, Campania, ITA'
%     '2 SOUR @S16@'
%     '3 PAGE 1862: 135'
%     '3 DATA'
%     '4 TEXT registro morti anagrafe Caposele'
%     
%     '1 FAMC @F746@'
%     
%     '1 FAMS @F1118@'
%     '1 FAMS @F372@'
%     
%     '1 CHAN'
%     '2 DATE 14 FEB 2012'
%     '3 TIME 00:19:55'
%     '2 _PGVU uploader'
%     };
%


ks_givn         = str_record_info. ks_givn;
ks_surn         = str_record_info. ks_surn;
sex             = str_record_info. sex;
ks_nasc         = str_record_info. ks_nasc;
ks_nasc_luo     = str_record_info. ks_nasc_luo;
ks_nasc_Nr      = str_record_info. ks_nasc_Nr;
int_nasc_a      = str_record_info. int_nasc_a;
ks_mort         = str_record_info. ks_mort;
ks_mort_luo     = str_record_info. ks_mort_luo;
ks_mort_Nr      = str_record_info. ks_mort_Nr;
int_mort_a      = str_record_info. int_mort_a;
ks_chan_date    = str_record_info. ks_chan_date;
ks_chan_time    = str_record_info. ks_chan_time;
ks_chan_user    = str_record_info. ks_chan_user;
ks_SID          = str_record_info. ks_SID;


%
% start assembling gedcom
%

% gedcom PID
gedcom_lines = {
    sprintf('0 @%s@ INDI',PID);
    };
    
% name and surname
gedcom_lines = [
    gedcom_lines;
    {
    sprintf('1 NAME %s /%s/',ks_givn,ks_surn);
    sprintf('2 GIVN %s',ks_givn);
    sprintf('2 SURN %s',ks_surn);
    };
    ];
    
% sex
if ~isempty(sex)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('1 SEX %s',sex);
        };
        ];
end

% birth
if ~isempty(ks_nasc)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('1 BIRT');
        sprintf('2 DATE %s',ks_nasc);
        };
        ];
    if ~isempty(ks_nasc_luo)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('2 PLAC %s',ks_nasc_luo);
        };
        ];
    end
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('2 SOUR %s',ks_SID);
        };
        ];
    if ~isempty(ks_nasc_Nr)
        ks_src_txt = normalize_string('BIRT','src_txt'); % 'es. 'BIRT' --> 'registro nati anagrafe Caposele'
        gedcom_lines = [
            gedcom_lines;
            {
            sprintf('3 PAGE %d: %s',int_nasc_a,ks_nasc_Nr);
            sprintf('3 DATA');
            sprintf('4 TEXT %s',ks_src_txt);
            };
            ];
    end
end

% death
if ~isempty(ks_mort)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('1 DEAT');
        sprintf('2 DATE %s',ks_mort);
        };
        ];
    if ~isempty(ks_mort_luo)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('2 PLAC %s',ks_mort_luo);
        };
        ];
    end
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('2 SOUR %s',ks_SID);
        };
        ];
    if ~isempty(ks_mort_Nr)
        ks_src_txt = normalize_string('DEAT','src_txt'); % 'es. 'DEAT' --> 'registro morti anagrafe Caposele'
        gedcom_lines = [
            gedcom_lines;
            {
            sprintf('3 PAGE %d: %s',int_mort_a,ks_mort_Nr);
            sprintf('3 DATA');
            sprintf('4 TEXT %s',ks_src_txt);
            };
            ];
    end
end

% paternal family
if ~isempty(famc)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('1 FAMC @%s@',famc);
        };
        ];
end

% bridal families
for i_fams = 1:length(fams)
    gedcom_lines = [
        gedcom_lines;
        {
        sprintf('1 FAMS @%s@',fams{i_fams});
        };
        ]; %#ok<AGROW>
end

% CHAN field
gedcom_lines = [
    gedcom_lines;
    {
    sprintf('1 CHAN');
    sprintf('2 DATE %s',ks_chan_date);
    sprintf('3 TIME %s',ks_chan_time);
    sprintf('2 _PGVU %s',ks_chan_user);
    };
    ];


gedcom_txt = sprintf('%s\n',gedcom_lines{:});
gedcom_txt = gedcom_txt(1:end-1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ks_givn ks_surn] = prepare_gedcom_name_fields(ks_cogn,ks_nome,ks_nome2)

if ~isempty(ks_nome2)
    ks_givn = [ks_nome ' ' ks_nome2]; % merge first name (ks_nome) and additional names (ks_nome2)
else
    ks_givn = ks_nome;
end

ks_givn = only_first_uppercase(ks_givn);
ks_surn = only_first_uppercase(ks_cogn);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_out = only_first_uppercase(ks_in)

list=regexp(ks_in,'[^\s'']+','match');
ind_copy = regexp(ks_in,'[^a-zA-Z]');

ks_out = '';
for i_match=1:length(list)
    ks_i = list{i_match};
    ks_out = [ks_out upper(ks_i(1)) lower(ks_i(2:end)) ' ']; %#ok<AGROW>
end
ks_out = ks_out(1:end-1);
ks_out(ind_copy) = ks_in(ind_copy);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = update_family_links(class_instance,SID,PID,matr_fam_changed)

result = struct();
err_code    = 0;
err_msg     = '';

for i_link = 1:size(matr_fam_changed,1)
    record_family_links = matr_fam_changed(i_link,:);
    link_token = record_family_links{1};
    link_FID   = record_family_links{2};
    gedcom_fam_txt  = record_family_links{3};
    
    % add link to the family
    result_tmp  = PhpGedViewSoapInterface('updateRecord',{class_instance,SID,link_FID,gedcom_fam_txt});
    pause(3) % this pause is important to let the asynchronous processes to complete on the remote server (otherwise the previous PID's added to the family could be lost)
    if (result_tmp.err_code>0)
        err_code = result_tmp.err_code;
        err_msg  = result_tmp.err_msg;
        break
    end
    fprintf(1,'link %s for PID %s added to family %s.\n',link_token,PID,link_FID)
end

result.err_code = err_code;
result.err_msg  = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = prepare_family_links(class_instance,SID,PID,matr_family_links)

result = struct();
err_code    = 0;
err_msg     = '';
matr_fam_changed = {};

list_unique_token={'HUSB','WIFE'}; % list of gedcom link tokens that are unique in a family

for i_link = 1:size(matr_family_links,1)
    record_family_links = matr_family_links(i_link,:);
    link_token = record_family_links{1};
    link_FID   = record_family_links{2};

    link_txt_generic = sprintf('1 %s ',link_token);
    link_txt = sprintf('%s@%s@',link_txt_generic ,PID);

    result_tmp = PhpGedViewSoapInterface('getFamilyByID',{class_instance,SID,link_FID});
    if (result_tmp.err_code>0)
        err_code = result_tmp.err_code;
        err_msg  = result_tmp.err_msg;
        break
    else
        gedcom_fam_txt = result_tmp.result_out.gedcom;
    end 
    
    if isempty(strfind(gedcom_fam_txt,link_txt))
        if ( ~isempty(strfind(gedcom_fam_txt,link_txt_generic)) && ismember(link_token,list_unique_token))
            error('Multiple %s link for family %s!',link_token,link_FID)
        end
        % add link to the family
        gedcom_fam_txt = sprintf('%s\n%s',gedcom_fam_txt,link_txt);
        matr_fam_changed(end+1,:) = [record_family_links gedcom_fam_txt]; %#ok<AGROW>
        fprintf(1,'link %s for PID %s will be added to family %s.\n',link_token,PID,link_FID)
    else
        % link already present
        fprintf(1,'link %s for PID %s already present in family %s... skipping\n',link_token,PID,link_FID)
    end
end

result.err_code = err_code;
result.err_msg  = err_msg;
result.matr_fam_changed = matr_fam_changed;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_family_links = get_family_links(gedcom_str)
% extract list of families that must point back to the individual in
% gedcom_str

matr_family_links = {};

if isfield(gedcom_str,'f_SEX_1')
    if (gedcom_str.f_SEX_1.data == 'F')
        sex = 'F';
    else
        sex = 'M';
    end
else
    sex = '';
end

list_fields = fieldnames(gedcom_str);

ind_famc = strmatch('f_FAMC_',list_fields); % paternal family
ind_fams = strmatch('f_FAMS_',list_fields); % family with wife (one or more)

for i_fam=1:length(ind_famc)
    tag = list_fields{ind_famc(i_fam)};
    var = gedcom_str.(tag);
    matr_family_links(end+1,:) = {'CHIL',var.data(2:end-1)}; %#ok<AGROW>
end

for i_fam=1:length(ind_fams)
    tag = list_fields{ind_fams(i_fam)};
    var = gedcom_str.(tag);
    
    switch sex
        case 'F'
            tag_fams = 'WIFE';
        case 'M'
            tag_fams = 'HUSB';
        otherwise
            error('Missing sex for this person, is it a wife or husband???')
    end
    matr_family_links(end+1,:) = {tag_fams,var.data(2:end-1)}; %#ok<AGROW>
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = uploader_search(params)
%
% result = uploader_search(params);
%
% Input:
%   params={str_archivio,wsdl_url,list_records}
%                   str_archivio  : archive struct, with fields:
%                       archivio  : matrix cell array archive as loaded by 'go.m'
%                       indici_arc: headers for archivio cell array
%                       filename  : filename of the csv source file
%                   soap_struct, struct with fields:
%                       wsdl_url      : url of the wsdl page (es.
%                                      'http://localhost/work/PhpGedView/genservice.php?wsdl')
%                       SID           : session id (empty string, or missing field
%                                       to start new session)
%                   list_records  : list of people to be searched, in
%                                   the form:
%                                   - [record1 record2 ... recordN],
%                                     with recordI as str_archivio.archivio(I,:)


result = struct();
err_code    = 0;
err_msg     = '';
list_found  = {};

debug = 0;

% manage input params
par_struct = assert(params,{'str_archivio','soap_struct','list_records'});
str_archivio = par_struct.str_archivio;
soap_struct  = par_struct.soap_struct;
list_records = par_struct.list_records;

% authenticate on pgv site via soap
wsdl_url = soap_struct.wsdl_url;
if (~isfield(soap_struct,'SID') || isempty(soap_struct.SID) )
    [class_instance, SID] = pgv_authenticate(soap_struct.wsdl_url);
    soap_struct.class_instance  = class_instance;
    soap_struct.SID             = SID;
else
    result_init = pgv_init_class(wsdl_url);
    class_instance  = result_init.class_instance;    
    SID             = soap_struct.SID;
end

% prepare cache archive
archive = struct();
archive.list_PID = {};
archive.list_PID{1e4+1} = []; % +1 because 1-based
archive.list_FID = archive.list_PID;
archive.list_obj = struct();

for i_record = 1:size(list_records,1) % for each record to be searched on PGV site
    record_i = list_records(i_record,:);    
    
    % record_i to struct
    nome        = record_i{str_archivio.indici_arc.nome};
    nome_2      = record_i{str_archivio.indici_arc.nome_2};
    cogn        = record_i{str_archivio.indici_arc.cogn};
    nasc        = record_i{str_archivio.indici_arc.nasc};
    int_nasc_a  = record_i{str_archivio.indici_arc.int_nasc_a};
    mort        = record_i{str_archivio.indici_arc.mort};
    int_mort_a  = record_i{str_archivio.indici_arc.int_mort_a};
    pad_nome    = record_i{str_archivio.indici_arc.pad_nome};
    mad_nome    = record_i{str_archivio.indici_arc.mad_nome};
    mad_cogn    = record_i{str_archivio.indici_arc.mad_cogn};
    
    % i campi di interesse per la query SOAP sono i seguenti:
    % Keywords: NAME, BIRTHDATE, DEATHDATE, BIRTHPLACE, DEATHPLACE, GENDER
    str_search = struct(...
        'nome'          , nome      , 'nome_2'  , nome_2    , ...
        'cogn'          , cogn      , 'nasc'    , nasc      , ...
        'int_nasc_a'    , int_nasc_a, 'mort'    , mort      , ...
        'int_mort_a'    , int_mort_a, 'pad_nome', pad_nome  , ...
        'mad_nome'      , mad_nome  , 'mad_cogn', mad_cogn  ...
        );
    
    start = 0; % zero-based index!
    maxResults = 1000; % long list, so as to get all results in a single call (to decrease it, check against ID 33340 --> present on pgv site, but PID I8886 not found, also 29322,50197)
    
    % prepare list of queries
    list_query = build_list_queries(str_search);
    
    list_found{i_record}  = struct([]); %#ok<AGROW>

    if debug
        fprintf(1,'\n%3d) Searching person "%s %s %s" (%10s,%10s) (di %s e %s %s)...\n',i_record,nome,nome_2,cogn,nasc,mort,pad_nome,mad_nome,mad_cogn)
    end
    list_persons_all    = struct([]);   % list of already found matching people
    for i_query = 1:length(list_query) % for each query
        query = list_query{i_query}; % Keywords: NAME, BIRTHDATE, DEATHDATE, BIRTHPLACE, DEATHPLACE, GENDER
        
        result_out = search(class_instance,SID,query,start,maxResults); % do PGV SOAP query
        
        persons=result_out.persons;
        if ~isempty(persons)
            % filter query results to exclude false positives
            list_persons = filter_search_results(persons,str_search,wsdl_url,list_persons_all,class_instance,SID,archive);
            if ~isempty(list_persons)
                [list_persons.query]    = deal(query); % incorporate query
                [list_persons.msgs_pgv] = deal({});    % incorporate list of msgs
            end
            
            % prepare msg
            for i_person = 1:length(list_persons)
                p   = list_persons(i_person);
                
                result_pgvurl = uploader('prepare_pgv_links',{wsdl_url,p.PID,p.childFamilies,p.spouseFamilies});
                msgs_pgv = sprintf('%.4f\t%5s - %25s  n: %-12s  m: %-12s (%s,%s,%s) (di %s e %s) ("%s")',p.fitness,p.PID,p.gedcomName,p.birthDate,p.deathDate,result_pgvurl.individual_atab,result_pgvurl.child_family_atab,result_pgvurl.spouse_family_atab,p.pad_nome_gedcom,p.mad_nome_gedcom,p.query);
                p.msgs_pgv = msgs_pgv;
                list_persons(i_person) = p;
            end

            list_found_i = [list_found{i_record} list_persons];
            list_found{i_record} = list_found_i; %#ok<AGROW>
            list_persons_all = [list_persons_all list_persons]; %#ok<AGROW>
            
            if ~isempty(list_persons)
                % found one match, stop here
                break
            end
        end
    end
    
    if debug
        % sort by fitness
        if ~isempty(list_persons_all) %#ok<UNRCH> enabled by debug constant
            [temp ind] = sort([list_persons_all.fitness]);
            list_persons_all = list_persons_all(ind);
        end
        
        % show matches
        for i_person = 1:length(list_persons_all)
            p       = list_persons_all(i_person);
            fprintf(1,'\t%s\n',p.msgs_pgv);
        end
    end
end

% prepare output
result.err_code     = err_code;
result.err_msg      = err_msg;
result.soap_struct  = soap_struct;
result.list_found   = list_found;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = uploader_interactive_upload(params)
%
% result = uploader_interactive_upload(params);
%
% Input:
%  params = {wsdl_url,arcfile}
%     arcfile : matfile containing variable list_changes, a cell array with
%               a record for each row, made up as follows:
%               {RID,RID_type,gedcom_old,gedcom_new,chng_time,chng_status,str_info_pgv,str_info_ged}
%                 RID         : gedcom id
%                 RID_type    : gedcom type (P: person, F: family)
%                 gedcom_old  : old gedcom data
%                 gedcom_new  : new proposed updated gedcom data
%                 chng_time   : time of update proposal (to detect those too old)
%                 chng_status : status of proposal (uploaded, skipped, discarded)
%                 str_info_pgv: info on the matched person on pgv site
%                 str_info_ged: info on the matched person on flat archive
%

result = struct();
err_code = 0;
err_msg  = '';

flg_skip_real_update = 0; % now it is time to upload!

% manage input params
par_struct = assert(params,{'wsdl_url','arcfile','start_pos'});
wsdl_url     = par_struct.wsdl_url;
arcfile      = par_struct.arcfile;
start_pos    = par_struct.start_pos;

% prepare logfile
logfile = 'logfile.txt';
clc
diary off
if exist(logfile,'file')
    delete(logfile)
end
diary(logfile)

% authenticate on pgv site via soap
[class_instance, SID] = pgv_authenticate(wsdl_url);

% load list of update proposals
flg_readonly = 1; % if missing filename, abort
session = load_session(arcfile,flg_readonly); % load archive of upload proposal from filename
list_changes = session.list_changes;
num_changes  = size(list_changes,1);

% first position in list_changes to start from to upload data
start_chng = determine_list_changes_position(list_changes,start_pos);

% pgv gedcom archive, for caching
archive = struct();
archive.list_PID = {};
archive.list_FID = archive.list_PID;
archive.list_obj = struct();

for i_chng = start_chng:num_changes

    record = list_changes(i_chng,:);

    RID          = record{1};
    RID_type     = record{2};
    gedcom_old   = record{3};
    gedcom_new   = record{4};
    chng_time    = record{5};
    chng_status  = record{6};
    str_info_pgv = record{7};
    str_info_ged = record{8};

    switch (chng_status)
        case {'archived','discarded'}
            msg_pgv = str_info_pgv.msg;
            msg_ged = str_info_ged.msg;
            msg_fit = str_info_ged.mask_fit;
            msg = sprintf('    based on the detected relation (fit %.3f):\n\t%s%s\n\t%s',msg_fit,char(ones(1,5-length(RID))*' '),msg_pgv,msg_ged);
            show_diff_gedcom(RID,gedcom_old,gedcom_new,msg)
            fprintf(1,'Update of gedcom (%s,%s): %s in a previous session\n\n',RID,RID_type,chng_status)

        case 'skipped'
            % let the user choose if update proposal is ok, and also to edit the
            % changes, and actually upload, if desired
            list_changes = manage_gedcom_update(class_instance,SID,flg_skip_real_update,list_changes,arcfile,RID,RID_type,gedcom_old,gedcom_new,chng_time,str_info_pgv,str_info_ged);

        otherwise
            error('Unmanaged update action: %s',chng_status)
    end
end

% close logfile
diary off
fprintf(1,'Written log file %s.\n',logfile)

% prepare output
result.err_code     = err_code;
result.err_msg      = err_msg;
result.list_changes = list_changes;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = uploader_browse(params)
%
% result = uploader_browse(params);
%
% Input:
%  params = {str_archivio,wsdl_url,list_pid,flg_skip_real_update}
%   str_archivio  : archive struct, with fields:
%           archivio   : matrix cell array archive as loaded by 'go.m'
%           indici_arc : headers for archivio cell array
%           filename   : filename of the csv source file
%
%   wsdl_url      ; url of the wsdl page (es.
%                   'http://localhost/work/PhpGedView/genservice.php?wsdl')
%
%   list_pid      : list of numeric id's for people in pgv site used to iterate pgv persons in the gedcom
%
%   flg_skip_real_update : [boolean] 1 -> just scan the pgv database, but don't update it%
%
%   arcfile       : matfile containing variable list_changes, a cell array with
%                   a record for each upload proposal (see 'interactive_upload' action)
%

result = struct();
err_code = 0;
err_msg  = '';

% manage input params
par_struct = assert(params,...
    {'str_archivio','wsdl_url','list_pid','flg_skip_real_update','arcfile'});
str_archivio = par_struct.str_archivio;
wsdl_url     = par_struct.wsdl_url;
list_pid     = par_struct.list_pid;
flg_skip_real_update = par_struct.flg_skip_real_update;
arcfile      = par_struct.arcfile;

% prepare logfile
logfile = 'logfile.txt';
clc
diary off
if exist(logfile,'file')
    delete(logfile)
end
diary(logfile)

max_pid = max(list_pid); % max id to be analysed

% authenticate on pgv site via soap
[class_instance, SID] = pgv_authenticate(wsdl_url);

% prepare cache archive
archive = struct();
archive.list_PID = {};
archive.list_PID{max_pid+1} = []; % +1 because 1-based
archive.list_FID = archive.list_PID;
archive.list_obj = struct();

flg_readonly = 0; % if missing filename, create it with empty list_changes
session = load_session(arcfile,flg_readonly); % archive of upload proposal
list_changes = session.list_changes;
list_matches = session.list_matches;

for i_pgv = list_pid

    [result_pgv archive] = search_pgv_data(archive,class_instance,SID,i_pgv); % search pgv for individual with id i_pgv

    search_threshold = uploader_conf('search_threshold'); % max err threshold to declare a match
    result_ged = query_ged(str_archivio,result_pgv,search_threshold); % search ged for individuals matching i_pgv

    if ( ~isempty(result_ged) && (~isempty(result_ged.report)) ) % if at least one match found...
        disp('Trovato!!!')
        
        list_found_id  = result_ged.result.mask_id;
        list_found_fit = result_ged.result.mask_fit;
        
        if ( (length(list_found_id) == 1) && (list_found_fit < search_threshold) ) % if only one match, and a good one (fit < threshold), than you have found a match
            [list_matches action action_value] = update_list_matches(list_matches,result_pgv.PID,list_found_id,list_found_fit,arcfile); % update the list of matches
            if ~strcmp(action,'drop_new') % if new match is not discarded, prepare the update proposal
                [result_upl list_changes] = update(class_instance,SID,result_pgv,result_ged,list_changes,arcfile,flg_skip_real_update);
            end
            if strcmp(action,'drop_old') % is the old match is discarded, drop the corresponding update proposal
                [list_changes list_matches] = discard_changes(action_value,'P',list_changes,list_matches,arcfile);
            end
        else
            fprintf(1,'\tMeglio procedere manualmente, poiche'' la scelta non e'' chiara e univoca:\n')
            for i_res=1:length(result_ged.mask_id)
                disp([sprintf('\t') result_ged.report{i_res}.msgs{1}])
            end

            % bad match, discard if already present
            [list_changes list_matches] = discard_changes(result_pgv.PID,'P',list_changes,list_matches,arcfile);
        end
    else
        % no match, discard if already present
        [list_changes list_matches] = discard_changes(result_pgv.PID,'P',list_changes,list_matches,arcfile);
    end
end

% close logfile
diary off
fprintf(1,'Written log file %s.\n',logfile)

% prepare output
result.err_code     = err_code;
result.err_msg      = err_msg;
result.list_changes = list_changes;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_init = pgv_init_class(wsdl_url)

flg_force = 1; % force the reload of the wsdl
result_init = PhpGedViewSoapInterface('init_class',{wsdl_url,flg_force});



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [class_instance, SID] = pgv_authenticate(wsdl_url)

% the auth request should be issued only once per session: issuing a
% second auth request ctually logs the user out

pgv_username = uploader_conf('pgv_username'); % username used for authentication on the pgv site
pgv_password = uploader_conf('pgv_password'); % password used for authentication on the pgv site
pgv_gedcom   = uploader_conf('pgv_gedcom');   % name of the gedcom to update on the pgv site

flg_err = 1;

% detect SOAP wsdl
result_init = pgv_init_class(wsdl_url);
if (result_init.err_code == 0)
    class_instance = result_init.class_instance;
    display(result_init.class_instance)

    % authenticate
    result_auth = PhpGedViewSoapInterface('Authenticate',{class_instance,pgv_username,pgv_password,pgv_gedcom,'none','GEDCOM'});
    
    try
        PhpGedViewSoapInterface('getXref',{class_instance,result_auth.SID,'first','INDI'}); % dummy request to check if server answers correctly
    catch %#ok<CTCH>
        % there was an error. This could be the case when an auth request
        % was issued when login had already been done. This second request
        % actually logout the user, so the subsequent request to the server
        % fails. It is necessary a new auth request, that follows here:
        result_auth = PhpGedViewSoapInterface('Authenticate',{class_instance,pgv_username,pgv_password,pgv_gedcom,'none','GEDCOM'});
    end
    
    if (result_auth.err_code == 0)
        SID         = result_auth.SID;
        flg_err     = 0; % once here, no errors eccurred
    end
end

if (flg_err)
    error('Authentication error: %s',result_init.err_msg)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result_upl list_changes] = update(class_instance,SID,result_pgv,result_ged,list_changes,arcfile,flg_skip_real_update)

result_upl = struct();

% Id of the pgv source associated to the flat archive, es. '@S16@'
source_ged   = uploader_conf('source_ged');

result_P = result_pgv.result_P.result_out;
RID_P = result_P.PID;

gedcom_P = result_P.gedcom;

str_gedcom_P = tokenize(gedcom_P);
str_gedcom_P = update_str_gedcom_P(str_gedcom_P,result_ged,source_ged);
gedcom_P_new = serialize(str_gedcom_P,0);
if (~isequal(gedcom_P,gedcom_P_new))

    RID        = RID_P;
    RID_type   = 'P';
    gedcom_old = gedcom_P;
    gedcom_new = gedcom_P_new;
    chng_time  = now;

    str_info_pgv = struct();
    str_info_pgv.msg  = result_pgv.msg;
    str_info_pgv.data = result_pgv;

    str_info_ged = struct();
    str_info_ged.msg      = result_ged.report{1}.msgs{1};
    str_info_ged.data     = result_ged.records;
    str_info_ged.mask_id  = result_ged.mask_id;
    str_info_ged.mask_fit = result_ged.mask_fit;

    % let the user choose if update proposal is ok, and also to edit the
    % changes, and actually upload, if desired
    [list_changes, result_upl] = manage_gedcom_update(class_instance,SID,flg_skip_real_update,list_changes,arcfile,RID,RID_type,gedcom_old,gedcom_new,chng_time,str_info_pgv,str_info_ged);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_changes, result_upl] = manage_gedcom_update(class_instance,SID,flg_skip_real_update,list_changes,arcfile,RID,RID_type,gedcom_old,gedcom_new,chng_time,str_info_pgv,str_info_ged)

result_upl = struct();

chng_status = 'undefined'; % shouldn't stay so

% show update proposal
msg_pgv = str_info_pgv.msg;
msg_ged = str_info_ged.msg;
msg_fit = str_info_ged.mask_fit;
msg = sprintf('    based on the detected relation (fit %.3f):\n\t%s%s\n\t%s',msg_fit,char(ones(1,5-length(RID))*' '),msg_pgv,msg_ged);
show_diff_gedcom(RID,gedcom_old,gedcom_new,msg)

delta_time = (now-chng_time)*24*60; % [min]
max_delta_time = 1; % [min]
if (delta_time>max_delta_time)
    fprintf(1,'Too much time (%.2f > %.1f minutes) has passed since the update proposal was issued\n',delta_time,max_delta_time)

    % load current gedcom from pgv
    archive = struct(); % dummy cache, as here we do want to download from pgv site
    archive.list_PID = {};
    archive.list_FID = archive.list_PID;
    archive.list_obj = struct();
    result = getXxxxById(archive,RID,class_instance,SID,'');
    gedcom_online = result.result_out.gedcom;

    if isequal(gedcom_online,gedcom_old)
        fprintf(1,'\t...but gedcom has not changed since then, so you can go on.\n')
    else
        % filter out CHAN field difference, if any
        gedcom_new_ = gedcom_filter_chan(gedcom_new,gedcom_online);
        if isequal(gedcom_online,gedcom_new_)
            fprintf(1,'\t...but gedcom has already been updated since then, so passing on.\n')
            chng_status = 'archived'; % already uploaded
        else
            fprintf(1,'\t...and gedcom has changed since then, it is better to invalidate the proposal!\n')
            fprintf(1,'Resume after %s (from position %d+1)\n',RID,strmatch(RID,list_changes(:,1),'exact'))
            error('todo')
        end
    end
end

if ( ~strcmp(chng_status,'archived') ) % if proposal hasn't already been uploaded
    if flg_skip_real_update

        % in no actual uploaded is allowed, archive the proposal, without user interaction
        chng_status = 'skipped';
    else
        % else let the user choose if update proposal is ok, and also to edit the changes
        [chng_status, gedcom_new] = interactive_choice(RID,gedcom_old,gedcom_new);
    end
end

switch chng_status
    case 'archived' % archived, already uploaded
        fprintf(1,'\tUpload of gedcom id %s has already been done previously in another session\n',RID)
        set_status = chng_status; % archive update proposal

    case 'discarded' % discarded
        fprintf(1,'\tDiscarded update of gedcom id %s (without archiving the update proposal)\n',RID)
        set_status = chng_status; % delete from list of proposals

    case 'skipped' % skipped
        fprintf(1,'\tSkipped update of gedcom id %s (but archived the update proposal)\n',RID)
        set_status = chng_status; % archive for future analisys

    case 'uploading' % user chose to upload
        if flg_skip_real_update
            fprintf(1,'\tSkipped update of gedcom id %s via flg_skip_real_update (but archived the update proposal)\n',RID)
            set_status = 'skipped'; % archive for future analisys
        else
            result_upl      = PhpGedViewSoapInterface('updateRecord',{class_instance,SID,RID,gedcom_new}); % actual update
            pause(3) % this pause is necessary to avoid ending up with an empty person in PGV
            fprintf(1,'\tUpdated gedcom id %s with result: %s\n',RID,result_upl.result_out)
            set_status = 'archived'; % archive update proposal
        end

    otherwise
        error('Todo: %s',chng_status)
end

if ~isempty(set_status)
    list_changes = archive_changes(RID,RID_type,gedcom_old,gedcom_new,chng_time,set_status,str_info_pgv,str_info_ged,list_changes,arcfile); % actually mark or archive proposal
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gedcom_new_ = gedcom_filter_chan(gedcom_new,gedcom_online)
% tage the CHAN field in the gedcom_online, and rewrite the CHAN field in
% the gedcom_new to mask the difference

format_chan = '\n1 CHAN\n2 DATE[^\n]+\n3 TIME[^\n]+\n2 _PGVU[^\n]+'; % regexp to detect the CHAN field inside the gedcom
chan_online = regexp(gedcom_online,format_chan,'match');
chan_new    = regexp(gedcom_new,format_chan,'match');
gedcom_new_ = strrep(gedcom_new,chan_new{1},chan_online{1});



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_diff_gedcom(RID,gedcom_old,gedcom_new,msg)

disp(' ')
fprintf(1,'Update proposal for gedcom %s:\n',RID)
disp(msg)
disp(' ')

quiet = 0; % show lines
show_diff(gedcom_old,gedcom_new,quiet);

disp(' ')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [update_choice, gedcom_new] = interactive_choice(RID,gedcom_old,gedcom_new)
% ask the user what to do with the proposed update

matr_choices = {
    'U',    'uploading';
    'S',    'skipped';
    'E',    'edited';
    'D',    'discarded'
    };

update_choice = 'edited';
while (ismember(update_choice,{'edited',''}))
    ch = '';
    ind = [];
    while ( (length(ch) ~= 1) && (length(ind) ~= 1) )
        ch = upper(input('Choose about the update proposal (U: upload now, S: skip for future analysys, E: interactive edit, D: discard, Q: quit): ','s'));
        if (ch=='Q')
            error('Aborted by user.')
        end
        ind = strmatch(ch,matr_choices(:,1));
    end
    update_choice = matr_choices{ind,2};

    if (strcmp(update_choice,'edited'))
        % gui di modifica
        handle = figure(99);
        set(handle,'Position',[135 40 1000 700])
        pos=get(handle,'Position');
        h_edit=uicontrol(handle,'Style','edit','String',gedcom_new,'Max',10,'Position',[10 50 pos(3)-10-5 pos(4)-50-35],'HorizontalAlignment','left');
        uicontrol(99,'style','push','string','ok','Position',[10 10 80 30],'Callback','uiresume(gcbf)')

        uiwait(handle)

        str_matrix = get(h_edit,'String');
        close(handle);

        gedcom_new_gui = '';
        for i=1:size(str_matrix);
            line=strtrim(str_matrix(i,:));
            gedcom_new_gui=sprintf('%s\n%s',gedcom_new_gui,line);
        end
        if ~isempty(gedcom_new_gui)
            gedcom_new_gui = gedcom_new_gui(2:end);
        end

        if isequal(gedcom_new_gui,gedcom_new)
            disp('No user changes.')
        else
            disp('User changes:')
            show_diff(gedcom_new,gedcom_new_gui,0);
        end

        gedcom_new = gedcom_new_gui; % update the gedcom to be uploaded according to user changes

        % show diff again
        msg = 'Gedcom edited.';
        show_diff_gedcom(RID,gedcom_old,gedcom_new,msg)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function session = load_session(arcfile,flg_readonly)

if ( ~exist('arcfile','var') || isempty(arcfile) ) % default filename
    arcfile = 'uploader_memory.mat';
end

[pathstr name ext] = fileparts(arcfile);
if isempty(ext)
    arcfile = [arcfile '.mat'];
end

fprintf(1,'Archive matfile: %s\n',arcfile)

if ~exist(arcfile,'file')
    if (flg_readonly)
        error('Missing archive mat-file %s!',arcfile)
    else
        list_changes = {};
        list_matches = {};
        session = struct();
        session.list_changes = list_changes;
        session.list_matches = list_matches;
        save(arcfile,'session')

        fprintf(1,'\t... matfile missing: starting with an empty archive.\n')
    end
else
    try
        load(arcfile,'session')
        if ~exist('session','var')
            % arcfile exists but without session??? Better delete it and restart
            delete(arcfile)
            error('Missing "session"')
        end
    catch %#ok<CTCH>
        error('Missing struct "session" from mat-file %s!',arcfile)
    end
    
    list_changes = session.list_changes; %#ok<NODEF>
    list_matches = session.list_matches;

    if isempty(list_changes)
        fprintf(1,'\t... resuming empty archive.\n')
    else
        list_status = list_changes(:,6);
        list_ = unique(list_status);
        num = zeros(size(list_));
        for i=1:length(list_)
            tag = list_{i};
            num(i) = sum(strcmp(list_status,tag));
        end

        [num ind] = sort(num);
        list_ = list_(ind);

        ks = '';
        for i=1:length(list_)
            tag = list_{i};
            num_i = num(i);
            ks = sprintf('%s, %s (%d items)',ks,tag,num_i);
        end
        ks = ks(3:end);

        fprintf(1,'\t... resuming archive : %s\n',ks)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_changes = archive_changes(RID,type,gedcom_old,gedcom_new,chng_time,chng_status,str_info_pgv,str_info_ged,list_changes,arcfile)

% index to the same RID already present in archive, in any
if isempty(list_changes)
    ind = [];
else
    ind = find(strcmp(list_changes(:,1),RID) & strcmp(list_changes(:,2),type));
end

new_record = {RID,type,gedcom_old,gedcom_new,chng_time,chng_status,str_info_pgv,str_info_ged};

if isempty(ind)
    list_changes(end+1,:) = new_record;
else
    % RID_         = list_changes{ind,1};
    % type_        = list_changes{ind,2};
    gedcom_old_  = list_changes{ind,3};
    gedcom_new_  = list_changes{ind,4};
    % chng_time_   = list_changes{ind,5};
    chng_status_ = list_changes{ind,6};
    % str_info_pgv = list_changes{ind,7};
    % str_info_ged = list_changes{ind,8};

    if ( isequal(gedcom_old_,gedcom_old) )
        % gedcom hasn't changed online, meanwhile
        if ( isequal(gedcom_new_,gedcom_new) )
            % and the update proposal is still the same
            if isequal(chng_status_,chng_status)
                fprintf(1,'Nothing to change, leaving the update proposal (%s,%s) in archive with status "%s"\n',RID,type,chng_status)
            else
                fprintf(1,'Updating archived proposal (%s,%s) from status "%s" to "%s"\n',RID,type,chng_status_,chng_status)
                list_changes(ind,:) = new_record;
            end
        else
            fprintf(1,'Archived new update proposal (%s,%s) with status "%s"\n',RID,type,chng_status)
            list_changes(ind,:) = new_record;
        end
    else
        fprintf(1,'WARNING: Updating proposal (%s,%s) is now obsolete:\n',RID,type)
        fprintf(1,'\ngedcom_pgv_arc vs gedcom_pgv:\n')
        show_diff(gedcom_filter_chan(gedcom_old_,gedcom_old),gedcom_old);
        fprintf(1,'\ngedcom_proposal_arc_ vs gedcom_proposal:\n')
        show_diff(gedcom_filter_chan(gedcom_new_,gedcom_new),gedcom_new);

        fprintf(1,'\nRewriting update proposal (%s,%s) with status "%s"\n',RID,type,chng_status)
        list_changes(ind,:) = new_record;
    end
end


load(arcfile,'session')
session.list_changes = list_changes;
save(arcfile,'session','-append')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_changes, list_matches] = discard_changes(RID,type,list_changes,list_matches,arcfile)

% index to the same RID already present in archive, in any
if isempty(list_changes)
    ind_changes = [];
else
    ind_changes = find(strcmp(list_changes(:,1),RID) & strcmp(list_changes(:,2),type));
end

% index to the same RID already present in archive, in any
if isempty(list_matches)
    ind_matches = [];
else
    ind_matches = find(strcmp(list_matches(:,1),RID));
end

% update list_changes
if ~isempty(ind_changes)
    chng_status = 'discarded';
    list_changes{ind_changes,6} = chng_status;
    fprintf(1,'\nDiscarding update proposal (%s,%s); marked as "%s"\n',RID,type,chng_status)
end

% update list_matches
if ~isempty(ind_matches)
    ks = '';
    for i=1:length(ind_matches)
        match_rid   = list_matches{ind_matches(i),1};
        % match_gedid = list_matches{ind_matches(i),2};
        match_fit   = list_matches{ind_matches(i),3};
        ks = sprintf('%s, %s (fit %.3f)',ks,match_rid,match_fit);
        list_matches{ind_matches(i),3} = 1000+abs(match_fit); % set fitness > 1 (<==> disabled)
    end
    ks = ks(3:end);
    
    fprintf(1,'\nDiscarding links %s:\n',ks)
    if ~isempty(ind_changes)
        for i_chg = 1:length(ind_changes)
            disp(list_changes{ind_changes(i_chg),8}.msg)
        end
    else
        fprintf(1,'\tNo update linked to it.\n')
    end
    disp(' ')
end

if ( ~isempty(ind_changes) || ~isempty(ind_matches) )
    load(arcfile,'session')
    session.list_changes = list_changes;
    session.list_matches = list_matches;
    save(arcfile,'session','-append')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function textbuf = show_diff(text_old,text_new,quiet)

if ~exist('quiet','var')
    quiet = 0; % by default show diffs
end

list_old = regexp(text_old,'[^\r\n]+','match');
list_new = regexp(text_new,'[^\r\n]+','match');
[align_new,align_old]=diffcode(list_old,list_new);

textbuf = {};
ind_new = 1;
ind_old = 1;
ancora = 1;
while ancora
    val_old = align_old(ind_old);
    val_new = align_new(ind_new);

    % show deleted lines
    while ( (val_old == 0)  && (ind_old <= length(list_old)) )
        ks = list_old{ind_old};
        textbuf(end+1,:) = {'-',ks};
        newline = sprintf('   - %s',ks);
        disp_quiet(newline,quiet)
        ind_old = ind_old+1;
        if (ind_old <= length(list_old))
            val_old = align_old(ind_old);
        else
            val_old = NaN;
        end
    end

    % show added lines
    while ( (val_new == 0) && (ind_new <= length(list_new)) )
        ks = list_new{ind_new};
        textbuf(end+1,:) = {'+',ks};
        newline = sprintf('   + %s',ks);
        disp_quiet(newline,quiet)
        ind_new = ind_new+1;
        if (ind_new <= length(list_new))
            val_new = align_new(ind_new);
        else
            val_new = NaN;
        end
    end

    if ( (ind_new <= length(list_new)) && (ind_old <= length(list_old)) )
        ks_old = list_old{ind_old};
        ks_new = list_new{ind_new};

        if strcmp(ks_old,ks_new)
            % show equal lines...
            textbuf(end+1,:) = {' ',ks_old};
            newline = sprintf('     %s',ks_old);
            disp_quiet(newline,quiet)
        else
            % or replaced lines
            textbuf(end+1,:) = {'-',ks_old};
            newline = sprintf('   - %s',ks_old);
            disp_quiet(newline,quiet)

            textbuf(end+1,:) = {'+',ks_new};
            newline = sprintf('   + %s',ks_new);
            disp_quiet(newline,quiet)
        end


        ind_old = ind_old+1;
        ind_new = ind_new+1;

        ancora = (ind_old <= length(list_old)) || (ind_new <= length(list_new));
    else
        ancora = 0; % stop, but added or deleted lines at the end of text may be there still unmanaged
    end
end

% show deleted lines at the end of the text
while ( ind_old <= length(list_old) )
    ks = list_old{ind_old};
    textbuf(end+1,:) = {'-',ks};
    newline = sprintf('   - %s',ks);
    disp_quiet(newline,quiet)
    ind_old = ind_old+1;
end

% show added lines at the end of the text
while ( ind_new <= length(list_new) )
    ks = list_new{ind_new};
    textbuf(end+1,:) = {'+',ks};
    newline = sprintf('   + %s',ks);
    disp_quiet(newline,quiet)
    ind_new = ind_new+1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function disp_quiet(ks,quiet)

if (~quiet)
    disp(ks)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_gedcom_P_new = update_str_gedcom_P(str_gedcom_P_old,result_ged,source_ged)

str_gedcom_P_new = str_gedcom_P_old;

id_ged = result_ged.mask_id;
if (length(id_ged) > 1)
    error('Piu'' di un id prescelto!!! Todo')
else
    record     = result_ged.records(1,:);
    indici_arc = result_ged.indici_arc;
end

list=fieldnames(indici_arc);
for i=1:length(list)
    field = list{i};
    str_ged.(field) = record{indici_arc.(field)};
end

str_gedcom_P_new = add_event_date(str_gedcom_P_new,str_ged,'nasc','BIRT','nascita',1,source_ged);
%str_gedcom_P_new = add_event_date(str_gedcom_P_new,str_ged,'matr','MARR','matrimonio');
str_gedcom_P_new = add_event_date(str_gedcom_P_new,str_ged,'mort','DEAT','morte',1,source_ged);

str_gedcom_P_new = save_last_changed(str_gedcom_P_old,str_gedcom_P_new ); % save the "last changed" field as a user



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_gedcom_P_new = save_last_changed(str_gedcom_P_old,str_gedcom_P_new)
% when saving the gedcom, the CHAN field is automatically changed. To
% prevent loosing information on who edited this item previously, an individual source
% field is added to the gedcom-

% list of users that won't generate a source field (es. the admin, etc.)
list_filtered_CHAN_user = uploader_conf('list_filtered_CHAN_user');

if ( ~isequal(str_gedcom_P_new,str_gedcom_P_old) )
    last_chan_pgvu = str_gedcom_P_old.f_CHAN_1.f__PGVU_1.data; % last user that edited the person
    if ( ~any(strcmp(list_filtered_CHAN_user,last_chan_pgvu)) )
        user_source = normalize_string(last_chan_pgvu,'pgvu'); % get the source corresponding to the user

        if strmatch(last_chan_pgvu,list_filtered_CHAN_user)
            fprintf(1,'Ultimo utente ad aver effettuato modifiche: %s\n',last_chan_pgvu)
        else
            fprintf(1,'Ultimo utente ad aver effettuato modifiche: %s. Aggiungo una nota!\n',last_chan_pgvu)

            str_gedcom_P_new = add_gedfield(str_gedcom_P_new,'SOUR',[],['@' user_source '@']); % add a new SOUR field
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_gedcom_P = add_event_date(str_gedcom_P,str_ged,field_ged,field_pgv,tag,level,source_ged)

RID = str_gedcom_P.data.data; % RID of the person

if ~isempty(str_ged.(field_ged)) % first of all, check if the date to be uploaded is available

    src_text = normalize_string(field_pgv,'src_txt'); % 'es. 'BIRT' --> 'registro nati anagrafe Caposele'

    field_luo_ged = normalize_string(str_ged.([field_ged '_luo']),'PLAC'); % normalized place of the event

    int_field_a_ged = str_ged.(['int_' field_ged '_a']);
    int_field_m_ged = str_ged.(['int_' field_ged '_m']);
    int_field_g_ged = str_ged.(['int_' field_ged '_g']);
    vett = [int_field_a_ged, int_field_m_ged, int_field_g_ged];
    event_ged = upper(datestr(datenum(vett),'dd mmm yyyy'));

    event_Nr_ged = str_ged.(['int_' field_ged '_Nr']); % numero dell'atto
    if ~isnan(event_Nr_ged)
        ks_page = sprintf('%d: %d',int_field_a_ged,event_Nr_ged);
        f_PAGE_1_ged = struct('data',ks_page);
    else
        f_PAGE_1_ged = [];
    end

    % create new source gedcom string
    if isnan(event_Nr_ged)
        fprintf(1,'Nessun numero di atto di %s\n',tag)
        field_text_ged = '';
        field_Nr_ged = '';
        ks_Nr_ged = '';
        ks_data = '';
    else
        field_text_ged = src_text;
        field_Nr_ged = sprintf('%d: %d',int_field_a_ged,event_Nr_ged);
        ks_Nr_ged = sprintf('%d PAGE %s\n',level+2,field_Nr_ged);
        ks_data = sprintf('%d DATA\n%d TEXT %s',level+2,level+3,src_text);
    end
    ks_src_ged = sprintf('%d SOUR %s\n%s%s',level+1,source_ged,ks_Nr_ged,ks_data);
    field_note_src_ged = sprintf('Viene indicata come data di %s %s; probabilmente e'' la data di registrazione, non quella effettiva.',tag,event_ged);
    f_SOURCE_new = tokenize(ks_src_ged);

    % cross check pgv with ged
    if isfield(str_gedcom_P,['f_' field_pgv '_1'])

        event_pgv_1 = str_gedcom_P.(['f_' field_pgv '_1']); % main event field to be updated

        if isfield(str_gedcom_P,['f_' field_pgv '_2']) % if more than one event of the same type
            error('Piu'' di un campo %s (RID %s)!',field_pgv,RID)
        end
        
        if isfield(event_pgv_1,'f_DATE_1') % check to see if date of event exists
            event_pgv = event_pgv_1.f_DATE_1.data; % get the date of event
        else
            event_pgv = ''; % missing date
        end
            
        % cross check pgv and ged date, to see if they match
        %   flg_date_match: 1 --> the dates match, so you can go on uploading all the related data
        %   flg_preserve_pgv_date: 1 --> the dates doesn't match perfectly, but the ged date is a few days later the pgv one: 
        %                                probably the ged date is the one when the record was filed out
        [flg_edit_event_date, flg_preserve_pgv_date] = cross_check_event_date(event_ged,event_pgv,tag);
        
        % pgv and ged dates are close enough, enter alla vailable data
        if flg_edit_event_date

            % set date info
            info_tag = 'la data';
            ged_tag = 'DATE';
            flg_preserve_pgv_data = flg_preserve_pgv_date;
            event_ged_data = event_ged; % event data from ged file
            event_pgv_1 = set_event_info(event_pgv_1,event_ged_data,tag,info_tag,ged_tag,flg_preserve_pgv_data);

            % set place info
            info_tag = 'il luogo';
            ged_tag = 'PLAC';
            flg_preserve_pgv_data = 0; % allways overwrite place event data
            event_ged_data = field_luo_ged; % event data from ged file
            event_pgv_1 = set_event_info(event_pgv_1,event_ged_data,tag,info_tag,ged_tag,flg_preserve_pgv_data);
            
            % search for ged source
            [source_found, i_source, info_src] = analyse_src(event_pgv_1,f_PAGE_1_ged,source_ged,tag); % analyse available sources
            ind_source = i_source; % point to the first free index (1-based)

            if ( ~isempty(source_found) )
                % if the ged source was found...
                fprintf(1,'Source %s already set for field %s\n',source_ged,field_pgv)
                src_str = info_src(source_found,:);

                flg_must_rewrite = cross_check_src_data(src_str,field_text_ged,field_Nr_ged,field_note_src_ged,flg_preserve_pgv_date);
                
                if flg_must_rewrite
                    ind_source = source_found; % point to the index of the found source
                    fprintf(1,'Source data will be rewritten\n')
                end
            else
                % else the ged source must be added, no rewrite needed.
                flg_must_rewrite = 0;
            end

            % if must_rewrite, rewrite the source at index ind_source, else
            % write a new source
            if ( isempty(source_found) || flg_must_rewrite )
                if (ind_source > 1) % more sources already present.
                    disp('other sources:')
                    display(info_src(:,1))
                end

                new_src_field = ['f_SOUR_' num2str(ind_source)];

                % if the date was not changed, add a note indicating the date in
                % the file
                if flg_preserve_pgv_date
                    note_data = field_note_src_ged;
                    f_SOURCE_new = add_gedfield(f_SOURCE_new,'NOTE',[],note_data); % add a note
                end

                % compare with previous source, if must rewrite
                if flg_must_rewrite
                    f_SOURCE_old = event_pgv_1.(new_src_field);
                    fprintf(1,'Old %s data:\n',source_ged)
                    disp(serialize(f_SOURCE_old,level+1,''))
                    fprintf(1,'\nNew %s data:\n',source_ged)
                    disp(serialize(f_SOURCE_new,level+1,''))
                end

                event_pgv_1.(new_src_field) = f_SOURCE_new;

            end
        else
            fprintf(1,'La data di %s non coincide: %s (ged) - %s (pgv)\n',tag,event_ged,event_pgv)
        end

        str_gedcom_P.(['f_' field_pgv '_1']) = event_pgv_1; % rewrite the updated event field

    else
        disp('Todo: add event data here!')
    end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function event_pgv_1 = set_event_info(event_pgv_1,event_ged_data,tag,info_tag,ged_tag,flg_preserve_pgv_data)

if ~isempty(event_ged_data) % something to upload
    get_tag_full = get_gedfield_tag(event_pgv_1,ged_tag,1); % es f_DATE_1
    if ~isfield(event_pgv_1,get_tag_full)
        event_pgv_1 = add_gedfield(event_pgv_1,ged_tag,[],event_ged_data);
        fprintf(1,'\t...aggiungo %s: %s\n',info_tag,event_ged_data)
    else
        event_ged_old = event_pgv_1.(get_tag_full).data; % current pgv event data

        % if pgv field is different from ged one, must reset the value to the ged one
        if (~strcmp(event_ged_old,event_ged_data) && ~flg_preserve_pgv_data)
            fprintf(1,'\t...resetto %s: %s --> %s\n',info_tag,event_ged_old,event_ged_data)
            event_pgv_1.(get_tag_full).data = event_ged_data;       % overwrite previous date with the one in the ged file

            % should write a note not to lose information
            [fieldname_new, fieldname_counter_new, fieldname_counter_old] = get_gedfield_tag(event_pgv_1,'NOTE',[]);
            flg_write_note = 0; % default is no note
            if (fieldname_counter_new == 1)
                flg_write_note = 1; % no notes yet, write the first one
                fieldname_counter_to_add = []; % just add another one
                fprintf(1,'\t...aggiungo una nota: %s --> %s\n',event_ged_old,event_ged_data)
            elseif ~isempty( regexp(get_gedfield_data(event_pgv_1,get_gedfield_tag(event_pgv_1,'NOTE',fieldname_counter_old)),event_ged_old,'once') )
                fieldname_counter_to_add = fieldname_counter_old; % rewrite last note available
                flg_write_note = 1;
                fprintf(1,'\t...sovrascrivo la nota %d: %s --> %s\n',fieldname_counter_new,event_ged_old,event_ged_data)
            end
            if flg_write_note
                note_data = sprintf('altre fonti indicano per %s di %s: %s',info_tag,tag,event_ged_old);
                event_pgv_1 = add_gedfield(event_pgv_1,'NOTE',fieldname_counter_to_add,note_data);
            end
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_edit_event_date, flg_preserve_pgv_date] = cross_check_event_date(event_ged,event_pgv,tag)

flg_date_match0 = isempty(event_pgv); % missing date, just upload it
flg_date_match1 = strcmp(event_ged,event_pgv); % date matches

% check for uncertain dates (es. ABT 22 FEB 1879)
if (strfind(event_pgv,'ABT '))
    flg_about = 1;
    event_pgv = event_pgv(5:end);
else
    flg_about = 0;
end

% pgv date is complete, but close enough?
deltaDay = 20; % [d]
flg_date_match2 = ~isempty(regexp(event_pgv,'[0-9]{1,2} [A-Za-z]{3} 1[0-9]{3}','once')) && ((datenum(event_ged)-datenum(event_pgv))<deltaDay && (datenum(event_ged)>datenum(event_pgv)));
deltaYear = 10; % [y]
flg_date_match3 = ~isempty(regexp(event_pgv,'[0-9]{1,2} [A-Za-z]{3} 1[0-9]{3}','once')) && (abs(datenum(event_ged)-datenum(event_pgv))<deltaYear*365);
% pgv date is only year, but close enough
flg_date_match4 = ~isempty(regexp(event_pgv,'1[0-9]{3}','once')) && (abs(datenum(event_ged)-datenum(event_pgv,'yyyy'))<deltaYear*365);

if flg_date_match0
    fprintf(1,'Carico la data di %s mancante: %s\n',tag,event_ged)
    flg_edit_event_date = 1;
    flg_preserve_pgv_date = 0;
elseif flg_date_match1
    fprintf(1,'La data di %s coincide: %s\n',tag,event_ged)
    flg_edit_event_date = 1;
    flg_preserve_pgv_date = 0;
elseif (flg_about && (flg_date_match2 || flg_date_match3 || flg_date_match4))
    fprintf(1,'\tLa data di %s e'' molto simile ma non era sicura, la correggo con i dati del file ged: ged: %s - pgv: %s\n',tag,event_ged,event_pgv)
    flg_edit_event_date = 1;
    flg_preserve_pgv_date = 0;
elseif (flg_date_match2)
    fprintf(1,'\tLa data di %s e'' molto simile (differisce di meno di %d giorni, probabilmente e'' la data di registrazione): ged: %s - pgv: %s\n',tag,deltaDay,event_ged,event_pgv)
    flg_edit_event_date = 1;
    flg_preserve_pgv_date = 1;
elseif (flg_date_match3 || flg_date_match4)
    fprintf(1,'\tLa data di %s e'' molto simile (differisce di meno di %.0f anni): ged: %s - pgv: %s\n',tag,deltaYear,event_ged,event_pgv)
    flg_edit_event_date = 1;
    flg_preserve_pgv_date = 0;
else
    flg_edit_event_date = 0;
    flg_preserve_pgv_date = 1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [source_found, i_source, info_src] = analyse_src(event_pgv_1,f_PAGE_1_ged,source_ged,tag)

% search for ged source
i_source = 1;
source_found = [];
info_src = {};
while isfield(event_pgv_1,['f_SOUR_' num2str(i_source)])
    source_pgv_i = event_pgv_1.(['f_SOUR_' num2str(i_source)]);

    % source ID
    src_id_i = source_pgv_i.data;
    ks = sprintf('%s',src_id_i);

    % source text
    if ( isfield(source_pgv_i,'f_DATA_1') && isfield(source_pgv_i.f_DATA_1,'f_TEXT_1') )
        src_text_i = source_pgv_i.f_DATA_1.f_TEXT_1.data;
        ks = sprintf('%s : %s',ks,src_text_i);
    else
        src_text_i = '';
    end

    % source page (es. "1898: 134")
    if ( isfield(source_pgv_i,'f_PAGE_1') )
        src_page_i = source_pgv_i.f_PAGE_1.data;
        ks = sprintf('%s (%s)',ks,src_page_i);
    else
        src_page_i = '';
    end

    % source note
    if ( isfield(source_pgv_i,'f_NOTE_1') )
        src_note_i = source_pgv_i.f_NOTE_1.data;
        ks = sprintf('%s (%s)',ks,src_note_i);
    else
        src_note_i = '';
    end

    info_src(i_source,:) = {ks,source_pgv_i,source_pgv_i.data,src_text_i,src_page_i,src_note_i};

    if strcmp(source_pgv_i.data,source_ged)
        % source found
        if ~isempty(f_PAGE_1_ged)
            if isfield(source_pgv_i,'f_PAGE_1')
                event_Nr_pgv = source_pgv_i.f_PAGE_1.data;

                if strcmp(f_PAGE_1_ged.data,event_Nr_pgv)
                    fprintf(1,'Stesso numero di atto di %s: "%s"\n',tag,event_Nr_pgv)
                else
                    fprintf(1,'Il numero di atto di %s non coincide "%s" invece di "%s": verra'' riscritto.\n',tag,event_Nr_pgv,f_PAGE_1_ged.data)
                end

            else

                fprintf(1,'Manca l''atto di %s, pur essendo disponibile: "%s"\n',tag,f_PAGE_1_ged.data)
            end
        end

        source_found = i_source;

        break % inutile continuare, hai gia' trovato la fonte che interessa

    end
    i_source = i_source+1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_must_rewrite = cross_check_src_data(src_str,field_text_ged,field_Nr_ged,field_note_src_ged,flg_preserve_pgv_date)
% info_src(i_source,:) = {ks,source_pgv_i,source_pgv_i.data,src_text_i,src_page_i,src_note_i};
% src_str = {ks,source_pgv_i,source_pgv_i.data,src_text_i,src_page_i,src_note_i};
% dati i dati relativi ad una fonte, verifica se sono correttamente
% presenti i campi field_text_ged, field_Nr_ged e field_note_src_ged.
% Se non e' cosi', setta il flag che richiede di riscrivere la fonte.

flg_must_rewrite = 0;
if ( ~strcmp(src_str{4},field_text_ged) )
    fprintf(1,'\ttext discrepancy: "%s" - "%s"\n',src_str{4},field_text_ged)
    flg_must_rewrite = 1;
end
if ( ~strcmp(src_str{5},field_Nr_ged) )
    fprintf(1,'\tpage discrepancy: "%s" - "%s"\n',src_str{5},field_Nr_ged)
    flg_must_rewrite = 1;
end
if ( flg_preserve_pgv_date && ~strcmp(src_str{6},field_note_src_ged) )
    fprintf(1,'\tnote discrepancy: "%s" - "%s"\n',src_str{6},field_note_src_ged)
    flg_must_rewrite = 1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_gedcom_new = add_gedfield(str_gedcom_old,gedcom_field_tag,gedcom_field_counter,gedcom_field_data)
% % es.:
% event_pgv_1 = add_gedfield(event_pgv_1,'PLAC',[],field_luo_ged); % add a new PLAC field
% event_pgv_1 = add_gedfield(event_pgv_1,'PLAC',1,field_luo_ged);  % add PLAC field 1

str_gedcom_new = str_gedcom_old;
str_gedcom_new.(get_gedfield_tag(str_gedcom_old,gedcom_field_tag,gedcom_field_counter)) = struct('data',gedcom_field_data);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fieldname_new, fieldname_counter_new, fieldname_counter_old] = get_gedfield_tag(str_gedcom,gedcom_field,fieldname_counter_new)

if isempty(fieldname_counter_new)
    list = fieldnames(str_gedcom);

    fieldname_counter_old = length(strmatch(['f_' gedcom_field],list)); % number of gedcom fields already present

    fieldname_counter_new = fieldname_counter_old+1; % id assigned to the new gecom_field
else
    fieldname_counter_old = [];
end

fieldname_new = sprintf('f_%s_%d',gedcom_field,fieldname_counter_new);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gedcom_field_data = get_gedfield_data(str_gedcom,gedcom_field_tag)

gedcom_field_data = str_gedcom.(gedcom_field_tag).data;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gedcom_new = serialize(str_gedcom,level,ks)

if (~exist('level','var') || (level==0))
    level = 0;
    root_data = str_gedcom.data;
    ks = sprintf('%d %s %s',level,root_data.data,root_data.type);
    % disp(ks)
end

level = level+1;

list = fieldnames(str_gedcom);
for i=1:length(list)
    field = list{i};

    if ~strcmp(field,'data');
        if (field(end-1) == '_')
            ged_tag = field(3:end-2); % 'f_NOTE_1' -> 'NOTE'
        else
            ged_tag = field(3:end-3); % 'f_NOTE_10' -> 'NOTE'
        end
        ged_data_str = str_gedcom.(field);
        ged_data = ged_data_str.data;

        ks_i = strtrim(sprintf('%d %s %s',level,ged_tag,ged_data));
        % disp(ks_i)

        ks = sprintf('%s\n%s',ks,ks_i);

        ks = serialize(ged_data_str,level,ks);
    end
end

% if level==1
%     disp(ks)
% end

gedcom_new = ks;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_gedcom = tokenize(gedcom)

z=regexp(gedcom,'([0-9]) ([_A-Z@0-9]+) ?([^\r\n]+)?','tokens');
matr = reshape([z{:}],3,length(z))';

prefix = 'f_';

ged_first_level = str2double(matr{1,1});
ged_tag         = matr{1,2};
ged_data        = matr{1,3};


% crete root data field
if (ged_first_level == 0)
    % if level = 0, keep type info
    str = struct('data',struct('type',ged_data,'data',ged_tag)); %#ok<NASGU> assigned via eval, init with root_data
else
    % else plain data string
    str = struct('data',ged_data); %#ok<NASGU> assigned via eval, init with root_data
end

list_field = {};
for i=2:size(matr,1)
    ged_level = str2double(matr{i,1});
    ged_tag   = matr{i,2};
    ged_data  = strtrim(matr{i,3}); %#ok<NASGU> used by eval


    list_field_prev = list_field(1:(ged_level-ged_first_level-1));
    if ~isempty(list_field_prev)
        ks = sprintf('.%s',list_field_prev{:});
    else
        ks = '';
    end

    i_field = 1;
    ancora = 1;

    % cerca un nome di campo ancora non esistente (per i campi multipli,
    % es. EMIG, FAMS, ecc.)
    while ancora
        new_field = [prefix ged_tag '_' num2str(i_field)];
        list_field = [list_field_prev new_field];

        cmd1 = ['ancora=isfield(str' ks ',''' new_field ''');'];
        eval(cmd1)

        if ancora
            % fprintf(1,'Duplicate field %s (%s)!',ged_tag,ged_data))
            i_field = i_field+1;
        end
    end

    cmd2=['str' ks '.' new_field '=struct(''data'',ged_data);'];
    eval(cmd2)

    % fprintf(1,'%d -> %s : %s',ged_level,ged_tag,ged_data))
    % disp(list_field);
end

str_gedcom = str;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result_ged = query_ged(str_archivio,result_pgv,threshold)

result_ged = [];

query = result_pgv.str_query;
list_delete = intersect({'matr_luo','pad_cogn','pad_nasc','mad_nasc'},fieldnames(query));
list_delete = union(list_delete,setdiff(fieldnames(query),{'int_nasc_a','int_matr_a','int_mort_a','cogn','mad_cogn','nome','pad_nome','mad_nome'}));
for i = 1:length(list_delete),query = rmfield(query,list_delete{i});end

% non ricercare il nome MARIA (per evitare numerosi falsi positivi
% es. GIUSEPPE MARIA --> darebbe match con DOMENICA MARIA!
if isfield(query,'nome')
    format = uploader_conf('search_name_filter_out');
    query.nome = regexprep(upper(query.nome),format,'');
end


if ( ~isempty(query) )
    % check if you can skip the search (external origin, missing dates, etc.
    [flg_skip,msg_skip] = skip_search(query,result_pgv);
    
    if ( flg_skip )
        fprintf(1,'\tSkipped %s: %s\n',result_pgv.PID,msg_skip)
    else
        % you cannot skip, try to match further
        result_ged = ged('find_person',query,str_archivio,threshold,[]);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_skip, msg_skip] = skip_search(query,result_pgv)

int_nasc_a_threshold = [1730 1902]+[-1 1]*2; % last birth year available in database to be uploaded
int_matr_a_threshold = [1809 1910]+[-1 1]*2; % last marriage year available in database to be uploaded
int_mort_a_threshold = [1747 1865]+[-1 1]*2; % last death year available in database to be uploaded

msg_skip = '';

[flg_skip_mort msg_skip] = check_skip_date(query,'int_mort_a',int_mort_a_threshold,msg_skip);
[flg_skip_matr msg_skip] = check_skip_date(query,'int_matr_a',int_matr_a_threshold,msg_skip);
[flg_skip_nasc msg_skip] = check_skip_date(query,'int_nasc_a',int_nasc_a_threshold,msg_skip);

flg_skip = ( (isnan(flg_skip_nasc) || flg_skip_nasc) && (isnan(flg_skip_matr) || flg_skip_matr) && (isnan(flg_skip_mort) || flg_skip_mort) );

if ( ~isfield(query,'int_nasc_a') && ~isfield(query,'int_mort_a') )
    flg_skip = 1;
    msg_skip = sprintf('mancano le date');
end

if regexp(result_pgv.result_P.result_out.gedcom,'[pP]rovenienza esterna')
    flg_skip = 1;
    msg_skip = sprintf('provenienza esterna');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_skip_i msg_skip] = check_skip_date(query,tag_fieldname,threshold,msg_skip)

if ( isfield(query,tag_fieldname) )
    range = query.(tag_fieldname);
    if ( (min(range) > max(threshold)) || (max(range) < min(threshold)) )
        flg_skip_i = 1;
        if (length(range)==1)
            ks_range = num2str(range);
        else
            ks_range = sprintf('[%d..%d]',range(1),range(2));
        end
        msg_skip_tmp = sprintf('%s fuori range [%d..%d]: %s',tag_fieldname,min(threshold),max(threshold),ks_range);
        if isempty(msg_skip)
            msg_skip = msg_skip_tmp;
        else
            msg_skip = [msg_skip '; ' msg_skip_tmp];
        end
    else
        flg_skip_i = 0;
    end
else
    flg_skip_i = NaN;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result_pgv archive] = search_pgv_data(archive,class_instance,SID,i_pgv)

str_query = struct([]);
result_Fs = struct([]);
result_Pcon = struct([]);
result_Fc = struct([]);
result_Ppad = struct([]);
result_Pmad = struct([]);

[result_P, archive, PID] = getXxxxById(archive,i_pgv,class_instance,SID,'getPersonByID');
if ~isempty(result_P)
    person      = result_P.result_out;
    str_query   = add_person_info(str_query,person);

    if ( ~isempty(person.spouseFamilies) )
        if (iscell(person.spouseFamilies) && (length(person.spouseFamilies)>1) )
            disp('Todo: multiple spouses') % !!! piu' di un matrimonio!
            person.spouseFamilies = person.spouseFamilies{1};
        end
        [result_Fs, archive] = getXxxxById(archive,person.spouseFamilies,class_instance,SID,''); % getFamilyByID is implicit
        family_s = result_Fs.result_out;
        str_query   = add_family_info(str_query,family_s);

        con_PID = setdiff({family_s.HUSBID,family_s.WIFEID},{PID,''});
        if ~isempty(con_PID)
            [result_Pcon, archive] = getXxxxById(archive,con_PID{1},class_instance,SID,''); % getPersonByID is implicit
            person_Pcon = result_Pcon.result_out;
            str_query_con = struct([]);
            str_query_con = add_person_info(str_query_con,person_Pcon);

            str_query = remap_query_string(str_query,str_query_con,'con');
        end
    end

    if ~isempty(person.childFamilies)
        [result_Fc, archive ] = getXxxxById(archive,person.childFamilies,class_instance,SID,''); % getFamilyByID is implicit
        family_c = result_Fc.result_out;

        if ~isempty(family_c.HUSBID)
            [result_Ppad, archive] = getXxxxById(archive,family_c.HUSBID,class_instance,SID,''); % getPersonByID is implicit
            person_Ppad = result_Ppad.result_out;
            str_query_pad = struct([]);
            str_query_pad = add_person_info(str_query_pad,person_Ppad);

            str_query = remap_query_string(str_query,str_query_pad,'pad');
        end

        if ~isempty(family_c.WIFEID)
            [result_Pmad, archive] = getXxxxById(archive,family_c.WIFEID,class_instance,SID,''); % getPersonByID is implicit
            person_Pmad = result_Pmad.result_out;
            str_query_mad = struct([]);
            str_query_mad = add_person_info(str_query_mad,person_Pmad);

            str_query = remap_query_string(str_query,str_query_mad,'mad');
        end
    end

    msg = show_person_data(PID,str_query);
else
    msg = sprintf('Missing Person with id %d!',i_pgv);
    disp(msg)
end

result_pgv = struct();
result_pgv.PID = PID;
result_pgv.result_P = result_P;
result_pgv.result_Fs = result_Fs;
result_pgv.result_Pcon = result_Pcon;
result_pgv.result_Fc = result_Fc;
result_pgv.result_Ppad = result_Ppad;
result_pgv.result_Pmad = result_Pmad;
result_pgv.str_query = str_query;
result_pgv.msg = msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_query = add_person_info(str_query,person) %#ok<INUSL>

% evalin('base','fieldnames(liste)''')

gedcom = person.gedcom;

% nome
z = regexp(gedcom,' GIVN ([^\r\n]+)','tokens');
fieldname = 'nome';
if ~isempty(z)
    ks = z{1}{1};
    str_query(1).(fieldname) = ks;
end

% cognome
z = regexp(gedcom,' SURN ([^\r\n]+)','tokens');
fieldname = 'cogn';
if ~isempty(z)
    ks = z{1}{1};
    str_query(1).(fieldname) = ks;
end

% data nascita
z = regexp(gedcom,'1 BIRT[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 DATE ([^\r\n]+)','tokens');
fieldname = 'nasc';
if ~isempty(z)
    ks = z{1}{2};
    ks = gedcomdate(ks);
    str_query(1).(fieldname) = ks;
    str_query = add_int_fieldname(ks,str_query,fieldname);
end

% luogo nascita
z = regexp(gedcom,'1 BIRT[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 PLAC ([^\r\n]+)','tokens');
fieldname = 'nasc_luo';
if ~isempty(z)
    ks = z{1}{2};
    z = regexp(ks,'[^\,\s]+','match');
    str_query(1).(fieldname) = z{1};
end

% data morte
z = regexp(gedcom,'1 DEAT[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 DATE ([^\r\n]+)','tokens');
fieldname = 'mort';
if ~isempty(z)
    ks = z{1}{2};
    ks = gedcomdate(ks);
    str_query(1).(fieldname) = ks;
    str_query = add_int_fieldname(ks,str_query,fieldname);
end

% luogo morte
z = regexp(gedcom,'1 DEAT[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 PLAC ([^\r\n]+)','tokens');
fieldname = 'nasc_luo';
if ~isempty(z)
    ks = z{1}{2};
    z = regexp(ks,'[^\,\s]+','match');
    str_query(1).(fieldname) = z{1};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_query = add_family_info(str_query,family)

gedcom = family.gedcom;

% data matrimonio
z = regexp(gedcom,'1 MARR[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 DATE ([^\r\n]+)','tokens');
fieldname = 'matr';
if ~isempty(z)
    ks = z{1}{2};
    ks = gedcomdate(ks);
    str_query(1).(fieldname) = ks;
    str_query = add_int_fieldname(ks,str_query,fieldname);
end

% luogo matrimonio
z = regexp(gedcom,'1 MARR[\r\n]+([2-9] [^\r\n]+[\r\n]+)*2 PLAC ([^\r\n]+)','tokens');
fieldname = 'matr_luo';
if ~isempty(z)
    ks = z{1}{2};
    z = regexp(ks,'[^\,\s]+','match');
    str_query(1).(fieldname) = z{1};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_query = add_int_fieldname(ks,str_query,fieldname)

z = regexp(ks,'[0-9]{4}','match');
if ~isempty(z)
    year = str2double(z{1});

    if ( regexp(ks,'^00') ) % range is wider if date is with ABT (--> 00/00/year)
        range = [year-5 year+5];
    else
        range = [year-1 year+1];
    end
    str_query(1).(['int_' fieldname '_a']) = range;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_out = gedcomdate(ks0)

ks = ks0;

z=regexp(ks0,'BET.*?([0-9]{4}) AND .*?([0-9]{4})','tokens');
if ~isempty(z)
    year1 = z{1}{1};
    year2 = z{1}{2};
    ks = num2str(round((str2double(year1)+str2double(year2))/2));
end

if regexp(ks0,'ABT ')
    ks = strrep(ks0,'ABT ','');
end

if regexp(ks0,'BEF ')
    ks = strrep(ks0,'BEF ','');
end

if regexp(ks0,'AFT ')
    ks = strrep(ks0,'AFT ','');
end

if ~strcmp(ks0,ks)
    % if string was changed, display the change
    fprintf(1,'%s -> %s\n',ks0,ks)
end

switch length(regexp(ks,'[^\s]+','match'))
    case 1 %year?
        if length(ks) == 4
            ks_out = ['00/00/' ks];
        else
            error('Error decoding year %s',ks)
        end
    case 2 %month and year?
        ks_out = datestr(datenum(['01 ' ks]),24); % 13 OCT 1974 --> 13/10/1974
        ks_out(1:2) = '0';
    case 3
        try
            ks_out = datestr(datenum(ks),24); % 13 OCT 1974 --> 13/10/1974
        catch %#ok<CTCH>
            error('Error converting date "%s"!',ks)
        end
    otherwise
        error('Error decoding date %s',ks)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result archive XID] = getXxxxById(archive,i_pgv,class_instance,SID,soap_method)

if (ischar(i_pgv) && ~isempty(i_pgv) ) % if a full string is passed ...
    switch (i_pgv(1))
        case 'I'
            soap_method = 'getPersonByID';
        case 'F'
            soap_method = 'getFamilyByID';
        otherwise
            error('Unknown gedcom type %s',i_pgv)
    end
end

if strcmp(soap_method,'getPersonByID')
    class_char = 'I';
    list_id    = 'list_PID';
else
    class_char = 'F';
    list_id    = 'list_FID';
end

if ( iscell(i_pgv) && (length(i_pgv)>1) )
    error('Attenzione!!! Le famiglie (%s) hanno come figlio la stessa persona!',sprintf('%s ',i_pgv{:})) %#ok<SPERR>
end

flg_must_archive = 0;
if ischar(i_pgv) % if a full string is passed ...
    XID = i_pgv;

    if isfield(archive.list_obj,XID)
        % search in teh cache
        result = archive.list_obj.(XID);
    else
        % else issue the SOAP query
        result    = PhpGedViewSoapInterface_waitNet(soap_method,{class_instance,SID,XID});
        i_pgv     = str2double(XID(2:end));
        flg_must_archive = 1;
    end
else % else if an integer is passed, try to find the right number of zeros in the string

    XID = archive.(list_id){i_pgv+1};
    if ~isempty(XID) % try to search for a cached XID (PID or FID)
        result = archive.list_obj.(XID);
    else % else try to guess the XID

        XID = sprintf([ class_char '%d'],i_pgv); % start with no useless zeros
        try
            result    = PhpGedViewSoapInterface_waitNet(soap_method,{class_instance,SID,XID});
            flg_must_archive = 1;
        catch
            XID = sprintf([class_char '%04d'],i_pgv); % then try with a fixed length (4 digits)
            try
                result    = PhpGedViewSoapInterface_waitNet(soap_method,{class_instance,SID,XID});
                flg_must_archive = 1;
            catch
                XID = '';
                result = []; % give up, return empty var
                msg=sprintf('Warning, ID %i not found!',i_pgv);
                disp(msg);
                % error('Warning, ID %d not found!',i_pgv);
            end
        end
    end
end

% prepare output
if ( (class_char=='F') && ~iscell(result.result_out.CHILDREN) )
    % force CHILDREN field to be always a cell array (for a single
    % child, it would be a string)
    result.result_out.CHILDREN = {result.result_out.CHILDREN};
end

if flg_must_archive % store in the cache for later use
    archive.(list_id){i_pgv+1} = XID; % +1 because one-based
    archive.list_obj.(XID) = result;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result    = PhpGedViewSoapInterface_waitNet(soap_method,params)

status = 0; % [0,1,2] 0 : no problem; 1 : net problems;

flg_repeat_download = 1; % [boolean] repeat download until true
while (flg_repeat_download)
    result    = PhpGedViewSoapInterface(soap_method,params);
    if (result.err_code ~= 1)
        flg_repeat_download = 0; % 0 --> the internet download was successful: go on
        if (status == 1)
            fprintf(1,'\tConnectivity problem solved.\n')
        end
    else
        if (status == 0)
            disp(result.err_code)
        end
        status = 1; % net problems found
        pause(1); % pause for a few seconds, no need to hurry
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_query = remap_query_string(str_query,str_query_con,person_class)

switch person_class
    case 'con'
        list_map_con = {...
            'nome'      , 'con_nome'; ...
            'cogn'      , 'con_cogn'; ...
            'nasc'      , 'con_nasc'; ...
            'int_nasc_a', 'int_con_nasc_a'; ...
            'int_nasc_m', 'int_con_nasc_m'; ...
            'int_nasc_g', 'int_con_nasc_g'; ...
            };
    case 'pad'
        list_map_con = {...
            'nome'      , 'pad_nome'; ...
            'cogn'      , 'pad_cogn'; ...
            'nasc'      , 'pad_nasc'; ...
            'int_nasc_a', 'int_pad_nasc_a'; ...
            'int_nasc_m', 'int_pad_nasc_m'; ...
            'int_nasc_g', 'int_pad_nasc_g'; ...
            };
    case 'mad'
        list_map_con = {...
            'nome'      , 'mad_nome'; ...
            'cogn'      , 'mad_cogn'; ...
            'nasc'      , 'mad_nasc'; ...
            'int_nasc_a', 'int_mad_nasc_a'; ...
            'int_nasc_m', 'int_mad_nasc_m'; ...
            'int_nasc_g', 'int_mad_nasc_g'; ...
            };
    otherwise
        error('Classe non gestita: %s',person_class)
end


list_fields = fieldnames(str_query_con);
for i=1:length(list_fields)
    field = list_fields{i};
    ind = strcmp(field,list_map_con(:,1));
    if any(ind)
        field_new = list_map_con{ind,2};
        str_query(1).(field_new) = str_query_con.(field);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function msg = show_person_data(PID,str_query)

fieldlist = {'nome','cogn','nasc_Nr','nasc','pad_nome','mad_nome',...
    'mad_cogn','matr_Nr','matr','con_nome','con_cogn','mort_Nr','mort','note'};

fieldavail = fieldnames(str_query);
fieldmissing = setdiff(fieldlist,fieldavail);
for i=1:length(fieldmissing)
    tag = fieldmissing{i};
    str_query(1).(tag) = '#';
end

msg = sprintf('%s) %s %s - b:%s,%s (%s, %s %s) - m:%s,%s (%s %s) - d:%s,%s - note: %s',...
    PID,str_query.nome,str_query.cogn,str_query.nasc_Nr,str_query.nasc,...
    str_query.pad_nome,str_query.mad_nome,str_query.mad_cogn,...
    str_query.matr_Nr,str_query.matr,str_query.con_nome,str_query.con_cogn,...
    str_query.mort_Nr,str_query.mort,str_query.note);
disp(msg);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function par_struct = assert(params,field_list)

if (length(params) ~= length(field_list))
    msg = sprintf('Number of input parameters (%d) doesn''t match the number of requested parameters (%d):\n',length(params),length(field_list));
    disp(msg)
    disp(field_list)
    error(' ')
end

par_struct = struct;
for i = 1:length(params)
    par_struct.(field_list{i}) = params{i};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function string_new = normalize_string(string_old,type)
% The match is done using a regexp pattern
%
% for a list: unique(str_archivio.archivio(:,12))
%

string_new = string_old; % default behaviour: no change


% table, made up of rows {regexp_pattern,corresponding_string}
list_conversion_table = struct();

% takes a string, and returns the canonical form of the place, if matching
% eg.: 'Caposele' --> 'Caposele, Avellino, Campania, ITA'.
list_conversion_table.PLAC = uploader_conf('list_conversion_table.PLAC');

% takes a pgvu user, and returns the corresponding source
% eg.: 'alex' --> 'S18'.
list_conversion_table.pgvu = uploader_conf('list_conversion_table.pgvu');

% takes a pgvu event tag, and returns the corresponding source txt description
% eg.: 'BIRT' --> 'registro nati anagrafe Caposele'.
list_conversion_table.src_txt = uploader_conf('list_conversion_table.src_txt');


conversion_table = list_conversion_table.(type); % choose the conversion table

ind_found = [];
if ~isempty(string_old)
    % find match
    ind = regexp(string_old,conversion_table(:,1));
    for i=1:length(ind)
        if ~isempty(ind{i})
            ind_found = i;
            break
        end
    end

    if isempty(ind_found)
        error('No match for string %s of type %s: add it to the list!',string_old,type)
    else
        string_new = conversion_table{ind_found,2};
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_matches action rid_action] = update_list_matches(list_matches,PID,list_found_id,list_found_fit,arcfile)
% update the list of matches (to detect duplicate matches with the same
% person)

action     = 'new';
rid_action = '';

ind_write  = size(list_matches,1)+1; % by default, append at the end
enab_write = 1; % by default, update the list

if (~isempty(list_matches))
    ind_found = find(cell2mat(list_matches(:,2))==list_found_id); % same ged id
    ind_found_complete = strmatch(PID,list_matches(ind_found,1)); % same ged id, and same pgv id <--> same link
    if (~isempty(ind_found_complete))
        % link was already managed: skip it
        ind_write  = ind_found_complete;
        
        record_found = list_matches(ind_found_complete,:);
        rid_old = record_found{1};
        fit_old = record_found{3};
        rid_new = PID;
        fit_new = list_found_fit;
        if (fit_old ~= fit_new) % link was previously disabled
            fprintf(1,'\nATTENZIONE! Il link (%s->%d, fit %.3f) e'' stato precedentemente disabilitato\n\n',rid_new,list_found_id,fit_new)
            action = 'drop_new';
            rid_action = rid_new;
            enab_write = 0; % don't update the link, leave it as it was left
        else
            % register the match again
        end
        
    elseif ~isempty(ind_found)
        % link to same ged id found: check the best link (the one with lower fit)
        record_found = list_matches(ind_found,:);
        rid_old = record_found{1};
        fit_old = record_found{3};
        rid_new = PID;
        fit_new = list_found_fit;
        fprintf(1,'\nATTENZIONE! La stessa persona del ged (%d) e'' associata a piu'' persone pgv: %s (fit %.3f), %s (fit %.3f)\n\n',list_found_id,rid_old,fit_old,rid_new,fit_new)
        if fit_new < fit_old
            fprintf(1,'\tVisto che il nuovo fitness (%.3f) e'' migliore del vecchio (%.3f), trascuro il vecchio match e considero questo\n\n',fit_new,fit_old)
            action = 'drop_old';
            rid_action = rid_old;
        else
            fprintf(1,'\tVisto che il nuovo fitness (%.3f) e'' peggiore del vecchio (%.3f), trascuro questo nuovo match\n\n',fit_new,fit_old)
            action = 'drop_new';
            rid_action = rid_new;
        end
    end
end

if enab_write
    list_matches(ind_write,:) = {PID,list_found_id,list_found_fit};
    
    load(arcfile,'session')
    session.list_matches = list_matches;
    save(arcfile,'session','-append')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function start_chng = determine_list_changes_position(list_changes,start_pos)
% determine the required position (integer 1..N) in list_changes

if ischar(start_pos)
    start_chng = strmatch(start_pos,list_changes(:,1),'exact');
    if isempty(start_chng)
        error('"%s" not found inside list_changes!',start_pos)
    else
        fprintf(1,'Starting upload proposal from %s (pos. %d)\n',start_pos,start_chng)
    end
elseif isreal(start_pos) && (start_pos-round(start_pos)<1e-9)
    start_chng = round(max(1,min(start_pos,size(list_changes,1)))); % first position in list_changes to start from to upload data
else
    error('start_pos must be an integer or a string (es. "I4563")')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_query = build_list_queries(str_search)
% determine the queries for the searched person

list_query1 = {};

% first name
name_str = sprintf('%s%%%s',str_search.nome,str_search.cogn); % es. 'CARMINA%CERES' (the % will match any intermediate string in the SQL LIKE statement, for example 'CARMINA "MENA" CERES')
query_name = ['NAME=' name_str]; % Keywords: NAME, BIRTHDATE, DEATHDATE, BIRTHPLACE, DEATHPLACE, GENDER
list_query1 = [list_query1 {query_name}];

if ~isempty(str_search.nome_2)
    % second name
    query_name = sprintf('NAME=%s%%%s%%%s',str_search.nome,str_search.nome_2,str_search.cogn); % Keywords: NAME, BIRTHDATE, DEATHDATE, BIRTHPLACE, DEATHPLACE, GENDER
    list_query1 = [list_query1 {query_name}]; % es. {'NAME=ALFONSA%ILARIA','NAME=ALFONSA%MARIA%ILARIA'}'
end


list_query2 = {''};

% only birth date
if ~isnan(str_search.int_nasc_a)
    query_ext = sprintf('&BIRTHDATE=%d',str_search.int_nasc_a);
    list_query2 = [list_query2 {query_ext}];
end
% only death date
if ~isnan(str_search.int_mort_a)
    query_ext = sprintf('&DEATHDATE=%d',str_search.int_mort_a);
    list_query2 = [list_query2 {query_ext}];
end
% both birth and death date
if (~isnan(str_search.int_nasc_a) && ~isnan(str_search.int_mort_a))
    query_ext = sprintf('&BIRTHDATE=%d&DEATHDATE=%d',str_search.int_nasc_a,str_search.int_mort_a);
    list_query2 = [list_query2 {query_ext}];
end


% mix lists
list_query = {};
for i2=1:length(list_query2)
    for i1=1:length(list_query1)
        list_query{end+1} = [list_query1{i1} list_query2{i2}]; %#ok<AGROW>
    end
end
list_query = fliplr(list_query); % from most specific to less specific


% add full birth date on top (if the date is in the canonical format)
if (~isempty(str_search.nasc) && (sum(str_search.nasc=='/')==2) )
    query_add = sprintf('BIRTHDATE=%s',create_gedcom_date(str_search.nasc)); % only name (surname could be slightly different)
    list_query = [{query_add} list_query];
    
    % % checks on single name and surname could be very slow
    %     query_add = sprintf('NAME=%s&BIRTHDATE=%s',str_search.nome,create_gedcom_date(str_search.nasc)); % only name (surname could be slightly different)
    %     list_query = [{query_add} list_query];
    %
    %     query_add = sprintf('NAME=%s&BIRTHDATE=%s',str_search.cogn,create_gedcom_date(str_search.nasc)); % only surname (name could be slightly different)
    %     list_query = [{query_add} list_query];
end


% remove queries with a single name or surname (to avoid too many matches)
list_query = list_query(~cellfun(@isempty,regexp(list_query,'[\s&]')));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gedcom_date = create_gedcom_date(ks_date)
% '13/02/1797' --> '13 Feb 1797'

gedcom_date = upper(datestr(datenum(ks_date,'dd/mm/yyyy'),'dd mmm yyyy'));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_persons = filter_search_results(persons,str_search,wsdl_url,list_persons_all,class_instance,SID,archive)

if ~isempty(list_persons_all) % other people, check if there are duplicates, and filter them out
    for i=1:length(list_persons_all)
        list_gedcomName_all{i} = list_persons_all(i).gedcomName; %#ok<AGROW>
        list_birthDate_all{i}  = list_persons_all(i).birthDate; %#ok<AGROW>
        list_deathDate_all{i}  = list_persons_all(i).deathDate; %#ok<AGROW>
    end
else
    list_gedcomName_all = {};
    list_birthDate_all  = {};
    list_deathDate_all  = {};
end

list_persons = struct([]);
for i_person=1:length(persons)
    p=persons(i_person);
    
    % other people, check if there are duplicates, and filter them out
    if ~isempty(list_gedcomName_all)
        ind1 = ismember(p.gedcomName,list_gedcomName_all);  % same name
        ind2 = ismember(p.birthDate,list_birthDate_all);    % same birth date
        ind3 = ismember(p.deathDate,list_deathDate_all);    % same death date
        
        ind = ind1 & ind2 & ind3;
        if ind
            continue % skip duplicated person
        end
    end
    
    % check to see if dates match...
    [flg_incompatible result_check] = check_flg_incompatible(p,str_search,class_instance,SID,archive);
    if ~flg_incompatible % ... if so, then list the person
        % add new fields
        p.pad_nome_gedcom       = result_check.result_F.pad_nome_full_to_be_checked; % gedcom name of father
        p.mad_nome_gedcom       = result_check.result_F.mad_nome_full_to_be_checked; % gedcom name of mother
        p.fitness               = result_check.fitness;     % correspondence fitness with search params
        p.result_F              = result_check.result_F;    % child family structure

        % update list
        list_persons        = [list_persons p]; %#ok<AGROW>
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = prepare_pgv_links(params)
% prepare links to pgv individuals/families URL's

result = struct();
err_code    = 0;
err_msg     = '';

% manage input params
par_struct = assert(params,{'wsdl_url','PID','childFamilies','spouseFamilies'});
wsdl_url        = par_struct.wsdl_url;       % link
PID             = par_struct.PID;            % string with PID from pgv site
childFamilies   = par_struct.childFamilies;  % string with FID  (child families) from pgv site
spouseFamilies  = par_struct.spouseFamilies; % string with FID  (spouse families) from pgv site

family_link = sprintf('%sfamily.php?famid=',wsdl_url(1:regexp(wsdl_url,'genservice')-1)); % PGV family link URL prefix
% mng child family
if ~isempty(childFamilies)
    if ( iscell(childFamilies) && length(unique(childFamilies)) < length(childFamilies) )
        ks_msg = sprintf('Warning! There are duplicated child families for PID %s:\n',PID);
        ks_msg = sprintf('%s%s\n',ks_msg,sprintf('%s,',childFamilies{:}));
        disp(childFamilies)
        if strcmp(childFamilies{1},childFamilies{2})
            % why are there two identical child families? please check
            keyboard
        end
        ks_msg = sprintf('%sPlease fix this manually on PhpGedView website, then continue\n',ks_msg);
        msgbox(ks_msg)
        childFamilies = unique(childFamilies);
        if iscell(childFamilies) && (length(childFamilies)==1)
            childFamilies = childFamilies{1};
        end
    end
    if ( iscell(childFamilies) && (length(childFamilies)>1) )
        error('Error in pgv gedcom: PID %s is children of more than one family: %s\n',PID,sprintf('%s,',childFamilies{:}))
    end
    child_family_link   = [family_link childFamilies];
    child_family_atab   = sprintf('<a href="%s">%s</a>',child_family_link,childFamilies); % tested on a single match case (child_family_link is a string, childFamilies is a string)
else
    child_family_atab   = '';
end
% mng spouse family
if ~isempty(spouseFamilies)
    if ischar(spouseFamilies)
        spouse_family_atab  = sprintf('<a href="%s%s">%s</a>',family_link,spouseFamilies,spouseFamilies);
    else
        spouse_family_link = {};
        for i=1:length(spouseFamilies)
            spouse_family_link{i}  = sprintf('<a href="%s%s">%s</a>',family_link,spouseFamilies{i},spouseFamilies{i}); %#ok<AGROW>
        end
        spouse_family_atab = sprintf(',%s',spouse_family_link{:});
        spouse_family_atab = ['(' spouse_family_atab(2:end) ')'];
    end
else
    spouse_family_atab   = '';
end
% PID link
individual_link = sprintf('%sindividual.php?pid=',wsdl_url(1:regexp(wsdl_url,'genservice')-1)); % PGV individual link URL prefix
individual_atab = sprintf('<a href="%s%s">%s</a>',individual_link,PID,PID);


result.err_code             = err_code;
result.err_msg              = err_msg;
result.family_link          = family_link;
result.individual_atab      = individual_atab;
result.child_family_atab    = child_family_atab;
result.spouse_family_atab   = spouse_family_atab;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_incompatible result_check] = check_flg_incompatible(p,str_search,class_instance,SID,archive)
% check if a person p matches against the query data in str_search

result_F        = struct([]);
fitness         = NaN;
val_pad_nome    = NaN;
val_mad_nome    = NaN;
val_mad_cogn    = NaN;
ks_parents      = 'di ???';

debug = 0;

fitness_thr         = 0.1;    % soglia di fitness finale
fitness_thr_dates   = 0.99;   % soglia di fitness per le date di nascita\morte

% check birth date compatibility
ks_birth_date_i = p.birthDate;
[flg_incompatible_birth fitness_birth] = check_date_incompatibility(str_search,'nasc',ks_birth_date_i,debug);

% check death date compatibility
ks_death_date_i = p.deathDate;
[flg_incompatible_death fitness_death] = check_date_incompatibility(str_search,'mort',ks_death_date_i,debug);

if ( (~flg_incompatible_birth) && (~flg_incompatible_death) && ( (fitness_birth<=fitness_thr_dates) || (fitness_death<=fitness_thr_dates) ) )
    % if dates are not clearly incompatible, try to analyze parent's names
    fitness0 = min([fitness_birth fitness_death]); % NaN's are ignored

    % check surname and parents
    FID_family = p.childFamilies;
    result_F = get_pgv_parents(archive,FID_family,class_instance,SID);
    z=regexp(p.gedcomName,'/([^/]+)/','tokens');
    if isempty(z)
        cogn_p = '';
    else
        cogn_p = upper(z{1}{1});
    end
    if result_F.err_code
        error(result_F.err_msg)
    else
        vett_parent_fit = zeros(1,0);
        if ~isempty(cogn_p) && ~isempty(str_search.cogn)
            vett_parent_fit = [vett_parent_fit ged('strfielddist',str_search.cogn,cogn_p)]; % string distance
        end
        if ~isempty(result_F.pad_nome_to_be_checked) && ~isempty(str_search.pad_nome)
            vett_parent_fit = [vett_parent_fit ged('strfielddist',str_search.pad_nome,result_F.pad_nome_to_be_checked)]; % string distance
        end
        if ~isempty(result_F.mad_nome_to_be_checked) && ~isempty(str_search.mad_nome)
            vett_parent_fit = [vett_parent_fit ged('strfielddist',str_search.mad_nome,result_F.mad_nome_to_be_checked)]; % string distance
        end
        if ~isempty(result_F.mad_cogn_to_be_checked) && ~isempty(str_search.mad_cogn)
            vett_parent_fit = [vett_parent_fit ged('strfielddist',str_search.mad_cogn,result_F.mad_cogn_to_be_checked)]; % string distance
        end
        bonus = [1 1 1 5]*fitness_thr; % allow a bad match if at least three are good
        bonus = bonus(1:length(vett_parent_fit));
        
        %fitness = fitness0*mean([val_pad_nome val_mad_nome val_mad_cogn]); % Formula too favorable: if date is quite close, alos a very bad fitness on parent's names can't decrease enough final fitness, and false matches are possible
        fitness = fitness0+max(0,mean(sort(vett_parent_fit)-bonus));
        
        ks_parents = sprintf('%s di %s (%.2f) e %s (%.2f) %s (%.2f) -> %f --> %f',p.gedcomName,result_F.pad_nome_to_be_checked,val_pad_nome,result_F.mad_nome_to_be_checked,val_mad_nome,result_F.mad_cogn_to_be_checked,val_mad_cogn,fitness0,fitness);
    end
else
    fitness = 1;
end

if (fitness<=fitness_thr)
    flg_incompatible = 0;
else
    flg_incompatible = 1;
end

result_check = struct();
result_check.result_F       = result_F;
result_check.fitness        = fitness;
result_check.fitness_birth  = fitness_birth;
result_check.fitness_death  = fitness_death;
result_check.val_pad_nome   = val_pad_nome;
result_check.val_mad_nome   = val_mad_nome;
result_check.val_mad_cogn   = val_mad_cogn;
result_check.ks_parents     = ks_parents;

if debug
    fprintf(1,'%30s: %15s (%f) %15s (%f) --> %f  (%s)\n',p.gedcomName,p.birthDate,fitness_birth,p.deathDate,fitness_death,fitness,ks_parents) %#ok<UNRCH>
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nome, cogn] = split_gedcomName(gedcomName)
% es. 'Serafina /Ceres/' --> nome='SERAFINA' e  cogn='CERES'

gedcomName = upper(gedcomName);

ind_slash = find(gedcomName=='/',1);
if ~isempty(ind_slash)
    nome = gedcomName(1:ind_slash-2);
    cogn = gedcomName(ind_slash+1:end-1);
else
    nome = gedcomName;
    cogn = '';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [i_pgv_new archive] = select_single_parental_family(archive,i_pgv,class_instance,SID)

global uploader_multiple_parental_families

if ( iscell(i_pgv) && (length(i_pgv)>1) )
    % multiple parental families, manage it
    
    % check if selection was performed in advance...
    for i_fam = 1:size(uploader_multiple_parental_families,1)
        i_pgv_i = uploader_multiple_parental_families{i_fam,1};
        val_i   = uploader_multiple_parental_families{i_fam,2};
        if isequal(i_pgv_i,i_pgv)
            i_pgv_new = i_pgv_i{val_i};
            return
        end
    end
    
    % ...no, a choice by user is needed
    ks0 = sprintf('\nMultiple parental family found!');
    list_children={};
    for i_parent=1:length(i_pgv)
        [result_F, archive] = getXxxxById(archive,i_pgv{i_parent},class_instance,SID,'getFamilyByID');
        result_F=result_F.result_out;
        HUSBID=result_F.HUSBID;
        if isempty(list_children)
            list_children=result_F.CHILDREN;
        else
            list_children=intersect(list_children,result_F.CHILDREN);
        end
        if isempty(HUSBID)
            % family with missing husband
            husb_id = '-';            
            husb_name = '<missing>';
        else
            [result_P, archive] = getXxxxById(archive,HUSBID,class_instance,SID,'getPersonByID');
            result_P=result_P.result_out;
            husb_id = HUSBID;
            husb_name = result_P.gedcomName;
        end
        ks0 = sprintf('%s\n%2d) %s: %s',ks0,i_parent,husb_id,husb_name);
    end
    
    PID = list_children{1};
    [result_P, archive] = getXxxxById(archive,PID,class_instance,SID,'getPersonByID');
    result_P = result_P.result_out;
    ks=num2str(1:length(i_pgv),'%d,');
    ks0=sprintf('%s\n*** This should be fixed manually in the online tree!\nAnyway, to proceed, which is the biological parental family for %s (%s)? [%s]',ks0,result_P.gedcomName,PID,ks(1:end-1));
    
    ancora = 1;
    while ancora
        ch = inputdlg(ks0);
        if (isempty(ch) || isempty(ch{1}))
            val = 1;
        else
            val = str2double(ch{1});
            if isempty(val)
                val=1;
            end
        end
        if (rem(val,1)==0) && (val>=1) && (val<=length(i_pgv))
            ancora = 0;
        end
    end
    
    % store chosen value
    if isempty(uploader_multiple_parental_families)
        uploader_multiple_parental_families = {i_pgv,val};
    else
        uploader_multiple_parental_families(end+1,:) = {i_pgv,val};
    end
    
    i_pgv_new = i_pgv{val};
else
    % only one parental family
    i_pgv_new = i_pgv;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result archive] = get_pgv_parents(archive,FID_family,class_instance,SID)

err_code = 0;
err_msg  = '';

result_F                    = struct([]);
CHILDREN                    = {};

result_pad                  = struct([]);
HUSBID                      = '';
pad_nome_full_to_be_checked = '';
pad_nome_to_be_checked      = '';
pad_cogn_to_be_checked      = '';

result_mad                  = struct([]);
WIFEID                      = '';
mad_nome_full_to_be_checked = '';
mad_nome_to_be_checked      = '';
mad_cogn_to_be_checked      = '';


% check parents
i_pgv = FID_family;
if ~isempty(i_pgv)
    % ensure only one parental family (for example in case of adoption
    % there are two families)
    [i_pgv archive] = select_single_parental_family(archive,i_pgv,class_instance,SID);

    [result_F_, archive] = getXxxxById(archive,i_pgv,class_instance,SID,'getFamilyByID');
    if result_F_.err_code
        err_code = result_F_.err_code;
        err_msg  = sprintf('Error downloading FID %s',i_pgv);
    else
        result_F = result_F_.result_out;
        CHILDREN = result_F.CHILDREN; % children list
        
        % get father pgv data
        i_pgv = result_F.HUSBID;
        if ~isempty(i_pgv)
            [result_pad_, archive] = getXxxxById(archive,i_pgv,class_instance,SID,'getPersonByID');
            if result_pad_.err_code
                err_code = result_pad_.err_code;
                err_msg  = sprintf('Error downloading PID %s',i_pgv);
            else
                result_pad = result_pad_.result_out;
                HUSBID = result_pad.PID;
                pad_nome_full_to_be_checked = result_pad.gedcomName;
                pad_nome_full_to_be_checked = upper(pad_nome_full_to_be_checked);
                [pad_nome_to_be_checked, pad_cogn_to_be_checked] = split_gedcomName(pad_nome_full_to_be_checked);
            end
        end
        
        % get mother pgv data
        i_pgv = result_F.WIFEID;
        if ~isempty(i_pgv)
            [result_mad_, archive] = getXxxxById(archive,i_pgv,class_instance,SID,'getPersonByID');
            if result_mad_.err_code
                err_code = result_mad_.err_code;
                err_msg  = sprintf('Error downloading PID %s',i_pgv);
            else
                result_mad = result_mad_.result_out;
                WIFEID = result_mad.PID;
                mad_nome_full_to_be_checked = result_mad.gedcomName;
                mad_nome_full_to_be_checked = upper(mad_nome_full_to_be_checked);
                [mad_nome_to_be_checked, mad_cogn_to_be_checked] = split_gedcomName(mad_nome_full_to_be_checked);
            end
        end
    end
end

% prepare output
result.err_code                     = err_code;
result.err_msg                      = err_msg;

result.result_F                     = result_F;
result.CHILDREN                     = CHILDREN;

result.result_pad                   = result_pad;
result.HUSBID                       = HUSBID;
result.pad_nome_full_to_be_checked  = pad_nome_full_to_be_checked;
result.pad_nome_to_be_checked       = pad_nome_to_be_checked;
result.pad_cogn_to_be_checked       = pad_cogn_to_be_checked;

result.result_mad                   = result_mad;
result.WIFEID                       = WIFEID;
result.mad_nome_full_to_be_checked  = mad_nome_full_to_be_checked;
result.mad_nome_to_be_checked       = mad_nome_to_be_checked;
result.mad_cogn_to_be_checked       = mad_cogn_to_be_checked;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flg_incompatible fitness] = check_date_incompatibility(str_search,event_tag,ks_date_to_be_checked,debug)
% check the date against a reference one, to see if there is a certain
% incompatibility (es. too many years of difference)
% fitness [0..1]: 0 identical, 1 totally incompatible

max_year_difference = 10; % [year] max number of years of difference beyond which dates are incompatible (fitness=1)

ks_date_ref = str_search.(event_tag);

fitness = NaN; % [0..1] nothing to compare
if ( ~isempty(ks_date_ref) )
    try
        % date_ref            = datenum(ks_date_ref,'dd/mm/yyyy');    % [g] '14/06/1859' --> 679151 o '1868' --> 682274
        date_ref            = datestr_to_datenum(ks_date_ref); % [g] '14/06/1859' --> 679151 o '1868' --> 682274
    catch
        error('Error decoding date "%s"',ks_date_ref)
    end
    if ( ~isempty(ks_date_to_be_checked) )
        ks_date_to_be_checked = strrep(ks_date_to_be_checked,'ABT ',''); % remove trailing 'ABT'
        ks_date_to_be_checked = strrep(ks_date_to_be_checked,'AFT ',''); % remove trailing 'AFT'
        ks_date_to_be_checked = strrep(ks_date_to_be_checked,'BEF ',''); % remove trailing 'BEF'
        if regexp(ks_date_to_be_checked,'^[0-9]+$')
            date_to_be_checked  = datenum(ks_date_to_be_checked,'yyyy');    % [g] es. '1865' --> 681179
        else
            date_to_be_checked  = datestr_to_datenum(ks_date_to_be_checked);           % [g] es. '14 JUN 1859' --> 679151
        end
        fitness = min(1,abs(date_to_be_checked-date_ref) / (max_year_difference*365)); % [0..1]: 0 identical, 1 totally incompatible
    else
        fitness = 0.99; % [0..1]: missing date for comparison
    end
end
flg_incompatible = (fitness >= 1);

% check for birth\death sequence check
flg_sequence_check = 0;
if strcmp(event_tag,'nasc')
    date_first = ks_date_to_be_checked;
    date_after = str_search.mort;
    flg_sequence_check = 1;
elseif strcmp(event_tag,'mort')
    date_first = str_search.nasc;
    date_after = ks_date_to_be_checked;
    flg_sequence_check = 1;
end
if flg_sequence_check
    if ( ~isempty(date_first) && ~isempty(date_after) )
        date_first_num = datestr_to_datenum(date_first);
        date_after_num = datestr_to_datenum(date_after);
        
        if date_first_num>=date_after_num
            if debug
                fprintf(1,'\t\tDate incompatibility: %s is not before %s!!!\n',datestr(date_first_num),datestr(date_after_num))
            end
            flg_incompatible = 1; % total incompatibility!
            fitness = 1;
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_new = export_normalize_string(params,type)

% manage input params
par_struct = assert(params,{'ks','type'});
ks   = par_struct.ks;
type = par_struct.type;

ks_new = normalize_string(ks,type); % normalized place of the event



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function date_num = datestr_to_datenum(date_str)
% convert a string date into a Matlab date number

if regexp(date_str,'BET (.+) AND (.+)','once')
    z=regexp(date_str,'BET (.+) AND (.+)','tokens');
    date_start = z{1}{1};
    date_end   = z{1}{2};
    date_num = mean([datestr_to_datenum(date_start),datestr_to_datenum(date_end)]);
elseif regexp(date_str,'[0-9]{2,2} [A-Z]{3,3} [0-9]{4,4}')
    date_str = strrep(date_str,'ABT ','');
    date_str = strrep(date_str,'AFT ','');
    date_str = strrep(date_str,'BEF ','');
    try
    date_num = datenum(date_str);
    catch
        disp(date_str)
    end
elseif regexp(date_str,'[0-9]{2,2}/[0-9]{2,2}/[0-9]{4,4}')
    date_num = datenum(date_str,'dd/mm/yyyy');
elseif regexp(date_str,'[0-9]{4,4}')
    date_num = datenum(date_str,'yyyy');
else
    error(date_str)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = analyse_record(params)
% analyse record fields, normalizing their content and preparing to Gedcom
% format.
% id_record is a numeric id
%
% example of Gedcom format:
% gedcom_lines = {
%     '0 @I6769@ INDI'
%     
%     '1 NAME Francesco /Ceres/'
%     '2 GIVN Francesco'
%     '2 SURN Ceres'
%     
%     '1 SEX M'
%     
%     '1 BIRT'
%     '2 DATE 28 NOV 1857'
%     '2 PLAC Caposele, Avellino, Campania, ITA'
%     '2 SOUR @S16@'
%     '3 PAGE 1857: 188'
%     '3 DATA'
%     '4 TEXT registro nati anagrafe Caposele'
%     
%     '1 DEAT'
%     '2 DATE 08 DEC 1862'
%     '2 PLAC Caposele, Avellino, Campania, ITA'
%     '2 SOUR @S16@'
%     '3 PAGE 1862: 135'
%     '3 DATA'
%     '4 TEXT registro morti anagrafe Caposele'
%     
%     '1 FAMC @F746@'
%     
%     '1 FAMS @F1118@'
%     '1 FAMS @F372@'
%     
%     '1 CHAN'
%     '2 DATE 14 FEB 2012'
%     '3 TIME 00:19:55'
%     '2 _PGVU uploader'
%     };
%


result = struct();
err_code    = 0;
err_msg     = '';

% manage input params
par_struct = assert(params,{'str_archivio','id_record'});
str_archivio = par_struct.str_archivio;
id_record    = par_struct.id_record; % id of record from file to be uploaded    

ind_record = strmatch(num2str(id_record),str_archivio.archivio(:,1),'exact');
if isempty(ind_record)
    error('Record ''%d'' not found in the archive!',id_record)
end

record = str_archivio.archivio(ind_record,:);

i_cogn      = str_archivio.indici_arc.cogn;
i_nome      = str_archivio.indici_arc.nome;
i_nome_2    = str_archivio.indici_arc.nome_2;
i_nasc      = str_archivio.indici_arc.nasc;
i_matr      = str_archivio.indici_arc.matr;
i_mort      = str_archivio.indici_arc.mort;
i_int_nasc_a  = str_archivio.indici_arc.int_nasc_a;
i_int_matr_a  = str_archivio.indici_arc.int_matr_a;
i_int_mort_a  = str_archivio.indici_arc.int_mort_a;
i_nasc_Nr   = str_archivio.indici_arc.nasc_Nr;   % atto di nascita Num. (anagrafe)
i_matr_Nr   = str_archivio.indici_arc.matr_Nr;   % atto di matrimonio Num. (anagrafe)
i_mort_Nr   = str_archivio.indici_arc.mort_Nr;   % atto di morte Num. (anagrafe)
i_nasc_luo  = str_archivio.indici_arc.nasc_luo;  % luogo di nascita
%i_matr_luo  = str_archivio.indici_arc.matr_luo; % luogo di matrimonio (il campo non esiste nel file)
i_mort_luo  = str_archivio.indici_arc.mort_luo;  % luogo di morte
i_note      = str_archivio.indici_arc.note;      % note aggiuntive (es. matrimonio non a Caposele)

ks_cogn     = record{i_cogn};
ks_nome     = record{i_nome};
ks_nome2    = record{i_nome_2};
ks_nasc_    = record{i_nasc};
ks_matr_    = record{i_matr};
ks_mort_    = record{i_mort};
int_nasc_a  = record{i_int_nasc_a};
int_matr_a  = record{i_int_matr_a};
int_mort_a  = record{i_int_mort_a};
ks_nasc_Nr  = record{i_nasc_Nr};
ks_matr_Nr  = record{i_matr_Nr};
ks_mort_Nr  = record{i_mort_Nr};
ks_nasc_luo_= record{i_nasc_luo};
%ks_matr_luo_= record{i_matr_luo};
ks_mort_luo_= record{i_mort_luo};
ks_note     = record{i_note};

% prepare full name
[ks_givn ks_surn] = prepare_gedcom_name_fields(ks_cogn,ks_nome,ks_nome2);

% prepare sex ( 'M'; % 'M' or 'F', or empty if undefined)
sex = ged('determine_sex',ks_givn);

% prepare birth date ('06/01/1859' -->'06 JAN 1869')
if ~isempty(ks_nasc_)
    if regexp(ks_nasc_,'^[12][6789][0-9][0-9]$', 'once')
        % single year: add ABT
        ks_nasc = ['ABT ' ks_nasc_];
    else
        ks_nasc = upper(datestr(datestr_to_datenum(ks_nasc_),'dd mmm yyyy'));
    end
else
    ks_nasc = '';
end

% prepare marriage date ('06/01/1859' -->'06 JAN 1869')
if ~isempty(ks_matr_)
    if regexp(ks_matr_,'^[12][6789][0-9][0-9]$', 'once')
        % single year: add ABT
        ks_matr = ['ABT ' ks_matr_];
    else
        ks_matr = upper(datestr(datestr_to_datenum(ks_matr_),'dd mmm yyyy'));
    end
else
    ks_matr = '';
end

% prepare death date ('06/01/1859' --> '06 JAN 1869' or '1896' --> '1896')
if ~isempty(ks_mort_)
    if ~isempty(regexp(ks_mort_,'^[12][6789][0-9][0-9]$', 'once'))
        % only year
        ks_mort = ks_mort_;
    else
        % full date
        ks_mort = upper(datestr(datenum(ks_mort_,'dd/mm/yyyy'),'dd mmm yyyy'));
    end
else
    % no date
    ks_mort = '';
end

% prepare birth place ('CAPOSELE' -->'Caposele, Avellino, Campania, ITA')
if ~isempty(ks_nasc_luo_)
    ks_nasc_luo = normalize_string(ks_nasc_luo_,'PLAC');
else
    ks_nasc_luo = '';
end

% prepare marriage place ('CAPOSELE' -->'Caposele, Avellino, Campania, ITA')
if ~isempty(ks_matr_) && isempty(ks_note)
    ks_matr_luo = normalize_string(ks_matr_luo_,'PLAC');
else
    fprintf(1,'Lascio il lugo di matrimonio vuoto perché ci sono delle note. Verifica:\n\t%s\n',ks_note);
    ks_matr_luo = '';
end

% prepare death place ('CAPOSELE' -->'Caposele, Avellino, Campania, ITA')
if ~isempty(ks_mort_luo_)
    ks_mort_luo = normalize_string(ks_mort_luo_,'PLAC');
else
    ks_mort_luo = '';
end

% prepare chan date and time
ks_chan_date = upper(datestr(now,'dd mmm yyyy'));
ks_chan_time = upper(datestr(now,'HH:MM:SS'));
ks_chan_user = uploader_conf('pgv_username');


% source id associated to the archive (es. '@S16@')
ks_SID = uploader_conf('source_ged');


%
% prepare info struct
%
str_record_info = struct();
str_record_info.ks_givn = ks_givn;
str_record_info.ks_surn = ks_surn;
str_record_info.sex = sex;
str_record_info.ks_nasc = ks_nasc;
str_record_info.ks_nasc_luo = ks_nasc_luo;
str_record_info.ks_nasc_Nr = ks_nasc_Nr;
str_record_info.int_nasc_a = int_nasc_a;
str_record_info.ks_matr = ks_matr;
str_record_info.ks_matr_luo = ks_matr_luo;
str_record_info.ks_matr_Nr = ks_matr_Nr;
str_record_info.int_matr_a = int_matr_a;
str_record_info.ks_mort = ks_mort;
str_record_info.ks_mort_luo = ks_mort_luo;
str_record_info.ks_mort_Nr = ks_mort_Nr;
str_record_info.int_mort_a = int_mort_a;
str_record_info.ks_chan_date = ks_chan_date;
str_record_info.ks_chan_time = ks_chan_time;
str_record_info.ks_chan_user = ks_chan_user;
str_record_info.ks_SID = ks_SID;

result.err_code         = err_code;
result.err_msg          = err_msg;
result.str_record_info  = str_record_info;
