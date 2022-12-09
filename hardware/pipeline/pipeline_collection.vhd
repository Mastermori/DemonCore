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
    SIGNAL immediate                             : signed(31 DOWNTO 0);
    SIGNAL upper_immediate                       : signed(31 DOWNTO 0);
    SIGNAL reg_pc_decode                         : unsigned(31 DOWNTO 0);
    SIGNAL d_out_use_immediate                   : std_logic;
    SIGNAL d_out_main_func                       : std_logic_vector(2 downto 0);
    SIGNAL d_out_second_func                     : std_logic;
    SIGNAL d_out_exec_func                       : std_logic_vector(2 downto 0);

    -- Register select signals
    SIGNAL reg_data_1, reg_data_2 : signed(31 downto 0);
    SIGNAL reg_pc_sel             : unsigned(31 DOWNTO 0);
    SIGNAL r_out_use_immediate    : std_logic;
    SIGNAL r_out_main_func        : std_logic_vector(2 downto 0);
    SIGNAL r_out_second_func      : std_logic;
    SIGNAL r_out_exec_func        : std_logic_vector(2 downto 0);

    -- Execute signals
    SIGNAL result     : signed(31 downto 0);
    SIGNAL reg_pc_exe : unsigned(31 DOWNTO 0);

BEGIN
    pipe_fetch_inst : ENTITY work.pipe_fetch
        PORT MAP(
            clk             => clk,
            reset           => reset,
            pc              => pc,
            reg_instruction => reg_instruction,
            f_out_pc        => reg_pc_fetch
        );
    pipe_decoder_inst : ENTITY work.pipe_decoder
        PORT MAP(
            clk                 => clk,
            reset               => reset,
            instruction         => reg_instruction,
            d_regaddr_1         => reg_addr_1,
            d_regaddr_2         => reg_addr_2,
            d_regaddr_dest      => reg_addr_dest,
            d_out_register_read => d_out_register_read,
            immediate           => immediate,
            upper_immediate     => upper_immediate,
            d_out_use_immediate => d_out_use_immediate,
            d_out_main_func     => d_out_main_func,
            d_out_second_func   => d_out_second_func,
            d_out_exec_func     => d_out_exec_func,
            d_in_pc             => reg_pc_fetch,
            d_out_pc            => reg_pc_decode
        );
    pipe_register_select_inst : ENTITY work.pipe_register_select
        PORT MAP(
            clk                 => clk,
            reset               => reset,
            r_in_pc             => reg_pc_decode,
            r_in_register_read  => d_out_register_read,
            addr_1              => reg_addr_1,
            addr_2              => reg_addr_2,
            reg_data_1          => reg_data_1,
            reg_data_2          => reg_data_2,
            f_out_pc            => reg_pc_sel,
            r_in_use_immediate  => d_out_use_immediate,
            r_in_main_func      => d_out_main_func,
            r_in_second_func    => d_out_second_func,
            r_in_exec_func      => d_out_exec_func,
            r_out_use_immediate => r_out_use_immediate,
            r_out_main_func     => r_out_main_func,
            r_out_second_func   => r_out_second_func,
            r_out_exec_func     => r_out_exec_func
        );
    pipe_execute_inst : ENTITY work.pipe_execute
        PORT MAP(
            clk                => clk,
            reset              => reset,
            data_1             => reg_data_1,
            data_2             => reg_data_2,
            immediate          => immediate,
            upper_immediate    => upper_immediate,
            in_alu_main_func   => r_out_main_func,
            in_alu_second_func => r_out_second_func,
            in_use_immediate   => r_out_use_immediate,
            result             => result,
            e_in_pc            => reg_pc_sel,
            e_out_pc           => reg_pc_sel
        );
    clkProcess : PROCESS(clk, reset) IS
    BEGIN
        IF (reset = '0') THEN
            pc <= x"0000_0000";
        ELSIF (rising_edge(clk)) THEN   -- TODO: changed back to rising_edge and fix 2-cycle pipeline
            pc <= pc + 4;
        END IF;
    END PROCESS;
END ARCHITECTURE;
