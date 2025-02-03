function [ripples,stdev] = FindSpindles_sqrt (LFP_rip, Epoch, thresh, varargin)

% =========================================================================
%                            FindRipples_sqrt
% =========================================================================
% 
% USAGE: [ripples, stdev] = FindRipples_sqrt(LFP_rip, LFP_noise, Epoch, thresh, varargin)
%
% DESCRIPTION:  Prepare LFP for ripples detection. 
%               Part of MOBs' CreateSleepSignal pipeline.
%
%               This code was originally a wrapper written by D. Bryzgalow 
%               for the M. Zugaro FindRipples function. It was adapted for 
%               the MOBs pipeline by S. Laventure (2021-01).
%
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       LFP_rip             LFP (one channel).
%       LFP_noise           LFP with channel without targeted events 
%       Epoch               Targeted epoch
%
%       <varargin>          optional list of property-value pairs (see table below)
%
%     'stdev'               constant std
%     'frequency'           frequency band of the ripples (default = [120 250])  
%     'threshold'           thresholds for ripple detection (default = [4 6])
%     'durations'           min inter-ripple interval & min and max ripple duration, in ms
%                           (default = [15 20 200])
%     'clean'               get rid of significant noise artefact (default = 1)
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       ripples             [start(in s) peak(in s) end(in s) duration(in ms) 
%                           frequency peak-amplitude]   
%       stdVal              standard value of LFP
% =========================================================================
% VERSIONS
%   2018 DB
%   20.01.2021 S. Laventure - adapted to MOBs pipeline
%
% =========================================================================
% SEE   CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
%       FindRipples_zug FindRipples FindRipples_abs CreateRipplesSleep
% =========================================================================

%% Parameters

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).']);
    end
    switch(lower(varargin{i}))
		case 'stdev'
			sd = varargin{i+1};
			if isdscalar(sd,'<0')
				error('Incorrect value for property ''stdev'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
            end
		case 'frequency'
			freq = varargin{i+1};
			if isdvector(freq,'#1')
				error('Incorrect value for property ''frequency'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
            end
        case 'thresh'
			thresh = varargin{i+1};
			if isdvector(thresh)
				error('Incorrect value for property ''thresh'' .');
            end
        case 'durations'
			dur = varargin{i+1};
			if isdvector(dur,'#1')
				error('Incorrect value for property ''durations'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
            end
        case 'clean'
			clean = varargin{i+1};
			if isdscalar(clean,'==0','==1')
				error('Incorrect value for property ''clean'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
            end
    end
end

%check if exist and assign default value if not
if ~exist('thresh','var')
   thresh = [2 5]; % Thresholds for FindRipples
end
if ~exist('clean','var')
   clean = 1; % Do we need to calculate noise on a noiseless epochs?
end

% Parameters to change manually
noise_thr = 13E3;
%%%%----------------------------------%%%
freq = [10 20]; % frequency range of ripples
dur = [200 400 3000]; % Durations for FindRipples
sd = [];
%%%%----------------------------------%%%

% set if removing noise
% if ~isempty(LFP_noise)
%     rmvnoise=1;
% else
%     rmvnoise=0;
% end

%% Load data
res = pwd;
LFP_rest = Restrict(LFP_rip,Epoch);
LFPf=FilterLFP(LFP_rest,freq,1048);
LFPr=LFP_rest;
% if rmvnoise
%     LFP_noise_rest = Restrict(LFP_noise,Epoch);
%     LFPfn=FilterLFP(LFP_noise_rest,freq,1048);
%     LFPn=LFP_noise_rest;
%     NoiseTime=Range(LFPfn, 's');
%     NoiseData=Data(LFPfn);
% end
GoodTime=Range(LFPf, 's');
GoodData=Data(LFPf);
clear LFP_rip

%% Calculate standard deviation without noise
if clean == 1
    load('behavResources.mat');
    AboveEpoch=thresholdIntervals(LFPr,noise_thr,'Direction','Above'); % Threshold on non-filtered data!!!
    NoiseEpoch=thresholdIntervals(LFPr,-noise_thr,'Direction','Below'); % Threshold on non-filtered data!!!
    CleanEpoch=or(AboveEpoch,NoiseEpoch);
    CleanEpoch=intervalSet(Start(CleanEpoch)-3E3,End(CleanEpoch)+5E3);
    if logical(exist('TTLInfo'))
        if isfield(TTLInfo, 'StimEpoch')
            StimEpoch = intervalSet(Start(TTLInfo.StimEpoch)-1E3, End(TTLInfo.StimEpoch)+3E3);
            GoEpoch = or(CleanEpoch,StimEpoch);
        else
            GoEpoch=CleanEpoch;
        end
    else
        GoEpoch=CleanEpoch;
    end
    rg=Range(LFPr);
    TotalEpoch=intervalSet(rg(1),rg(end));
    SCleanEpoch=mergeCloseIntervals(GoEpoch,1);
    GoodTime=Range(Restrict(LFPf,TotalEpoch-SCleanEpoch), 's');
    GoodData=Data(Restrict(LFPf,TotalEpoch-SCleanEpoch));
    %     if rmvnoise
    %         NoiseTime=Range(Restrict(LFPfn,TotalEpoch-SCleanEpoch), 's');
    %         NoiseData=Data(Restrict(LFPfn,TotalEpoch-SCleanEpoch));
%     end
end

% %% Find Ripples
% if rmvnoise
%     if ~isempty(sd)
%         [ripples, stdev,~] = FindSpindles_zug([GoodTime GoodData], 'thresholds',thresh,'durations',dur,...
%         'stdev', sd, 'noise',[NoiseTime NoiseData]);
%     else
%         [ripples, stdev,~] = FindSpindles_zug([GoodTime GoodData], 'thresholds',thresh,'durations',dur,...
%         'noise',[NoiseTime NoiseData]);
%     end
% else
    if ~isempty(sd)
        [ripples,stdev] = FindSpindles_zug([GoodTime GoodData], 'thresholds',thresh,'durations',dur, 'stdev', sd);
    else
        [ripples,stdev] = FindSpindles_zug([GoodTime GoodData], 'thresholds',thresh,'durations',dur);
    end
% end

end




