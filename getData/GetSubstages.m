%%GetSubstages
% 18.12.2018 KJ
%
% get/load sleep substages: N1,N2,N3,REM & Wake
% 
% function [N1, N2, N3, REM, Wake] = GetSubstages(varargin)
%
% 
% INPUT:
% - foldername (optional)       = directory to get the data
%                               (default pwd)
% - scoring     (optional)       = which scoring to use, bulb or accelero,
% will use bulb by default
% 
% OUTPUT:
% - N1, N2, N3, REM, Wake          = intervalSet (Start End)
%
%   see 
%       GetSleepScoring
%


function [N1, N2, N3, REM, Wake] = GetSubstages(varargin)


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
        case 'foldername'
            foldername = varargin{i+1};
        case 'scoring'
            scoring = lower(varargin{i+1});
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('scoring','var')
    scoring = 'ob';
end

%% Get Epochs
if exist(fullfile(foldername,'SleepSubstages.mat'), 'file')==2 || exist(fullfile(foldername,'SleepSubstages_Accelero.mat'), 'file')==2
    switch scoring
        case 'ob'
            load('SleepSubstages.mat', 'Epoch', 'NameEpoch')
            Substages = Epoch;
            NamesSubstages = NameEpoch;
        case 'accelero'
            load('SleepSubstages_Accelero.mat', 'Epoch', 'NameEpoch')
            Substages = Epoch;
            NamesSubstages = NameEpoch;
    end

elseif exist(fullfile(foldername,'NREMepochsML.mat'), 'file')==2
    load('NREMepochsML.mat', 'op', 'noise')
    [Substages,NamesSubstages]=DefineSubStages(op,noise);

else
    disp('No Sleep substages file found')
end


%% result
N1   = Substages{strcmpi(NamesSubstages,'N1')};
N2   = Substages{strcmpi(NamesSubstages,'N2')};
N3   = Substages{strcmpi(NamesSubstages,'N3')};
REM  = Substages{strcmpi(NamesSubstages,'REM')};
Wake = Substages{strcmpi(NamesSubstages,'Wake')};


end

