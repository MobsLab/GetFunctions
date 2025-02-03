function gui_sleepscoring_verif()

% =========================================================================
%                          CreateSleepSignals
% =========================================================================
% DESCRIPTION:  GUI for visual inspection of sleep scoring            
%
% =========================================================================
% VERSIONS
%   2021-05 - Original: written by Samuel Laventure for MOBs lab
%
% =========================================================================
% SEE SleepScoring_OBGamma_Accelero
% =========================================================================

%% Initilization 
global windur pos noob
global lsess tpsCatEvt fNames laddsess figH xl
global axs r1 r2 spectchange goSess tax pfcchan

laddsess = []; xl=[];
windur = [];
spectchange = 0;

foldername = pwd;
channel=[]; ch=[];
disp(' ')
disp('---------------------------------------------')
disp('  Preparing data will take several minutes')
disp('              Be patient...')
disp('---------------------------------------------')
disp(' ')

%% Load variables
% get mouse info
load('ExpeInfo.mat','ExpeInfo');
try
    m_id = num2str(ExpeInfo.nmouse);
catch
    m_id = 'Anon';
end

load('behavResources.mat','SessionEpoch','tpsCatEvt');
if exist('SessionEpoch','var')
    fNames = fieldnames(SessionEpoch);
    goSess=1;
else
    fNames = {''};
    goSess=0;
end


% obgamma
disp('Loading Bulb-based sleep scoring...')
try
    load SleepScoring_OBGamma Epoch Wake REMEpoch SWSEpoch SmoothGamma SmoothTheta Info
    InfoOB=Info;
    WakeOB=Wake;
    REMEpochOB=REMEpoch;
    SWSEpochOB=SWSEpoch;
    noob = 0;
catch
    noob = 1;
end

% accelero
disp('Loading Accelero-based sleep scoring...')
try
    load SleepScoring_Accelero Wake Epoch REMEpoch SWSEpoch ThetaRatioTSD tsdMovement SmoothTheta Info
    Infoacc = Info;
    noac = 0;
catch
    Infoacc = InfoOB;
    noac = 1;
end

% get theta channel and create theta data
try
    load ChannelsToAnalyse/PFCx_deltadeep.mat;
    try
        eval(['load SpectrumDataL/Sp',num2str(channel)])
    catch
        disp('Creating spectral data...')
        [Sp,tx,f]=LoadSpectrumML(channel,pwd,'newlow');
    end
    % create PFC power data
    disp('Creating PFC power data...')
    lowPowPFC=mean(Sp(:,find(f>0&f<15)),2);
    lowPowPFCtsd=tsd(tx*1E4,lowPowPFC);
    pfcchan=1;
catch
    lowPowPFC=[]; tx=[];
    warning('No PFC channel available. Please check your ChannelToAnalyze folder.');
    pfcchan = 0;
end


disp('Creating spectral data...')
% Variables that indicate if specta exist
SpecOk.OB = 0;
SpecOk.HPC = 0;

% load OB spectrum
if ~noob
    if exist([foldername,'/B_High_Spectrum.mat'])>0
        load([foldername,'/B_High_Spectrum.mat']);

        % smooth the spectrum for visualization
        datb = Spectro{1};
        for k = 1:size(datb,2)
            datbnew(:,k) = runmean(datb(:,k),100);
        end

        % make tsd
        sptsdB = tsd(Spectro{2}*1e4,datbnew);
        fB = Spectro{3};
        clear Spectro

        % get caxis lims
        CMax.OB = max(max(Data(Restrict(sptsdB,Epoch))))*1.05;
        CMin.OB = min(min(Data(Restrict(sptsdB,Epoch))))*0.95;

        SpecOk.OB = 1;
    end
end

