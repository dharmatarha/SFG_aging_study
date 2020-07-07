function SFGthresholdBackground(subNum, varargin)
%% Quest threshold for SFG stimuli aimed at estimating the effect of background notes
%
% USAGE: SFGthresholdBackground(subNum, stimopt=SFGparamsThreshold, trialMax=80)
%
% The procedure changes the number of background tones using the adaptive staircase
% procedure QUEST. Fixed trial approach. The function returns the Quest
% object ("q") and also saves it out to the folder of the subject. 
%
% Expects subject's folder to already exist and contain the results /
% output from SFGthresholdCoherence.m
%
% IMPORTANT: INITIAL QUEST PARAMETERS AND PSYCHTOOLBOX SETTINGS ARE 
% HARDCODED! TARGET THRESHOLD IS 80%! 
% Specific settings in general are for Mordor / Gondor labs of RCNS, Budapest.
%
% Mandatory input:
% subNum        - Numeric value, subject number. One of 1:999.
%
% Optional inputs:
% stimopt       - Struct containing the base parameters for SFG stimulus. 
%               Passed to createSingleSFGstim for generating stimuli. See
%               SFGparamsThreshold.m for details. Defaults to calling 
%               SFGparamsThreshold.m
% trialMax      - Numeric value, number of trials used for staircase
%               procedure, one of 10:120. Defaults to 80.
%
%
% Output:
% q             - Quest object.
%
% NOTES:
% (1) We need to implement inner checks on the robustness of the estimate.
% E.g. initial wrong answers at high SNR levels might throw the estimates
% off.
%
%

%% Input checks

% chcek no. of args
if ~ismember(nargin, 1:3) 
    error('Function SFGthresholdBackground needs mandatory input arg "subNum" and optional args "stimopt" and "trialMax"!');
end
% check mandatory input arg
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be one of 1:999!');
end
% check optional input args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isstruct(varargin{v}) && ~exist('stimopt', 'var')
            stimopt = varargin{v};
        elseif isnumeric(varargin{v}) && ismembertol(varargin{v}, 10:120) && ~exist('trialMax', 'var')
            trialMax = varargin{v};
        else
            error('An input arg could not be mapped nicely to "stimopt" or "trialMax"!');
        end
    end
end
% default values to optional args
if ~exist('stimopt', 'var')
    stimopt = SFGparamsThreshold();
end
if ~exist('trialMax', 'var')
    trialMax = 80;
end

% user message
disp([char(10), 'Called function SFGthresholdBackground with inputs: ',...
     char(10), 'subNum: ', num2str(subNum),...
     char(10), 'number of trials for Quest: ', num2str(trialMax),...
     char(10), 'stimulus params: ']);
disp(stimopt);
disp([char(10), 'TARGET THRESHOLD IS SET TO 80%!']);


%% Get subject's folder, define output file path

% subject folder name
dirN = ['subject', num2str(subNum)];

% check if subject folder already exists, complain if not
if ~exist(dirN, 'dir')
    error(['Could not find subject''s folder at ', dirN,...
        'SFGthresholdBackground requires the results from ',...
        'SFGthresholdCoherence to be saved to subject''s folder!']);
end

% date and time of starting with a subject
c = clock; d = date;
timestamp = {[d, '-', num2str(c(4)), num2str(c(5))]};
% subject log file for training
saveF = [dirN, '/thresholdBackground_sub', num2str(subNum), '_', timestamp{1}, '.mat'];

disp([char(10), 'Got output file path: ', saveF]);


%% Load results from SFGthresholdCoherence, get coherence level 

% user message
disp([char(10), 'Loading SFGthresholdCoherence results for subject']);

% get file name - exact file name contains unknown time stamp
cohResFile = dir([dirN, '/thresholdCoherence_sub', num2str(subNum), '*.mat']);
cohResFilePath = [cohResFile.folder, '/', cohResFile.name];

% load results from coherence-thresholding
cohRes = load(cohResFilePath);

