function [xOut, INFO] = prepAggregatedData(xIn, doDCCorrect, doNanCorrect, doPermuteDims)
% [xOut, INFO] = prepAggregatedData(xIn, doDCCorrect, doNanCorrect, doPermuteDims)
% -----------------------------------------------------------------------
% This function takes in an already-loaded 3D space x time x trial matrix 
% of aggregated data from the SENSI-EEG-Preproc-CS pipeline and can perform 
% the following steps on each trial of data in the matrix:
%   1 - DC correction: Subtract the mean from each channel, ignoring NaNs
%       if any are present.
%   2 - TEMPORALLY interpolate any NaNs in the data matrix. For now, we
%       assume that imputation of missing values was already attempted
%       using spatial interpolation of neighbors. This step handles any
%       remaining NaNs, i.e., at time samples were all channels were NaN
%       and hence could not be interpolated from spatial neighbors.
%   3 - Transpose the trial matrix to be time x space so that the 
%       aggregated output will be time x space x trial for input to e.g., 
%       Reliable Components Analysis (RCA).
%
% Inputs (required)
%   - xIn: A 3D space x time x trial matrix of the kind output by the 
%       preproc_5_aggregateData.m function of the SENSI-EEG-Preproc-CS
%       pipeline.
%
% Inputs (optional)
%   - doDCCorrect: Boolean of whether to DC correct the data. If empty or not
%       entered, will default to true.
%   - doNanCorrect: Boolean of whether to temporally interpolate any NaNs. If
%       empty or not entered, will default to true.
%   - doPermuteDims: Boolean of whether to permute the data dimensions from
%       space x time x trial to time x space x trial ([2 1 3]). If empty or
%       not entered, will default to true. 
%
% Outputs
% - xOut: The processed output data matrix. Will have the same number of
%   elements as the input matrix, although dimensions will be different if
%   doPermuteDims was set to TRUE.
% - INFO: Struct containing input parameters of the function call.

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

%% Check inputs and assign defaults if needed

% Input 1: Make sure data matrix is input
assert(nargin >= 1, 'At least one input is needed, the input data xIn.')

% Input 2: Set default for doDCCorrect if needed
if nargin < 2 || isempty(doDCCorrect), doDCCorrect = true; end

% Input 3: Set default for doNanCorrect if needed
if nargin < 3 || isempty(doNanCorrect), doNanCorrect = true; end

% Input 4: Set default for doPermuteDims if needed
if nargin < 4 || isempty(doPermuteDims), doPermuteDims = true; end

%% Create and fill in INFO struct

% Name of data matrix input variable, if the first input was a variable
INFO.inputVarName = inputname(1);

% Optional parameters
INFO.doDCCorrect = doDCCorrect;
INFO.doNanCorrect = doNanCorrect;
INFO.doPermuteDims = doPermuteDims;

% Date/time stamp for the function call
INFO.functionCallDateTime = thisDateTime(1);

%% Main data processing

% Get number of trials in the 3D matrix
nTrials = size(xIn, 3); 

% Iterate through each trial and do things
for i = 1:nTrials
    
    % Get current trial slice
    currXIn = xIn(:, :, i); 

    % DC correct if requested
    if doDCCorrect, currXIn = dcCorrect(currXIn); end

    % NaN correct if requested
    %%%% ---> Amilcar, add call to your function below <--- %%%%
    % if doNanCorrect, currXIn = TEMPORAL INTERPOLATION FUNCTION NAME (currXIn); end

    % Permute dimensions (i.e., transpose) if requested
    if doPermuteDims, currXIn = currXIn.'; end

    % Add this to the output data matrix
    xOut(:, :, i) = currXIn;

    % Clear temp variable
    clear currXIn

end