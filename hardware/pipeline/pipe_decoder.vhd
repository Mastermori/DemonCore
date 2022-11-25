LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;

-- Immer vor in Betriebnahme ein reset!

ENTITY pipe_decoder IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        instruction : IN instruction32;

        reg_addr_1, reg_addr_2, reg_addr_dest : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        control_enables : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        register_read : OUT STD_LOGIC;
        immediate : OUT signed(31 DOWNTO 0);
        upper_immediate : OUT signed(31 DOWNTO 0);

        -- Durchreiche Werte
        pc : IN unsigned(31 DOWNTO 0);
        pc_4 : IN unsigned(31 DOWNTO 0);
        reg_pc : OUT unsigned(31 DOWNTO 0);
        reg_pc_4 : OUT unsigned(31 DOWNTO 0)
    );
END;

ARCHITECTURE pipe_decoder_dummy OF pipe_decoder IS
    SIGNAL opcode : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL funct3 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL funct7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            reg_addr_1 <= x"0000_0000";
            reg_addr_2 <= x"0000_0000";
            reg_addr_dest <= x"0000_0000";
            control_enables <= "0000000";
            register_read <= "0";
            immediate <= 0;
            upper_immediate <= 0;
            reg_pc <= 0;
            reg_pc_4 <= 0;
        ELSIF (rising_edge(clk)) THEN
            opcode <= instruction(6 DOWNTO 0);
            CASE(opcode) IS

                WHEN REGISTER_ARITHMETIC_OPCODES => --R layout
                funct7 <= instruction(31 DOWNTO 25);
                reg_addr_2 <= instruction(24 DOWNTO 20);
                reg_addr_1 <= instruction(19 DOWNTO 15);
                funct3 <= instruction(14 DOWNTO 12);
                reg_addr_dest <= instruction(11 DOWNTO 7);

                WHEN LOADS_OPCODE | IMMEDIATE_ARITHMETIC_OPCODE => --I layout
                immediate <= instruction(31 DOWNTO 20);
                reg_addr_1 <= instruction(19 DOWNTO 15);
                funct3 <= instruction(14 DOWNTO 12);
                reg_addr_dest <= instruction(11 DOWNTO 7);

                WHEN SAVES_OPCODE => --S layout
                immediate(11 DOWNTO 5) <= instruction(31 DOWNTO 25);
                reg_addr_1 <= instruction(24 DOWNTO 20);
                reg_addr_2 <= instruction(19 DOWNTO 15);
                funct3 <= instruction(14 DOWNTO 12);
                immediate(4 DOWNTO 0) <= instruction(11 DOWNTO 7);

                WHEN BRANCHES_OPCODE => --B layout
                immediate(12) <= instruction(31);
                immediate(10 DOWNTO 5) <= instruction(30 DOWNTO 25);
                reg_addr_1 <= instruction(24 DOWNTO 20);
                reg_addr_2 <= instruction(19 DOWNTO 15);
                funct3 <= instruction(14 DOWNTO 12);
                immediate(4 DOWNTO 1) <= instruction(11 DOWNTO 8);
                immediate(11) <= instruction(8);

                WHEN LOAD_UPPER_IMMEDIATE_OPCODE | LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE => --U layout
                upper_immediate <= instruction(31 DOWNTO 12);
                reg_addr_dest <= instruction(11 DOWNTO 7);
                -- TODO: control_enables

                WHEN JUMP_AND_LINK_OPCODE | JUMP_AND_LINK_REGISTER_OPCODE => --J layout
                immediate(20) <= instruction(31);
                immediate(10 DOWNTO 1) <= instruction(30 DOWNTO 21);
                immediate(11) <= instruction(20);
                immediate(19 DOWNTO 12) <= instruction(19 DOWNTO 12);
                reg_addr_dest <= instruction(11 DOWNTO 7);
                -- TODO: control_enables

                WHEN OTHERS => --Ungültiger opcode
                -- TODO: find out what to do

            END CASE;

            reg_pc <= pc;
            reg_pc_4 <= pc_4;
        END IF;
    END PROCESS;

    function_decoder : PROCESS (funct3, funct7)
    BEGIN
        -- TODO: implement
    END PROCESS; -- function_decoder

END pipe_decoder_dummy; -- pipe_fetch_dummy