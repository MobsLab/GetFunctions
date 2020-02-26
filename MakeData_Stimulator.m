disp('Get Stimulator Data')

% if not(exist('LFPData/DigInfo1.mat'))
try
    load('LFPData/InfoLFP.mat')
    numStimulator = find(contains(InfoLFP.structure, 'Stimulator'));
    load(['LFPData/LFP' num2str(InfoLFP.channel(1)) '.mat'])
    Tmax=max(Range(LFP,'s'));
    LongFile=Tmax>3600;
    
    if LongFile==0 % short file --> all in one
        LFP_temp=GetWideBandData(numStimulator);
        LFP_temp=LFP_temp(1:16:end,:);
        StimulatorIN=LFP_temp(:,2);
        TimeIN=LFP_temp(:,1);
    else % long file --> load progressively
        disp('progressive loading')
        DigIN=[];TimeIN=[];
         
        for tt=1:ceil(Tmax/1000)
            disp(num2str(tt/ceil(Tmax/1000)))
            % we load 1001 seconds of data 
            LFP_temp=GetWideBandData(numStimulator,'intervals',[1000*(tt-1) min(1001*tt,Tmax)]);
            % just keep 1000 seconds of data - there are sometimes problems
            % at the end
            LastToKeep =  find(LFP_temp(:,1)>min(1000*tt,Tmax),1,'first')-1;
            LFP_temp(LastToKeep:end,:)=[];
            LFP_temp=LFP_temp(1:16:end,:);
            StimulatorIN=[DigIN;LFP_temp(:,2)];
            TimeIN=[TimeIN;LFP_temp(:,1)];
        end
    end
    
   
    StimulatorTSD=tsd(TimeIN*1e4,StimulatorIN');
    save('LFPData/Stimulator.mat','StimulatorTSD');

catch
        disp('problem for digin')
      
end
% end
clear LFP_temp LFP Stimulator StimulatorIN StimulatorTSD TimeIn InfoLFP