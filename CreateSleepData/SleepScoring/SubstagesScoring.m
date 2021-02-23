%SubstagesScoring
% 22.11.2017 KJ
% 
% [Epoch, NameEpoch] = SubstagesScoring(varargin)
%
%%INPUT
% featuresNREM:
% NoiseEpoch:
% 
%%OUTPUT
% Epoch:
% NameEpoch:
%
% SEE 
%   DefineSubStagesNew 
%
% a reminder of how featuresNREM is defined
% 
%     featuresNREM{1} = sup_OsciEpochSleep; %S34
%     featuresNREM{2} = deep_OsciEpochSleep; %S34;
%     featuresNREM{3} = SpindlesEpoch;
%     featuresNREM{4} = BurstDeltaEpoch_2_700; %N3
%     featuresNREM{5} = REMEpoch;
%     featuresNREM{6} = Wake;
%     featuresNREM{7} = SWSEpoch;
%     featuresNREM{8} = EpochSleepSlowPF; %PFCx
%     featuresNREM{9} = EpochSleepSlowOB; %OB
%     featuresNREM{10} = BurstDeltaEpoch_3_700; %N3etN4
%     featuresNREM{11} = BurstDeltaEpoch_2_1000; %N3etN4
%     featuresNREM{12} = BurstDeltaEpoch_3_1000; %N3etN4
%
% UPDATES:
%   2020-12-14 by SL: fixed use of burst 3 vs 2 delta condition

function [Epoch, NameEpoch] = SubstagesScoring(featuresNREM, NoiseEpoch, varargin)


if nargin < 2 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

