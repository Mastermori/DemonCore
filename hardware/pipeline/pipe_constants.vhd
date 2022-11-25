LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE pipe_constants IS

    SUBTYPE instruction32 IS STD_LOGIC_VECTOR(31 DOWNTO 0);
    SUBTYPE opcode IS STD_LOGIC_VECTOR(6 DOWNTO 0);

    CONSTANT NOP_INSTRUCTION : instruction32 := "00000000" & "00000000" & "00000000" & "00010011";
    CONSTANT BRANCHES_OPCODE : opcode := "1100011";
    CONSTANT LOADS_OPCODE : opcode := "0000011";
    CONSTANT IMMEDIATE_ARITHMETIC_OPCODE : opcode := "0010011";
    CONSTANT LOAD_UPPER_IMMEDIATE_OPCODE : opcode := "0110111";
    CONSTANT LOAD_UPPER_IMMEDIATE_TO_PC_OPCODE : opcode := "0010111";
    CONSTANT JUMP_AND_LINK_OPCODE : opcode := "1101111";
    CONSTANT JUMP_AND_LINK_REGISTER_OPCODE : opcode := "1100111";
    CONSTANT SAVES_OPCODE : opcode := "0100011";
    CONSTANT REGISTER_ARITHMETIC_OPCODES : opcode := "0110011";

END pipe_constants;

-- PACKAGE BODY pipe_constants IS

-- END pipe_constants;