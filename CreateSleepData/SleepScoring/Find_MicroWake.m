function [WakeEpoch GammaPeak] = Find_MicroWake(varargin)

% defining micro wake (< 3s) during sleep 


%% Initiation
if nargin < 3
    error('Incorrect number of parameters.');
end
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'user_confirmation'
            user_confirmation = varargin{i+1};
            if user_confirmation~=0 && user_confirmation ~=1
                error('Incorrect value for property ''user_confirmation''.');
            end
        case 'foldername'
            foldername = (varargin{i+1});
        case 'smoothwindow'
            smootime = (varargin{i+1});
        case 'predefinegammathresh'
            UserGammaThresh = (varargin{i+1});
        case 'sessepoch'
            SessEpoch = (varargin{i+1});
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('user_confirmation','var')
    user_confirmation=1;
end
if ~exist('foldername','var')
    foldername = pwd;
elseif foldername(end)~=filesep
    foldername(end+1) = filesep;
end
if ~exist('SessEpoch','var')
    res=0;
else
    res=1;
end
% accelero vars
if ~exist('mov_threshold','var')
    mov_threshold = 6e7;
end
if ~exist('mov_dropmerge','var')
    mov_dropmerge = [3 15]; % DropShortIntervals & mergeCloseIntervals
end
if ~exist('immob_dropmerge','var')
    immob_dropmerge = [10 3]; %DropShortIntervals & mergeCloseIntervals
end

%% Loading data
% load channel bulb
load(strcat([foldername,'/ChannelsToAnalyse/Bulb_deep.mat']));
channel_bulb=channel;

% load OB LFP
load(strcat([foldername,'/LFPData/LFP',num2str(channel_bulb),'.mat']));
Time = Range(LFP);
TotalEpoch = intervalSet(Time(1),Time(end));

% load bulb and accelero data
% check file existence
if exist([foldername '/SleepScoring_OBGamma.mat'],'file') && exist([foldername '/SleepScoring_Accelero.mat'],'file')
    ss=2;
    ssac = 1; ssob = 1;
elseif exist([foldername '/SleepScoring_OBGamma.mat'],'file')
    ss=1;
    ssac = 0; ssob = 1;
elseif exist([foldername '/SleepScoring_Accelero.mat'],'file')
    ss=1;
    ssac = 1; ssob = 0;
else
    ss=0;
end
% load sleep scoring
if ss>0
    if ssob
        load([foldername '/SleepScoring_OBGamma.mat'],'Epoch','TotalNoiseEpoch','Info');
    end
    if ssac
        load([foldername '/SleepScoring_Accelero.mat'],'tsdMovement','Sleep');
    end
else
    disp('No bulb or accelero data. Exiting...')
    return
end

% params
try
    smootime;
catch
    smootime=3;
end

%% BULB GAMMA
if ssob
    % get instantaneous gamma power
    if res 
        LFP=Restrict(LFP,SessEpoch);
        Epoch=and(Epoch,SessEpoch);
        TotalNoiseEpoch=and(TotalNoiseEpoch,SessEpoch);
    end
    FilGamma = FilterLFP(LFP,[50 70],1024); % filtering
    tEnveloppeGamma = tsd(Range(LFP), abs(hilbert(Data(FilGamma))) ); %tsd: hilbert transform then enveloppe

    % smooth gamma power
    SmoothGamma = tsd(Range(tEnveloppeGamma), runmean(Data(tEnveloppeGamma), ceil(smootime/median(diff(Range(tEnveloppeGamma,'s'))))));

    % get gamma threshold
    gamma_thresh = Info.gamma_thresh;

    % define sleep epoch
    SleepEpoch_all = thresholdIntervals(SmoothGamma, gamma_thresh, 'Direction','Below');
    SleepEpoch = mergeCloseIntervals(SleepEpoch_all, 3*1e4);
    SleepEpoch = dropShortIntervals(SleepEpoch, 3*1e4);
    % get all wake epochs scored as sleep because too short but were merged earlier
    mw_ob_tmp = (SleepEpoch - SleepEpoch_all) - TotalNoiseEpoch; 
    st = Start(mw_ob_tmp); en = End(mw_ob_tmp);
    ii=0;
    for i=1:length(st)
        if (en(i)-st(i))
            ii=ii+1;
            st_go(ii) = st(i);
            en_go(ii) = en(i);
        end
    end
    mw_ob = intervalSet(st_go,en_go);
    clear st en st_go en_go 
