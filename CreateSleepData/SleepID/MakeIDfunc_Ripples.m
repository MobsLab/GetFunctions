% MakeIDfunc_Ripples
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData MakeIDfunc_Neuron MakeIDfunc_Spindles
%


function [meancurve, nb_ripples] = MakeIDfunc_Ripples(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'binsize'
            binsize = lower(varargin{i+1});
            if binsize<=0
                error('Incorrect value for property ''binsize''.');
            end
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'lfp_ripples'
            LFP_ripples = varargin{i+1};
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('binsize','var')
    binsize = 50;
end
if ~exist('recompute','var')
    recompute=0;
end

if exist('SWR.mat','file')~=2 && exist('Ripples.mat','file')~=2
    disp('no ripples here')
    meancurve=[]; nb_ripples=0;
    return
end

%exist or load
if ~exist('LFP_ripples','var')
    %LFP Ripples
    try
        load('SWR.mat')    
    catch
        load('Ripples.mat')
    end
end

if ~exist('M','var')
    load(['LFPData/LFP' num2str(ripples_Info.channel)])
    LFP_ripples=LFP;
    clear LFP

    %% load ripples
    [tRipples, ~] = GetRipples('foldername',foldername);
    ripples_tmp = Range(tRipples)/1e4;


    %% Ripples and Spindles
    meancurve = PlotRipRaw(LFP_ripples, sort(ripples_tmp), binsize, 0, 0); close
    nb_ripples = length(ripples_tmp);
else
    meancurve = M;
    if exist('ripples','var')
        nb_ripples = size(ripples,1);
    else
        nb_ripples = size(Ripples,1);
    end
end
end












