function SOAP_tester(password)
%
% PhpGedView SOAP api tester
%
% Usage:
% password = '<your_password>' % password for 'uploader' user
% clc,SOAP_tester(password),diary off
%


%
% init SOAP api via wsdl url
%

logfile = 'soap_logfile.txt';
diary off
if exist(logfile,'file')
    delete(logfile)
end
diary(logfile)

wsdl_url = 'http://ars.altervista.org/PhpGedView/genservice.php?wsdl';

service_name = createClassFromWsdl(wsdl_url);

service_folder = [pwd filesep '@' service_name]; % created SOAP mfile folder

z=dir([service_folder filesep '*.m']);
list_methods = {z.name}'; % available SOAP methods

class_instance = eval(service_name); % SOAP object

clc
display(class_instance)


%
% authentication
%

username = 'uploader';
%password = '<your password here>';
gedcom = 'caposele';
compression = 'none';
data_type = 'GEDCOM';

disp(sprintf('\nAuthenticating user %s..',username))
diary('off'),diary('on')
result_out = Authenticate(class_instance,username,password,gedcom,compression,data_type); % SOAP function handler created by createClassFromWsdl

SID = result_out.SID; % authentication session token
disp(sprintf('    ...got session ID %s..',SID))
diary('off'),diary('on')


%
% retrieve info on Person by ID
%

PID = 'I0000';

disp(sprintf('\nRetrieving existing data on %s first time..',PID))
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);

display(result_out);
display(result_out.gedcom(1:200));
diary('off'),diary('on')


PID = 'I0000';

disp(sprintf('\nRetrieving existing data on %s second time..',PID))
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);

display(result_out);
display(result_out.gedcom(1:200));
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

PID = 'I0000';

disp(sprintf('\nRetrieving existing data on %s with wrong SID..',PID))
diary('off'),diary('on')
try
    result_out = getPersonByID(class_instance,'WrongSid',PID);
    
    display(result_out);
    display(result_out.gedcom(1:300));
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off'),diary('on')


PID = 'ZZZZ9999';

disp(sprintf('\nRetrieving wrong data on %s..',PID))
diary('off'),diary('on')
try
    result_out = getPersonByID(class_instance,SID,PID);
    
    display(result_out);
    display(result_out.gedcom);
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off')


PID = 'I0000';

disp(sprintf('\nRetrieving existing data on %s third time..',PID))
diary('off'),diary('on')
result_out = getPersonByID(class_instance,SID,PID);

display(result_out);
display(result_out.gedcom(1:200));
diary('off'),diary('on')


%
% retrieve Family by ID
%

FID = 'F309';

disp(sprintf('\nRetrieving existing data on %s with FID..',FID))
diary('off'),diary('on')
try
    result_out = getFamilyByID(class_instance,SID,FID);
    
    display(result_out);
    display(result_out.gedcom(1:300));
catch
    ks = lasterr;
    fprintf(1,'*** Errore nell''esecuzione del comando: %s\n',ks)
end

diary('off'),diary('on')