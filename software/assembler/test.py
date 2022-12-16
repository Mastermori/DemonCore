import re
typeDictionary = {
   #---------------------R_Type-------------------------#
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
   #---------------------P_Type-------------------------#
  'NOP': 'p',
  #---------------------I_Type-------------------------#
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
  #---------------------S_Type-------------------------#
  'SB': 's',
  'SH': 's',
  'SW': 's',
  #---------------------B_Type-------------------------#
  'BEQ': 'b',
  'BNE': 'b',
  'BLT': 'b',
  'BGE': 'b',
  'BLTU': 'b',
  'BGEU': 'b',
  #---------------------J_Type-------------------------#
  'JAL': 'ju',
  #---------------------U_Type-------------------------#
  'LUI': 'ju',
  'AUIPC': 'ju',
  }
opDictionary = {
  #---------------------R_Type-------------------------#
  'ADD': ['0000000','rs2','rs1','000','rd','0110011'],
  'SUB': ['0100000','rs2','rs1','000','rd','0110011'],
  'SLL': ['0000000','rs2','rs1','001','rd','0110011'],
  'SLT': ['0000000','rs2','rs1','010','rd','0110011'],
  'SLTU': ['0000000','rs2','rs1','011','rd','0110011'],
  'XOR': ['0000000','rs2','rs1','100','rd','0110011'],
  'SRL': ['0000000','rs2','rs1','101','rd','0110011'],
  'SRA': ['0100000','rs2','rs1','101','rd','0110011'],
  'OR': ['0000000','rs2','rs1','110','rd','0110011'],
  'AND': ['0000000','rs2','rs1','111','rd','0110011'],
  #---------------------P_Type-------------------------#
  'NOP': ['000000000000','00000','000','00000','0110011'],
  #---------------------I_Type-------------------------#
  'ADDI': ['imm12','rs1','000','rd','0110011'],
  'SLTI': ['imm12','rs1','010','rd','0110011'],
  'SLTIU': ['imm12','rs1','011','rd','0110011'],
  'XORI': ['imm12','rs1','100','rd','0110011'],
  'ORI': ['imm12','rs1','110','rd','0110011'],
  'ANDI': ['imm12','rs1','111','rd','0110011'],

  'SLLI': ['0000000','shamt','rs1','001','rd','0110011'],
  'SRLI': ['0000000','shamt','rs1','101','rd','0110011'],
  'SRAI': ['0100000','shamt','rs1','101','rd','0110011'],

  'LB': ['imm12','rs1','000','rd','0000011'],
  'LH': ['imm12','rs1','001','rd','0000011'],
  'LW': ['imm12','rs1','010','rd','0000011'],
  'LBU': ['imm12','rs1','100','rd','0000011'],
  'LHU': ['imm12','rs1','101','rd','0000011'],

  'JALR': ['imm','rs1','000','rd','1100111'],
  #---------------------S_Type-------------------------#
  'SB': ['imm_high7','rs2','rs1','000','imm_low5','0100011'],
  'SH': ['imm_high7','rs2','rs1','001','imm_low5','0100011'],
  'SW': ['imm_high7','rs2','rs1','010','imm_low5','0100011'],
  #---------------------B_Type-------------------------#
  'BEQ': ['imm_high7','rs2','rs1','000','imm_low5','1100011'],
  'BNE': ['imm_high7','rs2','rs1','001','imm_low5','1100011'],
  'BLT': ['imm_high7','rs2','rs1','100','imm_low5','1100011'],
  'BGE': ['imm_high7','rs2','rs1','101','imm_low5','1100011'],
  'BLTU': ['imm_high7','rs2','rs1','110','imm_low5','1100011'],
  'BGEU': ['imm_high7','rs2','rs1','111','imm_low5','1100011'],
  #---------------------J_Type-------------------------#
  'JAL': ['imm20','rd','1101111'],
  #---------------------U_Type-------------------------#
  'LUI': ['imm20','rd','1101111'],
  'AUIPC': ['imm20','rd','1101111'],
  }
file = open("C:/Users/Paul/Documents/Uni/DemonCore/software/assembler/test.txt").read().splitlines();
memonic = ''
program = ''
count = 0
for x in file:
  memonic+= ''.join(x)
list = memonic.split(';')
print(list)
for x in list:
  memonic = re.split(',| ', x)
  maschinecode = opDictionary[memonic[0]]
  match typeDictionary[memonic[0]]:
    case 'r':
      #['0000000','rs2','rs1','000','rd','0110011']#maschinecode#
      # mem[0] rd[1], rs1[2], rs2[3] #memonic#
        maschinecode[4] = f'{int(memonic[1]):05b}' #replace rd
        maschinecode[2] = f'{int(memonic[2]):05b}' #replace rs1
        maschinecode[1] = f'{int(memonic[3]):05b}' #replace rs2    
    case 'i':
      #['imm12','rs1','000','rd','0110011'] #maschinecode#
      # mem[0] rd[1], rs1[2], imm[3] #memonic#
      maschinecode[0] = f'{int(memonic[3]):012b}'
      maschinecode[1] = f'{int(memonic[2]):05b}'
      maschinecode[3] = f'{int(memonic[1]):05b}'
    case 'is':
      #['0000000','shamt','rs1','001','rd','0110011'], #maschinecode#
      # mem[0] rd[1], rs1[2], shamt[3] #memonic#
      maschinecode[2] = f'{int(memonic[3]):05b}' #rs1
      maschinecode[1] = f'{int(memonic[3]):05b}' #shamt
      maschinecode[4] = f'{int(memonic[1]):05b}' #rd
    case 's':
      #['imm_high7','rs2','rs1','000','imm_low5','0100011'],#maschinecode
      # mem[0] rs1[1], rs2[2], imm12[3] #memonic#
      temp = f'{int(memonic[3]):012b}'
      maschinecode[0] =  temp[0:7]#imm_high7
      maschinecode[4] = temp[7:12]#imm_low5
      maschinecode[1] = f'{int(memonic[2]):05b}' #rs2
      maschinecode[2] = f'{int(memonic[1]):05b}' #rs1
    case 'b':
      # ['imm_high7','rs2','rs1','000','imm_low5','1100011'],
      # mem[0] rs1[1], rs2[2], imm[3] #memonic#
      temp = f'{int(memonic[3]):012b}'
      maschinecode[0] =  temp[0:7]#imm_high7
      maschinecode[4] = temp[7:12]#imm_low5
      maschinecode[1] = f'{int(memonic[2]):05b}' #rs2
      maschinecode[2] = f'{int(memonic[1]):05b}' #rs1  
    case 'j':
      #['imm20','rd','1101111'],
      # mem[0] rd[1], imm20[2] #memonic#
      maschinecode[0] = f'{int(memonic[2]):020b}'
      maschinecode[1] = f'{int(memonic[1]):05b}'
    case 'u':
      # mem[0] rd[1], imm20[2] #memonic#
      maschinecode[0] = f'{int(memonic[2]):020b}'
      maschinecode[1] = f'{int(memonic[1]):05b}'
  program += ''.join(str(count)+ '=>' + "b\"")
  count = count + 1
  for i in maschinecode:
    if i != maschinecode[len(maschinecode)-1]:
      program += ''.join(i+"_")
    else:
      program = program + ''.join(i)
  program += ''.join("\", \n")
print(program)
print("others => NOP_INSTRUCTION")
print()