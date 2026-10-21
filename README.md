# SENSI-EEG-Preproc-CS: A MATLAB Preprocessing Pipeline for EEG Responses to Continuous Stimuli
SENSI-EEG-Preproc-CS is a preprocessing pipeline, written in MATLAB, to handle electroencephalography (EEG) responses to continuous stimuli. The pipeline comprises five main steps: (1) Data loading, filtering, and epoching; (2) specification of bad channels and electrooculogram (EOG) channels; (3) Independent Components Analysis (ICA); (4) identification of artifactual Independent Components and final data-rejection, imputation, and referencing; and (5) aggregation of cleaned data records on a per-stimulus basis. The codebase is self-contained, and code files contain documentation throughout. Future releases may include a User Manual and structured illustrative analyses.

## Information about the pipeline
The SENSI-EEG-Preproc-CS pipeline was created by [Amilcar J. Malave](https://scholar.google.com/citations?user=5qu3R50AAAAJ&hl=en&oi=sra), [Philip A. Hernandez](https://edneuroinitiative.stanford.edu/people/philip-hernandez), and [Blair Kaneshiro](https://ccrma.stanford.edu/~blairbo/) as part of their work with the [Stanford Educational Neuroscience Initiative (SENSI)](https://edneuroinitiative.stanford.edu/). 

Please contact amilcar.malave1997@gmail.com or blairbo@stanford.edu with any questions or bug reports. 

## Intended usage

This pipeline is designed for researchers collecting EEG with continuous stimuli paradigms. It emphasizes a semi-automated, human-in-the-loop workflow: automated algorithms surface candidates for review, and the researcher makes final decisions through interactive UIs before data proceed to the next step. Steps 2 and 4 are interactive and need the MATLAB desktop; Steps 1, 3 and 5 can run unattended. 

## Repository structure

* **preproc_0_config.m** — Configuration file where users specify directories, filtering parameters, trigger info, and other pipeline settings. Copy it to `preproc_0_config_<initials>.m` (git ignores that pattern).

1. **preproc_1_loadFilterEpoch.m** — Loads raw .mat EEG files, applies highpass, notch, and lowpass filtering, extracts triggers and trial onsets, and epochs the data. *Output: MatRawEpoched.*
2. **preproc_2_specifyBadChEOG.m** — Runs semi-automated bad-channel detection with an interactive review UI and specifies EOG channels. *Output: MatICAReady.*
3. **preproc_3_batchICA.m** — Runs ICA (bundled `runica.m`) on all MatICAReady files in batch. *Output: one unmixing matrix `W` per file.*
4. **preproc_4_postICA.m** — Identifies artifactual ICA components with interactive review: EOG components (high/low-reject review by correlation with the EOG channels), automated DIN (trigger) and EKG detectors with review UIs, and an "other" artifact review. Then removes the components, rejects bad samples, imputes missing data, and re-references. *Output: MatClean.*
5. **preproc_5_aggregateData.m** — Aggregates cleaned data across participants on a per-stimulus basis. Long NaN gaps are filled by an autoregressive forecast; a trial that cannot be filled is dropped and reported (`[DROPPED]` in the log, `INFO.preproc5_droppedTrials`). *Output: one .mat file per stimulus.*

* **/Utils.** — Helper functions, EGI montage files and the STIMINFO builder. Add it and all subfolders to the MATLAB path.

## Dependencies

The software was tested on MATLAB R2024b. The toolbox may work with earlier versions of MATLAB, but has not been fully tested on previous versions.

The software requires two MATLAB toolboxes: the Signal Processing Toolbox and the Statistics and Machine Learning Toolbox.

#### Third-party code

> The following bundled files originate from EEGLAB (Delorme & Makeig, 2004) and keep their original GNU General Public License (version 2 or later), as stated in their headers: `Utils/HelperFunctions/runica.m`, `topoplotStandalone.m`, `postICAartifacts/topoplot_new.m`, `postICAartifacts/chanlocsFromFile.m`.

> Delorme, A., & Makeig, S. (2004). EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics including independent component analysis. *Journal of Neuroscience Methods, 134*(1), 9–21.

## Input data

- Raw recordings as MATLAB `.mat` files, one per recording, each containing the EEG matrix (129 rows: 128 electrodes plus the reference), `EEGSamplingRate`, `evt_DIN2` (DIN triggers) and `evt_ECI_TCPIP_55513` (TCP/IP triggers). `Impedances_EEG_0` is optional: if it is absent, impedances are recorded as NaN.
- Trigger conventions as set in the config (`INFO.trigger.*`): stimulus and response codes parsed from "LNNN" TCP triggers, and DIN triggers marking stimulus onsets.
- A STIMINFO table describing the stimuli (`Utils/StimInfo/STIMINFO_createStimTableFromXlsx.m`).

#### Net layout

> The step scripts are written for the EGI HydroCel GSN 128-channel net. `Utils/HelperFunctions/EGIMontages/` includes montage and neighbour files for other EGI nets (64, 124–129, 194/195, 212/213 and 256/257 channels; electrode-location files for GSN 124 and 128). Using another net requires changing the channel ranges, EOG channels and reference channel in Steps 2 and 4 to match.

## Outputs and logs

Each step writes a `.mat` file and (when `saveFigs` is on) figures. With `saveLog` on, Steps 1, 4 and 5 also write a console log: `<name>_00_MatRawLog.txt` (Step 1, in `INFO.preprocLogDir`), `<name>_09_FinalStepsLog.txt` (Step 4's final cleaning block, in `INFO.preprocFigDir`) and `AggregateDataLog_<datetime>.txt` (Step 5, in its output folder). The logs hold values that are not saved elsewhere — trigger drift and onset lags, percent of data rejected, and dropped trials — and are meant for the analyst's write-up.

## Getting started

1. Download or clone this repository.
2. Open MATLAB and add the repository and all subfolders to your MATLAB path.
3. Create a personal copy of the config file by copying `preproc_0_config.m` and appending an underscore and your initials to the filename (e.g., `preproc_0_config_AB.m`). Git will ignore any config file with this naming pattern.
4. Fill in the directory paths and parameters in your personal config file following the instructions at the top of that file.
5. Run the five preprocessing steps in order, following the instructions at the top of each script file.

## Known limitations

- ICA results are not reproducible run to run: `runica.m` seeds its random number generator from the clock. Re-running Step 3 on a file gives a different `W`, so keep the `W` files that a Step 4 review was done against.
- Re-running Step 3 recomputes every file, including those that already have a `W`.

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