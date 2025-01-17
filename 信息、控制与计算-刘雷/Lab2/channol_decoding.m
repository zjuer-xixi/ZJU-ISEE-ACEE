function channol_decoded_signal = channol_decoding(received_signal, n)
    % Reshape the received signal into groups of n for majority voting
    reshaped_signal = reshape(received_signal, n, []);

    % Majority voting to decode each bit without using mode
    channol_decoded_signal = zeros(1, size(reshaped_signal, 2));
    for col = 1:size(reshaped_signal, 2)
        ones_count = sum(reshaped_signal(:, col) == 1);
        zeros_count = sum(reshaped_signal(:, col) == 0);
        if ones_count >= zeros_count
            channol_decoded_signal(col) = 1;
        else
            channol_decoded_signal(col) = 0;
        end
    end
    channol_decoded_signal = channol_decoded_signal(:);
end