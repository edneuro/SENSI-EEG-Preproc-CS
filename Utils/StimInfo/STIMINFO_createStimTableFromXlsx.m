% STIMINFO_createStimTableFromXlsx.m
% ----------------------------------
% Create and save out a .mat **TABLE** with stimulus information.
%
% How this script works: 
% 1. Load in STIMINFO.xlsx. The columns are as follows:
%   - Col 1: trigger (e.g., 102, 201 numeric)
%   - Col 2: wavFn (e.g., '1_FB_P.wav' string in cell array)
%   - Col 3: wavFs (~~initialized as all 0~~ numeric)
%   - Col 4: wavLenSamp (~~initialized as all 0~~ numeric)
%   - Col 5: wavSec (~~initialized as all 0~~ numeric)
%   - Col 6: sTrigger (e.g., 'S101' string in cell array)
%   - Col 7: blockType (e.g., 'FB', 'CNS' string in cell array)
%
% 2. Iterate through each .wav file and fill in ~~ fields
%
% 3. Save output
%   - Output filename: STIMINFO.mat
%   - Output variable STIMINFO: This is the main table as described above
%   - Output variable INFO: Information about the script call (not data)
%
% We no longer store fs=1000 or assumed D number of samples since this may
% vary depending on the analysis. This can be done during EEG preprocessing
% through a straightforward dimensional analysis inolving wavFs and 
% wavLenSamp.

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

clear all; close all; clc

% Original wav directory from Feb 2023
% wavDir = '/Volumes/LaPuffin/EdNeuroData/FBFP1_Literary/WavMono';

% Updated wav directory from Dec 2023 (merge with full set of stimuli)
wavDir = '/Volumes/LaPuffin/EdNeuroData/ISCPreproc_WuTsai2024/WavMono'; 
stimDir = '/Volumes/LaPuffin/EdNeuroData/ISCPreproc_WuTsai2024/Repo-ISCPreproc-WuTsai2024/StimInfo';
fnIn = 'STIMINFO.xlsx';
fnOut = 'STIMINFO.mat';

INFO.runDate = datestr(now, 'yyyymmdd');
INFO.runBy = 'bk';
INFO.wavDir = wavDir;
INFO.stimDir = stimDir;
INFO.fnIn = fnIn;
INFO.fnOut = fnOut;

disp(['~ * ~ * Starting createStimStruct * ~ * ~'])

%% Step 1: Load the Excel spreadsheet

STIMINFO = readtable([stimDir filesep fnIn], 'Sheet', 'STIMINFO');
STIMINFO.trigger = str2double(STIMINFO.trigger); % Triggers should be numeric
% STIMINFO(1:10,:)
nWav = size(STIMINFO, 1);
disp(['Loaded ' fnIn ': ' num2str(nWav) ' audio files.' newline])

INFO.nWav = nWav;

%% Step 2: Iterate through the table and fill in remaining fields

for i = 1:nWav
    
    % Get and display current trigger and fnIn
    thisTrigger = STIMINFO.trigger(i);
    thisWavFn = STIMINFO.wavFn{i};
    disp(['File ' num2str(i) '/' num2str(nWav) ...
        ': Trigger ' num2str(thisTrigger) ', file ' thisWavFn])
    
    [thisY, thisFs] = audioread([wavDir filesep thisWavFn]);
    STIMINFO.wavFs(i) = thisFs;
    STIMINFO.wavLenSamp(i) = length(thisY);
    STIMINFO.wavSec(i) = length(thisY) / thisFs;
    disp(['fs=' num2str(thisFs) ', ' ...
        num2str(length(thisY)) ' time samples (' ...
        sprintf('%.4f', STIMINFO.wavSec(i)) ' sec).' newline])
    
    clear this*
    
end

%% Save output

save([stimDir filesep fnOut], 'STIMINFO', 'INFO')

disp(['~ * ~ * Ending createStimStruct * ~ * ~'])