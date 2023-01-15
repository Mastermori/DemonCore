import abc
from dataclasses import dataclass
from typing import List

from ast_base import ParseContext, _ImmediateNumber, Register
from ast_instructions import _Instruction, ImmediateDirectInstruction, Mnemonic


@dataclass
class _PseudoInstruction(_Instruction):
    def __init__(self, meta, mnemonic_name: str):
        super().__init__(meta, Mnemonic(mnemonic_name, "pseudo"))

    @abc.abstractmethod
    def get_raw_instructions(self, context: ParseContext) -> List[List[str]]:
        pass


class PseudoNoArgs(_PseudoInstruction):
    def get_raw_instructions(self, context: ParseContext) -> List[List[str]]:
        match self.mnemonic.name.lower():
            case "nop":
                return [ImmediateDirectInstruction(self.meta, Mnemonic("addi", "i_type"), Register("x0"), Register("x0"), _ImmediateNumber(0)).get_raw_instruction(context)]
            case other:
                return None
