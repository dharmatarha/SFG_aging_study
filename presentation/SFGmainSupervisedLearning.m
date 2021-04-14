function SFGmainSupervisedLearning(subNum, varargin)
Screen('Preference', 'SkipSyncTests', 1);  % TODO remove this
%% Stochastic figure-ground experiment - main experimental script
%
% USAGE: SFGmain(subNum, stimArrayFile=./subjectXX/stimArray*.mat, blockNo=10, triggers='yes')
%
% Stimulus presentation script for stochastic figure-ground (SFG) experiment. 
% The script requires pre-generated stimuli organized into a
% "stimArrayFile". See the functions in /stimulus for details on producing
% stimuli. 
% The script also requires stim2blocksSupervisedLearning.m for sorting stimuli into blocks
% and expParamsHandlerSupervisedLearning.m for handling the loading of stimuli and existing
% parameters/settings, and also for detecting and handling earlier sessions 
% by the same subject (for multi-session experiment).
%
% Mandatory input:
% subNum        - Numeric value, one of 1:999. Subject number.
%
% Optional inputs:
% stimArrayFile - Char array, path to *.mat file containing the cell array 
%               "stimArray" that includes all stimuli + features
%               (size: no. of stimuli X 12 columns). Defaults to
%               ./subjectXX/stimArray*.mat, where XX stands for subject
%               number (subNum).
% blockNo       - Numeric value, one of 1:50. Number of blocks to sort 
%               trials into. Defaults to 10. 
% triggers      - Char array, one of {'yes', 'no'}. Sets flag for using /
%               not using TTL-level triggers used with EEG-recording.
%
% Results (response times and presentation timestamps for later checks) are
% saved out into /subjectXX/subXXLog.mat, where XX stands for subject
% number.
%
% NOTES:
% (1) Responses are counterbalanced across subjects, based on subject
% numbers (i.e., based on mod(subNum, 2)). This is a hard-coded method!!
% (2) Response keys are "L" and "S", hard-coded!!
% (3) Main psychtoolbox settings are hard-coded!! Look for the psychtoolbox
% initialization + the audio parameters code block for details
% (4) Logging (result) variable columns: 
% logHeader={'subNum', 'blockNo', 'trialNo', 'stimNo', 'toneComp',... 
%     'figCoherence', 'figPresence', 'figStartChord', 'figEndChord',... 
%     'accuracy', 'buttonResponse', 'respTime', 'iti', 'trialStart',... 
%     'soundOnset', 'figureStart', 'respIntervalStart', 'trigger'};
%
%

%% Input checks

% check no. of input args
if ~ismembertol(nargin, 1:4)
    error('Function SFGmain requires input arg "subNum" while input args "stimArrayFile", "blockNo" and "triggers" are optional!');
end
% check mandatory arg - subject number
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
% check and sort optional input args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isnumeric(varargin{v}) && ismembertol(varargin{v}, 1:50) && ~exist('blockNo', 'var')
            blockNo = varargin{v};
        elseif ischar(varargin{v}) && exist(varargin{v}, 'file') && ~exist('stimArrayFile', 'var')
            stimArrayFile = varargin{v};
        elseif ischar(varargin{v}) && ismember(varargin{v}, {'yes', 'no'}) && ~exist('triggers', 'var')
            triggers = varargin{v};    
        else
            error('An input arg could not be mapped nicely to "stimArrayFile" or "blockNo"!');
        end
    end
end
% default values
if ~exist('stimArrayFile', 'var')
    % look for any file "stimArray*.mat" in the subject's folder
    stimArrayFileStruct = dir(['subject', num2str(subNum), '/stimArray*.mat']);
    expoptFileStruct = dir(['subject', num2str(subNum), '/expopt*.mat']);
    % if there was none or there were multiple
    if isempty(stimArrayFileStruct) || length(stimArrayFileStruct)~=1
        error(['Either found too many or no stimArrayFile at ./subject', num2str(subNum), '/stimArray*.mat !!!']);
    else
        stimArrayFile = [stimArrayFileStruct.folder, '/', stimArrayFileStruct.name];
        expoptFile = [stimArrayFileStruct.folder, '/', expoptFileStruct.name];
    end
