import abc
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

class _Immediate(_Ast):
    @abc.abstractmethod
    def get_value(self, parseContext):
        pass

@dataclass
class _ImmediateNumber(_Immediate):
    value: int

    def get_value(self, parseContext):
        return self.value

class RamContent():
    direct_ram_dict = {}
    direct_ram_reference_dict = {}
    current_adress_pointer = 0

    def write_direct(self, words: List[str], reference_line: str = "") -> None:
        start_address = self.current_adress_pointer
        for i, word in enumerate(words):
            ram_address = self.current_adress_pointer + i
            self.direct_ram_dict[ram_address] = word
            self.direct_ram_reference_dict[ram_address] = reference_line
        self.current_adress_pointer += len(words)
        return start_address
    
    def get_printable_str(self, space_amount = 4) -> str:
        print_list = []
        for adress, word in self.direct_ram_dict.items():
            print_list.append(f"{adress}{' '*space_amount}{word}\t--{self.direct_ram_reference_dict[adress]}")
        return "\n".join(print_list)


class ParseContext():
    reference_lines: List[str]
    instruction_space_count_max: int
    labels = {}
    variables = {}
    instruction_strings = []
    ram_content: RamContent = RamContent()

    def __init__(self, reference_lines: List[str]) -> None:
        self.reference_lines = reference_lines
        self.instruction_space_count_max = len(str(len(reference_lines)))

    def add_label(self, label) -> None:
        self.labels[label.name] = label

    def add_varaible(self, variable) -> None:
        var_line = variable.meta.line-1
        variable.address = self.write_to_ram(variable.directive.get_words(), self.reference_lines[var_line])
        self.variables[variable.name] = variable
    
    def get_variable(self, name):
        return self.variables[name]

    def write_to_ram(self, words: List[str], reference_line="", direct=True) -> int:
        if direct:
            return self.ram_content.write_direct(words, reference_line)
        else:
            return -1
    
    def get_ram_content_str(self) -> str:
        return self.ram_content.get_printable_str()

    def get_next_adress(self) -> int:
        return len(self.instruction_strings)

    def append_raw_instructions(self, raw_instructions: List[List[str]], instruction_line: int):
        for raw_instruction in raw_instructions:
            self.number_spaces = ' ' * 4 #* (1+(self.instruction_space_count_max - len(''.join(raw_instruction))))
            self.instruction_strings.append(
                str(len(self.instruction_strings)) + self.number_spaces +
                ''.join(raw_instruction)
                + "    --" + self.reference_lines[instruction_line-1]
            )
