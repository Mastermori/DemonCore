LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_fetch IS
    PORT(
        clk               : IN  STD_LOGIC;
        reset             : IN  STD_LOGIC;
        pc                : IN  unsigned(31 DOWNTO 0);
        f_out_instruction : OUT instruction32;
        f_out_pc          : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_fetch_dummy OF pipe_fetch IS
    TYPE instruction_memory IS ARRAY (0 to 4095) OF instruction32; -- 2^12-1 as pc is 32 bit but fuck that
    SIGNAL rom : instruction_memory;
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            rom               <= (
                0      => ADDI_ONE_INSTRUCTION,
                1      => JAL_INSTRUCTION,
                others => NOP_INSTRUCTION
            );
            f_out_instruction <= NOP_INSTRUCTION;
            f_out_pc          <= (others => '0');
        ELSIF (rising_edge(clk)) THEN
            f_out_instruction <= rom(to_integer(pc(31 downto 2)));
            f_out_pc          <= pc;
        ELSE
            null;
        END IF;
    END PROCESS;
END pipe_fetch_dummy;                   -- pipe_fetch_dummy