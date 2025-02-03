%FindMovementAccelero_SleepScoring
% 22.11.2017 KJ
% 
% [ImmobilityEpoch, MovementEpoch, tsdMovement, Info] = FindMovementAccelero_SleepScoring(varargin)
%
% inputs:
%  user_confirmation (optional) :  0 to skip the user confirmation, 1 otherwise
%
%
% see 
%   FindNREMEpochML 
%


function [ImmobilityEpoch,MovementEpoch,tsdMovement,Info,microWakeEpoch,microSleepEpoch] = ...
    FindMovementAccelero_SleepScoring(Epoch,varargin)

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'user_confirmation'
            user_confirmation = varargin{i+1};
            if user_confirmation~=0 && user_confirmation ~=1
                error('Incorrect value for property ''user_confirmation''.');
            end
        case 'mov_threshold'
            mov_threshold = varargin{i+1};
            if mov_threshold<=0
                error('Incorrect value for property ''mov_threshold''.');
            end
        case 'mov_dropmerge'
            mov_dropmerge = varargin{i+1};
        case 'immob_dropmerge'
            immob_dropmerge = varargin{i+1};
        case 'resampling'
            resampling = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('user_confirmation','var')
    user_confirmation=1;
end
if ~exist('mov_threshold','var')
    mov_threshold = 6e7;
end
if ~exist('mov_dropmerge','var')
    mov_dropmerge = [3 15]; % DropShortIntervals & mergeCloseIntervals
end
if ~exist('immob_dropmerge','var')
    immob_dropmerge = [10 3]; %DropShortIntervals & mergeCloseIntervals
end
if ~exist('resampling','var')
    resampling = 1; %DropShortIntervals & mergeCloseIntervals
end

%% load
try
    load('behavResources.mat', 'MovAcctsd');
    if ~exist('TrackingEpoch','var')
        TrackingEpoch=intervalSet(min(Range(MovAcctsd)),max(Range(MovAcctsd)));
    end
catch
    warning('No accelerometer data - Accelerometer-based sleep scoring will not be generated');
    ImmobilityEpoch = [];
    MovementEpoch = [];
    tsdMovement = [];
    Info = [];
    microWakeEpoch = [];
    microSleepEpoch = [];
    return
end

%% params
pasPos=15; %Down sampling position tsd


%% DownSample Position XY
if ~exist('Mmov','var')
    %% we have an issue with the negative values no ?? BM on 21/10/2024
    if resampling
        tsdMovement =ResampleTSD(MovAcctsd,4);  % modified KB 07/09/2023
    else
        tsdMovement = MovAcctsd;
    end
end
    
%% Define immobility period    
disp('... Creating Immobility and Wake Epochs.');

scoring_ok = 'n'; % is the scoring finished ?
manual_scoring = 0; % is it a threshold put manually

