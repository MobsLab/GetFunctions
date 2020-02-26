%GenChannelsToAnalyse
% 02.11.2017 SB
% - generate ChannelsToAnalyse
%
%

res = pwd; % 01.04.2018 Dima

%create folder
if ~exist([res '/ChannelsToAnalyse'],'dir') % 01.04.2018 Dima
    mkdir('ChannelsToAnalyse');
end


structure_list = {'Bulb_sup','Bulb_deep', 'dHPC_sup','dHPC_deep','dHPC_rip', 'PaCx_sup','PaCx_deep', 'PFCx_sup','PFCx_deltasup','PFCx_deep','PFCx_deltadeep','PFCx_spindle', ...
    'MoCx_sup', 'MoCx_deep', 'AuCx', 'AuTh', 'NRT', 'Amyg','PiCx','InsCx','TaeniaTecta','EMG','EKG','VLPO'};
disp(' ');


%check if some channels already exists
do_display=0;
for stru=1:length(structure_list)
    try
        temp = load(['ChannelsToAnalyse/', structure_list{stru}, '.mat']);
        if isempty(temp.channel)
            default_answer{stru} = '[ ]';
        else
            default_answer{stru} = num2str(temp.channel);
        end
        do_display = 1;
    catch
        default_answer{stru} = 'NaN';
    end
end
if do_display
    disp('ChannelsToAnalyse already defined for some channels, check and add');
end

%formulary

% Modified by SB 22/01/2018 to accomodate the large number of inputs
%answer = inputdlg(['Exemple undefined','Example empty', structure_list], 'ChannelToAnalyse', 1, ['NaN','[ ]', default_answer]);
AddOpts.Resize = 'on';
AddOpts.WindowStyle = 'normal';
AddOpts.Interpreter = 'tex';
answer = inputdlgcol(['Exemple undefined','Example empty', structure_list], 'ChannelToAnalyse', 1, ['NaN','[ ]', default_answer],AddOpts,3);

%save channels in ChannelsToAnalyse
for stru=1:length(structure_list)
    channel = str2double(answer{stru+2});

    if strcmp(answer{stru+2},'[ ]')%empty
        channel = [];
    end

    if (~isempty(channel) && ~isnan(channel)) || isempty(channel)
        disp(['Saving ch', answer{stru+2}, ' for ',structure_list{stru}, ' in ChannelsToAnalyse'])
        save(['ChannelsToAnalyse/',structure_list{stru},'.mat'],'channel');
    end
end



