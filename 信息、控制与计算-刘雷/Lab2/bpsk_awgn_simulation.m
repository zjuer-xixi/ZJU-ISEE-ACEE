function received_signal = bpsk_awgn_simulation(encoded_channel_signal, snr)
    % BPSK with AWGN Channel Simulation: Simulate BPSK modulation, AWGN transmission, and BPSK demodulation

    % BPSK Modulation: Map bits to -1 and +1
    modulated_signal = 2*encoded_channel_signal - 1;

    % Transmit over AWGN channel
    noisy_signal = awgn(modulated_signal, snr, 'measured');

    % BPSK Demodulation: Map received values back to binary (1 or 0)
    received_signal = double(noisy_signal > 0);

    disp('BPSK modulation, AWGN channel transmission, and demodulation completed successfully.');
end
