function result = LDS_downloader(varargin)
%
% result = LDS_downloader;
%
% LDS_downloader('LDS_checker');
%
%
% result = LDS_downloader;
%     Prepare iMacros script z_LDS_downloader so as to open the thumbnail
%     view for the desired microfilm. Open Firefox and leave it focused,
%     then launch LDS_downloader.


folder_download = '/home/ceres/Downloads/'; % folder for downloads
filename_download = [folder_download 'record-image_undefined.jpg']; % name of the downloaded image
folder_archive  = '/home/ceres/LDS_images/';

matr_films = {};

% %
% % Caposele
% %

% matr_films(end+1,:) = {
%     'Caposele Nati 1866-1879'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32045-11085-89?cc=2043434&wc=MM1H-FLZ:1251545493'
%     1315
%     [0.57 0.33]
%     'imgA%07d.jpg'
%     };
% matr_films(end+1,:) = {
%     'Caposele Nati 1880-1910 Pubblicazioni 1866-1884'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32041-22763-90?cc=2043434&wc=MM1H-FLX:n1296023061'
%     3026
%     [0.69 0.33]
%     'imgB%07d.jpg'
%     };
% matr_films(end+1,:) = {
%     'Caposele Morti 1900-1910 Cittadinanze 1866-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32043-20588-19?cc=2043434&wc=MM1H-FL4:1483281623'
%     436
%     [0.69 0.33]
%     'imgC%07d.jpg'
%     };
% matr_films(end+1,:) = {
%     'Caposele Pubblicazioni 1885-1910 M...1866-1910 Morti 1866-1900'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32044-2091-59?cc=2043434&wc=MM1H-FLJ:n592451706'
%     3014
%     [0.77 0.33]
%     'imgD%07d.jpg'
%     };
% matr_films(end+1,:) = {
%     'Diversi volumi annuali di Caposele ed altri comuni'
%     'https://www.familysearch.org/search/film/007068430?cat=409650' % LDS #1743729 item 2, start from #1346 to #1407
%     1727
%     [0.06 0.34]
%     'imgE%07d.jpg'
%     };
matr_films(end+1,:) = {
    'Pubblicazioni 1876'
    'https://www.familysearch.org/search/film/007068214?cat=409650' % LDS #1742992 item 4, start from #153
    2807
    [0.06 0.34]
    'imgF%07d.jpg'
    };

% %
% % Teora
% %

% matr_films(end+1,:) = {
%     'Teora Matrimoni 1909-1910 Morti 1866-1910 Cittadinanze 1866-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32043-13856-63?cc=2043434&wc=MM1H-FP4:n951119582'
%     1108
%     [0.76 0.33]
%     'imgTeoraA%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Teora Nati 1898-1910 Pubblicazioni 1866-1910 Matrimoni 1866-1908'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32028-22537-22?cc=2043434&wc=MM1H-FPD:n1283538601'
%     2882
%     [0.76 0.33]
%     'imgTeoraB%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Teora Nati 1866-1897'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32042-5822-74?cc=2043434&wc=MM1H-FPC:995367139'
%     2955
%     [0.55 0.33]
%     'imgTeoraC%07d.jpg'
%     };


% %
% % Calabritto
% %

% matr_films(end+1,:) = {
%     'Calabritto Morti 1878, 1904'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32045-25003-71?cc=2043434&wc=MM1H-FLM:1545101525'
%     70
%     [0.57 0.33]
%     'imgCalabrittoA%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calabritto Pubblicazioni 1872-1910 Matrimoni 1870-1910 Morti 1871-1908 Cittadinanze 1874-1909'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32040-13693-24?cc=2043434&wc=MM1H-FLS:953943336'
%     %'https://familysearch.org/pal:/MM9.3.1/TH-1961-32040-14016-44?cc=2043434&wc=MM1H-FLS:953943336'
%     %'https://familysearch.org/pal:/MM9.3.1/TH-1942-32040-13666-21?cc=2043434&wc=MM1H-FLS:953943336'
%     2102
%     [0.77 0.33]
%     'imgCalabrittoB%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calabritto Nati 1866-1910 Pubblicazioni 1866-1871'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32047-16248-85?cc=2043434'
%     2629
%     [0.70 0.33]
%     'imgCalabrittoC%07d.jpg'
%     };


% %
% % Conza della Campania
% %

% matr_films(end+1,:) = {
%     'Conza Morti 1873-1910 Cittadinanze 1866-1909'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1971-32041-12711-91?cc=2043434&wc=MM1H-FL8:n2009264016'
%     %'https://familysearch.org/pal:/MM9.3.1/TH-1971-32041-12624-83?cc=2043434&wc=MM1H-FL8:n2009264016'
%     739
%     [0.76 0.33]
%     'imgConzaA%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Conza Nati 1866-1910 Pubblicazioni 1872-1910 Matrimoni 1866-1910 Morti 1866-1872'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32041-15158-34?cc=2043434&wc=MM1H-FLF:673295759'
%     2410
%     [0.10 0.37]
%     'imgConzaB%07d.jpg'
%     };


% %
% % Lioni
% %

% matr_films(end+1,:) = {
%     'Lioni Morti 1884-1910 Cittadinanze 1869-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32047-18116-80?cc=2043434&wc=MM1H-FGN:1468371775'
%     1029
%     [0.67 0.33]
%     'imgLioniA%07d.jpg'
%     };
%
% matr_films(end+1,:) = {
%     'Lioni Nati 1866-1876'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1961-32042-2307-55?cc=2043434&wc=MM1H-FGK:n1296982890'
%     1025
%     [0.54 0.33]
%     'imgLioniB%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Lioni Nati 1877-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32027-14846-60?cc=2043434&wc=MM1H-FGL:1879672398'
%     3037
%     [0.54 0.33]
%     'imgLioniC%07d.jpg'
%     };


% %
% % Bagnoli Irpino
% %

% matr_films(end+1,:) = {
%     'Bagnoli Nati 1866-1883'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1971-32042-6606-42?cc=2043434&wc=MM1H-F2V:1028453745'
%     1205
%     [0.59 0.33]
%     'imgBagnoliA%07d.jpg'
%     };
%
% matr_films(end+1,:) = {
%     'Bagnoli Nati 1884-1910 Pubblicazioni 1866-1902, 1905'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1971-32067-9732-63?cc=2043434&wc=MM1H-F2L:n2050764809'
%     2913
%     [0.75 0.33]
%     'imgBagnoliB%07d.jpg'
%     };


% %
% % Calitri
% %

% matr_films(end+1,:) = {
%     'Calitri Matrimoni 1878-1910 Morti 1866-1887'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32037-10467-9?cc=2043434&wc=MM1H-FL3:n957414541'
%     3030
%     [0.70 0.38]
%     'imgCalitriA%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calitri Morti 1888-1910 Cittadinanze 1866-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32045-17759-77?cc=2043434&wc=MM1H-FLQ:17711322'
%     1693
%     [0.71 0.38]
%     'imgCalitriB%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calitri Nati 1866-1872'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32040-8442-49?cc=2043434&wc=MM1H-FLW:1752215402'
%     870
%     [0.58 0.38]
%     'imgCalitriC%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calitri Nati 1872-1888'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32037-10968-62?cc=2043434&wc=MM1H-FLC:n876153842'
%     3012
%     [0.58 0.38]
%     'imgCalitriD%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calitri Nati 1889-1905'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32021-21492-58?cc=2043434&wc=MM1H-FL6:n1141983154'
%     3023
%     [0.69 0.38]
%     'imgCalitriE%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Calitri Nati 1906-1910 Pubblicazioni 1868-1910 Matrimoni 1866-1877'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32021-748-64?cc=2043434&wc=MM1H-FLN:n1906667903'
%     3026
%     [0.49 0.41]
%     'imgCalitriF%07d.jpg'
%     };


% %
% % Montella
% %
% 
% matr_films(end+1,:) = {
%     'Montella Morti 1889-1910 Cittadinanze 1866-1910'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32024-14385-96?cc=2043434&wc=MM1H-FGJ:n2094864465'
%     928
%     [0.11 0.41]
%     'imgMontellaA%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Montella Nati 1866-1882'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32048-138-64?cc=2043434&wc=MM1H-FGV:n1765165359'
%     1955
%     [0.72 0.38]
%     'imgMontellaB%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Montella Nati 1883-1906'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1951-32065-1349-34?cc=2043434&wc=MM1H-FG2:860584640'
%     2983
%     [0.60 0.38]
%     'imgMontellaC%07d.jpg'
%     };
% 
% matr_films(end+1,:) = {
%     'Montella Nati 1907-1910 Pubblicazioni 1866-1910 Matrimoni 1866-1909 Morti 1872-1887'
%     'https://familysearch.org/pal:/MM9.3.1/TH-1942-32044-13050-33?cc=2043434&wc=MM1H-FGP:891444795'
%     2994
%     [0.10 0.41]
%     'imgMontellaD%07d.jpg'
%     };





import java.awt.Robot;
import java.awt.event.*; % for KeyPress

robot = Robot;


if nargin>0
    action = varargin{1};
    switch action
        case 'LDS_checker';
            LDS_checker(robot,matr_films,folder_archive,filename_download);
        otherwise
            error('Unknown action: %s',action)
    end
    return
end


list_matr_download = {};
list_list_multiple = {};
for i_film = 1:size(matr_films,1)
    
    film_txt        = matr_films{i_film,1};
    %film_url        = matr_films{i_film,2};
    film_num        = matr_films{i_film,3}; % number of images
    %film_edit_vect  = matr_films{i_film,4}; % [x y] relative position of edit control for id
    %film_fileformat = matr_films{i_film,5}; % format of stored files
    
    [film_tag folder_film] = get_film_tag_and_folder(matr_films(i_film,:),folder_archive);
    
    list_id = detect_images_to_download(folder_film,1:film_num);
    
    fprintf(1,'\n\n*** Film %d: "%s"\n\n',i_film,film_txt);
    
    % download film images
    matr_download = download_film_images(robot,matr_films,i_film,list_id,folder_film,filename_download);
    
    % check for wrong or multiple images
    [list_id list_stored list_stored_filename] = detect_images_to_download(folder_film,1:film_num);
    list_multiple = check_multiple_images(list_stored,list_stored_filename);
    
    list_matr_download{i_film} = matr_download; %#ok<AGROW>
    list_list_multiple{i_film} = list_multiple; %#ok<AGROW>
