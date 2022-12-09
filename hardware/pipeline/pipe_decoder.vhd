LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_decoder IS
    PORT(
        clk                                      : IN  STD_LOGIC;
        reset                                    : IN  STD_LOGIC;
        instruction                              : IN  instruction32;
        d_regaddr_1, d_regaddr_2, d_regaddr_dest : OUT register_adress;
        d_out_register_read                      : OUT STD_LOGIC;
        immediate                                : OUT signed(31 DOWNTO 0);
        upper_immediate                          : OUT signed(31 DOWNTO 0);
        d_out_use_immediate                      : OUT std_logic;
        d_out_main_func                          : OUT std_logic_vector(2 downto 0);
        d_out_second_func                        : OUT std_logic;
        d_out_exec_func                          : OUT std_logic_vector(2 downto 0); -- Noch unklar, wie viele bits benötigt werden
        -- Durchreiche Werte
        d_in_pc                                  : IN  unsigned(31 DOWNTO 0);
        d_out_pc                                 : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_decoder_dummy OF pipe_decoder IS
    SIGNAL internal_immediate : signed(31 downto 0);
BEGIN
    PROCESS(clk, reset)
        variable d_opcode : opcode;
    BEGIN
        IF (reset = '0') THEN
            d_regaddr_1         <= (others => '0');
            d_regaddr_2         <= (others => '0');
            d_regaddr_dest      <= (others => '0');
            d_out_register_read <= '0';
            immediate           <= (others => '0');
            upper_immediate     <= (others => '0');
            d_out_pc            <= to_unsigned(0, 32);
            d_out_use_immediate <= '0';
            d_out_second_func   <= '0';
            d_out_main_func     <= "000";
            d_out_exec_func     <= "000";
        ELSIF (rising_edge(clk)) THEN
            d_opcode := instruction(6 DOWNTO 0);

            CASE (d_opcode) IS

                WHEN REGISTER_ARITHMETIC_OPCODES => --R layout
                    d_out_second_func   <= instruction(30); -- es wird immer nur das zweite bit von rechts gebraucht, siehe Instruction-Tabelle.
                    d_regaddr_2         <= instruction(24 DOWNTO 20);
                    d_regaddr_1         <= instruction(19 DOWNTO 15);
                    d_out_main_func     <= instruction(14 DOWNTO 12);
                    d_regaddr_dest      <= instruction(11 DOWNTO 7);
                    -- control flags
                    d_out_use_immediate <= '0';
                    d_out_register_read <= '1';

                WHEN LOADS_OPCODE | IMMEDIATE_ARITHMETIC_OPCODE | JUMP_AND_LINK_REGISTER_OPCODE => --I layout
                    immediate           <= resize(signed(instruction(31 DOWNTO 20)), immediate'length); --TODO: fix sign extension
                    d_regaddr_1         <= instruction(19 DOWNTO 15);
                    --reg_addr_2 <= instruction(24 DOWNTO 20);
                    d_out_main_func     <= instruction(14 DOWNTO 12);
                    d_regaddr_dest      <= instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func   <= '0';
                    -- control flags
                    d_out_use_immediate <= '1';
                    d_out_register_read <= '1';

                WHEN SAVES_OPCODE =>    --S layout
                    internal_immediate(11 DOWNTO 5) <= signed(instruction(31 DOWNTO 25)); --TODO: fix sign extension
                    d_regaddr_1                     <= instruction(24 DOWNTO 20);
                    d_regaddr_2                     <= instruction(19 DOWNTO 15);
                    d_out_main_func                 <= instruction(14 DOWNTO 12);
                    internal_immediate(4 DOWNTO 0)  <= signed(instruction(11 DOWNTO 7));
                    immediate                       <= resize(internal_immediate, immediate'length);
                    -- overwrite flags
                    d_out_second_func               <= '0';
                    -- control flags
                    d_out_use_immediate             <= '1';
                    d_out_register_read             <= '1';

                WHEN BRANCHES_OPCODE => --B layout
                    internal_immediate(12)          <= instruction(31);
                    internal_immediate(10 DOWNTO 5) <= signed(instruction(30 DOWNTO 25));
                    d_regaddr_1                     <= instruction(24 DOWNTO 20);
                    d_regaddr_2                     <= instruction(19 DOWNTO 15);
                    d_out_main_func                 <= instruction(14 DOWNTO 12);
                    internal_immediate(4 DOWNTO 1)  <= signed(instruction(11 DOWNTO 8));
                    internal_immediate(11)          <= instruction(8);
                    internal_immediate(0)           <= '0';
                    immediate                       <= resize(internal_immediate, immediate'length); -- sign extension
                    -- overwrite flags
                    d_out_second_func               <= '0';
                    -- control flags
                    d_out_use_immediate             <= '1';
                    d_out_register_read             <= '1';

                WHEN LOAD_UPPER_IMMEDIATE_OPCODE | LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE => --U layout
                    upper_immediate(31 downto 12) <= signed(instruction(31 DOWNTO 12));
                    upper_immediate(11 downto 0)  <= (others => '0');
                    d_regaddr_dest                <= instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func             <= '0';
                    -- control flags
                    d_out_use_immediate           <= '1';
                -- TODO: control_enables

                WHEN JUMP_AND_LINK_OPCODE => --J layout
                    internal_immediate(20)           <= instruction(31);
                    internal_immediate(10 DOWNTO 1)  <= signed(instruction(30 DOWNTO 21));
                    internal_immediate(11)           <= instruction(20);
                    internal_immediate(19 DOWNTO 12) <= signed(instruction(19 DOWNTO 12));
                    internal_immediate(0)            <= '0';
                    immediate                        <= resize(internal_immediate, immediate'length); -- sign extension
                    d_regaddr_dest                   <= instruction(11 DOWNTO 7);
                    -- overwrite flags
                    d_out_second_func                <= '0';
                    -- control flags
                    d_out_use_immediate              <= '1';
                -- TODO: control_enables

                WHEN OTHERS =>          --UngÃ¼ltiger opcode
                    -- TODO: find out what to do

            END CASE;

            d_out_pc <= d_in_pc;
        END IF;
    END PROCESS;

END pipe_decoder_dummy;                 -- pipe_fetch_dummy