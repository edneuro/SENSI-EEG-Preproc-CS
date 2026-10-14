function [xOut, allGapMs, REC] = temporalNaNCorrectDamped(data, fs, epochId, DAMP)
% TEMPORALNANCORRECTDAMPED  Repair NaN gaps in multi-channel EEG, constraining
% forecasts that diverge from the data they reproduce.
%
%   xOut = temporalNaNCorrectDamped(data, fs)
%   [xOut, allGapMs, REC] = temporalNaNCorrectDamped(data, fs, epochId, DAMP)
%
% PURPOSE
%   Fix missing samples (NaNs) in an EEG matrix by:
%     (1) Spline-interpolating small gaps along time per channel,
%     (2) Re-exposing "long" gaps as NaN,
%     (3) AR-forecasting each long gap per channel,
%     (4) Scoring each forecast against the data it reproduces and, when the
%         score is too high, refitting with progressively stronger decay or
%         replacing the forecast with a straight line,
%     (5) Spline-stitching the gap edges for smooth transitions.
%
% INPUTS
%   data    : [M x N] matrix (channels x samples) with NaNs at missing samples.
%   fs      : scalar sampling rate in Hz.
%   epochId : scalar identifier used in console messages. Default 0.
%   DAMP    : struct of settings; any field may be omitted.
%               .t              score at or above which a gap of at least
%                               minMs is reworked. Default 0.30.
%               .tShort         the same, for a gap between minMsShort and
%                               minMs. Default 1.50.
%               .rhoA, .rhoB    pole-shrink factors tried in that order, each
%                               applied to the original coefficients rather
%                               than compounded. Defaults 0.95 and 0.90.
%               .minMs          gaps below this are scored but never modified.
%                               Default 100.
%               .minMsShort     lower bound of the short band. Default 40.
%               .escalateLinear if true, a gap still above threshold after both
%                               factors is replaced by a straight line; if
%                               false the damped forecast is kept. Default true.
%               .enable         if false no gap is modified, and the output
%                               equals temporalNaNCorrect. Default true.
%
% OUTPUTS
%   xOut     : [M x N] matrix with small gaps splined and long gaps filled,
%              with edges re-stitched by spline.
%   allGapMs : every NaN run length in the INPUT, in milliseconds. Unaffected
%              by the repair; intended for the gap-length histogram.
%   REC      : [1 x nGaps] struct array, one element per long gap, in the order
%              the gaps were processed.
%                .ch, .gapNo          channel, and gap index within it
%                .sampStart, .sampEnd gap bounds, as columns of data
%                .gapLen, .gapMs      gap size in samples and milliseconds
%                .branch              'arForward', 'arFlipped' or 'linear'
%                .flipped             true if forecast right-to-left
%                .eligible            true if the gap reaches minMsShort
%                .thr                 threshold applied, NaN if ineligible
%                .tier                0 none, 1 rhoA, 2 rhoB, 3 straight line
%                .rho, .method        factor applied, and its label
%                .scoreRaw            score of the first forecast
%                .score95, .score90   score after each factor, NaN if untried
%                .scoreFinal          score of the samples finally written
%                .tvFill, .tvTmpl     path lengths behind scoreRaw
%                .maxAbsRaw           peak magnitude of the first forecast
%                .maxAbsDamped        peak magnitude after damping
%                .dampFailed          true if a refit returned an unusable fill
%                .fillRaw, .fillFinal forecast before and after, in forecast
%                                     order; both empty for 'linear'
%                .tmplPrime           the reproduced slice, forecast order
%
% DETAILS
%   - Long gap threshold (ms): AR_TIME_GAP (default 5.1 ms).
%   - Stitch size at each end (ms): AR_STICH_GAP (default 3 ms).
%   - AR order p = ceil(max(1.5*gapLen, 40)). The first forecast of every gap
%     comes from arGapFill, so which gaps take the forward, flipped or linear
%     branch is decided exactly as in temporalNaNCorrect.
%   - Scoring uses the raw forecast, before the edge stitch.
%   - Escalation stops as soon as the score falls below the threshold, so a gap
%     is never left above it with a stronger option untried.
%   - A gap replaced by a straight line is marked in that channel's linear-
%     interpolation mask, so no later AR fit in the channel uses it as history.
%   - AR failures are reported as one summary line per epoch rather than one
%     per gap, because a NaN window is usually identical across all channels.
%
% DEPENDENCIES
%   [longGaps, bigGapMask, edgeGapMask] = findLongNaNGaps(data, minGapSamples, stitchGap)
%   [rowOut, pPreds, ~] = arGapFill(rowIn, p, idx, gapLen)
%   [score, det] = pathRatioLog2(fill, histWin)
%   [fill, info] = arGapFillDamped(hist, gapLen, mode, param)
%
% ASSUMPTIONS
%   - Small holes get fixed by the initial spline, so AR seed windows are finite.
%   - Data is [channels x samples].
%
% EXAMPLE
%   [xOut, allGapMs, REC] = temporalNaNCorrectDamped(data, 250, epochId);

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

