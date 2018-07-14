function annotateGraph( handles, noteCommand )
%ANNOTATEGRAPH Adds notes to the graph and saves them
%   handles: figure reference
%   addNote: Determines whether to display all or add and display
%   one. Can be provided with coordinates for the new note, or if value is
%   in other form, will ask user.

% Get graph axes data
  graphHandle = handles.traceAxes;
  graphYRange = get(graphHandle, 'YLim');
  graphXRange = get(graphHandle, 'XLim');
  ySpacer = 0.02*(graphYRange(2)-graphYRange(1));
  noteDefaultY = graphYRange(1) + 0.94*(graphYRange(2)-graphYRange(1));
  noteLineShift = 0.05*(graphYRange(2)-graphYRange(1));
  %Default height for bottom of annotation text
  timeFactor = getUnitCoefficient(handles, 'time');;
  
  if ~exist('noteCommand', 'var')
    noteCommand = 'show';
  end
  if isstruct(noteCommand)
    createNote(noteCommand);
  elseif strcmp(noteCommand, 'add')
    createNote(); 
  elseif strcmp(noteCommand, 'clear')
    %Clear annotation objects
    clearNoteObjects();
  else
    displayAllNotes();
  end
  
  
  function clearNoteObjects
    existingObjects = get(handles.statusBox, 'UserData');
    delete(existingObjects(ishandle(existingObjects) & existingObjects ~= 0));
  end
  
  
  function createNote(noteStruct)
    response = '';
    color = 'black';
    textX = 0;
    saveNote = true;
    if exist('noteStruct', 'var')
      if isfield(noteStruct, 'text')
        response = noteStruct.text;
      end
      if isfield(noteStruct, 'color')
        color = noteStruct.color;
      end
      if isfield(noteStruct, 'position')
        textX = noteStruct.position;
      end
      if isfield(noteStruct, 'save')
        saveNote = noteStruct.save;
      else
        saveNote = false;
      end
    end
    
    if textX == 0
      [textX, ~] = quickGInput(1);
    end
    noteTime = textX*timeFactor; %Convert from graph unit to seconds
    
    if isempty(response)
      response = inputdlg({'Enter message:'}, 'Annotate', 1, {''});
      if isempty(response)
        set(handles.statusBox, 'String', 'Annotation canceled');
        return;
      end
    end
    
    if saveNote
      annotationList = get(handles.noteButton, 'UserData');
      if isempty(annotationList)
        annotationList = cell(0,2);
      end
      
      newNoteIndex = size(annotationList, 1) + 1;
      
      % Store variables
      annotationList{newNoteIndex, 1} = noteTime;
      annotationList{newNoteIndex, 2} = response{1};
      annotationList = sortrows(annotationList, 1); %Sorting makes it 
        %easier to annotate space on the graph.
      set(handles.noteButton, 'UserData', annotationList);
    end
    
    objectList = get(handles.statusBox, 'UserData');
    newObjects = displayNote(textX, response, color, Inf)';
    set(handles.statusBox, 'UserData', [objectList; newObjects]);
    
    set(handles.statusBox, 'String', 'Note added.');
  end
  

  function displayAllNotes()
    %Updates the notes shown on the graph
    clearNoteObjects();
    
%     Annotate the graph with all notes within its time range
    noteList = get(handles.noteButton, 'UserData');
    newObjectList = zeros(size(noteList,1)*2, 1);
    lastNoteEdge = zeros(9, 2);
    lastNoteEdge(1, 1:2) = [noteDefaultY graphXRange(1)];
    for lineCounter = 2:length(lastNoteEdge)
      lastNoteEdge(lineCounter, 1) = lastNoteEdge(lineCounter-1,1)-noteLineShift;
    end
    
    if size(noteList, 2)>0
      for noteCounter = 1:size(noteList, 1)
        noteX = noteList{noteCounter, 1}/timeFactor;
        if noteX>graphXRange(1) && noteX<graphXRange(2)
          if noteList{noteCounter, 2}
            [newObjectList(2*noteCounter-1:2*noteCounter), lastLine] = ...
              displayNote(noteX, noteList{noteCounter, 2}, 'black', lastNoteEdge);
          else
            [newObjectList(2*noteCounter-1:2*noteCounter), lastLine] = ...
              displayNote(noteX, '', 'red', lastNoteEdge, lastLine);
          end
          noteLine = get(newObjectList(2*noteCounter-1), 'UserData');
          lastNoteExtent = get(newObjectList(2*noteCounter-1), 'Extent');
          if lastNoteEdge(noteLine, 2) < noteX + lastNoteExtent(3)
            lastNoteEdge(noteLine, 2) = noteX + lastNoteExtent(3);
          end
        end
      end
      newObjectList = newObjectList(1:find(newObjectList, 1, 'last'));
      % Trim 0's
      
      set(handles.statusBox, 'UserData', newObjectList);
    end
  end


  function [objectList, lineCounter] = displayNote(noteX, noteText, color, textEdge, lastLine)
    if textEdge(1)==Inf
      lineCounter = 0;
      noteY = noteDefaultY + noteLineShift;
    else
      noteY = noteDefaultY;
%       if strcmp(noteText, '')
%         lineCounter = lastLine;
%         noteY = textEdge(lineCounter, 1);
%       elseif...
      if exist('textEdge', 'var')
        lineCounter = 1;
        while noteX<textEdge(lineCounter, 2)
          lineCounter = lineCounter + 1;
        end
        noteY = textEdge(lineCounter, 1);
      else
        lineCounter = 1;
      end
    end

    %previousNoteX = GET EXTENT X OF PREVIOUS NOTE, ADD width, compare to
    %note X, move down if exceede, default otherwise.
    objectList(1) = text(noteX, noteY, noteText);
    set(objectList(1), 'Color', color);
    set(objectList(1), 'UserData', lineCounter);
    objectList(2) = line([noteX noteX], ...
      [graphYRange(1)+.2*(graphYRange(2)-graphYRange(1)) noteY-ySpacer], ...
      'Color', color, 'DisplayName', '');
  end


  function [x, y] = quickGInput(clickNumber)
    % Removes much of ginput functionality to quickly return 2D coordinates
    % on large plots

    if ~exist('clickNumber', 'var')
      clickNumber = 1;
    end
    
    oldPointer = get(gcf, 'Pointer');
    set(gcf, 'Pointer', 'crosshair');
    axesToClick = gca;

    x = zeros(1, clickNumber);
    y = x;
    
    set(handles.statusBox, 'String', 'Click on the graph to select a time');

    for clickCounter = 1:clickNumber
      prevPoint = get(axesToClick, 'CurrentPoint');
      newPoint = prevPoint;

      while ~sum(newPoint~=prevPoint)
        drawnow();
        newPoint = get(axesToClick, 'CurrentPoint');
      end

      x(clickCounter) = newPoint(1, 1);
      y(clickCounter) = newPoint(1, 2);
    end

    set(gcf, 'Pointer', oldPointer); %Restore what was before
  end
end