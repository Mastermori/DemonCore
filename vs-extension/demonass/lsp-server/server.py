import re as re
from pygls.server import LanguageServer
import lsprotocol.types as types
from lsprotocol.types import (CompletionItem, CompletionList, CompletionOptions,
                              CompletionParams, HoverParams, Hover)
from urllib.parse import urlparse, unquote

default_host = "127.0.0.1"
default_port = 8080

server = LanguageServer('DemonAssembler-Server', 'v0.1')

def main(): 
    server.start_tcp(default_host, default_port)

@server.feature(types.TEXT_DOCUMENT_COMPLETION, CompletionOptions(trigger_characters=[',']))
def completions(params: CompletionParams):
    """Returns completion items."""
    print(params)
    return CompletionList(
        is_incomplete=False,
        items=[
            CompletionItem(label='Item1'),
            CompletionItem(label='Item2'),
            CompletionItem(label='Item3'),
        ]
    )

@server.feature(types.TEXT_DOCUMENT_HOVER)
def handle_hover(params: HoverParams):
    file_path = unquote(urlparse(params.text_document.uri).path)
    print(file_path[1:])
    edited_file = open(file_path[1:])
    lines = edited_file.read().split("\n")
    line = params.position.line
    character = params.position.character
    word = find_word(lines[line], character)
    print(word)
    edited_file.close()
    return Hover(contents=f"Line: {line}, Character: {character}, Word: {word}")

def find_word(line: str, position: int) -> str:
    word_indices = [(ele.start(), ele.end() - 1) for ele in re.finditer(r'\w+|\d+', line)]
    for i in word_indices:
        if i[0] <= position and i[1] >= position:
            print(i)
            return line[i[0]:i[1]+1]
    return line[position]

if __name__ == "__main__":
    main()