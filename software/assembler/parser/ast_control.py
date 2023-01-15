from dataclasses import dataclass
from ast_base import _AstMeta


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