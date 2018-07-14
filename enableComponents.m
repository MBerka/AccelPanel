function enableComponents( handles, newState )
%ENABLECOMPONENTS Sets components requiring loaded data to on or off
%   newState: boolean or 'on'/'off', defaults to 'on'
  if ~exist('newState', 'var')
    newState = 'on';
  else
    if strcmp(newState, 'off')
      newState = 'off';
    elseif newState
      newState = 'on';
    else
      newState = 'off';
    end
  end
  componentList = {'refreshViewButton', 'zoomInIcon', 'zoomOutIcon', ...
    'panIcon', 'dataCursorIcon', 'manualRangeButton', ...
    'selectDataButton', 'analyzeButton',};
  for componentCounter = 1:length(componentList)
    set(handles.(componentList{componentCounter}), 'Enable', newState)
  end
end