else
    mw_ob = [];
end


%% ACCELERO 
if ssac
    ImmobilityEpoch_all = thresholdIntervals(tsdMovement, mov_threshold, 'Direction','Below');
    % SleepEpoch_drop = dropShortIntervals(and(ImmobilityEpoch_all,ImmobilityEpoch), 3*1e4);
    mw_acc_tmp = (Sleep - ImmobilityEpoch_all) - TotalNoiseEpoch;
    st = Start(mw_acc_tmp); en = End(mw_acc_tmp);
    % get rid of interval length of 0
    ii=0;
    for i=1:length(st)
        if (en(i)-st(i))
            ii=ii+1;
            st_go(ii) = st(i);
            en_go(ii) = en(i);
        end
    end
    mw_acc = intervalSet(st_go,en_go);
    clear st en st_go en_go 
else
    mw_acc = [];
end

%% MERGING
mw_all_tmp = or(mw_acc,mw_ob);
mw_all_tmp = mergeCloseIntervals(mw_all_tmp, 3*1e4);
mw_all = dropShortIntervals(mw_all_tmp, .25*1e4);

mw.all = mw_all;
mw.acc = mw_acc;
mw.ob = mw_ob;
    
%% defining micro wake and sleep for figures and event files
% WakeEpoch = (Epoch-SleepEpoch)-TotalNoiseEpoch;

% get peak gamma amplitude
st = Start(mw_ob);
en = End(mw_ob);
if st
    for i=1:length(st)
        mw_tsd = Restrict(SmoothGamma,intervalSet(st(i),en(i)));
        GammaPeak(i) = max(Data(peaks(mw_tsd)));
    end
end
clear st en

% histogram
figure, hist((End(mw_all)-Start(mw_all))/1e4,50),xlim([0 3])

%% EVENT FILES
% CREATE GENERAL event file  
st = Start(mw_all);
en = End(mw_all);

if st
    extens = 'mwk';
    n = length(st);
    r = [st/1e4 en/1e4]';
    evt.time = r(:);
    for i = 1:2:2*n,
        evt.description{i,1} = 'MW START';
        evt.description{i+1,1} = 'MW END';
    end
    delete(['microwake.evt.' extens]);
    CreateEvent(evt, 'microwake', extens);
end
clear evt st en n r 

% CREATE gamma only event file  
if ssob
    st = Start(mw_ob);
    en = End(mw_ob);

    extens = 'mwo';
    n = length(st);
    r = [st/1e4 en/1e4]';
    evt.time = r(:);
    for i = 1:2:2*n,
        evt.description{i,1} = 'MW OB START';
        evt.description{i+1,1} = 'MW OB END';
    end
    delete(['microwake_OB.evt.' extens]);
    CreateEvent(evt, 'microwake_OB', extens);

    clear evt st en n r 
end

% CREATE ACCELEO event file  
if ssac
    st = Start(mw_acc);
    en = End(mw_acc);

    extens = 'mwa';
    n = length(st);
    r = [st/1e4 en/1e4]';
    evt.time = r(:);
    for i = 1:2:2*n,
        evt.description{i,1} = 'MW ACCELERO START';
        evt.description{i+1,1} = 'MW ACCELERO END';
    end
    delete(['microwake_accelero.evt.' extens]);
    CreateEvent(evt, 'microwake_accelero', extens);

    clear evt st en n r 
    
    st= Start(mw_acc); en=End(mw_acc);
    i=i+1;plot(Data(Restrict(tsdMovement,intervalSet(st(i)-5000,en(i)+5000)))); yline(mov_threshold)
    
    