% MakeData_CatEvents
% 23.10.2017 (KJ & SB)
%
% Processing:
%   - gets all the times of the concatenated files and puts them in behav
%   resources
%
%
%   see makeData, makeDataBulbe


function tpsCatEvt = MakeData_CatEvents(foldername)

%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end


if not(isempty( dir('*.cat.evt')))
    evtname_temp = GetEvents('output','Descriptions');
    evttimes_temp = GetEvents;
    
    tpsCatEvt={}; nameCatEvt={};
    for ev = 1:length(evtname_temp)
        if not(isempty(findstr(evtname_temp{ev},'beginning of'))) || not(isempty(findstr(evtname_temp{ev},'end of')))
            tpsCatEvt = [tpsCatEvt, evttimes_temp(ev)]; % in seconds
            nameCatEvt = [nameCatEvt, evtname_temp{ev}];
        end
    end
    
end

%% save
try
    save([foldername 'behavResources'],'tpsCatEvt','nameCatEvt','-append')
catch
    disp('Creating behavResources.mat')
    save([foldername 'behavResources'],'tpsCatEvt','nameCatEvt')
end
disp('Done')


end




