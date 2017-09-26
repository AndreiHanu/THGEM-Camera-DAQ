%=========================================================================%
%                   TDC-GPX Graphical User Interface                      %
%                                                                         %
% This graphical user interface (GUI) communicates with the FMC_TDC_GPX   %
% and the SP601 FPGA via UART Serial Interface. The GUI allows the user   %
% to configure and retrieving data from the TDC-GPX chip.                 %
%                                                                         %
% Programmed by: Andrei Hanu                                              %                         
% Contact: hanua@mcmaster.ca                                              %
% Last Edit: Jan 24, 2013                                                 %
%=========================================================================%

function varargout = guiTDCDAQ(varargin)
% GUITDCDAQ MATLAB code for guiTDCDAQ.fig
%      GUITDCDAQ, by itself, creates a new GUITDCDAQ or raises the existing
%      singleton*.
%
%      H = GUITDCDAQ returns the handle to a new GUITDCDAQ or the handle to
%      the existing singleton*.
%
%      GUITDCDAQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUITDCDAQ.M with the given input arguments.
%
%      GUITDCDAQ('Property','Value',...) creates a new GUITDCDAQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guiTDCDAQ_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guiTDCDAQ_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiTDCDAQ

% Last Modified by GUIDE v2.5 06-Mar-2013 14:04:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiTDCDAQ_OpeningFcn, ...
                   'gui_OutputFcn',  @guiTDCDAQ_OutputFcn, ...
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


% --- Executes just before guiTDCDAQ is made visible.
function guiTDCDAQ_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiTDCDAQ (see VARARGIN)

% Choose default command line output for guiTDCDAQ
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Button and Drop List States
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.boxCOMPort,'Enable','on');
set(handles.boxBaudRate,'Enable','on');
set(handles.btnInitConn,'Enable','on');
set(handles.btnCloseConn,'Enable','off');
set(handles.btnPURESN,'Enable','off');
set(handles.btnConfigTDC,'Enable','off');
set(handles.btnStart,'Enable','off');
set(handles.btnStop,'Enable','off');
set(handles.btnClearPlot,'Enable','on');
set(handles.btnSaveSpectrum,'Enable','on');
set(handles.btnGetData,'Enable','off');
set(handles.btnClearMemory,'Enable','off');
set(handles.boxPixDiv,'Enable','off');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the available COM ports and Baud Rates
%% Requires Instrument Control Toolbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
serialInfo = instrhwinfo('serial');
set( handles.boxCOMPort , 'String', serialInfo.AvailableSerialPorts );
% Pre-select the COM Port
%set( handles.boxCOMPort , 'Value', 3 );
% Baud Rate
baudRates = {'9600';'19200';'38400';'57600';'115200'};
set( handles.boxBaudRate , 'String', baudRates );
% Pre-select the Baud Rate
set( handles.boxBaudRate , 'Value', 4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the pixel divide factors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
divideFactors = {'1';'2';'4';'8';'16';'32';'64';'128'};
set( handles.boxPixDiv , 'String', divideFactors );
% Pre-select a value
set( handles.boxPixDiv , 'Value', 6 );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Time Histrogram Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call Initialize Spectrum Function
initializeSpectrum();
% Setup axes
global plotHandle time_bin_counts;
plotHandle = imagesc(time_bin_counts,[0 255]);
colormap(gray)
set(gca,'ydir','normal')
zoom on
zoom(2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- When executed, the TDC time spectrum is initialized (zero-ed)
function initializeSpectrum()
global time_bin_counts timeBins;
% Number of Time Bins
timeBins = 1024;
% Bins Counts
time_bin_counts = uint32(zeros(timeBins,timeBins));

% --- Outputs from this function are returned to the command line.
function varargout = guiTDCDAQ_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in boxCOMPort.
function boxCOMPort_Callback(hObject, eventdata, handles)
% hObject    handle to boxCOMPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns boxCOMPort contents as cell array
%        contents{get(hObject,'Value')} returns selected item from boxCOMPort


% --- Executes during object creation, after setting all properties.
function boxCOMPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to boxCOMPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in boxBaudRate.
function boxBaudRate_Callback(hObject, eventdata, handles)
% hObject    handle to boxBaudRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns boxBaudRate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from boxBaudRate


% --- Executes during object creation, after setting all properties.
function boxBaudRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to boxBaudRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnInitConn.
function btnInitConn_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Serial Connection Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Selected Serial Port
global portCOM baudRate;
portCOMText = get(handles.boxCOMPort, 'String');
portCOM = portCOMText{get(handles.boxCOMPort, 'value')};
% Get Selected Baud Rate
baudRateText = get(handles.boxBaudRate, 'String');
baudRate = str2double(baudRateText{get(handles.boxBaudRate, 'value')});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup Serial Connection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check to see if the port is in use already
out = instrfind('Port', portCOM);              

if (~isempty(out))
    % Port is already being used. Close it.
    disp(['WARNING: ' portCOM ' port is already in use.  Closing...'])
    if (strcmp(get(out(1), 'Status'),'open'))
        % Close Connection
        fclose(out(1));
    end
    % Delete Connection
    delete(out(1)); 
end 

global serialTDC;
serialTDC = serial(portCOM);                        % Define serial port object
set(serialTDC, 'BaudRate', baudRate);               % Baud Rate
set(serialTDC, 'Tag', 'FMC_TDC_GPX' );              % Port Name
set(serialTDC, 'TimeOut', .1 );
set(serialTDC, 'Terminator', '' );
set(serialTDC, 'InputBufferSize',  1048576 );       % 1 MB
set(serialTDC, 'ReadAsyncMode',  'continuous' ); 
set(serialTDC, 'BytesAvailableFcnMode','byte');
set(serialTDC, 'BytesAvailableFcnCount',4);
%set(serialTDC, 'BytesAvailableFcn',@TDC_Get_Data);

% Open Serial Connection
fopen(serialTDC);

disp(['Serial ' portCOM ', with Baud Rate ' num2str(baudRate) ', initialized'])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Button and Drop List States
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.boxCOMPort,'Enable','off');
set(handles.boxBaudRate,'Enable','off');
set(handles.btnInitConn,'Enable','off');
set(handles.btnCloseConn,'Enable','on');
set(handles.btnPURESN,'Enable','on');
set(handles.btnConfigTDC,'Enable','on');
set(handles.btnStart,'Enable','on');
set(handles.btnStop,'Enable','off');
set(handles.btnClearPlot,'Enable','on');
set(handles.btnSaveSpectrum,'Enable','on');
set(handles.btnGetData,'Enable','on');
set(handles.btnClearMemory,'Enable','on');
set(handles.boxPixDiv,'Enable','on');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnCloseConn.
function btnCloseConn_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Close & Delete Serial Connection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global serialTDC;
fclose(serialTDC);
delete(serialTDC);

global portCOM;
disp(['Serial ' portCOM ' closed'])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Button and Drop List States
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.boxCOMPort,'Enable','on');
set(handles.boxBaudRate,'Enable','on');
set(handles.btnInitConn,'Enable','on');
set(handles.btnCloseConn,'Enable','off');
set(handles.btnPURESN,'Enable','off');
set(handles.btnConfigTDC,'Enable','off');
set(handles.btnStart,'Enable','off');
set(handles.btnStop,'Enable','off');
set(handles.btnClearPlot,'Enable','on');
set(handles.btnSaveSpectrum,'Enable','on');
set(handles.btnGetData,'Enable','off');
set(handles.btnClearMemory,'Enable','off');
set(handles.boxPixDiv,'Enable','off');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnPURESN.
function btnPURESN_Callback(hObject, eventdata, handles)