end


result.matr_download    = list_matr_download; % info on downloaded files
result.list_multiple    = list_list_multiple; % list of detected multiple images



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_id list_stored list_stored_filename] = detect_images_to_download(folder_film,list_id_ref)

if ~exist(folder_film,'dir')
    mkdir(folder_film)
    list_id = list_id_ref;
    list_stored = [];
    list_stored_filename = {};
else
    z = dir([folder_film 'img*.jpg']);
    [list_stored_filename{1:length(z)}] = deal(z.name);
    list_stored_filename = list_stored_filename';
    z = regexp(list_stored_filename,'[0-9]+','match');
    list_stored = str2double([z{:}]'); % it's already downloaded
    list_id = setdiff(list_id_ref,list_stored);
    
    list_stored_filename = cellfun(@(x) [folder_film x],list_stored_filename,'UniformOutput',false); % filename to fullpath
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function select_film(robot,film_url)

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

flg_new_mode = 1;
if flg_new_mode
    
    % give focus to the browser
    robot.mouseMove(width*0.20, height*0.13);
    mouse_click(robot,'left')
    pause(0.3)
    
    % run iMacros bookmark to set first page
    key_press(robot,'%(b)');
    pause(0.1)
    key_press(robot,'z');
    pause(0.1)
    
else
    % enter the url  %#ok<UNRCH>
    
    % click in url edit control
    robot.mouseMove(width*0.10, height*0.13);
    mouse_click(robot,'left')
    
    % select all text to be deleted
    key_press(robot,'^(a)');
    
    % select all text to be deleted
    key_press(robot,film_url);
    pause(0.5)
    
    % press ENTER
    key_press(robot,sprintf('\n'));
end

pause(10) % wait for page loading
wait_for_firefox_idle(15); % wait till firefox finishes its work



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok_download = save_image(robot,filename_download)

% delete download file to be sure that the downloaded one can be linked to
% this id
if exist(filename_download,'file')
    delete(filename_download)
end

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

if ~exist('robot','var') || isempty(robot)
    import java.awt.Robot;
    import java.awt.event.*; % for KeyPress
    
    robot = Robot;
end
    
% click save
kx = 0.91;
ky = 0.33;
deltax = 0;
robot.mouseMove(width*kx, height*ky); % have "Save" label appear
pause(0.1)
robot.mouseMove(width*(kx+deltax), height*ky); % go over "Save" label
pause(0.1)
mouse_click(robot,'left')
%pause(5) % wait for new window opening
wait_for_firefox_idle(15); % wait till firefox finishes its work
pause(.2) % wait for new window opening

rwidth_ok  = 0.61; % rel x pos for Ok button
rheight_ok = 0.61; % rel y pos for Ok button

% select "save file" (instead of "open file")
robot.mouseMove(width*(rwidth_ok-0.22), height*(rheight_ok-0.06));
pause(0.1)
mouse_click(robot,'left')
pause(0.1)

% click ok button
robot.mouseMove(width*rwidth_ok, height*rheight_ok);
pause(1)
mouse_click(robot,'left')

% wait for image saving
pause(1)
%wait_for_firefox_idle(15); % wait till firefox finishes its work
max_download_time = 10; % [s]
ancora = 1;
count = 0;
bytes_old = -1;
while ancora
    count = count+1;
    
    z_file=dir(filename_download);
    if ~isempty(z_file)
        bytes = z_file.bytes;
        ok_download = (( bytes>0) && (bytes_old==bytes) ); % file was downloaded and not empty
        bytes_old = bytes;
        max_download_time = 60; % [s] if download was started, allow a longer time
        pause(1)
    else
        ok_download = 0;
    end
        
    ancora = ( (count<=max_download_time) && ~ok_download );
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ok err_msg file_dstname file_datenum file_bytes] = store_image(robot,ok_download,filename_download,id,film_fileformat,matr_download,folder_film,film_url)

file_dstname = '';
file_datenum = NaN;
file_bytes   = NaN;

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

rwidth_ok  = 0.61; % rel x pos for Ok button
rheight_ok = 0.61; % rel y pos for Ok button


if ~ok_download
    % 1) download failed, no need to manage the downloaded file
    ok = 0;
    err_msg = sprintf('\tMissed download');
else
    % a downloaded file exists
    z_file=dir(filename_download);
    if (z_file.bytes > 0)
        % non-empty downloaded file
        
        % check if downloaded file has the same size of previous one. If so, maybe
        % the web page has lost the edit control to enter the ID, and all entered
        % ID's are useless, thus leading to downloading the same image. If this is
        % the case, reload the page by entering the url
        num_download = size(matr_download,1); % number of download attempts
        flg_cloned_images = 0;
        if (num_download > 1)
            size_before_last    = matr_download{end-1,4};
            size_last           = matr_download{end,4};
            if isequal(size_before_last,size_last)
                % downloaded file is likely to be the same of previous,
                % discard it
                flg_cloned_images = 1;
            end
        end
        
        if flg_cloned_images
            % 3) cloned images detected, discard the downloaded file
            ok = 0;
            err_msg = sprintf('\tPossible wrong download detected (same size of previous one): reloading film web page!');
            
            % reload the web page to prevent more wrong downloads
            select_film(robot,film_url)
        else
            % 4) downloaded file is ok
            ok = 1;
            err_msg = '';
        end
    else
        % 2) empty downloaded file, discard it
        delete(filename_download)
        ok = 0;
        err_msg = sprintf('\tIncomplete download!');
    end
