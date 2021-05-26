
% Floating Point simulation of CORDIC ALgorithm 
% MATLAB doubble precision.

clear all
format long
iter = 20; % Max number of CORDIC iterations 

for N = 1:iter
    LUT = atan(2.^-(0:N)); % Generate the LUT for CORDIC with elementary angles
    index = 1;
    for rad = -3.14:0.01:3.14 % Needs to be the same as for fractional bit error test 
        x = cos(rad);
        y = sin(rad);  % Yes this rest on MATLABS ability to compute sin and cos
  
        [X, Y, Z] = CORDIC_vectormode(x, y, 0, LUT, N); % floating-point results
  
        recorded_angle(1,index) = rad;  % record the real angle
        recorded_angle(2,index) = Z(1); % record the CORDIC approximated  angle
        index = index + 1;
    end
    error_radian = abs(recorded_angle(1,:) - recorded_angle(2,:));
    error_degrees = error_radian.*(180/pi);
    
    angle_radian = recorded_angle(1,:);
    angle_degrees = angle_radian.*(180/pi);
    
    % get the max error for current number of iterations 
    max_error_degrees(N) = max(error_degrees);
    max_error_radian(N) = max(error_radian);
end


% Do the fractional bit-length error test:
% fractional bit length is tested agains MATLAB floating point representation
% the error is the difference between fixed point number of different
% fractional lengths and MATLAB floating point representation of radian
% angles in the range [-pi pi] 

word_length = 32; % word length
max_fractional_length = 29;
index = 1;
for fractional_length = 1:max_fractional_length
    % set the type
    T_interm = numerictype(1,word_length,fractional_length); % fixed point (signed=true)
    % Set fixed point math settings
    F_interm = fimath('RoundingMethod','Nearest','SumWordLength', word_length,...
                      'SumFractionLength', word_length, 'SumMode', 'SpecifyPrecision');

    value_fixed = fi([-3.14:0.01:3.14],'numerictype', T_interm, 'fimath', F_interm);
    value_float = [-3.14:0.01:3.14]; % default, ses MATLAB double floating point  

    len = length(value_fixed); 
    value_fixed = value_fixed.data; % convert back to double precision format
                                    % however the fixed point value is
                                    % retained.  

    for i = 1:len
        sprintf('%2.20f',value_float(i));
        error(i) = abs(value_float(i) - value_fixed(i));
    end

max_error_fixed_point(fractional_length) = max(error); % max error vs fractional bit length 
index = index +1;
end
 
% Choose the plotting sequence.
plot_ver = 1;

if plot_ver == 1
    figure
    % plot error vs CORDIC iterations
    % and error vs fixed point fractional bit length in the same plot
    % Plot Algorithm error vs number of CORDIC iterations 
    hold on
    grid on
    
    title('')
   
    yyaxis left % Algorithm iterations vs error
    x = max_error_radian;
    y = 1:iter;
    xlabel('Angle error (radians)')
    ylabel('CORDIC iterations')
    plot(x,y,'s--', 'LineWidth', 1)

    yyaxis right
    x = max_error_fixed_point;
    z = 1:fractional_length;
    ylabel('Fractional bit-length')
    plot(x,z,'s--','LineWidth', 1)

end 


if plot_ver == 2 
    figure
    % Plot Algorithm error vs number of CORDIC iterations 
    hold on
    grid on

    title('CORDIC Algorithm error vs. number of iterations (floating point)')
    x = 1:20;
    y = max_error_radian;
    xlabel('CORDIC iterations')
    ylabel('Algorithm error (radians)')
    plot(x,y,'s--','LineWidth', 1)

end 

