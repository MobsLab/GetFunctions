% FindNoiseEpoch_SleepScoring
% 21.11.2017 SB
%
%  [Epoch,TotalNoiseEpoch,SubNoiseEpoch,Info]=FindNoiseEpoch_SleepScoring(channel_hpc, foldername)
%
% This function calculates noise epochs based on 4 different criteria
%   - Noise in the 18-20Hz band
%   - Ground noise
%   - User defined threshold on LFP amplitude
%   - User defined epochs of noise
% 
%%INPUT
% foldername        : location of data & save location
% channel_hpc       : HPC channel, spectrum will be calculated if necessary
% user_confirmation (optional) :  0 to skip the user confirmation, 1 otherwise
%
%
%%OUTPUT 
% Epoch             : epoch with no noise
% TotalNoiseEpoch   : epoch with all the noise
% SubNoiseEpoch     : structure with all different noise epochs
% Info              : structure with all thresholds used
%
% adapted from FindNoiseEpoch
%


function [Epoch,TotalNoiseEpoch,SubNoiseEpoch,Info]=FindNoiseEpoch_SleepScoring(channel_hpc, varargin)

%% Check Inputs
if nargin < 1
    error('Incorrect number of parameters.');
end


% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'user_confirmation'
            user_confirmation = varargin{i+1};
            if user_confirmation~=0 && user_confirmation ~=1
                error('Incorrect value for property ''user_confirmation''.');
            end
        case 'foldername'
            foldername = varargin{i+1};% foldername = lower(varargin{i+1});
        case 'recompute'
            recompute = varargin{i+1};
            if recompute~=0 && recompute ~=1
                error('Incorrect value for property ''recompute''.');
            end
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('user_confirmation','var')
    user_confirmation=1;
end
if ~exist('foldername','var')
    foldername = pwd;
elseif foldername(end)~=filesep
    foldername(end+1) = filesep;
end
%recompute?
if ~exist('recompute','var')
    recompute=0;
end

%check if already exist
if ~recompute
    if exist('NoiseEpoch.mat','file')==2
        disp('Noise is already computed')
        load('NoiseEpoch.mat');
        return
    end
end

%% Initiation
scrsz = get(0,'ScreenSize');

% params
HighNoiseThresh = 3E5; % default value for power 18-20Hz
GndNoiseThresh = 3E6; % default value for power <2Hz

% Get HPC spectrum
if ~(exist([foldername '/' 'H_Low_Spectrum.mat'], 'file') == 2)
    LowSpectrumSB(foldername, channel_hpc,'H');
end
load(strcat(foldername, '/H_Low_Spectrum.mat'))
fH = Spectro{3};
tH = Spectro{2};
SpH = Spectro{1};
TotalEpoch = intervalSet(0*1e4,tH(end)*1e4);

% Low and high frequency bands
HighSp = SpH(:,fH<=20 & fH>=18);
NoiseTSD = tsd(tH*1E4,mean(HighSp,2));
LowSp = SpH(:,fH<=2);
GndNoiseTSD = tsd(tH*1E4,mean(LowSp,2));


