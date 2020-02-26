% MakeIDfunc_ScoringAccelero
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData MakeIDfunc_Neuron MakeIDfunc_Ripples MakeIDfunc_Spindles MakeIDfunc_Sleepstages
%
%


function [gamma, theta, SleepEpoch] = MakeIDfunc_ScoringAccelero(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('recompute','var')
    recompute=0;
end


%% Scoring OB

%load
try, load('SleepScoring_Accelero','Epoch','SWSEpoch','REMEpoch','Info');
    EpochScoring = Epoch;
    SleepEpoch = or(SWSEpoch,REMEpoch);
    gamma.threshold = Info.gamma_thresh;
    theta.threshold = Info.theta_thresh;
catch
    load StateEpochSB Epoch Sleep gamma_thresh theta_thresh
    EpochScoring = Epoch;
    SleepEpoch = Sleep;
    gamma.threshold = gamma_thresh;
    theta.threshold = theta_thresh;
end

%load theta and gamma and Epochs
try
load('SleepScoring_OBGamma','SmoothGamma','SmoothTheta','REMEpoch','SWSEpoch','Wake');
smoothGamma = Restrict(SmoothGamma, EpochScoring);
smoothTheta = Restrict(SmoothTheta, EpochScoring);
gamma.smooth = smoothGamma;
theta.smooth = smoothTheta;
catch
    load('StateEpochSB','smooth_ghi','smooth_Theta','REMEpoch','SWSEpoch','Wake');
smoothGamma = Restrict(smooth_ghi, EpochScoring);
smoothTheta = Restrict(smooth_Theta, EpochScoring);
gamma.smooth = smoothGamma;
theta.smooth = smoothTheta;
end

% Restrict signals to intervalSet
t = Range(smoothTheta);
ti = t(5:1200:end);
smoothGamma = Restrict(smoothGamma, ts(ti));
smoothTheta = Restrict(smoothTheta, ts(ti));

%restrict signals to Epochs
theta.rem = Restrict(smoothTheta, and(EpochScoring,REMEpoch));
gamma.rem = Restrict(smoothGamma, ts(Range(theta.rem)));

theta.sws = (Restrict(smoothTheta,and(EpochScoring,SWSEpoch)));
gamma.sws = Restrict(smoothGamma, ts(Range(theta.sws)));

theta.wake = Restrict(smoothTheta, Wake);
gamma.wake = Restrict(smoothGamma, ts(Range(theta.wake)));


end