%loop until movement scoring is ok
while scoring_ok~='y'

    %epoch with movement (merge & drop)
    
    MovementEpoch = thresholdIntervals(tsdMovement, mov_threshold, 'Direction','Above');
    MovementEpoch = mergeCloseIntervals(MovementEpoch, mov_dropmerge(2)*1E4); 
    MovementEpoch = dropShortIntervals(MovementEpoch, mov_dropmerge(1)*1E4);

    %epoch of immobility (merge & drop)
    ImmobilityEpoch_all = thresholdIntervals(tsdMovement, mov_threshold, 'Direction','Below');
    ImmobilityEpoch = dropShortIntervals(ImmobilityEpoch_all, immob_dropmerge(1)*1E4); 
    ImmobilityEpoch = mergeCloseIntervals(ImmobilityEpoch, immob_dropmerge(2)*1E4);        
    ImmobilityEpoch = ImmobilityEpoch-and(MovementEpoch, ImmobilityEpoch);
    ImmobilityEpoch = dropShortIntervals(ImmobilityEpoch, immob_dropmerge(1)*1E4);


    %% plot for manual checking
    figure('Name','Movement threshold', 'color',[1 1 1]);
    subplot(1,6,1:4),
    plot(Range(tsdMovement,'s'), Data(tsdMovement)); 
    ylim([0  max(Data(tsdMovement))])
    hold on, plot(Range(Restrict(tsdMovement,MovementEpoch),'s'), Data(Restrict(tsdMovement,MovementEpoch)),'c')
    hold on, plot(Range(Restrict(tsdMovement,ImmobilityEpoch),'s'), Data(Restrict(tsdMovement,ImmobilityEpoch)),'r'); 
    line([0,max(Range(tsdMovement,'s'))],[mov_threshold,mov_threshold], 'color',[0.7 0.7 0.7], 'linewidth',1)
    
    xlim([0,max(Range(tsdMovement,'s'))]);

    try 
        line([Start(TrackingEpoch,'s') Start(TrackingEpoch,'s')], [0 5], 'color','k', 'linewidth',2);
    end
    title('Wake period (blue) and immobility period (Red). Starts Tracking period (black)')
    yl=ylim;
    subplot(1,6,5), hist(Data(tsdMovement),[0:max(yl)/100:max(yl)]), xlim([0 max(yl)/3])
    hold on, line([mov_threshold,mov_threshold],ylim, 'color',[0.7 0.7 0.7], 'linewidth',1)
    [h,b]=hist((Data(tsdMovement)),[0:max(yl)/200:max(yl)]);h(h==0)=min(h>0);
    subplot(1,6,6), plot(b,log(h),'color','k')
    hold on, line([mov_threshold,mov_threshold],ylim, 'color',[0.7 0.7 0.7], 'linewidth',1), xlim([0 max(yl)/3])
    
    %can skip this step if user_confirmation==0
    if user_confirmation
        scoring_ok = input('--- Are you satisfied with the Immobility Epoch (y/n or m for manual) ? ', 's');
        while ~ismember(scoring_ok,['y' 'n' 'm'])
            scoring_ok = input('--- Are you satisfied with the Immobility Epoch (y/n or m for manual) ?', 's');
        end
    else
        scoring_ok='y';
    end

    % if 'no' or 'manual' 
    if scoring_ok=='n'
%         mov_threshold=input(['   threshold for movement (Default= ',sprintf('%1.1E',nanmean(Data(tsdMovement))+2*nanstd(Data(tsdMovement))),') : ']);
        mov_threshold=input(['   threshold for movement (Default or last input = ' num2str(mov_threshold) ') : ']);
    elseif scoring_ok=='m'
        disp('Define Immobility period on figure by hand.');
        ImmobilityEpoch = ginput;
        manual_scoring = 1;
        scoring_ok = input('--- Are you satisfied with the Immobility Epoch you just gave (y/n or m)? ','s');
        while ~ismember(scoring_ok,['y' 'n' 'm'])
            scoring_ok = input('--- Are you satisfied with the Immobility Epoch (y/n or m for manual) ?', 's');
        end

        if length(ImmobilityEpoch)/2~=floor(length(ImmobilityEpoch)/2)
            Disp('Problem: not same number of starts and ends! ')
            scoring_ok='n';
        end

        ImmobilityEpoch = ImmobilityEpoch*1E4;
        ImmobilityEpoch(ImmobilityEpoch(:,1)>max(Range(tsdMovement)),1) = max(Range(tsdMovement));
        ImmobilityEpoch(ImmobilityEpoch(:,1)<0,1) = 0;            
        ImmobilityEpoch = intervalSet(ImmobilityEpoch(1:2:end,1),ImmobilityEpoch(2:2:end,1)); 
    end
end

% defining micro wake (< 2s) during sleep (added by SL: 2021-05)
SleepEpoch_drop = dropShortIntervals(and(ImmobilityEpoch_all,ImmobilityEpoch), 2*1e4);
microWakeEpoch = ImmobilityEpoch - SleepEpoch_drop;
Wake_all = Epoch-ImmobilityEpoch;
Wake_drop = dropShortIntervals(Wake_all, 2*1e4);
microSleepEpoch = Wake_all - Wake_drop;

%Info
Info.immob_dropmerge = immob_dropmerge;
Info.mov_dropmerge = mov_dropmerge; 
Info.mov_threshold = mov_threshold;
Info.manual_scoring = manual_scoring;

    
end


