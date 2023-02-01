import abc
from dataclasses import dataclass
import sys
from typing import Dict, List, Tuple

from lark import Transformer, ast_utils, v_args

from demonass_parser.ast_base import ParseContext, _AstMeta, Register, ParserError
from demonass_parser.dictionarys import pseudoDic


class PseudoContext():
    reference_lines: List[str]
    pseudo_replaced_lines: List[List[str]]
    changed: bool = False
    pseudo_offset = 0

    def __init__(self, reference_lines: List[str]) -> None:
        self.reference_lines = reference_lines
        self.pseudo_replaced_lines = [[line] for line in reference_lines]

    def replace_pseudo_instruction(self, line: int, replacement: List[str]):
        self.pseudo_replaced_lines[line-1] = [
            f"{repl_line}    //{self.reference_lines[line-1]}" for repl_line in replacement]
        self.pseudo_offset += len(replacement) - 1
        self.changed = True

    def get_replaced_instructions(self) -> Tuple[List[str], Dict[int, int]]:
        replaced = []
        offsets = {}
        for line_index, line_list in enumerate(self.pseudo_replaced_lines):
            if len(line_list) - 1 > 0:
                offsets[line_index] = len(line_list) - 1 + (offsets[line_index] if line_index in offsets else 0)
            replaced.extend(line_list)
        return replaced, offsets


class ToAstPseudo(Transformer):
    @v_args(inline=True)
    def start(self, *x):
        return x


class _PseudoInstruction(_AstMeta):
    @abc.abstractmethod
    def replace(self, context):
        context.raise_error(ParserError(f"Method replace must be implemented in {self.__class__.__name__}", self.meta))

    def _get_replaced_list(self, mnemonic: str, replace_map: Dict[str, str]) -> List[str]:
        replacement_list = []
        for i, instruction in enumerate(pseudoDic[mnemonic]):
            replaced_instruction = instruction

            for replace_key, replace_val in replace_map.items():
                replaced_instruction = replaced_instruction.replace(
                    f"${replace_key}", replace_val)

            replacement_list.append(replaced_instruction)
        return replacement_list


@dataclass
class PseudoBranchSwap(_PseudoInstruction):
    mnemonic_name: str
    register1: Register
    register2: Register
    offset: str

    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list(self.mnemonic_name, {
                                              "rs1": self.register1.name,
                                              "rs2": self.register2.name,
                                              "offset": self.offset})
        context.replace_pseudo_instruction(self.meta.line, replacement)


@dataclass
class PseudoBranchZero(_PseudoInstruction):
    mnemonic_name: str
    register1: Register
    offset: str

    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list(
            self.mnemonic_name, {'rs1': self.register1.name, 'offset': self.offset})
        context.replace_pseudo_instruction(self.meta.line, replacement)

@dataclass
class PseudoMove(_PseudoInstruction):
    mnemonic_name: str
    register1: Register
    register2: Register

    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list(
            self.mnemonic_name, {'rd': self.register1.name, 'rs1': self.register2.name})
        context.replace_pseudo_instruction(self.meta.line, replacement)

@dataclass
class PseudoMul(_PseudoInstruction):
    register1: Register
    register2: Register
    register3: Register

    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list(
            "mul", {'rd': self.register1.name, 'rs1': self.register2.name, 'rs2': self.register3.name})
        context.replace_pseudo_instruction(self.meta.line, replacement)

@dataclass
class PseudoNop(_PseudoInstruction):
    count: int

    def __init__(self, meta, count="1"):
        super().__init__(meta)
        self.count = int(count)

    def replace(self, context: PseudoContext):
        replacement = [pseudoDic['nop'][0]
                       for i in range(int(self.count))]
        context.replace_pseudo_instruction(self.meta.line, replacement)


@dataclass
class PseudoLabel(_PseudoInstruction):
    label: str

    def replace(self, context: ParseContext) -> List[List[str]]:
        pass # Do Nothing so label isn't replaced

@dataclass
class PseudoSet(_PseudoInstruction):
    register1: Register
    offset: str
    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list("set", {"rd": self.register1.name, "imm12": self.offset})
        context.replace_pseudo_instruction(self.meta.line, replacement)

class PseudoLoadVar(_PseudoInstruction):
    register: Register
    var_name: str
    offset: str

    def __init__(self, meta, register: Register, var_name: str, offset: str = "0"):
        super().__init__(meta)
        self.var_name = var_name
        self.register = register
        self.offset = offset

    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list(
            "loadvar", {"rd": self.register.name, "var_name": self.var_name, "offset": self.offset})
        context.replace_pseudo_instruction(self.meta.line, replacement)

class PseudoReturn(_PseudoInstruction):
    def replace(self, context: PseudoContext):
        replacement = self._get_replaced_list("ret", {})
        context.replace_pseudo_instruction(self.meta.line, replacement)


def pseudo_parse(parser, text) -> str:
    this_module = sys.modules[__name__]
    transformer = ast_utils.create_transformer(this_module, ToAstPseudo())
    pseudo_text = text
    pseudo_offset = {}
    while True:
        parse_tree = parser.parse(pseudo_text)
        ast: _AstMeta = transformer.transform(parse_tree)

        pseudoContext = PseudoContext(pseudo_text.split("\n"))
        for instruction in ast:
            if isinstance(instruction, _PseudoInstruction):
                instruction.replace(pseudoContext)
        pseudo_text, new_pseudo_offsets = pseudoContext.get_replaced_instructions()
        pseudo_text = "\n".join(pseudo_text)
        pseudo_offset = {x: pseudo_offset.get(x, 0) + new_pseudo_offsets.get(x, 0) for x in set(pseudo_offset).union(new_pseudo_offsets)}
        #../testAssemblyPseudo.dasmb
        # with open("software/assembler/testAssemblyPseudo.dasmb", "w") as file:
        #     file.write(pseudo_text)
        #     print("File written")
        if not pseudoContext.changed:
            break

    return pseudoContext.get_replaced_instructions()[0], pseudo_offset
