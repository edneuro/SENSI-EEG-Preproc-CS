% preproc_5_aggregateData.m
% --------------------------------
% This script iterates through the clean .mat files, aggregates the data by
% stimulus (one 3D matrix per stimulus), and writes out one .mat file per
% stimulus. 
%
% Instructions
% ------------
% 1. On first use, update the "User-specified fields" in Code Block 1.
%   - inDir: Full path to MatClean directory (output of Step 4).
%   - outDir: Full path to directory where outputs of this step will be
%     saved. If the directory does not exist, the function will create it. 
%   - fileTypeToIdx: Specify 'All' or 'Rec' (in single quotes). The script
%     will index only the files that have that in the end of the filename. 
%   - stimUse: Leave as empty vector [] or comment out the line if you wish
%     to index all files. If you want to index only selected files, specify
%     them here (this can be helpful if e.g., wanting to look at only one
%     stimulus condition, since the steps can take a while when operating 
%     over many stimuli and participants).
% 2. Run the code. 
%   - After Step 1 is completed, the script can be run one code block at a 
%     time or in blocks since there are no other user actions. 
%   - Note: When operating over many stimuli and participants, the script
%     can take a little while to run. The following message will print in
%     the Matlab console once the script is completely done:
%               ~ * ~ * Data aggregation complete * ~ * ~

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


%% Setup

clear all; close all; clc

%%%%%%%%%%%%%%%%%%%%%%%%% User-specified fields %%%%%%%%%%%%%%%%%%%%%%%%%

% Specify input and output directories
inDir = '';
outDir = '';

% Specify whether to index 'All' or 'Rec' files from Step 4
fileTypeToIdx = 'Rec'; % Use single quotes

% Analyzer initials
analyzer = 'XX';

% Optional: Specify which stimuli you want to process and save out. If
% specified as empty or not specified (i.e., line is commented out), the
% script will process any stimulus listed in the stim table of each file.
stimUse = []; % e.g., [501:502];

% Whether to save out the log file (saved once as a standalone file in the
% output directory).
saveLog = 1; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Register date and time of this run
dateTimeOfRun = thisDateTime(1);

% Start the output log if specified
diary off
if saveLog
    tempLogFnOut = [outDir filesep 'AggregateDataLog_' dateTimeOfRun '.txt'];
    warning('off', 'MATLAB:DELETE:FileNotFound') % Turn off warning 
    delete(tempLogFnOut)    % Delete existing logfile, if it exists
    warning('on', 'MATLAB:DELETE:FileNotFound')  % Turn warning back on
    diary(tempLogFnOut)     % Initalize the current logfile
end

disp('~ * ~ * Initiating data aggregation (MatClean data) * ~ * ~')

%%% Set flag of whether to use custom stim array
if ~exist('stimUse', 'var') || isempty(stimUse)
    customStimArray = 0;
else, customStimArray = 1;
end

%%% Get the list of input files

% Index files whose filenames end with 'finalAll.mat' or 'finalRec.mat' as 
% specifed above.
fList = dir([inDir filesep '*final' fileTypeToIdx '.mat']);
fNames0 = {fList.name}; % Just the filenames
fNames = {};

% Get rid of filenames beginning with '._'
for tempF = 1:length(fNames0)
    currFName = fNames0{tempF};
    if ~strcmp(currFName(1:2), '._'), fNames{end+1} = currFName; end
end

nFiles = length(fNames); % Number of files to be processed

clear tempF currFName fNames0

