import re
from lark import Lark, Token
import asm_parser
import json


def tcomplement12(a: int):
    if (a < 0):
        temp = int(bin(int(a))[3:], 2) ^ int('111111111111', 2)
        return f'{temp+1:12b}'
    else:
        return f'{int(a):012b}'


def tcomplement5(a: int):
    if (a < 0):
        temp = int(bin(int(a))[3:], 2) ^ int('11111', 2)
        return f'{temp+1:5b}'
    else:
        return f'{int(a):05b}'


def tcomplement20(a: int):
    if (a < 0):
        temp = int(bin(int(a))[3:], 2) ^ int('11111111111111111111', 2)
        return f'{temp+1:20b}'
    else:
        return f'{int(a):020b}'


typeDictionary = {
    # ---------------------R_Type-------------------------#
    'ADD': 'r',
    'SUB': 'r',
    'SLL': 'r',
    'SLT': 'r',
    'SLTU': 'r',
    'XOR': 'r',
    'SRL': 'r',
    'SRA': 'r',
    'OR': 'r',
    'AND': 'r',
    # ---------------------P_Type-------------------------#
    'NOP': 'p',
    # ---------------------I_Type-------------------------#
    'ADDI': 'i',
    'SLTI': 'i',
    'SLTIU': 'i',
    'XORI': 'i',
    'ORI': 'i',
    'ANDI': 'i',

    'SLLI': 'is',
    'SRLI': 'is',
    'SRAI': 'is',

    'LB': 'i',
    'LH': 'i',
    'LW': 'i',
    'LBU': 'i',
    'LHU': 'i',

    'JALR': 'i',
    # ---------------------S_Type-------------------------#
    'SB': 's',
    'SH': 's',
    'SW': 's',
    # ---------------------B_Type-------------------------#
    'BEQ': 'b',
    'BNE': 'b',
    'BLT': 'b',
    'BGE': 'b',
    'BLTU': 'b',
    'BGEU': 'b',
    # ---------------------J_Type-------------------------#
    'JAL': 'ju',
    # ---------------------U_Type-------------------------#
    'LUI': 'ju',
    'AUIPC': 'ju',
}
opDictionary = {
    # ---------------------R_Type-------------------------#
    'ADD': ['0000000', 'rs2', 'rs1', '000', 'rd', '0110011'],
    'SUB': ['0100000', 'rs2', 'rs1', '000', 'rd', '0110011'],
    'SLL': ['0000000', 'rs2', 'rs1', '001', 'rd', '0110011'],
    'SLT': ['0000000', 'rs2', 'rs1', '010', 'rd', '0110011'],
    'SLTU': ['0000000', 'rs2', 'rs1', '011', 'rd', '0110011'],
    'XOR': ['0000000', 'rs2', 'rs1', '100', 'rd', '0110011'],
    'SRL': ['0000000', 'rs2', 'rs1', '101', 'rd', '0110011'],
    'SRA': ['0100000', 'rs2', 'rs1', '101', 'rd', '0110011'],
    'OR': ['0000000', 'rs2', 'rs1', '110', 'rd', '0110011'],
    'AND': ['0000000', 'rs2', 'rs1', '111', 'rd', '0110011'],
    # ---------------------P_Type-------------------------#
    'NOP': ['000000000000', '00000', '000', '00000', '0110011'],
    # ---------------------I_Type-------------------------#
    'ADDI': ['imm12', 'rs1', '000', 'rd', '0010011'],
    'SLTI': ['imm12', 'rs1', '010', 'rd', '0010011'],
    'SLTIU': ['imm12', 'rs1', '011', 'rd', '0010011'],
    'XORI': ['imm12', 'rs1', '100', 'rd', '0010011'],
    'ORI': ['imm12', 'rs1', '110', 'rd', '0010011'],
    'ANDI': ['imm12', 'rs1', '111', 'rd', '0010011'],

    'LB': ['imm12', 'rs1', '000', 'rd', '0000011'],
    'LH': ['imm12', 'rs1', '001', 'rd', '0000011'],
    'LW': ['imm12', 'rs1', '010', 'rd', '0000011'],
    'LBU': ['imm12', 'rs1', '100', 'rd', '0000011'],
    'LHU': ['imm12', 'rs1', '101', 'rd', '0000011'],

    'JALR': ['imm', 'rs1', '000', 'rd', '1100111'],
    # ---------------------Is_Type-------------------------#
    'SLLI': ['0000000', 'shamt', 'rs1', '001', 'rd', '0010011'],
    'SRLI': ['0000000', 'shamt', 'rs1', '101', 'rd', '0010011'],
    'SRAI': ['0100000', 'shamt', 'rs1', '101', 'rd', '0010011'],
    # ---------------------S_Type-------------------------#
    'SB': ['imm_high7', 'rs2', 'rs1', '000', 'imm_low5', '0100011'],
    'SH': ['imm_high7', 'rs2', 'rs1', '001', 'imm_low5', '0100011'],
    'SW': ['imm_high7', 'rs2', 'rs1', '010', 'imm_low5', '0100011'],
    # ---------------------B_Type-------------------------#
    'BEQ': ['imm_high7', 'rs2', 'rs1', '000', 'imm_low5', '1100011'],
    'BNE': ['imm_high7', 'rs2', 'rs1', '001', 'imm_low5', '1100011'],
    'BLT': ['imm_high7', 'rs2', 'rs1', '100', 'imm_low5', '1100011'],
    'BGE': ['imm_high7', 'rs2', 'rs1', '101', 'imm_low5', '1100011'],
    'BLTU': ['imm_high7', 'rs2', 'rs1', '110', 'imm_low5', '1100011'],
    'BGEU': ['imm_high7', 'rs2', 'rs1', '111', 'imm_low5', '1100011'],
    # ---------------------J_Type-------------------------#
    'JAL': ['imm20', 'rd', '1101111'],
    # ---------------------U_Type-------------------------#
    'LUI': ['imm20', 'rd', '1101111'],
    'AUIPC': ['imm20', 'rd', '1101111'],
}
registers = {
    'x0': 0,
    'x1': 1,
    'x2': 2,
    'x3': 3,
    'x4': 4,
    'x5': 5,
    'x6': 6,
    'x7': 7,
    'x8': 8,
    'x9': 9,
    'x10': 10,
    'x11': 11,
    'x12': 12,
    'x13': 13,
    'x14': 14,
    'x15': 15,
    'x16': 16,
    'x17': 17,
    'x18': 18,
    'x21': 21,
    'x19': 19,
    'x20': 20,
    'x22': 22,
    'x23': 23,
    'x24': 24,
    'x25': 25,
    'x26': 26,
    'x27': 27,
    'x28': 28,
    'x29': 29,
    'x30': 30,
    'x31': 31,
    'zero': 0,

    'ra': 1,
    'sp': 2,
    'gp': 3,
    'tp': 4,
    'fp': 8,

    'a0': 10,
    'a1': 11,
    'a2': 12,
    'a3': 13,
    'a4': 14,
    'a5': 15,
    'a6': 16,
    'a7': 17,

    's0': 8,
    's1': 9,
    's2': 18,
    's3': 19,
    's4': 20,
    's5': 21,
    's6': 22,
    's7': 23,
    's8': 24,
    's9': 25,
    's10': 26,
    's11': 27,

    't0': 5,
    't1': 6,
    't2': 7,
    't3': 28,
    't4': 29,
    't5': 30,
    't6': 31,


}
file = open("software/assembler/testAssembly.txt", "r")
tree = asm_parser.createTree(file.read())
for token in tree.scan_values(lambda v: isinstance(v, Token)):
    print(token.value)
