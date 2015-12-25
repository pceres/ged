function search_person(str_archivio,nome,cogn,relax_factor)
% nome = 'GAETANA'
% cogn = 'CERES'
% search_person(str_archivio,nome,cogn,1) % 3053?

disp(sprintf('\nCerco come self:'))
record = struct('nome',nome,'cogn',cogn);
result = ged('find_person',record,str_archivio,relax_factor,[]);

disp(sprintf('\nCerco come padre:'))
record = struct('pad_nome',nome,'cogn',cogn);
result = ged('find_person',record,str_archivio,relax_factor,[]);

disp(sprintf('\nCerco come madre:'))
record = struct('mad_nome',nome,'mad_cogn',cogn);
result = ged('find_person',record,str_archivio,relax_factor,[]);

disp(sprintf('\nCerco come coniuge:'))
record = struct('con_nome',nome,'con_cogn',cogn);
result = ged('find_person',record,str_archivio,relax_factor,[]);
