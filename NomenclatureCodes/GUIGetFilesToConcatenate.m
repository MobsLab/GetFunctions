function varargout = GUIGetFilesToConcatenate(varargin)
% GUIGETFILESTOCONCATENATE MATLAB code for GUIGetFilesToConcatenate.fig
%      GUIGETFILESTOCONCATENATE, by itself, creates a new GUIGETFILESTOCONCATENATE or raises the existing
%      singleton*.
%
%      H = GUIGETFILESTOCONCATENATE returns the handle to a new GUIGETFILESTOCONCATENATE or the handle to
%      the existing singleton*.
%
%      GUIGETFILESTOCONCATENATE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIGETFILESTOCONCATENATE.M with the given input arguments.
%
%      GUIGETFILESTOCONCATENATE('Property','Value',...) creates a new GUIGETFILESTOCONCATENATE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUIGetFilesToConcatenate_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUIGetFilesToConcatenate_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUIGetFilesToConcatenate

% Last Modified by GUIDE v2.5 18-Dec-2018 17:33:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUIGetFilesToConcatenate_OpeningFcn, ...
                   'gui_OutputFcn',  @GUIGetFilesToConcatenate_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUIGetFilesToConcatenate is made visible.
function GUIGetFilesToConcatenate_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUIGetFilesToConcatenate (see VARARGIN)

% Choose default command line output for GUIGetFilesToConcatenate
handles.output = hObject;

load('ExpeInfo.mat')

ExpeInfo.PreProcessingInfo.IsThereEphys = questdlg('Is there ephys?','FileTypes','Yes','No','Yes');
ExpeInfo.PreProcessingInfo.IsThereBehav = questdlg('Is there behaviour?','FileTypes','Yes','No','Yes');
save('ExpeInfo.mat','ExpeInfo')

NumFilesToConcatenate = inputdlg('Number of folders to concatenate');

NumFilesToConcatenate = eval(NumFilesToConcatenate{1});
ExpeInfo.PreProcessingInfo.NumFilesToConcatenate = NumFilesToConcatenate;
ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys = {''};
ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav = {''};
ExpeInfo.PreProcessingInfo.FolderSessionName = {''};


for k = 1 : NumFilesToConcatenate
    
    handles.(['FileNum',num2str(k)])= uicontrol(handles.figure1,'style','text',...
        'units','normalized','position',[0.01 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.02 0.02],...
        'string',num2str(k));
    
    handles.(['GetFileLocation',num2str(k)])= uicontrol(handles.figure1,'style','PushButton',...
        'units','normalized','position',[0.04 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.05 0.04],'String','GetFile',...
        'callback', {@GetFolder,k});
    
    handles.(['FileLocation_Ephys',num2str(k)])= uicontrol(handles.figure1,'style','text',...
        'units','normalized','position',[0.12 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.3 0.04],'String','Ephys folder name to define');
    
    handles.(['FileLocation_Behav',num2str(k)])= uicontrol(handles.figure1,'style','text',...
        'units','normalized','position',[0.45 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.3 0.04],'String','Behavior folder name to define');

    handles.(['FolderSessionName',num2str(k)])= uicontrol(handles.figure1,'style','edit',...
        'units','normalized','position',[0.8 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.08 0.04],'String','Session name',...
        'callback', {@FolderSession,k});
    
    handles.(['GetFileLocation',num2str(k)])= uicontrol(handles.figure1,'style','radiobutton',...
        'units','normalized','position',[0.92 0.9-(0.9/(NumFilesToConcatenate+1))*k 0.08 0.02],'String','Ref done',...
        'callback', {@RefDone,k});
    
    handles.(['GetFileLocation',num2str(k)])= uicontrol(handles.figure1,'style','radiobutton',...
        'units','normalized','position',[0.92 0.9-(0.9/(NumFilesToConcatenate+1))*k+0.02 0.08 0.02],'String','Merge done',...
        'callback', {@MergeDone,k});
    
    ExpeInfo.PreProcessingInfo.MergeDone{k} = 0;
    ExpeInfo.PreProcessingInfo.RefDone{k} = 0;

    
