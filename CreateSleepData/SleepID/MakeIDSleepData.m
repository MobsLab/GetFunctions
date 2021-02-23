% MakeIDSleepData
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%  PlotIDSleepData MakeIDSleepData2
%


function MakeIDSleepData(varargin)


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

%recompute ?
if recompute
    save('IdFigureData','foldername') 
elseif exist('IdFigureData.mat','file')~=2
    save('IdFigureData','foldername')
end

%% load eventually

%MUA
disp('load MUA...')
if exist('SpikesToAnalyse/PFCx_down.mat','file')==2
    load SpikesToAnalyse/PFCx_down
elseif exist('SpikesToAnalyse/PFCx_Neurons.mat','file')
    load SpikesToAnalyse/PFCx_Neurons
elseif exist('SpikesToAnalyse/PFCx_MUA.mat','file')
    load SpikesToAnalyse/PFCx_MUA
else
    number=[];
end

if not(isempty(number)) % added by SB for use with mice with no spikes
    load SpikeData
    
    NumNeurons=number;
    T=PoolNeurons(S,NumNeurons);
    clear ST
    ST{1}=T;
    try
        ST=tsdArray(ST);
    end
    binsize = 10;
    MUA=MakeQfromS(ST,binsize*10);
    clear ST T
    
    
    
    %% Down
    disp('Down and spike analysis')
    load('IdFigureData','firingrates');
    if recompute || ~exist('firingrates','var')
        [nb_neuron, firingrates, nbDown, raster_mua, duration_bins] = MakeIDfunc_Neuron('spike_data', S);
        if nb_neuron.all
            save IdFigureData -append nb_neuron firingrates nbDown raster_mua duration_bins
        end
        
    else
        disp('already done')
    end
else
    nb_neuron.all = 0;
    save IdFigureData -append nb_neuron
end


%% Spindles
disp('Spindles analysis')
load('IdFigureData','Mspi_spindles');
if recompute || ~exist('Mspi_spindles','var')
    
    if not(isempty(number)) % added by SB for use with mice with no spikes
    [meancurve, ~] = MakeIDfunc_Spindles('mua', MUA);
    else
        [meancurve, ~] = MakeIDfunc_Spindles('mua', []);
    end
    
    Mspi_spindles = meancurve.spindles.lfp; Mmua_spindles = meancurve.spindles.mua; Mdeep_spindles = meancurve.spindles.deep; 

    save IdFigureData -append Mspi_spindles Mdeep_spindles
    try
        save IdFigureData  -append Mmua_spindles
    end
    
else
    disp('already done')
end

%% Ripples
disp('Ripples analysis')
load('IdFigureData','Mripples');
if recompute || ~exist('Mripples','var')
    [Mripples, ~] = MakeIDfunc_Ripples;
    save IdFigureData -append Mripples
    
else
    disp('already done')
end


%% Delta waves
disp('Delta waves analysis')
load('IdFigureData','Msup_short_delta');
if recompute || ~exist('Msup_short_delta','var')
    if  not(isempty(number)) % added by SB for use with mice with no spikes
        [meancurve, ~] = MakeIDfunc_Deltas('mua', MUA);
    else
        [meancurve, ~] = MakeIDfunc_Deltas('mua', []);
    end
    Msup_short_delta = meancurve.short.sup; 
    Msup_long_delta = meancurve.long.sup;  
    Mdeep_short_delta = meancurve.short.deep;
    Mdeep_long_delta = meancurve.long.deep;
    Mmua_short_delta = meancurve.short.mua; 
    Mmua_long_delta = meancurve.long.mua;
    
    save IdFigureData -append Msup_short_delta Mdeep_short_delta Msup_long_delta Mdeep_long_delta
    save DeltaWaves -append Msup_short_delta Mdeep_short_delta Msup_long_delta Mdeep_long_delta
    try
        save IdFigureData -append Mmua_short_delta Mmua_long_delta
    end
    
else
    disp('already done')
end
    
%% Substages
disp('Substages analysis')
load('IdFigureData','time_in_substages');
if recompute || ~exist('time_in_substages','var')
    [SleepStages, Epochs, time_in_substages, meanDuration_substages, percentvalues_NREM] = MakeIDfunc_Sleepstages;
    save IdFigureData -append SleepStages Epochs time_in_substages percentvalues_NREM meanDuration_substages
else
    disp('already done')
end



end












