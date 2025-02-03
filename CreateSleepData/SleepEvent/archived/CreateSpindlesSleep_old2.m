function SpindleEpochs = CreateSpindlesSleep(varargin)

% =========================================================================
%                            CreateRipplesSleep
% =========================================================================
% DESCRIPTION:  Detect and save spindles.
%               Part of MOBs' CreateSleepSignal pipeline.
%
%               Structure of SWR.mat -> ripples:
%                   ----------------------------
%                   - Start (in seconds)
%                   - Peak (in seconds)
%                   - End (in seconds)
%                   - Duration (in milliseconds)
%                   - Frequency
%                   - Max p2p amplitude
%                   ----------------------------
%               Also saves, waveforms and average, general infos, spindles
%               epochs
%
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       <varargin>
%
%       scoring             type of sleep scoring 
%                           (accelero or obgamma)
%                                                           default 'ob'
%       deep                if detection should be done on PFC deep layer
%       recompute           recompute detection (0 or 1)
%                                                           default: 1
%       stim                stimulations artefact? (0 or 1)
%                                                           default: 0
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       SpindlesEpoch       Spindles start and en timestamps (intervalSet)             
%
% =========================================================================
% VERSIONS
%   09.11.2017 KJ
%   Updated 2020-12 SL: updated
%
% =========================================================================
% SEE CreateSleepSlignal CreateDownStatesSleep CreateDeltaWavesSleep
% =========================================================================

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
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
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
%stim
if ~exist('stim','var')
    stim=0;
end


%% params
Info.structure = structure;
Info.hemisphere = hemisphere;
Info.scoring = scoring;
Info.frequency_band = [9 18];
Info.frequency_low = [9 13];
Info.frequency_high = [13 18];
Info.durations = [100 300 3000];
Info.threshold = [1.5 2]; %[2 3];
Info.EventFileName = ['spindles_' structure hemisphere];

% set folders
[parentdir,~,~]=fileparts(pwd);
pathOut = [pwd '/Spindles/' date '/'];
if ~exist(pathOut,'dir')
    mkdir(pathOut);
end

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                         L O A D    D A T A 
% -------------------------------------------------------------------------
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

load([prefixe 'spindle' suffixe]);
if isempty(channel)||isnan(channel)
    error('channel error'); 
else
    ch_spindle = channel;
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

LFP_spindles = LFP;
clear LFP channel

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                    F I N D    S P I N D L E S 
% -------------------------------------------------------------------------
%% spindle detection KJ & SL
Spindles= FindSpindlesSB_SL(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_band, ...
    'durations',Info.durations,'threshold',Info.threshold,'stim',1);
SpindlesEpoch = intervalSet(Spindles(:,1)*1e4, Spindles(:,3)*1e4);
tSpindles = ts(Spindles(:,2)*1e4);

eval(['tSpindles_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_' Info.structure suffixe ' = SpindlesEpoch;'])
eval(['spindles_' Info.structure suffixe '_Info = Info;'])


%low frequency
spindles_low = FindSpindlesSB_SL(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_low, ...
    'durations',Info.durations,'threshold',Info.threshold,'stim',1);
SpindlesEpoch = intervalSet(spindles_low(:,1)*1e4, spindles_low(:,3)*1e4);
tSpindles = ts(spindles_low(:,2)*1e4);

eval(['tSpindles_low_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_low_' Info.structure suffixe ' = SpindlesEpoch;'])


%high freaquency
spindles_high = FindSpindlesSB_SL(LFP_spindles, Info.Epoch, 'frequency_band',Info.frequency_high, ...
    'durations',Info.durations,'threshold',Info.threshold,'stim',1);
SpindlesEpoch = intervalSet(spindles_high(:,1)*1e4, spindles_high(:,3)*1e4);
tSpindles = ts(spindles_high(:,2)*1e4);

eval(['tSpindles_high_' Info.structure suffixe ' = tSpindles;'])
eval(['SpindlesEpoch_high_' Info.structure suffixe ' = SpindlesEpoch;'])

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            S A V I N G  
% -------------------------------------------------------------------------

if exist('Spindles.mat', 'file') ~= 2
    save('Spindles.mat', 'Spindles', 'spindles_low', 'spindles_high', ...
        ['tSpindles_' Info.structure suffixe], ['SpindlesEpoch_' Info.structure suffixe], ['spindles_' Info.structure suffixe '_Info'], ...
        ['tSpindles_low_' Info.structure suffixe], ['SpindlesEpoch_low_' Info.structure suffixe],...
        ['tSpindles_high_' Info.structure suffixe], ['SpindlesEpoch_high_' Info.structure suffixe]);
else
    save('Spindles.mat', 'Spindles', 'spindles_low', 'spindles_high', ...
        ['tSpindles_' Info.structure suffixe], ['SpindlesEpoch_' Info.structure suffixe], ['spindles_' Info.structure suffixe '_Info'], ...
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

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            F I G U R E  
% -------------------------------------------------------------------------

% Plot Raw stuff
[M,T]=PlotRipRaw(LFP_spindles, Spindles(:,1:3), [-1000 1000]);
saveas(gcf, [pathOut '/Spindleraw.fig']);
print('-dpng','Spindleraw','-r300');
close(gcf);
save('Spindles.mat','M','T','-append');

% plot average spindle
supertit = ['Average spindle'];
figure('Color',[1 1 1], 'rend','painters','pos',[10 10 1000 600],'Name', supertit, 'NumberTitle','off')  
    shadedErrorBar([],M(:,2),M(:,3),'-b',1);
    xlabel('Time (ms)')
    ylabel('$${\mu}$$V')   
    title(['Average spindle']);      
    xlim([1 size(M,1)])
    set(gca, 'Xtick', 1:25:size(M,1),...
                'Xticklabel', num2cell([floor(M(1,1)*1000):20:ceil(M(end,1)*1000)]))   % need to fix x-tick

    %- save picture
    output_plot = ['average_spindle.png'];
    fulloutput = [pathOut output_plot];
    print('-dpng',fulloutput,'-r300');
    
end


