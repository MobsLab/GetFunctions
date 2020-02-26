% MakeData_RecordingTime
% 23.10.2017 (KJ & SB)
%
% Processing: 
%   - generate a tsd variable, MovAcctsd, and put it into behavResources
%
%
%   see makeData, makeDataBulbe


function MovAcctsd = MakeData_RecordingTime(foldername)

disp('Get time for recording')


%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end

% get tpsdeb tpsfin
load('LFPData/InfoLFP.mat')
load(['LFPData/LFP',num2str(InfoLFP.channel(1)),'.mat'])

tpsdeb{1}=0;
tpsfin{1}=max(Range(LFP,'s'));
tpsEvt={tpsdeb{1} tpsfin{1}};

if exist('behavResources.mat')>0
    save behavResources tpsEvt tpsdeb tpsfin -append
else
        save behavResources tpsEvt tpsdeb tpsfin
end
    


try
    load('behavResources.mat','TimeEndRec')
    TimeEndRec; disp('Done')
catch
    disp(' '); disp('GetTimeOfDataRecordingML.m')
    try
        TimeEndRec = GetTimeOfDataRecordingML;
        disp('Done');
    catch
        disp('Problem... SKIP');
    end
end

% get ZT time
GetZT_ML

end