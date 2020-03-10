function wavDir = createSFGstimuli(NStimuli, stimopt, figPresent)
%% Creates a sequence of Nstimuli stochastic figure-ground (SFG) stimulus.
% 
% USAGE: wavDir = createSFGstimuli(NStimuli, stimopt, figPresent)
%
% SFG-stimulus generator, where the parameters are supplied as a
% "stimopt" struct, usually generated by the SFGparams function. The 
% presence / absence of figure is controlled by the "figPresent" arg.  
% Generated sound samples are written in a folder (dd-mm-yyyy-hh-mm) 
% together with a csv file (dd-mm-yyyy-hh-mm-StimuliData.csv) that 
% describes the parameter settings of each generated stimulus. More 
% detailed chord information is written into a mat file 
% (dd-mm-yyyy-hh-mm-chordInfo.mat) in the same folder.
%
% Inputs:
% NStimuli      - number of stimuli to be generated
% stimopt       - struct containing stimulus parameters (both for 
%               background and figure). The list of fields required is
%               below, for details see SFGparams.m
% figPresent    - 'yes' = there is a figure layed over the background, its 
%               duration and coherence are controlled via stimopt;
%               'no' = random tones are added instead of figure, with the
%               same coherence and duration values
%
% Outputs:
% wavDir        - name of the folder with the generated stimuli
%
% Fields of stimopt struct:
% sampleFrequency, chordOnset, chordDuration, figureOnset, totalDuration, 
% toneComponents, toneFrequenciesMax, toneFrequenciesMin, 
% toneFrequenciesSetlength, figureDuration, figureCoherence
%
% Based on earlier scripts by Tamas Kurics, Zsuzsanna Kocsis and Botond 
% Hajdu, ex-members of the lab.
% date: January 2020
%
% Notes:
% (1) Earlier versions retained a feature for generating stimulus 
% originating from other directions than midline (by controlling inter-
% aural amplitude difference and latency). The current script only
% generates stimuli seemingly coming from the midline. 
% (2) This version removes the extra background frequencies 
% when the background plus figure frequencies exceed the 
% upper limit. 
% (3) When figure = 'no', there are still added components to the 
% standard background noise, but these tones are chosen randomly. In 
% earlier scripts in the lab, this feature was implemented in
% createSFGstimuli_decoy.m
%
% 
%


%% Input checks, loading params

if nargin ~= 3
    wavDir = 0;
    error('Function createSFGstimuli requires input args "NStimuli", "stimopt" and "figPresent"!');
end
% sanity check for requested no. of stimuli
if ~ismembertol(NStimuli, 1:1000)
    error('Input arg NStimuli should be element of 1:1000, please double-check and edit the function if necessary!');
end
% check figPresent arg
if ~ismember(figPresent, {'yes', 'no'})
    error('Input arg "figPresent" should be "yes" or "no"!');
end
% minimal checks on stimopt arg
if ~isstruct(stimopt) || isempty(stimopt)
    error('Input arg "stimopt" should be a struct with a number of predefined fields! Check the help and/or SFGparams.m!');
end

% user message at function start
disp([newline, 'Called createSFGstimuli function with input args:',...
    newline, 'NStimuli: ', num2str(NStimuli),...
    newline, 'figPresent: ', figPresent, ...
    newline, 'stimopt: ']);
disp(stimopt);


%% Basic settings

% set random number generator
rng(stimopt.randomSeed); 

% extracting variables from structure (converting millisec. to sec.)
sampleFrequency = stimopt.sampleFrequency;
chordDuration   = stimopt.chordDuration / 1000;
chordOnset      = stimopt.chordOnset / 1000;
figureOnset     = stimopt.figureOnset / 1000;
totalDuration   = stimopt.totalDuration / 1000;
toneComponents  = stimopt.toneComponents;
% extracting background noise parameters
toneFrequenciesMax       = stimopt.toneFrequenciesMax;
toneFrequenciesMin       = stimopt.toneFrequenciesMin;
toneFrequenciesSetlength = stimopt.toneFrequenciesSetlength;

% generating logarithmically uniform frequency range for the random
% background
logFreq = linspace(log(toneFrequenciesMin), log(toneFrequenciesMax), toneFrequenciesSetlength);

% number of chords in the stimulus
stimulusChordNumber = floor(totalDuration / chordDuration);

% number of samples in a chord
numberOfSamples = sampleFrequency * chordDuration;
timeNodes       = (1:numberOfSamples) / sampleFrequency;

% creating a cosine ramp, number of samples in the ramp
numberOfOnsetSamples = sampleFrequency * chordOnset;
timeOnsetNodes = (0:numberOfOnsetSamples-1) / sampleFrequency;
onsetRamp = sin(linspace(0, 1, numberOfOnsetSamples) * pi / 2);
onsetOffsetRamp = [onsetRamp, ones(1, numberOfSamples  - 2*numberOfOnsetSamples), fliplr(onsetRamp)];

% setting the zeros in the output name, ex.: filename001
digits = ceil(log10(NStimuli + 1));

% creating header for saved parameters
outFile = cell(NStimuli+1, 13);
outFile(1, :) = {'filename', 'totalDuration_sec', 'chordDuration_sec', 'chordOnset_sec', ...
                 'figPresent', 'figureDuration', 'figureCoherence', 'figureStepSize', 'snr', 'snrMaxDeviation', 'sampleFrequency_Hz', ...
                 'figureStartInterval', 'figureEndInterval'};

% create directory for saving audio data + parameters files
c = clock;  % dir name based on current time
wavDir = strcat(date, '-', num2str(c(4)), num2str(c(5)));
dircount = 0;
while exist(wavDir, 'dir')
    dircount = dircount + 1;
    if dircount > 1
        wavDir = strsplit(wavDir, '_');
        wavDir = wavDir{1};
    end
    wavDir = strcat(wavDir, '_', num2str(dircount));
end
mkdir(wavDir);

% save out params/options to directory
paramsFile = ['./', wavDir, '/', wavDir, '_stimopt.mat'];
save(paramsFile, 'stimopt', 'figPresent');

% user message
disp([newline,'Created stimulus directory at ', wavDir, ',',...
    newline, 'prepared parameters/settings, now generating stimuli...']);


%% Stimulus generation loop
% Generate random chords with a random figure placed at some random position

% preallocating variables containing chord data
allBackgroundFrequencies = cell(NStimuli, stimulusChordNumber);
allFigureFrequencies = cell(NStimuli, stimulusChordNumber);

