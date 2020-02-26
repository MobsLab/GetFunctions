%% Core corde to generate ExpeInfo

ChannelsToAnalyseLocation=uigetdir('','please provide ChannelsToAnalyzeFolder')
if ~(ChannelsToAnalyseLocation(end)==filesep),ChannelsToAnalyseLocation=[ChannelsToAnalyseLocation filesep]; end
[InfoLFPFile,PathName]=uigetfile('','please show the InfoLFP file')
load([PathName InfoLFPFile])

Response = inputdlg({'Mouse Number','Stim Type (PAG,Eyeshock,MFB)',...
    'Ripples','DeltaPF [sup (delta down) deep (delta up)]','SpindlePF','DrugInjected'},'Inputs for ExpeInfo',1);
gui_fig = figure;

ExpeInfo.VirusInjected={};
ExpeInfo.OptoStimulation=0;
ExpeInfo.StimulationInt=0;
ExpeInfo.MouseStrain='C57Bl6';

strfcts=strjoin(nametypes,'|');
u2=uicontrol(gui_fig,'Style', 'popup','String', strfcts,'units','normalized',...
    'Position', [0.01 0.84 0.2 0.05],'Callback', @setprotoc);
u2=uicontrol(gui_fig,'Style', 'edit');


function setprotoc(obj,event)
fctname=get(obj,'value');
ExpeInfo.namePhase=nametypes(fctname);ExpeInfo.namePhase=ExpeInfo.namePhase{1};
savProtoc;
end


% Mouse and date info
ExpeInfo.nmouse=eval(Response{1});
Dates.BigExpe=eval(Response{3});
Dates.Calibration=eval(Response{4});
Dates.BaselineSleep=eval(Response{5});
StimInt=eval(Response{9});
StimDur=eval(Response{10});
ExpeInfo.DrugInjected=eval(Response{11});

% Ephys info
ExpeInfo.StimElecs=Response{2}; % PAG or MFB or Eyeshock
ExpeInfo.Ripples=eval(Response{6}); % give channel
ExpeInfo.DeltaPF=eval(Response{7}); % give sup (delta down) the deep (delta up)
ExpeInfo.SpindlePF=eval(Response{8}); % give channel

% Implantation info
ExpeInfo.RecordElecs=InfoLFP;

cd(ChannelsToAnalyseLocation)
FileInfo=dir('*.mat');
for f=1:size(FileInfo,1)
    load(FileInfo(f).name)
    eval(['ExpeInfo.ChannelsToAnalyse.',FileInfo(f).name(1:end-4),'=channel;'])
end


% Mouse characteristics
ExpeInfo.VirusInjected={};
ExpeInfo.OptoStimulation=0;
ExpeInfo.StimulationInt=0;
ExpeInfo.MouseStrain='C57Bl6';


%% Create folders for the task
if not(isempty(Dates.BigExpe))
    cd(SaveFolderName)
    ExpeInfo.date=Dates.BigExpe;
    mkdir(num2str(ExpeInfo.date))
%     FolderName=OrganizeFilesEmbReactSB(ExpeInfo.nmouse,ExpeInfo.date,[SaveFolderName num2str(ExpeInfo.date) filesep],ChannelsToAnalyseLocation,InfoLFP,ExpeInfo,answer,answerdigin,XMLToCopy,XMLToCopySpike)
    FolderName=OrganizeFilesEmbReactNewProtocolSB_FLXbis(ExpeInfo.nmouse,ExpeInfo.date,[SaveFolderName num2str(ExpeInfo.date) filesep],ChannelsToAnalyseLocation,InfoLFP,ExpeInfo,answer,answerdigin,XMLToCopy,XMLToCopySpike)
    disp('Now fill in your folders with correct files')
end
AllFold=length(FolderName)+1;

%% Create folders for the calibration
if not(isempty(Dates.Calibration))
    cd(SaveFolderName)
    ExpeInfo.date=Dates.Calibration;
    mkdir(num2str(ExpeInfo.date))
    ExpeInfo.SleepSession=0;
    ExpeInfo.SessionType='Calibration';
    for e=1:length(StimInt)
        cd([SaveFolderName num2str(ExpeInfo.date) filesep])
        mkdir([BaseName,num2str(ExpeInfo.nmouse),'_',num2str(ExpeInfo.date),'_Calibration_',strrep(num2str(StimInt(e)),'.',','),'V_',num2str(StimDur(e)),'ms']);
        cd([BaseName,num2str(ExpeInfo.nmouse),'_',num2str(ExpeInfo.date),'_Calibration_',strrep(num2str(StimInt(e)),'.',','),'V_',num2str(StimDur(e)),'ms']);
        ExpeInfo.StimulationInt=StimInt(e);
        ExpeInfo.SessionNumber=e;
        save makedataBulbeInputs answer answerdigin spk doaccelero dodigitalin Questions
        mkdir('raw')
        mkdir('LFPData')
        mkdir('ChannelsToAnalyse')
        save('LFPData/InfoLFP.mat','InfoLFP')
        copyfile(ChannelsToAnalyseLocation,...
            [cd filesep 'ChannelsToAnalyse/']);
        copyfile(XMLToCopy)
        copyfile(XMLToCopySpike)
        save('ExpeInfo.mat','ExpeInfo');
        FolderName{AllFold}=cd;
        AllFold=AllFold+1;
        cd ..
    end
    disp('Now fill in your folders with correct files')
end

%% Create folders for baseline sleep

if not(isempty(Dates.BaselineSleep))
    for k=1:length(Dates.BaselineSleep)
        cd(SaveFolderName)
        ExpeInfo.date=Dates.BaselineSleep(k);
        mkdir(num2str(ExpeInfo.date))
        ExpeInfo.StimulationInt=0;
        ExpeInfo.SessionNumber=0;
        ExpeInfo.SessionType='BaselineSleep';
        ExpeInfo.SleepSession=1;
        cd([SaveFolderName num2str(ExpeInfo.date) filesep])
        mkdir([BaseName,num2str(ExpeInfo.nmouse),'_',num2str(ExpeInfo.date),'_BaselineSleep'])
        cd([BaseName,num2str(ExpeInfo.nmouse),'_',num2str(ExpeInfo.date),'_BaselineSleep'])
        save makedataBulbeInputs answer answerdigin
        mkdir('raw')
        mkdir('LFPData')
        mkdir('ChannelsToAnalyse')
        save('LFPData/InfoLFP.mat','InfoLFP')
        copyfile(ChannelsToAnalyseLocation,...
            [cd filesep 'ChannelsToAnalyse/']);
        copyfile(XMLToCopy)
        copyfile(XMLToCopySpike)
        save('ExpeInfo.mat','ExpeInfo');
        FolderName{AllFold}=cd;
        AllFold=AllFold+1;
        cd ..
    end
    disp('Now fill in your folders with correct files')
end

for f=1:length(FolderName)
FolderName{f}=strrep(FolderName{f},SaveFolderName,'/');
end

