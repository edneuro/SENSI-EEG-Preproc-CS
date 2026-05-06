function [drifts_din] =     checkDinIOI(sortedTriggers, sortedOnsets, dinValue, dinInterval)
% [drifts_din] =     checkDinIOI(sortedTriggers, sortedOnsets, dinValue, dinInterval)
% --------------------------------------------------------------------------
% This function examines drift in the inter-onset interval (IOI) of the 
% Digital Inputs (DINs) used for timing during recording
% (see https://www.egi.com/knowledge-center/item/73-basic-timing-theory).
% The function examines trigger vector to find adjacent DIN timing stimuli,
% then examines an onset vector to determine whether the inter-onset
% interval matches the expected value. If it does not, the beginning of the
% onset and duration of the IOI is added to drifts_din
% 
%
%
% Required inputs
% - sortedTriggers: a vector of trigger values sorted in chronological
% order
% - sortedOnsets: a vector of trigger onset values sorted in chronological
% - dinValue: Output value of DIN triggers
% - dinInterval: Expected inter-onset interval
%
% Optional inputs
% - none
%
% Outputs
% - drifts_din: a matrix of onsets and IOI when IOI differed from the
% expected interval

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

%% Check for IOI drift

    drift = [sortedTriggers, sortedOnsets];
    drifts_din= [];

    for k= 2:length(drift)
        if drift(k,1)== dinValue && drift(k-1,1) == dinValue % checks for neigboring DIN triggers
            if drift(k,2) - drift(k-1,2) ~= dinInterval % checks duration against DIN duration
                drifts_din_height = height(drifts_din)+1;
                drifts_din(drifts_din_height,1) = drift(k-1,2);
                drifts_din(drifts_din_height,2) = drift(k,2) - drift(k-1,2);
            end
        end
    end
     