% 基本参数设置
Rb = 50;                  % 码元速率 (bps)
Tb = 1/Rb;                % 码元的持续时间 (s)
Fc = 5e3;                 % 载波频率 (Hz)
Fs = 10*Fc;               % 采样频率 (Hz)
alpha = 0.25;             % 滚降因子
SNR = [-20, 5];           % 信噪比 (dB) 

% 输入数字序列
data = [0 1 1 1 0 1 0 0 0 1 1 1];
N = length(data); 
t = 0:1/Fs:N*Tb-1/Fs;

% 生成基带信号
baseband = kron(2*data-1, ones(1, Fs*Tb));

% 升余弦成型滤波器
span = 10; 
rrcFilter = rcosdesign(alpha, span, Fs*Tb, 'sqrt');
baseband_filtered = conv(baseband, rrcFilter, 'same');

% BPSK 调制
carrier = cos(2*pi*Fc*t);
bpsk_signal = baseband_filtered .* carrier;

% 显示基带信号和调制信号
figure;
subplot(3,1,1); plot(t, baseband_filtered); title('Baseband Signal');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(3,1,2); plot(t, bpsk_signal); title('BPSK Modulated Signal');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(3,1,3); pwelch(bpsk_signal,[],[],[],Fs); title('Spectrum of BPSK Signal');

% 通过不同SNR条件传输信号
for k = 1:length(SNR)
    rx_signal = awgn(bpsk_signal, SNR(k), 'measured');

    % 接收信号可视化
    figure;
    subplot(2,1,1);
    plot(t, rx_signal); title(['Received Signal with SNR = ', num2str(SNR(k)), ' dB']);
    xlabel('Time (s)'); ylabel('Amplitude');
    subplot(2,1,2);
    pwelch(rx_signal,[],[],[],Fs); title(['Spectrum of Received Signal with SNR = ', num2str(SNR(k)), ' dB']);

    % 基函数相干解调
    demod_signal = rx_signal .* cos(2*pi*Fc*t);
    demod_signal = conv(demod_signal, rrcFilter, 'same');

    num_symbols = length(data);
    demodulated = zeros(1, num_symbols);
    for i = 1:num_symbols
        start_idx = (i-1)*Fs*Tb + 1;
        end_idx = i*Fs*Tb;
        demodulated(i) = trapz(t(start_idx:end_idx), demod_signal(start_idx:end_idx));
    end

    % 判决规则
    received_bits = demodulated > 0;

    % 误码率计算
    [~, ber] = biterr(data, received_bits);

    % 显示判决后的波形
    figure;
    subplot(2,1,1);
    stem(data, 'ro'); hold on;
    stem(received_bits, 'b*');
    legend('Original Data', 'Received Data');
    title(['Decision Results (SNR = ', num2str(SNR(k)), ' dB)']);
    xlabel('Bit Index'); ylabel('Amplitude');

    % 显示解调后的波形
    subplot(2,1,2);
    plot(1:num_symbols, demodulated, '-o');
    title('Demodulated Signal');
    xlabel('Symbol Index'); ylabel('Amplitude');

    disp(['SNR = ', num2str(SNR(k)), ' dB, BER = ', num2str(ber)]);
end


