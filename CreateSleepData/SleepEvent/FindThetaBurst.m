% FindTBurstSB - Find Ripples in LFP signals
% 07.12.2017 SB & KJ
% Updated on 2020-11-25 by SL (added stim filtering)
%
%
%%  USAGE
% [TBurst, meanVal, stdVal] = FindTBurstSB(LFP, Epoch, varargin)
%
%
%%  INFOS 
% This code was adapted from FindRipplesSB by Karim El Kanbi
%
%    TBurst = FindTBurstSB(LFP, Epoch, varargin)
%
%    
%
%    LFP                    LFP (one channel).
%    SWSEpoch               Epoch of SWS
%
%    <options>              optional list of property-value pairs (see table below)
%    =========================================================================
%     Properties            Values
%    -------------------------------------------------------------------------
%     'frequency_band'      frequency band of the TBurst (default = [10 20])  
%     'threshold'           thresholds for TBurst detection (default = [2 3])
%     'durations'           min inter-ripple interval & min and max ripple duration, in ms
%                           (default = [200 400 3000])
%     'mean_std_values'     mean and standard deviation to normalize signals
%                           (default: computed on signals)
%     'stim'                if stim are to be clean (1), if not (0:
%                           default)
%    =========================================================================
%
%  OUTPUT
%
%    TBurst               [start peak end freq1 freq2] of TBurst (in ms)
%
%  NOTES
%           - freq:         derived from number of peaks (low: localMinima)
%           - freq2:        derived from zero-crossing
%
%  SEE
%       FindRipples, FindRipplesSB, FindTBurstKJ
%


function [TBurst, meanVal, stdVal] = FindThetaBurst(LFP, Epoch, varargin)

%% Initiation

% Check number of parameters
if nargin < 2 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).');
end

% Parse parameter list
for i = 1:2:length(varargin)
	if ~ischar(varargin{i})
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).']);
	end
	switch(lower(varargin{i}))
        case 'frequency_band'
            frequency_band =  varargin{i+1};
            if ~isivector(frequency_band,'#2','>0')
				error('Incorrect value for property ''frequency_band'' (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).');
            end
		case 'threshold'
			threshold = varargin{i+1};
			if ~isvector(threshold)
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isivector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).');
            end
        case 'mean_std_values'
			mean_std_values = varargin{i+1};
			if ~isivector(mean_std_values)
				error('Incorrect value for property ''mean_std_values'' (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).');
			end
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
            end
        otherwise
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help FindTBurstSB">FindTBurstSB</a>'' for details).']);
	end
end


%Default values 
if ~exist('frequency_band','var')
    frequency_band = [4 8];
end
if ~exist('threshold','var')
    threshold = [3 5];
end
if ~exist('durations','var')
    durations = [500 500 3000]; %in ms
end
%stim
if ~exist('stim','var')
    stim=0;
end
durations = durations*10;
minInterTBurstInterval = durations(1); % in ts
minTBurstDuration = durations(2);
maxTBurstDuration = durations(3);
frequency = 1250; % default sampling rate (need to get frequency of events

%% Filter signal and find SD

Filsp_tmp = FilterLFP(LFP, frequency_band, 1024); %filter
% clear stim from LFP
if stim
    try
        load('behavResources.mat','StimEpoch');
        st = Start(StimEpoch);
        time = Range(Filsp_tmp);
        TotalEpoch = intervalSet(time(1), time(end));
        for istim=1:length(st)
            sti(istim) = st(istim)-5000;
            en(istim) = st(istim)+5000;
        end
        stim_ti = intervalSet(sti,en);
        NoStimEpoch = TotalEpoch - stim_ti;
        FiltLFP = Restrict(Filsp_tmp, NoStimEpoch);
    catch
        warning('There is no StimEpoch for this session')
        FiltLFP=Filsp_tmp;
    end
else
    FiltLFP=Filsp_tmp;
end

FiltLFP = Restrict(FiltLFP, Epoch); %restrict to Epoch
signal_squared = Data(FiltLFP).^2;
if exist('mean_std_values','var')
    meanVal = mean_std_values(1);
    stdVal = mean_std_values(2);
else
    meanVal = mean(signal_squared);
    stdVal = std(signal_squared);
end
%squared signal
SquaredFiltLFP = tsd(Range(FiltLFP), signal_squared-meanVal);

%% Detection
% Detect using low threshold
PotentialTBurstEpochs = thresholdIntervals(SquaredFiltLFP, threshold(1)*stdVal);

% Merge ripples that are very close together
PotentialTBurstEpochs = mergeCloseIntervals(PotentialTBurstEpochs, minInterTBurstInterval);

% Get rid of ripples that are too short
PotentialTBurstEpochs = dropShortIntervals(PotentialTBurstEpochs, minTBurstDuration);

% Get rid of ripples that are too long
PotentialTBurstEpochs = dropLongIntervals(PotentialTBurstEpochs, maxTBurstDuration);

%Epoch with maximum above threshold
func_max = @(a) measureOnSignal(a,'maximum');
[maxVal, ~, ~] = functionOnEpochs(SquaredFiltLFP, PotentialTBurstEpochs, func_max);
TBurst_interval = [Start(PotentialTBurstEpochs) End(PotentialTBurstEpochs)];
idx_TBurst =  (maxVal >= threshold(2) * stdVal);
FinalTBurstEpoch = intervalSet(TBurst_interval(idx_TBurst,1), TBurst_interval(idx_TBurst,2));

%timestamps of the nadir
func_min = @(a) measureOnSignal(a,'minimum');
[~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, FinalTBurstEpoch, func_min);

% find peak-to-peak amplitude
func_amp = @(a) measureOnSignal(a,'amplitude_p2p');
[amp, ~, ~] = functionOnEpochs(SquaredFiltLFP, FinalTBurstEpoch, func_amp);

% added by SL 2020-11
% Detect instantaneous frequency Model 1
st_ss = Start(FinalTBurstEpoch);
en_ss = Stop(FinalTBurstEpoch);
freq = zeros(length(st_ss),1);
for i=1:length(st_ss)
	peakIx = LocalMinima(Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i)))),4,0);
    if ~isempty(peakIx)
        freq(i) = frequency/median(diff(peakIx));
    end
end

%% results
if not(isempty(Start(FinalTBurstEpoch)))
    TBurst(:,1) = Start(FinalTBurstEpoch,'s');
    TBurst(:,2) = nadir_tmp / 1e4;
    TBurst(:,3) = Stop(FinalTBurstEpoch,'s');
    TBurst(:,4) = Stop(FinalTBurstEpoch,'s')-Start(FinalTBurstEpoch,'s'); %duration
    TBurst(:,5) = freq;   % mean frequency
    TBurst(:,6) = amp;    % peak amplitude
else
    TBurst(:,1) = NaN;
    TBurst(:,2) = NaN;
    TBurst(:,3) = NaN;
    TBurst(:,4) = NaN;
    TBurst(:,5) = NaN;
    TBurst(:,6) = NaN;    
end




end
