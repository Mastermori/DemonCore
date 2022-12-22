from lark import Lark, Token

l = Lark(r'''start: (expression /\n/)*
            expression: long_expression | short_expression // | label

            // label:

            long_expression: opcode_long_register register "," register "," register
              | opcode_long_immediate register "," register "," number_short
              | pseudo_long_immediate register "," register "," number_short
            short_expression: opcode_short_immediate register "," number_long
              | opcode_short_store register "," number_short "(" register ")"
              | pseudo_short_register register "," register
              | pseudo_short_immediate register "," number_short
              | pseudo_extra_short number_short
              | pseudo_no_args

            opcode_long_register: r_type 
            opcode_long_immediate: i_type | b_type
            opcode_short_immediate: u_type | j_type
            opcode_short_store: i_type | s_type

            !pseudo_long_immediate: "bgt"i | "ble"i | "bgtu"i | "bleu"i
            !pseudo_short_register: "mv"i | "not"i | "neg"i
            !pseudo_short_immediate: "li"i | "la"i | "beqz"i | "bnez"i | "bgez"i | "blez"i | "bgtz"i // braucht mehr als upper immediate
            !pseudo_extra_short: "j"i | "call"i  // braucht mehr als upper immediate
            !pseudo_no_args: "ret"i | "nop"i

            number_short: IMM12_DEC | IMM12_HEX | IMM12_OCT | IMM12_BIN
            number_long: IMM20_DEC | IMM20_HEX | IMM20_OCT | IMM20_BIN

            !r_type: "add"i | "sub"i | "xor"i | "or"i | "and"i | "sll"i | "srl"i | "sra"i | "slt"i | "sltu"i
            !i_type: "addi"i | "xori"i | "ori"i | "andi"i | "slli"i | "srli"i | "srai"i | "slti"i | "sltiu"i
              | "lb"i | "lh"i | "lw"i | "lbu"i | "lhu"i | "jalr"i | "ecall"i | "ebreak"i
            !s_type: "sb"i | "sh"i | "sw"i
            !b_type: "beq"i | "bne"i | "blt"i | "bge"i | "bltu"i | "bgeu"i
            !u_type: "lui"i | "auipc"i
            !j_type: "jal"i

            register: always_zero | return_adress | stack_pointer | global_pointer | thread_pointer | frame_pointer
              | temporary | saved_register | function_argument

            !always_zero: "x0" | "zero"
            !return_adress: "x1" | "ra"
            !stack_pointer: "x2" | "sp"
            !global_pointer: "x3" | "gp"
            !thread_pointer: "x4" | "tp"
            !frame_pointer: "fp"
            !temporary: "x5" | "t0" | "x6" | "t1" | "x7" | "t2" | "x28" | "t3" | "x29"
              | "t4" | "x30" | "t5" | "x31" | "t6"
            !saved_register: "x8" | "s0" | "x9" | "s1" | "x18" | "s2" | "x19"
              | "s3" | "x20" | "s4" | "x21" | "s5" | "x22" | "s6" | "x23" | "s7"
              | "x24" | "s8" | "x25" | "s9" | "x26" | "s10" | "x27" | "s11"
            !function_argument: "x10" | "a0" | "x11" | "a1" | "x12" | "a2" | "x13"
              | "a3" | "x14" | "a4" | "x15" | "a5" | "x16" | "a6" | "x17" | "a7"

            IMM12_DEC: /(-[1-9]|-204[0-8]|-?[1-9][0-9]{1,2}|-?1[0-9][0-9][0-9]|-?20[0-3][0-9]|[0-9]|204[0-7])\b/
            IMM12_HEX: /(-0x[1-9a-fA-F]|-0x800|-?0x[1-9a-fA-F][0-9a-fA-F]|-?0x[1-7][0-9a-fA-F]{2}|0x[0-9a-fA-F])\b/
            IMM12_OCT: /(-0[1-7]|-0[1-3][0-7]{3}|-04000|-?0[1-7][0-7]{1,2}|0[0-7]|0[12][0-7]{3}|03[0-6][0-7]{2}|037[0-6][0-7]|0377[0-7])\b/
            IMM12_BIN: /(-0b[1-1]|-0b[1-1][0-1]{1,10}|-0b100000000000|0b[0-1]|0b[1-1][0-1]{1,9}|0b10[0-1]{9}|0b110[0-1]{8}|0b1110[0-1]{7}
              |0b11110[0-1]{6}|0b111110[0-1]{5}|0b1111110[0-1]{4}|0b11111110[0-1]{3}|0b111111110[0-1]{2}|0b1111111110[0-1]|0b1111111111[01])\b/x

            IMM20_DEC: /(-[1-9]|-52428[0-8]|-?[1-9]\d{1,4}|-?[1-4]\d{5}|-?5[01]\d{4}|-?52[0-3]\d{3}|-?524[01]\d{2}|-?5242[0-7]\d|\d|52428[0-7])\b/
            IMM20_HEX: /(-0x[1-9a-fA-F]|-0x80000|-?0x[1-9a-fA-F][0-9a-fA-F]{1,3}|-?0x[1-7][0-9a-fA-F]{4}|0x[0-9a-fA-F])\b/
            IMM20_OCT: /(-0[1-7]|-01[0-7]{6}|-02000000|-?0[1-7][0-7]{1,5}|0[0-7]|01[0-6][0-7]{5}|017[0-6][0-7]{4}|0177[0-6][0-7]{3}|01777[0-6][0-7]{2}|017777[0-6][0-7]|0177777[0-7])\b/
            IMM20_BIN: /(-0b[1-1]|-0b[1-1][0-1]{1,18}|-0b10000000000000000000|0b[0-1]|0b[1-1][0-1]{1,17}|0b10[0-1]{17}|0b110[0-1]{16}|0b1110[0-1]{15}
            |0b11110[0-1]{14}|0b111110[0-1]{13}|0b1111110[0-1]{12}|0b11111110[0-1]{11}|0b111111110[0-1]{10}|0b1111111110[0-1]{9}|0b11111111110[0-1]{8}
            |0b111111111110[0-1]{7}|0b1111111111110[0-1]{6}|0b11111111111110[0-1]{5}|0b111111111111110[0-1]{4}|0b1111111111111110[0-1]{3}|0b11111111111111110[0-1]{2}
            |0b111111111111111110[0-1]|0b111111111111111111[01])\b/x

            // CHARACTERS:
            // SHAMT: Bei RV32I shamt[5] = 0

            %import common.WORD   // imports from terminal library
            %ignore " "           // Disregard spaces in text
         ''')


def createTree(file):
  return l.parse(file)