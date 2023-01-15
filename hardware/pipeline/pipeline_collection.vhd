LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE work.memPkg.ALL;

ENTITY pipeline IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC
    );
END;

ARCHITECTURE pipeline_collection OF pipeline IS
    SIGNAL pc : unsigned(31 DOWNTO 0);

    SIGNAL f_out_rom_addr : std_logic_vector(7 downto 0);
    SIGNAL reg_instruction : instruction32;
    SIGNAL reg_pc_fetch : unsigned(31 DOWNTO 0);

    -- Decode signals
    SIGNAL reg_addr_1, reg_addr_2, reg_addr_dest : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL d_out_register_read : STD_LOGIC;
    SIGNAL d_out_immediate : signed(31 DOWNTO 0);
    SIGNAL reg_pc_decode : unsigned(31 DOWNTO 0);
    SIGNAL d_out_use_immediate : STD_LOGIC;
    SIGNAL d_out_main_func : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL d_out_second_func : STD_LOGIC;
    SIGNAL d_out_exec_func : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL d_out_read_memory : STD_LOGIC;

    -- Register select signals
    SIGNAL reg_data_1, reg_data_2 : signed(31 DOWNTO 0);
    SIGNAL r_out_pc : unsigned(31 DOWNTO 0);
    SIGNAL r_out_immediate : signed(31 DOWNTO 0);
    SIGNAL r_out_use_immediate : STD_LOGIC;
    SIGNAL r_out_main_func : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL r_out_second_func : STD_LOGIC;
    SIGNAL r_out_exec_func : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL r_out_addr_dest : register_adress;
    SIGNAL r_out_read_memory : STD_LOGIC;

    -- Execute signals
    SIGNAL e_out_result : signed(31 DOWNTO 0);
    SIGNAL e_out_pc_write_enable : STD_LOGIC;
    SIGNAL e_out_write_reg_enable : STD_LOGIC;
    SIGNAL e_out_reg_addr_dest : register_adress;
    SIGNAL e_out_read_memory_enable : STD_LOGIC;
    SIGNAL e_out_computed_pc : unsigned(31 DOWNTO 0);
    SIGNAL e_out_memory_addr : unsigned(31 DOWNTO 0);
    SIGNAL e_out_write_memory_enable : STD_LOGIC;

    -- Memory signals
    SIGNAL m_out_reg_addr_dest : register_adress;
    SIGNAL m_out_write_reg_enable : STD_LOGIC;
    SIGNAL m_out_data : word;
    SIGNAL m_out_memory_addr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL m_out_memory_not_write_enable : STD_LOGIC;

    -- Write back signals
    SIGNAL w_out_reg_addr_dest : register_adress;
    SIGNAL w_out_write_reg_enable : STD_LOGIC;
    SIGNAL w_out_data : unsigned(31 DOWNTO 0);

    -- RAM signals
    SIGNAL ram_out_data : word;
    SIGNAL dummy_txt : fileIoT;

    -- ROM signals
    SIGNAL rom_out_data : instruction32;
    SIGNAL rom_txt : fileIoT;

