% preproc_0_config.m
% -----------------------------
% Config file in which personalized and/or fairly stable information (e.g.,
% input/output/figure directories, filtering specifications) can be stored
% in a separate location from the preprocessing code. Some variables and
% fields are declared as empty and are filled in during preprocessing. 
%
% INSTRUCTIONS FOR USE: 
% - Create your own version of the config file by adding an underscore and
%   your initials at the end of the filename. 
%       Example: preproc_0_config_AB.m
% - Git will ignore any config file with an underscore after the word
%   'config'. 
% - Fill in all the variables with your own directory info, etc. Variables
%   and fields which should be declared as empty at this stage are 
%   indicated as such. 
% - Any preprocessing *functions* that use this config file will accept
%   your config filename as an input. 
% - Be sure to update any preprocessing *scripts* that use a config file
%   with the name of your specific config file. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If using this software, please cite as follows: 
%
% Amilcar J. Malave, Philip A. Hernandez, and Blair Kaneshiro (2026). 
% SENSI-EEG-Preproc-CS: A MATLAB Preprocessing Pipeline for EEG Responses 
% to Continuous Stimuli. Stanford Digital Repository. 
% doi:10.25740/vg446hd3139 
% Available at: https://github.com/edneuro/SENSI-EEG-Preproc-CS

% This software is released under the MIT License, as follows: 
%
% Copyright (c) 2026 Amilcar J. Malave, Philip A. Hernandez, and 
% Blair Kaneshiro.
% 
% Permission is hereby granted, free of charge, to any person obtaining 
% a copy of this software and associated documentation files (the 
% "Software"), to deal in the Software without restriction, including 
% without limitation the rights to use, copy, modify, merge, publish, 
% distribute, sublicense, and/or sell copies of the Software, and to 
% permit persons to whom the Software is furnished to do so, subject to 
% the following conditions:
% 
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% Ensure repo files are in path %%%%%%%%%%%%%%%%%%%%

assert(~isempty(which('saveCurrentFigure')), ...
    'Make sure the preprocessing pipeline repo and sub-folders are added to Matlab path.')

%%%%%%%%%%%%%%%%%%%%%% Directories and STIMINFO %%%%%%%%%%%%%%%%%%%%%%%%%%

% All directories should be given as full paths

%%% High level

% Directory containing pipeline code
INFO.codeDir = '';

% Directory containing the config file
INFO.configDir = 'INFO.codeDir';

% Config file filename
INFO.configFn = 'preproc_0_config.m';

% Directory in which to store preprocessing figures
INFO.preprocFigDir = '';

% Directory in which to store preprocessing logs
INFO.preprocLogDir = '';

% Directory containing stimulus info
INFO.stimInfoDir = '';

% STIMINFO .mat filename
INFO.stimInfoFn = 'STIMINFO.mat';
INFO.STIMINFO = []; % Leave empty when initializing this file

% Directory containing .wav stimulus files 
INFO.wavDir = ''; % Optional

%%% Specific preprocessing stages

% Step 1 input data directory
INFO.matRawDir = ''; 

% Step 1 output data directory
INFO.matRawEpochedDir = '';

% Steps 2 and 3 output data directory
INFO.matICAReadyDir = '';

% Step 4 output data directory
INFO.matCleanDir = '';

% Step 5 output data directory
INFO.matAggregatedDir = '';

%%%%%%%%%%%%%%%%%%% Annotations (fill and/or init) %%%%%%%%%%%%%%%%%%%%%%%

% Struct fields in this section refer to specific file runs. If a given
% field is expected to change from run to run, it is left blank at this
% stage. Otherwise, a default value can be provided here and overwritten in
% a specific file run if needed. 

% Data of current data collection
INFO.anno.dataCollectionDate = ''; % Leave empty when initializing this file

% Experimenter name/initials
INFO.anno.experimenter = ''; % Leave empty when initializing this file

% Block id of the run
INFO.anno.stimArray = ''; % Leave empty when initializing this file

% EGI net size and/or id
INFO.anno.net = ''; % Leave empty when initializing this file

% Were impedances checked beforehand? 
INFO.anno.impedancesChecked = 'Y'; % User can overwrite in each run

% Was the participant wearing a mask? 
INFO.anno.participantWearingMask = 'N'; % User can overwrite in each run

%%%%%%%%%%%%%%%%%%%% File search and save strings %%%%%%%%%%%%%%%%%%%%%%%%

