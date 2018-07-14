function tRange = ...
  selectData( handles, selectMethod, tRange, otherSelect)
%SELECTDATA Summary of this function goes here
%   selectMethod: 0, supplied by tRange; 1, click; 2, type; 
%   3, graph range; 4, all

%% Selection
  if ~exist('handles', 'var')
    return;
  end
  if exist('otherSelect', 'var')
    if otherSelect
      otherSelect = true;
    end
  else
    otherSelect = false;
  end
  xRange = get(handles.traceAxes, 'XLim'); %Boundaries of the graph
  %The graph whose contents is regularly cleared.
  if ~exist('selectMethod', 'var')
    [selectMethod, selected]=listdlg('Name','Select data set', ...
        'PromptString','Means of selection?', ...
        'ListSize', [160 60], ...
        'ListString',{'On graph, click with mouse', ...
        'Anywhere, type in values', 'On graph, whole graph', ...
        'Anywhere, all data'}, ...
        'InitialValue',1, ...
        'SelectionMode','single', ...
        'OKString','Choose');
    if ~selected
      tRange = [0 0];
      set(handles.statusBox, 'String', 'Selection canceled');
      return;
    end
    tRange = xRange; %Also the default return values
  end
  
  switch selectMethod
    case 0
      if exist('tRange', 'var')
        startData = tRange(1);
        endData = tRange(end);
      else
        return;
      end
    case 1
      set(handles.statusBox, 'String', 'Click on graph');
      drawnow;
      
%       [selectedX, ~] = ginput(2); %Get mouse x coordinate twice
      [selectedX, ~] = quickGInput(2);
      startData = min(selectedX);
      endData = max(selectedX);
    case 2
      tString = get(handles.tUnitList, 'String');
      tUnit = tString{get(handles.tUnitList, 'Value')};
      response = inputdlg({['Start time (' tUnit ')?'], ...
        ['End time (' tUnit ')?']}, 'Typed values', 1, ...
        {num2str(xRange(1)), num2str(xRange(end))});
      startData = str2double(response{1});
      endData = str2double(response{2});
    case 3
      startData = xRange(1);
      endData = xRange(end);
    case 4
      startData = 0;
      endData = Inf;
    otherwise
      set(handles.statusBox, 'String', 'Selection canceled');
      return;
  end
  if isnan(startData)||isnan(endData)
    set(handles.stausBox, 'String', 'Selection canceled');
    return;
  elseif startData==endData
    set(handles.statusBox, 'String', 'Selection too short');
    return;
  end
  
  if startData > endData
    tempVar = startData;
    startData = endData;
    endData = tempVar;
  end

  values = [startData endData];
  if otherSelect
    color = [1 0 1]; %magenta
  else
    color = [1 0 0]; %black
  end

  annotateGraph(handles, 'show');
  for lineCount=[1 2]
    val=values(lineCount);
    if val>=xRange(1) && val<=xRange(end)
      annotateGraph(handles, struct('text', 'Selected', ...
        'position', val, 'color', color, 'save', false));
    end
  end
  
  set(handles.statusBox, 'String', 'Data selected');
  
  if (selectMethod == 1 || selectMethod == 3)
    tRange = [startData endData]*get(handles.graphPanel, 'UserData')/ ...
      getUnitCoefficient(handles, 'time');
  else
    tRange = [startData endData];
  end
    
  if otherSelect
    return;
  end
  
 timeCoefficient = getUnitCoefficient(handles, 'time');
  
  %% Selected time
  accelCoefficient = getUnitCoefficient(handles, 'accel');
  time = get(handles.timePanel, 'UserData'); %Select everything in range 
  %Select data sample range and density
  selectedSourceTime = logical((time>startData*timeCoefficient).* ...
    (time<endData*timeCoefficient));
  samples = get(handles.accelPanel, 'UserData');
  whichResultants = logical([get(handles.select1Box, 'Value'), ...
    get(handles.select2Box, 'Value'), get(handles.select3Box, 'Value')]);
  selectedData = sqrt(sum(single(samples(selectedSourceTime, ...
    whichResultants)).^2, 2))*accelCoefficient;
  
  minVal = num2str(min(selectedData), 3);
  maxVal = num2str(max(selectedData), 3);
  meanVal = mean(selectedData);
  meanString = num2str(meanVal, 3);
  duration = (endData - startData)*timeCoefficient;
  sampleDensity = num2str(length(selectedData)/duration, 3);
  stdDev = num2str(sqrt(mean((meanVal-selectedData(1,:)).^2)), 2);
  timeStr = num2str(duration, 3);
  statsString = ['Mean=' meanString ', SD=' stdDev ', Min=' minVal ...
    ', Max=' maxVal ' Time=' timeStr ' , Samples/s=' sampleDensity];
  set(handles.selectStatsText, 'String', statsString);

end

function [x, y] = quickGInput(clickNumber) 
  % Removes much of ginput functionality to quickly return 2D coordinates
  % on large plots
  
  oldPointer = get(gcf, 'Pointer');
  set(gcf, 'Pointer', 'crosshair');
  axesToClick = gca;

  x = zeros(1, clickNumber);
  y = x;
  
  for clickCounter = 1:clickNumber
    prevPoint = get(axesToClick, 'CurrentPoint');
    newPoint = prevPoint;

    while ~sum(newPoint~=prevPoint)
      pause(.05);
      newPoint = get(axesToClick, 'CurrentPoint');
    end
    
    x(clickCounter) = newPoint(1, 1);
    y(clickCounter) = newPoint(1, 2);
  end
  
  set(gcf, 'Pointer', oldPointer); %Restore what was before
end