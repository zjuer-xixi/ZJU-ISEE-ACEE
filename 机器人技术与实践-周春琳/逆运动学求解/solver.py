import numpy as np


def forward_kinematics(a, alpha, d, theta):
    """ Compute the individual transformation matrix from DH parameters. """
    return np.array([
        [np.cos(theta), -np.sin(theta) * np.cos(alpha), np.sin(theta) * np.sin(alpha), a * np.cos(theta)],
        [np.sin(theta), np.cos(theta) * np.cos(alpha), -np.cos(theta) * np.sin(alpha), a * np.sin(theta)],
        [0, np.sin(alpha), np.cos(alpha), d],
        [0, 0, 0, 1]
    ])


def euler_to_rotation_matrix(alpha, beta, gamma):
    """ Convert Euler angles to a rotation matrix. """
    RX = np.array([
        [1, 0, 0],
        [0, np.cos(alpha), -np.sin(alpha)],
        [0, np.sin(alpha), np.cos(alpha)]
    ])
    Ry = np.array([
        [np.cos(beta), 0, np.sin(beta)],
        [0, 1, 0],
        [-np.sin(beta), 0, np.cos(beta)]
    ])
    Rz = np.array([
        [np.cos(gamma), -np.sin(gamma), 0],
        [np.sin(gamma), np.cos(gamma), 0],
        [0, 0, 1]
    ])

    return RX @ Ry @ Rz


def inverse_kinematics(x, y, z, alpha, beta, gamma, d1, a2, a3, d4, d5, d6):
    """ Compute joint angles for a 6-DOF robotic arm based on its end-effector pose. """
    R = euler_to_rotation_matrix(alpha, beta, gamma)
    T06 = np.eye(4)
    T06[0:3, 0:3] = R
    T06[0:3, 3] = [x, y, z]

    # Extract values from T06
    n_x, o_x, a_x, d_x = T06[0]
    n_y, o_y, a_y, d_y = T06[1]
    n_z, o_z, a_z, d_z = T06[2]

    solutions = []

    # Solve for θ1
    m = d_y - d6 * a_y
    n = d_x - d6 * a_x
    theta1_solutions = [
        np.arctan2(m, n) - np.arctan2(d4, np.sqrt(max(0, m**2 + n**2 - d4**2))),
        np.arctan2(m, n) - np.arctan2(d4, -np.sqrt(max(0, m**2 + n**2 - d4**2)))
    ]

    # Solve for θ5
    for theta1 in theta1_solutions:
        c1 = np.cos(theta1)
        s1 = np.sin(theta1)
        cos_theta5 = s1 * a_x - c1 * a_y
        if abs(cos_theta5) <= 1:
            theta5_solutions = [np.arccos(cos_theta5), -np.arccos(cos_theta5)]

            # Solve for θ6
            for theta5 in theta5_solutions:
                s5 = np.sin(theta5)
                if abs(s5) >= 1e-6:  # Avoid singularity
                    m = c1 * n_y - s1 * n_x
                    n = c1 * o_y - s1 * o_x
                    if abs(m**2 + n**2 - s5**2) < 0.01 and s5 > 0:
                        theta6_solutions = [np.arctan2(m, n) - np.pi/2]
                    elif abs(m**2 + n**2 - s5**2) < 0.01 and s5 < 0:
                        theta6_solutions = [np.arctan2(m, n) + np.pi/2]
                    else:
                        theta6_solutions = [
                            np.arctan2(m, n) - np.arctan2(s5, np.sqrt(max(0, m**2 + n**2 - s5**2))),
                            np.arctan2(m, n) - np.arctan2(s5, -np.sqrt(max(0, m**2 + n**2 - s5**2)))
                        ]

                    # Solve for θ3
                    for theta6 in theta6_solutions:
                        c6 = np.cos(theta6)
                        s6 = np.sin(theta6)
                        px = -d5 * (np.sin(theta6) * (c1 * n_x + s1 * n_y) + c6 * (c1 * o_x + s1 * o_y)) \
                             - d6 * (c1 * a_x + s1 * a_y) + c1 * d_x + s1 * d_y
                        py = d6 * a_z - d_z + d1 + d5 * (c6 * o_z + s6 * n_z)
                        D = (px**2 + py**2 - a2**2 - a3**2) / (2 * a2 * a3)

                        if abs(D) <= 1:
                            theta3_solutions = [np.arccos(D), -np.arccos(D)]

                            # Solve for θ2 and θ4
                            for theta3 in theta3_solutions:
                                s3 = np.sin(theta3)
                                c3 = np.cos(theta3)
                                s2 = ((a3 * c3 + a2) * py - a3 * s3 * px) / (a2**2 + a3**2 + 2 * a2 * a3 * c3)
                                c2 = (px + a3 * s3 * s2) / (a2 + a3 * c3)
                                theta2 = np.arctan2(s2, c2)

                                r11 = s6 * (c1 * n_x + s1 * n_y) + c6 * (c1 * o_x + s1 * o_y)
                                r21 = c6 * o_z + s6 * n_z
                                theta234 = np.arctan2(r11, r21)
                                theta4 = theta234 - theta2 - theta3

                                # Store the solution
                                solutions.append({
                                    "theta1": np.degrees(theta1),
                                    "theta2": np.degrees(theta2),
                                    "theta3": np.degrees(theta3),
                                    "theta4": np.degrees(theta4),
                                    "theta5": np.degrees(theta5),
                                    "theta6": np.degrees(theta6)
                                })

    # Print all valid solutions
    for i, solution in enumerate(solutions):
        print(f"Solution {i + 1}:")
        for joint, angle in solution.items():
            print(f"{joint} = {angle:.2f} degrees")
        print()

    return solutions


# Example usage
x, y, z = -0.066, 0.339, 0.444  # position in meters
alpha, beta, gamma = -2.618, -0.524, -3.141  # orientation in radians
d1, a2, a3, d4, d5, d6 = 0.23, 0.185, 0.17, 0.023, 0.077, 0.0855  # DH parameters

joint_angles = inverse_kinematics(x, y, z, alpha, beta, gamma, d1, a2, a3, d4, d5, d6)


