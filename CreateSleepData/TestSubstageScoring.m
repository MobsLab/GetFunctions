%TestSubstageScoring

load('FeaturesScoring', 'featuresNREM', 'NoiseEpoch')
[Epoch, NameEpoch] = SubstagesScoring(featuresNREM, NoiseEpoch,'BurstIs3',1,'newBurstThresh',0);
save('SleepSubstages', 'Epoch', 'NameEpoch')
[SleepStages, Epochs, time_in_substages, meanDuration_substages, percentvalues_NREM] = MakeIDfunc_Sleepstages;

%% Plot

figure, hold

%hypno
subplot(3,4,1:8), hold on
ylabel_substage = {'N3','N2','N1','REM','WAKE'};
ytick_substage = [1 1.5 2 3 4]; %ordinate in graph
colori = {[0.5 0.3 1], [1 0.5 1], [0.8 0 0.7], [0.1 0.7 0], [0.5 0.2 0.1]}; %substage color
plot(Range(SleepStages,'s')/3600,Data(SleepStages),'k'), hold on,
for ep=1:length(Epochs)
    plot(Range(Restrict(SleepStages,Epochs{ep}),'s')/3600 ,Data(Restrict(SleepStages,Epochs{ep})),'.','Color',colori{ep}), hold on,
end
xlim([0 max(Range(SleepStages,'s')/3600)]), ylim([0.5 5]), set(gca,'Ytick',ytick_substage,'YTickLabel',ylabel_substage), hold on,
title('Hypnogram'); xlabel('Time (h)')

%substage duration
subplot(3,4,9:10), hold on
for ep=1:length(time_in_substages)
    h = bar(ep, time_in_substages(ep)/1000); hold on
    set(h,'FaceColor', colori{ep}), hold on
    if any(1:3==ep)
        text(ep - 0.3, time_in_substages(ep)/1000 + 1000, [num2str(percentvalues_NREM(ep)) '%'], 'VerticalAlignment', 'top', 'FontSize', 8)
    end
end
set(gca, 'XTickLabel',{'N1','N2','N3','REM','WAKE'}, 'XTick',1:5), hold on
ylim([0, max(time_in_substages/1000) * 1.2]);
title('Total duration'); ylabel('duration (s)')

%episode duration
subplot(3,4,11:12), hold on
for ep=1:length(meanDuration_substages)
    h = bar(ep, meanDuration_substages(ep)/1000); hold on
    set(h,'FaceColor', colori{ep}), hold on
end
set(gca, 'XTickLabel',{'N1','N2','N3','REM','WAKE'}, 'XTick',1:5), hold on
title('Episode mean duration'); ylabel('duration (s)')
