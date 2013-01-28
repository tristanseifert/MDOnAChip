library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity VDP is
	port (
		VDP_MainClk:		in STD_LOGIC;
		VDP_50MHzClk:		in STD_LOGIC;
		VDP_PixelClk:		in STD_LOGIC;

		-- VGA interface
		ColourOut_R:		out STD_LOGIC_VECTOR(3 downto 0);
		ColourOut_G:		out STD_LOGIC_VECTOR(3 downto 0);
		ColourOut_B:		out STD_LOGIC_VECTOR(3 downto 0);
		
		ColourOut_HSync: 	inout STD_LOGIC;
		ColourOut_VSync: 	inout STD_LOGIC;
		
		-- CPU interface
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
		Mem_DTACK:			out STD_LOGIC
	);
end VDP;

architecture Behavioral of VDP is	
	signal CRAM_DIn:		STD_LOGIC_VECTOR(8 downto 0);
	signal CRAM_AIn:		STD_LOGIC_VECTOR(8 downto 0);
	signal CRAM_WE:		STD_LOGIC;
	signal CRAM_DOut:		STD_LOGIC_VECTOR(8 downto 0);
	signal CRAM_AOut:		STD_LOGIC_VECTOR(8 downto 0);
	
	signal VSCRAM_DIn:	STD_LOGIC_VECTOR(31 downto 0);
	signal VSCRAM_AIn:	STD_LOGIC_VECTOR(4 downto 0);
	signal VSCRAM_WE:		STD_LOGIC;
	signal VSCRAM_DOut:	STD_LOGIC_VECTOR(31 downto 0);
	signal VSCRAM_AOut:	STD_LOGIC_VECTOR(4 downto 0);
	
	signal FIFO_DIn: 		STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal FIFO_RdReq: 	STD_LOGIC;
	signal FIFO_WrReq: 	STD_LOGIC;
	signal FIFO_DOut: 	STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal FIFO_Empty: 	STD_LOGIC;
	signal FIFO_Full: 	STD_LOGIC;

	signal VInt_Pend:		STD_LOGIC;
	signal HInt_Pend:		STD_LOGIC;
	
	signal CmdWrd: 		STD_LOGIC_VECTOR(31 downto 0);
	signal CmdWrdDone:	STD_LOGIC := '1';
	
	signal StatusReg: 	STD_LOGIC_VECTOR(15 downto 0);
	
-------------------------------------------------------------------------------
-- Scanline doubling
-------------------------------------------------------------------------------

	signal ScanBuf_In: 		STD_LOGIC_VECTOR (15 DOWNTO 0);
	signal ScanBuf_RAddr: 	STD_LOGIC_VECTOR (8 DOWNTO 0);
	signal ScanBuf_WAddr: 	STD_LOGIC_VECTOR (8 DOWNTO 0);
	signal ScanBuf_WEN:		STD_LOGIC  := '0';
	signal ScanBuf_Out: 		STD_LOGIC_VECTOR (15 DOWNTO 0);
	
-------------------------------------------------------------------------------
-- Video counting
-------------------------------------------------------------------------------
	signal VGA_pixelCount:STD_LOGIC_VECTOR(9 downto 0);
	signal VGA_lineCount:STD_LOGIC_VECTOR(8 downto 0);
	signal pixelCount:	STD_LOGIC_VECTOR(8 downto 0);
	signal lineCount:		STD_LOGIC_VECTOR(7 downto 0);
	signal frameNumber: 	STD_LOGIC;
	
	signal HIntCounter:	STD_LOGIC_VECTOR(7 downto 0); -- HInt counter, subtracted every line, int when 0
	
	signal HVCounter:		STD_LOGIC_VECTOR(15 downto 0);
	
-------------------------------------------------------------------------------
-- Sprite engine
-------------------------------------------------------------------------------
	signal Sprite_SO:		STD_LOGIC; -- set when there's too many sprites on-screen
	signal Sprite_SC:		STD_LOGIC; -- set when 2 sprites collide
	
-------------------------------------------------------------------------------
-- DMA engine
-------------------------------------------------------------------------------
	signal In_DMA: 		STD_LOGIC;
	signal DMA_FILL:		STD_LOGIC; -- Set to 1 during VRAM fill DMA
	signal DMA_COPY:		STD_LOGIC; -- Set to 1 during VRAM copy DMA
	signal DMA_68K:		STD_LOGIC; -- Set to 1 during VRAM <-> 68k DMA
