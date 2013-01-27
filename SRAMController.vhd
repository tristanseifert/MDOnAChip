library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity SRAMController is
	port (
		MainCLK:				in STD_LOGIC;
		
		-- Interface to physical SRAM
		SRAM_Addr:			out STD_LOGIC_VECTOR(17 downto 0);
		SRAM_Data:			inout STD_LOGIC_VECTOR(15 downto 0);
		SRAM_CS:				out STD_LOGIC;
		SRAM_OE:				out STD_LOGIC;
		SRAM_UB:				out STD_LOGIC;
		SRAM_LB:				out STD_LOGIC;
		SRAM_WE:				out STD_LOGIC;
		
		-- CPU interface
		CPU_Addr:			in STD_LOGIC_VECTOR(15 downto 0); -- 64K allocated to 68k
		CPU_DataIn:			in STD_LOGIC_VECTOR(15 downto 0);
		CPU_DataOut:		out STD_LOGIC_VECTOR(15 downto 0);
		CPU_RW:				in STD_LOGIC;
		CPU_AS:				in STD_LOGIC;
		CPU_UDS:				in STD_LOGIC;
		CPU_LDS:				in STD_LOGIC;
		CPU_DTACK:			out STD_LOGIC;
		CPU_CS:				in STD_LOGIC :='1';
		
		-- VDP interface
		VDP_Addr:			in STD_LOGIC_VECTOR(15 downto 0); -- 64K allocated to VRAM
		VDP_Data:			inout STD_LOGIC_VECTOR(15 downto 0);
		VDP_RW:				in STD_LOGIC;
		VDP_AS:				in STD_LOGIC;
		VDP_DTACK:			out STD_LOGIC
	);
end SRAMController;

architecture Behavioral of SRAMController is
	signal CurrentMemoryCycle: STD_LOGIC_VECTOR(3 downto 0);
	signal CurrentMainClockCycle: STD_LOGIC_VECTOR(1 downto 0);
	
	signal ActualSRAMAddress: STD_LOGIC_VECTOR(17 downto 0);
	signal ActualSRAMData: STD_LOGIC_VECTOR(15 downto 0);
	signal ActualReadSRAMData: STD_LOGIC_VECTOR(15 downto 0);
	signal ActualSRAMReadMode: STD_LOGIC;
	signal ActualSRAMByteMask: STD_LOGIC_VECTOR(1 downto 0);
	
	-- Output state machine
	signal OS_State:		STD_LOGIC_VECTOR(1 downto 0);
	
begin
		process(MainCLK)
		begin
			if(falling_edge(MainCLK)) then
				CurrentMainClockCycle <= CurrentMainClockCycle + '1';
				
				if(CurrentMainClockCycle = "10") then
					CurrentMainClockCycle <= "00";
					CurrentMemoryCycle <= CurrentMemoryCycle + '1';
				
					-- 68k memory cycle
					if(CurrentMemoryCycle = "1111" AND CPU_CS = '0') then
						ActualSRAMAddress <= "00" & CPU_Addr;
						ActualSRAMReadMode <= CPU_RW;
						ActualSRAMByteMask <= CPU_UDS & CPU_LDS;
				
						-- If the access is a write, we need to tell it what data to write
						if(CPU_RW = '0') then
							ActualSRAMData <= CPU_DataIn;
					
						-- If it's not a write, tristate the data bus
						else
							ActualSRAMData <= "ZZZZZZZZZZZZZZZZ";
						end if;
				
						-- address output stage
						OS_State <= "00";
			
					-- VDP access cycle
					else
				
					end if;
				elsif(CurrentMainClockCycle = "01") then
					OS_State <= "01";
				end if;
			end if;
		end process;

		-- Output state machine.
		process(OS_State)
		begin
			case OS_State is
				when "00" =>
					-- No data has been fetched yet.
					CPU_DTACK <= '1';
					VDP_DTACK <= '1';
					
					SRAM_CS <= '0';
					SRAM_OE <= '0';
						
					SRAM_Addr <= ActualSRAMAddress;
					
					-- If we're writing to SRAM, give it the data too
					if(ActualSRAMReadMode = '0') then
						SRAM_WE <= '0';
						SRAM_Data <= ActualSRAMData;
					else
						SRAM_WE <= '1';
					end if;
				when "01" =>
					-- If it's a read, actually read the damn SRAM, durr
					if(ActualSRAMReadMode = '1') then
						ActualReadSRAMData <= SRAM_Data;
					end if;
					
					if(CurrentMemoryCycle = "1111" AND CPU_CS = '0') then
						CPU_DTACK <= '0';
						VDP_DTACK <= '1';
					else
						CPU_DTACK <= '1';
						VDP_DTACK <= '0';
					end if;
					
					-- Drive the appropriate data bus.
					if(ActualSRAMReadMode = '1') then
						if(CurrentMemoryCycle = "1111" AND CPU_CS = '0') then
							CPU_DataOut <= ActualReadSRAMData;
						else
							VDP_Data <= ActualReadSRAMData;
						end if;
					end if;

				when others =>
					null;
			end case;
		end process;
			
end Behavioral;
