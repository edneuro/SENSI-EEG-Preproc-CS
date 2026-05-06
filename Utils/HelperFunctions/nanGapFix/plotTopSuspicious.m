function fig = plotTopSuspicious(topTbl, plotPayload, topK, perChannel)
% plotTopSuspicious
% Plot the most suspicious entries using the pre-packed plotPayload
%
% Inputs
%   topTbl        : table with at least vars {'file','epoch','ch','s','E','L','z'}
%   plotPayload   : Nx12 cell array (from suspiciousGaps)
%   payloadCols   : 1x12 cellstr with column names for plotPayload
%   topK          : number of subplots (default 4)
%   perChannel    : if true, pick worst gap per channel, then top-K channels
%
% Output
%   fig           : figure handle

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

payloadCols = {'preIdx','preY','gapIdx','gapY','postIdx','postY', ...
               'xlines','xlim','title','xlabel','ylabel','legend'};

    if nargin < 4 || isempty(topK),     topK = 4;      end
    if nargin < 5 || isempty(perChannel), perChannel = false; end

    % Safety: align sizes
    assert(height(topTbl) == size(plotPayload,1), ...
        'topTbl rows must align with plotPayload rows.');

    % Pick indices to plot
    if perChannel
        % worst gap per channel by z
        [~, ord] = sort(topTbl.z, 'descend');
        seen = false(max(topTbl.ch),1);
        selIdx = [];
        for k = 1:numel(ord)
            ch = topTbl.ch(ord(k));
            if ~seen(ch)
                selIdx(end+1) = ord(k); %#ok<AGROW>
                seen(ch) = true;
                if numel(selIdx) >= topK, break, end
            end
        end
    else
        % top-K by z (ties already broken in suspiciousGaps by length)
        [~, ord] = sort(topTbl.z, 'descend');
        selIdx = ord(1:min(topK, numel(ord)));
    end

    % Payload column indices
    pPreIdx  = find(strcmp(payloadCols,'preIdx'));
    pPreY    = find(strcmp(payloadCols,'preY'));
    pGapIdx  = find(strcmp(payloadCols,'gapIdx'));
    pGapY    = find(strcmp(payloadCols,'gapY'));
    pPostIdx = find(strcmp(payloadCols,'postIdx'));
    pPostY   = find(strcmp(payloadCols,'postY'));
    pXlines  = find(strcmp(payloadCols,'xlines'));
    pXlim    = find(strcmp(payloadCols,'xlim'));
    pTitle   = find(strcmp(payloadCols,'title'));
    pXlab    = find(strcmp(payloadCols,'xlabel'));
    pYlab    = find(strcmp(payloadCols,'ylabel'));
    pLegend  = find(strcmp(payloadCols,'legend'));

    % Figure
    fig = figure('Name', sprintf('Top %d suspicious %s', numel(selIdx), ...
        tern(perChannel,'channels','gaps')));

    for i = 1:numel(selIdx)
        r = selIdx(i);
        preIdx  = plotPayload{r, pPreIdx};
        preY    = plotPayload{r, pPreY};
        gapIdx  = plotPayload{r, pGapIdx};
        gapY    = plotPayload{r, pGapY};
        postIdx = plotPayload{r, pPostIdx};
        postY   = plotPayload{r, pPostY};
        xlines  = plotPayload{r, pXlines};
        xlimv   = plotPayload{r, pXlim};
        titleS  = plotPayload{r, pTitle};
        xLab    = plotPayload{r, pXlab};
        yLab    = plotPayload{r, pYlab};
        legCell = plotPayload{r, pLegend};

        subplot(numel(selIdx), 1, i); hold on
        if ~isempty(preIdx),  plot(preIdx,  preY, 'k-'); end
        plot(gapIdx,  gapY,  'r-', 'LineWidth', 1.25);
        if ~isempty(postIdx), plot(postIdx, postY, 'k-'); end
        if ~isempty(xlines)
            xline(xlines(1),'k--'); xline(xlines(2),'k--');
        end
        grid on
        if ~isempty(xlimv), xlim(xlimv); end

        % If you prefer a deterministic title, override titleS here:
        % t = sprintf('File %s | Epoch %s | Ch %d | z=%.2f | L=%d', ...
        %     string(topTbl.file(r)), string(topTbl.epoch(r)), topTbl.ch(r), topTbl.z(r), topTbl.L(r));
        title(titleS);
        xlabel(xLab); ylabel(yLab);
        if ~isempty(legCell) && numel(legCell)>=2
            legend(legCell{:}, 'Location','best');
        end
    end

    % Optional suptitle:
    % sgtitle(sprintf('Top %d suspicious %s', numel(selIdx), tern(perChannel,'channels','gaps')));
end

function out = tern(cond, a, b)
    if cond, out = a; else, out = b; end
end
