% MakeIDfunc_Sleepstages
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData MakeIDfunc_Neuron MakeIDfunc_Ripples MakeIDfunc_Spindles
%
%


function [SleepStages, Epochs, time_in_substages, meanDuration_substages, percentvalues_NREM] = MakeIDfunc_Sleepstages(varargin)


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
        case 'binsize'
            binsize = varargin{i+1};

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
if ~exist('binsize','var')
    binsize=500; %50ms
end
%params

%% load
load('SleepSubstages', 'Epoch', 'NameEpoch')


%% Sleep stages
Record_period = or(or(Epoch{6},Epoch{4}),Epoch{5}); %SWS+WAKE+REM
Epochs = Epoch(1:5);
y_substage=[2 1.5 1 3 4]; %ordinate in graph

indtime = min(Start(Record_period)):binsize:max(Stop(Record_period));
timeTsd = ts(indtime);
rg = Range(timeTsd);

SleepStages = zeros(1,length(rg))+4.5;
time_in_substages = zeros(1,5);
sample_size = median(diff(rg))/10; %in ms
meanDuration_substages = zeros(1,5);
for ep=1:length(Epochs)
    idx = find(ismember(rg, Range(Restrict(timeTsd,Epochs{ep})))==1);
    SleepStages(idx) = y_substage(ep);
    time_in_substages(ep) = length(idx) * sample_size;
    meanDuration_substages(ep) = mean(diff([0;find(diff(idx)~=1);length(idx)])) * sample_size;
end
SleepStages = tsd(rg,SleepStages');
percentvalues_NREM = zeros(1,3);
for ep=1:3
    percentvalues_NREM(ep) = time_in_substages(ep)/sum(time_in_substages(1:3));
end
percentvalues_NREM = round(percentvalues_NREM*100,2);

end












