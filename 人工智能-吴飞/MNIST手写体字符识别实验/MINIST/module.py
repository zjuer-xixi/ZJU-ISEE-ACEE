import numpy as np


class Conv2d:
    def __init__(self, in_channels: int, out_channels: int, kernel_size: int,
                 stride: int = 1, padding: int = 0, dtype=None):
        self.x = None
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size
        self.stride = stride
        self.padding = padding
        self.dtype = dtype
        self.weight = np.random.randn(out_channels, in_channels, kernel_size, kernel_size)
        self.bias = np.zeros(out_channels)
        self.w_grad = np.zeros_like(self.weight)
        self.b_grad = np.zeros_like(self.bias)

    def forward(self, x):
        self.x = x
        (N, C, H, W) = x.shape
        h_out = (H + 2 * self.padding - self.kernel_size) // self.stride + 1
        w_out = (W + 2 * self.padding - self.kernel_size) // self.stride + 1
        x_pad = np.pad(x, ((0, 0), (0, 0), (self.padding, self.padding), (self.padding, self.padding)), 'constant')
        out = np.zeros((N, self.out_channels, h_out, w_out))
        for i in range(h_out):
            for j in range(w_out):
                x_window = x_pad[:, :, i * self.stride:i * self.stride + self.kernel_size,
                                 j * self.stride:j * self.stride + self.kernel_size]
                out[:, :, i, j] = np.sum(x_window[:, np.newaxis, :, :, :] * self.weight[np.newaxis, :, :, :, :],
                                         axis=(2, 3, 4)) + self.bias
        return out

    def backward(self, dy, lr):
        (N, O, H_out, W_out) = dy.shape
        (N, C, H, W) = self.x.shape
        x_pad = np.pad(self.x, ((0, 0), (0, 0), (self.padding, self.padding), (self.padding, self.padding)), 'constant')
        dx_pad = np.zeros_like(x_pad)

        # Initialize gradients
        self.w_grad.fill(0)
        self.b_grad.fill(0)

        # Compute gradient for bias
        self.b_grad = np.sum(dy, axis=(0, 2, 3))

        # Compute gradients for weights and input
        for i in range(H_out):
            for j in range(W_out):
                x_window = x_pad[:, :, i * self.stride:i * self.stride + self.kernel_size,
                           j * self.stride:j * self.stride + self.kernel_size]
                dy_expanded = dy[:, :, i, j][:, :, np.newaxis, np.newaxis, np.newaxis]
                self.w_grad += np.sum(dy_expanded * x_window[:, np.newaxis, :, :, :], axis=0)
                dx_pad[:, :, i * self.stride:i * self.stride + self.kernel_size,
                j * self.stride:j * self.stride + self.kernel_size] += np.sum(
                    dy_expanded * self.weight[np.newaxis, :, :, :, :], axis=1)

        # Update weights and biases
        self.weight -= lr * self.w_grad
        self.bias -= lr * self.b_grad

        # Remove padding from dx_pad
        if self.padding > 0:
            dx = dx_pad[:, :, self.padding:-self.padding, self.padding:-self.padding]
        else:
            dx = dx_pad

        return dx


class ReLU:
    def __init__(self):
        self.x = None

    def forward(self, x):
        self.x = x
        return np.maximum(x, 0)

    def backward(self, dy):
        return dy * (dy > 0)


class Tanh:
    def __init__(self):
        self.x = None

    def forward(self, x):
        self.x = x
        return np.tanh(x)

    def backward(self, dy):
        return dy * (1 - np.tanh(dy) ** 2)


class Sigmoid:
    def __init__(self):
        self.x = None

    def forward(self, x):
        self.x = x
        return 1 / (1 + np.exp(-x))

    def backward(self, dy):
        sig = self.forward(self.x)
        return dy * sig * (1 - sig)


class Flatten:
    def __init__(self):
        self.x = None

    def forward(self, x):
        self.x = x
        return x.reshape(x.shape[0], -1)

    def backward(self, dy):
        return dy.reshape(self.x.shape)


class MaxPool2d:
    def __init__(self, kernel_size: int):
        self.x = None
        self.kernel_size = kernel_size

    def forward(self, x):
        self.x = x
        (N, C, H, W) = x.shape
        h_out = H // self.kernel_size
        w_out = W // self.kernel_size
        out = np.zeros((N, C, h_out, w_out))
        for i in range(h_out):
            for j in range(w_out):
                x_window = x[:, :, i * self.kernel_size:(i+1) * self.kernel_size, j * self.kernel_size:(j+1) * self.kernel_size]
                out[:, :, i, j] = np.max(x_window, axis=(2, 3))
        return out

    def backward(self, dy):
        (N, C, h_out, w_out) = dy.shape
        dx = np.zeros_like(self.x)
        for i in range(h_out):
            for j in range(w_out):
                x_window = self.x[:, :, i * self.kernel_size:(i+1) * self.kernel_size, j * self.kernel_size:(j+1) * self.kernel_size]
                mask = (x_window == np.max(x_window, axis=(2, 3), keepdims=True))
                dx[:, :, i * self.kernel_size:(i+1) * self.kernel_size, j * self.kernel_size:(j+1) * self.kernel_size] += mask * dy[:, :, i, j][:, :, np.newaxis, np.newaxis]
        return dx


