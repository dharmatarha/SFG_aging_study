function SFGmain(subNum, varargin)
%% Stochastic figure-ground experiment - main experimental script
%
% USAGE: SFGmain(subNum, stimArrayFile=./subjectXX/stimArray*.mat, blockNo=10, triggers='yes')
%
% Stimulus presentation script for stochastic figure-ground (SFG) experiment. 
% The script requires pre-generated stimuli organized into a
% "stimArrayFile". See the functions in /stimulus for details on producing
% stimuli. 
% The script also requires stim2blocks.m for sorting stimuli into blocks
% and expParamsHandler.m for handling the loading of stimuli and existing
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
    % if there was none or there were multiple
    if isempty(stimArrayFileStruct) || length(stimArrayFileStruct)~=1
        error(['Either found too many or no stimArrayFile at ./subject', num2str(subNum), '/stimArray*.mat !!!']);
    else
        stimArrayFile = [stimArrayFileStruct.folder, '/', stimArrayFileStruct.name];
    end
end
if ~exist('blockNo', 'var')
    blockNo = 10;
end
if ~exist('triggers', 'var')
    triggers = 'yes';
end

% turn input arg "triggers" into boolean
if strcmp(triggers, 'yes')
    triggers = true;
else
    triggers = false;
end

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
[stimArray, ~, ~,... 
    startBlockNo, blockIdx, trialIdx,...
    logVar, subLogF, returnFlag,... 
    logHeader, stimTypes] = expParamsHandler(subNum, stimArrayFile, blockNo);

% if there was early return from expParamsHandler.m, abort
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
figStim = cell2mat(logVar(2:end, strcmp(logHeader, 'figPresence')));
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
if length(uniqueStimTypes) > 49
    error('Too many stimulus types for properly triggering them');
end
% triggers for stimulus types are integers in the range 151-199
trigTypes = uniqueStimTypes+150;
% add trigger info to stimTypes cell array as an extra column
stimTypes = [stimTypes, [{'trigger'}; num2cell(trigTypes)]];

% create triggers for stimulus types, for all trials
trig.stimType = cell2mat(stimArray(:, 13))+150;

% add triggers to logging / results variable
logVar(2:end, strcmp(logHeader, 'trigger')) = num2cell(trig.stimType);

% user message
disp([char(10), 'Set up triggers']);


%% Psychtoolbox initialization

% General init (AssertOpenGL, 'UnifyKeyNames')
PsychDefaultSetup(1);

% init PsychPortAudio with pushing for lowest possible latency
InitializePsychSound(1);

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
Screen('TextSize', win, 26);

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
figDetect = nan(size(stimArray, 1), 1);
respTime = figDetect;
acc = figDetect;

% set flag for aborting experiment
abortFlag = 0;
% hide mouse
HideCursor(screenNumber);
% suppress keyboard input to command window
ListenChar(-1);
% realtime priority
Priority(1);

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
    'jelezze, ha a hangmintában hall egy emelkedő hangsort.\n\n',...
    '1 - hangmintában van emelkedő hangsor - "', KbName(keys.figPresent), '" billentyű \n',... 
    '2 - hangmintában nincs emelkedő hangsor - "' ,KbName(keys.figAbsent), '" billentyű \n\n',...
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
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown 
        % if subject is ready to start
        if find(keyCode) == keys.go
            break;
        % if abort was requested    
        elseif find(keyCode) == keys.abort
            abortFlag = 1;
            break
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


%% Blocks loop

