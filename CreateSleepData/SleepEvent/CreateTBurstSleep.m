% CreateTBurstSleep
% 09.11.2017 KJ
% modified by SL 2020-12
%
% Detect TBurst and save them
%
%INPUTS
% structure:            Brain area for the detection (e.g 'PFCx')
% hemisphere:           Right or Left (or None)
% 
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%%OUTPUT
% TBEpochs:        TBurst epochs  
%
%%SEE 
%   CreateDownStatesSleep CreateRipplesSleep CreateDeltaWavesSleep 
%


function TBEpochs = CreateTBurstSleep(varargin)


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
Info.frequency_band = [4 8];
Info.durations = [500 700 3000];
Info.threshold = [2 3];
Info.EventFileName = ['TBurst_' structure hemisphere];

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
    if exist('TBurst.mat','file')==2
        load('TBurst', ['TBurst_' Info.structure suffixe])
        if exist(['TBurst_'  Info.structure suffixe],'var')
            disp(['TBurst already generated for ' structure suffixe])
            return
        end
    end
end


%% TBurst   
%load channel
prefixe = ['ChannelsToAnalyse/' structure '_' ];

% try
    load([prefixe 'spindle' suffixe]);
    if isempty(channel)||isnan(channel)
        error('channel error'); 
    else
        ch_TB = channel;
    end
% catch
%     load([prefixe 'ecog' suffixe]);
%     if isempty(channel)||isnan(channel)
%         error('channel error'); 
%     else
%         ch_ecog = channel;
%     end
% end



if deep_layer
    load([prefixe 'deep' suffixe]);
    if isempty(channel)||isnan(channel), error('channel error'); end
    Info.layer = 'deep';
    Info.channel = channel;

elseif exist('ch_TB','var')
    Info.layer = 'TB';
    Info.channel = ch_TB;
    
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

LFP_TBurst = LFP;
clear LFP channel

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                    F I N D    S P I N D L E S 
% -------------------------------------------------------------------------
%% TB detection KJ & SL
TBurst= FindThetaBurst(LFP_TBurst, Info.Epoch, 'frequency_band',Info.frequency_band, ...
    'durations',Info.durations,'threshold',Info.threshold,'stim',1);
TBurstEpoch = intervalSet(TBurst(:,1)*1e4, TBurst(:,3)*1e4);
tTBurst = ts(TBurst(:,2)*1e4);

eval(['tTBurst_' Info.structure suffixe ' = tTBurst;'])
eval(['TBurstEpoch_' Info.structure suffixe ' = TBurstEpoch;'])
eval(['TBurst_' Info.structure suffixe '_Info = Info;'])

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            S A V I N G  
% -------------------------------------------------------------------------

if exist('TBurst.mat', 'file') ~= 2
    save('TBurst.mat', 'TBurst', ...
        ['tTBurst_' Info.structure suffixe], ['TBurstEpoch_' Info.structure suffixe], ['TBurst_' Info.structure suffixe '_Info']);
else
    save('TBurst.mat', 'TBurst', ...
        ['tTBurst_' Info.structure suffixe], ['TBurstEpoch_' Info.structure suffixe], ['TBurst_' Info.structure suffixe '_Info'],'-append');
end


%extension evt
extens = ['s' lower(structure(1:2))];
if ~isempty(hemisphere)
    extens(3) = lower(hemisphere(1));
end

%evt classic
clear evt
evt.time = TBurst(:,2);
for i=1:length(evt.time)
    evt.description{i} = ['TBurst' Info.structure suffixe];
end
delete([Info.EventFileName '.evt.' extens]);
CreateEvent(evt, Info.EventFileName, extens)

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            F I G U R E  
% -------------------------------------------------------------------------

set(0,'defaulttextinterpreter','latex');
set(0,'DefaultTextFontname', 'Arial')
set(0,'DefaultAxesFontName', 'Arial')
set(0,'defaultTextFontSize',12)
set(0,'defaultAxesFontSize',12)

% Plot Raw stuff
[M,T]=PlotRipRaw(LFP_TBurst, TBurst(:,1:3), [-1000 1000]);
saveas(gcf, [pathOut '/TBraw.fig']);
print('-dpng','TBraw','-r300');
close(gcf);
save('TBurst.mat','M','T','-append');

% plot average TB
supertit = ['Average TB'];
figure('Color',[1 1 1], 'rend','painters','pos',[10 10 1000 600],'Name', supertit, 'NumberTitle','off')  
    shadedErrorBar([],M(:,2),M(:,3),'-b',1);
    xlabel('Time (ms)')
    ylabel('$${\mu}$$V')   
    title(['Average TB']);      
    xlim([1 size(M,1)])
    set(gca, 'Xtick', 1:25:size(M,1),...
                'Xticklabel', num2cell([floor(M(1,1)*1000):20:ceil(M(end,1)*1000)]))   % need to fix x-tick

    %- save picture
    output_plot = ['average_TB.png'];
    fulloutput = [pathOut output_plot];
    print('-dpng',fulloutput,'-r300');
    
end


