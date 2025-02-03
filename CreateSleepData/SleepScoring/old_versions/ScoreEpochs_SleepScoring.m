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


function [REMEpoch, SWSEpoch, Wake,REMEpochWiNoise, SWSEpochWiNoise, WakeWiNoise] = ScoreEpochs_SleepScoring(TotalNoiseEpoch, Epoch, SleepEpoch, ThetaEpoch, minduration)


%% Definition of vigilance states

% define REM as overlap of sleep and ThetaEpoch that lasts more than 3s
disp('...defining REM')
REMEpoch = and(SleepEpoch,ThetaEpoch);  
REMEpoch = mergeCloseIntervals(REMEpoch,minduration*1e4);
REMEpoch = dropShortIntervals(REMEpoch,minduration*1e4);

% define SWS as sleep that is not REM
disp('...defining NREM')
SWSEpoch = SleepEpoch-REMEpoch;


disp('...defining Wake')
% modified SB 20/11/2018 according to decision made together
% define wake as time (including noise) that is not sleep
WakeWiNoise = or(Epoch,TotalNoiseEpoch)-SleepEpoch;
% clean wake without noise
Wake = Epoch-SleepEpoch;


disp('...fixing rem-wake alignement')
% deal with non-alignement of end of REM and beginning of wake --> align if
% less than 2s difference
[~, bef_cell] = transEpoch(SWSEpoch,REMEpoch);
SWS_After_REM = bef_cell{1,2};

[aft_cell, ~] = transEpoch(SWSEpoch,Wake);
SWS_Bef_Wake = aft_cell{1,2};

if ~isempty(SWS_After_REM) && ~isempty(SWS_Bef_Wake)
    disp('...removing short NREM between REM and wake')
    % remove short episodes of SWS that are between REM and Wake
    SWS_between_REM_Wake = and(SWS_After_REM,SWS_Bef_Wake);
    SWS_to_delete = dropLongIntervals(SWS_between_REM_Wake,minduration*1e4); %episodes to remove from SWS
    Wake = or(Wake,SWS_to_delete); % add them to Wake
    SWSEpoch = SWSEpoch-SWS_to_delete;
end


%% Sanity checks 

disp('...Verifications:')
% There should be no noise during sleep 
[aft_cell,bef_cell] = transEpoch(TotalNoiseEpoch,SWSEpoch);
nsleep = and(aft_cell{1,2},bef_cell{1,2});
disp(strcat('noise periods during sleep :',num2str(size(Start(nsleep)/1e4,1))))
disp( ' ')

% There should be no wake to REM transitions 
[aft_cell, ~]=transEpoch(Wake,REMEpoch);
disp( ' ')
disp(strcat('wake to REM transitions :',num2str(size(Start(aft_cell{1,2}),1))))


disp('...clean noise epochs from stages')
% modified SB 20/11/2018 according to decision made together
% epochs with noise still there
REMEpochWiNoise = REMEpoch;
SWSEpochWiNoise = SWSEpoch;

% epochs with no noise 
REMEpoch = and(REMEpoch, Epoch);
SWSEpoch = and(SWSEpoch, Epoch);
Wake = and(Wake, Epoch);



end


