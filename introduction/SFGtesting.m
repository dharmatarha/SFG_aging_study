function SFGtesting(stimopt, OEMfiltering)

%% Script to play around with SFG stimuli
% 
% USAGE: SFGtesting(stimopt=SFGparamsIntro, OEMfiltering = true)
%
% A simple command line application that asks you to specify SFG stimulus
% properties coherence, duration, stepsize and no. of tones and then
% proceeds to generate and play the stimulus. Runs in a loop - you can
% generate and listen to as many stimuli as you want.
%
% Optional inputs:
% stimopt       - Struct. Its fields contain default stimulus options, some of
%               which are to be overwritten by user inputs. Defaults to calling
%               SFGparamsIntro(). See details in SFGparamsIntro or SFGparams.
% OEMfiltering  - Logical value. Flag for loading and applying a filter
%               correcting for loudness distortions (see loudness curves),
%               passed on to createSingleSFGstimulus. Defaults to "true",
%               which in turn requires an "OEM_*.mat" file containing
%               filter coeffs located in pwd.
%


%% Basics

% input checks
if ~ismembertol(nargin, 0:2)
    error('Function SFGtesting expects at maximum two (optional) input args, "stimopt" and "OEMfiltering"!');
end
if nargin == 1
    OEMfiltering = true;
elseif nargin == 0
    stimopt = SFGparamsIntro;
end
if ~isstruct(stimopt)
    error('Input arg "stimopt" should be a struct, for fields see "help SFGparams"!');
end
if ~islogical(OEMfiltering) || numel(OEMfiltering)~=1
    error('Input arg "OEMfiltering" should be a logical value!');
end

% user message
disp('Started SFGtesting with base SFG params: ');
disp(stimopt);
disp('OEMfiltering set to: ', num2str(OEMfiltering)); 


%% Psychtoolbox & PsychPortAudio setup, params & settings

% user message
disp([char(10), 'Setting params, PsychPortAudio...']);

% General init (AssertOpenGL, 'UnifyKeyNames')
PsychDefaultSetup(1);

% init PsychPortAudio with pushing for lowest possible latency
InitializePsychSound(1);

% Define the specific keys we use
keys = struct;
keys.abort = KbName('ESCAPE');
keys.go = KbName('SPACE');
keys.repeat = KbName('r');

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

% flag for aborting the script
abortFlag = 0;

% user message
disp([char(10), 'Params, PsychPortAudio prepared, ready to go']);


%% Stimulus loop

% while loop until ESC is pressed
while 1

    % User input flags for current stimulus
    cohFlag = 0; durFlag = 0; stepSizeFlag = 0; backgrFlag = 0; 
    
    % coherence
    while 1  
        if cohFlag
            break;
        end   
        % input for coherence level
        inputRes = input([char(10), 'Provide a coherence level (between 1-20): ', char(10)]);
        % check value, set coherence level and flag
        if ismember(inputRes, 1:20)
            stimopt.figureCoh = inputRes;
            cohFlag = 1;
            disp([char(10), 'Coherence level is set to ', num2str(inputRes), char(10)]);
        else
            disp([char(10), 'Wrong value, try again', char(10)]);
        end  
    end
    
    % duration
    while 1
        if durFlag
            break;
        end   
        % input for duration
        inputRes = input([char(10), 'Provide a duration value (in chords, between 1-20): ', char(10)]);
        % check value, set duration and flag
        if ismember(inputRes, 1:20)
            stimopt.figureDur = inputRes;
            durFlag = 1;
            disp([char(10), 'Duration is set to ', num2str(inputRes), char(10)]);
        else
            disp([char(10), 'Wrong value, try again', char(10)]);
        end 
    end

    % step size
    while 1
        if stepSizeFlag
            break;
        end   
        % input for step size
        inputRes = input([char(10), 'Provide a step size (in half-semitone/chord, from -5 to +5): ', char(10)]);
        % check value, set duration and flag
        if ismember(inputRes, -5:1:5)
            stimopt.figureStepS = inputRes;
            stepSizeFlag = 1;
            disp([char(10), 'Step size is set to ', num2str(inputRes), char(10)]);
        else
            disp([char(10), 'Wrong value, try again', char(10)]);
        end 
    end    
    
    % no. of background tone components
    while 1  
        if backgrFlag
            break;
        end   
        % input for coherence level
        inputRes = input([char(10), 'Provide the number of background tone components (between 1-30): ', char(10)]);
        % check value, set coherence level and flag
        if ismember(inputRes, 1:30)
            stimopt.toneComp = inputRes+stimopt.figureCoh;
            backgrFlag = 1;
            disp([char(10), 'No. of background tones is set to ', num2str(inputRes)]);
            disp(['Overall, there will be ', num2str(stimopt.toneComp),... 
                ' tone components.\n For the figure, ', num2str(stimopt.figureCoh),... 
                ' of them will move coherently', char(10)]);
        else
            disp([char(10), 'Wrong value, try again', char(10)]);
        end  
    end        
    
    % user message about upcoming stimulus
    disp([char(10), 'Stimulus parameters for next SFG stimulus: ', char(10)]);
    disp(stimopt);

    % create SFG stimulus
    [soundOutput, ~, ~] = createSingleSFGstim(stimopt, OEMfiltering);
    % fill audio buffer with next stimuli
    buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
    PsychPortAudio('FillBuffer', pahandle, buffer);
    
    % prompt for playback
    disp([char(10), 'Press SPACE to play the stimulus (press ESC to quit)']);
    
    % suppress keyboard input to command window
    ListenChar(-1);
    
    % listen on keyboard
    while 1
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            % if playback is requested 
            if find(keyCode) == keys.go
                break;
            elseif find(keyCode) == keys.abort
                abortFlag = 1;
                break;
            end
        end
        WaitSecs(0.05);
    end
    
    % if user requested to end the script
    if abortFlag
        disp([char(10), 'Terminating at user''s request']);
        PsychPortAudio('Close');
        return
    end
    
    % play audio from buffer
    PsychPortAudio('Start', pahandle, 1);

    % wait till keys are released before asking for more input
    KbReleaseWait;
    
    % prompt for next action: repeat, go to next, abort
    disp([char(10), 'Press ''r'' to repeat the stimulus, press SPACE to go ',...
        'to the next one, or press ESC to quit']);
    
    % listen on keyboard
    while 1
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            % if user wants to go to the next round
            if find(keyCode) == keys.go
                break;
            % if repeat
            elseif find(keyCode) == keys.repeat
                PsychPortAudio('Start', pahandle, 1);
                % wait till keys are released before asking for more input
                KbReleaseWait;
            % if termination is requested
            elseif find(keyCode) == keys.abort
                abortFlag = 1;
                break;
            end
        end
        WaitSecs(0.05);
    end    
    
    % restore keyboard input to command window
    ListenChar(0);
    
    % if user requested to end the script
    if abortFlag
        disp([char(10), 'Terminating at user''s request']);
        PsychPortAudio('Close');
        return
    end    

    % wait till keys are released before asking for more input
    KbReleaseWait;    
    
    WaitSecs(0.3);
    
end


return