% rename the coherence estimate from SFGthresholdCoherence results for
% readability
baseCoherence = cohRes.coherenceEst;  % base coherence value needs to be stored separately from stimopt, as stimopt.figureCoh is overwritten in figure-absent trials

% user message
disp('Done');
disp(['Coherence level for background-thresholding: ', num2str(baseCoherence)]);


%% Basic settings for Quest

% user message
disp([char(10), 'Setting params for Quest and initializing the procedure']);

% log SNR scale of possible stimuli, for Quest
% levels are defined for background tone numbers as
% 1:stimopt.toneComp-stimopt.figCoh
backgroundLevels = 1:stimopt.toneComp-baseCoherence;
snrLevels = baseCoherence./backgroundLevels;  % broadcasting in Matlab! :)
snrLogLevels = log(snrLevels);

% settings for quest 
qopt = struct;
qopt.tGuess = -0.12;  % prior threshold guess, -0.12 equals an SNR of ~0.89
qopt.tGuessSd = 5;  % SD of prior guess
qopt.pThreshold = 0.8;  % threshold of interest
qopt.beta = 3.5;  % Weibull steepness, 3.5 is the default used for a wide range of stimuli 
qopt.delta = 0.02;  % ratio of "blind" / "accidental" responses
qopt.gamma = 0.5;  % ratio of correct responses without stimulus present
qopt.grain = 0.001;  % internal table quantization
qopt.range = 7;  % range of possible values

% create Quest procedure object
q = QuestCreate(qopt.tGuess, qopt.tGuessSd, qopt.pThreshold,... 
    qopt.beta, qopt.delta, qopt.gamma, qopt.grain, qopt.range);

% user message
disp('Done with Quest init');


%% Basic settings for Psychtoolbox & PsychPortAudio

% user message
disp([char(10), 'Initializing Psychtoolbox, PsychPortAudio...']);

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

% use default audio device
device = [];
% mode is simple playback
mode = 1;
% reqlatencyclass is set to low-latency
reqLatencyClass = 2;
% 2 channels output
nrChannels = 2;
% sampling freq is most common
fs = 44100;

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

% user message
disp([char(10), 'Psychtoolbox functions, PsychPortAudio prepared']);


%% Procedure settings

% user message
disp([char(10), 'Initializing experiment settings...']);

% ratio of catch (no figure) trials
catchRatio = 0.5;
% vector for figure / catch trials
trialType = ones(trialMax, 1);
trialType(randperm(trialMax, round(trialMax*catchRatio))) = 0; 
% inter-trial interval, random between 700-1200 ms
iti = rand([trialMax, 1])*0.5+0.7;
% maximum time for a response, secs
respInt = 2;
% stimulus length for sanity checks later
stimLength = stimopt.totalDur;

% response variables preallocation
figDetect = nan(trialMax, 1);
respTime = figDetect;
acc = figDetect;

% user message
disp('Done');


%% Prepare first stimulus

% user message
disp([char(10), 'Preparing first stimulus in staircase...']);

% if there is no figure in current trial, stimopt.figureCoh is set to zero
% also, stimopt.toneComp just remains the last value it was set to
if trialType(1) == 0  
    stimopt.figureCoh = 0;
    
