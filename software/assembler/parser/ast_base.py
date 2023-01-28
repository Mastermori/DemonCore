import abc
import collections
from dataclasses import dataclass
from lark import ast_utils
from lark.tree import Meta
from typing import Dict, List
from util import two_complement

from util import get_register_bits


class ParserError():
    msg: str
    lineno: int
    colno: int
    suggestion: str

    def __init__(self, msg: str, meta: Meta, suggestion: str = "") -> None:
        self.msg = msg
        self.lineno = meta.line
        self.colno = meta.column
        self.suggestion = suggestion

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

    def get_printable_str(self, space_amount=4) -> str:
        print_list = []
        for adress, word in self.direct_ram_dict.items():
            print_list.append(
                f"{adress}{' '*space_amount}{word}\t--{self.direct_ram_reference_dict[adress]}")
        return "\n".join(print_list)

    def get_instruction_list(self) -> List[str]:
        # Zeug zu instructions machen oder so
        return []  # Liste aller instructions die zum schreiben gesetzt werden müssen


class ParseContext():
    reference_lines: List[str]
    instruction_space_count_max: int
    labels: Dict
    last_label: object
    variables: Dict
    instruction_address_pointer: int
    instruction_strings: Dict
    ram_content: RamContent
    flow_commands: Dict
    errors: List[ParserError]
    pseudo_offset_lines: Dict[int, int]

    def __init__(self, reference_lines: List[str]) -> None:
        self.reference_lines = reference_lines
        line_count = len(reference_lines)
        self.instruction_space_count_max = len(str(line_count))
        self.labels = {}
        self.last_label = None
        self.variables = {}
        self.instruction_address_pointer = 0
        self.instruction_strings = {}
        self.ram_content = RamContent()
        self.flow_commands = {}
        self.errors = []
        self.pseudo_offset_lines = {}

    def add_label(self, label) -> None:
        self.labels[label.name] = label
        self.last_label = label

    def add_flow_command(self, flow_command) -> None:
        self.flow_commands[self.instruction_address_pointer] = flow_command
        self.instruction_address_pointer += flow_command.get_instruction_count()

    def append_flow_commdands(self, parser, transformer) -> None:
        for address, flow_command in self.flow_commands.items():
            instruction_parse_string = "\n".join(
                flow_command.get_instructions(self, address))
            parsed_instructions = transformer.transform(
                parser.parse(instruction_parse_string))
            for index, instruction in enumerate(parsed_instructions):
                flow_command.label_offset = self.get_label_address(
                    flow_command.label_name) - address
                self.set_raw_instruction(instruction.get_raw_instruction(
                    self), address + index, flow_command.meta.line)
        self.instruction_strings = collections.OrderedDict(
            sorted(self.instruction_strings.items()))

    def get_label_address(self, label_name):
        return self.labels[label_name].jump_address

    def add_variable(self, variable) -> None:
        var_line = variable.meta.line-1
        variable.address = self.write_to_ram(
            variable.directive.get_words(self), self.reference_lines[var_line])
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
            self.set_raw_instruction(
                raw_instruction, self.instruction_address_pointer, instruction_line)
            if self.last_label:
                self.last_label.jump_address = self.instruction_address_pointer
                self.last_label = None
            self.instruction_address_pointer += 1

    def set_raw_instruction(self, raw_instruction, address, instruction_line):
        line_number = len(self.instruction_strings)
        number_spaces = ' ' * \
            (1+(self.instruction_space_count_max - len(str(line_number))))
        self.instruction_strings[address] = \
            f"{address}{number_spaces}{''.join(raw_instruction)}    --{self.reference_lines[instruction_line-1]}"

    def get_compiled_instructions(self, parser, transformer) -> str:
        self.append_flow_commdands(parser, transformer)
        return "\n".join(self.instruction_strings.values())
    
    def raise_error(self, error: ParserError) -> None:
        line_offset = 0
        for key, val in self.pseudo_offset_lines.items():
            if key < error.lineno:
                line_offset += val
        print(line_offset)
        error.lineno -= line_offset
        self.errors.append(error)
    
    def get_errors(self) -> List[ParserError]:
        return self.errors
