#!/usr/bin/env python
# coding: utf-8

import numpy as np
from scipy.stats import gaussian_kde
import matplotlib.pyplot as plt

filePath = 'data.txt'

with open(filePath, 'r') as file:
    low = np.array([float(i) for i in file.readline().strip().split()])
    high = np.array([float(i) for i in file.readline().strip().split()])
    increment = np.array([float(i) for i in file.readline().strip().split()])
    percent = float(file.readline().strip())

    x = file.readline().strip().split(',')
    y = file.readline().strip().split(',')
    z = file.readline().strip().split(',')

x = np.array([float(i) for i in x])
y = np.array([float(i) for i in y])
z = np.array([float(i) for i in z])

z = np.round(z).astype(int)

x2 = low[0] + x * increment[0]
y2 = low[1] + y * increment[1]

x3 = np.repeat(x2, z)
y3 = np.repeat(y2, z)

xy = np.vstack([x3, y3])
kde = gaussian_kde(xy)
density = kde(xy)

cutOff = np.percentile(density, 100 - percent)
selected = np.column_stack((x3, y3))[density > cutOff]

mean_x, mean_y = np.mean(selected, axis=0)

cov_matrix = np.cov(selected, rowvar=False)

eigenvalues, eigenvectors = np.linalg.eigh(cov_matrix)

order = np.argsort(eigenvalues)[::-1]
eigenvalues = eigenvalues[order]
eigenvectors = eigenvectors[:, order]

major_axis_length = 2 * np.sqrt(eigenvalues[0])  # Scaled for visualization
minor_axis_length = 2 * np.sqrt(eigenvalues[1])

angle = np.arctan2(eigenvectors[1, 0], eigenvectors[0, 0])  # Rotation angle

theta = np.linspace(0, 2 * np.pi, 100)
ellipse_x = mean_x + major_axis_length * np.cos(theta) * np.cos(angle) - minor_axis_length * np.sin(theta) * np.sin(angle)
ellipse_y = mean_y + major_axis_length * np.cos(theta) * np.sin(angle) + minor_axis_length * np.sin(theta) * np.cos(angle)

ellipse_points = np.column_stack((ellipse_x, ellipse_y))
print(ellipse_points)

# In[ ]:




