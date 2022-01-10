function spindlesEpoch = CreateSpindlesSleep(varargin)

% =========================================================================
%                            CreatespindlesSleep
% =========================================================================
% DESCRIPTION:  Detect and save spindles.
%               Part of MOBs' CreateSleepSignal pipeline.
%
%               Structure of sSpindles.mat -> Spindles:
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
%               This revised version merges two different technique to
%               detect spindles (absolute and square-root of the LFP). 
%               The older version (absolute only), can be found in the
%               /archived/ folder. 
%
%               Be careful of threshold when detecting. Always visually
%               verify and help yourself with the different event files to
%               know which threshold (mob or zug) to change. 
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       <varargin>
%
%       scoring             Either 'ob' or 'accelero'
%       recompute           Recompute spindles
%       save_data           Do you want to save the figures
%       rmvnoise            Clean artefactual noises
%       stim                Stim or not during sleep
%       plotavg             Do you want to plot the average figure
%       thresh              set specific threshold for spindles
%                           [absolute detection; rootsquare det.]
%                                                           default: [2 3;3 5];
%       structure           PFCx, PACx...
%       hemisphere          Left or right
%       deep
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       spindlesEpoch        spindles start and en timestamps (intervalSet)             
%
% =========================================================================
% VERSIONS
%   09.11.2017 KJ
%   Updated 2020-11 SL: added characteristics extraction
%   Updated 2021-01 SL: uses 2 diff detection techniques 
%   (abs & sqrt) then merges. Commented. 
%
% =========================================================================
% SEE CreateSpindlesSleep CreateDownStatesSleep CreateRipplesSleep
% =========================================================================



%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                     I N I T I A L I Z A T I O N 
% -------------------------------------------------------------------------
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'structure'
            structure = varargin{i+1};
        case 'hemisphere'
            hemisphere = varargin{i+1};
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
        case 'thresh'
            thresh = varargin{i+1};
            if ~isnumeric(thresh)
                error('Incorrect value for property ''thresh''.');
            end
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
            end
        case 'rmvnoise'
            rmvnoise = varargin{i+1};
            if rmvnoise~=0 && rmvnoise ~=1
                error('Incorrect value for property ''rmvnoise''.');
            end
        case 'plotavg'
            plotavg = varargin{i+1};
            if plotavg~=0 && plotavg ~=1
                error('Incorrect value for property ''plotavg''.');
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
    recompute=1;
end
%save_data?
if ~exist('save_data','var')
    save_data=1;
end
%spindle threshold 
if ~exist('thresh','var')
    thresh=[2 3;3 5]; % 1st: thresh for absolute detection; 2nd: thresh for rootsquare det. 
end
%stim
if ~exist('stim','var')
    stim=0;
end
%rmvnoise (non-rip)
if ~exist('rmvnoise','var')
    rmvnoise=1;
end
%stim
if ~exist('plotavg','var')
    plotavg=1;
end
%layer
if ~exist('deep_layer','var')
    deep_layer=0;
end

% params
Info.hemisphere = hemisphere;
Info.scoring = scoring;
Info.frequency_band = [9 18];
Info.durations = [100 300 3000];
Info.threshold = thresh;
Info.EventFileName = ['spl' hemisphere];
Info.structure = structure;

% set folders
[parentdir,~,~]=fileparts(pwd);
pathOut = [pwd '/spindles/' date '/'];
if ~exist(pathOut,'dir')
    mkdir(pathOut);
end

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                         L O A D    D A T A 
% -------------------------------------------------------------------------
if strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero Epoch TotalNoiseEpoch SWSEpoch
    catch
        try
            load StateEpoch Epoch TotalNoiseEpoch SWSEpoch
        catch
            warning('Please, run sleep scoring before extracting spindles!');
            return
        end
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma Epoch TotalNoiseEpoch SWSEpoch
    catch
        try
            load StateEpochSB Epoch TotalNoiseEpoch SWSEpoch
        catch
            warning('Please, run sleep scoring before extracting spindles!');
            return
        end
    end
    
end

