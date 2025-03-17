#!/usr/bin/env python
# coding: utf-8

import numpy as np
import numpy.random as rnd
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

xRange = np.abs(np.percentile(x,20)-np.percentile(x,80))
yRange = np.abs(np.percentile(y,20)-np.percentile(y,80))
n = xRange*yRange

if n > 10000:
	n = 10000

z = np.round(z).astype(int)

x2 = low[0] + x * increment[0]
y2 = low[1] + y * increment[1]

x3 = np.repeat(x2, z)
y3 = np.repeat(y2, z)

ratio = n/len(x3)

if ratio < 1:
	mask = (rnd.rand(len(x3)) < ratio)
	x4 = x3[mask]
	y4 = y3[mask]
else:
	x4 = x3
	y4 = y3

xy = np.vstack([x4, y4])
kde = gaussian_kde(xy)
density = kde(xy)

cutOff = np.percentile(density, 100 - percent)
selected = np.column_stack((x4, y4))[density > cutOff]

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




