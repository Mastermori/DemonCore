import logging
import sys
import re

from lark import Lark, UnexpectedInput, ast_utils, Transformer, v_args, Token

from ast_base import *
from ast_control import *
from ast_instructions import *
from ast_variables import *
from ast_base import _ImmediateNumber
from ast_control import _Label, _Directive, _FlowControlPseudoInstruction
from ast_instructions import _DirectInstruction
from ast_pseudo import pseudo_parse
from util import chad_success

from tkinter.filedialog import askopenfilename

from ast_exceptions import AssemblerInvalidRegisterError, AssemblerSyntaxError, AssemblerInvalidNumberError, AssemblerMissingCommaError, AssemblerMissingOpenParensError, AssemblerMissingCloseParensError, AssemblerInvalidSymbolError


def start_logging(logging_level=logging.DEBUG, logging_show_time=False, format_level=1):
    method_format_str = "%(levelname)s: {%(filename)s:%(lineno)d} - %(funcName)s(): %(message)s"
    normal_format_str = "%(levelname)s: {%(filename)s:%(lineno)d}: %(message)s"
    minimal_format_str = "%(levelname)s: %(message)s"
    format_str = ""
    match format_level:
        case 0:
            format_str = minimal_format_str
        case 1:
            format_str = normal_format_str
        case 2:
            format_str = method_format_str
    logging.basicConfig(filename="software/assembler/assembler_debug.log",
                        format=f"{'[%(asctime)s] ' if logging_show_time else ''}{format_str}", level=logging_level, encoding='utf-8')

#
#   Define AST
#


class ToAst(ToAstInstructions):
    logging

    def __default_token__(self, token: Token):
        if token.type.startswith("__ANON"):
            logging.debug(f"Using own value {token.value} for {token.type}")
            return token.value
        if token.type.lower() == token.value.lower():
            logging.debug(f"Using own value {token.value} for {token.type}")
            return token.value
        if re.match("(imm|shamt|var_param_word).*", token.type.lower()):
            return _ImmediateNumber(int(token.value, int(token.type.split("_")[-1])))
        return token

    @v_args(inline=True)
    def start(self, *x):
        return x


this_module = sys.modules[__name__]
transformer = ast_utils.create_transformer(this_module, ToAst())


l = Lark.open("../grammar.lark", rel_to=__file__,
              propagate_positions=True, parser="earley")


def parse(text):
    try:
        reference_lines, pseudo_offset = pseudo_parse(l, text)
        pseudo_text = "\n".join(reference_lines)
        pseudo_parsed_tree = l.parse(pseudo_text)
        return transformer.transform(pseudo_parsed_tree), reference_lines, pseudo_offset
    except UnexpectedInput as u:
        error_class = u.match_examples(l.parse, {
            AssemblerInvalidRegisterError: [
                "add t",  # First register missing
                "add t0, t"  # Any register after comma missing
            ],
            AssemblerInvalidNumberError: [
                "addi t0, t0, ",  # [Missing IMM12]
                "slli t0, t0, "  # [Missing SHAMT]
                "lui t0, ",  # [Missing IMM20]
            ],
            AssemblerMissingCommaError: [
                "add t0",
                "add t0, t0",  # Register type
                "addi t0",
                "addi t0, t0",  # Immediate type
                "lw t0",  # Offset type
                "beq t0",
                "beq t0, t0",
                "slli t0",
                "slli t0, t0",  # Shift type
                "lui t0",  # Jump Upper type
                "jalr t0" # Jup Register type
            ],
            AssemblerMissingOpenParensError: [
                "lw t0, 0 t0)",  # Load type
                "sw t0, 0 t0)",  # Save tpye
                "jalr t0, 0 t0)"  # JumpLink type
            ],
            AssemblerMissingCloseParensError: [
                "lw t0, 0 (t0",  # Load type
                "sw t0, 0 (t0",  # Save tpye
                "jalr t0, 0 (t0"  # JumpLink type
            ],
            AssemblerInvalidSymbolError: [
                "a",
                "add t0, t0, t0 t"
            ]
        }, use_accepts=True)
        if not error_class:
            raise
        raise error_class(u.get_context(text), u.line, u.column)


class ContextParser:
    parseContext: ParseContext

    def __init__(self, lines_to_parse) -> None:
        self.ast, self.reference_lines, self.pseudo_offset = parse(
            lines_to_parse)
        self.parseContext = ParseContext(self.reference_lines)

    def parse_with_context(self) -> ParseContext:
        parseContext = self.parseContext
        parseContext.pseudo_offset_lines = self.pseudo_offset
        # Parse context:
        for token in self.ast:
            if isinstance(token, Variable):
                parseContext.add_variable(token)
            if isinstance(token, _Directive):
                token.run(parseContext)

        # Parse content (context-dependend)
        for token in self.ast:
            if isinstance(token, _Label):
                parseContext.add_label(token)
            if isinstance(token, _DirectInstruction):
                parseContext.append_raw_instructions(
                    [token.get_raw_instruction(parseContext)], token.meta.line)
            if isinstance(token, _FlowControlPseudoInstruction):
                token.replace(parseContext)

        return parseContext


def main():
    # "software/assembler/testAssembly.dasmb"
    choosenPath = ""
    if (len(sys.argv) > 1):
        choosenPath = sys.argv[1]
    else:
        choosenPath = askopenfilename()
    defaultPath = "software/assembler/testAssembly.dasmb"
    with open(defaultPath if choosenPath == "" else choosenPath, "r") as file:
        file_contents = file.read()

    parseContext = ContextParser(file_contents).parse_with_context()

    print("ROM:")
    rom_content = parseContext.get_compiled_instructions(l, transformer)
    print(rom_content)
    print("RAM:")
    print(parseContext.get_ram_content_str())
    # ../../../hardware/memorySim/rom_fill.dat
    with open("hardware/memorySim/rom_fill.dat", "w") as out_file:
        out_file.writelines(rom_content)
    # ../../../hardware/memorySim/ram_fill.dat
    with open("hardware/memorySim/ram_fill.dat", "w") as out_file:
        out_file.writelines(parseContext.get_ram_content_str())


if __name__ == '__main__':
    main()
