%%GetDownStates
% 18.12.2018 KJ
%
% get/load Down Staes
%
% function down_states = GetDownStates(varargin)
%
% INPUT:
% - area (optional)             = brain area of detection
%                               (default 'PFCx')
% - Epoch (optional)            = epoch on which Down States detection is restricted 
%                               (default no restrict)
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%
%
% OUTPUT:
% - down_states             = Down States intervalSet (Start End)
%
%   see 
%       


function down_states = GetDownStates(varargin)


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


%init
down_states = [];

%% Get Down states
if exist(fullfile(foldername,'DownState.mat'), 'file')==2
    load(fullfile(foldername,'DownState.mat'));   
    try
        eval(['down_states = down_' area ';'])
    catch
        disp(['No Down states file found for ' area])
    end
else
    disp('No Down states file found')
end


%% Restrict eventually
if ~isempty(Epoch) && ~isempty(down_states)
    down_states = and(down_states,Epoch);
end
    
    

end

