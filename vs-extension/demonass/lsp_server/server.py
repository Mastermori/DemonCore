import difflib
from json import JSONDecodeError
import re as re
from typing import Dict, List
from lark import UnexpectedInput
from pygls.server import LanguageServer
import lsprotocol.types as gls
from lsprotocol.types import (CompletionList, CompletionOptions, CompletionParams, SignatureHelpOptions,
                              SignatureHelpParams, HoverParams, SignatureHelp, TypeDefinitionParams, ReferenceParams)
from urllib.parse import urlparse, unquote

from demonass_parser.asm_parser import ContextParser
from demonass_parser.ast_base import ParseContext

from .server_doc import AssemblerDoc, indentation_level


server = LanguageServer('DemonAssembler-Server', 'v0.1')

documents: Dict[str, List[str]] = {}


def start(args):
    print("Server starting..")
    if args.tcp:
        server.start_tcp(args.host, args.port)
    else:
        print("in io mode!")
        server.start_io()


doc = AssemblerDoc("lsp_server/instruction_doc.ddoc")
last_context: ParseContext = None


@server.feature(gls.TEXT_DOCUMENT_COMPLETION, CompletionOptions(trigger_characters=[',']))
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
            probable_mnemonic, param_index, last_context)
        items.extend(param_completions)
    elif len(split_line) == 1:
        items.extend(doc.get_instruction_completions())
    return CompletionList(
        is_incomplete=False,
        items=items
    )


@server.feature(gls.TEXT_DOCUMENT_HOVER)
def handle_hover(params: HoverParams):
    lines = get_file_contents(params.text_document.uri)
    line = params.position.line
    character = params.position.character
    word, range = find_word(lines[line], character)
    hover = doc.get_hover_for(word, last_context)
    if hover:
        return hover
    # return Hover(contents=f"Line: {line}, Character: {character}, Word: {word}")


@server.feature(gls.TEXT_DOCUMENT_SIGNATURE_HELP, SignatureHelpOptions(trigger_characters=[',', '(']))
def signature_help(params: SignatureHelpParams):
    line = get_file_contents(params.text_document.uri)[params.position.line]
    line_to_cursor = line[:params.position.character]
    split_line = line_to_cursor.split(" ")
    param_index = line_to_cursor.count(",") + line_to_cursor.count("(")
    signature_information = doc.get_signature_info_for_instruction(
        split_line[0])
    if signature_information:
        return SignatureHelp([signature_information], active_parameter=param_index)


@server.feature(gls.TEXT_DOCUMENT_DEFINITION)
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
        end_index = found_index + range[1] - range[0] + 1
        line = lines[line_index]
        if end_index < len(line) and line[end_index] == ":":
            return gls.Location(params.text_document.uri, gls.Range(gls.Position(line_index, found_index), gls.Position(line_index, end_index)))


@server.feature(gls.TEXT_DOCUMENT_REFERENCES)
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
        end_index = found_index + range[1] - range[0] + 1
        found_locations.append(gls.Location(params.text_document.uri, gls.Range(
            gls.Position(line_index, found_index), gls.Position(line_index, end_index))))
    return found_locations


@server.feature(gls.TEXT_DOCUMENT_FORMATTING)
def format_document(params: gls.DocumentFormattingParams):
    lines = get_file_contents(params.text_document.uri)
    options = params.options
    edits = []
    for line_index, line in enumerate(lines):
        starts_with = line.lstrip().split(" ")[0]
        if starts_with in doc.instructions:
            format_instruction(edits, line_index, line, starts_with, options)
    return edits


