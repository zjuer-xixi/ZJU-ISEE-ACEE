% 参数设置
lambda = 0.5;        % 正则化参数
t = 0.01;             % 学习率（步长）
max_iter = 5000;      % 最大迭代次数

% 加载图像
RGB = imread('raw_figure.png');
image = rgb2gray(RGB); % 转换为灰度图像
image = double(image); % 转换为 double 类型

% 添加噪声并归一化
y_noisy = image + 20 * randn(size(image));
maxu = max(y_noisy(:)); minu = min(y_noisy(:));
y_noisy = (y_noisy - minu) / (maxu - minu);

% 统一归一化到 [0, 1]
max_image = max(image(:));
min_image = min(image(:));
image = (image - min_image) / (max_image - min_image);

% 初始化
u = y_noisy; % 初始估计
gradient_norms = zeros(max_iter, 1); % 保存梯度二范数
function_values = zeros(max_iter, 1); % 保存优化函数值
psnr_values = zeros(max_iter, 1); % 保存 PSNR

% 梯度下降迭代
for iter = 1:max_iter

    if iter < 1000
        t = 0.1;
    elseif iter < 3000
        t = 0.05;
    else
        t = 0.01;
    end

    % 计算拉普拉斯算子 Δx
    lap_x = imfilter(u, [0 1 0; 1 -4 1; 0 1 0], 'replicate');
    
    % 梯度计算
    grad = u - y_noisy - 2 * lambda * lap_x;
    
    % 计算梯度二范数
    gradient_norms(iter) = norm(grad(:), 2);
    
    % 计算优化函数值
    function_values(iter) = 0.5 * norm(u(:) - y_noisy(:), 2)^2 + ...
                            lambda * sum(sum((u(:, 2:end) - u(:, 1:end-1)).^2)) + ...
                            lambda * sum(sum((u(2:end, :) - u(1:end-1, :)).^2));
    
    % 更新 u
    u = u - t * grad;
    
    % 计算 PSNR
    psnr_values(iter) = psnr(u, image);
    
    % 可视化中间结果
    if mod(iter, 10) == 0
        imshow(u, []);
        title(['Iteration ', num2str(iter)]);
        drawnow;
    end
end

% 显示结果
figure;
subplot(1, 3, 1); imshow(image, []); title('Original Image');
subplot(1, 3, 2); imshow(y_noisy, []); title('Noisy Image');
subplot(1, 3, 3); imshow(u, []); title('Denoised Image');

% 绘制梯度二范数变化曲线
figure;
plot(1:max_iter, log(gradient_norms + 1e-8), 'LineWidth', 2);
xlabel('Iteration'); ylabel('Gradient Norm (L2)');
title('Gradient Norm over Iterations');
grid on;

% 绘制优化函数值变化曲线
figure;
plot(1:max_iter, log(function_values + 1e-8), 'LineWidth', 2);
xlabel('Iteration'); ylabel('Objective Function Value');
title('Objective Function Value over Iterations');
grid on;

% 绘制 PSNR 变化曲线
figure;
plot(1:max_iter, psnr_values, 'LineWidth', 2);
xlabel('Iteration'); ylabel('PSNR (dB)');
title('PSNR over Iterations');
grid on;

