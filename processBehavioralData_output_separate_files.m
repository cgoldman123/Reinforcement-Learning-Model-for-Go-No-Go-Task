% DATA PROCESSING

% Base directory where files are stored
baseDir = 'L:\rsmith\lab-members\cgoldman\go_no_go\COBRE_GNGB_data';

% Get list of all files in the directory
fileList = dir(fullfile(baseDir, '*.csv'));

% Loop over every file in the directory
for fileIdx = 1:length(fileList)
    % Full path to the current file
    currentFile = fullfile(fileList(fileIdx).folder, fileList(fileIdx).name);
    % get the id of the participant 
    parts = split(currentFile, '\');
    % Take the last part 
    short_filename = parts(length(parts));
    parts = split(short_filename, '-');
    participantID = parts(1);
    outputFile = strjoin(['L:\rsmith\lab-members\cgoldman\go_no_go\processed_behavioral_files\' participantID '_processed_behavioral_file.csv'], '');
    % call the processing function
    processfile(currentFile, outputFile);
end


function processfile(inputFile, outputFile)

    rawData = readtable(inputFile, 'ReadVariableNames', false);

    colNames = {'trial_number', 'trial_type', 'response_time', 'result', 'total_score'};
    % Initialize an empty table with the specified column names
    resultsTable = table('Size', [0, length(colNames)], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, 'VariableNames', colNames);
    % Process each row of the raw file
    for k = 3:height(rawData)
        % add 1 to trial_number and trial_type to keep 1 indexed
        trial_number = (rawData{k, 1}+1);
        trial_type = (rawData{k, 2}+1);
        event_code = rawData{k, 3};
        response_time = rawData{k, 5};
        result = rawData{k, 6};
        total_score = rawData{k, 7};
        % Process based on event_code
        if (event_code == 8)
            newRow = {trial_number, trial_type, response_time, result, total_score};
            resultsTable = [resultsTable; newRow];
        end
        
    end
    
    writetable(resultsTable, outputFile);


end
