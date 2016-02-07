function SOAP_tester(wsdl_url,password)
%
% PhpGedView SOAP api tester
%
% Usage:
% password = '<your_password>' % password for 'uploader' user
% wsdl_url = '<wsdl url>'
% clc,SOAP_tester(wsdl_url,password),diary off
%


%
% init SOAP api via wsdl url
%

flgRegenerateClass = 0; % 1 --> recreate the method files in the hidden @GenealogyService folder; 0 --> just try to use the xisting files

logfile = 'soap_logfile.txt';
diary off
if exist(logfile,'file')
    delete(logfile)
end
diary(logfile)

if flgRegenerateClass
    service_name = createClassFromWsdl(wsdl_url); %#ok<UNRCH>
else
    service_name = 'GenealogyService';
end

service_folder = [pwd filesep '@' service_name]; % created SOAP mfile folder

class_instance = eval(service_name); % SOAP object

clc
display(class_instance)

% available SOAP methods
z=dir([service_folder filesep '*.m']);
list_methods = {z.name}'; 
fprintf(1,'\nAvailable methods:\n')
for i_method=1:length(list_methods)
    ks=[sprintf('\t') list_methods{i_method}(1:end-2)];
    disp(ks);
end
disp(' ');


%
% authentication
%

username = 'uploader';
%password = '<your password here>'; ATTENTION! If the wrong password is inserted, an out of memory message will be returned
gedcom = 'caposele';
compression = 'none';
data_type = 'GEDCOM';

fprintf(1,'\nAuthenticating user %s (Authenticate)..\n',username)
diary('off'),diary('on')
result_out = Authenticate(class_instance,username,password,gedcom,compression,data_type); % SOAP function handler created by createClassFromWsdl

SID = result_out.SID; % authentication session token
fprintf(1,'    ...got session ID %s..\n',SID)
diary('off'),diary('on')


%
% retrieve info on ID of last individual in the gedcom
%

position    = 'last';
type        = 'INDI';

fprintf(1,'\nRetrieving %s xref for %s (getXref)..\n',position,type)
diary('off'),diary('on')
result_out = getXref(class_instance,SID,position,type);

PID_last = result_out;
fprintf(1,'    ...last ID is %s..\n',PID_last)
diary('off'),diary('on')



%
% retrieve info on individual ID's in the gedcom
%

position    = 'all';
type        = 'INDI';

fprintf(1,'\nRetrieving %s xref for %s (getXref)..\n',position,type)
diary('off'),diary('on')
list_PID = getXref(class_instance,SID,position,type);
fprintf(1,'    ...got %d ID''s..\n',length(list_PID))

ind = ceil(length(list_PID)*rand);
PID = list_PID{ind}; % pick a random PID
fprintf(1,'    ...picking ID %s..\n',PID)
diary('off'),diary('on')



%
% retrieve info on Person by ID
%

%PID = 'I0000';

fprintf(1,'\nRetrieving existing data on %s first time..\n',PID)
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);
len = min(200,length(result_out.gedcom));

display(result_out);
display(result_out.gedcom(1:len));
diary('off'),diary('on')


% PID = 'I0000';

fprintf(1,'\nRetrieving existing data on %s second time..\n',PID)
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);
len = min(200,length(result_out.gedcom));

display(result_out);
display(result_out.gedcom(1:len));
diary('off'),diary('on')


%
% search
%

query = 'NAME=Maria Luigia Tremante&BIRTHDATE=1868'; % Keywords: NAME, BIRTHDATE, DEATHDATE, BIRTHPLACE, DEATHPLACE, GENDER
start = 0; % zero-based index!
maxResults = 10;

fprintf(1,'\nSearching person %s..\n',query)
diary('off'),diary('on')
try
    result_out = search(class_instance,SID,query,start,maxResults);
    
    persons=result_out.persons;for i=1:length(persons),p=persons(i);fprintf(1,'%03d) %40s %20s %20s\n',i,p.gedcomName,p.birthDate,p.deathDate);end
catch me
    ks = me.message;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end
diary('off'),diary('on')


%
% retrieve info on Person by ID (with wrong PID)
%

% PID = 'I0000';

fprintf(1,'\nRetrieving existing data on %s with wrong SID..\n',PID)
diary('off'),diary('on')
try
    result_out = getPersonByID(class_instance,'WrongSid',PID);
    len = min(300,length(result_out.gedcom));
    
    display(result_out);
    display(result_out.gedcom(1:len));
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off'),diary('on')


PID_bad = 'ZZZZ9999';

fprintf(1,'\nRetrieving wrong data on %s..\n',PID_bad)
diary('off'),diary('on')
try
    result_out = getPersonByID(class_instance,SID,PID_bad);
    
    display(result_out);
    display(result_out.gedcom);
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off')


% PID = 'I0000';

fprintf(1,'\nRetrieving existing data on %s third time..\n',PID)
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);
len = min(200,length(result_out.gedcom));

display(result_out);
display(result_out.gedcom(1:len));
diary('off'),diary('on')


%
% retrieve Family by ID
%

FID = 'F309';

fprintf(1,'\nRetrieving existing data on %s with FID..\n',FID)
diary('off'),diary('on')
try
    result_out = getFamilyByID(class_instance,SID,FID);
    len = min(300,length(result_out.gedcom));
    
    display(result_out);
    display(result_out.gedcom(1:len));
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off'),diary('on')
