%%GetDeltaWaves
% 18.12.2018 KJ
%
% get/load delta waves
%
% function delta_waves = GetDeltaWaves(varargin)
%
% INPUT:
% - area (optional)             = brain area of detection
%                               (default 'PFCx')
% - Epoch (optional)            = epoch on which Delta waves detection is restricted 
%                               (default no restrict)
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%
%
% OUTPUT:
% - delta_waves             = Delta waves intervalSet (Start End)
%
%   see 
%       


function delta_waves = GetDeltaWaves(varargin)


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
        case 'area'
            area = varargin{i+1};
        case 'Epoch'
            Epoch = varargin{i+1};
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('area','var')
    area='PFCx';
end
if ~exist('Epoch','var')
    Epoch=[];
end
if ~exist('foldername','var')
    foldername = pwd;
end



%% Get Delta waves
if exist(fullfile(foldername,'DeltaWaves.mat'), 'file')==2
    load(fullfile(foldername,'DeltaWaves.mat'));    
    eval(['delta_waves = deltas_' area ';'])
    
elseif exist(fullfile(foldername,'AllDeltaPFCx.mat'), 'file')==2
    load(fullfile(foldername,'AllDeltaPFCx.mat'), 'DeltaEpoch'); 
    delta_waves = DeltaEpoch;
else
    disp('No Delta Waves file found')
end


%% Restrict eventually
if ~isempty(Epoch)
    delta_waves = and(delta_waves,Epoch);
end
    

end

