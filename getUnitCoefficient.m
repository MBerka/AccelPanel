function [ coefficient, unit ] = getUnitCoefficient( handles, type, selectedInd )
%TIMECOEFFICIENT Returns coefficient and unit name corresponding to dropdown
%selection
%   type: 'time' or none to return time, anything else to return
%   acceleration
%   selectedInd: optional index of unit in dropdown list, ignores current
%   selection
  if ~exist('type', 'var')
    type = 'time'
  end
  
  if strcmp(type, 'time')
    if ~exist('selectedInd', 'var')
      selectedInd = get(handles.tUnitList, 'Value');
    end
    switch selectedInd  %Choose coefficient for time units
      case 1
        fileStats = get(handles.fileStatisticsText, 'UserData');
        coefficient = 1/fileStats.samplesPerSecond;
      case 2
        coefficient = 1;
      case 3
        coefficient = 60;
      case 4
        coefficient = 3600;
    end
    unitList = get(handles.tUnitList, 'String');
  else
    if ~exist('selectedInd', 'var')
      selectedInd = get(handles.accelUnitList, 'Value');
    end
    unitsPerGrav = 682.5/2; %Half the standard 2g difference as found in 
    % the 1-g calibration tests.
    switch selectedInd %Choose coefficient for time units
      case 1
        coefficient = 1;
      case 2
        coefficient = 1/unitsPerGrav; %g per dimensionless
      case 3
        coefficient = 9.81/unitsPerGrav; %m/s^2 per dimensionless
    end
    unitList = get(handles.accelUnitList, 'String');
  end
  unit = unitList{selectedInd, :};
end

