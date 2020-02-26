%FindOscillationEpochNREM
% 04.12.2017 KJ
% 
% [features, Namesfeatures, EpochSleep, noiseEpoch] = FindNREMfeatures(varargin)
%
%%INPUTS
% LFP:                      tsd - LFP 
% Epoch (optional):         intervalSet - Epoch of restriction
% std_thresh (optional):    double - coefficient to determine threshold from std
%
%
%%OUTPUT
% tPeaks:  
% t_waveP:
% t_waveT:
% burst:
%
% see FindOscillationEpochNREM 
%


function [tPeaks, t_waveP, t_waveT, burst] = FindExtremePeaks(LFP, varargin)

if nargin<1 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

%% INITIATION
disp('Running FindOscillationEpochNREM.m')
% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'epoch'
            Epoch = lower(varargin{i+1});
        case 'std_thresh'
            std_thresh = lower(varargin{i+1});
            if std_thresh<=0
                error('Incorrect value for property ''std_thresh''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
rg=Range(LFP);
if ~exist('Epoch','var')
    Epoch=intervalSet(rg(1),rg(end));
end
Epoch=CleanUpEpoch(Epoch);

if ~exist('std_thresh','var')
    std_thresh=2;
end


%resample
LFP=ResampleTSD(LFP,250);
% Std, for 2Hz frequency step [2-20Hz], for each subset of Epoch
disp('Calculating variance...');
for j=1:10
    Filt_EEGd = [];
    for i=1:length(Start(Epoch))
        signal_epoch=Restrict(LFP,subset(Epoch,i));
        % concatenate filtered signal
        try
            freq_range = [2*j 2*(j+1)];
            Filt_EEGd = [Filt_EEGd ; Data(FilterLFP(signal_epoch, freq_range, 512))];
        end
    end
    % std for each freq band
    std_freq(j)=std((Filt_EEGd));
end
        
        
t_T=[]; t_P=[];

%% loop over subset of epochs
for i=1:length(Start(Epoch))

    signal_epoch=Restrict(LFP,subset(Epoch,i));
    if ~isempty(Range(signal_epoch))
        disp([num2str(round(i*100/length(Start(Epoch)))) '% ...'])
        for j=1:10
            try
                Filt_EEGd = FilterLFP(signal_epoch, [2*j 2*(j+1)], 256);
            catch
                Filt_EEGd = FilterLFP(signal_epoch, [2*j 2*(j+1)], 128);
            end
            
            %arrays
            eegd = Data(Filt_EEGd)';
            td = Range(Filt_EEGd,'s')';
            %diff
            de = diff(eegd);
            de1 = [de 0];
            de2 = [0 de];

            %finding peaks
            upPeaksIdx = find(de1 < 0 & de2 > 0);
            downPeaksIdx = find(de1 > 0 & de2 < 0);

            PeaksIdx = [upPeaksIdx downPeaksIdx];
            PeaksIdx = sort(PeaksIdx);
            Peaks = eegd(PeaksIdx);

            t_peaks=td(PeaksIdx);
            % relative thresshold
            DetectThresholdP =  mean(Data(Filt_EEGd)) + std_thresh*std_freq(j)*log(j+2);
            DetectThresholdT = -mean(Data(Filt_EEGd)) - std_thresh*std_freq(j)*log(j+2);

            % find peaks above/below std*std_thresh
            t_peaksT = t_peaks(Peaks<DetectThresholdT);
            t_peaksP = t_peaks(Peaks>DetectThresholdP);

            try
                t_T = [t_T; [t_peaksT',(2*j+1)*ones(length(t_peaksT),1)]];
                t_P = [t_P; [t_peaksP',(2*j+1)*ones(length(t_peaksP),1)]];
            catch
                disp('line 303 t_T/t_P');
                keyboard
                t_T = zeros(size(t_peaksT',1),size(t_peaksT',2));
                t_T(:,1) = t_peaksT';
                t_T(:,2) = 2*(j+1)*ones(length(t_peaksT),1);

                t_P = zeros(size(t_peaksP',1),size(t_peaksP',2));
                t_P(:,1) = t_peaksP';
                t_P(:,2) = 2*(j+1)*ones(length(t_peaksP),1);
            end
        end
    end
end

% TERMINATION
[~,idx] = sort(t_T(:,1));
tdeltaT = [t_T(idx,1)*1E4 t_T(idx,2)];
t_waveT = tdeltaT(tdeltaT(:,1)+1E4<rg(end)&tdeltaT(:,1)-1E4>0,:);
t_waveT = tsd(t_waveT(:,1),t_waveT(:,2));

[~,idx] = sort(t_P(:,1));
tdeltaP = [t_P(idx,1)*1E4 t_P(idx,2)];
t_waveP = tdeltaP(tdeltaP(:,1)+1E4<rg(end)&tdeltaP(:,1)-1E4>0,:);
t_waveP = tsd(t_waveP(:,1),t_waveP(:,2));

[tps,id] = sort([Range(t_waveP);Range(t_waveT)]);
Mat = [Data(t_waveP);Data(t_waveT)];

% burstinfo_2.m
tPeaks = tsd(tps,Mat(id,:));
burst = burstinfo_2(Range(tPeaks,'s'), 5,Inf,3);


end
