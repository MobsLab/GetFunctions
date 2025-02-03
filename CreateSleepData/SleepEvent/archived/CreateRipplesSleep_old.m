% CreateRipplesSleep
% 09.11.2017 KJ
%
% Detect ripples and save them
%
%INPUTS
% hemisphere:           Right or Left (or None)
% 
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% RipplesEpoch:         Ripples epochs  
%
%   see CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep



function RipplesEpoch = CreateRipplesSleep(varargin)


%% Initiation

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'hemisphere'
            hemisphere = varargin{i+1};
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isstring_FMAToolbox(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        case 'save_data'
            save_data = varargin{i+1};
            if save_data~=0 && save_data ~=1
                error('Incorrect value for property ''save_data''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
% which hemisphere ?
if ~exist('hemisphere','var')
    hemisphere = '';
    suffixe = '';
else
    suffixe = ['_' lower(hemisphere(1))];
end
%type of sleep scoring
if ~exist('scoring','var')
    scoring='ob';
end
%recompute?
if ~exist('recompute','var')
    recompute=0;
end
%save_data?
if ~exist('save_data','var')
    save_data=1;
end


%% params
Info.hemisphere = hemisphere;
Info.scoring = scoring;

Info.threshold = [5 7];
Info.durations = [150 20 200];
Info.frequency_band = [120 250]; 

Info.EventFileName = ['ripples' hemisphere];

% Epoch
if strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero SWSEpoch Wake REMEpoch  TotalNoiseEpoch
    catch
        load StateEpoch SWSEpoch Wake REMEpoch  TotalNoiseEpoch
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma SWSEpoch Wake REMEpoch TotalNoiseEpoch
    catch
        load StateEpochSB SWSEpoch Wake REMEpoch  TotalNoiseEpoch
    end
    
end

Info.Epoch=SWSEpoch-TotalNoiseEpoch;

%check if already exist
if ~recompute
    if exist('Ripples.mat','file')==2
        load('Ripples', ['RipplesEpoch' hemisphere])
        if exist(['RipplesEpoch' hemisphere],'var')
            disp(['Ripples already detected in HPC' suffixe])
            return
        end
    end
end


%% Ripples
%load
load(['ChannelsToAnalyse/dHPC_rip' suffixe],'channel');
if isempty(channel)||isnan(channel), error('channel error'); end
eval(['load LFPData/LFP',num2str(channel)])
HPCrip=LFP;
Info.channel = channel;
clear LFP channel


%% ripples detection SB
[Ripples, meanVal, stdVal] = FindRipplesKJ(HPCrip, Info.Epoch, 'frequency_band',Info.frequency_band, 'threshold',Info.threshold, 'durations',Info.durations);
RipplesEpoch = intervalSet(Ripples(:,1)*10, Ripples(:,3)*10);
tRipples = ts(Ripples(:,2)*10);

eval(['RipplesEpoch' hemisphere '= RipplesEpoch;'])
eval(['ripples_Info' hemisphere '= Info;'])
eval(['tRipples' hemisphere '= tRipples;'])
eval(['meanVal' hemisphere '= meanVal;'])
eval(['stdVal' hemisphere '= stdVal;'])

%% save
if save_data
    if exist('Ripples.mat', 'file') ~= 2
        save('Ripples.mat', ['RipplesEpoch' hemisphere], ['ripples_Info' hemisphere], ['tRipples' hemisphere], ['meanVal' hemisphere], ['stdVal' hemisphere])
    else
        save('Ripples.mat', ['RipplesEpoch' hemisphere], ['ripples_Info' hemisphere], ['tRipples' hemisphere], ['meanVal' hemisphere], ['stdVal' hemisphere], '-append')
    end
    

    %evt classic
    clear evt
    extens = 'rip';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end

    evt.time = Ripples(:,2)/1e3; %peaks
    for i=1:length(evt.time)
        evt.description{i}= ['ripples' hemisphere];
    end
    delete([Info.EventFileName '.evt.' extens]);
    CreateEvent(evt, Info.EventFileName, extens);

end
    
end