% start from the block specified by the parameters/settings parts
for block = startBlockNo:blockNo

    % uniform background
    Screen('FillRect', win, backGroundColor);
    Screen('Flip', win);    
    
    % wait for releasing keys before going on
    releaseStart = GetSecs;
    KbReleaseWait([], releaseStart+2);
    
    % fill a dynamic buffer with data for whole block
    % get trial index list for current block
    trialList = trialIdx(blockIdx==block);
    buffer = [];
    for trial = min(trialList):max(trialList)
        audioData = stimArray{trial, 12};
        buffer(end+1) = PsychPortAudio('CreateBuffer', [], audioData');
    end

    % counter for trials in given block
    trialCounterForBlock = 0;    
    
    % user message
    disp([char(10), 'Buffered all stimuli for block ', num2str(block),... 
        ', showing block start message']);    
     
    % block starting text
    blockStartText = ['Kezdhetjük a(z) ', num2str(block), '. blokkot,\n\n',... 
            'mint mindegyik, ez is ', num2str(length(trialList)), ' próbából fog állni.\n\n\n',... 
            'Nyomja meg a SPACE billentyűt ha készen áll!'];
    
    % uniform background
    Screen('FillRect', win, backGroundColor);
    % draw block-starting text
    DrawFormattedText(win, blockStartText, 'center', 'center', textColor);
    Screen('Flip', win);
    % wait for key press to start
    while 1
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown 
            % if subject is ready to start
            if find(keyCode) == keys.go
                break;
            % if abort was requested    
            elseif find(keyCode) == keys.abort
                abortFlag = 1;
                break
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
    
    % trial loop (over the trials for given block)
    for trial = min(trialList):max(trialList)

        % relative trial number (trial in given block)
        trialCounterForBlock = trialCounterForBlock+1;
        
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
        disp([char(10), 'Starting trial ', num2str(trialCounterForBlock)]);
        if figStim(trial)
            disp('There is a figure in this trial');
        elseif ~figStim(trial)
            disp('There is no figure in this trial');
        end

        % fill audio buffer with next stimuli
        PsychPortAudio('FillBuffer', pahandle, buffer(trialCounterForBlock));
        
        % wait till we are 100 ms from the start of the playback
        while GetSecs-trialStart <= iti(trial)-100
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
            [keyIsDown, respSecs, keyCode] = KbCheck;
            if keyIsDown
                % if subject responded figure presence/absence
                if find(keyCode) == keys.figPresent
                    figDetect(trial) = 1;
                    respFlag = 1;
                    % response trigger
                    if triggers
                        lptwrite(1, trig.respPresent, trig.l);
                    end
                    break;
                elseif find(keyCode) == keys.figAbsent
                    figDetect(trial) = 0;
                    respFlag = 1;
                    % response trigger
                    if triggers
                        lptwrite(1, trig.respAbsent, trig.l);
                    end
                    break;
                % if abort was requested    
                elseif find(keyCode) == keys.abort
                    abortFlag = 1;
                    break
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
        if figDetect(trial) == 1
            disp('Subject detected a figure');    
        elseif figDetect(trial) == 0
            disp('Subject detected no figure');
        elseif isnan(figDetect(trial))
            disp('Subject did not respond in time');
        end
        % accuraccy
        if (figDetect(trial)==1 && figStim(trial)) || (figDetect(trial)==0 && ~figStim(trial))
            disp('Subject''s response was accurate');
            acc(trial) = 1;
        elseif (figDetect(trial)==1 && ~figStim(trial)) || (figDetect(trial)==0 && figStim(trial))
            disp('Subject made an error');
            acc(trial) = 0;
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
        logVar(trial+1, 10:end-1) = {acc(trial), figDetect(trial),... 
            respTime(trial), iti(trial),...
            trialStart, startTime-trialStart,... 
            (figStartCord(trial)-1)*chordLength,... 
            respStart-startTime};
        
        % save logging/results variable
        save(subLogF, 'logVar');
        
    end  % trial for loop
    
    
    % feedback to subject
    % if not last block
    if block ~= blockNo
        
        % user message
        disp([char(10), 'Block no. ', num2str(block), ' has ended,'... 
            'showing block-ending text']);
        
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
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown 
                % if subject is ready to start
                if find(keyCode) == keys.go
                    break;
                % if abort was requested    
                elseif find(keyCode) == keys.abort
                    abortFlag = 1;
                    break
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
        blockEndText = ['Vége a feladatnak, köszönjük a részvételt!'];       
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
        Screen('Flip', win);
        
        WaitSecs(5);
        
    end        
            
end  % block for loop
    

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


    
  
    