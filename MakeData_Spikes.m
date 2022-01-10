% MakeData_Spikes
% 23.10.2017 (KJ & SB)
%
% Processing: 
%   - generate spike trains and mean neuron waveform
%   - save in SpikeData and MeanWaveform
%
%
%   see makeData, makeDataBulbe


function [S, TT, cellnames, tetrodeChannels] = MakeData_Spikes(varargin)


disp('SpikeData')

%% Initiation
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        case 'mua'
            mua = varargin{i+1};
            if mua~=0 && mua ~=1
                error('Incorrect value for property ''mua''.');
            end
        case 'xmlname'
            xmlname = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('recompute','var')
    recompute=0;
end
if ~exist('mua','var')
    mua=0;
end

% Get variable data, made available when current session has been chosen
global DATA
if exist('xmlname','var')
    clearvars -global DATA
    SetCurrentSession(xmlname)
elseif isempty(DATA)
    SetCurrentSession
end
global DATA
xmlname = DATA.session.basename;
clear AllSpikeData

%load
tetrodeChannels =  DATA.spikeGroups.groups;
AllSpikeData = GetSpikes('output','full');

%check if already exist
if ~recompute
    if exist('SpikeData.mat','file')==2 && exist('MeanWaveform.mat','file')==2
        disp('Already computed! ')
        return
    end
end

% Get the user's mark
tempInfo = xmltree([DATA.session.path,filesep,DATA.session.name,'.xml']);
UnitInfotemp = convert(tempInfo);
UnitInfo={};

% Changed by Dima 22/11/2019 to deal with potential absense of the user's mark
if isfield(UnitInfotemp.units,'unit')
    for ee=1:size(UnitInfotemp.units.unit,2)
        if size(UnitInfotemp.units.unit,2)==1
            UnitInfo{eval(UnitInfotemp.units.unit.group),eval(UnitInfotemp.units.unit.cluster)}=UnitInfotemp.units.unit.quality;
        else
            UnitInfo{eval(UnitInfotemp.units.unit{ee}.group),eval(UnitInfotemp.units.unit{ee}.cluster)}=UnitInfotemp.units.unit{ee}.quality;
        end
    end
end


%% Format data
count_all_units=1;
% Loop on all tetrodes
for tet_num=1:max(AllSpikeData(:,2))
    if exist([DATA.session.name,'.clu.',num2str(tet_num)])==2
        % Get all units on this tetrode
        UnitNums = unique(AllSpikeData(AllSpikeData(:,2)==tet_num,3));
        
        % MUA ?
        if mua
            UnitNums(UnitNums<1) = [];
        else
            UnitNums(UnitNums<2) = [];
        end
        
        features = LoadSpikeFeatures([DATA.session.name,'.clu.',num2str(tet_num)],20000);
        if length(UnitNums)>0
            LRatio=[];distance=[];
            % Changed by Dima 29/03/2019
            [distance,LRatio] = IsolationDistance(features);
        end
        
        
        %loop
        for unit_num=1:length(UnitNums)
            SpikeID = find(AllSpikeData(:,2)==tet_num & AllSpikeData(:,3)==UnitNums(unit_num));
            if length(SpikeID)>1 % at least one spike n the session
                
                % tsd of spike times
                S{count_all_units} = tsd(AllSpikeData(SpikeID,1)*1E4, AllSpikeData(SpikeID,1)*1E4);
                % tetrode number and unit name
                TT{count_all_units} = [tet_num, UnitNums(unit_num)];
                cellnames{count_all_units} = ['TT',num2str(tet_num),'c',num2str(UnitNums(unit_num))];
                % average waveform on each electrode
                tempW{count_all_units}  =  GetSpikeWaveforms([tet_num UnitNums(unit_num)]);
                for elec=1:size(tempW{count_all_units},2)
                    W{count_all_units}(elec,:) = mean(squeeze(tempW{count_all_units}(:,elec,:)));
                end
%                 quality of sorting
%                 Changed by Dima 29.03.2019 to put NANs in MUA quality
                if length(UnitNums)~=length(LRatio)
                    if UnitNums(unit_num) == 1
                        % First is MUA
                        if ~isempty(UnitInfo)
                            Quality.MyMark{count_all_units}= NaN;
                        end
                        Quality.LRatio(count_all_units)= NaN;
                        Quality.IsoDistance(count_all_units)= NaN;
                    else
                        % Then normal units
                        if ~isempty(UnitInfo)
                        Quality.MyMark{count_all_units}= UnitInfo{tet_num,UnitNums(unit_num)};
                        end
                        Quality.LRatio(count_all_units)=LRatio(unit_num-1); %
                        Quality.IsoDistance(count_all_units)=distance(unit_num-1);
                    end
                else
                    if ~isempty(UnitInfo)
                        Quality.MyMark{count_all_units}= UnitInfo{tet_num,UnitNums(unit_num)};
                    end
                    Quality.LRatio(count_all_units)=LRatio(unit_num);
                    Quality.IsoDistance(count_all_units)=distance(unit_num);
                end
                disp(['Cluster : ',cellnames{count_all_units},' > done'])
                
                % increment unit count
                count_all_units = count_all_units+1;
            end
        end
        
        disp(['Tetrodes #',num2str(tet_num),' > done'])
        
    end
end

S = tsdArray(S);



%% save
save SpikeData -v7.3 S TT cellnames tetrodeChannels Quality
save MeanWaveform W

%% This was changed so that all waveforms are systematically saved (allwaveforms is no longer an option)
mkdir('Waveforms')
clear W
for sp = 1 :length(cellnames)
    W = tempW{sp};
    save(['Waveforms/Waveforms' cellnames{sp} '.mat'],'W','-v7.3')
end

%% Update the xml file with the spike names
if exist([xmlname,'._SpikeRef.xml']) == 2
    XmlStructure_Spikes = xml2struct_SB([xmlname,'.xml']);
    UnitInfo = XmlStructure_Spikes.parameters.units.unit;
    
    xmlnameGeneral = xmlname(1:findstr(xmlname,'_SpikeRef')-1);
    XmlStructure_General = xml2struct_SB([xmlnameGeneral,'.xml']);
    XmlStructure_General.parameters.units.unit = d;
    XmlStructure_General.parameters.units = rmfield(XmlStructure_General.parameters.units,'Text');
    
    struct2xml_SB(XmlStructure_General,[xmlnameGeneral,'.xml']);
end

end

