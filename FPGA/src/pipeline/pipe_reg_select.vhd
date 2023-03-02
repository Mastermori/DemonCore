LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_register_select IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        r_in_pc : IN unsigned(31 DOWNTO 0);
        r_in_immediate : IN signed(31 DOWNTO 0);
        r_in_register_read : IN STD_LOGIC;
        addr_1, addr_2, r_in_addr_dest : IN register_adress;
        r_out_addr_dest : OUT register_adress;
        reg_data_1, reg_data_2 : OUT signed(31 DOWNTO 0);
        r_out_pc : OUT unsigned(31 DOWNTO 0);
        r_out_immediate : OUT signed(31 DOWNTO 0);
        -- Pipeline-register
        r_in_use_immediate : IN STD_LOGIC;
        r_in_main_func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        r_in_second_func : IN STD_LOGIC;
        r_in_exec_func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        r_in_read_memory : IN STD_LOGIC;
        r_out_use_immediate : OUT STD_LOGIC;
        r_out_main_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        r_out_second_func : OUT STD_LOGIC;
        r_out_exec_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        r_out_read_memory : OUT STD_LOGIC;
        -- Write-Back Verkn�pfung
        r_in_reg_addr_dest : IN register_adress;
        r_in_write_reg_enable : IN STD_LOGIC;
        r_in_write_data : IN unsigned(31 DOWNTO 0);

        reg_t0_out: OUT word
    );
END;

ARCHITECTURE pipe_register_select_simple OF pipe_register_select IS
    TYPE register_bank IS ARRAY (31 DOWNTO 0) OF signed(31 DOWNTO 0);
    SIGNAL reg_bank : register_bank := (OTHERS => x"0000_0000");
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_data_1 <= (OTHERS => '0');
            reg_data_2 <= (OTHERS => '0');
            r_out_pc <= (OTHERS => '0');
            r_out_use_immediate <= '0';
            r_out_main_func <= "000";
            r_out_second_func <= '0';
            r_out_exec_func <= "000";
            r_out_addr_dest <= (OTHERS => '0');
            r_out_immediate <= (OTHERS => '0');
            r_out_read_memory <= '0';
            reg_t0_out <= x"0000_0002";
        ELSIF rising_edge(clk) THEN
            -- Register select
            reg_t0_out <= std_logic_vector(reg_bank(5));
            IF r_in_register_read = '1' THEN
                reg_data_1 <= reg_bank(to_integer(unsigned(addr_1)));
                reg_data_2 <= reg_bank(to_integer(unsigned(addr_2)));
            ELSE
                --reg_data_1 <= (OTHERS => '-');
                --reg_data_2 <= (OTHERS => '-');
            END IF;
            r_out_addr_dest <= r_in_addr_dest;
            r_out_use_immediate <= r_in_use_immediate;
            r_out_main_func <= r_in_main_func;
            r_out_second_func <= r_in_second_func;
            r_out_exec_func <= r_in_exec_func;
            r_out_pc <= r_in_pc;
            r_out_immediate <= r_in_immediate;
            r_out_read_memory <= r_in_read_memory;
        END IF;
    END PROCESS;

    reg_write_back : PROCESS (clk, reset) IS
    BEGIN
        IF (reset = '0') then
            reg_bank <= (others => x"0000_0000");
        ELSIF (falling_edge(clk)) THEN
            IF r_in_write_reg_enable = '1' AND to_integer(unsigned(r_in_reg_addr_dest)) /= 0 THEN
                reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= signed(r_in_write_data);
                -- reg_bank(0) <= (OTHERS => '0'); -- TODO: find solution to hardwire 0
                --reg_t0_out <= std_logic_vector(reg_bank(to_integer(unsigned(r_in_reg_addr_dest))));
            ELSE
                NULL;
            END IF;
        END if;
    END PROCESS reg_write_back;

    -- Write Back
    --reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= r_in_write_data when r_in_write_reg_enable = '1' and unsigned(r_in_reg_addr_dest) /= 0 else null;

    --if r_in_write_reg_enable = '1' then
    --    reg_bank(to_integer(unsigned(r_in_reg_addr_dest))) <= r_in_write_data;
    --    reg_bank(0) <= (others => '0');
    --else
    --    null;
    --end if;
END pipe_register_select_simple; -- pipe_register_select_simple