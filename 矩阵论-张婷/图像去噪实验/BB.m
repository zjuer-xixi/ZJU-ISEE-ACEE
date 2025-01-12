% 参数设置
lambda = 0.5;        % 正则化参数
max_iter = 5000;      % 最大迭代次数
tol = 1e-12;          % 收敛阈值

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
grad_prev = zeros(size(u)); % 上一步的梯度
t = 0.1; % 初始步长
u_prev = u; % 保存前一步的解
gradient_norms = zeros(max_iter, 1); % 保存梯度二范数
function_values = zeros(max_iter, 1); % 保存优化函数值
psnr_values = zeros(max_iter, 1); % 保存 PSNR

% 梯度下降迭代（非单调线搜索 + BB 步长）
for iter = 1:max_iter
    % 计算拉普拉斯算子 Δx
    lap_x = imfilter(u, [0 1 0; 1 -4 1; 0 1 0], 'replicate');
    
    % 当前梯度
    grad = u - y_noisy - 2 * lambda * lap_x;
    
    % 计算目标函数值
    function_values(iter) = 0.5 * norm(u(:) - y_noisy(:), 2)^2 + ...
                            lambda * sum(sum((u(:, 2:end) - u(:, 1:end-1)).^2)) + ...
                            lambda * sum(sum((u(2:end, :) - u(1:end-1, :)).^2));
    
    % 计算 PSNR
    psnr_values(iter) = psnr(u, image);
    
    % 计算梯度二范数
    gradient_norms(iter) = norm(grad(:), 2);

    % 步长更新（BB 方法）
    if iter > 1
        % 位置变化量 s
        s = u - u_prev;
        % 梯度变化量 y
        y = grad - grad_prev;

        % 使用 BB1 和 BB2 步长交替更新
        if mod(iter, 2) == 0
            % BB1 步长
            t = (s(:)' * y(:)) / (y(:)' * y(:));
        else
            % BB2 步长
            t = (s(:)' * s(:)) / (s(:)' * y(:));
        end

        % 限制步长范围
        t = max(min(t, 1), 1e-4); % 防止步长过大或过小
    end

    % 保存当前解和梯度
    u_prev = u;
    grad_prev = grad;
    
    % 更新解
    u = u - t * grad;
    
    % 限制解在 [0, 1] 范围内
    u = min(max(u, 0), 1);

    % 可视化中间结果
    if mod(iter, 500) == 0
        imshow(u, []);
        title(['Iteration ', num2str(iter)]);
        drawnow;
    end

    % 判断收敛
    if norm(grad(:), 2) < tol
        disp(['Converged at iteration ', num2str(iter)]);
        break;
    end
end

% 显示结果
figure;
subplot(1, 3, 1); imshow(image, []); title('Original Image');
subplot(1, 3, 2); imshow(y_noisy, []); title('Noisy Image');
subplot(1, 3, 3); imshow(u, []); title('Denoised Image');

% 绘制梯度二范数变化曲线
figure;
plot(1:iter, log(gradient_norms(1:iter) + 1e-8), 'LineWidth', 2);
xlabel('Iteration'); ylabel('Log(Gradient Norm)');
title('Gradient Norm over Iterations');
grid on;

% 绘制优化函数值变化曲线
figure;
plot(1:iter, log(function_values(1:iter) + 1e-8), 'LineWidth', 2);
xlabel('Iteration'); ylabel('Log(Objective Function Value)');
title('Objective Function Value over Iterations');
grid on;

% 绘制 PSNR 变化曲线
figure;
plot(1:iter, psnr_values(1:iter), 'LineWidth', 2);
xlabel('Iteration'); ylabel('PSNR (dB)');
title('PSNR over Iterations');
grid on;
