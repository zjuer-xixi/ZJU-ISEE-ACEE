function quantized_signal = quantization(audio_signal, bits)
    % Quantize the audio signal to the specified number of bits.
    
    % Find the maximum absolute value of the audio signal.
    MAX = max(abs(audio_signal));
    MIN = min(abs(audio_signal));
    
    % Calculate the quantization step size.
    step_size = (MAX - MIN) / (2^bits);
    
    % Quantize the signal.
    quantized_signal = round(audio_signal / step_size) * step_size;    
end