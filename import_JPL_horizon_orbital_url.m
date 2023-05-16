%% Import data from text file.
% Script for importing data

%% Initialize variables.
%websave(ELEMENTS.COMET,"https://ssd.jpl.nasa.gov/dat/ELEMENTS.COMET");
httpsUrl = "https://ssd.jpl.nasa.gov";
dataUrl = strcat(httpsUrl, "/dat/ELEMENTS.COMET");
cometsFile = "ELEMENTS.COMET";
cometsFileFullPath = websave(cometsFile, dataUrl);
filename = 'ELEMENTS.COMET';
startRow = 3;

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%25s%26s%12s%11s%10s%10s%10s%15s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Remove white space around all cell columns.
dataArray{1} = strtrim(dataArray{1});
dataArray{9} = strtrim(dataArray{9});

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,3,4,5,6,7,8]
    % Converts text in the input cell array to numbers. Replaced non-numeric text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^[-/+]*\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Split data into numeric and string columns.
rawNumericColumns = raw(:, [2,3,4,5,6,7,8]);
rawStringColumns = string(raw(:, [1,9]));


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
ELEMENTS = table;
ELEMENTS.Num_Name = rawStringColumns(:, 1);
ELEMENTS.Epoch = cell2mat(rawNumericColumns(:, 1));
ELEMENTS.q = cell2mat(rawNumericColumns(:, 2));
ELEMENTS.e = cell2mat(rawNumericColumns(:, 3));
ELEMENTS.i = cell2mat(rawNumericColumns(:, 4));
ELEMENTS.w = cell2mat(rawNumericColumns(:, 5));
ELEMENTS.Node = cell2mat(rawNumericColumns(:, 6));
ELEMENTS.Tp = cell2mat(rawNumericColumns(:, 7));
ELEMENTS.Ref = rawStringColumns(:, 2);

%% Clear temporary variables
clearvars filename startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R;

%% Write table to file 
save('JPL_horizon_orbital_elements.mat', 'ELEMENTS')
clear