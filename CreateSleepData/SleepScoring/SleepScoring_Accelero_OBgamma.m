function SleepScoring_Accelero_OBgamma(varargin)

%==========================================================================
% Details: Sleep Scoring Using Olfactory Bulb and Hippocampal LFP
%          This function creates SleepScoring_OBGamma with sleep scoring 
%          variables and figures 
%
% INPUTS:
%       VARARGINs:
%       - plotfigure    overview figrue of sleep scoring if 1; default is 1
%       - recompute     Recompute events (0 or 1)
%       - smoothwindow  Smoothing. Default = 3 
%       - stimepoch     If stim are present length of stim (optional)
%       - continuity    Enables REM continuity scripts (selectively analyze
%                       epoch containing REM). Default = 1
%       - controlepoch  IntervalSet (1 start time, 1 end time) of epoch
%                       for mean and std value (gamma and theta)
% 
% OUTPUT:
%
% NOTES:
%
%   Written by Sophie Bagur - 01-12-2017
%   Updated 2020-11 Dima - added SleepScoring_Accelero_OBgamma('PlotFigure',1)
%   Updated 2021-03/10 Samuel Laventure 
%                   added: - REM continuity
%                          - Streamlining saving process + aesthetic
%                          - Corrected REM epoch minduration
%                          - Added Theta channel
%      
%  see also, SleepScoringAccelerometer SleepScoringOBGamma
%==========================================================================

%% INITITATION
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
        case 'controlepoch'
            ControlEpoch = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

% check if exist and assign default value if not
if ~exist('PlotFigure','var')
    PlotFigure=1;
end
% smoothing
try
    smootime;
catch
    smootime = 3;
end
% recompute?
if ~exist('recompute','var')
    recompute=0;
end
% rem continuity enable
if ~exist('continuity','var')
    continuity=1;
end
% fill ControlEpoch
if ~exist('ControlEpoch','var')
    ControlEpoch=[];
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


% initilize diary function (save the content of the command line)
diary('SleepScoring_history.txt')

disp(' ')
disp(' ')
disp('MOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBS')
disp(' ')
disp(' ')
disp('============================================================')
disp('|                                                          |')
disp('|              S L E E P    S C O R I N G                  |')
disp('|                     by MOBs lab                          |')
disp('|                                                          |')
disp('============================================================')
disp(' ')
disp('                                           _   _  ')
disp('   Written by Marie Lacroix               (q\_/p) ') 
disp('              Karim Benchenane        .-.  |. .|  ')
disp('              Sophie Bagur               \ =\,/=  ')
disp('              Karim El Kambi              )/ _ \  ')
disp('              Samuel Laventure           (/\):(/\ ')
disp('                                          \_   _/ ')
disp('                                          `""^""` ')   
disp(' ')   

%% Load necessary channels

foldername=pwd;
if foldername(end)~=filesep
    foldername(end+1)=filesep;
end

% OB
if exist('ChannelsToAnalyse/Bulb_deep.mat','file')==2
    load('ChannelsToAnalyse/Bulb_deep.mat')
    channel_bulb=channel;
    doob=1;
else
    dowiob=input('No OB channel, do you want to do only accelerometer-based scoring? 1/0 ');
    if ~dowiob
        error('No OB channel, do not want to continue. Terminated by user');
    else
        doob=0;
    end
end

% HPC theta for REM detection
% Modified by S. Laventure 18/10/2021
% - Looks for ThetaREM instead of HPC_deep or else. 

if exist('ChannelsToAnalyse/ThetaREM.mat','file')==2
    load('ChannelsToAnalyse/ThetaREM.mat')
    channel_theta=channel;
else
    channel=input('Please set a channel for Theta REM detection: ');
    save([pwd '/ChannelsToAnalyse/ThetaREM.mat'],'channel');
    channel_theta=channel;
end

%% create file
Info.minduration=minduration;
if doob
    save('SleepScoring_OBGamma','Info')
end
save('SleepScoring_Accelero','Info')
clear Info


%% Get Noise epochs & save

disp('------------------------------------------------------------')
disp(' STEP 1: DEFINING NOISE EPOCHS')
disp('------------------------------------------------------------')
disp(' ')
[Epoch,TotalNoiseEpoch,SubNoiseEpoch,Info_temp] = FindNoiseEpoch_SleepScoring(channel_theta, ...
    'foldername', foldername);
Info_OB = Info_temp;
Info_accelero = Info_temp;

clear Info_temp
disp(' ')
disp('Noise epoch: DONE')
disp(' ')

%% Find gamma epochs
if doob
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 2: DEFINING WAKE AND SLEEP WITH OB GAMMA')
    disp('------------------------------------------------------------')
    disp(' ')
    disp('Gamma Epochs')
    if ~exist('StimEpoch')
        [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]= ...
            FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
            'smoothwindow', smootime,'controlepoch',ControlEpoch);
    else
        [SleepOB,SmoothGamma,Info_temp,microWakeEpochOB,microSleepEpochOB]= ...
            FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, 'foldername', foldername,...
            'smoothwindow', smootime, 'stimepoch', StimEpoch,'controlepoch',ControlEpoch);
    end
    Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
    Sleep = SleepOB;
    clear Sleep
    disp(' ')
    disp('Bulb Gamma: DONE')
    disp(' ')
else
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 2 SKIPPED: NO OB GAMMA')
    disp('------------------------------------------------------------')
    disp(' ')    
end


%% Find immobility epochs
disp(' ')
disp('------------------------------------------------------------')
disp(' STEP 3: DEFINING IMMOBILITY EPOCHS')
disp('------------------------------------------------------------')
disp(' ')
[ImmobilityEpoch,MovementEpoch,tsdMovement,Info_temp,microWakeEpochAcc,microSleepEpochAcc] = ...
    FindMovementAccelero_SleepScoring(Epoch);
