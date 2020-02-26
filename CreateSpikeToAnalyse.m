% CreateSpikeToAnalyse
% 04.12.2017 KJ
%
% create spike to analyse
%
% SEE
%   CreateSpikeToAnalyse_KJ
%
%
%
%INPUTS
% structure:   brain area
%
%


function [num_neurons, num_mua] = CreateSpikeToAnalyse(structure,hemisphere)

if nargin<1
    error('Incorrect number of inputs')
end

if exist('hemisphere', 'var')
    [num_neurons, ~, ~] = GetSpikesFromStructure(structure, 'hemisphere',hemisphere, 'remove_MUA',1);
    [num_mua, ~, ~] = GetSpikesFromStructure(structure, 'hemisphere',hemisphere, 'remove_MUA',0);
    num_mua = setdiff(num_mua, num_neurons);
else
    [num_neurons, ~, ~] = GetSpikesFromStructure(structure, 'remove_MUA',1);
    [num_mua, ~, ~] = GetSpikesFromStructure(structure, 'remove_MUA',0);
    num_mua = setdiff(num_mua, num_neurons);
end
        

end