function TTLInfo = MakeData_TTLInfo_OpenEphys(File, oebin_folder, ExpeInfo)

% This function creates timestamps of ONOFF and Stim TTL events from OpenEphys
% 
% By Dima Bryzgalov, MOBS team, Paris, France
% 12/06/2020
% github.com/bryzgalovdm
% github.com/MobsLab

%% Learn sampling rate and start time
oebin = fileread([oebin_folder 'structure.oebin']);
[~, sr_id] = regexp(oebin,'"sample_rate": ');
samplingrate = str2double(oebin(sr_id(1)+1:sr_id(1)+5));

sync = fileread([oebin_folder 'sync_messages.txt']);
[~,sync_id_st] = regexp(sync,'start time: ');
sync_id_en = regexp(sync,'@');
sync_id_en = sync_id_en(2)-1;
starttime = str2double(sync(sync_id_st:sync_id_en));

%% load file
load(File);

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
        StimEpoch = TTLInfo.StimEpoch;
        
    end
end

end