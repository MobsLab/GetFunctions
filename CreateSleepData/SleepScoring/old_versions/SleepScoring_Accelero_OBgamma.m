% SleepScoring_Accelero_OBgamma
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


function SleepScoring_Accelero_OBgamma(varargin)

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
                error('Incorrect value for property ''stimepoch''.');
            end
        case 'continuity'
            continuity = varargin{i+1};
            if continuity~=0 && continuity ~=1
                error('Incorrect value for property ''continuity''.');
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
if ~exist('continuity','var')
    continuity=0;
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
    dowiob=input('No OB channel, you want to do only accelerometer-based scoring? 1/0 ');
    if ~dowiob
        error('No OB channel, do not want ');
    end
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


%% create file
Info.minduration=minduration;
if exist('dowiob','var')
    if ~dowiob
        save('SleepScoring_OBGamma','Info')
    end
else
    save('SleepScoring_OBGamma','Info')
end
save('SleepScoring_Accelero','Info')
clear Info


%% Get Noise epochs & save
disp('NoiseEpochs')
[Epoch,TotalNoiseEpoch,SubNoiseEpoch,Info_temp] = FindNoiseEpoch_SleepScoring(channel_hpc, 'foldername', foldername);
Info_OB = Info_temp;
Info_accelero = Info_temp;

clear Info_temp
if exist('dowiob','var')
    if ~dowiob
        save('SleepScoring_OBGamma','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')
    end
else
    save('SleepScoring_OBGamma','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')
end
save('SleepScoring_Accelero','Epoch','SubNoiseEpoch','TotalNoiseEpoch','-append')


%% Find gamma epochs
if exist('dowiob','var')
    if ~dowiob
        disp('Gamma Epochs')
        if ~exist('StimEpoch')
            [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
                'smoothwindow', smootime);
        else
            [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
                'smoothwindow', smootime, 'stimepoch', StimEpoch);
        end
        Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
        
        Sleep = SleepOB;
        save('SleepScoring_OBGamma','Sleep','SmoothGamma','-append');
        clear Sleep
    end
else
    disp('Gamma Epochs')
    if ~exist('StimEpoch')
        [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
            'smoothwindow', smootime);
    else
        [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]=FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
            'smoothwindow', smootime, 'stimepoch', StimEpoch);
    end
    Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
    
    Sleep = SleepOB;
    save('SleepScoring_OBGamma','Sleep','SmoothGamma','-append');
    clear Sleep
end


%% Find immobility epochs
disp('Defining immobility epochs')
[ImmobilityEpoch, MovementEpoch, tsdMovement, Info_temp,microWakeEpochAcc,microSleepEpochAcc] = FindMovementAccelero_SleepScoring(Epoch);
if ~isempty(ImmobilityEpoch)
    is_accelero = true;
    Info_accelero=ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
    save('SleepScoring_Accelero','ImmobilityEpoch','tsdMovement', 'MovementEpoch','-append');
else
    is_accelero = false;
end


%% Find Theta epoch
disp('Theta Epochs for OBgamma')
if exist('dowiob','var')
    if ~dowiob
        % restricted to sleep with OB gamma
        if ~exist('StimEpoch')
            [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
                FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_hpc, minduration, 'foldername', foldername,...
                'smoothwindow', smootime,'continuity',continuity);
        else
            [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
                FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_hpc, minduration, 'foldername', foldername,...
                'smoothwindow',smootime,'stimepoch',StimEpoch,'continuity',continuity);
        end
        Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
        ThetaEpoch = ThetaEpoch_OB;
        save('SleepScoring_OBGamma','ThetaEpoch','SmoothTheta','-append');
        clear ThetaEpoch;
    end
else
    % restricted to sleep with OB gamma
    if ~exist('StimEpoch')
        [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
            FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_hpc, minduration, 'foldername', foldername,...
            'smoothwindow', smootime,'continuity',continuity);
    else
        [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
            FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_hpc, minduration, 'foldername', foldername,...
            'smoothwindow', smootime, 'stimepoch', StimEpoch,'continuity',continuity);
    end
    Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
    ThetaEpoch = ThetaEpoch_OB;
    save('SleepScoring_OBGamma','ThetaEpoch','SmoothTheta','-append');
    clear ThetaEpoch;
