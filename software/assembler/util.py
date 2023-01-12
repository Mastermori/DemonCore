from lark import ParseTree
from dictionarys import registers

def get_subtree(tree: ParseTree, depth: int, index: int = 0):
    subtree = tree
    for i in range(depth-1):
        subtree = subtree.children[0]
    return subtree.children[index]

def register_lookup(register_str) -> int:
    return f'{int(registers[register_str]):05b}'

def two_complement(a: int, b: int):
    bitmask = '1'*b
    if (a < 0):
        temp = int(bin(int(a))[3:], 2) ^ int(bitmask, 2)
        return f'{temp+1:{b}b}'
    else:
        return f'{int(a):0{b}b}'
