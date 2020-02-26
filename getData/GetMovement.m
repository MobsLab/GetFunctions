%%GetMovement
% 18.12.2018 KJ
%
% get/load movement
%
% function MovAcctsd = GetMovement(varargin)
%
% INPUT:
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%
% OUTPUT:
% - MovAcctsd           = tsd of movement (Start End)
%
%   see 
%       
%


function MovAcctsd = GetMovement(varargin)


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
   

%% Get movement
load(fullfile(foldername,'behavResources.mat'), 'MovAcctsd')
if ~exist(MovAcctsd, 'var')
    disp('No movement file found')
end


%% Restrict eventually
if ~isempty(Epoch)
    MovAcctsd = Restrict(MovAcctsd,Epoch);
end
    


end

