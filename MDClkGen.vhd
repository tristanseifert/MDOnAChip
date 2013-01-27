library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity MDClockGen is
	port (
		MD_MainClk:			in STD_LOGIC;
		MD_CPUClk:			inout STD_LOGIC;
		MD_CPUClkSlow:		inout STD_LOGIC
	);
end MDClockGen;

architecture Behavioral of MDClockGen is

	signal CPUClkDivider: STD_LOGIC_VECTOR(2 downto 0);
	signal CPUClkDividerSlow: STD_LOGIC_VECTOR(22 downto 0);
	
begin

	process(MD_MainClk)
	begin
		if(rising_edge(MD_MainClk)) then
			if(CPUClkDivider = "010") then
				MD_CPUClk <= '1';
			elsif(CPUClkDivider = "011") then
				MD_CPUClk <= '0';
				CPUClkDivider <= "000";
			end if;
		
			if(CPUClkDividerSlow = "0111111111111111111111") then
				MD_CPUClkSlow <= '1';
			elsif(CPUClkDividerSlow = "11111111111111111111111") then
				MD_CPUClkSlow <= '0';
			end if;
	
			CPUClkDivider <= CPUClkDivider + '1';
			CPUClkDividerSlow <= CPUClkDividerSlow + '1';
		end if;		
	end process;
end Behavioral;
