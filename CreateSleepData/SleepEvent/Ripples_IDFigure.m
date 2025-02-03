function Ripples_IDFigure(ripples,T,RipplesEpoch,epoch,nrem,wake)

%==========================================================================
% Details: Create an ID figure of ripples detected giving several measures:
%           waveforms, density (1st half/2nd half), Amplitude, Duration,
%           Frequency. 
%
%
% INPUTS:
%       - ripples           ripples variable from SWR.mat
%       - M                 M variable from SWR.mat
%       - epoch             Epoch of the whole session (intervalSet)
%       - TotalNoiseEpoch   Noise epoch (intervalSet)
%
% NOTES:
%
%   Written by Samuel Laventure - 2021/12
%      
%==========================================================================

% prepare ripples (split in two parts)
epoch_is = intervalSet(Start(subset(epoch,1)),End(subset(epoch,length(End(epoch)))));
split = regIntervals(epoch_is,2);
stage{1} = nrem;
stage{2} = wake;

for i=1:2
    ep{1} = Start(split{i});
    ep{2} = End(split{i});
    sess{i} = intervalSet(ep{1}(1),ep{2}(end));
%     
%     epnoise{1} = Start(splitnoise{i});
%     epnoise{2} = End(splitnoise{i});
%     sessnoise{i} = intervalSet(epnoise{1}(1),epnoise{2}(end));

    sess{i} = and(sess{i},stage{1});
        
    % set ripples per stage
    ripsess{i} = and(RipplesEpoch,sess{i});
    st_ripsess = Start(ripsess{i});
    ripnrem{i} = and(RipplesEpoch,stage{i});
    st_ripstg = Start(ripnrem{i});
    st_ripall = Start(RipplesEpoch);
    void=[]; ii=1;
    for irip=1:length(st_ripsess)
        if ~isempty(find(st_ripsess(irip)==st_ripall))
            rip_idx(irip) = find(st_ripsess(irip)==st_ripall);
        else
            void(ii) = irip;
            ii=ii+1;
        end
    end
    if exist('void','var') && ~isempty(void)
        rip_idx(void) = [];
    end
    
    % density
    %    all
    sessdur = sum(End(sess{i})-Start(sess{i})) /1e4;
    den(i) = length(st_ripsess)/sessdur; 
    %    stages
    stgdur = sum(End(stage{i})-Start(stage{i}))/1e4;
    dstg(i) = length(st_ripstg)/stgdur; 
    
    % waveforms
    if i==1
        en = End(sess{i});
        limit = en(end)/1e4;
        id_lim = find(ripples(:,2)<limit,1,'last');
        Tpart{i} = T(1:id_lim,:);
    else
        Tpart{i} = T(id_lim+1:end,:);
    end
    Tstg{i} = T(rip_idx,:);
    
    clear epnoise ep st_ripstg st_ripsess st_ripall rip_idx
end


supertit = ['ID FIGURE - RIPPLES'];
figH = figure('Color',[1 1 1], 'rend','painters','pos', ...
    [10 10 1400 1000],'Name', supertit, 'NumberTitle','off');
    % set axes position
    axWave = axes('position', [.05 .7 .6 .24]);
    axDen = axes('position', [.725 .7 .25 .24]);
    axWstg = axes('position', [.05 .37 .6 .24]);
    axDstg = axes('position', [.725 .37 .25 .24]);
    axAmp = axes('position', [.05 .05 .25 .24]);
    axDur = axes('position', [.385 .05 .25 .24]);
    axFreq = axes('position', [.725 .05 .25 .24]);

    axes(axWave)
%         shadedErrorBar([],M(:,2),M(:,3),'-b',1);
        p1=plot(mean(Tpart{1})); hold on
        p2=plot(mean(Tpart{2})); hold on
        p3=plot(mean(T)); 
        xlabel('Time (ms)')   
        title({'Average ripple','Session divided in 2 equal parts (NREM only)'});      
        xlim([1 size(T,2)])
        set(gca, 'Xtick', 1:25:size(T,2),...
                    'Xticklabel', num2cell([floor(T(1,1)*1000):20:ceil(T(1,end)*1000)])) 
        legend([p1 p2 p3],{'pre','post','all'})
        makepretty_erc
        
    axes(axDen)
        b=bar(den','FaceColor','flat');
        b.CData(1,:) = [0 0 1];
        b.CData(2,:) = [1 0 0];
        b.FaceAlpha = 0.5;
        title({'Density'})
        set(gca,'xticklabel',{'pre','post'})
        ylabel('rip/sec')
        makepretty_erc
        
    axes(axWstg)
%         shadedErrorBar([],M(:,2),M(:,3),'-b',1);
        p1=plot(mean(Tstg{1})); hold on
        p2=plot(mean(Tstg{2}));
        xlabel('Time (ms)') 
        title({'Average ripple','NREM vs Wake'});     
        xlim([1 size(T,2)])
        set(gca, 'Xtick', 1:25:size(T,2),...
                    'Xticklabel', num2cell([floor(T(1,1)*1000):20:ceil(T(1,end)*1000)])) 
        legend([p1 p2 p3],{'NREM','Wake'})
        makepretty_erc
        
    axes(axDstg)
        b=bar(dstg','FaceColor','flat');
        b.CData(1,:) = [0 0 1];
        b.CData(2,:) = [1 0 0];
        b.FaceAlpha = 0.5;
        title({'Density - NREM vs Wake'})
        set(gca,'xticklabel',{'NREM','Wake'})
        ylabel('rip/sec')
        makepretty_erc    
        
    axes(axAmp)
        histogram(ripples(:,6));        
        title('Amplitude')
        makepretty_erc
        
    axes(axDur)
        histogram(ripples(:,4)); 
        title('Duration')
        makepretty_erc
        
    axes(axFreq)
        histogram(ripples(:,5));
        title('Frequency')
        makepretty_erc
        
%- save picture
pathOut = [pwd '/Ripples/' date '/'];
if ~exist(pathOut,'dir')
    mkdir(pathOut);
end
output_plot = 'IDFigure_ripple.png';
fulloutput = [pathOut output_plot];
print('-dpng',fulloutput,'-r300');     
   
        