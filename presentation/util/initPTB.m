function [pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs)
    %% Psychtoolbox initialization
    
    [pahandle] = initPTBAudio(fs);

    % General init (AssertOpenGL, 'UnifyKeyNames')
    PsychDefaultSetup(1);

    % init PsychPortAudio with pushing for lowest possible latency
    InitializePsychSound(1);

    % Keyboard params - names
    KbNameSub = 'Logitech USB Keyboard'; % TODO move to params
    KbNameExp = 'CASUE USB KB';
    % detect attached devices
    [keyboardIndices, productNames, ~] = GetKeyboardIndices;
    % define subject's and experimenter keyboards
    KbIdxSub = keyboardIndices(ismember(productNames, KbNameSub));
    KbIdxExp = keyboardIndices(ismember(productNames, KbNameExp));
    
    % Force costly mex functions into memory to avoid latency later on
    GetSecs; WaitSecs(0.1); KbCheck();

    % screen params, screen selection
    screens=Screen('Screens');
    screenNumber=max(screens);  % look into XOrgConfCreator and XOrgConfSelector 
end