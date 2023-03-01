-- de0Test.vhd
--
-- entity	de0Test		-testbench for: de0Board
-- architecture	testbench
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity de0Test is
generic(	periodC	: time		:= 20 ns);
end entity de0Test;

architecture testbench of de0Test is

-- quartus vhdl netlist writer: BUFFER instead of OUT!	------------------------
-- workaround:	1. change component declaration
--		2. edit: sim/xcelium/de0Board...vho
  component de0Board is	-- noIO version			------------------------
  port(	clk50		: in	std_logic;		-- 50 MHz external clock
	key		: in	std_logic_vector( 1 downto 0);	-- act. L
	led		: buffer std_logic_vector( 7 downto 0); -- act. H
	dramCsN		: buffer std_logic;		-- L: chip select
	epcsCsN		: buffer std_logic;		-- L: chip sel.	CS#
	gSensorCs	: buffer std_logic;		-- H: chip sel. I2C-mode
	adcCsN		: buffer std_logic);		-- L: chip select
  end component de0Board;

--component de0Board is	-- cDisp version		------------------------
--port(	clk50		: in	std_logic;		-- 50 MHz external clock
--	key		: in	std_logic_vector( 1 downto 0);	-- act. L
--	led		: buffer std_logic_vector( 7 downto 0);	-- act. H
--	dramCsN		: buffer std_logic;		-- L: chip select
--	epcsCsN		: buffer std_logic;		-- L: chip sel.	CS#
--	gSensorCs	: buffer std_logic;		-- H: chip sel. I2C-mode
--	adcCsN		: buffer std_logic);		-- L: chip select
--	butWh		: in	std_logic_vector(1 to 8); -- [H]  gpio1(24..31)
--	butBk		: in	std_logic_vector(1 to 2); -- [L]  gpio1(16..17)
--	butRd		: in	std_logic_vector(1 to 2); -- [L]  gpio1(19..20)
--	s_ceN		: buffer std_logic;	-- SPI client ena.	[L]
--						-- 3-SCE	= gpio1(0)
--	s_rstN		: buffer std_logic;	-- SPI reset		[L]
--						-- 4-RST	= gpio1(1)
--	s_dNc		: buffer std_logic;	-- SPI data [1]/ctrl [0]
--						-- 5-D/C	= gpio1(2)
--	s_din		: buffer std_logic;	-- SPI data in
--						-- 6-DN(MOSI)	= gpio1(3)
--	s_clk		: buffer std_logic;	-- SPI clock
--						-- 7-SCLK	= gpio1(4)
--	bgLed		: buffer std_logic);	-- background LED
--						-- 8-LED	= gpio1(5)
--end component de0Board;

  signal clk50		: std_logic;
  signal key		: std_logic_vector( 1 downto 0);
  signal led		: std_logic_vector( 7 downto 0);
  signal dramCsN	: std_logic;		-- L: chip select
  signal epcsCsN	: std_logic;		-- L: chip sel.	CS#
  signal gSensorCs	: std_logic;		-- H: chip sel. I2C-mode
  signal adcCsN		: std_logic;		-- L: chip select
begin
  de0I: de0Board	port map (clk50, key, led,
			dramCsN, epcsCsN, gSensorCs, adcCsN);

  -- 50 MHz clock
  ------------------------------------------------------------------------------
  clkP: process is
  begin
	clk50 <= '0', '1' after periodC/2;
	wait for periodC;
  end process clkP;

  -- reset at simulation start: key(0) resets pipeProc (low active)
  ------------------------------------------------------------------------------
  keyP: process is
  begin
	key <= "10", "11" after 5*periodC/4;
	wait;
  end process keyP;
end architecture testbench;
