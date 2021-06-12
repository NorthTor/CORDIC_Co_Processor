

-- Author: Tor Kaufmann Gjerde
-- VHDL for a CORDIC arctan Co Processor 
-- Semester Project during spring 2021 AAU 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- CONTROLLER and datapath for arctan CORDIC co processor --

entity cordic_co_processor is
port (

	clk         : in std_logic;
	START       : in std_logic;  -- Positive START
	RESET	    : in std_logic;  -- Positive RESET
	
	X_in		: in signed(15 downto 0);
	Y_in		: in signed(15 downto 0);
    
	DONE        : out std_logic;
	counter_out : out integer range 0 to 13;
	REG_X_out   : out signed(15 downto 0);
	
	Z_out       : out signed(15 downto 0)
	
	   );
end entity cordic_co_processor;


architecture RTL of cordic_co_processor is 

	-- Enumerated type declaration and state signal declaration
	type t_state is (S1, S2, S3, S4, S5, S6, 
	                 S7, S8, S9, S10, S11, S12, S13 ); 
	
	signal state: t_state; 

	-- flag used for holding quadrant information
	signal quadrant_flag : std_logic_vector(1 downto 0);
	
	-- counter for counting CORDIC iterations
   	-- used for both number of shifts and LUT index	
	
	signal counter       : integer range 0 to 13;
	signal X_temp        : signed(15 downto 0);
	signal Y_temp        : signed(15 downto 0);
	signal REG_X         : signed(15 downto 0);
	signal REG_Y         : signed(15 downto 0);
	signal REG_Z         : signed(15 downto 0);

	signal Y_abs         : signed(15 downto 0);
	signal X_abs         : signed(15 downto 0);
		
   	signal X_MSB_MAP     : std_logic;
   	signal Y_MSB_MAP     : std_logic;
   	signal Y_MSB         : std_logic;
	 
	signal X_add_sub     : signed(15 downto 0);
	signal Y_add_sub     : signed(15 downto 0);
	signal Z_add_sub     : signed(15 downto 0);
	
	signal MUX_1         : std_logic_vector(1 downto 0);
   	signal MUX_2         : std_logic_vector(1 downto 0);
  	signal MUX_3         : std_logic_vector(1 downto 0);
	signal MUX_1_out     : signed(15 downto 0);
	signal MUX_2_out     : signed(15 downto 0);
	signal MUX_3_out     : signed(15 downto 0);
	
	signal LUT_out       : signed(15 downto 0);
	

