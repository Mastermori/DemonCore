-- procTest.vhd
--
-- entity	procTest		-testbench for pipeline processor
-- architecture	testbench		-
--
-- to do:	- replace pipeProc with new top-level design
--		- add component declaration or provide 'procPkg.vhd' with it
--		- write: 'instMem.dat' + 'dataMem.dat'
------------------------------------------------------------------------------
library ieee;						-- packages:
use ieee.std_logic_1164.all;				--   std_logic
use ieee.numeric_std.all;				--   (un)signed
use work.memPkg.all;					--   ramIO / rom
--use work.procPkg.all;					--   pipeProc

-- entity	--------------------------------------------------------------
------------------------------------------------------------------------------
entity procTest is
generic(clkPeriod	: time		:= 20 ns;	-- clock period
	clkCycles	: positive	:= 100);	-- clock cycles
end entity procTest;


-- architecture	--------------------------------------------------------------
------------------------------------------------------------------------------
architecture testbench of procTest is
  signal clk, nRst	: std_logic;
  signal const1		: std_logic;
  signal dnWE		: std_logic;
  signal iAddr,  dAddr	: std_logic_vector( 9 downto 0);  -- 10-bit address!!!
  signal iDataI, dDataI	: std_logic_vector(31 downto 0);  -- mem  => proc
  signal dummy,  dDataO	: std_logic_vector(31 downto 0);  -- proc => mem
  signal iCtrl,  dCtrl	: fileIoT;

begin
-- sample usage: ramIO instaed of rom	--------------------------------------
--const1 <= '1';
--dummy  <= (others => '-');
--
--instMemI: ramIO	generic map (	addrWd	=> 10,
--					dataWd	=> 32,
--					fileId	=> "instMem.dat")
--			port map    (	nWE	=> const1,	-- read-only
--					addr	=> iAddr,
--					dataI	=> dummy,
--					dataO	=> iDataI,
--					fileIO	=> iCtrl);

  -- memories		------------------------------------------------------
  instMemI: rom		generic map (	addrWd	=> 10,
					dataWd	=> 32,
					fileId	=> "instMem.dat")
			port map    (	addr	=> iAddr,
					data	=> iDataI,
					fileIO	=> iCtrl);
  dataMemI: ramIO	generic map (	addrWd	=> 10,
					dataWd	=> 32,
					fileId	=> "dataMem.dat")
			port map    (	nWE	=> dnWE,
					addr	=> dAddr,
					dataI	=> dDataO,
					dataO	=> dDataI,
					fileIO	=> dCtrl);

  -- pipe processor	------------------------------------------------------
  pipeProcI: pipeProc	port map    (	clk	=> clk,
					nRst	=> nRst,
					iAddr	=> iAddr,
					iData	=> iData,
					dnWE	=> dnWE,
					dAddr	=> dAddr,
					dDataI	=> dDataI,
					dDataO	=> dDataO);

  -- stimuli		------------------------------------------------------
  stiP: process is
  begin
    clk		<= '0';
    nRst	<= '0',   '1'  after 5 ns;
    iCtrl	<= load,  none after 5 ns;
    dCtrl	<= load,  none after 5 ns;
    wait for clkPeriod/2;
    for n in 1 to clkCycles loop
	clk <= '0', '1' after clkPeriod/2;
	wait for clkPeriod;
    end loop;
    wait;
  end process stiP;

end architecture testbench;
------------------------------------------------------------------------------
-- procTest.vhd	- end
