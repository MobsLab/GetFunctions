%FindOscillationEpochNREM
% 04.12.2017 KJ
% 
% [features, Namesfeatures, EpochSleep, noiseEpoch] = FindNREMfeatures(varargin)
%
%%INPUTS
% epoch (optional):             Epoch of restriction - default WholeEpoch 
% std_thresh (optional)         threshold of detection for the peaks - default 2 fold std 
% isi_thresh (optional)         threshold for the burst detection in sec - default 1s 
% spindle_band (optional)       spindle band detection in Hz - default [2 20] 
% 
% 
%%OUTPUT
% features:  
% Namesfeatures:
% EpochSleep:
% noiseEpoch:
% scoring: 
%
% see FindNREMEpochSleepsML 
%

function [OsciEpoch, WholeEpoch, SpindlesEpoch, BurstEpoch] = FindOscillationEpochNREM(LFP, varargin)

if nargin<1 || mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

%% INITIATION
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
        case 'isi_thresh'
            isi_thresh = lower(varargin{i+1});
            if isi_thresh<=0
                error('Incorrect value for property ''isi_thresh''.');
            end
        case 'spindle_band'
            spindle_band = lower(varargin{i+1});
            if length(spindle_band)~=2
                error('Incorrect value for property ''spindle_band''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
rg=Range(LFP);
WholeEpoch=intervalSet(rg(1),rg(end)); clear rg
if ~exist('Epoch','var')
    Epoch=WholeEpoch;
end
Epoch=CleanUpEpoch(Epoch);

if ~exist('std_thresh','var')
    std_thresh=2;
end
if ~exist('isi_thresh','var')
    isi_thresh=1;
end
if ~exist('spindle_band','var')
    spindle_band=[2 20];
end


%% Find oscillations
%burst of peaks
tpeaks = FindExtremePeaks(LFP, 'std_thresh',std_thresh, 'epoch', dropShortIntervals(Epoch,1.5E4));
burst_peak = burstinfo(Range(tpeaks)/1e4, isi_thresh);
BurstEpoch = intervalSet(burst_peak.t_start*1E4, burst_peak.t_end*1E4);
%spindles
SpindlesEpoch = FindSpindlesKJ(LFP, Epoch, 'frequency_band', spindle_band);


%% OUTPUT EPOCHS DEFINITION
OsciEpoch = or(SpindlesEpoch, BurstEpoch);



end