arguments
    data    (:,:) double
    fs      (1,1) double
    epochId (1,1) double = 0
    DAMP    (1,1) struct = struct()
end

d = struct('t', 0.30, 'tShort', 1.50, 'rhoA', 0.95, 'rhoB', 0.90, ...
    'minMs', 100, 'minMsShort', 40, ...
    'escalateLinear', true, 'enable', true);
for f = fieldnames(d)'
    if ~isfield(DAMP, f{1}), DAMP.(f{1}) = d.(f{1}); end
end
minSamp      = ceil(DAMP.minMs / 1000 * fs);
minSampShort = ceil(DAMP.minMsShort / 1000 * fs);

REC = local_emptyRec();
allGapMs = [];
if ~any(isnan(data(:)))
    xOut = data;
    return
end

[M, N] = size(data);
AR_TIME_GAP  = 5.1;
AR_STICH_GAP = 3;
arSampleGap = ceil(AR_TIME_GAP / 1000 * fs);
arSampleGap = max([arSampleGap, 3]);
arStitchGap = ceil(AR_STICH_GAP / 1000 * fs);
arStitchGap = min([arStitchGap, floor(arSampleGap / 2)]);

[longGaps, bigGapMask, edgeGapMask] = findLongNaNGaps(data, arSampleGap, arStitchGap);

xOut = fillmissing(data, 'spline', 2);
xOut(bigGapMask) = NaN;

fallbackCh = [];        % released AR fallback, collected for one summary
fallbackSamp = [];

