%FindSpindlesKJ - Find spindles.
%
%  USAGE
%
%    Spindles = FindSpindlesKJ(LFP, Epoch, varargin)
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
%  SEE 
%    FindSpindlesKJ2 FindSpindlesKJ3 FindSpindlesKarimNewSB
%


function [Spindles, SWA] = FindSpindlesSL(LFP, Epoch, varargin)

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
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
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
    if isequal(frequency_band,[2 20])
        threshold = [1.5 4];
    else
        threshold = [3 5];
    end
end
if ~exist('durations','var')
    durations = [100 350 200000]; %in ms
end
%stim
if ~exist('stim','var')
    stim=0;
end
minInterSpindleInterval = durations(1) * 10; % in ts
minSpindleDuration = durations(2) * 10;
maxSpindleDuration = durations(3) * 10;


%% variance computation
if tot_length(Epoch)>12000e4 % more than 200min
    variance_epoch=subset(Epoch,1:floor(length(Start(Epoch))/3));
else
    variance_epoch=Epoch;
end

frequency=round(1/median(diff(Range(LFP,'s'))));
windowLength = round(frequency/1250*11);    
window = ones(windowLength,1)/windowLength;

squaredSignal = Data(Restrict(FilterLFP(LFP,frequency_band,512),variance_epoch)).^2;
filtsig = Filter0(window,sum(squaredSignal,2));
variance_sig = (2/3) * std(filtsig);


%% look for spindles
Filsp_tmp = FilterLFP(LFP,frequency_band,512);
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
        Filsp = Restrict(Filsp_tmp, NoStimEpoch);
    catch
        warning('There is no StimEpoch for this session')
        Filsp=Filsp_tmp;
    end
else
    Filsp=Filsp_tmp;
end
Filsp_sws = Restrict(FilterLFP(LFP,frequency_band,512),variance_epoch);

rg_epoch = Range(Filsp_sws,'s');
filtered = [rg_epoch-rg_epoch(1) Data(Filsp_sws)];

[Spindles, SWA] = FindspindlesMarie(filtered,'durations',[100 350 200000], 'stdev',variance_sig, 'thresholds',threshold, 'show','off');


end


function y = Filter0(b,x)

    if size(x,1) == 1
        x = x(:);
    end

    if mod(length(b),2)~=1
        error('filter order should be odd');
    end
    shift = (length(b)-1)/2;
    [y0,z] = filter(b,1,x);
    y = [y0(shift+1:end,:) ; z(1:shift,:)];

end

