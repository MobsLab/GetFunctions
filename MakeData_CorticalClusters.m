%%MakeData_CorticalClusters
% 18.12.2018 KJ
%
%   Attributes clusters (layers) to channels
%   
%
% see
%   MakeData_PFCxClustersKJ
%


function clusters = MakeData_CorticalClusters(varargin)


%% CHECK INPUTS
if mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end

%params
area='PFCx';
list_channels = 'locations';
durations = [125 175] * 10; %of down
amplitude_range = [-1000 -10 60 200 300 600];
factorLFP = 0.195;
binsize_met  = 5; %for mETAverage  
nbBins_met   = 240; %for mETAverage 

%% load down states
try
    down_states = GetDownStates('area', area, 'foldername', foldername);
    down_states = dropShortIntervals(down_states, durations(1));
    down_states = dropLongIntervals(down_states, durations(2));
    start_down = Start(down_states);
catch
    start_down = [];
end

if isempty(start_down)
    delta_PFCx = GetDeltaWaves;
    delta_PFCx = dropShortIntervals(delta_PFCx, durations(1));
    delta_PFCx = dropLongIntervals(delta_PFCx, durations(2));
    start_down = Start(delta_PFCx);
end


%% list of cortical channels
Signals = cell(0);

if strcmpi(list_channels,'all')
    load(fullfile(foldername, 'LFPData', 'InfoLFP.mat'))
    channels = InfoLFP.channel(strcmpi(InfoLFP.structure,area));
else
   %LFP with corresponding events
    if exist(['ChannelsToAnalyse/' area '_locations.mat'],'file')==2
        load(['ChannelsToAnalyse/' area '_locations.mat'],'channels')
    else
        channels = GetDifferentLocationStructure(area);
    end 
end

for ch=1:length(channels)
    load(['LFPData/LFP' num2str(channels(ch))], 'LFP')
    Signals{ch} = LFP; clear LFP
end

%ECOG ?
ecogs = [];
if exist('ChannelsToAnalyse/PFCx_ecog.mat','file')==2
    load('ChannelsToAnalyse/PFCx_ecog.mat','channel')
    ecogs = [ecogs channel];
end
if exist('ChannelsToAnalyse/PFCx_ecog_right.mat','file')==2
    load('ChannelsToAnalyse/PFCx_ecog_right.mat','channel')
    ecogs = [ecogs channel];
end
if exist('ChannelsToAnalyse/PFCx_ecog_left.mat','file')==2
    load('ChannelsToAnalyse/PFCx_ecog_left.mat','channel')
    ecogs = [ecogs channel];
end
ecogs = unique(ecogs);


%% 
for ch=1:length(channels)
    [m,~,tps] = mETAverage(start_down, Range(Signals{ch}), Data(Signals{ch}), binsize_met, nbBins_met);
    meandown{ch}(:,1) = tps; meandown{ch}(:,2) = m;
end

%% Put new points in clusters

Xp = [];
%features
for ch=1:length(channels)
    x = meandown{ch}(:,1);
    y = meandown{ch}(:,2)*factorLFP;

    %postive deflection
    if sum(y(x>0 & x<=150))>0
        x1 = x>0 & x<=200;
        Xp(ch,1) = max(y(x1));
    %negative deflection
    else
        x1 = x>0 & x<=250;
        Xp(ch,1) = min(y(x1));
    end
end

%clustering
clusters = nan(length(Xp),1);
for c=1:length(amplitude_range)-1
    cond = Xp>amplitude_range(c) & Xp<=amplitude_range(c+1);
    clusters(cond) = c+1;
end
clusters(ismember(channels,ecogs))=1;



%% save layers info
save(fullfile(foldername,'ChannelsToAnalyse','PFCx_clusters.mat'),'clusters', 'channels')


end



