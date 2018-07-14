function detection(handles, tRange, detectCommand)
%DETECTION Detects the presence of the desired frequency
%   Uses a spectrogram function.

  if ~exist('handles', 'var')
    return;
  end
  
  %From selectData
  time = get(handles.timePanel, 'UserData'); %Select everything in range 
  %Select data sample range and density
  timeCoefficient = getUnitCoefficient(handles, 'time');;
  selectedSourceTime = logical((time>tRange(1)*timeCoefficient).* ...
    (time<tRange(2)*timeCoefficient));
  samples = get(handles.accelPanel, 'UserData');
  whichResultants = logical([get(handles.select1Box, 'Value'), ...
    get(handles.select2Box, 'Value'), get(handles.select3Box, 'Value')]);
  samples = samples(selectedSourceTime, whichResultants);
  for dimCounter=1:size(samples, 2) %Subtract mean acceleration components
    samples(:, dimCounter) = samples(:, dimCounter) - ...
      mean(samples(:, dimCounter));
    %   Alternatively, subtract a well-calibrated gravity constant;
    %   (682.5)/2 is not fully verified.
  end
  selectedData = sqrt(sum(double(samples).^2, 2)); %Resultant

  if ~exist('detectCommand', 'var')
    [detectCommand, selected]= listdlg('Name','Select data set', ...
        'PromptString','Type of analysis?', ...
        'ListSize', [160 60], ...
        'ListString',{'Frequency power', ...
        'Repetition'}, ...
        'InitialValue',1, ...
        'SelectionMode','single', ...
        'OKString','Choose');
    if ~selected
      tRange = [0 0];
      set(handles.statusBox, 'String', 'Selection canceled');
      return;
    end
  end
  
  switch detectCommand
    case 1
      sampleFreq = floor(length(time)/(time(end)-time(1)));
      specWindow = max(min(floor(sampleFreq*2), 2000), 30);
      % 2s windows have frequency resolution of 0.5Hz.
      
      if length(time)<specWindow
        set(handles.statusBox, 'String', 'Selection too short to analyze');
        return;
      end
      set(handles.statusBox, 'String', 'Analyzing selection');

      [S, F, T, P] = spectrogram( selectedData, ...
        hamming(specWindow), floor(0.95*specWindow), specWindow, sampleFreq);
      %S is the short time Fourier transform. F is the frequency vector.
      %T holds the window times. P is the power. The last three are supposedly
      %plotted with surf(T,F,10*log10(abs(P))), though graphical results differ.

      timeCoefficient = getUnitCoefficient(handles, 'time');;
      T = T/timeCoefficient+tRange(1); %Shift time values into correct position

      %These are point values that expand outwards.  Boundaries should be
      %exclusive to avoid pickind up too much, and the range will need to be
      %made more flexible.
      freqMin = 3;
      freqMax = 7;
      %Select this range for all times, and add the desired powerss
      keyFreqPower = sum(P( logical((F>freqMin).*(F<freqMax)), : ), 1);

      %For comparison, take total power as well.
      totalPower = sum(P, 1); %Sum in different dimension because of the lack 
      %of indexing involved here.

      %Assign a threshold value. Since this software has not yet been tested on
      %patient data, this level is necessarily unknown, but should exceed
      %levels from the calibration data.
      absoluteThreshold = 50;
      relativeThreshold = 0.09;
      [selectMethod, selected]=listdlg('Name','Frequency detection', ...
        'PromptString','Criterium?', ...
        'ListSize', [160 60], ...
        'ListString',{'Absolute', 'Relative'}, ...
        'InitialValue',1, ...
        'SelectionMode','single', ...
        'OKString','Choose');
      if ~selected
        set(handles.statusBox, 'String', 'Analysis canceled');
      end
      if selectMethod == 1
        powerMatches = keyFreqPower > absoluteThreshold;
      else
        powerMatches = keyFreqPower ./ totalPower > relativeThreshold;
      end
    case 2
      xcorr(selectedData);
    otherwise
      1;
  end
  
  yLimits = get(handles.traceAxes, 'YLim');
  yHeight = (max(yLimits)-0.1*(max(yLimits)-min(yLimits)))*ones(length(T), 1);
  yHeight(~powerMatches) = NaN; %Matlab does not plot coordinate points with 
    %NaN values, nor draw connections between their neighbors.
  
  set(handles.detectLine, 'XData', T);
  set(handles.detectLine, 'YData', yHeight);
  set(handles.detectLine, 'Visible', 'on');
%   line(T, yHeight, 'LineWidth', 10, 'Color', [1 0.6 0]); %Thick, orange line
    %between the centers of neighboring windows meeting the condition.

  set(handles.statusBox, 'String', 'Analysis complete');
end