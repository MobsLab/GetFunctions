% MakeIDfunc_Spindles
% 06.12.2017 KJ
%
%%INPUT
%
%
%%OUTPUT
%
%
% SEE
%   MakeIDSleepData MakeIDfunc_Neuron MakeIDfunc_Ripples
%


function [meancurve, nb_spindle] = MakeIDfunc_Spindles(varargin)


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
        case 'lfp_spindles'
            LFPspindles = varargin{i+1};
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

if ~exist('LFPspindles','var') && (exist('Spindles.mat','file')==2 || exist('sSpindles.mat','file')==2)
    %LFP Spindles
    try
        load('sSpindles.mat', 'spindles_Info_PFCx','spindles_Info')
    catch
        load('Spindles.mat', 'spindles_PFCx_Info','spindles_Info')
    end
    try
        load(['LFPData/LFP' num2str(spindles_Info_PFCx.channel)],'LFP')
    catch
        load(['LFPData/LFP' num2str(spindles_Info.channel)],'LFP')
    end
    LFPspindles=LFP;
    clear LFP channel
end

if ~exist('LFPdeep','var')
    %LFP deep
    load ChannelsToAnalyse/PFCx_deep
    eval(['load LFPData/LFP',num2str(channel)])
    LFPdeep=LFP;
    clear LFP channel
end


%% load
if exist('Spindles.mat')>0 || exist('sSpindles.mat')>0
    [tSpindles, ~] = GetSpindles('foldername',foldername,'area','PFCx');
    spindles_tmp = Range(tSpindles)/1e4;
    
%     [tSpindles, ~] = GetSpindles('foldername',foldername,'area','PFCx','spindle_type','high');
%     spindles_high_tmp = Range(tSpindles)/1e4;
%     
%     [tSpindles, ~] = GetSpindles('foldername',foldername,'area','PFCx','spindle_type','low');
%     spindles_low_tmp = Range(tSpindles)/1e4;
    
    
    %% Spindles
    %all
    meancurve.spindles.lfp = PlotRipRaw(LFPspindles, sort(spindles_tmp), 500, 0, 0); close
    if not(isempty(MUA))
        meancurve.spindles.mua = PlotRipRaw(MUA, sort(spindles_tmp), 500, 0, 0); close
    else
        meancurve.spindles.mua = [];
    end
    meancurve.spindles.deep = PlotRipRaw(LFPdeep, sort(spindles_tmp), 500, 0, 0); close
    % %low
    % meancurve.low.lfp = PlotRipRaw(LFPspindles, sort(spindles_low_tmp), 500, 0, 0); close
    % meancurve.low.mua = PlotRipRaw(MUA, sort(spindles_low_tmp), 500, 0, 0); close
    % meancurve.low.deep = PlotRipRaw(LFPdeep, sort(spindles_low_tmp), 500, 0, 0); close
    % %high
    % meancurve.high.lfp = PlotRipRaw(LFPspindles, sort(spindles_high_tmp), 500, 0, 0); close
    % meancurve.high.mua = PlotRipRaw(MUA, sort(spindles_high_tmp), 500, 0, 0); close
    % meancurve.high.deep = PlotRipRaw(LFPdeep, sort(spindles_high_tmp), 500, 0, 0); close
    
    nb_spindle.all = length(spindles_tmp);
%     nb_spindle.low = length(spindles_low_tmp);
%     nb_spindle.high = length(spindles_high_tmp);
    
else
    nb_spindle.all = 0;
%     nb_spindle.low = 0;
%     nb_spindle.high = 0;
    meancurve.spindles.mua = [];
    meancurve.spindles.lfp = [];
    meancurve.spindles.deep = [];
    
end

end












