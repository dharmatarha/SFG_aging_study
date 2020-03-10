function stimopt = SFGparams()
% Set parameters for random figure generation with createSFGstimuli.m 
%
% USAGE: stimopt = SFGparams()
%
% totalDur         - total length of the whole stimuli (sec)
% chordDur         - length of any individual chord (sec)
% toneComp         - number of pure tone components in a chord (min-max) 
%                   (integer). It is ignored if the snr is set. 
% toneFreq         - the frequencies of the pure tone components, (min-max, 
%                   selection length) (Hz)
% chordOnset       - duration of the onset and offset of a chord (sec)
% figureDur        - duration of the hidden figure/pattern (integer)
% figureCoh        - number of repeated tonal components in each chord of
%                   the figure (integer)
% figureMinOnset   - onset of the figure in the stimuli (sec); the figure
%                   should be placed in the [figureOnset, totalDuration - 
%                   figureOnset] interval
% figureOnset      - Onset value in chord number for figures. If empty or
%                   nan, its value will be chosen randomly from possible 
%                   values (see figureMinOnset).
% figureStepS      - step size with which the figure is raised/lowered at
%                   each chord within the predefined frequency set
%                   (toneFreq)
% sampleFreq       - sample frequency in Hz
%
%
% Based on scripts of: Tamas Kurics, Zsuzsanna Kocsis and Botond Hajdu
% date: 2020

        
% set random number generator here
c = clock; seed = round(sum(c));

stimopt = struct( ...
    'totalDur', 2, ...
    'chordDur', 0.05, ...
    'toneComp', 20, ...
    'toneFreqSetL', 129, ...
    'toneFreqMin', 179, ...
    'toneFreqMax', 7246, ...
    'chordOnset', 0.01, ...
    'figureDur', 10, ...
    'figureCoh', 8, ...
    'figureMinOnset', 0.3, ...
    'figureOnset', nan,...
    'figureStepS', 2, ...
    'sampleFreq', 44100, ...
    'randomSeed', seed);
        
end
        