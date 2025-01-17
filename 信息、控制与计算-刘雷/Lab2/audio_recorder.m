function audio_recorder()
    % Set audio recording parameters
    Fs = 44100;      % Sampling frequency (Hz)
    nBits = 16;      % Bit depth
    nChannels = 1;   % Number of channels (1 for mono)
    recDuration = 2; % Recording duration (seconds)

    recObj = audiorecorder(Fs, nBits, nChannels);

    disp('Prepare to start recording...');
    pause(2);
    disp('Recording started... Speak now.');

    % Start recording and block until complete
    recordblocking(recObj, recDuration);
    disp('Recording finished!');

    % Get the recorded audio data
    audio_signal = getaudiodata(recObj);

    % Play back the recorded audio
    disp('Playing back the recorded audio...');
    play(recObj);
    pause(recDuration + 1); 

    audiowrite("4.wav", audio_signal, Fs);
    disp('Audio saved to file');
end