print(json.dumps(tree))
file_content = ''
program = ''
count = 0
for x in file:
    file_content += ''.join(x)
list = file_content.replace("\n", "").split(';')
print(list)
for x in list:
    split_x = re.split(',| ', x)
    mnemonic = split_x[0]
    params = split_x[1:]
    raw_instruction = opDictionary[mnemonic]
    match typeDictionary[mnemonic]:
        case 'r':
          # ['0000000','rs2','rs1','000','rd','0110011']#maschinecode#
          # mem[0] rd[1], rs1[2], rs2[3] #memonic#
            raw_instruction[4] = f'{int(params[0]):05b}'  # replace rd
            raw_instruction[2] = f'{int(params[1]):05b}'  # replace rs1
            raw_instruction[1] = f'{int(params[2]):05b}'  # replace rs2
        case 'i':
          # ['imm12','rs1','000','rd','0110011'] #maschinecode#
          # mem[0] rd[1], rs1[2], imm[3] #memonic#
            raw_instruction[0] = tcomplement12(int(params[2]))
            raw_instruction[1] = f'{int(params[1]):05b}'
            raw_instruction[3] = f'{int(params[0]):05b}'
        case 'is':
            # ['0000000','shamt','rs1','001','rd','0110011'], #maschinecode#
            # mem[0] rd[1], rs1[2], shamt[3] #memonic#
            raw_instruction[2] = f'{int(params[1]):05b}'  # rs1
            raw_instruction[1] = tcomplement5(int(params[2]))  # shamt
            raw_instruction[4] = f'{int(params[0]):05b}'  # rd
        case 's':
            # ['imm_high7','rs2','rs1','000','imm_low5','0100011'],#maschinecode
            # mem[0] rs1[1], rs2[2], imm12[3] #memonic#
            imm12 = tcomplement12(int(params[2]))
            raw_instruction[0] = imm12[0:7]  # imm_high7
            raw_instruction[4] = imm12[7:12]  # imm_low5
            raw_instruction[1] = f'{int(params[1]):05b}'  # rs2
            raw_instruction[2] = f'{int(params[0]):05b}'  # rs1
        case 'b':
            # ['imm_high7','rs2','rs1','000','imm_low5','1100011'],
            # mem[0] rs1[1], rs2[2], imm[3] #memonic#
            imm12 = tcomplement12(int(params[2]))
            raw_instruction[0] = imm12[0:7]  # imm_high7
            raw_instruction[4] = imm12[7:12]  # imm_low5
            raw_instruction[1] = f'{int(params[1]):05b}'  # rs2
            raw_instruction[2] = f'{int(params[0]):05b}'  # rs1
        case 'ju':
            # ['imm20','rd','1101111'],
            # mem[0] rd[1], imm20[2] #memonic#
            raw_instruction[0] = tcomplement20(int(params[1]))
            raw_instruction[1] = f'{int(params[0]):05b}'
    program += ''.join(str(count) + '=>' + "b\"")
    count = count + 1
    for i in raw_instruction:
        if i != raw_instruction[len(raw_instruction)-1]:
            program += ''.join(i+"_")
        else:
            program = program + ''.join(i)
    if x != list[len(list)-1]:
        program += ''.join("\", \n")
    else:
        program += ''.join("\",")
print(program)
print("others => NOP_INSTRUCTION")
print()
