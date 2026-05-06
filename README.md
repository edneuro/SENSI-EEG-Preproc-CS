# SENSI-EEG-Preproc-CS: A MATLAB Preprocessing Pipeline for EEG Responses to Continuous Stimuli
SENSI-EEG-Preproc-CS is a preprocessing pipeline, written in MATLAB, to handle electroencephalography (EEG) responses to continuous stimuli. The pipeline comprises five main steps: (1) Data loading, filtering, and epoching; (2) specification of bad channels and electrooculogram (EOG) channels; (3) Independent Components Analysis (ICA); (4) identification of artifactual Independent Components and final data-rejection, imputation, and referencing; and (5) aggregation of cleaned data records on a per-stimulus basis. The codebase is self-contained, and code files contain documentation throughout. Future releases may include a User Manual and structured illustrative analyses.

## Information about the pipeline
The SENSI-EEG-Preproc-CS pipeline was created by [Amilcar J. Malave](https://scholar.google.com/citations?user=5qu3R50AAAAJ&hl=en&oi=sra), [Philip A. Hernandez](https://edneuroinitiative.stanford.edu/people/philip-hernandez), and [Blair Kaneshiro](https://ccrma.stanford.edu/~blairbo/) as part of their work with the [Stanford Educational Neuroscience Initiative (SENSI)](https://edneuroinitiative.stanford.edu/). 

Please contact amilcar.malave1997@gmail.com or blairbo@stanford.edu with any questions or bug reports. 

## Repository structure

1. **preproc_1_loadFilterEpoch.m** — Loads raw .mat EEG files, applies highpass, notch, and lowpass filtering, extracts triggers and trial onsets, and epochs the data. *Output: MatRawEpoched .mat file.*
2. **preproc_2_specifyBadChEOG.m** — Runs semi-automated bad-channel detection with an interactive review UI and specifies EOG channels. *Input: MatRawEpoched. Output: MatICAReady .mat file.*
3. **preproc_3_batchICA.m** — Runs ICA on all MatICAReady files in batch using the bundled `runica.m` function. *Output: W matrix .mat file per recording.*
4. **preproc_4_postICA.m** — Identifies artifactual ICA components (EOG, EKG, DIN), applies component rejection, data imputation, and re-referencing. *Input: MatICAReady + W files. Output: MatClean .mat file.*
5. **preproc_5_aggregateData.m** — Aggregates cleaned data across participants on a per-stimulus basis. *Input: MatClean files. Output: one .mat file per stimulus.*

* **/Utils.** Helper functions and utilities used throughout the pipeline. This folder and its subfolders must be added to the MATLAB path before use.

## Dependencies

The software was tested on MATLAB R2024b. The toolbox may work with earlier versions of MATLAB, but has not been fully tested on previous versions.

The software requires two MATLAB toolboxes: the Signal Processing Toolbox and the Statistics and Machine Learning Toolbox.

The `runica.m` function (used in Step 3) is bundled in `Utils/HelperFunctions/` and originates from EEGLAB (Delorme & Makeig, 2004).

## Getting started

1. Download or clone this repository.
2. Open MATLAB and add the repository and all subfolders to your MATLAB path.
3. Create a personal copy of the config file by copying `preproc_0_config.m` and appending an underscore and your initials to the filename (e.g., `preproc_0_config_AB.m`). Git will ignore any config file with this naming pattern.
4. Fill in the directory paths and parameters in your personal config file following the instructions at the top of that file.
5. Run the five preprocessing steps in order, following the instructions at the top of each script file.

## Citing the pipeline
If using any materials from this pipeline, please cite it as follows: 

*Amilcar J. Malave, Philip A. Hernandez, and Blair Kaneshiro (2026). SENSI-EEG-Preproc-CS: A MATLAB Preprocessing Pipeline for EEG Responses to Continuous Stimuli. Stanford Digital Repository. doi:10.25740/vg446hd3139 Available at: https://github.com/edneuro/SENSI-EEG-Preproc-CS*

## Conditions of use

This software is released under the MIT License, as follows: 

Copyright (c) 2026 Amilcar J. Malave, Philip A. Hernandez, and
Blair Kaneshiro.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.