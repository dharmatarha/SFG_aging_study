function SFGintro(subNum, stimopt)
%% Function to familiarize subjects with SFG stimuli
%
% USAGE: SFGintro(subNum, stimopt=SFGparamsIntro)
%
% Gives control to the subject to request stimuli either without figure or
% with an easily recognizable figure. Two connected displays are assumed,
% one for experimenter/control, one for the subject with simple
% instructions.
%
% Input:
% subNum        - Subject number, integer between 1-999
% stimopt       - Parameters for SFG stimulus in a struct. Passed to
%               createSingleSFGstim for generating stimuli. See
%               SFGparamsIntro for details. Defaults to calling
%               SFGparamsIntro
%


%% Input checks

if nargin == 1
    stimopt = SFGparamsIntro;
end
% subject number
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
% stimopt
if ~isstruct(stimopt)
    error('Input arg "stimopt" is expected to be a struct!');
end

disp([char(10), 'Called function SFGintro with inputs: ',...
     char(10), 'subject number: ', num2str(subNum),...
     char(10), 'stimulus options: ']);
disp(stimopt);


%% stimopt versions for the recognizable-figure stimulus and the no-figure stimulus

% user message
disp([char(10), 'Preparing stimulus parameters for figure/no-figure stimuli']);

% if there is a 'seed' field in stimopt, set the random num gen
if isfield(stimopt, 'randomSeed')
    rng(stimopt.randomSeed);
end

% easily recognizable version 
stimoptFigure = stimopt;
stimoptFigure.figureCoh = 14;
disp([char(10), 'Stimulus settings for easily-recognizable version: ']);
disp(stimoptFigure);

% stimulus with no figure
stimoptNoFigure = stimopt;
stimoptNoFigure.figureCoh = 0;
disp([char(10), 'Stimulus settings for no-figure version: ']);
disp(stimoptNoFigure);

% user message
disp([char(10), 'Prepared stimulus parameters']);


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

% restrict keys to the ones we use - turn values from fields into one
% vector
keysFields = fieldnames(keys);
keysVector = zeros(1, length(keysFields));
for f = 1:length(keysFields)
    keysVector(f) = keys.(keysFields{f});
end
RestrictKeysForKbCheck(keysVector);

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

% Force costly mex functions into memory to avoid latency later on
GetSecs; WaitSecs(0.1); KbCheck();

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

% init flag for reqested trial type
nextTrial = [];

% hide mouse
HideCursor(screenNumber);
% suppress keyboard input to command window
ListenChar(-1);
% realtime priority
Priority(1);

% user message
disp([char(10), 'Initialized psychtoolbox basics, opened window, ',...
    'started PsychPortAudio device']);


%% Start stimulus introduction

% instructions for subject
introText = ['Most ismerkedhet meg a hangokkal, amiket a kísérlet során használni fogunk.\n\n',... 
    'A hangok egy véletlenszerű háttérből, és egy abból kiugró, folyamatosan \n',...
    'emelkedő alakzatból állnak. Később az lesz a feladata, hogy jelezze, \n',... 
    'hogy egy hang tartalmazott-e ilyen emelkedő, kiugró alakzatot vagy sem. \n\n',...
    'Most, az ismerkedés során, ha a "', KbName(keys.figPresent), '" billentyűt \n',...
    'nyomja le, egy emelkedő, könnyen felismerhető alakzatot tartalmazó hangot \n',...
    'fogunk lejátszani, és ha a "', KbName(keys.figAbsent), '" billentyűt nyomja le, \n',... 
    'egy, csak háttérből álló hangot fogunk lejátszani Önnek. \n\n',...
    'Nyomja meg valamelyik billentyűt a kezdéshez!'];

taskText = ['Ha a "', KbName(keys.figPresent), '" billentyűt nyomja le,\n',...
    'egy emelkedő alakzatot tartalmazó hangot fogunk lejátszani, \n',...
    'és ha a "', KbName(keys.figAbsent), '" billentyűt nyomja le, \n',... 
    'egy, csak háttérből álló hangot fogunk lejátszani Önnek. \n\n',...
    'Nyomja meg valamelyik billentyűt a következő hanghoz. \n\n',...
    'Az "', KbName(keys.abort), '" billentyűvel befejezheti a feladatot.'];

% display instructions
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, introText, 'center', 'center', textColor);
Screen('Flip', win);

% user message
disp([char(10), 'Showing the instructions text right now...']);

% wait for key press to start
while 1
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown 
        % if subject requested stimulus with figure
        if find(keyCode) == keys.figPresent
            nextTrial = 1;
            break;
        % if subject requested stimulus with no figure
        elseif find(keyCode) == keys.figAbsent
            nextTrial = 0;
            break;            
        % if abort was requested    
        elseif find(keyCode) == keys.abort
            abortFlag = 1;
            break
        end
    end
end
if abortFlag
    disp('Terminating at user''s or subject''s request')
    ListenChar(0);
    Priority(0);
    RestrictKeysForKbCheck([]);
    PsychPortAudio('Close');
    sca; Screen('CloseAll');
    ShowCursor(screenNumber);
    return;
end

% feedback to subject - we are starting
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, 'Starting...', 'center', 'center', textColor);
Screen('Flip', win);

% user message
if nextTrial==1
    trialMessage = 'with';
elseif nextTrial==0
    trialMessage = 'without';
end
disp([char(10), 'Subject requested a trial ', trialMessage, ' a figure, we are starting...']);


%% Loop of playing requested stimuli

while 1  % until abort is requested
    
    % display fixation cross
    % background with fixation cross, get trial start timestamp
    Screen('CopyWindow', fixCrossWin, win);
    Screen('DrawingFinished', win);
    trialStart = Screen('Flip', win); 
    
    % create stimulus - with or without figure
    if nextTrial == 1
        % create next stimulus and load it into buffer
        [soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimoptFigure);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer); 
    elseif nextTrial == 0
        % create next stimulus and load it into buffer
        [soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimoptNoFigure);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer);         
    end
    
    % iti - random wiat time of 500-800 ms, treated generously
    iti = rand(1)*0.3+0.5;
    
    % user message
    if nextTrial==1
        trialMessage = 'with';
    elseif nextTrial==0
        trialMessage = 'without';
    end
    disp([char(10), 'Playing next stimulus - ', trialMessage, ' a figure']);
    
    % play stimulus - blocking start
    startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti, 1);
    
    % wait till playback is over
    WaitSecs('UntilTime', startTime+stimopt.totalDur);
    
    % display text for subject about requesting next stimulus
    Screen('FillRect', win, backGroundColor);
    DrawFormattedText(win, taskText, 'center', 'center', textColor);
    Screen('Flip', win);

    % wait for key press to go on to next stimulus
    while 1
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown 
            % if subject requested stimulus with figure
            if find(keyCode) == keys.figPresent
                nextTrial = 1;
                break;
            % if subject requested stimulus with no figure
            elseif find(keyCode) == keys.figAbsent
                nextTrial = 0;
                break;            
            % if abort was requested    
            elseif find(keyCode) == keys.abort
                abortFlag = 1;
                break
            end
        end
    end
    if abortFlag
        break;
    end
    
     % user message
    if nextTrial==1
        trialMessage = 'with';
    elseif nextTrial==0
        trialMessage = 'without';
    end
    disp([char(10), 'Subject requested a stimulus ', trialMessage, ' a figure']);   
    
    % only go on to next stimulus when keys are released
    KbReleaseWait;
    
end


%% Ending

disp('Terminating at user''s or subject''s request')
ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
sca; Screen('CloseAll');
ShowCursor(screenNumber);


return









