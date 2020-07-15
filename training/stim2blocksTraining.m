function [blockIdx, stimTypes, stimTypeIdx, stimArray, trialIdx] = stim2blocksTraining(stimArrayFile, seqFeatures)
%% Helper function sorting stimuli to training blocks
%
% USAGE: [blockIdx, stimTypes, stimTypeIdx, stimArray] = 
%           stim2blocksTraining(stimArrayFile, seqFeatures=[10,12; 10,11; 10,10; 10,9; 10,8; 10,7])
%
% For training phase of stochastic figure-ground (SFG) experiment. 
% The function examines the stimuli array for unique stimuli types and 
% creates blocks containing the different types, as used for training. 
% Returns block and trial indices for each stimulus.
%
%
% Inputs:
% stimArrayFile - *.mat file with cell array "stimArray" containing all 
%               stimuli + features (size: no. of stimuli X 11 columns)
% seqFeatures   - Matrix with figure duration (column one) and coherence 
%               values (column two). Each row specifies the duration and
%               coherence values needed for block. Row index corresponds
%               to block number. Aim is to imitate the training setup
%               used in (Toth et al., 2016, EEG signatures accompanying...)
%               Defaults to [10,12; 10,11; 10,10; 10,9; 10,8; 10,7]
%               
%
% Outputs:
% blockIdx      - Numeric column vector with a block index for each
%               stimulus in the stimuli array
% stimTypes     - Matrix where each row corresponds to a unique figure
%               type in terms of figure duration and coherence level. 
%               Its size is "no. of unique types" X 2, with columns 
%               corresponding to duration and coherence.
% stimTypeIdx   - Numeric column vector with a figure type index for each
%               stimulus in the stimuli array. Index numbers correspond to 
%               the rows of the stimTypes output variable 
% stimArray     - Stimulus array (cell), with the 11th column storing the
%               generated audio (two identical channels)
% trialIdx      - Numeric column vector with a trial index for each
%               stimuli, generated by randomizing the trial numbers 
%               corresponding to each block
%
% NOTES:
% Hard-coded expectation for the number of columns of stimuli array (=11)!! 
%


%% Input checks

if ~ismember(nargin, [1 2])
    error('Function needs mandatory input arg "stimArray" and optional arg "seqFeatures"!');
end
if nargin == 1
    seqFeatures = [10,12; 10,11; 10,10; 10,9; 10,8; 10,7];
end
% file with stimuli array
if ~exist(stimArrayFile, 'file')
    error('Cannot find input arg "stimArrayFile"!');
end
% number of blocks
if ~ismembertol(size(seqFeatures, 1), 1:50)
    error('Number of training blocks should be between 1 - 50!');
end

% user message
disp([char(10), 'Called stim2blocksTraining with input args: ',...
    char(10), 'stimArrayFile:', stimArrayFile,...
    char(10), 'seqFeatures: ']);
disp({'figureDuration', 'figureCoherence'});
disp(num2str(seqFeatures));


%% Loading stimuli, sanity checks

% number of stimulus blocks = number of training blocks = rows of
% seqFeatures
blockNo = size(seqFeatures, 1);

