import sys
import re

from lark import Lark, ast_utils, Transformer, v_args, Token

from ast_base import *
from ast_control import *
from ast_instructions import *
from ast_variables import *
from ast_pseudo import *
from ast_base import _Ast, _ImmediateNumber
from ast_control import _Label
from ast_instructions import _DirectInstruction
from ast_pseudo import _PseudoInstruction

#
#   Define AST
#
class ToAst(ToAstInstructions):
    def __default_token__(self, token: Token):
        if token.type.startswith("__ANON"):
            return token.value
        if token.type.lower() == token.value.lower():
            return token.value
        if re.match("(imm|shamt|var_param_word).*", token.type.lower()):
            return _ImmediateNumber(int(token.value, int(token.type.split("_")[-1])))
        return token

    @v_args(inline=True)
    def start(self, *x):
        return x


this_module = sys.modules[__name__]
transformer = ast_utils.create_transformer(this_module, ToAst())


l = Lark.open("../grammar.lark", rel_to=__file__, propagate_positions=True)


def parse(text):
    tree = l.parse(text)
    return transformer.transform(tree)


def main():
    with open("software/assembler/testAssembly.dasmb", "r") as file:
        file_contents = file.read()
    reference_lines = file_contents.split("\n")
    ast: _Ast = parse(file_contents)
    print(ast)
    parseContext = ParseContext(reference_lines)
    # Parse context:
    for token in ast:
        if isinstance(token, _Label):
            parseContext.add_label(token)
        if isinstance(token, Variable):
            parseContext.add_varaible(token)

    # Parse content (context-dependend)
    for token in ast:
        if isinstance(token, _DirectInstruction):
            parseContext.append_raw_instructions(
                [token.get_raw_instruction(parseContext)], token.meta.line)
        if isinstance(token, _PseudoInstruction):
            parseContext.append_raw_instructions(
                token.get_raw_instructions(parseContext), token.meta.line)

    print("ROM:")
    print("\n".join(parseContext.instruction_strings))
    print("RAM:")
    print(parseContext.get_ram_content_str())

    with open("hardware/memorySim/rom_fill.dat", "w") as out_file:
        out_file.writelines("\n".join(parseContext.instruction_strings))
    
    with open("hardware/memorySim/ram_fill.dat", "w") as out_file:
        out_file.writelines(parseContext.get_ram_content_str())


if __name__ == '__main__':
    main()
