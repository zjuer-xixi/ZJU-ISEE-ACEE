function encoded_signal = repetition_encoding(input_signal, n)
    % Repetition Encoding Function
    % input_signal: The signal to be encoded
    % n: Number of repetitions per bit

    % Repeat each bit n times
    encoded_signal = repelem(input_signal, n);

    disp('Repetition encoding completed successfully.');
end

