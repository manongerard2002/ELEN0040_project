library ieee;
use ieee.std_logic_1164.all;

entity game_catch_the_light is port(
	clock0 : in std_logic;
	clock1 : in std_logic;
	leds : out std_logic_vector(0 to 5) := "000000";
	reset_led : out std_logic := '0';
	score1 : buffer integer range 0 to 9 := 0;
	score2 : buffer integer range 0 to 9 := 0;
	buttons : in std_logic_vector(0 to 5);
	reset : in std_logic
);
end entity game_catch_the_light;

architecture game_catch_the_light_architecture of game_catch_the_light is

	constant max_lighten : integer := 3;

	type lighten_type is array(0 to max_lighten-1) of integer range 0 to 6;
	signal lighten_seq : lighten_type := (6, 6, 6);

	type states is (add_random, display, verification, correct, wrong, end_game);
	signal state : states := add_random;
	
	signal new_user_command : boolean := false;
	signal index_correct : integer range 0 to max_lighten-1;

	constant max_timer : integer := 1000;
	signal timer : integer range 0 to max_timer := 0;
	
	signal random : integer range 0 to 5;

begin
	random_generator : process(clock0)
	begin
		if (rising_edge(clock0)) then
			if (random = 5) then
				random <= 0;
			else
				random <= random + 1;
			end if;
		end if;
	end process random_generator;
	
	state_machine : process(clock1)
	variable number_lighten : integer range 0 to max_lighten := 0;
	variable user_selection : integer range 0 to 5;
	variable non_illuminated : boolean := true;
	begin
		if (rising_edge(clock1)) then
			if (timer < max_timer) then --Increase the timer at each clock cycle
				timer <= timer + 1;
			end if;
			case state is
				when add_random =>
					non_illuminated := true;
					if (lighten_seq(0) = random or lighten_seq(1) = random or lighten_seq(2) = random) then
						non_illuminated := false;
					end if; --Verification whether the LED is non-illuminated

					if (non_illuminated = true) then
						--The random number is added to the lighten LEDs
						lighten_seq(number_lighten) <= random;
						number_lighten := number_lighten + 1; --The size of the sequence is increamented
					end if;

					if (number_lighten = max_lighten) then
						state <= display;
					end if;

				when display =>
					for i in 0 to max_lighten-1 loop
						leds(lighten_seq(i)) <= '1'; --The LED of the lighten_seq at index i is on
					end loop;
					state <= verification; --End of the sequence

				when verification =>
					if (timer = max_timer) then --Verify the timer
						state <= end_game;

					elsif (buttons = "111111") then --No button pressed by the player
						new_user_command <= true;
					elsif (new_user_command) then --New signal send by the player
						new_user_command <= false;
						for i in 0 to 5 loop
							if (buttons(i) = '0') then 
								user_selection := i;
							end if;
						end loop; --Button signals interpretation

						non_illuminated := true;
						for i in 0 to max_lighten-1 loop
							if (user_selection = lighten_seq(i)) then
								non_illuminated := false;
								index_correct <= i;
							end if;
						end loop; --Verification of the chosen LED
						
						if (non_illuminated = false) then --The player is correct
							state <= correct;
						else --The player is wrong
							state <= wrong;
						end if;
					end if;
					
				when correct =>
					leds(lighten_seq(index_correct)) <= '0';
					for k in 0 to max_lighten-2 loop
						if (k >= index_correct) then
							lighten_seq(k) <= lighten_seq(k+1);
						end if;
					end loop; --Switch off
					number_lighten := number_lighten - 1;

					if (score1 = 9) then
						if (score2 < 9) then
							score1 <= 0;
							score2 <= score2 + 1;
						end if;
					else
						score1 <= score1 + 1;
					end if; --Reward
					state <= add_random;

				when wrong =>
					if (score1 = 0) then
						if (score2 >= 1) then
							score1 <= 9;
							score2 <= score2 - 1;
						end if;
					else
						score1 <= score1 - 1;
					end if; --Penalty
					state <= verification;

				when end_game =>
					number_lighten := 0;
					lighten_seq <= (6, 6, 6); --Reset the lighten sequence
					leds <= "000000"; --All the LEDs are off to indicate end of display
					reset_led <= '1';  --Except the reset LEDs to indicate the game can be started again
					if (reset = '0') then
						score1 <= 0; --reset the score that was still displayed at the end of the game
						score2 <= 0;
						state <= add_random;
						reset_led <= '0'; --The reset LED is off to indicate the game is running
						timer <= 0;
					end if;

			end case;
		end if;
	end process state_machine;
end architecture game_catch_the_light_architecture;