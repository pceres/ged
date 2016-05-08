function list_filename = download_pgv_images(list_images,url_format)
%
% list_filename = download_pgv_images({'I10396'},'http://ars.altervista.org/PhpGedView/treenav.php?ged=caposele&rootid=<PID>');eval(['!gimp' sprintf(' "%s"',list_filename{:}) ' &'])
%

dest_folder = 'snapshot';

robot = robot_wrapper('init');

screenSize = get(0, 'screensize');
width  = screenSize(3);
height = screenSize(4);

% give focus to the browser
robot_wrapper('mouse_move',{robot,width*0.20, height*0.105});
robot_wrapper('mouse_click',{robot,'left'});
pause(0.3)

if ~exist(dest_folder,'dir')
    mkdir(dest_folder)
end

list_filename = {};
for i_atl = 1:length(list_images)
%     id       = data{i_atl,str.ind_id};
%     name     = data{i_atl,str.ind_name};
%     % image    = data{i_atl,str.ind_image};
%     id_genea = data{i_atl,str.ind_id_genea};
    id_genea = list_images{i_atl};
    
    url = strrep(url_format,'<PID>',id_genea);
    
    % give focus to the browser url control
    robot_wrapper('mouse_move',{robot,width*0.20, height*0.105});
    robot_wrapper('mouse_click',{robot,'left'});
    pause(0.2)
    robot_wrapper('key_press',{robot,'^(a)'}); % select all
    pause(0.2)
    robot_wrapper('key_press',{robot,url}); % type the url
    pause(0.2)
    robot_wrapper('key_press',{robot,sprintf('\n')}); % enter
    pause(2) % wait for page load
    
    % scroll the window
    robot_wrapper('mouse_move',{robot,width*0.995, height*0.925});
    for i_tmp = 1:4
        robot_wrapper('mouse_click',{robot,'left'});
        pause(0.2)
    end
    
    % move graph a bit to the right
    robot_wrapper('mouse_move',{robot,width*0.01, height*0.47})
    pause(0.2)
    robot_wrapper('mouse_move_with_button_pressed',{robot,'left',width*0.055, height*0.47})
    
    
    %%input('Please position the graph in the middle of the screen, then press ENTER','s')
    
    filename = [dest_folder filesep id_genea '.jpg'];
    robot_wrapper('save_snapshot',{robot,filename});
    list_filename{end+1} = filename; %#ok<AGROW>
    
    fprintf(1,'%6s %s\n',id_genea,url)
end
