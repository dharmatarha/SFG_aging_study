function stimulusGenerationGlue()
%% Script glueing stimulus generation functions together for our use case
%
% USAGE: stimulusGenerationGlue
%
% Our goal is generate stimuli similar to those used in Toth et al., 2016
% (https://www.sciencedirect.com/science/article/pii/S1053811916303354?via%3Dihub).
% The difference is that we drop the location manipulation. So we have 12
% stimulus types based on three factors:
% 
% - Figure (Present vs Absent)
% - Coherence Level (4 vs 6)
% - Duration (3 vs 4 vs 5)
%
% Here we generate trials for one example block (96 trials, 8 of each
% type), the final set for the main part of the experiment consists of 20 
% such blocks.
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
% generating stimuli, we only change the duration and coherence values
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
saveF = ['stimArray-', id, '.mat'];
% figure presence/absence values
figValues = {'yes', 'no'};
% figure coherence level values
cohValues = [4 6];
% figure duration values (in no. of chords)
durValues = [3 4 5];
% no. of trials for each stimulus type
trialNo = 8;
% no. of stimulus types
stimTypeNo = length(figValues)*length(cohValues)*length(durValues);
% cell array holding the subfolder names with different stimulus types
stimTypeDirs = cell(stimTypeNo, 1);

% user message
disp([char(10), 'Called the stimulusGenerationGlue script, ',... 
    'hard-coded main parameter values:', ...
    char(10), 'Figure coherence values: ', num2str(cohValues),...
    char(10), 'Figure duration values: ', num2str(durValues),...);
    char(10), 'Figure presence/absence: ']);
disp(figValues);


%% Create stimuli for each type

% load base params
stimopt = SFGparams();
% counter for stimuli folders created
counter = 1;

% loop over figure presence/absence values
for f = 1:length(figValues)
    % figPresent is fed to createSFGparams directly
    figPresent = figValues{f};
    
    % loop over figure coherence values
    for c = 1:length(cohValues)
        % change params accordingly
        stimopt.figureCoherence = cohValues(c);
        
        % loop over figure duration values
        for d = 1:length(durValues)
            % change params accordingly
            stimopt.figureDuration = durValues(d);
            
            % generate stimuli
            stimTypeDirs{counter} = createSFGstimuli(trialNo, stimopt, figPresent);
            counter = counter+1;
            
        end  % for d
        
    end  % for c
    
end  % for f

% user message
disp([char(10), 'Generated stimuli for all requested parameter values']);


%% Aggregate stimuli across types
    
stimArray = getStimuliArray(stimTypeDirs);    
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
    
    
%% Sanity checks - do we have the intended stimuli set?    

% user message
disp([char(10), 'Quick and minimal sanity checks on generated stimuli...']);

% intended number of trials with each of figValues
figTypeNo = (stimTypeNo*trialNo)/length(figValues);
% check if true
figParams = stimArray(:, 5);
for f = 1:length(figValues)
    figValueNo = sum(ismember(figParams, figValues{f}));
    if ~isequal(figValueNo, figTypeNo)
        error('Not the right number of trials with figure presence/absence values in resulting stimArray! Needs debugging!');
    end
end
% same as above but for figure duration
durTypeNo = (stimTypeNo*trialNo)/length(durValues);
% check if true
durParams = cell2mat(stimArray(:, 6));
for c = 1:length(durValues)
    durValueNo = sum(durParams == durValues(c));
    if ~isequal(durValueNo, durTypeNo)
        error('Not the right number of trials with figure duration values in resulting stimArray! Needs debugging!');
    end
end 
% same as above but for figure coherence
cohTypeNo = (stimTypeNo*trialNo)/length(cohValues);
% check if true
cohParams = cell2mat(stimArray(:, 7));
for c = 1:length(cohValues)
    cohValueNo = sum(cohParams == cohValues(c));
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

