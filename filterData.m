function filterData( handles)
%FILTERDATA Filters the source data to remove noise
%   handles: figure reference
  [selectMethod, selected]=listdlg('Name','Filter data', ...
    'PromptString','Technique?', ...
    'ListSize', [160 60], ...
    'ListString',{'Golay-Savitzky smoothing', 'Subtractive'}, ...
    'InitialValue',1, ...
    'SelectionMode','single', ...
    'OKString','Choose');
  if ~selected
    set(handles.statusBox, 'String', 'Filtering canceled');
  end
  moddata = double(get(handles.accelPanel, 'UserData'));
  if selectMethod == 1
    thresholdAccel = .1/getUnitCoefficient(handles, 'g', 2);
    for channelCounter = 1:3
      sampleData = moddata(:, channelCounter);
      moddata(:, channelCounter) =  sgolayfilt(sampleData, 3, 21);
      diff = moddata(:, channelCounter) - sampleData;
      fixfilter = abs(diff)> thresholdAccel;
      moddata(fixfilter, channelCounter)=sampleData(fixfilter)+ ...
        thresholdAccel*sign(diff(fixfilter));
    end
    set(handles.accelPanel, 'UserData', moddata);
    set(handles.statusBox, 'String', 'Loaded data filtered. Refresh.');
  else
    load('filter.mat');
    dataLength = length(moddata);
    paddedNoise = zeros(dataLength, 1);
    noiSeg = double(sampleData(1:1250)); %#ok<NODEF>
    noiSeg=(noiSeg-mean(noiSeg))*getUnitCoefficient(handles, 'accel', 2);
    
    n=zeros(length(sampleData, 0));
    
    
    lengthDif = length(sampleData) - length(noiSeg);
    zeroPad = floor(lengthDif/2);
    noiSeg = [zeros(zeroPad,1);noiSeg;zeros(lengthDif-zeroPad,1)];
    for channelCounter = 1:3
      channelData = moddata(:, channelCounter);
      correl = xcorr(channelData, noiSeg, 'biased');
      get(handles.timePanel, 'UserData');
      expandedTime = [time(length(time):-1:2); time]+median(time);
      localMaxima = (correl(2:end-1)-correl(1:end-2)>.15)&(correl(2:end-1)-correl(3:end)>.15);
    end
  end
end