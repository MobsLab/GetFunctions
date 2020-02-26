%FindDownKJ
%01.04.2016 KJ
%
% [Down, small_Down] = FindDownKJ(MUA);
% Find Down Intervals
% Find periods of neural silence
%
%% INPUT:
%   MUA                         tsd: Times (ts) x Sparse Array
%
%   low_thresh (optional)       double (default 0.5)
%                               second or unique threshold applied on data, it correspond to real silence
%   high_thresh (optional)      double (default 0.5)   
%                               for the method double (threshold) only, first threshold applied on data
%   minduration (optional)      double (default 75ms or 100ms)
%                               minimum duration of a detection
%   maxduration (optional)      double (default 500ms)
%                               maximum duration of a detection
%   mergegap (optional)         double (default 10ms)
%                               condition in the duration between two detection to merge them
%   predown_size (optional)     double (default 0ms or 50ms)
%                               minimum duration of detections before merging them
%   method (optional)           double (default 'mono')
%                               'mono' for unique threshold method, 'double' for two threshold method
%   smooth (optional)           double (default 0)
%                               smmothing parameter for the MUA data
%
%% OUTPUT:
% - Down            Down state intervalSet
% - small_Down      intervalSet of small Down states, not retained by the duration threshold
%
%
%
% EXAMPLE OF PARAMS
%       (used in the DeltaTone Project)
%       thresh0 = 0.7;
%       minDownDur = 90;
%       maxDownDur = 500;
%       mergeGap = 10; % merge
%       predown_size = 50;
%
%
% USER EXAMPLE 
%       Down = FindDownKJ(MUA, 'low_thresh', thresh0, 'high_thresh', thresh1, 'minDuration', minDuration,'maxDuration', maxDuration, 'mergeGap', mergeGap, 'predown_size', predown_size);
%       Down = FindDownKJ(MUA)    --> default mode, just give the MUA signal in input
%
%
%   To get the MUA signal :
%
%       binsize = 10 %in ms
%       T=PoolNeurons(S,NumNeurons);
%       ST{1}=T;
%       try
%           ST=tsdArray(ST);
%       end
%       MUA = MakeQfromS(ST,binsize*10); %binsize*10 to be in E-4s
%       MUA = Restrict(Q, SWSEpoch);
%
% 
% See 
%   CreateSignalsIDFigures
%
%
%

function [Down, small_Down] = FindDownKJ(MUA, varargin)


%% Initiation

if nargin < 1 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'low_thresh'
            thresh0 = varargin{i+1};
            if ~isfloat(thresh0) || thresh0 <=0
                error('Incorrect value for property ''low_thresh''.');
            end
        case 'high_thresh'
            thresh1 = varargin{i+1};
            if ~isfloat(thresh1) || thresh1 <=0
                error('Incorrect value for property ''high_thresh''.');
            end
        case 'minduration'
            minDuration = varargin{i+1};
            if ~isint(minDuration) || minDuration <0
                error('Incorrect value for property ''minDuration''.');
            end
        case 'maxduration'
            maxDuration = varargin{i+1};
            if ~isint(maxDuration) || maxDuration <=0
                error('Incorrect value for property ''maxDuration''.');
            end
        case 'mergegap'
            mergeGap = varargin{i+1};
            if ~isint(mergeGap) || mergeGap <0
                error('Incorrect value for property ''mergeGap''.');
            end
        case 'predown_size'
            predown_size = varargin{i+1};
            if ~isint(predown_size) || predown_size <0
                error('Incorrect value for property ''predown_size''.');
            end
        case 'method'
            method = lower(varargin{i+1});
            if ~isstring_FMAToolbox(method, 'mono', 'double')
                error('Incorrect value for property ''method''.');
            end
        case 'smooth'
            smooth_param = lower(varargin{i+1});
            if ~isint(smooth_param) || smooth_param <0
                error('Incorrect value for property ''smooth''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

if ~exist('method', 'var')
    method = 'mono';
end
if ~exist('smooth_param', 'var')
    smooth_param = 0;
end

if smooth_param>0
    MUA=tsd(Range(MUA),smooth(full(Data(MUA)),smooth_param));
else
    MUA=tsd(Range(MUA),full(Data(MUA)));
end



%%
%% METHODS


%% double: two thresholds are applied
if strcmp(method, 'double')
    if ~exist('thresh0', 'var')
        thresh0 = 0.5;
    end
    if ~exist('thresh1', 'var')
        thresh1 = 1.1;
    end
    try
        minDuration = minDuration * 10; %in E-4s
    catch
        minDuration = 750;
    end

    try
        maxDuration = maxDuration * 10; %in E-4s
    catch
        maxDuration = 6000;
    end

    try
        mergeGap = mergeGap * 10; %in E-4s
    catch
        mergeGap = 100;
    end

    try
        predown_size = predown_size * 10; %in E-4s
    catch
        predown_size = 300;
    end


    LowMuaInt = thresholdIntervals(MUA,thresh1,'Direction','Below');
    Q1 = Restrict(MUA, LowMuaInt);
    Predown = thresholdIntervals(Q1,thresh0,'Direction','Below');
    small_Down1 = dropLongIntervals(Predown, predown_size); %keep small down
    Predown = dropShortIntervals(Predown, predown_size);
    warning off
    if mergeGap > 0
        Down = mergeCloseIntervals(Predown, mergeGap);
    else
        Down = Predown;
    end
    warning on
    Down = dropLongIntervals(Down, maxDuration);
    small_Down2 = dropLongIntervals(Down, minDuration);
    
    Down = dropShortIntervals(Down, minDuration); 
    small_Down = union(small_Down1, small_Down2);
    
    
%% mono: only one threshold is applied
elseif strcmp(method, 'mono')
    if ~exist('thresh0', 'var')
        thresh0 = 0.5;
    end
    try
        minDuration = minDuration * 10; %in E-4s
    catch
        minDuration = 750;
    end

    try
        maxDuration = maxDuration * 10; %in E-4s
    catch
        maxDuration = 5000;
    end
    try
        mergeGap = mergeGap * 10; %in E-4s
    catch
        mergeGap = 100;
    end
    try
        predown_size = predown_size * 10; %in E-4s
    catch
        predown_size = 0;
    end
    
    Predown = thresholdIntervals(MUA,thresh0,'Direction','Below');
    small_Down1 = dropLongIntervals(Predown, predown_size); %keep small down
    Predown = dropShortIntervals(Predown, predown_size);
    warning off
    if mergeGap > 0
        Down = mergeCloseIntervals(Predown, mergeGap);
    else
        Down = Predown;
    end
    warning on
    Down=dropLongIntervals(Down, maxDuration);
    small_Down2 = dropLongIntervals(Down, minDuration);
    %output
    Down=dropShortIntervals(Down, minDuration);
    small_Down = union(small_Down1, small_Down2);
    
end
    
    
