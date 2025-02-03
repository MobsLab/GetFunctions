% Figure_SleepScoring_OBGamma
% 21.11.2017 SB
%
%
% This function makes an overview of sleep scoring using the OB gamma
% 
%%INPUT
% foldername : location of data & save location
%
%
% SEE
%   SleepScoringOBGamma SleepScoringFigure_Accelero
%


function Figure_SleepScoring_OBGamma(foldername)

%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end

%% INITIATION
% colors for plotting
Colors.SWS = 'r';
Colors.REM = 'g';
Colors.Wake = 'b';
Colors.Noise = [0 0 0];

% Variables that indicate if specta exist
SpecOk.OB = 0;
SpecOk.HPC = 0;

% load sleep scoring info
load([foldername 'SleepScoring_OBGamma'])

% load OB spectrum
if exist([foldername,'B_High_Spectrum.mat'])>0
    load([foldername,'B_High_Spectrum.mat']);
    
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

% load HPC spectrum
if exist([foldername,'H_Low_Spectrum.mat'])>0
    load([foldername,'H_Low_Spectrum.mat']);

    % make tsd
    sptsdH = tsd(Spectro{2}*1e4,Spectro{1});
    fH = Spectro{3};
    clear Spectro
    
    % get caxis lims
    CMax.HPC = max(max(Data(Restrict(sptsdH,Epoch))))*1.05;
    CMin.HPC = min(min(Data(Restrict(sptsdH,Epoch))))*0.95;
    
    SpecOk.HPC = 1;
end

% gamma and theta power : restrict to non-noisy epoch
SmoothGammaNew = Restrict(SmoothGamma,Epoch);
SmoothThetaNew = Restrict(SmoothTheta,Epoch);

% gamma and theta power : subsample to same bins
t = Range(SmoothThetaNew);
ti = t(5:1200:end);
SmoothGammaNew = (Restrict(SmoothGammaNew,ts(ti)));
SmoothThetaNew = (Restrict(SmoothThetaNew,ts(ti)));

% beginning and end of session
begin = t(1)/1e4;
endin = t(end)/1e4;

%% Make the figure
% create figure
SleepScoringFigureOB = figure;
set(SleepScoringFigureOB,'color',[1 1 1],'Position',[1 1 1600 600])

% HPC spectrum
subplot(6,3,[1:2,4:5])
if SpecOk.HPC
    imagesc(Range(sptsdH,'s'),fH,10*log10(Data(sptsdH))'), axis xy, caxis(10*log10([CMin.HPC CMax.HPC]))
    hold on
    % Lines to indicate epochs
    LineHeight = 19;
    line([begin endin],[LineHeight LineHeight],'linewidth',10,'color','w')
    PlotPerAsLine(REMEpoch,LineHeight,Colors.REM);
    PlotPerAsLine(SWSEpoch,LineHeight,Colors.SWS);
    PlotPerAsLine(Wake,LineHeight,Colors.Wake);
    PlotPerAsLine(TotalNoiseEpoch,LineHeight,Colors.Noise);
    xlim([begin endin])
    set(gca,'XTick',[])
    title('HPC')
end

% Theta/delta ratio
subplot(6,3,[7:8])
plot(Range(SmoothThetaNew,'s'),Data(SmoothThetaNew),'linewidth',1,'color','k')
xlim([begin endin])
set(gca,'XTick',[])

% OB spectrum
subplot(6,3,[10:11,13:14])
if SpecOk.OB
    imagesc(Range(sptsdB,'s'),fB,10*log10(Data(sptsdB))'), axis xy, caxis(10*log10([CMin.OB CMax.OB]))
    hold on
    % Lines to indicate epochs
    LineHeight = 90;
    line([begin endin],[LineHeight LineHeight],'linewidth',10,'color','w')
    PlotPerAsLine(REMEpoch,LineHeight,Colors.REM);
    PlotPerAsLine(SWSEpoch,LineHeight,Colors.SWS);
    PlotPerAsLine(Wake,LineHeight,Colors.Wake);
    PlotPerAsLine(TotalNoiseEpoch,LineHeight,Colors.Noise);
    xlim([begin endin])
    set(gca,'XTick',[])
    title('OB')
end

% Gamma power
subplot(6,3,[16:17])
plot(Range(SmoothGammaNew,'s'),Data(SmoothGammaNew),'linewidth',1,'color','k')
xlim([begin endin])

% Phase space plot theta/delta ratio vs gamma power
subplot(6,12,[22:24,34:36,46:48]),hold on
% REM
SmoothThetaREM  =  (Restrict(SmoothThetaNew,REMEpoch));
SmoothGammaREM  =  Restrict(SmoothGammaNew,ts(Range(SmoothThetaREM)));
plot(log(Data(SmoothGammaREM)),log(Data(SmoothThetaREM)),'.','color',Colors.REM,'MarkerSize',1);
% SWS
SmoothThetaSWS  =  (Restrict(SmoothThetaNew,SWSEpoch));
SmoothGammaSWS = Restrict(SmoothGammaNew,ts(Range(SmoothThetaSWS)));
plot(log(Data(SmoothGammaSWS)),log(Data(SmoothThetaSWS)),'.','color',Colors.SWS,'MarkerSize',1);
% Wake
SmoothThetaWake = (Restrict(SmoothThetaNew,Wake));
SmoothGammaWake = Restrict(SmoothGammaNew,ts(Range(SmoothThetaWake)));
plot(log(Data(SmoothGammaWake)),log(Data(SmoothThetaWake)),'.','color',Colors.Wake,'MarkerSize',1);

legend('REM','SWS','Wake')
findobj(gcf,'tag','legend');
[~,icons,~,~] = legend('REM','SWS','Wake');
set(icons(5),'MarkerSize',20)
set(icons(7),'MarkerSize',20)
set(icons(9),'MarkerSize',20)

% Some esthetics
axphase = gca;
ys = get(axphase,'Ylim');
xs = get(axphase,'Xlim');
box on
set(gca,'XTick',[],'YTick',[])

% Histogram of theta/delta ratio values
subplot(6, 12, [21,33,45]), hold on
[~, rawN, ~] = nhist(log(Data(Restrict(SmoothTheta,Sleep))), 'maxx',max(log(Data(Restrict(SmoothTheta,Sleep)))), 'noerror', 'xlabel','Theta/Delta power', 'ylabel',[]); 
axis xy,
view(90,-90),
line([log(Info.theta_thresh) log(Info.theta_thresh)],[0 max(rawN)],'linewidth',4,'color','r');
set(gca,'YTick',[],'Xlim',ys);

% Histogram of gamma values
subplot(6, 12, 58:60), hold on
[~, rawN, ~] = nhist(log(Data(SmoothGamma)),'maxx',max(log(Data(SmoothGamma))),'noerror','xlabel','Gamma power','ylabel',[]);
line([log(Info.gamma_thresh) log(Info.gamma_thresh)],[0 max(rawN)],'linewidth',4,'color','r');
set(gca,'YTick',[],'Xlim',xs);


% save figure
try    
    res=pwd;
    cd(foldername);
    saveas(SleepScoringFigureOB, 'SleepScoringOB.png', 'png');
    cd(res);
catch    
    res=pwd;
    cd(foldername);
    saveas(SleepScoringFigureOB.Number, 'SleepScoringOB.png', 'png');
    cd(res);
end


end




