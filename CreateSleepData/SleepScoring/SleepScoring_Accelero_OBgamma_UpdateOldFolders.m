% SleepScoring_Accelero_OBgamma_UpdateOldFolders
% A modified version of SleepScoring_Accelero_OBgamma that can be run on
% old folders to put the sleep scoring the new format 
% it gets all the infor from StateEpochSB so that the user doesn't have to
% intervene
%
% 01.12.2017 SB - corrected by Dima on 20.11.18: StimEpoch and smoothwindow
% added
%
% SleepScoring_Accelero_OBgamma('PlotFigure',1)
%
% Sleep Scoring Using Olfactory Bulb and Hippocampal LFP
% This function creates SleepScoring_OBGamma with sleep scoring variables
%
%
%INPUTS
% PlotFigure (optional) = overview figrue of sleep scoring if 1; default is 1
%
%
% SEE
%   SleepScoringAccelerometer SleepScoringOBGamma
%


function SleepScoring_Accelero_OBgamma_UpdateOldFolders(varargin)

%% INITITATION
disp('Performing sleep scoring with OB gamma and with Accelerometer')

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
        case 'smoothwindow'
            smootime = varargin{i+1};
            if smootime<=0
                error('Incorrect value for property ''smoothwindow''.');
            end
        case 'stimepoch'
            StimEpoch = varargin{i+1};
            if ~isobject(StimEpoch)
                error('Incorrect value for property ''smoothwindow''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('PlotFigure','var')
    PlotFigure=1;
end
%recompute?
if ~exist('recompute','var')
    recompute=0;
end

% params
minduration = 3;     % abs cut off duration for epochs (sec)

%check if already exist
if ~recompute
    if exist('SleepScoring_OBGamma.mat','file')==2 && exist('SleepScoring_Accelero.mat','file')==2
        disp('Scoring both already generated')
        return
    end
end

try
    smootime;
catch
    smootime = 3;
end

% see if accelerometer exists
if exist('behavResources.mat')>0 
    load('behavResources.mat', 'MovAcctsd');
    if exist('MovAcctsd','var')>0
        DoAccelero = 1;
    else
        DoAccelero = 0;
    end
else
    DoAccelero = 0;
end

% create file
Info.minduration=minduration;
save('SleepScoring_OBGamma','Info')
save('SleepScoring_Accelero','Info')
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
elseif exist('ChannelsToAnalyse/dHPC_sup.mat','file')==2
    load('ChannelsToAnalyse/dHPC_sup.mat')
    channel_hpc=channel;
else
    error('No HPC channel, cannot do sleep scoring');
end


%% Get Noise epochs & save
disp('NoiseEpochs')
if exist('StateEpochSB.mat')>0
    load('StateEpochSB.mat','GndNoiseEpoch','NoiseEpoch','WeirdNoiseEpoch','ThresholdedNoiseEpoch',...
        'ThresholdedNoiseEpochThreshold','GndNoiseThresh','NoiseThresh','Epoch','TotalNoiseEpoch')
    
    % Group the parameters together
    Info_temp.GndNoiseThresh=GndNoiseThresh;
    Info_temp.HighNoiseThresh=NoiseThresh;
    Info_temp.ThresholdedNoiseEpochThresh=ThresholdedNoiseEpochThreshold;
    
    % Group the different NoiseEpochs together
    SubNoiseEpoch.GndNoiseEpoch=GndNoiseEpoch;
    SubNoiseEpoch.HighNoiseEpoch=NoiseEpoch;
    if exist('WeirdNoiseEpoch')>0
        SubNoiseEpoch.WeirdNoiseEpoch=WeirdNoiseEpoch;
    else
        SubNoiseEpoch.WeirdNoiseEpoch = intervalSet(0,0.1*1e4);
    end
    SubNoiseEpoch.ThresholdedNoiseEpoch=ThresholdedNoiseEpoch;
    
    Info_OB = Info_temp;
    Info_accelero = Info_temp;
    
    clear Info_temp
    save('SleepScoring_OBGamma','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')
    save('SleepScoring_Accelero','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')
end


%% Find gamma epochs

disp('Gamma Epochs')
if ~exist('StimEpoch')
    load('StateEpochSB.mat','gamma_thresh')
    [SleepOB,SmoothGamma,Info_temp]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
        'smoothwindow', smootime,'PredefineGammaThresh',gamma_thresh);
