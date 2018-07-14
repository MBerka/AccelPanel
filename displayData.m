function [ ] = displayData(thisTrace, time, handles)
%DisplayData Displays the selected traces in the graph space
%   Individually, as a resultant, and as spectrogram

  if ~exist('handles', 'var')
    return;
  end

  tStart = str2double(get(handles.startField,'String'));
  [tScale, tUnit] = getUnitCoefficient(handles, 'time');

  if ~exist('thisTrace','var')
    set(handles.statusBox, 'String', 'Nothing to display');
    return;
  elseif length(thisTrace)<2
    set(handles.statusBox, 'String', 'Too little data');
    return;
  end
  
  set(handles.statusBox, 'String', 'Display in progress');
  annotateGraph(handles, 'clear');
  set(handles.detectLine, 'Visible', 'off');
  
  if ~exist('time','var')
    indicesAsTime = true;
  elseif length(time)<2 || length(time)~=length(thisTrace)
    indicesAsTime = true;
  else
    indicesAsTime = false;
  end

  if indicesAsTime
    time = 1:length(thisTrace);
    sampleFreq = [];
  else
    sampleFreq = floor(length(time)/(time(end)-time(1)));
  end

  spectroAxes = get(handles.spectroPanel,'UserData');
  traceAxes = get(handles.tracePanel,'UserData');
  drawingSpectro = false; %#ok<NASGU> %Changed under certain conditions
  if get(handles.showSpectro, 'Value')
    drawingSpectro = true;
    selectedSpectro = logical([get(handles.spectro1Box, 'Value'), ...
      get(handles.spectro2Box, 'Value'),get(handles.spectro3Box, 'Value')]);

    specWindow = max(min(floor(sampleFreq*2), 2000), 30);
    % 2s windows have frequency resolution of 0.5Hz. Upper limit in case of
    % very dense sampling. Lower limit to retain some degree of consistency
    % even if sampling is low.
    
    specHandle = get(handles.spectroAxes, 'Children'); %Should have only one
    if length(time)>specWindow
      drawingSpectro = true;

      axes(spectroAxes);
      for dimCounter=1:size(thisTrace, 2)
        thisTrace(:, dimCounter) = thisTrace(:, dimCounter) - ...
          mean(thisTrace(:, dimCounter));
      end
      delete(get(handles.spectroAxes, 'Children'));
      spectrogram(sqrt(sum(double( ...
        (thisTrace(:,selectedSpectro))).^2,2))-(682.5/2), ...
        hamming(specWindow), floor(0.95*specWindow), specWindow, sampleFreq, 'yaxis');
      hold(spectroAxes,'on');
      set(handles.showSpectro, 'UserData', specHandle);
      
      set(handles.colorbarIcon, 'State', 'on'); %Leave for colorbar callback
      xlabel('');
      ylabel('Frequency (spectrogram) [Hz]');
      specHandle = get(handles.spectroAxes, 'Children');
    end
    
    %Spectrogram must be in seconds for easy calculation of Hz. Change the
    %horizontal time scale unit/offset only after the image is made.
    set(specHandle,'XData', get(specHandle,'XData')/tScale+tStart);
    set(handles.spectroAxes,'XLim',get(handles.spectroAxes,'XLim')/tScale);
    hold on;
  else
    drawingSpectro = false;
    colorbar('hide');
    set(handles.colorbarIcon, 'State', 'off');
  end

  resultantHandles = [handles.resultant1Box handles.resultant2Box ...
    handles.resultant3Box];
  dimNames = get(resultantHandles, 'String').'; %Cell, 1-2-3, make 1x3 
  whichResultants = logical(cell2mat(get(resultantHandles, 'Value')));
  whichTraces = logical([1 1 1 sum(whichResultants)]); %Current approach is 
    %to load all basic traces so that they can be shown and hidden without 
    %re-running this function. 4th is the resultant; no sense in loading a
    %blank.
  
  if whichTraces(4) %If the resultant is being plotted
    thisTrace(:,4)=sqrt(sum(single(thisTrace(:,whichResultants)).^2,2));
    whichTraces(4)=true;
    set(get(handles.showResultant, 'UserData'), 'DisplayName', ...
      ['||'  strjoin(dimNames(whichResultants),', ') '||']);
    %Only legend entry that changes.
  end

  if sum(whichTraces) %If any line is being plotted
    drawingTraces = true;
    axes(traceAxes);
    boxRefs = [handles.trace1Box, handles.trace2Box, ...
      handles.trace3Box, handles.showResultant];
    
    [accelCoefficient, accelUnit] = getUnitCoefficient(handles, 'accel');
    for boxCounter =1:length(whichTraces) %Includes resultant if any parts checked
      thisBox = boxRefs(boxCounter);
      %Load to visible and hidden traces
        set(get(thisBox, 'UserData'), 'XData', time/tScale);
        set(get(thisBox, 'UserData'), 'YData', ...
          thisTrace(:,boxCounter)*accelCoefficient);
    end
    xlabel(['Time [' tUnit ']']);
    set(handles.graphPanel, 'UserData', tScale); %For data selection
    ylabel(['Acceleration [' accelUnit ']']);
    axis auto;
  else
    drawingTraces = false;
  end
%   linkaxes([spectroAxes traceAxes],'x');

  annotateGraph(handles);

  set(handles.statusBox, 'String', 'Display complete'); %Finished
end