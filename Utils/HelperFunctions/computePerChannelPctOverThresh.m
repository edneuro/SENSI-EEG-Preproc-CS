function [pctOverThresh, iMatrix] = computePerChannelPctOverThresh(xIn, thresh)
% [pctOverThresh, iMatrix] = computePerChannelPctOverThresh(xIn, thresh)
% -------------------------------------------------
% This matrix computes the percent of (magnitude) values in a matrix that
% are over a specified threshold, on a per-channel (row) basis. 
%
% Inputs (required)
% - xIn: A data matrix. The input data are assumed to be space x time since
%   the function returns a percent over threshold for each row (channel). 
% - thresh: A threshold. Flagged values will be strictly greater than this
%   threshold (not geq).
%
% Outputs
% - pctOverThresh: The percent over threshold for each row (channel) of the
%   input data. 
% - iMatrix: The indicator matrix from which the percentage was computed. 

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

%% Check inputs

assert(nargin == 2, 'This function requires two inputs: A data matrix and a threshold.')

%% Do the stuff

% Create an indicator matrix to capture values of the input whose magnitude
% (absolute value) strictly exceed the specified threshold. 
iMatrix = abs(xIn) > thresh; 
pctOverThresh = 100 * sum(iMatrix, 2) / size(iMatrix, 2);