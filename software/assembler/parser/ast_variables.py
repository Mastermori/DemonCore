import abc
from dataclasses import dataclass
from typing import List
from lark import ast_utils
from ast_base import _Ast, _AstMeta, ParseContext, _Immediate


@dataclass
class _VariableParam(_Ast):
    value: _Immediate

    def get_bits_for_ascii(self) -> List[str]:
        raise NotImplementedError(
            f"{self.__class__.__name__} does not support ascii format.")

    def get_bits_for_byte(self) -> str:
        raise NotImplementedError(
            f"{self.__class__.__name__} does not support byte format.")

    def get_bits_for_int(self) -> str:
        raise NotImplementedError(
            f"{self.__class__.__name__} does not support int format.")

    def get_bits_for_word(self) -> str:
        raise NotImplementedError(
            f"{self.__class__.__name__} does not support word format.")


@dataclass
class _VarDirective(_Ast, ast_utils.AsList):
    params: List[_VariableParam]

    @abc.abstractmethod
    def get_words(self) -> List[str]:
        pass


class VarDirectiveWord(_VarDirective):
    def get_words(self) -> List[str]:
        return list([param.get_bits_for_word() for param in self.params])


@dataclass
class Variable(_AstMeta):
    name: str
    directive: _VarDirective
    address: int = -1

    def __init__(self, meta, name: str, directive: _VarDirective):
        super().__init__(meta)
        self.name = name
        self.directive = directive


class VarParamChar(_VariableParam):
    pass


class VarParamNum(_VariableParam):
    pass


class VarParamWord(_VariableParam):
    def __init__(self, value: int):
        super().__init__(value)
        if len(self.get_bits_for_word()) > 32:
            raise ValueError(
                f"A VarParamWord can only store 32 bit at most, got {len(self.get_bits_for_word())} bit for value {value}")

    def get_bits_for_word(self) -> str:
        value = self.value.get_value(None)
        return f"{value:032b}"


class VarParamString(_VariableParam):
    def get_bits_for_ascii(self) -> List[str]:
        bit_string = []
        value = str(self.value.get_value())
        value = value[1:-1]
        for string_index in range(len(value)//4+1):
            bits = ""
            for i in range(4):
                char_index = string_index * 4 + i
                if char_index >= len(value):
                    bits += "0"*8
                    continue
                char = value[char_index]
                bits += f"{ord(char):08b}"
            bit_string.append(bits)
        return bit_string


@dataclass
class VarAddressLower(_Ast):
    name: str

    def get_value(self, context: ParseContext) -> int:
        address = context.get_variable(self.name).address
        if address < 0:
            raise ValueError(
                f"Cannot process address {address} of non existent or faulty variable: {self.name}")
        return address & 0xfff  # Get lower 12 bits


@dataclass
class VarAddressUpper(_Ast):
    name: str

    def get_value(self, context: ParseContext) -> int:
        address = context.get_variable(self.name).address
        if address < 0:
            raise ValueError(
                f"Cannot process address {address} of non existent or faulty variable: {self.name}")
        return (address & 0xfffff000) >> 12  # Get upper 20 bits