% if there is a figure in current trial, stimopt.figureCoh is set to the
% base coherence value, and stimopt.toneComp is adjusted according to Quest
elseif trialType(1) == 1  
    % set figure coherence (presence)
    stimopt.figureCoh = baseCoherence;
    % ask Quest object about optimal log SNR - for setting toneComp
    tTest=QuestMean(q); 
    % find the closest SNR level we have
    [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
    % update stimopt accordingly - we get the required number of background
    % tones indirectly, via manipulating the total number of tones
    stimopt.toneComp = backgroundLevels(closestSnrIdx)+baseCoherence;
end

% query a stimulus
[soundOutput, ~, ~] = createSingleSFGstim(stimopt);

% fill audio buffer with next stimuli
buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
PsychPortAudio('FillBuffer', pahandle, buffer);

% user message
disp([char(10), 'Done, we are ready to start the staircase for threshold ',... 
    num2str(qopt.pThreshold)]);


%% Instructions phase

% instructions text
instrText = ['A következő részben ugyanaz lesz a feladata, mint az előzőben - \n',...
    'kérjük, jelezze a próbák során, hogy hall-e egy, \n',...
    'a háttérből kiemelkedő hangot vagy nem.\n\n',... 
    'Összesen ', num2str(trialMax), ' hangot foguk lejátszani Önnek, \n',...
    'a feladat kb. ', num2str(round(trialMax/9)), ' percen át fog tartani.\n\n',...
    'Fontos! Mindig az "', KbName(keys.figPresent), '" gombbal jelezze, ha hallott \n',... 
    'egy különálló hangot, és az "' ,KbName(keys.figAbsent), '" gombot nyomja meg ha \n',...
    'nem hallott különálló hangot. \n\n',...
    'Mindig akkor válaszoljon, amikor megjelenik a kérdőjel.\n\n',...
    'Nyomja meg a SPACE billentyűt ha készen áll!'];    

% write instructions to text
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, instrText, 'center', 'center', textColor);
Screen('Flip', win);

% user message
disp([char(10), 'Showing the instructions right now...']);

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


%% Starting staircase - Trial loop

% blank screen (uniform background) after instructions
Screen('FillRect', win, backGroundColor);
Screen('Flip', win);

for trialN = 1:trialMax
    
    % wait for releasing keys before going on
    releaseStart = GetSecs;
    KbReleaseWait([], releaseStart+2);
    
    % background with fixation cross, get trial start timestamp
    Screen('CopyWindow', fixCrossWin, win);
    Screen('DrawingFinished', win);
    trialStart = Screen('Flip', win);  
    
    % user message
    disp([char(10), 'Starting trial ', num2str(trialN)]);
    if trialType(trialN) == 1
        disp('There is a figure in this trial');
    elseif trialType(trialN) == 0
        disp('There is no figure in this trial');
    end 
    
    % if not first trial, update quest and prepare next stimulus
    if trialN ~= 1
        
        % if previous trial was with figure, update quest object
        if trialType(trialN-1) == 1
            % missing response is understood as negative response for Quest
            if isnan(figDetect(trialN-1))
                questResp = 0;
            else
                questResp = figDetect(trialN-1);
            end
            q = QuestUpdate(q, tTest, questResp);
        end
        
        % if current trial is a catch trial, without figure, stimopt.figureCoh is set to zero
        % also, stimopt.toneComp just remains the last value it was set to
        if trialType(trialN) == 0
            stimopt.figureCoh = 0;  % no figure
            
        % else stimopt.figureCoh is set to the base coherence value, and 
        % stimopt.toneComp is adjusted according to Quest
        elseif trialType(trialN) == 1
            % set figure coherence (presence)
            stimopt.figureCoh = baseCoherence;
            % ask Quest object about optimal log SNR - for setting toneComp
            tTest=QuestMean(q); 
            % find the closest SNR level we have
            [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
            % update stimopt accordingly - we get the required number of background
            % tones indirectly, via manipulating the total number of tones
            stimopt.toneComp = backgroundLevels(closestSnrIdx)+baseCoherence;   
        end
        
        % user message
        disp(['Number of background tones is set to: ', num2str(stimopt.toneComp-stimopt.figureCoh)]);
        disp(['Coherence level is set to: ', num2str(stimopt.figureCoh)]);
        
        % create next stimulus and load it into buffer
        [soundOutput, ~, ~] = createSingleSFGstim(stimopt);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer);        
        
    end
    
    % blocking playback start for precision
    startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti(trialN), 1);
      
    % user message
    disp(['Audio started at ', num2str(startTime-trialStart), ' secs after trial start']);
    disp(['(Target ITI was ', num2str(iti(trialN)), ' secs)']);

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
                figDetect(trialN) = 1;
                respFlag = 1;
                break;
            elseif find(keyCode) == keys.figAbsent
                figDetect(trialN) = 0;
                respFlag = 1;
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
        respTime(trialN) = 1000*(respSecs-respStart);
    end    
    
    % accuracy
    if (figDetect(trialN)==1 && trialType(trialN)==1) || (figDetect(trialN)==0 && trialType(trialN)==0)
        acc(trialN) = 1;
    elseif (figDetect(trialN)==1 && trialType(trialN)==0) || (figDetect(trialN)==0 && trialType(trialN)==1)
        acc(trialN) = 0;
    end    
    
    % blank screen (uniform background) after response / end of response
    % interval
    Screen('FillRect', win, backGroundColor);
    Screen('Flip', win);    
    
    % user messages
    if figDetect(trialN) == 1
        disp('Subject detected a figure');    
    elseif figDetect(trialN) == 0
        disp('Subject detected no figure');
    elseif isnan(figDetect(trialN))
        disp('Subject did not respond in time');
    end
    % accuraccy
    if acc(trialN) == 1
        disp('Subject''s response was accurate');
    elseif acc(trialN) == 0
        disp('Subject made an error');
    end
    % response time
    if ~isnan(respTime(trialN))
        disp(['Response time was ', num2str(respTime(trialN)), ' ms']);
    end    
    
    % save logging/results variable
    save(saveF, 'q', 'respTime', 'figDetect', 'acc', 'trialType', 'cohRes',... 
        'trialMax', 'stimopt', 'qopt', 'backgroundLevels', 'snrLogLevels',...
        'snrLevels');
    
    % wait a bit before next trial
    WaitSecs(0.4);
    
