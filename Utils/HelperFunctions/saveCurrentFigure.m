function saveCurrentFigure(pathOut, fnOut, saveSize, h, printMsg)
% saveCurrentFigure(pathOut, fnOut, saveSize, h, printMsg)
% --------------------------------------------------------
% This function saves out the current (or specified figure) with
% customizable specifications.
%
% Inputs (all optional):
% - pathOut: Output path in which to save the figure. If empty or not
%   entered, this value will default to pwd. 
% - fnOut: Output figure filename including full path and extension 
%   (e.g., '.png'). If empty or not entered, the function will save out the 
%   figure as 'saveCurrentFigure_yyyymmdd_HHMM.png' in the current
%   working directory. 
% - saveSize: 2-element vector specifying the width and height of the
%   figure to be saved. If empty or not specified, the figure will be saved
%   at its current width and height as indexed by get(gcf,
%   'PaperPosition').
% - h: Figure handle. If empty or not specified, will default to current
%   figure (gcf).
% - printMsg: Whether to print a message that the figure has been saved
%   out. If empty or not specified, will default to TRUE.

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% Parse through the inputs

% Input 1: Assign default output path if not specified
if nargin < 1 || isempty(pathOut), pathOut = pwd; end

% Input 2: Assign default output filename if not specified
if nargin < 2 || isempty(fnOut)
    fnOut = ['saveCurrentFigure_' thisDateTime '.png'];
end

% Input 3: Skip for now

% Input 4: Assign figure handle if not specified
if nargin < 4 || isempty(h), h = gcf; end

% Input 5: Print message at end if not specified
if nargin < 5 || isempty(printMsg), printMsg = 1; end

%% Do the stuff

% Set the figure save size if it is specified
if exist('saveSize', 'var') && ~isempty(saveSize)
    assert(length(saveSize) == 2, ['The input ''saveSize'' should be a ' ...
        '2-element vector specifying the width and height of the saved figure.'])
    setFigureSaveSize(saveSize(1), saveSize(2));
end

% Save the figure
saveas(h, [pathOut filesep fnOut])

% Print message if specified
if printMsg
    disp(['\ * \ Saved ' fnOut ' / * /'])
end



