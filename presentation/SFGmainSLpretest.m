function SFGmainSLpretest(subNum, varargin)
Screen('Preference', 'SkipSyncTests', 1);  % TODO remove this
%% Stochastic figure-ground experiment - main experimental script
%
% USAGE: SFGmainSLpretest(subNum, stimArrayFile=./subjectXX/stimArray*.mat, blockNo=10, triggers='yes')
%
% Stimulus presentation script for stochastic figure-ground (SFG) experiment. 
% The script requires pre-generated stimuli organized into a
% "stimArrayFile". See the functions in /stimulus for details on producing
% stimuli. 
% The script also requires stim2blocksSLpretest.m for sorting stimuli into blocks
% and expParamsHandlerSLpretest.m for handling the loading of stimuli and existing
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
    blockNo = 1;
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
disp([newline, 'Called SFGmain (the main experimental function) with input args: ',...
    newline, 'subNum: ', num2str(subNum),...
    newline, 'stimArrayFile:', stimArrayFile,...
    newline, 'blockNo: ', num2str(blockNo)]);


%% Load/set params, stimuli, check for conflicts

% user message
disp([newline, 'Loading params and stimuli, checking ',...
    'for existing files for the subject']);

% a function handles all stimulus sorting to blocks and potential conflicts
% with earlier recordings for same subject
[stimArray, ~,~,... 
    startBlockNo,  blockIdx, trialIdx,...
    logVar, subLogF, returnFlag,... 
    logHeader, stimTypes] = expParamsHandlerSLpretest(subNum, stimArrayFile, blockNo);

%%%%%%%%%%%%%%%%%%%%%% HARDCODED BREAKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
breakBlocks = [4, 7];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if there was early return from expParamsHandlerSLpretest.m, abort
if returnFlag
    return
end

% user message
disp([newline, 'Ready to start the experiment']);

%% Stimulus features for triggers + logging
[stepSizes, figStartCord, stimLength, chordLength] = extractStimulusFeatures(stimArray);

%% Triggers
[logVar, ~] = setUpTriggers(stimArray, logVar, logHeader, stimTypes);

%% Init PTB

fs = extractSampleRate(stimArray);
[pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs);

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

setUpKeyRestrictions(keys);

%% Set up PTB screen

% Set up display params:
backGroundColor = [0 0 0];
textColor = [255 255 255];

[win, rect, ifi] = setUpAndOpenPTBScreen(screenNumber, backGroundColor);

fixCrossWin = createFixationCrossOffscreenWindow(win, backGroundColor, textColor, rect);
qMarkWin = createQuestionMarkOffscreenWindow(win, backGroundColor, textColor, rect);

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
disp([newline, 'Initialized psychtoolbox basics, opened window, ',...
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
disp([newline, 'Showing the instructions text right now...']);

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
    closePTB(screenNumber);
    return;
end

% user message
disp([newline, 'Subject signalled she/he is ready, we go ahead with the task']);

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
    disp([newline, 'Buffered all stimuli for block ', num2str(block),... 
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
        closePTB(screenNumber);
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
        disp([newline, 'Starting trial ', num2str(trialCounterForBlock)]);
        disp([newline, 'Step size: ', num2str(stepSizes(trial))]);
        if stepSizes(trial) > 0
            disp('There is an ascending figure in this trial');
        elseif stepSizes(trial) < 0
            disp('There is a descending figure in this trial');
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
            closePTB(screenNumber);
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
        if (detectedDirection(trial)==1 && stepSizes(trial) > 0) || (detectedDirection(trial)==-1 && stepSizes(trial) < 0)
            disp('Subject''s response was accurate');
            acc(trial) = 1;
        elseif (detectedDirection(trial)==1 && stepSizes(trial) < 0) || (detectedDirection(trial)==-1 && stepSizes(trial) > 0)
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
    
        logVar(trial+1, 10:end-1) = {acc(trial), detectedDirection(trial),... 
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
    disp([newline, newline, 'Block no. ', num2str(block), ' has ended,'... 
        'showing block-ending text to participant']);
    disp([newline, 'Overall accuracy in block was ', num2str(blockAcc),... 
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
            closePTB(screenNumber);
            return;
        end  
    
    % if not last block and there is a break
    elseif (block ~= blockNo) && ismembertol(block, breakBlocks)
        
        % user message
        disp([newline, 'There is a BREAK now!']);
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
            closePTB(screenNumber);
            return;
        end      
        
        
    % if last block ended now   
    elseif block == blockNo
 
        % user message
        disp([newline, 'The task has ended!!!']);
        
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

closePTB(screenNumber);

return


    
  
    