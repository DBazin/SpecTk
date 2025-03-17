#!/usr/bin/env python
# coding: utf-8

import numpy as np
import numpy.random as rnd
from scipy.stats import gaussian_kde
from scipy.spatial import ConvexHull

filePath= 'data.txt'  

with open(filePath, 'r') as file:
    low= np.array([float(i) for i in file.readline().strip().split()])
    high= np.array([float(i) for i in file.readline().strip().split()])
    increment= np.array([float(i) for i in file.readline().strip().split()])
    percent= float(file.readline().strip()) 

    x= file.readline().strip().split(',')
    y= file.readline().strip().split(',')
    z= file.readline().strip().split(',')

x= np.array([float(i) for i in x])
y= np.array([float(i) for i in y])
z= np.array([float(i) for i in z])

xRange = np.abs(np.percentile(x,20)-np.percentile(x,80))
yRange = np.abs(np.percentile(y,20)-np.percentile(y,80))
n = xRange*yRange

if n > 10000:
	n = 10000

z= np.round(z).astype(int)

x2= low[0]+x*increment[0]
y2= low[1]+y*increment[1]

x3= np.repeat(x2, z)
y3= np.repeat(y2, z)

ratio = n/len(x3)

if ratio < 1:
	mask = (rnd.rand(len(x3)) < ratio)
	x4 = x3[mask]
	y4 = y3[mask]
else:
	x4 = x3
	y4 = y3
    
xy= np.vstack([x4, y4])
kde= gaussian_kde(xy)
density= kde(xy)

cutOff= np.percentile(density, 100-percent)

selected= np.column_stack((x4, y4, density))[density > cutOff]

hull= ConvexHull(selected[:, :2])

points= selected[hull.vertices, :2]

print(points)


# In[ ]:




