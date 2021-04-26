function [logVar, stimTypes] = setUpTriggers(stimArray, logVar, logHeader, stimTypes)
    % Triggers

    % basic triggers for trial start, sound onset and response
    trig = struct;
    trig.trialStart = 200;
    trig.playbackStart = 210;
    trig.respPresent = 220;
    trig.respAbsent = 230;
    trig.l = 1000; % trigger length in microseconds
    trig.blockStart = 100;

    % triggers for stimulus types, based on the number of unique stimulus types
    % we assume that stimTypes is a cell array (with headers) that contains the 
    % unique stimulus feature combinations, with an index for each combination 
    % in the last column
    uniqueStimTypes = cell2mat(stimTypes(2:end,end));
    if length(uniqueStimTypes) > 4900
        error('Too many stimulus types for properly triggering them');
    end
    % triggers for stimulus types are integers in the range 151-199
    trigTypes = uniqueStimTypes+150;
    % add trigger info to stimTypes cell array as an extra column
    stimTypes = [stimTypes, [{'trigger'}; num2cell(trigTypes)]];

    % create triggers for stimulus types, for all trials
    trig.stimType = cell2mat(stimArray(:, 13))+150;

    % add triggers to logging / results variable
    logVar(2:end, strcmp(logHeader, 'trigger')) = num2cell(trig.stimType);
    % TODO add triggers as the staircase runs

    % user message
    disp([newline, 'Set up triggers']);
end