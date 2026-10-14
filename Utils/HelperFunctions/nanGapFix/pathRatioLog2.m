function [score, det] = pathRatioLog2(fill, histWin)
% PATHRATIOLOG2  Compare the path length of a gap fill with that of its template.
%
%   score = pathRatioLog2(fill, histWin)
%   [score, det] = pathRatioLog2(fill, histWin)
%
% PURPOSE
%   Quantify how much more a filled gap moves than the stretch of real data the
%   fill reproduces. Path length (total variation) is the summed absolute
%   sample-to-sample change, so it rises both with oscillation and with a
%   monotone excursion. Expressed as a base-2 log ratio, so 0 means the fill
%   travels exactly as far as the template, +1 twice as far, -1 half as far.
%
% INPUTS
%   fill    : [1 x gapLen] the filled samples, in forecast order (the first
%             element is the first sample predicted, which for a flipped fill
%             means the series is reversed relative to the recording).
%   histWin : [1 x p] the window the AR model was fitted on, oriented so that
%             histWin(end) is the sample adjacent to the gap. Only its first
%             gapLen samples are used; see DETAILS.
%
% OUTPUTS
%   score : scalar, log2( TV(fill) / TV(template) ), where TV(x) = sum|diff(x)|.
%           NaN if either series is shorter than 2 samples.
%   det   : struct with the terms behind the score:
%             .tvFill    path length of fill
%             .tvTmpl    path length of the template
%             .nStep     number of differences used, gapLen-1
%             .truncated true if gapLen exceeded p and the template had to be
%                        padded (see DETAILS)
%
% DETAILS
%   • The template is histWin(1:gapLen), the START of the fitted window rather
%     than the part touching the gap. arGapFill fits aryule at order p on
%     exactly p samples, so the model order equals the sample count; the
%     resulting forecast reproduces the fitted window from its first sample.
%   • Both series are cut to the same length, so gap length cancels in the
%     ratio and no length normalisation is required.
%   • If gapLen > p the template is padded with its last value and .truncated
%     is set. With the released order p = ceil(max(1.5*gapLen,40)) this cannot
%     occur, since p is always at least 1.5*gapLen.
%   • Both path lengths are floored at eps before dividing, so a perfectly flat
%     template yields a large finite score rather than Inf.
%
% EXAMPLE
%   [score, det] = pathRatioLog2(pPreds, x(idx-p:idx-1));
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
    fill    (1,:) double
    histWin (1,:) double
end

ng = numel(fill);
p  = numel(histWin);
det = struct('tvFill', NaN, 'tvTmpl', NaN, 'nStep', ng - 1, 'truncated', false);
score = NaN;
if ng < 2 || p < 2, return, end

if ng <= p
    tmpl = histWin(1:ng);
else
    % Cannot happen with the released order p = ceil(max(1.5*gapLen,40)), which
    % makes p >= 1.5*gapLen always. Held padded
    % rather than cycled so that if the order rule ever changes the number
    % stays defined and the flag says it happened.
    tmpl = [histWin repmat(histWin(end), 1, ng - p)];
    det.truncated = true;
end

det.tvFill = sum(abs(diff(fill)));
det.tvTmpl = sum(abs(diff(tmpl)));
score = log2(max(det.tvFill, eps) / max(det.tvTmpl, eps));
end
