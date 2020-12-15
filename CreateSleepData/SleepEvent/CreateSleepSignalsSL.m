% CreateSleepSignals
% 10.11.2017 KJ
%
% Detect and save sleep events:
%   - Down states       (CreateDownStatesSleep.m)
%   - Delta waves       (CreateDeltaWavesSleep.m)
%   - Ripples           (CreateRipplesSleep.m)
%   - Spindles          (CreateSpindlesSleep.m)
%
%
%INPUTS
% scoring (optional):   method used to distinguish sleep from wake 
%                         'accelero' or 'OB'; default is 'accelero'
%
%


function [lfp_structures, cortical_structures] = CreateSleepSignals(varargin)


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
        case 'nonrip'
            nonRip = varargin{i+1};
            if ~isnumeric(nonRip)
                error('Incorrect value for property ''nonRip''.');
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
    recompute=0;
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
    ripthresh=[5 7];
end

%change directory
init_directory=pwd;
cd(foldername);


%% Find structures
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


%down states
if down
    down_structures = cell(0);
    if exist(fullfile(foldername,'SpikeData.mat'), 'file')==2
        %structures with spikes
        for i=1:length(cortical_structures)
            [NumNeurons, ~, ~] = GetSpikesFromStructure(cortical_structures{i}, 'remove_MUA',1,'verbose',0);
            if ~isempty(NumNeurons)
                down_structures{end+1} = cortical_structures{i};
            end
        end

        %% Down states
        for i=1:length(down_structures)

            structure = down_structures{i};

            CreateDownStatesSleep('structure',structure, 'scoring',scoring, 'recompute',recompute);

            %right and left
            if exist(['ChannelsToAnalyse/' structure '_deep_left.mat'],'file')==2
                CreateDownStatesSleep('structure',structure, 'hemisphere','left', 'scoring',scoring, 'recompute',0);
            end
            if exist(['ChannelsToAnalyse/' structure '_deep_right.mat'],'file')==2
                CreateDownStatesSleep('structure',structure, 'hemisphere','right', 'scoring',scoring, 'recompute',0);
            end
        end

    end
end


%% Delta waves
if delta
    for i=1:length(cortical_structures)

        structure = cortical_structures{i};

        if or(exist(['ChannelsToAnalyse/' structure '_deep.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_delatdeep.mat'],'file')==2) ...
                & or(exist(['ChannelsToAnalyse/' structure '_sup.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'scoring',scoring, 'recompute',recompute);
        end

        %right and left
        if or(exist(['ChannelsToAnalyse/' structure '_deep_left.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltadeep_left.mat'],'file')==2)...
                & or(exist(['ChannelsToAnalyse/' structure '_sup_left.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup_left.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'hemisphere','left', 'scoring',scoring, 'recompute',recompute);
        end
        if or(exist(['ChannelsToAnalyse/' structure '_deep_right.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltadeep_right.mat'],'file')==2) ...
                & or(exist(['ChannelsToAnalyse/' structure '_sup_right.mat'],'file')==2,exist(['ChannelsToAnalyse/' structure '_deltasup_right.mat'],'file')==2)
            CreateDeltaWavesSleep('structure',structure, 'hemisphere','right', 'scoring',scoring, 'recompute',recompute);
        end
    end
end


%% Ripples
if rip
%     try
        if exist('ChannelsToAnalyse/dHPC_rip.mat','file')==2 || exist('ChannelsToAnalyse/dHPC_deep.mat','file')==2
            CreateRipplesSleepSL(nonRip, 'scoring',scoring, 'recompute',recompute,'thresh',ripthresh);
        else
            disp('no HPC channel');
        end

        if exist('ChannelsToAnalyse/dHPC_rip_left.mat','file')==2
            load('ChannelsToAnalyse/dHPC_rip_left.mat','channel')
            if ~isempty(channel)
                CreateRipplesSleepSL(nonRip, 'scoring',scoring, 'recompute',recompute,'thresh',ripthresh)
            end
        end
        if exist('ChannelsToAnalyse/dHPC_rip_right.mat','file')==2
             load('ChannelsToAnalyse/dHPC_rip_right.mat','channel')
            if ~isempty(channel)
                CreateRipplesSleepSL(nonRip, 'scoring',scoring, 'recompute',recompute,'thresh',ripthresh)
            end
        end

%     catch
%         disp('Ripples error for this record');
%     end
end


%% Spindles
%
if spindle
    for i=1:length(cortical_structures)
%         try
            structure = cortical_structures{i};
            CreateSpindlesSleepSL('structure',structure, 'scoring',scoring, 'recompute',recompute,'stim',1);
%         catch
%             disp(['Spindles (' structure ') Error for this record']);
%         end
    end
end


%% go back
cd(init_directory);


end



