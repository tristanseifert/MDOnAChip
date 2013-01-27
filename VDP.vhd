library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity VDP is
	port (
		VDP_MainClk:		in STD_LOGIC;
		VDP_PixelClk:		in STD_LOGIC;
		
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
	signal pixelCount: 	STD_LOGIC_VECTOR(9 downto 0);
	signal lineCount: 	STD_LOGIC_VECTOR(9 downto 0);
	
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

	component VDP_CRAM
		port (
			data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdaddress		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	end component VDP_CRAM;
	
	component VDP_VSCRAM
		port (
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdaddress		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	end component VDP_VSCRAM;
	
	component VDP_WriteFIFO
		port(
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			wrempty		: OUT STD_LOGIC ;
			wrfull		: OUT STD_LOGIC 
		);
	end component VDP_WriteFIFO;
	
begin
	CRAM: VDP_CRAM port map(data => CRAM_DIn, wraddress => CRAM_AIn, q => CRAM_DOut, rdaddress => CRAM_AOut,
									wren => CRAM_WE, wrclock => CPUBus_Clk, rdclock => VDP_MainClk);
	
	VSCRAM: VDP_VSCRAM port map(data => VSCRAM_DIn, wraddress => VSCRAM_AIn, q => VSCRAM_DOut, rdaddress => VSCRAM_AOut,
										 wren => VSCRAM_WE, wrclock => CPUBus_Clk, rdclock => VDP_MainClk);
	
	WriteFIFO: VDP_WriteFIFO port map(data => FIFO_DIn, q => FIFO_DOut, rdreq => FIFO_RdReq, wrreq => FIFO_WrReq,
												 rdclk => VDP_MainClk, wrclk => CPUBus_Clk,
												 wrempty => FIFO_Empty, wrfull => FIFO_Full);
	
	-- Once the address is valid, do fun decode-y shenanigans
	process(CPU_AS)
	begin
		if(CPU_Addr(23 downto 16) = "11000000") then
		
		end if;
	end process;
	
end Behavioral;