end

% restricted to immobility epoch
if is_accelero
    disp('Theta Epochs for accelero')
    if ~exist('StimEpoch')
        [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = ...
            FindThetaEpoch_SleepScoring(ImmobilityEpoch, Epoch, channel_hpc, minduration,...
            'foldername', foldername,'smoothwindow', smootime,'continuity',continuity);
    else
        [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = ...
            FindThetaEpoch_SleepScoring(ImmobilityEpoch, Epoch, channel_hpc, minduration,...
            'foldername', foldername,'smoothwindow', smootime, 'stimepoch', StimEpoch,'continuity',continuity);
    end
    Info_accelero = ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
    ThetaEpoch = ThetaEpoch_acc;
    save('SleepScoring_Accelero','ThetaEpoch','SmoothTheta', 'ThetaRatioTSD', '-append');
    clear ThetaEpoch;
end


%% Define behavioural epochs
disp('Defining stages')
if exist('dowiob','var')
    if ~dowiob
        [REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
            ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepOB, ThetaEpoch_OB, minduration);
        SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
        Sleep = or(REMEpoch,SWSEpoch);
        disp('Saving OBgamma stages')
        save('SleepScoring_OBGamma','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', ...
            'SWSEpochWiNoise', 'WakeWiNoise','Sleep','SleepWiNoise','-append');
    end
else
    [REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
        ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepOB, ThetaEpoch_OB, minduration);
    SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
    Sleep = or(REMEpoch,SWSEpoch);
    disp('Saving OBgamma stages')
    save('SleepScoring_OBGamma','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', ...
        'SWSEpochWiNoise', 'WakeWiNoise','Sleep','SleepWiNoise','-append');
end
    
if is_accelero
    [REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
        ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, ImmobilityEpoch, ThetaEpoch_acc, minduration);
    SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
    Sleep = or(REMEpoch,SWSEpoch);
    disp('Saving accelero stages')
    save('SleepScoring_Accelero','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', ...
        'SWSEpochWiNoise', 'WakeWiNoise','Sleep','SleepWiNoise','-append');
end

%% save Info
disp('Updating info variable')
if exist('dowiob','var')
    if ~dowiob
        Info = Info_OB;
        save('SleepScoring_OBGamma','Info','-append')
    end
else
    Info = Info_OB;
    save('SleepScoring_OBGamma','Info','-append')
end

if is_accelero
    Info = Info_accelero;
    save('SleepScoring_Accelero','Info','-append')
end


%% Make sleep scoring figure if PlotFigure is 1
if PlotFigure==1
    disp('----------------')
    disp('Creating figures')
    disp('----------------')
    
    %OB
    % Calculate spectra if they don't alread exist
    if ~(exist('H_Low_Spectrum.mat', 'file') == 2)
        LowSpectrumSB(foldername,channel_hpc,'H');
    end
    if exist('dowiob','var')
        if ~dowiob
            if ~(exist('B_High_Spectrum.mat', 'file') == 2)
                HighSpectrum(foldername,channel_bulb,'B');
            end
        end
    else
        if ~(exist('B_High_Spectrum.mat', 'file') == 2)
            HighSpectrum(foldername,channel_bulb,'B');
        end
    end
    % Make figure
    if exist('dowiob','var')
        if ~dowiob
            Figure_SleepScoring_OBGamma(foldername)
        end
    else
        Figure_SleepScoring_OBGamma(foldername)
    end
    
    %Accelerometer
    % Make figure
    if is_accelero
        ratio_display_movement = (max(Data(ThetaRatioTSD))-min(Data(ThetaRatioTSD)))/(max(Data(tsdMovement))-min(Data(tsdMovement)));
        Figure_SleepScoring_Accelero(ratio_display_movement, foldername)
    end
    
end

disp('---- SLEEP SCORING COMPLETED ----')
end