end


%% Final Quest object update if last trial was with figure present

% if previous trial was with figure, update quest object
if trialType(trialN) == 1
    % missing response is understood as negative response for Quest
    if isnan(figDetect(trialN))
        questResp = 0;
    else
        questResp = figDetect(trialN);
    end
    q = QuestUpdate(q, tTest, questResp);
end

% get final background-threshold estimate
% ask Quest object about optimal log SNR - for setting toneComp
tTest=QuestMean(q); 
% find the closest SNR level we have
[~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
% update stimopt accordingly - we get the required number of background
% tones indirectly, via manipulating the total number of tones
backgroundEst = backgroundLevels(closestSnrIdx); 

% user message
disp([char(10), 'Final estimate for number of background tones: ', num2str(backgroundEst)]);


%% Ending

% user message
disp([char(10), 'The task has ended!!!']);

% block ending text
blockEndText = ['Vége a feladatnak! \n\n',...
    'Köszönjük a részvételt!'];       
% uniform background
Screen('FillRect', win, backGroundColor);
% draw block-starting text
DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
Screen('Flip', win);

% final user messages about accuracy
hitRate = sum(acc==1 & trialType==1)/(trialMax/2);
falseAlarmRate = sum(acc==0 & trialType==0)/(trialMax/2);
disp([char(10), 'Participant''s ratio of correct responses for trials',...
    char(10), 'with figures (hit rate) was ', num2str(hitRate)]);
disp([char(10), 'Participant''s ratio of detection responses for trials',...
    char(10), 'without figures (false alarm rate) was ', num2str(falseAlarmRate), ...
    '.', char(10) 'Consider re-running the thresholding procedure if ',...
    'the latter number is too high (>0.15)!']);

% saving resutls with extra info
save(saveF, 'q', 'respTime', 'figDetect', 'acc', 'trialType', 'cohRes',... 
    'trialMax', 'stimopt', 'qopt', 'backgroundLevels', 'snrLogLevels',...
    'snrLevels', 'backgroundEst', 'hitRate', 'falseAlarmRate');

% show ending message for a few secs
WaitSecs(3);

% cleanup
disp(' ');
disp('Got to the end!');
ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
Screen('CloseAll');
ShowCursor(screenNumber);


return









