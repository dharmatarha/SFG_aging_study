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
The study relies on [Psychtoolbox 3.0.16](https://psychtoolbox.org/) under Ubuntu 18.04 for stimulus generation/presentation. While Psychtoolbox is compatible with Octave, code development is for Matlab (2017a) with Octave compatibility not tested. In principle though, adapting the functions to Octave should be simple. 

Stimulus presentation settings / parameters are specified for the Mordor lab at RCNS, Budapest. We rely on a two-X-screens setup (two independent displays): one for stimulus presentation, one for control. Subject responses are recorded via standard keyboards. For EEG, TTL-logic level triggers are supported via the great [ppdev-mex interface by Andreas Widmann](https://github.com/widmann/ppdev-mex). Optional loudness curve correction in stimulus generation (using the filter coefficients stored in OEM_iir_51_fs44100.mat) is based on [HUTear Matlab toolbox v2 by Aki Härmä and Kalle Palomäki](http://legacy.spa.aalto.fi/software/HUTear/HUTear.html). 
<br></br>
## How to start
Just include the subfolders in your path. For stimulus presentation functions make sure (1) you have a working Psychtoolbox setup, preferably under Linux; and (2) that all Screen, PsychPortAudio, etc. settings in the relevant functions are matched to your setup.<br></br>  
#### (1) Check out SFG stimuli 
Take a look at a stimulus first. Define a stimulus options struct by calling SFGparams.m: 
```
stimopt = SFGparams;
```
Type `help SFGparams` for the meaning of each field. Change any field value you want then call
```
[soundOutput, allFigFreqs, allBackgrFreqs] = createSingleSFGstim(stimopt);  % see the help for loudness correction (OEMfiltering) option
```
The matrix `soundOutput` holds the raw audio of the stimulus, play it with any method you prefer (e.g. quick check with `sound(soundOutput, stimopt.sampleFreq)`. To check if the generated audio reflects the stimulus options, run the plotting function plotChordsSingleStim:
```
fig = plotChordsSingleStim(soundOutput, stimopt, allFigFreqs, allBackgrFreqs);
```
If all is well, the right side of the plotted figure (spectrogram of audio) matches the left side (chord components the stimulus should be built from).<br></br>
You can also play around with the main stimulus options in an interactive playback loop using SFGtesting:
```
SFGtesting(false);  % see the help for OEMfiltering and base stimulus options
```

#### (2) Generate stimuli in batches
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

