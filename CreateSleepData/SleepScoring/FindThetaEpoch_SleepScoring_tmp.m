% FindThetaEpoch_SleepScoring
% 21.11.2017 SB
%
% [ThetaEpoch,smooth_Theta, Info] = FindThetaEpoch_SleepScoring(Epoch,Sleep,chH,mindur,filename)
% 
% This function calculates epochs of high theta
%
%
%%INPUT
% SleepEpoch        : sleep epochs
% minduration       : minimal duration  of theta epochs
% channel_HPC       : HPC channel
% foldername        : location of data & save location
% continuity        : fix continuity issue within theta/rem epochs
%
%
%OUTPUT
% ThetaEpoch        : epoch of high theta during sleep (i.e REM)
% SmoothTheta       : tsd of theta / delta ratio used for scoring
% Info              : structure with all parameters used
%
%
% SEE
%   SleepScoringOBGamma
%

function [ThetaEpoch, SmoothTheta, Info] = FindThetaEpoch_SleepScoring_tmp(SmoothTheta,theta_thresh,SleepEpoch, Epoch, channel_HPC, minduration, varargin)


%% Initiation
if nargin < 3
    error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'user_confirmation'
            user_confirmation = varargin{i+1};
            if user_confirmation~=0 && user_confirmation ~=1
                error('Incorrect value for property ''user_confirmation''.');
            end
        case 'foldername'
            foldername = (varargin{i+1});
        case 'smoothwindow'
            smootime = (varargin{i+1});
        case 'stimepoch'
            StimEpoch = (varargin{i+1});
        case 'continuity'
            continuity = (varargin{i+1});
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('user_confirmation','var')
    user_confirmation=1;
end
if ~exist('continuity','var')
    continuity=0;
end
if ~exist('foldername','var')
    foldername = pwd;
elseif foldername(end)~=filesep
    foldername(end+1) = filesep;
end


% load HPC LFP
load(strcat([foldername,'LFPData/LFP',num2str(channel_HPC),'.mat']));
Time = Range(LFP);
TotalEpoch = intervalSet(Time(1),Time(end));
if exist('StimEpoch')
    LFP = Restrict(LFP,TotalEpoch-StimEpoch);
end

% params
try
    smootime;
catch
    smootime=3;
end

%% find theta epochs
disp(' ');
disp('... Creating Theta Epochs ');
% 
% % get instantaneous Theta / delta ratio
% FilTheta = FilterLFP(LFP,[5 10],1024);
% FilDelta = FilterLFP(LFP,[2 5],1024);
% hilbert_theta = abs(hilbert(Data(FilTheta)));
% hilbert_delta = abs(hilbert(Data(FilDelta)));
% hilbert_delta(hilbert_delta<100) = 100;
% theta_ratio = hilbert_theta ./ hilbert_delta;
% ThetaRatioTSD = tsd(Range(FilTheta), theta_ratio);
% 
% % smooth Theta / delta ratio
% SmoothTheta = tsd(Range(ThetaRatioTSD),runmean(Data(ThetaRatioTSD),ceil(smootime/median(diff(Range(ThetaRatioTSD,'s'))))));

% Get threshold
% log_theta = log(Data(Restrict((SmoothTheta), SleepEpoch)));
% theta_thresh = exp(GetThetaThresh(log_theta, 1, user_confirmation));

disp(['Theta threshold @ ' num2str(theta_thresh)])
% define high theta epochs
ThetaEpoch = thresholdIntervals(SmoothTheta, theta_thresh, 'Direction','Above');
disp('----------------------------------')
disp(['Number of epochs after high thresholding: ' num2str(length(Start(ThetaEpoch)))])

% ---- section added to fix REM continuity issues --------
% 2021-04 by SL
if continuity
    disp('Fixing continuity issues')
    LongThetaEpoch = mergeCloseIntervals(ThetaEpoch, minduration*5*1E4); % long merge
    disp(['Number of epochs after long merge:                  ' num2str(length(Start(LongThetaEpoch)))]) 
    % changer thresh
    nonThetaEpoch = thresholdIntervals(Restrict(SmoothTheta,LongThetaEpoch), theta_thresh/2, 'Direction','Below'); % 2nd thresh 
    disp(['Number of epochs after low thresholding:            ' num2str(length(Start(nonThetaEpoch)))])
    ThetaEpoch = mergeCloseIntervals(LongThetaEpoch-nonThetaEpoch, minduration*1E4);
    disp(['Number of epochs after removal of non-theta epochs: ' num2str(length(Start(ThetaEpoch)))])
    ThetaEpoch = dropShortIntervals(ThetaEpoch, minduration*1E4);
    disp(['Number of epochs after removal of short intervals:  ' num2str(length(Start(ThetaEpoch)))])
    disp('... computing REM epochs ...')
    disp('Fixing REM after wake bouts')
    
    % fix bouts of rem after wake
    Wake = Epoch-SleepEpoch;
    REMEpoch = and(SleepEpoch,ThetaEpoch);  
    REMEpoch = mergeCloseIntervals(REMEpoch,minduration*1e4);
    REMEpoch = dropShortIntervals(REMEpoch,minduration*1e4);
    
    [~, bef_cell] = transEpoch(REMEpoch,Wake);
    REM_After_Wake = bef_cell{1,2};
    disp(['Number of REM epochs after wake:                    ' num2str(length(Start(REM_After_Wake)))])
    if ~isempty(Start(REM_After_Wake))
        fixing = 1;
        i=1;
        while fixing 
            remThetaEpoch = thresholdIntervals(Restrict(SmoothTheta,REM_After_Wake), theta_thresh, 'Direction','Above');
            remThetaEpoch = mergeCloseIntervals(remThetaEpoch, minduration*5*1E4);
            noremThetaEpoch = thresholdIntervals(Restrict(SmoothTheta,remThetaEpoch), theta_thresh/2, 'Direction','Below'); %2nd thresh
            remThetaEpoch = mergeCloseIntervals(remThetaEpoch-noremThetaEpoch, minduration*1E4);
            remThetaEpoch = dropShortIntervals(remThetaEpoch, minduration*1E4);
            wakeThetaEpoch = REM_After_Wake-remThetaEpoch;

            ThetaEpoch = ThetaEpoch-wakeThetaEpoch;
            % verification
            [~, bef_cell] = transEpoch(ThetaEpoch,Wake);
            REM_After_Wake2 = bef_cell{1,2};
            disp(['Verification #' num2str(i) ': after fix, number of REM epochs after wake:' num2str(length(Start(REM_After_Wake2)))])
            i=i+1;
            if isempty(Start(REM_After_Wake)) || i==11
                fixing=0;
            end
        end
    end
    disp(['Final number of theta epochs after fixing wake-rem transitions:' num2str(length(Start(ThetaEpoch)))])
else
    disp('Warning: not fixing continuity issues. To fix such issues relaunch the function including ''continuity'',''1'' as parameters')
end
% -------------------------------------------------------
ThetaEpoch = mergeCloseIntervals(ThetaEpoch, minduration*1E4);
ThetaEpoch = dropShortIntervals(ThetaEpoch, minduration*1E4);

%% generate output
Info.theta_thresh = theta_thresh;
Info.theta_mindur = minduration;
Info.theta_HPC_channel = channel_HPC;

end