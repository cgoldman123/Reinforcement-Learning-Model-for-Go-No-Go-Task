% DATA PROCESSING


% Base directory where files are stored
baseDir = 'L:\rsmith\lab-members\cgoldman\go_no_go\COBRE_GNGB_data';

% Get list of all files in the directory
fileList = dir(fullfile(baseDir, '*.csv'));

% Loop over every file in the directory
for fileIdx = 1:length(fileList)
    % Full path to the current file
    currentFile = fullfile(fileList(fileIdx).folder, fileList(fileIdx).name);
    % Call your data processing function
    processfile(currentFile, 'L:\rsmith\lab-members\cgoldman\go_no_go\r_stats\data_long_11-9-23.csv');
end


function processfile(inputFile, outputFile)

    rawData = readtable(inputFile, 'ReadVariableNames', false);

    % Indices initialization
    go_win_idx = 0;
    go_lose_idx = 0;
    nogo_win_idx = 0;
    nogo_lose_idx = 0;
    
    % Creating an empty structure for the results
    results = struct();
    results.('participant_ID') = {inputFile};

    % Process each row of the raw file
    for k = 3:height(rawData)
        trial_number = rawData{k, 1};
        trial_type = rawData{k, 2};
        event_code = rawData{k, 3};
        absolute_time = rawData{k, 4};
        response_time = rawData{k, 5};
        response = rawData{k, 6};
        result = rawData{k, 7};

        if strcmp(response, "don't know")
            response = 'DontKnow';
        end

        % Process based on event_code
        switch event_code
            case 8
                switch trial_type
                    % read in the reaction times and the observations
                    case 0
                        colName = sprintf('gngb_go_win_%d', go_win_idx);
                        results.(colName) = response_time;
                        colName = sprintf('observation_gngb_go_win_%d', go_win_idx);
                        results.(colName) = response;
                        go_win_idx = go_win_idx + 1;
                    case 1
                        colName = sprintf('gngb_go_lose_%d', go_lose_idx);
                        results.(colName) = response_time;
                        colName = sprintf('observation_gngb_go_lose_%d', go_lose_idx);
                        results.(colName) = response;
                        go_lose_idx = go_lose_idx + 1;
                    case 2
                        colName = sprintf('gngb_nogo_win_%d', nogo_win_idx);
                        results.(colName) = response_time;
                        colName = sprintf('observation_gngb_nogo_win_%d', nogo_win_idx);
                        results.(colName) = response;
                        nogo_win_idx = nogo_win_idx + 1;
                    case 3
                        colName = sprintf('gngb_nogo_lose_%d', nogo_lose_idx);
                        results.(colName) = response_time;
                        colName = sprintf('observation_gngb_nogo_lose_%d', nogo_lose_idx);
                        results.(colName) = response;
                        nogo_lose_idx = nogo_lose_idx + 1;
                end

            case 12
                results.gngb_total_reward = result;

            case 14
                switch trial_type
                    case 0
                        colName = 'gngb_go_win_outcomes';
                        results.(colName) = response;
                    case 1
                        colName = 'gngb_go_lose_outcomes';
                        results.(colName) = response;
                    case 2
                        colName = 'gngb_nogo_win_outcomes';
                        results.(colName) = response;
                    case 3
                        colName = 'gngb_nogo_lose_outcomes';
                        results.(colName) = response;
                end

            case 16
                switch trial_type
                    case 0
                        colName = 'gngb_go_win_strategy';
                        results.(colName) = response;
                    case 1
                        colName = 'gngb_go_lose_strategy';
                        results.(colName) = response;
                    case 2
                        colName = 'gngb_nogo_win_strategy';
                        results.(colName) = response;
                    case 3
                        colName = 'gngb_nogo_lose_strategy';
                        results.(colName) = response;
                end
        end
    end
    % put the date in
    fid = fopen(inputFile, 'rt');
    % Read the first line
    firstLine = fgetl(fid);
    % Close the file
    fclose(fid);
    % Split the line by comma
    parts = strsplit(firstLine, ',');
    % The date should be the 6th element after splitting, but we need to trim
    % any leading or trailing whitespace
    dateStr = strtrim(parts{6});
    results.date = dateStr;

    % Convert structure to table and then to CSV
    resultTable = struct2table(results);
    if isfile(outputFile)
        % If the file exists, read it and append the row
        opts = detectImportOptions('L:\rsmith\lab-members\cgoldman\go_no_go\r_stats\data_long_11-9-23.csv');
        opts = setvartype(opts, 'char');  % Set all variable types to 'char' to preserve 'NA'
        existingData = readtable(outputFile, opts);
        try
            combinedData = [existingData; resultTable];
            writetable(combinedData, outputFile);
        catch
            inputFile
        end
    else
        % If the file doesn't exist, write the table with headers
        writetable(resultTable, outputFile);
    end
end