end

% check for multiple downloads
filename_multiple = strrep(filename_download,'.jpg','*.jpg');
z_multiple = dir(filename_multiple);
if ( length(z_multiple)>1 )
    % multiple downloads detected!
    delete(filename_multiple)
    
    ok = 0;
    err_msg = sprintf('%s - Multiple downloads detected!',err_msg);
end

    
if (~ok)
    z_file=dir(filename_download);
    if isempty(z_file)
        % - downloaded file doesn't exist, but is empty
        
        % no attempt to download the file started, maybe the save window
        % remained open: try to close it
        err_msg = sprintf('%s - Click cancel button after empty file!',err_msg);

        % click on cancel button, if save window was left open somehow
        robot.mouseMove(width*(rwidth_ok-0.07), height*(rheight_ok));
        mouse_click(robot,'left')
        pause(0.5)
        
        % reload the web page to prevent more wrong downloads
        select_film(robot,film_url)
        
    else
        % - downloaded file exists
        
        % if not ok, ensure the file is deleted
        delete(filename_download)
    end
else
    % downloaded file looks ok, store it
    file_dstname = [folder_film sprintf(film_fileformat,id)];
    movefile(filename_download,file_dstname);
    
    file_datenum    = z_file.datenum;
    file_bytes      = z_file.bytes;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function select_image(robot,id,film_edit_vect)

if ( ~exist('robot','var') )
    import java.awt.Robot;
    import java.awt.event.*; % for KeyPress
    
    robot = Robot;
    
    film_edit_vect=[0.06 0.34]; % relative position of edit control to enter the image id
end

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

film_editx = film_edit_vect(1);
film_edity = film_edit_vect(2);

% select edit control
robot.mouseMove(width*film_editx, height*film_edity);
mouse_click(robot,'left')

% select all text to be deleted
key_press(robot,'^(a)');

% enter id of image
key_press(robot,num2str(id));

% % press "go" button
% robot.mouseMove(width*(film_editx+0.09), height*film_edity);
% mouse_click(robot,'left')

% press "ENTER
key_press(robot,sprintf('\n'));

% wait for image loading
pause(26)
%wait_for_firefox_idle(15) % wait till firefox finishes its work



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mouse_click(robot,button_type)

switch button_type
    case 'left' % left button
        mouse_button = java.awt.event.InputEvent.BUTTON1_MASK;
    case 'middle' % middle button
        mouse_button = java.awt.event.InputEvent.BUTTON2_MASK;
    case 'right' % rightbutton
        mouse_button = java.awt.event.InputEvent.BUTTON3_MASK;
    otherwise
        error('Unmanaged button type: %s',button_type)
end

pause(0.01)
robot.mousePress(mouse_button);
pause(0.01)
robot.mouseRelease(mouse_button);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function key_press(robot,char)

list_needshift = ['/?:=&' 'A':'Z'];

stack=dbstack;
calling_fcn = stack(2).name;
if ( ~strcmp(calling_fcn,'key_press') )
    % only pause once per call
    pause(1)
end

event_ext = []; % default is no modifier (SHIFT, CTRL, etc)
listkeys = char; % chars to be pressed
if isempty(char)
    return
elseif (length(char)>1)
    if ~isempty(regexp(char,['^[' list_needshift ']+$'],'once'))
        % all upper case, use canonic format
        key_press(robot,['+(' char ')'])
        return
    elseif ( ~ismember('(',char) && ~ismember(')',char) )
        % es. 'ciao'
        event_ext = [];
        
        ind=regexp(char,['[' list_needshift ']']);
        if ~isempty(ind)
            char_i = char(1:ind(1)-1);
            key_press(robot,char_i)
            
            i = 1;
            ancora = 1;
            while ancora
                %for i=1:(length(ind)-1)
                char_i_ext = char(ind(i));
                char_i_non_ext = char(ind(i)+1:ind(i+1)-1);
                ancora_ext = isempty(char_i_non_ext);
                while ancora_ext
                    if (i<(length(ind)-1))
                        % not the last upper case char
                        i = i+1;
                        char_i_ext = [char_i_ext char(ind(i))]; %#ok<AGROW>
                        char_i_non_ext = [char_i_non_ext char(ind(i)+1:ind(i+1)-1)]; %#ok<AGROW>
                        ancora_ext = isempty(char_i_non_ext);
                    else
                        % last upper case char
                        if (i==(length(ind)-1))
                            i=i+1;
                            char_i_ext = [char_i_ext char(ind(i))]; %#ok<AGROW>
                            char_i_non_ext = [char_i_non_ext char(ind(i)+1:end)]; %#ok<AGROW>
                        end
                        ancora_ext = 0;
                    end                        
                end
                key_press(robot,char_i_ext)
                key_press(robot,char_i_non_ext)
                %end
                i = i+1;
                ancora = (i<=(length(ind)-1));
            end
            return
        else
            listkeys = char;
        end
    else
        switch char(1)
            case '+'% SHIFT
                event_ext = java.awt.event.KeyEvent.VK_SHIFT;
            case '^' % CTRL
                event_ext = java.awt.event.KeyEvent.VK_CONTROL;
            case '%' % ALT
                event_ext = java.awt.event.KeyEvent.VK_ALT;
            otherwise
                error('Unmanaged modifier key: %s',char)
        end
        if (length(char)==2)
            % es. '+a'
            listkeys = char(2);
        else
            if ( (char(2)=='(') && (char(end)==')') )
                % es. '+(ciao)'
                listkeys = char(3:end-1);
            else
                error('Wrong format: %s',char)
            end
        end
    end