begin

	-- Mux 1 for selecting input to Register X 
	with MUX_1 select MUX_1_out <=
	X_temp       when "00",
	Y_abs        when "01",
	Y_temp       when "10",
	X_add_sub    when "11";

	-- Mux 2 for selecting input to Register Y
	with MUX_2 select MUX_2_out <= 
	Y_temp       when "00",
	X_abs        when "01",
	X_temp       when "10",
	Y_add_sub    when "11";

	-- Mux 3 for selecting input to Register Z
	with MUX_3 select MUX_3_out <=
	"0000000000000000" when "00", -- zero
	LUT_out    			 when "01", -- LUT 
	"0011001001000100" when "10", -- pi half 
	"0000000000000000" when "11"; -- zero (not used) 

	-- arctan Look Up Table - 16 bit (13 bit fraction)
	with counter select LUT_out <=
	"0001100100100010" when 0, -- decimal: 0.78...
	"0000111011010110" when 1, -- decimal:
	"0000011111010111" when 2, -- decimal:
	"0000001111111011" when 3,
	"0000000111111111" when 4,
	"0000000100000000" when 5,
	"0000000010000000" when 6,
	"0000000001000000" when 7,
	"0000000000100000" when 8,
	"0000000000010000" when 9,
	"0000000000001000" when 10,
	"0000000000000100" when 11,
	"0000000000000010" when 12,
	"0000000000000000" when 13;

	
	
	process(clk) is
	begin
		if rising_edge(clk) then
			if RESET = '1' then -- Synchronous reset
				-- RESET, output values
		    	MUX_1 <= "00";
    			MUX_2 <= "00";
    			MUX_3 <= "00";
    			DONE <= '1';


    			-- RESET, Internal values
    			state <= S1;
				quadrant_flag <= "00";
				counter <= 0;
				Z_add_sub <= "0000000000000000";
				
			else

				case state is  -- the signal "state" holds the next state 

					when S1 =>
						if START = '0' then 
							DONE <= '1';
							state <= S1; -- stay in S1 "standby mode"
						end if;
						
						if START ='1' then -- start is initiated
							DONE <= '0';
	   					state <= S2;  -- next state 	
						end if;
						

						
					------- State: S2 - Here we perform quadrant mapping --------------------
					when S2 =>
						-- Open the right output from the MUXes. The value is propagated through the MUX and into 
						-- corresponding register in the next state (S3)
						X_temp <= X_in;  
			         	Y_temp <= Y_in;  
						MUX_3 <= "00";  -- open up for initializing REG_Z with constant zero
								
						X_MSB_MAP <= X_in(15); -- get MSB used for quadrant detection and mapping
			         	Y_MSB_MAP <= Y_in(15);
							
						X_abs <= abs(X_in); -- get absolute value used for quadrant mapping
						Y_abs <= abs(Y_in);
						
					   	counter <= 0; -- initialize counter
					   	counter_out <= 0;
						
						
						if X_in(15) = '0' then -- 1st or 4th quadrant
							-- input X is positive meaning that we are either in 1st or 4th quadrant
							state <= S3;
						else
						
							if Y_in(15) = '0' then 
								-- 3rd Quadrant 
								state <= S4;
							else 
								-- we are in the 2nd quadrant
								state <= S5;
								
							end if;
							
						end if;
						
	
					------- State S3 to S5 --- Quadrant Mapping -----------------------------	
				   
					when S3 =>
						MUX_1 <= "00"; -- open up for X_in straight into REG_X 
						MUX_2 <= "00"; -- open up for Y_in straight into REG_Y
						quadrant_flag <= "00";
						state <= S6;

					
					when S4 =>
						MUX_1 <= "10"; -- Y_in into REG_X (mapping)
						MUX_2 <= "01"; -- X_abs into REG_Y (mapping)
						quadrant_flag <= "01";
						state <= S6;
						
						
					when S5 =>
						MUX_1 <= "01"; -- Y_abs into REG_X (mapping)
						MUX_2 <= "00"; -- Y_in into REG_Y (mapping)
						quadrant_flag <= "10"; 
						state <= S6;
					
					------- State S6 to S9 --- CORDIC Iterations  -------------------	
					
					when S6 =>
						Y_MSB <= MUX_2_out(15); -- get the MSB of Y
						REG_X <= MUX_1_out; -- insert value into register X
						REG_Y <= MUX_2_out; -- insert value into register Y 
						REG_Z <= Z_add_sub; -- insert value into register Z
						
						Z_out <= Z_add_sub; -- done for testing 
						MUX_3 <= "01"; -- update MUX_3 opening up for arctan LUT
					
						if MUX_2_out(15) = '0' then
							state <= S7;
						else
							state <= S8;
						end if;

					
					-- first iteration -> counter is zero. ie. no shifts take place 
					When S7 =>
						X_add_sub <= REG_X + shift_right(REG_Y, counter);
						Y_add_sub <= REG_Y - shift_right(REG_X, counter);
						Z_add_sub <= REG_Z + MUX_3_out; -- the LUT with "counter" used as index
						
						-- increment counter
						counter <= counter + 1;
						counter_out <= counter + 1;
						state <= S9;
					
					
					when S8 =>
						X_add_sub <= REG_X - shift_right(REG_Y, counter);
						Y_add_sub <= REG_Y + shift_right(REG_X, counter);
						Z_add_sub <= REG_Z - MUX_3_out; -- the LUT with "counter" used as index
						
						-- increment counter
						counter <= counter + 1;
						counter_out <= counter + 1;
						state <= S9;
				
					
					when S9 => 	
						if counter = 12 then 
							state <= S10; -- iterations done
						else
							state <= S6;  -- do more iterations
							-- update the MUXes making them ready for 
							-- more iteration starting again from S6
							MUX_1 <= "11"; 
							MUX_2 <= "11";
						end if;
					
					
					when S10 =>
						REG_X <= MUX_1_out; -- insert value from last iteration into register X
						REG_Y <= MUX_2_out; -- insert value from last iteration into register Y 
						REG_Z <= Z_add_sub; -- insert value from last iteration into register Z
	
						-- CORDIC iterations done - peform Post Quadrant Correction PQC if needed
						if quadrant_flag = "00" then -- 1st or 4th quadrant
							state <= S13;   -- no correction needed 
							
						elsif quadrant_flag = "01" then -- 2nd quadrant
						   MUX_3 <= "10";  -- open MUX_3 to propagate  pi/2
							state <= S12;  -- add pi/2
							
						elsif quadrant_flag = "10" then -- 3rd quadrant
							MUX_3 <= "10";  -- open MUX_3 to propagate  pi/2
							state <= S11;   -- subtract pi/2
						end if;
					
				
					when S11 =>
					   -- subtract pi/2 from angle Z
						REG_Z <= REG_Z - MUX_3_out; 
						state <= S13;

					when S12 =>
						-- add pi/2 to angle Z
						REG_Z <= REG_Z + MUX_3_out;   
						state <= S13;

			 		when S13 =>
					   	Z_out <= REG_Z;
			 			DONE <= '1'; -- resulting angle is now valid in register Z
			 			state <= S1; -- Back to standy mode is S1
						
			    end case;

			end if; -- end if RESET
			
		end if; -- end if rising edge 

	end process;

end architecture RTL;