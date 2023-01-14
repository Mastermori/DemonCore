import sys
import abc
import re

from lark import Lark, ast_utils, Transformer, v_args, Token

from parser_base import *
from parser_control import *
from parser_instructions import *
from parser_variables import *
from parser_base import _Ast
from parser_control import _Label
from parser_instructions import _DirectInstruction

l = Lark.open("../grammar.lark", rel_to=__file__, propagate_positions=True)


def createTree(file):
    return l.parse(file)


this_module = sys.modules[__name__]

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
            return int(token.value, int(token.type.split("_")[-1]))
        return token

    @v_args(inline=True)
    def start(self, *x):
        return x



transformer = ast_utils.create_transformer(this_module, ToAst())


def parse(text):
    tree = l.parse(text)
    return transformer.transform(tree)


def main():
    file_contents = open("software/assembler/testAssembly.dasmb", "r").read()
    reference_lines = file_contents.split("\n")
    ast: _Ast = parse(file_contents)
    print(ast)
    parseContext = ParseContext(reference_lines)
    for token in ast:
        if token is _Label:
            parseContext.add_label(token)

    for token in ast:
        if isinstance(token, _DirectInstruction):
            parseContext.append_raw_instruction(
                [token.get_raw_instruction(parseContext)], token.meta.line)
    print("\n".join(parseContext.instruction_strings))


if __name__ == '__main__':
    main()
