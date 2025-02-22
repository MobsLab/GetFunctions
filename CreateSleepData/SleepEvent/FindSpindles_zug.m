function [spindles,sd,bad] = FindSpindles_zug(filtered,varargin)

% =========================================================================
%                            Findspindles_zug
% =========================================================================
% 
% USAGE: [spindles,sd,bad] = Findspindles_zug(filtered,<options>)
%
% DESCRIPTION:  Detect and save spindles using square-root value followed by
%               a normalization of power of the LFP. 
%               Part of MOBs' CreateSleepSignal pipeline.
%
%               spindles are detected using the normalized squared signal (NSS) by
%               thresholding the baseline, merging neighboring events, thresholding
%               the peaks, and discarding events with excessive duration.
%               Thresholds are computed as multiples of the standard deviation of
%               the NSS. Alternatively, one can use explicit values, typically obtained
%               from a previous call.
%
%               This code was derived from FindSpindles.m originally written by M. Zugaro 
%               (see ref below). It was adapted for the MOBs pipeline 
%               by S. Laventure (2021-01).
%
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       filtered        lfp time and signal ([time signal]). 
%                       Time in second.              
%
%       <varargin>          optional list of property-value pairs (see table below)
%
%     'thresholds'      thresholds for ripple beginning/end and peak, in multiples
%                       of the stdev (default = [2 5])
%     'durations'       minimum inter-ripple interval, and minimum and maximum
%                       ripple durations, in ms (default = [30 20 100])
%     'baseline'        interval used to compute normalization (default = all)
%     'restrict'        same as 'baseline' (for backwards compatibility)
%     'frequency'       sampling rate (in Hz) (default = 1250Hz)
%     'stdev'           reuse previously computed stdev
%     'noise'           noisy ripple-band filtered channel used to exclude ripple-
%                       like noise (events also present on this channel are
%                       discarded)
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       spindles             [start(in s) peak(in s) end(in s) duration(in ms) 
%                           frequency peak-amplitude]   
%       sd                  standard value of LFP
%       bad                 removed spindles from detection
% =========================================================================
% VERSIONS
%   Copyright (C) 2004-2011 by Michaël Zugaro, 2016 Ralitsa Todorova (vectorized secondPass),
%   initial algorithm by Hajime Hirase
%   Adapted for MOBs pipeline by S. Laventure - 2021-01 (extract frequency and peak-amplitude)
%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 3 of the License, or
%   (at your option) any later version.
%
% =========================================================================
% SEE   CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
%       Findspindles_zug Findspindles Findspindles_abs CreatespindlesSleep
%       FilterLFP
% =========================================================================

% Default values
frequency = 1250;
restrict = [];
sd = [];
lowThresholdFactor = 1; % Ripple envoloppe must exceed lowThresholdFactor*stdev
highThresholdFactor = 2; % Ripple peak must exceed highThresholdFactor*stdev
minInterRippleInterval = 200; % in ms
minRippleDuration = 400; % in ms
maxRippleDuration = 3000; % in ms
noise = [];

