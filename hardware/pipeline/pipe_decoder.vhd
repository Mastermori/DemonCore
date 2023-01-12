LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_decoder IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        d_in_instruction : IN instruction32;
        d_reg_addr_1, d_reg_addr_2, d_reg_addr_dest : OUT register_adress;
        d_out_register_read : OUT STD_LOGIC;
        d_out_read_memory : OUT STD_LOGIC;
        d_out_immediate : OUT signed(31 DOWNTO 0);
        d_out_use_immediate : OUT STD_LOGIC;
        d_out_main_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        d_out_second_func : OUT STD_LOGIC;
        d_out_exec_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- Noch unklar, wie viele bits ben�tigt werden
        -- Durchreiche Werte
        d_in_pc : IN unsigned(31 DOWNTO 0);
        d_out_pc : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_decoder_dummy OF pipe_decoder IS
BEGIN
    PROCESS (clk, reset)
        VARIABLE d_opcode : opcode;
        VARIABLE internal_immediate : signed(31 DOWNTO 0);
    BEGIN
        IF (reset = '0') THEN
            d_reg_addr_1 <= (OTHERS => '0');
            d_reg_addr_2 <= (OTHERS => '0');
            d_reg_addr_dest <= (OTHERS => '0');
            d_out_register_read <= '0';
            d_out_immediate <= (OTHERS => '0');
            d_out_pc <= (OTHERS => '0');
            d_out_use_immediate <= '0';
            d_out_second_func <= '0';
            d_out_main_func <= "000";
            d_out_exec_func <= LOGIC_ARITHMETIC_EXEC_CODE;
            d_out_read_memory <= '0';
        ELSIF (rising_edge(clk)) THEN
            --d_reg_addr_1 <= (OTHERS => '-');
            --d_reg_addr_2 <= (OTHERS => '-');
            --d_reg_addr_dest <= (OTHERS => '-');
            --d_out_register_read <= '-';
            --d_out_read_memory <= '-';
            --d_out_use_immediate <= '-';
            --d_out_main_func <= (OTHERS => '-');
            --d_out_second_func <= '-';
            --d_out_exec_func <= (OTHERS => '-');
            --d_out_pc <= (OTHERS => '-');
            d_opcode := d_in_instruction(6 DOWNTO 0);
            CASE (d_opcode) IS
                WHEN REGISTER_ARITHMETIC_OPCODES => --R layout
                    d_out_second_func <= d_in_instruction(30); -- es wird immer nur das zweite bit von rechts gebraucht, siehe Instruction-Tabelle.
                    d_reg_addr_2 <= d_in_instruction(24 DOWNTO 20);
                    d_reg_addr_1 <= d_in_instruction(19 DOWNTO 15);
                    d_out_main_func <= d_in_instruction(14 DOWNTO 12);
                    d_reg_addr_dest <= d_in_instruction(11 DOWNTO 7);
                    -- control flags
                    d_out_use_immediate <= '0';
                    d_out_register_read <= '1';
                    d_out_read_memory <= '0';
                    d_out_exec_func <= LOGIC_ARITHMETIC_EXEC_CODE;

                WHEN LOADS_OPCODE | IMMEDIATE_ARITHMETIC_OPCODE | JUMP_AND_LINK_REGISTER_OPCODE => --I layout
                    d_out_immediate <= resize(signed(d_in_instruction(31 DOWNTO 20)), d_out_immediate'length);
                    d_reg_addr_1 <= d_in_instruction(19 DOWNTO 15);
                    --reg_addr_2 <= instruction(24 DOWNTO 20);
                    d_out_main_func <= d_in_instruction(14 DOWNTO 12);
                    d_reg_addr_dest <= d_in_instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func <= '0';
                    -- control flags
                    d_out_register_read <= '1';
                    IF d_opcode = LOADS_OPCODE THEN
                        d_out_use_immediate <= '0';
                        d_out_read_memory <= '1';
                        d_out_exec_func <= LOAD_EXEC_CODE;
                    ELSIF d_opcode = IMMEDIATE_ARITHMETIC_OPCODE THEN
                        d_out_use_immediate <= '1';
                        d_out_read_memory <= '0';
                        d_out_exec_func <= LOGIC_ARITHMETIC_EXEC_CODE;
                    ELSE
                        d_out_use_immediate <= '0';
                        d_out_read_memory <= '0';
                        d_out_exec_func <= JUMP_REGISTER_EXEC_CODE;
                    END IF;

                WHEN STORE_OPCODE => --S layout
                    internal_immediate(11 DOWNTO 5) := signed(d_in_instruction(31 DOWNTO 25)); --TODO: fix sign extension
                    d_reg_addr_1 <= d_in_instruction(24 DOWNTO 20);
                    d_reg_addr_2 <= d_in_instruction(19 DOWNTO 15);
                    d_out_main_func <= d_in_instruction(14 DOWNTO 12);
                    internal_immediate(4 DOWNTO 0) := signed(d_in_instruction(11 DOWNTO 7));
                    d_out_immediate <= resize(internal_immediate(11 DOWNTO 0), d_out_immediate'length);
                    -- overwrite flags
                    d_out_second_func <= '0';
                    -- control flags
                    d_out_use_immediate <= '0';
                    d_out_register_read <= '1';
                    d_out_read_memory <= '0';
                    d_out_exec_func <= STORE_EXEC_CODE;

                WHEN BRANCHES_OPCODE => --B layout
                    internal_immediate(13 DOWNTO 7) := signed(d_in_instruction(31 DOWNTO 25));
                    --internal_immediate(10 DOWNTO 5) := signed(d_in_instruction(30 DOWNTO 25));
                    d_reg_addr_1 <= d_in_instruction(24 DOWNTO 20);
                    d_reg_addr_2 <= d_in_instruction(19 DOWNTO 15);
                    d_out_main_func <= d_in_instruction(14 DOWNTO 12);
                    internal_immediate(6 DOWNTO 2) := signed(d_in_instruction(11 DOWNTO 7));
                    --internal_immediate(11)          := d_in_instruction(7);
                    internal_immediate(1 DOWNTO 0) := (OTHERS => '0');
                    d_out_immediate <= resize(internal_immediate(13 DOWNTO 0), d_out_immediate'length); -- sign extension
                    -- overwrite flags
                    d_out_second_func <= '0';
                    -- control flags
                    d_out_use_immediate <= '0';
                    d_out_register_read <= '1';
                    d_out_read_memory <= '0';
                    d_out_exec_func <= BRANCH_EXEC_CODE;

                WHEN LOAD_UPPER_IMMEDIATE_OPCODE | LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE => --U layout
                    d_out_immediate(31 DOWNTO 12) <= signed(d_in_instruction(31 DOWNTO 12));
                    d_out_immediate(11 DOWNTO 0) <= (OTHERS => '0');
                    d_reg_addr_dest <= d_in_instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func <= '0';
                    -- control flags
                    d_out_read_memory <= '0';
                    IF d_opcode = LOAD_UPPER_IMMEDIATE_OPCODE THEN
                        d_out_exec_func <= LOGIC_ARITHMETIC_EXEC_CODE;
                        d_out_use_immediate <= '1';
                        d_out_main_func <= "000";
                    ELSE
                        d_out_exec_func <= ADD_TO_PC_EXEC_CODE;
                        d_out_use_immediate <= '0';
                    END IF;
                    -- TODO: control_enables

                WHEN JUMP_AND_LINK_OPCODE => --J layout
                    --internal_immediate(31 downto 21) := (others => '0');
                    internal_immediate(21 DOWNTO 2) := signed(d_in_instruction(31 DOWNTO 12));
                    --internal_immediate(10 DOWNTO 1)  := signed(d_in_instruction(30 DOWNTO 21));
                    --internal_immediate(11)           := d_in_instruction(20);
                    --internal_immediate(19 DOWNTO 12) := signed(d_in_instruction(19 DOWNTO 12));
                    internal_immediate(1 DOWNTO 0) := (OTHERS => '0');
                    d_out_immediate <= resize(internal_immediate(21 DOWNTO 0), d_out_immediate'length); -- sign extension
                    d_reg_addr_dest <= d_in_instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func <= '0';
                    -- control flags
                    d_out_use_immediate <= '0';
                    d_out_read_memory <= '0';
                    d_out_exec_func <= JUMP_EXEC_CODE;
                    -- TODO: control_enables

                WHEN OTHERS => --Ung�ltiger opcode
                    -- TODO: find out what to do

            END CASE;

            d_out_pc <= d_in_pc;
        END IF;
    END PROCESS;

END pipe_decoder_dummy; -- pipe_fetch_dummy