%% Audio Signal Data Process
file_paths = {'1.wav', '2.wav', '3.wav'};

audio_vectors = {};
labels = [];

% Set number of MFCC coefficients
numCoeffs = 13;  

% Loop through audio files for feature extraction
for i = 1:length(file_paths)
    % Read audio file
    [audio_signal, Fs] = audioread(file_paths{i});
    
    % Normalize audio signal
    audio_signal = audio_signal / max(abs(audio_signal));
    
    % Extract MFCC features
    features = mfcc(audio_signal, Fs, 'NumCoeffs', numCoeffs)';
    [~, cols] = size(features);

    % Store features and labels
    audio_vectors{end+1} = features;
    labels = [labels; i];
end

% Convert cell array to 4D array (required for CNN input)
XTrain = cat(4, audio_vectors{:});  
YTrain = categorical(labels);       

%% CNN Architecture
layers = [
    imageInputLayer([numCoeffs+1 cols 1]) 
    convolution2dLayer([3 3],16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer([3 3],32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    
    fullyConnectedLayer(3) % 3 Classes
    softmaxLayer
    classificationLayer
];

% Set Training Options
options = trainingOptions('adam', ...
    'MaxEpochs',50, ...
    'MiniBatchSize',1, ...
    'InitialLearnRate',1e-3, ...
    'Verbose',true, ...
    'Plots','training-progress');

% Train the CNN 
net = trainNetwork(XTrain, YTrain, layers, options);

% Save the trained CNN model to a .mat file
save('trained_cnn.mat', 'net');
disp('CNN model saved as trained_cnn.mat');
