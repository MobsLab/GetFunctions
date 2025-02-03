
function [Ripples, meanVal, stdVal] = FindRipplesSL(LFP, nonLFP, Epoch, varargin)

% FindRipplesSL - Find Ripples in LFP signals
% 07.12.2017 SB & KJ
% 2020-12 Samuel Laventure
%
%%  USAGE
% [Spindles, meanVal, stdVal] = FindRipplesKJ(LFP, Epoch, varargin)
%
%
%%  INFOS 
% This code was adapted from FindRipplesSB by Karim El Kanbi
% Cleaned and modified to include amplitude, frequency detection and filtering through a non Ripple channel by
% Samuel laventure 2020-12
%
%    Ripples = FindRipplesKJ(LFP, Epoch, varargin)
%
%    
%
%    LFP                    LFP (one channel).
%    nonLFP                 LFP with channel without targeted events 
%    SWSEpoch               Epoch of SWS
%
%    <options>              optional list of property-value pairs (see table below)
%    =========================================================================
%     Properties            Values
%    -------------------------------------------------------------------------
%     'frequency_band'      frequency band of the ripples (default = [120 250])  
%     'threshold'           thresholds for ripple detection (default = [5 7])
%     'durations'           min inter-ripple interval & min and max ripple duration, in ms
%                           (default = [15 20 200])
%     'mean_std_values'     mean and standard deviation to normalize signals
%                           (default: computed on signals)
%    =========================================================================
%
%  OUTPUT
%
%    Ripples               [start peak end] of ripples, in ms
%
%  SEE
%       FindRipples, FindRipplesSB, FindSpindlesKJ, FindSpindlesSB
%



%% Initiation

% Check number of parameters
if nargin < 2 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
end

