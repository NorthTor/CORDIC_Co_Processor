

-- Author: Tor Kaufmann Gjerde
-- Project: Arcus tangent using the CORDIC algorithm 
-- Moore Finite State Machine architecture  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- CONTROLLER and datapath for arctan CORDIC co processor --
entity main is
port (

   clk          : in std_logic;
   START        : in std_logic;  -- Positive START
   RESET	    : in std_logic;  -- Positive RESET
    
   FSM_controll : out std_logic_vector(1 downto 0);
   DONE         : out std_logic;
   counter      : out integer range 0 to 13;
	   );
end entity main;


architecture RTL of FSM is 

	-- Enumerated type declaration and state signal declaration
	type t_state is (S1, S2, S3, S4, S5, S6,
					 	      S10, S11, S12); 
	signal state: t_state; 

	-- flag used for holding quadrant information
	signal quadrant_flag : std_logic_vector(1 downto 0);

begin

	process(clk) is
	begin
		if rising_edge(clk) then
			if RESET = '1' then -- Synchronous reset
				-- RESET, output values
				FSM_controll = "00"
		    	MUX_1 <= "00";
    			MUX_2 <= "00";
    			MUX_3 <= "00";
    			DONE <= '1';
    			counter <= 0;

    			-- RESET, Internal values
    			state <= S1;
				quadrant_flag <= "00";

			else
				case state is  -- the signal "state" holds the next state 

					when S1 =>
						if START = '0' then 
							DONE <= '1'; -- if START is zero everythin is DONE
							state <= S1; -- stay  in S1 "standby mode"
						end if;
						
						if START ='1' then -- start is initiated 
							DONE <= '0';
							--REG_X_input <= X_in;  -- Input register X is filled 
			                --REG_Y_input <= Y_in;  -- input register Y is filled
								
							--X_MSB_MAP <= X_in(15); -- get MSB used for quadrant detection and mapping
			                --Y_MSB_MAP <= Y_in(15);
							
							--X_abs <= abs(X_in); -- get absolute value used for quadrant mapping
							--Y_abs <= abs(Y_in);

	   					state <= S2;  -- next state 	
						end if;
						

					------- State: S2 - Here we perform quadrant mapping --------------------
					when S2 =>
						-- Open the right output from the MUXes. The value is propagated through the MUX and into 
						-- corresponding register in the next state (S3)
						
					   	counter <= 0; -- initialize counter
					   	MUX_3 <= "00"; -- open up for initializing REG_Z to zero

					  	FSM_controll = "01"; -- Load CORDIC registers in the following state (S3)
					  	FSM_QPM = "00"; -- CORDIC iterations not finished in the following state

						if X_MSB_MAP = '0' then -- 1st or 4th quadrant
							-- input X is positive meaning that we are either in 1st or 4th quadrant
							MUX_1 <= "00"; -- open up for X_in straight into REG_X 
							MUX_2 <= "00"; -- open up for Y_in straight into REG_Y
							quadrant_flag <= "00";
							state <= S3;
						else
						
							if Y_MSB_MAP = '1' then -- 3rd Quadrant
								MUX_1 <= "01"; -- abs(Y_in) into REG_X (mapping)
								MUX_2 <= "00"; -- Y_in into REG_Y (mapping)
								quadrant_flag <= "10"; 
								state <= S3;
							else 
								-- we are in the 2nd quadrant
								MUX_1 <= "10"; -- Y_in into REG_X
								MUX_2 <= "01"; -- abs(X_in) into REG_Y
								quadrant_flag <= "01";
								state <= S3;
								
							end if;
							
						end if;

	
					------- State 3 to 5 - Here we perform the CORDIC iterations -----------------------------	
				   
					when S3 =>
						-- Load values into CORDIC registers
						MUX_3 <= "01"; -- update MUX_3 opening up for arctan LUT
						FSM_controll = "00";  -- DON'T load CORDIC registers in the following state (S4 and S6) 

						-- Decide if we continue to quadrant post mapping (PQM) 
						-- we want to make maximum 12 iterations (ie. 12 shifts)
						if counter = 13 then 
							state <= S6;
						else
							state <=S4; -- Do more iterations
							FSM_controll = "10"; -- updates add_sub signal in the following state
						end if;
						

					-- Do iterations -> for first iteration counter should be zero. ie. no shifts take place 
					When S4 =>
						-- following signals get new values 
						-- X_add_sub 
						-- Y_add_sub
						-- Z_add_sub
						state <= S5;
				
					
					when S5 => 
					    -- We now need to update the MUXes output and the counter making them ready for 
					    -- the next iteration starting again from S3.  
						MUX_1 <= "11"; 
					    MUX_2 <= "11";

					    FSM_controll = "01"; -- load CORDIC registers in the following state (S3) 
						counter <= counter + 1; -- used as LUT index and nbr of shifts in the datapath
						state <= S3;
					
					
					when S6 =>
					-- CORDIC iterations done - peform PQM
						if quadrant_flag = "00" then -- 1st or 4th quadrant
							FSM_QPM <= "00"; -- no Quadrant Post Mapping 
							MUX_3 <= "00"; -- subtract/add zero to Z  ie. no change 
							FSM_controll = "00"; -- no change in datapath registers 
							state <= S12;  -- no correction needed 

						elsif quadrant_flag = "01" then -- 2nd quadrant
						   FSM_QPM <= "01";    -- Quadrant Post Mapping (addition)
						   MUX_3 <= "10";  -- open up MUX_3 in order to add pi/2 to angle Z
						   FSM_controll = '10'; -- Do add_sub signal update in datapath in the next state (S11)
						   state <= S11;
							
						elsif quadrant_flag = "10" then -- 3rd quadrant
							FSM_QPM <= "10";    -- Quadrant Post Mapping (subtraction)
							MUX_3 <= "10";  -- open up MUX_3 in order to subtract pi/2 from angle Z
							FSM_controll = '10'; -- Do add_sub signal update in datapath in the next state (S10)
							state <= S10;
						end if;
					
				
					when S10 =>
					    -- subtract pi/2 from angle Z
					    -- REG_Z <= REG_Z - MUX_3_out;
					    FSM_controll = "11"; -- update Z register only
					    state <= S12;

					when S11 =>
						-- add pi/2 to angle Z
						-- REG_Z <= REG_Z + MUX_3_out; 
						FSM_controll = "11"; -- update Z register only
						state <= S12;

			 		when S12 =>
			 			DONE <= '1'; -- resulting angle is now valid in register Z
			 			state <= S1; -- Back to "standy mode" is state 1
						
			    end case;

			end if; -- end if RESET
			
		end if; -- end if rising edge 

	end process;

end architecture RTL;