-------------------------------------------------------------------------------
-- Registers
-------------------------------------------------------------------------------
	type reg_t is array(0 to 31) of std_logic_vector(7 downto 0);
	signal registers:		reg_t;
	
	signal HInt_En:		STD_LOGIC;
	signal VInt_En:		STD_LOGIC;
	signal HV_Latch:		STD_LOGIC;
	signal DispEn:			STD_LOGIC;
	signal DMAEn:			STD_LOGIC;
	signal V30:				STD_LOGIC;
	
	-- base addresses
	signal NTAB:			STD_LOGIC_VECTOR(2 downto 0); -- Plane A (* $400)
	signal NTBB:			STD_LOGIC_VECTOR(2 downto 0); -- Plane B (* $2000)
	signal NAWB:			STD_LOGIC_VECTOR(2 downto 0); -- Window plane (* $400)
	signal HSCB:			STD_LOGIC_VECTOR(5 downto 0); -- HScroll (* $400)
	signal SATB:			STD_LOGIC_VECTOR(6 downto 0); -- Sprite attribute table (* $200)
	
	signal BGColour:		STD_LOGIC_VECTOR(5 downto 0);
	
	signal HIntValue:		STD_LOGIC_VECTOR(7 downto 0); -- Value for HInt counter.
	
	signal VScroll:		STD_LOGIC; -- Controls VScroll screen/16px	
	signal HScroll:		STD_LOGIC_VECTOR(1 downto 0); -- Controls HScroll screen/invalid/8px/1px
	
	signal H40:				STD_LOGIC;
	signal SHI:				STD_LOGIC; -- Shadow/highlight
	signal LSM:				STD_LOGIC_VECTOR(1 downto 0); -- Interlace mode
	
	signal AutoInc:		STD_LOGIC_VECTOR(7 downto 0);
	
	signal HSize:			STD_LOGIC_VECTOR(1 downto 0); -- Horizontal plane size
	signal VSize:			STD_LOGIC_VECTOR(1 downto 0); -- Vertical plane size
	
	signal WINH:			STD_LOGIC_VECTOR(4 downto 0);
	signal WINHD:			STD_LOGIC;
	signal WINV:			STD_LOGIC_VECTOR(4 downto 0);
	signal WINVD:			STD_LOGIC;
