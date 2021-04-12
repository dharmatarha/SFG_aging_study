function [stimArray, startTrialNo,... 
    startBlockNo,...
    logVar, subLogF, returnFlag, logHeader,...
    stimTypes] = expParamsHandlerSupervisedLearning(subNum, stimArrayFile, blockNo)
%% Function handling parameters/settings, stimuli and conflicts
%
% USAGE: [stimArray, sortIndices, startTrialNo,... 
%    startBlockNo, blockIdx, trialIdx,...
%    logVar, subLogF, returnFlag, logHeader,...
%    stimTypes] = expParamsHandler(subNum, stimArrayFile, blockNo)
%
% For stochastic figure-ground (SFG) experiment. To be called by the main 
% experimental script (SFGmain.m).
% 
% The function sorts out subject number conflicts, including cases of
% paused and restarted experiments, multi-session recordings and so on.
% Using the input args, it checks for earlier recorded data with the same
% settings and asks for user input where necessary. 
%
% As the function calls in basic parameters, checks for earlier params and
% saved logs, it propagates many different variables to the main
% experimental script. Basic parameters are saved out to 
% /subjectXX/subXXParams.mat where XX stands for subject number
%
% Inputs:
% subNum        - Subject number, integer between 1-999
% stimArrayFile - *.mat file with cell array "stimArray" containing all 
%               stimuli + features (size: no. of stimuli X 12 columns)
% blockNo       - Number of blocks to sort trials into, integer between
%               1-50
%
% Outputs:
% stimArray     - Stimulus array (cell) sorted into the order of trials for
%               given subject. 11th column contains the raw audio.
% sortIndices   - Indices of stimuli in the original (loadable .mat),
%               unsorted array, so that e.g.
%               stimArray_unsorted(sortIndices(1)) = stimArray_sorted(1) 
% startTrialNo  - Trial number the experiment starts from
% startBlockNo  - Block number the experiment starts from (we always start
%               from the beginning of a block)
% trialIdx      - Trial number for each stimulus in unsorted stimArray - 
%               sorted (returned) stimArray is sorted according to 
%               trialIdx already at the return and also contains the sorted
%               trialIdx in 14th column
% blockIdx      - Block number of each stimulus in unsorted stimArray,
%               sorted (returned) stimArray contains its sorted version in 
%               13th column 
% logVar        - logging variable (cell array), might already contain
%               earlier results if the experiment is a continuation of an
%               earlier one
% subLogF       - logging variable file for subject, string
% returnFlag    - 1 if the function returns early due to a problem with the
%               dirs / params / logs
% logHeader     - column names for logging variable logVar 
% stimTypes     - cell array detailing unique stimulus types, in
%               human-readable form (with column headers), passed on from
%               stim2blocksSupervisedLearning.m
%


%% Input checks

if nargin ~= 3
    error('Function needs input args "subNum", "stimArrayFile" and "blockNo"!');
end
% subject number
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
% file with stimuli array
if ~exist(stimArrayFile, 'file')
    error('Cannot find input arg "stimArrayFile"!');
end
% number of blocks
if ~ismembertol(blockNo, 1:50)
    error('Input arg "blockNo" should be between 1 - 50!');
end

% user message
disp([char(10), 'Called paramsHandler function with input args: ',...
    char(10), 'subNum: ', num2str(subNum),...
    char(10), 'stimArrayFile:', stimArrayFile,...
    char(10), 'blockNo: ', num2str(blockNo)]);


%% Check for previously created dir, settings and logs

% flag for propagating early return/exit
returnFlag = 0;
% pre-set certain return variables to defaults to support early return
startTrialNo = 1; startBlockNo = 1;
logVar = {};
stimArray = []; stimTypes = [];