end

%listkeys = upper(listkeys); % case insensitive. Use SHIFT'for calital letters


% press modifier key
if ~isempty(event_ext)
    robot.keyPress(event_ext)
    pause(0.004)
end

for i_char=1:length(listkeys)
    ch = listkeys(i_char);
    if ( ismember(ch,list_needshift) && ~isequal(event_ext,java.awt.event.KeyEvent.VK_SHIFT) )
        key_press(robot,['+(' ch ')']) % needs a SHIFT ???
    else
        event_key = get_key_event(ch);
        
        if isempty(event_key)
            % carattere non riconosciuto, termina ciclo
            break
        else
            robot.keyPress(event_key)
            pause(0.004)
            robot.keyRelease(event_key)
        end
    end
end

% release modifier key
if ~isempty(event_ext)
    robot.keyRelease(event_ext)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function event_key = get_key_event(ch)

if ( ismember(ch,['a':'z' 'A':'Z']) || ismember(ch,'0':'9') )
    event_key = eval(['java.awt.event.KeyEvent.VK_' upper(ch)]);
else
    switch ch
        case ' '
            event_key = java.awt.event.KeyEvent.VK_SPACE;
        case ''''
            event_key = java.awt.event.KeyEvent.VK_QUOTE;
        case '!'
            event_key = java.awt.event.KeyEvent.VK_EXCLAMATION_MARK;
        case ','
            event_key = java.awt.event.KeyEvent.VK_COMMA;
        case '.'
            event_key = java.awt.event.KeyEvent.VK_PERIOD;
        case ':'
            event_key = java.awt.event.KeyEvent.VK_COLON;
        case ';'
            event_key = java.awt.event.KeyEvent.VK_SEMICOLON;
        case '-'
            event_key = java.awt.event.KeyEvent.VK_SUBTRACT;
        case '*'
            event_key = java.awt.event.KeyEvent.VK_ASTERISK;
        case '+'
            event_key = java.awt.event.KeyEvent.VK_ADD;
        case '='
            event_key = java.awt.event.KeyEvent.VK_EQUALS;
        case '_'
            event_key = java.awt.event.KeyEvent.VK_UNDERSCORE;
        case '@'
            event_key = java.awt.event.KeyEvent.VK_AT;
        case '&'
            event_key = java.awt.event.KeyEvent.VK_AMPERSAND;
        case '/'
            event_key = java.awt.event.KeyEvent.VK_SLASH;
        case '\'
            event_key = java.awt.event.KeyEvent.VK_BACK_SLASH;
        case '('
            event_key = java.awt.event.KeyEvent.VK_LEFT_PARENTHESIS;
        case ')'
            event_key = java.awt.event.KeyEvent.VK_RIGHT_PARENTHESIS;
        case sprintf('\t')
            event_key = java.awt.event.KeyEvent.VK_TAB;
        case sprintf('\n')
            event_key = java.awt.event.KeyEvent.VK_ENTER;
        case sprintf('\b')
            event_key = java.awt.event.KeyEvent.VK_BACK_SPACE;
        case char(27) % ESCAPE
            event_key = java.awt.event.KeyEvent.VK_ESCAPE;
        case '?' % needs SHIFT
            event_key = java.awt.event.KeyEvent.VK_QUOTE;
        case '/' % needs SHIFT
            event_key = java.awt.event.KeyEvent.VK_7;
        %case '#' % doesn't work!
        %    event_key = java.awt.event.KeyEvent.VK_NUMBER_SIGN;
        otherwise
            fprintf(1,'Unmanaged key "%s"!\n',ch)
            event_key = [];
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function reload_page(robot)

% reload web page
key_press(robot,'^(R)') 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function manage_pause(robot,matr_download,film_url)

num_download = size(matr_download,1);

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

% every step downloads, do a longer pause to prevent download block by the site
step = 30;
%step_pause = 90; % [s] time pause every step downloads
%step_pause = 75; % [s] time pause every step downloads
step_pause = 60; % [s] time pause every step downloads
if (rem(num_download,step)==0)
    fprintf(1,'\tPause (%d s) after %d images (%s)!\n',step_pause,step,datestr(now))
    pause(step_pause)
end

% maybe "lost sync" bar appeared: try to close it
num_max_sync = 3;
if (num_download>num_max_sync)
    list_ok = [matr_download{(end-num_max_sync+1):end,2}];
    if (all(~list_ok) )
        fprintf(1,'\tTrying to close sync bar (%s)\n',datestr(now))
        robot.mouseMove(width*.015, height*.92);
        mouse_click(robot,'left')
        select_film(robot,film_url)
        
        fprintf(1,'\tTrying to press "try again" button (%s)\n',datestr(now))
        robot.mouseMove(width*.32, height*.67);
        mouse_click(robot,'left')
        
        select_film(robot,film_url)
    end
end

% if too many missed downloads, try a long wait, then try to restart
num_max_lost = 6;
max_lost_pause = 3*60; % [s] time pause every step downloads
if (num_download>num_max_lost)
    list_ok = [matr_download{(end-num_max_lost+1):end,2}];
    if (all(~list_ok) )
        % too many missed downloads, try to reload the page
        fprintf(1,'\tLong pause (%d m) after %d failed downloads (%s)!\n',max_lost_pause/60,num_max_lost,datestr(now))
        pause(max_lost_pause)
        select_film(robot,film_url)
        reload_page(robot);
        pause(step_pause)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_multiple = check_multiple_images(list_stored,list_stored_filename)

list_multiple = {};

fprintf(1,'\nChecking for duplicated images:\n')

% first pass: get file size
list_bytes = ones(size(list_stored))*NaN;
for i_img = 1:length(list_stored)
    % img_id          = list_stored(i_img);
    img_filename    = list_stored_filename{i_img};
    
    z = dir(img_filename);
    list_bytes(i_img,1) = z.bytes;
end
[temp ind_unique] = unique(list_bytes); % find index to unique occurrence
ind_multiple = setdiff(1:length(list_bytes),ind_unique); % potential clones (same byte-size)

% leave one element for every byte-size
[temp ind_unique_bytes] = unique(list_bytes(ind_multiple)); % one element for every byte-size
ind_multiple = ind_multiple(ind_unique_bytes);

% assemble vectors of potentially multiple images
for i_multiple = 1:length(ind_multiple)
    ind_multiple_i = ind_multiple(i_multiple); % index of i-th potential multiple
    
    bytes_multiple_i = list_bytes(ind_multiple_i);
    vett_multiple_i = find(list_bytes==bytes_multiple_i);  % index of i-th potential multiple
    
    list_stored_i           = list_stored(vett_multiple_i);             % potentially linked image id's
    list_stored_filename_i  = list_stored_filename(vett_multiple_i);    % potentially linked image filenames
    
    list_multiple(i_multiple,:) = {bytes_multiple_i,list_stored_i list_stored_filename_i}; %#ok<AGROW>
end


% analize potential multiple images
for i_multiple = 1:size(list_multiple,1)
    % bytes_multiple_i        = list_multiple{i_multiple,1}; % bytes of multiple files
    list_stored_i           = list_multiple{i_multiple,2}; % id's
    list_stored_filename_i  = list_multiple{i_multiple,3}; % filenames
    
    fprintf(1,'\n')
    
    matr_fingerprint = [];
    for i_img = 1:length(list_stored_filename_i)
        img_id          = list_stored_i(i_img);
        img_filename    = list_stored_filename_i{i_img};
        
        img_fingerprint = get_img_fingerprint(img_filename); % horiz vector of numbers characterizing an image
        matr_fingerprint(end+1,:) = img_fingerprint; %#ok<AGROW>
        
        fprintf(1,'\t%3d:\t%dx%d - %d\n',img_id,img_fingerprint(1),img_fingerprint(2),img_fingerprint(3))
    end
    
    [temp ind_unique] = unique(matr_fingerprint,'rows'); % unique images
    ind_multiple = setdiff(1:length(list_stored_i),ind_unique); % potential clones (same byte-size and image-size)
    % detect all images equal to the detected clones
    ind_rows = [];
    for i_ind_i = 1:length(ind_multiple)
        ind_tmp = ind_multiple(i_ind_i);
        
        ind_rows = [ind_rows; find(all((matr_fingerprint==repmat(matr_fingerprint(ind_tmp,:),size(matr_fingerprint,1),1))'))']; %#ok<AGROW>
    end
    ind_multiple = unique(ind_rows); % group of clones with the same file size

    % update the group of clones
    list_stored_i           = list_stored_i(ind_multiple);
    list_stored_filename_i  = list_stored_filename_i(ind_multiple);

    if isempty(list_stored_i)
        fprintf(1,'\tFalse positive.\n')
    end

    % update the list of groups of clones
    list_multiple{i_multiple,2} = list_stored_i; %#ok<AGROW> % update id's
    list_multiple{i_multiple,3} = list_stored_filename_i; %#ok<AGROW> % update filenames
end
if ( ~isempty(list_multiple) )
    % remove potential groups that have become empty (false positive)
    list_multiple = list_multiple(~cellfun('isempty',list_multiple(:,2)),:);
end


% remove multiple images
% max_num_clones = 10; % max number of cloned images beyond which deletion will have to be confirmed
if ( ~isempty(list_multiple) )
    for i_multiple = 1:size(list_multiple,1)
        bytes_multiple_i        = list_multiple{i_multiple,1}; % bytes of multiple files
        list_stored_i           = list_multiple{i_multiple,2}; % id's
        list_stored_filename_i  = list_multiple{i_multiple,3}; % filenames

        ks = sprintf('%d,',list_stored_i);
        ks=ks(1:end-1);
        num_clones = length(list_stored_i);
        fprintf(1,'\n\tMultiple files (%d) detected and to be deleted (same size: %d bytes): image id''s: %s\n',num_clones,bytes_multiple_i,ks);

        cmd = ['delete ' sprintf('''%s'' ',list_stored_filename_i{:})];
        eval(cmd);
        
        fprintf(1,'\tDone (%d files removed).\n',num_clones);
    end
