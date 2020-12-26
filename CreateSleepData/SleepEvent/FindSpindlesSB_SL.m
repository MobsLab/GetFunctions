% FindSpindlesSB - Find Ripples in LFP signals
% 07.12.2017 SB & KJ
% Updated on 2020-11-25 by SL (added stim filtering)
%
%
%%  USAGE
% [Spindles, meanVal, stdVal] = FindSpindlesSB(LFP, Epoch, varargin)
%
%
%%  INFOS 
% This code was adapted from FindRipplesSB by Karim El Kanbi
%
%    Spindles = FindSpindlesSB(LFP, Epoch, varargin)
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
%     'frequency_band'      frequency band of the spindles (default = [10 20])  
%     'threshold'           thresholds for spindle detection (default = [2 3])
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
%    Spindles               [start peak end freq1 freq2] of spindles (in ms)
%
%  NOTES
%           - freq:         derived from number of peaks (low: localMinima)
%           - freq2:        derived from zero-crossing
%
%  SEE
%       FindRipples, FindRipplesSB, FindSpindlesKJ
%


function [Spindles, meanVal, stdVal] = FindSpindlesSB(LFP, Epoch, varargin)

%% Initiation

% Check number of parameters
if nargin < 2 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
end

% Parse parameter list
for i = 1:2:length(varargin)
	if ~ischar(varargin{i})
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).']);
	end
	switch(lower(varargin{i}))
        case 'frequency_band'
            frequency_band =  varargin{i+1};
            if ~isivector(frequency_band,'#2','>0')
				error('Incorrect value for property ''frequency_band'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
            end
		case 'threshold'
			threshold = varargin{i+1};
			if ~isvector(threshold)
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isivector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
            end
        case 'mean_std_values'
			mean_std_values = varargin{i+1};
			if ~isivector(mean_std_values)
				error('Incorrect value for property ''mean_std_values'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
			end
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
            end
        otherwise
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).']);
	end
end


%Default values 
if ~exist('frequency_band','var')
    frequency_band = [10 20];
end
if ~exist('threshold','var')
    threshold = [1.5 2];
end
if ~exist('durations','var')
    durations = [200 400 3000]; %in ms
end
%stim
if ~exist('stim','var')
    stim=0;
end
durations = durations*10;
minInterSpindleInterval = durations(1); % in ts
minSpindleDuration = durations(2);
maxSpindleDuration = durations(3);
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
PotentialSpindleEpochs = thresholdIntervals(SquaredFiltLFP, threshold(1)*stdVal);

% Merge ripples that are very close together
PotentialSpindleEpochs = mergeCloseIntervals(PotentialSpindleEpochs, minInterSpindleInterval);

% Get rid of ripples that are too short
PotentialSpindleEpochs = dropShortIntervals(PotentialSpindleEpochs, minSpindleDuration);

% Get rid of ripples that are too long
PotentialSpindleEpochs = dropLongIntervals(PotentialSpindleEpochs, maxSpindleDuration);

%Epoch with maximum above threshold
func_max = @(a) measureOnSignal(a,'maximum');
[maxVal, ~, ~] = functionOnEpochs(SquaredFiltLFP, PotentialSpindleEpochs, func_max);
spindles_interval = [Start(PotentialSpindleEpochs) End(PotentialSpindleEpochs)];
idx_spindles =  (maxVal >= threshold(2) * stdVal);
FinalSpindlesEpoch = intervalSet(spindles_interval(idx_spindles,1), spindles_interval(idx_spindles,2));

% % filter false spindles (non-waxing)
% st_ss = Start(FinalSpindlesEpoch);
% en_ss = Stop(FinalSpindlesEpoch);
% realss=[];
% ii=1;
% for i=1:length(st_ss)
%     ssdat = Data(Restrict(SquaredFiltLFP,intervalSet(st_ss(i),en_ss(i))));
% 	peakIx = LocalMaxima(ssdat,4,0);
%     if ~isempty(peakIx)
%         peakval = ssdat(peakIx);
%         [maxpeak maxidx] = max(peakval);
%         goodidx = find(peakval >= threshold(1)*stdVal);
%         peakstd = std(peakval);
%         medpeak = median(peakval);
% %         peakcheck = peakval-medpeak;
%         if goodidx
%             if (maxidx > 2) && (maxidx < length(peakval)-2)
%                 if peakval(maxidx-1)>peakval(maxidx)-(medpeak*1.4) && ...
%                         peakval(maxidx+1)>peakval(maxidx)-(medpeak*1.4) && ...
%                         peakval(maxidx-2)>peakval(maxidx)-(medpeak*2) && ...
%                         peakval(maxidx+2)>peakval(maxidx)-(medpeak*2)  % filter out huge peak in sigma band
%                     difpeak = diff(goodidx);
%                     try
%                         if sum(difpeak(maxidx-2:maxidx+1))==4
%                             realss(ii) = i;
%                             ii=ii+1;
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% FinalSpindlesEpoch = intervalSet(st_ss(realss), en_ss(realss));

%timestamps of the nadir
func_min = @(a) measureOnSignal(a,'minimum');
[~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, FinalSpindlesEpoch, func_min);

% find peak-to-peak amplitude
func_amp = @(a) measureOnSignal(a,'amplitude_p2p');
[amp, ~, ~] = functionOnEpochs(SquaredFiltLFP, FinalSpindlesEpoch, func_amp);

% added by SL 2020-11
% Detect instantaneous frequency Model 1
st_ss = Start(FinalSpindlesEpoch);
en_ss = Stop(FinalSpindlesEpoch);
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
if not(isempty(Start(FinalSpindlesEpoch)))
    Spindles(:,1) = Start(FinalSpindlesEpoch,'s');
    Spindles(:,2) = nadir_tmp / 1e4;
    Spindles(:,3) = Stop(FinalSpindlesEpoch,'s');
    Spindles(:,4) = Stop(FinalSpindlesEpoch,'s')-Start(FinalSpindlesEpoch,'s'); %duration
    Spindles(:,5) = freq;   % mean frequency
    Spindles(:,6) = amp;    % peak amplitude
else
    Spindles(:,1) = NaN;
    Spindles(:,2) = NaN;
    Spindles(:,3) = NaN;
    Spindles(:,4) = NaN;
    Spindles(:,5) = NaN;
    Spindles(:,6) = NaN;    
end




end
