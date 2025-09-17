% kalman_motor_model.m
% Models and simulates a Kalman Filter for Maxon EC 8 mm BLDC Motor with Hall Sensors
% Based on the provided report: state x = [theta (rad), omega (rad/s), i (A)]^T
% Input u = V (phase voltage, simplified)

pkg load control;

% Parameters from report (approximate)
R = 5.5;          % Phase resistance (Ohm)
L = 0.0002;       % Phase inductance (H)
Ke = 0.0025;      % Back-EMF constant (V/rpm)
Kt = 0.0024;      % Torque constant (Nm/A)
J = 3e-7;         % Rotor inertia (kg m^2)
B = 1e-5;         % Viscous friction (Nm s/rad)

% Convert Ke to V/(rad/s): 1 rpm = 2*pi/60 rad/s
Ke_rad = Ke / (1000 * (60 / (2 * pi)));  % ≈ 0.02387 V/(rad/s)

% Continuous-time state-space matrices
A_cont = [
  0, 1, 0;
  0, -B/J, Kt/J;
  0, -Ke_rad/L, -R/L
];
B_cont = [0; 0; 1/L];
C_cont = eye(3);  % For full state output (simulation only)
D_cont = zeros(3,1);

% Measurement matrix H (measures theta_Hall and i_meas)
H = [
  1, 0, 0;
  0, 0, 1
];

% Discretize with sampling time Delta_t = 0.001 s (1 kHz)
Delta_t = 0.001;
sys_cont = ss(A_cont, B_cont, C_cont, D_cont);
sys_disc = c2d(sys_cont, Delta_t, 'zoh');
A = sys_disc.A;
B = sys_disc.B;

% Noise covariances (tuning: assumed values based on guidelines)
% Q: process noise (load variations, model errors)
Q = diag([1e-4, 1e-2, 1e-3]);  % Small for theta, higher for omega/i uncertainties
% R: measurement noise (Hall jitter ~0.1 rad, current ~2% error assuming 1A max)
R = diag([0.1^2, (0.02*1)^2]);

% Simulation parameters
T_sim = 1;                % Total simulation time (s)
N = round(T_sim / Delta_t);  % Number of steps
t = (0:N-1)' * Delta_t;

% Input voltage: simple sinusoid for demo (amplitude 5V, freq 10 Hz)
u = 5 * sin(2 * pi * 10 * t);

% Hall sensor resolution: assume 6 transitions/rev (60 deg electrical steps)
hall_resolution = pi / 3;  % rad (60 deg)

% Initialize states
x_true = zeros(3, N);     % True states
x_est = zeros(3, N);      % Estimated states
P = eye(3);               % Initial covariance
x_hat = [0; 0; 0];        % Initial estimate

% Process and measurement noise std devs
w_std = sqrt(diag(Q));
v_std = sqrt(diag(R));

for k = 2:N
  % Simulate true system dynamics with process noise
  w_k = w_std .* randn(3,1);
  x_true(:,k) = A * x_true(:,k-1) + B * u(k-1) + w_k;

  % Measurements with noise
  theta_true = x_true(1,k);
  % Hall measurement: quantized with jitter
  theta_hall = hall_resolution * round(theta_true / hall_resolution) + v_std(1) * randn;
  i_meas = x_true(3,k) + v_std(2) * randn;
  z_k = [theta_hall; i_meas];

  % Kalman Filter: Predict
  x_pred = A * x_hat + B * u(k-1);
  P_pred = A * P * A' + Q;

  % Kalman Filter: Update
  K = P_pred * H' / (H * P_pred * H' + R);
  x_hat = x_pred + K * (z_k - H * x_pred);
  P = (eye(3) - K * H) * P_pred;

  x_est(:,k) = x_hat;
end

% Plot results
figure(1);
subplot(3,1,1);
plot(t, x_true(1,:), 'b', t, x_est(1,:), 'r--');
xlabel('Time (s)'); ylabel('Theta (rad)');
legend('True', 'Estimated');
title('Rotor Position');

subplot(3,1,2);
plot(t, x_true(2,:), 'b', t, x_est(2,:), 'r--');
xlabel('Time (s)'); ylabel('Omega (rad/s)');
legend('True', 'Estimated');
title('Angular Velocity');

subplot(3,1,3);
plot(t, x_true(3,:), 'b', t, x_est(3,:), 'r--');
xlabel('Time (s)'); ylabel('Current (A)');
legend('True', 'Estimated');
title('Current');

% Save figure (optional)
print -dpng motor_kalman_sim.png;