% Which block was looked at - placeholder, gets filled during cleaning
INFO.blkID = []; % Leave empty when initializing this file
INFO.blkStrUse = []; % Leave empty when initializing this file

% Other strings for searching and labelling
INFO.fSaveStr = 'WTISC_';               % For output files

% User-entered search string - will be entered in preproc 1
INFO.sStr = ''; % Leave empty when initializing this file   
INFO.fSearchStrUse = {}; % Leave empty when initializing this file

%%%%%%%%%%%%%%%%%%%%%%%%% Sampling rate info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Expected acquisition sampling rate - fs of each loaded file will be
% confirmed to equal this
INFO.fs_0 = 1000; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Impedances %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Impedances for specific recording(s)
INFO.nImpedanceRows = 130; % Number of rows in the impedance file - EGI 128-chan value is 130
INFO.impedances = [];  % Leave empty when initializing this file

%%%%%%%%%%%%%% Truncate very end of continuous recording %%%%%%%%%%%%%%%%%

% How many msec to truncate from end of each recording - set to 0 to ignore
INFO.truncateMsec = 100;  

% How many msec to visualize from end of each recording
INFO.visTruncateMsec = 100; 

%%%%%%%%%%%%%%%%%% Filtering and downsampling info %%%%%%%%%%%%%%%%%%%%%%%

INFO.FILTERING.hpHz = 0.3;              % Highpass cutoff, in Hz
INFO.FILTERING.notchHz = [59 61];       % Notch boundaries, in Hz
INFO.FILTERING.lpHz = 50;               % Lowpass cutoff, in Hz
INFO.FILTERING.filterSpecs = [];        % Filter specs returned by fn call - leave empty when initializing this file
INFO.FILTERING.DS = 4;                  % Downsampling factor
INFO.FILTERING.DSPhase = 0;             % Phase offset of downsampling

%%%%%%%%%%%%%%%%%%%%%%%%% Trigger info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Triggers of interest once parsed from "LNNN" format of TCP triggers
INFO.trigger.stim = [101:148 201:248 301:324 401:424 501:512 701:702]; % Triggers corresponding to stimuili
INFO.trigger.response = [1:9 11 12]; % Triggers corresponding to number/true/false keys

% Value that all DIN triggers will end up getting
INFO.trigger.inDIN = 2;         % Expected value of input DIN triggers (1=photodiode, 2=audio click)
INFO.trigger.outDIN = 8888;     % Output value of DIN triggers (use value not represented in TCP set to avoid overlap)

% Number of EEG time samples into trial that first timing click occurs
INFO.onset.dinSampOffset = 1000;       % SENSI: Typically 1000 samples (1000 msec) 

% Number of EEG time samples between timing clicks
INFO.onset.dinIOI = 1000; % SENSI: Typically 1000 samples (1000 msec)

%%%%%%%%%%%%%%%%%%%%%%%%%% Bad channel info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Placeholders
INFO.badCh = [];  % Leave empty when initializing this file
INFO.badChsRecs = []; % Leave empty when initializing this file

% Some Thresholds
INFO.badChs.chMax = 1000; % Channels with samples that reach this value will be declared as bad
INFO.badChs.neighborDissThresh = 0.3; % Channels w/ Neightbor Dissimilarity (time dependent)
                                      % >= to this value will be flagged

% Windowing Varaibles - For time dependent analyses
INFO.badChs.winSec = 10; % Time window (sec) - Max, Corr, and Var
INFO.badChs.hopSec = INFO.badChs.winSec; % Time skip per window (sec)

% Clustering variables
INFO.badChs.win_sec = 0.200; % Maxpool window in sec
INFO.badChs.eps = 0.8; % Distance Matrix Clustering Thresshold - Number between 0 and 1. 
                       % This defines the number of clusters during bad
                       % channel detection. Higher eps lead to fewer clusters

% UI Plot Settings
INFO.badChs.minClusterUI = 7; % If > #Chs in cluster. Plot cluster in UI figure (e.g cluster #ch = 4, plot cluster)  
INFO.badChs.alpha = .25;      % plot transparency. Original = .25
INFO.badChs.nCols = 2;        % number of columns. Original = 2
INFO.badChs.nRows = 3;        % number of rows
INFO.badChs.ref = 36;         % reference channel. Original = 36 for EGI

% Post-ICA data rejection (Rec or All)
INFO.badChRejectionThresh = 15; % Reject if MORE than this many channels are bad    

