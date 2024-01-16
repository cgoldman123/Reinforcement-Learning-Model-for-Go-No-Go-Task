% Carter Goldman and Claire Lavalley, 2023
% Gets all data in sourceDir (organized by date of behavioral session) and puts CSVs in destinationDir
% based on matching the filePattern

% Define source and destination directories
sourceDir = 'L:\NPC\DataSink\COBRE-CORE\data-original\behavioral_session\';
destinationDir = 'L:\rsmith\l\cgoldman\go_no_go\COBRE_GNGB_data';

% Define the pattern to search for in file names
filePattern = 'GNGB.*R1-_BEH\.csv';

% List all subdirectories in the source directory
subdirs = dir(sourceDir);
subdirs = subdirs([subdirs.isdir] & ~strcmp({subdirs.name}, '.') & ~strcmp({subdirs.name}, '..'));

% Loop through each subdirectory
for subdirIdx = 1:numel(subdirs)
    currentSubdir = fullfile(sourceDir, subdirs(subdirIdx).name);
    
    % List all CSV files in the current subdirectory
    files = dir(fullfile(currentSubdir, '*.csv'));
    
    % Loop through each CSV file in the current subdirectory
    for fileIdx = 1:numel(files)
        currentFile = fullfile(currentSubdir, files(fileIdx).name);
        
        % Check if the file name matches the pattern
        if ~isempty(regexp(currentFile, filePattern, 'once'))
            % Copy the file to the destination directory with its original name
            copyfile(currentFile, fullfile(destinationDir, files(fileIdx).name));
        end
    end
end



%%% CLAIRES FUNCTION TO GET SUBJECT NAMES
% 
% 
% function listofsubs = find_subjects(folder)
% directory = dir(folder);
% index_array = find(arrayfun(@(n) contains(directory(n).name, 'cooperation_task_'),1:numel(directory)));
% 
% for i=1:length(index_array)
%    index = index_array(i);
%    raw = readtable([folder '/' directory(index).name]);
%    if ~isdouble(raw.trial)
%       raw.trial = str2double(raw.trial);
%    end
%    % fix this to actually validate data
%       if 1
%            valid_data(i)=1;
%       else 
%            valid_data(i)=0;
%       end
% end
% 
% listoffiles = {directory(index_array(logical(valid_data))).name};
%     for k=1:length(listoffiles)
%         listofsubs(k) = extractBetween(listoffiles{k}, 'cooperation_task_', '_T');
%     end 
% 
% listofsubs = cell2table(unique(listofsubs'));
% listofsubs = renamevars(listofsubs,'Var1', 'ID');
% writetable(listofsubs, 'L:\rsmith\lab-members\cgoldman\Wellbeing\CooperationTask\coop_model_output\coop_subjects-grd.csv')
% 
% end
% %% Utilities
% function output = isdouble(array)
%     if strcmp(class(array), 'double')
%         output=true;
%     else
%         output=false;
%     end
% end
% 
% 
