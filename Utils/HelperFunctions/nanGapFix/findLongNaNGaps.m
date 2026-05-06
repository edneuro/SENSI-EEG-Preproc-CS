function [longGaps, bigGapMask, edgeGapMask] = findLongNaNGaps(data, minGapSamples, stitchGap)
% FINDLONGNANGAPS  Identify NaN stretches ≥ minGapSamples in each channel
%                  and return a mask of those long gaps.
%
%   [longGaps, bigGapMask] = findLongNaNGaps(data, minGapSamples)
%
%   Inputs:
%     data           – M×N matrix (channels × samples), may contain NaNs
%     minGapSamples  – minimum gap duration in samples (integer)
%     stitchGap      – number of samples at each end of a long gap to mark
%
%   Outputs:
%     longGaps       – M×1 cell array; longGaps{ch} is K×2 array of 
%                      [startIdx, endIdx] for each of the K gaps in channel ch
%                      whose length ≥ minGapSamples.
%     bigGapMask     – M×N logical, true for samples belonging to any such
%                      “long” gap.
%     edgeGapMask    – M×N logical, true for the stitchGap samples at each
%                      end of every long gap (used for spline re-stitching
%                      after AR forecasting).

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

    [M, N] = size(data);
    longGaps   = cell(M,1);
    bigGapMask = false(M, N);
    edgeGapMask = false(M, N);


    for ch = 1:M
        x    = data(ch, :);
        isn  = isnan(x);
        d    = diff([0, isn, 0]);       % pad so runs at edges count
        starts = find(d==1);            % where each NaN-run starts
        ends   = find(d==-1)-1;         % where each NaN-run ends

        lens = ends - starts + 1;       % length of each run
        keep = lens >= minGapSamples;   % which runs are “big”

        % record the start/end pairs
        longGaps{ch} = [starts(keep)', ends(keep)'];

        % build the per-channel mask
        for i = find(keep)
            bigGapMask(ch, starts(i):ends(i)) = true;

            edgeGapMask(ch, starts(i):starts(i)+stitchGap-1) = true;
            edgeGapMask(ch, ends(i)-stitchGap+1:ends(i)) = true;
        end
    end
end
