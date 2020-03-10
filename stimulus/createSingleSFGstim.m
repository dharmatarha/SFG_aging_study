
function [soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt)
%% Generates a single SFG stimulus
%
% Returns two-channel audio (2 X samples) of SFG stimulus for the
% parameters passed in stimopt struct. To be used in cases where an
% experimental script needs to generate stimuli on the fly, in some loop.
%
% USAGE: [soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt)
%
% Input:
% stimopt       - struct containing stimulus parameters (both for 
%               background and figure). The list of fields required is
%               below, for details see SFGparams.m
%
% Outputs:
% soundOutput       - Numeric matrix corresponding to the audio stimulus.
%                   Its size is 2 X samples, with the two channels being 
%                   identical 
% allFigFreqs       - Numeric matrix containing the frequencies used for 
%                   figure contruction. Its size is Coherence level X 
%                   no. of chords
% allBackgrFreqs    - Numeric matrix containing the frequencies used for
%                   background contruction. Its size is no. of tone 
%                   components X no. of chords
%
% Fields of stimopt struct:
% sampleFreq, chordOnset, chordDur, figureMinOnset, figureOnset, 
% totalDur, toneComp, toneFreqMax, toneFreqMin, 
% toneFreqSetL, figureDur, figureCoh, figureStepS
%
% NOTES:
% (1) Check the resulting stimuli with plotChordsSingleStim.m
% (2) Typical stimopt struct:
% stimopt = struct( ...
%     'totalDur', 2, ...
%     'chordDur', 0.05, ...
%     'toneComp', 24, ...
%     'toneFreqSetL', 129, ...
%     'toneFreqMin', 179, ...
%     'toneFreqMax', 7246, ...
%     'chordOnset', 0.01, ...
%     'figureDur', 12, ...
%     'figureCoh', 4, ...
%     'figureOnset', 0.2, ...
%     'figureStepS', -2, ...
%     'sampleFreq', 44100, ...
%     'randomSeed', 'some seed here');
% (3) On our lab machines it should reliably run in ~50 ms, taking 
%   slightly longer on occasion. Allocating 100 ms should be more than
%   enough.
% (4) Fix number of tones/chord, that is, figure coherence and background 
% tones always add up to the same total tone no. 
%
% Based on earlier scripts by Tamas Kurics, Zsuzsanna Kocsis and Botond 
% Hajdu, ex-members of the lab.
% date: January 2020


%% Input checks

if nargin ~= 1
    error('Function createSingleSFGstim requires input arg "stimopt"!');
end
if ~isstruct(stimopt)
    error('Input arg "stimopt" is expected to be a struct!');
end


%% Settings

% set random number generator if random seed was supplied
if isfield(stimopt, 'randomSeed')
    rng(stimopt.randomSeed); 
end

% generating logarithmically uniform frequency range for the random
% background
logFreq = linspace(log(stimopt.toneFreqMin), log(stimopt.toneFreqMax), stimopt.toneFreqSetL);

% number of chords in the stimulus
stimulusChordNumber = floor(stimopt.totalDur / stimopt.chordDur);

% number of samples in a chord
numberOfSamples = stimopt.sampleFreq * stimopt.chordDur;
timeNodes = (1:numberOfSamples) / stimopt.sampleFreq;

% creating a cosine ramp, number of samples in the ramp
numberOfOnsetSamples = stimopt.sampleFreq * stimopt.chordOnset;
onsetRamp = sin(linspace(0, 1, numberOfOnsetSamples) * pi / 2);
onsetOffsetRamp = [onsetRamp, ones(1, numberOfSamples  - 2*numberOfOnsetSamples), fliplr(onsetRamp)];

% setting figure random parameters for each stimulus if needed
if isnan(stimopt.figureOnset)
    % setting figure random parameters for each stimulus
    figureIntervals = (round(stimopt.figureMinOnset/stimopt.chordDur) + 1):(round((stimopt.totalDur - stimopt.figureMinOnset)/stimopt.chordDur) - stimopt.figureDur + 1);
    figureStartInterval = figureIntervals(randi([1, length(figureIntervals)], 1));
    figureEndInterval   = figureStartInterval + stimopt.figureDur - 1;
else
    figureStartInterval = stimopt.figureOnset;
    figureEndInterval   = figureStartInterval + stimopt.figureDur - 1;
end
    
% initializing left and right speaker outputs
soundOutput  = zeros(2, stimopt.sampleFreq * stimopt.totalDur);
soundIndex = 1;  % counter for filling soundOutput with chords

% preallocate variables holding chord information
allFigFreqs = nan(stimopt.figureCoh, stimulusChordNumber);
allBackgrFreqs = nan(stimopt.toneComp, stimulusChordNumber);


%% Select figure tone components

% define possible frequency components for figure start, based on step size
% and figure duration
figureFreqIdx = 1:stimopt.toneFreqSetL-abs(stimopt.figureStepS)*(stimopt.figureDur-1); 
if stimopt.figureStepS < 0
    figureFreqIdx = figureFreqIdx+abs(stimopt.figureStepS)*(stimopt.figureDur-1);
end

% select starting freqs
figureStartFreqIdx = figureFreqIdx(randperm(length(figureFreqIdx), stimopt.figureCoh));

% add steps
figureFreqsPerChord = repmat(figureStartFreqIdx', [1, stimopt.figureDur]);
allFigureSteps = 0:stimopt.figureStepS:(stimopt.figureDur-1)*stimopt.figureStepS;  % all steps in one vector
allFigureSteps = repmat(allFigureSteps, [stimopt.figureCoh, 1]);  % put steps into a matrix, one row for each figure component
figureFreqsPerChord = figureFreqsPerChord+allFigureSteps;  % each column contains logFreq indices for one figure chord

    
%% Chord loop

for chordPos = 1:stimulusChordNumber 

    % number of background tones depends on the presence/absence of figure
    if (chordPos >= figureStartInterval) && (chordPos <= figureEndInterval)  % figure present

        % chord position relative to figure start (1 when chordPos==figureStartInterval)
        figChordPos = chordPos-figureStartInterval+1;
        
        % background freq components + figure freq components = stimopt.toneComp
        backgroundFreqsNo = stimopt.toneComp-stimopt.figureCoh; 
        
        % only tones not already in the figure can be used for background
        availableFreqsIdx = setdiff(1:stimopt.toneFreqSetL, figureFreqsPerChord(:, figChordPos)', 'stable');           
        
        % define figure frequencies
        figureFrequencies = round(exp(logFreq(figureFreqsPerChord(:, figChordPos)')));
        
        % creating figure tones for this chord
        figureTones = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));
        
        % store figure freq values for chord
        allFigFreqs(:, chordPos) = figureFrequencies';
        
    % if there is no figure, all frequencies can be used for background
    else
        backgroundFreqsNo = stimopt.toneComp;
        availableFreqsIdx = 1:stimopt.toneFreqSetL;
    end

    % selecting random background frequencies
    backgroundFreqIdx = availableFreqsIdx(randperm(length(availableFreqsIdx), backgroundFreqsNo));
    backgroundFreqs = round(exp(logFreq(backgroundFreqIdx)));
    
    % store figure freq values for chord
    allBackgrFreqs(1:length(backgroundFreqs), chordPos) = backgroundFreqs';
    
    % creating the tones for the background
    backgroundTones = sin(2*pi*diag(backgroundFreqs)*repmat(timeNodes,length(backgroundFreqs),1));

    % sum background plus figure, apply onset-offset ramp
    if (chordPos >= figureStartInterval) && (chordPos <= figureEndInterval)
        chord = (sum(backgroundTones, 1) + sum(figureTones, 1)) .* onsetOffsetRamp;
    else
        chord = sum(backgroundTones, 1).* onsetOffsetRamp;
    end
    
    % chord data into aggregate stimulus array
    soundOutput(1:2, soundIndex:soundIndex+numberOfSamples-1) = repmat(chord, [2, 1]);  % both channels contain the same stimulus
    soundIndex = soundIndex + numberOfSamples;    

end  % chord for loop

% normalize left and right output to the range -1 <= amplitude <= 1
maxSoundOutput = max(max(abs(soundOutput)));
soundOutput(1,:)  = soundOutput(1,:) / maxSoundOutput;
soundOutput(2,:)  = soundOutput(2,:) / maxSoundOutput;


return

