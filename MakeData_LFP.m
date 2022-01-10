% MakeData_LFP
% 23.10.2017 (KJ & SB)
%
% Processing: 
%   - generate LFP data, saved in .mat files
%
%
%   see makeData, makeDataBulbe


function SessLength = MakeData_LFP(foldername)

%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end

%load InfoLFP
disp(' '); disp('LFP Data')
load(fullfile(foldername,'LFPData','InfoLFP.mat'), 'InfoLFP');


%% Create LFPs
disp(' ');
disp('...Creating LFPData.mat')
try
    for i=1:length(InfoLFP.channel)
        if ~exist(['LFPData/LFP' num2str(InfoLFP.channel(i)) '.mat'],'file') %only LFP signals

            disp(['loading and saving LFP' num2str(InfoLFP.channel(i)) ' in LFPData...']);
            % FMA toolbox function to load LFP
            LFP_temp = GetLFP(InfoLFP.channel(i));
            %data to tsd
            LFP = tsd(LFP_temp(:,1)*1E4, LFP_temp(:,2));
            SessLength = max(LFP_temp(:,1));
            %save
            save([foldername '/LFPData/LFP' num2str(InfoLFP.channel(i))], 'LFP');
            clear LFP LFP_temp
        end
    end
    disp('Done')
catch
    disp('problem for lfp')
    
end
clear LFP InfoLFP

end




