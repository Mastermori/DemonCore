-- delayLine.vhd				AJM : 25.11.2002
--
-- entity	delayLine	-parametrisable delay line
-- architecture	behavior
--		structure
-- config	dlBehavior
--		dlStructure
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity delayLine is
generic(bitWid	: integer range 2 to 64 := 16;
	delLen	: integer range 2 to 16 := 16);
port (	clk	: in  std_logic;
	dataIn	: in  signed(bitWid-1 downto 0);
	dataOut	: out signed(bitWid-1 downto 0));
end entity delayLine;

------------------------------------------------------------------------------
architecture behavior of delayLine is
  type	  delArray_T is array (1 to delLen) of signed(bitWid-1 downto 0);
  signal  delArray   : delArray_T;
begin
  dataOut <= delArray(delLen);
  reg_P: process (clk) is
  begin
    if rising_edge(clk) then delArray <= dataIn & delArray(1 to delLen-1);
    end if;
  end process reg_P;
end architecture behavior;

------------------------------------------------------------------------------
architecture structure of delayLine is
  component reg is
  generic( width	: integer range 2 to 64);
  port	 ( clk		: in std_logic;
	   dIn		: in  signed(width-1 downto 0);
	   dOut		: out signed(width-1 downto 0));
  end component reg;
  type	  delReg_T is array (0 to delLen) of signed(bitWid-1 downto 0);
  signal  delReg   : delReg_T;
begin
  delReg(0) <= dataIn;
  dataOut <= delReg(delLen);
  gen_I: for i in 1 to delLen generate
    reg_I: reg generic map (width => bitWid)
		port map (clk, delReg(i-1), delReg(i));
  end generate gen_I;
end architecture structure;

------------------------------------------------------------------------------
configuration dlBehavior of delayLine is
for behavior
end for;
end configuration dlBehavior;

------------------------------------------------------------------------------
configuration dlStructure of delayLine is
for structure
  for gen_I
    for all: reg use entity work.reg(behavior);
    end for;
  end for;
end for;
end configuration dlStructure;
