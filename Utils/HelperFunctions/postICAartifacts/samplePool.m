function pooled = samplePool(x, desiredMaxSamples)

% pooled = samplePool(x, desiredMaxSamples)
% ------------------------------------------
% Downsamples a [channels x samples] matrix via max pooling so that the
% output sample count does not exceed desiredMaxSamples.
%
% If nSamples > desiredMaxSamples, a pooling window of
% floor(nSamples / desiredMaxSamples) is computed. Each window is reduced
% to its maximum value. Any trailing samples that do not fill a complete
% window are discarded.
%
% If nSamples <= desiredMaxSamples, the input is returned unchanged.
%
% Inputs:
%   x                - [channels x samples] numeric matrix
%   desiredMaxSamples - target maximum number of output samples
%
% Output:
%   pooled - [channels x nWindows] matrix, where
%            nWindows = floor(nSamples / poolSize)

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

    % x: matrix of size [channels x samples]
    % desiredMaxSamples: desired maximum number of samples in the pooled output (e.g., 7000)
    
    [nChannels, nSamples] = size(x);
    
    % If the number of samples is greater than the desired max, compute the pooling window size.
    if nSamples > desiredMaxSamples
        poolSize = floor(nSamples / desiredMaxSamples);
    else
        poolSize = 1;
    end

    % Number of complete windows (trim extra samples)
    nComplete = floor(nSamples / poolSize);
    xTrim = x(:, 1:(nComplete * poolSize));

    % Reshape into a 3D array: [channels, poolSize, number_of_windows]
    xReshaped = reshape(xTrim, nChannels, poolSize, nComplete);

    % Compute the max along the pooling dimension (dimension 2)
    pooled = max(xReshaped, [], 2);

    % Remove the singleton dimension to get the final pooled matrix:
    % Final size is [channels x number_of_windows]
    pooled = squeeze(pooled);
end
