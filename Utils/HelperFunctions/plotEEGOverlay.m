function plotEEGOverlay(x, vertLinePos)
% plotEEGOverlay(x, vertLinePos)
% ----------------------------------------
% This function plots the specified data and optional vertical lines in the
% current axis.
%
% Inputs
% - x (required): Space-by-time data matrix (will be transposed by this
%   function for plotting).
% - vertLinePos (optional): Vector of x-values at which vertical reference
%   lines (for e.g., trial boundaries) should be plotted. If empty or not
%   entered, no lines will be plotted.

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

%% Validate inputs

assert(nargin > 1, 'This function requires at least one input (the space x time data matrix).')

if nargin < 2 || isempty(vertLinePos), vertLinePos = []; end

%% Do the plot

% Plot the data overlay
p = plot(x'); 
xlim('tight');
box off;

% If specified, plot the vertical lines
yl = get(gca, 'ylim');
grayCol = [.5 .5 .5];
for i = 1:length(vertLinePos)
    hold on
    % xline(vertLinePos(i), 'color', grayCol, 'linewidth', 1.5);
    xline(vertLinePos(i), ':k', 'linewidth', 1.5);
end

% Move data to top (doesn't seem to be quite doing this...) 
uistack(p, 'top');