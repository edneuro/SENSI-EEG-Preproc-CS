function [topTbl, plotPayload, payloadCols] = suspiciousGaps( ...
    xOut, longGaps, fs, fileId, epochId, topK, minGapMs, minContextSec)

% suspiciousGaps (no plotting)

% Inputs:
%   xOut         – [M x N] gap-filled EEG matrix (channels x samples),
%                  output of temporalNaNCorrect. Used to extract signal
%                  context around each gap for ranking and plotting.
%   longGaps     – M×1 cell array from findLongNaNGaps; each cell is a
%                  K×2 matrix of [startIdx, endIdx] pairs for long gaps
%                  in that channel.
%   fs           – scalar sampling rate in Hz.
%   fileId       – scalar file index; written into topTbl for traceability.
%   epochId      – scalar epoch index; written into topTbl for traceability.
%   topK         – (optional) number of top suspicious gaps to return.
%                  Default: 4.
%   minGapMs     – (optional) minimum gap duration (ms) to include in
%                  ranking. Default: 200.
%   minContextSec – (optional) seconds of signal context on each side of
%                   a gap to include in plotPayload. Default: 1.

% Ranks gaps and returns:
%   topTbl      : file, epoch, ch, s, E, L, gap_ms, medAbs, logMedAbs, z
%   plotPayload : Kx12 cell array with everything needed to plot later
%   payloadCols : names for plotPayload columns
%
% plotPayload columns (in order):
% 1 preIdx    (1xP double, sample indices)
% 2 preY      (1xP double)
% 3 gapIdx    (1xG double)
% 4 gapY      (1xG double)
% 5 postIdx   (1xQ double)
% 6 postY     (1xQ double)
% 7 xlines    (1x2 double) [s E]
% 8 xlim      (1x2 double) [ctxStart ctxEnd]
% 9 titleStr  (char)
% 10 xLabel   (char)
% 11 yLabel   (char)
% 12 legend   (1x2 cellstr) e.g., {'signal','gap'}

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

    if nargin < 6 || isempty(topK),          topK = 4;       end
    if nargin < 7 || isempty(minGapMs),      minGapMs = 200; end
    if nargin < 8 || isempty(minContextSec), minContextSec = 1; end

    topTbl = table();
    payloadCols = {'preIdx','preY','gapIdx','gapY','postIdx','postY', ...
                   'xlines','xlim','title','xlabel','ylabel','legend'};
    plotPayload = cell(0, numel(payloadCols));

    [M, N] = size(xOut);
    minGap = ceil(minGapMs/1000 * fs);
    minCtx = ceil(minContextSec * fs);

    % ---------- score gaps ----------
    rows = [];  % [ch s E L medAbs logMedAbs]
    for ch = 1:M
        G = longGaps{ch};
        if isempty(G), continue, end
        for k = 1:size(G,1)
            s = G(k,1); E = G(k,2);
            if s < 1 || E > N || E < s, continue, end
            L = E - s + 1;
            if L < minGap, continue, end
            seg = xOut(ch, s:E);
            if ~any(isfinite(seg)), continue, end
            medA = median(abs(seg), 'omitnan');
            rows = [rows; ch, s, E, L, medA, log10(medA + eps)]; %#ok<AGROW>
        end
    end
    if isempty(rows), return, end

    % ---------- robust z on log-median-abs ----------
    lm  = rows(:,6);
    mu  = median(lm, 'omitnan');
    sig = 1.4826 * median(abs(lm - mu), 'omitnan');
    if ~(isfinite(sig) && sig > 0)
        sig = std(lm, 0, 'omitnan');
        if ~(isfinite(sig) && sig > 0), sig = 1; end
    end
    z = (lm - mu) ./ sig;

    % ---------- sort by z desc, tie-break by length desc ----------
    rowsZ = [rows, z]; % [ch s E L medAbs logMedAbs z]
    [~, ord] = sortrows(rowsZ(:,[7,4]), [-1 -1]);
    rowsZ = rowsZ(ord, :);

    % ---------- top K ----------
    K = min(topK, size(rowsZ,1));
    kept = rowsZ(1:K, :);

    % ---------- context per kept gap ----------
    gap_ms   = 1000 * kept(:,4) / fs;
    ctxStart = zeros(K,1);
    ctxEnd   = zeros(K,1);

    for i = 1:K
        s = kept(i,2); E = kept(i,3); L = kept(i,4);
        preWant  = max(ceil(1.5 * L), minCtx);
        postWant = max(ceil(1.5 * L), minCtx);

        t0 = max(1, s - preWant);
        t2 = min(N, E + postWant);

        preGot  = s - t0;
        postGot = t2 - E;

        missPre  = preWant  - preGot;
        missPost = postWant - postGot;

        if missPre > 0,  t2 = min(N, t2 + missPre);  end
        if missPost > 0, t0 = max(1, t0 - missPost); end

        ctxStart(i) = max(1, t0);
        ctxEnd(i)   = min(N, t2);
    end

    % ---------- build topTbl ----------
    fileCol  = repmat({fileId},  K, 1);
    epochCol = repmat({epochId}, K, 1);
    varNames = {'file','epoch','ch','s','E','L','gap_ms','medAbs','logMedAbs','z'};
    topTbl = table( ...
        fileCol, epochCol, kept(:,1), kept(:,2), kept(:,3), kept(:,4), gap_ms, ...
        kept(:,5), kept(:,6), kept(:,7), 'VariableNames', varNames);

    % ---------- build plotPayload (K x 12 cell array) ----------
    plotPayload = cell(K, numel(payloadCols));
    for i = 1:K
        ch = kept(i,1); s  = kept(i,2); E  = kept(i,3);
        t0 = ctxStart(i);  t2 = ctxEnd(i);

        preIdx  = t0 : max(s-1, t0);
        gapIdx  = s  : E;
        postIdx = min(E+1, t2) : t2;

        preY  = []; postY = [];
        if ~isempty(preIdx),  preY  = xOut(ch, preIdx);  end
        gapY = xOut(ch, gapIdx);
        if ~isempty(postIdx), postY = xOut(ch, postIdx); end

        titleStr = sprintf('File %s | Epoch %s | Ch %d | gap [%d,%d] | %d samp (%.1f ms) | z=%.2f', ...
            toChar(fileId), toChar(epochId), ch, s, E, E-s+1, 1000*(E-s+1)/fs, kept(i,7));
        xLabel = 'sample';
        yLabel = 'amplitude';
        legendCell = {'signal','gap'};

        plotPayload(i, :) = { ...
            preIdx, preY, ...
            gapIdx, gapY, ...
            postIdx, postY, ...
            [s E], [t0 t2], ...
            titleStr, xLabel, yLabel, legendCell};
    end
end

function c = toChar(x)
    if isstring(x) || ischar(x)
        c = char(x);
    elseif isnumeric(x) && isscalar(x)
        c = num2str(x);
    else
        c = '<id>';
    end
end
