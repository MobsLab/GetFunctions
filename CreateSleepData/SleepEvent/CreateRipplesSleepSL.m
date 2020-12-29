% CreateRipplesSleep
% 09.11.2017 KJ
% Updated 2020-11 SL
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



function RipplesEpoch = CreateRipplesSleepSL(varargin)


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
    thresh=[5 7];
end
%stim
if ~exist('stim','var')
    stim=0;
end

% params
Info.hemisphere = hemisphere;
Info.scoring = scoring;
Info.threshold = thresh; %[5 7];
Info.durations = [15 20 200];
Info.frequency_band = [120 250]; 
Info.EventFileName = ['ripples' hemisphere];

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
        load SleepScoring_Accelero Epoch  TotalNoiseEpoch
    catch
        load StateEpoch Epoch TotalNoiseEpoch
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma Epoch TotalNoiseEpoch
    catch
        load StateEpochSB Epoch TotalNoiseEpoch
    end
    
end

% check if already exist
if ~recompute
    if exist('Ripples.mat','file')==2
        load('Ripples', ['RipplesEpoch' hemisphere])
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
try
    load([pwd '/ChannelsToAnalyse/nonHPC.mat'],'channel');
catch
    warning('Please set a non-ripples channel on HPC and re-run');
    RipplesEpoch = [];
    return
end
nonRip = channel;
eval(['load LFPData/LFP',num2str(nonRip)])
HPCnonRip=LFP;

Info.channel_nonRip = nonRip;
clear LFP  

%% 
% ------------------------------------------------------------------------- 
%                              SECTION
%                       F I N D    R I P P L E S  
% -------------------------------------------------------------------------
Info.Epoch=Epoch-TotalNoiseEpoch;
[Ripples, meanVal, stdVal] = FindRipplesSL(HPCrip, HPCnonRip, Info.Epoch, ...
    'frequency_band',Info.frequency_band, 'threshold',Info.threshold, ...
    'durations',Info.durations,'stim',stim);
RipplesEpoch = intervalSet(Ripples(:,1)*1E4, Ripples(:,3)*1E4);
tRipples = ts(Ripples(:,2)*1E4);

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
    if exist('Ripples.mat', 'file') ~= 2
        save('Ripples.mat', 'Ripples', ['RipplesEpoch' hemisphere], ...
            ['ripples_Info' hemisphere], ['tRipples' hemisphere], ...
            ['meanVal' hemisphere], ['stdVal' hemisphere])
    else
        save('Ripples.mat', 'Ripples', ['RipplesEpoch' hemisphere], ...
            ['ripples_Info' hemisphere], ['tRipples' hemisphere], ...
            ['meanVal' hemisphere], ['stdVal' hemisphere], '-append')
    end
    
    % CREATE event file
    clear evt
    extens = 'rip';
    if ~isempty(hemisphere)
        extens(end) = lower(hemisphere(1));
    end

    evt.time = Ripples(:,2); %peaks
    for i=1:length(evt.time)
        evt.description{i}= ['ripples' hemisphere];
    end
    delete([Info.EventFileName '.evt.' extens]);
    CreateEvent(evt, Info.EventFileName, extens);
end

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
[M,T]=PlotRipRaw(HPCrip, Ripples(:,1:3), [-60 60]);
saveas(gcf, [pathOut '/Rippleraw.fig']);
print('-dpng','Rippleraw','-r300');
close(gcf);
save('Ripples.mat','M','T','-append');

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