-------------------------------------------------------------------------------
-- Memories and external components
-------------------------------------------------------------------------------
	component VDP_CRAM
		port (
			data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdaddress: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdclock	: IN STD_LOGIC ;
			wraddress: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			wrclock	: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	end component VDP_CRAM;
	
	component VDP_VSCRAM
		port (
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdaddress: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			rdclock	: IN STD_LOGIC ;
			wraddress: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			wrclock	: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	end component VDP_VSCRAM;
	
	component VDP_WriteFIFO
		port(
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			wrempty	: OUT STD_LOGIC ;
			wrfull	: OUT STD_LOGIC 
		);
	end component VDP_WriteFIFO;
	
	component VDP_ScanlineBuffer
		port (
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdaddress: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdclock	: IN STD_LOGIC ;
			wraddress: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			wrclock	: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	end component VDP_ScanlineBuffer;
	
begin
-------------------------------------------------------------------------------
-- Registers
-------------------------------------------------------------------------------
	HInt_En <= registers(0)(4);
	HV_Latch <= registers(0)(1);
	DispEn <= registers(1)(6);
	VInt_En <= registers(1)(5);
	DMAEn <= registers(1)(4);
	V30 <= registers(1)(3);
	NTAB <= registers(2)(5 downto 3);
	NAWB <= registers(3)(2 downto 0);
	NTBB <= registers(4)(2 downto 0);
	SATB <= registers(5)(6 downto 0);
	HSCB <= registers(13)(5 downto 0);
	BGColour <= registers(7)(5 downto 0);
	HIntValue <= registers(10);
	VScroll <= registers(11)(2);
	HScroll <= registers(11)(1 downto 0);
	H40 <= registers(12)(0);
	SHI <= registers(12)(3);
	LSM <= registers(12)(2 downto 1);
	AutoInc <= registers(15);
	HSize <= registers(16)(1 downto 0);
	VSize <= registers(16)(5 downto 4);
	WINH <= registers(17)(4 downto 0);
	WINHD <= registers(17)(7);
	WINV <= registers(18)(4 downto 0);
	WINVD <= registers(18)(7);
	
	In_DMA <= DMA_FILL OR DMA_COPY OR DMA_68K;

	StatusReg <= "001101" & FIFO_Empty & FIFO_Full & VInt_Pend & Sprite_SO & Sprite_SC & frameNumber & ColourOut_VSync & ColourOut_HSync & In_DMA & V30;
	
	pixelCount <= VGA_pixelCount(9 downto 1);
	lineCount <= VGA_lineCount(8 downto 1);
	
-------------------------------------------------------------------------------
-- Component instantiations
-------------------------------------------------------------------------------
	
	CRAM: VDP_CRAM port map(data => CRAM_DIn, wraddress => CRAM_AIn, q => CRAM_DOut, rdaddress => CRAM_AOut,
									wren => CRAM_WE, wrclock => CPUBus_Clk, rdclock => VDP_MainClk);
	
	VSCRAM: VDP_VSCRAM port map(data => VSCRAM_DIn, wraddress => VSCRAM_AIn, q => VSCRAM_DOut, rdaddress => VSCRAM_AOut,
										 wren => VSCRAM_WE, wrclock => CPUBus_Clk, rdclock => VDP_MainClk);
	
	WriteFIFO: VDP_WriteFIFO port map(data => FIFO_DIn, q => FIFO_DOut, rdreq => FIFO_RdReq, wrreq => FIFO_WrReq,
												 rdclk => VDP_MainClk, wrclk => CPUBus_Clk,
												 wrempty => FIFO_Empty, wrfull => FIFO_Full);
	
	ScanBuf: VDP_ScanlineBuffer port map(data => ScanBuf_In, q => ScanBuf_Out,
													 wraddress => ScanBuf_WAddr, rdAddress => ScanBuf_RAddr,
													 wren => ScanBuf_WEN, 
													 rdClock => VDP_PixelClk, wrClock => VDP_50MHzClk);
	
	-- Once the address is valid, do fun decode-y shenanigans
	process(CPU_AS)
	begin
		-- First of all, check if it's even a write to VDP address space
		if(CPU_Addr(23 downto 16) = "11000000") then
			-- Control port access
			if(CPU_Addr(4 downto 2) = "001") then
				if(CPU_RW = '0') then
				
				-- Reading control register -> status reg
				else
					CPU_DataOut <= StatusReg;
				end if;
			-- Data port access
			elsif(CPU_Addr(4 downto 2) = "000") then				
				if(CPU_Addr(1) = '1') then
					-- Write low word of command word, signal it's done.
					CmdWrd(15 downto 0) <= CPU_DataIn;
					CmdWrdDone <= '0';
				else
					-- Write high word of command word
					CmdWrd(31 downto 16) <= CPU_DataIn;		
					CmdWrdDone <= '1';		
				end if;
			-- H/V counter access
			elsif(CPU_Addr(3) = '1') then
				-- Only do something on a read.
				if(CPU_RW = '1') then
					CPU_DataOut <= HVCounter;
				end if;
			-- PSG access
			elsif(CPU_Addr(4) = '1' AND CPU_Addr(2) = '0') then
			
			-- Debug register access
			elsif(CPU_Addr(4 downto 2) = "111") then
			
			end if;
			
			-- Generate /DTAK for CPU.
			CPU_DTACK <= '0';
		end if;
	end process;
	
	-- Actual video generation! Wow!
	process(VDP_50MHzClk)
	begin
		if(falling_edge(VDP_50MHzClk)) then
			scanBuf_WAddr <= pixelCount;
			--scanBuf_In <= pixelCount(7 downto 4) & "0" & lineCount(7 downto 4) & "00" & "00000";
			scanBuf_In <= "00000" & lineCount(3 downto 0) & "00" & "00000";
			scanBuf_WEN <= '1';
		end if;
	end process;
	
	-- Sync generation and shit.
	process(VDP_PixelClk)
	begin
		if falling_edge(VDP_PixelClk) then
		
			-- active display
			if((VGA_pixelCount < 640) AND (VGA_lineCount < 480)) then
				scanBuf_RAddr <= pixelCount;
				colourOut_R <= ScanBuf_Out(15 downto 12);
				colourOut_G <= ScanBuf_Out(10 downto 7);
				colourOut_B <= ScanBuf_Out(4 downto 1);
			end if;
			
			VGA_pixelCount <= VGA_pixelCount + '1';
			
			-- start of front porch
			if(VGA_pixelCount = 640) then
				ColourOut_R <= "0000";
				colourOut_G <= "0000";
				ColourOut_B <= "0000";

				-- Decrement HInt counter
				hintCounter <= hintCounter - 1;
				
				-- If it's 0, 
				if(hintCounter = 0) then
					HInt_Pend <= '1';
				end if;
			-- start of sync pulse
			elsif(VGA_pixelCount = 656) then
				ColourOut_HSync <= '0';
				
				if(hintCounter = 0) then
					hintCounter <= hintValue;
					HInt_Pend <= '0';
				end if;
			-- start of back porch
			elsif(VGA_pixelCount = 752) then
				ColourOut_HSync <= '1';		
			-- end of back porch
			elsif(VGA_pixelCount = 800) then
				VGA_pixelCount <= "0000000000";
				VGA_lineCount <= VGA_lineCount + '1';
			end if;
		
			-- start of front porch
			if(VGA_lineCount = 480) then
				VInt_Pend <= '1';
			-- start of sync pulse
			elsif(VGA_lineCount = 490) then
				ColourOut_VSync <= '0';
				VInt_Pend <= '0';
				ColourOut_R <= "0000";
				colourOut_G <= "0000";
				ColourOut_B <= "0000";
			-- start of back porch
			elsif(VGA_lineCount = 492) then
				ColourOut_VSync <= '1';
			-- end of back porch
			elsif(VGA_lineCount = 525) then
				frameNumber <= not frameNumber;
				VGA_lineCount <= "0000000000";
			end if;
			
		end if;
	end process;
	
	-- CPU interrupt interface
	process(VInt_Pend, HInt_Pend)
	begin
		-- Process pending vertical interrupt
		if(VInt_Pend = '1' AND VInt_En = '1') then
			CPU_IPL <= "011";
		-- Process pending horizontal interrupt
		elsif(HInt_Pend = '1' AND HInt_En = '1') then
			CPU_IPL <= "101";		
		else
			-- No interrupts are pending.
			CPU_IPL <= "111";
		end if;
	end process;
	
end Behavioral;
