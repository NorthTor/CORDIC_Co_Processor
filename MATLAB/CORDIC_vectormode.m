
function [x, y, z, coordinate_xy] = CORDIC_vectormode(x, y, z, LUT, N,...
                                                      word_length,... 
                                                      fraction_length)
% CORDIC vectoring mode 
% The input vector is rotated down on the positive x-axis
% The angle accumulator Z records all angles

%    INPUT:  
%    x, y :   Coordinate,       
%    z    :   Initialization angle z (radians) should be set to zero
%    LUT  :   A lookup table for arctan(2^(-n))
%    N    :   Number of CORDIC algorithm iterations 
%
%   OUTPUT:   x and y coordinate after rotation together with angle z z(N)
%             where z(N) holds the value arctan(y,x) 

% ----- Quadrant mapping -------------------------------------------------
% 1st and 4th quadrant is handled in the CORDIC iterations
% if we find ourselves in the 2nd or 3rd quadrant we need
% to do some mapping 

% fixed-point data type for intermediate calculations
% REMOVE when doing floating point simulation.
% fixed point (signed=true, 16-bit word, 13-bit fraction)
fix_type = numerictype(1,word_length,fraction_length);
% Set fixed point math settings
fix_math = fimath('RoundingMethod','Nearest',...
                  'SumWordLength', word_length,... 
                  'SumFractionLength', fraction_length,...
                  'SumMode', 'SpecifyPrecision');

pi_half_floating = pi/2; %1.57079632679;

pi_half_fixed = fi(pi_half_floating, 'numerictype', fix_type,...
                    'fimath', fix_math);

quad_flag = 0;
xtemp = x;
ytemp = y; 

if x < 0 % we are in either the 2rd or 3rd quadrant do mapping
    if y < 0 % 3rd quadrant
        quad_flag = 1; % set flag 
        x = abs(y);
        y = xtemp;
    else % 2nd quadrant
        quad_flag = 2; % set flag
        x = y;
        y = abs(xtemp);
    end
    % Restore temporay registers with mapped values
    xtemp = x; 
    ytemp = y; 
end

% ----- CORDIC Iterations ------------------------------------------------
for i = 1:N
    % "coordinate_xy" used for vizualisation script only
    coordinate_xy(1,i) = x;
    coordinate_xy(2,i) = y; 
    if y < 0 % bitget(16, 1)
        x(:) = x - ytemp;
        y(:) = y + xtemp;
        z(:) = z - LUT(i);
    else
        x(:) = x + ytemp;
        y(:) = y - xtemp;
        z(:) = z + LUT(i);
    end
    xtemp = bitsra(x, i); % bit-shift-right, multip. with 2^(-i)
    ytemp = bitsra(y, i); % bit-shift-right, multip. with 2^(-i)
end

% ----- Quadrant correction ------
if quad_flag == 2
    z = z + pi_half_fixed; % add pi/2
end
if quad_flag == 1
    z = z - pi_half_fixed; % subtract pi/2
end
