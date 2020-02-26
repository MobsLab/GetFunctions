% MakeIDfunc_LfpOnDown
% 08.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_DownDelta MakeIDfunc_SleepEvent MakeIDfunc_LfpInfo
%
%


function [meancurves, channel_list, structures, peak_value] = MakeIDfunc_LfpOnDown(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'durations'
            durations = lower(varargin{i+1});
        case 'windowsize'
            windowsize = lower(varargin{i+1});
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
if ~exist('durations','var')
    durations=[150 250] * 10; %in ts
end
if ~exist('windowsize','var')
    windowsize=1600; %in ms
end
if ~exist('windowsize','var')
    windowsize=1600; %in ms
end

binsize  = 5; %for mETAverage  
nbBins = windowsize / binsize; %for mETAverage


%% Structures
list_cortex = {'PFCx', 'PaCx', 'AuCx', 'MoCx', 'PiCx','S1Cx'};
%structures with down states
down_structures = cell(0);
%%% ASK KJ about this
for i=1:length(list_cortex)
    try
    temp_down = GetDownStates('area',list_cortex{i});
    if ~isempty(temp_down)
        eval(['down_' list_cortex{i} ' = temp_down;'])
    end
%     load('DownState', ['down_' list_cortex{i}])
    if exist(['down_' list_cortex{i}],'var')
        down_structures{end+1} = list_cortex{i};
    end
    end
end

%channels of each structures
meancurves = cell(0);
channel_list = [];
structures = cell(0);

for i=1:length(down_structures)
    %down
        Down = GetDownStates('area',down_structures{i});

%     load('DownState.mat', ['down_' down_structures{i}])
%     eval(['Down = down_' down_structures{i} ';'])
    start_down = Start(Down);
    down_durations = End(Down) - Start(Down);
    start_down = start_down(down_durations>durations(1) & down_durations<durations(2));
    
    %LFP with corresponding events
    if exist(['ChannelsToAnalyse/' down_structures{i} '_locations.mat'],'file')==2
        load('ChannelsToAnalyse/PFCx_locations.mat','channels')
    else
        channels = GetDifferentLocationStructure(down_structures{i});
    end
    
    k=length(meancurves);
    for ch=1:length(channels)
        load(['LFPData/LFP' num2str(channels(ch))], 'LFP')
        [m,~,tps] = mETAverage(start_down, Range(LFP), Data(LFP), binsize, nbBins);
        meancurves{ch+k}(:,1) = tps/1000; meancurves{ch+k}(:,2) = m;        
        clear LFP
        
        channel_list = [channel_list channels(ch)];
        structures{ch+k} = down_structures{i};
    end
    
end


%% order by max value
for i=1:length(meancurves)
    x_down = meancurves{i}(:,1)>0 & meancurves{i}(:,1)<0.2;
    
    if sum(meancurves{i}(x_down,2))>0
        peak_value(i) = max(meancurves{i}(x_down,2));
    else
        peak_value(i) = min(meancurves{i}(x_down,2));
    end
    
end



end




