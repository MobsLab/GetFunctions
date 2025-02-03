function [ripples, meanVal, stdVal] = FindRipples_abs(LFP, nonLFP, Epoch, SWSEpoch, varargin)

% =========================================================================
%                            FindRipples_abs
% =========================================================================
% 
% USAGE: [ripples, meanVal, stdVal] = FindRipples_abs(LFP, nonLFP, Epoch, varargin)
%
% DESCRIPTION:  Detect and save ripples using absolute value
%               Part of MOBs' CreateSleepSignal pipeline.
%
%               Structure of ripples:
%                   ----------------------------
%                   - Start (in seconds)
%                   - Peak (in seconds)
%                   - End (in seconds)
%                   - Duration (in milliseconds)
%                   - Frequency
%                   - Max p2p amplitude
%                   ----------------------------
%
%               This code was adapted from FindRipplesSB by Karim El Kanbi
%               Cleaned and modified to include amplitude, frequency 
%               detection and filtering through a non Ripple channel by
%               Samuel laventure 2020-12
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       LFP                 LFP (one channel).
%       nonLFP              LFP with channel without targeted events 
%       Epoch               Targeted epoch
%
%       <varargin>          optional list of property-value pairs (see table below)
%
%     'frequency_band'      frequency band of the ripples (default = [120 250])  
%     'threshold'           thresholds for ripple detection (default = [4 6])
%     'durations'           min inter-ripple interval & min and max ripple duration, in ms
%                           (default = [15 20 200])
%     'mean_std_values'     mean and standard deviation to normalize signals
%                           (default: computed on signals)
%     'stim'                (0 or 1) stimulation to filter out  
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       ripples             [start(in s) peak(in s) end(in s) duration(in ms) 
%                           frequency peak-amplitude]              
%       meanVal             average value of LFP
%       stdVal              standard value of LFP
% =========================================================================
% VERSIONS
%   07.12.2017 SB & KJ
%   10.12.2020 S. Laventure
%   20.01.2021 S. Laventure - adapted to MOBs pipeline
%
% =========================================================================
% SEE   CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
%       FindRipples_zug FindRipples FindRipples_sqrt
% =========================================================================


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
    threshold = [4 6];
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
if ~isempty(nonLFP)
    rmvnoise=1;
else
    rmvnoise=0;
end

if rmvnoise
    % calculate overall SD
    FiltnonLFP = FilterLFP(nonLFP, frequency_band, 1024); %filter
    FiltnonLFP_EpochRestrict = Restrict(FiltnonLFP, Epoch); %restrict to Epoch
    signal_squared = abs(Data(FiltnonLFP_EpochRestrict));
    % prep data for sd
    nonlfp_sws = Restrict(FiltnonLFP, SWSEpoch); %restrict to Epoch
    signal_squared_non_sws = abs(Data(nonlfp_sws));
    if exist('mean_std_values','var')
        meanVal_nonRip = mean_std_values(1);
        stdVal_nonRip = mean_std_values(2);
    else
        meanVal_nonRip = mean(signal_squared_non_sws);
        stdVal_nonRip = std(signal_squared_non_sws);
    end

    %signal taken over the whole record for detection
    signal_squared = abs(Data(FiltnonLFP));
    SquaredFiltnonLFP = tsd(Range(FiltnonLFP),signal_squared-meanVal_nonRip);

    % Detect using low threshold
    nonRipples = thresholdIntervals(SquaredFiltnonLFP, threshold(1)*stdVal_nonRip);
end

%% Processing Ripple channel
% Calculate overall SD
Filsp_tmp = FilterLFP(LFP, frequency_band, 1024); %filter

% clear stim from LFP
if stim
    try
        load('behavResources.mat','StimEpoch'); % supposed for eyelid, 0.1 ms before, 0.5 ms after
        st = Start(StimEpoch);
        if isempty(st)
            time = Range(Filsp_tmp);
            NoStimEpoch = intervalSet(time(1), time(end));
        else
            time = Range(Filsp_tmp);
            TotalEpoch = intervalSet(time(1), time(end));
            for istim=1:length(st)
                sti(istim) = st(istim)-1000;
                en(istim) = st(istim)+5000;
            end
            stim_ti = intervalSet(sti,en);
            NoStimEpoch = TotalEpoch - stim_ti;
        end
        
        try % add by BM, optimized for VHC stims
            clear st time sti en
            load('behavResources.mat','StimEpoch2'); % supposed for VHC, 0.05 ms before, 0.2 ms after
            st = Start(StimEpoch2);
            time = Range(Filsp_tmp);
            
            TotalEpoch = intervalSet(time(1), time(end));
            for istim=1:length(st)
                sti(istim) = st(istim)-500; % changed from 0.1s to 0.05s the 25/08/2023
                en(istim) = st(istim)+1000; % changed from 0.2s to 0.1s the 29/08/2023
            end
            stim_ti = intervalSet(sti,en);
            NoStimEpoch2 = TotalEpoch - stim_ti;
            FiltLFP_pre = Restrict(Filsp_tmp, NoStimEpoch2);
            FiltLFP = Restrict(FiltLFP_pre, NoStimEpoch);
        catch
            FiltLFP = Restrict(Filsp_tmp, NoStimEpoch);
        end
    catch
        warning('There is no StimEpoch for this session')
        FiltLFP=Filsp_tmp;
    end
