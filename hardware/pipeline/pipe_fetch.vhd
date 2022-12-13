LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_fetch IS
    PORT(
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        pc              : IN  unsigned(31 DOWNTO 0);
        reg_instruction : OUT instruction32;
        f_out_pc        : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_fetch_dummy OF pipe_fetch IS
    TYPE instruction_memory IS ARRAY (0 to 1000) OF instruction32;
    SIGNAL rom         : instruction_memory;
    SIGNAL instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            rom             <= (
                0      => b"0000000_00001_00000_000_00000_0110011", 1 => b"0100000_00010_00000_000_00000_0110011",
                2      => b"0000000_00010_00000_001_00000_0110011", 3 => b"0000000_00001_00000_010_00000_0110011",
                4      => b"0000000_00001_00000_011_00000_0110011", 5 => b"0000000_00001_00000_100_00000_0110011",
                6      => b"0100000_00001_00000_101_00000_0110011", 7 => b"0000000_00001_00000_110_00000_0110011",
                8      => b"0000000_00001_00000_111_00000_0110011", others => NOP_INSTRUCTION
            );
            reg_instruction <= NOP_INSTRUCTION;
            instruction     <= NOP_INSTRUCTION;
            f_out_pc        <= (others => '0');
        ELSIF (rising_edge(clk)) THEN
            reg_instruction <= instruction;
            instruction     <= rom(to_integer(pc(31 downto 2)));
            f_out_pc        <= pc;
        ELSE
            null;
        END IF;
    END PROCESS;
END pipe_fetch_dummy;                   -- pipe_fetch_dummy