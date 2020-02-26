%FindSpindlesKJ3 - Find spindles.
%
%  USAGE
%
%    Spindles = FindSpindlesKJ3(LFP, Epoch, varargin)
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
%    =========================================================================
%
%  OUTPUT
%
%    Spindles               [start peak end] of spindles, in ms
%



function Spindles = FindSpindlesKJ3(LFP, Epoch, varargin)

% Check number of parameters
if nargin < 2 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
end

% Parse parameter list
for i = 1:2:length(varargin)
	if ~ischar(varargin{i})
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).']);
	end
	switch(lower(varargin{i}))
        case 'frequency_band'
            frequency_band =  varargin{i+1};
            if ~isdvector(frequency_band,'#2','>0')
				error('Incorrect value for property ''frequency_band'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
            end
		case 'threshold'
			threshold = varargin{i+1};
			if ~isdvector(threshold,'#2','>0')
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isdvector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
            end
        case 'mean_std_values'
			mean_std_values = varargin{i+1};
			if ~isdvector(mean_std_values,'#2','>0')
				error('Incorrect value for property ''mean_std_values'' (type ''help <a href="matlab:help FindRipplesKJ">FindRipplesKJ</a>'' for details).');
			end
        otherwise
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).']);
	end
end


%Default values 
if ~exist('frequency_band','var')
    frequency_band = [10 18];
end
if ~exist('threshold','var')
    if all(frequency_band==[2 20])
        threshold = [1.5 4];
    else
        threshold = [3 5];
    end
end
if ~exist('durations','var')
    durations = [200 400 3000]; %in ms
end
minInterSpindleInterval = durations(1) * 10; % in ts
minSpindleDuration = durations(2) * 10;
maxSpindleDuration = durations(3) * 10;

%sampling frequency and window
fsampling = round(1/median(diff(Range(LFP,'s'))));
windowLength = round(fsampling/1250*11);
window = ones(windowLength,1) / windowLength;

%% Filtering - stdev
FiltLFP = FilterLFP(LFP, frequency_band, 512);
signal_squared = Data(Restrict(FiltLFP, Epoch));
if exist('mean_std_values','var')
    meanVal = mean_std_values(1);
    stdVal = mean_std_values(2);
else
    meanVal = mean(signal_squared);
    stdVal = std(signal_squared);
end
norm_signal = (Data(FiltLFP) - meanVal) / stdVal;
rmpath('/home/mobsjunior/Dropbox/Kteam/PrgMatlab/chronux2/spectral_analysis/continuous/') %conflict with findpeaks of chronux
[envelope_up,~] = envelope(norm_signal, 75,'peak');
tEnvelope = tsd(Range(LFP), envelope_up);
 
%% Thresholds

%low thresholds
lowThreshEpochs = thresholdIntervals(tEnvelope, threshold(1), 'Direction', 'Above');
lowThreshEpochs = mergeCloseIntervals(lowThreshEpochs, minInterSpindleInterval);
start_lowthresh = Start(lowThreshEpochs); end_lowthresh = End(lowThreshEpochs); 
%high thresholds
highThreshEpochs = thresholdIntervals(tEnvelope, threshold(2), 'Direction', 'Above');
 
% keep low threshold intervals containing a high threshold one
peak_thresh_epochs = (Start(highThreshEpochs) + End(highThreshEpochs)) / 2;
[~,interval,~] = InIntervals(peak_thresh_epochs, [start_lowthresh end_lowthresh]);
good_intervals = unique(interval);
good_intervals(good_intervals==0)=[];
 
PreSpindlesEpoch = intervalSet(start_lowthresh(good_intervals), end_lowthresh(good_intervals));
SpindleEpochs = dropShortIntervals(PreSpindlesEpoch, minSpindleDuration);
SpindleEpochs = dropLongIntervals(SpindleEpochs, maxSpindleDuration);
 
%timestamps of the nadir
func_min = @(a) measureOnSignal(a,'minimum');
[~, nadir_tmp, ~] = functionOnEpochs(FiltLFP, SpindleEpochs, func_min);
 



%% results
if not(isempty(Start(SpindleEpochs,'s')))
    Spindles(:,1) = Start(SpindleEpochs,'s');
    Spindles(:,2) = nadir_tmp / 1e4;
    Spindles(:,3) = Stop(SpindleEpochs,'s');
    
else
    Spindles(:,1) = NaN;
    Spindles(:,2) = NaN;
    Spindles(:,3) = NaN;
end





end


function [U,stdA] = unity(A,sd,restrict)


meanA = mean(A);
stdA = std(A);

U = (A - mean(A))/std(A);

end

