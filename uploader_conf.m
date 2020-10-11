function result = uploader_conf(tag)

switch tag
    case 'search_threshold'
        % Used by uploader_browse in ged->find_person.
        % Threshold [0..1] used to discriminate good matches from bad ones
        % eg.: 0.75
        result = 0.15;

    case 'search_name_filter_out'
        % Used by query_ged.
        % Cell array of subnames (with space as separator) to be dropped as 
        % too common to avoid false matches. Result is the format of the
        % regexprep: name_out = regexprep(name_in,format,'').
        % eg.: MARIA has to be filtered, to avoid the following false
        %      match:
        %      GIUSEPPE ANTONIO MARIA matched by DOMENICA MARIA!!!
        result = ' (MARIA|JUNIOR)$';

    case 'list_conversion_table.PLAC'
        % Used by normalize_string.
        % Takes a string, and returns the canonical form of the place, if matching
        % eg.: 'Caposele' --> 'Caposele, Avellino, Campania, ITA'
        result = {
            'BLOOMFIELD'            , 'Bloomfield, Essex, New Jersey, USA';
            'BUCCINO'               , 'Buccino, Salerno, Campania, ITA';
            'CALABRITTO'            , 'Calabritto, Avellino, Campania, ITA';
            'CAP[OU]S[S]?EL[AE]'    , 'Caposele, Avellino, Campania, ITA';  % for Caposele, Capussela, Capossela
            'FRANCIA'               , 'Francia';
            'LIONI'                 , 'Lioni, Avellino, Campania, ITA';
            'MORRA IRPIN[AO]'       , 'Morra De Sanctis, Avellino, Campania, ITA';
            'NEWARK'                , 'Newark, Essex, New Jersey, USA';
            'NAPOLI'                , 'Napoli, Napoli, Campania, ITA';
            'NEW YORK'              , 'New York, New York, New York, USA';
            'NOCERA( INFERIORE)?'   , 'Nocera Inferiore, Salerno, Campania, ITA';
            '(F|PH)ILIPPE[R]?VILLE' , 'Philippeville, Skikda, Skikda, DZA';
            'SALERNO'               , 'Salerno, Salerno, Campania, ITA';
            'SOMMA VESUVIANA'       , 'Somma Vesuviana, Napoli, Campania, ITA';
            'UDINE'                 , 'Udine, Udine, Friuli Venezia Giulia, ITA';
            'TEORA'                 , 'Teora, Avellino, Campania, ITA';
            };

    case 'list_conversion_table.pgvu'
        % Used by normalize_string
        % Takes a pgvu user, and returns the corresponding source
        % eg.: 'alex' --> 'S18'
        result = {
            'nick'              , 'S13';
            'angelo.ceres'      , 'S19';
            'JohnR'             , 'S28';
            'Sturchio'          , 'S29';
            'alex'              , 'S40';
            'tobie02'           , 'S48';
            'archinesta'        , 'S71';
            'antmat'            , 'S72';
            'jep040'            , 'S73';
            'kcapadona'         , 'S74';
            'tomem'             , 'S76';
            'JJOC1414'          , 'S89';
            'william.larezza'   , 'S103';
            };
        
    case 'list_conversion_table.src_txt'
        % Used by normalize_string
        % Takes a gedcom event, and returns the corresponding description
        % text to be added to the source field in the gedcom
        % eg.: 'BIRT' --> 'registro nati anagrafe Caposele'
        result = {
        'BIRT'  , 'registro nati anagrafe Caposele';
        'MARR'  , 'registro matrimoni anagrafe Caposele';
        'DEAT'  , 'registro morti anagrafe Caposele';
        };

    case 'list_filtered_CHAN_user'
        % Used by save_last_changed.
        % List of users that won't generate a source field
        result = {'ceres','uploader'};
        
    case 'source_ged'
        % Used by update
        % Id of the pgv source associated to the flat archive,
        % that will be associated to uploaded gedcoms (es. '@S16@')
        result = '@S16@';

    case 'pgv_username'
        % Used by 
        % Username to login on PhpGedView site via SOAP interface
        result = '<your_login>';
        
    case 'pgv_password'
        % Used by 
        % Password to login on PhpGedView site via SOAP interface
        result = '<your_password>';
        
    case 'pgv_gedcom'
        % Used by 
        % Name of the gedcom to be updated on the pgv site
        result = '<your_gedcom>';
        
    case 'default_place'
        % Used by record2msg
        % Default place (regexp format). In case of different place, it
        % will be shown
        result = '<your_default_place>';
        
    otherwise
        error('Unknown uploader configuration tag "%s"',tag)
end
