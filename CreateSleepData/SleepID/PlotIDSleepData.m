% PlotIDSleepData
% 06.12.2017 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   PlotIDSleepData2 MakeIDSleepData
%


function PlotIDSleepData(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        case 'scoring'
            scoring = lower(varargin{i+1});
            if ~isstring_FMAToolbox(scoring, 'accelero' , 'ob')
                error('Incorrect value for property ''scoring''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end

%type of sleep scoring
if ~exist('scoring','var')
    scoring='ob';
end


%% load sleep data
load IdFigureData 
% check if sup delta exist
if~exist('Msup_short_delta','var'), DeltaSup = 0; else DeltaSup = 1; end
    
% %sleep scoring bulb
if strcmpi(scoring,'ob')
[gamma, theta, SleepEpoch] = MakeIDfunc_ScoringBulb;
end

%% figure
figure('Color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]);
RasterDown_Axes = axes('position', [0.27 0.72 0.15 0.21]);
DistribDown_Axes = axes('position', [0.45 0.72 0.15 0.21]);
textbox_dim = [0.05 0.75 0.18 0.17];

Sleepscoring_Axes = axes('position', [0.74 0.6 0.2 0.32]);
SleepscoringTheta_Axes = axes('position', [0.66 0.6 0.07 0.32]);
SleepscoringGamma_Axes = axes('position', [0.74 0.49 0.2 0.1]);

AverageRipple_Axes = axes('position', [0.05 0.54 0.3 0.13]);
AverageSpindle_Axes = axes('position', [0.05 0.3 0.3 0.19]);
AverageDelta_Axes = axes('position', [0.41 0.3 0.3 0.25]);

Substages_Axes = axes('position', [0.05 0.05 0.4075 0.2]);
StatSubstage_Axes = axes('position', [0.52 0.05 0.2 0.2]);
MeanDurSubstage_Axes = axes('position', [0.75 0.05 0.2 0.2]);

%% Down states
% Create textbox
if nb_neuron.all>0
    textbox_str = {[num2str(nb_neuron.all) ' neurons'], [num2str(nb_neuron.pyr) ' pyramidal(s) / ' num2str(nb_neuron.int) ' interneuron(s)'],... 
                    ['FR (SWS) = ' num2str(firingrates.sws.all) ' Hz ( ' num2str(firingrates.sws.all/nb_neuron.all) ' Hz)'],...
                    ['FR (Wake) = ' num2str(firingrates.wake.all) ' Hz ( ' num2str(firingrates.wake.all/nb_neuron.all) ' Hz)'],...
                    ['Pyr (SWS) = ' num2str(firingrates.sws.pyr) ' Hz ( ' num2str(firingrates.sws.pyr/nb_neuron.pyr) ' Hz)'],...
                    ['Pyr (Wake) = ' num2str(firingrates.wake.pyr) ' Hz ( ' num2str(firingrates.wake.pyr/nb_neuron.pyr) ' Hz)'],...
                    ['Int (SWS) = ' num2str(firingrates.sws.int) ' Hz ( ' num2str(firingrates.sws.int/nb_neuron.int) ' Hz)'],...
                    ['int (Wake) = ' num2str(firingrates.wake.int) ' Hz ( ' num2str(firingrates.wake.int/nb_neuron.int) ' Hz)']};
else
   textbox_str = {'No neurons'}; 
end

annotation(gcf,'textbox',...
    textbox_dim,...
    'String',textbox_str,...
    'LineWidth',1,...
    'HorizontalAlignment','center',...
    'FontWeight','bold',...
    'FitBoxToText','off');

%raster
axes(RasterDown_Axes);
if exist('raster_mua','var')
    imagesc(raster_mua.time/1E4, 1:size(raster_mua.matrix,1), raster_mua.matrix), hold on
    axis xy, xlabel('time (sec)'), ylabel('# down'), hold on
    colorbar, hold on
end

%distribution of down
axes(DistribDown_Axes);
if nb_neuron.all>0
    plot(duration_bins, nbDown.sws ,'r'), hold on
    plot(duration_bins, nbDown.wake ,'k'), hold on
    set(gca,'xscale','log','yscale','log'), hold on
    set(gca,'ylim',[1 1E6],'xlim',[10 1500]), hold on
    set(gca,'xtick',[10 50 100 200 500 1500]), hold on
    legend('SWS','Wake'), xlabel('down duration (ms)'), ylabel('number of down')
end


%% Sleep scoring
if strcmpi(scoring,'ob')
axes(Sleepscoring_Axes);
if not(isempty(Data(gamma.rem)))
plot(log(Data(gamma.rem)),log(Data(theta.rem)),'.','color',[1 0.2 0.2],'MarkerSize',1); hold on
else
plot(median(log(Data(gamma.sws))),median(log(Data(theta.sws))),'.','color',[1 0.2 0.2],'MarkerSize',1); hold on    
end
plot(log(Data(gamma.sws)),log(Data(theta.sws)),'.','color',[0.4 0.5 1],'MarkerSize',1); hold on
plot(log(Data(gamma.wake)),log(Data(theta.wake)),'.','color',[0.6 0.6 0.6],'MarkerSize',1); hold on
[~,icons,~,~]=legend('REM','SWS','Wake'); hold on
set(icons(5),'MarkerSize',20)
set(icons(7),'MarkerSize',20)
set(icons(9),'MarkerSize',20)
ys=get(gca,'Ylim');
xs=get(gca,'Xlim');
box on
set(gca,'XTick',[],'YTick',[])

axes(SleepscoringTheta_Axes);
[~, rawN, ~] = nhist(log(Data(Restrict(theta.smooth, SleepEpoch))),'maxx',max(log(Data(Restrict(theta.smooth, SleepEpoch)))),'noerror','xlabel','Theta power','ylabel',[]); axis xy
view(90,-90)
line([log(theta.threshold) log(theta.threshold)],[0 max(rawN)],'linewidth',4,'color','r')
set(gca,'YTick',[],'Xlim',ys)

axes(SleepscoringGamma_Axes);
[~, rawN, ~] = nhist(log(Data(gamma.smooth)),'maxx',max(log(Data(gamma.smooth))),'noerror','xlabel','Gamma power','ylabel',[]);
line([log(gamma.threshold) log(gamma.threshold)],[0 max(rawN)],'linewidth',4,'color','r')
set(gca,'YTick',[],'Xlim',xs)
end

%% Ripples and spindles
%ripples
axes(AverageRipple_Axes);
if ~isempty(Mripples)
    plot(Mripples(:,1), Mripples(:,2),'r','linewidth',2), hold on 
end
line([0 0],get(gca,'YLim')), hold on
title('Mean ripples signal : -50 +50 ms'), hold on

%spindles
axes(AverageSpindle_Axes);
if ~isempty(Mspi_spindles)
    yyaxis left
    plot(Mspi_spindles(:,1),Mspi_spindles(:,2),'b','linewidth',2), hold on
    plot(Mdeep_spindles(:,1),Mdeep_spindles(:,2),'r','linewidth',2), hold on
    ylabel('LFP')
    try
        yyaxis right
        plot(Mmua_spindles(:,1),Mmua_spindles(:,2), 'color','b'), hold on
        ylabel('MUA (10s bin)')
        legend('PFCx on spindles','PFCx deep','MUA')
    catch
        legend('PFCx on spindles','PFCx deep')
    end
end
line([0 0],get(gca,'YLim')), hold on
title('Mean spindles signal : -500 +500 ms'), hold on

%% Delta waves
axes(AverageDelta_Axes);
yyaxis left
plot(Msup_short_delta(:,1),Msup_short_delta(:,2),'--', 'color', 'b'), hold on
plot(Msup_long_delta(:,1),Msup_long_delta(:,2), '-', 'color', 'b'), hold on
plot(Mdeep_short_delta(:,1),Mdeep_short_delta(:,2),'--', 'color', 'r'), hold on
plot(Mdeep_long_delta(:,1),Mdeep_long_delta(:,2),'-', 'color', 'r'), hold on
ylabel('LFP')
try %MUA average sync
    yyaxis right
    maxvalue = ceil(max([Mmua_short_delta(:,2);Mmua_long_delta(:,2)]));
    plot(Mmua_short_delta(:,1),Mmua_short_delta(:,2),'--', 'color','k'), hold on
    plot(Mmua_long_delta(:,1),Mmua_long_delta(:,2),'-',  'color','k'), hold on
    ylabel('MUA (10s bin)'), ylim([0 maxvalue*3])
    legend('LFP Sup (short deltas)','LFP Sup (long deltas)','LFP deep (short deltas)','LFP deep (long deltas)','LFP deep (long deltas)','MUA (short deltas)','MUA (long deltas)')
    title_ax = 'Mean LFP and MUA: averaged on delta waves centers';
catch
    legend('LFP Sup (short deltas)','LFP Sup (long deltas)','LFP deep (short deltas)','LFP deep (long deltas)')
    title_ax = 'Mean LFP  averaged on delta waves centers';
end

line([0 0],get(gca,'YLim')), hold on
title(title_ax), hold on


%% Substages
axes(Substages_Axes);
ylabel_substage = {'N3','N2','N1','REM','WAKE'};
ytick_substage = [1 1.5 2 3 4]; %ordinate in graph
colori = {[0.5 0.3 1], [1 0.5 1], [0.8 0 0.7], [0.1 0.7 0], [0.5 0.2 0.1]}; %substage color
plot(Range(SleepStages,'s')/3600,Data(SleepStages),'k'), hold on,
for ep=1:length(Epochs)
    plot(Range(Restrict(SleepStages,Epochs{ep}),'s')/3600 ,Data(Restrict(SleepStages,Epochs{ep})),'.','Color',colori{ep}), hold on,
end
xlim([0 max(Range(SleepStages,'s')/3600)]), ylim([0.5 5]), set(gca,'Ytick',ytick_substage,'YTickLabel',ylabel_substage), hold on,
title('Hypnogram'); xlabel('Time (h)')

axes(StatSubstage_Axes);
for ep=1:length(time_in_substages)
    h = bar(ep, time_in_substages(ep)/1000); hold on
    set(h,'FaceColor', colori{ep}), hold on
%     if any(1:5==ep)
%         text(ep - 0.3, time_in_substages(ep)/1000 + 1000, [num2str(percentvalues_NREM(ep)) '%'], 'VerticalAlignment', 'top', 'FontSize', 8)
%     end
end
set(gca, 'XTickLabel',{'N1','N2','N3','REM','WAKE'}, 'XTick',1:5), hold on
ylim([0, max(time_in_substages/1000) * 1.2]);
title('Total duration'); ylabel('duration (s)')


axes(MeanDurSubstage_Axes)
for ep=1:length(meanDuration_substages)
    h = bar(ep, meanDuration_substages(ep)/1000); hold on
    set(h,'FaceColor', colori{ep}), hold on
end
set(gca, 'XTickLabel',{'N1','N2','N3','REM','WAKE'}, 'XTick',1:5), hold on
title('Episode mean duration'); ylabel('duration (s)')



end












