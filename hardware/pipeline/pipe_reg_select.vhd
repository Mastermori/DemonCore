LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_register_select IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        pc : IN unsigned(31 DOWNTO 0);
        pc_4 : IN unsigned(31 DOWNTO 0);
        reg_addr_1, reg_addr_2 : IN register_adress;

        reg_data_1, reg_data_2 : OUT word;
        reg_pc : OUT unsigned(31 DOWNTO 0);
        reg_pc_4 : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_register_select_simple OF pipe_register_select IS
    TYPE registr_bank IS ARRAY (31 DOWNTO 1) OF word;
    SIGNAL reg_bank : registr_bank := (NOP_INSTRUCTION);
    SIGNAL instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL data_1, data_2 : OUT word;
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_data_1 <= x"0000_0000";
            reg_data_2 <= x"0000_0000";
            data_1 <= x"0000_0000";
            data_2 <= x"0000_0000";
            reg_pc <= x"0000_0000";
            reg_pc_4 <= x"0000_0004";
        ELSIF (rising_edge(clk)) THEN
            reg_data_1 <= data_1;
            reg_data_2 <= data_2;
            data_1 <= reg_bank(reg_addr_1);
            data_2 <= reg_bank(reg_addr_2);
            reg_pc <= pc;
            reg_pc_4 <= pc_4;
        END IF;
    END PROCESS;
END pipe_register_select_simple; -- pipe_register_select_simple