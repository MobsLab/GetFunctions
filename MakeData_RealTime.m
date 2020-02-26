% MakeData_RealTime
% 23.10.2017 (KJ & SB)
%
% Processing:
%   - this creates a variable NewtsdZT which gives you the real clock time of the recording (inspired by GetZT_ML)
%   - LFPData and TimeRec must exist for this to work
%
%   see makeData, makeDataBulbe


function MakeData_RealTime(foldername)


%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end
% to make the NewtsdZT tsd
NewtsdZT_Data= [];
NewtsdZT_Times = [];

%% load the necessary information
load([foldername 'behavResources'],'tpsCatEvt','nameCatEvt')
load([foldername 'TimeRec.mat'],'TimeEndRec','TimeBeginRec','TimeEndRec_Allfiles','TimeBeginRec_Allfiles')
load('LFPData/InfoLFP.mat')
load(['LFPData/LFP' num2str(InfoLFP.channel(1))])


for file = 1:size(TimeBeginRec_Allfiles,1)
    
    % Get exact beginning and end of the first file
    LittleEpoch = intervalSet(tpsCatEvt{1+(file-1)*2}*1e4,tpsCatEvt{2+(file-1)*2}*1e4);
    
    % Get the LFP times and set them to zero (the beginning of this file)
    LFPBlock  = Range(Restrict(LFP,LittleEpoch));
    LFPBlock_zero = LFPBlock - LFPBlock(1);
    
    % Convert the time to seconds since midnight
    BeginTime = TimeBeginRec_Allfiles(file,:)*[3600 60 1]';
    
    NewtsdZT_Data = [NewtsdZT_Data;LFPBlock_zero+BeginTime*1e4];
    NewtsdZT_Times = [NewtsdZT_Times;LFPBlock];
    
end

NewtsdZT = tsd(NewtsdZT_Times,NewtsdZT_Data);

%% save
try
    save([foldername 'behavResources'],'NewtsdZT','-append')
catch
    disp('Creating behavResources.mat')
    save([foldername 'behavResources'],'NewtsdZT')
end
disp('Done')


end