def format_instruction(edits: List, line_index: int, line: str, starts_with: str, options: gls.FormattingOptions):
    print(f"Found instruction: {starts_with}")
    expected_indentation_level = indentation_level - len(starts_with)
    while expected_indentation_level <= 0:
        # Check if word is to long and indentation needs to be increased.
        expected_indentation_level += 1
    actual_indentation = len(re.findall("\s+", line.lstrip())[0])
    if expected_indentation_level != actual_indentation:
        print(f"Edited instruction: {starts_with}")
        start_char = line.find(starts_with) + len(starts_with)
        end_char = start_char + actual_indentation
        edits.append(get_text_edit(line_index, start_char,
                     end_char, " " * expected_indentation_level))
    if options.trim_trailing_whitespace:
        stripped_line_len = len(line.rstrip())
        to_remove = len(line) - stripped_line_len
        if to_remove > 0:
            edits.append(get_text_edit(
                line_index, stripped_line_len, len(line)-1, ""))

    #     if options.trim_trailing_whitespace:
    #         edits.append()
    #         new_lines[line_index] = line.replace(r"\s+$", "")
    #     split_line = line.replace(r"\s+", " ").split(" ")
    #     instruction_name = split_line[0]
    #     if instruction_name in doc.instructions:
    #         indentation = " " * (indentation_level - len(split_line[0]))
    #         new_lines[line_index] = split_line[0] + indentation + " ".join(split_line[1:])
    # # if options.trim_final_newlines:
    #     last_clean_line = len(new_lines)
    #     for line in new_lines.reverse():
    #         if re.match(r"\S+", line):
    #             break
    #         last_clean_line -= 1
    #     new_lines = new_lines[:last_clean_line]
    # server.show_message_log("\n".join(new_lines))


# def generate_edit(old_line, new_line, line_index) -> List[gls.TextEdit]:
#     current_start = len(old_line)+len(new_line)
#     operation = " "
#     current_diff = ""
#     changes = []
#     for i, s in enumerate(difflib.ndiff(old_line, new_line)):
#         distance = i - current_start
#         if distance > 1:
#             changes.append(get_text_edit(line_index, current_start, i))
#         if s[0] == ' ':
#             continue
#         elif s[0] == '-':
#             pass


def get_text_edit(line_index, char_start, char_end, change):
    return gls.TextEdit(gls.Range(
        gls.Position(line_index, char_start),
        gls.Position(line_index, char_end)
    ), change)


@server.feature(gls.TEXT_DOCUMENT_DID_CHANGE)
def did_change(params: gls.DidChangeTextDocumentParams):
    """Text document did change notification."""
    _validate(params)


@server.feature(gls.TEXT_DOCUMENT_DID_CLOSE)
def did_close(params: gls.DidCloseTextDocumentParams):
    """Text document did close notification."""
    server.show_message('Text Document Did Close')


@server.feature(gls.TEXT_DOCUMENT_DID_OPEN)
async def did_open(params: gls.DidOpenTextDocumentParams):
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
        parse_context = ContextParser(source).parse_with_context()
        global last_context
        last_context = parse_context
        for error in parse_context.get_errors():
            msg = error.msg
            col = error.colno
            line = error.lineno

            d = gls.Diagnostic(
                range=gls.Range(
                    start=gls.Position(line=line - 1, character=col - 1),
                    end=gls.Position(line=line - 1, character=col)
                ),
                message=msg,
                source=type(server).__name__
            )
            diagnostics.append(d)
    except UnexpectedInput as err:
        # msg = err.msg
        msg = err.msg if hasattr(err, "msg") else f"{str(err)}"
        col = err.column
        line = err.line
        add_error(msg, line, col, diagnostics)
    except SyntaxError as err:
        msg = str(err)
        col = err.column
        line = err.line
        add_error(msg, line, col, diagnostics)
    return diagnostics


def add_error(msg, line, col, diagnostics):
    d = gls.Diagnostic(
        range=gls.Range(
            start=gls.Position(line=line - 1, character=col - 1),
            end=gls.Position(line=line - 1, character=col)
        ),
        message=msg,
        source=type(server).__name__
    )
    diagnostics.append(d)


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
    if line[position] == ":":
        return find_word(line, position-1)
    word_indices = [(ele.start(), ele.end() - 1)
                    for ele in re.finditer(r'\w+|\d+', line)]
    for i in word_indices:
        if i[0] <= position and i[1] >= position:
            return line[i[0]:i[1]+1], i
    return line[position], (position, position)


def find_word_from_position(file_lines: List[str], position: gls.Position) -> str:
    return find_word(file_lines[position.line], position.character)
