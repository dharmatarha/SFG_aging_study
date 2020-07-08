function trialTypes = getTrialTypes(subNum, trialMax, stimopt)
%% Function to get trial types for a subject based on thresholding results
%
% USAGE: trialTypes = getTrialTypes(subNum)
%

%% Get subject's folder, load results from SFGthreshold* functions

% subject folder name
dirN = ['subject', num2str(subNum)];

% check if subject folder already exists, complain if not
if ~exist(dirN, 'dir')
    error(['Could not find subject''s folder at ', dirN, '!']);
end

% get file name for SFGthresholdCoherence results - exact file name contains unknown time stamp
cohResFile = dir([dirN, '/thresholdCoherence_sub', num2str(subNum), '*.mat']);
cohResFilePath = [cohResFile.folder, '/', cohResFile.name];
% load results from coherence-thresholding
cohRes = load(cohResFilePath);

% get file name for SFGthresholdBackground results - exact file name contains unknown time stamp
backgrResFile = dir([dirN, '/thresholdBackground_sub', num2str(subNum), '*.mat']);
backgrResFilePath = [backgrResFile.folder, '/', backgrResFile.name];
% load results from background-thresholding
backgrRes = load(cohResFilePath);


%% Define base coherence value and the two types of background tone numbers

% coherence value to be used throughout all trials
baseCoherence = cohRes.coherenceEst;
% background values for normal (~70% accuracy) and easy (~80% accuracy)
% trials
stdBackgr = stimopt.toneComp-baseCoherence;
lowBackgr = backgrRes.backgroundEst;


%% Define trial types arrays

%% Load results from SFGthresholdCoherence, get coherence level 

% user message
disp([char(10), 'Loading SFGthresholdCoherence results for subject']);

% get file name - exact file name contains unknown time stamp
cohResFile = dir([dirN, '/thresholdCoherence_sub', num2str(subNum), '*.mat']);
cohResFilePath = [cohResFile.folder, '/', cohResFile.name];

% load results from coherence-thresholding
cohRes = load(cohResFilePath);

% rename the coherence estimate from SFGthresholdCoherence results for
% readability
baseCoherence = cohRes.coherenceEst;  % base coherence value needs to be stored separately from stimopt, as stimopt.figureCoh is overwritten in figure-absent trials

% user message
disp('Done');
disp(['Coherence level for background-thresholding: ', num2str(baseCoherence)]);

