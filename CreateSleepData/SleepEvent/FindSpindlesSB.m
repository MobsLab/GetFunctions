% FindSpindlesSB - Find Ripples in LFP signals
% 07.12.2017 SB & KJ
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
%    =========================================================================
%
%  OUTPUT
%
%    Spindles               [start peak end] of spindles, in ms
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
			if ~isivector(threshold,'#2','>0')
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isivector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
            end
        case 'mean_std_values'
			mean_std_values = varargin{i+1};
			if ~isivector(mean_std_values,'#2','>0')
				error('Incorrect value for property ''mean_std_values'' (type ''help <a href="matlab:help FindSpindlesSB">FindSpindlesSB</a>'' for details).');
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
    threshold = [2 3];
end
if ~exist('durations','var')
    durations = [200 400 3000]; %in ms
end
durations = durations*10;
minInterSpindleInterval = durations(1); % in ts
minSpindleDuration = durations(2);
maxSpindleDuration = durations(3);


%% Filter signal and find SD

FiltLFP = FilterLFP(LFP, frequency_band, 1024); %filter
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

%timestamps of the nadir
func_min = @(a) measureOnSignal(a,'minimum');
[~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, FinalSpindlesEpoch, func_min);



%% results
if not(isempty(Start(FinalSpindlesEpoch,'s')))
    Spindles(:,1) = Start(FinalSpindlesEpoch,'s');
    Spindles(:,2) = nadir_tmp / 1e4;
    Spindles(:,3) = Stop(FinalSpindlesEpoch,'s');
    
else
    Spindles(:,1) = NaN;
    Spindles(:,2) = NaN;
    Spindles(:,3) = NaN;
end




end