% load HPC spectrum
if exist([foldername,'/H_Low_Spectrum.mat'])>0
    load([foldername,'/H_Low_Spectrum.mat']);
    
    % make tsd
    sptsdH = tsd(Spectro{2}*1e4,Spectro{1});
    fH = Spectro{3};
    clear Spectro
    
    % get caxis lims
    CMax.HPC = max(max(Data(Restrict(sptsdH,Epoch))))*1.05;
    CMin.HPC = min(min(Data(Restrict(sptsdH,Epoch))))*0.95;
    
    SpecOk.HPC = 1;
end

%% Create figure and components
% axes titles
tax{1} = {'THETA RAW   -   Scoring ACCELERO', ...
            'THETA   -   Scoring ACCELERO', ...
            'MOVEMENTS   -   Scoring ACCELERO', ...
            'GAMMA   -   Scoring OB GAMMA', ...   
            'PFC POWER   -   Scoring OB GAMMA'};
tax{2} = {'THETA RAW   -   Scoring ACCELERO   -   Spectro HPC', ...
        'THETA   -   Scoring ACCELERO   -   Spectro HPC', ...
        'MOVEMENTS   -   Scoring ACCELERO   -   Spectro BULB', ...
        'GAMMA   -   Scoring OB GAMMA   -   Spectro BULB', ...   
        'PFC POWER   -   Scoring OB GAMMA   -   Spectro BULB'};


 figH = uifigure('pos',[1 1 1600 1400]);
    % theta raw
    ax1 = uiaxes(figH,'Position',[120 790 1450 170]);
        if ~noac
            plot(ax1,Range(ThetaRatioTSD,'s'), Data(ThetaRatioTSD),'color',[0.6 0.6 0.6]);
            title(ax1,tax{1}{1})
            set(ax1,'ytick',[]);
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[10 2],'axObj',ax1);
        end
    % theta
    ax2 = uiaxes(figH,'Position',[120 600 1450 170]);
        plot(ax2,Range(SmoothTheta,'s'), Data(SmoothTheta),'color',[0.6 0.6 0.6]);
        title(ax2,tax{1}{2})
        set(ax2,'ytick',[]);
        try
            yline(ax2,Infoacc.theta_thresh,'color','r');
        catch % for earlier version than 2018b
            xL = get(ax2,'XLim');
            line(ax2,xL,[Infoacc.theta_thresh Infoacc.theta_thresh],'Color','r');
        end
        SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[7 1],'axObj',ax2);
    % movement
    ax3 = uiaxes(figH,'Position',[120 410 1450 170]);
        if ~noac
            plot(ax3,Range(tsdMovement,'s'), Data(tsdMovement),'color',[0.6 0.6 0.6]);
            title(ax3,tax{1}{3})
            set(ax3,'ytick',[]);
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[2E8 5e7],'axObj',ax3);
            ylim(ax3,[0 5E8]);
            try
                yline(ax3,Infoacc.mov_threshold,'color','r');
            catch % for earlier version than 2018b
                xL = get(ax3,'XLim');
                line(ax3,xL,[Infoacc.mov_threshold Infoacc.mov_threshold],'Color','r');
            end
        end
    % gamma
    ax4 = uiaxes(figH,'Position',[120 220 1450 170]);
        if ~noob
            plot(ax4,Range(SmoothGamma,'s'), Data(SmoothGamma),'color',[0.6 0.6 0.6]);
            title(ax4,tax{1}{4})
            set(ax4,'ytick',[]);
            SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[700 100],'axObj',ax4);
            try
                yline(ax4,InfoOB.gamma_thresh,'color','r');
            catch % for earlier version than 2018b
                xL = get(ax4,'XLim');
                line(ax4,xL,[InfoOB.gamma_thresh InfoOB.gamma_thresh],'Color','r');
            end
        end
    % low PFC power
    ax5 = uiaxes(figH,'Position',[120 30 1450 170]);
        if pfcchan
            plot(ax5,tx, 10*log10(lowPowPFC),'color',[0.6 0.6 0.6]);
            title(ax5,tax{1}{5})
            set(ax5,'ytick',[]);
            try
                SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[55 4],'axObj',ax5);
            catch
                SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[2E8 5e7],'axObj',ax5);
            end
            try
                yline(ax5,43,'color','r');
            catch % for earlier version than 2018b
                xL = get(ax5,'XLim');
                line(ax5,xL,[43 43],'Color','r');
            end
        end
    