else
    fprintf(1,'\n\tNo multiple images detected: film was downloaded correctly.\n')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_fingerprint = get_img_fingerprint(img_filename)

img_bitmap = imread(img_filename);  % image greyscale bitmap
img_size = fliplr(size(img_bitmap)); % width x height
img_fingerprint = [img_size(1) img_size(2) sum(img_bitmap(:))];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [film_tag film_folder] = get_film_tag_and_folder(matr_film_i,folder_archive)

film_txt        = matr_film_i{1};
% film_url        = matr_film_i{2};
% film_num        = matr_film_i{3}; % number of images
% film_edit_vect  = matr_film_i{4}; % [x y] relative position of edit control for id
% film_fileformat = matr_film_i{5}; % format of stored files

film_tag = regexprep(regexprep(film_txt,'[^a-zA-Z0-9]','_'),'_+','_');
film_folder = [folder_archive film_tag filesep];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_download = download_film_images(robot,matr_films,i_film,list_id,folder_film,filename_download)
% download film images

film_txt        = matr_films{i_film,1};
film_url        = matr_films{i_film,2};
% film_num      = matr_films{i_film,3}; % number of images
film_edit_vect  = matr_films{i_film,4}; % [x y] relative position of edit control for id
film_fileformat = matr_films{i_film,5}; % format of stored files

