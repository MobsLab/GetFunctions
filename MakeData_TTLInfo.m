
for dig = 1:length(ExpeInfo.DigID)
    
    load(['LFPData/DigInfo',num2str(dig),'.mat'])
    UpEpoch = thresholdIntervals(DigTSD,0.9,'Direction','Above');
    
    % Some special cases
    if strcmp(ExpeInfo.DigID{dig},'ONOFF')
        StartSession = Start(UpEpoch);
        StopSession = Stop(UpEpoch);
        
        TTLInfo.StartSession = StartSession;
        TTLInfo.StopSession = StopSession;
        
    elseif strcmp(ExpeInfo.DigID{dig},'STIM')
        TTLInfo.StimEpoch = UpEpoch;
        StimEpoch = UpEpoch;
        
    elseif strcmp(ExpeInfo.DigID{dig},'STIM2')
        TTLInfo.StimEpoch2 = UpEpoch;
        StimEpoch2 = UpEpoch;
        
    elseif strcmp(ExpeInfo.DigID{dig},'PIEZO')
        TTLInfo.Sync = UpEpoch;
        
    else
        StartSession = Start(UpEpoch);
        % + and - are not authorized symbols, correct for thi
        DigName = (ExpeInfo.DigID{dig});
        DigName = strrep(DigName,'+','pl');
        DigName = strrep(DigName,'-','mn');

        TTLInfo.DigName = StartSession;
    end
end

save('behavResources.mat','TTLInfo','-append')
if exist('StimEpoch')>0
    save('behavResources.mat','StimEpoch','-append')
end
if exist('StimEpoch2')>0
    save('behavResources.mat','StimEpoch2','-append')
end