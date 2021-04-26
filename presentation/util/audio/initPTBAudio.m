function [pahandle] = initPTBAudio(fs)
    % Audio parameters for PsychPortAudio

    % get correct audio device
    device = [];  % system default is our default as well
    % we only change audio device in the lab, when we see the correct audio
    % card
    tmpDevices = PsychPortAudio('GetDevices');
    for i = 1:numel(tmpDevices)
        if strcmp(tmpDevices(i).DeviceName, 'ESI Juli@: ICE1724 (hw:2,0)')
            device = tmpDevices(i).DeviceIndex;
        end
    end

    % mode is simple playback
    mode = 1;
    % reqlatencyclass is set to low-latency
    reqLatencyClass = 2;
    % 2 channels output
    nrChannels = 2;

    % user message
    disp([newline, 'Set audio parameters']);
    
    % open PsychPortAudio device for playback
    pahandle = PsychPortAudio('Open', device, mode, reqLatencyClass, fs, nrChannels);

    % get and display device status
    pahandleStatus = PsychPortAudio('GetStatus', pahandle);
    disp([newline, 'PsychPortAudio device status: ']);
    disp(pahandleStatus);

    % initial start & stop of audio device to avoid potential initial latencies
    tmpSound = zeros(2, fs/10);  % silence
    tmpBuffer = PsychPortAudio('CreateBuffer', [], tmpSound);  % create buffer
    PsychPortAudio('FillBuffer', pahandle, tmpBuffer);  % fill the buffer of audio device with silence
    PsychPortAudio('Start', pahandle, 1);  % start immediately
    PsychPortAudio('Stop', pahandle, 1);  % stop when playback is over
end