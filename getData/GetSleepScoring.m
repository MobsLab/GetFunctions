%%GetSleepScoring
% 18.12.2018 KJ
%
% get/load sleep scoring i.e Wake, REM & NREM
%
% function [NREM, REM, Wake, TotalNoiseEpoch] = GetSleepScoring(varargin)
%
% INPUT:
% - scoring (optional)          = method of sleep scoring (ob or accelero)
%                               (default 'ob')
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%
% OUTPUT:
% - NREM, REM, Wake, TotalNoiseEpoch    = intervalSet (Start End)
%
%   see 
%       GetSubstages        
%


function [NREM, REM, Wake, TotalNoiseEpoch] = GetSleepScoring(varargin)


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
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isastring(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('scoring','var')
    scoring = 'ob';
end
if ~exist('foldername','var')
    foldername = pwd;
end

    

%% Get Epochs
if strcmpi(scoring,'ob')
    if exist(fullfile(foldername,'SleepScoring_OBGamma.mat'), 'file')==2
        load(fullfile(foldername,'SleepScoring_OBGamma.mat'), 'REMEpoch', 'SWSEpoch', 'Wake','TotalNoiseEpoch')

    elseif exist(fullfile(foldername,'StateEpochSB.mat'), 'file')==2
        load(fullfile(foldername,'StateEpochSB.mat'), 'REMEpoch', 'SWSEpoch', 'Wake','TotalNoiseEpoch')
        
    else
        disp('No Sleep scoring file found')
    end
    
    
elseif strcmpi(scoring,'accelero')
    if exist(fullfile(foldername,'SleepScoring_Accelero.mat'), 'file')==2
        load(fullfile(foldername,'SleepScoring_Accelero.mat'), 'REMEpoch', 'SWSEpoch', 'Wake','TotalNoiseEpoch')

    elseif exist(fullfile(foldername,'StateEpoch.mat'), 'file')==2
        load(fullfile(foldername,'StateEpoch.mat'), 'REMEpoch', 'SWSEpoch', 'Wake','TotalNoiseEpoch')
        
    else
        disp('No Sleep scoring file found')
    end
        
end

%result
try
    REM = REMEpoch;
catch
    REM = intervalSet([],[]);
    disp('no REM found')
end

try
    NREM = SWSEpoch;
catch
    NREM = intervalSet([],[]);
    disp('no NREM found')
end




end

