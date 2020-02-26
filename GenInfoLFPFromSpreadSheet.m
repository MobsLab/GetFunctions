%GenInfoLFPFromSpreadSheet
% 02.11.2017 SB
% - get channel info from a xls file
%
%


%list of structures
structure_list = {'nan', 'ref', 'bulb', 'hpc', 'dhpc', 'pfcx', 'pacx', 'picx', 'mocx', 'aucx', 's1cx', 'th', 'nrt', 'auth', 'mgn', 'il', 'tt', ...
    'amyg', 'vlpo','ekg','emg', 'digin', 'accelero', 'laser', 'respi','sound'};
hemisphere_list = {'r','l','nan'};
depth_list = [-1 0 1 2 3];
%-1=EEG 0=EcoG 1=LFPsup 2=LFPmid 3=LFPdeep, NaN=undefined;


%check if InfoLFP.mat already exists
try
    load LFPData/InfoLFP InfoLFP
    m = input('Info LFP already exists - Do you want to rewrite it ? Y/N [Y]:','s');
    
catch
    disp('creating InfoLFP...');
    m = 'y';
end


%if yes : create InfoLFP from xls file
if ~strcmpi(m,'n')
    
    %load file
    [filename, pathname, filterindex] = uigetfile('.xlsx','please give spreadsheet with channels');

    %read spreadsheet
    try
        [num,str] = xlsread([pathname filename]);
    catch
        error('xls file cannot be read');
    end
    
    
    %% get info to InfoLFP
    InfoLFP.channel = num(:,1);
    InfoLFP.depth = num(:,3);
    for k=1:length(InfoLFP.channel)
        InfoLFP.structure{k} = str{k,1};
        InfoLFP.hemisphere{k} = str{k,3};
    end
    clear num str

    
    %% check data in InfoLFP
    %depth
    if ~all(ismember(InfoLFP.depth, depth_list) | isnan(InfoLFP.depth))
        disp(InfoLFP.depth)
        error('one depth value is not correct')
    end
    %structure
    if ~all(ismember(lower(InfoLFP.structure), structure_list))
        disp(InfoLFP.structure)
        error('one structure input is not correct')
    end
    %hemisphere
    if ~all(ismember(lower(InfoLFP.hemisphere), hemisphere_list))
        disp(InfoLFP.hemisphere)
        error('one structure input is not correct')
    end
    
    %% save data in LFPData
    mkdir('LFPData')
    save('LFPData/InfoLFP.mat','InfoLFP')
end





