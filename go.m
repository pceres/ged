% implicit input:
%   verbose: 1 -> check loaded data; 0 -> fast load

global buf_indici
% struct with link between header and column position, used inside ged.m functions
% buf_indici = str_archivio.indici_arc, with str_archivio saved inside temp_workspace

if (~exist('verbose','var'))
    verbose = 0; % default is fast load
end

tic

filename = 'file9_data.csv'; % file csv con i dati genealogici in forma tabellare

flg_load = 1;
if (~verbose && exist('temp_workspace.mat','file'))
    str=load('temp_workspace');
    
    if isfield(str,'str_archivio')
        str_archivio = str.str_archivio;
        z1 = dir(str_archivio.filename);    % current file data
        z2 = str_archivio.filedata;         % saved file data
        flg_load = ~isequal(z1,z2) || verbose;         % must reload file, if it changed compared to the saved one
        
        clear z1 z2
    end
    
    clear str
end

if flg_load
    disp(['read_csv : ' filename])
    result = ged('read_csv',filename);
    if ~result.status
        error('Errore di lettura')
    end
    tabella  = result.tabella;
    info     = result.info;


    disp('crea_archivio')
    result = ged('table2archive',info.header,tabella); % this also populates buf_indici global variable
    if ~result.status
        error('Errore di lettura')
    end
    archivio = result.archivio;
    liste    = result.liste;
    indici_arc = result.indici;

    str_archivio.archivio   = archivio;
    str_archivio.indici_arc = indici_arc;
    str_archivio.filename   = filename;
    str_archivio.filedata   = dir(filename);

    verbose = 1; % file changed, must re-check
    
    toc
    
    save('temp_workspace','str_archivio','-v6');
else
    
    buf_indici = str_archivio.indici_arc; % populates buf_indici as a global variable to be used in ged scripts
    
    disp('Parsing inutile, carico dal mat')
end

clear flg_load


if (verbose)
    disp('check')
    
    archivio = str_archivio.archivio;
    result = ged('check',archivio);
    if ~result.status
        error('Errore nel check')
    end
    archivio_ok = result.archivio_ok;
    report      = result.report;
    
    disp('show_items')
    result = ged('show_items',report);

    if (~isequalwithequalnans(archivio,archivio_ok))
        archivio = archivio_ok;

        filename_out = [filename '.ok'];
        disp(['write_csv : ' filename_out])
        result = ged('write_archive',info.header,archivio,filename_out,info.new_line);
        if ~result.status
            error('Errore di scrittura')
        end
    end
    clear archivio_ok;

    % grafici
    list={'int_nasc_num','int_matr_num','int_mort_num'};

    for i=1:length(list)
        tag=list{i};
        y=liste.(tag);
        x = floor(min(y)/25)*25+1:ceil(max(y)/25)*25; % definisci range x basandosi sugli anni disponibili
        y2=histc(y,x);
        analisi.anni = x;

        analisi.(tag) = y2;
        figure(i)
        bar(x,y2)
        title(list{i},'interpreter','none')
        xlabel('anni')
        ylabel('numero persone')
        grid on
    end
else
    disp('set verbose=1 for full check and analysis')
end
