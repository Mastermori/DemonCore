LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;

ENTITY pipeline IS
    PORT(
        clk   : IN STD_LOGIC;
        reset : IN STD_LOGIC
    );
END;

ARCHITECTURE pipeline_collection OF pipeline IS
    SIGNAL pc : unsigned(31 DOWNTO 0);

    SIGNAL reg_instruction : instruction32;
    SIGNAL reg_pc_fetch    : unsigned(31 DOWNTO 0);

    -- Decode signals
    SIGNAL reg_addr_1, reg_addr_2, reg_addr_dest : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL d_out_register_read                   : STD_LOGIC;
    SIGNAL d_out_immediate                       : signed(31 DOWNTO 0);
    SIGNAL reg_pc_decode                         : unsigned(31 DOWNTO 0);
    SIGNAL d_out_use_immediate                   : std_logic;
    SIGNAL d_out_main_func                       : std_logic_vector(2 downto 0);
    SIGNAL d_out_second_func                     : std_logic;
    SIGNAL d_out_exec_func                       : std_logic_vector(2 downto 0);
    signal d_out_read_memory                     : std_logic;

    -- Register select signals
    SIGNAL reg_data_1, reg_data_2 : signed(31 downto 0);
    SIGNAL r_out_pc               : unsigned(31 DOWNTO 0);
    SIGNAL r_out_immediate        : signed(31 downto 0);
    SIGNAL r_out_use_immediate    : std_logic;
    SIGNAL r_out_main_func        : std_logic_vector(2 downto 0);
    SIGNAL r_out_second_func      : std_logic;
    SIGNAL r_out_exec_func        : std_logic_vector(2 downto 0);
    signal r_out_addr_dest        : register_adress;
    signal r_out_read_memory      : std_logic;

    -- Execute signals
    SIGNAL e_out_result           : signed(31 downto 0);
    signal e_out_pc_write_enable  : std_logic;
    signal e_out_write_reg_enable : std_logic;
    signal e_out_reg_addr_dest    : register_adress;
    signal e_out_read_memory_enable      : std_logic;
    signal e_out_computed_pc      : unsigned(31 downto 0);
    signal e_out_memory_read_addr : unsigned(31 downto 0);
    signal e_out_write_memory_enable : std_logic;

    -- Memory signals
    signal m_out_reg_addr_dest    : register_adress;
    signal m_out_write_reg_enable : std_logic;
    signal m_out_data             : signed(31 downto 0);

    -- Write back signals
    signal w_out_reg_addr_dest    : register_adress;
    signal w_out_write_reg_enable : std_logic;
    signal w_out_data             : signed(31 downto 0);