end
if ~exist('blockNo', 'var')
    blockNo = 2; % TODO
end
if ~exist('triggers', 'var')
    triggers = 'no'; % TODO undo this after setting up triggers
end

% turn input arg "triggers" into boolean
if strcmp(triggers, 'yes')
    triggers = true;
else
    triggers = false;
end

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([char(10), 'Called SFGmain (the main experimental function) with input args: ',...
    char(10), 'subNum: ', num2str(subNum),...
    char(10), 'stimArrayFile:', stimArrayFile,...
    char(10), 'blockNo: ', num2str(blockNo)]);


%% Load/set params, stimuli, check for conflicts

% user message
disp([char(10), 'Loading params and stimuli, checking ',...
    'for existing files for the subject']);

% a function handles all stimulus sorting to blocks and potential conflicts
% with earlier recordings for same subject
[stimArray, ~,... 
    startBlockNo,...
    logVar, subLogF, returnFlag,... 
    logHeader, stimTypes] = expParamsHandlerSupervisedLearning(subNum, stimArrayFile, blockNo);

%%%%%%%%%%%%%%%%%%%%%% HARDCODED BREAKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
breakBlocks = [4, 7];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if there was early return from expParamsHandlerSupervisedLearning.m, abort
if returnFlag
    return
end

% user message
disp([char(10), 'Ready to start the experiment']);


%% Audio parameters for PsychPortAudio

% audio params
% sampling rate is derived from stimuli
fs = cell2mat(stimArray(:, 8));
% sanity check - there should be only one fs value
if ~isequal(length(unique(fs)), 1)
    error([char(10), 'There are multiple different sampling rates ',...
        'specified in the stimulus array!']);
else
    fs = unique(fs);
end

% get correct audio device
device = [];  % system default is our default as well
% we only change audio device in the lab, when we see the correct audio
% card
tmpDevices = PsychPortAudio('GetDevices');
for i = 1:numel(tmpDevices)
    if strcmp(tmpDevices(i).DeviceName, 'ESI Juli@: ICE1724 (hw:2,0)')
        device = tmpDevices(i).DeviceIndex;
    end
end

% mode is simple playback
mode = 1;
% reqlatencyclass is set to low-latency
reqLatencyClass = 2;
% 2 channels output
nrChannels = 2;

% user message
disp([char(10), 'Set audio parameters']);


%% Stimulus features for triggers + logging

% get figure presence/absence variable for stimuli
stepSizes = cell2mat(stimArray(:, 7));
% figure / added noise start and end time in terms of chords
figStartCord = cell2mat(stimArray(:, 9));

% we check the length of stimuli + sanity check
stimLength = cell2mat(stimArray(:, 2));
if ~isequal(length(unique(stimLength)), 1)
    error([char(10), 'There are multiple different stimulus length values ',...
        'specified in the stimulus array!']);
else
    stimLength = unique(stimLength);
end

% we also check the length of a cord + sanity check
chordLength = cell2mat(stimArray(:, 3));
if ~isequal(length(unique(chordLength)), 1)
    error([char(10), 'There are multiple different chord length values ',...
        'specified in the stimulus array!']);
else
    chordLength = unique(chordLength);
end

% user message
disp([char(10), 'Extracted stimulus features']);


%% Triggers

% basic triggers for trial start, sound onset and response
trig = struct;
trig.trialStart = 200;
trig.playbackStart = 210;
trig.respPresent = 220;
trig.respAbsent = 230;
trig.l = 1000; % trigger length in microseconds
trig.blockStart = 100;

% triggers for stimulus types, based on the number of unique stimulus types
% we assume that stimTypes is a cell array (with headers) that contains the 
% unique stimulus feature combinations, with an index for each combination 
% in the last column
uniqueStimTypes = cell2mat(stimTypes(2:end,end));
if length(uniqueStimTypes) > 4900
    error('Too many stimulus types for properly triggering them');
