%FindNREMfeatures
% 15.11.2017 KJ
%
% [features, Namesfeatures, EpochSleep, noiseEpoch] = FindNREMfeatures(varargin)
%
%%INPUTS
% scoring (optional):   method used to distinguish sleep from wake
%                         'accelero' or 'OB'; default is 'ob'
%
%%OUTPUT
% features:
% Namesfeatures:
% EpochSleep:
% NoiseEpoch:
% scoring:
%
% see FindNREMEpochsML
%

function [features, Namesfeatures, EpochSleep, NoiseEpoch, scoring] = FindNREMfeatures(varargin)

if mod(length(varargin),2) ~= 0
    error('Incorrect number of parameters.');
end
channel = [];

%% INITIATION
disp('Running FindNREMfeatures.m')
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isstring_FMAToolbox(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('scoring','var')
    scoring='ob';
end

%params
Namesfeatures = {'PFsupOsci','PFdeepOsci','BurstDelta','REM','WAKE','SWS','SIEpochSleep','PFswa','OBswa'};
mergelim = 5;
mergesleep = 3;
min_delta_duration = 75*10; % same as Marie's paper


%% Check if prerequired variables are available
try
    load('DeltaWaves.mat', 'deltas_PFCx')
    deltas_PFCx = dropShortIntervals(deltas_PFCx, min_delta_duration);
    tdeltas = ts(Start(deltas_PFCx));
    if isempty(Start(deltas_PFCx))
        error('Delta are empty')
    end
catch
    try
        load('AllDeltaPFCx.mat'); tdeltas = ts(tDelta);
    catch
        makeerror('Run CreateDeltaWavesSleep before and relaunch');
    end
    %     error('delta waves detection has to be done before')
end

%% load sleep scoring
if strcmpi(scoring,'accelero')
    load SleepScoring_Accelero SWSEpoch REMEpoch Wake ImmobilityEpoch TotalNoiseEpoch
    NoiseEpoch = TotalNoiseEpoch;
    EpochSleep = ImmobilityEpoch - TotalNoiseEpoch;
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma SWSEpoch REMEpoch Wake Sleep TotalNoiseEpoch
    catch
        load StateEpochSB SWSEpoch SWSEpoch REMEpoch Wake Sleep TotalNoiseEpoch
    end
    NoiseEpoch = TotalNoiseEpoch;
    EpochSleep = Sleep - TotalNoiseEpoch;
end


%% Find oscillatory period of NREM

%channel deep
load('ChannelsToAnalyse/PFCx_deep.mat')
channel_deep = channel;
clear channel
%channel sup
if exist('ChannelsToAnalyse/PFCx_sup.mat','file')==2
    load('ChannelsToAnalyse/PFCx_sup.mat');
    channel_sup = channel;
    if isempty(channel)
        load('ChannelsToAnalyse/PFCx_deltasup.mat');
        channel_sup = channel;
    end
else 
    load('ChannelsToAnalyse/PFCx_deltasup.mat');
    channel_sup = channel;
end
clear channel

%Find Oscillatory periods (inspired from FindSleepStageML)
eval(['load LFPData/LFP',num2str(channel_deep)])
LFPdeep=LFP;
[deep_OsciEpochSleep]=FindOsciEpochs(LFPdeep,EpochSleep);

eval(['load LFPData/LFP',num2str(channel_sup)])
LFPsup=LFP;
[sup_OsciEpochSleep]=FindOsciEpochs(LFPsup,EpochSleep);

%spindles
try
    load('Spindles','SpindlesEpoch_PFCx')
    if exist('SpindlesEpoch_PFCx', 'var')
        SpindlesEpoch = SpindlesEpoch_PFCx;
    else
        SpindlesEpoch = intervalSet([],[]);
    end
catch
    SpindlesEpoch = intervalSet([],[]);
end

% % for FindSleepStageML
% SpindlesEpoch = intervalSet([],[]);
% channel_sup='PFCx_deltasup'; %for FindSleepStageML
% [~,~,~, sup_OsciEpochSleep]=FindSleepStageML(channel_sup);
% channel_deep = 'PFCx_deep'; %for FindSleepStageML
% [~,~,~, deep_OsciEpochSleep]=FindSleepStageML(channel_deep);


%% Load delta PFCx and find BurstDeltaEpochSleep
BurstDeltaEpoch_2_700 = FindDeltaBurst2(tdeltas, 0.7, 0);
BurstDeltaEpoch_3_700 = FindDeltaBurst2(tdeltas, 0.7, 1); % final 1 means that only bursts of at least 3 delta are kept
BurstDeltaEpoch_2_1000 = FindDeltaBurst2(tdeltas, 1, 0);
BurstDeltaEpoch_3_1000 = FindDeltaBurst2(tdeltas, 1, 1); % final 1 means that only bursts of at least 3 delta are kept


%% Find strong delta activity in PFCx
try
    channel_deep = load('ChannelsToAnalyse/PFCx_deep.mat');
    
    disp(['... loading PFCx_deep SpectrumDataL/Spectrum',num2str(channel_deep.channel),'.mat'])
    eval(['pfc_spectrum = load(''SpectrumDataL/Spectrum',num2str(channel_deep.channel),'.mat'');'])
    
    disp('... FindSlowOscBulb.m on PFCxDeep channel')
    EpochSleepSlowPF = FindSlowOscillation(pfc_spectrum.Sp, pfc_spectrum.t, pfc_spectrum.f); % !!! not restricted to SWS !!!
    clear pfc_spectrum
    
    disp('Done.');close
catch
    EpochSleepSlowPF=intervalSet(NaN,NaN);
end


%% Find strong oscillation in OB
clear channel Sp t f
try
    channel_bulb = load('ChannelsToAnalyse/Bulb_deep.mat');
    
    disp(['... loading Bulb_deep SpectrumDataL/Spectrum', num2str(channel_bulb.channel), '.mat'])
    eval(['bulb_spectrum = load(''SpectrumDataL/Spectrum', num2str(channel_bulb.channel), '.mat'');'])
    
    disp('... FindSlowOscBulb.m on Bulb_deep channel')
    EpochSleepSlowOB = FindSlowOscillation(bulb_spectrum.Sp, bulb_spectrum.t, bulb_spectrum.f); % not restricted to SWS !!
    clear bulb_spectrum
    
    disp('Done.')
catch
    EpochSleepSlowOB=intervalSet(NaN,NaN);
end


%% TERMINATION

if exist('EpochSleep','var')
    % raw EpochSleeps
    features{1} = sup_OsciEpochSleep; %S34
    features{2} = deep_OsciEpochSleep; %S34;
    features{3} = SpindlesEpoch;
    features{4} = BurstDeltaEpoch_2_700; %N3
    features{5} = REMEpoch;
    features{6} = Wake;
    features{7} = SWSEpoch;
    features{8} = EpochSleepSlowPF; %PFCx
    features{9} = EpochSleepSlowOB; %OB
    features{10} = BurstDeltaEpoch_3_700; %N3etN4
    features{11} = BurstDeltaEpoch_2_1000; %N3etN4
    features{12} = BurstDeltaEpoch_3_1000; %N3etN4
else
    features={};
end

if ~exist('EpochSleep','var')
    EpochSleep=intervalSet([],[]);
end
if ~exist('noiseEpoch','var')
    NoiseEpoch=intervalSet([],[]);
end



end


