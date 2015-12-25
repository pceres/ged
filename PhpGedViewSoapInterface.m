
%***************************************************************************************************
%
% SCRIPT   : PhpGedViewSoapInterface.m
% AUTHOR   : Pasquale CERES (pasquale.ceres@fptpowertrain.crf.it)
% VERSION  : $Id$
% COMMIT   : $Hash$
%
%***************************************************************************************************
%
% Interfaccia Soap con il sito PhpGedView
%
% result = PhpGedViewSoapInterface(action,params)
%
% Input:
%   action   : action to perform:
%               'init_class': init the wsdl class
%                             params = {wsdl_url,flg_force};
%                   wsdl_url  : url of the wsdl for pgv site
%                   flg_force : 1 -> force wsdl parsing; 0 -> use previous
%                               SOAP class, if found
%                             returns a struct result_init with fields
%                               class_instance : class instance for the pgv
%                               soap api
%
%               'serviceInfo': get an info struct about the SOAP server,
%                              with following fields:
%                   compression: {'none','zlib','zip'}
%                    apiVersion: es. '1.1'
%                        server: es. 'webtrees 1.0.4' or 'PhpGedView 4.3.0 svn'
%                       gedcoms: struct with awailable gedcom file managed
%                                by the pgv site (with fields title (es.
%                                'Genealogy from [caposele]') and ID (es.
%                                'caposele')
%
%               'Authenticate': authenticate on the pgv site
%                             params = {class_instance,username,password,gedcom,compression,data_type};
%                   class_instance  : field of the struct returnet by init_class action
%                   username        : username to authenticate on pgv site
%                   password        : password to authenticate on pgv site
%                   gedcom          : name of the gedcom file to be used on pgv site
%                   compression     : not implemented (es. 'none')
%                   data_type       : {'GEDCOM','GRAMPS'} type of data returned
%
%                               returns a struct with fields 
%                                   SID: session id to be used for next
%                                        queries as an aauthenticated user
%
%               'getPersonByID': get info about a specific person in the
%                                pgv gedcom
%                               params = {class_instance,SID,PID}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   PID             : person gedcom id whose data must be retrieved
%                               Returns a struct with several info fields, among
%                               which:
%                                   PID     : person gedcom id whose data was retrieved
%                                   gedcom  : gedcom data of the requested person
%     
%               'getFamilyByID': get info about a specific family in the
%                                pgv gedcom
%                               params = {class_instance,SID,FID}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   FID             : family gedcom id whose data must be retrieved
%                               Returns a struct with several info fields, among
%                               which:
%                                   FID     : family gedcom id whose data was retrieved
%                                   gedcom  : gedcom data of the requested
%                                   family
%
%               'updateRecord': update a gedcom on pgv site
%                               params = {class_instance,SID,RID,gedcom}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   RID             : gedcom id whose data must be updated
%                                     (person or family)
%                   gedcom          : multiline string (\n separated) with
%                                     new gedcom data
%
%               'getXref': get the Xref (eg. I6972 for INDI, F1234 for FAM)
%                               params = {class_instance,SID,position,type}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   position        : Xref required ['first','last','next','prev','all','new'] 
%                                     (only new seems to work)
%                   type            : type of Xref ['INDI', 'FAM', 'SOUR', 'REPO',
%                                       'NOTE', 'OBJE', 'OTHER']
%
%               'appendRecord': append a gedcom on pgv site
%                               params = {class_instance,SID,gedcom}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   gedcom          : multiline string (\n separated) with
%                                     new gedcom data
%
%               'search': search gedcom on pgv site
%                               params = {class_instance,SID,query,start,maxResults}
%                   class_instance  : field of the struct returnet by init_class action
%                   SID             : session id
%                   query           : query string
%                   start           : start index in the result list (0-based)
%                   maxResults      : max number of result to show
%
%
% es.:
%
% flg_force = 0;
% wsdl_url  = 'http://localhost/work/PhpGedView/genservice.php?wsdl';
% result_init = PhpGedViewSoapInterface('init_class',{wsdl_url,flg_force}); class_instance = result_init.class_instance
% result      = PhpGedViewSoapInterface('serviceInfo',{class_instance}); info = result
% pgv_username = uploader_conf('pgv_username'); % username used for authentication on the pgv site
% pgv_password = uploader_conf('pgv_password'); % password used for authentication on the pgv site
% result      = PhpGedViewSoapInterface('Authenticate',{class_instance,pgv_username,pgv_password,'caposele','none','GEDCOM'}); SID = result.SID
% result      = PhpGedViewSoapInterface('getPersonByID',{class_instance,SID,'I0000'}); person = result.result_out,gedcom=person.gedcom
% result      = PhpGedViewSoapInterface('getFamilyByID',{class_instance,SID,'F0000'}); family = result.result_out
% gedcom_new = strrep(gedcom,'2 _PGVU ceres','2 _PGVU uploader');
% result      = PhpGedViewSoapInterface('updateRecord',{class_instance,SID,'I0000',gedcom_new}); msg = result.result_out
% result      = PhpGedViewSoapInterface('getXref',{class_instance,SID,'new','INDI'}); msg = result.result_out
% result      = PhpGedViewSoapInterface('appendRecord',{class_instance,SID,strrep(gedcom_new,'0 @I0000@ INDI','0 @I7@ INDI')}); msg = result.result_out
% result      = PhpGedViewSoapInterface('search',{class_instance,SID,'Turri',0,10}); list = result.result_out.persons
% 

function result = PhpGedViewSoapInterface(action,params)

result = struct();
err_code = 0;
err_msg  = '';

fmt_network_error = '(Unknown host:|Network is unreachable)'; % regexp format to detect a network connectivity error

switch action
    case 'init_class'
        par_struct = assert(params,{'wsdl_url','flg_force'});

        wsdl_url    = par_struct.wsdl_url;    % wsdl web page
        flg_force   = par_struct.flg_force;   % force wsdl reload
        
        z=dir('@*');
        if ( (length(z) == 1) && ~flg_force )
            service_name    = z(1).name(2:end);
            service_folder = [pwd filesep '@' service_name];
            msg = 'class already exists';
        else
            try
                service_name = createClassFromWsdl(wsdl_url);
                service_folder = [pwd filesep '@' service_name];
                msg = 'class initialised';
            catch me
                ks_err = me.message;
                if regexp(ks_err,fmt_network_error)
                    err_code = 1;
                    err_msg  = 'No connectivity';
                else
                    err_code = 2;
                    err_msg  = ks_err;
                end
            end
        end
        
        if (~err_code)
            z=dir([service_folder filesep '*.m']);
            list_methods = {z.name}';

            class_instance = eval(service_name);

            result.msg = msg;
            result.service_name   = service_name;
            result.service_folder = service_folder;
            result.list_methods   = list_methods;
            result.class_instance = class_instance;
        end

    case 'serviceInfo'
        
        par_struct = assert(params,{'class_instance'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        
        result = serviceInfo(class_instance);
        
    case 'Authenticate'
        
        par_struct = assert(params,{'class_instance','username','password','gedcom','compression','data_type'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        username        = par_struct.username;          % username per il login al sito PhpGedView
        password        = par_struct.password;          % password per il login al sito PhpGedView
        gedcom          = par_struct.gedcom;            % gedcom da utilizzare
        compression     = par_struct.compression;       % tipo di compressione (es. 'none')
        data_type       = par_struct.data_type;         % tipo di dati (es. 'none')
        
        result_out = [];
        SID        = '';

        try
            result_info = serviceInfo(class_instance);

            if isempty(regexp(result_info.server,'webtrees','once'))
                result_out = Authenticate(class_instance,username,password,gedcom,compression,data_type);
            else
                % webtrees doesn't use the data_type info
                result_out = Authenticate(class_instance,username,password,gedcom,compression);
            end
            SID = result_out.SID;
            
        catch me
            ks_err = me.message;
            if regexp(ks_err,fmt_network_error)
                err_code = 1;
                err_msg  = 'No connectivity';
            else
                rethrow(ks_err)
            end
        end
        
        result.result_out   = result_out;
        result.SID          = SID;
         
    case 'getPersonByID'
        
        par_struct = assert(params,{'class_instance','SID','PID'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        PID             = par_struct.PID;               % gedcom person ID

        if isempty(PID)
            disp('*** ATTENTION!!! PID is empty for action getPersonByID!')
        end

        try
            % disp(sprintf('%s: %s, %s',action,SID,PID));
            result_out = getPersonByID(class_instance,SID,PID);
        catch me
            ks_err  = me.message;

            if regexp(ks_err,fmt_network_error)

            else
                rethrow(me)
            end
        end
        
        result.result_out   = result_out;
         
    case 'getFamilyByID'
        
        par_struct = assert(params,{'class_instance','SID','FID'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        FID             = par_struct.FID;               % gedcom family ID

        % disp(sprintf('%s: %s, %s',action,SID,FID));

        try
            result_out = getFamilyByID(class_instance,SID,FID);
        catch me
            ks_err = me.message;
            if regexp(ks_err,fmt_network_error)
                result_out = struct();
                err_code = 1;
                err_msg  = 'No connectivity';
            else
                rethrow(me)
            end
        end

        result.result_out   = result_out;

    case 'updateRecord'
        
        par_struct = assert(params,{'class_instance','SID','RID','gedcom'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        RID             = par_struct.RID;               % gedcom record ID
        gedcom          = par_struct.gedcom;            % gedcom to upload

        result_out = updateRecord(class_instance,SID,RID,gedcom);
        
        result.result_out   = result_out;

    case 'getXref'
        
        par_struct = assert(params,{'class_instance','SID','position','type'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        position        = par_struct.position;          % position of required Xref ['first','last','next','prev','all','new'] (only new seems to work)
        type            = par_struct.type;              % type of Xref ['INDI', 'FAM', 'SOUR', 'REPO', 'NOTE', 'OBJE', 'OTHER']

        result_out = getXref(class_instance,SID,position,type);
        
        result.result_out   = result_out;

    case 'appendRecord'
        
        par_struct = assert(params,{'class_instance','SID','gedcom'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        gedcom          = par_struct.gedcom;            % gedcom to create

        result_out = appendRecord(class_instance,SID,gedcom);
        
        result.result_out   = result_out;

    case 'search'
        
        par_struct = assert(params,{'class_instance','SID','query','start','maxResults'});

        class_instance  = par_struct.class_instance;    % instanza della classe Soap
        SID             = par_struct.SID;               % authentication session ID
        query           = par_struct.query;             % query string
        start           = par_struct.start;             % start in the result list
        maxResults      = par_struct.maxResults;         % max Result to show

        result_out = search(class_instance,SID,query,start,maxResults);
        
        result.result_out   = result_out;
         
    otherwise
        error('Unknown action %s!',action)
end

result.err_code = err_code;
result.err_msg  = err_msg;



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

