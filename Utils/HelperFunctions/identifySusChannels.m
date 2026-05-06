function [sus_ids_sorted, sus_vals_sorted] = identifySusChannels(xIn, nChannels, W, figStr)
% [sus_ids_sorted, sus_vals_sorted] = identifySusChannels(xIn, nChannels, W, figStr)
% --------------------------------------------------------------------------
% This fuction takes the [space x time] xAll_129 data matrix and returns a 
% list of suspicious channels scored by each channel's max abs value,
% variance, and neighbor dissimilarity. 
%
% Required inputs: 
% xIn: EEG data (channel x time) size(129,:)
% nChannels: # of channels to be considered (e.g. 124 if xIn will be
%    cropped in the future, xIn = xIn(1:124,:);
%
% Optional inputs: 
% W: eights for sus_score linear combination. If empty or not entered,
%   will default to W = [0.25, 0.25, 0.5] for each Ch 
%   (max, variance, neighbor corr)
% figStr: sgtitle of the entire figure
%
% Outputs:
% sus_ids_sorted: List of suspicious channel #s, sorted by their sus_scores
% sus_vals_sorted: The corresponding sorted list of sus_scores

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

% Assign default weights vector if needed
if nargin < 3 || isempty(W), W = [0.25, 0.25, 0.5]; end

sum_threshold = 1; % weighted Z score baseline for a suspicious channel.

channel_NeighborCorrs = computeCorrelationsWithNeighboringElectrodes(xIn, nChannels);

xIn = xIn(1:nChannels,:);

% Suspecious Max sample from each Channel.
channel_maxes = max(abs(xIn'))';
z_maxes = zscore(log(channel_maxes));
% z_maxes(z_maxes < 0) = 0;
z_maxes(z_maxes < 2) = 0;

% Suspecious Variance of each Channel.
channel_variance = var(xIn, [], 2);
z_var = zscore(log(channel_variance));
z_var = abs(z_var);
z_var(z_var < 2) = 0;

% Suspecious Neighbor Dissimilarity measure
dis_corr = 1 - channel_NeighborCorrs;
z_discorr = zscore(dis_corr);
z_discorr = abs(z_discorr);
z_discorr(z_discorr < 2) = 0;

% Suspecious Linear Combination
sus_scores = W(1)*z_maxes + W(2)*z_var + W(3)*z_discorr;

% Sorting CHs by their sus_score
valid_indices = find(sus_scores >= sum_threshold ); % Get indices where bad_scores >= sum_threshold 
valid_values = sus_scores(valid_indices); % Extract the corresponding values
% Sort the valid values in descending order
[sus_vals_sorted, sort_order] = sort(valid_values, 'descend'); % Get sorted order of valid values
% Obtain the sorted indices relative to the original vector
sus_ids_sorted = valid_indices(sort_order);

%% Figure

figure;

subplot(511)
stem(z_maxes)
ylabel('zScore (z>2 log)')
title('CHs with Sus Max')
box off; xlim('tight')

subplot(512)
stem(z_var)
ylabel('zScore (z>2 log + abs)')
title('CHs with Sus Variance')
box off; xlim('tight')

subplot(513)
stem(z_discorr)
ylabel('zScore (z>2 abs)')
title('CHs with Sus Neighbor Dissimilarity')
box off; xlim('tight')

subplot(5, 1, 4:5)
stem(26:nChannels, sus_scores(26:end),'k'); hold on
stem(valid_indices, valid_values, 'r');
stem(1:25, sus_scores(1:25),'b');
legend('Non-eye region, ok', 'Non-eye region, flagged', 'Eye region')
title('Bad Channel Score')
ylabel('zScores Weighted Sum')
box off; xlim('tight'); grid on

% Plot the sgtitle
if nargin == 4
    sgtitle([figStr ': Suspicious channel scores'], 'interpreter', 'none');
else
    sgtitle('Suspicious channel scores');
end

% Print the sus channel numbers
annotation('textbox', [.5 0.01 0 0], ...
    'String', ['Flagged sus ch (sorted): ' mat2str(sus_ids_sorted(:)')], ...
    'FitBoxToText', 'on', 'fontsize', 12, ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment','center');

end