% MakeIDfunc_SleepEvent
% 05.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_DownDelta
%
%


function [deltas, down, ripples, spindles, night_duration] = MakeIDfunc_SleepEvent(varargin)


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

%params isi
step=100;
edges=0:step:5000;
%params density
smoothing = 1;
windowsize = 60E4; %60s


%% load
deltas_PFCx = GetDeltaWaves('area','PFCx');

if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
    down_PFCx = GetDownStates('area','PFCx');
end

% to del after check - SB
% load('DeltaWaves.mat', 'deltas_PFCx')
% if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
% load('DownState.mat', 'down_PFCx')
% end

try
%     load('Ripples.mat', 'Ripples')
    [tRipples, RipplesEpoch] = GetRipples;
catch
    no_ripples=1;
end

try
% load('Spindles.mat', 'spindles_PFCx')
[tSpindles, SpindlesEpoch] = GetSpindles('area','PFCx');
end


%intervals for density
try
    load('LFPData/LFP0','LFP')
catch
    load('LFPData/InfoLFP.mat','InfoLFP')
    load(['LFPData/LFP' num2str(InfoLFP.channel(1))],'LFP')    
end
night_duration = max(Range(LFP));
intervals_start = 0:windowsize:night_duration;    
x_intervals = (intervals_start + windowsize/2)/(3600E4);
clear LFP


%% delta 
deltas_tmp = (Start(deltas_PFCx) + End(deltas_PFCx)) / 2;

%amount
deltas.nb = length(deltas_tmp);

%density
deltas.density.y = zeros(length(intervals_start),1);
for t=1:length(intervals_start)
    intv = intervalSet(intervals_start(t),intervals_start(t) + windowsize);
    deltas.density.y(t) = length(Restrict(ts(deltas_tmp),intv))/60; %per sec
end
deltas.density.x = x_intervals;
%smooth
deltas.density.y = Smooth(deltas.density.y, smoothing);

%ISI
h1_deltas = histogram(diff(deltas_tmp/10), edges);
deltas.isi.x = h1_deltas.BinEdges(1:end-1);
deltas.isi.y = h1_deltas.Values; close

if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
%% down 
down_tmp = (Start(down_PFCx) + End(down_PFCx)) / 2;

%amount
down.nb = length(down_tmp);

%density
down.density.y = zeros(length(intervals_start),1);
for t=1:length(intervals_start)
    intv = intervalSet(intervals_start(t),intervals_start(t) + windowsize);
    down.density.y(t) = length(Restrict(ts(down_tmp),intv))/60; %per sec
end
down.density.x = x_intervals;
%smooth
down.density.y = Smooth(down.density.y, smoothing);

%ISI
h1_down = histogram(diff(down_tmp/10), edges);
down.isi.x = h1_down.BinEdges(1:end-1);
down.isi.y = h1_down.Values; close

else
    down.nb = NaN;
    down.isi.x = NaN;
    down.isi.y= NaN;
    down.density.y= NaN;
    down.density.x = NaN;
end


%% ripples
if exist('Ripples','var')
%     ripples_tmp = Ripples(:,2);
    ripples_tmp =  Range(tRipples,'s');
elseif exist('ripples','var')
    ripples_tmp =  Range(tRipples,'s');
else
    ripples_tmp = [];
end

%amount
ripples.nb = length(ripples_tmp);

%density
ripples.density.y = zeros(length(intervals_start),1);
for t=1:length(intervals_start)
    intv = intervalSet(intervals_start(t),intervals_start(t) + windowsize);
    ripples.density.y(t) = length(Restrict(ts(ripples_tmp),intv))/60; %per sec
end
ripples.density.x = x_intervals;
%smooth
ripples.density.y = Smooth(ripples.density.y, smoothing);

%ISI
h1_ripples = histogram(diff(ripples_tmp/10), edges);
ripples.isi.x = h1_ripples.BinEdges(1:end-1);
ripples.isi.y = h1_ripples.Values; close


%% spindles 
if exist('tSpindles','var')
% spindles_tmp = spindles_PFCx(:,2);
spindles_tmp = Range(tSpindles,'s');
else
spindles_tmp = [];
end

%amount
spindles.nb = length(spindles_tmp);

%density
spindles.density.y = zeros(length(intervals_start),1);
for t=1:length(intervals_start)
    intv = intervalSet(intervals_start(t),intervals_start(t) + windowsize);
    spindles.density.y(t) = length(Restrict(ts(spindles_tmp),intv))/60; %per sec
end
spindles.density.x = x_intervals;
%smooth
spindles.density.y = Smooth(spindles.density.y, smoothing);

%ISI
h1_spindles = histogram(diff(spindles_tmp/10), edges);
spindles.isi.x = h1_spindles.BinEdges(1:end-1);
spindles.isi.y = h1_spindles.Values; close

end












