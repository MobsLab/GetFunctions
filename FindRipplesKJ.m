% FindRipplesKJ - Find Ripples in LFP signals
% 07.12.2017 SB & KJ
%
%
%%  USAGE
% [Spindles, meanVal, stdVal] = FindRipplesKJ(LFP, Epoch, varargin)
%
%
%%  INFOS 
% This code was adapted from FindRipplesSB by Karim El Kanbi
%
%    Ripples = FindRipplesKJ(LFP, Epoch, varargin)
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


function [Ripples, meanVal, stdVal] = FindRipplesKJ(LFP, Epoch, varargin)

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
        otherwise
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).']);
	end
end


%Default values 
if ~exist('frequency_band','var')
    frequency_band = [120 250];
end
if ~exist('threshold','var')
    threshold = [5 7];
end
if ~exist('durations','var')
    durations = [15 20 200]; %in ms
end
durations = durations*10;
minInterRippleInterval = durations(1); % in ts
minRippleDuration = durations(2);
maxRippleDuration = durations(3);



% Calculate overall SD
FiltLFP = FilterLFP(LFP, frequency_band, 1024); %filter
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
signal_squared = abs(Data(FiltLFP));
SquaredFiltLFP = tsd(Range(FiltLFP),signal_squared-meanVal);

% Detect using low threshold
PotentialRipples = thresholdIntervals(SquaredFiltLFP, threshold(1)*stdVal);

% Merge ripples that are very close together
PotentialRipples = mergeCloseIntervals(PotentialRipples, minInterRippleInterval);

% Get rid of ripples that are too short
PotentialRipples = dropShortIntervals(PotentialRipples, minRippleDuration);

% Get rid of ripples that are too long
PotentialRipples = dropLongIntervals(PotentialRipples, maxRippleDuration);


%Epoch with maximum above threshold
func_max = @(a) measureOnSignal(a,'maximum');
if not(isempty(Start(PotentialRipples)))
    [maxVal, ~, ~] = functionOnEpochs(SquaredFiltLFP, PotentialRipples, func_max);
    ripples_interval = [Start(PotentialRipples) End(PotentialRipples)];
    idx_ripples =  (maxVal >= threshold(2) * stdVal);
    FinalRipplesEpoch = intervalSet(ripples_interval(idx_ripples,1), ripples_interval(idx_ripples,2));
    
    %timestamps of the nadir
    if not(isempty(Start(FinalRipplesEpoch,'ms')))
    func_min = @(a) measureOnSignal(a,'minimum');
    [~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, FinalRipplesEpoch, func_min);
    end
else
    FinalRipplesEpoch = PotentialRipples;
end

%% results

if not(isempty(Start(FinalRipplesEpoch,'ms')))
    Ripples(:,1) = Start(FinalRipplesEpoch,'ms');
    Ripples(:,2) = nadir_tmp/10;
    Ripples(:,3) = Stop(FinalRipplesEpoch,'ms');
    
else
    Ripples(:,1) = NaN;
    Ripples(:,2) = NaN;
    Ripples(:,3) = NaN;
end



end

