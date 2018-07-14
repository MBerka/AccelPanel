function loadFile(handles, fullFilePath)
%LOADFILE selects, reads, and parses a file
  
  if ~exist('handles', 'var')
    return;
  end
  
  sampleCount = Inf;
  dimCount = 3;
  
  if ~exist('fullFilePath', 'var')
    fileFieldString = get(handles.filePathField,'String');
    if ~fileFieldString
      fileFieldString = '';
    end

    %   File selected by user
    %   Reads positive integers in the range [0, 9999]. One ASCII bit can
    %   safely encode 100 states, two digits

    set(handles.statusBox, 'String', 'Choosing data file');

    [fileName, filePath, filterIndex] = uigetfile({'*.TXT', 'Text data file'; ...
      '*.mat', 'Processed data file'; '*.mat', 'Settings file'}, ...
      'Select file to load');
    if length(filePath)<2 || length(fileName)<2 || filterIndex==0
      set(handles.statusBox, 'String', 'No file chosen');
      return;
    end

    fullFilePath = [filePath fileName];
  end

  fileData = dir(fullFilePath);
  fileSize = fileData.bytes;

  [~,~,ext] = fileparts(fullFilePath);
  if strcmp(ext, '.mat')
    fileContents = load(fullFilePath);
    if isfield(fileContents, 'settingsStruct') %Separate function for settings
      getRestoreSettings(handles, false, fileContents.settingsStruct);
    end
    if sum(isfield(fileContents, {'timeData', 'sampleData'}))>1
      set(handles.statusBox, 'String', 'Loading processed data file');
      % Easy reading
      time = fileContents.timeData;
      samples = fileContents.sampleData;
      if isfield(fileContents, 'annotationData')
        set(handles.noteButton, 'UserData', fileContents.annotationData);
      else
        set(handles.noteButton, 'UserData', '');
      end
    else
      return; %File contains no time-sample data
    end
  else %Otherwise, complicated procedure to read text file
  
    maxSampleCount = ceil(fileSize / (2*dimCount+2));
    if maxSampleCount<2
      set(handles.statusBox, 'String', 'Too little readable data in file');
      return;
    end

    set(handles.statusBox, 'String', 'Loading raw data file');
    drawnow();
    fileReference = fopen(fullFilePath,'r'); %Open for reading
    if fileReference == -1
      set(handles.statusBox, 'String', 'Could not open data file');
    end

    if ~exist('sampleCount','var')
      sampleCount = maxSampleCount;
    elseif sampleCount>maxSampleCount
      sampleCount = maxSampleCount; %Limit
    end

    adcCenter = [88 236 195] + 2618; 
      %Encoded values are ~200-4095, lower half (2148) should
      %correspond to accelerations in the opposite direction, however:
      %+105 bias from unsigned ADC mode (2.5%, half of the 5% added to the
      %lower boundary)
      %+365 for the .25V difference between the accel voltage center and the 
      %adc voltage center.
      %Add to that measured calibration values.
    adcScale = [1.044 1 0.972]; %682.5/654, 1:1, 682.5/702.
    % 654 is also used as the gravity coefficient; adjust accelUnit.
    %Fast block-based reading: may need to restrict to part of large file
    c=int16(reshape(fscanf(fileReference,['%2c' '%2c' '%2c' '\r\n'], ...
      fileSize/2)-28, 6, [])');
    c=c(:,[1 3 5])*100+c(:,[2 4 6]);
    samples = c(c(:,1)<4096,:); %ADC can produce up to 4095; higher is artificial
    for adcCounter = 1:3
      samples(:, adcCounter) = adcScale(adcCounter) * ...
        (samples(:, adcCounter)-adcCenter(adcCounter));
    end
    samples = int16(samples);
    sampleCounter = length(samples);
    time = mean(c(:,1)>8191)*(1:sampleCounter)';

    tString = get(handles.tUnitList, 'String');
    tUnit = tString{get(handles.tUnitList, 'Value')};
    givenTimes = inputdlg({['Start time (' tUnit ')?'], ...
      ['End time (' tUnit ')?']}, 'Provide known data', 1);
    
    set(handles.fileStatisticsText, 'UserData', ...
      struct('samplesPerSecond', length(time)/(time(end)-time(1))));
    timeFactor = getUnitCoefficient(handles, 'time');
    if isempty(givenTimes)
      startTime = [];
      endTime = [];
    else
      startTime = str2double(givenTimes(1))*timeFactor;
      endTime = str2double(givenTimes(2))*timeFactor;
    end
    
    if (~isempty(startTime)&&~isnan(startTime))
      if (~isempty(endTime)&&~isnan(endTime)) %Rescale
        scaleFactor = (endTime - startTime) / (time(end) - time(1));
        if abs(1-scaleFactor)>.1
          proceed = questdlg('Given and measured times vary > 10%', ...
            'Rescale?');
          if ~strcmp(proceed, 'Yes')
            scaleFactor = 1;
          end
        end
        difFactor = startTime - time(1)*scaleFactor;
        if scaleFactor==1
          time = time+difFactor;
        else
          time = time*scaleFactor+difFactor;
        end
      else
        difFactor = startTime - time(1);
        time = time+difFactor;
      end
    elseif (~isempty(endTime)&&~isnan(endTime))
      difFactor = endTime - time(end);
      time = time+difFactor;
    end
    
    if sampleCounter<sampleCount
      sampleCount = sampleCounter; %#ok<NASGU>
    end

    fclose(fileReference); %Close file and store values
    set(handles.noteButton, 'UserData', ''); %Raw data has no annotations
  end
  
  set(handles.filePathField,'String', fullFilePath);
  set(handles.timePanel, 'UserData', time);
  set(handles.accelPanel, 'UserData', samples);
  
  set(handles.statusBox, 'String', 'Data file loaded');
  
  %Data is loaded, now for statistics

  %Size
  traceMetadata = whos('samples');
  fileStats = struct('size', traceMetadata.bytes, ...
  'seconds', time(end)-time(1));
  
  if fileStats.seconds < 100
    timeLength = [int2str(fileStats.seconds) ' s'];
  elseif fileStats.seconds< 3600
    timeLength = [num2str(fileStats.seconds/60, 3) ' min'];
  elseif fileStats.seconds<36e4
		timeLength = [num2str(fileStats.seconds/3600, 3) ' h'];
	else
		timeLength = [num2str(fileStats.seconds/86400, 3) ' d'];
  end
  
  if fileStats.size < 1e3
    dataSize = [int2str(fileStats.size) ' b'];
  elseif fileStats.size < 1e6
    dataSize = [num2str(fileStats.size/1024, 3) ' KiB'];
  else
    dataSize = [num2str(fileStats.size/1048576, 3) ' MiB'];
  end

  fileStats.samplesPerSecond = length(time)/fileStats.seconds;

  set(handles.fileStatisticsText, 'String', [timeLength ', ' ...
	dataSize ', ' num2str(fileStats.samplesPerSecond, 3) ' samples/s']);
  set(handles.fileStatisticsText, 'UserData', fileStats);
  enableComponents(handles, true);
end
