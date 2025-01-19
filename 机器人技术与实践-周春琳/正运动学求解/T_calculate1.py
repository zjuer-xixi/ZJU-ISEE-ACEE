import numpy as np
import math

def transformation_matrix(a, alpha, d, theta):
    """
    根据DH参数生成齐次变换矩阵
    """
    return np.array([
        [np.cos(theta), -np.sin(theta)*np.cos(alpha), np.sin(theta)*np.sin(alpha), a*np.cos(theta)],
        [np.sin(theta), np.cos(theta)*np.cos(alpha), -np.cos(theta)*np.sin(alpha), a*np.sin(theta)],
        [0, np.sin(alpha), np.cos(alpha), d],
        [0, 0, 0, 1]
    ])

def forward_kinematics(theta1, theta2, theta3, theta4, theta5, theta6):
    """
    基于给定的关节角度theta1-6计算末端的齐次变换矩阵
    """
    DH_params = [
        (0, -np.pi/2, 230, theta1),
        (185, 0, 0, theta2),
        (170, 0, 0, theta3),
        (0, np.pi/2, 23, theta4),
        (0, np.pi/2, 77, theta5),
        (0, 0, 85.5, theta6)
    ]

    T = np.eye(4)  # 初始化单位矩阵

    for a, alpha, d, theta in DH_params:
        T = np.dot(T, transformation_matrix(a, alpha, d, theta))  # 累积每个关节的变换

    return T

def rotation_matrix_to_euler_angles_xyz(R):
    """
    通过旋转矩阵计算Xyz顺序的欧拉角
    """
    r11, r12, r13 = R[0, 0], R[0, 1], R[0, 2]
    r23, r33 = R[1, 2], R[2, 2]
    gamma = math.atan2(-r12, r11)   # 绕X轴旋转
    beta = math.asin(r13)           # 绕Y轴旋转
    alpha = math.atan2(-r23, r33)   # 绕Z轴旋转
    return alpha, beta, gamma

# 输入关节角度（单位：弧度）
theta1, theta2, theta3 = np.radians(30), np.radians(-90), np.radians(30)
theta4, theta5, theta6 = np.radians(90), np.radians(150), np.radians(0)

# 计算齐次变换矩阵
T_06 = forward_kinematics(theta1, theta2, theta3, theta4, theta5, theta6)
R_06 = T_06[:3, :3]  # 提取旋转矩阵

# 计算欧拉角并转为角度
alpha, beta, gamma = map(np.degrees, rotation_matrix_to_euler_angles_xyz(R_06))

# 输出结果
print("齐次变换矩阵 ^{0}T_6：")
print(T_06)
print(f"Alpha (X轴旋转): {alpha:.2f} 度")
print(f"Beta (Y轴旋转): {beta:.2f} 度")
print(f"Gamma (Z轴旋转): {gamma:.2f} 度")