BEGIN
    pipe_fetch_inst : ENTITY work.pipe_fetch
        PORT MAP(
            clk => clk,
            reset => reset,
            pc => pc,
            f_out_rom_addr    => f_out_rom_addr,
            f_in_rom_data     => rom_out_data,
            f_out_instruction => reg_instruction,
            f_out_pc => reg_pc_fetch
        );
    pipe_decoder_inst : ENTITY work.pipe_decoder
        PORT MAP(
            clk => clk,
            reset => reset,
            d_in_instruction => reg_instruction,
            d_reg_addr_1 => reg_addr_1,
            d_reg_addr_2 => reg_addr_2,
            d_reg_addr_dest => reg_addr_dest,
            d_out_register_read => d_out_register_read,
            d_out_read_memory => d_out_read_memory,
            d_out_immediate => d_out_immediate,
            d_out_use_immediate => d_out_use_immediate,
            d_out_main_func => d_out_main_func,
            d_out_second_func => d_out_second_func,
            d_out_exec_func => d_out_exec_func,
            d_in_pc => reg_pc_fetch,
            d_out_pc => reg_pc_decode
        );
    pipe_register_select_inst : ENTITY work.pipe_register_select
        PORT MAP(
            clk => clk,
            reset => reset,
            r_in_pc => reg_pc_decode,
            r_in_immediate => d_out_immediate,
            r_in_register_read => d_out_register_read,
            addr_1 => reg_addr_1,
            addr_2 => reg_addr_2,
            r_in_addr_dest => reg_addr_dest,
            r_out_addr_dest => r_out_addr_dest,
            reg_data_1 => reg_data_1,
            reg_data_2 => reg_data_2,
            r_out_pc => r_out_pc,
            r_out_immediate => r_out_immediate,
            r_in_use_immediate => d_out_use_immediate,
            r_in_main_func => d_out_main_func,
            r_in_second_func => d_out_second_func,
            r_in_exec_func => d_out_exec_func,
            r_in_read_memory => d_out_read_memory,
            r_out_use_immediate => r_out_use_immediate,
            r_out_main_func => r_out_main_func,
            r_out_second_func => r_out_second_func,
            r_out_exec_func => r_out_exec_func,
            r_out_read_memory => r_out_read_memory,
            r_in_reg_addr_dest => w_out_reg_addr_dest,
            r_in_write_reg_enable => w_out_write_reg_enable,
            r_in_write_data => w_out_data
        );
    pipe_execute_inst : ENTITY work.pipe_execute
        PORT MAP(
            clk => clk,
            reset => reset,
            e_in_data_1 => reg_data_1,
            e_in_data_2 => reg_data_2,
            e_in_reg_addr_dest => r_out_addr_dest,
            e_in_immediate => r_out_immediate,
            in_alu_main_func => r_out_main_func,
            in_alu_second_func => r_out_second_func,
            in_use_immediate => r_out_use_immediate,
            in_exec_func => r_out_exec_func,
            e_in_pc => r_out_pc,
            e_in_read_memory => r_out_read_memory,
            e_out_result => e_out_result,
            e_out_computed_pc => e_out_computed_pc,
            e_out_write_pc_enable => e_out_pc_write_enable,
            e_out_write_reg_enable => e_out_write_reg_enable,
            e_out_reg_addr_dest => e_out_reg_addr_dest,
            e_out_memory_addr => e_out_memory_addr,
            e_out_read_memory_enable => e_out_read_memory_enable,
            e_out_write_memory_enable => e_out_write_memory_enable
        );
    pipe_memory_inst : ENTITY work.pipe_memory
        PORT MAP(
            clk => clk,
            reset => reset,
            m_in_reg_addr_dest => e_out_reg_addr_dest,
            m_in_write_reg_enable => e_out_write_reg_enable,
            m_in_data => e_out_result,
            m_in_memory_addr => e_out_memory_addr,
            m_in_read_memory_enable => e_out_read_memory_enable,
            m_in_write_memory_enable => e_out_write_memory_enable,
            m_in_memory_data => ram_out_data,
            m_out_memory_addr => m_out_memory_addr,
            m_out_memory_not_write_enable => m_out_memory_not_write_enable,
            m_out_reg_addr_dest => m_out_reg_addr_dest,
            m_out_write_reg_enable => m_out_write_reg_enable,
            m_out_data => m_out_data
        );

    pipe_write_back_inst : ENTITY work.pipe_write_back
        PORT MAP(
            clk => clk,
            reset => reset,
            w_in_reg_addr_dest => m_out_reg_addr_dest,
            w_in_write_reg_enable => m_out_write_reg_enable,
            w_in_data => m_out_data,
            w_out_reg_addr_dest => w_out_reg_addr_dest,
            w_out_write_reg_enable => w_out_write_reg_enable,
            w_out_data => w_out_data
        );

    ramio_inst : ENTITY work.ramIO
        GENERIC MAP(
            addrWd => 8,
            dataWd => 32,
            fileId	=> "memorySim/ram_fill.dat"
        )
        PORT MAP(
            nWE => m_out_memory_not_write_enable,
            addr => m_out_memory_addr(9 DOWNTO 2), -- TODO: Find out how to do proper this properly (+4 bit adresses)
            dataI => m_out_data,
            dataO => ram_out_data,
            fileIO => dummy_txt
        );
    romio_inst : ENTITY work.rom
        GENERIC MAP(
            addrWd => 8,
            dataWd => 32,
            fileId	=> "memorySim/rom_fill.dat"
        )
        PORT MAP(
            addr => f_out_rom_addr,
            data => rom_out_data,
            fileIO => rom_txt
        );

    clkProcess : PROCESS (clk, reset) IS
    BEGIN
        IF (reset = '0') THEN
            pc <= x"0000_0000";
            dummy_txt	<= load;
            rom_txt   <= load;
            -- rom_txt	<= load,  none after 5 ns;
        ELSIF (rising_edge(clk)) THEN
            IF e_out_pc_write_enable = '1' THEN
                pc <= unsigned(e_out_computed_pc);
            ELSE
                pc <= pc + 4;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;