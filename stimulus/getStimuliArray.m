function stimArray = getStimuliArray(folders)
%% Function to summarize figure-ground stimuli into one big stimuli mat file
%
% USAGE: stimArray = getStimuliArray(folders)
%
% Loads all audio data and corresponding parameters from the supplied list
% of folders and concatenates them into one cell matrix. 
%
% Input:
% folders       - Cell array of folder names/paths. Folders are expected to
%               be created with createSFGstimuli script,
%               that is, to contain wav files (one per stimulus) and a csv
%               file with metadata. If there is only one folder, simple
%               char array is sufficient as well.
%
% Output:
% stimArray    - Cell array of cells, each with size "no. of stimuli" X 12. 
%               Column 12 contains raw audio data matrices
%
% Notes         (1) We expect the param csv files to have the following
%               columns:
%               {'filename', 'totalDuration_sec', 'chordDuration_sec', 'chordOnset_sec', ...
%                 'figPresent', 'figureDuration', 'figureCoherence', 'sampleFrequency_Hz', ...
%                 'figureStartInterval', 'figureEndInterval', 'toneComp'};
%

%% Input check

% if input is string, put it into cell
if ischar(folders)
    if ~exist(folders, 'dir')
        error('Could not find target folder (input arg)! If there are multiple folders, supply them as a cell array');
    end
    folders = {folders};
end
% check for existence of folders
if iscell(folders)
    for i = 1:length(folders)
        if ~exist(folders{i}, 'dir')
            error(['Could not find target folder ', folders{i}, '!']);
        end
    end
end

% user message
disp([char(10), 'Called function getStimuliArray with inputs: ', char(10),...
    'folders: ']);
for i = 1:length(folders)
    disp(folders{i});
end


%% Loop through folders, load the parameters file and audio data from each

% fields we expect in params files
paramFields = {'filename', 'totalDur', 'chordDur', 'chordOnset', ...
                 'figureDur', 'figureCoh', 'figureStepS', 'sampleFreq', ...
                 'figureStartInterval', 'figureEndInterval', 'toneComp'};

% output variable collecting stimuli sets
stimArray = cell(length(folders), 1);

for f = 1:length(folders)
    
    disp([char(10), 'Loading params and audio from: ', folders{f}]);
    
    % find corresponding csv file
    csvFile = dir([folders{f},'/*.csv']);
    paramFile = [folders{f}, '/', csvFile.name];
    % load params from csv file
    T = readtable(paramFile, 'Delimiter', ',');
    % transform into cell
    myCell = table2cell(T);
    
    % check params fields (and implicitly, size)
    if ~isequal(T.Properties.VariableNames, paramFields)
        error(['CSV params file ', csvFile, ' had unexpected variables/columns']);
    end

    % load first audio to get audio size
    audioF = [folders{f}, '/', myCell{1, 1}, '.wav'];
    [data, ~] = audioread(audioF);
    
    % preallocate all memory we need to include the audio as well (add
    % extra column for raw audio data)
    myCell = [myCell, repmat({zeros(size(data))}, size(myCell, 1), 1)];
    
    
    %% Loop through audio files
    
    for audio = 1:size(myCell, 1)
        
        % load audio into cell array
        audioF = [folders{f}, '/', myCell{audio, 1}, '.wav'];
        [myCell{audio, length(paramFields)+1}, ~] = audioread(audioF);           
    
    end  % audio files for loop

    % accumulate all data into final 
    stimArray{f, 1} = myCell;
    
    disp(['Done with folder ', folders{f}]);
    
    
end  % folders for loop


%% Ending

disp([char(10), 'Finished, returning']);


return
    
    
    
    
    
    
    
    
    
    
    
    
    