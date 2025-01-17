import glob
import struct
import math
import numpy as np
import tqdm

from module import Conv2d, Sigmoid, AvgPool2d, Linear, CrossEntropyLoss, Flatten, BatchNorm, ReLU


def load_mnist(path, kind='train'):
    image_path = glob.glob('./%s*3-ubyte' % kind)[0]
    label_path = glob.glob('./%s*1-ubyte' % kind)[0]

    with open(label_path, "rb") as lbpath:
        magic, n = struct.unpack('>II', lbpath.read(8))
        labels = np.fromfile(lbpath, dtype=np.uint8)

    with open(image_path, "rb") as impath:
        magic, num, rows, cols = struct.unpack('>IIII', impath.read(16))
        images = np.fromfile(impath, dtype=np.uint8).reshape(len(labels), 28 * 28)

    return images, labels


class LeNet5:
    def __init__(self):
        self.conv1 = Conv2d(1, 6, 5, 1, 2)
        self.bn1 = BatchNorm(6)
        self.relu1 = Sigmoid()
        self.pool1 = AvgPool2d(2)
        self.conv2 = Conv2d(6, 16, 5)
        self.bn2 = BatchNorm(16)
        self.relu2 = Sigmoid()
        self.pool2 = AvgPool2d(2)
        self.flatten = Flatten()
        self.fc1 = Linear(16 * 5 * 5, 120)
        self.relu3 = Sigmoid()
        self.fc2 = Linear(120, 84)
        self.relu4 = Sigmoid()
        self.fc3 = Linear(84, 10)

    def forward(self, x):
        x = self.conv1.forward(x)
        x = self.bn1.forward(x)
        x = self.relu1.forward(x)
        x = self.pool1.forward(x)
        x = self.conv2.forward(x)
        x = self.bn2.forward(x)
        x = self.relu2.forward(x)
        x = self.pool2.forward(x)
        x = self.flatten.forward(x)
        x = self.fc1.forward(x)
        x = self.relu3.forward(x)
        x = self.fc2.forward(x)
        x = self.relu4.forward(x)
        x = self.fc3.forward(x)
        return x

    def backward(self, dy, lr):
        dy = self.fc3.backward(dy, lr)
        dy = self.relu4.backward(dy)
        dy = self.fc2.backward(dy, lr)
        dy = self.relu3.backward(dy)
        dy = self.fc1.backward(dy, lr)
        dy = self.flatten.backward(dy)
        dy = self.pool2.backward(dy)
        dy = self.relu2.backward(dy)
        dy = self.bn2.backward(dy, lr)
        dy = self.conv2.backward(dy, lr)
        dy = self.pool1.backward(dy)
        dy = self.relu1.backward(dy)
        dy = self.bn1.backward(dy, lr)
        dy = self.conv1.backward(dy, lr)


def main():
    # Load MNIST dataset
    train_images, train_labels = load_mnist("mnist_dataset", kind="train")
    test_images, test_labels = load_mnist("mnist_dataset", kind="t10k")

    train_images = train_images.astype(np.float32) / 255
    test_images = test_images.astype(np.float32) / 255

    # Define model, loss function, and optimizer
    net = LeNet5()
    loss_func = CrossEntropyLoss()
    batch_size = 64
    num_epochs = 10
    lr = 0.4

    # Training loop
    for epoch in range(num_epochs):
        if epoch < 5:
            lr = 0.1 + (lr - 0.1) * epoch / 5
        elif 5 <= epoch < num_epochs:
            lr = 0.4 * math.cos(math.pi / 2 * (epoch - 5) / (num_epochs - 5))

        total_loss = 0.0
        correct = 0
        total = 0
        num_batches = len(train_images) // batch_size

        for i in tqdm.tqdm(range(num_batches)):
            # Prepare batch
            batch_images = train_images[i * batch_size:(i + 1) * batch_size]
            batch_labels = train_labels[i * batch_size:(i + 1) * batch_size]

            # Forward pass
            x = batch_images.reshape(batch_size, 1, 28, 28)
            y_pred = net.forward(x)

            # Calculate loss
            loss = loss_func.forward(y_pred, batch_labels)
            total_loss += loss

            # Backward pass
            dy = loss_func.backward(y_pred, batch_labels)
            net.backward(dy, lr)

            # Calculate accuracy
            pred_labels = np.argmax(y_pred, axis=1)
            correct += np.sum(pred_labels == batch_labels)
            total += batch_size

        # Print training stats
        print(f"Epoch {epoch + 1}/{num_epochs}, Loss: {total_loss / num_batches:.4f}, Accuracy: {correct / total * 100:.2f}%")

        # Test the model after each epoch
        test_correct = [0.0] * 10
        total = [0.0] * 10
        total_test_correct = 0
        total_test = 0

        with tqdm.tqdm(total=len(test_images)) as pbar:
            for i in range(len(test_images)):
                x = test_images[i].reshape(1, 1, 28, 28)
                y = test_labels[i]
                y_pred = net.forward(x)
                pred = np.argmax(y_pred)
                if pred == y:
                    test_correct[y] += 1
                    total_test_correct += 1
                total[y] += 1
                total_test += 1
                pbar.update(1)

        test_accuracy = 100.0 * total_test_correct / total_test
        print(f"Test Accuracy: {test_accuracy:.2f}%")

        for i in range(10):
            if total[i] > 0:
                accuracy = 100.0 * test_correct[i] / total[i]
                print(f"Test Accuracy for {i}: {accuracy:.2f}%")


if __name__ == "__main__":
    main()

