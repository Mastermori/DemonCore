LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_register_select IS
    PORT(
        clk                            : IN  STD_LOGIC;
        reset                          : IN  STD_LOGIC;
        r_in_pc                        : IN  unsigned(31 DOWNTO 0);
        r_in_immediate                 : IN  signed(31 downto 0);
        r_in_register_read             : IN  std_logic;
        addr_1, addr_2, r_in_addr_dest : IN  register_adress;
        r_out_addr_dest                : OUT register_adress;
        reg_data_1, reg_data_2         : OUT signed(31 downto 0);
        r_out_pc                       : OUT unsigned(31 DOWNTO 0);
        r_out_immediate                : OUT signed(31 downto 0);
        -- Pipeline-register
        r_in_use_immediate             : IN  std_logic;
        r_in_main_func                 : IN  std_logic_vector(2 downto 0);
        r_in_second_func               : IN  std_logic;
        r_in_exec_func                 : IN  std_logic_vector(2 downto 0);
        r_in_read_memory               : IN  std_logic;
        r_out_use_immediate            : OUT std_logic;
        r_out_main_func                : OUT std_logic_vector(2 downto 0);
        r_out_second_func              : OUT std_logic;
        r_out_exec_func                : OUT std_logic_vector(2 downto 0);
        r_out_read_memory              : OUT std_logic;
        -- Write-Back Verkn�pfung
        r_in_reg_addr_dest             : IN  register_adress;
        r_in_write_reg_enable          : IN  std_logic;
        r_in_write_data                : IN  signed(31 downto 0)
    );
END;

ARCHITECTURE pipe_register_select_simple OF pipe_register_select IS
    TYPE register_bank IS ARRAY (31 DOWNTO 0) OF signed(31 downto 0);
    SIGNAL reg_bank : register_bank := (5 => x"0000_0004", others => x"0000_0000");
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_data_1          <= x"0000_0000";
            reg_data_2          <= x"0000_0000";
            r_out_pc            <= x"0000_0000";
            r_out_use_immediate <= '0';
            r_out_main_func     <= "000";
            r_out_second_func   <= '0';
            r_out_exec_func     <= "000";
            r_out_addr_dest     <= (others => '0');
            r_out_immediate     <= (others => '0');
            r_out_read_memory   <= '0';
        ELSIF rising_edge(clk) THEN
            -- Register select
            if r_in_register_read = '1' then
                reg_data_1 <= reg_bank(to_integer(unsigned(addr_1)));
                reg_data_2 <= reg_bank(to_integer(unsigned(addr_2)));
            else
                null;
            end if;
            r_out_addr_dest     <= r_in_addr_dest;
            r_out_use_immediate <= r_in_use_immediate;
            r_out_main_func     <= r_in_main_func;
            r_out_second_func   <= r_in_second_func;
            r_out_exec_func     <= r_in_exec_func;
            r_out_pc            <= r_in_pc;
            r_out_immediate     <= r_in_immediate;
            r_out_read_memory   <= r_in_read_memory;
        END IF;
    END PROCESS;

    reg_write_back : process(r_in_reg_addr_dest, r_in_write_data, r_in_write_reg_enable) is
    begin
        if r_in_write_reg_enable = '1' then
            reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= r_in_write_data;
            reg_bank(0)                                        <= (others => '0'); -- TODO: find solution to hardwire 0
        else
            null;
        end if;
    end process reg_write_back;

    -- Write Back
    --reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= r_in_write_data when r_in_write_reg_enable = '1' and unsigned(r_in_reg_addr_dest) /= 0 else null;

    --if r_in_write_reg_enable = '1' then
    --    reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= r_in_write_data;
    --    reg_bank(0) <= (others => '0');
    --else
    --    null;
    --end if;
END pipe_register_select_simple;        -- pipe_register_select_simple