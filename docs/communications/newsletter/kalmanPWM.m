% Kalman filter simulation for a motor with three-phase PWM control in Octave

% Load required package
pkg load control

% Parameters from document (approximate)
R = 31.8;          % Ohm (phase resistance)Line 10 correlated to voltage
L = 0.447;        % H (phase inductance) line 11 correlated to voltage
Ke_rad = 0.002387; % V/(rad/s) (back-EMF constant)
Kt = 0.00521;      % Nm/A (torque constant)line 12 correlated to voltage
J = 3e-6;         % kg m^2 (rotor inertia)
B = 2e-5;         % Adjusted viscous friction for damping

% Continuous-time state-space matrices (simplified for dq-frame)
A_cont = [
    0, 1, 0;
    0, -B/J, Kt/J;
    0, -Ke_rad/L, -R/L
];
B_cont = [0; 0; 1/L];  % Input affects q-axis voltage
C_cont = eye(3);
D_cont = zeros(3,1);

% Measurement matrix H
H = [
    1, 0, 0;
    0, 0, 1
];

% Discretize
Delta_t = 0.001;
sys_cont = ss(A_cont, B_cont, C_cont, D_cont);
sys_disc = c2d(sys_cont, Delta_t, 'zoh');
A = sys_disc.A;
B = sys_disc.B;

% Noise covariances
Q = diag([1e-4, 1e-2, 1e-3]);
R = diag([0.1^2, (0.02*1)^2]);

% Simulation
T_sim = 2;
N = floor(T_sim / Delta_t) + 1;
t = linspace(0, T_sim, N);

% PWM parameters
f_sine = 10;  % Frequency of sinewave modulation (Hz)
f_pwm = 1000; % PWM carrier frequency (Hz)
V_supply = 24; % Peak voltage (supply voltage)
pwm_samples = floor(1 / (f_pwm * Delta_t)); % Samples per PWM period
oversample_factor = 100; % Oversample PWM for accuracy
dt_pwm = Delta_t / oversample_factor;

% Generate sinewave reference for duty cycle (scaled to match 5V amplitude)
sine_scale = 5 / (V_supply * 0.5); % Adjust for 0.5 offset to get 5V peak
sine_a = 0.5 * (1 + sine_scale * sin(2 * pi * f_sine * t + pi/2)); % Phase A
sine_b = 0.5 * (1 + sine_scale * sin(2 * pi * f_sine * t - 2 * pi / 3 + pi/2)); % Phase B
sine_c = 0.5 * (1 + sine_scale * sin(2 * pi * f_sine * t + 2 * pi / 3 + pi/2)); % Phase C

% Generate oversampled PWM signals
t_pwm = 0:dt_pwm:T_sim;
N_pwm = length(t_pwm);
sine_a_pwm = interp1(t, sine_a, t_pwm, 'linear');
sine_b_pwm = interp1(t, sine_b, t_pwm, 'linear');
sine_c_pwm = interp1(t, sine_c, t_pwm, 'linear');
V_a_pwm = zeros(1, N_pwm);
V_b_pwm = zeros(1, N_pwm);
V_c_pwm = zeros(1, N_pwm);

for i = 1:pwm_samples*oversample_factor:N_pwm-pwm_samples*oversample_factor
    duty_a = sine_a_pwm(i);
    duty_b = sine_b_pwm(i);
    duty_c = sine_c_pwm(i);
    on_samples_a = floor(duty_a * pwm_samples * oversample_factor);
    on_samples_b = floor(duty_b * pwm_samples * oversample_factor);
    on_samples_c = floor(duty_c * pwm_samples * oversample_factor);
    start_idx = i;
    end_idx_a = min(start_idx + on_samples_a - 1, N_pwm);
    end_idx_b = min(start_idx + on_samples_b - 1, N_pwm);
    end_idx_c = min(start_idx + on_samples_c - 1, N_pwm);
    V_a_pwm(start_idx:end_idx_a) = V_supply;
    V_b_pwm(start_idx:end_idx_b) = V_supply;
    V_c_pwm(start_idx:end_idx_c) = V_supply;
endfor

% Average PWM to match simulation time step
average_window = pwm_samples * oversample_factor;
num_windows = floor((N_pwm - 1) / average_window);
V_a = mean(reshape(V_a_pwm(1:num_windows*average_window), average_window, num_windows))';
V_b = mean(reshape(V_b_pwm(1:num_windows*average_window), average_window, num_windows))';
V_c = mean(reshape(V_c_pwm(1:num_windows*average_window), average_window, num_windows))';
u = [V_a, V_b, V_c];

% Adjust t to match the averaged length
t_plot = t(1:length(V_a));

