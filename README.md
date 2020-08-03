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

Stimulus presentation settings / parameters are specified for the Mordor lab at RCNS, Budapest. We rely on a two-X-screens setup (two independent displays): one for stimulus presentation, one for control. Subject responses are recorded via standard keyboards. For EEG, TTL-logic level triggers are supported via the great [ppdev-mex interface by Andreas Widmann](https://github.com/widmann/ppdev-mex). For loudness perception corrections we rely on the [iso226 interpolation by Christopher Hummersone](https://github.com/IoSR-Surrey/MatlabToolbox/blob/master/%2Biosr/%2Bauditory/iso226.m).
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
The matrix `soundOutput` holds the raw audio of the stimulus - play it with any method you prefer (e.g. quick check with `sound(soundOutput, stimopt.sampleFreq)`. To check if the generated audio reflects the stimulus options, run the plotting function plotChordsSingleStim:
```
fig = plotChordsSingleStim(soundOutput, stimopt, allFigFreqs, allBackgrFreqs);
```
If all is well, the right side of the plotted figure (spectrogram of audio) matches the left side (chord components the stimulus should be built from).<br></br>
You can also play around with the main stimulus options in an interactive playback loop using SFGtesting:
```
SFGtesting;  % see the help for loudness correction and base stimulus options
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
The last column in the variable `stimArray` holds the raw audio. Any sorting into blocks / types can now be done easily using this cell array. <br></br>
The above process is implemented for specific settings in "glueing" scripts (`stimulusGenerationGlueTraining` and `stimulusGenerationGlueThresholded`). For example, our training stimuli set can be generated simply by:
```
stimulusGenerationGlueTraining;
```


## Run the experiment

Introduce the task by calling `SFGintro(subjectNumber)`. The aim of this phase is for participants to understand what tye of object we ask them to detect. During the introduction, the participant can initiate the playback of a stimulus with or without a figure in each trial. 
```
% all experimental scripts are called with the subject number
subNum = 99;
SFGintro(subNum);
```

Run a training session next with `SFGtraining(subjectNumber)`. Participants' task is to indicate with key presses in each trial whether they heard a *Figure* or not in the stimulus (yes-no detection task). Half of the trials contain a *Figure*. Importantly, there is visual feedback after each trial. The training phase consists of 6 blocks with 10 trials each. Blocks go from easy to less-easy in terms of coherence. Requires either a pre-generated training stimuli set named `stimArrayTraining.mat` or a path to a specific stimuli set (and corresponding edits to `stim2blocksTraining`).
```
SFGtraining(subNum);
```

In our setup, we aim to generate an "easy" and a "hard" set of participant-specific stimuli. The "easy" set should elicit a ~85% rate of correct responses while the hard is amed at ~65%. To achieve this we rely on individual thresholding using the [Quest procedure by A. B. Watson and D. G. Pelli](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.534.7583&rep=rep1&type=pdf) as implemented in Psychtoolbox. First, we set the coherence level while holding the number of all tone components (*Figure* + *Background*) constant. This is done by `SFGthresholdCoherence`:    
Threshold estimations for specific accuracy levels:
```
SFGthresholdCoherence(subNum);
```
Then we fix the coherence level at the result of the coherence-thresholding procedure and start adding background tones in a second Quest run aimed at the "hard" set of SFG stimuli:   
```
SFGthresholdBackground(subNum);
```

Based on the outcomes of the thresholding procedures we generate four types of participant-specific stimuli: (1) "Easy" trials with *Figure*; (2) "Easy" trials without *Figure*; (3) "Hard" trials with *Figure*; (4) "Hard" trials without *Figure*. 200-200 stimuli are generated for each type. Stimulus generation is handled by a function glueing together more basic steps:
```
stimulusGenerationGlueThresholded(subNum);
```

In the main part of the experiment, participants' task is the same as in training: yes-no detection task. We use the SFG stimuli generated in the previous step, sorting them into 10 blocks, with 80 trials in each block. Trials are ordered randomly. Unlike in training, there is no feedback at the end of the trials. We record EEG from this phase.
```
SFGmain(subNum);
```

## List of functions

See the `help` of each function for details.

Functions in `/stimulus` are used for stimulus generation: 
- **SFGparams.m** - Base SFG parameters for stimuli generation
- **createSFGstimuli.m** - Generates given number of stimuli for specific parameters
- **createSingleSFGstim.m** - Generates one stimulus for specific parameters
- **plotChords.m** - Diagnostic and visualization tool: plot the chords defining a given stimulus next to its spectrogram. To be used for stimuli generated with **createSFGstimuli.m**
- **plotChordsSingleStim.m** - Diagnostic and visualization tool: plot the chords defining a given stimulus next to its spectrogram. To be used for a stimulus generated with **createSingleSFGstim.m**
- **stimulusGenerationGlueTraining.m** - Glueing script generating the stimulus ensemble for the training phase  
- **stimulusGenerationGlueThresholded.m** - Glueing script generating the stimulus ensemble for the main part of the experiment, based on the outcomes of the thresholding functions
- **getStimuliArray.m** - Aggregates stimulus (sub)sets into full ensemble 
- **getEnDiff.m** - Diagnostic tool testing for acoustic energy differences between two stimuli (sub)sets
- **iso226.m** - ISO226 implementation with interpolation - returns the sound pressure level (SPL dB) of requested frequencies at the loudness level specified (phon). [From here.](https://github.com/IoSR-Surrey/MatlabToolbox/blob/master/%2Biosr/%2Bauditory/iso226.m) 

Functions in `/introduction` are used for quick tests and the introduction phase:
- **SFGparamsIntro.m** - Base SFG parameters specific to the introduction phase
- **SFGintro.m** - Experimental script for the introduction phase
- **SFGtesting.m** - Function to try out and test different parameters quickly, without any Psychtoolbox visuals.

Functions in `/training` are used for the training phase:
- **stim2blockTraining.m** - Helper function detecting unique stimulus types in a given SFG stimulus ensemble file and sorting them into blocks for the training phase.
- **SFGtraining.m** - Experimental script for the training phase

Functions in `/threshold` are used for deriving individual SFG parameter estimates before the main experimental phase:
- **SFGparamsThreshold.m** - Base SFG parameters specific to the thresholding (SFG parameter estimation) phase
- **SFGthresholdCoherence.m** - Experimental script running a Quest procedure estimating the SFG coherence level for given accuracy (85% in our case)
- **SFGthresholdBackground.m** - Experimental script running a Quest procedure estimating the SFG tone component number (and thus the no. of background tones) for given accuracy (65% in our case)

Functions in `/presentation` are used for the main experimental phase (stimulus presentation and recording responses):  
- **stim2blocks.m** - Helper function detecting unique stimulus types in a given SFG stimulus ensemble file and sorting them into the required number of blocks. Ensures that the same number of stimuli from each stimulus type is in each block (basic counterbalancing across blocks).
- **expParamsHandler.m** - Helper function for detecting existing parameters/settings and results for subjects in a multi-session experiment. Also handles loading and sorting of stimuli, saving subject-specific parameters, etc.
- **SFGmain.m** - Main experimental script responsible for stimulus presentation and recording responses. 

<br></br>
## Citation
Code is free to all (GNU Public license v2) but please cite the repo and earlier work by the group:

Tóth, Brigitta, Zsuzsanna Kocsis, Gábor P. Háden, Ágnes Szerafin, Barbara G. Shinn-Cunningham, and István Winkler. "EEG signatures accompanying auditory figure-ground segregation." Neuroimage 141 (2016): 108-119. https://doi.org/10.1016/j.neuroimage.2016.07.028

