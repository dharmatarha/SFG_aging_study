# SFG_aging_study
Code for an ongoing research project (*"Testing aging deficits in auditory object perception"*). SFG stands for Stochastic Figure-Ground, a stimulus type used in auditory research that combines sets of randomly selected tones from a broad frequency range (*Background*) with short sequences of repeated tones (*Figure*). The latter is regularly perceived as an auditory object, that is, as a sound source separate from the background. For more on the figure-ground stimuli please see (among others):

[Teki, Sundeep, Maria Chait, Sukhbinder Kumar, Katharina von Kriegstein, and Timothy D. Griffiths. "Brain bases for auditory stimulus-driven figure–ground segregation." Journal of Neuroscience 31, no. 1 (2011): 164-171.](https://www.jneurosci.org/content/jneuro/31/1/164.full.pdf)

[Teki, Sundeep, Maria Chait, Sukhbinder Kumar, Shihab Shamma, and Timothy D. Griffiths. "Segregation of complex acoustic scenes based on temporal coherence." Elife 2 (2013): e00699.](https://elifesciences.org/articles/00699.pdf)

[O'Sullivan, James A., Shihab A. Shamma, and Edmund C. Lalor. "Evidence for neural computations of temporal coherence in an auditory scene and their enhancement during active listening." Journal of Neuroscience 35, no. 18 (2015): 7256-7263.](https://www.jneurosci.org/content/jneuro/35/18/7256.full.pdf)

The study relies on [Psychtoolbox](https://psychtoolbox.org/) for stimulus generation/presentation and so related code is written in Matlab (developed with 2017a). Octave compatibility is not tested.

Functions in /stimulus are used for stimulus generation, functions in /presentation for stimulus presentation and recording responses. 

Code is free to all (MIT license) but please cite earlier work by the group:

Tóth, Brigitta, Zsuzsanna Kocsis, Gábor P. Háden, Ágnes Szerafin, Barbara G. Shinn-Cunningham, and István Winkler. "EEG signatures accompanying auditory figure-ground segregation." Neuroimage 141 (2016): 108-119. https://doi.org/10.1016/j.neuroimage.2016.07.028

