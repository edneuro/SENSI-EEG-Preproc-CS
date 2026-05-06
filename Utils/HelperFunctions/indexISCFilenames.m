function [fNames, fList] = indexISCFilenames(inDir, fInitStr, searchStr)
% [fNames, fList] = indexISCFilenames(inDir, fInitStr, searchStr)
% -----------------------------------------------------------------
% This function takes in various directory and filename specifications and
% returns a list of filenames, if any, in the directory matching the
% filename specifications. The function will ensure that only unique
% entries in the overall indexed list are returned.
%
% Inputs
% - inDir: Path to directory to be indexed
% - fInitStr: String with e.g., experiment/group and/or participant
%   identifier that starts off the filename.
% - searchStr: Other strings by which to index, e.g., block number,
%   stimulus condition label.
%
% Outputs
% - fNames: The list of unique filenames, as a cell array of strings. If
%   filenames are repeated, the subset unique list will be in alphabetical
%   order. It is up to the user to check the ordering of output filenames.
% - fList: The full 'dir' output, as a struct array. fList may have more
%   elements than fNames if any files were returned twice during indexing.

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

assert(nargin == 3, ['This function requires 3 inputs: The path to '...
    'the file directory, a string init identifier, and a variable string '...
    'identifier.'])

% How many searches are we doing?
nSearchStr = max(length(searchStr), 1);

% Init fList
fList = [];

% Index the files
for i = 1:nSearchStr

    fl = dir([inDir filesep fInitStr '*' searchStr{i} '*.mat']);

    fList = cat(1, fList, fl);

end

% Pull out fName
fNames = {fList.name};   % Here are all the names
fNames = fNames(:);       % Make it column orientation

if length(fNames) > length(unique(fNames))
    warning('Repeated filenames found! Returning unique subset.')
    fNames = unique(fNames);  % Return unique entries only (alphabetical)
end