class AvgPool2d:
    # Initialize method, set kernel size
    def __init__(self, kernel_size: int):
        self.x = None
        self.kernel_size = kernel_size

    # Forward propagation method, compute average pooling
    def forward(self, x):
        self.x = x
        (N, C, H, W) = x.shape
        stride = self.kernel_size
        h_out = H // self.kernel_size
        w_out = W // self.kernel_size
        out = np.zeros((N, C, h_out, w_out))
        for i in range(h_out):
            for j in range(w_out):
                x_window = x[:, :, i * stride:i * stride + self.kernel_size,
                             j * stride:j * stride + self.kernel_size]
                out[:, :, i, j] = np.mean(x_window, axis=(2, 3))
        return out

    # Backward propagation method, compute gradients
    def backward(self, dy):
        (N, C, H, W) = self.x.shape
        stride = self.kernel_size
        h_out, w_out = dy.shape[2], dy.shape[3]
        dx = np.zeros_like(self.x)
        for i in range(h_out):
            for j in range(w_out):
                dx[:, :, i * stride:i * stride + self.kernel_size,
                   j * stride:j * stride + self.kernel_size] += dy[:, :, i, j][:, :, np.newaxis, np.newaxis] / (self.kernel_size * self.kernel_size)
        return dx


class Linear:
    def __init__(self, in_features: int, out_features: int, bias: bool = True):
        # Initialize parameters and gradients for the linear layer
        self.x = None
        self.in_features = in_features
        self.out_features = out_features
        self.weight = np.random.randn(out_features, in_features)
        self.bias = np.zeros(out_features) if bias else None
        self.w_grad = np.zeros_like(self.weight)
        self.b_grad = np.zeros_like(self.bias) if bias else None

    def forward(self, x):
        # Compute the output for forward propagation
        self.x = x
        out = np.dot(x, self.weight.T)
        if self.bias is not None:
            out += self.bias
        return out

    def backward(self, dy, lr):
        # Compute gradients and update parameters for backward propagation
        self.w_grad = np.dot(dy.T, self.x)
        self.b_grad = np.sum(dy, axis=0)
        dx = np.dot(dy, self.weight)
        self.weight -= lr * self.w_grad
        if self.bias is not None:
            self.bias -= lr * self.b_grad
        return dx


class CrossEntropyLoss:
    def __init__(self):
        self.softmax = None
        self.label = None

    def forward(self, x, label):
        n = x.shape[0]
        x_exp = np.exp(x - np.max(x, axis=1, keepdims=True))
        softmax = x_exp / np.sum(x_exp, axis=1, keepdims=True)
        self.softmax = softmax
        self.label = label

        softmax = np.clip(softmax, 1e-10, 1.0)
        loss = -np.sum(np.log(softmax[np.arange(n), label])) / n
        return loss

    def backward(self, x, label):
        n = x.shape[0]
        dx = self.softmax
        dx[np.arange(n), label] -= 1
        dx /= n
        return dx


class BatchNorm:
    def __init__(self, num_features, eps=1e-5, momentum=0.1):
        self.num_features = num_features
        self.eps = eps
        self.momentum = momentum

        # Parameters
        self.gamma = np.ones((1, num_features, 1, 1))
        self.beta = np.zeros((1, num_features, 1, 1))

        # Running statistics
        self.running_mean = np.zeros((1, num_features, 1, 1))
        self.running_var = np.ones((1, num_features, 1, 1))

        # Cache for backward pass
        self.cache = None

    def forward(self, x, training=True):
        if training:
            batch_mean = np.mean(x, axis=(0, 2, 3), keepdims=True)
            batch_var = np.var(x, axis=(0, 2, 3), keepdims=True)

            # Normalize
            x_normalized = (x - batch_mean) / np.sqrt(batch_var + self.eps)

            # Scale and shift
            out = self.gamma * x_normalized + self.beta

            # Update running statistics
            self.running_mean = self.momentum * batch_mean + (1 - self.momentum) * self.running_mean
            self.running_var = self.momentum * batch_var + (1 - self.momentum) * self.running_var

            # Save cache for backward pass
            self.cache = (x, x_normalized, batch_mean, batch_var)
        else:
            # Use running statistics for inference
            x_normalized = (x - self.running_mean) / np.sqrt(self.running_var + self.eps)
            out = self.gamma * x_normalized + self.beta

        return out

    def backward(self, dy, lr=None):
        x, x_normalized, mean, var = self.cache
        (N, C, H, W) = x.shape

        # Gradients w.r.t. parameters
        dgamma = np.sum(dy * x_normalized, axis=(0, 2, 3), keepdims=True)
        dbeta = np.sum(dy, axis=(0, 2, 3), keepdims=True)

        # Gradients w.r.t. normalized x
        dx_normalized = dy * self.gamma

        # Gradients w.r.t. input
        dvar = np.sum(dx_normalized * (x - mean) * -0.5 * (var + self.eps) ** -1.5, axis=(0, 2, 3), keepdims=True)
        dmean = np.sum(dx_normalized * -1 / np.sqrt(var + self.eps), axis=(0, 2, 3), keepdims=True) + \
                dvar * np.sum(-2 * (x - mean), axis=(0, 2, 3), keepdims=True) / N / H / W
        dx = dx_normalized / np.sqrt(var + self.eps) + dvar * 2 * (x - mean) / N / H / W + dmean / N / H / W

        # Update parameters
        self.gamma -= lr * dgamma
        self.beta -= lr * dbeta

        return dx

