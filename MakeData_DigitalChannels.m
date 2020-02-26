% MakeData_DigitalChannels
% 23.10.2017 (KJ & SB)
%
% Processing:
%   - generate a tsd variable, MovAcctsd, and put it into behavResources
%
%
%   see makeData, makeDataBulbe


function MakeData_DigitalChannels(foldername)

disp('Get INTAN DigitalInput')
load('ExpeInfo.mat')
chanDig = ExpeInfo.InfoLFP.channel(find(strcmp(ExpeInfo.InfoLFP.structure,'Digin')));
ChannelNumber = length(ExpeInfo.DigID);

% if not(exist('LFPData/DigInfo1.mat'))
    try
        load('LFPData/InfoLFP.mat')
        load(['LFPData/LFP' num2str(InfoLFP.channel(1)) '.mat'])
        Tmax=max(Range(LFP,'s'));
        LongFile=Tmax>3600;
        
        if LongFile==0 % short file --> all in one
            LFP_temp=GetWideBandData(chanDig);
            LFP_temp=LFP_temp(1:16:end,:);
            DigIN=LFP_temp(:,2);
            TimeIN=LFP_temp(:,1);
        else % long file --> load progressively
            disp('progressive loading')
            DigIN=[];TimeIN=[];
            
            for tt=1:ceil(Tmax/1000)
                disp(num2str(tt/ceil(Tmax/1000)))
                % we load 1001 seconds of data
                LFP_temp=GetWideBandData(chanDig,'intervals',[1000*(tt-1) min(1001*tt,Tmax)]);
                % just keep 1000 seconds of data - there are sometimes problems
                % at the end
                LastToKeep =  find(LFP_temp(:,1)>min(1000*tt,Tmax),1,'first')-1;
                LFP_temp(LastToKeep:end,:)=[];
                LFP_temp=LFP_temp(1:16:end,:);
                DigIN=[DigIN;LFP_temp(:,2)];
                TimeIN=[TimeIN;LFP_temp(:,1)];
            end
        end
        
        
        DigOUT=[];
        
        for k=0:16
            a(k+1)=2^k-0.1;
        end
        
        % Look at all the range to account for hardware errors
        for k=16:-1:1
            DigOUT(k,:)=double(DigIN>a(k));
            DigIN(DigIN>a(k))=   DigIN(DigIN>a(k))-a(k)+0.1;
            DigTSD_all{k}=tsd(TimeIN*1e4,DigOUT(k,:)');
        end
        
        % Save only those that are defined
        for j=ChannelNumber:-1:1
           
            DigTSD = DigTSD_all{j};
            save(['LFPData/DigInfo',num2str(j),'.mat'],'DigTSD')
        end

        
        
    catch
        disp('problem for digin')
        
    end
% end

end