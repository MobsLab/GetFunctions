function TTLInfo = MakeData_TTLInfo_OpenEphys(File, sync_folder, ExpeInfo)

% This function creates timestamps of ONOFF and Stim TTL events from OpenEphys
% 
% INPUT
% 
%   File            .mat file with TTL info converted from .npy (usually in
%                   .../recordingN/events/Rhythm_FPGA-100.0_TTL_1.mat
%
%   sync_folder    folder with structure.oebin
%        
%   ExpeInfo        structure that contains information about identities of
%                   all TTL channels
% 
% OUTPUT 
% 
%   TTLINFO         structure with TTL timestamps of stimulation and
%                   start/stop
% 
% By Dima Bryzgalov, MOBS team, Paris, France
% 10/07/2020
% github.com/bryzgalovdm
% github.com/MobsLab

%% Learn sampling rate and start time

% Sampling rate
oebin = fileread([sync_folder '/structure.oebin']);
[~, sr_id] = regexp(oebin,'"sample_rate": ');
samplingrate = str2double(oebin(sr_id(1)+1:sr_id(1)+5));

% Start time
% AG has had issue with loading large files, so below is for him (2025/01/12)
special_sync_folders = { ...
    '/media/nas8/OB_ferret_AG_BM/Shropshire/freely-moving/20250107_LSP_saline/recording1/', ...
    '/media/nas8/OB_ferret_AG_BM/Shropshire/freely-moving/20241228_LSP_saline/recording1/', ...
    '/media/nas8/OB_ferret_AG_BM/Shropshire/freely-moving/20241224_LSP_saline/recording1/', ...
    '/media/nas8/OB_ferret_AG_BM/Shropshire/freely-moving/20241217_LSP_saline/recording1/', ...
    '/media/nas8/OB_ferret_AG_BM/Shropshire/freely-moving/20241126_LSP/recording1/'};

% Check if the sync_folder is in the special list
if ismember(sync_folder, special_sync_folders)
    sync = h5read([sync_folder '/continuous/continuous_Rhythm_FPGA-100.0.mat'], '/timestamps');
    starttime = sync(1);
else
    sync = load([sync_folder '/continuous/continuous_Rhythm_FPGA-100.0.mat']);
    starttime = sync.timestamps(1);
end


%% load file
% Check if the sync_folder is in the special list
if ismember(sync_folder, special_sync_folders)
   channel_states = h5read(File, '/channel_states');
   channels = h5read(File, '/channels');
   full_words = h5read(File, '/full_words');
   timestamps = h5read(File, '/timestamps');
else
    load(File);
end

%% Loop over all possible dig inputs
for dig = 1:length(ExpeInfo.DigID)
    % ONOFF
    if strcmp(ExpeInfo.DigID{dig},'ONOFF')
        id_on = find(channel_states == dig);
        id_off = find(channel_states == -dig);
        
        if length(id_on) == 1
            TTLInfo.StartSession = double((timestamps(id_on) - starttime))/samplingrate*1e4;
        else
            TTLInfo.StartSession = 0;
            warning('You syncroniztion will not be precise!!! You had to start recording before start of tracking!!!')
        end
        TTLInfo.StopSession = double((timestamps(id_off) - starttime))/samplingrate*1e4;
        
    elseif strcmp(ExpeInfo.DigID{dig},'STIM')
        id_stimon = find(channel_states == dig);
        
        TTLInfo.StimEpoch = intervalSet(double((timestamps(id_stimon) - starttime))/samplingrate*1e4, ...
            double((timestamps(id_stimon)) - starttime)/samplingrate*1e4);
        
    end
end

end

