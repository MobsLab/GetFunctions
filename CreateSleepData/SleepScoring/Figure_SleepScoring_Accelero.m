% Figure_SleepScoring_Accelero
% 29.11.2017 KJ
%
%
% This function makes an overview of sleep scoring using the accelerometer
% 
%%INPUT
% coeff_display     : coefficient for the display of signals
% foldername        : location of data & save location
%
%
% SEE
%   SleepScoringAccelerometer Figure_SleepScoring_OBGamma
%


function Figure_SleepScoring_Accelero(coeff_display, foldername)


%% INITIATION
if nargin < 1
    error('Incorrect number of parameters.');
elseif nargin < 2
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end

% colors for plotting
Colors.SWS = 'r';
Colors.REM = 'g';
Colors.Wake = 'c';
Colors.Noise = [0 0 0];

% Variables that indicate if specta exist
SpecOk.HPC = 0;

% load sleep scoring info

try
    load([foldername 'SleepScoring_Accelero'])
catch
    load([foldername 'StateEpochSB'])
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

% theta power : restrict to non-noisy epoch

% try
    SmoothThetaNew = Restrict(SmoothTheta,Epoch);
% catch
%     load('StateEpochSB','SmoothTheta','Epoch')
%     SmoothThetaNew = Restrict(SmoothTheta,Epoch);
% end

% gamma and theta power : subsample to same bins
t = Range(SmoothThetaNew);
ti = t(5:1200:end);
SmoothThetaNew = (Restrict(SmoothThetaNew,ts(ti)));

% beginning and end of session
begin = t(1)/3600e4;
endin = t(end)/3600e4;


%% Final display
SleepScoringFigure = figure;
set(SleepScoringFigure,'color',[1 1 1],'Position',[1 1 1600 600])

% HPC spectrum
subplot(3,1,1)
if SpecOk.HPC
    imagesc(Range(sptsdH)/3600e4,fH,10*log10(Data(sptsdH))'), axis xy, caxis(10*log10([CMin.HPC CMax.HPC]))
    hold on
    xlim([begin endin])
    set(gca,'XTick',[])
    title('HPC')
end


% Theta/delta ratio % Décommenté le 31/07/24
subplot(3,1,2), hold on
plot(Range(SmoothThetaNew)/3600e4, Data(SmoothThetaNew), 'linewidth',1, 'color','k')
try
    line([begin endin], [Info.theta_thresh Info.theta_thresh], 'linewidth',1, 'color',[0.7 0.7 0.7])
catch
    load('StateEpochSB','Info')
    line([begin endin], [Info.theta_thresh Info.theta_thresh], 'linewidth',1, 'color',[0.7 0.7 0.7])
end
xlim([begin endin]), 
title('Theta/Delta ratio')
set(gca,'XTick',[])

% Movement % Décommenté le 31/07/24
subplot(3,1,3), hold on
plot(Range(tsdMovement)/3600e4, Data(tsdMovement), 'linewidth',1, 'color','k')
line([begin endin], [Info.mov_threshold Info.mov_threshold], 'linewidth',1, 'color',[0.7 0.7 0.7])
xlim([begin endin]), 
title('Movement')

% Lines to indicate epochs
for i=2:3
    subplot(3,1,i), hold on
    
    if i == 2
        plot(Range(SmoothThetaNew)/3600e4, Data(SmoothThetaNew), 'linewidth',1, 'color','k')
        try
            line([begin endin], [Info.theta_thresh Info.theta_thresh], 'linewidth',1, 'color',[0.7 0.7 0.7])
        catch
            load('StateEpochSB','Info')
            line([begin endin], [Info.theta_thresh Info.theta_thresh], 'linewidth',1, 'color',[0.7 0.7 0.7])
        end
        xlim([begin endin]),
        title('Theta/Delta ratio')
        set(gca,'XTick',[])
        
    elseif i == 3
        plot(Range(tsdMovement)/3600e4, Data(tsdMovement), 'linewidth',1, 'color','k')
        line([begin endin], [Info.mov_threshold Info.mov_threshold], 'linewidth',1, 'color',[0.7 0.7 0.7])
        xlim([begin endin]),
        title('Movement')
    end
    yl=ylim;
    LineHeight = yl(2);
    line([begin endin], [LineHeight LineHeight], 'linewidth',10, 'color','w')
    
%     % temporary solution, BM on 22/08/2024
%     load('SleepScoring_Accelero.mat','Wake','SWSEpoch','REMEpoch')
%     WakeAcc = Wake;
%     SWSEpochAcc = SWSEpoch;
%     REMEpochAcc = REMEpoch;    

try
    load('SleepScoring_Accelero.mat','Wake','SWSEpoch','REMEpoch')
    WakeAcc = Wake;
    SWSEpochAcc = SWSEpoch;
    REMEpochAcc = REMEpoch;
catch
    load('StateEpochSB.mat')
end
    
    
    try % décommenté le 190724 pour check
        PlotPerAsLine(REMEpochAcc, LineHeight, Colors.REM, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(SWSEpochAcc, LineHeight, Colors.SWS, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(WakeAcc, LineHeight, Colors.Wake, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(TotalNoiseEpoch, LineHeight, Colors.Noise, 'timescaling', 3600e4, 'linewidth',5);
    catch
        load('StateEpochSB')
        PlotPerAsLine(REMEpochAcc, LineHeight, Colors.REM, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(SWSEpochAcc, LineHeight, Colors.SWS, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(WakeAcc, LineHeight, Colors.Wake, 'timescaling', 3600e4, 'linewidth',10);
        PlotPerAsLine(TotalNoiseEpoch, LineHeight, Colors.Noise, 'timescaling', 3600e4, 'linewidth',5);
    end
    
    
    suplabel('Sleep scoring with movements (Wake=cyan, SWS=red, REM=green, Noise=black)','t');
    
    %% save figure
    try
        res=pwd;
        cd(foldername);
        saveas(SleepScoringFigure, 'SleepScoringAccelero.png', 'png');
        cd(res);
    catch
        res=pwd;
        cd(foldername);
        saveas(SleepScoringFigure.Number, 'SleepScoringAccelero.png', 'png');
        cd(res);
    end
    
    
end