if ~isempty(ImmobilityEpoch)
    is_accelero = true;
    Info_accelero=ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
else
    is_accelero = false;
end
disp(' ')
disp('Immobility: DONE')
disp(' ')

% clear
%% Find Theta epoch
if doob
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 4: DEFINING NREM and REM WITH HPC THETA')
    disp('         for OB Gamma scoring')
    disp('------------------------------------------------------------')
    disp(' ') 
    % restricted to sleep with OB gamma
    if ~exist('StimEpoch')
        [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
            FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_theta, minduration, 'foldername', foldername,...
            'smoothwindow', smootime,'continuity',continuity,'controlepoch',ControlEpoch);
    else
        [ThetaEpoch_OB, SmoothTheta, ~, Info_temp] = ...
            FindThetaEpoch_SleepScoring(SleepOB, Epoch, channel_theta, minduration, 'foldername', foldername,...
            'smoothwindow', smootime, 'stimepoch', StimEpoch,'continuity',continuity,'controlepoch',ControlEpoch);
    end
    Info_OB=ConCatStruct(Info_OB,Info_temp); clear Info_temp;
    clear ThetaEpoch Info;
else
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 4: SKIPPED')
    disp('         no OB Gamma')
    disp('------------------------------------------------------------')
    disp(' ')  
end
disp(' ')
disp('Defining theta epochs for OB Gamma: DONE')
disp(' ')

% restricted to immobility epoch
if is_accelero
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 5: DEFINING NREM and REM WITH HPC THETA')
    disp('         for accelero scoring')
    disp('------------------------------------------------------------')
    disp(' ') 
    disp(' '),disp(' '),disp('Theta Epochs for accelero')
    if ~exist('StimEpoch')
        [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = ...
            FindThetaEpoch_SleepScoring(ImmobilityEpoch, Epoch, channel_theta, minduration,...
            'foldername', foldername,'smoothwindow', smootime,'continuity',continuity);
    else
        [ThetaEpoch_acc, SmoothTheta, ThetaRatioTSD, Info_temp] = ...
            FindThetaEpoch_SleepScoring(ImmobilityEpoch, Epoch, channel_theta, minduration,...
            'foldername', foldername,'smoothwindow', smootime, 'stimepoch', StimEpoch,'continuity',continuity);
    end
    Info_accelero = ConCatStruct(Info_accelero,Info_temp); clear Info_temp;
else 
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 5: SKIPPED')
    disp('         no accelero data')
    disp('------------------------------------------------------------')
    disp(' ') 
end
disp(' ')
disp('Defining theta epochs for accelero: DONE')
disp(' ')
 
%% Define behavioural epochs
disp(' ')
disp('------------------------------------------------------------')
disp(' STEP 6: DEFINING SLEEP STAGES')
disp('------------------------------------------------------------')
disp(' ') 
if doob
    disp('   1) OB Gamma')
    [REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
        ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepOB, ThetaEpoch_OB, minduration,SmoothTheta,Info_OB);
    SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
    Sleep = or(REMEpoch,SWSEpoch);
    Info=Info_OB;
    ThetaEpoch = ThetaEpoch_OB;
    disp('           >>>  Saving OBgamma stages  <<<')
    disp(' ')
    save('SleepScoring_OBGamma','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', ...
        'SWSEpochWiNoise', 'WakeWiNoise','Sleep','SleepWiNoise', ...
        'SmoothGamma','ThetaEpoch','SmoothTheta','Info',...
        'Epoch','SubNoiseEpoch','TotalNoiseEpoch', ...
        'microWakeEpochOB','microSleepEpochOB','-append');
    clear ThetaEpoch Info Sleep;
end
    
if is_accelero
    disp(' ')
    disp('   2) Accelero')
    [REMEpoch,SWSEpoch,Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
        ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, ImmobilityEpoch, ThetaEpoch_acc, minduration,SmoothTheta,Info_accelero);
    SleepWiNoise = or(REMEpochWiNoise,SWSEpochWiNoise);
    Sleep = or(REMEpoch,SWSEpoch);
    Info=Info_accelero;
    ThetaEpoch = ThetaEpoch_acc;
    disp('           >>>  Saving Accelero stages  <<<')
    disp(' ')
    save('SleepScoring_Accelero','REMEpoch','SWSEpoch','Wake','REMEpochWiNoise', ...
        'SWSEpochWiNoise', 'WakeWiNoise','Sleep','SleepWiNoise', ...
        'ImmobilityEpoch','tsdMovement', 'MovementEpoch', ...
        'ThetaEpoch','SmoothTheta', 'ThetaRatioTSD','Info',...
        'Epoch','SubNoiseEpoch','TotalNoiseEpoch', ...
        'microWakeEpochAcc','microSleepEpochAcc','-append');
    clear ThetaEpoch Info Sleep;
end
disp(' ')
disp('Defining sleep stages: DONE')
disp(' ')

%% Make sleep scoring figure if PlotFigure is 1
if PlotFigure==1
    disp(' ')
    disp('------------------------------------------------------------')
    disp(' STEP 7: CREATING FIGURES')
    disp('------------------------------------------------------------')
    disp(' ') 
    
    %OB
    % Calculate spectra if they don't alread exist
    if ~(exist('H_Low_Spectrum.mat', 'file') == 2)
        LowSpectrumSB(foldername,channel_theta,'H');
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
disp(' '), disp(' ')
disp('           SLEEP SCORING COMPLETED')
disp(' ')
disp('    "It could be worse, you could be') 
disp('     studying drosophila" - anonymous, 2021')
disp(' ')
disp('MOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBSMOBS')
diary off
% close all
end