BEGIN
    pipe_fetch_inst : ENTITY work.pipe_fetch
        PORT MAP(
            clk               => clk,
            reset             => reset,
            pc                => pc,
            f_out_instruction => reg_instruction,
            f_out_pc          => reg_pc_fetch
        );
    pipe_decoder_inst : ENTITY work.pipe_decoder
        PORT MAP(
            clk                 => clk,
            reset               => reset,
            d_in_instruction    => reg_instruction,
            d_reg_addr_1        => reg_addr_1,
            d_reg_addr_2        => reg_addr_2,
            d_reg_addr_dest     => reg_addr_dest,
            d_out_register_read => d_out_register_read,
            d_out_read_memory   => d_out_read_memory,
            d_out_immediate     => d_out_immediate,
            d_out_use_immediate => d_out_use_immediate,
            d_out_main_func     => d_out_main_func,
            d_out_second_func   => d_out_second_func,
            d_out_exec_func     => d_out_exec_func,
            d_in_pc             => reg_pc_fetch,
            d_out_pc            => reg_pc_decode
        );
    pipe_register_select_inst : ENTITY work.pipe_register_select
        PORT MAP(
            clk                   => clk,
            reset                 => reset,
            r_in_pc               => reg_pc_decode,
            r_in_immediate        => d_out_immediate,
            r_in_register_read    => d_out_register_read,
            addr_1                => reg_addr_1,
            addr_2                => reg_addr_2,
            r_in_addr_dest        => reg_addr_dest,
            r_out_addr_dest       => r_out_addr_dest,
            reg_data_1            => reg_data_1,
            reg_data_2            => reg_data_2,
            r_out_pc              => r_out_pc,
            r_out_immediate       => r_out_immediate,
            r_in_use_immediate    => d_out_use_immediate,
            r_in_main_func        => d_out_main_func,
            r_in_second_func      => d_out_second_func,
            r_in_exec_func        => d_out_exec_func,
            r_in_read_memory      => d_out_read_memory,
            r_out_use_immediate   => r_out_use_immediate,
            r_out_main_func       => r_out_main_func,
            r_out_second_func     => r_out_second_func,
            r_out_exec_func       => r_out_exec_func,
            r_out_read_memory     => r_out_read_memory,
            r_in_reg_addr_dest    => w_out_reg_addr_dest,
            r_in_write_reg_enable => w_out_write_reg_enable,
            r_in_write_data       => w_out_data
        );
    pipe_execute_inst : ENTITY work.pipe_execute
        PORT MAP(
            clk                       => clk,
            reset                     => reset,
            data_1                    => reg_data_1,
            data_2                    => reg_data_2,
            e_in_reg_addr_dest        => r_out_addr_dest,
            e_in_immediate            => r_out_immediate,
            in_alu_main_func          => r_out_main_func,
            in_alu_second_func        => r_out_second_func,
            in_use_immediate          => r_out_use_immediate,
            in_exec_func              => r_out_exec_func,
            e_in_pc                   => r_out_pc,
            e_in_read_memory          => r_out_read_memory,
            e_out_result              => e_out_result,
            e_out_computed_pc         => e_out_computed_pc,
            e_out_write_pc_enable     => e_out_pc_write_enable,
            e_out_write_reg_enable    => e_out_write_reg_enable,
            e_out_reg_addr_dest       => e_out_reg_addr_dest,
            e_out_memory_read_addr => e_out_memory_read_addr,
            e_out_read_memory_enable  => e_out_read_memory_enable,
            e_out_write_memory_enable => e_out_write_memory_enable
        );
    pipe_memory_inst : entity work.pipe_memory
        port map(
            clk                      => clk,
            reset                    => reset,
            m_in_reg_addr_dest       => e_out_reg_addr_dest,
            m_in_write_reg_enable    => e_out_write_reg_enable,
            m_in_data                => e_out_result,
            m_in_read_addr           => e_out_memory_read_addr,
            m_in_read_memory_enable  => e_out_read_memory_enable,
            m_in_write_memory_enable => e_out_write_memory_enable,
            m_out_reg_addr_dest      => m_out_reg_addr_dest,
            m_out_write_reg_enable   => m_out_write_reg_enable,
            m_out_data               => m_out_data
        );

    pipe_write_back_inst : ENTITY work.pipe_write_back
        port map(
            clk                    => clk,
            reset                  => reset,
            w_in_reg_addr_dest     => m_out_reg_addr_dest,
            w_in_write_reg_enable  => m_out_write_reg_enable,
            w_in_data              => m_out_data,
            w_out_reg_addr_dest    => w_out_reg_addr_dest,
            w_out_write_reg_enable => w_out_write_reg_enable,
            w_out_data             => w_out_data
        );

    clkProcess : PROCESS(clk, reset) IS
    BEGIN
        IF (reset = '0') THEN
            pc <= x"0000_0000";
        ELSIF (rising_edge(clk)) THEN
            if e_out_pc_write_enable = '1' then
                pc <= unsigned(e_out_computed_pc);
            else
                pc <= pc + 4;
            end if;
        END IF;
    END PROCESS;
END ARCHITECTURE;
