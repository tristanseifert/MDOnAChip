library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity VGAOutput is
	port (
		ColourOut_R:		out STD_LOGIC_VECTOR(3 downto 0);
		ColourOut_G:		out STD_LOGIC_VECTOR(3 downto 0);
		ColourOut_B:		out STD_LOGIC_VECTOR(3 downto 0);
		
		ColourOut_HSync: 	out STD_LOGIC;
		ColourOut_VSync: 	out STD_LOGIC;
		
		-- clocks
		VDP_PClk:			in STD_LOGIC -- Pixel clock (25 MHz)
	);
end VGAOutput;

architecture Behavioral of VGAOutput is

	signal pixelCount: STD_LOGIC_VECTOR(9 downto 0);
	signal lineCount: STD_LOGIC_VECTOR(9 downto 0);
	signal frameNumber: STD_LOGIC;

begin

	process(VDP_PClk)
	begin
		if falling_edge(VDP_PClk) then
		
			-- active display
			if((pixelCount < 640) AND (lineCount < 480)) then
				colourOut_R <= pixelCount(5 downto 2);
				colourOut_G <= lineCount(5 downto 2);
				colourOut_B <= pixelCount(9 downto 6);
			end if;
			
			pixelCount <= pixelCount + '1';
			
			-- start of front porch
			if(pixelCount = 640) then
			-- start of sync pulse
			elsif(pixelCount = 656) then
				ColourOut_R <= "0000";
				colourOut_G <= "0000";
				ColourOut_B <= "0000";
				ColourOut_HSync <= '0';
			-- start of back porch
			elsif(pixelCount = 752) then
				ColourOut_HSync <= '1';		
			-- end of back porch
			elsif(pixelCount = 800) then
				pixelCount <= "0000000000";
				lineCount <= lineCount + '1';
			end if;
		
			-- start of front porch
			if(lineCount = 480) then
			-- start of sync pulse
			elsif(lineCount = 490) then
				ColourOut_VSync <= '0';
				ColourOut_R <= "0000";
				colourOut_G <= "0000";
				ColourOut_B <= "0000";
			-- start of back porch
			elsif(lineCount = 492) then
				ColourOut_VSync <= '1';
			-- end of back porch
			elsif(lineCount = 525) then
				frameNumber <= not frameNumber;
				lineCount <= "0000000000";
			end if;
			
		end if;
	end process;
end Behavioral;
