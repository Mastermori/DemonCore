import abc
from dataclasses import dataclass
from typing import List, Dict

from lark import Transformer, v_args
from lark.tree import Meta
from demonass_parser.ast_base import _AstMeta, ParseContext, Register, _Immediate, ParserError
from demonass_parser.util import two_complement
from demonass_parser.dictionarys import opDictionary


class BaseInstruction():
    instruction_bits: List[str]

    def __init__(self, mnemonic: str, bindings: Dict[str, str], context: ParseContext, meta: Meta):
        self.set_instruction_bits(mnemonic.upper(), bindings, context, meta)

    def set_instruction_bits(self, mnemonic: str, bindings: Dict[str, str], context: ParseContext, meta: Meta) -> None:
        if mnemonic in opDictionary:
            self.instruction_bits = opDictionary[mnemonic]
            for binding in bindings:
                self.instruction_bits[binding] = bindings[binding]
        else:
            context.raise_error(ParserError("Can't find instruction with mnemonic {mnemonic}", meta))

    def get_bit_string(self) -> List[str]:
        return self.instruction_bits


@dataclass
class Mnemonic():
    name: str
    type: str


@dataclass
class _DirectInstruction(_AstMeta, metaclass=abc.ABCMeta):
    mnemonic: Mnemonic

    @abc.abstractmethod
    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        pass

    def get_instruction_from_mnemonic(self) -> List[str]:
        return opDictionary[self.mnemonic.name.upper()]


@dataclass
class RegisterDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    register2: Register

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        return BaseInstruction(self.mnemonic.name, {
            4: self.register_destination.get_bit_string(),  # rd
            2: self.register1.get_bit_string(), #rs1
            1: self.register2.get_bit_string() #rs2
        }, context, self.meta).get_bit_string()


@dataclass
class ImmediateDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    imm12: _Immediate

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = two_complement(
            self.imm12.get_value(context), 12)  # imm12
        raw_instruction[1] = self.register1.get_bit_string()  # rs1
        raw_instruction[3] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


@dataclass
class OffsetDirectInstruction(_DirectInstruction):
    register1: Register
    offset: _Immediate
    register2: Register

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        match self.mnemonic.type:
            case 'jl_type' | 'l_type':
                raw_instruction[0] = two_complement(
                    self.offset.get_value(None), 12)  # imm12
                raw_instruction[1] = self.register2.get_bit_string()  # rs2
                raw_instruction[3] = self.register1.get_bit_string()  # rs1
            case 's_type':
                # ['imm_high7','rs2','rs1','000','imm_low5','0100011'],#maschinecode
                # mem[0] rs1[1], imm12[2](rs2[3])  #memonic#
                imm12 = two_complement(self.offset.get_value(None), 12)
                raw_instruction[0] = imm12[0:7]  # imm_high7
                raw_instruction[4] = imm12[7:12]  # imm_low5
                raw_instruction[1] = self.register2.get_bit_string()  # rs2
                raw_instruction[2] = self.register1.get_bit_string()  # rs1
        return raw_instruction


@dataclass
class BranchDirectInstruction(_DirectInstruction):
    register1: Register
    register2: Register
    imm12: _Immediate

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = self.imm12.get_value_bit_str(context, 12)[0:7]  # imm_high7
        raw_instruction[4] = self.imm12.get_value_bit_str(context, 12)[7:12]  # imm_low5
        raw_instruction[1] = self.register2.get_bit_string()  # rs2
        raw_instruction[2] = self.register1.get_bit_string()  # rs1
        return raw_instruction


@dataclass
class ShiftDirectInstruction(_DirectInstruction):
    register_destination: Register
    register1: Register
    shamt: _Immediate

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[2] = self.register1.get_bit_string()  # rs1
        raw_instruction[1] = two_complement(self.shamt.get_value(context), 5)  # shamt
        raw_instruction[4] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


@dataclass
class JumpUpperDirectInstruction(_DirectInstruction):
    register_destination: Register
    imm20: _Immediate

    def get_raw_instruction(self, context: ParseContext) -> List[str]:
        raw_instruction = self.get_instruction_from_mnemonic()
        raw_instruction[0] = two_complement(
            self.imm20.get_value(context), 20)  # imm20
        raw_instruction[1] = self.register_destination.get_bit_string()  # rd
        return raw_instruction


class ToAstInstructions(Transformer):
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
