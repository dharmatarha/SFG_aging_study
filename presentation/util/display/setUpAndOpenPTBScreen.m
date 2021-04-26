function [win, rect, ifi] = setUpAndOpenPTBScreen(screenNumber, backGroundColor)
    % open stimulus window
    [win, rect] = Screen('OpenWindow', screenNumber, backGroundColor);

    % query frame duration for window
    ifi = Screen('GetFlipInterval', win);
    % set up alpha-blending for smooth (anti-aliased) lines
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    % Setup the text type for the window
    Screen('TextFont', win, 'Ariel');
    Screen('TextSize', win, 30);
end