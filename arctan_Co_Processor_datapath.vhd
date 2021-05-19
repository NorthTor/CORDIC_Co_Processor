
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- DATAPATH --

entity datapath_arctan_CORDIC is 
port(

X_in    : in signed(15 downto 0);		-- input coordinate from main processor
Y_in    : in signed(15 downto 0);		-- input coordinate from main pocessor

MUX_1   : in std_logic_vector(1 downto 0);      -- control signal in from FSM
MUX_2   : in std_logic_vector(1 downto 0);      -- control signal in from FSM
MUX_3   : in std_logic_vector(1 downto 0);      -- control signal in from FSM

counter : in unsigned;     -- control signal in from FSM
clk     : in std_logic;

X_MSB_MAP : out std_logic;  -- control signal out to FSM
Y_MSB_MAP : out std_logic;  -- control signal out to FSM
Y_MSB     : out std_logic;  -- control signal out to FSM

Z_out : out signed(15 downto 0) -- Output radian angle to main processor
);
end entity datapath_arctan_CORDIC;


architecture RTL of datapath_arctan_CORDIC is 

-- signal declarations


begin

	-- Mux 1 for selecting input to Register X 
	with MUX_1 select MUX_1_out <=
	X_temp     when "00";
	Y_abs      when "01";
	Y_temp     when "10";
	X_add_sub  when "11";

	-- Mux 2 for selecting input to Register Y
	with MUX_2 select MUX_2_out <= 
	Y_temp     when "00";
	X_abs      when "01";
	X_temp     when "10";
	Y_add_sub  when "11";

	-- Mux 3 for selecting input to Register Z
	with MUX_3 select MUX_3_out <=
	0 			  when "00";
	LUT_out       when "01";
	pi_half 	  when "10";

	-- arctan Look Up Table - 16 bit 
	with counter select LUT_out <=
	"0000100000101110"   when "0";         
	"0000100000101110"   when "1";
	"0000010010010001"   when "2";
	"0000000010110100"   when "3";
	"0100100000101110"   when "4";
	"0010010010010001"   when "5";
	"0010100010010100"   when "6";
	"0010100000101110"   when "7";
	"0000110010010001"   when "8";
	"0000110010010100"   when "9";
	"1000100000101110"   when "10";
	"1000010010010001"   when "11";
	"1110000010010100"   when "12";

	  
	-- Following describes the register transfers and logic between transfers 
	-- at positive clock edge
	process(clk) 
	begin
		if rising_edge(clk) then
			-- Register tranfers 
			REG_X_input <= X_in; 
			REG_Y_input <= Y_in;

			REG_X_temp <= REG_X_input;
			REG_Y_temp <= REG_Y_input;

			REG_X <= MUX_1_out;
			REG_Y <= MUX_2_out;

			-- Get MSB, used for quadrant detection/mapping
			X_MSB_MAP <= X_in(15);
			Y_MSB_MAP <= Y_in(15);

			-- ABS logic 
			X_abs <= abs(REG_X_temp);
			Y_abs <= abs(REG_Y_temp);

			-- Get the MSB out from MUX_2 (Y_MSB used as input to adders)
			Y_MSB <= MUX_2_out(15);

			-- Shift values "counter" amount of right using arithmetic shift right (sra) 
			shifted_Y <= REG_Y sra counter;
			shifted_X <= REX_X sra counter;

			if Y_MSB = '1' then
				X_add_sub <= REG_X - shifted_Y;
				Y_add_sub <= REG_Y + shifted_X;
				REG_Z <= REG_Z - MUX_3_out 
			else
				X_add_sub <= REG_X + shifted_Y;
				Y_add_sub <= REG_Y - shifted_X;
				REG_Z <= REG_Z + MUX_3_out;
			end if;

		end if;
			-- Register REG_Z is valid output when DONE is '1'
	end process;



