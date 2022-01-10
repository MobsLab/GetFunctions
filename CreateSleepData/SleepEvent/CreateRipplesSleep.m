function RipplesEpoch = CreateRipplesSleep(varargin)

% =========================================================================
%                            CreateRipplesSleep
% =========================================================================
% DESCRIPTION:  Detect and save ripples.
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
%               Also saves, waveforms and average, general infos, ripples
%               epochs
%
%               This revised version merges two different technique to
%               detect ripples (absolute and square-root of the LFP). 
%               The older version (absolute only), can be found in the
%               /archived/ folder. 
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       <varargin>
%
%       foldername          Path to folder with SpikeData.mat
%                           (if diff than pwd)
%       scoring             type of sleep scoring 
%                           (accelero or obgamma)
%                                                           default 'ob'
%       recompute           recompute detection (0 or 1)
%                                                           default: 1
%       save_data           save result into SWR.mat
%       thresh              set specific threshold for ripples
%                           [absolute detection; rootsquare det.]
%                                                           default: [4 6; 2 5] 
%       stim                set to 1 if stimulation are present (will
%                           clean). 0 if none (default)
%       rmvnoise            remove false ripples using non-ripples channel
%       plotavg             plot average figure
%       restrict            restrict to SWS epoch to calculate mean and std
%                           parameters
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       RipplesEpoch        Ripples start and en timestamps (intervalSet)             
%
% =========================================================================
% VERSIONS
%   09.11.2017 KJ
%   Updated 2020-11 SL: added characteristics extraction
%   Updated 2021-01 SL: uses 2 diff detection techniques 
%   (abs & sqrt) then merges. Commented. 
%
% =========================================================================
% SEE CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
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
        case 'restrict'
            restrict = varargin{i+1};
            if restrict~=0 && restrict ~=1
                error('Incorrect value for property ''restrict''.');
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
%ripple threshold 
if ~exist('thresh','var')
    thresh=[4 6;2 5]; % 1st: thresh for absolute detection; 2nd: thresh for rootsquare det. 
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
if ~exist('restrict','var')
    restrict=0;
end

% params
Info.hemisphere = hemisphere;
Info.scoring = scoring;
Info.threshold = thresh;
Info.durations = [15 20 200];
Info.frequency_band = [120 250]; 
Info.EventFileName = ['swr' hemisphere];

% set folders
[parentdir,~,~]=fileparts(pwd);
pathOut = [pwd '/Ripples/' date '/'];
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
        load SleepScoring_Accelero Epoch TotalNoiseEpoch SWSEpoch Wake
    catch
        try
            load StateEpoch Epoch TotalNoiseEpoch SWSEpoch Wake
        catch
            warning('Please, run sleep scoring before extracting ripples!');
            return
        end
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma Epoch TotalNoiseEpoch SWSEpoch Wake
    catch
        try
            load StateEpochSB Epoch TotalNoiseEpoch SWSEpoch Wake
        catch
            warning('Please, run sleep scoring before extracting ripples!');
            return
        end
    end
    
end

% check if already exist
if ~recompute
    if exist('SWR.mat','file')==2
        load('SWR', ['RipplesEpoch' hemisphere])
        if exist(['RipplesEpoch' hemisphere],'var')
            disp(['Ripples already detected in HPC' suffixe])
            return
        end
    end
end

%load rip channel
load(['ChannelsToAnalyse/dHPC_rip' suffixe],'channel');
if isempty(channel)||isnan(channel), error('channel error'); end
eval(['load LFPData/LFP',num2str(channel)])
HPCrip=LFP;
Info.channel = channel;
clear LFP channel 

%load non-ripple channel
if rmvnoise
    try
        load([pwd '/ChannelsToAnalyse/nonRip.mat'],'channel');
    catch
        disp(pwd) % add by BM on 25/10/2021
        channel = input('Please set a non-ripples channel on HPC: ');
        save([pwd '/ChannelsToAnalyse/nonRip.mat'],'channel');
    end
    nonRip = channel;
    eval(['load LFPData/LFP',num2str(nonRip)])
    HPCnonRip=LFP;

    Info.channel_nonRip = nonRip;
    clear LFP  
else
    HPCnonRip=[];
end

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                       F I N D    R I P P L E S  
% -------------------------------------------------------------------------

Info.Epoch=Epoch-TotalNoiseEpoch;
if restrict
    Info.Restrict = SWSEpoch;
    % Get longest epoch of sws start and stop times (for zug)
    [~,idx]=max(End(SWSEpoch)-Start(SWSEpoch));
    tsws(1) = Start(subset(SWSEpoch,idx))/1e4;
    tsws(2) = End(subset(SWSEpoch,idx))/1e4;
else
    Info.Restrict = Info.Epoch;
end

% Step 1: detect using LFP's absolute value
disp('----------------------------------------')
disp(' ') 
disp('Detecting using absolute value of the LFP')
disp(' ')
[ripples_abs, meanVal, stdVal] = FindRipples_abs(HPCrip, HPCnonRip, ...
    Info.Epoch, Info.Restrict,'frequency_band',Info.frequency_band, ...
    'threshold',Info.threshold(1,:),'durations',Info.durations,'stim',stim);

% Step 2: detect using LFP's square root 
disp('----------------------------------------')
disp(' ')
disp('Detecting using root-square value of the LFP')
disp(' ')
if restrict
    [ripples_sqrt,stdev] = FindRipples_sqrt(HPCrip, HPCnonRip, Info.Epoch, Info.threshold(2,:), ...
        'clean',1,'restrict',tsws);
else
    [ripples_sqrt,stdev] = FindRipples_sqrt(HPCrip, HPCnonRip, Info.Epoch, Info.threshold(2,:), ...
        'clean',1);
