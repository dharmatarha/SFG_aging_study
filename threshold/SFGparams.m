function stimopt = SFGparams()
% Set parameters for random figure generation with createSFGstimuli.m 
%
% USAGE: stimopt = SFGparams()
%
% totalDuration    - total length of the whole stimuli (ms)
% chordDuration    - length of any individual chord (ms)
% toneComponents   - number of pure tone components in a chord (min-max) (integer). It is ignored if the snr is set. 
% toneFrequencies  - the frequencies of the pure tone components, (min-max, selection length) (Hz)
% chordOnset       - duration of the onset and offset of a chord (ms)
% figureDuration   - duration of the hidden figure/pattern (integer)
% figureCoherence  - number of repeated tonal components in each chord of the figure (integer)
% figureOnset      - onset of the figure in the stimuli (ms); the figure
%                    should be placed in the [figureOnset, totalDuration - figureOnset]
%                    interval
% figureStepSize   - step size with which the figure is raised/lowered at
%                    each chord within the predefined frequency set
%                    (toneFrequencies)
% snr              - signal-to-noise ratio (min-max) (integer). If set, toneComponents has no
%                    effect. Set to -1 if not used (the value 0 generates a
%                    signal without noise.
% snrMaxDeviation  - Maximum random deviation from the calculated
%                    background tone count required to reach the desired SNR.
% sampleFrequency  - sample frequency in Hz (1/s)
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
    'figureStepSize', 2, ...
    'snr', 1, ...
    'snrMaxDeviation', 1, ...
    'sampleFrequency', 44100, ...
    'randomSeed', seed);
        
end
        