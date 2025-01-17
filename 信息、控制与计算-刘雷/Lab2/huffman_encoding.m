function [encoded_signal, dict] = huffman_encoding(quantized_signal)
    % Perform Huffman encoding on the quantized audio signal.

    % Calculate the probability of each unique value in the signal
    [unique_values, ~, idx] = unique(quantized_signal);
    freq = accumarray(idx, 1);
    probabilities = freq / numel(quantized_signal);

    % Create a Huffman dictionary using the unique values and their probabilities
    dict = huffmandict(unique_values, probabilities);

    % Encode the signal using the generated dictionary
    encoded_signal = huffmanenco(quantized_signal, dict);

end
