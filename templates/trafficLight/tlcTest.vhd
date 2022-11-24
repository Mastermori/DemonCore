-- tlcTest.vhd
--
-- entity	tlcTest		-testbench for: tlcWalk
-- architecture	testbench
-- config	tlcConf
--		tlcConf1
--		tlcConfSyn
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity tlcTest is
generic(	periodC	: time		:= 10 ns;
		cyclesC	: integer	:= 100);
end entity tlcTest;

architecture testbench of tlcTest is

  component tlcWalk is
--  generic (	maxWalkC	: integer range 10 to 2000	:= 1000; 
--		maxCarC		: integer range 10 to 2000	:=  800); 
  port    (	clk, rst	: in  std_logic;
		reqWalk		: in  std_logic;
		lightCar	: out std_logic_vector(1 to 3);
		lightWalk	: out std_logic_vector(1 to 2));
  end component tlcWalk;

  signal clk, rst, req	: std_logic;
  signal liCar		: std_logic_vector(1 to 3);
  signal liWalk		: std_logic_vector(1 to 2);
begin
  tlcI: tlcWalk	port map (clk, rst, req, liCar, liWalk);

  stiP: process is
    variable	sti	: std_logic_vector(31 downto 1)	:= (others => '0');
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

----------------------------------------------------------------------------
--configuration tlcConf of tlcTest is
--for testbench
--  for tlcI: tlcWalk use entity work.tlcWalk(behave);
--  end for;
--end for;
--end configuration tlcConf;

----------------------------------------------------------------------------
--configuration tlcConf1 of tlcTest is
--for testbench
--  for tlcI: tlcWalk use entity work.tlcWalk(behave1);
--  end for;
--end for;
--end configuration tlcConf1;

----------------------------------------------------------------------------
--configuration tlcConfSyn of tlcTest is
--for testbench
--  for tlcI: tlcWalk use entity work.tlcWalk(module);		--Verilog
--  for tlcI: tlcWalk use entity work.tlcWalk(SYN_behave);	--VHDL
--  end for;
--end for;
--end configuration tlcConfSyn;
