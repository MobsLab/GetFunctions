% MakeIDSleepData2
% 05.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%  MakeIDSleepData PlotIDSleepData2
%


function MakeIDSleepData2(varargin)


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
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isstring_FMAToolbox(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
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
%type of sleep scoring
if ~exist('scoring','var')
    scoring='ob';
end

%recompute ?
if recompute
    save('IdFigureData2','foldername') 
elseif exist('IdFigureData2.mat','file')~=2
    save('IdFigureData2','foldername')
end


%% Down and Delta
disp('Down and delta analysis')
load('IdFigureData2','nb_down');
if recompute || ~exist('nb_down','var')
    [nb_down, nb_delta] = MakeIDfunc_DownDelta();
    save IdFigureData2 -append nb_down nb_delta

else
    disp('already done')
end


%% Event density and ISI
disp('Sleep Events analysis')
load('IdFigureData2','deltas_stat');
if recompute || ~exist('deltas_stat','var')
    [deltas_stat, down_stat, ripples_stat, spindles_stat, night_duration] = MakeIDfunc_SleepEvent;
    save IdFigureData2 -append deltas_stat down_stat ripples_stat spindles_stat night_duration

else
    disp('already done')
end


%% LFP info
disp('LFP informations')
load('IdFigureData2','nb_channel');
if recompute || ~exist('nb_channel','var')
    [nb_channel, lfp_structures, hemispheres] = MakeIDfunc_LfpInfo;
    save IdFigureData2 -append nb_channel lfp_structures hemispheres

else
    disp('already done')
end


%% Tetrode info
if exist([cd filesep 'SpikeData.mat'])>0 % added by SB for use with mice with no spikes
disp('Tetrode informations')
load('IdFigureData2','info_tetrode');
if recompute || ~exist('info_tetrode','var')
    [nb_neurons, info_tetrode] = MakeIDfunc_Tetrode;
    save IdFigureData2 -append nb_neurons info_tetrode

else
    disp('already done')
end
else
    nb_neurons.all = 0;
    info_tetrode = [];
    save IdFigureData2 -append nb_neurons info_tetrode
end


%% Mean curves on down states
if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes
    
    disp('Mean Curves on down states')
    load('IdFigureData2','down_curves');
    if recompute || ~exist('down_curves','var')
        [down_curves, channel_curves, structures_curves, peak_value] = MakeIDfunc_LfpOnDown;
        save IdFigureData2 -append down_curves channel_curves structures_curves peak_value
        
    else
        disp('already done')
    end
else
    down_curves = NaN;
    channel_curves = NaN;
    structures_curves = NaN;
    peak_value = NaN;
    save IdFigureData2 -append down_curves channel_curves structures_curves peak_value
end

%% Mean curves on ripples
disp('Mean Curves on ripples')
load('IdFigureData2','ripples_curves');
if recompute || ~exist('ripples_curves','var')
    [ripples_curves, hpc_channels, hpc_hemispheres] = MakeIDfunc_HpcRipples;
    save IdFigureData2 -append ripples_curves hpc_channels hpc_hemispheres

else
    disp('already done')
end




end







