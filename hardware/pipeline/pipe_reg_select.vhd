LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_register_select IS
    PORT(
        clk                    : IN  STD_LOGIC;
        reset                  : IN  STD_LOGIC;
        r_in_pc                : IN  unsigned(31 DOWNTO 0);
        addr_1, addr_2         : IN  register_adress;
        reg_data_1, reg_data_2 : OUT signed(31 downto 0);
        f_out_pc               : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_register_select_simple OF pipe_register_select IS
    TYPE registr_bank IS ARRAY (31 DOWNTO 0) OF signed(31 downto 0);
    SIGNAL reg_bank       : registr_bank := (0 => x"0000_0001", 1 => x"0000_0002", 2 => x"0000_0003", others => x"0000_0000");
    SIGNAL data_1, data_2 : signed(31 downto 0);
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_data_1 <= x"0000_0000";
            reg_data_2 <= x"0000_0000";
            data_1     <= x"0000_0000";
            data_2     <= x"0000_0000";
            f_out_pc   <= x"0000_0000";
        ELSIF (rising_edge(clk)) THEN
            reg_data_1 <= reg_bank(to_integer(unsigned(addr_1)));
            reg_data_2 <= reg_bank(to_integer(unsigned(addr_2)));
            --reg_data_1 <= data_1;
            --reg_data_2 <= data_2;
            f_out_pc   <= r_in_pc;
        END IF;
    END PROCESS;
END pipe_register_select_simple;        -- pipe_register_select_simple