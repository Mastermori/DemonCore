from dataclasses import dataclass
from typing import List
from lark import ast_utils
from ast_base import _Ast, _AstMeta


@dataclass
class _VariableParam(_Ast):
    value: str

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


class VarDirective(_Ast, ast_utils.AsList):
    type: str
    params: List[_VariableParam]

    def __init__(self, arg_list):
        self.type = arg_list[0]
        self.params = arg_list[1:]


@dataclass
class Variable(_AstMeta):
    name: str
    directive: VarDirective


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
        return f"{self.value:032b}"


class VarParamString(_VariableParam):
    def __init__(self, value: str):
        self.value = value[1:-1]

    def get_bits_for_ascii(self) -> List[str]:
        bit_string = []
        for string_index in range(len(self.value)//4+1):
            bits = ""
            for i in range(4):
                char_index = string_index * 4 + i
                if char_index >= len(self.value):
                    bits += "0"*8
                    continue
                char = self.value[char_index]
                bits += f"{ord(char):08b}"
            bit_string.append(bits)
        return bit_string
