import numpy as np
import matplotlib
matplotlib.use('TkAgg')  # Force TkAgg backend for WSL
import matplotlib.pyplot as plt
from control import ss, c2d
import os

# Check if DISPLAY is set
if 'DISPLAY' not in os.environ:
    os.environ['DISPLAY'] = ':0'
    print("DISPLAY environment variable set to :0")

# Parameters from document (approximate)
R = 5.5          # Ohm (phase resistance)
L = 0.0002       # H (phase inductance)
Ke_rad = 0.002387  # V/(rad/s) (back-EMF constant)
Kt = 0.0024      # Nm/A (torque constant)
J = 3e-7         # kg m^2 (rotor inertia)
B = 2e-5         # Adjusted viscous friction for damping

# Continuous-time state-space matrices (simplified for dq-frame)
A_cont = np.array([
    [0, 1, 0],
    [0, -B/J, Kt/J],
    [0, -Ke_rad/L, -R/L]
])
B_cont = np.array([0, 0, 1/L])  # Input affects q-axis voltage
C_cont = np.eye(3)
D_cont = np.zeros(3)

# Measurement matrix H
H = np.array([
    [1, 0, 0],
    [0, 0, 1]
])

# Discretize
Delta_t = 0.001
sys_cont = ss(A_cont, B_cont.reshape(3,1), C_cont, D_cont.reshape(3,1))
sys_disc = c2d(sys_cont, Delta_t, 'zoh')
A = sys_disc.A
B = sys_disc.B.flatten()

# Noise covariances
Q = np.diag([1e-4, 1e-2, 1e-3])
R = np.diag([0.1**2, (0.02*1)**2])

# Simulation
T_sim = 2
N = int(T_sim / Delta_t) + 1
t = np.linspace(0, T_sim, N)

# PWM parameters
f_sine = 10  # Frequency of sinewave modulation (Hz)
f_pwm = 1000  # PWM carrier frequency (Hz)
V_supply = 24  # Peak voltage (supply voltage)
pwm_samples = int(1 / (f_pwm * Delta_t))  # Samples per PWM period (1000)
oversample_factor = 100  # Oversample PWM for accuracy
dt_pwm = Delta_t / oversample_factor

# Generate sinewave reference for duty cycle (scaled to match 5V amplitude)
sine_scale = 5 / (V_supply * 0.5)  # Adjust for 0.5 offset to get 5V peak
sine_a = 0.5 * (1 + sine_scale * np.sin(2 * np.pi * f_sine * t + np.pi/2))  # Phase A, start at peak
sine_b = 0.5 * (1 + sine_scale * np.sin(2 * np.pi * f_sine * t - 2 * np.pi / 3 + np.pi/2))  # Phase B
sine_c = 0.5 * (1 + sine_scale * np.sin(2 * np.pi * f_sine * t + 2 * np.pi / 3 + np.pi/2))  # Phase C

# Generate oversampled PWM signals
t_pwm = np.arange(0, T_sim + dt_pwm, dt_pwm)
N_pwm = len(t_pwm)
sine_a_pwm = np.interp(t_pwm, t, sine_a)
sine_b_pwm = np.interp(t_pwm, t, sine_b)
sine_c_pwm = np.interp(t_pwm, t, sine_c)
V_a_pwm = np.zeros(N_pwm)
V_b_pwm = np.zeros(N_pwm)
V_c_pwm = np.zeros(N_pwm)

for i in range(0, N_pwm - (pwm_samples * oversample_factor), pwm_samples * oversample_factor):
    duty_a = sine_a_pwm[i]
    duty_b = sine_b_pwm[i]
    duty_c = sine_c_pwm[i]
    on_samples_a = int(duty_a * pwm_samples * oversample_factor)
    on_samples_b = int(duty_b * pwm_samples * oversample_factor)
    on_samples_c = int(duty_c * pwm_samples * oversample_factor)
    start_idx = i
    end_idx_a = min(start_idx + on_samples_a, N_pwm)
    end_idx_b = min(start_idx + on_samples_b, N_pwm)
    end_idx_c = min(start_idx + on_samples_c, N_pwm)
    V_a_pwm[start_idx:end_idx_a] = V_supply
    V_b_pwm[start_idx:end_idx_b] = V_supply
    V_c_pwm[start_idx:end_idx_c] = V_supply

# Average PWM to match simulation time step
average_window = pwm_samples * oversample_factor
num_windows = (N_pwm - 1) // average_window
V_a = np.mean(V_a_pwm[:num_windows * average_window].reshape(num_windows, average_window), axis=1)
V_b = np.mean(V_b_pwm[:num_windows * average_window].reshape(num_windows, average_window), axis=1)
V_c = np.mean(V_c_pwm[:num_windows * average_window].reshape(num_windows, average_window), axis=1)
u = np.stack((V_a, V_b, V_c), axis=1)

# Adjust t to match the averaged length
t_plot = t[:len(V_a)]