end
% triggers for stimulus types are integers in the range 151-199
trigTypes = uniqueStimTypes+150;
% add trigger info to stimTypes cell array as an extra column
stimTypes = [stimTypes, [{'trigger'}; num2cell(trigTypes)]];

% create triggers for stimulus types, for all trials
trig.stimType = cell2mat(stimArray(:, 13))+150;

% add triggers to logging / results variable
% logVar(2:end, strcmp(logHeader, 'trigger')) = num2cell(trig.stimType);
% TODO add triggers as the staircase runs

% user message
disp([newline, 'Set up triggers']);


%% Psychtoolbox initialization

% General init (AssertOpenGL, 'UnifyKeyNames')
PsychDefaultSetup(1);

% init PsychPortAudio with pushing for lowest possible latency
InitializePsychSound(1);

% Keyboard params - names
KbNameSub = 'Logitech USB Keyboard';
KbNameExp = 'CASUE USB KB';
% detect attached devices
[keyboardIndices, productNames, ~] = GetKeyboardIndices;
% define subject's and experimenter keyboards
KbIdxSub = keyboardIndices(ismember(productNames, KbNameSub));
KbIdxExp = keyboardIndices(ismember(productNames, KbNameExp));

% Define the specific keys we use
keys = struct;
keys.abort = KbName('ESCAPE');
keys.go = KbName('SPACE');
% counterbalancing response side across subjects, based on subject number
if mod(subNum, 2) == 0
    keys.figPresent = KbName('l');
    keys.figAbsent = KbName('s');
else
    keys.figPresent = KbName('s');
    keys.figAbsent = KbName('l');
end

% restrict keys to the ones we use
keysFields = fieldnames(keys);
keysVector = zeros(1, length(keysFields));
for f = 1:length(keysFields)
    keysVector(f) = keys.(keysFields{f});
end
RestrictKeysForKbCheck(keysVector);

% Force costly mex functions into memory to avoid latency later on
GetSecs; WaitSecs(0.1); KbCheck();

% screen params, screen selection
backGroundColor = [0 0 0];
textColor = [255 255 255];
screens=Screen('Screens');
screenNumber=max(screens);  % look into XOrgConfCreator and XOrgConfSelector 

% open stimulus window
[win, rect] = Screen('OpenWindow', screenNumber, backGroundColor);

% query frame duration for window
ifi = Screen('GetFlipInterval', win);
% set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Setup the text type for the window
Screen('TextFont', win, 'Ariel');
Screen('TextSize', win, 30);

