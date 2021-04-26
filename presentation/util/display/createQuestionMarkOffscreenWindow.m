function qMarkWin = createQuestionMarkOffscreenWindow(win, backGroundColor, textColor, rect)
    % set up the question mark (stimulus marking response period) into a
    % texture / offscreen window
    % get the centre coordinate of the window
    [xCenter, yCenter] = RectCenter(rect);
    qMarkWin = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
    Screen('BlendFunction', qMarkWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', qMarkWin, 50);
    Screen('DrawText', qMarkWin, '?', xCenter-15, yCenter-15, textColor);
end