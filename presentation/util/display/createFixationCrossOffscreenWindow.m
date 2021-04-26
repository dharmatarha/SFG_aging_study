function fixCrossWin = createFixationCrossOffscreenWindow(win, backGroundColor, textColor, rect)
    % set up a central fixation cross into a texture / offscreen window
    % get the centre coordinate of the window
    [xCenter, yCenter] = RectCenter(rect);
    % Here we set the size of the arms of our fixation cross
    fixCrossDimPix = 40;
    % set the coordinates
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    % set the line width for our fixation cross
    lineWidthPix = 4;
    
    % command to draw the fixation cross
    fixCrossWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
    Screen('BlendFunction', fixCrossWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('DrawLines', fixCrossWin, allCoords,...
        lineWidthPix, textColor, [xCenter yCenter], 2);
end