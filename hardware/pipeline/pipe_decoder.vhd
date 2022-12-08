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
        control_enables                          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        logic_enable                             : OUT STD_LOGIC;
        alu_enable                               : OUT STD_LOGIC;
        add_sub_alu_code                         : OUT STD_LOGIC;
        register_read                            : OUT STD_LOGIC;
        immediate                                : OUT signed(31 DOWNTO 0);
        upper_immediate                          : OUT signed(31 DOWNTO 0);
        -- Durchreiche Werte
        d_in_pc                                  : IN  unsigned(31 DOWNTO 0);
        d_out_pc                                 : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_decoder_dummy OF pipe_decoder IS
    SIGNAL funct3             : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL funct7             : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL internal_immediate : signed(31 downto 0);
BEGIN
    PROCESS(clk, reset)
        variable d_opcode : opcode;
    BEGIN
        IF (reset = '0') THEN
            d_regaddr_1     <= (others => '0');
            d_regaddr_2     <= (others => '0');
            d_regaddr_dest  <= (others => '0');
            control_enables <= (others => '0');
            logic_enable    <= '0';
            register_read   <= '0';
            immediate       <= (others => '0');
            upper_immediate <= (others => '0');
            d_out_pc        <= to_unsigned(0, 32);
        ELSIF (rising_edge(clk)) THEN
            d_opcode := instruction(6 DOWNTO 0);

            CASE (d_opcode) IS

                WHEN REGISTER_ARITHMETIC_OPCODES => --R layout
                    funct7         <= instruction(31 DOWNTO 25);
                    d_regaddr_2    <= instruction(24 DOWNTO 20);
                    d_regaddr_1    <= instruction(19 DOWNTO 15);
                    funct3         <= instruction(14 DOWNTO 12);
                    d_regaddr_dest <= instruction(11 DOWNTO 7);

                WHEN LOADS_OPCODE | IMMEDIATE_ARITHMETIC_OPCODE | JUMP_AND_LINK_REGISTER_OPCODE => --I layout
                    immediate      <= resize(signed(instruction(31 DOWNTO 20)), immediate'length); --TODO: fix sign extension
                    d_regaddr_1    <= instruction(19 DOWNTO 15);
                    --reg_addr_2 <= instruction(24 DOWNTO 20);
                    funct3         <= instruction(14 DOWNTO 12);
                    d_regaddr_dest <= instruction(11 DOWNTO 7);

                WHEN SAVES_OPCODE =>    --S layout
                    internal_immediate(11 DOWNTO 5) <= signed(instruction(31 DOWNTO 25)); --TODO: fix sign extension
                    d_regaddr_1                     <= instruction(24 DOWNTO 20);
                    d_regaddr_2                     <= instruction(19 DOWNTO 15);
                    funct3                          <= instruction(14 DOWNTO 12);
                    internal_immediate(4 DOWNTO 0)  <= signed(instruction(11 DOWNTO 7));
                    immediate                       <= resize(internal_immediate, immediate'length);

                WHEN BRANCHES_OPCODE => --B layout
                    internal_immediate(12)          <= instruction(31);
                    internal_immediate(10 DOWNTO 5) <= signed(instruction(30 DOWNTO 25));
                    d_regaddr_1                     <= instruction(24 DOWNTO 20);
                    d_regaddr_2                     <= instruction(19 DOWNTO 15);
                    funct3                          <= instruction(14 DOWNTO 12);
                    internal_immediate(4 DOWNTO 1)  <= signed(instruction(11 DOWNTO 8));
                    internal_immediate(11)          <= instruction(8);
                    internal_immediate(0)           <= '0';
                    immediate                       <= resize(internal_immediate, immediate'length); -- sign extension

                WHEN LOAD_UPPER_IMMEDIATE_OPCODE | LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE => --U layout
                    upper_immediate(31 downto 12) <= signed(instruction(31 DOWNTO 12));
                    upper_immediate(11 downto 0)  <= (others => '0');
                    d_regaddr_dest                <= instruction(11 DOWNTO 7);
                -- TODO: control_enables

                WHEN JUMP_AND_LINK_OPCODE => --J layout
                    internal_immediate(20)           <= instruction(31);
                    internal_immediate(10 DOWNTO 1)  <= signed(instruction(30 DOWNTO 21));
                    internal_immediate(11)           <= instruction(20);
                    internal_immediate(19 DOWNTO 12) <= signed(instruction(19 DOWNTO 12));
                    internal_immediate(0)            <= '0';
                    immediate                        <= resize(internal_immediate, immediate'length); -- sign extension
                    d_regaddr_dest                   <= instruction(11 DOWNTO 7);
                -- TODO: control_enables

                WHEN OTHERS =>          --Ungültiger opcode
                    -- TODO: find out what to do

            END CASE;

            d_out_pc <= d_in_pc;
        END IF;
    END PROCESS;

    function_decoder : PROCESS(funct3, funct7)
    BEGIN
        add_sub_alu_code <= '0';
        alu_enable       <= '0';
        logic_enable     <= '0';
        CASE (funct3) IS
            WHEN "000" =>
                add_sub_alu_code <= funct7(5);
                alu_enable       <= '1';
            WHEN OTHERS =>
        END CASE;
    END PROCESS;                        -- function_decoder

END pipe_decoder_dummy;                 -- pipe_fetch_dummy