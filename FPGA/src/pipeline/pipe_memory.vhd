LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_memory IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        m_in_reg_addr_dest : IN register_adress;
        m_in_write_reg_enable : IN STD_LOGIC;
        m_in_data : IN signed(31 DOWNTO 0);
        m_in_memory_addr : IN std_logic_vector(31 DOWNTO 0);
        m_in_read_memory_enable : IN STD_LOGIC;
        m_in_write_memory_enable : IN STD_LOGIC;
        m_in_memory_data : IN word;
        m_out_memory_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_out_memory_not_write_enable : OUT STD_LOGIC;
        m_out_reg_addr_dest : OUT register_adress;
        m_out_write_reg_enable : OUT STD_LOGIC;
        m_out_data : OUT word
    );
END;

ARCHITECTURE pipe_memory_simple OF pipe_memory IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        m_out_memory_addr <= m_in_memory_addr;
        IF (reset = '0') THEN
            --m_out_memory_addr <= (OTHERS => '1'),  (OTHERS => '0') after 1 ns;
            m_out_memory_not_write_enable <= '1';
            m_out_reg_addr_dest <= (OTHERS => '0');
            m_out_write_reg_enable <= '1';
            m_out_data <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            -- Dont cares
            --m_out_reg_addr_dest <= (OTHERS => '-');
            --m_out_data <= (OTHERS => '-');
            --
            
            m_out_reg_addr_dest <= m_in_reg_addr_dest;
            m_out_write_reg_enable <= m_in_write_reg_enable;
            m_out_memory_not_write_enable <= NOT m_in_write_memory_enable;

            IF m_in_read_memory_enable = '1' THEN
                m_out_data <= m_in_memory_data;
            ELSE
                m_out_data <= STD_LOGIC_VECTOR(m_in_data);
            END IF;
        END IF;
    END PROCESS;
END pipe_memory_simple; -- pipe_memory_simple