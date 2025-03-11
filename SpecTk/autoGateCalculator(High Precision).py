#!/usr/bin/env python
# coding: utf-8

import numpy as np
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

z= np.round(z).astype(int)

x2= low[0]+x*increment[0]
y2= low[1]+y*increment[1]

x3= np.repeat(x2, z)
y3= np.repeat(y2, z)
    
xy= np.vstack([x3, y3])
kde= gaussian_kde(xy)
density= kde(xy)

cutOff= np.percentile(density, 100-percent)

selected= np.column_stack((x3, y3, density))[density > cutOff]

hull= ConvexHull(selected[:, :2])

points= selected[hull.vertices, :2]

print(points)


# In[ ]:




