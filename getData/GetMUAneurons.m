%%GetMUAneurons
% 18.12.2018 KJ
%
% get MUA from a brain area or a list of neurons
%
% function [MUA, nb_neurons] = GetMUAneurons(neuron_group, varargin)
%
% INPUT:
% - neuron_group                a string containing the brain area, or the .mat file, or a list of neuron number
%                           
%
% - binsize (optional)          = binsize 
%                               (default 10ms)
% - depth (optional)            = BOOL - MUA for each depth 
%                               (default False)
% - Epoch (optional)            = epoch on which MUA is restricted 
%                               (default no restrict)
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%

%
%
% OUTPUT:
% - MUA             = tsd of the Multi-Unit Activity
% - nb_neurons      = number of neurons  
%
%
%   see 
%       
%


function [MUA, nb_neurons] = GetMUAneurons(neuron_group, varargin)


%% CHECK INPUTS

if nargin < 1 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'binsize'
            binsize = varargin{i+1};
            if binsize<=0
                error('Incorrect value for property ''binsize''.');
            end
        case 'depth'
            depth = varargin{i+1};
        case 'Epoch'
            Epoch = varargin{i+1};
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('binsize','var')
    binsize=10;
end
if ~exist('depth','var')
    depth=0;
end
if ~exist('Epoch','var')
    Epoch=[];
end
if ~exist('foldername','var')
    foldername = pwd;
end

%binsize in ms
binsize = binsize*10;


%% Get neurons number

%string
if isastring(neuron_group)
    
    %.mat file
    if strcmp(neuron_group(end-3:end),'.mat')
        load(fullfile(foldername,'SpikesToAnalyse',neuron_group), 'number')
        neurons_number=number;
    elseif ~contains(neuron_group,'Neurons','IgnoreCase',true) && ~contains(neuron_group,'MUA','IgnoreCase',true)
        load(fullfile(foldername,'SpikesToAnalyse',[neuron_group '_Neurons.mat']), 'number')
        neurons_number=number;
    else
        load(fullfile(foldername,'SpikesToAnalyse',[neuron_group '.mat']), 'number')
        neurons_number=number;
    end
            
%list of neurons number
elseif isivector(neuron_group,'>0')
    neurons_number=neuron_group;

%incorrect input
else
    error('Incorrect input ''neuron_group''.');
end

%depth, eventually
if depth
    load(fullfile(foldername,'SpikeData.mat'), 'neuronsLayers') 
end


%% Get MUA
    
load(fullfile(foldername,'SpikeData.mat'), 'S')

if ~exist('neuronsLayers', 'var')
    [MUA, nb_neurons] = SpikeToMUA(S, neurons_number, binsize, Epoch);
    
else %struct of MUA for each layers
    layers = unique(neuronsLayers);
    layers(isnan(layers))=[];
    for i=1:length(layers)
        NumNeurons = intersect(find(neuronsLayers==layers(i)), neurons_number);
        [MUA{layers(i)}, nb_neurons(i)] = SpikeToMUA(S, NumNeurons, binsize, Epoch);
    end
end

end


function [MUA, nb_neurons] = SpikeToMUA(S, neurons_number, binsize, Epoch)
    if isa(S,'tsdArray')
        MUA = MakeQfromS(S(neurons_number), binsize);
    else
        MUA = MakeQfromS(tsdArray(S(neurons_number)),binsize);
    end

    %MUA
    MUA = tsd(Range(MUA), sum(full(Data(MUA)),2));
    %number of neurons
    nb_neurons = length(neurons_number);

    %Restrict eventually
    if ~isempty(Epoch)
        MUA = Restrict(MUA,Epoch);
    end

end

