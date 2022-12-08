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
    SIGNAL control_enables                       : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL logic_enable                          : STD_LOGIC;
    SIGNAL alu_enable                            : STD_LOGIC;
    SIGNAL add_sub_alu_code                      : STD_LOGIC;
    SIGNAL register_read                         : STD_LOGIC;
    SIGNAL immediate                             : signed(31 DOWNTO 0);
    SIGNAL upper_immediate                       : signed(31 DOWNTO 0);
    SIGNAL reg_pc_decode                         : unsigned(31 DOWNTO 0);

    -- Register select signals
    SIGNAL reg_data_1, reg_data_2 : signed(31 downto 0);
    SIGNAL reg_pc_sel             : unsigned(31 DOWNTO 0);

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
            clk              => clk,
            reset            => reset,
            instruction      => reg_instruction,
            d_regaddr_1      => reg_addr_1,
            d_regaddr_2      => reg_addr_2,
            d_regaddr_dest   => reg_addr_dest,
            control_enables  => control_enables,
            logic_enable     => logic_enable,
            alu_enable       => alu_enable,
            add_sub_alu_code => add_sub_alu_code,
            register_read    => register_read,
            immediate        => immediate,
            upper_immediate  => upper_immediate,
            d_in_pc          => reg_pc_fetch,
            d_out_pc         => reg_pc_decode
        );
    pipe_register_select_inst : ENTITY work.pipe_register_select
        PORT MAP(
            clk        => clk,
            reset      => reset,
            r_in_pc    => reg_pc_decode,
            addr_1     => reg_addr_1,
            addr_2     => reg_addr_2,
            reg_data_1 => reg_data_1,
            reg_data_2 => reg_data_2,
            f_out_pc   => reg_pc_sel
        );
    pipe_execute_inst : ENTITY work.pipe_execute
        PORT MAP(
            clk              => clk,
            reset            => reset,
            data_1           => reg_data_1,
            data_2           => reg_data_2,
            immediate        => immediate,
            upper_immediate  => upper_immediate,
            alu_enable       => alu_enable,
            add_sub_alu_code => add_sub_alu_code,
            result           => result,
            e_in_pc          => reg_pc_sel,
            e_out_pc         => reg_pc_sel
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
