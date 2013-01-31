library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity MDOnAChip is
	port (
		-- VGA
		VGAOut_R:		out STD_LOGIC_VECTOR(3 downto 0);
		VGAOut_G:		out STD_LOGIC_VECTOR(3 downto 0);
		VGAOut_B:		out STD_LOGIC_VECTOR(3 downto 0);
		
		VGA_HSync: 		out STD_LOGIC;
		VGA_VSync: 		out STD_LOGIC;
		
		-- IO/HID
		PS2_CLK:			inout STD_LOGIC;
		PS2_DAT:			inout STD_LOGIC;
		
		RS232_TXD:		out STD_LOGIC;
		RS232_RXD:		in STD_LOGIC;
		
		SW_Toggle:		in STD_LOGIC_VECTOR(9 downto 0);
		SW_Push:			in STD_LOGIC_VECTOR(3 downto 0);
		
		LED_Red:			out STD_LOGIC_VECTOR(9 downto 0);
		LED_Green:		out STD_LOGIC_VECTOR(7 downto 0);
		
		-- Audio
		AUD_ADCLRCK:	in STD_LOGIC;
		AUD_ADCLRDAT: 	in STD_LOGIC;
		AUD_DACLRCK:	out STD_LOGIC;
		AUD_DACLRDAT:	out STD_LOGIC;
		AUD_XCK:			out STD_LOGIC;
		AUD_BCLK:		out STD_LOGIC;
		AUD_I2C_SCK:	inout STD_LOGIC;
		AUD_I2C_SDA:	inout STD_LOGIC;
		
		-- SDRAM
		SDRAM_Addr:		out STD_LOGIC_VECTOR(11 downto 0);
		SDRAM_Bank:		out STD_LOGIC_VECTOR(1 downto 0);
		
		SDRAM_Data:		inout STD_LOGIC_VECTOR(15 downto 0);
		
		SDRAM_LDQM:		out STD_LOGIC;
		SDRAM_UDQM:		out STD_LOGIC;
		SDRAM_WE:		out STD_LOGIC;
		SDRAM_CS:		out STD_LOGIC;
		
		SDRAM_RAS:		out STD_LOGIC;
		SDRAM_CAS:		out STD_LOGIC;
		
		SDRAM_CKE:		out STD_LOGIC;
		SDRAM_CLK:		out STD_LOGIC;
		
		-- SRAM
		SRAM_Addr:		out STD_LOGIC_VECTOR(17 downto 0);
		SRAM_Data:		inout STD_LOGIC_VECTOR(15 downto 0);
		
		SRAM_CS:			out STD_LOGIC;
		SRAM_OE:			out STD_LOGIC;
		
		SRAM_UB:			out STD_LOGIC;
		SRAM_LB:			out STD_LOGIC;
		
		SRAM_WE:			out STD_LOGIC;
		
		-- 7 segment
		HEX_0:			out STD_LOGIC_VECTOR(6 downto 0) := "1000001";
		HEX_1:			out STD_LOGIC_VECTOR(6 downto 0) := "1000000";
		HEX_2:			out STD_LOGIC_VECTOR(6 downto 0) := "1000000";
		HEX_3:			out STD_LOGIC_VECTOR(6 downto 0) := "1000000";
		
		-- clocks
		CLK_50:			in STD_LOGIC;
		CLK_27:			in STD_LOGIC;
		CLK_24:			in STD_LOGIC
	);
end MDOnAChip;

