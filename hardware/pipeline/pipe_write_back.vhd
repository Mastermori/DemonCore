LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_write_back IS
    PORT(
        clk                    : IN  STD_LOGIC;
        reset                  : IN  STD_LOGIC;
        w_in_reg_addr_dest     : IN  register_adress;
        w_in_write_reg_enable  : IN  std_logic;
        w_in_data              : IN  signed(31 downto 0);
        w_out_reg_addr_dest    : OUT register_adress;
        w_out_write_reg_enable : OUT std_logic;
        w_out_data             : OUT signed(31 downto 0)
    );
END;

ARCHITECTURE pipe_write_back_simple OF pipe_write_back IS

BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            w_out_reg_addr_dest    <= b"0_0000";
            w_out_data             <= x"0000_0000";
            w_out_write_reg_enable <= '0';
        ELSIF (rising_edge(clk)) THEN
            w_out_reg_addr_dest    <= w_in_reg_addr_dest;
            w_out_write_reg_enable <= w_in_write_reg_enable;
            w_out_data             <= w_in_data;
        END IF;
    END PROCESS;
END pipe_write_back_simple;             -- pipe_write_back_simple