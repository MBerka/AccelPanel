function mergeFiles(handles)
%ACCELFILEOPPANEL Iterface for splitting/merging 
%   Detailed explanation goes here
  if ~exist('handles', 'var')
    return;
  end
  [fileNames, pathName] = uigetfile({'*.TXT', 'Text data file'; ...
      '*.mat', 'Processed data file'}, ...
      'Select files to load and merge', 'MultiSelect', 'on');
  if ~iscell(fileNames)||((length(fileNames)<2) && (length(pathName)<2))
    set(handles.statusBox, 'String', 'Too few files to merge');
    return;
  end
  
  fullSampleData = cell([length(fileNames) 1]);
  fullTimeData = cell([length(fileNames) 1]);
  
  for fileCounter = 1:length(fileNames)
    loadFile(handles, [pathName fileNames{fileCounter}]);
    fullTimeData{fileCounter} = get(handles.timePanel, 'UserData');
    if ~exist('endOfLastTimeStretch', 'var')
      endOfLastTimeStretch = fullTimeData{1}(1); %First instant
    end
    timeOffset = endOfLastTimeStretch - fullTimeData{fileCounter}(1);
    fullTimeData{fileCounter} = fullTimeData{fileCounter} + timeOffset;
    endOfLastTimeStretch = fullTimeData{fileCounter}(end);
    fullSampleData{fileCounter} = get(handles.accelPanel, 'UserData');
  end
  
  [fileName, pathToFile] = uiputfile({'*.mat', 'Processed data file'}, ...
    'Enter name for merged file');
  if (length(fileName)<2)||(length(pathToFile)<2)
    return;
  end
  
  set(handles.statusBox, 'String', 'Saving merged data');
    
  sampleData = cat(1, fullSampleData{:});
  timeData = cat(1, fullTimeData{:});
  
  save([pathToFile fileName], 'timeData', 'sampleData');
  set(handles.statusBox, 'String', 'Merged data saved to file');
  
%     fileData = whos('-file', [pathName fileNames{fileCounter}]);
%     varNames = {fileData.name};
%     localVarSizes = {fileData.size};
%     validSizes = true;
%     for varCounter = 1:length(varNames)
%       thisVarSizes = localVarSizes{varCounter};
%       if ~isfield(totalVarSizes, varNames{varCounter})
%         totalVarSizeList.varNames{varCounter}.TOTAL = thisVarSizes;
%       else
%         existingVarSizes = totalVarSizeList.varNames{varCounter};
%         [existingVarLength, existingVarDim] = max(existingVarSizes);
%         [existingVarWidth, existingConstDim] = min(existingVarSizes);
%         [newVarLength, newVarDim] = max(thisVarSizes);
%         [newVarWidth, newConstDim] = min(thisVarSizes);
%         
%         if (existingVarWidth~=newVarWidth) || (existingConstDim~=newConstDim)
%           validSizes = false;
%         else
%           totalVarSizeList.varNames{varCounter}.TOTAL
%         end
%       end
%     end
%     if validSizes
%       loadFile(handles, [pathName fileNames{fileCounter}]);
%       for
%       totalVarSizes.varNames{varCounter}.fileName =
%     else
%       set(handles.statusBox, 'String', ['Skipping ' fileNames{fileCounter}]);
%     end
%   end
%   
%   varNames = fieldnames(totalVarSizes);
%   
%   for varCounter = 1:length(varNames)
%     C = cat(dim, C{:});
%   end
end