axs = {ax1,ax2,ax3,ax4,ax5};

% axes position and size
pbback     = [650 975 150 35];
pbfor      = [920 975 150 35];
pddwindur  = [810 975 100 35];
plID       = [25 970 150 50];
plexpe     = [25 910 150 50];
plsess     = [135 940 100 20];
pbgo       = [1290 980 80 30];
ptgo       = [1380 985 100 20];
pbgo2      = [1290 945 80 30];
pddgo      = [1380 948 100 20];
plgo       = [1490 984 100 20];
pbgspect   = [300 955 120 60];
prbspectoff= [10 18 100 20];
prbspecton = [10 2 100 20];

% buttons
% back
bback = uibutton(figH,'Position',pbback, ...
        'Text','<< Back ',...
        'ButtonPushedFcn', @(bback,event) bBack(bback));   
% forward
bfor = uibutton(figH,'Position',pbfor, ...
        'Text','Forward >>',...
        'ButtonPushedFcn', @(bfor,event) bForward(bfor)); 

% dropdown
% step dropdown  
ddwindur = uidropdown(figH,'Position',pddwindur,...
'Items',{'50','100','250','500','1000','2000','5000','10000','25000'},'Value','500',...
'ValueChangedFcn',@(ddwindur,event) ddwindur_select(ddwindur));

% ------LABELS-------
% mouse id
uilabel(figH,'Position',plID,'Text',['MOUSE ' m_id], ...
    'FontSize',22);
% expe name
% uilabel(figH,'Position',plexpe,'Text',, ...
%     'FontSize',18);
uilabel(figH,'Position',plgo,'Text','Seconds', ...
    'FontSize',12);

% Place window
pos=0;
windur = str2double(ddwindur.Value);
fmovewin

% write session labels
lsess = uilabel(figH,'Position',plsess,'Text','',...
    'FontSize',14,'FontColor','b');
fsessName

% -------Jump to----------
tgo = uitextarea(figH,...
    'Position',ptgo); 
bgo = uibutton(figH,'Position',pbgo, ...
        'Text','Go to time...',...
        'ButtonPushedFcn', @(bgo,event) fgo(bgo,tgo)); 
ddgo = uidropdown(figH,'Position',pddgo,...
'Items',fNames,'Value',fNames{1},...
'ValueChangedFcn',@(ddgo,event) fddgo(ddgo));
bgo2 = uibutton(figH,'Position',pbgo2, ...
        'Text','Go to session...',...
        'ButtonPushedFcn', @(bgo2,event) fgo(bgo2,ddgo)); 

% ------ spectrum visible --------
bgspect = uibuttongroup(figH,'Visible','off',...
                  'Position',pbgspect,...
                  'Title','Spectral Data', ...
                  'SelectionChangedFcn',@(bgspect,event) frbspect(ThetaRatioTSD,Wake, ...
                  SWSEpoch,REMEpoch,SmoothTheta, ...
                  tsdMovement,Infoacc,SmoothGamma,WakeOB,SWSEpochOB,REMEpochOB, ...
                  InfoOB,lowPowPFC,sptsdH,...
                  CMin,CMax,sptsdB,fB,fH,tx));
              
% Create three radio buttons in the button group.
r1 = uiradiobutton(bgspect,'Text','OFF',...
                  'Position',prbspectoff,...
                  'Value',true);
              
r2 = uiradiobutton(bgspect,'Text','ON',...
                  'Position',prbspecton,...
                  'Value',false);
              
% Make the uibuttongroup visible after creating child objects. 
bgspect.Visible = 'on';

