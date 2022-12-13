LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE WORK.alu;

ENTITY pipe_execute IS
    PORT(
        clk                    : IN  STD_LOGIC;
        reset                  : IN  STD_LOGIC;
        data_1, data_2         : IN  signed;
        e_in_reg_addr_dest     : IN  register_adress;
        immediate              : IN  signed(31 DOWNTO 0);
        upper_immediate        : IN  signed(31 DOWNTO 0);
        in_alu_main_func       : IN  std_logic_vector(2 downto 0);
        in_alu_second_func     : IN  std_logic;
        in_use_immediate       : IN  std_logic;
        in_exec_func           : IN  std_logic_vector(2 downto 0);
        e_in_pc                : IN  unsigned(31 DOWNTO 0);
        e_out_result           : OUT signed(31 DOWNTO 0);
        e_out_write_pc_enable  : OUT std_logic;
        e_out_write_reg_enable : OUT std_logic;
        e_out_reg_addr_dest    : OUT register_adress
    );
END;

architecture pipe_execute_simple of pipe_execute is
    signal alu_result : signedNumber;
    signal alu_data_2 : signedNumber;
begin

    alu_inst : entity work.alu(alu_simple)
        port map(
            vec1        => data_1,
            vec2        => alu_data_2,
            main_func   => in_alu_main_func,
            second_func => in_alu_second_func,
            out_vec     => alu_result
        );

    alu_data_2 <= immediate when in_use_immediate = '1' else data_2;

    alu_proc : process(clk, reset) is
    begin
        if (reset = '0') then
            e_out_result           <= (others => '0');
            e_out_write_pc_enable  <= '0';
            e_out_write_reg_enable <= '0';
            e_out_reg_addr_dest    <= (others => '0');
        elsif (rising_edge(clk)) then
            e_out_reg_addr_dest <= e_in_reg_addr_dest;
            case in_exec_func is
                when "000" =>
                    e_out_write_pc_enable <= '0';
                    e_out_write_reg_enable <= '1';
                    e_out_result <= alu_result;
                when others => null;
            end case;
        else
            null;
        end if;
    end process;
end architecture;
