% PlotIDSleepData2
% 08.01.2018 KJ
%
%%INPUT
% 
% 
%%OUTPUT
% 
%
% SEE
%   MakeIDSleepData2
%


function PlotIDSleepData2(varargin)


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'foldername'
            foldername = lower(varargin{i+1});
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('foldername','var')
    foldername = pwd;
end


%% load sleep data
load IdFigureData2
load('IdFigureData','SleepStages','Epochs') 


%% figure
figure('Color',[1 1 1],'units','normalized','outerposition',[0 0 1 1]);

%left : tables and text
table_events_dim = [0.05 0.82 0.14 0.11];
table_downdelta_dim = [0.2 0.82 0.16 0.11];
table_lfp_dim = [0.05 0.51 0.14 0.3];
table_tetrode_dim = [0.2 0.51 0.16 0.3];

%density and hypno
Density_Axes = axes('position', [0.4 0.75 0.37 0.15]);
Hypnogram_Axes = axes('position', [0.4 0.55 0.37 0.15]);
%isi
DeltaIsi_Axes = axes('position', [0.8 0.75 0.15 0.14]);
DownIsi_Axes = axes('position', [0.8 0.55 0.15 0.14]);

%mean curves on ripples and down states
RipplesCurves_Axes = axes('position', [0.05 0.05 0.37 0.4]);
DownCurves_Axes = axes('position', [0.47 0.05 0.48 0.4]);


%% Table number of sleep events
data_table1{1,1} = 'delta';  data_table1{1,2} = deltas_stat.nb;
data_table1{2,1} = 'down';  data_table1{2,2} = down_stat.nb;
data_table1{3,1} = 'ripples'    ;  data_table1{3,2} = ripples_stat.nb;
data_table1{4,1} = 'spindles'   ;  data_table1{4,2} = spindles_stat.nb;

tableau1 = uitable(gcf, 'Data',data_table1, 'units','normalized', 'position',table_events_dim, 'ColumnWidth',{120 80});
tableau1.ColumnName = {'sleep events', 'quantity'};


%% Table about delta waves and down states occurence
data_table2{1,1} = 'delta only'     ;  data_table2{1,2} = nb_delta.only;
data_table2{2,1} = 'down only'      ;  data_table2{2,2} = nb_down.only;
data_table2{3,1} = 'down+delta'     ;  data_table2{3,2} = nb_down.delta;

tableau2 = uitable(gcf, 'Data',data_table2, 'units','normalized', 'position',table_downdelta_dim, 'ColumnWidth',{120 80});
tableau2.ColumnName = {'delta/down', 'quantity'};


%% Table LFP info
for i=1:length(lfp_structures)
    data_table3{i,1} = lfp_structures{i};
    for h=1:length(hemispheres)
        data_table3{i,h+1} = nb_channel(i,h);
    end
end
tableau3 = uitable(gcf, 'Data',data_table3, 'units','normalized', 'position',table_lfp_dim, 'ColumnWidth',{'auto' 40 40 40});
tableau3.ColumnName = ['LFP' hemispheres];


%% Table Tetrode Info
if exist(fullfile(foldername,'SpikeData.mat'),'file')==2
    k=1;
    for t=1:length(nb_neurons.all)
        if nb_neurons.all(t)
            data_table4{k,1} = info_tetrode.structure{t};
            data_table4{k,2} = info_tetrode.hemisphere{t};
            data_table4{k,3} = nb_neurons.all(t);
            data_table4{k,4} = nb_neurons.pyr(t);
            data_table4{k,5} = nb_neurons.int(t);

            k=k+1;
        end
    end
    tableau3 = uitable(gcf, 'Data',data_table4, 'units','normalized', 'position',table_tetrode_dim, 'ColumnWidth',{'auto' 40 50 40 40});
    tableau3.ColumnName = {'Tetrodes', 'hemi', 'total', 'pyr','int'};
end

%% Density
axes(Density_Axes);
plot(deltas_stat.density.x, deltas_stat.density.y, 'color', 'r'), hold on
plot(down_stat.density.x, down_stat.density.y, 'color', 'b'),
legend('delta waves','down states'),
ylabel('deltas/down per sec'), xlim([0 max(deltas_stat.density.x)])
set(gca, 'XTickLabel',{''}, 'XTick',1:10), hold on
title('event density')
xlim([0 max(Range(SleepStages,'s')/3600)])

%% Hypnogram
axes(Hypnogram_Axes);

ylabel_substage = {'N3','N2','N1','REM','WAKE'};
ytick_substage = [1 1.5 2 3 4]; %ordinate in graph
colori = {[0.5 0.3 1], [1 0.5 1], [0.8 0 0.7], [0.1 0.7 0], [0.5 0.2 0.1]}; %substage color
plot(Range(SleepStages,'s')/3600,Data(SleepStages),'k'), hold on,
for ep=1:length(Epochs)
    plot(Range(Restrict(SleepStages,Epochs{ep}),'s')/3600 ,Data(Restrict(SleepStages,Epochs{ep})),'.','Color',colori{ep}), hold on,
end
xlim([0 max(Range(SleepStages,'s')/3600)]), ylim([0.5 5]), set(gca,'Ytick',ytick_substage,'YTickLabel',ylabel_substage), hold on,
title('Hypnogram'); xlabel('Time (h)')


%% ISI
axes(DeltaIsi_Axes);
bar(deltas_stat.isi.x, deltas_stat.isi.y), hold on
title('Inter-delta-intervals')

axes(DownIsi_Axes);
bar(down_stat.isi.x, down_stat.isi.y), hold on
title('Inter-down-intervals')


%% Mean Curves on Ripples
axes(RipplesCurves_Axes);
if ~isempty(ripples_curves)
    for i=1:length(ripples_curves)
        plot(ripples_curves{i}(:,1), ripples_curves{i}(:,2)), hold on
        name_curves{i} = ['ch' num2str(hpc_channels(i)) ' - ' hpc_hemispheres{i}];
    end
    legend(name_curves), title('mean LFP on ripples'), 
    set(gca,'xlim',[-0.3 0.4])
    clear name_curves
else
    text(0.5,0.5,'No ripples')
end

%% Mean Curves on Down states
axes(DownCurves_Axes);
if exist([cd filesep 'DownState.mat'])>0 % added by SB for use with mice with no spikes

%sort by peak value
[~,idx] = sort(peak_value,'descend');
down_curves = down_curves(idx);
channel_curves = channel_curves(idx);
structures_curves = structures_curves(idx);

for i=1:length(down_curves)
    plot(down_curves{i}(:,1), down_curves{i}(:,2)), hold on
    name_curves{i} = [structures_curves{i} ' - ch' num2str(channel_curves(i))];
end
legend(name_curves), title('mean LFP on down states'), 
set(gca,'xlim',[-0.4 0.8])
clear name_curves
else
    text(0.5,0.5,'No downs')

end


end












