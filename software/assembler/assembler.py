import re
from lark import Lark, Token
import asm_parser
import json
from dictionarys import *
from util import *

def main():
    file = open("software/assembler/testAssembly.txt", "r")
    file_contents = file.read()
    reference_file = re.sub("\n+", "\n", file_contents)
    reference_file = re.sub("\n\s*\/\/.+", "", reference_file)
    reference_lines = reference_file.split("\n")
    print(len(reference_lines))
    print(reference_file)
    tree = asm_parser.createTree(file_contents)
    instruction_strings = []
    instruction_count = 0
    instruction_space_count_max = len(str(len(reference_lines)))
    for expression in tree.find_pred(lambda v: v.data == "expression"):
        param_count = int(get_subtree(expression, 1).data.replace("param_", ""))
        params = []
        for i in range(param_count):
            params.append(get_subtree(expression, 3, 1+i).value)
        mnemonic = get_subtree(expression, 4).value
        instruction_type = get_subtree(expression, 3).data
        instruction_format = get_subtree(expression, 2).data
        # print(params)
        # print(mnemonic)
        # print(instruction_format)
        raw_instruction = opDictionary[mnemonic.upper()]

        match instruction_format:
            case 'register_format':
            # ['0000000','rs2','rs1','000','rd','0110011']#maschinecode#
            # mem[0] rd[1], rs1[2], rs2[3] #memonic#
                raw_instruction[4] = register_lookup(params[0])  # replace rd
                raw_instruction[2] = register_lookup(params[1])  # replace rs1
                raw_instruction[1] = register_lookup(params[2])  # replace rs2
            case 'immediate_format':
            # ['imm12','rs1','000','rd','0110011'] #maschinecode#
            # mem[0] rd[1], rs1[2], imm[3] #memonic#
                raw_instruction[0] = two_complement(int(params[2]), 12)
                raw_instruction[1] = register_lookup(params[1])
                raw_instruction[3] = register_lookup(params[0])
            case 'shift_format':
                # ['0000000','shamt','rs1','001','rd','0110011'], #maschinecode#
                # mem[0] rd[1], rs1[2], shamt[3] #memonic#
                raw_instruction[2] = register_lookup(params[1])  # rs1
                raw_instruction[1] = two_complement(int(params[2]), 5)  # shamt
                raw_instruction[4] = register_lookup(params[0])  # rd
            case 'offset_format':
                match instruction_type:
                    case 'jl_type' | 'l_type':
                        raw_instruction[0] = two_complement(int(params[1]), 12)
                        raw_instruction[1] = register_lookup(params[2])
                        raw_instruction[3] = register_lookup(params[0])
                    case 's_type':
                        # ['imm_high7','rs2','rs1','000','imm_low5','0100011'],#maschinecode
                        # mem[0] rs1[1], imm12[2](rs2[3])  #memonic#
                        imm12 = two_complement(int(params[1]), 12)
                        raw_instruction[0] = imm12[0:7]  # imm_high7
                        raw_instruction[4] = imm12[7:12]  # imm_low5
                        raw_instruction[1] = register_lookup(params[2])  # rs2
                        raw_instruction[2] = register_lookup(params[0])  # rs1
            case 'branch_format':
                # ['imm_high7','rs2','rs1','000','imm_low5','1100011'],
                # mem[0] rs1[1], rs2[2], imm[3] #memonic#
                imm12 = two_complement(int(params[2]), 12)
                raw_instruction[0] = imm12[0:7]  # imm_high7
                raw_instruction[4] = imm12[7:12]  # imm_low5
                raw_instruction[1] = register_lookup(params[1])  # rs2
                raw_instruction[2] = register_lookup(params[0])  # rs1
            case 'jump_upper_format':
                # ['imm20','rd','1101111'],
                # mem[0] rd[1], imm20[2] #memonic#
                raw_instruction[0] = two_complement(int(params[1]), 20)
                raw_instruction[1] = register_lookup(params[0])
        print(instruction_count)
        number_spaces = ' '*(1+(instruction_space_count_max-len(str(instruction_count))))
        instruction_strings.append(str(instruction_count) + number_spaces + ''.join(raw_instruction) + "    --" + reference_lines[instruction_count])
        instruction_count += 1
    print("\n".join(instruction_strings))

if __name__ == "__main__":
    main()