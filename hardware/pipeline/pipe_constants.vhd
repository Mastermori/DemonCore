LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE pipe_constants IS

    SUBTYPE instruction32 IS STD_LOGIC_VECTOR(31 DOWNTO 0);
    SUBTYPE opcode IS STD_LOGIC_VECTOR(6 DOWNTO 0);
    SUBTYPE word IS std_logic_vector(31 DOWNTO 0);
    SUBTYPE signedNumber IS signed(31 DOWNTO 0);
    SUBTYPE register_adress IS STD_LOGIC_VECTOR(4 DOWNTO 0);
    SUBTYPE exec_code IS std_logic_vector(2 downto 0);

    -- instructions
    CONSTANT NOP_INSTRUCTION               : instruction32 := b"0000000_00000_00000_000_00000_0010011"; --addi x0, x0, 0
    CONSTANT ADDI_ONE_INSTRUCTION          : instruction32 := b"000000000001_00001_000_00001_0010011"; --addi x1, x1, 1;
    CONSTANT ADDI_NEGATIVE_ONE_INSTRUCTION : instruction32 := b"111111111111_00001_000_00001_0010011"; --addi x1, x1, -1;
    CONSTANT AUIPC_INSTRUCTION             : instruction32 := b"00000000000000000001_00010_0010111"; --auipc x2, 1; 
    CONSTANT LUI_INSTRUCTION               : instruction32 := b"00000000000000000001_00011_0110111"; --lui x3, 1;
    CONSTANT JAL_INSTRUCTION               : instruction32 := b"00000000000000000101_00100_1101111"; --jal x4, 5;
    CONSTANT JALR_INSTRUCTION              : instruction32 := b"000000000001_00101_000_00100_1100111"; --jalr x4, 1;
    CONSTANT BNEQ_INSTRUCTION              : instruction32 := b"1111111_00101_00001_001_11011_1100011"; --bneq x1, x5, 1;

    -- words
    CONSTANT ZERO_WORD : word := (others => '0');

    -- opcodes
    CONSTANT BRANCHES_OPCODE                   : opcode := b"1100011";
    CONSTANT LOADS_OPCODE                      : opcode := b"0000011";
    CONSTANT IMMEDIATE_ARITHMETIC_OPCODE       : opcode := b"0010011";
    CONSTANT LOAD_UPPER_IMMEDIATE_OPCODE       : opcode := b"0110111";
    CONSTANT LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE : opcode := b"0010111";
    CONSTANT JUMP_AND_LINK_OPCODE              : opcode := b"1101111";
    CONSTANT JUMP_AND_LINK_REGISTER_OPCODE     : opcode := b"1100111";
    CONSTANT STORE_OPCODE                      : opcode := b"0100011";
    CONSTANT REGISTER_ARITHMETIC_OPCODES       : opcode := b"0110011";

    -- execute codes (internal codes for execute multiplexer)
    CONSTANT LOGIC_ARITHMETIC_EXEC_CODE : exec_code := b"000";
    CONSTANT JUMP_EXEC_CODE             : exec_code := b"001";
    CONSTANT JUMP_REGISTER_EXEC_CODE    : exec_code := b"010";
    CONSTANT BRANCH_EXEC_CODE           : exec_code := b"011";
    CONSTANT LOAD_EXEC_CODE             : exec_code := b"100";
    CONSTANT STORE_EXEC_CODE            : exec_code := b"101";
    CONSTANT ADD_TO_PC_EXEC_CODE        : exec_code := b"110";

END pipe_constants;

-- PACKAGE BODY pipe_constants IS

-- END pipe_constants;