end
handles.ExpeInfo = ExpeInfo;

set(handles.DoneButton,'enable','off')


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUIGetFilesToConcatenate wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUIGetFilesToConcatenate_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% Marks whether or not the channels should be used for subtraction
function GetFolder(hObject, eventdata, Num)
TempData = guidata(hObject);

% get the folder with ephys
switch TempData.ExpeInfo.PreProcessingInfo.IsThereEphys
    case 'Yes'
        directoryname = uigetdir(cd, 'Click on the ephys folder');
    case 'No'
        directoryname = 'NoEphys';
end
TempData.ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys{Num} = directoryname;
set(TempData.(['FileLocation_Ephys',num2str(Num)]),'String',directoryname);
guidata(hObject,TempData)
set(TempData.(['FileLocation_Ephys',num2str(Num)]),'BackGroundColor',[0.8 0.4 0.2])

% get the folder with behaviour
switch TempData.ExpeInfo.PreProcessingInfo.IsThereBehav
    case 'Yes'
directoryname = uigetdir(cd, 'Click on the behaviour folder');
    case 'No'
        directoryname = 'NoBehaviour';
end
TempData.ExpeInfo.PreProcessingInfo.FolderForConcatenation_Behav{Num} = directoryname;
set(TempData.(['FileLocation_Behav',num2str(Num)]),'String',directoryname);
guidata(hObject,TempData)
set(TempData.(['FileLocation_Behav',num2str(Num)]),'BackGroundColor',[0.8 0.4 0.2])


if sum(~cellfun(@isempty,TempData.ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys),2) == TempData.ExpeInfo.PreProcessingInfo.NumFilesToConcatenate && ...
      sum(~cellfun(@isempty,TempData.ExpeInfo.PreProcessingInfo.FolderSessionName),2) == TempData.ExpeInfo.PreProcessingInfo.NumFilesToConcatenate  
    set(TempData.DoneButton,'enable','on')
end


% Marks whether or not the channels should be used for subtraction
function FolderSession(hObject, eventdata, Num)
TempData = guidata(hObject);
 get(hObject,'String')
TempData.ExpeInfo.PreProcessingInfo.FolderSessionName{Num} = get(hObject,'String');
guidata(hObject,TempData)
set(TempData.(['FolderSessionName',num2str(Num)]),'BackGroundColor',[0.8 0.4 0.2])
if sum(~cellfun(@isempty,TempData.ExpeInfo.PreProcessingInfo.FolderForConcatenation_Ephys),2) == TempData.ExpeInfo.PreProcessingInfo.NumFilesToConcatenate && ...
      sum(~cellfun(@isempty,TempData.ExpeInfo.PreProcessingInfo.FolderSessionName),2) == TempData.ExpeInfo.PreProcessingInfo.NumFilesToConcatenate  
    set(TempData.DoneButton,'enable','on')
end

% Marks whether or not the channels should be used for subtraction
function RefDone(hObject, eventdata, Num)
TempData = guidata(hObject);
TempData.ExpeInfo.PreProcessingInfo.RefDone{Num} = hObject.Value;
guidata(hObject,TempData)

% Marks whether or not the channels should be used for subtraction
function MergeDone(hObject, eventdata, Num)
TempData = guidata(hObject);
TempData.ExpeInfo.PreProcessingInfo.MergeDone{Num} = hObject.Value;
guidata(hObject,TempData)


% --- Executes on button press in DoneButton.
function DoneButton_Callback(hObject, eventdata, handles)
TempData = guidata(hObject);
ExpeInfo = TempData.ExpeInfo;
ExpeInfo.PreProcessingInfo
save('ExpeInfo.mat','ExpeInfo')
delete(TempData.figure1)
