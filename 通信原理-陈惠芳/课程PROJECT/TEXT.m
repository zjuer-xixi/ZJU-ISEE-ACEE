% 基本参数设置
Rb = 50;                   % 码元速率 (bps)
Tb = 1/Rb;                 % 码元持续时间 (s)
Fc = 5e3;                  % 载波频率 (Hz)
Fs = 10*Fc;                % 采样频率 (Hz)
alpha = 0.25;              % 滚降因子
SNR = [-10, -5, 0, 5, 10]; % 信噪比 (dB)

% 输入文本转为ASCII码
text = 'Although individual definitions of communication vary, those definitions often include some of the same essential elements. Seven important components of the communication process include participants, symbols, encoding, decoding, channels, feedback, and noise.';
ascii_data = double(text);
binary_data = dec2bin(ascii_data, 8)';
binary_data = binary_data(:)' - '0';

% 生成基带信号
N = length(binary_data);
t = 0:1/Fs:(N*Tb - 1/Fs);
baseband = kron(2*binary_data-1, ones(1, Fs*Tb));

% 升余弦成型滤波器 (RRC) 
span = 10;
rrcFilter = rcosdesign(alpha, span, Fs*Tb, 'sqrt');

% 对基带信号进行脉冲成形
baseband_filtered = conv(baseband, rrcFilter, 'same');

% BPSK 调制（上变频）
carrier = cos(2*pi*Fc*t);
bpsk_signal = baseband_filtered .* carrier;

% 不同SNR下传输与解调
for k = 1:length(SNR)
    % 加性高斯白噪声
    rx_signal = awgn(bpsk_signal, SNR(k), 'measured');

    % 接收端相干下变频：r(t)*cos(2*pi*Fc*t)
    demod_signal = rx_signal .* cos(2*pi*Fc*t);
    demod_signal = conv(demod_signal, rrcFilter, 'same');

    % 对每个符号区间进行积分判决
    demodulated = zeros(1, N);
    samples_per_symbol = Fs*Tb;
    for i = 1:N
        start_idx = (i-1)*samples_per_symbol + 1;
        end_idx = i*samples_per_symbol;
        % 对匹配滤波后的信号在一个码元间隔上积分
        demodulated(i) = trapz(demod_signal(start_idx:end_idx));
    end

    % 判决规则：正判为1，负判为0
    received_bits = demodulated > 0;

    % 译码为ASCII文本
    received_binary = reshape(received_bits, 8, []).';
    received_ascii = char(bin2dec(num2str(received_binary))');

    % 计算误码率
    [num_bit_errors, ber] = biterr(binary_data, received_bits);
    total_bits = length(binary_data);

    % 按字符（码元）统计误码
    original_ascii = reshape(binary_data, 8, []).';
    decoded_ascii = reshape(received_bits, 8, []).';
    num_code_errors = sum(~all(original_ascii == decoded_ascii, 2));
    total_codes = size(original_ascii, 1);

    % 显示结果
    disp(['SNR = ', num2str(SNR(k)), ' dB']);
    disp('Decoded Text:');
    disp(received_ascii);
    disp(['Total Bits: ', num2str(total_bits), ', Bit Errors: ', num2str(num_bit_errors), ', Bit Error Rate (BER): ', num2str(ber)]);
    disp(['Total Codes: ', num2str(total_codes), ', Code Errors: ', num2str(num_code_errors)]);
end



