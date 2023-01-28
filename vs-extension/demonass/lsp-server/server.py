from json import JSONDecodeError
import os
import re as re
import sys
from typing import Dict, List
from lark import UnexpectedInput
from pygls.server import LanguageServer
import lsprotocol.types as types
from lsprotocol.types import (CompletionList, CompletionOptions, CompletionParams, SignatureHelpOptions,
                              SignatureHelpParams, HoverParams, SignatureHelp, TypeDefinitionParams, ReferenceParams)
from urllib.parse import urlparse, unquote
from server_doc import AssemblerDoc

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(
    SCRIPT_DIR + "/../../../software/assembler/parser/"))
from asm_parser import parse_with_context

default_host = "127.0.0.1"
default_port = 8080

server = LanguageServer('DemonAssembler-Server', 'v0.1')

documents: Dict[str, List[str]] = {}


def main():
    print("Server started!")
    server.start_tcp(default_host, default_port)


doc = AssemblerDoc("lsp-server/instruction_doc.txt")


@server.feature(types.TEXT_DOCUMENT_COMPLETION, CompletionOptions(trigger_characters=[',']))
def completions(params: CompletionParams):
    """Returns completion items."""
    line = get_file_contents(params.text_document.uri)[params.position.line]
    line_to_cursor = line[:params.position.character]
    split_line = line_to_cursor.split(" ")
    items = []
    if len(split_line) > 1:
        probable_mnemonic = split_line[0]
        param_index = line_to_cursor.count(",") + line_to_cursor.count("(")
        param_completions = doc.get_param_completion_for_instruction(
            probable_mnemonic, param_index)
        items.extend(param_completions)
    elif len(split_line) == 1:
        items.extend(doc.get_instruction_completions())
    return CompletionList(
        is_incomplete=False,
        items=items
    )


@server.feature(types.TEXT_DOCUMENT_HOVER)
def handle_hover(params: HoverParams):
    lines = get_file_contents(params.text_document.uri)
    line = params.position.line
    character = params.position.character
    word, range = find_word(lines[line], character)
    hover = doc.get_hover_for(word)
    if hover:
        return hover
    # , range=types.Range())
    # return Hover(contents=f"Line: {line}, Character: {character}, Word: {word}")


@server.feature(types.TEXT_DOCUMENT_SIGNATURE_HELP, SignatureHelpOptions(trigger_characters=[',', '(']))
def signature_help(params: SignatureHelpParams):
    line = get_file_contents(params.text_document.uri)[params.position.line]
    line_to_cursor = line[:params.position.character]
    split_line = line_to_cursor.split(" ")
    param_index = line_to_cursor.count(",") + line_to_cursor.count("(")
    signature_information = doc.get_signature_info_for_instruction(
        split_line[0])
    if signature_information:
        return SignatureHelp([signature_information], active_parameter=param_index)


@server.feature(types.TEXT_DOCUMENT_DEFINITION)
def goto_definition(params: TypeDefinitionParams):
    lines = get_file_contents(params.text_document.uri)
    position = params.position
    word, range = find_word_from_position(lines, position)
    if len(word.strip()) < 1:
        return None
    for line_index, line in enumerate(lines):
        found_index = line.find(word)
        if found_index < 0:
            continue
        end_index = found_index + range[1] - range[0]
        if lines[line_index][end_index+1] == ":":
            return types.Location(params.text_document.uri, types.Range(types.Position(line_index, found_index), types.Position(line_index, end_index)))


@server.feature(types.TEXT_DOCUMENT_REFERENCES)
def find_references(params: ReferenceParams):
    lines = get_file_contents(params.text_document.uri)
    position = params.position
    word, range = find_word_from_position(lines, position)
    if len(word.strip()) < 1:
        return None
    found_locations = []
    for line_index, line in enumerate(lines):
        found_index = line.find(word)
        if found_index < 0:
            continue
        end_index = found_index + range[1] - range[0]
        found_locations.append(types.Location(params.text_document.uri, types.Range(
            types.Position(line_index, found_index), types.Position(line_index, end_index))))
    return found_locations


@server.feature(types.TEXT_DOCUMENT_DID_CHANGE)
def did_change(params: types.DidChangeTextDocumentParams):
    """Text document did change notification."""
    _validate(params)


@server.feature(types.TEXT_DOCUMENT_DID_CLOSE)
def did_close(params: types.DidCloseTextDocumentParams):
    """Text document did close notification."""
    server.show_message('Text Document Did Close')


@server.feature(types.TEXT_DOCUMENT_DID_OPEN)
async def did_open(params: types.DidOpenTextDocumentParams):
    """Text document did open notification."""
    server.show_message('Text Document Did Open')
    _validate(params)


def _validate(params):
    server.show_message_log('Validating assembler code...')

    text_doc = server.workspace.get_document(params.text_document.uri)

    source = text_doc.source
    diagnostics = _validate_assembler(source) if source else []

    server.publish_diagnostics(text_doc.uri, diagnostics)


def _validate_assembler(source: str):
    diagnostics = []

    try:
        parse_context = parse_with_context(source)
        for error in parse_context.get_errors():
            msg = error.msg
            col = error.colno
            line = error.lineno

            d = types.Diagnostic(
                range=types.Range(
                    start=types.Position(line=line - 1, character=col - 1),
                    end=types.Position(line=line - 1, character=col)
                ),
                message=msg,
                source=type(server).__name__
            )
            diagnostics.append(d)
        # diagnostics.extend(parse_context.get_errors())
    except UnexpectedInput as err:
        # msg = err.msg
        msg = f"There is an {type(err).__name__} here."
        print(err.args)
        col = err.column
        line = err.line

        d = types.Diagnostic(
            range=types.Range(
                start=types.Position(line=line - 1, character=col - 1),
                end=types.Position(line=line - 1, character=col)
            ),
            message=msg,
            source=type(server).__name__
        )

        diagnostics.append(d)
        print("Error occured during diagnostics")

    return diagnostics


def read_file_contents(uri: str) -> List[str]:
    file_path = unquote(urlparse(uri).path)
    with open(file_path[1:]) as edited_file:
        return edited_file.read().split("\n")


def get_file_contents(uri: str) -> List[str]:
    return server.workspace.get_document(uri).lines


def find_word(line: str, position: int) -> str:
    line = line.removesuffix("\n").removesuffix("\r")
    if position == len(line):
        return find_word(line, position - 1)
    word_indices = [(ele.start(), ele.end() - 1)
                    for ele in re.finditer(r'\w+|\d+', line)]
    for i in word_indices:
        if i[0] <= position and i[1] >= position:
            return line[i[0]:i[1]+1], i
    return line[position], (position, position)


def find_word_from_position(file_lines: List[str], position: types.Position) -> str:
    return find_word(file_lines[position.line], position.character)


if __name__ == "__main__":
    main()