%%%%%% HARD-CODED VALUES %%%%%
% number of expected cell columns for the stimuli array
stimFeaturesNo = 11;
% header for final stimTypes cell array (see the last code block)
stimTypesHdr = {'figDuration', 'figCoherence', 'stimulusTypeIndex'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load stimuli
load(stimArrayFile, 'stimArray');
% sanity check - number of stimuli features
if ~isequal(size(stimArray, 2), stimFeaturesNo)
    error('Loaded stimuli array has unexpected size (no. of columns)!');
end
% get number of trials from stimuli array
trialNo = size(stimArray, 1);
% sanity check - trials/blocks == integer?
if mod(trialNo/blockNo, 1) ~= 0
    error(['Number of trials (', num2str(trialNo), ', based on stimuli',... 
        'array) is incompatible with the number of blocks (', num2str(blockNo), ') requested']);
end

% user message
disp([char(10), 'Loaded stimuli array, found ', num2str(trialNo), ' trials, ',...
    char(10), 'each stimulus block will contain ', num2str(trialNo/blockNo), ' trials']);


%% Get unique stimulus types

% get number of unique stimulus types based on figure presence/absence, 
% coherence and duration
durValues = cell2mat(stimArray(:, 5));
cohValues = cell2mat(stimArray(:, 6));
figPresent = cohValues~=0;  % where coherence is 0, there is no figure

% unique combinations for stimuli with figure
[stimTypes, ~, stimTypeIdx] = unique([durValues, cohValues], 'rows');

% focus first on combinations with figure present (coherence ~= 0)
stimTypesFig = stimTypes;
stimTypesFig(stimTypesFig(:, 2)==0, :) = [];

% user message about unique figure types
disp([char(10), 'There are ', num2str(size(stimTypesFig, 1)),... 
    ' different figure types in the stimuli array ',... 
    char(10), '(in terms of duration and coherence).'])

% check how many of each unique figure types we have
figTypesNumbers = nan(size(stimTypes, 1), 1);
for i = 1:size(stimTypes, 1)
    % only look at unique figure types now
    if stimTypes(i ,2) ~= 0
        figTypesNumbers(i) = sum(stimTypeIdx==i);
    end
end
figTypesNumbers(isnan(figTypesNumbers)) = [];

% if there are different numbers for trial types, that is a problem, throw
% error, otherwise report the number per type and per type per block
if length(unique(figTypesNumbers)) ~= 1
    disp([char(10), 'Stimulus types in terms of duration, coherence and figure presence:']);
    disp(stimTypes);
    disp('Number of trials per stimulus type:');
    disp(figTypesNumbers);
    error('There are different numbers of trials for different trial types!');
else
    stimNoPerType = unique(figTypesNumbers);
    disp([char(10), 'There are ', num2str(stimNoPerType), ' trials for each trial type']);
end


%% Check stimuli without figure

% we expect that the no. of stimuli without figure equals the no. of
% stimuli with figure
if ~isequal(sum(figPresent), trialNo/2)
    error(['There are ', num2str(sum(figPresent)), ' stimuli with figure and ',...
        num2str(sum(figPresent==0)), ' stimuli without figure, there is a problem!']);
end


%% Sort stimuli with figure into blocks

% split trials into blocks according to seqFeatures
blockIdx = nan(trialNo, 1); % block index for each stimulus
for seq = 1:blockNo
    % which unique figure type corresponds to the features of the current
    % block (duration + coherence value)
    idx = find(ismember(stimTypes(:, 1:2), seqFeatures(seq,:), 'rows'));
    % go through the duration and coherence values of all trials, look for
    % the ones with the current stimType
    blockIdx(ismember([durValues, cohValues], stimTypes(idx, 1:2), 'rows')) = seq;
end

% user message
disp([char(10), 'Sorted stimuli with figure into blocks, with equal number of trials per type per block']);


%% Sort equal numbers of stimuli without figure to each block

% initial set of indices for stimuli without a figure
idx = find(figPresent==0);
% go through all blocks
for seq = 1:blockNo
    % select a random subset of stimuli without figure
    seqIdx = idx(randperm(length(idx), stimNoPerType));
    % assign the selected stimuli to the right block
    blockIdx(seqIdx) = seq;
    % set the selected subset of available indices to stg out of range
    figPresent(seqIdx) = 999;
    % define again the available set of non-figure stimuli indices
    idx = find(figPresent==0);
end
    
% user message
disp([char(10), 'Sorted stimuli without figure into blocks, with equal number of trials per block']);


%% Get exact trial indices for stimuli, return

% expected number of stimuli per block
stimNoPerBlock = trialNo/blockNo;
% init a trial indices column vector
trialIdx = zeros(trialNo, 1);

% go through each block and generate trial indices for corresponding
% stimuli
for block = 1:blockNo
    % check if we have the expected number of trials
    if ~isequal(sum(blockIdx==block), stimNoPerBlock)
        error(['There are ', num2str(sum(blockIdx==block)),... 
            ' trials for block ', num2str(block), ' instead of ',... 
            num2str(stimNoPerBlock), ', investigate!']);
    end
    % trial indices for given block, in order
    trialIdxForBlock = (block-1)*stimNoPerBlock+1:block*stimNoPerBlock; 
    % randomizing trial indices for given block
    trialIdxForBlock = trialIdxForBlock(randperm(length(trialIdxForBlock)));
    % assigning the randomized trial indices to the stimuli corresponding
    % to the block
    trialIdx(blockIdx==block) = trialIdxForBlock;
end

% user message
disp([char(10), 'Randomized trial order within blocks, generated final trial indices vector']);


%% Transform stimTypes varialbe into human readable form 

% get cell array with headers
stimTypes = [stimTypesHdr; num2cell([stimTypes, [1:size(stimTypes, 1)]'])];

disp([char(10), 'Detailed information about stimulus types is stored in '...
    'the stimTypes cell array']);


return






