% preproc_4_postICA.m
% ---------------------------------------
% This script performs data preprocessing step following ICA:
% - Operates on pairs of RawMatEpoched (RME) + corresponding W .mat files
% - Final preprocessing steps can be conducted (1) across all available 
%   data at once, or (2) on a per-subfile (i.e., original recording) basis. 
% - Final data are saved out in an [electrode x time] matrix, in which all
%   trials are concatenated. The trials can later be epoched using the
%   start- and end-sample specifications in the table T.

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

%%% Code block 1 of 11: Instructions
% 1 - Ensure items in 'per-run user-specified fields' sections in this 
%     code block are up to date.
% 2 - Run the code block.
% 3 - Confirm that command window output is as expected.
% 4 - There is no other decision making or interpretation for this block.

clear; close all; clc
disp('~ * ~ * Initiating ISC data cleaning (4 - post-ICA) * ~ * ~')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Begin per-run user-specified fields %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% User specifies items in this section for every file set.

% Specify input MIR filename
% No '.mat' extension, e.g., 'WTISC_ENI_139_b1234'
tempInFn = 'WTISC_ENI_136_b1234'; 

tempConfigFn = "preproc_0_config.m"; % Config File name

% Whether to save figures
saveFigs = 1;

% Whether to save log 
saveLog = 1; 

%%% Items in this section are set and then rarely or never updated.

% Specify input directory
% Full path of MatICAReady (MIR) input directory
tempInDir = '';

% Specify analyzer's initials
tempAnalyzer = 'XX';

% Path for Cleaning and Removing Bad electrodes after ICA
% tempPostICAPath = "Rec"; % Per Recording = "Rec", All data at once = "All"
tempPostICAPath = "Rec";

% Bad Channel Threshold
% SENSI NOTE: Ideally this was specified in the config file prior to Step 1, but
% since many Step 1 files were cleaned before it was added, we can specify
% it here. Default is 15.
tempBadChThres = 15;  % Recording will be removed after this many channels

% Electrode Location File
tempLocfile = 'Hydrocel GSN 124 1.0.sfp';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% End per-run user-specified fields %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Load the main data file and the W file
tempInFnW = [tempInFn '_W'];
load([tempInDir filesep tempInFn])
load([tempInDir filesep tempInFnW])

% Add post-ICA path to INFO
INFO.PostICAPath = tempPostICAPath;

% Update bad channel data rejection threshold if needed
if ~isfield(INFO, 'badChRejectionThresh') || ...
        isempty(INFO.badChRejectionThresh) || ...
        tempBadChThres ~= INFO.badChRejectionThresh

    INFO.badChRejectionThresh = tempBadChThres;
end

% Add current input filenames to INFO
INFO.preproc4_MIR_fNameLoaded = [tempInFn '.mat'];
INFO.preproc4_W_fNameLoaded = [tempInFnW '.mat'];
INFO.preproc4_analyzer = tempAnalyzer;

% Time samples of recording onsets, used for plotting but not saved
recOnsets = T.SampStart(T.TrialN == 1);

% Print a message
disp([newline 'Preprocessing post-ICA data for ' tempInFn '.'])
disp(['Input RME data file (w/ INFO struct): ' INFO.preproc4_MIR_fNameLoaded '.'])
disp(['Input W data file: ' INFO.preproc4_W_fNameLoaded '.'])

% Updating INFO struct and Loading Post ICA structs (just in case)
tempINFO = runConfig2Struct(tempConfigFn);
INFO.preprocFigDir = tempINFO.INFO.preprocFigDir; % Update Figure Folder
INFO.matCleanDir = tempINFO.INFO.matCleanDir; % Update Output Dir
% DIN and EKG Detection Options
INFO.PostICA = tempINFO.INFO.PostICA;

%%% Load electrode locations needed for plotting topographies:
chanlocs = chanlocsFromFile(tempLocfile);
% Remove previously identified bad channels from the chanlocs struct for plotting
if ~isempty(INFO.badCh)
    chanlocs(INFO.badCh) = [];
end

% Clear temporary variables
clear temp* configFn

disp([newline '\ * \ Code section complete (no figures) / * /'])

%% Convert data to ICA space and correlate EOG

