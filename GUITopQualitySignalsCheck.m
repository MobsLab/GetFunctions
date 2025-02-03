function varargout = GUITopQualitySignalsCheck(varargin)
% GUITOPQUALITYSIGNALSCHECK MATLAB code for GUITopQualitySignalsCheck.fig
%      GUITOPQUALITYSIGNALSCHECK, by itself, creates a new GUITOPQUALITYSIGNALSCHECK or raises the existing
%      singleton*.
%
%      H = GUITOPQUALITYSIGNALSCHECK returns the handle to a new GUITOPQUALITYSIGNALSCHECK or the handle to
%      the existing singleton*.
%
%      GUITOPQUALITYSIGNALSCHECK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUITOPQUALITYSIGNALSCHECK.M with the given input arguments.
%
%      GUITOPQUALITYSIGNALSCHECK('Property','Value',...) creates a new GUITOPQUALITYSIGNALSCHECK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUITopQualitySignalsCheck_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUITopQualitySignalsCheck_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUITopQualitySignalsCheck

% Last Modified by GUIDE v2.5 23-Jan-2025 09:49:15

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUITopQualitySignalsCheck_OpeningFcn, ...
    'gui_OutputFcn',  @GUITopQualitySignalsCheck_OutputFcn, ...
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


% --- Executes just before GUITopQualitySignalsCheck is made visible.
function GUITopQualitySignalsCheck_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUITopQualitySignalsCheck (see VARARGIN)

% Choose default command line output for GUITopQualitySignalsCheck
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Get Info so far
load('ExpeInfo.mat')
handles.ExpeInfo = ExpeInfo;

% Initialise
handles.ExpeInfo.TopQualitySignals.OBrespiInversion = 0;
handles.ExpeInfo.TopQualitySignals.OBrespi = 0;
handles.ExpeInfo.TopQualitySignals.OBgamma = 0;
handles.ExpeInfo.TopQualitySignals.EKG = 0;
handles.ExpeInfo.TopQualitySignals.EMG = 0;
handles.ExpeInfo.TopQualitySignals.Spindles = 0;
handles.ExpeInfo.TopQualitySignals.DeltaWaves = 0;
handles.ExpeInfo.TopQualitySignals.ThetaInversion = 0;
handles.ExpeInfo.TopQualitySignals.Ripples = 0;

% Only enable buttons with corresponding channels to analyse
% if ~isfield(handles.ExpeInfo.ChannelToAnalyse,'dHPC_rip')
%     set(handles.ripplesbutton,'Enable','Off')
%     handles.ExpeInfo.TopQualitySignals.Ripples = NaN;
% end
% 
% if ~isfield(handles.ExpeInfo.ChannelToAnalyse,'EMG')
%     set(handles.emgbutton,'Enable','Off')
%     handles.ExpeInfo.TopQualitySignals.EMG = NaN;
% end
% if ~isfield(handles.ExpeInfo.ChannelToAnalyse,'EKG')
%     set(handles.ekgbutton,'Enable','Off')
%     handles.ExpeInfo.TopQualitySignals.EKG = NaN;
% end
% 
% if ~isfield(handles.ExpeInfo.ChannelToAnalyse,'Bulb_deep')
%     set(handles.obgammabutton,'Enable','Off')
%     handles.ExpeInfo.TopQualitySignals.OBgamma = NaN;
% end
% if ~isfield(handles.ExpeInfo.ChannelToAnalyse,'Bulb_deep')
%     set(handles.obrespibutton,'Enable','Off')
%     handles.ExpeInfo.TopQualitySignals.OBrespi = NaN;
% end

% Update handles structure
guidata(hObject, handles);




% UIWAIT makes GUITopQualitySignalsCheck wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUITopQualitySignalsCheck_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ripplesbutton.
function ripples_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.Ripples = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in obgammabutton.
function thetainversion_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.ThetaInversion = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in emgbutton.
function delta_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.DeltaWaves = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in ekgbutton.
function spindles_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.Spindles = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in obrespibutton.
function emg_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.EMG = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in spindlesbutton.
function ekg_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.EKG = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in thetabutton.
function OBgamma_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.OBgamma = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in obrespinversionbutton.
function OBrespi_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.OBrespi = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


function OBrespinversion_Callback(hObject, eventdata, handles)
handles.ExpeInfo.TopQualitySignals.OBrespiInversion = get(hObject,'Value');
% Update handles structure
guidata(hObject, handles);


function ImDone_Callback(hObject, eventdata, handles)
ExpeInfo = handles.ExpeInfo;
save('ExpeInfo.mat','ExpeInfo')
handles.figure1.delete