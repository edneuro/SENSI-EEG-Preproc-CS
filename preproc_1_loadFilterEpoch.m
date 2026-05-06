% preproc_1_loadFilterEpoch.m
% -----------------------------------
% This script captures file loading / session specifications and performs
% automated file indexing/loading as well as filtering and epoching of one
% or more input data files.
% - The script can accommodate single or multiple recordings with SENSI
%   ISC triggering conventions.
% - Works in conjunction with the user-customized config file.
% - Filtering, trigger/onset extraction, and epoching are performed on a
%   per-recording basis and aggregated across recordings.
% - Trial epoching information and behavioral responses are stored in a
%   centralized table, T.
% - Specifications and nonessential variables are consolidated in the INFO
%   struct.
%
% Outputs: 
% - The script writes out a MatRawEpoched (MRE) .mat file containing the
%   following variables: fs, INFO, Onsets, T, Triggers, xAll_129. 
% - The user can also choose to save out a journal, which details the
%   following in a .txt file: Session information, input .mat filenames,
%   filtering specifications, triggers and onsets. 

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

%% Set current run specifications, index files, print info about run

%%% Code block 1 of 2: Instructions
% 1 - Ensure items in 'one-time specifications' and 'per-run 
%     user-specified fields' sections are up to date.
% 2 - Run the code block.
% 3 - Confirm that command window output is as expected.

clear all; close all; clc

disp('~ * ~ * Initiating ISC data cleaning (1 - MatRaw) * ~ * ~')

%%%%%%%%%%%%%%%%%%% Begin one-time specifications %%%%%%%%%%%%%%%%%%%%%%%%

% User should only need to specify items in this section once. 

%%% Specify config filename
% It is the responsibility of the user to ensure that the config file is 
% in the path.
configFn = 'preproc_0_config.m';
run(configFn);
INFO.configFn = configFn; clear configFn

%%% Specify analyzer's initials
INFO.preproc1_analyzer = 'XX';

%%%%%%%%%%%%%%%%%%%%% End one-time specifications %%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%% Begin per-run user-specified fields %%%%%%%%%%%%%%%%%%%

% User specifies items in this section for every file set. 

%%% Participant identifier
% When to specify: Always
INFO.sStr = 'ENI_191'; % Include leading letter string. E.g., 'ENI_001'

%%% Block identifier
% When to specify: Always specify, even if customizing file indexing 
%    strings in next lines. 
% Current experiment assignments:
%   - blk1234: 1
%   - blk5678: 2
%   -    blk9: 3
INFO.blkID = 1;

%%% File indexing strings override
% When to specify: Specify block-specific strings if block numbers (e.g., 
%   'B01') are not included in filenames of Net Station .mat exports.
%   Otherwise, leave this part commented out. 
% Examples:
% INFO.fSearchStrUse = {'M1', 'FB', 'AS1', 'ANS1'};
% INFO.fSearchStrUse = {'MU'};

%%% Annotations for current file set - copy from big table
% When to specify: Always
INFO.anno.dataCollectionDate = '2022-12-16'; % 'YYYY-MM-DD'
INFO.anno.experimenter = 'MB,PH';            % Experimenter's(s') initials
INFO.anno.stimArray = 'P009';                % E.g., 'P035'
INFO.anno.net = 'M:S-000036';                % Net size:id as available

