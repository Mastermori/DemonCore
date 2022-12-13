LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_memory IS
    PORT(
        clk                    : IN  STD_LOGIC;
        reset                  : IN  STD_LOGIC;
        m_in_reg_addr_dest     : IN  register_adress;
        m_in_write_reg_enable  : IN  std_logic;
        m_in_data              : IN  signed(31 downto 0);
        m_out_reg_addr_dest    : OUT register_adress;
        m_out_write_reg_enable : OUT std_logic;
        m_out_data             : OUT signed(31 downto 0)
    );
END;

ARCHITECTURE pipe_memory_simple OF pipe_memory IS

BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            m_out_reg_addr_dest    <= b"0_0000";
            m_out_data             <= x"0000_0000";
            m_out_write_reg_enable <= '0';
        ELSIF (rising_edge(clk)) THEN
            m_out_reg_addr_dest    <= m_in_reg_addr_dest;
            m_out_write_reg_enable <= m_in_write_reg_enable;
            m_out_data             <= m_in_data;
        END IF;
    END PROCESS;
END pipe_memory_simple;             -- pipe_memory_simple