import abc
from dataclasses import dataclass
from typing import List
from demonass_parser.ast_base import _Ast, _AstMeta, ParseContext, Register
from demonass_parser.ast_pseudo import _PseudoInstruction


@dataclass
class _Label(_Ast):
    name: str
    jump_address: int

    def __init__(self, name: str):
        super().__init__()
        self.name = name

    def get_addr(self) -> int:
        return self.jump_address


class GlobalLabel(_Label):
    pass


class LocalLabel(_Label):
    pass


class _Directive(_AstMeta):
    pass


@dataclass
class AddressDirective(_Directive):
    address: str

    def run(self, context: ParseContext) -> None:
        context.set_ram_address(int(self.address))


@dataclass
class _FlowControlPseudoInstruction(_PseudoInstruction):
    label_name: str
    label_offset: int

    def __init__(self, meta, label_name: str):
        super().__init__(meta)
        self.label_name = label_name

    def replace(self, context: ParseContext) -> None:
        context.add_flow_command(self)

    @abc.abstractmethod
    def get_instructions(self, context: ParseContext) -> List[str]:
        pass

    @abc.abstractmethod
    def get_instruction_count(self) -> int:
        pass


class PseudoJump(_FlowControlPseudoInstruction):

    def get_instructions(self, context: ParseContext, labelOffset: int) -> List[str]:
        return self._get_replaced_list("j", {"offset": str(labelOffset)})

    def get_instruction_count(self) -> int:
        return 1


class PseudoCall(_FlowControlPseudoInstruction):
    rd: str

    def __init__(self, meta, labelName, rd="x1"):
        super().__init__(meta, labelName)
        if isinstance(rd, Register):
            rd = rd.name
        self.rd = rd

    def get_instructions(self, context: ParseContext, labelOffset: int) -> List[str]:
        return self._get_replaced_list("call", {"rd": self.rd, "offsetLo": str(labelOffset & 0xfff), "offsetHi": str(labelOffset >> 12)})

    def get_instruction_count(self) -> int:
        return 2