%%% [Annotations that probably don't need to be edited] %%%
% When to specify: Specify only if you need to override a default value.
%   Otherwise, leave this part commented out.
% INFO.anno.impedancesChecked = '?';      % Default Y; can change to N/? here
% INFO.anno.participantWearingMask = 'Y'; % Default N; can change to Y/? here

%%% Whether to save figures/journal in current run
% When to specify: Always
saveFigs = 1;
saveLog = 1;

%%%%%%%%%%%%%%%%%%% End per-run user-specified fields %%%%%%%%%%%%%%%%%%%%

%%% Block search string and output file labelling specifications. 
% This information is provided here and not in the config file since it 
% could change depending on the experiment. 

% To search input filenames (WT Session 1)
tempFSearchStr{1} = {'B01', 'B02', 'B03', 'B04'};   % Blocks 1--4
tempFSearchStr{2} = {'B05', 'B06', 'B07', 'B08'};   % Blocks 5--8
tempFSearchStr{3} = {'B09'};           % Block 9

% For labelling output filenames (WT Session 1) 
tempBlkStr{1} = 'b1234';   
tempBlkStr{2} = 'b5678';
tempBlkStr{3} = 'b9';

%%% Load STIMINFO table. We'll use the following columns:
% (1) trigger, (3) wavFs, (4) wavLenSamp, (7) blocktype {'FB'}.
% We specify 'STIMINFO' variable only to avoid overwriting main INFO.
load([INFO.stimInfoDir filesep INFO.stimInfoFn], 'STIMINFO')

%%% Retrieve filenames for current run

% If user did ~not~ override INFO.fSearchStrUse above, search using the
% block number specified by INFO.blkID. If the user ~did~ override, their
% override will be retained. 
if isempty(INFO.fSearchStrUse)
    INFO.fSearchStrUse = tempFSearchStr{INFO.blkID};
end

% Retrieve the filenames
[fNamesMatRaw, ~] = indexISCFilenames(...
    INFO.matRawDir, [INFO.sStr], INFO.fSearchStrUse);

% Save out output block specifier string, e.g., 'b1234'
INFO.blkStrUse = tempBlkStr{INFO.blkID};

%%%%%%%%%%%%%%%%%%%%  Custom version if needed %%%%%%%%%%%%%%%%%%%%%%%%%%%
% tempFList = dir([INFO.matRawDir filesep INFO.sStr '*.mat']);
% fNamesMatRaw = {tempFList.name};

% [Optional] Manually reorder filenames here if needed
% fNamesMatRaw = fNamesMatRaw([4 3 2 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute number of files and confirm at least 1 file was indexed
nFilesMatRaw = length(fNamesMatRaw);
assert(nFilesMatRaw > 0, 'No files were indexed! Check indexing parameters.')

% Start the output log if specified
diary off
if saveLog
    tempLogFnOut = [INFO.preprocLogDir filesep INFO.fSaveStr INFO.sStr ...
        '_' INFO.blkStrUse '_00_MatRawLog.txt'];
    warning('off', 'MATLAB:DELETE:FileNotFound') % Turn off warning 
    delete(tempLogFnOut)    % Delete existing logfile, if it exists
    warning('on', 'MATLAB:DELETE:FileNotFound')  % Turn warning back on
    diary(tempLogFnOut)     % Initalize the current logfile
end

disp([newline 'Session information' ...
    newline '- Participant number: ' INFO.sStr ...
    newline '- Stim array: ' INFO.anno.stimArray ...
    newline '- Data collection date: ' INFO.anno.dataCollectionDate ...
    newline '- Experimenter initials: ' INFO.anno.experimenter ...
    newline '- Net: ' INFO.anno.net ...
    newline '- Impedances: ' INFO.anno.impedancesChecked ...
    newline '- Participant wearing mask: ' INFO.anno.participantWearingMask])

disp([newline 'MatRaw analyzer initials: ' INFO.preproc1_analyzer])

disp([newline 'Input filenames (ordered list):'])
fprintf('%s \n', fNamesMatRaw{:});
disp([newline 'Output filename (MatRawEpoched): ' ...
    INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse '.mat'])

disp([newline 'Filtering specifications' ...
    newline '- Highpass: ' num2str(INFO.FILTERING.hpHz) ' Hz' ...
    newline '- Notch: ' mat2str(INFO.FILTERING.notchHz) ' Hz' ...
    newline '- Lowpass (Chebyshev I): ' num2str(INFO.FILTERING.lpHz) ' Hz' ...
    newline '- Downsampling factor: ' num2str(INFO.FILTERING.DS) ...
    '; phase offset: ' num2str(INFO.FILTERING.DSPhase) ' samples' ...
    newline '- Analysis sampling rate (fs): ' num2str(INFO.fs_0/INFO.FILTERING.DS)])

clear temp*

disp([newline '\ * \ Code section complete (no figures) / * /'])

%% Perform all loading, filtering, epoching, and saving steps

%%% Code block 2 of 2: Instructions
% 1 - Run the code block.

%%% Visualize and optionally save recording endings of all indexed files at once

close all

% Before going to per-file processing, we iterate through the files and
% visualize the DC-corrected data to confirm the ending artifact is there
% with expected timing.

% Call the 'visualizeRecordingEndings' function from the BKan repo. Inputs
% are (1) var idx str, (2) inDir, (3) fNames, 
% (4) doDCCorrection, (5) nMsec, (6) fs, (7) sg title custom str, 
% (8) fSize (default 12), (9) figVisibility

thisVisStr = [INFO.sStr];
visualizeRecordingEndings(thisVisStr, INFO.matRawDir, fNamesMatRaw, ...
    0, 100, 1000, [thisVisStr '_' INFO.blkStrUse], ...
    [], 'off');

clear this*

%%% [optional] Save the figure

if saveFigs

    % Make the output filename.
    thisFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
        '_01_recordingEndings.png'];

    % Specify save size width and height (will depend on number of files)
    thisFigSize = [10 6];

    % Call the 'saveCurrentFigure' function from the BKan repo. Inputs are
    % (1) output path, (2) output filename w/ extension, (3) figure save size
    % [width height], (4) figure handle (default gcf) (5) whether to print
    % message at the end (default true).
    saveCurrentFigure(INFO.preprocFigDir, thisFnOut, thisFigSize);

    clear this*

end

%%% Perform per-recording processing steps and propagate main table

close all

%%% Initialize current main variables

% Initialize across-recordings concat data
xAll_129 = [];

% Initialize table to store information. Columns:
% (1) RowN: Trial number (double)
% (2) FileN: Recording/file number (double)
% (3) TrialN: Trial number in recording/file (double)
% (4) Block: Block type (e.g., FB; categorical)
% (5) Trigger: Trigger (double)
% (6) SampLen: Trial length in samples (double)
% (7) SampStart: Trial starting sample (concat data; double)
% (8) SampEnd: Trial ending sample (concat data; double)
% (9) Behav: Behavioral responses, if any (cell)
T = table('Size', [0 9], 'VariableTypes', ...
    {'double', 'double', 'double', 'categorical', 'double', 'double', 'double', 'double', 'cell'});
T.Properties.VariableNames = {'RowN', 'FileN', 'TrialN', 'Block', 'Trigger', ...
    'SampLen', 'SampStart', 'SampEnd', 'Behav'};
tCounter = 1; % Row counter for the table

%%% Process individual files
% This section includes load the file; move loaded variables into variables
% with stable names; filter and downsample; parse DIN/TCP triggers and
% onsets; compute corrected trial onset times; epoch EEG and aggregate in
% single concat matrix (across files); add each trial info to main table.

for i = 1:nFilesMatRaw

    thisFnIn = fNamesMatRaw{i};

    disp([newline '~* Processing file ' num2str(i) ' of ' num2str(nFilesMatRaw) ...
        ': ' thisFnIn ' ~*'])

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%% Load the current data %%%%%%%%%%%%%%%%%%%%%%%

    %%% This section could be converted to a function in a future release.

    THIS = load([INFO.matRawDir filesep thisFnIn]);

    % ENI_133_M1_B01_20230525_034648mff: [129×297569 single]
    %               EEGSamplingRate: 1000
    %              Impedances_EEG_0: [130×1 double]
    %                      evt_DIN2: {4×133 cell}
    %           evt_ECI_TCPIP_55513: {4×84 cell}

    %%% Variable 1: Get current data, convert to double --> thisXIn

    % Here are all the field names
    thisFieldNames = fieldnames(THIS);

    % Logical to specify which field number contains particip id --> data
    thisFieldIdx = contains(thisFieldNames, [INFO.sStr]);

    % Move data to consistently named variable and convert to double
    thisXIn = double(THIS.(thisFieldNames{thisFieldIdx}));

    %%% Variable 2: Confirm loaded fs matches prespecified fs.
    assert(isequal(INFO.fs_0, THIS.EEGSamplingRate), ...
        'Sampling rate of loaded data does not match prespecified sampling rate!')

    %%% Variable 3: Aggregate impedances in matrix

    % Save out impedances if they are included in the loaded recording.
    % Impedances are stored in a [130 x nFiles] matrix. Note that multiple 
    % files may have identical impedances. If the current file does not
    % have impedances, a column of NaNs will be saved instead. 
    if isfield(THIS, 'Impedances_EEG_0')
        INFO.impedances(:, i) = THIS.Impedances_EEG_0;
    else
        INFO.impedances(:, i) = nan(INFO.nImpedanceRows,1);
    end

    %%% Variables 4, 5: For now move DIN and TCPIP in temp variables. Will
    %%% parse them more in a future section.
    thisDIN = THIS.evt_DIN2;
    thisTCPIP = THIS.evt_ECI_TCPIP_55513;

    %%% Get rid of the input variable
    clear THIS
    disp(['Loaded ' thisFnIn '.'])
    %%%%%%%%%%%%%%%%%%%%%%%% Data loading complete %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% New! Truncate end of recording %%%%%%%%%%%%%%%%%%%%

    % Just truncating here, we already created and saved the plots.

    thisTruncateSamp = INFO.truncateMsec * INFO.fs_0 / 1000;
    assert(floor(thisTruncateSamp) == thisTruncateSamp, ...
        'Specified truncation must be integer number of time samples.')

    thisXTruncated = thisXIn(:, 1:(end-thisTruncateSamp));

    %%%%%%%%%%%%%%%%%%%%%%%% Truncation complete %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% Filter and downsample the data %%%%%%%%%%%%%%%%%%%%

    % Call the filter-only function in the BKan repo. Inputs are
    % (1) xIn, (2) fs, (3) hpHz, 
    % (4) nHz, (5) lpHz, (6) doPlots, (7) figVisibility
    % Figure 200 is time domain; Figure 201 is frequency domain
    [thisXFiltered, INFO.FILTERING.filterSpecs, tH, fH, tfH] = ...
        doTrioFilterNoDS(thisXTruncated, INFO.fs_0, INFO.FILTERING.hpHz, ...
        INFO.FILTERING.notchHz, INFO.FILTERING.lpHz, 1, 'off');

    % Save the figures if requested - rare per-recording figures
        
    if saveFigs

        disp(' ')

        
         % Combined Time-domain and Frequency-domain figure
        set(0,'CurrentFigure',tfH)
        thatFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
            '_02_trioFilter_time_and_freq_Domain_rec' num2str(i) '.png'];
        sgtitle({thatFnOut,""},'interpreter', 'none') % Title is 2 lines to avoid overlap
        thatFnSize = [10 20];
        saveCurrentFigure(INFO.preprocFigDir, thatFnOut, thatFnSize);
        img1 = imread(thatFnOut);
        clear that*
        
      %%%%%%%%%%%%%%%%%%%%%%%%%%  Optional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   If seperate time-domain and frequency-domain figures are desired,
%   then uncomment sections below
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
        
%         % Time-domain figure
%         set(0,'CurrentFigure',tH)
%         thatFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
%             '_02a_trioFilter_timeDomain_rec' num2str(i) '.png'];
%         sgtitle({thatFnOut,""}, 'interpreter', 'none') % Title is 2 lines to avoid overlap
%         thatFnSize = [10 10];
%         saveCurrentFigure(INFO.preprocFigDir, thatFnOut, thatFnSize);
%         clear that*
% 
%         % Frequency-domain figure
%         set(0,'CurrentFigure',fH)
%         thatFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
%             '_02b_trioFilter_freqDomain_rec' num2str(i) '.png'];
%         sgtitle({thatFnOut,""}, 'interpreter', 'none') % Title is 2 lines to avoid overlap
%         thatFnSize = [10 10];
%         saveCurrentFigure(INFO.preprocFigDir, thatFnOut, thatFnSize);
%         clear that*

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    else
        disp(['\ * \ No figures saved / * /'])
    end

    close all

    % Downsample the data - doing after saving filtering figures to keep
    % time/frequency axes the same pre- and post-filtering.
    % The 'downsample' function will operate on each column of a matrix.
    thisXFiltDS = downsample(thisXFiltered', ...
        INFO.FILTERING.DS, INFO.FILTERING.DSPhase)';
    disp([newline 'Data downsampled by a factor of ' num2str(INFO.FILTERING.DS) ...
        ' with a phase offset of ' num2str(INFO.FILTERING.DSPhase) '.'])

    % Compute the analysis sampling rate
    fs = INFO.fs_0 / INFO.FILTERING.DS;
    disp(['Analysis sampling rate: ' num2str(fs) ' Hz.'])

    %%%%%%%%%%%%%%%% Filtering and downsampling complete %%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% Parse DIN and TCP Triggers and Onsets %%%%%%%%%%%%%%%%%

    %%% This section could be converted to a function in a future release.

    % This section might need to be customized on a per-study basis in the
    % future (e.g., if the DINs or TCPs have different LNNN formats. If
    % this is necessary, try to load customizations and special cases into
    % config file as much as possible.
    % thisDIN = THIS.evt_DIN2;
    % thisTCPIP = THIS.evt_ECI_TCPIP_55513;

    %%%% Extract, combine, and sort triggers and onsets

    %%% DIN triggers and onsets
    % Extract triggers and onsets
    [thisTempTriggers, thisTempOnsets] = parseDIN_col(thisDIN);

    % Confirm that all DIN triggers equal the expected value
    assert(all(thisTempTriggers == INFO.trigger.inDIN, 'all'), ...
        ['Not all DIN triggers are equal to ' num2str(INFO.trigger.inDIN)])

    % Convert DIN triggers for use to another value to avoid overlap with
    % TCP trigger values
    Triggers(i).din = INFO.trigger.outDIN * ones(size(thisTempTriggers));

    % Also store out the current DIN onsets at original sampling rate
    Onsets(i).dinOrigFs = thisTempOnsets;

    % Clear temp and optionally display
    clear thisTemp*
    % disp('Input DIN triggers and onsets (all)')
    % [Triggers(i).din Onsets(i).dinOrigFs]

    %%% TCP triggers and onsets
    % Extract triggers and onsets: LNNN trigger format, e.g., 'S701'
    [thisTempTriggers, thisTempOnsets] = parseTCP_LNNN(thisTCPIP);

    % Store out triggers and (orig samp rate) onsets
    Triggers(i).tcp = thisTempTriggers;
    Onsets(i).tcpOrigFs = thisTempOnsets;

    % Clear temp and optionally display
    clear thisTemp*
    % disp('Input TCP triggers and onsets (all)')
    % [Triggers(i).tcp Onsets(i).tcpOrigFs]

    %%% Combine and sort DIN and TCP triggers and onsets
    % Stack DIN and TCP triggers
    thisTempTriggers = [Triggers(i).din; Triggers(i).tcp];

    % Stack DIN and TCP onsets
    thisTempOnsets = [Onsets(i).dinOrigFs; Onsets(i).tcpOrigFs];

    % Sort stacked onsets and also get sorting index
    [thisTempSortedOnsets, thisTempIdx] = sort(thisTempOnsets);

    % Apply sorting index to the stacked triggers
    thisTempSortedTriggers = thisTempTriggers(thisTempIdx);

    % Here are the sorted triggers and onsets
    Triggers(i).all = thisTempSortedTriggers;
    Onsets(i).allOrigFs = thisTempSortedOnsets;

    % Show table of drifts
    disp('Drift based on DINs')
    [drifts_din] = checkDinIOI(thisTempSortedTriggers, thisTempSortedOnsets, INFO.trigger.outDIN, INFO.onset.dinIOI);
    drifts_din

    % Clear temp and display
    clear thisTemp*
    disp(['Combined and sorted triggers and onsets'])
    [Triggers(i).all Onsets(i).allOrigFs]

    %%%% Compute corrected stimulus start times and display timing lags

    % Which element(s) of the combined, sorted trigger array correspond to
    % stim trials?
    thisStimTCPIdx = find(ismember(Triggers(i).all, INFO.trigger.stim));

    % Use the above index/indices to get the uncorrected onset time(s)
    % based on the TCP onset
    thisStimStartTime_uncorrected = Onsets(i).allOrigFs(thisStimTCPIdx);

    % Compute the corrected onset time based on the assumption that...
    % The TCP onset is always followed by a DIN event (thisStimTCPIdx + 1)
    % Occurring at the specified number of EEG time samples into the stimulus (- INFO.onset.dinSampOffset)
    thisStimStartTime_corrected = Onsets(i).allOrigFs(thisStimTCPIdx + 1) - INFO.onset.dinSampOffset;

    % Corrected (DIN-based) onset time always occurs after uncorrected
    % (TCP-based) onset time: Compute the onset lag as the corrected time
    % minus the uncorrected time.
    thisStimStartTime_lag = thisStimStartTime_corrected - thisStimStartTime_uncorrected;

    % Store the original and corrected stim onset(s) and lag(s)
    Onsets(i).stimUncorrOrigFs = thisStimStartTime_uncorrected;
    Onsets(i).stimCorrOrigFs = thisStimStartTime_corrected;
    Onsets(i).stimLagOrigFs = thisStimStartTime_lag;


    % Display median and outlier lags (skipped if only one lag)
    if length(thisStimStartTime_lag) > 1
        disp('Median lag  Mean lag and SD')
        [median(thisStimStartTime_lag)  mean(thisStimStartTime_lag) std(thisStimStartTime_lag,1)]
        disp('Outlier lags (>1 Median Absolute Deviation)')
        TF = isoutlier(thisStimStartTime_lag, 'median', 'ThresholdFactor',1); % Threshold set to 1 SD 
        [thisStimStartTime_uncorrected(TF) thisStimStartTime_corrected(TF) thisStimStartTime_lag(TF)]
        clear TF
    end
    
    % Display original fs onset(s), corrected onset(s), and lag(s)
    disp('Original, corrected, and lag(s) - original sampling rate')
    [thisStimStartTime_uncorrected thisStimStartTime_corrected thisStimStartTime_lag]
    
    % Compute downsampled versions of uncorrected and corrected onsets
    Onsets(i).stimUncorrDS = round(Onsets(i).stimUncorrOrigFs / INFO.FILTERING.DS);
    Onsets(i).stimCorrDS = round(Onsets(i).stimCorrOrigFs / INFO.FILTERING.DS);

    %%% Extract triggers corresponding to stimuli and stim + response
    Triggers(i).stimuli = Triggers(i).all(ismember(Triggers(i).all, INFO.trigger.stim));
    Triggers(i).stimBehav = Triggers(i).all(ismember(Triggers(i).all, [INFO.trigger.stim(:); INFO.trigger.response(:)]));

    disp('Stimulus and behav response triggers:')
    Triggers(i).stimBehav

    %%%%%%%%%%%%%%%%%%%%% DIN/TCP parsing complete %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%% Epoch the EEG data %%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%% Variables of interest for this section - use element j for each.
    % Stimulus triggers are in Triggers(i).stimuli
    % Corrected, downsampled onsets are in Onsets(i).stimCorrDS

    % Compute number of stimulus trials for the current file
    thisNTrials = length(Triggers(i).stimuli);
    disp([newline 'Epoching ' num2str(thisNTrials) ' trial(s) for this file.'])

    %%%% Iterate through the trials of this file
    for j = 1:thisNTrials

        %%% Get current trigger
        thatTrigger = Triggers(i).stimuli(j);

        %%% Get current info from STIMINFO

        % STIMINFO table row number for current trigger
        thatSIIdx = find(STIMINFO.trigger == thatTrigger);
        assert(length(thatSIIdx) == 1, ...
            'Did not retrieve exactly one table row for current trial!')

        % Audio sampling rate for current stimulus
        thatWavFs = STIMINFO.wavFs(thatSIIdx);

        % Current stimulus length in audio samples
        thatWavLenSamp = STIMINFO.wavLenSamp(thatSIIdx);

        % Block type label of current stimulus as categorical variable
        thatStimBlock = categorical(STIMINFO.blocktype(thatSIIdx));

        %%% Compute corresponding EEG epoch length (dimensional analysis)
        % Note that we are using 'round' which means that it's possible for
        % the EEG epoch to be slightly longer than the audio. The other
        % option would be to use 'floor', which would always make the EEG
        % no longer than the audio.
        thatEEGLenSamp = round(thatWavLenSamp * 1/thatWavFs * fs);

        %%% Specify the EEG data columns of the current trial
        thatCols = Onsets(i).stimCorrDS(j) + (0:(thatEEGLenSamp - 1));

        %%% Grab the current epoch and median DC Correct
        thatXDC = medianDCCorrect(thisXFiltDS(:, thatCols));

        %%% Append the current epoch on the per-file concat
        xAll_129 = [xAll_129 thatXDC];

        %%% Print a bunch of stuff
        disp([newline '~~ Current trial info ~~' newline ...
            'File ' num2str(i) ', trial ' num2str(j) ': Stim ' ...
            num2str(thatTrigger) ' (' char(thatStimBlock) ')' ...
            newline num2str(round(thatWavLenSamp/thatWavFs, 3)) ...
            ' seconds, ' num2str(thatEEGLenSamp) ' EEG samples.'])

        %%% Aggregate current info as table row and append to table
        % (1) Row number; (2) File number; (3) Trial number in file;
        % (4) Block type; (5) Trigger; (6) Trial len (samp);
        % (7) Samp start; (8) Samp end; (9) Stim + behav triggers
        thatTableRow = {tCounter, i, j, thatStimBlock, thatTrigger, ...
            thatEEGLenSamp, 0, 0, {NaN}};
        T = [T; thatTableRow];
        tCounter = tCounter + 1;

    end

    %%%%%%%%%%%%%%%%%%%%%%% EEG epoching complete %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp([newline '~* File ' num2str(i) ': Filtering, trigger/onset extraction, and filtering complete ~*'])

end

clear this* that* temp* tCounter

disp([newline '~*~* Filtering and epoching complete *~*~'])

%%% Post-concatenation steps - add additional columns to table

%%% NOTE: This section assumes the table rows are in the correct order.
%%% This section could be converted to a function in a future release.

%%% Add trial start and end samples to table
tempStartEndSamps = convertTrialLenToStartStopIdx(T.SampLen, size(xAll_129, 2));
T.SampStart = tempStartEndSamps(:, 1);
T.SampEnd = tempStartEndSamps(:, 2);
clear tempStartEndSamps

%%% Add behavioral responses to table
% Variable of interest: Triggers(i).stimBehav

tempAllBehav = {};

% Iterate through the elements of the Triggers struct
for i = 1:length(Triggers)

    % Get current array of triggers
    thisStimBehavTriggers = Triggers(i).stimBehav;

    % Get number of elements in current array
    thisNStimBehav = length(thisStimBehavTriggers);

    % Iterate through the elements in the current array
    for j = 1:thisNStimBehav

        % Here is the current element
        thatElement = thisStimBehavTriggers(j);

        % If the current element is a stim trigger, start a new cell array
        if ismember(thatElement, Triggers(i).stimuli)
            tempAllBehav{end+1} = [];
        end

        % Fill in the current cell array with the current element, whether
        % it's a stim or behav trigger
        tempAllBehav{end}(end+1) = thatElement;

    end

end

% Move the behavioral responses into the table
T.Behav = tempAllBehav(:);

% Check that the responses are correctly separated by stimulus and mapped
% to table elements by confirming that the first element of each behavioral
% response array matches the trigger in each table row.
for i = 1:size(T,1)
    assert(isequal(T.Trigger(i), T.Behav{i}(1)), ...
        ['Trigger-Behav mismatch for trial ' num2str(i) '!'])
end

disp([newline '~*~* Added trial start/end samps and behavioral responses to table. *~*~'])

clear this* that* temp* 

%%% Clear vars get ready to save

INFO.STIMINFO = STIMINFO;
INFO.preproc1_MR_fNamesLoaded = fNamesMatRaw;
INFO.preproc1_MR_nFilesLoaded = nFilesMatRaw;
INFO.preproc1_MRE_fNameSaved = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse '.mat'];
INFO.preproc1_datetime = thisDateTime(1);

if saveFigs
    disp([newline '\ * \ Script complete (multiple figures saved) / * /'])
else
    disp([newline '\ * \ Script complete (no figures saved) / * /'])
end

%%%%%%%%%%%%%%%%%%%%% Variables to clear %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear ans fNamesMatRaw i j nFilesMatRaw saveFigs saveLog STIMINFO fH tH tfH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Save

% 7 variables saved: EOG, fs, INFO, Onsets, T, Triggers, xAll_129

save([INFO.matRawEpochedDir filesep INFO.preproc1_MRE_fNameSaved])

disp([newline 'Run date/time: ' INFO.preproc1_datetime])

disp([newline '~ * ~ * MatRawEpoched file ' INFO.preproc1_MRE_fNameSaved ' was saved * ~ * ~'])
diary off