global serialTDC;
% Send Power-up Reset Command to TDC-GPX
fwrite(serialTDC,'$1');


% --- Executes on button press in btnConfigTDC.
function btnConfigTDC_Callback(hObject, eventdata, handles)
global serialTDC;
% Send Configure Command to TDC-GPX
fwrite(serialTDC,'$2');


% --- Executes on button press in btnStart.
function btnStart_Callback(hObject, eventdata, handles)
global serialTDC;
% Output Message
disp('Acquisition Started');

% Send Start Command to TDC-GPX
fwrite(serialTDC,'$3');

tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Button States
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.btnInitConn,'Enable','off');
set(handles.btnCloseConn,'Enable','on');
set(handles.btnPURESN,'Enable','off');
set(handles.btnConfigTDC,'Enable','off');
set(handles.btnStart,'Enable','off');
set(handles.btnStop,'Enable','on');
set(handles.btnClearPlot,'Enable','off');
set(handles.btnSaveSpectrum,'Enable','off');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function TDC_Get_Data()
% Global Variables
global serialTDC time_bin_counts startX startY endX endY pixDiv;

% Bytes Available
bytesAvail = serialTDC.BytesAvailable;

% Zero Image
time_bin_counts = uint32(zeros((endX - startX + 1)/pixDiv, (endY - startY + 1)/pixDiv));
curX = 1;
curY = 1;
curXEnd = (endX - startX + 1)/pixDiv;
count = 0;
while bytesAvail > 0
    [a,c,msg] = fread(serialTDC,[4 1],'uint8');
    
    time_bin_counts(curX,curY) = uint32(a(1)) + bitshift(uint32(a(2)),8) + bitshift(uint32(a(3)),16) + bitshift(uint32(a(4)),24);    
    bytesAvail = serialTDC.BytesAvailable;
    count = count + 1;
    
    % Check Current X Position
    if (curX < curXEnd)
        curX = curX + 1;
    else
        curX = 1;
        curY = curY + 1;
    end
