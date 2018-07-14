function settingsStruct = getRestoreSettings(handles, getMore, newSettings)
%GETRESTORESETTINGS Gets the customizable settings of components
%   newSettings: multi-layer structure, component-field-value
%   getMore: if true, will gather all UserData and graphical
%   content
%   settingsStruct: output analogous to newSettings
  if ~exist('handles','var')
    return;
  end
  if exist('newSettings', 'var')
    set(handles.statusBox, 'String', 'Loading settings file');
    componentList = fieldnames(newSettings);
    for componentCounter = 1:length(componentList)
      componentName = componentList{componentCounter};
      fieldList = fieldnames(newSettings.(componentName));
      for fieldCounter = 1:length(fieldList)
        fieldName = fieldList{fieldCounter};
        newFieldVal = newSettings.(componentName).(fieldName);
        if sum(strcmp(fieldName, {'SelectedObject', 'CurrentAxes'}))
          newFieldVal = handles.(newFieldVal); %Convert tag to reference
          if strcmp(fieldName, 'CurrentAxes')
            axes(newFieldVal); %#ok<LAXES>
          end
        end
        set(handles.(componentName), fieldName, newFieldVal);
      end
    end
    set(handles.statusBox, 'String', 'Settings loaded');
  else
    set(handles.statusBox, 'String', 'Saving settings to file');
    saveFields = {'BLANKFIELD'};
    if exist('getMore', 'var')
      if getMore
        saveFields = {'BLANKFIELD', 'UserData', 'XData', 'YData', ...
          'ZData', 'Enable', 'Visible', 'XLim'};
        % First field for replacement with field relevant to component; 
        % appending may be necessary to add more fields
      end
    end
    
    settingsStruct = struct();
    componentList = fieldnames(handles);
    for componentCounter = 1:length(componentList)
      thisComponent = handles.(componentList{componentCounter});
      
%       saveFields = {'UserData'}; %Multiple fields can be saved
      if strcmp(get(thisComponent, 'Type'), 'uicontrol')
        switch get(thisComponent, 'Style')
          case 'edit'
            if strcmp(get(thisComponent, 'Enable'), 'on')
              saveFields{1} = 'String';
            end
          case {'checkbox', 'listbox', 'popupmenu'}
            saveFields{1} = 'Value';
          otherwise
        end
      elseif strcmp(get(thisComponent, 'Type'), 'uipanel')
        saveFields{1} = 'SelectedObject';
      elseif strcmp(get(thisComponent, 'Type'), 'uitoggletool')
        saveFields{1} = 'State';
      elseif strcmp(get(thisComponent, 'Type'), 'figure')
        saveFields{1} = 'CurrentAxes';
      end
      
      fieldList = get(thisComponent);
      fieldsToGet = saveFields(isfield(fieldList,saveFields));
      savedFields = 0;
      theseSettings = struct();
      
      for fieldCounter = 1:length(fieldsToGet)
        fieldName = fieldsToGet{fieldCounter};
        thisFieldVal = fieldList.(fieldName);
        if sum(strcmp(fieldName, {'SelectedObject', 'CurrentAxes'})) 
          %Fun with button groups
          thisFieldVal = get(thisFieldVal, 'Tag'); %Reference will break
        end
        
        if ~ishandle(thisFieldVal)
          %Let other handle connections be created during initialization
          recordThisVal = true;
        elseif strcmp(fieldName, 'Value')
          recordThisVal = true;
        else
          recordThisVal = false;
        end
        if recordThisVal
          theseSettings.(fieldsToGet{fieldCounter}) = thisFieldVal;
          savedFields = savedFields+1;
        end
      end
      if savedFields
        settingsStruct.(componentList{componentCounter}) = theseSettings;
      end
    end
    set(handles.statusBox, 'String', 'Settings saved');
  end
  
end