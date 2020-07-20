function SFGtraining(subNum, stimArrayFile)
%% Stochastic figure-ground experiment - training phase script
%
% USAGE: SFGtraining(subNum, stimArrayFile='stimArrayTraining.mat')
%
% Stimulus presentation script for the training phase of the 
% stochastic figure-ground (SFG) experiment. 
% The script requires pre-generated stimuli organized into a
% "stimArrayFile". See the functions in /stimulus for details on producing
% stimuli. 
%
% The script also requires stim2blocksTraining.m for sorting stimuli into
% blocks.
%
% Mandatory input:
% subNum        - Numeric value, one of 1:999. Subject number.
%
% Optional input:
% stimArrayFile - Char array, path to *.mat file with cell array  
%               "stimArray" containing all stimuli + features 
%               (size: no. of stimuli X 11 columns), defaults to 
%               'stimArrayTraining.mat'
% 
% Results (response times and presentation timestamps for later checks) are
% saved out into /subjectXX/training_subXXLog_"timestamp".mat, where XX 
% stands for subject number.
%
% NOTES:
% (1) Responses are counterbalanced across subjects, based on subject
% numbers (i.e., based on mod(subNum, 2)). This is a hard-coded method!!
% (2) Response keys are "L" and "S", hard-coded!!
% (3) Main psychtoolbox settings are hard-coded!! Look for the psychtoolbox
% initialization + the audio parameters code block for details
% (4) Logging (result) variable columns: 
% logHeader={'subNum', 'blockNo', 'trialNo', 'stimNo', 'figDuration',... 
%     'figCoherence', 'figPresence', 'figStartChord', 'figEndChord', 'figStepS',... 
%     'accuracy', 'buttonResponse', 'respTime', 'iti', 'trialStart', 'soundOnset',... 
%     'figureStart', 'respIntervalStart'};
%


%% Input checks

if ~ismembertol(nargin, 1:2) 
    error('Function SFGtraining requires input arg "subNum" while input arg "stimArrayFile" is optional!');
end
if nargin == 1
    stimArrayFile = 'stimArrayTraining.mat';
end
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
if ~exist(stimArrayFile, 'file')
    error(['Cannot find stimulus file at ', stimArrayFile, '!']);
end

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([char(10), 'Called SFG training function with input args: ',...
    char(10), 'subject number: ', num2str(subNum),...
    char(10), 'stimArrayFile: ', stimArrayFile]);


%% Load/set params, stimuli, set folder, etc

% user message
disp([char(10), 'Loading params and stimuli']);

% stimuli sorting is handled by stim2blocksTraining
[blockIdx, stimTypes, stimTypeIdx,... 
    stimArray, trialIdx] = stim2blocksTraining(stimArrayFile);

% set block number variable based on blockIdx
blockNo = length(unique(blockIdx));

% attach stimulus type indices, block and trial indices to stimulus
% array - but first a quick sanity check of stimArray size
if ~isequal(size(stimArray), [length(trialIdx), 11])
    error('Stimulus cell array ("stimArray") has unexpected size, investigate!');
end
stimArray = [stimArray, num2cell(stimTypeIdx), num2cell(blockIdx), num2cell(trialIdx)];
% sort into trial order
[stimArray, sortIndices] = sortrows(stimArray, size(stimArray, 2));

% subject folder name
dirN = ['subject', num2str(subNum)];
% check if subject folder already exists, create if necessary
if ~exist(dirN, 'dir')
    % create a folder for subject if there was none
    mkdir(dirN);
    disp([char(10), 'Created folder for subject at ', dirN]);
end

% date and time of starting with a subject
c = clock; d = date;
timestamp = {[d, '-', num2str(c(4)), num2str(c(5))]};
% subject log file for training
subLogF = [dirN, '/training_sub', num2str(subNum), 'Log_', timestamp{1}, '.mat'];

disp([char(10), 'Initializing a logging variable']);
% log header
logHeader={'subNum', 'blockNo', 'trialNo', 'stimNo', 'figDuration',... 
    'figCoherence', 'figPresence', 'figStartChord', 'figEndChord', 'figStepS',... 
    'accuracy', 'buttonResponse', 'respTime', 'iti', 'trialStart', 'soundOnset',... 
    'figureStart', 'respIntervalStart'};
% empty cell array, insert header
logVar = cell(size(stimArray, 1)+1, size(logHeader, 2));
logVar(1, :) = logHeader;
% insert known columns in advance
logVar(2:end, strcmp(logHeader, 'subNum')) = num2cell(repmat(subNum, [size(stimArray, 1), 1]));  % subNum
logVar(2:end, strcmp(logHeader, 'blockNo')) = stimArray(:, 13);  % blockNo
logVar(2:end, strcmp(logHeader, 'trialNo')) = stimArray(:, 14);  % trialNo
logVar(2:end, strcmp(logHeader, 'stimNo')) = num2cell(sortIndices);  % stimNo - original stimArray row numbers (ie. stimulus numbers) before applying sortrows
logVar(2:end, strcmp(logHeader, 'figDuration')) = stimArray(:, 5);  % figure duration in chords
logVar(2:end, strcmp(logHeader, 'figCoherence')) = stimArray(:, 6);  % figure coherence in chords
logVar(2:end, strcmp(logHeader, 'figPresence')) = num2cell(cell2mat(stimArray(:, 6))~=0);  % figure presence/absence
logVar(2:end, strcmp(logHeader, 'figStartChord')) = stimArray(:, 9);  % figure start in terms of chords
logVar(2:end, strcmp(logHeader, 'figEndChord')) = stimArray(:, 10);  % figure start in terms of chords
logVar(2:end, strcmp(logHeader, 'figStepS')) = stimArray(:, 7);  % figure start in terms of chords

