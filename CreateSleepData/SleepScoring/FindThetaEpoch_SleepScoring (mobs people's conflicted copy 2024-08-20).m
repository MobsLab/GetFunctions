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

function [ThetaEpoch, SmoothTheta, ThetaRatioTSD, Info] = FindThetaEpoch_SleepScoring(SleepEpoch, channel_HPC, minduration, varargin)


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
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('user_confirmation','var')
    user_confirmation=1;
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

% get instantaneous Theta / delta ratio
FilTheta = FilterLFP(LFP,[5 10],1024);
FilDelta = FilterLFP(LFP,[2 5],1024);
hilbert_theta = abs(hilbert(Data(FilTheta)));
hilbert_delta = abs(hilbert(Data(FilDelta)));
hilbert_delta(hilbert_delta<100) = 100;
theta_ratio = hilbert_theta ./ hilbert_delta;
ThetaRatioTSD = tsd(Range(FilTheta), theta_ratio);

% smooth Theta / delta ratio
SmoothTheta = tsd(Range(ThetaRatioTSD),runmean(Data(ThetaRatioTSD),ceil(smootime/median(diff(Range(ThetaRatioTSD,'s'))))));

% Get threshold
log_theta = log(Data(Restrict((SmoothTheta), SleepEpoch)));
theta_thresh = exp(GetThetaThresh(log_theta, 1, user_confirmation));

% defien high theta epochs
ThetaEpoch = thresholdIntervals(SmoothTheta, theta_thresh, 'Direction','Above');
ThetaEpoch = mergeCloseIntervals(ThetaEpoch, minduration*1E4);
ThetaEpoch = dropShortIntervals(ThetaEpoch, minduration*1E4);

%% generate output
Info.theta_thresh = theta_thresh;
Info.theta_mindur = minduration;
Info.theta_HPC_channel = channel_HPC;



end