# Initialize states
x_true = np.zeros((3, N))  # [theta, omega, i_q]
x_true[1, 0] = 1.0  # Small initial angular velocity
x_true[2, 0] = 0.1  # Small initial current
x_est = np.zeros((3, N))
P = np.eye(3)
x_hat = np.zeros(3)
w_std = np.sqrt(np.diag(Q))
v_std = np.sqrt(np.diag(R))
hall_sensors = np.zeros((3, N))  # Three Hall sensors (H1, H2, H3)
theta_e = np.zeros(N)  # Electrical angle

for k in range(1, len(t_plot) + 1):
    w_k = w_std * np.random.randn(3)
    theta_true = x_true[0, k-1]
    theta_e[k] = theta_true  # Assuming 1 pole pair
    # Park transformation for q-axis voltage
    if k-1 < len(u):
        V_q = (2/3) * (u[k-1, 0] * np.cos(theta_e[k-1]) + u[k-1, 1] * np.cos(theta_e[k-1] - 2*np.pi/3) + u[k-1, 2] * np.cos(theta_e[k-1] + 2*np.pi/3))
    else:
        V_q = 0  # Fallback if index exceeds
    x_true[:, k] = A @ x_true[:, k-1] + B * V_q + w_k
    theta_true = x_true[0, k]
    
    # Model three Hall sensors
    for i in range(3):
        threshold = (i * 2 * np.pi / 3) % (2 * np.pi)
        jitter = v_std[0] * np.random.randn()
        hall_sensors[i, k] = 1 if (np.mod(theta_true + jitter, 2 * np.pi) - threshold) % (2 * np.pi) < np.pi else 0
    
    i_meas = x_true[2, k] + v_std[1] * np.random.randn()
    z_k = np.array([theta_true, i_meas])
    x_pred = A @ x_hat + B * V_q
    P_pred = A @ P @ A.T + Q
    K = P_pred @ H.T @ np.linalg.inv(H @ P_pred @ H.T + R)
    x_hat = x_pred + K @ (z_k - H @ x_pred)
    P = (np.eye(3) - K @ H) @ P_pred
    x_est[:, k] = x_hat

# Plot
fig, axs = plt.subplots(6, 1, figsize=(8, 14))
axs[0].plot(t_plot, x_true[0, :len(t_plot)], 'b', t_plot, x_est[0, :len(t_plot)], 'r--')
axs[0].set_ylabel('Theta (rad)')
axs[0].set_title('Rotor Position')
axs[1].plot(t_plot, x_true[1, :len(t_plot)], 'b', t_plot, x_est[1, :len(t_plot)], 'r--')
axs[1].set_ylabel('Omega (rad/s)')
axs[1].set_title('Angular Velocity')
axs[2].plot(t_plot, x_true[2, :len(t_plot)], 'b', t_plot, x_est[2, :len(t_plot)], 'r--')
axs[2].set_ylabel('Current (A)')
axs[2].set_title('Current')
axs[3].plot(t_plot, hall_sensors[0, :len(t_plot)], 'g', t_plot, hall_sensors[1, :len(t_plot)], 'm', t_plot, hall_sensors[2, :len(t_plot)], 'y')
axs[3].set_ylabel('Hall Sensors')
axs[3].set_title('Hall Sensor Outputs (H1, H2, H3)')
axs[3].set_yticks([0, 1])
axs[3].set_ylim(-0.1, 1.1)
axs[4].plot(t_plot, u[:, 0], 'r', t_plot, u[:, 1], 'g', t_plot, u[:, 2], 'b')
axs[4].set_ylabel('Voltage (V)')
axs[4].set_title('Three-Phase PWM Average (Va, Vb, Vc)')
axs[4].set_ylim(5, 20)
axs[5].plot(t_plot, x_true[0, :len(t_plot)], 'b')
axs[5].set_ylabel('Theta (rad)')
axs[5].set_xlabel('Time (s)')
axs[5].set_title('True Rotor Angle')
fig.legend(['True', 'Estimated', 'H1', 'H2', 'H3', 'Va', 'Vb', 'Vc'], loc='upper right')
plt.tight_layout()
plt.savefig('motor_kalman_sim_pwm_three_phase_stabilized.png')
plt.show()
print('Plot saved as motor_kalman_sim_pwm_three_phase_stabilized.png')

# RMSE
rmse_theta = np.sqrt(np.mean((x_true[0, 1:len(t_plot)] - x_est[0, 1:len(t_plot)])**2))
rmse_omega = np.sqrt(np.mean((x_true[1, 1:len(t_plot)] - x_est[1, 1:len(t_plot)])**2))
rmse_i = np.sqrt(np.mean((x_true[2, 1:len(t_plot)] - x_est[2, 1:len(t_plot)])**2))
print(f'RMSE Theta: {rmse_theta:.3f} rad')
print(f'RMSE Omega: {rmse_omega:.3f} rad/s')
print(f'RMSE i: {rmse_i:.3f} A')
