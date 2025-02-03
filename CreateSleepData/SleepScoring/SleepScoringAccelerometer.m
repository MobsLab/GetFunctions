% SleepScoringAccelerometer
% 29.11.2017 KJ
%
% SleepScoringAccelerometer('PlotFigure',1)
%
% Sleep Scoring Using Accelerometer and Hippocampal LFP
% This function creates SleepScoring_Accelero with sleep scoring variables
%
%
%INPUTS
% PlotFigure (optional) = overview figrue of sleep scoring if 1; default is 1
%
%
% APADTED from BulbSleepScript
% CALLS FindNoiseEpoch_SleepScoring ; 
% FindThetaEpoch_SleepScoring ; FindMovementAccelero_SleepScoring ;
%
% SEE
%   SleepScoringOBGamma
%


function SleepScoringAccelerometer(varargin)

%% INITITATION
disp('Performing sleep scoring with Accelerometer')

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
    if exist('SleepScoring_Accelero.mat','file')==2
        disp('Already computed! ')
        return
    end
end

% create file
save('SleepScoring_Accelero','')

%% Load necessary channels

foldername=pwd;
if foldername(end)~=filesep
    foldername(end+1)=filesep;
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


%% Get Noise epochs & save
disp('NoiseEpochs')
[Epoch, TotalNoiseEpoch, SubNoiseEpoch, Info_temp] = FindNoiseEpoch_SleepScoring(channel_hpc, 'foldername', foldername, 'user_confirmation', user_confirmation);
Info=Info_temp; clear Info_temp;
save('SleepScoring_Accelero','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')

%% Find theta and movement epochs

% Movement Epoch
disp('MovementAccelero')
[ImmobilityEpoch, MovementEpoch, tsdMovement, Info_temp] = FindMovementAccelero_SleepScoring(Epoch,'user_confirmation', user_confirmation);
Info=ConCatStruct(Info,Info_temp); clear Info_temp;
save('SleepScoring_Accelero','ImmobilityEpoch','tsdMovement', 'MovementEpoch','-append')

SleepEpoch = ImmobilityEpoch;

% Theta epoch
disp('Theta Epochs')
[ThetaEpoch, SmoothTheta, ThetaRatioTSD, Info_temp] = FindThetaEpoch_SleepScoring(SleepEpoch, Epoch, channel_hpc, minduration, 'foldername', foldername, 'user_confirmation', user_confirmation);
Info=ConCatStruct(Info,Info_temp); clear Info_temp;
save('SleepScoring_Accelero','ThetaEpoch','SmoothTheta', 'ThetaRatioTSD', '-append')


%% Define behavioural epochs
disp('ScoreEpochs REM & SWS')
[REMEpoch, SWSEpoch, Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepEpoch, ThetaEpoch, minduration,SmoothTheta,Info);
SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
Sleep = or(REMEpoch,SWSEpoch);
save('SleepScoring_Accelero','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', 'SWSEpochWiNoise', 'WakeWiNoise',...
    'Sleep','SleepWiNoise','-append')


%% save Info 
save('SleepScoring_Accelero','Info','-append')


%% Make sleep scoring figure if PlotFigure is 1
if PlotFigure==1
    % Make figure
    ratio_display_movement = (max(Data(ThetaRatioTSD))-min(Data(ThetaRatioTSD)))/(max(Data(tsdMovement))-min(Data(tsdMovement)));
    Figure_SleepScoring_Accelero(ratio_display_movement, foldername)
end

end


