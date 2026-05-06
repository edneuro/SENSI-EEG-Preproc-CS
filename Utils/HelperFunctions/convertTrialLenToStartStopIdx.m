function startStopIdx = convertTrialLenToStartStopIdx(trialLens, totalLen)
% startStopIdx = convertTrialLenToStartStopIdx(trialLens)
% -------------------------------------------------------------------
% This function takes in a vector of trial lengths and converts it to a 
% matrix of start and stop indices. These indices can then be used to epoch
% concatenated trials.
%
% Inputs
% - trialLens(required): Vector of trial lengths. Can be a row or column.
% - totalLen (optional): Total length of data. If entered, the function
%   will assert that the last entry in the output matrix is equal to this.
%   Can be useful to confirm proper epoching of a concatenated matrix.
%
%
% Ouput
% startStopIdx: nTrial x 2 matrix. Each row contains the sample index of
% the start and stop, assuming all trials were concatenated into a single
% matrix. 
%
% Example function call
%   trialLens = [5 100 23];
%   startStopIdx = convertTrialLenToStartStopIdx(trialLens)

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

%% Check for required input

assert(nargin >= 1, 'One input is required: Vector of trial lengths.')

%% Create the matrix from the input vector

trialLens = trialLens(:);
nTrials = length(trialLens);
startStopIdx = nan(nTrials, 2);

% Start with column 2: Cumulative total number of samples
startStopIdx(:, 2) = cumsum(trialLens);

% Column 1 continues where each previous row left off
startStopIdx(1, 1) = 1;
startStopIdx(2:end, 1) = startStopIdx(1:(end-1), 2) + 1;

%% Confirm total length if two inputs were given

if nargin == 2
    assert(isequal(startStopIdx(end, end), totalLen), ...
        ['Last entry of start-stop matrix (' num2str(startStopIdx(end, end)) ...
        ') does not equal specified total length (' num2str(totalLen) ')!'])
end