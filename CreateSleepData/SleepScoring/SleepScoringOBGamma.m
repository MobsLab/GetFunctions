% SleepScoringOBGamma
% 21.11.2017 SB
%
% SleepScoringOBGamma('PlotFigure',1)
%
% Sleep Scoring Using Olfactory Bulb and Hippocampal LFP
% This function creates SleepScoring_OBGamma with sleep scoring variables
%
%
%INPUTS
% PlotFigure (optional) = overview figrue of sleep scoring if 1; default is 1
%
%
% APADTED from BulbSleepScript
% CALLS FindNoiseEpoch_SleepScoringOBGamma ;
% FindThetaEpoch_SleepScoringOBGamma ; FindGammaEpoch_SleepScoringOBGamma ;
%
% SEE
%   SleepScoringAccelerometer
%


function SleepScoringOBGamma(varargin)

%% INITITATION
disp('Performing sleep scoring with OB gamma')

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'plotfigure'
            PlotFigure = varargin{i+1};
            if PlotFigure~=0 && PlotFigure ~=1
                error('Incorrect value for property ''PlotFigure''.');
            end
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        case 'minduration'
            minduration = varargin{i+1};
            if minduration<0
                error('Incorrect value for property ''minduration''.');
            end
        case 'user_confirmation'
            user_confirmation = varargin{i+1};
            if user_confirmation~=0 && user_confirmation ~=1
                error('Incorrect value for property ''user_confirmation''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('PlotFigure','var')
    PlotFigure=1;
end
if ~exist('recompute','var')
    recompute=0;
end
if ~exist('minduration','var')
    minduration = 3;     % abs cut off duration for epochs (sec)
end
if ~exist('user_confirmation','var')
    user_confirmation=1;
end

%check if already exist
if ~recompute
    if exist('SleepScoring_OBGamma.mat','file')==2
        disp('Already computed! ')
        return
    end
end

% create fileNaN
Info.minduration=minduration;
save('SleepScoring_OBGamma','Info')
clear Info

%% Load necessary channels

foldername=pwd;
if foldername(end)~=filesep
    foldername(end+1)=filesep;
end

% OB
if exist('ChannelsToAnalyse/Bulb_deep.mat','file')==2
    load('ChannelsToAnalyse/Bulb_deep.mat')
    channel_bulb=channel;
else
    error('No OB channel, cannot do sleep scoring');
end

% HPC
if exist('ChannelsToAnalyse/dHPC_deep.mat','file')==2
    load('ChannelsToAnalyse/dHPC_deep.mat')
    channel_hpc=channel;
elseif exist('ChannelsToAnalyse/dHPC_rip.mat','file')==2
    load('ChannelsToAnalyse/dHPC_rip.mat')
    channel_hpc=channel;
else
    error('No HPC channel, cannot do sleep scoring');
end
if isempty(channel_hpc)
    try
        load('ChannelsToAnalyse/dHPC_rip.mat')
        channel_hpc=channel;
    catch
        error('No HPC channel, cannot do sleep scoring');
    end
end


%% Get Noise epochs & save
disp('NoiseEpochs')
[Epoch,TotalNoiseEpoch,SubNoiseEpoch,Info_temp] = FindNoiseEpoch_SleepScoring(channel_hpc, 'foldername', foldername, 'user_confirmation', user_confirmation);
Info=Info_temp; clear Info_temp;
save('SleepScoring_OBGamma','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')

%% Find theta and gamma epochs

% Gamma epoch
disp('Gamma Epochs')
[Sleep,SmoothGamma,Info_temp]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername, 'user_confirmation', user_confirmation);
Info=ConCatStruct(Info,Info_temp); clear Info_temp;
save('SleepScoring_OBGamma','Sleep','SmoothGamma','-append')

% Theta epoch
disp('Theta Epochs')
[ThetaEpoch,SmoothTheta, ~, Info_temp] = FindThetaEpoch_SleepScoring(Sleep, channel_hpc, minduration, 'foldername', foldername, 'user_confirmation', user_confirmation);
Info=ConCatStruct(Info,Info_temp); clear Info_temp;
save('SleepScoring_OBGamma','ThetaEpoch','SmoothTheta','-append')


%% Define behavioural epochs
[REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, Sleep, ThetaEpoch, minduration);
SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
Sleep = or(REMEpoch,SWSEpoch);
save('SleepScoring_OBGamma','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', 'SWSEpochWiNoise', 'WakeWiNoise',...
    'SleepWiNoise','Sleep','-append')


%% save Info 
save('SleepScoring_OBGamma','Info','-append')


%% Make sleep scoring figure if PlotFigure is 1
if PlotFigure==1
    % Calculate spectra if they don't alread exist
    if ~(exist('H_Low_Spectrum.mat', 'file') == 2)
        LowSpectrumSB(foldername,channel_hpc,'H');
    end
    if ~(exist('B_High_Spectrum.mat', 'file') == 2)
        HighSpectrum(foldername,channel_bulb,'B');
    end
    
    % Make figure
    Figure_SleepScoring_OBGamma(foldername)
end

end


