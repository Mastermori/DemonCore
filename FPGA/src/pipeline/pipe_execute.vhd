LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE WORK.alu;

ENTITY pipe_execute IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        e_in_data_1, e_in_data_2 : IN signed;
        e_in_reg_addr_dest : IN register_adress;
        e_in_immediate : IN signed(31 DOWNTO 0);
        in_alu_main_func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        in_alu_second_func : IN STD_LOGIC;
        in_use_immediate : IN STD_LOGIC;
        in_exec_func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        e_in_pc : IN unsigned(31 DOWNTO 0);
        e_in_read_memory : IN STD_LOGIC;
        e_out_result : OUT signed(31 DOWNTO 0);
        e_out_computed_pc : OUT unsigned(31 DOWNTO 0);
        e_out_write_pc_enable : OUT STD_LOGIC;
        e_out_write_reg_enable : OUT STD_LOGIC;
        e_out_reg_addr_dest : OUT register_adress;
        e_out_memory_addr : OUT std_logic_vector(31 DOWNTO 0);
        e_out_read_memory_enable : OUT STD_LOGIC;
        e_out_write_memory_enable : OUT STD_LOGIC
    );
END;

ARCHITECTURE pipe_execute_simple OF pipe_execute IS
    SIGNAL alu_result : signedNumber;
    SIGNAL alu_data_2 : signedNumber;
BEGIN

    alu_inst : ENTITY work.alu(alu_simple)
        PORT MAP(
            vec1 => e_in_data_1,
            vec2 => alu_data_2,
            main_func => in_alu_main_func,
            second_func => in_alu_second_func,
            out_vec => alu_result
        );

    alu_data_2 <= e_in_immediate WHEN in_use_immediate = '1' ELSE
        e_in_data_2;

    alu_proc : PROCESS (clk, reset) IS
        VARIABLE pc_4 : unsigned(31 DOWNTO 0);
        PROCEDURE branch IS
        BEGIN
            e_out_computed_pc <= unsigned(e_in_pc + unsigned(e_in_immediate));
            e_out_write_pc_enable <= '1';
        END PROCEDURE;
    BEGIN
        IF (reset = '0') THEN
            e_out_result <= (OTHERS => '0');
            e_out_computed_pc <= (OTHERS => '0');
            e_out_write_pc_enable <= '0';
            e_out_write_reg_enable <= '0';
            e_out_reg_addr_dest <= (OTHERS => '0');
            e_out_memory_addr <= (OTHERS => '0');
            e_out_read_memory_enable <= '0';
            e_out_write_memory_enable <= '0';
        ELSIF (rising_edge(clk)) THEN
            --e_out_result <= (OTHERS => '-');
            --e_out_computed_pc <= (OTHERS => '-');
            --e_out_write_pc_enable <= '-';
            --e_out_write_pc_enable <= '-';
            --e_out_write_reg_enable <= '-';
            --e_out_reg_addr_dest <= (OTHERS => '-');
            --e_out_memory_addr <= (OTHERS => '-');
            --e_out_read_memory_enable <= '-';
            --e_out_write_memory_enable <= '-';
            e_out_reg_addr_dest <= e_in_reg_addr_dest;
            e_out_read_memory_enable <= e_in_read_memory;
            pc_4 := e_in_pc + 4;
            CASE in_exec_func IS
                WHEN LOGIC_ARITHMETIC_EXEC_CODE =>
                    e_out_result <= alu_result;
                    e_out_write_pc_enable <= '0';
                    e_out_write_reg_enable <= '1';
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '0';
                WHEN JUMP_EXEC_CODE =>
                    -- write linked register
                    e_out_result <= shift_right(signed(pc_4), 2);
                    e_out_write_reg_enable <= '1';
                    -- jump (by setting pc)
                    e_out_computed_pc <= unsigned(signed(pc_4) + shift_left(e_in_immediate, 2));
                    e_out_write_pc_enable <= '1';
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '0';
                WHEN BRANCH_EXEC_CODE =>
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '0';
                    CASE in_alu_main_func IS
                        WHEN "000" =>
                            IF e_in_data_1 = e_in_data_2 THEN
                                branch;
                            END IF;
                        WHEN "001" =>
                            IF e_in_data_1 /= e_in_data_2 THEN
                                branch;
                            END IF;
                        WHEN "100" =>
                            IF e_in_data_1 < e_in_data_2 THEN
                                branch;
                            END IF;
                        WHEN "101" =>
                            IF e_in_data_1 >= e_in_data_2 THEN
                                branch;
                            END IF;
                        WHEN "110" =>
                            IF unsigned(e_in_data_1) < unsigned(e_in_data_2) THEN
                                branch;
                            END IF;
                        WHEN "111" =>
                            IF unsigned(e_in_data_1) >= unsigned(e_in_data_2) THEN
                                branch;
                            END IF;
                        WHEN OTHERS => NULL;
                    END CASE;

                WHEN JUMP_REGISTER_EXEC_CODE =>
                    -- write linked register
                    e_out_result <= shift_right(signed(pc_4), 2);
                    e_out_write_reg_enable <= '1';
                    -- jump (by setting pc)
                    e_out_computed_pc <= unsigned(shift_left(e_in_data_1, 2) + shift_left(e_in_immediate, 2));
                    e_out_write_pc_enable <= '1';
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '0';

                WHEN LOAD_EXEC_CODE =>
                    e_out_memory_addr <= std_logic_vector(e_in_data_1 + e_in_immediate);
                    e_out_read_memory_enable <= '1';
                    e_out_write_memory_enable <= '0';

                WHEN STORE_EXEC_CODE =>
                    e_out_memory_addr <= std_logic_vector(e_in_data_1 + e_in_immediate);
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '1';
                    e_out_result <= e_in_data_2;

                WHEN ADD_TO_PC_EXEC_CODE =>
                    e_out_result <= signed(unsigned(e_in_pc) + unsigned(e_in_immediate)); -- TODO: check if this really works correctly
                    e_out_write_pc_enable <= '0';
                    e_out_write_reg_enable <= '1';
                    e_out_read_memory_enable <= '0';
                    e_out_write_memory_enable <= '0';
                WHEN OTHERS => NULL;
            END CASE;
        ELSE
            NULL;
        END IF;
    END PROCESS;
END ARCHITECTURE;