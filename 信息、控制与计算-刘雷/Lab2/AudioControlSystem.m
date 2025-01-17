%% Main Entrance to Perform Complete Audio Signal Processing and Transmission Simulation
Qbits = 8;
n = 3;  % Number of repetitions per bit

% Step 1: Load Audio File
filename = '6.wav'; 
[audio_signal, fs] = audioread(filename);
disp(['Loaded audio file: ', filename]);

% Step 2: Quantization (8-bit)
quantized_signal = quantization(audio_signal, Qbits); 
disp('Quantization complete.');

% Display quantized signal and difference with original
figure;
subplot(3,1,1);
plot(audio_signal);
title('Original Audio Signal');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(3,1,2);
plot(quantized_signal, 'r');
title('Quantized Audio Signal');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(3,1,3);
plot(quantized_signal - audio_signal, 'g');
title('Differnece between two signals');
xlabel('Sample Index');
ylabel('Amplitude');

% Step 3: Huffman Encoding
[encoded_signal, dict] = huffman_encoding(quantized_signal); 
disp('Huffman encoding complete.');

disp('Huffman Dictionary:');
for j = 1:length(dict)
    fprintf('Symbol: %.2f -> Code: %s\n', dict{j,1}, num2str(dict{j,2}));
end

for j = 1:length(dict)
    % Calculate probabilities
    symbol = dict{j,1};
    code = dict{j,2};
    prob = sum(quantized_signal == symbol) / length(quantized_signal);
    symbol_probabilities(j) = prob;
    code_lengths(j) = length(code);
end

% Calculate Source Entropy H(X)
entropy_HX = -sum(symbol_probabilities .* log2(symbol_probabilities));
disp(['Source Entropy H(X): ', num2str(entropy_HX), ' bits/symbol']);

% Calculate Code Rate R
code_rate_R = sum(symbol_probabilities .* code_lengths);
disp(['Code Rate R: ', num2str(code_rate_R), ' bits/symbol']);

% Step 4: Channel Encoding
channol_encoded_signal = channol_encoding(encoded_signal, n);
disp('Repetition encoding completed successfully.');

% Step 5: BPSK Modulation and AWGN Channel Transmission
snr = 20; 
received_signal = bpsk_awgn_simulation(channol_encoded_signal, snr);  
disp('BPSK modulation and transmission through AWGN channel complete.');

% Step 6: Channel Decoding (Repetition Decoding)
channol_decoded_signal = channol_decoding(received_signal, n);

% Step 7: Huffman Decoding
reconstructed_signal = huffman_decoding(channol_decoded_signal, dict);
disp('Huffman decoding complete.');

% Display Reconstructed Signal and Difference with Original
figure;
subplot(2,1,1);
plot(reconstructed_signal);
title('Reconstructed Signal');
xlabel('Sample Index');
ylabel('Amplitude');

subplot(2,1,2);
plot(audio_signal - reconstructed_signal, 'Color',[0.4,0.2,0.7]);
title('Difference Between Original and Reconstructed Signal');
xlabel('Sample Index');
ylabel('Amplitude');

%% CNN Classification
disp('Passing the reconstructed signal through the CNN...');

% Step 8: Preprocessing for CNN (MFCC Extraction)
numCoeffs = 13; 

reconstructed_signal = reconstructed_signal / max(abs(reconstructed_signal));

% Extract MFCC features
test_features = mfcc(audio_signal, fs, 'NumCoeffs', numCoeffs);
test_features = test_features';  

[~, nCols] = size(test_features);

% Reshape the data to match CNN input format
test_features = reshape(test_features, [size(test_features,1), size(test_features,2), 1, 1]);

% Step 9: Load the pre-trained CNN model 
load('trained_cnn.mat'); 

% Step 10: Classify the signal using the CNN
YPred = classify(net, test_features);
disp(['Predicted Class: ', char(YPred)]);

%% Control System
YPred_num = double(YPred);  % Convert prediction to numerical form

% Control Force Based on Predicted Class
if YPred_num == 1
    F = 5000;
elseif YPred_num == 2
    F = -5000;
else
    F = -50000;
end

% Parameters
M = 1500;          % Mass of the robot (kg)
b = 200;           % Friction coefficient (N·s/m)
a = 20;            % Coefficient of depth impact (N/m)
v0 = 5;            % Initial velocity (m/s)
y0 = 0;            % Initial depth (m)
v_max = 40;        % Maximum velocity limit (m/s)
v_min = 0;         % Minimum velocity limit (m/s)
t_span = [0 5];    % Simulation time range (s)

% Define the state-space system considering velocity control
% x(1) = y (depth), x(2) = v (velocity)
velocity_control_ode = @(t, x) [x(2);
                                (F * (x(2) < v_max && x(2) > v_min) - b * x(2) - a * x(1)) / M];

% Solve the ODE using ode45
[t, x] = ode45(velocity_control_ode, t_span, [y0 v0]);

% Plot the velocity curve
figure
plot(t, x(:,2), 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Velocity (m/s)');
title('Robot Velocity Over Time with Speed Control');
legend(sprintf('F = %.2f N, M = %.2f kg, b = %.2f, a = %.2f', F, M, b, a));



