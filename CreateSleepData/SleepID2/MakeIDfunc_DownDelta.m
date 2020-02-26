% MakeIDfunc_DownDelta
% 05.01.2018 KJ
%
%%INPUT
%
%
%%OUTPUT
%
%
% SEE
%   MakeIDSleepData2 MakeIDfunc_Deltas
%
%


function [down, delta] = MakeIDfunc_DownDelta(varargin)


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


%% load data
deltas_PFCx = GetDeltaWaves('area','PFCx');

if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
    down_PFCx = GetDownStates('area','PFCx');
end

%% Numbers

%total amount
delta.all = length(Start(deltas_PFCx));

if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
    down.all = length(Start(down_PFCx));
    
    
    % intersection delta waves and down states
    intvDur = 1E3;
    larger_delta_epochs = [Start(deltas_PFCx)-intvDur, End(deltas_PFCx)+intvDur];
    down_tmp = (Start(down_PFCx)+End(down_PFCx)) / 2;
    
    if ~isempty(down_tmp)
        [status, ~, ~] = InIntervals(down_tmp,larger_delta_epochs);
    else
        status = [];
    end
    
    %result
    down.delta = sum(status);
    delta.down = sum(status);
    
    down.only = down.all - down.delta;
    delta.only = delta.all - delta.down;
    
else
    down.all = NaN;
    down.only = NaN;
    down.delta = NaN;
    delta.down = NaN;
    delta.only = NaN;    
end


end












