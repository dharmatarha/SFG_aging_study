function fs = extractSampleRate(stimArray)
    % sampling rate is derived from stimuli
    fs = cell2mat(stimArray(:, 8));
    % sanity check - there should be only one fs value
    if ~isequal(length(unique(fs)), 1)
        error([newline, 'There are multiple different sampling rates ',...
            'specified in the stimulus array!']);
    else
        fs = unique(fs);
    end
end