% Parse parameter list
for i = 1:2:length(varargin)
	if ~ischar(varargin{i})
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).']);
	end
	switch(lower(varargin{i}))
        case 'frequency_band'
            frequency_band =  varargin{i+1};
            if ~isdvector(frequency_band,'#2','>0')
				error('Incorrect value for property ''frequency_band'' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
            end
		case 'threshold'
			threshold = varargin{i+1};
			if ~isdvector(threshold,'#2','>0')
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isdvector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
            end
        case 'mean_std_values'
			mean_std_values = varargin{i+1};
			if  ~isdvector(mean_std_values,'#2','>0')   
				error('Incorrect value for property ''mean_std_values'' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
			end
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
            end
        otherwise
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).']);
	end
end


%Default values 
if ~exist('frequency_band','var')
    frequency_band = [120 220];
end
if ~exist('threshold','var')
    threshold = [2 5];
end
if ~exist('durations','var')
    durations = [15 20 200]; %in ms
end
%stim
if ~exist('stim','var')
    stim=0;
end

durations = durations*10;
minInterRippleInterval = durations(1); % in ts
minRippleDuration = durations(2);
maxRippleDuration = durations(3);
frequency = 1250; % default sampling rate (need to get frequency of events)

%% Processing non-Ripple channel
% calculate overall SD
FiltnonLFP = FilterLFP(nonLFP, frequency_band, 1024); %filter
FiltnonLFP_EpochRestrict = Restrict(FiltnonLFP, Epoch); %restrict to Epoch
signal_squared = abs(Data(FiltnonLFP_EpochRestrict));
if exist('mean_std_values','var')
    meanVal_nonRip = mean_std_values(1);
    stdVal_nonRip = mean_std_values(2);
else
    meanVal_nonRip = mean(signal_squared);
    stdVal_nonRip = std(signal_squared);
end

%signal taken over the whole record for detection
signal_squared = abs(Data(FiltnonLFP));
SquaredFiltnonLFP = tsd(Range(FiltnonLFP),signal_squared-meanVal_nonRip);

% Detect using low threshold
nonRipples = thresholdIntervals(SquaredFiltnonLFP, threshold(1)*stdVal_nonRip);

%% Processing Ripple channel
% Calculate overall SD
Filsp_tmp = FilterLFP(LFP, frequency_band, 1024); %filter

%-------------------------------------------------------------------------
%... testing


%% Calculate standard deviation without noise
noise_thr = 13E3;
    load('behavResources.mat');
    AboveEpoch=thresholdIntervals(LFP,noise_thr,'Direction','Above'); % Threshold on non-filtered data!!!
    NoiseEpoch=thresholdIntervals(LFP,-noise_thr,'Direction','Below'); % Threshold on non-filtered data!!!
    CleanEpoch=or(AboveEpoch,NoiseEpoch);
    CleanEpoch=intervalSet(Start(CleanEpoch)-3E3,End(CleanEpoch)+5E3);
    if exist('TTLInfo')
        StimEpoch = intervalSet(Start(TTLInfo.StimEpoch)-1E3, End(TTLInfo.StimEpoch)+3E3);
        GoEpoch = or(CleanEpoch,StimEpoch);
    else
        GoEpoch=CleanEpoch;
    end
    rg=Range(LFP);
    TotalEpoch=intervalSet(rg(1),rg(end));
    SCleanEpoch=mergeCloseIntervals(GoEpoch,1);
    GoodTime=Range(Restrict(Filsp_tmp,TotalEpoch-SCleanEpoch));
    GoodData=Data(Restrict(Filsp_tmp,TotalEpoch-SCleanEpoch));
    FiltLFP = tsd(GoodTime,GoodData);
% 
% % clear stim from LFP
% if stim
%     try
%         load('behavResources.mat','StimEpoch');
%         st = Start(StimEpoch);
%         time = Range(Filsp_tmp);
%         TotalEpoch = intervalSet(time(1), time(end));
%         for istim=1:length(st)
%             sti(istim) = st(istim)-5000;
%             en(istim) = st(istim)+5000;
%         end
%         stim_ti = intervalSet(sti,en);
%         NoStimEpoch = TotalEpoch - stim_ti;
%         FiltLFP = Restrict(Filsp_tmp, NoStimEpoch);
%     catch
%         warning('There is no StimEpoch for this session')
%         FiltLFP=Filsp_tmp;
%     end
% else
%     FiltLFP=Filsp_tmp;
% end
%-------------------------------------------------------------------------

FiltLFP_EpochRestrict = Restrict(FiltLFP, Epoch); %restrict to Epoch
signal_squared = abs(Data(FiltLFP_EpochRestrict));
if exist('mean_std_values','var')
    meanVal = mean_std_values(1);
    stdVal = mean_std_values(2);
else
    meanVal = mean(signal_squared);
    stdVal = std(signal_squared);
end

%signal taken over the whole record for detection
% signal_squared = abs(Data(FiltLFP));
% SquaredFiltLFP = tsd(Range(FiltLFP),signal_squared-meanVal);
signal_squared = Data(FiltLFP).^2;

% normalize
sd=[]; keep=[];
windowLength = round(frequency/1250*11);
window = ones(windowLength,1)/windowLength;
[normalizedSquaredSignal] = unity(Filter0(window,sum(signal_squared,2)),sd,keep);
SquaredFiltLFP = tsd(Range(FiltLFP),normalizedSquaredSignal);

% Detect using low threshold
PotentialRipples = thresholdIntervals(SquaredFiltLFP, threshold(1));
% PotentialRipples = thresholdIntervals(SquaredFiltLFP, threshold(1)*stdVal);
disp(['Step 1: After LOW thresholding: ' num2str(length(Start(PotentialRipples))) ' events']);

% Merge ripples that are very close together
PotentialRipples = mergeCloseIntervals(PotentialRipples, minInterRippleInterval);
disp(['Step 2: After Merging close events: ' num2str(length(Start(PotentialRipples))) ' events']);

% Filtering out artefact events
st = Start(nonRipples);
en = End(nonRipples);
time = Range(nonLFP);
TotalEpoch = intervalSet(time(1), time(end));
ev_ti = intervalSet(st,en);
PotentialRipples = PotentialRipples - ev_ti;
disp(['Step 3: After removing artefacts (from non-ripple channel): ' num2str(length(Start(PotentialRipples))) ' events']);

% Get rid of ripples that are too short
PotentialRipples = dropShortIntervals(PotentialRipples, minRippleDuration);
disp(['Step 4: After removing too short events: ' num2str(length(Start(PotentialRipples))) ' events']);

% Get rid of ripples that are too long
PotentialRipples = dropLongIntervals(PotentialRipples, maxRippleDuration);
disp(['Step 5: After removing too long events: ' num2str(length(Start(PotentialRipples))) ' events']);


%Epoch with maximum above threshold
func_max = @(a) measureOnSignal(a,'maximum');
if not(isempty(Start(PotentialRipples)))
    [maxVal, ~, ~] = functionOnEpochs(SquaredFiltLFP, PotentialRipples, func_max);
    ripples_interval = [Start(PotentialRipples) End(PotentialRipples)];
    idx_ripples =  (maxVal >= threshold(2) * stdVal);
    FinalRipplesEpoch = intervalSet(ripples_interval(idx_ripples,1), ripples_interval(idx_ripples,2));
    amp = maxVal(idx_ripples);
    %timestamps of the nadir
    if not(isempty(Start(FinalRipplesEpoch,'ms')))
    func_min = @(a) measureOnSignal(a,'minimum');
    [~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, FinalRipplesEpoch, func_min);
    end
else
    FinalRipplesEpoch = PotentialRipples;
end
disp(['Step 6: After removing events below 2nd threshold: ' num2str(length(Start(FinalRipplesEpoch))) ' events']);


% find peak-to-peak amplitude
func_amp = @(a) measureOnSignal(a,'amplitude_p2p');
[amp, ~, ~] = functionOnEpochs(SquaredFiltLFP, FinalRipplesEpoch, func_amp);

% Detect instantaneous frequency Model 1
st_ss = Start(FinalRipplesEpoch);
en_ss = Stop(FinalRipplesEpoch);
freq = zeros(length(st_ss),1);
for i=1:length(st_ss)
	peakIx = LocalMinima(Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i)))),4,0);
    if ~isempty(peakIx)
        freq(i) = frequency/median(diff(peakIx));
    end
