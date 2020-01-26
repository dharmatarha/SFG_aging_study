function stimopt = SFGparams()
% Set parameters for random figure generation with createSFGstimuli.m 
%
% USAGE: stimopt = SFGparams()
%
% totalDuration    - total length of the whole stimuli (ms)
% chordDuration    - length of any individual chord (ms)
% toneComponents   - number of pure tone components in a chord (min-max) (integer)
% toneFrequencies  - the frequencies of the pure tone components, (min-max, selection length) (Hz)
% chordOnset       - duration of the onset and offset of a chord (ms)
% figureDuration   - duration of the hidden figure/pattern (integer)
% figureCoherence  - number of repeated tonal components in each chord of the figure (integer)
% figureOnset      - onset of the figure in the stimuli (ms); the figure
%                    should be placed in the [figureOnset, totalDuration - figureOnset]
%                    interval
% sampleFrequency  - sample frequency in Hz (1/s)
% earDistance      - distance between the ears of the subject (m)
%
%
% Based on scripts of: Tamas Kurics, Zsuzsanna Kocsis and Botond Hajdu
% date: 2020

        
% set random number generator here
c = clock; seed = round(sum(c));

stimopt = struct( ...
    'totalDuration', 2000, ...
    'chordDuration', 50, ...
    'toneComponents', 9:21, ...
    'toneFrequenciesSetlength', 129, ...
    'toneFrequenciesMin', 179, ...
    'toneFrequenciesMax', 7246, ...
    'chordOnset', 10, ...
    'figureDuration', 5, ...
    'figureCoherence', 4, ...
    'figureOnset', 200, ...
    'sampleFrequency', 44100, ...
    'randomSeed', seed);
        
end
        