% CreateDownStatesSleep
% 10.11.2017 KJ
%
% Detect down states and save them
%
%INPUTS
% structure (optional):     Brain area for the detection (e.g 'PFCx')
% hemisphere (optional):    Right or Left (or None)
% scoring (optional):       method used to distinguish sleep from wake 
%                             'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% Down:                     Down states epochs  
%
%%SEE 
%   CreateSpindlesSleep CreateRipplesSleep CreateDeltaWavesSleep
%

function Down = CreateDownStatesSleep(varargin)

%% Initiation

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'structure'
            structure = varargin{i+1};
        case 'hemisphere'
            hemisphere = lower(varargin{i+1});
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isastring(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
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
% which structure ?
if ~exist('structure','var')
    structure = 'PFCx';
end
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


%% params
InputInfo.structure = structure;
InputInfo.hemisphere = hemisphere;
InputInfo.scoring = scoring;

InputInfo.binsize=10;
InputInfo.thresh0 = 0.7;
InputInfo.min_duration = 50;
InputInfo.max_duration = 700;
InputInfo.mergeGap = 10; % merge
InputInfo.predown_size = 30;
InputInfo.method = 'mono';

InputInfo.EventFileName = 'down_states';
InputInfo.SaveDown = 1;

% Epoch
if strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma SWSEpoch TotalNoiseEpoch
    catch
        load StateEpochSB SWSEpoch TotalNoiseEpoch
    end
elseif strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero SWSEpoch TotalNoiseEpoch
    catch
        load StateEpoch SWSEpoch TotalNoiseEpoch
    end
end


InputInfo.Epoch=SWSEpoch-TotalNoiseEpoch;

%check if already exist
if ~recompute
    if exist('DownState.mat','file')==2
        load('DownState', ['down_' InputInfo.structure suffixe])
        if exist(['down_' InputInfo.structure suffixe],'var')
            disp(['Down states already generated for ' structure suffixe])
            return
        end
    end
end


%% Down states
load('SpikeData', 'S');
try
    try
        eval(['load SpikesToAnalyse/' structure suffixe '_Down'])
    catch
        eval(['load SpikesToAnalyse/' structure suffixe '_Neurons'])
    end
catch
    disp(['SpikesToAnalyse/' structure suffixe '_Neurons not found...' ]);
    Down = intervalSet([],[])
    return
end

NumNeurons=number; clear number
if isempty(NumNeurons)
   disp('No neurons found')
   Down = intervalSet([],[])
   return
end

T=PoolNeurons(S,NumNeurons);
ST{1}=T;
try
    ST=tsdArray(ST);
end
MUA = MakeQfromS(ST, InputInfo.binsize*10); %binsize*10 to be in E-4s
MUA_nrem = Restrict(MUA, InputInfo.Epoch);
%Down
Down = FindDownKJ(MUA_nrem, 'low_thresh', InputInfo.thresh0, 'minDuration', InputInfo.min_duration,'maxDuration', InputInfo.max_duration, 'mergeGap', InputInfo.mergeGap, ...
    'predown_size', InputInfo.predown_size, 'method', InputInfo.method);
AllDown = FindDownKJ(MUA, 'low_thresh', InputInfo.thresh0, 'minDuration', InputInfo.min_duration,'maxDuration', InputInfo.max_duration, 'mergeGap', InputInfo.mergeGap, ...
    'predown_size', InputInfo.predown_size, 'method', InputInfo.method);


eval(['down_' InputInfo.structure suffixe ' = Down;'])
eval(['alldown_' InputInfo.structure suffixe ' = AllDown;'])
eval(['down_' InputInfo.structure suffixe '_Info = InputInfo;'])

%% save
if InputInfo.SaveDown
    if exist('DownState.mat', 'file') == 2
        save('DownState.mat', ['down_' InputInfo.structure suffixe], ['alldown_' InputInfo.structure suffixe], ['down_' InputInfo.structure suffixe '_Info'],'-append')
    else
        save('DownState.mat', ['down_' InputInfo.structure suffixe], ['alldown_' InputInfo.structure suffixe],['down_' InputInfo.structure suffixe '_Info'])
    end

    %extension event
    extens = 'dow';
    if ~isempty(hemisphere)
        extens(3) = lower(hemisphere(1));
    end

    %evt
    evt.time=Start(Down)/1E4;
    for i=1:length(evt.time)
        evt.description{i}='down_states';
    end
    delete([InputInfo.EventFileName '.evt.' extens])
    CreateEvent(evt, InputInfo.EventFileName, extens)

end


end


% SB commented this on 23 nov 2018 because code was crashing
%CreateEvent(evt, 'down_states', 'dow')









