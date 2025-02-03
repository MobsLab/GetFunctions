% CreatesoWavesSleep
% 10.11.2017 KJ
%
% Detect 2-channel so waves and save them into 'soWaves.mat'
%
%INPUTS
% structure:            Brain area for the detection (e.g 'PFCx')
% hemisphere:           Right or Left (or None)
% 
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% soOffline:         so waves epochs  
%
%   see CreateSpindlesSleep CreateRipplesSleep CreateDownStatesSleep 


function soOffline = CreateThetaBurstSleep(varargin)

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

InputInfo.freq_so = [0.1 1];
InputInfo.thresh_std = 2;
InputInfo.thresh_std2 = 1;
InputInfo.min_duration = 40;
InputInfo.Saveso = 1;

InputInfo.EventFileName = ['so_' structure hemisphere];

% Epoch
if strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero SWSEpoch TotalNoiseEpoch
    catch
        load StateEpoch SWSEpoch TotalNoiseEpoch
        
        try
            TotalNoiseEpoch;
        catch
            load StateEpoch NoiseEpoch GndNoiseEpoch
            
            try
                TotalNoiseEpoch=or(NoiseEpoch,GndNoiseEpoch);
            catch
                TotalNoiseEpoch=NoiseEpoch;
            end
           save StateEpoch -Append TotalNoiseEpoch
            
        end
        
        
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
    if exist('soWaves.mat','file')==2
        load('soWaves', ['so_' InputInfo.structure suffixe])
        if exist(['so_' InputInfo.structure suffixe],'var')
            disp(['so Waves already generated for ' structure suffixe])
            return
        end
    end
end


%% so waves detection   

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
try
    load([prefixe 'sodeep' suff]);
    if isempty(channel)||isnan(channel), error('channel error'); end
catch
    load([prefixe 'deep' suff]);
    if isempty(channel)||isnan(channel), error('channel error'); end
end    
InputInfo.channel_deep= channel;


%sup

try
    load([prefixe 'soup' suff]);
    if isempty(channel)||isnan(channel), error('channel error'); end
catch
    try
    load([prefixe 'sup' suff]);
    if isempty(channel)||isnan(channel), error('channel error'); end
    catch
       channel = NaN;
       disp('no sup channel')
    end
end
InputInfo.channel_sup = channel;
clear channel


if ~isempty(InputInfo.channel_deep) && ~isempty(InputInfo.channel_sup)
    %loadLFP
    eval(['load LFPData/LFP',num2str(InputInfo.channel_deep)])
    LFPdeep=LFP;
    
    if not(isnan(InputInfo.channel_sup))
    eval(['load LFPData/LFP',num2str(InputInfo.channel_sup)])
    LFPsup=LFP;
    else
        % if there is no LFPsup then nothing is subtracted
        LFPsup = tsd(Range(LFPdeep),Data(LFPdeep)*0);
    end
    
    %% detect so waves

    %normalize
    clear distance
    k=1;
    if not(isnan(InputInfo.channel_sup))
        
        for i=0.1:0.1:4
            distance(k)=std(Data(LFPdeep)-i*Data(LFPsup));
            k=k+1;
        end
        Factor = find(distance==min(distance))*0.1;
    else
        Factor = 0;
    end
    
    %resample & filter & positive value
    EEGsleepDiff = ResampleTSD(tsd(Range(LFPdeep),Data(LFPdeep) - Factor*Data(LFPsup)),100);
    Filt_diff = FilterLFP(EEGsleepDiff, InputInfo.freq_so, 1024);
    pos_filtdiff = max(Data(Filt_diff),0);
    %stdev
    std_diff = std(pos_filtdiff(pos_filtdiff>0));  % std that determines thresholds

    % so detection
    thresh_so = InputInfo.thresh_std * std_diff;
    all_cross_thresh = thresholdIntervals(tsd(Range(Filt_diff), pos_filtdiff), thresh_so, 'Direction', 'Above');
    center_detections = (Start(all_cross_thresh)+End(all_cross_thresh))/2;
    
    %thresholds start ends
    thresh_so2 = InputInfo.thresh_std2 * std_diff;
    all_cross_thresh2 = thresholdIntervals(tsd(Range(Filt_diff), pos_filtdiff), thresh_so2, 'Direction', 'Above');
    %intervals with dections inside
    [~,intervals,~] = InIntervals(center_detections, [Start(all_cross_thresh2), End(all_cross_thresh2)]);
    intervals = unique(intervals); intervals(intervals==0)=[];
    %selected intervals
    all_cross_thresh = subset(all_cross_thresh2,intervals);
   
    
    % Code Modification 2020/03/12 LP : Drop short intervals AFTER
    % restriction to SWS epoch. 
    
    %SWS
    soOffline = and(all_cross_thresh, InputInfo.Epoch);
    % crucial element for noise detection.
    soOffline = dropShortIntervals(soOffline, InputInfo.min_duration * 10); 
    Allso = dropShortIntervals(all_cross_thresh, InputInfo.min_duration * 10);
    

    eval(['so_' InputInfo.structure suffixe ' = soOffline;'])
    eval(['allso_' InputInfo.structure suffixe ' = Allso;'])
    eval(['so_' InputInfo.structure suffixe '_Info = InputInfo;'])



    %% save
    if InputInfo.Saveso
        if exist('soWaves.mat', 'file') == 2
            save('soWaves.mat', ['so_' InputInfo.structure suffixe], ['allso_' InputInfo.structure suffixe], ['so_' InputInfo.structure suffixe '_Info'],'-append')
        else
            save('soWaves.mat', ['so_' InputInfo.structure suffixe], ['allso_' InputInfo.structure suffixe], ['so_' InputInfo.structure suffixe '_Info'])
        end

        %extension evt
        extens = [lower(structure(1:2)) 'd'];
        if ~isempty(hemisphere)
            extens(1) = lower(hemisphere(1));
        end

        %evt
        evt.time = (Start(soOffline) + End(soOffline)) / 2E4;
        for i=1:length(evt.time)
            evt.description{i}= ['so_waves_' InputInfo.structure suffixe];
        end

        delete([InputInfo.EventFileName '.evt.' extens]);
        CreateEvent(evt, InputInfo.EventFileName, extens);
    end

else
    disp('one channel is missing for the detection')
end


end















