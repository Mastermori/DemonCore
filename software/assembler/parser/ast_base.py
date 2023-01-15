from dataclasses import dataclass
from lark import ast_utils
from lark.tree import Meta
from typing import List

from util import get_register_bits


class _Ast(ast_utils.Ast):
    pass


@dataclass
class _AstMeta(_Ast, ast_utils.WithMeta):
    meta: Meta


@dataclass
class Register(_Ast):
    name: str

    def get_bit_string(self) -> str:
        return get_register_bits(self.name)


class ParseContext():
    reference_lines: List[str]
    instruction_space_count_max: int
    number_spaces: int
    labels = {}
    variables = {}
    instruction_strings = []

    def __init__(self, reference_lines: List[str]) -> None:
        self.reference_lines = reference_lines
        self.instruction_space_count_max = len(str(len(reference_lines)))
        self.number_spaces = ' ' * (1+(self.instruction_space_count_max -
                                       len(str(len(self.instruction_strings)))))

    def add_label(self, label) -> None:
        self.labels[label.name] = label

    def add_varaible(self, variable) -> None:
        self.variables[variable.name]

    def get_next_adress(self) -> int:
        return len(self.instruction_strings)

    def append_raw_instruction(self, raw_instructions: List[List[str]], instruction_line: int):
        for raw_instruction in raw_instructions:
            self.instruction_strings.append(
                str(len(self.instruction_strings)) + self.number_spaces +
                ''.join(raw_instruction)
                + "    --" + self.reference_lines[instruction_line-1]
            )
