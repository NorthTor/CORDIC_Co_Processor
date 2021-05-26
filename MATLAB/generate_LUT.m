
clear all
% Object sescribing fixed-point data type output from CORDIC, holds values in range [-pi/2 to +pi/2]

Trad = numerictype(1,16,13); % fixed point (signed=true, 16-bit word, 13-bit fraction)
Frad = fimath('SumWordLength', 16, 'SumFractionLength', 13, 'SumMode', 'SpecifyPrecision');

N = 12;  
LUT = fi(atan(2.^-(0:N)),'numerictype', Trad, 'fimath', Frad); % Generate the LUT for CORDIC with angles

pi_half = fi(pi/2, 'numerictype', Trad, 'fimath', Frad);

fpr = fipref;
fpr.NumberDisplay = 'bin'; % use 'bin' for binary
fpr.FimathDisplay = 'none';  % turn off fimath info
fpr.NumerictypeDisplay = 'none'; % tunr off numerictype info

for i = 1:N+1
 disp(LUT(i));
end 
