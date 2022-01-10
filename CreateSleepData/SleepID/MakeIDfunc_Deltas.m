% MakeIDfunc_Deltas
% 06.12.2017 KJ
%
%%INPUT
%
%
%%OUTPUT
%
%
% SEE
%   MakeIDSleepData MakeIDfunc_Neuron MakeIDfunc_Ripples MakeIDfunc_Spindles
%
%


function [meancurve, nb_delta] = MakeIDfunc_Deltas(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'binsize'
            binsize = lower(varargin{i+1});
            if binsize<=0
                error('Incorrect value for property ''binsize''.');
            end
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'mua'
            MUA = varargin{i+1};
        case 'lfp_sup'
            LFPsup = varargin{i+1};
        case 'lfp_deep'
            LFPdeep = varargin{i+1};
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
if ~exist('binsize','var')
    binsize = 10;
end
if ~exist('recompute','var')
    recompute=0;
end
if ~exist('MUA','var')
    %MUA
    load SpikeData
    if exist('SpikesToAnalyse/PFCx_down.mat','file')==2
        load SpikesToAnalyse/PFCx_down
    elseif exist('SpikesToAnalyse/PFCx_Neurons.mat','file')
        load SpikesToAnalyse/PFCx_Neurons
    elseif exist('SpikesToAnalyse/PFCx_MUA.mat','file')
        load SpikesToAnalyse/PFCx_MUA
    else
        number=[];
    end
    NumNeurons=number;
    T=PoolNeurons(S,NumNeurons);
    clear ST
    ST{1}=T;
    try
        ST=tsdArray(ST);
    end
    MUA=MakeQfromS(ST,binsize*10);
    clear ST T
end

if ~exist('LFPsup','var')
    %LFP sup
    load('DeltaWaves.mat', 'deltas_PFCx_Info')
    load(['LFPData/LFP' num2str(deltas_PFCx_Info.channel_sup)],'LFP')
    LFPsup=LFP;
    clear LFP channel
end

if ~exist('LFPdeep','var')
    load('DeltaWaves.mat', 'deltas_PFCx_Info')
    load(['LFPData/LFP' num2str(deltas_PFCx_Info.channel_deep)],'LFP')
    LFPdeep=LFP;
    clear LFP channel
end


%% data
load('DeltaWaves.mat', 'deltas_PFCx')
%delta data
deltas_tmp = (Start(deltas_PFCx) + End(deltas_PFCx)) / 2e4;
delta_duration = End(deltas_PFCx) - Start(deltas_PFCx);
nb_deltas = length(deltas_tmp);
%shortest and largest
[~, idx_delta_sorted] = sort(delta_duration,'ascend');
halfsize = min(floor(nb_deltas/2), 500);
short_deltas = deltas_tmp(idx_delta_sorted(1:halfsize));
long_deltas = deltas_tmp(idx_delta_sorted(end-halfsize+1:end));


%% Mean curves
% short deltas
meancurve.short.sup = PlotRipRaw(LFPsup, sort(short_deltas), 500, 0, 0); close
if not(isempty(MUA))
    meancurve.short.mua = PlotRipRaw(MUA, sort(short_deltas), 500, 0, 0); close
else
    meancurve.short.mua = [];
end
meancurve.short.deep = PlotRipRaw(LFPdeep, sort(short_deltas), 500, 0, 0); close

% long deltas
meancurve.long.sup = PlotRipRaw(LFPsup, sort(long_deltas), 500, 0, 0); close
if not(isempty(MUA))
    meancurve.long.mua = PlotRipRaw(MUA, sort(long_deltas), 500, 0, 0); close
else
    meancurve.long.mua = [];
end
meancurve.long.deep = PlotRipRaw(LFPdeep, sort(long_deltas), 500, 0, 0); close

nb_delta.short = length(short_deltas);
nb_delta.long = length(long_deltas);
nb_delta.all = nb_deltas;


end