%%% Code block 2 of 11: Instructions
% 1 - Run the code block.
% 2 - Figures will render and save if saveFigs = 1.
% 3 - This block converts the sensor-space EEG to component space using the 
%     ICA unmixing matrix W. It will render 3 or more figures.
%     a - The scatterplot figure is showing the correlation with each ICA 
%       component with the HEOG (x-axis) and VEOG (y-axis) components.  
%     b - The **High Reject Figure** (Figure 2) displays sources 
%         automatically flagged for removal based on INFO.ICA.HiThresh. 
%         This figure is non-interactive.
%     c - The **Low Reject Review UI** (Figure 3 onwards) will open an 
%         interactive window for components flagged based on 
%         INFO.ICA.LowThresh. Low-reject can be rejected by the user's 
%         discretion later in this script.
% 4 - By default, the low-reject components are specified for removal later 
%     in this script. Therefore you should make a note if any of the 
%     low-reject components are NOT appropriate for removal. You will use 
%     this information in a later step.
       
% **INTERACTION (Low Reject UI):**
% - The Low Reject UI displays topographies, correlations, and time series.
%   **Sources start flagged for REJECT (red).**
% - **To KEEP a source, click on its row** (time series). 
%   The row will turn **green**. You are confirming that the component 
%   is *not* artifactual and should be *kept*.
% - Review each component's topography and time course (particularly 
%   focusing on any clear artifacts) and use the interactive tool to make 
%   your final decisions.
% - Click the **'Done'** button to close the UI and save your final 
%   `lowReject` list.

close all

%%% Convert data from sensor space to ICA space
xICA = W * xRaw;

%%% Compute correlations of ICA-space data with EOG channels

% Input the hiReject threshold to get the hiReject sources
[corrV, corrH, hiReject] = corrEOG(xICA', EOG.dataVEOG, EOG.dataHEOG, ...
    INFO.ICA.HiThresh);

% Input the lowReject threshold to get the lowReject (and hiReject) sources
[~, ~, lowReject] = corrEOG(xICA', EOG.dataVEOG, EOG.dataHEOG, ...
    INFO.ICA.LowThresh);

% Remove the hiReject sources from the lowReject list
lowReject = setdiff(lowReject, hiReject);

%%% Render ICA plots

% Plot the correlations - Figure 1
plotCorrEOG(corrV, corrH, INFO.preproc4_MIR_fNameLoaded(1:end-4))
if saveFigs
    thisFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
            '_05a_ica_eogCorr.png'];
    saveCurrentFigure(INFO.preprocFigDir, thisFnOut, [14 8]);
end

% Plot High Reject Sources - Figure 2
reviewICAHighRejectSAVE(W, xICA, chanlocs, corrV, corrH, INFO.badCh, hiReject, ...
    [INFO.preproc4_MIR_fNameLoaded(1:end-4) '_05b_' 'High Reject'], saveFigs, INFO.preprocFigDir); 

% UI - Low Reject Sources - Figure 3
lowReject = reviewICALowRejectUI(W, xICA, chanlocs, corrV, corrH, INFO.badCh, lowReject, ...
    [INFO.preproc4_MIR_fNameLoaded(1:end-4) '_05c_' 'Low Reject'], saveFigs, INFO.preprocFigDir); 

