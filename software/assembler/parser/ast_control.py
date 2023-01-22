from dataclasses import dataclass
from ast_base import _AstMeta, ParseContext


@dataclass
class _Label(_AstMeta):
    name: str

    def get_addr_line(self) -> int:
        self.meta.line + 1


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