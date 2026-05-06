function [xOut, pPreds, a] = arGapFill(xIn, p, idx, gapLen)
% arGapFill   Fill a single-channel NaN gap using an AR(p) model
%
%   [xOut, pPreds, a] = arGapFill(xIn, p, idx, gapLen)
%
%   Inputs:
%     xIn    – 1×N or N×1 vector with NaNs marking a single gap
%     p      – AR model order (must have at least p clean samples before idx)
%     idx    – index of first NaN to fill
%     gapLen – number of samples in the gap
%
%   Outputs:
%     xOut   – same shape as xIn, with xOut(idx:idx+gapLen-1) replaced by AR forecasts
%     pPreds – 1×gapLen vector of the predicted samples
%     a      – 1×(p+1) AR coefficient vector from aryule

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

    % ensure column
    wasRow = isrow(xIn);
    x = xIn(:);

    assert(idx > p, 'idx must be > p (need %d samples of history)', p);
    % assert(idx+gapLen-1 <= N, 'Gap exceeds signal length.'); % this is not right

    % extract and check history
    hist = x(idx-p : idx-1); 
    assert(~any(isnan(hist)), 'History contains NaNs; cannot fit AR.');

    % AR failure check - ill condition
    failure_threshold = 1.5*max(abs(hist));

    % demean and fit AR
    mu = mean(hist);
    y  = hist - mu;
    a  = aryule(y, p);              % a(1)=1, a(2..)=–phi

    % forecast gapLen steps
    pPreds = zeros(gapLen,1);

    for k = 1:gapLen
        seg    = y(end-p+1:end);
        pred_d = -a(2:end) * seg;   % one-step forecast (demeaned)
        y(end+1) = pred_d;
        pPreds(k) = pred_d + mu;    % re-add mean

        % --- FAILURE CHECK ---
        % Is the gap prediction ill conditioned? Do Linear Interpolation
        if abs(pPreds(k)) > failure_threshold
            error('AR_FAILURE. Ill conditioned');
        end
    end

    % insert predictions
    x(idx : idx+gapLen-1) = pPreds;

    % restore shape
    if wasRow
        xOut   = x.';
        pPreds = pPreds.';
    else
        xOut   = x;
        pPreds = pPreds;
    end
end
