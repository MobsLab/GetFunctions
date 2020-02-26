% MakeIDfunc_Neuron
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData
%


function [nb_neuron, firingrates, nbDown, raster_mua, duration_bins] = MakeIDfunc_Neuron(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'spike_data'
            S = varargin{i+1};
        case 'binsize'
            binsize = lower(varargin{i+1});
            if binsize<=0
                error('Incorrect value for property ''binsize''.');
            end
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

if ~exist('S','var')
    %S
    load('SpikeData','S')  
end


%params
thresh0 = 0.7;
minDownDur = 60;
maxDownDur = 1000;
mergeGap = 0; % merge
predown_size = 0;
duration_bins = 0:10:1500; %duration bins for downstates


%% load
if exist('SleepScoring_Accelero.mat','file')==2
    load('SleepScoring_Accelero','SWSEpoch','Wake')
else
    try
        load SleepScoring_OBGamma SWSEpoch Wake
    catch
        load StateEpochSB SWSEpoch Wake
    end
end
%MUA
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
clear number
T=PoolNeurons(S,NumNeurons);
clear ST
ST{1}=T;
try
    ST=tsdArray(ST);
end
MUA=MakeQfromS(ST,binsize*10);
%pyr or int
try
    load('NeuronClassification', 'UnitID')
catch
    load('WFIdentit', 'UnitID')
end
id_neurons = UnitID(NumNeurons);


%% Down characteristics
DurationSWS = tot_length(SWSEpoch)/1e4;
DurationWake = tot_length(Wake)/1e4;
Qsws = Restrict(MUA, SWSEpoch);
Qwake = Restrict(MUA, Wake);

% Mean firing rates
nb_neuron.all = length(NumNeurons);
firingrates.sws.all = round(mean(full(Data(Restrict(MUA, SWSEpoch))), 1)*100,2); % firing rate for a bin of 10ms
firingrates.wake.all = round(mean(full(Data(Restrict(MUA, Wake))), 1)*100,2); % firing rate for a bin of 10ms

%interneurons 
nb_neuron.pyr = length(NumNeurons(id_neurons>0));
T_pyr=PoolNeurons(S,NumNeurons(id_neurons>0)); %pyramidal
clear ST
ST{1}=T_pyr;
try
    ST=tsdArray(ST);
end
Q_pyr=MakeQfromS(ST,binsize*10);
%pyramidal cells
nb_neuron.int = length(NumNeurons(id_neurons<0));
T_int=PoolNeurons(S,NumNeurons(id_neurons<0)); %interneuron
clear ST
ST{1}=T_int;
try
    ST=tsdArray(ST);
end
Q_int=MakeQfromS(ST,binsize*10);
clear ST T_int T_pyr

firingrates.sws.pyr = round(mean(full(Data(Restrict(Q_pyr, SWSEpoch))), 1)*100,2); % firing rate for a bin of 10ms
firingrates.wake.pyr = round(mean(full(Data(Restrict(Q_pyr, Wake))), 1)*100,2); % firing rate for a bin of 10ms
firingrates.sws.int = round(mean(full(Data(Restrict(Q_int, SWSEpoch))), 1)*100,2); % firing rate for a bin of 10ms
firingrates.wake.int = round(mean(full(Data(Restrict(Q_int, Wake))), 1)*100,2); % firing rate for a bin of 10ms
clear Q_pyr Q_int

% Number of down
if ~isempty(NumNeurons)
    DownSws = FindDownKJ(Qsws, 'low_thresh', thresh0, 'minDuration', 0,'maxDuration', maxDownDur, 'mergeGap', mergeGap, 'predown_size', predown_size);
    downSws_dur = (End(DownSws) - Start(DownSws)) / 10; %ms
    DownWake = FindDownKJ(Qwake, 'low_thresh', thresh0, 'minDuration', 0,'maxDuration', maxDownDur, 'mergeGap', mergeGap, 'predown_size', predown_size);
    downWake_dur = (End(DownWake) - Start(DownWake)) / 10; %ms

    nbDown.sws = zeros(1, length(duration_bins));
    nbDown.wake = zeros(1, length(duration_bins));
    for j=1:length(duration_bins)
        binvalue = duration_bins(j);
        nbDown.sws(j) = sum(downSws_dur==binvalue);
        nbDown.wake(j) = sum(downWake_dur==binvalue);
    end

    % Raster
    true_DownSws = dropShortIntervals(DownSws, minDownDur*10);
    true_DownSws_dur = (End(true_DownSws) - Start(true_DownSws)) / 10;
    [~, idx_down] = sort(true_DownSws_dur,'descend');
    t_before = -2000; %in 1E-4s
    t_after = 5000; %in 1E-4s
    raster_tsd = RasterMatrixKJ(MUA, ts(Start(true_DownSws)), t_before, t_after, idx_down);
    raster_mua.matrix = Data(raster_tsd)';
    raster_mua.time = Range(raster_tsd);
end



end












