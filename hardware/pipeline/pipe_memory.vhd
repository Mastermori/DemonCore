LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_memory IS
    PORT(
        clk                      : IN  STD_LOGIC;
        reset                    : IN  STD_LOGIC;
        m_in_reg_addr_dest       : IN  register_adress;
        m_in_write_reg_enable    : IN  std_logic;
        m_in_data                : IN  signed(31 downto 0);
        m_in_memory_addr         : IN  unsigned(31 downto 0);
        m_in_read_memory_enable  : IN  std_logic;
        m_in_write_memory_enable : IN  std_logic;
        m_in_memory_size         : IN  unsigned(4 downto 0);
        m_in_memory_sign_type    : IN  std_logic;
        m_out_reg_addr_dest      : OUT register_adress;
        m_out_write_reg_enable   : OUT std_logic;
        m_out_data               : OUT signed(31 downto 0)
    );
END;

ARCHITECTURE pipe_memory_simple OF pipe_memory IS
    TYPE memory_bank IS ARRAY (0 to 4095) OF word;
    signal memory : memory_bank := (others => x"0000_0000");
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
            if m_in_read_memory_enable = '1' then
                if m_in_memory_sign_type = '0' then
                    m_out_data <= signed(resize(signed(memory(to_integer(m_in_memory_addr))(to_integer(m_in_memory_size) downto 0)), m_out_data'length));
                else
                    m_out_data <= signed(resize(unsigned(memory(to_integer(m_in_memory_addr))(to_integer(m_in_memory_size) downto 0)), m_out_data'length));
                end if;
            elsif m_in_write_memory_enable = '1' then
                memory(to_integer(m_in_memory_addr))(to_integer(m_in_memory_size) downto 0) <= std_logic_vector(m_in_data(to_integer(m_in_memory_size) downto 0));
            else
                m_out_data <= m_in_data;
            end if;
        END IF;
    END PROCESS;
END pipe_memory_simple;                 -- pipe_memory_simple