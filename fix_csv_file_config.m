function result = fix_csv_file_config(action,params)

switch action
    case 'get_warn_exceptions'
        warn_type = params{1};
        exception_list = get_exception_list(warn_type);
        result = exception_list;
        
    otherwise
        error('Unknown action %s!',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function exception_list = get_exception_list(warn_type)
% exception_list must be a matrix array (or a vertical array) with the
% parameters for warning exception. The first column contains the ID for
% which the warning is being disabled

switch warn_type
        %%%
        %%% fix_csv_file.m warnings
        %%%
        case '7_swapped_dates_matrimonio'
        % ATTENTION! Possible swap in day\month columns: ID 26367: 06/05/1886 - 20/06/1886
        exception_list = {
            '26367' , '06/05/1886'  , '20/06/1886';
            '27869' , '07/06/1913'  , '28/06/1913';
            '28444' , '04/03/1880'  , '29/03/1880';
            '29766' , '20/06/1878'  , '06/12/1878';
            '30259' , '04/02/1882'  , '18/03/1882';
            '30378' , '04/03/1880'  , '29/03/1880';
            '36417' , '01/06/1875'  , '06/02/1875';
            '37938' , '06/05/1886'  , '20/06/1886';
            '39905' , '06/04/1919'  , '28/05/1919';
            '40407' , '11/12/1886'  , '18/11/1886';
            '40729' , '07/06/1913'  , '28/06/1913';
            '44026' , '12/11/1882'  , '13/12/1882';
            '44327' , '01/06/1875'  , '06/02/1875';
            '45728' , '08/07/1809'  , '30/07/1809';
            '46581' , '04/02/1882'  , '18/03/1882';
            '48379' , '12/11/1882'  , '13/12/1882';
            '48810' , '01/11/1920'  , '11/12/1920';
			'49333' , '01/02/1877'  , '15/01/1877';
            '49731' , '01/11/1920'  , '11/12/1920';           
			'49975' , '11/12/1886'  , '28/10/1886';
			'54844' , '22/12/1881'  , '12/11/1881';
            '56642' , '08/07/1809'  , '30/07/1809';
			'61056' , '11/12/1886'  , '28/10/1886';
			'61187' , '22/12/1881'  , '12/11/1881';
			'61727' , '11/12/1886'  , '18/11/1886';     
            '61758' , '20/06/1878'  , '06/12/1878';
			'61765' , '01/02/1877'  , '15/01/1877';
            
            '34471' , '07/08/1876'  , '20/07/1876';     % TODO: i matrimoni anagrafe 1876 non sono disponibili online
			'42332' , '12/10/1873'  , '27/11/1873';     % TODO: i matrimoni anagrafe 1873 non sono disponibili online
			'45588' , '12/10/1873'  , '27/11/1873';     % TODO: i matrimoni anagrafe 1873 non sono disponibili online
            }; % at least one column, even if without rows
        
    case '7_wrong_format_matrimonio'
        % Not all dates are in the dd/mm/yyyy format! (ID 29002)
        exception_list = {
            '29002' , '20/04/1885'  , '1881';
            '32142' , '20/04/1885'	, '1881';
            }; % at least one column, even if without rows
        
        
    case '7_great_delta_matrimonio'
        % ????? Unmanaged: ID 42777: "11/06/1870" <--> "05/06/1870"
        exception_list = {
            '42777' , '11/06/1870'  , '05/06/1870';
            }; % at least one column, even if without rows
        
    case '7_great_delta_morte'
        % ????? Unmanaged: ID 43063: "00/08/1904" <--> "26/08/1904"
        exception_list = {
            '43063' , '00/08/1904'  , '26/08/1904';     % la registrazione dello stato civile è rovinata e non si legge il giorno
            }; % at least one column, even if without rows
    
        
        
    %%%
    %%% ged.m warnings    
    %%%
    case 'ged2_day_month_year_incoherence_mort'   
        % err.2: giorno-mese-anno (26-08-1904->1904.6505) non coerenti con la data nel campo mort: 00/08/1904 (1904.5806)
        exception_list = {
            '43063' , '00/08/1904';     % certificato di morte non leggibile, sostituito dal sw con data sepoltura
            }; % at least one column, even if without rows     
        
    case 'ged2_wrong_date_format_nasc'   
        % err.2: formato data errata nel campo nasc: 00/08/1875
        exception_list = {
            '60844' , '00/08/1875';     % atto di nascita a Valva
            }; % at least one column, even if without rows     
        
    case 'ged2_wrong_date_format_matr'   
        % err.2: formato data errata nel campo matr: 00/02/1797
        exception_list = {
            '28706' , '00/02/1797';     % nella registrazione religiosa (ribaltata sul civile dal sw) manca deliberatamente il giorno
            '56257' , '00/02/1797';     % nella registrazione religiosa (ribaltata sul civile dal sw) manca deliberatamente il giorno
            }; % at least one column, even if without rows     
        
    case 'ged2_wrong_date_format_matr_rel'   
        % err.2: formato data errata nel campo matr_rel: 00/02/1797
        exception_list = {
            '28706' , '00/02/1797';     % nella registrazione religiosa manca deliberatamente il giorno
            '56257' , '00/02/1797';     % nella registrazione religiosa manca deliberatamente il giorno
            '40112' , '00/08/1878';     % nella registrazione religiosa manca deliberatamente il giorno
            '48315' , '00/08/1878';     % nella registrazione religiosa manca deliberatamente il giorno
            }; % at least one column, even if without rows  
                
    case 'ged2_wrong_date_format_mort'
        % err.2: formato data errata nel campo mort: 00/00/1897
        exception_list = {
            '28324' , '00/00/1897';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '28831' , '00/04/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '29417' , '00/11/1959';     % i certificati di morte US online talvolta non indicano il giorno
            '31183' , '00/11/1955';     % i certificati di morte US online talvolta non indicano il giorno
            '31986' , '00/10/1903';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '32010' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '38289' , '00/10/1903';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '40011' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '40261' , '00/12/1972';     % il giorno non è noto
            '40884' , '00/00/1877';     % atto di morte difficile da decifrare
            '42196' , '00/02/1975';     % i certificati di morte US online talvolta non indicano il giorno
            '43063' , '00/08/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '46130' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '46780' , '00/11/1987';     % i certificati di morte US online talvolta non indicano il giorno
            '46825' , '00/06/1971';     % il giorno non è noto
            '47022' , '00/12/1966';     % i certificati di morte US online talvolta non indicano il giorno
            '47930' , '00/05/1935';     % i certificati di morte US online talvolta non indicano il giorno
            '56662' , '00/10/1903';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57255' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '57342' , '00/04/1904';     % il giorno non è noto
            '57363' , '00/07/1903';     % la registrazione dello stato civile è rovinata e non si legge giorno           
            '57425' , '00/07/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57440' , '00/05/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57474' , '00/07/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57488' , '00/10/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57527' , '00/10/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57533' , '00/04/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57564' , '00/11/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57577' , '00/03/1977';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '57578' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '57596' , '00/00/1904';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            '59993' , '00/07/1973';     % la registrazione dello stato civile è rovinata e non si legge giorno
            '61027' , '00/00/1898';     % solo indice annuale
            '61028' , '00/00/1898';     % solo indice annuale
            '61029' , '00/00/1898';     % solo indice annuale
            '61030' , '00/00/1898';     % solo indice annuale
            '61031' , '00/00/1898';     % solo indice annuale
            '61032' , '00/00/1898';     % solo indice annuale
            '61033' , '00/00/1898';     % solo indice annuale
            '61034' , '00/00/1898';     % solo indice annuale
            '61035' , '00/00/1898';     % solo indice annuale
            '61036' , '00/00/1898';     % solo indice annuale
            '61775' , '00/00/1897';     % la registrazione dello stato civile è rovinata e non si legge giorno e mese
            }; % at least one column, even if without rows     
        
    case 'ged3_wrong_numeric_format'   
        % err.3: formato numerico errato nel campo mort_Nr: 621
        exception_list = {
            '38347' , 'matr_Nr'    , '993';     % corretto: il valore è un numero progressivo dello stato civile Caposele (doc allegato nel registro nascite)
            '29192' , 'mort_Nr'    , '621';     % corretto: a Salerno ci sono molti atti di morte ogni anno
            '29394' , 'mort_Nr'    , '642';     % corretto: a Salerno ci sono molti atti di morte ogni anno
            '32362' , 'mort_Nr'    , '1123';    % corretto: a Roma ci sono molti atti di morte ogni anno
            '59294' , 'mort_Nr'    , '352';     % corretto: a Lioni ci sono molti atti di morte ogni anno
            '61894' , 'mort_Nr'    , '1001';    % corretto: a Napoli ci sono molti atti di morte ogni anno
            }; % at least one column, even if without rows  
        
    case 'ged4_birth_marr_death_incoherence'   
        % err.4: date incoerenti (B:13/04/1904 M: D:00/04/1904)
        exception_list = {
            '32153' , '29/01/1809' , '*'          , '28/01/1809';     % PROBABILE ERRORE DI UN GIORNO NELLA DATA DI NASCITA, SIA STATO CIVILE CHE BATTESIMO - LA DATA DI MORTE DEI GEMELLI E' CORRETTA SULLA BASE DELLE ALTRE REGISTRAZIONI
            '36055' , '13/11/1878' , '*'          , '10/11/1878';     % LE DATE DI NASCITA E MORTE SONO QUELLE ESATTE RIPORTATE NEGLI ATTI, MA SONO INCOERENTI TRA LORO
            '37975' , '04/10/1851' , '*'          , '29/09/1851';     % ERRORE TRA LE DATE DI NASCITA E DI MORTE, LE DATE SONO CORRETTE IN BASE AGLI ATTI DI NASCITA E DI MORTE
            '44393' , '05/03/1844' , '*'          , '04/03/1844';     % DATA DI MORTE ERRATA
            '51532' , '*'          , '14/02/1914' , '24/07/1897';     % L'ATTO DI MORTE E' RELATIVO A LEI, MA NON PUO' ESSERE PERCHE' SI SPOSO' NEL 1914 - NELL'ATTO DI MORTE CIVILE SI INDICA UN'ETA' DI 6 ANNI, IN QUELLO RELIGIOSO DI 10 MESI
            '52516' , '1749'       , '04/12/1757' , '*'         ;     % ANNO DI NASCITA DEDOTTA DA ETA' IN ATTO DI MORTE (40), MA DA ANTICIPARE VISTO ANNO DI MATRIMONIO
            '52621' , '1744'       , '16/06/1753' , '*'         ;     % ANNO DI NASCITA DEDOTTA DA ETA' IN ATTO DI MORTE (46), MA DA ANTICIPARE VISTO ANNO DI MATRIMONIO
            '53251' , '1742'       , '17/01/1750' , '*'         ;     % ANNO DI NASCITA DEDOTTA DA ETA' IN ATTO DI MORTE (60), MA DA ANTICIPARE VISTO ANNO DI MATRIMONIO
            '53579' , '1746'       , '09/02/1751' , '*'         ;     % ANNO DI NASCITA DEDOTTA DA ETA' IN ATTO DI MORTE (60), MA DA ANTICIPARE VISTO ANNO DI MATRIMONIO
            '53451' , '1744'       , '24/05/1751' , '*'         ;     % ANNO DI NASCITA DEDOTTA DA ETA' IN ATTO DI MORTE (50), MA DA ANTICIPARE VISTO ANNO DI MATRIMONIO
            '56857' , '28/03/1809' , '*'          , '27/03/1809';     % ERRORE TRA LE DATE DI NASCITA E DI MORTE, LE DATE SONO CORRETTE IN BASE AGLI ATTI DI NASCITA E DI MORTE
            }; % at least one column, even if without rows  
        
        
        
    otherwise
        %%%
        %%% dummy warn types (default is enable all)
        %%%
        exception_list = repmat({''},0,1); % at least one column, even if without rows
end
