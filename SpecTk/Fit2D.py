#!/usr/bin/env python
# coding: utf-8

# In[ ]:
import numpy as np
from scipy.optimize import curve_fit

def rotated_gaussian_exp(coords, A, x0, y0, sigx, sigy, theta, B):
    x, y = coords
    x_shift = x - x0
    y_shift = y - y0
    cos_t = np.cos(theta)
    sin_t = np.sin(theta)
    x_prime = x_shift * cos_t + y_shift * sin_t
    y_prime = -x_shift * sin_t + y_shift * cos_t
    exponent = -((x_prime**2) / (2 * sigx**2) + (y_prime**2) / (2 * sigy**2))
    return A * np.exp(exponent) + B

def poly2d_rotated(coords, a, b, c, d, e, f):
    x, y = coords
    return a * x**2 + b * x * y + c * y**2 + d * x + e * y + f

def ellipse(coords, x0, y0, a, b, c, theta):
    x, y = coords
    cos_t = np.cos(theta)
    sin_t = np.sin(theta)
    x_shift = x - x0
    y_shift = y - y0
    x_rot = x_shift * cos_t + y_shift * sin_t
    y_rot = -x_shift * sin_t + y_shift * cos_t
    inside = 1 - (x_rot**2 / a**2 + y_rot**2 / b**2)
    inside = np.clip(inside, 0, None)
    return c * np.sqrt(inside)

with open("data.txt", "r") as file:
    fit_type = file.readline().strip()
    params = [float(i) for i in file.readline().strip().split(",")]
    low = [float(i) for i in file.readline().strip().split(",")]
    increment = [float(i) for i in file.readline().strip().split(",")]
    x = np.array([float(i) for i in file.readline().strip().split(",")])
    y = np.array([float(i) for i in file.readline().strip().split(",")])
    z = np.array([float(i) for i in file.readline().strip().split(",")])
    hold_flags = [int(i) for i in file.readline().strip().split(",")]

x = low[0] + x * increment[0]
y = low[1] + y * increment[1]

params = np.array(params)
hold_flags = np.array(hold_flags)
fit_mask = hold_flags == 0
init_guess = params[fit_mask]

if fit_type == "EllipseMoment":
    def ellipse_from_moments(x, y, weights=None):
        if weights is None:
            weights = np.ones_like(x)

        x0 = np.average(x, weights=weights)
        y0 = np.average(y, weights=weights)

        x_shift = x - x0
        y_shift = y - y0

        cov_xx = np.average(x_shift**2, weights=weights)
        cov_yy = np.average(y_shift**2, weights=weights)
        cov_xy = np.average(x_shift * y_shift, weights=weights)

        cov_matrix = np.array([[cov_xx, cov_xy],
                               [cov_xy, cov_yy]])

        eigvals, eigvecs = np.linalg.eigh(cov_matrix)
        order = np.argsort(eigvals)[::-1]
        eigvals = eigvals[order]
        eigvecs = eigvecs[:, order]

        a = np.sqrt(eigvals[0])
        b = np.sqrt(eigvals[1])
        theta = np.arctan2(eigvecs[1, 0], eigvecs[0, 0])

        return x0, y0, a, b, theta, cov_xx, cov_yy, cov_xy

    x0, y0, a, b, theta, cov_xx, cov_yy, cov_xy = ellipse_from_moments(x, y, weights=z)

    fit = np.array([x0, y0, a, b, theta])

    # No normChi here
    print(" ".join([f"{v:.6f}" for v in fit]))
    print(f"#rms_x {cov_xx:.6f} rms_y {cov_yy:.6f} cov_xy {cov_xy:.6f}")
    exit(0)

if fit_type == "Gaussian2D":
    fit_func = rotated_gaussian_exp
elif fit_type == "Polynomial2D":
    fit_func = poly2d_rotated
elif fit_type == "Ellipse":
    fit_func = ellipse

def wrapped_func(coords, *free_params):
    full = params.copy()
    full[fit_mask] = free_params
    return fit_func(coords, *full)

scales = [20, 10, 5, 2, 1]
fit_free = None

for scale in scales:
    try:
        scale_values = np.maximum(np.abs(init_guess) * scale, 1.0)
        boundL = -scale_values
        boundU = scale_values

        fit_free, _ = curve_fit(
            wrapped_func, (x, y), z, p0=init_guess,
            bounds=(boundL, boundU)
        )
        break
    except RuntimeError as e:
        print("oop")
    except ValueError as e:
        print("oop")

if fit_free is None:
    raise RuntimeError("Fit failed at all tested scales.")

params[fit_mask] = fit_free
fit = params

z_fit = fit_func((x, y), *fit)
residuals = z - z_fit
chisq = np.sum(residuals**2)
n_data = len(z)
n_params = np.sum(fit_mask)
dof = n_data - n_params
reducedChi = chisq / dof
normChi = chisq / n_data

print(" ".join(["{:.6f}".format(v) for v in fit] + ["{:.6f}".format(normChi)]))