for newstimulus = 1:NStimuli

    % setting figure random parameters for each stimulus
    figureDuration  = stimopt.figureDuration(randi([1, length(stimopt.figureDuration)], 1));
    figureCoherence = stimopt.figureCoherence(randi([1, length(stimopt.figureCoherence)], 1));
    figureIntervals = (round(figureOnset/chordDuration) + 1):(round((totalDuration - figureOnset)/chordDuration) - figureDuration + 1);
    figureStartInterval = figureIntervals(randi([1, length(figureIntervals)], 1));
    figureEndInterval   = figureStartInterval + figureDuration - 1;
    figureStepSize = stimopt.figureStepSize(randi([1, length(stimopt.figureStepSize)], 1));
    snr = stimopt.snr(randi([1, length(stimopt.snr)], 1));
    snrMaxDeviation = stimopt.snrMaxDeviation(randi([1, length(stimopt.snrMaxDeviation)], 1));
    
    averageToneCountToReachSnr = getAverageBgToneCountToReachSnr(snr, figureDuration, figureCoherence, stimulusChordNumber);
    
    % initializing left and right speaker outputs
    soundOutput  = zeros(2, sampleFrequency * totalDuration);
    soundIndex = 1;
    
    
    %% Chord loop
    for chordPosition = 1:stimulusChordNumber
        
        % number of pure tones in a chord in the background.
        [minFreqsInChord, maxFreqsInChord] = determineBgFrequencyCountRange(toneComponents, snr, averageToneCountToReachSnr, snrMaxDeviation);
        if maxFreqsInChord > toneFrequenciesSetlength
            error('You have requested to generate more background tones (%f) than the length of the frequency grid (%f). Please adjust your settings accordingly.', maxFreqsInChord, toneFrequenciesSetlength);
        end
        numberOfFrequencies = randi([minFreqsInChord, maxFreqsInChord], 1);  
        
        % selecting random background frequencies
        indexOfFrequencies = randperm(toneFrequenciesSetlength, numberOfFrequencies);
        backgroundUniqueFrequencies = round(exp(logFreq(indexOfFrequencies)));
        
        % initializing an empty figure tone vector
        figureTonesLeft  = zeros(length(backgroundUniqueFrequencies), length(timeNodes));
        figureTonesRight = zeros(length(backgroundUniqueFrequencies), length(timeNodes));
        
        % do we have the figure in this chord position?
        if ((chordPosition >= figureStartInterval) && (chordPosition <= figureEndInterval) && (strcmp(figPresent, 'yes')))
            
            % define the figure's frequencies
            if chordPosition == figureStartInterval
                indexOfFigureFrequencies = defineFigure(figureStepSize, figureDuration, figureCoherence, toneFrequenciesSetlength);
            else
                % raise figure by the requested step size
                indexOfFigureFrequencies = indexOfFigureFrequencies + figureStepSize;
            end
            figureFrequencies = round(exp(logFreq(indexOfFigureFrequencies)));
            
            % for each chord in the figure remove the figure
            % frequencies from the background; we should also
            % check whether the complete figure + background noise
            % contains more than maxFreqsInChord tones. 
            backgroundUniqueFrequencies = setdiff(backgroundUniqueFrequencies,figureFrequencies, 'stable');
            if snr ~= 0 && length(backgroundUniqueFrequencies) + figureCoherence > maxFreqsInChord
                backgroundUniqueFrequencies(maxFreqsInChord-figureCoherence+1:end) = [];
            end

            % creating figure tones for this chord
            figureTonesLeft  = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));
            figureTonesRight = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));            
        
        % if there is no figure, we add random frequencies instead
        elseif ((chordPosition >= figureStartInterval) && (chordPosition <= figureEndInterval) && (strcmp(figPresent, 'no')))
            %if there is no coherent figure, then we add extra random
            %background
            indexOfFigureFrequencies = randperm(toneFrequenciesSetlength, figureCoherence);
            figureFrequencies        = round(exp(logFreq(indexOfFigureFrequencies)));
            
            % for each chord in the 'figure-like noise' remove the figure
            % frequencies from the background (decoy)
            backgroundUniqueFrequencies = setdiff(backgroundUniqueFrequencies, figureFrequencies);

            % creating figure tones for this chord
            figureTonesLeft  = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));
            figureTonesRight = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));
        end                
        
        % creating the tones for the background
        randomTones      = sin(2*pi*diag(backgroundUniqueFrequencies)*repmat(timeNodes,length(backgroundUniqueFrequencies),1));
        randomChordLeft  = (sum(randomTones, 1) + sum(figureTonesLeft, 1)) .* onsetOffsetRamp;
        randomChordRight = (sum(randomTones, 1) + sum(figureTonesRight, 1)) .* onsetOffsetRamp;
        
        soundOutput(1, soundIndex:soundIndex+numberOfSamples-1) = randomChordLeft;
        soundOutput(2, soundIndex:soundIndex+numberOfSamples-1) = randomChordRight;
        soundIndex = soundIndex + numberOfSamples;
        
        % collect chord-specific figure information
        if (chordPosition >= figureStartInterval) && (chordPosition <= figureEndInterval)
            allFigureFrequencies{newstimulus, chordPosition} = figureFrequencies;
        end
        allBackgroundFrequencies{newstimulus, chordPosition} = backgroundUniqueFrequencies;
        
    end  % chord for loop
    
    % normalize left and right output to the range -1 <= amplitude <= 1
    maxSoundOutput = max(max(abs(soundOutput)));
    soundOutput(1,:)  = soundOutput(1,:) / maxSoundOutput;
    soundOutput(2,:)  = soundOutput(2,:) / maxSoundOutput;
    
    % save results to wav, add parameters to the cell array later saved out
    % to csv
    stimulusdigits = ceil(log10(newstimulus + 1));
    temp = char('');
    for digind = 1:(digits-stimulusdigits)
        temp = strcat(temp, '0');
    end
    c = clock;
    filename = strcat(wavDir, '-', temp, num2str(newstimulus));
    outFile(newstimulus+1, :) = {filename, totalDuration, chordDuration, chordOnset, ...
                                 figPresent, figureDuration, figureCoherence, figureStepSize, snr, snrMaxDeviation, sampleFrequency, ...
                                 figureStartInterval, figureEndInterval};
    audiowrite(strcat('./', wavDir, '/', filename, '.wav'), soundOutput', sampleFrequency);
    
    
end  % newstimulus for loop


%% Save out parameters, user message, return

% save out detailed info about random background + figure chords
chordInfoFile = ['./', wavDir, '/', wavDir, '_chordInfo.mat'];
save(chordInfoFile, 'allBackgroundFrequencies', 'stimulusChordNumber',... 
    'NStimuli', 'allFigureFrequencies');

% Convert cell to a table and use first row as variable names
T = cell2table(outFile(2:end,:), 'VariableNames', outFile(1,:));
 
% Write the table to a CSV file, final user message
writetable(T,strcat('./', wavDir, '/', strcat(wavDir, '-', 'StimuliData.csv')));
disp([newline, 'Task done, files and parameters are saved to directory ', wavDir, newline]);


return

%% Helper functions

function averageBgToneCountToReachSnr = getAverageBgToneCountToReachSnr(snr, figureDuration, figureCoherence, stimulusChordNumber)
    figureToneCount = figureDuration * figureCoherence;
    overallSignalToneCountPerChord = figureToneCount / stimulusChordNumber;
    if (snr == 0)
        averageBgToneCountToReachSnr = 0;
    elseif (snr > 0)
        averageBgToneCountToReachSnr = overallSignalToneCountPerChord / snr;
    end
return

function [minFreqsInChord, maxFreqsInChord] = determineBgFrequencyCountRange(toneComponents, snr, averageToneCountToReachSnr, snrMaxDeviation)
    if (snr == 0)
        minFreqsInChord = 0;
        maxFreqsInChord = snrMaxDeviation;
    elseif (snr > 0)
        minFreqsInChord = round(averageToneCountToReachSnr - snrMaxDeviation);
        maxFreqsInChord = round(averageToneCountToReachSnr + snrMaxDeviation);
    else
        minFreqsInChord = toneComponents(1);
        maxFreqsInChord = toneComponents(end);
    end
return

function indexOfFigureFrequencies = defineFigure(figureStepSize, figureDuration, figureCoherence, toneFrequenciesSetlength)
    figureRampHeight = abs(figureStepSize) * figureDuration;
    indexOfFigureFrequencies = randperm(toneFrequenciesSetlength - (figureRampHeight - 1), figureCoherence); 
    if figureStepSize < 0
        indexOfFigureFrequencies = indexOfFigureFrequencies + (figureRampHeight - 1); 
    end
return





















