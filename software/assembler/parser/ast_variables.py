import abc
from dataclasses import dataclass
from typing import List
from lark import ast_utils
from ast_base import _Ast, _AstMeta, ParseContext, _Immediate, ParserError
from util import two_complement


@dataclass
class _VariableParam(_AstMeta):
    value: _Immediate

    def get_bits_for_ascii(self, context) -> List[str]:
        context.raise_error(ParserError(
            f"{self.__class__.__name__} does not support ascii format.", self.meta))

    def get_bits_for_byte(self, context) -> str:
        context.raise_error(ParserError(
            f"{self.__class__.__name__} does not support byte format.", self.meta))

    def get_bits_for_int(self, context) -> str:
        context.raise_error(ParserError(
            f"{self.__class__.__name__} does not support byte format.", self.meta))

    def get_bits_for_word(self, context) -> str:
        context.raise_error(ParserError(
            f"{self.__class__.__name__} does not support word format.", self.meta))

    def get_bits_for_char(self, context) -> str:
        context.raise_error(ParserError(
            f"{self.__class__.__name__} does not support char format.", self.meta))


@dataclass
class _VarDirective(_Ast, ast_utils.AsList):
    params: List[_VariableParam]

    @abc.abstractmethod
    def get_words(self, context: ParseContext) -> List[str]:
        pass


class VarDirectiveWord(_VarDirective):
    def get_words(self, context: ParseContext) -> List[str]:
        return list([param.get_bits_for_word(context) for param in self.params])


class VarDirectiveAscii(_VarDirective):
    def get_words(self, context: ParseContext) -> List[str]:
        words = []
        for param in self.params:
            words.extend(param.get_bits_for_ascii(context))
        return words


class VarDirectiveInt(_VarDirective):
    def get_words(self, context: ParseContext) -> List[str]:
        return list([param.get_bits_for_int(context) for param in self.params])


class VarDirectiveChar(_VarDirective):
    def get_words(self, context: ParseContext) -> List[str]:
        return list([param.get_bits_for_char(context) for param in self.params])


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
        
    def get_value(self, context):
        if len(self.value) > 1:
            context.raise_error(f"A VarParamChar can only store 1 char per word at most, got {len(self.value)} chars instead", self.meta)
        return self.value

    def get_bits_for_char(self, context) -> str:
        return str("{0:032b}".format(ord(self.get_value(context))))


class VarParamNum(_VariableParam):
    def get_value(self, context):
        if len(str("{0:b}".format(abs(int(self.value))))) > 31:
            context.raise_error(f"A VarParamNum can only store 32 bit at most, got {len(self.get_bits_for_int())} bit for value {self.value}", self.meta)
        return self.value

    def get_bits_for_int(self, context) -> str:
        return two_complement(int(self.get_value(context)), 32)


class VarParamWord(_VariableParam):
    def get_value(self, context):
        print(f"{self.value.get_value(context):032b}")
        if len(f"{self.value.get_value(context):032b}") > 32:
            context.raise_error(f"A VarParamWord can only store 32 bit at most, got {len(self.get_bits_for_word())} bit for value {self.value}", self.meta)
        return self.value

    def get_bits_for_word(self, context) -> str:
        value = self.get_value(context).get_value(context)
        return f"{value:032b}"


class VarParamString(_VariableParam):
    def get_bits_for_ascii(self, context) -> List[str]:
        bit_string = []
        value = str(self.value)
        print(value)
        value = value[1:-1]
        for string_index in range(len(value)//4+1):
            bits = ""
            for i in range(4):
                char_index = string_index * 4 + (3-i)
                if char_index >= len(value):
                    bits += "0"*8
                    continue
                char = value[char_index]
                bits += f"{ord(char):08b}"
            bit_string.append(bits)
        return bit_string


@dataclass
class VarAddressLower(_AstMeta):
    name: str

    def get_value(self, context: ParseContext) -> int:
        address = context.get_variable(self.name).address
        if address < 0:
            context.raise_error(f"Cannot process address {address} of non existent or faulty variable: {self.name}", self.meta)
        return address & 0xfff  # Get lower 12 bits


@dataclass
class VarAddressUpper(_AstMeta):
    name: str

    def get_value(self, context: ParseContext) -> int:
        address = context.get_variable(self.name).address
        if address < 0:
            context.raise_error(f"Cannot process address {address} of non existent or faulty variable: {self.name}", self.meta)
        return (address & 0xfffff000) >> 12  # Get upper 20 bits