end

% Step 3: merge results
disp('----------------------------------------')
disp(' ')
disp('Merging events')
disp(' ')
% get common ripples and sqrt-detected only 
id{1}=[];id{2}=[];id{3}=[];
ripabs = intervalSet(ripples_abs(:,1)*1E4, ripples_abs(:,3)*1E4);
ripabs_tsd = Restrict(HPCrip,ripabs);
for i=1:size(ripples_sqrt,1)
    ripsqrt_ts = intervalSet(ripples_sqrt(i,1)*1E4,ripples_sqrt(i,3)*1E4);
    in = inInterval(ripsqrt_ts,ripabs_tsd);
    if sum(Data(in))
        id{1}(end+1)=i;
    else
        id{2}(end+1)=i;
    end
    clear in
end
% get abs-detected only 
ripsqrt = intervalSet(ripples_sqrt(:,1)*1E4, ripples_sqrt(:,3)*1E4);
ripsqrt_tsd = Restrict(HPCrip,ripsqrt);
for i=1:size(ripples_abs,1)
    ripabs_ts = intervalSet(ripples_abs(i,1)*1E4,ripples_abs(i,3)*1E4);
    in = inInterval(ripabs_ts,ripsqrt_tsd);
    if ~sum(Data(in))
        id{3}(end+1)=i;
    end
end

ripples_tmp = [ripples_sqrt([id{1}'; id{2}'],:); ripples_abs(id{3}',:)];
% sorting events by start time
[~,idx] = sort(ripples_tmp(:,1)); % sort just the first column
ripples = ripples_tmp(idx,:);   % sort the whole matrix using the sort indices

% saving final results
Info.results.common = length(id{1});
Info.results.sqrt_only = length(id{2});
Info.results.abs_only = length(id{3});
Info.results.total = size(ripples,1);

% display final results
disp('----------------------------------------')
disp(['SquareRoot ripples only: ' num2str(length(id{2}))])
disp(['Absolute ripples only : ' num2str(length(id{3}))])
disp(['Common ripples count   : ' num2str(length(id{1}))])
disp('----------------------------------------')
disp(['RIPPLES FINAL TOTAL    : ' num2str(size(ripples,1))])
disp('')

% create complementary variables
Info.Description = {'Start(sec)','Peak(sec)','End(sec)','Duration','Frequency','P2P-Amplitude'};
Info.abs.meanVal = meanVal;
Info.abs.stdVal = stdVal;
Info.sqrt.stdev = stdev;
RipplesEpoch = intervalSet(ripples(:,1)*1E4, ripples(:,3)*1E4);
tRipples = ts(ripples(:,2)*1E4);


eval(['RipplesEpoch' hemisphere '= RipplesEpoch;'])
eval(['ripples_Info' hemisphere '= Info;'])
eval(['tRipples' hemisphere '= tRipples;'])
eval(['meanVal' hemisphere '= meanVal;'])
eval(['stdVal' hemisphere '= stdVal;'])

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                            S A V I N G  
% -------------------------------------------------------------------------
if save_data
    disp('----------------------------------------')
    disp(' ')
    disp('Saving data and event file')
    if exist('SWR.mat', 'file') ~= 2
        save('SWR.mat', 'ripples', ['RipplesEpoch' hemisphere], ...
            ['ripples_Info' hemisphere], ['tRipples' hemisphere], ...
            ['meanVal' hemisphere], ['stdVal' hemisphere])
    else
        save('SWR.mat', 'ripples', ['RipplesEpoch' hemisphere], ...
            ['ripples_Info' hemisphere], ['tRipples' hemisphere], ...
            ['meanVal' hemisphere], ['stdVal' hemisphere], '-append')
    end
    
    % CREATE event file  
    clear evt
    extens = 'swr';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end
    n = size(ripples,1);
    r = ripples(:,1:3)';
    evt.time = r(:);
    for i = 1:3:3*n,
        evt.description{i,1} = ['Ripple start ' int2str(Info.channel)];
        evt.description{i+1,1} = ['Ripple peak ' int2str(Info.channel)];
        evt.description{i+2,1} = ['Ripple stop ' int2str(Info.channel)];
    end
%     evt.time = ripples(:,2); %peaks
%     for i=1:length(evt.time)
%         evt.description{i}= ['rip peak' hemisphere];
%     end
    delete([Info.EventFileName '.evt.' extens]);
    CreateEvent(evt, Info.EventFileName, extens);
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
    [M,T]=PlotRipRaw(HPCrip, ripples(:,1:3), [-60 60]);
    saveas(gcf, [pathOut '/Rippleraw.fig']);
    print('-dpng','Rippleraw','-r300');
    close(gcf);
    save('SWR.mat','M','T','-append');

try % add by BM on 03/01/2022
    Ripples_IDFigure(ripples,T,RipplesEpoch,Epoch,SWSEpoch,Wake)
end

    % plot average ripple
    supertit = ['Average ripple'];
    figure('Color',[1 1 1], 'rend','painters','pos',[10 10 1000 600],'Name', supertit, 'NumberTitle','off')  
        shadedErrorBar([],M(:,2),M(:,3),'-b',1);
        xlabel('Time (ms)')
        ylabel('$${\mu}$$V')   
        title(['Average ripple']);      
        xlim([1 size(M,1)])
        set(gca, 'Xtick', 1:25:size(M,1),...
                    'Xticklabel', num2cell([floor(M(1,1)*1000):20:ceil(M(end,1)*1000)]))   

        %- save picture
        output_plot = ['average_ripple.png'];
        fulloutput = [pathOut output_plot];
        print('-dpng',fulloutput,'-r300');
end    
disp('----------------------------------------')
disp(' ')
disp(' DONE ')
end