% Initialize states
x_true = zeros(3, N);  % [theta, omega, i_q]
x_true(2, 1) = 1.0;    % Small initial angular velocity
x_true(3, 1) = 0.1;    % Small initial current
x_est = zeros(3, N);
P = eye(3);
x_hat = zeros(3, 1);
w_std = sqrt(diag(Q));
v_std = sqrt(diag(R));
hall_sensors = zeros(3, N);  % Three Hall sensors (H1, H2, H3)
theta_e = zeros(1, N);       % Electrical angle

for k = 2:length(t_plot)
    w_k = w_std .* randn(3, 1);
    theta_true = x_true(1, k-1);
    theta_e(k) = theta_true;  % Assuming 1 pole pair
    % Park transformation for q-axis voltage
    if k-1 <= size(u, 1)
        V_q = (2/3) * (u(k-1, 1) * cos(theta_e(k-1)) + ...
                       u(k-1, 2) * cos(theta_e(k-1) - 2*pi/3) + ...
                       u(k-1, 3) * cos(theta_e(k-1) + 2*pi/3));
    else
        V_q = 0;  % Fallback if index exceeds
    endif
    x_true(:, k) = A * x_true(:, k-1) + B * V_q + w_k;
    theta_true = x_true(1, k);

    % Model three Hall sensors
    for i = 1:3
        threshold = mod((i-1) * 2 * pi / 3, 2 * pi);
        jitter = v_std(1) * randn();
        hall_sensors(i, k) = (mod(theta_true + jitter, 2 * pi) - threshold) < pi;
    endfor

    i_meas = x_true(3, k) + v_std(2) * randn();
    z_k = [theta_true; i_meas];
    x_pred = A * x_hat + B * V_q;
    P_pred = A * P * A' + Q;
    K = P_pred * H' * inv(H * P_pred * H' + R);
    x_hat = x_pred + K * (z_k - H * x_pred);
    P = (eye(3) - K * H) * P_pred;
    x_est(:, k) = x_hat;
endfor

% Plot
figure('Position', [100, 100, 800, 1400]);
subplot(6, 1, 1);
plot(t_plot, x_true(1, 1:length(t_plot)), 'b', t_plot, x_est(1, 1:length(t_plot)), 'r--');
ylabel('Theta (rad)');
title('Rotor Position');

subplot(6, 1, 2);
plot(t_plot, x_true(2, 1:length(t_plot)), 'b', t_plot, x_est(2, 1:length(t_plot)), 'r--');
ylabel('Omega (rad/s)');
title('Angular Velocity');

subplot(6, 1, 3);
plot(t_plot, x_true(3, 1:length(t_plot)), 'b', t_plot, x_est(3, 1:length(t_plot)), 'r--');
ylabel('Current (A)');
title('Current');

subplot(6, 1, 4);
plot(t_plot, hall_sensors(1, 1:length(t_plot)), 'g', ...
     t_plot, hall_sensors(2, 1:length(t_plot)), 'm', ...
     t_plot, hall_sensors(3, 1:length(t_plot)), 'y');
ylabel('Hall Sensors');
title('Hall Sensor Outputs (H1, H2, H3)');
axis([0, t_plot(end), -0.1, 1.1]);
set(gca, 'YTick', [0, 1]);

subplot(6, 1, 5);
plot(t_plot, u(:, 1), 'r', t_plot, u(:, 2), 'g', t_plot, u(:, 3), 'b');
ylabel('Voltage (V)');
title('Three-Phase PWM Average (Va, Vb, Vc)');
axis([0, t_plot(end), 5, 24]);

subplot(6, 1, 6);
plot(t_plot, x_true(1, 1:length(t_plot)), 'b');
ylabel('Theta (rad)');
xlabel('Time (s)');
title('True Rotor Angle');

% Add legend
legend('True', 'Estimated', 'H1', 'H2', 'H3', 'Va', 'Vb', 'Vc', 'Location', 'northeast');

% Adjust layout
set(gcf, 'PaperPositionMode', 'auto');
print('-dpng', 'motor_kalman_sim_pwm_three_phase_stabilized.png');
disp('Plot saved as motor_kalman_sim_pwm_three_phase_stabilized.png');

% RMSE
rmse_theta = sqrt(mean((x_true(1, 2:length(t_plot)) - x_est(1, 2:length(t_plot))).^2));
rmse_omega = sqrt(mean((x_true(2, 2:length(t_plot)) - x_est(2, 2:length(t_plot))).^2));
rmse_i = sqrt(mean((x_true(3, 2:length(t_plot)) - x_est(3, 2:length(t_plot))).^2));
printf('RMSE Theta: %.3f rad\n', rmse_theta);
printf('RMSE Omega: %.3f rad/s\n', rmse_omega);
printf('RMSE i: %.3f A\n', rmse_i);
