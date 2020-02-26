% CreateLocalDownStatesSleep
% 10.09.2019 KJ
%
% Detect local down states and save them
%
%INPUTS
% structure (optional):     Brain area for the detection (e.g 'PFCx')
% scoring (optional):       method used to distinguish sleep from wake 
%                             'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% LocalDown:                     Down states epochs  
%
%%SEE 
%   CreateSpindlesSleep CreateRipplesSleep CreateDeltaWavesSleep CreateDownStatesSleep
%

function LocalDown = CreateLocalDownStatesSleep(varargin)

%% Initiation

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'structure'
            structure = varargin{i+1};
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
InputInfo.scoring = scoring;

InputInfo.binsize=5;
InputInfo.thresh0 = 0.7;
InputInfo.min_duration = 100;
InputInfo.max_duration = 1000;
InputInfo.mergeGap = 0; % merge
InputInfo.predown_size = 50;
InputInfo.method = 'mono';

InputInfo.EventFileName = 'local_down';
InputInfo.SaveDown = 1;
InputInfo.neurons = [];


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
    if exist('LocalDownState.mat','file')==2
        load('LocalDownState', ['localdown_' InputInfo.structure])
        if exist(['localdown_' InputInfo.structure],'var')
            disp(['Local Down states already generated for ' structure])
            return
        end
    end
end


%% Down states
try
    eval(['load SpikesToAnalyse/' structure '_tetrodes'])
catch
    disp(['SpikesToAnalyse/' structure '_tetrodes not found...' ]);
    LocalDown = intervalSet([],[])
    return
end

NeuronTetrodes = numbers; clear number
if isempty(NeuronTetrodes)
   disp('No neurons found')
   LocalDown = intervalSet([],[]);
   return
end
InputInfo.neurons = NeuronTetrodes;


for tt=1:length(NeuronTetrodes)
    MUA = GetMuaNeurons_KJ(NeuronTetrodes{tt}, 'binsize',InputInfo.binsize);
    MUA_nrem = Restrict(MUA, InputInfo.Epoch);
    
    %all local on whole night
    AllDownLocal{tt} = FindDownKJ(MUA, 'low_thresh', InputInfo.thresh0, 'minDuration', InputInfo.min_duration,'maxDuration', InputInfo.max_duration, 'mergeGap', InputInfo.mergeGap, ...
    'predown_size', InputInfo.predown_size, 'method', InputInfo.method);

    %restricted to nrem
    LocalDown{tt} = FindDownKJ(MUA_nrem, 'low_thresh', InputInfo.thresh0, 'minDuration', InputInfo.min_duration,'maxDuration', InputInfo.max_duration, 'mergeGap', InputInfo.mergeGap, ...
    'predown_size', InputInfo.predown_size, 'method', InputInfo.method);
end

eval(['localdown_' InputInfo.structure ' = LocalDown;'])
eval(['all_local_' InputInfo.structure ' = AllDownLocal;'])
eval(['localdown_' InputInfo.structure '_Info = InputInfo;'])


%% save
if InputInfo.SaveDown
    if exist('LocalDownState.mat', 'file') == 2
        save('LocalDownState.mat', ['localdown_' InputInfo.structure], ['all_local_' InputInfo.structure], ['localdown_' InputInfo.structure '_Info'],'-append')
    else
        save('LocalDownState.mat', ['localdown_' InputInfo.structure], ['all_local_' InputInfo.structure],['localdown_' InputInfo.structure '_Info'])
    end
end


end









