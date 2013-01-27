library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity SevenSegDriver is
	port (
		InputHex:			in STD_LOGIC_VECTOR(15 downto 0);
		
		HEX_0:				out STD_LOGIC_VECTOR(6 downto 0);
		HEX_1:				out STD_LOGIC_VECTOR(6 downto 0);
		HEX_2:				out STD_LOGIC_VECTOR(6 downto 0);
		HEX_3:				out STD_LOGIC_VECTOR(6 downto 0)
	);
end SevenSegDriver;

architecture Behavioral of SevenSegDriver is	
		constant state_0: STD_LOGIC_VECTOR(6 downto 0) := "1000000";
		constant state_1: STD_LOGIC_VECTOR(6 downto 0) := "1111001";
		constant state_2: STD_LOGIC_VECTOR(6 downto 0) := "0100100";
		constant state_3: STD_LOGIC_VECTOR(6 downto 0) := "0110000";
		
		constant state_4: STD_LOGIC_VECTOR(6 downto 0) := "0011001";
		constant state_5: STD_LOGIC_VECTOR(6 downto 0) := "0010010";
		constant state_6: STD_LOGIC_VECTOR(6 downto 0) := "0000010";
		constant state_7: STD_LOGIC_VECTOR(6 downto 0) := "1111000";
		
		constant state_8: STD_LOGIC_VECTOR(6 downto 0) := "0000000";
		constant state_9: STD_LOGIC_VECTOR(6 downto 0) := "0011000";
		constant state_A: STD_LOGIC_VECTOR(6 downto 0) := "0001000";
		constant state_B: STD_LOGIC_VECTOR(6 downto 0) := "0000011";
		
		constant state_C: STD_LOGIC_VECTOR(6 downto 0) := "1000110";
		constant state_D: STD_LOGIC_VECTOR(6 downto 0) := "0000110";
		constant state_E: STD_LOGIC_VECTOR(6 downto 0) := "1000000";
		constant state_F: STD_LOGIC_VECTOR(6 downto 0) := "0001110";
		
		constant state_Z: STD_LOGIC_VECTOR(6 downto 0) := "1111111";
begin

	process(InputHex)
	begin
		case InputHex(3 downto 0) is
			when "0000" => HEX_0 <= state_0;
			when "0001" => HEX_0 <= state_1; 
			when "0010" => HEX_0 <= state_2;
			when "0011" => HEX_0 <= state_3;
			when "0100" => HEX_0 <= state_4;
			when "0101" => HEX_0 <= state_5;
			when "0110" => HEX_0 <= state_6;
			when "0111" => HEX_0 <= state_7;
			when "1000" => HEX_0 <= state_8;
			when "1001" => HEX_0 <= state_9;
			when "1010" => HEX_0 <= state_A;
			when "1011" => HEX_0 <= state_B;
			when "1100" => HEX_0 <= state_C;
			when "1101" => HEX_0 <= state_D;
			when "1110" => HEX_0 <= state_E;
			when "1111" => HEX_0 <= state_F;
			when "ZZZZ" => HEX_0 <= state_Z;
		end case;
		
		
		case InputHex(7 downto 4) is
			when "0000" => HEX_1 <= state_0;
			when "0001" => HEX_1 <= state_1; 
			when "0010" => HEX_1 <= state_2;
			when "0011" => HEX_1 <= state_3;
			when "0100" => HEX_1 <= state_4;
			when "0101" => HEX_1 <= state_5;
			when "0110" => HEX_1 <= state_6;
			when "0111" => HEX_1 <= state_7;
			when "1000" => HEX_1 <= state_8;
			when "1001" => HEX_1 <= state_9;
			when "1010" => HEX_1 <= state_A;
			when "1011" => HEX_1 <= state_B;
			when "1100" => HEX_1 <= state_C;
			when "1101" => HEX_1 <= state_D;
			when "1110" => HEX_1 <= state_E;
			when "1111" => HEX_1 <= state_F;
			when "ZZZZ" => HEX_1 <= state_Z;
		end case;
		
		
		case InputHex(11 downto 8) is
			when "0000" => HEX_2 <= state_0;
			when "0001" => HEX_2 <= state_1; 
			when "0010" => HEX_2 <= state_2;
			when "0011" => HEX_2 <= state_3;
			when "0100" => HEX_2 <= state_4;
			when "0101" => HEX_2 <= state_5;
			when "0110" => HEX_2 <= state_6;
			when "0111" => HEX_2 <= state_7;
			when "1000" => HEX_2 <= state_8;
			when "1001" => HEX_2 <= state_9;
			when "1010" => HEX_2 <= state_A;
			when "1011" => HEX_2 <= state_B;
			when "1100" => HEX_2 <= state_C;
			when "1101" => HEX_2 <= state_D;
			when "1110" => HEX_2 <= state_E;
			when "1111" => HEX_2 <= state_F;
			when "ZZZZ" => HEX_2 <= state_Z;
		end case;
		
		
		case InputHex(15 downto 12) is
			when "0000" => HEX_3 <= state_0;
			when "0001" => HEX_3 <= state_1; 
			when "0010" => HEX_3 <= state_2;
			when "0011" => HEX_3 <= state_3;
			when "0100" => HEX_3 <= state_4;
			when "0101" => HEX_3 <= state_5;
			when "0110" => HEX_3 <= state_6;
			when "0111" => HEX_3 <= state_7;
			when "1000" => HEX_3 <= state_8;
			when "1001" => HEX_3 <= state_9;
			when "1010" => HEX_3 <= state_A;
			when "1011" => HEX_3 <= state_B;
			when "1100" => HEX_3 <= state_C;
			when "1101" => HEX_3 <= state_D;
			when "1110" => HEX_3 <= state_E;
			when "1111" => HEX_3 <= state_F;
			when "ZZZZ" => HEX_3 <= state_Z;
		end case;
		
	end process;
	
end Behavioral;
