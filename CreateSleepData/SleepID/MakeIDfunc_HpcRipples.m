% MakeIDfunc_HpcRipples
% 09.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_DownDelta MakeIDfunc_SleepEvent MakeIDfunc_LfpInfo MakeIDfunc_LfpOnDown
%
%


function [meancurves, hpc_channels, hpc_hemispheres] = MakeIDfunc_HpcRipples(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'windowsize'
            windowsize = lower(varargin{i+1});
        case 'foldername'
            foldername = lower(varargin{i+1});
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
if ~exist('recompute','var')
    recompute=0;
end
if ~exist('windowsize','var')
    windowsize=400; %in ms
end

%% load
if exist('Ripples.mat','file')==2 || exist('SWR.mat','file')==2
        [tRipples, RipplesEpoch] = GetRipples;
        ripples_tmp = Range(tRipples,'s');
%     load('Ripples.mat', 'Ripples')
%     ripples_tmp = Ripples(:,2)/1e3; %in s
else
    meancurves = cell(0);
    hpc_channels = [];
    hpc_hemispheres = cell(0);
    return
end

%% Structures
load('LFPData/InfoLFP.mat');

hpc_channels = InfoLFP.channel(strcmpi(InfoLFP.structure,'HPC')|strcmpi(InfoLFP.structure,'dHPC'));

%hemisphere
for i=1:length(InfoLFP.hemisphere)
    if strcmpi(InfoLFP.hemisphere{i},'right') || strcmpi(InfoLFP.hemisphere{i},'left')
        InfoLFP.hemisphere{i} = InfoLFP.hemisphere{i}(1);
    end
end
hpc_hemispheres = InfoLFP.hemisphere(strcmpi(InfoLFP.structure,'HPC')|strcmpi(InfoLFP.structure,'dHPC'));


%% means curves
for ch=1:length(hpc_channels)
    load(['LFPData/LFP' num2str(hpc_channels(ch))], 'LFP')
    meancurves{ch} = PlotRipRaw(LFP,ripples_tmp, windowsize,0,0);
    clear LFP
end


end




