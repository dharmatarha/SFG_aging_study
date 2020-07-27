# SFG_aging_study
Matlab code for the ongoing research project _**Testing aging deficits in auditory object perception**_ at the **Sound and Speech Perception Research Group** at TTK, Budapest (Winkler lab). Project PI: Brigitta Tóth.
<br></br>
## On SFG
SFG stands for Stochastic Figure-Ground, a stimulus type used in auditory research that combines sets of randomly selected tones from a broad frequency range (*Background*) with short sequences of repeated tones (*Figure*). The latter is regularly perceived as an auditory object, that is, as a sound source separate from the background. 
For more on SFG see (among others):  
- [Teki et al., 2011. Brain bases for auditory stimulus-driven figure–ground segregation](https://www.jneurosci.org/content/jneuro/31/1/164.full.pdf)  
- [O'Sullivan et al., 2015. Evidence for neural computations of temporal coherence in an auditory scene and their enhancement during active listening](https://www.jneurosci.org/content/jneuro/35/18/7256.full.pdf)
- [Tóth et al., 2016. EEG signatures accompanying auditory figure-ground segregation](https://europepmc.org/article/PMC/5656226)
<br></br>
## Dependencies / environment
The study relies on [Psychtoolbox 3.0.16](https://psychtoolbox.org/) under Ubuntu 18.04 for stimulus generation/presentation. While Psychtoolbox is compatible with Octave, code development is for Matlab (2017a) with Octave never tested. In principle though, adapting the functions to Octave should be simple. 

Stimulus presentation settings / parameters are specified for the Mordor lab at RCNS, Budapest. We rely on a two-X-screens setup (two independent displays): one for stimulus presentation, one for control. Subject responses are recorded via standard keyboards. For EEG, TTL-logic level triggers are supported via the great [ppdev-mex interface by Andreas Widmann](https://github.com/widmann/ppdev-mex).
<br></br>
## How to start
Just include the repo (with its subfolders) in your path. For stimulus presentation functions make sure (1) you have a working Psychtoolbox setup, preferably under Linux; and (2) that all Screen, PsychPortAudio, etc. settings in the relevant functions are matched to your setup.<br></br>  
#### (1) Check out SFG stimuli 
Take a look at a stimulus first. Define a struct containing the stimulus options by calling SFGparams.m: 
```
stimopt = SFGparams;
```
Type `help SFGparams` for the meaning of each field. Change any field value you want then call
```
[soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt);  % see the help for loudness correction option (loudnessEq flag)
```
The matrix `soundOutput` holds the raw audio of the stimulus, play it with any method you prefer (e.g. quick check with `sound(soundOutput, stimopt.sampleFreq)`. To check if the generated audio reflects the stimulus options, run the plotting function plotChordsSingleStim:
```
fig = plotChordsSingleStim(soundOutput, stimopt, allFigFreqs, allBackgrFreqs);
```
If all is well, the right side of the plotted figure (spectrogram of audio) matches the left side (chord components the stimulus should be built from).<br></br>
You can also play around with the main stimulus options in an interactive playback loop using SFGtesting:
```
SFGtesting(false);  % see the help for loudness correction and base stimulus options
```

#### (2) Generate stimuli in batches
Generate a set of stimuli with the function `createSFGstimuli`. First define a stimulus options struct:
```
stimopt = SFGparams;
disp(stimopt);
```
Let's generate a set of 20 SFG stimuli with a coherence level of 12, figure duration of 9, loudness correction flag set to "true" and a step size of 0 (that is, *Figure* is simply composed of repetitions of the same tones). Background tones, figure tone components and figure onset (if stimopt.figureOnset==NaN) will vary randomly across members of the set. 
```
NStimuli = 20;
stimopt.figureCoh = 12;
stimopt.figureDur = 9;
stimopt.figureStepS = 0;
wavDir = createSFGstimuli(NStimuli, stimopt, true)  % batch stimuli generation, loudness correction set to true
```
SFG stimuli are saved out into `wavDir`, together with the stimulus options used for their generation (`*_stimopt.mat`). A `*_StimuliData.csv` file containing the main parameters of each stimulus / file is also present, just as a `*_chordInfo.mat` file containing detailed chord information. 
To check any stimulus in the set, use `plotChords`:
```
% check the first stimulus in the set
fig = plotChords(wavDir, 1);
```
Or run it in a loop to generate and save a figure for each stimulus in `wavDir`:
```
wavFiles = dir([wavDir, '/*.wav']);  % list of wav files
for i=1:NStimuli; 
    fig = plotChords(wavDir, i);
    % generate a .png file name from the path of the wav file
    [~, wavName, ~] = fileparts(wavFiles(i).name);
    figFile=[wavFiles(i).folder, '/', wavName, '.png'];
    saveas(fig, figFile);
    close(fig);
end
```
For a study we usually need a number of different stimuli sets (e.g. stimuli with a *Figure* and stimuli without one, that is, with figureCoh=0). The tool `getStimuliArray` takes as input a cell array of wav folders (outputs if `createSFGstimuli`) and collects all stimuli together with their main parameters into one big array:
```
stimopt = SFGparams;
% figure coherence values for generating stimuli
cohValues = [0 10];
% number of SFG stimuli for each run of createSFGstimuli
NStimuli = 20;
% var to hold wav dir names
sfgDirs = cell(length(cohValues), 1);

% generate stimuli
for i = 1:length(cohValues)
    stimopt.figureCoh = cohValues(i);
    sfgDirs{i} = createSFGstimuli(NStimuli, stimopt, true);
end
    
% collect all stimuli into one array
stimArray = getStimuliArray(sfgDirs);
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
disp(stimArray)

```
The last column in stimArray holds the raw audio. Any sorting into blocks / types can now be done easily using this cell array. <br></br>
The above process is implemented for specific settings in "glueing" scripts (`stimulusGenerationGlueTraining` and `stimulusGenerationGlueThresholded`). For example, our training stimuli set can be generated simply by:
```
stimulusGenerationGlueTraining;
```


### Run the experiment


## List of all functions
Functions in `/stimulus` are used for stimulus generation:  
- **stimulusGenerationGlue.m** - Glueing script for generating full stimulus ensemble for an experiment, needs to be edited for use case in question  
- **SFGparams.m** - Basic parameters for stimuli generation
- **createSFGstimuli.m** - Generates given number of stimuli for specific parameters
- **getStimuliArray.m** - Aggregates stimulus (sub)sets into full ensemble
- **plotChords.m** - Diagnostic and visualization tool: plot the chords defining a given stimulus next to its spectrogram
- **getEnDiff.m** - Diagnostic tool testing for acoustic energy differences between two stimuli (sub)sets

Functions in `/presentation` for stimulus presentation and recording responses:  
- **SFGmain.m** - Main experimental script responsible for stimulus presentation and recording responses. Requires the rest of the functions under `/presentation`. Good enough for piloting, doesn't fully handle yet triggers for EEG. Responses are expected via regualar keyboards.
- **expParamsHandler.m** - Helper function for detecting existing parameters/settings and results for subjects in a multi-session experiment. Also handles loading and sorting of stimuli, saving subject-specific parameters, etc. Requires stim2blocks.m
- **stim2blocks.m** - Helper function detecting unique stimulus types in a stimulus array and sorting them into the required number of blocks. Ensures that the same number of stimuli from each stimulus type is in each block (basic counterbalancing across blocks).
<br></br>
## Citation
Code is free to all (GNU Public license v2) but please cite earlier work by the group:

Tóth, Brigitta, Zsuzsanna Kocsis, Gábor P. Háden, Ágnes Szerafin, Barbara G. Shinn-Cunningham, and István Winkler. "EEG signatures accompanying auditory figure-ground segregation." Neuroimage 141 (2016): 108-119. https://doi.org/10.1016/j.neuroimage.2016.07.028

