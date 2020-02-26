%FindSpindlesKJ2 - Find spindles.
%
%  USAGE
%
%    Spindles = FindSpindlesKJ2(LFP, Epoch, varargin)
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
%     'frequency_sampling'  sampling rate (in Hz) (default = 1250Hz)
%    =========================================================================
%
%  OUTPUT
%
%    Spindles               [start peak end] of spindles, in ms
%
%  SEE 
%    FindSpindlesKJ   
%


function Spindles = FindSpindlesKJ2(LFP, Epoch, varargin)

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
            if ~isivector(frequency_band,'#2','>0')
				error('Incorrect value for property ''frequency_band'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
            end
		case 'threshold'
			threshold = varargin{i+1};
			if ~isivector(threshold,'#2','>0')
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
			end
		case 'durations'
			durations = varargin{i+1};
            if ~isivector(durations,'#3','>0')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindSpindlesKJ">FindSpindlesKJ</a>'' for details).');
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
    threshold = [2 3];
end
if ~exist('durations','var')
    durations = [200 400 3000]; %in ms
end
minInterSpindleInterval = durations(1) * 10; % in ts
minSpindleDuration = durations(2) * 10;
maxSpindleDuration = durations(3) * 10;


%% Filtering - normalizing - enveloppe
FiltLFP = FilterLFP(LFP, frequency_band, 1024);
signal = Data(Restrict(FiltLFP, Epoch));
norm_signal = (Data(FiltLFP) - mean(signal)) / std(signal);
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



%re-add path
addpath('/home/mobsjunior/Dropbox/Kteam/PrgMatlab/chronux2/spectral_analysis/continuous/') %conflict with findpeaks of chronux


end




