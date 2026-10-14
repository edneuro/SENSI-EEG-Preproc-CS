function [fill, info] = arGapFillDamped(hist, gapLen, mode, param)
% ARGAPFILLDAMPED  AR-forecast a gap with an optional constraint on divergence.
%
%   fill = arGapFillDamped(hist, gapLen)
%   fill = arGapFillDamped(hist, gapLen, mode, param)
%   [fill, info] = arGapFillDamped(...)
%
% PURPOSE
%   Produce gapLen forecast samples from a window of history, the same way
%   arGapFill does, with an optional mode that limits how far the forecast can
%   run away from the data. Unlike an amplitude cap it always returns a fill of
%   the requested length and never raises an error, so the caller does not fall
%   through to another branch.
%
% INPUTS
%   hist   : [1 x p] the history the model is fitted on. The AR order is p,
%            i.e. numel(hist); hist(end) is the sample adjacent to the gap.
%            Must contain no NaN.
%   gapLen : scalar, how many samples to forecast.
%   mode   : char, one of
%              'none'       (default) plain AR forecast, no constraint
%              'poleShrink' multiply coefficient k by param^(k-1) before
%                           forecasting, which moves every pole of the fitted
%                           model radially inward by param, so the forecast
%                           decays geometrically instead of sustaining
%              'clampFeed'  forecast normally, but limit any sample exceeding
%                           param*max(abs(hist)) and feed the limited value
%                           back into the model state
%   param  : scalar, default 0.99. The shrink factor for 'poleShrink', or the
%            multiple of max(abs(hist)) at which 'clampFeed' limits.
%
% OUTPUTS
%   fill : [1 x gapLen] forecast samples, in forecast order.
%   info : struct describing what was applied:
%            .mode       the mode used
%            .param      the parameter used
%            .nClamped   samples limited ('clampFeed' only, else 0)
%            .poleRadius largest pole magnitude of the coefficients actually
%                        used, so the effect of shrinkage is visible
%
% DETAILS
%   • The history is demeaned before fitting and the mean is added back to each
%     forecast sample, as in arGapFill.
%   • 'poleShrink' leaves the first coefficient untouched (param^0 = 1), so only
%     the pole radii change, not the overall gain.
%   • With 'none' and the same history, the forecast matches arGapFill, except
%     that no failure threshold is applied and no error is raised.
%
% DEPENDENCIES
%   a = aryule(y, p)
%
% EXAMPLE
%   [fill, info] = arGapFillDamped(x(idx-p:idx-1), gapLen, 'poleShrink', 0.95);
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

arguments
    hist   (1,:) double
    gapLen (1,1) double
    mode   (1,:) char = 'none'
    param  (1,1) double = 0.99
end
p = numel(hist);
mu = mean(hist);
yv = (hist - mu).';
a  = aryule(yv, p);

if strcmp(mode, 'poleShrink')
    a = a .* (param .^ (0:numel(a)-1));
end

thr = param * max(abs(hist));
fill = zeros(1, gapLen);
nClamp = 0;
for k = 1:gapLen
    seg = yv(end-p+1:end);
    pd  = -a(2:end) * seg;
    v   = pd + mu;
    if strcmp(mode, 'clampFeed') && abs(v) > thr
        v  = sign(v) * thr;
        pd = v - mu;              % feed the CLAMPED value back into the state
        nClamp = nClamp + 1;
    end
    yv(end+1) = pd;                                                 %#ok<AGROW>
    fill(k) = v;
end
info = struct('mode', mode, 'param', param, 'nClamped', nClamp, ...
              'poleRadius', max(abs(roots(a))));
end