else
    load('StateEpochSB.mat','gamma_thresh')
    [SleepOB,SmoothGamma,Info_temp]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
        'smoothwindow', smootime, 'stimepoch', StimEpoch,'PredefineGammaThresh',gamma_thresh);
end
Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;

Sleep = SleepOB;
save('SleepScoring_OBGamma','Sleep','SmoothGamma','-append');
clear Sleep


%% Find immobility epochs

if DoAccelero
    [ImmobilityEpoch, MovementEpoch, tsdMovement, Info_temp] = FindMovementAccelero_SleepScoring('user_confirmation',0);
    Info_accelero=ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
    save('SleepScoring_Accelero','ImmobilityEpoch','tsdMovement', 'MovementEpoch','-append');
end

%% Find Theta epoch
disp('Theta Epochs')

% restricted to sleep with OB gamma
if ~exist('StimEpoch')
    [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = FindThetaEpoch_SleepScoring(SleepOB, channel_hpc, minduration, 'foldername', foldername,...
        'smoothwindow', smootime,'user_confirmation',0);
else
    [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = FindThetaEpoch_SleepScoring(SleepOB, channel_hpc, minduration, 'foldername', foldername,...
        'smoothwindow', smootime, 'stimepoch', StimEpoch,'user_confirmation',0);
end
Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
ThetaEpoch = ThetaEpoch_OB;
save('SleepScoring_OBGamma','ThetaEpoch','SmoothTheta','-append');
clear ThetaEpoch;

% restricted to immobility epoch
if DoAccelero
if ~exist('StimEpoch')
    [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = FindThetaEpoch_SleepScoring(ImmobilityEpoch, channel_hpc, minduration,...
        'foldername', foldername,'smoothwindow', smootime,'user_confirmation',0);
else
    [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = FindThetaEpoch_SleepScoring(ImmobilityEpoch, channel_hpc, minduration,...
        'foldername', foldername,'smoothwindow', smootime, 'stimepoch', StimEpoch,'user_confirmation',0);
end
Info_accelero = ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
ThetaEpoch = ThetaEpoch_acc;
save('SleepScoring_Accelero','ThetaEpoch','SmoothTheta', 'ThetaRatioTSD', '-append');
clear ThetaEpoch;
end


%% Define behavioural epochs
[REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepOB, ThetaEpoch_OB, minduration);
save('SleepScoring_OBGamma','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', 'SWSEpochWiNoise', 'WakeWiNoise','-append');

if DoAccelero
[REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, ImmobilityEpoch, ThetaEpoch_acc, minduration);
save('SleepScoring_Accelero','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', 'SWSEpochWiNoise', 'WakeWiNoise','-append')
end

%% save Info
Info = Info_OB;
save('SleepScoring_OBGamma','Info','-append')
Info = Info_accelero;
save('SleepScoring_Accelero','Info','-append')

if DoAccelero ==0
    delete('SleepScoring_Accelero.mat')
end

%% Make sleep scoring figure if PlotFigure is 1
if PlotFigure==1
    
    %OB
    % Calculate spectra if they don't alread exist
    if ~(exist('H_Low_Spectrum.mat', 'file') == 2)
        LowSpectrumSB(foldername,channel_hpc,'H');
    end
    if ~(exist('B_High_Spectrum.mat', 'file') == 2)
        HighSpectrum(foldername,channel_bulb,'B');
    end
    % Make figure
    Figure_SleepScoring_OBGamma(foldername)
    
    %Accelerometer
    % Make figure
    if DoAccelero
    ratio_display_movement = (max(Data(ThetaRatioTSD))-min(Data(ThetaRatioTSD)))/(max(Data(tsdMovement))-min(Data(tsdMovement)));
    Figure_SleepScoring_Accelero(ratio_display_movement, foldername)
    end
end


end