end

% Update Plot
updatePlot();

% Display Gross Counts
disp('========================================================');
str = sprintf('Gross Counts: %d',sum(sum(time_bin_counts)));
disp(str);
str = sprintf('Expected # of Pixels: %d',((endX - startX + 1)/pixDiv)*((endY - startY + 1)/pixDiv));
disp(str);
str = sprintf('Received # of Pixels: %d',count);
disp(str);
disp('========================================================');

function updatePlot()
global time_bin_counts;
% Update The Plot
imagesc(time_bin_counts,[0 255]);
colormap(gray)
set(gca,'ydir','normal')


% --- Executes on button press in btnStop.
function btnStop_Callback(hObject, eventdata, handles)
global serialTDC timediff;
% Send Stop Command to TDC-GPX
fwrite(serialTDC,'$4');

timediff = toc;

% Output Message
str = sprintf('Acquisition Stopped. Running Time: %0.2f sec',timediff);
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the Button States
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.btnInitConn,'Enable','off');
set(handles.btnCloseConn,'Enable','on');
set(handles.btnPURESN,'Enable','on');
set(handles.btnConfigTDC,'Enable','on');
set(handles.btnStart,'Enable','on');
set(handles.btnStop,'Enable','off');
set(handles.btnClearPlot,'Enable','on');
set(handles.btnSaveSpectrum,'Enable','on');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnClearPlot.
function btnClearPlot_Callback(hObject, eventdata, handles)

% Call Initialize Spectrum Function
initializeSpectrum();

% Update The Plot
updatePlot();

% Output Message
disp('Plot cleared');

% --- Executes on button press in btnSaveSpectrum.
function btnSaveSpectrum_Callback(hObject, eventdata, handles)

global time_bin_counts;

% Image Save Parameters
filename = ['imgTDCDAQ_' datestr(now,'yyyymmdd_HH_MM') '.out'];

dlmwrite(filename, time_bin_counts, 'delimiter', '\t', ...
         'precision', 6)
     
% Output Message
str = sprintf('Raw image saved to %s', filename);
disp(str);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
global portCOM;
% Check to see if the port was left open
out = instrfind('Port', portCOM);              

if (~isempty(out))
    % Send Stop Command to TDC-GPX
    fwrite(out(1),'$4');
    % Port is already being used. Close it.
    disp(['WARNING: ' portCOM ' port was left open.  Closing...'])
    if (strcmp(get(out(1), 'Status'),'open'))
        % Close Connection
        fclose(out(1));
    end
    % Delete Connection
    delete(out(1)); 
    % Display status
    disp(['Serial ' portCOM ' closed'])
end 

% Close the figure
delete(hObject);

% --- Executes on button press in btnClearMemory.
function btnClearMemory_Callback(hObject, eventdata, handles)
global serialTDC;
% Send ClrMem Command to FPGA
fwrite(serialTDC,'$5');

% Output Message
disp('DDR2 Memory Cleared');


% --- Executes on button press in btnGetData.
function btnGetData_Callback(hObject, eventdata, handles)
global serialTDC timeBins startX startY endX endY pixDiv;
% Send GetData Command to FPGA
fwrite(serialTDC,'$6');
startX = 0;
startY = 0;
endX = timeBins-1;
endY = timeBins-1;

% Get Selected Subpixel Size
pixDivText = get(handles.boxPixDiv, 'String');
pixDiv = str2double(pixDivText{get(handles.boxPixDiv, 'value')});

fwrite(serialTDC,startX,'uint16');
fwrite(serialTDC,startY,'uint16');
fwrite(serialTDC,endX,'uint16');
fwrite(serialTDC,endY,'uint16');
fwrite(serialTDC,pixDiv,'uint8');

pause(0.5)

% Output Message
disp('========================================================');
disp('Requesting memory contents');
disp('========================================================');
str = sprintf('Start: \t\t X=%d \t\t Y=%d', startX, startY);
disp(str);
str = sprintf('End: \t\t X=%d \t Y=%d', endX, endY);
disp(str);
str = sprintf('Divide: \t %d', pixDiv);
disp(str);
disp('========================================================');

% Call GetData Function
TDC_Get_Data();


% --- Executes on selection change in boxPixDiv.
function boxPixDiv_Callback(hObject, eventdata, handles)
% hObject    handle to boxPixDiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns boxPixDiv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from boxPixDiv


% --- Executes during object creation, after setting all properties.
function boxPixDiv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to boxPixDiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
