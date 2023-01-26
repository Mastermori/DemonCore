import abc
from dataclasses import dataclass
from lark import ast_utils
from lark.tree import Meta
from typing import List
from util import two_complement

from util import get_register_bits


class _Ast(ast_utils.Ast):
    pass


@dataclass
class _AstMeta(_Ast, ast_utils.WithMeta):
    meta: Meta


@dataclass
class Register(_Ast):
    name: str

    def __init__(self, name):
        self.name = name

    def get_bit_string(self) -> str:
        return get_register_bits(self.name)

class _Immediate(_Ast):
    @abc.abstractmethod
    def get_value(self, parseContext):
        pass
    
    def get_value_bit_str(self, parseContext, length: int):
        return two_complement(self.get_value(parseContext), length)

@dataclass
class _ImmediateNumber(_Immediate):
    value: int

    def get_value(self, parseContext):
        return self.value
    

class RamContent():
    direct_ram_dict = {}
    direct_ram_reference_dict = {}
    instruction_ram_dict = {}
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
    
    def get_instruction_list(self) -> List[str]:
        # Zeug zu instructions machen oder so
        return [] # Liste aller instructions die zum schreiben gesetzt werden müssen


class ParseContext():
    reference_lines: List[str]
    instruction_space_count_max: int
    labels = {}
    variables = {}
    instruction_address_pointer = 0
    instruction_strings = {}
    ram_content: RamContent = RamContent()
    flow_commands = {}

    def __init__(self, reference_lines: List[str]) -> None:
        self.reference_lines = reference_lines
        line_count = len(reference_lines)
        self.instruction_space_count_max = len(str(line_count))

    def add_label(self, label) -> None:
        self.labels[label.name] = label

    def add_flow_command(self, flowCommand) -> None:
        self.flow_commands[self.instruction_address_pointer] = flowCommand
        self.instruction_address_pointer += 2

    def add_variable(self, variable) -> None:
        var_line = variable.meta.line-1
        variable.address = self.write_to_ram(variable.directive.get_words(), self.reference_lines[var_line])
        self.variables[variable.name] = variable
    
    def get_variable(self, name):
        return self.variables[name]
    
    def set_ram_address(self, address: int) -> None:
        self.ram_content.current_adress_pointer = address

    def write_to_ram(self, words: List[str], reference_line="", direct=True) -> int:
        if direct:
            return self.ram_content.write_direct(words, reference_line)
        else:
            return -1
    
    def get_ram_content_str(self) -> str:
        return self.ram_content.get_printable_str()
    
    def get_ram_instructions(self) -> List[str]:
        return self.ram_content.get_instruction_list()
    
    def append_raw_instructions(self, raw_instructions: List[List[str]], instruction_line: int):
        for raw_instruction in raw_instructions:
            line_number = len(self.instruction_strings)
            number_spaces = ' ' * (1+(self.instruction_space_count_max - len(str(line_number))))
            self.instruction_strings[self.instruction_address_pointer] = \
                f"{self.instruction_address_pointer}{number_spaces}{''.join(raw_instruction)}    --{self.reference_lines[instruction_line-1]}"
            self.instruction_address_pointer += 1
    
    def get_compiled_instructions(self) -> str:
        return "\n".join(self.instruction_strings.values())