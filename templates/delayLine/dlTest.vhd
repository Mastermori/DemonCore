-- dlTest.vhd
--
-- entity	dlTest		-testbench for: delayLine
-- architecture	testbench
-- config	dlBehavTest
--		dlStrucTest
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dlTest is
generic(	bitWid	: integer range 2 to 64 := 16;
		delLen	: integer range 2 to 16 := 16;
		periodC	: time		:= 10 ns;
		cyclesC	: integer	:= 30);
end entity dlTest;

architecture testbench of dlTest is

  component delayLine is
  generic(	bitWid	: integer range 2 to 64 := 16;
		delLen	: integer range 2 to 16 := 16);
  port (	clk	: in  std_logic;
		dataIn	: in  signed(bitWid-1 downto 0);
		dataOut	: out signed(bitWid-1 downto 0));
  end component delayLine;

  signal clk		: std_logic;
  signal dataIn		: signed(bitWid-1 downto 0);
  signal dataOut	: signed(bitWid-1 downto 0);
begin
  dlI: delayLine	generic map (bitWid, delLen)
			port map (clk, dataIn, dataOut);

  stiP: process is
  begin
    for i in 0 to cyclesC-1 loop
	dataIn <= to_signed(i, dataIn'length);
	wait for periodC;
    end loop;
    wait;
  end process stiP;

  clkP: process is
  begin
    clk <= '0', '1' after periodC/2;
    wait for periodC;
  end process clkP;

end architecture testbench;

----------------------------------------------------------------------------
configuration dlBehavTest of dlTest is
for testbench
--for dlI: delayLine use entity work.delayLine(behavior);
  for dlI: delayLine use configuration work.dlBehavior;
  end for;
end for;
end configuration dlBehavTest;

----------------------------------------------------------------------------
configuration dlStrucTest of dlTest is
for testbench
--for dlI: delayLine use entity work.delayLine(structure);
  for dlI: delayLine use configuration work.dlStructure;
  end for;
end for;
end configuration dlStrucTest;

