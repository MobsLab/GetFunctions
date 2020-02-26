% MakeIDfunc_Tetrode
% 08.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_DownDelta MakeIDfunc_SleepEvent MakeIDfunc_LfpInfo
%
%


function [nb_neurons, info_tetrode] = MakeIDfunc_Tetrode(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('recompute','var')
    recompute=0;
end



%% load
load SpikeData tetrodeChannels TT
load('LFPData/InfoLFP.mat','InfoLFP');
try
try,load('NeuronClassification.mat', 'UnitID'),
catch, load('WFIdentit.mat', 'UnitID'), end
end

%hemisphere
for i=1:length(InfoLFP.hemisphere)
    if strcmpi(InfoLFP.hemisphere{i},'right') || strcmpi(InfoLFP.hemisphere{i},'left')
        InfoLFP.hemisphere{i} = InfoLFP.hemisphere{i}(1);
    end
end

nb_tetrode = length(tetrodeChannels);

for t=1:nb_tetrode
    %LFP info on tetrode
    channel1 = tetrodeChannels{t}(1);
    info_tetrode.structure{t} = InfoLFP.structure{InfoLFP.channel==channel1};
    info_tetrode.hemisphere{t} = InfoLFP.hemisphere{InfoLFP.channel==channel1};
    info_tetrode.depth(t) = InfoLFP.depth(InfoLFP.channel==channel1);
    
    %neurons of tetrode and their class
    numNeurons{t} = [];
    for i=1:length(TT)
        if TT{i}(2)>1 && TT{i}(1)==t
            numNeurons{t} = [numNeurons{t} i];
        end
    end
    if not(exist('UnitID'))
        neuronsType{t} = numNeurons{t}*0;
    else
    neuronsType{t} = UnitID(numNeurons{t});
    end
    
    %number
    nb_neurons.all(t) = length(numNeurons{t});
    nb_neurons.pyr(t) = sum(neuronsType{t}>0);
    nb_neurons.int(t) = sum(neuronsType{t}<0);
    
end




end




