%%GetRipples
% 18.12.2018 KJ
%
% get/load Ripples
%
% function [tRipples, RipplesEpoch] = GetRipples(varargin)
%
% INPUT:
% - Epoch (optional)            = epoch on which Ripples detection is restricted 
%                               (default no restrict)
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%

%
%
% OUTPUT:
% - tRipples                = ts of SPW-Ripples center
% - RipplesEpoch            = Ripples intervalSet (Start End)
%
%
%   see 
%       
%


function [tRipples, RipplesEpoch] = GetRipples(varargin)


%% CHECK INPUTS

if mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'Epoch'
            Epoch = varargin{i+1};
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('Epoch','var')
    Epoch=[];
end
if ~exist('foldername','var')
    foldername = pwd;
end



%% Get Ripples
if exist(fullfile(foldername,'SWR.mat'), 'file')==2
    load(fullfile(foldername,'SWR.mat'));
    
    if ~exist('tRipples','var')
        tRipples = ts(Ripples(:,2)*10);
    end 
elseif exist(fullfile(foldername,'Ripples.mat'), 'file')==2
    load(fullfile(foldername,'Ripples.mat'));
    
    if ~exist('tRipples','var')
        tRipples = ts(Ripples(:,2)*10);
    end
    
elseif exist(fullfile(foldername,'AllRipplesdHPC25.mat'), 'file')==2
    load(fullfile(foldername,'AllRipplesdHPC25.mat'));
    
    tRipples = ts(dHPCrip(:,2)*1e4);
    RipplesEpoch = intervalSet(dHPCrip(:,1)*1e4, dHPCrip(:,3)*1e4);
    
    
else
    disp('No Ripples file found')
end


%% Restrict eventually
if ~isempty(Epoch)
    tRipples = Restrict(tRipples,Epoch);
    RipplesEpoch = and(RipplesEpoch,Epoch);
end
    
    

end