%% Make main figure
disp('... Finding Noisy Epochs in LFP.');
fig_Noise = figure('color',[1 1 1],'Position',[2 scrsz(4) scrsz(3) scrsz(4)/1.5]);
subplot(4,1,1)
imagesc(tH,fH,10*log10(SpH)'), axis xy,
title('Global Spectrogramm : determine noise periods');


%% High frequency noise
Ok_HighFreq = 'n';
while ~strcmpi(Ok_HighFreq,'y')
    
    % display spectrum
    subplot(4,1,2), hold off,
    imagesc(tH,fH(fH<=20 & fH>=18),10*log10(HighSp)'), axis xy,
    
    % calucate noise from HighNoiseThresh
    HighNoiseEpoch = thresholdIntervals(NoiseTSD,HighNoiseThresh,'Direction','Above');
    
    % display values and noise epochs
    hold on, plot(Range(NoiseTSD,'s'),Data(NoiseTSD)/max(Data(NoiseTSD))+19,'b')
    hold on, plot(Range(Restrict(NoiseTSD,HighNoiseEpoch),'s'),Data(Restrict(NoiseTSD,HighNoiseEpoch))/max(Data(NoiseTSD))+19,'*w')
    title(['18-20Hz Spectrogramm, determined High Noise Epochs are in white (total=',num2str(floor(10*sum(Stop(HighNoiseEpoch,'s')-Start(HighNoiseEpoch,'s')))/10),'s)']);
    
    %can skip this step if user_confirmation==0
    if user_confirmation % user can change HighNoiseThresh manually
        Ok_HighFreq = input('--- Are you satisfied with High Noise Epochs (y/n)? ','s');
        if ~strcmpi(Ok_HighFreq,'y')
            HighNoiseThresh =  input(['Give a new High Noise Threshold (Current=',num2str(HighNoiseThresh), ') : ']);
        end
    else
        Ok_HighFreq='y';
    end
    
end


%% Low frequency noise - generally grounding problem

% Stim
% -------------------------------------------------------------
% In case there is an issue with the stim digital channel,
% false stim will be treated as noise. Comment the IF section below 
% and make sure to set StimNoiseEpoch to intervalSet([],[]);

if exist('behavResources.mat')>0
    load('behavResources.mat','TTLInfo');
    
    if exist('TTLInfo')
        if isfield(TTLInfo,'StimEpoch')
            StimNoiseEpoch= intervalSet(Start(TTLInfo.StimEpoch), Start(TTLInfo.StimEpoch)+0.2*1E4);
        else
            StimNoiseEpoch= intervalSet([],[]);
        end
    else
        StimNoiseEpoch= intervalSet([],[]);
    end
else
    StimNoiseEpoch= intervalSet([],[]);
end

% StimNoiseEpoch= intervalSet([],[]);
% ----------------------------------------------------------

Ok_LowFreq='n';
while ~strcmpi(Ok_LowFreq,'y')

    % display spectrum
    subplot(4,1,3), hold off,
    imagesc(tH,fH(fH<=2),10*log10(LowSp)'), axis xy
    
    % calucate noise from GndNoiseThresh
    GndNoiseEpoch = thresholdIntervals(GndNoiseTSD,GndNoiseThresh,'Direction','Above');
    
    % display values and noise epochs
    hold on, plot(Range(GndNoiseTSD,'s'),Data(GndNoiseTSD)/max(Data(GndNoiseTSD))+1,'b')
    hold on, plot(Range(Restrict(GndNoiseTSD,GndNoiseEpoch),'s'),Data(Restrict(GndNoiseTSD,GndNoiseEpoch))/max(Data(GndNoiseTSD))+1,'*w')
    title(['0-2Hz Spectrogramm, determined Ground Noise Epochs are in white (total=',num2str(floor(10*sum(Stop(GndNoiseEpoch,'s')-Start(GndNoiseEpoch,'s')))/10),'s)']);
    
     %can skip this step if user_confirmation==0
    if user_confirmation
        % user can change GndNoiseThresh manually
        Ok_LowFreq = input('--- Are you satisfied with Ground Noise Epochs (y/n)? ','s');
        if ~strcmpi(Ok_LowFreq,'y')
            GndNoiseThresh = input(['Give a new High Noise Threshold (Current=',num2str(GndNoiseThresh), ') : ']);
        end
    else
        Ok_LowFreq='y';
    end
end


%% Threshold to define noise and weird epochs
subplot(4,1,4), hold off,

% Load HPC data for ploting and thresholding
load([foldername '/LFPData/LFP' num2str(channel_hpc) '.mat'])
plot(Range(LFP,'s'),Data(LFP))
xlim([0 max(Range(LFP,'s'))])

%user confirmation
if user_confirmation
    Do_Thresh=input('Do you want to add a ThresholdedNoiseEpoch (y/n)? ','s');
else
    Do_Thresh='n';
    disp('no ThresholdedNoiseEpoch step')
end
    
% if user wants to put the threshold manually
if strcmpi(Do_Thresh,'y')
    Ok_Thresh='n';
    while strcmpi(Ok_Thresh,'n')
        
        % plot data
        subplot(4,1,4), hold off,
        plot(Range(LFP,'s'),Data(LFP))
        title(['Please place upper bound for threshold'])
        
        % User inputs superior bound
        [~,ThresholdedNoiseEpochThresh] = ginput(1);
        
        % calculate noise from ThresholdedNoiseEpochThresh
        ThresholdedNoiseEpoch = thresholdIntervals(LFP,ThresholdedNoiseEpochThresh,'Direction','Above');
        ThresholdedNoiseEpoch = mergeCloseIntervals(ThresholdedNoiseEpoch,5E4);
        hold on, plot(Range(Restrict(LFP,ThresholdedNoiseEpoch),'s'),Data(Restrict(LFP,ThresholdedNoiseEpoch)),'r')
        
        if user_confirmation
            % check if user is satisfied or wants to redefine
            Ok_Thresh=input('--- Are you satisfied with Thresholded Noise Epochs (y/n -- k for keyboard)? ','s');
            if Ok_Thresh=='k'
                disp('Type "dbcont" to continue...')
                keyboard
            end
        else
            Ok_Thresh='y';
        end
    end
    
else
    % defined as empty if user doesn't define epochs
    ThresholdedNoiseEpoch = intervalSet([],[]);
    ThresholdedNoiseEpochThresh = NaN;
end


%% Manually add extra noise epochs
%user confirmation
if user_confirmation
    Do_Weird=input('Do you want to add a WeirdNoiseEpoch (y/n)? ','s');
else
    Do_Weird='n';
end

% if user wants to put the threshold manually
if strcmpi(Do_Weird,'y')
% if Do_Weird(Do_Thresh,'y') corrected SB Jan 2018
    CheckWeirdEpoch=0; % this variable is set to 1 only after a correct format of times is entered
    while CheckWeirdEpoch==0
        disp('Enter start and stop time (s) of WeirdNoise')
        disp('(e.g. [1,200, 400,500] to put 1-200s and 400-500s periods into noise)')
        WeirdNoise=input(': ');
        CheckWeirdEpoch = issorted(WeirdNoise);
        if CheckWeirdEpoch
            WeirdNoiseEpoch = intervalSet(WeirdNoise(1:2:end)*1E4, WeirdNoise(2:2:end)*1E4);
        else
            disp('')
            disp('Incorrect time stamps')
        end
    end
else
    WeirdNoiseEpoch=intervalSet([],[]);
end


%% Close and generate output
close(fig_Noise)

% Define total noise and epoch with no noise
TotalNoiseEpoch = or(or(or(GndNoiseEpoch,HighNoiseEpoch),or(WeirdNoiseEpoch,ThresholdedNoiseEpoch)),...
                        StimNoiseEpoch);
Epoch = TotalEpoch-TotalNoiseEpoch;

% Group the parameters together
Info.GndNoiseThresh=GndNoiseThresh;
Info.HighNoiseThresh=HighNoiseThresh;
Info.ThresholdedNoiseEpochThresh=ThresholdedNoiseEpochThresh;

% Group the different NoiseEpochs together
SubNoiseEpoch.GndNoiseEpoch=GndNoiseEpoch;
SubNoiseEpoch.HighNoiseEpoch=HighNoiseEpoch;
SubNoiseEpoch.WeirdNoiseEpoch=WeirdNoiseEpoch;
SubNoiseEpoch.ThresholdedNoiseEpoch=ThresholdedNoiseEpoch;
SubNoiseEpoch.StimNoiseEpoch=StimNoiseEpoch;



end