architecture Behavioral of MDOnAChip is
	signal VGA_PixelClock: STD_LOGIC;
	
	signal CPU_CLK: 			STD_LOGIC;
	signal CPU_Reset: 		STD_LOGIC;
	signal CPU_ClkEna_In: 	STD_LOGIC:='1';
	signal CPU_Data_in: 		STD_LOGIC_VECTOR(15 downto 0);
	signal CPU_IPL: 			STD_LOGIC_VECTOR(2 downto 0):="111";
	signal CPU_DTACK: 		STD_LOGIC;
	signal CPU_Addr: 			STD_LOGIC_VECTOR(31 downto 0);
	signal CPU_Data_Out: 	STD_LOGIC_VECTOR(15 downto 0);
	signal CPU_AS: 			STD_LOGIC;
	signal CPU_UDS: 			STD_LOGIC;
	signal CPU_LDS: 			STD_LOGIC;
	signal CPU_RW: 			STD_LOGIC;
	signal CPU_drive_data: 	STD_LOGIC;				--enable for data_out driver
	
	signal ROM_Data:			STD_LOGIC_VECTOR(15 downto 0);
	
	signal MD_MasterClk: 	STD_LOGIC;
	signal CPU_CLK_Real:		STD_LOGIC;
	signal CPU_CLK_Slow:		STD_LOGIC;
	
	signal MemClk:				STD_LOGIC;
	
	signal HexDisplayVal:	STD_LOGIC_VECTOR(15 downto 0);
	
	signal VDP_Mem_Addr:		STD_LOGIC_VECTOR(15 downto 0);
	signal VDP_Mem_Data:		STD_LOGIC_VECTOR(15 downto 0);
	signal VDP_Mem_RW:		STD_LOGIC;
	signal VDP_Mem_AS:		STD_LOGIC;
	signal VDP_Mem_DTACK:	STD_LOGIC;
	
	signal CPU_RAM_CS:		STD_LOGIC:='1';
	
	signal CPU_REAL_DTACK:	STD_LOGIC;
	signal CPU_VDP_DTACK: 	STD_LOGIC;
	signal CPU_RAM_DTACK: 	STD_LOGIC;
	
	signal VDP_ColourBus:	STD_LOGIC_VECTOR(11 downto 0);
	signal Vid_HSync:			STD_LOGIC;
	signal Vid_VSync:			STD_LOGIC;

	component MainSystemPLL
		port (
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
		);
	end component MainSystemPLL;

	
	component TG68
		port(        
			clk           : in std_logic; --
			reset         : in std_logic; --
			clkena_in     : in std_logic:='1'; --
			data_in       : in std_logic_vector(15 downto 0); --
			IPL           : in std_logic_vector(2 downto 0):="111"; ---
			dtack         : in std_logic; --
			addr          : out std_logic_vector(31 downto 0); --
			data_out      : out std_logic_vector(15 downto 0); --
			as            : out std_logic; --
			uds           : out std_logic; --
			lds           : out std_logic; --
			rw            : out std_logic; --
			drive_data    : out std_logic	 --			--enable for data_out driver
		);
	end component TG68;
	
	component VGAOutput
		port (
			ColourOut_R:		out STD_LOGIC_VECTOR(3 downto 0);
			ColourOut_G:		out STD_LOGIC_VECTOR(3 downto 0);
			ColourOut_B:		out STD_LOGIC_VECTOR(3 downto 0);
		
			ColourOut_HSync: 	out STD_LOGIC;
			ColourOut_VSync: 	out STD_LOGIC;
		
			PixelInput:			in STD_LOGIC_VECTOR(11 downto 0);
		
			-- clocks
			VDP_PClk:			in STD_LOGIC -- Pixel clock (25 MHz)
		);
	end component VGAOutput;
	
	component MDPLL
	port (
		inclk0		: IN STD_LOGIC  := '0';
		c0				: OUT STD_LOGIC 
	);
	end component MDPLL;
	
	component MDClockGen
		port (
			MD_MainClk:			in STD_LOGIC;
			MD_CPUClk:			inout STD_LOGIC;
			MD_CPUClkSlow:		inout STD_LOGIC
		);
	end component MDClockGen;
	
	component VDP
		port (
			VDP_MainClk:		in STD_LOGIC;
			VDP_50MHzClk:		in STD_LOGIC;
			VDP_PixelClk:		in STD_LOGIC;

			-- VGA interface
			ColourOut_R:		out STD_LOGIC_VECTOR(3 downto 0);
			ColourOut_G:		out STD_LOGIC_VECTOR(3 downto 0);
			ColourOut_B:		out STD_LOGIC_VECTOR(3 downto 0);
			
			ColourOut_HSync: 	out STD_LOGIC;
			ColourOut_VSync: 	out STD_LOGIC;
		
			CPUBus_Clk:			in STD_LOGIC;
			CPU_Addr:			in STD_LOGIC_VECTOR(23 downto 0);
			CPU_DataIn:			in STD_LOGIC_VECTOR(15 downto 0);
			CPU_DataOut:		out STD_LOGIC_VECTOR(15 downto 0);
			CPU_RW:				in STD_LOGIC;
			CPU_AS:				in STD_LOGIC;
			CPU_DTACK:			out STD_LOGIC;
			CPU_IPL:				out STD_LOGIC_VECTOR(2 downto 0) := "111";
		
			Mem_Addr:			in STD_LOGIC_VECTOR(15 downto 0);
			Mem_Data:			inout STD_LOGIC_VECTOR(15 downto 0);
			Mem_RW:				in STD_LOGIC;
			Mem_AS:				in STD_LOGIC;
			Mem_DTACK:			out STD_LOGIC;
		
			VDP_State:			out STD_LOGIC_VECTOR(3 downto 0)
		);
	end component VDP;
	
	component MD_TestPrgROM
		port (
			address		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	end component MD_TestPrgROM;
	
	component SevenSegDriver
		port (
			InputHex:			in STD_LOGIC_VECTOR(15 downto 0);
		
			HEX_0:				out STD_LOGIC_VECTOR(6 downto 0);
			HEX_1:				out STD_LOGIC_VECTOR(6 downto 0);
			HEX_2:				out STD_LOGIC_VECTOR(6 downto 0);
			HEX_3:				out STD_LOGIC_VECTOR(6 downto 0)
		);
	end component SevenSegDriver;
	
	component SRAMController
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
			CPU_Addr:			in STD_LOGIC_VECTOR(15 downto 0);
			CPU_DataIn:			in STD_LOGIC_VECTOR(15 downto 0);
			CPU_DataOut:		out STD_LOGIC_VECTOR(15 downto 0);
			CPU_RW:				in STD_LOGIC;
			CPU_AS:				in STD_LOGIC;
			CPU_UDS:				in STD_LOGIC;
			CPU_LDS:				in STD_LOGIC;
			CPU_DTACK:			out STD_LOGIC;
			CPU_CS:				in STD_LOGIC :='1';
			
			-- VDP interface
			VDP_Addr:			in STD_LOGIC_VECTOR(15 downto 0);
			VDP_Data:			inout STD_LOGIC_VECTOR(15 downto 0);
			VDP_RW:				in STD_LOGIC;
			VDP_AS:				in STD_LOGIC;
			VDP_DTACK:			out STD_LOGIC
		);
	end component SRAMController;
	
