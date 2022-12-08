
library ieee;
use ieee.std_logic_1164.all;
use work.pipe_fetch;
use work.pipe_decoder;
use work.pipe_execute;
use ieee.numeric_std.all;

entity procTest is
generic(	periodC	: time		:= 10 ns;
		cyclesC	: integer	:= 100);
end entity procTest;

architecture procTestbench of procTest is

  signal clk, rst, req	: std_logic;
  signal pc : unsigned(31 downto 0);
  
  
begin
  pipe_fetch_inst : entity work.pipe_fetch
      port map(
          clk             => clk,
          reset           => rst,
          pc              => pc,
          reg_instruction => reg_instruction,
          f_out_pc          => reg_pc,
          f_out_pc4        => reg_pc_4
      ) ;
  

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
