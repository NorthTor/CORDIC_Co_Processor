%% Script for generating 16-bit, 13-bit fraction length values
%  Generate binary representation used for testing CORDIC algorithm in Quartus
%  Prime Lite waveform simulation 
 
Trad = numerictype(1,16,13); % fixed point (signed=true, 16-bit word, 13-bit fraction)
Frad = fimath('SumWordLength', 16, 'SumFractionLength', 13, 'SumMode', 'SpecifyPrecision');

rad = pi/2


x_coordinate = fi(cos(rad), 'numerictype', Trad, 'fimath', Frad);
y_coordinate = fi(sin(rad), 'numerictype', Trad, 'fimath', Frad);

binary_rad = fi(rad, 'numerictype', Trad, 'fimath', Frad)

fpr = fipref;
fpr.NumberDisplay = 'bin';       % use 'bin' for binary, else RealWorldValue 
fpr.FimathDisplay = 'none';      % turn off fimath info
fpr.NumerictypeDisplay = 'none'; % tunr off numerictype info

x_coordinate
y_coordinate