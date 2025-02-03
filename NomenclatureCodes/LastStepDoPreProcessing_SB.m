
%% File by file preparation for concatenation
clear all
load('ExpeInfo.mat')
BaseFileName = ['M' num2str(ExpeInfo.nmouse) '_' ExpeInfo.date '_' ExpeInfo.SessionType];
FinalFolder = cd;



switch ExpeInfo.PreProcessingInfo.IsThereEphys
    case 'Yes'
        
        %% ephys
        for f = 1:length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys)
            
            %% go to folder
            cd(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f})
            disp(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f})
            
            %% Get the true time of the beginning and the end of the folders
            
            StopFile=dir('*supply.dat');
            ind=strfind(StopFile.date,':');
            TimeEndRec_Allfiles(f,1:3)=[str2num(StopFile.date(ind(1)-2:ind(1)-1)),str2num(StopFile.date(ind(1)+1:ind(2)-1)),str2num(StopFile.date(ind(2)+1:end))];
            
            %Sanity check :  the foldername should finish with the time int TimeBeginRec
            FolderNameTime = (ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}(end-5:end));
            TimeBeginRec_Allfiles(f,1:3)=[str2num(FolderNameTime(1:2)),str2num(FolderNameTime(3:4)),str2num(FolderNameTime(5:6))];
            
            
            disp(['File starts at ' num2str(TimeBeginRec_Allfiles(f,1:3)) ' and ends at ' num2str(TimeEndRec_Allfiles(f,1:3))])
            
            %% here is the place where we check if the ephys is the right length comapred to the behav resources - to do
            
            
            %% copy ephys files that are ref subtracted and merged
            if ExpeInfo.PreProcessingInfo.RefDone{f} && ExpeInfo.PreProcessingInfo.MergeDone{f}
                disp('file is merged and ref subtracted - copying ...')
                
                % Create the xml
                WriteExpeInfoToXml(ExpeInfo)
                
                
                % copy the .dat and the .xml
                movefile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, ['amplifier_M' num2str(ExpeInfo.nmouse) '.dat']),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.dat']));
                copyfile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, 'amplifier.xml'),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.xml']));
                
                
            elseif  ExpeInfo.PreProcessingInfo.RefDone{f}==0 && ExpeInfo.PreProcessingInfo.MergeDone{f}
                disp('file is merged - subtracting ref ...')
                
                
                % Create the xml
                WriteExpeInfoToXml(ExpeInfo)
                
                % subtract the reference
                RefChannel = ExpeInfo.ChannelToAnalyse.Ref;
                % do subtraction on all the wideband channels
                ChanToSub = [0 : ExpeInfo.PreProcessingInfo.NumWideband-1];
                ChanToSub(ChanToSub==RefChannel) = [];
                % special case for breathingLastStepDoPreProcessing_SB
                if isfield(ExpeInfo.ChannelToAnalyse,'Respi')
                    ChanToSub(ChanToSub==ExpeInfo.ChannelToAnalyse.Respi) = [];
                end
                ChanToSave = [0 :ExpeInfo.PreProcessingInfo.TotalChannels-1];
                ChanToSave(ChanToSub+1) = [];
                % Do the subtraction
                RefSubtraction_multi('amplifier.dat',ExpeInfo.PreProcessingInfo.TotalChannels,1,['M' num2str(ExpeInfo.nmouse)],ChanToSub,RefChannel,ChanToSave);
                
                disp(['file is merged and ref subtracted - copying ...'])
                % copy the file
                movefile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, ['amplifier_M' num2str(ExpeInfo.nmouse) '.dat']),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.dat']));
                copyfile([ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f} filesep 'amplifier.xml'],...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.xml']));
                
                
            elseif  ExpeInfo.PreProcessingInfo.RefDone{f} && ExpeInfo.PreProcessingInfo.MergeDone{f}==0
                
                disp(['file is ref subtracted - merging...'])
                % Create the xml
                WriteExpeInfoToXml(ExpeInfo)
                
                % Merge
                if exist(['amplifier_M' num2str(ExpeInfo.nmouse) '.dat'], 'file') == 2
                    movefile(['amplifier_M' num2str(ExpeInfo.nmouse) '.dat'], 'amplifier-wideband.dat');
                else
                    system('mv amplifier.dat amplifier-wideband.dat')
                end
                if ExpeInfo.PreProcessingInfo.NumAccelero>0
                    movefile('auxiliary.dat', 'amplifier-accelero.dat');
                end
                if ExpeInfo.PreProcessingInfo.NumDigChan>0
                    movefile('digitalin.dat', 'amplifier-digin.dat');
                end
                if ExpeInfo.PreProcessingInfo.NumAnalog>0
                    movefile('analogin.dat', 'amplifier-analogin.dat');
                end
                system('ndm_mergedat amplifier')
                
                disp('file is merged and ref subtracted - copying ...')
                % copy the file
                copyfile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, 'amplifier.dat'),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.dat']));
                copyfile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, 'amplifier.xml'),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.xml']));
                
                
            elseif  ExpeInfo.PreProcessingInfo.RefDone{f}==0 && ExpeInfo.PreProcessingInfo.MergeDone{f}==0
                
                disp('file is unpreprocessed - subtracting ref...')
                % Create the xml
                WriteExpeInfoToXml(ExpeInfo)
                
                
                % subtract the reference
                RefChannel = ExpeInfo.ChannelToAnalyse.Ref;
                % do subtraction on all the wideband channels
                ChanToSub = [0 : ExpeInfo.PreProcessingInfo.NumWideband-1];
                ChanToSub(ChanToSub==RefChannel) = [];
                % special case for breathing
                if isfield(ExpeInfo.ChannelToAnalyse,'Respi')
                    ChanToSub(ChanToSub==ExpeInfo.ChannelToAnalyse.Respi) = [];
                end
                ChanToSave = 0 :ExpeInfo.PreProcessingInfo.NumWideband-1;
                ChanToSave(ChanToSub+1) = [];
                % Do the subtraction
                RefSubtraction_multi('amplifier.dat',ExpeInfo.PreProcessingInfo.NumWideband,1,['M' num2str(ExpeInfo.nmouse)],ChanToSub,RefChannel,ChanToSave);
                
                disp('file is ref subtracted - merging...')
                % Merge
                movefile(['amplifier_M' num2str(ExpeInfo.nmouse) '.dat'], 'amplifier-wideband.dat');
                if ExpeInfo.PreProcessingInfo.NumAccelero>0
                    movefile('auxiliary.dat', 'amplifier-accelero.dat');
                end
                if ExpeInfo.PreProcessingInfo.NumDigChan>0
                    movefile('digitalin.dat', 'amplifier-digin.dat');
                end
                if ExpeInfo.PreProcessingInfo.NumAnalog>0
                    movefile('analogin.dat', 'amplifier-analogin.dat');
                end
                system('ndm_mergedat amplifier')
                
                disp('file is merged and ref subtracted - copying ...')
                % copy the file
                copyfile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, 'amplifier.dat'),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.dat']));
                copyfile(fullfile(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{f}, 'amplifier.xml'),...
                    fullfile(FinalFolder, [BaseFileName '-' sprintf('%02d',f) '.xml']));
                
            end
            cd(FinalFolder)
            
        end
        cd(FinalFolder)
        
        
        %% save the times
        TimeEndRec = TimeEndRec_Allfiles(end,:);
        TimeBeginRec = TimeBeginRec_Allfiles(1,:);
        save([FinalFolder filesep 'TimeRec.mat'],'TimeEndRec','TimeBeginRec','TimeEndRec_Allfiles','TimeBeginRec_Allfiles')
        
        %% What's this???
        copyfile([FinalFolder filesep BaseFileName '-' sprintf('%02d',f) '.xml'],...
            [FinalFolder filesep BaseFileName '.xml']);

        
        %% concatenate all the files
        if length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys)>1
            system(['ndm_concatenate ' BaseFileName])
        else
            movefile([FinalFolder filesep BaseFileName '-' sprintf('%02d',f) '.dat'],...
                [FinalFolder filesep BaseFileName '.dat']);
        end
        
        
        %% make lfp
        system(['ndm_lfp ' BaseFileName])
        
        %% create lfp and channels to analyse folders
        
        InfoLFP = ExpeInfo.InfoLFP;
        mkdir('LFPData')
        save('LFPData/InfoLFP.mat','InfoLFP')
        
        
        mkdir('ChannelsToAnalyse');
        if isfield(ExpeInfo,'ChannelToAnalyse')
            AllStructures = fieldnames(ExpeInfo.ChannelToAnalyse);
            for stru=1:length(AllStructures)
                channel = ExpeInfo.ChannelToAnalyse.(AllStructures{stru});
                save(['ChannelsToAnalyse/',AllStructures{stru},'.mat'],'channel');
            end
        end
        
        %% run the makeData scripts
        SetCurrentSession([BaseFileName '.xml'])
        
        SessLength = MakeData_LFP(FinalFolder);
        
        % This is SUPER dirty!! DO it again Sophie!!
        if length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys)==1
            %evt
            evt.time(1)=0;
            evt.time(2)=SessLength*1e4;

            evt.description{1}='beginning of';
            evt.description{2}='end of';

            CreateEvent(evt, [FinalFolder filesep BaseFileName], 'cat')
            movefile( [FinalFolder filesep BaseFileName '.evt.cat'],[FinalFolder filesep BaseFileName '.cat.evt'])
            
            global DATA
            DATA.events.time = evt.time';
            DATA.events.description = evt.description;

        end
        
        if ExpeInfo.PreProcessingInfo.NumAccelero>0
            MakeData_Accelero(FinalFolder)
        end
        
        if ExpeInfo.PreProcessingInfo.NumDigChan>0
            MakeData_DigitalChannels(FinalFolder)
        end
        
        
        tpsCatEvt = MakeData_CatEvents(FinalFolder);
        
        MakeData_RealTime(FinalFolder)
        
        
        
        %% Make TTLInfo
        cd(FinalFolder)
        if isfield(ExpeInfo,'DigID')
            MakeData_TTLInfo
        end
        
        %% if there are spikes
        if ExpeInfo.PreProcessingInfo.DoSpikes
            
            % Do subtraction if necessary
            if sum(ExpeInfo.SpikeGroupInfo.UseForElecSub)>0
                
                % get the electrodes to make the subtraction on
                ElecPerformSub = [];
                for sp = 1:length(ExpeInfo.SpikeGroupInfo.UseForElecSub)
                    if ExpeInfo.SpikeGroupInfo.UseForElecSub(sp) ==1
                        ElecPerformSub = [ElecPerformSub,str2num(ExpeInfo.SpikeGroupInfo.ChanNames{sp})];
                    end
                end
                
                
                % Old version
                % Get the electrodes which will eb averaged to make the subtraction
                %RefElec = str2num((ExpeInfo.SpikeGroupInfo.ElecsToSub));
                % Preform the subtraction
                %         AllChans = [0:ExpeInfo.PreProcessingInfo.TotalChannels-1];
                %         AllChans(ElecPerformSub+1) = [];
                %         RefSubtraction_multi_AverageChans([BaseFileName '.dat'],ExpeInfo.PreProcessingInfo.TotalChannels,1,'SpikeRef',ElecPerformSub,RefElec,AllChans);
                
                % New version with different reference channels
                LeftOverChannels = 0:ExpeInfo.PreProcessingInfo.TotalChannels-1;
                ToDel = [];
                numtet = 1;
                for tet = 1:length(ExpeInfo.SpikeGroupInfo.ChanNames)
                    if ~isempty(ExpeInfo.SpikeGroupInfo.ElecsToSub{tet})
                        ChannelsToPerfSub{numtet} = str2num(ExpeInfo.SpikeGroupInfo.ChanNames{tet});
                        ChannelsToAverageForSub{numtet} = str2num(ExpeInfo.SpikeGroupInfo.ElecsToSub{tet});
                        ToDel = [ToDel, str2num(ExpeInfo.SpikeGroupInfo.ChanNames{tet})];
                        
                        numtet =  numtet +1;
                    end
                end
                LeftOverChannels(ismember(LeftOverChannels,ToDel)) = [];
                
                RefSubtraction_GroupByGroup([BaseFileName '.dat'],ExpeInfo.PreProcessingInfo.TotalChannels,1,'SpikeRef', ...
                    ChannelsToPerfSub, ChannelsToAverageForSub, LeftOverChannels);
                system(['mv ' BaseFileName '_original.dat ' BaseFileName '.dat'])
                copyfile([BaseFileName '.xml'], [BaseFileName '_SpikeRef.xml'])
                
                
                % Do the preprcessing steps
                system(['ndm_hipass ' BaseFileName '_SpikeRef'])
                system(['ndm_extractspikes ' BaseFileName '_SpikeRef'])
                system(['ndm_pca ' BaseFileName '_SpikeRef'])
                
            else
                
                % Do the preprcessing steps
                system(['ndm_hipass ' BaseFileName])
                system(['ndm_extractspikes ' BaseFileName])
                system(['ndm_pca ' BaseFileName])
            end
            
        end
    
        
    case 'No'
        disp('No Ephys');
        