% Check number of parameters
if nargin < 1 | mod(length(varargin),2) ~= 0,
  error('Incorrect number of parameters (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
end

% Check parameter sizes
if ~isdmatrix(filtered) | size(filtered,2) ~= 2,
	error('Parameter ''filtered'' is not a Nx2 matrix (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
end

% Parse parameter list
for i = 1:2:length(varargin),
	if ~ischar(varargin{i}),
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).']);
	end
	switch(lower(varargin{i})),
		case 'thresholds',
			thresholds = varargin{i+1};
			if ~isdvector(thresholds,'#2','>0'),
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
			lowThresholdFactor = thresholds(1);
			highThresholdFactor = thresholds(2);
		case 'durations',
			durations = varargin{i+1};
			if ~isdvector(durations,'#2','>0') && ~isdvector(durations,'#3','>0'),
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
			if length(durations) == 2,
				minInterRippleInterval = durations(1);
				maxRippleDuration = durations(2);
			else
				minInterRippleInterval = durations(1);
				minRippleDuration = durations(2);
				maxRippleDuration = durations(3);
			end
		case 'frequency',
			frequency = varargin{i+1};
			if ~isdscalar(frequency,'>0'),
				error('Incorrect value for property ''frequency'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
		case 'show',
			show = varargin{i+1};
			if ~isastring(show,'on','off'),
				error('Incorrect value for property ''show'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
		case {'baseline','restrict'},
			restrict = varargin{i+1};
			if ~isempty(restrict) & ~isdvector(restrict,'#2','<'),
				error('Incorrect value for property ''restrict'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
		case 'stdev',
			sd = varargin{i+1};
			if ~isdscalar(sd,'>0'),
				error('Incorrect value for property ''stdev'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
		case 'noise',
			noise = varargin{i+1};
			if ~isdmatrix(noise) | size(noise,1) ~= size(filtered,1) | size(noise,2) ~= 2,
				error('Incorrect value for property ''nFilspoise'' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).');
			end
		otherwise,
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help Findspindles">Findspindles</a>'' for details).']);
	end
end

% Parameters
windowLength = round(frequency/1250*11);

% Square and normalize signal
time = filtered(:,1);
signal = filtered(:,2);
squaredSignal = signal.^2;
window = ones(windowLength,1)/windowLength;
keep = [];
if ~isempty(restrict),
	keep = filtered(:,1)>=restrict(1)&filtered(:,1)<=restrict(2);
end

[normalizedSquaredSignal,sd] = unity(Filter0(window,sum(squaredSignal,2)),sd,keep);

% Detect ripple periods by thresholding normalized squared signal
thresholded = normalizedSquaredSignal > lowThresholdFactor;
start = find(diff(thresholded)>0);
stop = find(diff(thresholded)<0);
% Exclude last ripple if it is incomplete
if length(stop) == length(start)-1,
	start = start(1:end-1);
end
% Exclude first ripple if it is incomplete
if length(stop)-1 == length(start),
    stop = stop(2:end);
end
% Correct special case when both first and last spindles are incomplete
if start(1) > stop(1),
	stop(1) = [];
	start(end) = [];
end
firstPass = [start,stop];
if isempty(firstPass),
	disp('  Step 1: Detection by thresholding failed');
	return
else
	disp(['  Step 1: After detection by low thresholding: ' num2str(length(firstPass)) ' events.']);
end

% Merge spindles if inter-ripple period is too short (unless this would yield too long a ripple)
secondPass = firstPass;
iri = time(secondPass(2:end,1)) - time(secondPass(1:end-1,2));
duration = time(secondPass(2:end,2)) - time(secondPass(1:end-1,1));
toMerge = iri<minInterRippleInterval/1000 & duration<maxRippleDuration/1000;
while any(toMerge),
    % Get indices of first spindles in pairs to be merged
    spindlestart = strfind([0 toMerge'],[0 1])';
    % Incorporate second ripple into first in all pairs
    rippleEnd = spindlestart+1;
    secondPass(spindlestart,2) = secondPass(rippleEnd,2);
    % Remove second spindles and loop
    secondPass(rippleEnd,:) = [];
    iri = time(secondPass(2:end,1)) - time(secondPass(1:end-1,2));
    duration = time(secondPass(2:end,2)) - time(secondPass(1:end-1,1));
    toMerge = iri<minInterRippleInterval/1000 & duration<maxRippleDuration/1000;
end

if isempty(secondPass),
	disp('  Step 2: Ripple merge failed');
	return
else
	disp(['  Step 2: After ripple merge: ' num2str(length(secondPass)) ' events.']);
end

% Discard spindles with a peak power < highThresholdFactor
thirdPass = [];
peakNormalizedPower = [];
for i = 1:size(secondPass,1)
	maxValue = max(normalizedSquaredSignal([secondPass(i,1):secondPass(i,2)]));
	if maxValue > highThresholdFactor,
		thirdPass = [thirdPass ; secondPass(i,:)];
		peakNormalizedPower = [peakNormalizedPower ; maxValue];
	end
end
if isempty(thirdPass),
	disp('  Step 3: Peak thresholding failed.');
	return
else
	disp(['  Step 3: After peak thresholding: ' num2str(length(thirdPass)) ' events.']);
end

% Detect negative peak position for each ripple
peakPosition = zeros(size(thirdPass,1),1);
for i=1:size(thirdPass,1),
	[~,minIndex] = min(signal(thirdPass(i,1):thirdPass(i,2)));
	peakPosition(i) = minIndex + thirdPass(i,1) - 1;
end

% Discard spindles that are way too short
spindles = [time(thirdPass(:,1)) time(peakPosition) time(thirdPass(:,2)) peakNormalizedPower];
duration = spindles(:,3)-spindles(:,1);
spindles(duration<minRippleDuration/1000,:) = [];
disp(['  Step 4: After min duration test: ' num2str(size(spindles,1)) ' events.']);

% Discard spindles that are way too long
duration = spindles(:,3)-spindles(:,1);
spindles(duration>maxRippleDuration/1000,:) = [];
disp(['  Step 5: After max duration test: ' num2str(size(spindles,1)) ' events.']);

% If a noisy channel was provided, find ripple-like events and exclude them
bad = [];
if ~isempty(noise),
	% Square and pseudo-normalize (divide by signal stdev) noise
	squaredNoise = noise(:,2).^2;
	window = ones(windowLength,1)/windowLength;
	normalizedSquaredNoise = unity(Filter0(window,sum(squaredNoise,2)),sd,[]);
	excluded = logical(zeros(size(spindles,1),1));
	% Exclude spindles when concomittent noise crosses high detection threshold
	previous = 1;
	for i = 1:size(spindles,1),
		j = FindInInterval(noise,[spindles(i,1),spindles(i,3)],previous);
		previous = j(2);
		if any(normalizedSquaredNoise(j(1):j(2))>highThresholdFactor),
			excluded(i) = 1;
		end
	end
	bad = spindles(excluded,:);
	spindles = spindles(~excluded,:);
	disp(['  Step 6: After noise removal: ' num2str(size(spindles,1)) ' events.']);
end

%% -----------------------------------
% Extract peak amplitude and frequency 
% (also add duration in ms)
% added by S. Laventure 2021-01
LFP = tsd(time*1E4,signal);
FiltLFP = FilterLFP(LFP, [10 20], 1024);
FinalspindlesEpoch = intervalSet(spindles(:,1)*1E4,spindles(:,3)*1E4);

% find peak-to-peak amplitude
func_amp = @(a) measureOnSignal(a,'amplitude_p2p');
[amp, ~, ~] = functionOnEpochs(FiltLFP, FinalspindlesEpoch, func_amp); %,'uniformoutput',false);

% Detect instantaneous frequency 
st_ss = spindles(:,1)*1E4;
en_ss = spindles(:,3)*1E4;
freq = zeros(length(st_ss),1);
for i=1:length(st_ss)
	peakIx = LocalMinima(Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i)))),4,0);
    if ~isempty(peakIx)
        freq(i) = frequency/median(diff(peakIx));
    end
end 

% add duration, frequency and peak amplitude (normalized peak amplitude is discarded)
if not(isempty(Start(FinalspindlesEpoch)))
    spindles(:,4) = Stop(FinalspindlesEpoch,'ms')-Start(FinalspindlesEpoch,'ms');
    spindles(:,5) = freq;
    spindles(:,6) = amp;
else
    spindles(:,4) = NaN;
    spindles(:,5) = NaN;
    spindles(:,6) = NaN;
end
%% -----------------------------------

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