disp('----------------')
disp('Interface ready.')
disp('----------------')
end
%% 
% =========================================================================
%                       NESTED FUNCTION
% =========================================================================
% change session label
function fsessName
    global pos windur lsess tpsCatEvt fNames laddsess figH xl axs 
    global spectchange goSess
    if goSess
        idsess = ceil(find([tpsCatEvt{:}]<=pos,1,'last')/2);
        try
            sessName = fNames{idsess};
        catch
            sessName = '';
        end
        lsess.Text = sessName;
        % turn visible to off
        if ~isempty(laddsess) || ~spectchange
            for i=1:length(laddsess)
                laddsess{i}.Visible = 'off';
                for iax=1:5
                    try
                        xl{i,iax}.Visible = 'off';
                    end
                end
            end
        else
            spectchange=0;
        end
        % check for additional session in current window
        addsess = find([tpsCatEvt{:}]>pos & [tpsCatEvt{:}]<pos+windur);
        if ~isempty(addsess)
            for i=1:length(addsess)/2
                st = tpsCatEvt{addsess(i*2-1)};
                phor = round((((st-pos)/windur)*1380)+windur/3.2);
                psess = [phor 925 100 20];
                sessName = fNames{round(addsess(i*2-1)/2+1)};
                laddsess{i} = uilabel(figH,'Position', ...
                    psess,'Text',sessName,'FontSize',14,'FontColor','r');
                laddsess{i}.Visible = 'on';
                for iax=1:5
                    try
                        xl{i,iax}=xline(axs{iax},st,'Color','r','LineWidth',1.25);
                    catch % for earlier version than 2018b
                        yyaxis(axs{iax},'right');
                        yL = get(axs{iax},'YLim');
                        xl{i,iax} = line(axs{iax},[st st],yL,'Color','r','LineWidth',1.25);
                    end
                    xl{i,iax}.Visible = 'on';
                end
            end
        end
    end
end
    
% button back
function bBack(bback)
    global pos windur
    pos=pos-windur; 
    fmovewin
    fsessName
end        
function bForward(bfor)
    global pos windur
    pos=pos+windur; 
    fmovewin
    fsessName
end
function fgo(bgo,tgo)
    global pos
    try 
        pos=str2double(tgo.Value); 
    catch
        warning('Input must an integer in second')
    end
    fmovewin
    fsessName
end
function fddgo(ddgo)
    global fNames windur tpsCatEvt pos
    starget = ddgo.Value;
    idx = find(contains(fNames,starget));
    pos = tpsCatEvt{idx*2-1}-windur/2;
    fmovewin
    fsessName
end    
function ddwindur_select(dd)
    global windur
    windur = str2double(dd.Value);
    fmovewin
    fsessName
end    

% move window 
function fmovewin
    global pos windur axs 
    xlim(axs{1},[pos pos+windur])
    xlim(axs{2},[pos pos+windur])
    xlim(axs{3},[pos pos+windur])
    xlim(axs{4},[pos pos+windur])
    xlim(axs{5},[pos pos+windur])
end
%show spectral data or not
function frbspect(ThetaRatioTSD,Wake,SWSEpoch,REMEpoch,SmoothTheta, ...
    tsdMovement,Infoacc,SmoothGamma,WakeOB,SWSEpochOB,REMEpochOB,InfoOB,lowPowPFC,sptsdH,...
    CMin,CMax,sptsdB,fB,fH,tx)
    global axs r1 noob noac spectchange tax pfcchan
    if r1.Value
%          axes(axs{1})
            if ~noac
                cla(axs{1},'reset')
                plot(axs{1},Range(ThetaRatioTSD,'s'), Data(ThetaRatioTSD),'color',[0.6 0.6 0.6]);
                title(axs{1},tax{1}{1})
                set(axs{1},'ytick',[]);
                SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[10 2],'axObj',axs{1});
            end
        % theta