matr_download = {};
if ~isempty(list_id)
    % wait for browser window to be focused by the user
    fprintf(1,'\nDownloading film "%s":\n\n',film_txt);
    
    if (i_film==1)
        disp('Give focus to the browser window rapidly!')
        pause(4)
    end
    
    select_film(robot,film_url); % select url if microfilm
    for id = list_id
        select_image(robot,id,film_edit_vect)
        ok_download = save_image(robot,filename_download);
        [ok err_msg file_dstname file_datenum file_bytes] = store_image(robot,ok_download,filename_download,id,film_fileformat,matr_download,folder_film,film_url);
        fprintf(1,'%3d: %d %s\n',id,ok,err_msg)
        matr_download(end+1,:) = {id,ok,file_datenum,file_bytes,file_dstname}; %#ok<AGROW>
        manage_pause(robot,matr_download,film_url);
    end
else
    disp('    all images are already downloaded')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_bad_img v_bad_img] = crosscheck(folder_film,list_stored_filename)

list_bad_img = {};

fprintf(1,'\nChecking chunk images (%d):\n',length(list_stored_filename))

for i_img = 1:length(list_stored_filename)
    filename_check = list_stored_filename{i_img};
    [tmp name ext] = fileparts(filename_check);
    filename = [name ext];
    fprintf(1,'\t%s',filename)
    filename_image = [folder_film filename];
    if ~isequal_img(filename_check,filename_image)
        v_bad_img(i_img) = 1; %#ok<AGROW>
        list_bad_img{end+1} = filename; %#ok<AGROW>
        fprintf(1,' - ATTENTION! no correspondence!\n')
    else
        v_bad_img(i_img) = 0; %#ok<AGROW>
        fprintf(1,'\n')
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_equal = isequal_img(filename_1,filename_2)

flg_equal = 1;

z1=dir(filename_1);
z2=dir(filename_2);

if ~isequal(z1.bytes,z2.bytes)
    % different byte size
    flg_equal = 0;
else
    img_fingerprint1 = get_img_fingerprint(filename_1); % horiz vector of numbers characterizing an image
    img_fingerprint2 = get_img_fingerprint(filename_2); % horiz vector of numbers characterizing an image
    
    if ~isequal(img_fingerprint1,img_fingerprint2)
        % different image fingerprint (size or checksum)
        flg_equal = 0;
    end
end    



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LDS_checker(robot,matr_films,folder_archive,filename_download)

close all

v_ok = [];
for i_film=1:size(matr_films,1)
    fprintf(1,'\n\n***\n*** Checking film %d\n***\n\n',i_film)
    ok = LDS_checker_i(robot,matr_films,i_film,folder_archive,filename_download);
    v_ok(i_film) = ok; %#ok<AGROW>
end

disp('Final report:')
disp(v_ok)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok = LDS_checker_i(robot,matr_films,i_film,folder_archive,filename_download)

%num_checks = 20; % [adim]
max_time_gap = 4; % [min] max time gap between two consecutive downloads to trigger a check

matr_film_i = matr_films(i_film,:);

[film_tag film_folder] = get_film_tag_and_folder(matr_film_i,folder_archive);

z0=dir([film_folder '*.jpg']);

if (length(z0)<matr_film_i{3})
    error('Film not downloaded correctly: %d out of %d images',length(z0),matr_film_i{3})
end

list_datenum = [z0.datenum]';

% ordina per istante di scaricamento
[list_datenum ind] = sort(list_datenum); %#ok<UDIM>
z0 = z0(ind);

