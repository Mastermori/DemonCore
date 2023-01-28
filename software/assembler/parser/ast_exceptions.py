


class AssemblerSyntaxError(SyntaxError):
    line: int
    column: int
    conntext: str

    def __init__(self, *args: tuple) -> None:
        super().__init__(args)
        self.context, self.line, self.column = args

    def __str__(self):
        return '%s at line %s, column %s.\n\n%s' % (self.label, self.line, self.column, self.context)

class AssemblerInvalidRegisterError(AssemblerSyntaxError):
    label = "Invalid Register"

class AssemblerInvalidNumberError(AssemblerSyntaxError):
    label = "Invalid Number"

class AssemblerInvalidVariableError(AssemblerSyntaxError):
    label = "Invalid Variable"

class AssemblerUndefindVariableError(AssemblerSyntaxError):
    label = "Undefined Variable"

class AssemblerMissingCommaError(AssemblerSyntaxError):
    label = "Missing Comma"

class AssemblerMissingOpenParensError(AssemblerSyntaxError):
    label = "Missing Opening Parenthesis"

class AssemblerMissingCloseParensError(AssemblerSyntaxError):
    label = "Missing Closing Parenthesis"

class AssemblerInvalidSymbolError(AssemblerSyntaxError):
    label = "Invalid Symbol"