function reconstructed_signal = huffman_decoding(decoded_signal, dict)
    % Huffman Decoding Function

    % Perform Huffman decoding
    reconstructed_signal = huffmandeco(decoded_signal, dict);

    disp('Huffman decoding completed successfully.');
end
