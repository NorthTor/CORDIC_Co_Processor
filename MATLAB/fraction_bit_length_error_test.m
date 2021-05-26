
% Plot the error in radian angle due to fixed point representation.
% Script includes rounding method adjustments.
% Different bit lengths for the fraction in fixed point is evaluated against 
% MATLAB doubble precision floating point representation.

format long

W_L = 24 ; % word length
index = 1;

% F_L is the fractional bit length
for F_L = 1:21
    %F_L = 18;  % fractional length
    T_interm = numerictype(1,W_L,F_L); % fixed point (signed=true, 21-bit word, 17-bit fraction)
    F_interm = fimath('RoundingMethod','Nearest','SumWordLength', W_L, 'SumFractionLength', W_L, 'SumMode', 'SpecifyPrecision');% Set fixed point math settings

    value_fixed = fi([-3.14:0.01:3.14],'numerictype', T_interm, 'fimath', F_interm);
    value_float = [-3.14:0.01:3.14];

    len = length(value_fixed);
    value_fixed = value_fixed.data; % get back to double precision

for i = 1:len
  sprintf('%2.20f',value_float(i));
  error(i) = abs(value_float(i) - value_fixed(i));
end

maxerr(index) = max(error);
index = index +1;
end


figure
plot(1:21, maxerr,'s--', 'LineWidth', 1)
grid on
title('Quantization error')
xlabel('Number of fractional bits used')
ylabel('Angle error (radians)')


