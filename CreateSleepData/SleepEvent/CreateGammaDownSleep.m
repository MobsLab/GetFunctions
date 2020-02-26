% CreateGammaDownSleep
% 24.04.2018 KJ
%
% Detect down from gamma LFP and save them
%
%INPUTS
% structure:            Brain area for the detection (e.g 'PFCx')
% hemisphere:           Right or Left (or None)
% 
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% DeltaOffline:         Delta waves epochs  
%
%   see CreateSpindlesSleep CreateRipplesSleep CreateDownStatesSleep CreateDeltaWavesSleep


function GammaDown = CreateGammaDownSleep(varargin)

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
    scoring='accelero';
end
%recompute?
if ~exist('recompute','var')
    recompute=0;
end


%% params
InputInfo.structure = structure;
InputInfo.hemisphere = hemisphere;
InputInfo.scoring = scoring;

InputInfo.freqGamma = [300 550];
InputInfo.predectDur = 30;
InputInfo.mergeGap = 10;
InputInfo.thresh_std = 1.5;
InputInfo.minDuration = 50;
InputInfo.maxDuration = 700;
InputInfo.SaveDelta = 1;

InputInfo.EventFileName = ['gammadown_' structure hemisphere];

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

InputInfo.Epoch=SWSEpoch-TotalNoiseEpoch;


%check if already exist
if ~recompute
    if exist('GammaDown.mat','file')==2
        load('GammaDown', ['gammadown_' InputInfo.structure suffixe])
        if exist(['gammadown_' InputInfo.structure suffixe],'var')
            disp(['Gamma Down already generated for ' structure suffixe])
            return
        end
    end
end


%% Delta waves detection   
%load
prefixe = ['ChannelsToAnalyse/' structure '_' ];
if strcmpi(suffixe,'_l')
    suff = '_left';
elseif strcmpi(suffixe,'_r')
    suff = '_right';
else
    suff = '';
end

%deep
load([prefixe 'deep' suff]);
InputInfo.channel = channel;


if ~isempty(InputInfo.channel)
    
    %load LFP
    load(['LFPData/LFP' num2str(InputInfo.channel)], 'LFP')

    %% detect gamma down
    %filtered
    FiltLFP = FilterLFP(LFP, InputInfo.freqGamma, 1024);

    %stdev
    std_of_signal = std(Data(Restrict(FiltLFP, InputInfo.Epoch)));  % std that determines thresholds
    thresh = InputInfo.thresh_std * std_of_signal;


    all_cross_thresh = thresholdIntervals(FiltLFP, thresh, 'Direction', 'Below');
    GammaDown = dropShortIntervals(all_cross_thresh, InputInfo.predectDur * 10); 
    GammaDown = mergeCloseIntervals(GammaDown, InputInfo.mergeGap * 10); 
    GammaDown = dropShortIntervals(GammaDown, InputInfo.minDuration * 10); 
    GammaDown = dropLongIntervals(GammaDown, InputInfo.maxDuration * 10); 
    %Restrict to epoch
    GammaDown = and(GammaDown, InputInfo.Epoch);
    
    eval(['gammadown_' InputInfo.structure suffixe ' = GammaDown;'])
    eval(['gammadown_' InputInfo.structure suffixe '_Info = InputInfo;'])


    %% save
    if InputInfo.SaveDelta
        if exist('GammaDown.mat', 'file') == 2
            save('GammaDown.mat', ['gammadown_' InputInfo.structure suffixe], ['gammadown_' InputInfo.structure suffixe '_Info'],'-append')
        else
            save('GammaDown.mat', ['gammadown_' InputInfo.structure suffixe], ['gammadown_' InputInfo.structure suffixe '_Info'])
        end

        %extension evt
        extens = [lower(structure(1:2)) 'd'];
        if ~isempty(hemisphere)
            extens(1) = lower(hemisphere(1));
        end

        %evt
        evt.time = (Start(GammaDown) + End(GammaDown)) / 2E4;
        for i=1:length(evt.time)
            evt.description{i}= ['gamma_down_' InputInfo.structure suffixe];
        end

        delete([InputInfo.EventFileName '.evt.' extens]);
        CreateEvent(evt, InputInfo.EventFileName, extens);
    end

else
    disp('one channel is missing for the detection')
end


end















