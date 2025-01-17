function channol_encoded_signal = channol_encoding(encoded_signal, n)
    % n: Number of repetitions per bit

    % Initialize the encoded signal array
    channol_encoded_signal = zeros(1, length(encoded_signal) * n); 

    % Perform repetition encoding
    for i = 1:length(encoded_signal)
        for j = 1:n
            channol_encoded_signal((i-1)*n+j) = encoded_signal(i);
        end
    end
end



