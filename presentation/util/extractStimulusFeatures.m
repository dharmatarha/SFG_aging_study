function [stepSizes, figStartCord, stimLength, chordLength] = extractStimulusFeatures(stimArray)
    % Stimulus features for triggers + logging

    % get figure presence/absence variable for stimuli
    stepSizes = cell2mat(stimArray(:, 7));
    % figure / added noise start and end time in terms of chords
    figStartCord = cell2mat(stimArray(:, 9));

    % we check the length of stimuli + sanity check
    stimLength = cell2mat(stimArray(:, 2));
    if ~isequal(length(unique(stimLength)), 1)
        error([newline, 'There are multiple different stimulus length values ',...
            'specified in the stimulus array!']);
    else
        stimLength = unique(stimLength);
    end

    % we also check the length of a chord + sanity check
    chordLength = cell2mat(stimArray(:, 3));
    if ~isequal(length(unique(chordLength)), 1)
        error([newline, 'There are multiple different chord length values ',...
            'specified in the stimulus array!']);
    else
        chordLength = unique(chordLength);
    end

    % user message
    disp([newline, 'Extracted stimulus features']);
end