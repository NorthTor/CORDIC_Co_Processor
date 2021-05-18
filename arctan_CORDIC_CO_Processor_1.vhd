
--DATAPATH CODE --

entity datapath_arctan_CORDIC is 
port(

X_in    : in signed(15 downto 0);		-- input coordinate from main processor
Y_in    : in signed(15 downto 0);		-- input coordinate from main pocessor

MUX_1   : in std_logic_vector(1 downto 0);      -- control signal in from FSM
MUX_2   : in std_logic_vector(1 downto 0);      -- control signal in from FSM
MUX_3   : in std_logic_vector(1 downto 0);      -- control signal in from FSM

counter : in std_logic_vectore(3 downto 0);     -- control signal in from FSM
CLK     : in std_logic;

X_MSB_MAP : out std_logic;  -- control signal out to FSM
Y_MSB_MAP : out std_logic;  -- control signal out to FSM
Y_MSB     : out std_logic;  -- control signal out to FSM

Z_out : out signed(15 downto 0); -- Output radian angle to main processor
)
end entity;


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
0 			  when "00"
LUT_out       when "01"
pi_half 	  when "10"


-- arctan Look Up Table
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


-- Following describes the register transfers at each clock edge
process(CLK) 
begin

	REG_X_input <= X_in; 
	REG_Y_input <= Y_in;

	X_MSB_MAP <= X_in(15);
	Y_MSB_MAP <= Y_in(15);

	REG_X_temp <= REG_X_input;
	REG_Y_temp <= REG_Y_input;

	-- ABS logic 
	X_abs <= abs(REG_X_temp);
	Y_abs <= abs(REG_Y_temp);

	--Get the MSB out from MUX_2;
	Y_MSB <= MUX_2_out(15);

	REG_X <= MUX_1_out;
	REG_Y <= MUX_2_out;

	-- shift values "counter" amount of right using arithmetic shift right (sra) 
	shifted_Y <= REG_Y sra counter;
	shifted_X <= REX_X sra counter;

	IF Y_MSB = '1' THEN
		X_add_sub <= REG_X - shifted_Y;
		Y_add_sub <= REG_Y + shifted_X;
		REG_Z <= REG_Z - MUX_3_out
	ELSE
		X_add_sub <= REG_X + shifted_Y;
		Y_add_sub <= REG_Y - shifted_X;
		REG_Z <= REG_Z + MUX_3_out;

		-- Register REG_Z is valid output when DONE is '1'
end process





-- CONTROLLER CODE --

entity controller_arctan_CORDIC is
port (
	START     : in std_logic;
	RESET	  : in std_logic;

    X_MSB_MAP : in std_logic;
    Y_MSB_MAP : in std_logic;
    Y_MSB     : in std_logic;

    MUX_1     : out std_logic_vector(1 downto 0);
    MUX_2     : out std_logic_vector(1 downto 0);
    MUX_3     : out std_logic_vector(1 ownto 0);
    counter   : out std_logic_vector(3 downto 0); -- used for both number of shifts and LUT index 
    
    DONE      : out std_logic;
    CLK       : in std_logic;
) ;
end entity;


architecture RTL of controller_arctan_CORDIC is 
	-- Enumerated type declaration and state signal declaration
	type t_state is (S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12); 
	signal state: t_state; 

	-- Flag used for holding quadrant information
	signal quadrant_flag: std_logic_vector(1 downto 0);

	-- Counter for counting clock ticks
	signal counter integer range 0 to 12

begin
	
	process(clk)
		IF rising_edge(clk)

			IF RESET = '1'
				-- RESET values

				-- Outputs
		    	MUX_1 <= '00';
    			MUX_2 <= '00';
    			MUX_3 <= '00';
    			DONE <= '0';
    			nbr_shift <= '0000';

    			-- Internals
    			state <= S1;
				quadrant_flag = '00';
				counter <= '0';

			ELSE 
			    -- DEFAULT values

				-- Outputs
		    	MUX_1 <= '00';
    			MUX_2 <= '00';
    			MUX_3 <= '00';
    			DONE <= '0';
    			nbr_shift <= '0000';

    			-- Internals
    			state <= S1;
				quadrant_flag = '00';
			    counter <= 0; 


				CASE state IS  -- the signal "state" holds the next state 

					WHEN S1 =>
						IF START ='1' THEN -- start is initiated 
	   						state <= S2; 
						ELSE IF start ='0' THEN 
		    				state <= S1; -- back to "standby mode"
					END IF;

					------- State: S2 to S5 - Here we perform quadrant detection and mapping --------------------
					WHEN S2 =>
						IF X_MSB_MAP ='0' THEN -- next state logic 
							-- input X is positive meaning that we are either in 1st or 4th quadrant
							state <= S5;
						ELSE	
							IF Y_MSB_MAP = '1' THEN -- next state logic
								-- input Y and X are negative - we are in 3rd quadrant
								state <= S3;
							ELSE 
								-- we are in the 2nd quadrant
								state <= S4;
							END IF;
						END IF;


					WHEN S3 =>
						MUX_1 <= '01'; -- abs(Y_in) into REG_X
						MUX_2 <= '00'; -- Y_in into REG_Y
						quadrant_flag <= '10'; 
						state <= S5;

					WHEN S4 =>
						MUX_1 <= '10'; -- Y_in into REG_X
						MUX_2 <= '01'; -- abs(X_in) into REG_Y
						quadrant_flag <= '01';
						state <= S5;

					WHEN S5 => 
						MUX_1 <= '00' -- X_in into REG_X
						MUX_2 <= '00' -- Y_in into REG_Y
						quadrant_flag = '00';
						state <= S6;

					------- State: S6 to S9 - Here we perform the CORDIC iterations ------------------------------

					WHEN S6 => 
						IF Y_MSB = '1' THEN 
							state <= S8;
						ELSE
							state <= S7;
						END IF;

					WHEN S7 => 
						MUX_1 <= '11';  -- add X and Y    result in REG X    (shifted Y in following iterations)
						MUX_2 <= '11';  -- sub Y from X   result in REG Y    (shifted X in following iterations)
						MUX_3 <= '01';  -- add Z and atan_LUT(counter) 
						state <= S9;   

					WHEN S8 =>
						MUX_1 <= '11';    --  sub Y from X    result in REG X
						MUX_2 <= '11';    --  add Y and X     result in REG Y
						MUX_3 <= '01';	  --  sub atan_LUT(counter) from Z
						state <= S9; 

					WHEN S9 =>
						IF counter = N  THEN
							-- CORDIC iterations finished do quadrant post correction
							IF quadrant_flag = '00' THEN -- 1st or 4th quadrant
								state <= S12;
							ELSE IF quadrant_flag = '01' THEN -- 2nd quadrant
								state <= S11;

							ELSE IF quadrant_flag = '10' THEN -- 3rd quadrant
								state <= S10;
							END IF;
						ELSE
							-- CORDIC iterations not finished
							counter = counter + 1; 	
							state <= S6;	
						END IF;
				
					WHEN S10 =>
						MUX_3 <= '10';  -- subtract pi/2 to angle Z
						state <= S12;

					WHEN S11 =>
						MUX_3 <= '10'  -- add pi/2 to angle Z
						state <= S12;

			 		WHEN S12 =>
			 			DONE <= '1' -- resulting angle is now valid in register Z
			 			state <= S1

			 	END CASE;

			 END IF;
		END IF;
	END process;

END architecture;















