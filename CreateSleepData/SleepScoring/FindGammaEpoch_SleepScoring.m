
% FindGammaEpoch_SleepScoringOBGamma
% 21.11.2017 SB
%
% [SleepEpoch, SmoothGamma, Info] = FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, foldername)
%
% This function calculates epochs of low gamma corresponding to sleep
% 
%
%%INPUT
% Epoch             : epoch of data with no noise
% channel_bulb      : OB channel
% minduration       : minimal duration  of sleep epochs
% foldername        : location of data & save location
%       - controlepoch  IntervalSet (1 start time, 1 end time) of epoch
%                       for mean and std value (gamma and theta)
%
%
%%OUTPUT
% SleepEpoch        : epoch of sleep
% SmoothGamma       : tsd of gamma power used for scoring
% Info              : structure with all parameters used
%
%
% SEE 
%   SleepScoringOBGamma
%


function [SleepEpoch,SmoothGamma,Info,microWakeEpoch,microSleepEpoch] = FindGammaEpoch_SleepScoring(Epoch, channel_bulb, minduration, varargin)

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
        case 'predefinegammathresh'
            UserGammaThresh = (varargin{i+1});
        case 'controlepoch'
            ControlEpoch = varargin{i+1};
        case 'frequency'
            Frequency = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end
% fill ControlEpoch
if ~exist('ControlEpoch','var')
    ControlEpoch=[];
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


% load OB LFP
load(strcat([foldername,'LFPData/LFP',num2str(channel_bulb),'.mat']));
Time = Range(LFP);
TotalEpoch = intervalSet(Time(1),Time(end));

% restrict LFP - stim
if exist('StimEpoch')
    LFP = Restrict(LFP,TotalEpoch-StimEpoch);
end
    
% params
try
    smootime;
catch
    smootime=3;
end

% add by BM on 06/02/2024
% choose gamma frequency 
if ~exist('Frequency','var')
    Frequency = [50 70];
    disp('Note, that chosen Gamma frequency is 50-70Hz')
end



%% find gamma epochs
disp(' ');
disp('... Creating Gamma Epochs ');

% get instantaneous gamma power
FilGamma = FilterLFP(LFP,Frequency,1024); % filtering
tEnveloppeGamma = tsd(Range(LFP), abs(hilbert(Data(FilGamma))) ); %tsd: hilbert transform then enveloppe
  
% SB 18/05/2018: removed the restrict here so that gamma power is
% calculated everywhere
% gamma_high = Restrict(tEnveloppeGamma, Epoch); % restrict

% smooth gamma power
SmoothGamma = tsd(Range(tEnveloppeGamma), runmean(Data(tEnveloppeGamma), ...
    ceil(smootime/median(diff(Range(tEnveloppeGamma,'s'))))));


% get gamma threshold
if exist('UserGammaThresh','var')
    gamma_thresh = UserGammaThresh;
else
    if ~isempty(ControlEpoch)
        gamma_thresh = GetGammaThresh(Data(Restrict(Restrict(SmoothGamma,Epoch),ControlEpoch)), user_confirmation);
    else
        gamma_thresh = GetGammaThresh(Data(Restrict(SmoothGamma,Epoch)), user_confirmation);
    end
    gamma_thresh = exp(gamma_thresh);
end

% define sleep epoch
SleepEpoch_all = thresholdIntervals(SmoothGamma, gamma_thresh, 'Direction','Below');
SleepEpoch = mergeCloseIntervals(SleepEpoch_all, minduration*1e4);
SleepEpoch = dropShortIntervals(SleepEpoch, minduration*1e4);

% defining micro wake and sleep (< 3s; added by SL: 2021-05;2021-10 (3s instead of 2s))
SleepEpoch_drop = dropShortIntervals(and(SleepEpoch_all,SleepEpoch), 3*1e4);
microWakeEpoch = SleepEpoch - SleepEpoch_drop;
Wake_all = Epoch-SleepEpoch;
Wake_drop = dropShortIntervals(Wake_all, 3*1e4);
microSleepEpoch = Wake_all - Wake_drop;

% SB 18/05/2018: Restrict to Epoch to get rid of noise --> we revoked this
% decision
% SleepEpoch =  and(SleepEpoch, Epoch);

%% generate output
Info.gamma_thresh      = gamma_thresh;
Info.gamma_minduration = minduration;
Info.gamma_OB_channel  = channel_bulb;
if ~isempty(ControlEpoch), Info.controlepoch = 'yes'; end


end

