% MakeData_Accelero
% 23.10.2017 (KJ & SB)
%
% Processing: 
%   - generate a tsd variable, MovAcctsd, and put it into behavResources
%
%
%   see makeData, makeDataBulbe

function MovAcctsd = MakeData_Accelero(foldername, varargin)

disp('Get INTAN Accelerometer')
%% Initiation
if nargin < 1
    foldername = pwd;
end
if foldername(end)~=filesep
    foldername(end+1) = filesep;
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
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
if ~exist('recompute','var')
    recompute=0;
end

%check if already exist
if ~recompute
    if exist('behavResources.mat','file')==2
        load('behavResources', 'MovAcctsd')
        if exist('MovAcctsd','var')
            disp('Already computed! ')
            return
        end
    end
end


%% find accelrometer channels
load([foldername 'LFPData/InfoLFP.mat'])
channel_accelero = InfoLFP.channel(strcmp(InfoLFP.structure,'Accelero'));

if isempty(channel_accelero)
    disp('No Accelero found in InfoLFP.mat')
else
    clear X Y Z
    disp('... Loading LFP.mat (wait!)')
    X = load([foldername 'LFPData/LFP' num2str(channel_accelero(1)) '.mat'], 'LFP');
    Y = load([foldername 'LFPData/LFP' num2str(channel_accelero(2)) '.mat'], 'LFP');
    Z = load([foldername 'LFPData/LFP' num2str(channel_accelero(3)) '.mat'], 'LFP');


    disp('... Creating movement Vector')
    MX = Data(X.LFP);
    MY = Data(Y.LFP);
    MZ = Data(Z.LFP);
    Rg = Range(X.LFP);
    Acceleration = MX.^2 + MY.^2 + MZ.^2;
    %Acc=sqrt(MX.*MX+MY.*MY+MZ.*MZ);
    disp('... DownSampling at 50Hz');
    MovAcctsd = tsd(Rg(1:25:end), double(abs([0;diff(Acceleration(1:25:end))])) );

    
    %% save
    try
        save([foldername 'behavResources'],'MovAcctsd','-append')
    catch
        disp('Creating behavResources.mat')
        save([foldername 'behavResources'],'MovAcctsd')
    end
    disp('Done')
end

end

