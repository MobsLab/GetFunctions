%GetBasicInfoRecord
% 02.11.2017 SB
% - get info for record
%
% see GenMakeDataInputs GenInfoLFPFromSpreadSheet GenChannelsToAnalyse
%



%% Initiation
warning off
res=pwd;


%% create makedataBulbeInputs
GenMakeDataInputs


%% create InfoLFP
%read LFP info from xls file and write it into InfoLFP
GenInfoLFPFromSpreadSheet


%% create ChannelsToAnalyse
GenChannelsToAnalyse