%check if already exist
if ~recompute
    if exist('sSpindles.mat','file')==2
        load('sSpindles.mat', ['Spindles_' Info.structure suffixe])
        if exist(['Spindles_'  Info.structure suffixe],'var')
            disp(['Spindles already generated for ' structure suffixe])
            return
        end
    end
end
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
%                       F I N D    S P I N D L E S  
% -------------------------------------------------------------------------

Info.Epoch= Epoch-TotalNoiseEpoch;
Info.SWSEpoch= SWSEpoch-TotalNoiseEpoch;

% Step 1: detect using LFP's absolute value
disp('----------------------------------------')
disp(' ') 
disp('Detecting spindles using absolute value of the LFP')
disp(' ')
[spindles_abs, meanVal, stdVal] = FindSpindlesSB_SL(LFP_spindles, Info.SWSEpoch, 'frequency_band',Info.frequency_band, ...
    'durations',Info.durations,'threshold',Info.threshold(1,:),'stim',1,'clean',1);

% Step 2: detect using LFP's square root 
disp('----------------------------------------')
disp(' ')
disp('Detecting using root-square value of the LFP')
disp(' ')
[spindles_sqrt, stdev] = FindSpindles_sqrt(LFP_spindles, Info.SWSEpoch, Info.threshold(2,:),'clean',1);

% Step 3: merge results
disp('----------------------------------------')
disp(' ')
disp('Merging events')
disp(' ')
% get common spindles and sqrt-detected only 
id{1}=[];id{2}=[];id{3}=[];
ripabs = intervalSet(spindles_abs(:,1)*1E4, spindles_abs(:,3)*1E4);
ripabs_tsd = Restrict(LFP_spindles,ripabs);
for i=1:size(spindles_sqrt,1)
    ripsqrt_ts = intervalSet(spindles_sqrt(i,1)*1E4,spindles_sqrt(i,3)*1E4);
    in = inInterval(ripsqrt_ts,ripabs_tsd);
    if sum(Data(in))
        id{1}(end+1)=i;
    else
        id{2}(end+1)=i;
    end
    clear in
end
% get abs-detected only 
ripsqrt = intervalSet(spindles_sqrt(:,1)*1E4, spindles_sqrt(:,3)*1E4);
ripsqrt_tsd = Restrict(LFP_spindles,ripsqrt);
for i=1:size(spindles_abs,1)
    ripabs_ts = intervalSet(spindles_abs(i,1)*1E4,spindles_abs(i,3)*1E4);
    in = inInterval(ripabs_ts,ripsqrt_tsd);
    if ~sum(Data(in))
        id{3}(end+1)=i;
    end
end

