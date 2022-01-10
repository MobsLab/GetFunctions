%%GetSpindles
% 18.12.2018 KJ
%
% get/load spindles
%
% function [tSpindles, SpindlesEpoch] = GetSpindles(varargin)
%
% INPUT:
% - area (optional)             = brain area of detection
%                               (default 'PFCx')
% - spindle_type (optional)     = type of spindles (all, high, low)
%                               (default 'all')
% - Epoch (optional)            = epoch on which Spindles detection is restricted 
%                               (default no restrict)
% - foldername (optional)       = directory to get the data
%                               (default pwd)
%

%
%
% OUTPUT:
% - tSpindles                = ts of spindles center
% - SpindlesEpoch            = Spindles intervalSet (Start End)
%
%   see 
%       


function [tSpindles, SpindlesEpoch] = GetSpindles(varargin)


%% CHECK INPUTS

if mod(length(varargin),2) ~= 0
  error('Incorrect number of parameters.');
end

% Parse parameter list
for i = 1:2:length(varargin)
    if ~ischar(varargin{i})
        error(['Parameter ' num2str(i+2) ' is not a property.']);
    end
    switch(lower(varargin{i}))
        case 'area'
            area = varargin{i+1};
        case 'spindle_type'
            spindle_type = varargin{i+1};
        case 'Epoch'
            Epoch = varargin{i+1};
        case 'foldername'
            foldername = varargin{i+1};
        otherwise
            error(['Unknown property ''' num2str(varargin{i}) '''.']);
    end
end

%check if exist and assign default value if not
if ~exist('area','var')
    area = 'PFCx';
end
if ~exist('spindle_type','var')
    spindle_type = 'all';
end
if ~exist('Epoch','var')
    Epoch=[];
end
if ~exist('foldername','var')
    foldername = pwd;
end


%type of spindles
if strcmpi(spindle_type, 'high') || strcmpi(spindle_type, 'low')
    sptype = spindle_type;
else
    sptype = '';
end
    

%% Get Spindles
if exist(fullfile(foldername,'Spindles.mat'), 'file')==2 || exist(fullfile(foldername,'sSpindles.mat'), 'file')==2
    if ~isempty(sptype)
        varname = ['spindles_' sptype '_' area];
    else
%         varname = ['spindles_' area];
        try
            varname = ['Spindles'];
        catch
            varname = ['spindles_' area];
        end
    end
    try
        a = load(fullfile(foldername,'sSpindles.mat'), varname);    
    catch
        a = load(fullfile(foldername,'Spindles.mat'), varname);    
    end
    
    if isfield(a,varname)
        % the old version
        spindles = a.(varname);
        tSpindles = ts(spindles(:,2)*1e4);
        SpindlesEpoch = intervalSet(spindles(:,1)*1e4, spindles(:,3)*1e4);
    else
        % the new version
        if ~isempty(sptype)
            varname = ['tSpindles_' sptype '_' area];
            varnameEp = ['SpindlesEpoch_' sptype '_' area];

        else
            varname = ['tSpindles_' area];
            varnameEp = ['SpindlesEpoch_' area];
        end
        try
            a = load(fullfile(foldername,'sSpindles.mat'), varname,varnameEp,'tSpindles','SpindlesEpoch');
        catch
            a = load(fullfile(foldername,'Spindles.mat'), varname,varnameEp,'tSpindles','SpindlesEpoch');
        end
        try
            tSpindles = a.(varname);
            SpindlesEpoch = a.(varnameEp);
        catch % if no PFCx label
            tSpindles = a.tSpindles;
            SpindlesEpoch = a.SpindlesEpoch;
        end
    end

else
    disp('No Spindles file found')
end


%% Restrict eventually
if ~isempty(Epoch)
    tSpindles = Restrict(tSpindles,Epoch);
    SpindlesEpoch = and(SpindlesEpoch,Epoch);
end


end