%%% Print hiReject lowReject info
disp([newline '~ * ~ * ICA info * ~ * ~'])
disp(['High reject sources: ' mat2str(hiReject(:)')])
disp(['Low reject sources: ' mat2str(lowReject(:)')])

disp([newline '\ * \ Code section complete (rendered 3+ temporary figures) / * /'])


%% [optional] Visualize additional sources

%%% Code block 3 of 11: Instructions (optional block)
% 1 - The user can specify other components to look at. For instance, if
%     components [1 2 4] were flagged for high-reject and there are no
%     low-reject, you may want to see what is going on in component 3.
%     However, the user should NOT use this step to hunt around for
%     additional components to exclude! This pipeline seeks to flag
%     components for exclusion quantitatively as much as possible.
% 2 - Run the code block.
% 3 - Figure(s) will render but not save.
% 4 - As noted in internal documentation, it is highly unusual to flag any 
%     component for removal on the basis of visual inspection alone.  

% Current figures remain open

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Can edit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tempSrcLook = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

multiplotICAResultsStandalone(W, xICA, corrV, corrH, INFO.badCh, tempSrcLook, ...
    [INFO.preproc4_MIR_fNameLoaded(1:end-4) ' - Additional'])

% NOTE: These are just temporary figures that aren't saved out.

disp([newline '\ * \ Code section complete (rendered temporary figure[s]) / * /'])

%% Look for EKG and DIN activity

%%% Code block 4 of 11: Instructions
% 1 - Run the code block.
% 2 - This block uses a combination of automated detection and interactive 
%     review (two separate UIs) to identify components containing EKG or 
%     DIN artifacts.
% 3 - Two interactive figures will render: The **DIN Review UI** and the 
%     **EKG Review UI**. These figures will NOT automatically save; 
%     saving is triggered by clicking 'Done' inside the UI, provided 
%     'saveFigs = 1' in Code Block 1.
% 4 - Review the figures and make your final decisions for each component.

% INTERACTION (DIN UI and EKG UI):
% 5 - The UIs display suspected components. Sources start as flagged for 
%     REJECT (red).
% 6 - To KEEP a source (i.e., you do not believe it is an artifact): Click 
%     anywhere on its row (topography, time series, or frequency plot). The 
%     row will toggle to green.
% 7 - Review the components:
%     - For EKG, look for the classic cardiac beat waveform in the time 
%       series, frequency peaks on harmonics of 1 Hz, and characteristic 
%       topography.
%     - For DIN, look for abrupt, simultaneous sharp transients in the time 
%       series, and comb-like harmonics in the frequency domain. 
% 8 - Click 'Done' in each UI to submit your final selections and proceed 
%       to the next step.

% [OPTIONAL] Adjusting the Time Window:
% 9 - The time-domain plots show a 10-second segment starting at 
%     `tempStartSec` (default 5 minutes, or 5*60 seconds). In rare cases 
%     where an artifact is ambiguous (e.g., EKG-like), you may visualize a 
%     different segment of data by adjusting the value of `tempStartSec` in 
%     the preliminary variables section. Be sure any value you enter does 
%     not exceed the total length of the data. NOTE: In most cases, you 
%     should NOT need to adjust this parameter. Please do not spot-check 
%     different data segments by default.

% %%%%%%%%%%%%%%%%%% Preliminary Variables %%%%%%%%%%%%%%%%%%%%%

tempNSources = 1:size(xRaw,1); % Assess all available ICA components
% tempNSources = [1:30]; % Or, specify a subset of ICA Sources to Check

tempStartSec = 5*60; % Start time for temporal plot (seconds). Adjust per instruction #9.
tempNSec = 10; % Duration of temporal plot in seconds.

%%%%%%%%%%%%%%%%%%%%%% DIN Detection %%%%%%%%%%%%%%%%%%%%%%%%%

% Detect DIN ICA components via harmRatioFromSignal
[dinSrc, tempDinInfo] = autoDetectDIN(xICA, fs, tempNSources, INFO.PostICA.dinOpts);

% Interactive review of DIN candidates
dinSrc = reviewDINArtifactUI(W, xICA, fs, chanlocs, dinSrc, tempDinInfo.reviewCandidates, ...
   tempStartSec, tempNSec, [INFO.preproc4_MIR_fNameLoaded(1:end-4) '_05d_' 'DIN'], ...
   saveFigs, INFO.preprocFigDir);

if isempty(dinSrc); fprintf('\n\tNo DIN artifact detected\n')
else; fprintf('\n\tdinSrc = %s\n', mat2str(dinSrc));
end

%%%%%%%%%%%%%%%%%%%%%%% EKG Detection %%%%%%%%%%%%%%%%%%%%%%%%%
% SNR Harmonic Test (detecting beats via spectral analysis)
[ekgSrc, ekgSus, ~] = autoDetectEkg(xICA, fs, tempNSources, INFO.PostICA.ekgOpts);

% EKG UI - Interactive review of flagged and suspected sources
ekgSrc = reviewEkgArtifactUI(W, xICA, fs, chanlocs, ekgSrc, ekgSus, ...
   tempStartSec, tempNSec, [INFO.preproc4_MIR_fNameLoaded(1:end-4) '_05e_' 'EKG'], ...
   saveFigs, INFO.preprocFigDir);

if isempty(ekgSrc); fprintf('\n\tNo EKG artifact detected\n')
else; fprintf('\n\tekgSrc = %s\n', mat2str(ekgSrc));
end


%% EXCEPTIONAL CIRCUMSTANCES ONLY!!

%%% Code block 5 of 11: Instructions
% Use this block ONLY for components not caught by the automated EOG, EKG,
% or DIN detectors that are CLEARLY artifactual.

otherSrc = [];
% Identify all components NOT already flagged for removal from the first 10 ICs
tempOtherSrc = setdiff((1:10).',[hiReject(:); lowReject(:); ekgSrc(:); dinSrc(:)]);

% Use the updated, save-enabled UI for review. Note: This UI starts components 
% flagged for KEEP (green), as rejection here should be rare.
otherSrc = reviewOtherUI(W, xICA, fs, chanlocs, otherSrc, tempOtherSrc, ...
    [INFO.preproc4_MIR_fNameLoaded(1:end-4) '_05f_' 'Other'], saveFigs, INFO.preprocFigDir); % Figure 6

clear temp*

%% Specify ICA sources to remove

%%% Code block 6 of 11: Instructions
% 1 - The component lists below which were generated in Code Blocks 2, 4, and 5:
%     - 'hiReject' (Hi-Frequency/Muscle)
%     - 'lowReject' (Lo-Frequency/Eye)
%     - 'ekgSrc' (EKG/Cardiac)
%     - 'dinSrc' (Digital Input Artifact)
%     - 'otherSrc' (Exceptional Manual Reject)
% 2 - Run the code block to finalize the list of components to remove.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Can edit  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The default behavior removes ALL components identified in all previous steps:
rmSrc = [hiReject(:); lowReject(:); ekgSrc(:); dinSrc(:); otherSrc(:)];

% Example of keeping lowReject sources:
% rmSrc = [hiReject(:); ekgSrc(:); dinSrc(:); otherSrc(:)];

% Example of rejecting even more sources not specified in a variable:
% extraSrc = [12 15];
% rmSrc = [hiReject(:); ekgSrc(:); dinSrc(:); otherSrc(:); extraSrc(:)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp([newline 'rmSrc = ' mat2str(rmSrc(:)')]);
disp(['\ * \ Code section complete (no additional figures rendered) / * /'])
clear this*

%% Remove artifact sources and convert back to channel space

%%% Code block 7 of 11: Instructions
% 1 - Run the code block.
% 2 - This block zeroes out any artifact components and converts the
%     resulting data back to "clean" sensor space. 
% 3 - There are no figures or other actions in this block.

close all

% In the ICA-space data frame, set rows (components) of data that are 
% flagged for removal to zero. 
xICA(rmSrc,:) = 0;

%%% Convert the data back to (clean) sensor space
xCl = inv(W) * xICA;            % <-- this is the post-ICA data

%%% Add variables to INFO
INFO.ICA.W = W;
INFO.ICA.HiReject = hiReject;
INFO.ICA.LowReject = lowReject;
INFO.ICA.EkgSrc = ekgSrc;
INFO.ICA.DinSrc = dinSrc;
INFO.ICA.OtherSrc = otherSrc;
INFO.ICA.RmSrc = rmSrc;

%%% Clear extraneous variables
clear hiReject lowReject ekg* dinSrc otherSrc rmSrc corr* temp*

disp([newline '\ * \ Code section complete (no figures) / * /'])

%% Plot and optionally save before and after ICA

%%% Code block 8 of 11: Instructions
% 1 - Run the code block.
% 2 - This block plots the data before and after artifacts were removed 
%     using ICA. If saveFigs is on, the figure will be saved. 
% 3 - It also looks across all of the available data and determines 
%     whether, for any channel, sample magnitudes exceeding the specified 
%     voltage threshold is greater than or equal to the specified
%     percentage threshold. If this is detected (in this case there will 
%     be a red horizontal line), a warning will print in the console and 
%     you may expect one or more blocks to be flagged for rejection in 
%     the final stages. 
% 4 - Interpret the before and after line plot. Also make note of the
%     overall per-channel percentages exceeding to uV, and if any channels
%     have crossed the 10% threshold. 

close all

% Temporarily fill bad channel rows with NaNs
tempX124_before = fillBadChRows(xRaw, INFO.badCh);
tempX124_after = fillBadChRows(xCl, INFO.badCh);

figure()

% Overlay - before ICA
subplot(4, 2, 1)
plotEEGOverlay(tempX124_before, recOnsets(2:end))
title('Before ICA, data overlay')
xlabel('Time (sample)'); ylabel('\muV')

% Image - before ICA
subplot(4, 2, [3 5])
imagesc(abs(tempX124_before)); box off
title('Before ICA, data image (abs)')
xlabel('Time (sample)'); ylabel('Electrode')
tempH = colorbar;
tempH.Location = 'southoutside';
tempH.Label.String = 'abs(\muV)';

% Overlay - after ICA
subplot(4, 2, 2)
plotEEGOverlay(tempX124_after, recOnsets(2:end))
title('After ICA, data overlay')
xlabel('Time (sample)'); ylabel('\muV')

% Image - after ICA
subplot(4, 2, [4 6])
imagesc(abs(tempX124_after)); box off
title('After ICA, data image (abs)')
xlabel('Time (sample)'); ylabel('Electrode')
tempH = colorbar;
tempH.Location = 'southoutside';
tempH.Label.String = 'abs(\muV)';

sgtitle([INFO.sStr '_' INFO.blkStrUse ': Before and after ICA'], 'interpreter', 'none')


%%% ID and plot recording-wide bad channels

% Create a temporary indicator matrix -> data values > threshold.

% Call the function to compute the percentage of data points whose
% magnitudes strictly exceed the specified recording uV threshold.
tempRecOverUVThresh = computePerChannelPctOverThresh(tempX124_after, INFO.recUVThresh);

% Plot the pct over threshold
subplot(4, 2, [7 8])
stem(1:124, tempRecOverUVThresh);
xlim([1 124]); box off; hold on; grid on
title(['After ICA, per-channel percentage of abs values exceeding ' num2str(INFO.recUVThresh) 'uV'])

% If any electrodes' percentage of data points over the uV threshold is
% greater than or equal to the specified percentage threshold, annotate the
% plot, print which ones, and print warning.
if any(tempRecOverUVThresh >= INFO.recPctThresh)

    yline(INFO.recPctThresh, 'r', 'linewidth', 1.5);
    tempChOver = find(tempRecOverUVThresh >= INFO.recPctThresh);
    stem(tempChOver, tempRecOverUVThresh(tempChOver), 'r')
    disp([sprintf('Electrodes with at least %.1f%% of samples exceeding %d uV\nacross all data: ', ...
        INFO.recPctThresh, INFO.recUVThresh) mat2str(tempChOver(:)')])
    title(['After ICA, per-channel percentage of abs values exceeding ' num2str(INFO.recUVThresh) 'uV: ' ...
        mat2str(tempChOver(:)') ' flagged'])
    warning(['Recording bad channel(s) detected after ICA. One or more recordings may need to be' ...
        'removed depending on total bad channel count.'])
else

    % If we didn't encounter an error, that means there are no recording bad
    % channels and we can continue.
    disp('- * No recording bad channels! * -')
end

clear temp*

if saveFigs

    % Make the output filename.
    thisFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
        '_06_xRaw_xCl_prePostICA.png'];

    % Specify save size width and height (will depend on number of files)
    thisFigSize = [16 12];

    % Call the 'saveCurrentFigure' function in the BKan repo. Inputs are
    % (1) output path, (2) output filename w/ extension, (3) figure save size
    % [width height], (4) figure handle (default gcf) (5) whether to print
    % message at the end (default true).
    saveCurrentFigure(INFO.preprocFigDir, thisFnOut, thisFigSize);
    disp([newline '\ * \ Code section complete (rendered and saved 1 figure) / * /' newline])

    clear this*
else
    disp([newline '\ * \ Code section complete (rendered 1 figure; no figures saved) / * /' newline])
end


%% Final cleaning steps ("per-trial" or "all at once")

%%% Code block 9 of 11: Instructions
% 1 - Run the code block.
% 2 - This block performs all of the post-ICA cleaning steps. A warning
%     will print in the console if any data is not usable, or if more than
%     10% of data were flagged as transients and converted to NaN in the
%     respective data unit "Rec" or "All". 
% 3 - Unusable data are not cleaned further, and the stimulus table T is
%     updated to reflect their removal. 
% 4 - This block also renders a figure that visualizes (with pooling) the
%     NaNs present in the data before and after missing values are imputed.
%     If all values at a given time point are 0 after imputation, this
%     means that all channels' data were NaN-d at that point and only the
%     zero reference was imputed. In this case, data for all channels at
%     that time point will be converted back to NaN. 
% 5 - If saveFigs is on, this figure will be saved. If saveLog is on, the 
%     console output for this block will be saved. If a .txt file of the
%     log already exists, it will be deleted and a new one will be written.
% 6 - Review the console output for any warnings. Make note of the final
%     percentage of NaN-d data.
% 7 - Review the figure for any NaNs remaining after imputation (it may
%     help to stretch the figure horizontally a bit). Make note of whether
%     this was observed for any of the files. 

% This section cleans xCl "after ICA" either "per-trial" or "all at once"

close all;

% Start the output log if specified
diary off
if saveLog
    tempLogFnOut = [INFO.preprocFigDir filesep ...
        INFO.preproc4_MIR_fNameLoaded(1:end-4) '_09_FinalStepsLog.txt'];
    warning('off', 'MATLAB:DELETE:FileNotFound') % Turn off warning 
    delete(tempLogFnOut)    % Delete existing logfile, if it exists
    warning('on', 'MATLAB:DELETE:FileNotFound')  % Turn warning back on
    diary(tempLogFnOut)     % Initalize the current logfile
end

disp(['Final cleaning steps for ' INFO.preproc4_MIR_fNameLoaded(1:end-4) newline])

T_old = T; % Saving Legacy Table
config.badRec = 0; % Leave empty. Will update if there is at least one bad Rec

% Initializing Path: Rec or All
if INFO.PostICAPath == "Rec"
    tmpTableFiles = unique(T.FileN); % File Tags
    tmpRecCell = {}; % Cell containing clean output that passed #Bad Chs
    tmpremoveMask = false(height(T), 1);  % initialize Table mask
    N = length(tmpTableFiles); % Number of Files
elseif INFO.PostICAPath == "All"
    N = 1; % if path = "All: pass all data at once
else
    warning('INFO.PostICAPath was not defined correctly. Ending this run.'); return;
end

INFO.badChsRecs = cell(N,1); % Initializing variable Bad Channel cell array
finalPctNBS = ones(4,1)*NaN; % Initializing variable - Final BadSample % "per rec" or "all";

% Initializing NaN Pool Figures
fig1 = figure();
tiledlayout(N,2, 'TileSpacing', 'compact', 'Padding', 'compact');

disp(['~ * ~ * Performing final steps on xCl (' ...
    mat2str(size(xCl)) ') matrix: * ~ * ~'])

% Main Loop
fprintf('\n----- Cleaning Main Loop -----\n');
for i = 1:N

    % Getting Data
    if INFO.PostICAPath == "Rec"
        fprintf('\n---- Rec %g of %g ----\n', i, N);
        tmpFileID = tmpTableFiles(i);
        tmpFileLogic = T.FileN == tmpFileID;
        tmpFileTable = T(tmpFileLogic,:);

        % Slicing Data
        start_id = tmpFileTable.SampStart(1);
        end_id = tmpFileTable.SampEnd(end);
        
        xSingleRec = xCl(:,start_id:end_id);
    else
        xSingleRec = xCl; % All data if "All" Path
    end

    % Over UV Thresh
    tmpOverUVPct = computePerChannelPctOverThresh(xSingleRec, INFO.recUVThresh);
    curr_badCh_logic = tmpOverUVPct >= INFO.recPctThresh;

    % Getting/Saving Absolute Bad Channel per Rec
    tmpCurrChannels = setdiff(1:124, INFO.badCh, 'stable');

    tmpCurrBadChs = tmpCurrChannels(curr_badCh_logic);
    INFO.badChsRecs{i} = union(tmpCurrBadChs, INFO.badCh);
    if INFO.PostICAPath == "All"
        INFO.badCh = INFO.badChsRecs{1}; % If All Path, update INFO.badCh
    end

    % If #Bad CHs is higher than %, Skip and Remove From Table
    badChTotal = sum(curr_badCh_logic) + length(INFO.badCh);
    if badChTotal > INFO.badChRejectionThresh
        if INFO.PostICAPath == "Rec"
            config.badRec = 1; % There is at least 1 bad recording
            tmpremoveMask(tmpFileLogic) = true; % Update Table Mask
            warning('Recording %g not usable and will be removed\n', i)
            continue; % Continue with Next Recording
        else
            warning(sprintf('Recording "All" not usable. Ending this run.\n')); return; % Stop
        end
    end

    % Removing Bad Channels from Single Recording
    xSingleRecGood = xSingleRec(~curr_badCh_logic,:);

    % Median DC correct
    xSingleRecDC1 = medianDCCorrect(xSingleRecGood);

    % NaN bad samples
    [xSingleNBS, SinglePctNBS] = nanBadSamples(xSingleRecDC1, 4, 4, 0, 25);
    disp('-- NaN bad samples: Done.')
    disp(['Percent NaNs after each NBS iteration: ' ...
        mat2str(round(SinglePctNBS(:)', 4))])

    % Warning if NaN > 10%
    if max(SinglePctNBS) > 10
        warning('NaN = %.1f%%', max(SinglePctNBS))
    end

    % Mean DC Correct
    xSingleRecDC2 = dcCorrect(xSingleNBS);
    disp('-- Mean DC correction: Done.')

    % Fill bad channels back in with NaN --> 124-channel data
    xSingle124 = fillBadChRows(xSingleRecDC2, INFO.badChsRecs{i});
    disp('-- Fill bad ch rows: Done.')

    % Add zero row of reference --> 125-channel data
    xSingle125 = [xSingle124; zeros(1, size(xSingle124, 2))];
    disp('-- Add zero row of reference: Done.')

    % Impute missing values
    xSingleImputed = imputeAllNaN129(xSingle125);
    disp('-- Impute missing values: Done.')

    % NaN zero Columns (incidates all-channel artifact)
    xSingleNanCol = nanZeroColumns(xSingleImputed);

    % Convert to average reference
    xSingleAR = doAR(xSingleNanCol);
    disp('-- Convert to average reference: Done.')

    % Final mean DC correction 
    X = dcCorrect(xSingleAR); 
    disp('-- Final mean DC correction: Done.')

    % Temp Cell collecting for Good Recs
    if INFO.PostICAPath == "Rec"
        tmpRecCell{end+1} = X;
    end

    % Final NBS percentage "Per Recording" or for "All"
    finalPctNBS(i) = SinglePctNBS(end);

    nexttile;
    imagesc(samplePool(isnan(xSingle125),5000))
    title('Before imputation')
    title(sprintf('File %d - Before imputation', i));

    nexttile;
    tmpNan = isnan(xSingleAR);
    imagesc(samplePool(tmpNan,5000))
    title(sprintf('Exactly %d after imputation and avg ref', sum(tmpNan(:))));

end

% Per Recording Concat Trials - 
if INFO.PostICAPath == "Rec"
    X = [tmpRecCell{:}]; % Concat Good Trials
end

% Figure Handling
sgtitle([strrep(INFO.sStr, '_', '\_') '\_' INFO.blkStrUse ': NaNs Pooled'])
disp([newline '----- Cleaning Complete -----'])

% Stop saving to log if that was happening
diary off

% Saving Figure if enabled
if saveFigs
    thisFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse '_07_finalPooled_NaNs.png'];
    saveCurrentFigure(INFO.preprocFigDir, thisFnOut);
    clear this*
end

% Check if Output is Empty or Does not Exist
if ~exist('X','var') || isempty(X)
    warning('Output is Empty. No usable recording found.');
    warning('Ending this run.'); return;
end

% Update T table
if config.badRec % Update T if at least 1 bad recording
    T(tmpremoveMask, :) = [];
    % Fix T start and end sample
    tmpIds = convertTrialLenToStartStopIdx(T.SampLen,size(X,2));
    T.SampStart = tmpIds(:,1);
    T.SampEnd = tmpIds(:,2);
end

% Time samples of recording onsets, used for plotting but not saved
recOnsets = T.SampStart(T.TrialN == 1);

% End of code block
if saveFigs
    disp([newline '\ * \ Code section complete (rendered and saved 1 figure) / * /'])
else
    disp([newline '\ * \ Code section complete (rendered 1 figure; no figures saved) / * /'])
end

clear tmp* start_id end_id i N


%% Render and optionally save the final plot

%%% Code block 10 of 11: Instructions
% 1 - Run the code block.
% 2 - This block renders and - if saveFigs is on - saves the final clean
%     data plot. 
% 3 - Review the figure and make note of the final data. 
% 4 - There are no other actions or decisions for this block. 

close all

figure()

% Overlay
subplot(4, 1, 1)
plotEEGOverlay(X, recOnsets(2:end))
title('Overlay, all trials')
xlabel('Time (sample)'); ylabel('\muV')

% Image
subplot(4, 1, [2 3])
imagesc(abs(X)); box off
title('Image (abs), all trials')
xlabel('Time (sample)'); ylabel('Electrode')
h = colorbar;
h.Location = 'southoutside';
h.Label.String = 'abs(\muV)';

% Pct over threshold
tempRecOverUVThresh = computePerChannelPctOverThresh(X, INFO.recUVThresh);
subplot(4, 1, 4)
stem(1:125, tempRecOverUVThresh);
xlim([1 125]); box off; hold on; grid on
xlabel('Electrode'); ylabel('%')
title(['Per-channel pct abs values > ' num2str(INFO.recUVThresh) 'uV, all trials'])
sgtitle([INFO.sStr '_' INFO.blkStrUse ': Final AR data'], 'interpreter', 'none')

%%% [optional] Save the final plot

if saveFigs

    % Make the output filename.
    thisFnOut = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
        '_08_X_finalAR.png'];

    % Specify save size width and height (will depend on number of files)
    thisFigSize = [12 12];

    % Call the 'saveCurrentFigure' function in the BKan repo. Inputs are
    % (1) output path, (2) output filename w/ extension, (3) figure save size
    % [width height], (4) figure handle (default gcf) (5) whether to print
    % message at the end (default true).
    saveCurrentFigure(INFO.preprocFigDir, thisFnOut, thisFigSize);
    disp([newline '\ * \ Code section complete (rendered and saved 1 figure) / * /'])

    clear this*
else
    disp([newline '\ * \ Code section complete (rendered 1 figure; no figures saved) / * /'])
end

%% Final updates / clean up unneeded variables / save the output

%%% Code block 11 of 11: Instructions
% 1 - Run the code block.
% 2 - This block adds final values to the INFO struct, clears all
%   variables except those that will be saved, and saves the remaining
%   variables in the MatClean directory.
% 3 - When everything is done running, a message like this will print in
%     the console: 
%    ~ * ~ * MatClean file WTISC_ENI_139_b1234_finalRec was saved * ~ * ~

close all

%%% Add final fields to INFO
INFO.T_original = T_old;
INFO.T_final = T;
INFO.recPctOverUVThresh = tempRecOverUVThresh;
INFO.pctNBS = finalPctNBS; % Pooled across recordings
INFO.preproc4_MC_fNameSaved = [INFO.fSaveStr INFO.sStr '_' INFO.blkStrUse ...
    '_final' char(INFO.PostICAPath) '.mat'];
INFO.preproc4_datetime = thisDateTime(1);

%%%%%%%%%%%%%%%%%%%%% Variables to clear %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except EOG fs INFO Onsets T Triggers X

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 7 variables saved: EOG, fs, INFO, Onsets, T, Triggers, X

save([INFO.matCleanDir filesep INFO.preproc4_MC_fNameSaved])
disp([newline '~ * ~ * MatClean file ' INFO.preproc4_MC_fNameSaved ' was saved * ~ * ~'])
