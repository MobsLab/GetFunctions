function TTLInfo = GetTTLTimesInd_Intan(Dir, ExpeInfo)

% Get TTLchannel
[DigIN, TimeIN] = GetIndividualDigitalChannel_Intan(Dir);

% Parse binary files to separtate digital inputs 
ChannelNumber = length(ExpeInfo.DigID);
DigOUT=[];

for k=0:16
    a(k+1)=2^k-0.1;
end

% Look at all the range to account for hardware errors
for k=16:-1:1
    DigOUT(k,:)=double(DigIN>a(k));
    DigIN(DigIN>a(k)) = DigIN(DigIN>a(k))-a(k)+0.1;
    DigTSD_all{k}=tsd(TimeIN*1e4,DigOUT(k,:)');
end

% Save only those that are defined
for j=ChannelNumber:-1:1
    DigTSD{j} = DigTSD_all{j};
end

% get start stop stim camerasnyc
for dig = 1:length(ExpeInfo.DigID)
    
    UpEpoch = thresholdIntervals(DigTSD{dig},0.9,'Direction','Above');
    
    % Some special cases
    if strcmp(ExpeInfo.DigID{dig},'ONOFF')
        StartSession = Start(UpEpoch);
        StopSession = Stop(UpEpoch);
        
        TTLInfo.StartSession = StartSession;
        TTLInfo.StopSession = StopSession;
        
    elseif strcmp(ExpeInfo.DigID{dig},'STIM')
        TTLInfo.StimEpoch = UpEpoch;
        StimEpoch = UpEpoch;
        
    elseif strcmp(ExpeInfo.DigID{dig}, 'CAMERASYNC')
        TTLInfo.SyncEpoch = UpEpoch;
        
    else
        StartSession = Start(UpEpoch);
        % + and - are not authorized symbols, correct for thi
        DigName = (ExpeInfo.DigID{dig});
        DigName = strrep(DigName,'+','pl');
        DigName = strrep(DigName,'-','mn');

        TTLInfo.DigName = StartSession;
    end
end

end


function [DigIN, TimeIN] = GetIndividualDigitalChannel_Intan(Dir)

% Get .xml for *digitalin.dat*
copyfile([dropbox '/Kteam/PrgMatlab/PreProcessing/NomenclatureCodes/digitalin.xml'], Dir);
% Load it
SetCurrentSession([Dir '/digitalin.xml']);

% % Load the file
% if FileDuration > 3600*1e4
%     DigIN=[];TimeIN=[];
%     
%     for tt=1:ceil(FileDuration/1000)
%         disp(num2str(tt/ceil(FileDuration/1000)))
%         % we load 1001 seconds of data
%         temp=GetWideBandData('all','intervals',[1000*(tt-1) min(1001*tt,Tmax)]);
%         % just keep 1000 seconds of data - there are sometimes problems
%         % at the end
%         LastToKeep =  find(LFP_temp(:,1)>min(1000*tt,Tmax),1,'first')-1;
%         LFP_temp(LastToKeep:end,:)=[];
%         DigIN=[DigIN;LFP_temp(:,2)];
%         TimeIN=[TimeIN;LFP_temp(:,1)];
%         
%     end
%     
% else
    temp=GetWideBandData(0);
    TimeIN = temp(:,1);
    DigIN = temp(:,2);
% end

end