spindles_tmp = [spindles_sqrt([id{1}'; id{2}'],:); spindles_abs(id{3}',:)];
% sorting events by start time
[~,idx] = sort(spindles_tmp(:,1)); % sort just the first column
Spindles = spindles_tmp(idx,:);   % sort the whole matrix using the sort indices

% saving final results
spindles_Info.results.common = length(id{1});
spindles_Info.results.sqrt_only = length(id{2});
spindles_Info.results.abs_only = length(id{3});
spindles_Info.results.total = size(Spindles,1);

% display final results
disp('----------------------------------------')
disp(['SquareRoot spindles only: ' num2str(length(id{2}))])
disp(['Absosulte spindles only : ' num2str(length(id{3}))])
disp(['Common spindles count   : ' num2str(length(id{1}))])
disp('----------------------------------------')
disp(['Spindles FINAL TOTAL    : ' num2str(size(Spindles,1))])
disp('')

% create complementary variables
Info.Description = {'Start(sec)','Peak(sec)','End(sec)','Duration','Frequency','P2P-Amplitude'};
Info.abs.meanVal = meanVal;
Info.abs.stdVal = stdVal;
Info.sqrt.stdev = stdev;
SpindlesEpoch = intervalSet(Spindles(:,1)*1E4, Spindles(:,3)*1E4);
tSpindles = ts(Spindles(:,2)*1E4);

eval(['SpindlesEpoch_' Info.structure suffixe '= SpindlesEpoch;'])
eval(['spindles_Info_' Info.structure suffixe '= Info;'])
eval(['tSpindles_' Info.structure suffixe '= tSpindles;'])
eval(['meanVal_' Info.structure suffixe '= meanVal;'])
eval(['stdVal_' Info.structure suffixe '= stdVal;'])

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            S A V I N G  
% -------------------------------------------------------------------------
if save_data
    disp('----------------------------------------')
    disp(' ')
    disp('Saving data and event file')

    if exist([pwd '/sSpindles.mat'], 'file') ~= 2
        save([pwd '/sSpindles.mat'], 'Spindles', ... 
            ['spindles_Info_' Info.structure suffixe], ...
            ['tSpindles_' Info.structure suffixe], ...
            ['SpindlesEpoch_' Info.structure suffixe]);
    else
        save([pwd '/sSpindles.mat'], 'Spindles', ... 
            ['spindles_Info_' Info.structure suffixe], ...
            ['tSpindles_' Info.structure suffixe], ...
            ['SpindlesEpoch_' Info.structure suffixe],'-append');
    end
    
    % CREATE GENERAL event file  
    clear evt
    extens = 'ssp';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end
    n = size(Spindles,1);
    r = Spindles(:,1:3)';
    evt.time = r(:);
    for i = 1:3:3*n,
        evt.description{i,1} = ['Spindle start ' int2str(Info.channel)];
        evt.description{i+1,1} = ['Spindle peak ' int2str(Info.channel)];
        evt.description{i+2,1} = ['Spindle stop ' int2str(Info.channel)];
    end
    delete([Info.EventFileName '.evt.' extens]);
    CreateEvent(evt, Info.EventFileName, extens);
    
    % CREATE ABS event file  
    clear evt
    extens = 'mob';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end
    n = size(spindles_abs,1);
    r = spindles_abs(:,1:3)';
    evt.time = r(:);
    for i = 1:3:3*n,
        evt.description{i,1} = ['Spindle start ' int2str(Info.channel)];
        evt.description{i+1,1} = ['Spindle peak ' int2str(Info.channel)];
        evt.description{i+2,1} = ['Spindle stop ' int2str(Info.channel)];
    end
    delete(['spindles_abs.evt.' extens]);
    CreateEvent(evt,'spindles_abs', extens);
    
    % CREATE SQRT event file  
    clear evt
    extens = 'zug';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end
    n = size(spindles_sqrt,1);
    r = spindles_sqrt(:,1:3)';
    evt.time = r(:);
    for i = 1:3:3*n,
        evt.description{i,1} = ['Spindle start ' int2str(Info.channel)];
        evt.description{i+1,1} = ['Spindle peak ' int2str(Info.channel)];
        evt.description{i+2,1} = ['Spindle stop ' int2str(Info.channel)];
    end
    delete(['spindles_sqrt.evt.' extens]);
    CreateEvent(evt,'spindles_sqrt', extens);    
end

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            F I G U R E  
% -------------------------------------------------------------------------
if plotavg
    disp('----------------------------------------')
    disp(' ')
    disp('Ploting averages')
    disp(' ')
    % Plot Raw stuff
    [M,T]=PlotRipRaw(LFP_spindles, Spindles(:,1:3),[-1000 1000],'PlotFigure',0);
    saveas(gcf, [pathOut '/Spindleraw.fig']);
    print('-dpng','Spindleraw','-r300');
    close(gcf);
    save('sSpindles.mat','M','T','-append');

    % plot average ripple
    supertit = ['Average spindle'];
    figure('Color',[1 1 1], 'rend','painters','pos',[10 10 1000 600],'Name', supertit, 'NumberTitle','off')  
        shadedErrorBar([],M(:,2),M(:,3),'-b',1);
        xlabel('Time (ms)')
        ylabel('$${\mu}$$V')   
        title(['Average spindle']);      
        xlim([1 size(M,1)])
        set(gca, 'Xtick', 1:25:size(M,1),...
                    'Xticklabel', num2cell([floor(M(1,1)*1000):20:ceil(M(end,1)*1000)]))   

        %- save picture
        output_plot = ['average_spindle.png'];
        fulloutput = [pathOut output_plot];
        print('-dpng',fulloutput,'-r300');
end    
disp('----------------------------------------')
disp(' ')
disp(' DONE ')
end