end


%% behaviour (Camera)
% First sort out times if they don't yet exist because tehre is no ephys
switch ExpeInfo.PreProcessingInfo.IsThereBehav
    case 'Yes'
        switch ExpeInfo.PreProcessingInfo.IsThereEphys
            case 'No'
                tps = 0;
                tpsCatEvt = 0;
                for f = 1:length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav)
                    
                    load([ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav{f} filesep 'behavResources.mat'] ,'PosMat')
                    tps = tps + max(PosMat(:,1));
                    tpsCatEvt = [tpsCatEvt, [tps;tps]']; % in seconds
                    
                end
                tpsCatEvt(end) = [];
                tpsCatEvt = num2cell(tpsCatEvt);
                
                try
                    save([FinalFolder 'behavResources'],'tpsCatEvt','-append')
                catch
                    disp('Creating behavResources.mat')
                    save([FinalFolder 'behavResources'],'tpsCatEvt')
                end
            case 'Yes'
                disp('')
        end
    case 'No'
        disp('')
end


switch ExpeInfo.PreProcessingInfo.IsThereBehav
    case 'Yes'
        
        if ~strcmpi(ExpeInfo.CameraType, 'None')
            if  length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav)==1
                copyfile([ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav{1} filesep 'behavResources.mat'],...
                    [FinalFolder filesep 'behavResources-temp.mat']);
                TempVar = load([FinalFolder filesep 'behavResources-temp.mat']);
                save([FinalFolder filesep 'behavResources.mat'],'-struct','TempVar','-append')
                delete([FinalFolder filesep 'behavResources-temp.mat'])
                
            else
                for f = 1:length(ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav)
                    
                    copyfile([ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav{f} filesep 'behavResources.mat'],...
                        [FinalFolder filesep 'behavResources-' sprintf('%02d',f) '.mat']);
                    filelist{f} = [FinalFolder filesep 'behavResources-' sprintf('%02d',f) '.mat'];
                    
                end
                BehavResourcesConcatenation(filelist, ExpeInfo.PreProcessingInfo.FolderSessionName, tpsCatEvt, FinalFolder)
            end
        end
        
    case 'No'
end

disp('All done, you''re good! Jesus loves you. And your momma too')
disp('All hail the Holy Octopus')
