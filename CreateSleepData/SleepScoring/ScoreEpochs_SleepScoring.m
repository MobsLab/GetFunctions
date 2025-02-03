% ScoreEpochs_SleepScoring
% 21.11.2017 SB
%
% [REMEpoch, SWSEpoch, Wake] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, Sleep, ThetaEpoch, min_duration)
%
% This function takes as input Sleep and ThetaEpoch to make the final
% epochs of REM, SWS and Wake
%
%
%
%%INPUTS
%
% TotalNoiseEpoch   : epoch of data with all the noise
% Epoch             : epoch of data with no noise
% SleepEpoch        : Sleep Epoch
% ThetaEpoch        : epoch of high theta activity in HPC
% minduration       : minimum duration of events
%
%
%%OUTPUT
%
% REMEpoch          : Intersection of Sleep and ThetaEpoch, drop intervals less than min_duration
% SWSEpoch          : Sleep that is not REMEpoch, drop very short SWS between REM and Wake
% Wake              : The rest of the session (including noise) that is not Sleep
%
%
%%SEE
%   SleepScoringOBGamma
%


function [REMEpoch, SWSEpoch, Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ...
    ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepEpoch, ThetaEpoch, minduration,SmoothTheta,Info)

try
    theta_thresh=Info.theta_thresh;
catch
    load('StateEpochSB.mat', 'Info')
    theta_thresh=Info.theta_thresh;
end

%% Definition of vigilance states

% define REM as overlap of sleep and ThetaEpoch that lasts more than 3s
disp('          ...defining REM')
REMEpoch = and(SleepEpoch,ThetaEpoch);
REMEpoch = mergeCloseIntervals(REMEpoch,minduration*1e4);
REMEpoch = dropShortIntervals(REMEpoch,minduration*1e4);

% define SWS as sleep that is not REM
disp('          ...defining NREM')
SWSEpoch = SleepEpoch-REMEpoch;


disp('          ...defining Wake')
% modified SB 20/11/2018 according to decision made together
% define wake as time (including noise) that is not sleep
WakeWiNoise = or(Epoch,TotalNoiseEpoch)-SleepEpoch;
% clean wake without noise
Wake = Epoch-SleepEpoch;


disp('          ...fixing rem-wake alignement')
% deal with non-alignement of end of REM and beginning of wake --> align if
% less than 2s difference
[~, bef_cell] = transEpoch(SWSEpoch,REMEpoch);
SWS_After_REM = bef_cell{1,2};

[aft_cell, ~] = transEpoch(SWSEpoch,Wake);
SWS_Bef_Wake = aft_cell{1,2};

if ~isempty(SWS_After_REM) && ~isempty(SWS_Bef_Wake)
    disp('          ...removing short NREM between REM and wake')
    % remove short episodes of SWS that are between REM and Wake
    SWS_between_REM_Wake = and(SWS_After_REM,SWS_Bef_Wake);
    SWS_to_delete = dropLongIntervals(SWS_between_REM_Wake,minduration*1e4); %episodes to remove from SWS
    Wake = or(Wake,SWS_to_delete); % add them to Wake
    SWSEpoch = SWSEpoch-SWS_to_delete;
end

% fix bouts of rem after wake - added by SL 2021-05
disp('          ___________________________________________')
disp('')
disp('          -Check-')
[~, bef_cell] = transEpoch(REMEpoch,Wake);
REM_After_Wake = bef_cell{1,2};
disp(['          Number of REM epochs after wake:' num2str(length(Start(REM_After_Wake)))])
if ~isempty(Start(REM_After_Wake))
    disp('                     ...fixing...')
    Theta = thresholdIntervals(SmoothTheta, theta_thresh, 'Direction','Above');
    remThetaEpoch = and(Theta,REM_After_Wake);
    remThetaEpoch = mergeCloseIntervals(remThetaEpoch, minduration*5*1E4);
    tmean = mean(Data(Restrict(SmoothTheta,SleepEpoch)));% find averaged theta
    % get epoch below theta threshold
    noremThetaEpoch = thresholdIntervals(Restrict(SmoothTheta,REM_After_Wake), ...
    theta_thresh-(tmean/2), 'Direction','Below'); %2nd thresh
    remThetaEpoch = mergeCloseIntervals(remThetaEpoch-noremThetaEpoch, minduration*1E4);
    remThetaEpoch = dropShortIntervals(remThetaEpoch, minduration*1E4);
    
    %     SWSEpoch_old = SWSEpoch;
    REMEpoch = or((REMEpoch-REM_After_Wake),remThetaEpoch);
    %     % update wake
    %     newSWS = SWSEpoch_old-SWSEpoch;
    %     SWSEpoch = or(newSWS,SWSEpoch);
    clear REM_After_Wake bef_cell newSWS
    
    % update SleepEpoch for added bouts (with continuity)
    SleepEpoch = or(SleepEpoch,REMEpoch);
    %% SB addition for safety  - 07/06/2024
    
    SleepEpoch = CleanUpEpoch(SleepEpoch);
    REMEpoch = CleanUpEpoch(REMEpoch);
    
    
    % define SWS as sleep that is not REM
    disp('          ...redefining NREM after correction (NREM=Sleep-REM)')
    SWSEpoch = SleepEpoch-REMEpoch;
    
    disp('          ...redefining Wake after correction')
    % clean wake without noise
    Wake = Epoch-SleepEpoch;
    
    % verification
    [~, bef_cell] = transEpoch(REMEpoch,Wake);
    REM_After_Wake = bef_cell{1,2};
    disp('          -After fix-')
    disp(['          Number of REM epochs after wake:' num2str(length(Start(REM_After_Wake)))])
    
end

%% Sanity checks
% There should be no noise during sleep
[aft_cell,bef_cell] = transEpoch(TotalNoiseEpoch,SWSEpoch);
nsleep = and(aft_cell{1,2},bef_cell{1,2});
disp(strcat('          Noise periods during sleep: ',num2str(size(Start(nsleep)/1e4,1))))
if ~isempty(Start(REM_After_Wake))
    disp('          --------------------------------------------')
    disp('          Both should be at zero.')
    disp('          If not, visually check sleep scoring.')
    disp('          It can be due to epochs scored as sleep during a wake period (solution: lower threshold).')
    disp('          Helpful funtion: gui_sleepscoring_verif')
    disp('          ____________________________________________')
end
disp(' ')

disp('          ...clean noise epochs from stages')
disp(' ')

% modified SB 20/11/2018 according to decision made together
% epochs with noise still there
WakeWiNoise = or(Epoch,TotalNoiseEpoch)-SleepEpoch;
REMEpochWiNoise = REMEpoch;
SWSEpochWiNoise = SWSEpoch;

% epochs with no noise
REMEpoch = and(REMEpoch, Epoch);
SWSEpoch = and(SWSEpoch, Epoch);
Wake = and(Wake, Epoch);
end


