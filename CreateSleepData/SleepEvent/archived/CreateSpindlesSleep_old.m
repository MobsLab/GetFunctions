% CreateSpindlesSleep
% 09.11.2017 KJ
%
% Detect spindles and save them
%
%INPUTS
% structure:            Brain area for the detection (e.g 'PFCx')
% hemisphere:           Right or Left (or None)
% 
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% SpindleEpochs:        Spindles epochs  
%
%%SEE 
%   CreateDownStatesSleep CreateRipplesSleep CreateDeltaWavesSleep 
%


function SpindleEpochs = CreateSpindlesSleep(varargin)


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
            if ~isstring_FMAToolbox(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        case 'deep'
            deep_layer = varargin{i+1};
            if deep_layer~=0 && deep_layer ~=1
                error('Incorrect value for property ''deep''.');
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
%layer
if ~exist('deep_layer','var')
    deep_layer=0;
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
Info.structure = structure;
Info.hemisphere = hemisphere;
Info.scoring = scoring;
Info.frequency_band = [10 16];
Info.frequency_low = [10 13];
Info.frequency_high = [13 16];
Info.durations = [100 350 200000];

Info.EventFileName = ['spindles_' structure hemisphere];

% Epoch
if strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero SWSEpoch TotalNoiseEpoch
    catch
        load StateEpoch SWSEpoch TotalNoiseEpoch
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma SWSEpoch TotalNoiseEpoch
    catch
        load StateEpochSB SWSEpoch TotalNoiseEpoch
    end
    
end

Info.Epoch=SWSEpoch-TotalNoiseEpoch;

%check if already exist
if ~recompute
    if exist('Spindles.mat','file')==2
        load('Spindles', ['spindles_' Info.structure suffixe])
        if exist(['spindles_'  Info.structure suffixe],'var')
            disp(['Spindles already generated for ' structure suffixe])
            return
        end
    end
end


%% Spindles   
%load channel
prefixe = ['ChannelsToAnalyse/' structure '_' ];

try
    load([prefixe 'spindle' suffixe]);
    if isempty(channel)||isnan(channel)
        error('channel error'); 
    else
        ch_spindle = channel;
    end
% catch
%     load([prefixe 'ecog' suffixe]);
%     if isempty(channel)||isnan(channel)
%         error('channel error'); 
%     else
%         ch_ecog = channel;
%     end
end



if deep_layer
    load([prefixe 'deep' suffixe]);
    if isempty(channel)||isnan(channel), error('channel error'); end
    Info.layer = 'deep';
    Info.channel = channel;

elseif exist('ch_spindle','var')
    Info.layer = 'spindle';
    Info.channel = ch_spindle;
    
elseif exist('IdFigureData2.mat','file')==2
    load('IdFigureData2.mat', 'channel_curves','structures_curves', 'peak_value')
    channel_curves = channel_curves(strcmpi(structures_curves, Info.structure));
    peak_value = peak_value(strcmpi(structures_curves, Info.structure));
    
    [value, idx] = min(peak_value);
    Info.layer = num2str(round(value,2));
    Info.channel = channel_curves(idx);
    
else
    load([prefixe 'sup' suffixe]);
    if isempty(channel)||isnan(channel), error('channel error'); end
    Info.layer = 'sup';
    Info.channel = channel;
end


%LFP tsd
eval(['load LFPData/LFP',num2str(Info.channel)])
LFP_spindles=LFP;
clear LFP channel


%% spindle detection KJ
Spindles= FindSpindlesKJ(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_band, 'durations',Info.durations);
SpindlesEpoch = intervalSet(Spindles(:,1)*1e4, Spindles(:,3)*1e4);
tSpindles = ts(Spindles(:,2)*1e4);

eval(['tSpindles_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_' Info.structure suffixe ' = SpindlesEpoch;'])
eval(['spindles_' Info.structure suffixe '_Info = Info;'])


%low frequency
spindles_low = FindSpindlesKJ(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_low, 'durations',Info.durations);
SpindlesEpoch = intervalSet(spindles_low(:,1)*1e4, spindles_low(:,3)*1e4);
tSpindles = ts(spindles_low(:,2)*1e4);

eval(['tSpindles_low_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_low_' Info.structure suffixe ' = SpindlesEpoch;'])


%high freaquency
spindles_high = FindSpindlesKJ(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_high, 'durations',Info.durations);
SpindlesEpoch = intervalSet(spindles_high(:,1)*1e4, spindles_high(:,3)*1e4);
tSpindles = ts(spindles_high(:,2)*1e4);

eval(['tSpindles_high_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_high_' Info.structure suffixe ' = SpindlesEpoch;'])


%% save
if save_data
    if exist('Spindles.mat', 'file') ~= 2
        save('Spindles.mat', ['tSpindles_' Info.structure suffixe], ['SpindlesEpoch_' Info.structure suffixe], ['spindles_' Info.structure suffixe '_Info'], ...
            ['tSpindles_low_' Info.structure suffixe], ['SpindlesEpoch_low_' Info.structure suffixe],...
            ['tSpindles_high_' Info.structure suffixe], ['SpindlesEpoch_high_' Info.structure suffixe]);
    else
        save('Spindles.mat', ['tSpindles_' Info.structure suffixe], ['SpindlesEpoch_' Info.structure suffixe], ['spindles_' Info.structure suffixe '_Info'], ...
            ['tSpindles_low_' Info.structure suffixe], ['SpindlesEpoch_low_' Info.structure suffixe],...
            ['tSpindles_high_' Info.structure suffixe], ['SpindlesEpoch_high_' Info.structure suffixe],'-append');
    end
    

    %extension evt
    extens = ['s' lower(structure(1:2))];
    if ~isempty(hemisphere)
        extens(3) = lower(hemisphere(1));
    end

    %evt classic
    clear evt
    evt.time = Spindles(:,2);
    for i=1:length(evt.time)
        evt.description{i} = ['spindles' Info.structure suffixe];
    end
    delete([Info.EventFileName '.evt.' extens]);
    CreateEvent(evt, Info.EventFileName, extens)

end
    
end