% set up a central fixation cross into a texture / offscreen window
% get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(rect);
% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;
% set the coordinates
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
% set the line width for our fixation cross
lineWidthPix = 4;
% command to draw the fixation cross
fixCrossWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
Screen('BlendFunction', fixCrossWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('DrawLines', fixCrossWin, allCoords,...
    lineWidthPix, textColor, [xCenter yCenter], 2);

% set up the question mark (stimulus marking response period) into a
% texture / offscreen window
qMarkWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
Screen('BlendFunction', qMarkWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextSize', qMarkWin, 50);
Screen('DrawText', qMarkWin, '?', xCenter-15, yCenter-15, textColor);

% open PsychPortAudio device for playback
pahandle = PsychPortAudio('Open', device, mode, reqLatencyClass, fs, nrChannels);

% get and display device status
pahandleStatus = PsychPortAudio('GetStatus', pahandle);
disp([char(10), 'PsychPortAudio device status: ']);
disp(pahandleStatus);

% initial start & stop of audio device to avoid potential initial latencies
tmpSound = zeros(2, fs/10);  % silence
tmpBuffer = PsychPortAudio('CreateBuffer', [], tmpSound);  % create buffer
PsychPortAudio('FillBuffer', pahandle, tmpBuffer);  % fill the buffer of audio device with silence
PsychPortAudio('Start', pahandle, 1);  % start immediately
PsychPortAudio('Stop', pahandle, 1);  % stop when playback is over

% set random ITI between 500-800 ms, with round 100 ms values
iti = (randi(4, [size(stimArray, 1) 1])+4)/10;  % in secs

% response time interval
respInt = 2;

% response variables preallocation
detectedDirection = nan(size(stimArray, 1), 1);
respTime = detectedDirection;
acc = detectedDirection;

% set flag for aborting experiment
abortFlag = 0;
% hide mouse
% HideCursor(screenNumber);
% suppress keyboard input to command window
% ListenChar(-1);
% realtime priority
Priority(1);

% minimum wait time for breaks in secs
breakTimeMin = 120;

if triggers
    % init parallel port control
    ppdev_mex('Open', 1);
end

% user message
disp([char(10), 'Initialized psychtoolbox basics, opened window, ',...
    'started PsychPortAudio device']);


%% Instructions phase

% instructions text
instrText = ['A feladat ugyanaz lesz, mint az előző blokkok során - \n',... 
    'jelezze, hogy a hangmintában emelkedő vagy ereszkedő hangsort hall.\n\n',...
    'Emelkedő hangsor a hangmintában - "', KbName(keys.figPresent), '" billentyű. \n',... 
    'Ereszkedő hangsor a hangmintában - "' ,KbName(keys.figAbsent), '" billentyű. \n\n',...
    'Mindig akkor válaszoljon, amikor megjelenik a kérdőjel.\n\n',...
    'Nyomja meg a SPACE billentyűt ha készen áll!'];

% write instructions to text
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, instrText, 'center', 'center', textColor);
Screen('Flip', win);

% user message
disp([char(10), 'Showing the instructions text right now...']);

% wait for key press to start
while 1
    [keyIsDownSub, ~, keyCodeSub] = KbCheck(KbIdxSub);
    [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
    % subject key down
    if keyIsDownSub 
        % if subject is ready to start
        if find(keyCodeSub) == keys.go
            break;
        end
    % experimenter key down    
    elseif keyIsDownExp
        % if abort was requested    
        if find(keyCodeExp) == keys.abort
            abortFlag = 1;
            break;
        end
    end
end
if abortFlag
    if triggers
        ppdev_mex('Close', 1);
    end
    ListenChar(0);
    Priority(0);
    RestrictKeysForKbCheck([]);
    PsychPortAudio('Close');
    Screen('CloseAll');
    ShowCursor(screenNumber);
    return;
end

% user message
disp([char(10), 'Subject signalled she/he is ready, we go ahead with the task']);

%% Preload all stimuli

expopt = load(expoptFile, 'expopt');

buffer = [];
for i = 1:size(stimArray,1)
    audioData = stimArray{i, 12};
    buffer(end+1) = PsychPortAudio('CreateBuffer', [], audioData');
end

% Exit conditions:
minTrialCount = 100; % TODO 100
minReversalCount = 7; % TODO 10

%% Blocks loop

% overall trial counter
trial = 0;

% start from the block specified by the parameters/settings parts
for block = startBlockNo:blockNo
    
    reversalCount = 0;

    % uniform background
    Screen('FillRect', win, backGroundColor);
    Screen('Flip', win);    
    
    % wait for releasing keys before going on
    releaseStart = GetSecs;
    KbReleaseWait([], releaseStart+2);

    % counter for trials in given block
    trialCounterForBlock = 0;    
    
    % user message
    disp([char(10), 'Buffered all stimuli for block ', num2str(block),... 
        ', showing block start message']);    
     
    % block starting text
    blockStartText = ['Kezdhetjük a(z) ', num2str(block), '. blokkot,\n\n\n',... 
            'Nyomja meg a SPACE billentyűt ha készen áll!'];
    
    % uniform background
    Screen('FillRect', win, backGroundColor);
    % draw block-starting text
    DrawFormattedText(win, blockStartText, 'center', 'center', textColor);
    Screen('Flip', win);
    % wait for key press to start
    while 1
        [keyIsDownSub, ~, keyCodeSub] = KbCheck(KbIdxSub);
        [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
        % subject key down
        if keyIsDownSub 
            % if subject is ready to start
            if find(keyCodeSub) == keys.go
                break;
            end
        % experimenter key down    
        elseif keyIsDownExp
            % if abort was requested    
            if find(keyCodeExp) == keys.abort
                abortFlag = 1;
                break;
            end
        end
    end
    if abortFlag
        if triggers
            ppdev_mex('Close', 1);
        end
        ListenChar(0);
        Priority(0);
        RestrictKeysForKbCheck([]);
        PsychPortAudio('Close');
        Screen('CloseAll');
        ShowCursor(screenNumber);
        return;
    end    
    
    if triggers
        % block start trigger + block number trigger
        lptwrite(1, trig.blockStart, trig.l);
        WaitSecs(0.005);
        lptwrite(1, trig.blockStart+block, trig.l);
    end
    
    
    %% Trials loop
    
    % TODO
    initialStepSize = 80;
    staircaseHitThreshold = 3;
    staircaseMissThreshold = 1;
    
    stepSize = initialStepSize;
    hitsInARow = 0;
    missesInARow = 0;
    direction = 0;
    staircaseTendency = 0;
    
    toneCompConditions = [expopt.expopt.toneCompHigh, expopt.expopt.toneCompLow];
    directionConditions = [-1, 1];
    
    % trial loop (over the trials for given block)
    while ~(trialCounterForBlock >= minTrialCount && reversalCount >= minReversalCount)
        
        % randomize parameters
        toneComp = toneCompConditions(randi(2));
        direction = directionConditions(randi(2));
        desiredStepSize = stepSize * direction;
        disp(['Step size:', num2str(desiredStepSize)]);
        
        filteredStimIndexes = find(cell2mat(stimArray(:,7))==desiredStepSize & cell2mat(stimArray(:,11))-cell2mat(stimArray(:,6))==toneComp);
        stimIndex = filteredStimIndexes(randi(length(filteredStimIndexes)));
        disp(['StimIndex: ', num2str(stimIndex)]);
        
        % relative trial number (trial in given block)
        trialCounterForBlock = trialCounterForBlock+1;
       
        % absolute trial number
        trial = trial + 1;
        
        % background with fixation cross, get trial start timestamp
        Screen('CopyWindow', fixCrossWin, win);
        Screen('DrawingFinished', win);
        trialStart = Screen('Flip', win); 
        
        if triggers
            % trial start trigger + trial type trigger
            lptwrite(1, trig.trialStart, trig.l);
            WaitSecs(0.005);
            lptwrite(1, trig.stimType(trial), trig.l);
        end
        
        % user message
        disp([newline, 'Starting trial ', num2str(trialCounterForBlock)]);
        if stepSizes(stimIndex) > 0
            disp('There is an ascending figure in this trial');
        elseif stepSizes(stimIndex) < 0
            disp('There is a descending figure in this trial');
        end

        % fill audio buffer with next stimuli
        PsychPortAudio('FillBuffer', pahandle, buffer(stimIndex));
        
        % wait till we are 100 ms from the start of the playback
        while GetSecs-trialStart <= iti(trialCounterForBlock)-100
            WaitSecs(0.001);
        end
        
        % blocking playback start for precision
        startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti(trial), 1);
        
        % playback start trigger
        if triggers
            lptwrite(1, trig.playbackStart, trig.l);
        end
        
        % user message
        disp(['Audio started at ', num2str(startTime-trialStart), ' secs after trial start']);
        disp(['(Target ITI was ', num2str(iti(trial)), ' secs)']);
        
        % prepare screen change for response period       
        Screen('CopyWindow', qMarkWin, win);
        Screen('DrawingFinished', win);
        
        % switch visual right when the audio finishes
        respStart = Screen('Flip', win, startTime+stimLength-0.5*ifi);
        
        % user message
        disp(['Visual flip for response period start was ', num2str(respStart-startTime),... 
            ' secs after audio start (should equal ', num2str(stimLength), ')']);
        
        % wait for response
        respFlag = 0;
        while GetSecs-(startTime+stimLength) <= respInt
            [keyIsDownSub, respSecs, keyCodeSub] = KbCheck(KbIdxSub);
            [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
            % subject key down
            if keyIsDownSub
                % if subject responded figure presence/absence
                if find(keyCodeSub) == keys.figPresent
                    detectedDirection(trial) = 1;
                    respFlag = 1;
                    % response trigger
                    if triggers
                        lptwrite(1, trig.respPresent, trig.l);
                    end
                    break;
                elseif find(keyCodeSub) == keys.figAbsent
                    detectedDirection(trial) = -1;
                    respFlag = 1;
                    % response trigger
                    if triggers
                        lptwrite(1, trig.respAbsent, trig.l);
                    end
                    break;
                end
            % experimenter key down    
            elseif keyIsDownExp
                % if abort was requested    
                if find(keyCodeExp) == keys.abort
                    abortFlag = 1;
                    break;
                end
            end
        end
        
        % if abort was requested, quit
        if abortFlag
            if triggers
                ppdev_mex('Close', 1);
            end
            ListenChar(0);
            Priority(0);
            RestrictKeysForKbCheck([]);
            PsychPortAudio('Close');
            Screen('CloseAll');
            ShowCursor(screenNumber);
            return;
        end        
        
        % response time into results variable
        if respFlag
            respTime(trial) = 1000*(respSecs-respStart);
        end
        
        % user messages
        if detectedDirection(trial) == 1
            disp('Subject detected an ascending figure');    
        elseif detectedDirection(trial) == -1
            disp('Subject detected a descending figure');
        elseif isnan(detectedDirection(trial))
            disp('Subject did not respond in time');
        end
        % accuraccy
        if (detectedDirection(trial)==1 && desiredStepSize > 0) || (detectedDirection(trial)==-1 && desiredStepSize < 0)
            disp('Subject''s response was accurate');
            acc(trial) = 1;
            hitsInARow = hitsInARow + 1;
            missesInARow = 0;
            disp(['Hits in a row:', num2str(hitsInARow)]);
            if staircaseTendency == 0
                staircaseTendency = -1;
            end
            if hitsInARow == staircaseHitThreshold
                hitsInARow = 0;
                stepSize = stepSize - 1;
                if staircaseTendency == 1
                    staircaseTendency = -1;
                    reversalCount = reversalCount + 1;
                    disp(['REVERSAL nr. ', num2str(reversalCount)]);
                end
            end
        elseif (detectedDirection(trial)==1 && desiredStepSize < 0) || (detectedDirection(trial)==-1 && desiredStepSize > 0)
            disp('Subject made an error');
            acc(trial) = 0;
            missesInARow = missesInARow + 1;
            hitsInARow = 0;
            disp(['Misses in a row:', num2str(missesInARow)]);
            if staircaseTendency == 0
                staircaseTendency = -1;
            end
            if missesInARow == staircaseMissThreshold
                stepSize = stepSize + 1;
                if staircaseTendency == -1
                    staircaseTendency = 1;
                    reversalCount = reversalCount + 1;
                    disp(['REVERSAL nr. ', num2str(reversalCount)]);
                end
            end
        end
        % response time
        if ~isnan(respTime(trial))
            disp(['Response time was ', num2str(respTime(trial)), ' ms']);
        end
        % cumulative accuraccy
        % in block
        blockAcc = sum(acc(trial-trialCounterForBlock+1:trial), 'omitnan')/trialCounterForBlock*100;
        disp(['Overall accuraccy in block so far is ', num2str(blockAcc), '%']);
        
        % accumulating all results in logging / results variable
            
        stimFileName = cell2mat(stimArray(stimIndex, 1));
        toneComp = cell2mat(stimArray(stimIndex, 11));
        figCoherence = cell2mat(stimArray(stimIndex, 6));
        figStepSize = cell2mat(stimArray(stimIndex, 7));
        figStartChord = cell2mat(stimArray(stimIndex, 9));
        figEndChord = cell2mat(stimArray(stimIndex, 10));
    
        logVar(end+1, 1:end-1) = {subNum, block, trial, stimFileName, toneComp, ...
            figCoherence, figStepSize, figStartChord, figEndChord...
            acc(trial), detectedDirection(trial),... 
            respTime(trial), iti(trial),...
            trialStart, startTime-trialStart,... 
            (figStartCord(trial)-1)*chordLength,... 
            respStart-startTime};
        
        % save logging/results variable
        save(subLogF, 'logVar');
        
    end  % trial for loop
     
    % Workaround for a command window text display bug - too much printing to
    % command window results in garbled text, see e.g.
    % https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
    % Calling "clc" from time to time prevents the bug from making everything
    % unreadable
    clc;    
    
    % false alarm rate in block
    blockFalseAlarm = sum(acc(trial-trialCounterForBlock+1:trial)==0 &... 
        stepSizes(trial-trialCounterForBlock+1:trial)==0)/trialCounterForBlock*100;
    % user messages
    disp([char(10), char(10), 'Block no. ', num2str(block), ' has ended,'... 
        'showing block-ending text to participant']);
    disp([char(10), 'Overall accuracy in block was ', num2str(blockAcc),... 
        '%; false alarm rate was ', num2str(blockFalseAlarm), '%']);    
    
    
    %% Feedback to subject at the end of block
    % if not last block and not a break
    if (block ~= blockNo) && ~ismembertol(block, breakBlocks)        
        
        % block ending text
        blockEndText = ['Vége a(z) ', num2str(block), '. blokknak!\n\n\n',... 
                'Ebben a blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n\n',... 
                'Nyomja meg a SPACE billentyűt ha készen áll a következő blokkra!'];
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);   
        Screen('Flip', win);
        % wait for key press to start
        while 1
            [keyIsDownSub, ~, keyCodeSub] = KbCheck(KbIdxSub);
            [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
            % subject key down
            if keyIsDownSub 
                % if subject is ready to start
                if find(keyCodeSub) == keys.go
                    break;
                end
            % experimenter key down    
            elseif keyIsDownExp
                % if abort was requested    
                if find(keyCodeExp) == keys.abort
                    abortFlag = 1;
                    break;
                end
            end
        end
        if abortFlag
            if triggers
                ppdev_mex('Close', 1);
            end
            ListenChar(0);
            Priority(0);
            RestrictKeysForKbCheck([]);
            PsychPortAudio('Close');
            Screen('CloseAll');
            ShowCursor(screenNumber);
            return;
        end  
    
    % if not last block and there is a break
    elseif (block ~= blockNo) && ismembertol(block, breakBlocks)
        
        % user message
        disp([char(10), 'There is a BREAK now!']);
        disp('Only the experimenter can start the next block - press "SPACE" when ready');
        
        % block ending text
        blockEndText = ['Vége a(z) ', num2str(block), '. blokknak!\n\n\n',... 
                'Ebben a blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n\n',... 
                'Most tartunk egy rövid szünetet, a kísérletvezető hamarosan beszél Önnel.'];
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);   
        Screen('Flip', win);
        
        % approximate wait time 
        
        % wait for key press to start
        while 1
            [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
            % experimenter key down
            if keyIsDownExp 
                % if subject is ready to start
                if find(keyCodeExp) == keys.go
                    break;
                % if abort was requested    
                elseif find(keyCodeExp) == keys.abort
                    abortFlag = 1;
                    break;
                end
            end
        end
        if abortFlag
            if triggers
                ppdev_mex('Close', 1);
            end
            ListenChar(0);
            Priority(0);
            RestrictKeysForKbCheck([]);
            PsychPortAudio('Close');
            Screen('CloseAll');
            ShowCursor(screenNumber);
            return;
        end      
        
        
    % if last block ended now   
    elseif block == blockNo
 
        % user message
        disp([char(10), 'The task has ended!!!']);
        
        % block ending text
        blockEndText = ['Vége a feladatnak!\n',...
            'Az utolsó blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n',...
            'Köszönjük a részvételt!'];       
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
        Screen('Flip', win);
        
        WaitSecs(5);
        
    end  % if block       
         
    
end  % block for loop


%% Ending, cleaning up

disp(' ');
disp('Got to the end!');

if triggers
    ppdev_mex('Close', 1);
end
ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
Screen('CloseAll');
ShowCursor(screenNumber);


return


    
  
    