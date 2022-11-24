LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE pipe_constants.NOP_INSTRUCTION;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_fetch IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        pc : IN unsigned(31 DOWNTO 0);
        reg_instruction : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        reg_pc : OUT unsigned(31 DOWNTO 0);
        reg_pc_4 : OUT unsigned(31 DOWNTO 0);
    );
END;

ARCHITECTURE pipe_fetch_dummy OF pipe_fetch IS
    TYPE instruction_memory IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rom : instruction_memory := (NOP_INSTRUCTION);
    SIGNAL instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_instruction <= NOP_INSTRUCTION;
            instruction <= NOP_INSTRUCTION;
            reg_pc <= x"0000_0000";
            reg_pc_4 <= x"0000_0000";
        ELSIF (rising_edge(clk)) THEN
            reg_instruction <= instruction;
            instruction <= rom(pc);
            reg_pc <= pc;
            reg_pc_4 <= pc + 4;
        END IF;
    END PROCESS;
END pipe_fetch_dummy; -- pipe_fetch_dummy