begin
	SRAMMultiplexer: SRAMController port map(MainCLK => MemClk,
														  SRAM_Addr => SRAM_Addr, SRAM_Data => SRAM_Data,
														  SRAM_CS => SRAM_CS, SRAM_OE => SRAM_OE, SRAM_WE => SRAM_WE,
														  SRAM_UB => SRAM_UB, SRAM_LB => SRAM_LB,
														  
														  CPU_Addr => CPU_Addr(16 downto 1), CPU_DataIn => CPU_Data_in,
														  CPU_DataOut => CPU_Data_Out, CPU_RW => CPU_RW, CPU_AS => CPU_AS,
														  CPU_UDS => CPU_UDS, CPU_LDS => CPU_LDS, CPU_DTACK => CPU_RAM_DTACK, CPU_CS => CPU_RAM_CS,
														  
														  VDP_AS => VDP_Mem_AS, VDP_DTACK => VDP_Mem_DTACK, VDP_RW => VDP_Mem_RW,
														  VDP_Addr => VDP_Mem_Addr, VDP_Data => VDP_Mem_Addr);

	MainPLL: MainSystemPLL port map(inclk0 => clk_50, c0 => VGA_PixelClock, c1 => MemClk);
	MegaDriveClkPLL: MDPLL port map(inclk0 => CLK_24, c0 => MD_MasterClk);
	MegaDriveClkGen: MDClockGen port map(MD_MainClk => MD_MasterClk, MD_CPUClk => CPU_CLK_Real, MD_CPUClkSlow => CPU_CLK_Slow);
	
