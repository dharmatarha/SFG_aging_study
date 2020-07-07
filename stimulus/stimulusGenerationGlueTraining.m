function stimulusGenerationGlueTraining()
%% Script glueing stimulus generation functions together for training
%
% USAGE: stimulusGenerationGlueTraining()
%
% The goal is to generate stimuli similar to those used in O'Sullivan et al.,
% 2015, Evidence for Neural Computations of Temporal Coherence...
% (https://www.jneurosci.org/content/jneuro/35/18/7256.full.pdf) and in
% Tóth et al., 2016,  EEG signatures accompanying auditory 
% figure-ground segregation
% (https://www.sciencedirect.com/science/article/pii/S1053811916303354)
% 
% The current glue-script creates a set for training, following the first
% part of the practice session in Tóth et al. 2016. Relative to Tóth et al., 
% the main differences  are: 
% - we drop the location manipulation
% - use a fixed number of tones/chord
% - use one fix duration value
% 
% We only manipulate figure coherence and figure onset time between
% stimuli with figure. Training consists of 6 blocks of 10 trials each,
% with 5 figure trials and 5 nop-figure trials mixed randomly. Training
% blocks go from easy to harder coherence values in each block.
%
% The script creates a folder with subfolders for stimulus types, and a
% cell array accumulating all stimuli together, saved out into a .mat file
%
% The script relies on the following functions:
% SFGparams         - base parameter settings
% createSFGstimuli  - create stimuli for specific parameters
% getStimuliArray   - aggregate stimuli from multiple runs of
%                   createSFGstimuli
%
% NOTE:
% (1) Make sure SFGparams contains the right base parameters. While
% generating stimuli, we only change the coherence and onset values
% across runs of createSFGstimuli, the rest is taken from SFGparams.m. 
% 


%% Basic parameters - hardcoded values

% create date and time based ID for current stimulus set
c = clock;  % dir name based on current time
id = strcat(date, '-', num2str(c(4)), num2str(c(5)));
% directory name for stimulus subdirs
stimDirName = ['stimulusTypes-', id];
mkdir(stimDirName);
% file for saving final cell array containing all stimuli
saveF = ['stimArrayTraining-', id, '.mat'];

% figure coherence level values
cohValues = [12, 11, 10, 9, 8, 7];
% figure duration values (in no. of chords)
durValues = 10;
% figure onset values in chords
figOnsets = nan;
% no. of trials for each figure type
trialNo = 5;

% no. of stimulus types
stimTypeNo = length(figOnsets)*length(cohValues)*length(durValues);
% cell array holding the subfolder names with different stimulus types (+1
% due to folder for no-figure stimuli
stimTypeDirs = cell(stimTypeNo+1, 1);

% user message
disp([char(10), 'Called the stimulusGenerationGlueTraining script, ',... 
    'main parameter values for generated stimulus set:', ...
    char(10), 'Figure coherence values: ', num2str(cohValues),...
    char(10), 'Figure duration values: ', num2str(durValues),...
    char(10), 'Figure onsets: ', num2str(figOnsets)]);


%% Create stimuli for each figure type

% load base params
stimopt = SFGparams();

% counter for stimuli folders created
counter = 1;

% loop over figure coherence values
for c = 1:length(cohValues)
    % change params accordingly
    stimopt.figureCoh = cohValues(c);
    
    % loop over figure duration values
    for d = 1:length(durValues)
        % change params accordingly
        stimopt.figureDur = durValues(d);
        
        % loop over figure onsets
        for o = 1:length(figOnsets)
            % change params accordingly
            stimopt.figureOnset = figOnsets(o);
            
            % generate stimuli
            stimTypeDirs{counter} = createSFGstimuli(trialNo, stimopt);
            counter = counter+1;
            
        end  % for o
        
    end  % for d
    
end  % for c

% user message
disp([char(10), 'Generated figure stimuli for all requested parameter values']);


%% Create stimuli without figure

% total no. of stimuli with figure - we need and equal no. of stimuli
% without figure
figStimNo = stimTypeNo*trialNo;

% no figure = zero coherence
stimopt.figureCoh = 0;

% generate stimuli
stimTypeDirs{counter} = createSFGstimuli(figStimNo, stimopt);


%% Aggregate stimuli across types
    
stimArray = getStimuliArray(stimTypeDirs);    
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
    
    
%% Sanity checks - do we have the intended stimuli set?    

% user message
disp([char(10), 'Quick and minimal sanity checks on generated stimuli...']);

% check if we have the expected number of stimuli with requested figure
% duration values
durTypeNo = (stimTypeNo*trialNo)/length(durValues);
% check if true
durParams = cell2mat(stimArray(:, 5));
cohParams = cell2mat(stimArray(:, 6));
for c = 1:length(durValues)
    durValueNo = sum(durParams == durValues(c) & cohParams ~= 0);
    if ~isequal(durValueNo, durTypeNo)
        error('Not the right number of trials with figure duration values in resulting stimArray! Needs debugging!');
    end
end 

% same as above but for figure coherence
cohTypeNo = (stimTypeNo*trialNo)/length(cohValues);
% check if true
cohParams = cell2mat(stimArray(:, 6));
for c = 1:length(cohValues)
    cohValueNo = sum(cohParams == cohValues(c) & cohParams ~= 0);
    if ~isequal(cohValueNo, cohTypeNo)
        error('Not the right number of trials with figure coherence values in resulting stimArray! Needs debugging!');
    end
end   
    
% user message
disp('Found no obvious errors with the generated stimulus set with regards to requested parameters');
    

%% Move around dirs, save out final stimulus cell array

% move the subfolders with stimulus type files under a common stimulus
% folder
for d = 1:length(stimTypeDirs)
    movefile(stimTypeDirs{d}, [stimDirName, '/', stimTypeDirs{d}]);
end

% save out stimArray
save(saveF, 'stimArray');

% user message
disp([char(10), 'Saved out final stimulus array to ', saveF]);


return

