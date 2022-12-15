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
        e_in_immediate         : IN  signed(31 DOWNTO 0);
        in_alu_main_func       : IN  std_logic_vector(2 downto 0);
        in_alu_second_func     : IN  std_logic;
        in_use_immediate       : IN  std_logic;
        in_exec_func           : IN  std_logic_vector(2 downto 0);
        e_in_pc                : IN  unsigned(31 DOWNTO 0);
        e_in_read_memory       : IN  std_logic;
        e_out_result           : OUT signed(31 DOWNTO 0);
        e_out_computed_pc      : OUT unsigned(31 downto 0);
        e_out_write_pc_enable  : OUT std_logic;
        e_out_write_reg_enable : OUT std_logic;
        e_out_reg_addr_dest    : OUT register_adress;
        e_out_read_memory      : OUT std_logic
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

    alu_data_2 <= e_in_immediate when in_use_immediate = '1' else data_2;

    alu_proc : process(clk, reset) is
        variable pc_4 : unsigned(31 downto 0);
        procedure branch is
        begin
            e_out_computed_pc     <= unsigned(e_in_pc + unsigned(e_in_immediate));
            e_out_write_pc_enable <= '1';
        end procedure;
    begin
        if (reset = '0') then
            e_out_result           <= (others => '0');
            e_out_write_reg_enable <= '0';
            e_out_reg_addr_dest    <= (others => '0');
            e_out_read_memory      <= '0';
            e_out_computed_pc      <= x"0000_0000";
            e_out_write_pc_enable  <= '0';
        elsif (rising_edge(clk)) then
            e_out_reg_addr_dest <= e_in_reg_addr_dest;
            e_out_read_memory   <= e_in_read_memory;
            case in_exec_func is
                when LOGIC_ARITHMETIC_EXEC_CODE =>
                    e_out_result           <= alu_result;
                    e_out_write_pc_enable  <= '0';
                    e_out_write_reg_enable <= '1';
                when JUMP_EXEC_CODE =>
                    pc_4                   := e_in_pc + 4;
                    -- write linked register
                    e_out_result           <= signed(pc_4);
                    e_out_write_reg_enable <= '1';
                    -- jump (by setting pc)
                    e_out_computed_pc      <= unsigned(pc_4 + unsigned(e_in_immediate));
                    e_out_write_pc_enable  <= '1';
                when BRANCH_EXEC_CODE =>
                    case in_alu_main_func is
                        when "000" =>
                            if data_1 = data_2 then
                                branch;
                            else
                                null;
                            end if;
                        when "001" =>
                            if data_1 /= data_2 then
                                branch;
                            else
                                null;
                            end if;
                        when "100" =>
                            if data_1 < data_2 then
                                branch;
                            else
                                null;
                            end if;
                        when "101" =>
                            if data_1 >= data_2 then
                                branch;
                            else
                                null;
                            end if;
                        when "110" =>
                            if unsigned(data_1) < unsigned(data_2) then
                                branch;
                            else
                                null;
                            end if;
                        when "111" =>
                            if unsigned(data_1) >= unsigned(data_2) then
                                branch;
                            else
                                null;
                            end if;
                        when others => null;
                    end case;

                when JUMP_REGISTER_EXEC_CODE =>
                    -- write linked register
                    e_out_result           <= signed(e_in_pc + 4);
                    e_out_write_reg_enable <= '1';
                    -- jump (by setting pc)
                    e_out_computed_pc      <= unsigned(shift_left(data_1, 2) + shift_left(e_in_immediate, 2));
                    e_out_write_pc_enable  <= '1';

                when LOAD_EXEC_CODE =>

                when STORE_EXEC_CODE =>

                when ADD_TO_PC_EXEC_CODE =>
                    e_out_result           <= signed(unsigned(e_in_pc) + unsigned(e_in_immediate)); -- TODO: check if this really works correctly
                    e_out_write_pc_enable  <= '0';
                    e_out_write_reg_enable <= '1';
                when others => null;
            end case;
        else
            null;
        end if;
    end process;
end architecture;
