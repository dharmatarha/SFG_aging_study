function output = createSFGstimuli(NStimuli, fnHandle, figure)
%% Creates a sequence of Nstimuli stochastic figure-ground (SFG) stimulus.
% 
% USAGE: output = createSFGstimuli(NStimuli, fnHandle)
%
% SFG-stimulus generator, where the parameters are set via the supplied
% parameter function (SGFparams.m or your custom function). Generated sound 
% samples are written in a folder (dd-mm-yyyy-hh-mm) together with a csv
% file (dd-mm-yyyy-hh-mm-StimuliData.csv) that describes the parameter
% settings of each generated stimulus. More detailed chord information is 
% written into a mat file (dd-mm-yyyy-hh-mm-chordInfo.mat)
% in the same folder.
%
% Inputs:
% NStimuli - number of stimuli to be generated
% fnHandle - @functionname that contains the experiment options, including
%           the presence/absence of a figure over the background
% figure   - 'yes': there is a coherent figure
%            'no': added random tones instead of figure
%
% Outputs:
% output   - exit code, 1 = successful run, 0 = general error code
%
% Based on the scripts by Tamas Kurics, Zsuzsanna Kocsis and Botond Hajdu
% date: January 2020
%
% Notes:
% (1) There is no "phi" argument unlike in earlier versions. That is, all
% stimulus is prepared as coming from the midline, not from the sides 
% (2) This version removes the extra background frequencies 
% when the background plus figure frequencies exceed the 
% upper limit. 
% (3) When figure = 'no', there are still added components to the 
% standard background noise, but these tones are chosen randomly. Just as
% in createSFGstimuli_decoy.m
%
% Dependencies: 
% SFGparams.m or other function that can be fed as fnHandle
% 
%


%% Input checks, loading params

if nargin ~= 3
    output = 0;
    error('Function createSFGstimuli requires input args "NStimuli", "fnHandle" and "figure"!');
end

% sanity check for requested no. of stimuli
if ~ismembertol(NStimuli, 1:1000)
    error('Input arg NStimuli should be element of 1:1000, please double-check and edit the function if necessary!');
end

% check figure arg
if ~ismember(figure, {'yes', 'no'})
    error('Input arg "figure" should be "yes" or "no"!');
end

% loading stimulus options
stimopt = fnHandle();
if isempty(stimopt)
    error('Could not load stimulus params, please check the supplied function!');
end

% user message at function start
disp([char(10), 'Called createSFGstimuli_noaddfreq function with input args:',...
    char(10), '    NStimuli: ', num2str(NStimuli),...
    char(10), '    parameters function: ', char(fnHandle),...
    char(10), '    figure: ', figure]);


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

% setting the zeros in the output nam, ex.: filename001
digits = ceil(log10(NStimuli + 1));

% creating header for saved parameters
outFile = cell(NStimuli+1, 10);
outFile(1, :) = {'filename', 'totalDuration_sec', 'chordDuration_sec', 'chordOnset_sec', ...
                 'figure', 'figureDuration', 'figureCoherence', 'sampleFrequency_Hz', ...
                 'figureStartInterval', 'figureEndInterval'};

% create directory for saving audio data + parameters files
c = clock;  % dir name based on current time
directory = strcat(date, '-', num2str(c(4)), num2str(c(5)));
dircount = 0;
while exist(directory, 'dir')
    dircount = dircount + 1;
    if dircount > 1
        directory = strsplit(directory, '_');
        directory = directory{1};
    end
    directory = strcat(directory, '_', num2str(dircount));
end
mkdir(directory);

% save out params/options to directory
paramsFile = ['./', directory, '/', directory, '_stimopt.mat'];
save(paramsFile, 'stimopt', 'figure');

