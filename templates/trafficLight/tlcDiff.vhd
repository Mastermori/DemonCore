-- tlcDiff.vhd
--
-- entity	tlcDiff		-testbench: tlcWalk(behave) vs. tlcWalk(behave1)
-- architecture	testbench
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity tlcDiff is
generic(	periodC	: time		:= 10 ns;
		cyclesC	: integer	:= 20000);
end entity tlcDiff;

architecture testbench of tlcDiff is

  component tlcWalk is
  generic (	maxWalkC	: integer range 10 to 2000	:= 1000; 
		maxCarC		: integer range 10 to 2000	:=  800); 
  port    (	clk, rst	: in  std_logic;
		reqWalk		: in  std_logic;
		lightCar	: out std_logic_vector(1 to 3);
		lightWalk	: out std_logic_vector(1 to 2));
  end component tlcWalk;

  signal clk, rst, req	: std_logic;
  signal liCar1, liCar2		: std_logic_vector(1 to 3);
  signal liWalk1, liWalk2	: std_logic_vector(1 to 2);
begin
  tlc1I: tlcWalk	port map (clk, rst, req, liCar1, liWalk1);
  tlc2I: tlcWalk	port map (clk, rst, req, liCar2, liWalk2);

  stiP: process is
    variable	sti	: std_logic_vector(31 downto 1)	:= (others => '0');
    variable	liC1	: std_logic_vector(1 to 3) := "001";
    variable	liW1	: std_logic_vector(1 to 2) := "10";
  begin
    clk <= '0';
    rst <= '0';
    req <= '0';
    wait for periodC/2;
    clk <= '1';
    wait for periodC/2;
    rst <= '1';
    for i in 1 to cyclesC loop
	sti := sti(30 downto 1) & (sti(31) xnor sti(28));
	req <= sti(1);
      for j in 1 to 1000 loop
	clk <= '0';
	wait for periodC/2;
	clk <= '1';
	wait for periodC/2;
	assert (liC1 = liCar2 and liW1 = liWalk2)
		report "simulation mismatch"
		severity error;
	liC1 := liCar1;
	liW1 := liWalk1;
      end loop;
    end loop;
    wait;
  end process stiP;

--  clkP: process is
--  begin
--    clk <= '0';
--    wait for periodC/2;
--    clk <= '1';
--    wait for periodC/2;
--  end process clkP;

--  rstP: process is
--  begin
--    rst <= '0';
--    wait for periodC;
--    rst <= '1';
--    wait for periodC;
--    wait on rst;
--  end process rstP;

end architecture testbench;

configuration tlcDiffC of tlcDiff is
for testbench
  for tlc1I: tlcWalk use entity work.tlcWalk(behave);
  end for;
  for tlc2I: tlcWalk use entity work.tlcWalk(behave1);
  end for;
end for;
end configuration tlcDiffC;