%%% Print messages on number of files indexed and stimUse
disp([newline 'Indexed ' num2str(nFiles) ' clean (ME) files.'])
if customStimArray
    disp(['Stimuli processed: ' mat2str(stimUse(:)') '.'])
else
    disp('Processing all available stimuli.')
end

%%% Fill in the INFO struct (will be saved with each output file)
INFO.preproc5_inDir = inDir;
INFO.preproc5_outDir = outDir;
INFO.preproc5_analyzer = analyzer;
INFO.preproc5_fileType = fileTypeToIdx;
INFO.preproc5_stimUse = stimUse;
INFO.preproc5_fNames = fNames;
INFO.preproc5_datetime = dateTimeOfRun;

%% Process the data

% Initiate variable to store which stim numbers were processed
ALLSTIMS = [ ];

% Variables for NaN Gaps Fix
allNanGaps = {};
allNanGapsID = 0;
longGapTable = table();
allnanPlotData = {};

% Clear important variables
clear data* subID* behav*

% Iterate through the files
for f = 1:nFiles

    %%% Specify, load, and check the current input file

    % Current input filename
    thisFnIn = [inDir filesep fNames{f}];

    % Load the file
    THIS = load(thisFnIn);
    %   struct with fields:
    %
    %      EOG: [1×1 struct]
    %     INFO: [1×1 struct]
    %   Onsets: [1×4 struct]
    %        T: [50×9 table]
    % Triggers: [1×4 struct]
    %        X: [125×223020 double]
    %       fs: 250

    % Initialize or confirm the sampling rate
    if f == 1, fs = THIS.fs;
    else, assert(THIS.fs == fs, 'Loaded data "fs" does not match global "fs"!')
    end

    % Create the current subID
    thisSubID = [THIS.INFO.fSaveStr THIS.INFO.sStr];

    % Confirm that X and T exist
    assert(isfield(THIS, 'X'), 'Loaded data does not contain data variable "X"!')
    assert(isfield(THIS, 'T'), 'Loaded data does not contain trial info table "T"!')

    % Confirm that last epoch specified in T matches total length of X
    assert(isequal(THIS.T.SampEnd(end), size(THIS.X, 2)), ...
        'Number of time samples accounted for in T does not equal length of X!')

    % Get number of rows in current table (number of trials to process)
    thisNTrials = height(THIS.T);

    disp([newline '~* Processing file ' num2str(f) ' of ' num2str(nFiles) ...
        ': ' thisSubID ' (' num2str(thisNTrials) ' trials) ~*'])

    %%% Iterate through the table rows in the current file
    for t = 1:thisNTrials

        %%% Get various info for current trial -- for now we are just
        %%% collecting data, participant id, and behavioral responses.
        %%% Eventually we should also note e.g., which block it was, which
        %%% trial for the block.
        thatTrigger = THIS.T.Trigger(t);
        thatStartSamp = THIS.T.SampStart(t);
        thatEndSamp = THIS.T.SampEnd(t);
        thatBehav = THIS.T.Behav{t}; % Row vector

        if ~customStimArray || ismember(thatTrigger, stimUse)

            disp(['Trigger ' num2str(thatTrigger) ...
                ', time samples ' num2str(thatStartSamp) ' to ' num2str(thatEndSamp) ...
                ', trigger+behav: ' mat2str(thatBehav)])

            % If variable 'data###' for trigger### doesn't exist, initiate
            % the variables for this trigger
            if ~exist(['data' num2str(thatTrigger)], 'var')
                eval(['data' num2str(thatTrigger) ' = [];']);
                eval(['behav' num2str(thatTrigger) ' = [];']);
                eval(['subID' num2str(thatTrigger) ' = {};']);
                ALLSTIMS(end+1) = thatTrigger;
            end
            % eval(['size(data' num2str(thatTrigger) ')']) % DEBUG
            
            % ================ Gap Fix Section =================
            [xGapsFix, nanGaps, GapTable, nanPlotData] = ...
                temporalNaNCorrect(THIS.X(:, thatStartSamp:thatEndSamp), THIS.fs, f, t);
            
            allNanGapsID = allNanGapsID + 1;
            allNanGaps{allNanGapsID} = nanGaps;

            longGapTable = [longGapTable; GapTable];
            allnanPlotData = [allnanPlotData; nanPlotData];
            % ==================================================

            
            % eval(['size(data' num2str(thatTrigger) ')']) % DEBUG


            % Get current trial epoch, dcCorrect, and add it to correct data###
            % NOTE: This step may seem redundant given that Step 4 had a
            % final DC correction, but that was being done on the final
            % data unit level ("All" or "Rec"). We do it again here to
            % ensure that each single trial is DC-corrected. 
            eval(['data' num2str(thatTrigger) ...
                '= cat(3, data' num2str(thatTrigger) ', dcCorrect(xGapsFix));']);
            % eval(['size(data' num2str(thatTrigger) ')']) % DEBUG

            % Add current behav to correct behav###
            eval(['behav' num2str(thatTrigger) ...
                '(end+1, :) = transpose(thatBehav(:));']);

            % Add current sub id to correct subID###
            eval(['subID' num2str(thatTrigger) '{end+1} = thisSubID;']);
        end

        clear that*


    end

    clear THIS this*

end

% =================== NaN Gap Fix plots ====================
tmp  = cellfun(@(x) x(:), allNanGaps, 'UniformOutput', false);  % each cell -> column vector
allGapMsFlat = vertcat(tmp{:});

figHist = plotNanGaps(allGapMsFlat);

if exist('longGapTable','var') && exist('allnanPlotData','var')
    if ismember('z', longGapTable.Properties.VariableNames)
        figSus = plotTopSuspicious(longGapTable, allnanPlotData, 4);
    end
end
% ==========================================================


%% Save outputs

ALLSTIMS = sort(ALLSTIMS);
nStims = length(ALLSTIMS);

% Create output directory if it doesn't exist
if ~exist(outDir, 'dir')
    mkdir(outDir);
    disp(['Created directory ' outDir])
end

% Iterate through the stimuli and save out
disp(' ')
for s = 1:nStims
    thisStimStr = num2str(ALLSTIMS(s));
    eval(['save([outDir filesep ''aggregated' thisStimStr '.mat''], ''data' thisStimStr ''', ''behav' thisStimStr ''', ''subID' thisStimStr ''', ''fs'', ''INFO'', "-v7.3");'])
    eval(['disp([''Saved aggregated' thisStimStr '.mat''])'])
end

disp([newline '~ * ~ * Data aggregation complete * ~ * ~'])
diary off