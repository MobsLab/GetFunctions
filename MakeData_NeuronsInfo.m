%%MakeData_NeuronsInfo
% 19.12.2018 KJ
%
%   Create InfoNeuronsPFCx.mat, containing informations on neurons
%   
%
% see
%   MakeNeuronInfoData_KJ 
%


function InfoNeurons = MakeData_NeuronsInfo(varargin)


%% CHECK INPUTS
if mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = varargin{i+1};
        case 'savedata'
            savedata = varargin{i+1};
            if savedata~=0 && savedata ~=1
                error('Incorrect value for property ''savedata''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('savedata','var')
    savedata = 1;
end


%% load data
load(fullfile(foldername,'SpikeData.mat'), 'S', 'tetrodeChannels', 'TT')
load(fullfile(foldername,'NeuronClassification.mat'), 'UnitID')
load(fullfile(foldername,'LFPData','InfoLFP.mat'), 'InfoLFP')

if exist(fullfile(foldername,'ChannelsToAnalyse','PFCx_clusters.mat'),'file')==2
    load(fullfile(foldername,'ChannelsToAnalyse','PFCx_clusters.mat'), 'clusters', 'channels')
else
    disp('no cluster layer file')
end

%% info

% structure & hemisphere
neuron_structures = cell(0);
neuron_hemisphere = cell(0);
for n=1:length(TT)    
    neuron_channel = tetrodeChannels{TT{n}(1)};
    neuron_structures{n} = InfoLFP.structure{InfoLFP.channel==neuron_channel(1)};
    neuron_hemisphere{n} = InfoLFP.hemisphere{InfoLFP.channel==neuron_channel(1)};
end

%MUA or neuron
neuron_ismua = zeros(length(S), 1);
for i=1:length(S)
    if TT{i}(2)==1
        neuron_ismua(i)=1;
    end
end
    
% firing rate
firingrates = nan(length(S), 1);
for i=1:length(S) 
    firingrates(i) = length(S{i}) / (max(Range(S{i}))*1e-4);
end

% putative interneuon-pyramidal
neuron_type = UnitID(:,1);

% layer / cluster
neuron_layer = nan(length(S), 1);
if exist('clusters','var')
    for n=1:length(TT)    
        neuron_channels = tetrodeChannels{TT{n}(1)};
        idx = ismember(channels, neuron_channels);
        if any(idx)
            neuron_layer(n) = clusters(find(idx,1));
        end
    end
end

% soloist
neuron_soloist = nan(length(S), 1);
list_structures = unique(neuron_structures);
for i=1:length(list_structures)
    NumNeurons = find(strcmpi(neuron_structures,list_structures{i}));
    if length(NumNeurons)>3
        [numSoloist, numChorist] = FindSoloistChorist_KJ(S, NumNeurons);
        neuron_soloist(numSoloist) = 1;
        neuron_soloist(numChorist) = 0;
    end
end


%% save
InfoNeurons.structure   = neuron_structures;
InfoNeurons.hemisphere  = neuron_hemisphere;
InfoNeurons.ismua       = neuron_ismua;
InfoNeurons.firingrate  = firingrates;
InfoNeurons.putative    = neuron_type;
InfoNeurons.layer       = neuron_layer;
InfoNeurons.soloist     = neuron_soloist;
    

if savedata
    save('InfoNeuronsAll', 'InfoNeurons')
end

end


