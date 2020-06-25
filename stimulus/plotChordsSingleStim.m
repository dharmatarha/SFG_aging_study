function plotChordsSingleStim(audioData, stimopt, allFigFreqs, allBackgrFreqs)
%% Plot background + figure chords for SFG stimulus
%
% USAGE: plotChordsSingleStim(audioData, stimopt, allFigFreqs, allBackgrFreqs)
%
% Reads in and plots a given SFG stimulus, both in terms of the frequency
% components as described in the parameter files and in terms of the
% spectrogram. Assumes that wav files were generated with
% createSingleSFGstimuli.m
%
% Inputs:
% audioData         - Numeric matrix, audio data. Sized 1/2 X samples 
%                   (mono or stereo)
% stimopt           - Stimulus parameters in struct, as used with
%                   createSingleSFGstim.m
% allFigFreqs       - Figure frequencies in a figure components X chords
%                   numeric matrix. Output of createSingleSFGstim.m
% allBackgrFreqs    - Background frequencies in a no. of tones X chords
%                   numeric matrix. Output of createSingleSFGstim.m
%
% The only output is a figure with two subplots.
%
%

%% Input checks

if nargin ~= 4
    error('Requires input args "audioData", "stimopt", "allFigFreqs" and "allBackgrFreqs"!');
end

disp([char(10), 'Called function plotChordsSingleStim with inputs: ',...
     char(10), 'audioData: matrix sized ', num2str(size(audioData)),...
     char(10), 'allFigFreqs: matrix sized ', num2str(size(allFigFreqs)),...
     char(10), 'allBackgrFreqs: matrix sized ', num2str(size(allBackgrFreqs)),...
     char(10), 'stimulus options: ']);
disp(stimopt);


%% Basics, load params and audio

% extract audio and figure features
fs = stimopt.sampleFreq;  % sampling freq (Hz)
dur = stimopt.totalDur;  % duration of stimulus in secs
chordDur = stimopt.chordDur;  % chord duration in secs
figDur = stimopt.figureDur;  % figure duration in chords
figCoh = stimopt.figureCoh;  % figure coherence in chords
figStepSize = stimopt.figureStepS;  % figure step size (within the frequency grid)
chordN = stimopt.totalDur/stimopt.chordDur;  % number of chords
compNo = stimopt.toneComp;  % number of components: background + figure tones

% figure intervals
figIntervals = find(any(~isnan(allFigFreqs)));  % all intervals with a figure
figStart = figIntervals(1);  % figure start time in chords
figEnd = figIntervals(end);  % last figure element in chords
snr = figCoh/stimopt.toneComp;  % signal-to-noise ratio

% frequency range used
freqLimits = [stimopt.toneFreqMin, stimopt.toneFreqMax];

% sanity checks
if ~isequal(size(audioData, 2), dur*fs)
    error('Sampling frequency or audio length does not match the parameters in stimopt!');
end
if ~isequal(chordN, size(allBackgrFreqs, 2)) || ...
        ~isequal(chordN, size(allFigFreqs, 2))
    error('Stimulus duration does not match that from stimopt!');
end

% user message
disp([char(10), 'Properties of SFG stimulus according to parameters in stimopt:', char(10),...
    'Figure coherence level: ', num2str(figCoh), char(10),...
    'Figure step size: ', num2str(figStepSize), char(10),...
    'Figure duration: ', num2str(figDur), ' chords', char(10),...
    'Figure starts at chord: ', num2str(figStart), char(10),...
    'Figure ends at chord: ', num2str(figEnd), char(10),...
    'Chord duration: ', num2str(chordDur*1000), ' ms', char(10),...
    'Signal-to-noise ratio: ', num2str(snr), char(10),...
    'Total stimulus duration: ', num2str(dur*1000), ' ms']);


%% Plotting: chord info and spectrogram into two subplots 

% % we leave this here so that we can create multiple figures when calling
% % the function in a loop
% figure(wavN);

% plot detailed chord info first (left)

subplot(1, 2, 1);
plot(allBackgrFreqs', 'bo');
hold on;
plot(allFigFreqs', 'r*', 'LineWidth', 3);  % emphasize figure frequency components
% two black lines mark figure start and end times
linX = [figStart-0.5, figEnd+0.5; figStart-0.5, figEnd+0.5];
linY = [freqLimits(1)-1, freqLimits(1)-1; freqLimits(2)+600, freqLimits(2)+600];
line(linX, linY, 'Color', 'k', 'LineWidth', 2);
% subplot details
title('Background and figure chords used for SFG stimulus');
xlabel('Chord number');
ylabel('Log frequency');
hold off;
set(gca, 'FontSize', 14);

% plot the spectrogram second (right)

subplot(1, 2, 2);
% values for frequencies of interest
fValues = linspace(1, (ceil(freqLimits(2)/1000))*1000, 1000);
spectrogram(audioData(1,:), dur/chordN*fs, 0, fValues, fs, 'yaxis', 'MinThreshold', -70);
hold on; 
% two white lines mark figure start and end times
linX = [(figStart-1)*dur/chordN, figEnd*dur/chordN; (figStart-1)*dur/chordN, figEnd*dur/chordN];
linY = [(freqLimits(1)-100)/1000, (freqLimits(1)-100)/1000; (freqLimits(2)+600)/1000, (freqLimits(2)+600)/1000];
line(linX, linY, 'Color', 'w', 'LineWidth', 2);
% white markers for figure chords
markerX = [(figStart-0.5)*dur/chordN:dur/chordN:(figEnd-0.5)*dur/chordN];
markerFreqs = allFigFreqs';
markerFreqs(isnan(markerFreqs)) = 0;
markerFreqs(ismember(markerFreqs, zeros(1, size(markerFreqs, 2)), 'rows'), :) = [];
plot(markerX, markerFreqs/1000, 'wx', 'LineWidth', 2, 'MarkerSize',12);  % emphasize figure frequency components
% subplot details
title('Spectrogram of SFG stimulus');
hold off;

% Set overall figure features
set(gcf,'color','w');
figureTitle = ['Coh_', num2str(figCoh), '__Dur_', num2str(figDur)];
set(gcf, 'NumberTitle', 'off', 'Name', figureTitle);
set(gca, 'FontSize', 14);
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.1, 0.9, 0.9]);


return





