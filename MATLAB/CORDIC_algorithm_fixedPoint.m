%% CORDIC fixed point simulation
% Done by comparing computation of arctan using CORDIC with 
% the "true" angle presented on MATLAB floating point doubble precision.

clear all

fraction_length = 13;
word_length = fraction_length + 3;
angle_pi = 3.12;

% Object describing fixed-point data type used for signals
% (signed=true, 16-bit word, 13-bit fraction)
fix_typ = numerictype(1,word_length,fraction_length );
% Set fixed point math settings
fix_math = fimath('SumWordLength', word_length,...
                  'SumFractionLength', fraction_length,... 
                  'SumMode', 'SpecifyPrecision');
              
N = 12; % Number of Cordic iterations 

% Generate the LUT for with elementary angles 
LUT = fi(atan(2.^-(0:N)),'numerictype', fix_typ , 'fimath', fix_math); 

index = 1;
% Perform CORDIC iterations over the range of angles
for rad = -angle_pi:0.01:angle_pi 
    angle = fi(0,'numerictype', fix_typ, 'fimath', fix_math); % Starting angle at zero radians 
   
    % Input and intermediate CORDIC results
    % z holds values in range [-pi/2   +pi/2]
    y = fi(sin(rad), 'numerictype', fix_typ,'fimath', fix_math); % fi returns fixed point pobject 
    x = fi(cos(rad), 'numerictype', fix_typ,'fimath', fix_math); % fi returns fixed point pobject
    z = fi(0, 'numerictype', fix_typ,'fimath', fix_math); % fi returns fixed point pobject
    
    [X, Y, Z] = CORDIC_vectormode(x, y, z, LUT, N, word_length, fraction_length);
 
    recorded_angle(1, index) = rad;
    recorded_angle(2, index) = Z;
    index = index + 1;
end

% Compute the error: fixed point CORDIC is compared to the "true" radian
% angle represented by MATLABs doubbble precision floating point.
error_rad = abs(recorded_angle(1,:) - recorded_angle(2,:));

% Get the simulated angles in radians 
angle_rad = recorded_angle(1,:);

figure
plot(angle_rad, error_rad);

xlabel('Angle (radians)')
ylabel('error (radians)')

max_error = max(error_rad);

fprintf('Iterations: %2d, Max radian error: %g\n',...
    [N; max_error]);