% user message
disp([char(10),'Created stimulus directory at ', directory, ',',...
    char(10), 'prepared parameters/settings, now generating stimuli...']);


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
    
    % initializing left and right speaker outputs
    soundOutput  = zeros(2, sampleFrequency * totalDuration);
    soundIndex = 1;
    
    
    %% Chord loop
    for chordPosition = 1:stimulusChordNumber
        
        % number of pure tones in a chord in the background.
        numberOfFrequencies = randi([toneComponents(1), toneComponents(end)], 1);
        % selecting random background frequencies
        indexOfFrequencies = randperm(toneFrequenciesSetlength, numberOfFrequencies);
        backgroundUniqueFrequencies = round(exp(logFreq(indexOfFrequencies)));
        
        % initializing an empty figure tone vector
        figureTonesLeft  = zeros(length(backgroundUniqueFrequencies), length(timeNodes));
        figureTonesRight = zeros(length(backgroundUniqueFrequencies), length(timeNodes));
        
        % do we have the figure in this chord position?
        if ((chordPosition >= figureStartInterval) && (chordPosition <= figureEndInterval) && (strcmp(figure, 'yes')))
            
            % at the first chord the figure is present, define it
            if (chordPosition == figureStartInterval)
                % setting the figure frequencies
                indexOfFigureFrequencies = randperm(toneFrequenciesSetlength, figureCoherence);
                figureFrequencies   = round(exp(logFreq(indexOfFigureFrequencies)));
            end
            
            % for each chord in the figure remove the figure
            % frequencies from the background; we should also
            % check whether the complete figure + background noise
            % contains more than max(toneComponents) tones. 
            backgroundUniqueFrequencies = setdiff(backgroundUniqueFrequencies,figureFrequencies);
            if length(backgroundUniqueFrequencies) + figureCoherence > toneComponents(end)
                backgroundUniqueFrequencies(toneComponents(end)-figureCoherence+1:end) = [];
            end

            % creating figure tones for this chord
            figureTonesLeft  = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));
            figureTonesRight = sin(2*pi*diag(figureFrequencies)*repmat(timeNodes, length(figureFrequencies), 1));            
        
        % if there is no figure, we add random frequencies instead
        elseif ((chordPosition >= figureStartInterval) && (chordPosition <= figureEndInterval) && (strcmp(figure, 'no')))
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

    % do you want to hear it?
    %sound(soundOutput, sampleFrequency);
    
    % save results to wav, add parameters to the cell array later saved out
    % to csv
    stimulusdigits = ceil(log10(newstimulus + 1));
    temp = char('');
    for digind = 1:(digits-stimulusdigits)
        temp = strcat(temp, '0');
    end
    c = clock;
    filename = strcat(directory, '-', temp, num2str(newstimulus));
    outFile(newstimulus+1, :) = {filename, totalDuration, chordDuration, chordOnset, ...
                                 figure, figureDuration, figureCoherence, sampleFrequency, ...
                                 figureStartInterval, figureEndInterval};
    audiowrite(strcat('./', directory, '/', filename, '.wav'), soundOutput', sampleFrequency);
    
    
end  % newstimulus for loop


%% Save out parameters, user message, return

% save out detailed info about random background + figure chords
chordInfoFile = ['./', directory, '/', directory, '_chordInfo.mat'];
save(chordInfoFile, 'allBackgroundFrequencies', 'stimulusChordNumber',... 
    'NStimuli', 'allFigureFrequencies');

% Convert cell to a table and use first row as variable names
T = cell2table(outFile(2:end,:), 'VariableNames', outFile(1,:));
 
% Write the table to a CSV file, final user message
try
    writetable(T,strcat('./', directory, '/', strcat(directory, '-', 'StimuliData.csv')));
    disp([char(10), 'Task done, files and parameters are saved to directory ', directory, char(10)]);
    output = 1;
catch ME
    disp([char(10), 'Writing parameters to csv was unsuccessful, error details:', char(10)]);
    disp(ME.message);
    disp(ME.stack);
    output = 0;
end


return