% subject folder name
dirN = ['subject', num2str(subNum)];
% subject parameters/settings file
subParamsF = [dirN, '/sub', num2str(subNum), 'Params.mat'];
% subject log file
subLogF = [dirN, '/sub', num2str(subNum), 'Log.mat'];
% date and time of starting with a subject
c = clock; d = date;
timestamp = {[d, '-', num2str(c(4)), num2str(c(5))]};
% flags for existing parameters and log files
oldParamsFileFlag = 0;
oldParamsMatchFlag = 0;
logFileFlag = 0;
% log header - needed for sanity check as well
logHeader={'subNum', 'blockNo', 'trialNo', 'stimNo', 'toneComp',... 
    'figCoherence', 'figStepSize', 'figStartChord', 'figEndChord',... 
    'accuracy', 'buttonResponse', 'respTime', 'iti', 'trialStart',... 
    'soundOnset', 'figureStart', 'respIntervalStart', 'trigger'};

% check if subject folder already exists
if exist(dirN, 'dir')
    % if there is a parameter file, check if it is compatible with current
    % input args
    if exist(subParamsF, 'file') 
        oldParams = load(subParamsF);
        oldParamsFileFlag = 1;
        % check if the parameters are compatible with current input args
        if isequal(oldParams.stimArrayFile, stimArrayFile) && isequal(oldParams.blockNo, blockNo) && ...
                isequal(oldParams.subNum, subNum)
            oldParamsMatchFlag = 1;
            % check if there is also a log file
            if exist(subLogF, 'file')
                oldLog = load(subLogF);
                % check if stored log is expected format - sane header?
                % no. of rows equals expected number of trials + 1?
                %if isequal(oldLog.logVar(1, :), logHeader) && isequal(size(oldLog.logVar, 1), size(oldParams.stimArray, 1)+1)
                    logFileFlag = 1;
                    logVar = oldLog.logVar;
                %end
            end
        end
    end
else
    % create a folder for subject if there was none
    mkdir(dirN);
    disp([char(10), 'Created folder for subject at ', dirN]);
end

% user messages and inputs where necessary
% depending on what we found (params + log files)
if oldParamsFileFlag && ~oldParamsMatchFlag
    disp([char(10), 'There is already a folder for subject ', num2str(subNum),...
        ', and the parameters/settings file there is incompatible with ',... 
        char(10), 'the input arguments supplied now! Maybe take a look?']);
    inputRes = input([char(10), 'What should we do? (1 = Force the new settings, delete ',...
        'old file(s) and start; ', char(10), '2 = Exit, so I can check the situation ',... 
        '(maybe start the function again with a new subject number?)', char(10)]);
    if isequal(inputRes, 1)
        oldParamsFileFlag = 0;
        disp([char(10), 'Okay, we get rid of old file(s) and start the experiment!']);
    elseif isequal(inputRes, 2)
        returnFlag = 1;
        return
    else
        warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
        returnFlag = 1;
        return
    end
elseif oldParamsFileFlag && oldParamsMatchFlag && ~logFileFlag
    disp([char(10), 'There is already a folder for subject ', num2str(subNum),...
        ', and the parameters/settings file there matches the input arguments ',... 
        'supplied now. ', char(10), 'There is no valid log file though, so we could simply ',...
        'start the experiment(?)']);
    inputRes = input([char(10), 'What should we do? (1 = Simply start the ',...
        'experiment; 2 = Exit, so I can take a better look at the situation)', char(10)]);
    if isequal(inputRes, 1)
        oldParamsFileFlag = 0;
        oldParamsMatchFlag = 0;
        disp([char(10), 'Great, we simply start the experiment!']);
    elseif isequal(inputRes, 2)
        returnFlag = 1;
        return
    else
        warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
        returnFlag = 1;
        return
    end    