else
    FiltLFP=Filsp_tmp;
end

FiltLFP_EpochRestrict = Restrict(FiltLFP, Epoch); %restrict to Epoch
signal_squared = abs(Data(FiltLFP_EpochRestrict));
% prep data for sd
lfp_sws = Restrict(FiltLFP, SWSEpoch); %restrict to Epoch
signal_squared_sws = abs(Data(lfp_sws));
if exist('mean_std_values','var')
    meanVal = mean_std_values(1);
    stdVal = mean_std_values(2);
else
    meanVal = mean(signal_squared_sws);
    stdVal = std(signal_squared_sws);
end

%signal taken over the whole record for detection
% signal_squared = abs(Data(FiltLFP));
SquaredFiltLFP = tsd(Range(FiltLFP_EpochRestrict),signal_squared-meanVal);

% Detect using low threshold
PotentialRipples = thresholdIntervals(SquaredFiltLFP, threshold(1)*stdVal);
disp(['  Step 1: After LOW thresholding: ' num2str(length(Start(PotentialRipples))) ' events']);

% Merge ripples that are very close together
PotentialRipples = mergeCloseIntervals(PotentialRipples, minInterRippleInterval);
disp(['  Step 2: After merging close events: ' num2str(length(Start(PotentialRipples))) ' events']);

% Filtering out artefact events
if rmvnoise
    st = Start(nonRipples);
    en = End(nonRipples);
    ev_ti = intervalSet(st-500,en+500);
    PotentialRipples = PotentialRipples - ev_ti;
    disp(['  Step 3: After removing artefacts (from non-ripple channel): ' num2str(length(Start(PotentialRipples))) ' events']);
else
    disp('  Step 3: No non-ripple channel set.')
end

% Get rid of ripples that are too short
PotentialRipples = dropShortIntervals(PotentialRipples, minRippleDuration);
disp(['  Step 4: After removing too short events: ' num2str(length(Start(PotentialRipples))) ' events']);

% Get rid of ripples that are too long
PotentialRipples = dropLongIntervals(PotentialRipples, maxRippleDuration);
disp(['  Step 5: After removing too long events: ' num2str(length(Start(PotentialRipples))) ' events']);

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
disp(['  Step 6: After removing events below 2nd threshold: ' num2str(length(Start(FinalRipplesEpoch))) ' events']);

%% Extracting chracteristics
% find peak-to-peak amplitude
func_amp = @(a) measureOnSignal(a,'amplitude_p2p');
if not(isempty(Start(FinalRipplesEpoch))) % add by BM on 03/01/2022
    [amp, ~, ~] = functionOnEpochs(FiltLFP, FinalRipplesEpoch, func_amp);
end

% Detect instantaneous frequency Model 1
st_ss = Start(FinalRipplesEpoch);
en_ss = Stop(FinalRipplesEpoch);
freq = zeros(length(st_ss),1); % modified by BM on 17/12/2021 based on KB advices
for i=1:length(st_ss)
	%peakIx = LocalMinima(Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i)))) , 4 ,0); 
	peakIx = LocalMaxima(resample(Data(Restrict(FiltLFP,intervalSet(st_ss(i),en_ss(i)))) , 30 , 1) , 4 ,0); % resample ripples data to be 30 times more detailed, find maxima rather than minima where spikes are
    if ~isempty(peakIx)
        freq(i) = frequency/(median(diff(peakIx))/30);
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

%% Creating main variable
if not(isempty(Start(FinalRipplesEpoch)))
    ripples(:,1) = Start(FinalRipplesEpoch,'s');
    ripples(:,2) = nadir_tmp / 1E4;  
    ripples(:,3) = Stop(FinalRipplesEpoch,'s');
    ripples(:,4) = Stop(FinalRipplesEpoch,'ms')-Start(FinalRipplesEpoch,'ms');
    ripples(:,5) = freq;
    ripples(:,6) = amp;
else
    ripples(:,1) = NaN;
    ripples(:,2) = NaN;
    ripples(:,3) = NaN;
    ripples(:,4) = NaN;
    ripples(:,5) = NaN;
    ripples(:,6) = NaN;
end



