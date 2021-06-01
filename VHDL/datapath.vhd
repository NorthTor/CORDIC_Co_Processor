





signal REG_X_input   : signed(15 downto 0);
signal REG_Y_input   : signed(15 downto 0);
signal REG_X         : signed(15 downto 0);
signal REG_Y         : signed(15 downto 0);
signal REG_Z         : signed(15 downto 0);

signal MUX_1_out     : signed(15 downto 0);
signal MUX_2_out     : signed(15 downto 0);
signal MUX_3_out     : signed(15 downto 0);
signal LUT_out       : signed(15 downto 0);

signal X_MSB_MAP     : std_logic;
signal Y_MSB_MAP     : std_logic;
signal Y_MSB         : std_logic;
signal Y_abs         : signed(15 downto 0);
signal X_abs         : signed(15 downto 0);

signal X_add_sub     : signed(15 downto 0);
signal Y_add_sub     : signed(15 downto 0);
signal Z_add_sub     : signed(15 downto 0);


------------------------------------------------------------------------------------------------------
	-- Mux 1 for selecting input to Register X 
	with MUX_1 select MUX_1_out <=
	REG_X_input  when "00",
	Y_abs        when "01",
	REG_Y_input  when "10",
	X_add_sub    when "11";

	-- Mux 2 for selecting input to Register Y
	with MUX_2 select MUX_2_out <= 
	REG_Y_input   when "00",
	X_abs         when "01",
	REG_X_input   when "10",
	Y_add_sub     when "11";

	-- Mux 3 for selecting input to Adder in Z path
	with MUX_3 select MUX_3_out <=
	"0000000000000000" when "00", -- zero
	LUT_out    		   when "01", -- LUT 
	"0011001001000100" when "10", -- pi half 
	"0000000000000000" when "11"; -- zero (not used) 

    -- Arctan Look Up Table - 16 bit (13 bit fraction)
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

------------------------------------------------------------------------------------------------------

process(clk)
if rising_edge(clk) then 
	if RESET = '1' then
		-- reset registers and signals 
		REG_X <= "0000000000000000";
		REG_Y <= "0000000000000000";
		REG_Z <= "0000000000000000";
		X_add_sub <= "0000000000000000";
		Z_add_sub <= "0000000000000000";
		Y_add_sub <= "0000000000000000";

	else

		REG_X_input <= X_in;  -- input register X is filled on each clock
		REG_Y_input <= Y_in;  -- input register Y is filled on each clock 

		X_MSB_MAP <= X_in(15); -- These two signals must also act as an output to FSM for use in S2
		Y_MSB_MAP <= Y_in(15);  
							
		X_abs <= abs(X_in); -- get absolute value used for quadrant mapping
		Y_abs <= abs(Y_in);
------------------------------------------------------------------------------------------------------

		if FSM_controll = "01" then 
			-- Load all registers with new values and get new values
			REG_X <= MUX_1_out; -- insert value into register X
			REG_Y <= MUX_2_out; -- insert value into register Y
			REG_Z <= Z_add_sub; -- insert value into register Z

        	if FSM_QPM = "00" -- CORDIC iterations NOT yet finished or no Quadrant Post Mapping need to take place  
				Y_MSB <= MUX_2_out(15); -- get the Y_MSB for next 

			elsif FSM_QPM = "01" then -- CORDIC iterations FINISHES in the next clock  
				Y_MSB <= '0'; -- set Z_add_sub for addition 
				-- 2nd next clock FSM_controll equals "11"

			elsif FSM_QPM = "10" then
				Y_MSB <= '1'; -- set Z_add_sub for subtraction
				-- 2nd next clock FSM_controll equals "11"
			end if;
		end if;


		if FSM_controll = '10' then 
			-- Do add_sub signal update
		    if Y_MSB = '1' then
				X_add_sub <= REG_X - shift_right(REG_Y, counter);
				Y_add_sub <= REG_Y + shift_right(REG_X, counter);
				Z_add_sub <= REG_Z - MUX_3_out; -- the LUT with "counter" used as index
			else
				X_add_sub <= REG_X + shift_right(REG_Y, counter);
				Y_add_sub <= REG_Y - shift_right(REG_X, counter);
				Z_add_sub <= REG_Z + MUX_3_out; -- the LUT with "counter" used as index
			end if;
        end if; 


        if FSM_controll = "11" then
	 		-- Load only Z with new (mapped) value (counter = 13)
	 		-- X and Y register should not be altered when doing Post Quadrant Mapping 
	    	REG_Z <= Z_add_sub; -- insert value into register Z
	    end if;

	    if FSM_controll = "00" then
	    	-- nothing happens - the registers in the CORDIC iteration path is not updated
	    end if;

	end if; -- RESET
end if; -- rising clock 
	   	    