z=regexp({z0.name},'[0-9]+','match')';
list_id = str2double([z{:}]');

[temp ind] = sort(-diff(list_datenum));

sub_ind1 = [1;ind(find((-temp)*24*60>=max_time_gap))+1]; %#ok<FNDSB>
%sub_ind1 = [1;ind(1:num_checks)+1];

sub_ind2 = find(diff(list_id)<0)+1; % indici in cui l'id diventa più piccolo del precedente

ind_dl = union(sub_ind1,sub_ind2);

% suddividi in chunk
matr_chunk = {};
for i_chunk=1:(length(ind_dl)-1)
    ind_start = ind_dl(i_chunk);
    ind_end = ind_dl(i_chunk+1)-1;
    if ismember(ind_start,sub_ind2)
        flg_restart = 1;
    else
        flg_restart = 0;
    end
    matr_chunk(end+1,:) = {list_datenum(ind_start:ind_end) z0(ind_start:ind_end) list_id(ind_start:ind_end),flg_restart}; %#ok<AGROW>
end
ind_start = ind_dl(end);
ind_end = length(z0);
if ismember(ind_start,sub_ind2)
    flg_restart = 1;
else
    flg_restart = 0;
end
matr_chunk(end+1,:) = {list_datenum(ind_start:ind_end) z0(ind_start:ind_end) list_id(ind_start:ind_end),flg_restart};
    

figure(99+i_film)
hold off
plot(list_datenum-round(min(list_datenum)),list_id,'.-');
xlabel('[giorni]')
ylabel('[id]')
title(film_tag,'interpreter','none')
grid on
hold on

plot(list_datenum(sub_ind1)-round(min(list_datenum)),list_id(sub_ind1),'rx');

plot(list_datenum(sub_ind2)-round(min(list_datenum)),list_id(sub_ind2),'rd');

plot(list_datenum(ind_dl)-round(min(list_datenum)),list_id(ind_dl),'go');


fprintf(1,'Checking film %d: %s\n',i_film,film_tag)
fprintf(1,'\tchunks found: %d\n',length(ind_dl))
for i_chunk = 1:size(matr_chunk,1)
    list_datenum_i = matr_chunk{i_chunk,1};
    list_z0_i = matr_chunk{i_chunk,2};
    list_id_i = matr_chunk{i_chunk,3};
    flg_restart = matr_chunk{i_chunk,4};
    
    if flg_restart
        msg_restart = '***';
    else
        msg_restart = '   ';
    end
    
    fprintf(1,'%sStart: %s (%s, id %d), End: %s (%s, id %d)\n',msg_restart,datestr(list_datenum_i(1)),list_z0_i(1).name,list_id_i(1),datestr(list_datenum_i(end)),list_z0_i(end).name,list_id_i(end))
end

% download check images
list_id_check_ref = list_id(ind_dl)'; % must be horizonal vector!
[film_tag folder_film] = get_film_tag_and_folder(matr_films(i_film,:),folder_archive);
folder_film_check = [folder_film 'check' filesep];

[list_id_check list_stored list_stored_filename] = detect_images_to_download(folder_film_check,list_id_check_ref); % detect images to be downloaded
ancora = 1;
while ancora
    matr_download = download_film_images(robot,matr_films,i_film,list_id_check,folder_film_check,filename_download); %#ok<NASGU>
    
    % check for wrong or multiple images
    [list_id_check list_stored list_stored_filename] = detect_images_to_download(folder_film_check,list_id_check);
    list_multiple = check_multiple_images(list_stored,list_stored_filename);
    ancora = ~isempty(list_multiple) || ~isempty(list_id_check);
end

% crosscheck
[list_bad_img v_bad_img] = crosscheck(folder_film,list_stored_filename);

% report
if any(v_bad_img)
    ok = 0;
    fprintf(1,'\nBad chunks identified: %d\n',sum(v_bad_img))
    for i_chunk = 1:size(matr_chunk,1)
        if v_bad_img(i_chunk)
            list_datenum_i = matr_chunk{i_chunk,1};
            list_z0_i = matr_chunk{i_chunk,2};
            list_id_i = matr_chunk{i_chunk,3};
            flg_restart = matr_chunk{i_chunk,4};
            
            if flg_restart
                msg_restart = '***';
            else
                msg_restart = '   ';
            end
            
            plot(list_datenum_i-round(min(list_datenum)),list_id_i,'rx');
            
            fprintf(1,'%sStart: %s (%s, id %d), End: %s (%s, id %d)\n',msg_restart,datestr(list_datenum_i(1)),list_z0_i(1).name,list_id_i(1),datestr(list_datenum_i(end)),list_z0_i(end).name,list_id_i(end))
        end
    end
else
    ok = 1;
    fprintf(1,'\nAll chunks look ok!\n')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function wait_for_firefox_idle(cpu_load_thr)
% wait till firefox finishes its work
%   cpu_load_thr [%] firefox cpu load under which function returns

max_count = 60; % [s]

cpu_load=100;
count = 1;
while (cpu_load>cpu_load_thr) && (count < max_count)
    [exit_code txt] = system('top -b -n 1 | grep firefox | gawk ''{print $9}''');
    cpu_load=str2double(txt);
    count = count+1;
    pause(1)
end

pause(3) % additional pause

if count>max_count
    fprintf(1,'\t*** Too much time with firefox working (cpu load > %d %%)\n',cpu_load_thr)
end