%          axes(axs{2})
            cla(axs{2},'reset')
            plot(axs{2},Range(SmoothTheta,'s'), Data(SmoothTheta),'color',[0.6 0.6 0.6]);
            title(axs{2},tax{1}{2})
            set(axs{2},'ytick',[]);
            try
                yline(axs{2},Infoacc.theta_thresh,'color','r');
                yline(axs{2},InfoOB.theta_thresh,'color','b');
            catch % for earlier version than 2018b
                xL = get(axs{2},'XLim');
                line(axs{2},xL,[Infoacc.theta_thresh Infoacc.theta_thresh],'Color','r');
                line(axs{2},xL,[InfoOB.theta_thresh InfoOB.theta_thresh],'Color','b');
            end
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[7 1],'axObj',axs{2});
        % movement
%          axes(axs{3})
            if ~noac
                cla(axs{3},'reset')
                plot(axs{3},Range(tsdMovement,'s'), Data(tsdMovement),'color',[0.6 0.6 0.6]);
                title(axs{3},tax{1}{3})
                set(axs{3},'ytick',[]);
                SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[2E8 5e7],'axObj',axs{3});
                ylim(axs{3},[0 5E8]);
                try
                    yline(axs{3},Infoacc.mov_threshold,'color','r');
                catch % for earlier version than 2018b
                    xL = get(axs{3},'XLim');
                    line(axs{3},xL,[Infoacc.mov_threshold Infoacc.mov_threshold],'Color','r');
                end
            end
        % gamma
%          axes(axs{4})
            if ~noob
                cla(axs{4},'reset')
                plot(axs{4},Range(SmoothGamma,'s'), Data(SmoothGamma),'color',[0.6 0.6 0.6]);
                title(axs{4},tax{1}{4})
                set(axs{4},'ytick',[]);
                SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[700 100],'axObj',axs{4});
                try
                    yline(axs{4},InfoOB.gamma_thresh,'color','r');
                catch % for earlier version than 2018b
                    xL = get(axs{4},'XLim');
                    line(axs{4},xL,[InfoOB.gamma_thresh InfoOB.gamma_thresh],'Color','r');
                end
            end
        % low PFC power
