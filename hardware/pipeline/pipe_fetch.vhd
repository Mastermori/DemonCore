LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_fetch IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        pc : IN unsigned(31 DOWNTO 0);
        f_out_rom_addr : OUT std_logic_vector(7 downto 0);
        f_in_rom_data : IN instruction32;
        f_out_instruction : OUT instruction32;
        f_out_pc : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_fetch_dummy OF pipe_fetch IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            f_out_instruction <= NOP_INSTRUCTION;
            f_out_rom_addr <= (others => '0');
            f_out_pc <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            f_out_rom_addr <= std_logic_vector(pc(9 downto 2)); -- TODO: Find out how to do proper this properly (+4 bit adresses)
            f_out_instruction <= f_in_rom_data;
            f_out_pc <= pc;
        END IF;
    END PROCESS;
END pipe_fetch_dummy; -- pipe_fetch_dummy