elseif oldParamsFileFlag && oldParamsMatchFlag && logFileFlag
    disp([char(10), 'There is already a folder for subject ', num2str(subNum),...
        ',the parameters/settings file there matches the input arguments ',... 
        char(10), 'supplied now, and there is also a valid log file. We could ',...
        'continue with the experiment from where we left earlier.']);
    inputRes = input([char(10), 'What should we do? (1 = Simply go on with the ',...
        'experiment; 2 = Exit, so I can take a better look at the situation)', char(10)]);
    if isequal(inputRes, 1)
        disp([char(10), 'Great, we continue from where we left!']);
    elseif isequal(inputRes, 2)
        returnFlag = 1;
        return
    else
        warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
        returnFlag = 1;
        return
    end 
end


%% Initialize settings and log, depending on the outcome of the previous block

% if there was no matching parameters file, generate everything from
% scratch
if ~oldParamsMatchFlag

    % user message
    disp([char(10), 'We load the stimuli, perform checks on it and sort them to blocks with stim2blocksSupervisedLearning']);
    
    % get new random seed, set RNG
    randomseed = round(sum(c));
    rng(randomseed);
    % check stimuli and sort them into blocks
    [stimTypes, stimTypeIdx,... 
        stimArray] = stim2blocksSupervisedLearning(stimArrayFile, blockNo);   
    
% if old params were matching the ones supplied now (e.g. in case of a 
% second session of the subject) we just load stimuli and use the block 
% and trial indices already available    
elseif oldParamsMatchFlag
    
    % user message
    disp([char(10), 'We load the stimuli and use the old params/settings for sorting them to blocks']);    
    
    % loading the stimuli results in a variable stimArray, this is the same
    % as the one returned by stim2blocksSupervisedLearning
    load(stimArrayFile);
    % we keep the old/loaded params for sorting
    stimTypes = oldParams.stimTypes;
    stimTypeIdx = oldParams.stimTypeIdx;
    randomseed = oldParams.randomseed;
    timestamp = [timestamp; {[d, '-', num2str(c(4)), num2str(c(5))]}]; % add current date&time to old timestamp
 
end

% save / re-save basic params
save(subParamsF, 'stimTypes', 'stimTypeIdx',... 
    'randomseed', 'stimArrayFile', 'timestamp', 'blockNo', 'subNum');

% user message
disp([char(10), 'Loaded stimuli and saved out parameters/settings into params file ', subParamsF]); 

% attach stimulus type indices to stimulus array
stimArray = [stimArray, num2cell(stimTypeIdx)];

%% Init logging/result variable if there was no logging/result file

% if there was no valid log file / logging variable, init one
if ~logFileFlag
    % user message
    disp([char(10), 'Initializing a logging variable']);
    % empty cell array, insert header
    logVar = cell(1, size(logHeader, 2));
    logVar(1, :) = logHeader;
end


%% Find correct start point if there was a valid logging file

% If the last trial of a block was finished (and the block was not the last one) we 
% start with the next block. Otherwise we restart the last block.