--	VGAOutputter: VGAOutput port map(ColourOut_R => VGAOut_R, ColourOut_G => VGAOut_G, ColourOut_B => VGAOut_B,
--												ColourOut_HSync => Vid_HSync, ColourOut_VSync => Vid_VSync,
--												VDP_PClk => VGA_PixelClock, PixelInput => VDP_ColourBus);

	CPU: TG68 port map(clk => CPU_CLK, clkena_in => CPU_ClkEna_In, reset => CPU_Reset,
							 data_in => CPU_Data_in, data_out => CPU_Data_Out, rw => CPU_RW, dtack => CPU_REAL_DTACK,
							 addr => CPU_Addr, as => CPU_AS, uds => CPU_UDS, lds => CPU_LDS,
							 IPL => CPU_IPL, drive_data => CPU_Drive_data);
	
	MD_VDP: VDP port map(VDP_MainClk => MD_MasterClk, VDP_PixelClk => VGA_PixelClock, VDP_50MHzClk => CLK_50,

								CPUBus_Clk => CPU_CLK, CPU_Addr => CPU_Addr(23 downto 0),
								CPU_DataIn => CPU_Data_in, CPU_DataOut => CPU_Data_Out,
								CPU_RW => CPU_RW, CPU_AS => CPU_AS, CPU_DTACK => CPU_VDP_DTACK, CPU_IPL => CPU_IPL,
								
								ColourOut_R => VGAOut_R, ColourOut_G => VGAOut_G, ColourOut_B => VGAOut_B,
								ColourOut_HSync => Vid_HSync, ColourOut_VSync => Vid_VSync,
												
								Mem_Data => VDP_Mem_Data, Mem_Addr => VDP_Mem_Addr, Mem_AS => VDP_Mem_AS, Mem_DTACK => VDP_Mem_DTACK,
								Mem_RW => VDP_Mem_RW,
								
								VDP_State => LED_Red(9 downto 6));

	TMSSROM: MD_TestPrgROM port map(address => CPU_Addr(9 downto 1), q => ROM_Data, clock => CPU_CLK);

	HexDriver: SevenSegDriver port map(InputHex => HexDisplayVal, HEX_0 => HEX_0, HEX_1 => HEX_1, HEX_2 => HEX_2,
												  HEX_3 => HEX_3);
	
	VGA_HSync <= Vid_HSync;
	VGA_VSync <= Vid_VSync;
	
	LED_Red(0) <= CPU_CLK;
	
	LED_Green(0) <= CPU_RW;
	LED_Green(1) <= CPU_AS;
	LED_Green(2) <= CPU_DTACK;
	LED_Green(3) <= CPU_UDS;
	LED_Green(4) <= CPU_LDS;
	
	LED_Green(5) <= CPU_IPL(0);
	LED_Green(6) <= CPU_IPL(1);
	LED_Green(7) <= CPU_IPL(2);
	
	CPU_Reset <= SW_Push(3);

	process(SW_Toggle(0))
	begin
		if(SW_Toggle(0) = '1') then
			if(SW_Toggle(1) = '1') then
				CPU_CLK <= CPU_CLk_Real;
			else
				CPU_CLK <= CPU_CLk_Slow;
			end if;
		else
			CPU_CLK <= SW_Push(0);		
		end if;
	end process;
	
	process(SW_Toggle(3))
	begin
		if(SW_Toggle(3) = '1') then
			CPU_REAL_DTACK <= SW_Push(2);
		else
			CPU_REAL_DTACK <= CPU_DTACK;
		end if;
	end process;
	
	process(SW_Toggle(2))
	begin
		if(SW_Toggle(2) = '1') then
			if(CPU_AS = '1') then
				HexDisplayVal <= "ZZZZZZZZZZZZZZZZ";
			else
				HexDisplayVal <= CPU_Addr(15 downto 0);
			end if;
		else
	--		if(CPU_RW = '1') then
				HexDisplayVal <= CPU_Data_in;
	--		else
	--			HexDisplayVal <= CPU_Data_Out;			
	--		end if;
		end if;	
	end process;
	
	-- CS generation
	process(CPU_AS)
	begin
		-- Only process if CPU address is valid
		if(CPU_AS = '0') then
			-- Release CS of all other devices.
			CPU_RAM_CS <= '1';
				
			-- 68k RAM access
			if(CPU_Addr(23 downto 16) = "11111111") then
				CPU_RAM_CS <= '0';
			end if;
		end if;
	end process;
	
	process(CPU_VDP_DTACK, CPU_RAM_DTACK, CPU_CLK)
	begin	
		-- Only process if CPU address is valid
		if(CPU_AS = '0') then
			-- 68k RAM access
			if(CPU_Addr(23 downto 16) = "11111111") then
				CPU_DTACK <= CPU_RAM_DTACK;
			-- VDP
			elsif(CPU_Addr(23 downto 16) = "11000000") then
				CPU_DTACK <= CPU_VDP_DTACK;
			elsif(CPU_Addr(23 downto 16) < "00000100") then
				CPU_DTACK <= '0';
				CPU_Data_In <= ROM_Data;
			end if;	
		end if;
	end process;
	
end Behavioral;