%          axes(axs{5})
            if pfcchan
                cla(axs{5},'reset')
                plot(axs{5},tx, 10*log10(lowPowPFC),'color',[0.6 0.6 0.6]);
                title(axs{5},tax{1}{5})
                set(axs{5},'ytick',[]);
                try
                    SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[55 4],'axObj',axs{5});
                catch
                    SleepStagesOB=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[55 4],'axObj',axs{5});
                end
                try
                    yline(axs{5},43,'color','r');
                catch % for earlier version than 2018b
                    xL = get(axs{5},'XLim');
                    line(axs{5},xL,[43 43],'Color','r');
                end
            end
    else
        % raw theta
            cla(axs{1},'reset')
            yyaxis(axs{1},'left')
            imagesc(axs{1},Range(sptsdH,'s'),fH,10*log10(Data(sptsdH))')
            set(axs{1},'ytick',[]);
            axis(axs{1},'xy')
            ylim(axs{1},[1 20])
            caxis(axs{1},10*log10([CMin.HPC CMax.HPC]))
            yyaxis(axs{1},'right')
            plot(axs{1},Range(ThetaRatioTSD,'s'), Data(ThetaRatioTSD),'color',[0 0 0]);
            title(axs{1},tax{2}{1})
            set(axs{1},'ytick',[]);
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[10 2],'axObj',axs{1});
        % theta
            cla(axs{2},'reset')
            yyaxis(axs{2},'left')
            imagesc(axs{2},Range(sptsdH,'s'),fH,10*log10(Data(sptsdH))')
            set(axs{2},'ytick',[]);
            axis(axs{2},'xy')
            ylim(axs{2},[1 20])
            caxis(axs{2},10*log10([CMin.HPC CMax.HPC]))
            yyaxis(axs{2},'right')
            plot(axs{2},Range(SmoothTheta,'s'), Data(SmoothTheta),'color',[0 0 0]);
            title(axs{2},tax{2}{2})
            set(axs{2},'ytick',[]);
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[7 1],'axObj',axs{2});
            try
                yline(axs{2},Infoacc.theta_thresh,'color','r');
                yline(axs{2},InfoOB.theta_thresh,'color','b');
            catch % for earlier version than 2018b
                xL = get(axs{2},'XLim');
                line(axs{2},xL,[Infoacc.theta_thresh Infoacc.theta_thresh],'Color','r');
                line(axs{2},xL,[InfoOB.theta_thresh InfoOB.theta_thresh],'Color','b');
            end
        % movement
            cla(axs{3},'reset')
            yyaxis(axs{3},'left')
            imagesc(axs{3},Range(sptsdB,'s'),fB,10*log10(Data(sptsdB))')
            set(axs{3},'ytick',[]);
            axis(axs{3},'xy')
            ylim(axs{3},[21 99])
            caxis(axs{3},10*log10([CMin.OB CMax.OB]))
            yyaxis(axs{3},'right')
            plot(axs{3},Range(tsdMovement,'s'), Data(tsdMovement),'color',[0 0 0]);
            title(axs{3},tax{2}{3})
            set(axs{3},'ytick',[]);
            SleepStages=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[2E8 5e7],'axObj',axs{3});
            ylim(axs{3},[0 5E8]);
            try
                yline(axs{3},Infoacc.mov_threshold,'color','r');
            catch % for earlier version than 2018b
                xL = get(axs{3},'XLim');
                line(axs{3},xL,[Infoacc.mov_threshold Infoacc.mov_threshold],'Color','r');
            end
        % gamma
            if ~noob
                cla(axs{4},'reset')
                yyaxis(axs{4},'left')
                imagesc(axs{4},Range(sptsdB,'s'),fB,10*log10(Data(sptsdB))') 
                set(axs{4},'ytick',[]);
                axis(axs{4},'xy')
                ylim(axs{4},[21 99])
                caxis(axs{4},10*log10([CMin.OB CMax.OB]))
                yyaxis(axs{4},'right')
                plot(axs{4},Range(SmoothGamma,'s'), Data(SmoothGamma),'color',[0 0 0]);
                title(axs{4},tax{2}{4})
                set(axs{4},'ytick',[]);
                SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[700 100],'axObj',axs{4});
                try
                    yline(axs{4},InfoOB.gamma_thresh,'color','r');
                catch % for earlier version than 2018b
                    xL = get(axs{4},'XLim');
                    line(axs{4},xL,[InfoOB.gamma_thresh InfoOB.gamma_thresh],'Color','r');
                end
            end
        % low PFC power
            if pfcchan
                cla(axs{5},'reset')
                yyaxis(axs{5},'left')
                imagesc(axs{5},Range(sptsdB,'s'),fB,10*log10(Data(sptsdB))')
                set(axs{5},'ytick',[]);
                axis(axs{5},'xy')
                ylim(axs{5},[21 99])
                caxis(axs{5},10*log10([CMin.OB CMax.OB]))
                yyaxis(axs{5},'right')
                plot(axs{5},tx, 10*log10(lowPowPFC),'color',[0 0 0]);
                title(axs{5},tax{2}{5})
                set(axs{5},'ytick',[]);
                try
                    SleepStagesOB=PlotSleepStage(WakeOB,SWSEpochOB,REMEpochOB,0,[55 4],'axObj',axs{5});
                catch
                    SleepStagesOB=PlotSleepStage(Wake,SWSEpoch,REMEpoch,0,[55 4],'axObj',axs{5});
                end
                try
                    yline(axs{5},43,'color','r');
                catch % for earlier version than 2018b
                    xL = get(axs{5},'XLim');
                    line(axs{5},xL,[43 43],'Color','r');
                end
            end
    end 
    spectchange=1;
    fmovewin
    fsessName
end
