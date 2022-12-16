LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.pipe_execute;
USE work.pipe_decoder;
use std.textio.all;

ENTITY pipeTest IS
    GENERIC(
        periodC : TIME    := 10 ns;
        cyclesC : INTEGER := 10);
END ENTITY pipeTest;

ARCHITECTURE testbenchPipe OF pipeTest IS
    SIGNAL clk, rst : STD_LOGIC;
BEGIN
    pipeline_inst : ENTITY work.pipeline
        PORT MAP(
            clk   => clk,
            reset => rst
        );

    stiP : PROCESS IS
    BEGIN
        clk <= '0';
        rst <= '0';
        WAIT FOR periodC / 2;
        clk <= '1';
        WAIT FOR periodC / 2;
        rst <= '1';
        FOR i IN 0 TO cyclesC LOOP
            FOR j IN 1 TO 5 LOOP
                clk <= '0';
                WAIT FOR periodC / 2;
                clk <= '1';
                WAIT FOR periodC / 2;
                --write(l, j);
                --writeline(output, l);
            END LOOP;
        END LOOP;
        WAIT;
    END PROCESS stiP;

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

END ARCHITECTURE testbenchPipe;

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