% user message
disp([char(10), 'Ready to start the experiment']);


%% Set starting point

disp([char(10), 'There are trials pre-sorted for blocks:']);
disp(num2str(unique(blockIdx)'));
inpRes = input([char(10), 'Which training block do we start from? Just type 1 if you do not know!', char(10)]);
if ismember(inpRes, unique(blockIdx)')
    disp([char(10), 'Got it, we start from training block ', num2str(inpRes), char(10)]);
    startBlockNo = inpRes;
else
    disp([char(10), 'Not a valid answer, we exit to be rather safe than sorry', char(10)]);
    return;
end
    

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


%% Stimulus features for logging

% get figure presence/absence variable for stimuli
figStim = cell2mat(logVar(2:end, strcmp(logHeader, 'figPresence')));
% figure start and end time in terms of chords
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

% set up "correct" feedback screen
okRespWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
Screen('BlendFunction', okRespWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextSize', okRespWin, 26);
Screen('DrawText', okRespWin, 'Jó válasz!', xCenter-50, yCenter-15, textColor);
% set up "incorrect" feedback screen
badRespWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
Screen('BlendFunction', badRespWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextSize', badRespWin, 26);
Screen('DrawText', badRespWin, 'Nem jó válasz!', xCenter-70, yCenter-15, textColor);

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

% user message
disp([char(10), 'Initialized psychtoolbox basics, opened window, ',...
    'started PsychPortAudio device']);


%% Instructions phase

% instructions text
instrText = ['A feladatot rövid blokkokban fogjuk elvégezni.\n\n',...
    'Először hat gyakorló blokk következik, ezek egyre nehezebbek lesznek. \n',... 
    'Minden blokkban tíz hangot hall majd. \n\n',...
    'A hangminták fele tartalmaz emelkedő hangsort, a másik fele nem. \n',...
    'Kérjük, minden hangminta után gombnyomással jelezze, hogy hallott-e a hangmintában \n',... 
    'emelkedő hangsort vagy sem. A képernyőn minden gombnyomást követően megjelenik majd, \n',...
    'hogy a válasz helyes volt-e.\n\n',...
    'Hangmintában van emelkedő hangsor  -  "', KbName(keys.figPresent), '" billentyű. \n',...
    'Hangmintában nincs emelkedő hangsor  -  "', KbName(keys.figAbsent), '" billentyű. \n\n',...
    'Mindig akkor válaszoljon, amikor megjelenik a kérdőjel. \n',...
    'Nyomja meg a SPACE billentyűt ha készen áll!'];

% write instructions to text
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, instrText, 'center', 'center', textColor);
Screen('Flip', win);

% user message
disp([char(10), 'Showing the instructions right now...']);

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
        audioData = stimArray{trial, 11};
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
        ListenChar(0);
        Priority(0);
        RestrictKeysForKbCheck([]);
        PsychPortAudio('Close');
        Screen('CloseAll');
        ShowCursor(screenNumber);
        return;
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
                    figDetect(trial) = 1;
                    respFlag = 1;
                    break;
                elseif find(keyCodeSub) == keys.figAbsent
                    figDetect(trial) = 0;
                    respFlag = 1;
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
        
        % participant feedback
        if (figDetect(trial)==1 && figStim(trial)) || (figDetect(trial)==0 && ~figStim(trial))
            acc(trial) = 1;
            Screen('CopyWindow', okRespWin, win);
        elseif (figDetect(trial)==1 && ~figStim(trial)) || (figDetect(trial)==0 && figStim(trial))
            acc(trial) = 0;
            Screen('CopyWindow', badRespWin, win);
        end
        Screen('DrawingFinished', win);
        Screen('Flip', win);
                
        % user messages
        if figDetect(trial) == 1
            disp('Subject detected a figure');    
        elseif figDetect(trial) == 0
            disp('Subject detected no figure');
        elseif isnan(figDetect(trial))
            disp('Subject did not respond in time');
        end
        % accuraccy
        if acc(trial) == 1
            disp('Subject''s response was accurate');
        elseif acc(trial) == 0
            disp('Subject made an error');
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
        logVar(trial+1, 11:end) = {acc(trial), figDetect(trial),... 
            respTime(trial), iti(trial),...
            trialStart, startTime-trialStart,... 
            (figStartCord(trial)-1)*chordLength,... 
            respStart-startTime};
        
        % save logging/results variable
        save(subLogF, 'logVar');
        
        % wait to show feedback
        WaitSecs(0.4);
        
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
                    break
                end
            end
        end
        if abortFlag
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
        blockEndText = ['Vége a feladatnak! \n\n',...
            'Az utolsó blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n',... 
            'Köszönjük a részvételt!'];       
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
        Screen('Flip', win);
        
        WaitSecs(5);
        
    end  % if loop blockNo       
            
end  % block for loop
    

disp(' ');
disp('Got to the end!');

ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
Screen('CloseAll');
ShowCursor(screenNumber);


return


    
  
    