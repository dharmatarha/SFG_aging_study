function stimopt = SFGparamsIntro()
% Set parameters for random figure generation with createSFGstimuli.m 
%
% To be used with SFGintro.m, that is, with the introductory phase of the
% study.
%
% USAGE: stimopt = SFGparamsIntro()
%
% totalDur         - Numeric value, total length of the whole stimulus (sec)
% chordDur         - Numeric value, length of any individual chord (sec)
% toneComp         - Numeric value, number of pure tone components in a 
%                   chord. 
% toneFreqMin      - Numeric value, minimum frequency of the pure tone 
%                   components vector (Hz)
% toneFreqMax      - Numeric value, maximum frequency of the pure tone 
%                   components vector (Hz)
% toneFreqSetL     - Numeric value, number of elements requested in the 
%                   pure tone components vector
% chordOnset       - Numeric value, duration of the onset and offset of a 
%                   chord (sec)
% figureDur        - Numeric value, duration of the hidden figure/pattern
%                   in terms of chords
% figureCoh        - Numeric value, number of repeated tonal components in 
%                   each chord of the figure
% figureMinOnset   - Numeric value, minimum allowed onset of the figure in 
%                   the stimulus in sec; the figure should be placed in the 
%                   [figureMinOnset, totalDuration - figureMinOnset] interval
% figureOnset      - Numeric value, figure onset in terms of chords. 
%                   If nan, its value will be chosen randomly from 
%                   possible values (see figureMinOnset).
% figureStepS      - Numeric value, step size with which the figure is 
%                   raised/lowered at each chord within the predefined 
%                   frequency set (toneFreqMin, -Max, -SetL)
% sampleFreq       - Numeric value, sample frequency in Hz
% randomSeed       - Numeric value, a seed for the random number generator. 
%                   Included mainly for testing/troubleshooting, other 
%                   scripts might not rely on it. 
%
% Based on scripts of: Tamas Kurics, Zsuzsanna Kocsis and Botond Hajdu
% date: 2020

        
% For the intro we generate stimuli on the fly but only call 
% the params function once. Thus, it is better to ommit setting the 
% random seed as it could lead to repeating the same stimuli over and over 
% again.         
% (Get a seed for the random number generator, as part of the current param
% set)
% c = clock; seed = round(sum(c));
seed = [];

% fields = parameter values
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
        