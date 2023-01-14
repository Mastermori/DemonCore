import abc
from dataclasses import dataclass
from typing import List

from lark import Transformer, v_args
from parser_base import _AstMeta
from parser_base import ParseContext, Register
from util import two_complement
from dictionarys import opDictionary


@dataclass
class Mnemonic():
    name: str
    type: str


@dataclass
class _Instruction(_AstMeta):
    mnemonic: Mnemonic


@dataclass
class _DirectInstruction(_Instruction, metaclass=abc.ABCMeta):
    @abc.abstractmethod
    def get_raw_instruction(self) -> List[str]:
        pass

    def get_instruction_from_mnemonic(self) -> str:
        return opDictionary[self.mnemonic.name.upper()]


@dataclass
class _PseudoInstruction(_Instruction):
    @abc.abstractmethod
    def get_raw_instructions(self, context: ParseContext) -> List[List[str]]:
        pass


@dataclass
class RegisterDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    register2: Register

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[4] = self.register_destination.get_bit_string()  # rd
        raw_instruction[2] = self.register1.get_bit_string()  # rs1
        raw_instruction[1] = self.register2.get_bit_string()  # rs2
        return raw_instruction


@dataclass
class ImmediateDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    imm12: int

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = two_complement(self.imm12, 12)  # imm12
        raw_instruction[1] = self.register1.get_bit_string()  # rs1
        raw_instruction[3] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


@dataclass
class OffsetDirectInstruction(_DirectInstruction):
    register1: Register
    register2: Register
    offset: int

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        match self.mnemonic.type:
            case 'jl_type' | 'l_type':
                raw_instruction[0] = two_complement(self.offset, 12)  # imm12
                raw_instruction[1] = self.register2.get_bit_string()  # rs2
                raw_instruction[3] = self.register1.get_bit_string()  # rs1
            case 's_type':
                # ['imm_high7','rs2','rs1','000','imm_low5','0100011'],#maschinecode
                # mem[0] rs1[1], imm12[2](rs2[3])  #memonic#
                imm12 = two_complement(self.offset, 12)
                raw_instruction[0] = imm12[0:7]  # imm_high7
                raw_instruction[4] = imm12[7:12]  # imm_low5
                raw_instruction[1] = self.register2.get_bit_string()  # rs2
                raw_instruction[2] = self.register1.get_bit_string()  # rs1
        return raw_instruction


@dataclass
class BranchDirectInstruction(_DirectInstruction):
    register1: Register
    register2: Register
    imm12: int

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = self.imm12[0:7]  # imm_high7
        raw_instruction[4] = self.imm12[7:12]  # imm_low5
        raw_instruction[1] = self.register2.get_bit_string()  # rs2
        raw_instruction[2] = self.register1.get_bit_string()  # rs1
        return raw_instruction


@dataclass
class ShiftDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    shamt: int

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[2] = self.register1.get_bit_string()  # rs1
        raw_instruction[1] = two_complement(self.shamt, 5)  # shamt
        raw_instruction[4] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


@dataclass
class JumpUpperDirectInstruction(_DirectInstruction):
    register_destination: Register
    imm20: int

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = two_complement(self.imm20, 20)  # imm20
        raw_instruction[1] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


class ToAstInstructions(Transformer):
    @v_args(inline=True)
    def instruction(self, x):
        return x

    @v_args(inline=True)
    def direct_instruction(self, x):
        return x

    @v_args(inline=True)
    def param_3(self, x):
        return x

    @v_args(inline=True)
    def param_2(self, x):
        return x

    @v_args(inline=True)
    def r_type(self, x):
        return Mnemonic(x, "r_type")

    @v_args(inline=True)
    def i_type(self, x):
        return Mnemonic(x, "i_type")

    @v_args(inline=True)
    def is_type(self, x):
        return Mnemonic(x, "is_type")

    @v_args(inline=True)
    def l_type(self, x):
        return Mnemonic(x, "l_type")

    @v_args(inline=True)
    def s_type(self, x):
        return Mnemonic(x, "s_type")

    @v_args(inline=True)
    def b_type(self, x):
        return Mnemonic(x, "b_type")

    @v_args(inline=True)
    def ju_type(self, x):
        return Mnemonic(x, "ju_type")

    @v_args(inline=True)
    def jl_type(self, x):
        return Mnemonic(x, "jl_type")
