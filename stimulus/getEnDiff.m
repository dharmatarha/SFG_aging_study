function [eValues, eMeans, p, stats] = getEnDiff(folderA, folderB)
%% Helper function to evaluate acoustic energy in figureGround stimuli
%
% USAGE: [eValues, eMeans, p, stats] = getEnDiff(folderA, folderB)
%
% This function tests for acoustic energy difference between two sets of 
% stimuli. We expect the two sets to be in two separate folders (default 
% createSFGstim behavior). 
%
% Inputs:
% folderA               - Char array, path to a folder with wav files, each
%                       wav file a stochastic figure-ground stimulus
% folderB  -            - Char array, path to a folder with wav files, each
%                       wav file a stochastic figure-ground stimulus
%
% Outputs:
% eValues               - Acoustic energy in each file from the two input
%                       folders - column 1 is for folderA, column 2 for
%                       folderB files
% eMeans                - Mean values of the columns (see above)
% p                     - independent samples t-test result from comparing
%                       energy values across the two groups of files
% stats                 - detailed results from the t-test (ttest2 output
%                       "stats")
%

%% Basics, input checks

if nargin ~= 2
    error('Function getRMS requires input args "folderA" and "folderB"!');
end
if ~exist(folderA, 'dir')
    error('Input arg "folderA" needs to point to an existing folder!');
end
if ~exist(folderB, 'dir')
    error('Input arg "folderB" needs to point to an existing folder!');
end

disp([char(10), 'Started function getEnDiff with input args: ', char(10),...
    'folderA: ', folderA, char(10),...
    'folderB: ', folderB, char(10)]);


%% Get wav lists

% simply list files ending in wav
wavList1 = dir([folderA, '/', '*.wav']);
wavList2 = dir([folderB, '/', '*.wav']);
% sanity check - did we find any?
if isempty(wavList1) || isempty(wavList2)
    error('Did not find any wav file in at least one of the supplied dirs!');
end
% user message
disp(['Found ', num2str(length(wavList1)), ' files in "folderA"']);
disp(['Found ', num2str(length(wavList2)), ' files in "folderB"']);
    

%% Load files, get length and rms

% preallocate
maxL = max(length(wavList1), length(wavList2));  % maximum list length
eValues = nan(maxL, 2);

% loop through files, get energy values
for i = 1:maxL
    
    % wav file from wavList1
    if i <= length(wavList1)
        % load audio data
        [data, fs] = audioread([folderA, '/', wavList1(i).name]);
        % sanity check
        if fs ~= 44100
            error(['Found a bad file: ', wavList1(i).name]);
        end
        % get energy 
        eValues(i, 1) = sum(data(:, 1).^2);
    end
    
    % wav file from wavList2
    if i <= length(wavList2)
        % load audio data
        [data, fs] = audioread([folderB, '/', wavList2(i).name]);
        % sanity check
        if fs ~= 44100
            error(['Found a bad file: ', wavList2(i).name]);
        end
        % get energy 
        eValues(i, 2) = sum(data(:, 1).^2);
    end    
    
end  % files for loop


%% Get mean values, test for difference, ending

% get means
eMeans = mean(eValues, 1, 'omitnan');
disp(['Mean acoustic energy for "folderA" files: ', num2str(eMeans(1))]);
disp(['Mean acoustic energy for "folderB" files: ', num2str(eMeans(2))]);

% compare group values
values1 = eValues(~isnan(eValues(:, 1)), 1);
values2 = eValues(~isnan(eValues(:, 2)), 2);
[~, p , ~, stats] = ttest2(values1, values2);
% get effect size (cohen's d)
sd1 = std(eValues(:,1), 0, 'omitnan');
sd2 = std(eValues(:,2), 0, 'omitnan');
sdPooled = ((sd1^2+sd2^2)/2)^0.5;
cohensD = (eMeans(2)-eMeans(1))/sdPooled;
% display results
disp(['T-test result for difference: ', num2str(p)]);
disp(['Cohen''s D: ', num2str(abs(cohensD))]);


return