%%%%%%%%%%%%%%%%%%%%%%%% Default VEOG and HEOG %%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOG.chVEOG = [8 25]; % User can overwrite in each run
EOG.chHEOG = [1 32 125 128]; % User can overwrite in each run

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ICA params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

INFO.ICA.W = [];   % Leave empty when initializing this file
INFO.ICA.HiThresh = 0.30;   % High EOG corr threshold for automatic reject
INFO.ICA.LowThresh = 0.20;  % Low EOG corr threshold for manual inspection
INFO.ICA.HiReject = []; % Leave empty when initializing this file
INFO.ICA.LowReject = []; % Leave empty when initializing this file
INFO.ICA.EkgSrc = []; % Leave empty when initializing this file
INFO.ICA.DinSrc = []; % Leave empty when initializing this file
INFO.ICA.OtherSrc = []; % Leave empty when initializing this file
INFO.ICA.RmSrc = []; % Leave empty when initializing this file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Post-ICA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

INFO.PostICAPath = []; % Leave empty when initializing this file

% DIN (Digital Input) Parameters
% Can edit
INFO.PostICA.dinOpts.T = 1;     % Din repetition period in seconds. Default: 1 sec
INFO.PostICA.dinOpts.fmin = 10; % Minimum frequency for detection (Hz)
INFO.PostICA.dinOpts.fmax = 50; % Maximum frequency for detection (Hz)

% EKG (Cardiac) Parameters (default values already loaded)
% Can edit
INFO.PostICA.ekgOpts.fmin = .8;             % Lower bound of cardiac rhythm band (Hz)
INFO.PostICA.ekgOpts.fmax = 2;              % Upper bound of cardiac rhythm band (Hz)
INFO.PostICA.ekgOpts.harmonics = 4;         % Number of harmonics to include in spectral test
% INFO.PostICA.ekgOpts.peakHalfHz  = 0.20;    % half-width of peak window around each harmonic (Hz)
% INFO.PostICA.ekgOpts.nbHalfHz    = 0.60;    % half-width of neighbor ring around each harmonic (Hz)
% INFO.PostICA.ekgOpts.time        = 14;      % Welch window length (sec)

%%%%%%%%%%%%%%%%%%%% Voltage magnitude thresholds %%%%%%%%%%%%%%%%%%%%%%%%

INFO.recPctThresh = 10; % "THIS percent or more of voltage magnitudes (≥) ...
INFO.recUVThresh = 50;  % ... being (strictly) greater than THIS (>)."
INFO.recPctOverUVThresh = []; % Leave empty when initializing this file

%%%%%% Percent of data replaced by NaNs in nanBadSamples iterations %%%%%%

INFO.pctNBS = [];   % Leave empty when initializing this file

%%%%%%%%%%%%% Historical record of original and final table %%%%%%%%%%%%%
INFO.T_original = []; % Leave empty when initializing this file
INFO.T_final = []; % Leave empty when initializing this file

%%%%%%%%%%%%%% Files loaded; files saved; run datetime %%%%%%%%%%%%%%%%

% This section initializes struct fields that will be filled in with
% information specific to a given trial run at the end of the respective
% preprocessing step. 

% preproc_1a_loadFilterEpochOneFile.m: One or more files in, one file out
INFO.preproc1_MR_fNamesLoaded = {}; % Leave empty when initializing this file
INFO.preproc1_MR_nFilesLoaded = []; % Leave empty when initializing this file
INFO.preproc1_MRE_fNameSaved = []; % Leave empty when initializing this file
INFO.preproc1_analyzer = []; % Leave empty when initializing this file
INFO.preproc1_datetime = []; % Leave empty when initializing this file

% preproc_2_preICA.m: One file in, one file out
INFO.preproc2_MRE_fNameLoaded = {}; % Leave empty when initializing this file
INFO.preproc2_MIR_fNameSaved = {}; % Leave empty when initializing this file
INFO.preproc2_analyzer = []; % Leave empty when initializing this file
INFO.preproc2_datetime = []; % Leave empty when initializing this file

% preproc_4_postICA.m: Two files in, one file out
INFO.preproc4_MIR_fNameLoaded = []; % Leave empty when initializing this file
INFO.preproc4_W_fNameLoaded = []; % Leave empty when initializing this file
INFO.preproc4_MC_fNameSaved = []; % Leave empty when initializing this file
INFO.preproc4_analyzer = []; % Leave empty when initializing this file
INFO.preproc4_datetime = []; % Leave empty when initializing this file