rem = isnan(xOut);
if any(rem(:))
    for i = 1:M
        chGaps = longGaps{i};
        N2 = size(chGaps, 1);
        mask_LinearInterp = false(1, N);

        for j = 1:N2
            idx = chGaps(j, 1);
            gapLen = chGaps(j, 2) - idx + 1;
            p = ceil(max([gapLen * 1.5, 40]));
            r = local_newRec(i, j, idx, gapLen, fs);
            goLinear = false;

            try
                if any(mask_LinearInterp(idx-p : idx-1))
                    error('AR history was a previous linear interpolation.')
                end
                [xOut(i,:), pPreds, ~] = arGapFill(xOut(i,:), p, idx, gapLen);
                r.branch = 'arForward';
                hist = xOut(i, idx-p : idx-1);
                [xOut(i,:), r, goLinear] = local_gate(xOut(i,:), hist, ...
                    pPreds(:).', idx, gapLen, r, DAMP, minSamp, minSampShort, false);

            catch
                try
                    nSamp = size(xOut, 2);
                    gap_end = chGaps(j, 2);
                    idx_flip = nSamp - gap_end + 1;
                    tmp = flip(xOut(i,:));
                    if any(mask_LinearInterp(gap_end+1 : gap_end+p))
                        error('AR history was a previous linear interpolation.')
                    end
                    [tmpFilled, pPreds, ~] = arGapFill(tmp, p, idx_flip, gapLen);
                    r.branch = 'arFlipped';
                    hist = tmpFilled(idx_flip-p : idx_flip-1);
                    [tmpFilled, r, goLinear] = local_gate(tmpFilled, hist, ...
                        pPreds(:).', idx_flip, gapLen, r, DAMP, minSamp, minSampShort, true);
                    xOut(i,:) = flip(tmpFilled);

                catch
                    % Counted, not printed. A dropped window is typically
                    % missing in every channel at once, so a per-gap message
                    % repeats once per channel for a single bad window. One
                    % summary line per epoch is printed after the loops.
                    fallbackCh(end+1) = i; %#ok<AGROW>
                    fallbackSamp(end+1) = idx; %#ok<AGROW>
                    r.branch = 'linear';
                    xOut(i,:) = local_lineFill(xOut(i,:), idx, gapLen, epochId, i, j);
                    mask_LinearInterp(idx:idx+gapLen-1) = true;
                end
            end

            % Step 3 of the gate: the AR fill is still above threshold after
            % both shrinkages, so replace it with a straight line. Done here,
            % in the original frame, and masked so no later AR fit uses it.
            if goLinear
                xOut(i,:) = local_lineFill(xOut(i,:), idx, gapLen, epochId, i, j);
                mask_LinearInterp(idx:idx+gapLen-1) = true;
                r.tier = 3;
                r.method = 'linear';
                r.rho = NaN;
                fo = xOut(i, idx:idx+gapLen-1);
                if r.flipped, fo = fliplr(fo); end
                r.scoreFinal = pathRatioLog2(fo, r.tmplPrime);
                r.fillFinal = fo;
            end
            REC(end+1) = r; %#ok<AGROW>
        end
    end

    xOut(edgeGapMask) = NaN;
    xOut = fillmissing(xOut, 'spline', 2);
end

% One line for the whole epoch, in place of the released per-gap message.
if ~isempty(fallbackCh)
    fprintf(['Epoch %d: released AR fallback on %d gap(s), %d channel(s), ' ...
        '%d distinct window(s). Linear interpolation used.%s'], ...
        epochId, numel(fallbackCh), numel(unique(fallbackCh)), ...
        numel(unique(fallbackSamp)), newline);
end

% --- released tail: NaN run lengths, for the gap histogram ---
% Measured on the INPUT, so the gate cannot change it.
allGapLens = cell(M, 1);
for ch = 1:M
    isn = isnan(data(ch, :));
    if any(isn)
        d2 = diff([0, isn, 0]);
        st = find(d2 == 1);
        en = find(d2 == -1) - 1;
        allGapLens{ch} = en - st + 1;
    end
end
allGapLens = cell2mat(allGapLens);
allGapMs = allGapLens * 1000 / fs;
end


function [row, r, goLinear] = local_gate(row, hist, fillRaw, idx, gapLen, r, ...
    DAMP, minSamp, minSampShort, flipped)
%LOCAL_GATE  Score the raw forecast, then escalate until it clears threshold.
%  row is the single channel in whatever frame the caller used, so idx is
%  already correct for the flipped branch.
goLinear = false;
[r.scoreRaw, det] = pathRatioLog2(fillRaw, hist);
r.tvFill = det.tvFill;
r.tvTmpl = det.tvTmpl;
r.maxAbsRaw = max(abs(fillRaw));
r.fillRaw = fillRaw;
r.tmplPrime = hist(1:min(gapLen, numel(hist)));
r.flipped = flipped;
r.scoreFinal = r.scoreRaw;
r.fillFinal = fillRaw;
r.method = 'none';

% Which threshold applies, by length band.
if gapLen >= minSamp
    thr = DAMP.t;
elseif gapLen >= minSampShort
    thr = DAMP.tShort;
else
    thr = NaN;              % too short to act on at all
end
r.eligible = isfinite(thr);
r.thr = thr;

if ~DAMP.enable || ~r.eligible || ~isfinite(r.scoreRaw) || r.scoreRaw < thr
    return
end

% Step 1 and 2: stronger single decays, each from the ORIGINAL coefficients.
attempts = {DAMP.rhoA, 1, 'score95'; DAMP.rhoB, 2, 'score90'};
for a = 1:size(attempts, 1)
    rho = attempts{a, 1};
    [fillD, ~] = arGapFillDamped(hist, gapLen, 'poleShrink', rho);
    fillD = fillD(:).';
    if numel(fillD) ~= gapLen || any(~isfinite(fillD))
        r.dampFailed = true;
        continue
    end
    sc = pathRatioLog2(fillD, hist);
    r.(attempts{a, 3}) = sc;
    if ~isfinite(sc), continue, end
    row(idx : idx+gapLen-1) = fillD;
    r.tier = attempts{a, 2};
    r.rho = rho;
    r.scoreFinal = sc;
    r.fillFinal = fillD;
    r.maxAbsDamped = max(abs(fillD));
    r.method = sprintf('rho%.2f', rho);
    if sc < thr
        return
    end
end

% Step 3: both shrinkages left it above threshold.
if DAMP.escalateLinear
    goLinear = true;
end
end


function row = local_lineFill(row, idx, gapLen, epochId, ch, gapNo)
%LOCAL_LINEFILL  The released straight-line fill, including its NaN warning.
pL = linspace(row(idx-1), row(idx+gapLen), gapLen+2);
if any(isnan(pL))
    warning(['LINEAR_INTERP_FAILURE: Epoch %d, Ch %d, Gap %d. ' ...
        'Cannot fill gap safely.'], epochId, ch, gapNo);
end
row(idx:idx+gapLen-1) = pL(2:end-1);
end


function R = local_emptyRec()
R = local_newRec(0, 0, 0, 0, 1);
R = R([]);
end


function r = local_newRec(ch, gapNo, idx, gapLen, fs)
r = struct( ...
    'ch', ch, 'gapNo', gapNo, 'sampStart', idx, 'sampEnd', idx + gapLen - 1, ...
    'gapLen', gapLen, 'gapMs', gapLen * 1000 / fs, 'branch', '', ...
    'flipped', false, 'eligible', false, 'tier', 0, 'rho', NaN, ...
    'method', '', 'scoreRaw', NaN, 'score95', NaN, 'score90', NaN, ...
    'scoreFinal', NaN, 'thr', NaN, 'tvFill', NaN, 'tvTmpl', NaN, ...
    'maxAbsRaw', NaN, ...
    'maxAbsDamped', NaN, 'dampFailed', false, 'fillRaw', [], ...
    'fillFinal', [], 'tmplPrime', []);
end