%% INITIATION
disp('Running FindNREMEpochSleeps.m')
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'removesi'
            RemoveSI = varargin{i+1};
            if RemoveSI~=0 && RemoveSI ~=1
                error('Incorrect value for property ''RemoveSI''.');
            end
        case 'burstis3'
            BurstIs3 = varargin{i+1};
            if BurstIs3~=0 && BurstIs3 ~=1
                error('Incorrect value for property ''BurstIs3''.');
            end
        case 'newburstthresh'
            newBurstThresh = varargin{i+1};
            if newBurstThresh~=0 && newBurstThresh ~=1
                error('Incorrect value for property ''newBurstThresh''.');
            end
        case 'verbose'
            verbose = varargin{i+1};
            if verbose~=0 && verbose ~=1
                error('Incorrect value for property ''verbose''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('RemoveSI','var')
    RemoveSI=0;
end
if ~exist('BurstIs3','var')
    BurstIs3=1;
end
if ~exist('newBurstThresh','var')
    newBurstThresh=0;
end
if ~exist('verbose','var')
    verbose=0;
end

%params
NameEpoch = {'N1','N2','N3','REM','WAKE','SI','SWS','swaPF','swaOB','TOTSleep','WAKEnoise'};

t_mergeEp=3; % in second
t_dropEp=1;


warning('off','all')
%% Sleep stages and substages

% sleep and SI
sleep = or(featuresNREM{5},featuresNREM{7});
sleep = mergeCloseIntervals(sleep,3E4);
if RemoveSI
    SI = sleep-dropShortIntervals(sleep,15E4);
    SI = mergeCloseIntervals(SI,10);
    SI = CleanUpEpoch(SI);
    sleep = dropShortIntervals(sleep,15E4); % 15s
else
    sleep = dropShortIntervals(sleep,2E4);
    SI = intervalSet([],[]);
end
sleep = CleanUpEpoch(sleep);

% REM
REM = and(featuresNREM{5},sleep);
REM = mergeCloseIntervals(REM,t_mergeEp*1E4);
REM = dropShortIntervals(REM,t_dropEp*1E4);
REM = CleanUpEpoch(REM);

% SWS
SWS = featuresNREM{7}-REM;
SWS = and(SWS,sleep); 
SWS = mergeCloseIntervals(SWS,t_mergeEp*1E4);
SWS = dropShortIntervals(SWS,t_dropEp*1E4);
SWS = CleanUpEpoch(SWS);

% Wake disp('Following option is OFF : Burst is defined as at least 3 delta')
    N3 = and(featuresNREM{10},SWS);  % 3 deltas with thresh @ 700
    if newBurstThresh
        N3 = and(featuresNREM{12},SWS); % 3 deltas with thresh @ 1000
    end
WAKE = mergeCloseIntervals(featuresNREM{6},t_mergeEp*1E4);
WAKE = (WAKE-REM)-SWS;
WAKE = dropShortIntervals(WAKE,t_dropEp*1E4);
WAKE = CleanUpEpoch(WAKE);
%Wake noise
WAKEnoise = or(WAKE,NoiseEpoch);
WAKEnoise = mergeCloseIntervals(WAKEnoise,1E4);
WAKEnoise = (WAKEnoise-REM)-SWS;
WAKEnoise = dropShortIntervals(WAKEnoise,t_dropEp*1E4);
WAKEnoise = CleanUpEpoch(WAKEnoise);

% N3

if ~BurstIs3
    disp('Burst is defined as at least 2 delta')
    N3 = and(featuresNREM{4}, SWS);  % 2 deltas with thresh @ 700
    if newBurstThresh
        N3 = and(featuresNREM{11}, SWS); % 2 deltas with thresh @ 1000
    end
else
    disp('Burst is defined as at least 3 delta')
    N3 = and(featuresNREM{10},SWS);  % 3 deltas with thresh @ 700
    if newBurstThresh
        N3 = and(featuresNREM{12},SWS); % 3 deltas with thresh @ 1000
    end
end

N3 = mergeCloseIntervals(N3, t_mergeEp*1E4);
N3 = dropShortIntervals(N3, t_dropEp*1E4);
N3 = CleanUpEpoch(N3);

% N23
N23 = or(or(featuresNREM{1},featuresNREM{2}),featuresNREM{3}); 
N23 = or(and(N23,SWS), N3); 
N23 = mergeCloseIntervals(N23, t_mergeEp*1E4);
N23 = dropShortIntervals(N23, t_dropEp*1E4);
N23 = CleanUpEpoch(N23);

% N1
N1 = SWS-N23;
N1 = mergeCloseIntervals(N1, t_mergeEp*1E4);
N1 = N1-N23;
N1 = dropShortIntervals(N1, t_dropEp*1E4);
N1 = CleanUpEpoch(N1);

% N2
N2 = N23-N3;
N2 = mergeCloseIntervals(N2, t_mergeEp*1E4);
N2 = N2-N3-N1;
N2 = dropShortIntervals(N2, t_dropEp*1E4);
N2 = CleanUpEpoch(N2);


EP = {N1,N2,N3,REM,WAKE,SI,WAKEnoise};
%% check overlapping epochs N1 N2 N3
for i=1:5
    for j=i+1:6
        overlap_duration = tot_length(and(EP{i}, EP{j}));
        if overlap_duration>0
            disp([NameEpoch{i} 'and ' NameEpoch{j} 'epochs overlap: ' num2str(round(overlap_duration/1E4,2)) 's'])
        end
    end
end


%% replace lost epoch, continuous hypothesis
WS=WAKE; SIS=SI; WnoiseS=WAKEnoise;

% ------------ nameEp -----------
nam1={'N1','N2','N3','REM','WAKE','SI','WAKEnoise'};

start_epochs = [];
end_epochs = [];
for i=1:length(EP)
    start_epochs = [start_epochs;Start(EP{i})];
    end_epochs = [end_epochs; [Stop(EP{i}) i*ones(size(Stop(EP{i})))]];
end
TOTepoch = intervalSet(min(start_epochs), max(end_epochs(:,1)));
lostEpoch = TOTepoch-WAKEnoise-REM-N1-N2-N3-SI;
lostEpoch = CleanUpEpoch(lostEpoch);
lostEpoch = mergeCloseIntervals(lostEpoch,1);
warning('on','all')

start_lostepoch = Start(lostEpoch);
disp(['! ' num2str(length(start_lostepoch)) ' lost epochs'   ])

new_epochs=[];
for i=1:length(start_lostepoch) % for each lost epochs
    try
        prev_end = max(end_epochs(end_epochs(:,1)<=start_lostepoch(i),1));% find the previous end of epoch before the lost epochs
        new_epochs(i) = max(end_epochs(end_epochs(:,1)==prev_end,2)); % put in wakeNoise if ambiguous
        EP{new_epochs(i)} = or(EP{new_epochs(i)}, subset(lostEpoch,i));        
    end
end
disp(['lostEpoch found for :', sprintf(' %s',nam1{unique(new_epochs)})])

for i=1:length(EP)
    EP{i} = CleanUpEpoch(EP{i});
    EP{i} = mergeCloseIntervals(EP{i}, 1);
end


%% Output
PFswa = mergeCloseIntervals(featuresNREM{8},t_mergeEp*1E4);
PFswa = dropShortIntervals(PFswa,t_dropEp*1E4);
OBswa = mergeCloseIntervals(featuresNREM{9},t_mergeEp*1E4);
OBswa = dropShortIntervals(OBswa,t_dropEp*1E4);

TOTSleep = or(or(N1,N2), or(N3,REM));
TOTSleep = CleanUpEpoch(TOTSleep);

Epoch = {EP{1}, EP{2}, EP{3}, EP{4}, EP{5}, EP{6}, SWS, PFswa, OBswa, TOTSleep, WAKEnoise};



end