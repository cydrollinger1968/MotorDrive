% Script to compute discretized state-space matrices A and B for the motor model
% from kalmanPWM.m using Octave's control package

% Load required package
pkg load control

% Parameters from kalmanPWM.m
R = 5.5;          % Ohm (phase resistance)
L = 0.0002;       % H (phase inductance)
Ke_rad = 0.002387; % V/(rad/s) (back-EMF constant)
Kt = 0.0024;      % Nm/A (torque constant)
J = 3e-7;         % kg m^2 (rotor inertia)
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

% Time step for discretization
Delta_t = 0.001;

% Create continuous-time state-space system
sys_cont = ss(A_cont, B_cont, C_cont, D_cont);

% Discretize the system using zero-order hold (zoh)
sys_disc = c2d(sys_cont, Delta_t, 'zoh');

% Extract discretized matrices
A = sys_disc.A;
B = sys_disc.B;

% Display the matrices
disp('Discretized A matrix:');
disp(A);
disp('Discretized B matrix:');
disp(B);

% Save matrices to a file for use in C code
save('discretized_matrices.mat', 'A', 'B');

% Optional: Format matrices as C code arrays
printf('\nC code formatted matrices:\n');
printf('float A[3][3] = {\n');
printf('    {%f, %f, %f},\n', A(1,1), A(1,2), A(1,3));
printf('    {%f, %f, %f},\n', A(2,1), A(2,2), A(2,3));
printf('    {%f, %f, %f}\n', A(3,1), A(3,2), A(3,3));
printf('};\n');
printf('float B[3][1] = {\n');
printf('    {%f},\n', B(1));
printf('    {%f},\n', B(2));
printf('    {%f}\n', B(3));
printf('};\n');
