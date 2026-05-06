function [xOut, allGapMs, topTbl, plotPayload] = temporalNaNCorrect(data, ...
    fs, fileId, epochId)

% TEMPORALNANCORRECT  Repair NaN gaps in multi-channel EEG using AR + spline stitching.
%
%   xOut = temporalNaNCorrect(data, fs)
%
% PURPOSE
%   Fix missing samples (NaNs) in an EEG matrix by:
%     (1) Spline-interpolating small gaps along time per channel,
%     (2) Re-exposing “long” gaps as NaN,
%     (3) AR-forecasting each long gap per channel,
%     (4) Spline-stitching the gap edges for smooth transitions.
%
% INPUTS
%   data : [M x N] matrix (channels x samples) with NaNs at missing samples.
%   fs   : scalar sampling rate in Hz.
%
% OUTPUT
%   xOut : [M x N] matrix with small gaps splined and long gaps AR-filled
%          (with edges re-stitched by spline).
%   allGapMs: an array of all NaN gap lenghts in milliseconds
%
% DETAILS
%   • Long gap threshold (ms): AR_TIME_GAP (default 5.1 ms).
%   • Stitch size at each end (ms): AR_STICH_GAP (default 3 ms).
%   • For each long gap, let s=startIdx, E=endIdx, gapLen = E - s + 1.
%     AR order p is chosen as: p = max(round(1.5 * gapLen), 40).
%   • After AR, only the marked edge samples are set to NaN and spline-filled
%     to stitch boundaries; the AR interior remains untouched.
%
% DEPENDENCIES
%   [longGaps, bigGapMask, edgeGapMask] = findLongNaNGaps(data, minGapSamples, stitchGap)
%   [rowOut, ~, ~] = arGapFill(rowIn, p, idx, gapLen)
%
% ASSUMPTIONS
%   • Small holes get fixed by the initial spline, so AR seed windows are finite.
%   • Data is [channels x samples].
%
% EXAMPLE
%   xOut = temporalNaNCorrect(data, 1000);

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


if any(isnan(data(:)))

    [M, N] = size(data);
    
    
    % Min Gap for AR forecasting (ms)
    AR_TIME_GAP = 5.1; % NaN Gaps >= arTimegap (ms) will use AR forecasting
    
    % Stitch Size for AR (ms)
    AR_STICH_GAP = 3; % (ms). These ends should be stitched with Spline Interpolation
    
    % Min Gap for AR forecasting (samples)
    arSampleGap = ceil(AR_TIME_GAP/1000*fs); % min gap for AR filtering in samples
    arSampleGap = max([arSampleGap,3]); % should be at least 3 samples
    
    % Stitch Size for AR (samples)
    arStitchGap = ceil(AR_STICH_GAP/1000*fs);
    arStitchGap = min([arStitchGap, floor(arSampleGap/2)]);
    
    % Find long Gaps that need AR forecasting
    [longGaps, bigGapMask, edgeGapMask] = findLongNaNGaps(data, arSampleGap, arStitchGap);
    
    % === First NaN pass with Interpolation ===
    % Perform spline interpolation along time (dim=2)
    xOut = fillmissing(data, 'spline', 2);
    
    % Revert Long Gap NaNs for AR
    xOut(bigGapMask) = NaN;
    
    
    % === Continue with AR forecasting if there is remaing NaNs ===
    % Check for any remaining NaNs
    rem = isnan(xOut);
    if any(rem(:))
        
        % Perform AR forecasting
        for i = 1:M
            chGaps = longGaps{i};
            N2 = size(chGaps,1);
            
            % mask where data was linearly interpolated (samples cannot be
            % used for AR forecasting)
            mask_LinearInterp = false(1,N); 

            % Iterating through epochs
            for j = 1:N2
                idx = chGaps(j,1);
                gapLen = chGaps(j,2) - idx + 1;
                p = ceil(max([gapLen*1.5,40]));

                % AR ForeCasting 1st attempt
                try
                    % Checking AR History
                    historySegmentMask = mask_LinearInterp(idx-p:idx-1);
                    if any(historySegmentMask)
                        % If true, abort the AR process and signal failure
                        error('AR history was a previous linear interpolation.')
                    end
                    
                    [xOut(i,:),~,~] = arGapFill(xOut(i,:), p, idx, gapLen);
    
                catch ME
                    
                    try % AR ForeCasting 2nd attempt (flipped data)
                        % disp(['Error message: ' ME.message]);

                        nSamp = size(xOut,2);
                        gap_end = chGaps(j,2);
                        idx_flip = nSamp - gap_end + 1;
                        tmp = flip(xOut(i,:));

                        % Checking AR History
                        historySegmentMask = mask_LinearInterp(gap_end+1:gap_end+p);
                        if any(historySegmentMask)
                            % If true, abort the AR process and signal failure
                            error('AR history was a previous linear interpolation.')
                        end

                        [tmpFilled,~,~] = arGapFill(tmp, p, idx_flip, gapLen);
                        xOut(i,:) = flip(tmpFilled);
%                         fprintf('AR Forecasted - flipped channel %d\n', i);

                    catch ME2 % AR Failed. Do Linear Interpolation

                        fprintf(['Epoch %d, Ch %d, Gap %d. AR failure - ' ...
                            'Do Linear Interpolation.\n'], epochId, i, j);

                        tempX = xOut(i,:);
                        pPreds = linspace(tempX(idx-1),tempX(idx+gapLen),gapLen+2);
                        if any(isnan(pPreds))
                            warning(['LINEAR_INTERP_FAILURE: Epoch %d, Ch %d, Gap %d. ' ...
                                'Cannot fill gap safely.'], epochId, i, j);
                        end
                        xOut(i,idx:idx+gapLen-1) = pPreds(2:end-1);

                        mask_LinearInterp(idx:idx+gapLen-1) = true;
                    end

                end
                % disp([i, max(abs(a))]);
            end
        end
        
        % Stich 3 ms with Spine Interpolation
        xOut(edgeGapMask) = NaN;
        xOut = fillmissing(xOut, 'spline', 2);
    end
    
 
    % === Data - NaN gap lengths Histogram ===
    % Collect all NaN-run lengths (samples) across channels
    allGapLens = cell(M,1);   % all gaps
    for ch = 1:M
        isn = isnan(data(ch,:));
        if any(isn)
            d = diff([0, isn, 0]);      % start/end markers
            s = find(d==1);             % start indices
            e = find(d==-1)-1;          % end indices (inclusive)
            allGapLens{ch} = e - s + 1;    % keeping NaNs
        end
    end
    allGapLens = cell2mat(allGapLens);
    allGapMs = allGapLens * 1000/fs;

    [topTbl, plotPayload] = suspiciousGaps(xOut, longGaps, fs, fileId, ...
        epochId, 4);

else
    xOut = data; topTbl = table();
    allGapMs = []; plotPayload = {};

end