% only if there was a valid log file
if logFileFlag
    
    % extract recorded response times and trial accuracies (use both as sanity check)
    logRT = cell2mat(logVar(2:end, strcmp(logHeader, 'respTime')));
    logAcc = cell2mat(logVar(2:end, strcmp(logHeader, 'accuracy')));
    % sanity check against bad logs
    if ~isequal(size(logRT), size(logAcc))
        error('Estimates for the number of past trials are inconsistent, investigate!');
    end
    
    % get the number of the last valid trial
    loggedRTtrialsNo = size(logRT, 1);
    % get the exact recorded trial and block numbers for last data point
    loggedTrialNo = cell2mat(logVar(loggedRTtrialsNo+1, strcmp(logHeader, 'trialNo'))); 
    loggedBlockNo = cell2mat(logVar(loggedRTtrialsNo+1, strcmp(logHeader, 'blockNo'))); 
    
    % get the trial indices for the block in question
    trialList = []; % TODO log staircase block terminations
    
    % check if the block was finished and if it was the last block
    if isequal(max(trialList), loggedTrialNo) && isequal(loggedBlockNo, blockNo)
        % let the user know, ask what to do
        disp([char(10), 'Based on the log file, the subject finished all the  blocks!']);
        inputRes = input(['Do you want the subject to restart the last block maybe? ', ...
            char(10), '(1 = Yes, restart the last block; 2 = No, exit and let me think about this...)',...
            char(10)]);
        if isequal(inputRes, 1)
            % restart last block
            disp([char(10), 'Great, we restart block ', num2str(loggedBlockNo), '!']);
            % set starting point to the start of the block
            startTrialNo = min(trialList);
            startBlockNo = loggedBlockNo;
            % user message
            disp(['We start from trial no. ', num2str(startTrialNo), '.', char(10),...
                'First block is set to ', num2str(startBlockNo)]);           
        elseif isequal(inputRes, 2)
            returnFlag = 1;
            return
        else
            warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
            returnFlag = 1;
            return
        end
        
    % if it was the last trial in block, but not the last block, start with next block 
    elseif isequal(max(trialList), loggedTrialNo) && ~isequal(loggedBlockNo, blockNo)
        % let the user know
        disp([char(10), 'Based on the log file, the subject just finished block ', num2str(loggedBlockNo),... 
            ' when the script finished.', char(10), 'We could restart from the next block by setting ',...
            'the trial number to the first one in block ', num2str(loggedBlockNo+1)]);
        inputRes = input(['Do you want the subject to restart from the ',...
            'first trial of the upcoming block (block ', num2str(loggedBlockNo+1), ')? ', ...
            char(10), '(1 = Yes, restart from the next block; 2 = No, exit and let me think about this...)',...
            char(10)]); 
        if isequal(inputRes, 1)
            % restart from upcoming block
            disp([char(10), 'Great, we restart from the upcoming block ', num2str(loggedBlockNo+1), '!']);
            % set starting point to the start of the block
            startTrialNo = loggedTrialNo+1;
            startBlockNo = loggedBlockNo+1;
            % verify that the new start point belongs to next block
            if ~isequal(blockIdx(trialIdx==startTrialNo), loggedBlockNo+1)
                error('Could not set starting trial for next block based on the existing log file, investigate!');
            end            
            % user message
            disp(['We start from trial no. ', num2str(startTrialNo), '.', char(10),...
                'First block is set to ', num2str(startBlockNo)]);                     
        elseif isequal(inputRes, 2)
            returnFlag = 1;
            return
        else
            warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
            returnFlag = 1;
            return    
        end
    
    % if trial is not the last one of the current block, we restart the last block    
    else
        disp([char(10), 'Based on the log file, the subject was performing block ', num2str(loggedBlockNo),... 
            ' but did not finish it.', char(10), 'We could restart from the beginning of that block by setting ',...
            'the trial number to the first one in block ', num2str(loggedBlockNo)]);
        inputRes = input(['Do you want the subject to restart from the ',...
            'first trial of the last block (block ', num2str(loggedBlockNo), ')? ', ...
            char(10), '(1 = Yes, restart the last block; 2 = No, exit and let me think about this...)',...
            char(10)]);    
        if isequal(inputRes, 1)
            % restart last block
            disp([char(10), 'Great, we restart the last block ', num2str(loggedBlockNo), '!']);            
             % set starting point to the start of the block
            startTrialNo = min(trialList);
            startBlockNo = loggedBlockNo;
            % user message
            disp(['We start from trial no. ', num2str(startTrialNo), '.', char(10),...
                'First block is set to ', num2str(startBlockNo)]);  
        elseif isequal(inputRes, 2)
            returnFlag = 1;
            return
        else
            warning('Invalid answer to the prompt, we exit to be rather safe than sorry!');
            returnFlag = 1;
            return       
        end
    end
    
    
else
    disp([char(10), 'We start the experiment anew, first trial is set to ', num2str(startTrialNo), '.', char(10),...
        'First block is set to ', num2str(startBlockNo)]);
    
end



return

