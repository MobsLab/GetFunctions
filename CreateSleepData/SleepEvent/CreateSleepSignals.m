function [lfp_structures, cortical_structures] = CreateSleepSignals(varargin)

% =========================================================================
%                          CreateSleepSignals
% =========================================================================
% DESCRIPTION:  MAIN of MOBs' CreateSleepSignal pipeline
%               Detect and save sleep events:
%               - Down states       (CreateDownStatesSleep.m)
%               - Delta waves       (CreateDeltaWavesSleep.m)
%               - Ripples           (CreateRipplesSleep.m)
%               - Spindles          (CreateSpindlesSleep.m)
%
% =========================================================================
% INPUTS: 
%    __________________________________________________________________
%       Properties          Description                     Default
%    __________________________________________________________________
%
%       <varargin>
%       foldername          Path to folder with SpikeData.mat
%                           (if diff than pwd)
%       scoring             type of sleep scoring 
%                           (accelero or obgamma)
%                                                       default 'ob'
%       recompute           recompute detection (0 or 1)
%                                                       default: 1
%       stim                stimulations artefact? (0 or 1)
%                                                       default: 0
%       down                process down states detection (0 or 1)
%                                                       default: 1
%       delta               process delta waves detection (0 or 1)
%                                                       default: 1
%       rip                 process ripples detection (0 or 1)
%                                                       default: 1
%       spindle             process spindles detection (0 or 1)
%                                                       default: 1
%       ripthresh           set specific threshold for ripples
%                           [absolute detection; rootsquare det.]
%                                                       default: [4 6; 2 5] 
%       delthresh           set specific threshold for deltas
%                                                       default: [2 1] 
%       spithresh           set specific threshold for spindles
%                           [absolute detection; rootsquare det.]
%                                                       default: [2 3; 3 5] 
%
% =========================================================================
% OUTPUT:
%    __________________________________________________________________
%       Properties          Description                   
%    __________________________________________________________________
%
%       RipplesEpoch        Ripples start and en timestamps (intervalSet)             
%
% =========================================================================
% VERSIONS
%   10.11.2017 KJ
%   2021-01 - Updated by SL: 
%                   - added conditions for each event type
%                   - added varargin (stim, ripthresh)
%                   - find old script in /archived/ with suffixe '-old'
%   2021-02 - Added delta threshold argument to delta function. (SL)
%
% =========================================================================
% SEE CreateSpindlesSleep CreateDownStatesSleep CreateDeltaWavesSleep
% =========================================================================

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isastring(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        case 'stim'
            stim = varargin{i+1};
            if stim~=0 && stim ~=1
                error('Incorrect value for property ''stim''.');
            end
        case 'down'
            down = varargin{i+1};
            if down~=0 && down ~=1
                error('Incorrect value for property ''down''.');
            end
        case 'delta'
            delta = varargin{i+1};
            if delta~=0 && delta ~=1
                error('Incorrect value for property ''delta''.');
            end
        case 'rip'
            rip = varargin{i+1};
            if rip~=0 && rip ~=1
                error('Incorrect value for property ''rip''.');
            end
        case 'spindle'
            spindle = varargin{i+1};
            if spindle~=0 && spindle ~=1
                error('Incorrect value for property ''spindle''.');
            end
        case 'ripthresh'
            ripthresh = varargin{i+1};
            if ~isnumeric(ripthresh)
                error('Incorrect value for property ''ripthresh''.');
            end
        case 'delthresh'
            delthresh = varargin{i+1};
            if ~isnumeric(delthresh)
                error('Incorrect value for property ''delthresh''.');
            end
        case 'spithresh'
            spithresh = varargin{i+1};
            if ~isnumeric(spithresh)
                error('Incorrect value for property ''spithresh''.');
            end
        case 'restrict'
            restrict = varargin{i+1};
            if restrict~=0 && restrict ~=1
                error('Incorrect value for property ''restrict''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end


%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end
if ~exist('scoring','var')
    scoring='ob';
end
if ~exist('recompute','var')
    recompute=1;
end
if ~exist('stim','var')
    stim=0;
end
if ~exist('down','var')
    down=1;
end
if ~exist('delta','var')
    delta=1;
end
if ~exist('rip','var')
    rip=1;
end
if ~exist('spindle','var')
    spindle=1;
end
if ~exist('ripthresh','var')
    ripthresh=[4 6; 2 5]; % 1st: thresh for absolute detection; 2nd: thresh for rootsquare det. 
end
if ~exist('delthresh','var')
    delthresh=[2 1];
end
if ~exist('spithresh','var')
    spithresh=[2 3; 3 5]; % 1st: thresh for absolute detection; 2nd: thresh for rootsquare det. 
end
if ~exist('restrict','var')
    restrict=0;
end


%change directory
init_directory=pwd;
cd(foldername);


%% Find structures
if strcmpi(scoring,'accelero')
    try
        load SleepScoring_Accelero Epoch TotalNoiseEpoch
    catch
        try
            load StateEpoch Epoch TotalNoiseEpoch
        catch
            warning('Please, run sleep scoring before extracting deltas!');
            return
        end
    end
elseif strcmpi(scoring,'ob')
    try
        load SleepScoring_OBGamma Epoch TotalNoiseEpoch
    catch
        try
            load StateEpochSB Epoch TotalNoiseEpoch
        catch
            warning('Please, run sleep scoring before extracting deltas!');
            return
        end
    end
    
end

load('LFPData/InfoLFP.mat');

%LFP structures
lfp_structures = unique(InfoLFP.structure);
lfp_structures(strcmpi(lfp_structures,'accelero'))=[];
lfp_structures(strcmpi(lfp_structures,'ekg'))=[];
lfp_structures(strcmpi(lfp_structures,'nan'))=[];
lfp_structures(strcmpi(lfp_structures,'ref'))=[];
lfp_structures(strcmpi(lfp_structures,'noise'))=[];

%cortical structures
list_cortex = {'PFCx', 'PaCx', 'AuCx', 'MoCx', 'PiCx','S1Cx'};
cortical_structures = cell(0);
for i=1:length(lfp_structures)
    if any(strcmpi(lfp_structures{i}, list_cortex))
        cortical_structures{end+1} = lfp_structures{i};
    end
end
% temporary fix // cortical need to be fixed to account for specific
% structure per lfp/probe site
structure = 'PFCx';

% down states
if down
    down_structures = cell(0);
    if exist(fullfile(foldername,'SpikeData.mat'), 'file')==2
        %structures with spikes
%         for i=1:length(cortical_structures)
            [NumNeurons, ~, ~] = GetSpikesFromStructure(cortical_structures{i}, 'remove_MUA',1,'verbose',0);
            if ~isempty(NumNeurons)
                down_structures{end+1} = cortical_structures{i};
            end
%         end
        %% Down states
        for i=1:length(down_structures)

%             structure = down_structures{i};
            
            disp('----------------------------')
            disp('   Detecting down states')
            disp('----------------------------')
            disp('...')
            CreateDownStatesSleep('structure',structure, 'scoring',scoring, 'recompute',recompute);

            %right and left
            if exist(['ChannelsToAnalyse/' structure '_deep_left.mat'],'file')==2
                CreateDownStatesSleep('structure',structure, 'hemisphere','left', 'scoring',scoring, 'recompute',0);
            end
            if exist(['ChannelsToAnalyse/' structure '_deep_right.mat'],'file')==2
                CreateDownStatesSleep('structure',structure, 'hemisphere','right', 'scoring',scoring, 'recompute',0);
            end
        end
        disp('Down states detection done')

    end
end


%% Delta waves
if delta
%     for i=1:length(cortical_structures)

%         structure = cortical_structures{i};
        
        disp('----------------------------')
        disp('   Detecting delta waves')
        disp('----------------------------')
        disp('...')
        
        if or(exist(['ChannelsToAnalyse/' structure '_deep.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_delatdeep.mat'],'file')==2) ...
                & or(exist(['ChannelsToAnalyse/' structure '_sup.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'scoring',scoring, ...
                'recompute',recompute,'thresh',delthresh);
        end

        %right and left
        if or(exist(['ChannelsToAnalyse/' structure '_deep_left.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltadeep_left.mat'],'file')==2)...
                & or(exist(['ChannelsToAnalyse/' structure '_sup_left.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup_left.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'hemisphere','left', ...
                'scoring',scoring, 'recompute',recompute,'thresh',delthresh);
        end
        if or(exist(['ChannelsToAnalyse/' structure '_deep_right.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltadeep_right.mat'],'file')==2) ...
                & or(exist(['ChannelsToAnalyse/' structure '_sup_right.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup_right.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'hemisphere','right', ...
                'scoring',scoring, 'recompute',recompute,'thresh',delthresh);
        end
%     end
    disp('Delta waves detection done')
end


%% Ripples
if rip
        
    disp('----------------------------')
    disp('     Detecting ripples')
    disp('----------------------------')
    disp('...')
    
    if exist('ChannelsToAnalyse/dHPC_rip.mat','file')==2 || exist('ChannelsToAnalyse/dHPC_deep.mat','file')==2
        CreateRipplesSleep('scoring',scoring, 'recompute',recompute, ...
            'thresh',ripthresh,'stim',stim,'restrict',restrict);
    else
        disp('no HPC channel');
    end

    if exist('ChannelsToAnalyse/dHPC_rip_left.mat','file')==2
        load('ChannelsToAnalyse/dHPC_rip_left.mat','channel')
        if ~isempty(channel)
            CreateRipplesSleep('scoring',scoring, 'recompute',recompute, ...
            'thresh',ripthresh,'restrict',restrict);
        end
    end
    if exist('ChannelsToAnalyse/dHPC_rip_right.mat','file')==2
         load('ChannelsToAnalyse/dHPC_rip_right.mat','channel')
        if ~isempty(channel)
            CreateRipplesSleep('scoring',scoring, 'recompute',recompute, ...
            'thresh',ripthresh,'restrict',restrict);
        end
    end
    disp('Ripples detection done')
end


%% Spindles
%
if spindle
        
    disp('----------------------------')
    disp('    Detecting spindles')
    disp('----------------------------')
    disp('...')
    
    if exist(['ChannelsToAnalyse/' structure '_spindle.mat'],'file')==2
%     for i=1:length(cortical_structures)
%         structure = cortical_structures{i};
        CreateSpindlesSleep('structure',structure, 'scoring',scoring, ...
            'recompute',recompute,'stim',stim,'thresh',spithresh);
%     end
        disp('Spindles detection done')
    else
        disp('No spindle channel. Skipped.')
    end
    
end


%% go back
cd(init_directory);


end



