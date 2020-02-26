% FindRipplesSB - Find Ripples in LFP signals
%
% 02.11.2017 SB
%
%
%%  USAGE
% [Rip,InputInfo,meanVal,stdVal] = FindRipplesSB(LFP, InputInfo)
%
%
%%  INFOS 
% This code was modified from FindRipplesKarimSB in september 2016 by SB
% Modification 1 : Calculate SD over whole period and not local epochs
% Modification 2 : Automatically creates an evt file for looking at which
% ripples are detected i, neuroscope
%
%
%%  INPUT
%
%
% LFP           LFP signal where ripples are to be detected (HPCrip)
%
%
% INPUTINFO     structure:
%
%       InputInfo.Epoch = SWSEpoch;
%           Epoch (opt)    Epoch/IntervalSet where detection is retricted
%                     default: no restriction
%       InputInfo.thresh = [5,7];
%           thresh (opt)   Thresholds in std [low_threshold high_threshold]
%                           - high_threshold is to detect a ripple
%                           - low_threshold is to find start and end of the ripples
%                             default: [5,7]
%       InputInfo.duration = [0.01,0.02,0.2];
%           duration (opt) Duration parameters
%                           [min interval - min ripple dur -max ripple duration]
%                           default: [30 30 100]
%       InputInfo.MakeEventFile = 1;
%           MakeEventFile (opt) If you want to make a file with neuroscope events
%       InputInfo.EventFileName = 'HPCRipplesSleep';
%           MakeEventFile (opt) If you want to give a name for the event
%                               file, the default is HPCRipples.evt.s00
%       InputInfo.SaveRipples = 1
%           SaveRipples (opt) If you want to save ripple events
%       InputInfo.MeanStdVals
%           MeanStdVals (opt) if you want to use values calculated
%           independantly to se the threshold for ripple det
%
%
%% OUTPUT
%
%    Ripples_tmp    list of ripples events (timestamps)
%                   [start_t peak_t end_t]
%    usedEpoch      Epoch/IntervalSet (same as input)
%
%
%%
%  NOTE
%    thresh is [5 7] by default and it is restrictive, it can be [2 5] if the
%    amplitude of the HPC signal is not high enough.
%
%  SEE
%
%    See also FindRipples, FindRipplesKarim, FindRipplesKarimSB
 
 
function [Ripples,InputInfo,meanVal,stdVal] = FindRipplesSB(LFP, InputInfo)
 
 
if ~isfield(InputInfo,'Epoch')
    rg = Range(LFP);
    InputInfo.Epoch = intervalSet(rg(1),rg(end));
end
 
if ~isfield(InputInfo,'thresh')
    InputInfo.thresh = [5 7]; % default [2 5] , restrictive [5,7]
end
 
if ~isfield(InputInfo,'duration')
    InputInfo.duration = [30 30 100]; % default [2 5] , restrictive [5,7]
end
InputInfo.duration = InputInfo.duration*10; %in ts
 
if ~isfield(InputInfo,'FreqBand')
    InputInfo.FreqBand = [120 200]; % default [2 5] , restrictive [5,7]
end
 
if ~isfield(InputInfo,'MatName')
    InputInfo.MatName = 'Ripples'; % default [2 5] , restrictive [5,7]
end
 
 
% Calculate overall SD
FiltLFP = FilterLFP(Restrict(LFP,InputInfo.Epoch), InputInfo.FreqBand, 1024);
%signal_squared = Data(FiltLFP).^2;
signal_squared = abs(Data(FiltLFP));
meanVal = mean(signal_squared);
stdVal = std(signal_squared);
 
if isfield(InputInfo,'MeanStdVals')
    meanVal = InputInfo.MeanStdVals(1);
    stdVal = InputInfo.MeanStdVals(2);
end
 
SquaredFiltLFP = tsd(Range(FiltLFP),signal_squared-meanVal);
 
% Detect using low threshold
PotentialRippleEpochs = thresholdIntervals(SquaredFiltLFP, InputInfo.thresh(1)*stdVal);
 
% Merge ripples that are very close together
PotentialRippleEpochs = mergeCloseIntervals(PotentialRippleEpochs, InputInfo.duration(1));
 
% Get rid of ripples that are too short
PotentialRippleEpochs = dropShortIntervals(PotentialRippleEpochs, InputInfo.duration(2));
 
% Get rid of ripples that are too long
PotentialRippleEpochs = dropLongIntervals(PotentialRippleEpochs, InputInfo.duration(3));
 
ToKeep = [];
for k=1:length(Start(PotentialRippleEpochs))
    [maxval,~] = max(Data(Restrict(SquaredFiltLFP, subset(PotentialRippleEpochs,k))));
    if maxval >= InputInfo.thresh(2) * stdVal
        ToKeep = [ToKeep,k];
        tps = Range(Restrict(FiltLFP,subset(PotentialRippleEpochs,k)),'s');
        [~,ind] = min(Data(Restrict(FiltLFP,subset(PotentialRippleEpochs,k))));
        PeakVal(k) = tps(ind);
    end
end
 
FinalRipplesEpoch = subset(PotentialRippleEpochs,ToKeep);
 
if not(isempty(Start(FinalRipplesEpoch,'s')))
    Ripples(:,1) = Start(FinalRipplesEpoch,'s');
    Ripples(:,2) = PeakVal(ToKeep);
    Ripples(:,3) = Stop(FinalRipplesEpoch,'s');
     
     
    % Save events to .evt file for visualization in Neuroscope
    if isfield(InputInfo,'MakeEventFile')
        if InputInfo.MakeEventFile == 1
            for i = 1:length(Ripples(:,1))
                event1.time(2*i-1) = Ripples(i,1);
                event1.time(2*i) = Ripples(i,3);
                event1.description{2*i-1} = 'ripstart';
                event1.description{2*i} = 'ripstop';
            end
             
            if isfield(InputInfo, 'EventFileName')
                delete([InputInfo.EventFileName])
                SaveEvents([InputInfo.EventFileName],event1)
                disp(['Ripples saved to' InputInfo.EventFileName])
            else
                delete('HPCRipples.evt.s00')
                SaveEvents('HPCRipples.evt.s00',event1)
                disp('Ripples saved to HPCRipples.evt.s00')
            end
        end
    else
        InputInfo.MakeEventFile = 0;
    end
     
else
    Ripples(:,1) = NaN;
    Ripples(:,2) = NaN;
    Ripples(:,3) = NaN;
end
 
end


