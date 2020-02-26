% MakeIDfunc_LfpInfo
% 08.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_DownDelta MakeIDfunc_SleepEvent
%
%


function [nb_channel, lfp_structures, hemispheres] = MakeIDfunc_LfpInfo(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
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



%% init
load('LFPData/InfoLFP.mat');

%hemisphere
hemispheres = {'L','R','NaN'};
for i=1:length(InfoLFP.hemisphere)
    if strcmpi(InfoLFP.hemisphere{i},'right') || strcmpi(InfoLFP.hemisphere{i},'left')
        InfoLFP.hemisphere{i} = InfoLFP.hemisphere{i}(1);
    end
end

%LFP structures
lfp_structures = unique(InfoLFP.structure);
lfp_structures(strcmpi(lfp_structures,'nan'))=[];
lfp_structures(strcmpi(lfp_structures,'ref'))=[];
lfp_structures(strcmpi(lfp_structures,'noise'))=[];


%% info
for i=1:length(lfp_structures)
    for h=1:length(hemispheres)
        area_channels = strcmpi(lfp_structures{i}, InfoLFP.structure) & strcmpi(hemispheres{h}, InfoLFP.hemisphere);
        nb_channel(i,h) = sum(area_channels);
    end
end





end




