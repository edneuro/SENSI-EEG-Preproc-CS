function [fig, figDrop] = plotNanGaps(allNanGaps, dropped)

% fig = plotNanGaps(allNanGaps)
% [fig, figDrop] = plotNanGaps(allNanGaps, dropped)
% ------------------------------------------
% Plots a histogram of NaN gap lengths across all channels. If the list of
% dropped trials is given, also plots which trials were dropped in a
% second figure.
%
% Called from preproc_5_aggregateData.m after all files are processed.
% There, a trial is dropped when the NaN gap fix (temporalNaNCorrectDamped)
% fails for it; the trial is left out of the outputs, and its gaps are not
% included in the histogram.
%
% Input:
%   allNanGaps - numeric vector of NaN gap lengths in milliseconds,
%                pooled across all channels and recordings
%   dropped    - (optional) struct array of dropped trials, one element
%                per trial (DROPPED in preproc_5_aggregateData.m). Fields
%                used here:
%                  fName   - name of the input file the trial came from
%                  trigger - stimulus number of the trial
%                  trial   - row of the trial in that file's table T
%                Other fields (e.g., errMsg, errWhere) are ignored here;
%                the reason for each drop is printed in the log.
%
% Output:
%   fig     - handle to the histogram figure ('NaN gap length histograms')
%   figDrop - handle to the dropped-trials figure ('Dropped trials');
%             empty if 'dropped' is not given
%
% Dropped-trials figure:
%   - One row per file (the '_finalAll.mat' / '_finalRec.mat' suffix is
%     removed from the label) and one column per stimulus. Only files and
%     stimuli with at least one dropped trial are shown.
%   - A dot marks each file/stimulus with dropped trials, labelled with
%     the trial numbers (e.g., '11' or '12,35').
%   - The title gives the total number of dropped trials.
%   - If 'dropped' is empty, the figure says 'No trials dropped'.
%

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

fig = figure('Name','NaN gap length histograms');
% All gaps (linear bins)
histogram(allNanGaps, 'BinMethod','sturges');
grid on;
xlabel('Gap length (ms)'); ylabel('Count');
title(sprintf('All NaN gaps (All Channels) = %d', numel(allNanGaps)));

% Dropped trials
figDrop = [];
if nargin < 2, return, end
figDrop = figure('Name','Dropped trials');
if isempty(dropped)
    axis off;
    text(0.5, 0.5, 'No trials dropped', 'HorizontalAlignment','center');
else
    files = regexprep({dropped.fName}, '_final(All|Rec)\.mat$', '');
    [uFile, ~, iFile] = unique(files);
    [uStim, ~, iStim] = unique([dropped.trigger]);
    [cells, ~, iCell] = unique([iStim(:) iFile(:)], 'rows');
    scatter(cells(:,1), cells(:,2), 30, 'filled'); hold on;
    for c = 1:size(cells,1)
        text(cells(c,1) + 0.12, cells(c,2), ...
            strjoin(string(sort([dropped(iCell == c).trial])), ","), 'FontSize', 8);
    end
    hold off; grid on; box on;
    xlim([0.5 numel(uStim) + 0.5]); ylim([0.5 numel(uFile) + 0.5]);
    set(gca, 'XTick', 1:numel(uStim), 'XTickLabel', string(uStim), ...
        'YTick', 1:numel(uFile), 'YTickLabel', uFile, ...
        'TickLabelInterpreter', 'none', 'YDir', 'reverse');
    xlabel('Stimulus'); ylabel('File');
end
title(sprintf('Dropped trials: %d (labels = trial numbers; reasons in the log)', numel(dropped)));

end