end
% % Detect instantaneous frequency Model 2
% fqcy2 = zeros(length(st_ss),1);
% for i=1:length(st_ss)
%     [up, ~] = ZeroCrossings([Range(Restrict(FiltLFP,[intervalSet(st_ss(i),en_ss(i))]')),Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i))))]);
%     if ~isempty(up)
%         fqcy2(i) = sum(up)/(length(up)/frequency);
%     end
% end

%% results
if not(isempty(Start(FinalRipplesEpoch)))
    Ripples(:,1) = Start(FinalRipplesEpoch,'s');
    Ripples(:,2) = nadir_tmp / 1E4;  
    Ripples(:,3) = Stop(FinalRipplesEpoch,'s');
    Ripples(:,4) = Stop(FinalRipplesEpoch,'ms')-Start(FinalRipplesEpoch,'ms');
    Ripples(:,5) = freq;
    Ripples(:,6) = amp;
else
    Ripples(:,1) = NaN;
    Ripples(:,2) = NaN;
    Ripples(:,3) = NaN;
    Ripples(:,4) = NaN;
    Ripples(:,5) = NaN;
    Ripples(:,6) = NaN;
end

function y = Filter0(b,x)

if size(x,1) == 1,
	x = x(:);
end

if mod(length(b),2) ~= 1,
	error('filter order should be odd');
end

shift = (length(b)-1)/2;

[y0 z] = filter(b,1,x);

y = [y0(shift+1:end,:) ; z(1:shift,:)];

function [U,stdA] = unity(A,sd,restrict)

if ~isempty(restrict),
	meanA = mean(A(restrict));
	stdA = std(A(restrict));
else
	meanA = mean(A);
	stdA = std(A);
end
if ~isempty(sd),
	stdA = sd;
end

U = (A - meanA)/stdA;


