function q = SFGthreshold(stimopt)
%% Quest threshold for SFG stimuli
%
% USAGE: SFGthreshold(stimopt)
%
% The procedure changes the coherence level using the adaptive staircase
% procedure QUEST. Fix trial no.
%
% Input:
% stimopt       - Base stimulus params.
%
% Output:
% q             - Quest object
%
% NOTES:
% (1) Example stimopt with sensible values:
% stimopt = struct( ...
%     'totalDur', 2, ...
%     'chordDur', 0.05, ...
%     'toneComp', 20, ...
%     'toneFreqSetL', 129, ...
%     'toneFreqMin', 179, ...
%     'toneFreqMax', 7246, ...
%     'chordOnset', 0.01, ...
%     'figureDur', 10, ...
%     'figureCoh', 7, ...
%     'figureOnset', 0.2, ...
%     'figureStepS', 2, ...
%     'sampleFreq', 44100, ...
%     'randomSeed', 'some seed here');
%
%

%% Input checks

if nargin ~= 1
    error('Function SFGthreshold requires input arg "stimopt"!');
end
if ~isstruct(stimopt)
    error('Input arg "stimopt" is expected to be a struct!');
end

disp([char(10), 'Called function SFGthreshold with inputs: ',...
     char(10), 'stimulus options: ']);
disp(stimopt);


%% Basic settings for Quest

% user message
disp([char(10), 'Setting params for Quest and initializing the procedure']);

% log SNR scale of possible stimuli, for Quest
% levels are defined for coherence values 0:stimopt.toneComp-1
cohLevels = 0:stimopt.toneComp-1;
snrLevels = cohLevels./(stimopt.toneComp:-1:1);
snrLogLevels = log(snrLevels);

% settings for quest 
qopt = struct;
qopt.tGuess = -0.8;  % prior thresholod guess, 0.8 equals an SNR of ~0.43
qopt.tGuessSd = 5;  % SD of prior guess
qopt.pThreshold = 0.7;  % threshold of interest
qopt.beta = 3.5;  % Weibull steepness, 3.5 is the default used for a wide range of stimuli 
qopt.delta = 0.02;  % ratio of "blind" / "accidental" responses
qopt.gamma = 0.5;  % ratio of correct responses without stimulus present
qopt.grain = 0.01;  % internal table quantization
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
keys.yes = KbName('y');
keys.no = KbName('n');

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
disp([char(10), 'Psychtoolbox functions, PsychPortAudio prepared']);


%% Procedure settings

% user message
disp([char(10), 'Initializing experiment settings...']);

% stop after a fix number of trials
trialMax = 60;

% ratio of catch (no figure) trials
catchRatio = 0.5;
% vector for figure / catch trials
trialType = ones(trialMax, 1);
trialType(randperm(trialMax, round(trialMax*catchRatio))) = 0; 

% inter-trial interval, random between 700-1200 ms
iti = rand([trialMax, 1])*0.5+0.7;

% maximum time for a response, secs
respTime = 2;

% variable holding rts
rts = nan(trialMax, 1);

% user message
disp('Done');


%% Starting staircase

% prepare first stimulus

if trialType(1) == 0  % if there is no figure in current trial
    stimopt.figureCoh = 0;
    
elseif trialType(1) == 1  % if there is a figure in current trial
    % ask Quest object about optimal log SNR
    tTest=QuestMean(q); 
    % find the closest SNR level we have
    [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
    % update stimopt accordingly
    stimopt.figureCoh = cohLevels(closestSnrIdx);
end

% query a stimulus
[soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt);

% fill audio buffer with next stimuli
buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
PsychPortAudio('FillBuffer', pahandle, buffer);

% user message
disp([char(10), 'We are ready to start the staircase for threshold ',... 
    num2str(qopt.pThreshold)]);
disp([char(10), 'Your task is to listen to each stimulus and respond with pressing "',... 
    KbName(keys.yes),'" if you here the sound, otherwise press "', KbName(keys.no),'"!']);
disp(['Press ', KbName(keys.go), ' to start!']);

% listen on keyboard
while 1
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        % if we can go on
        if find(keyCode) == keys.go
            break;
        % if we should terminate
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

% make sure all keys are released
KbReleaseWait;

    
%% Trial loop

for trialN = 1:trialMax
    
    % approximate start of trial
    apprStart = GetSecs;
    
    % user message
    disp([char(10), 'Starting trial ', num2str(trialN)]);
    
    % if not first trial, update quest and prepare next stimulus
    if trialN ~= 1
        
        % if previous trial was with figure, update quest object
        if trialType(trialN-1) == 1 && ~isempty(response)
            q = QuestUpdate(q, tTest, response);
        end
        
        % ask Quest object about optimal log SNR
        tTest=QuestMean(q); 
        % find the closest SNR level we have
        [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
        % update stimopt accordingly
        stimopt.figureCoh = cohLevels(closestSnrIdx);
        
        % if current trial is a catch trial, without figure
        if trialType(trialN) == 0
            stimopt.figureCoh = 0;  % no figure
            
        elseif trialType(trialN) == 1
            % ask Quest object about optimal log SNR
            tTest=QuestMean(q); 
            % find the closest SNR level we have
            [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
            % update stimopt accordingly
            stimopt.figureCoh = cohLevels(closestSnrIdx);     
        end
        
        % create next stimulus and load it into buffer
        [soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer);        
        
    end
    
    % blocking playback start for precision
    startTime = PsychPortAudio('Start', pahandle, 1, apprStart+iti(trialN), 1);
    
    % make sure all keys are released
    KbReleaseWait;    
    
    % wait for response
    response = [];
    while (GetSecs-startTime) < (respTime + stimopt.totalDur)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            % "yes" response
            if find(keyCode) == keys.yes
                response = 1;
                rts(trialN) = secs;
                break;
            % "no" response    
            elseif find(keyCode) == keys.no
                response = 0;
                rts(trialN) = secs;
                break;
            % abort   
            elseif find(keyCode) == keys.abort
                abortFlag = 1;
                break;                
            end
        end
    end
    
    % if user requested to end the script
    if abortFlag
        disp([char(10), 'Terminating at user''s request']);
        PsychPortAudio('Close');
        return
    end  
    
    % user messages
    disp(['Coherence level was: ', num2str(stimopt.figureCoh)]); 
    respString = [];
    if response == 1
        respString = 'yes';
    elseif response == 0
        respString = 'no';
    end
    disp(['User responded: ', respString]);
    disp(['RT was: ', num2str(rts(trialN)*1000, 2), ' ms']);
    
    
end


%% Ending

PsychPortAudio('Close');

return









