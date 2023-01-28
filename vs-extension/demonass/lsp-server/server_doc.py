import abc
import re as re
import dictionaries
import lsprotocol.types as types
from dataclasses import dataclass
from typing import Dict, List
from lsprotocol.types import (CompletionItem, Hover, SignatureInformation, ParameterInformation)


@dataclass
class ParamDefinition(abc.ABC):
    name: str
    description: str

    @abc.abstractmethod
    def get_completion(self) -> List[CompletionItem]:
        pass
    
    def get_param_info(self) -> ParameterInformation:
        return ParameterInformation(self.name, self.description)


class RegisterParamDefinition(ParamDefinition):

    def __init__(self, name: str, description: str):
        super().__init__(name, description)

    def get_completion(self) -> List[CompletionItem]:
        items = []
        for register in dictionaries.registers:
            items.append(CompletionItem(
                label=register, kind=types.CompletionItemKind.Variable, detail=dictionaries.registers[register]))
        return items


# TODO: implement for %hi and %lo
class ImmediateParamDefinition(ParamDefinition):
    def __init__(self, name: str, description: str):
        super().__init__(name, description)

    def get_completion(self) -> List[CompletionItem]:
        return []


class InstructionDefinition(abc.ABC):
    indentation_level = 10

    name: str
    type: str
    param_definitions: List[ParamDefinition]
    documentation: types.MarkupContent
    description: str
    deprecated = False

    def __init__(self, name: str, type: str, param_definitions: List[ParamDefinition], description: str = "") -> None:
        self.name = name
        self.type = type
        self.param_definitions = param_definitions
        self.set_description(description)

    def get_param_definition(self, param_index: int) -> ParamDefinition:
        if not self.param_definitions:
            return None
        if param_index >= len(self.param_definitions):
            return None
        return self.param_definitions[param_index]

    def get_param_completion(self, param_index) -> List[CompletionItem]:
        if param_index >= len(self.param_definitions):
            return []
        return self.param_definitions[param_index].get_completion()

    def get_completion(self) -> CompletionItem:
        name = self.name
        indentation = ' ' * \
            (InstructionDefinition.indentation_level - len(name))
        insert_text = self.get_insert_text(indentation)
        return CompletionItem(label=name, insert_text=insert_text,
                              kind=types.CompletionItemKind.Method, insert_text_format=types.InsertTextFormat.Snippet,
                              documentation=self.get_description(), command=types.Command("", "editor.action.triggerParameterHints"),
                              tags=[types.CompletionItemTag.Deprecated] if self.deprecated else None, sort_text="zzz" if self.deprecated else None)

    def get_hover(self) -> Hover:
        return Hover(contents=self.get_description())

    def get_signature_info(self) -> SignatureInformation:
        parameters = []
        for param in self.param_definitions:
            parameters.append(param.get_param_info())
        return SignatureInformation(label=self.get_signature_label(), documentation=self.description, parameters=parameters)

    def get_signature_label(self) -> str:
        return re.sub(r"\${\d+:(\w+)}", r"\1", self.get_insert_text())

    def _set_markdown_documentation(self) -> None:
        lines = []
        if self.deprecated:
            lines.append("## Deprecated  \n")
        lines.extend([
            '**' + self.get_signature_label() + '**',
            '\n---\n',
        ])
        lines.extend(self.description.split("\n"))
        lines.append("\nParameters:  ")
        for param_def in self.param_definitions:
            indentation = "&nbsp;" * (10 - len(param_def.name))
            lines.append(
                f"&nbsp;&nbsp;&nbsp;&nbsp;{param_def.name}:{indentation}{param_def.description}  ")
        self.documentation = types.MarkupContent(
            types.MarkupKind.Markdown,
            '\n'.join(lines)
        )

    def set_description(self, description: str) -> None:
        self.description = description
        self._set_markdown_documentation()

    def get_description(self) -> types.MarkupContent:
        return self.documentation

    def set_deprecated(self, deprecated: bool) -> None:
        self.deprecated = deprecated
        self._set_markdown_documentation()
    
    def get_snippet(self, index: int) -> str:
        return f"${{{index+1}:{self.param_definitions[index].name}}}"

    @abc.abstractmethod
    def get_insert_text(self, indentation=" ") -> str:
        pass


class RegisterInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "register", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "First operation register"),
            RegisterParamDefinition("rs2", "Second operation register")
        ], "Computes *rs1* and *rs2* into *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class ImmediateInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "immediate", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "First operation register"),
            ImmediateParamDefinition("imm12", "12-bit immediate value")
        ], "Computes *rs1* and *imm12* to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class ImmediateshamtInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "immediate", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "Register to shift"),
            ImmediateParamDefinition(
                "shamt", "5-bit immediate value to shift with")
        ], "Shifts *rs1* by *shamt* and writes the result to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class LoadInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "load", [
            RegisterParamDefinition("rd", "Register that will be loaded to"),
            ImmediateParamDefinition(
                "offset", "12-bit immediate offset added to *rs1*"),
            RegisterParamDefinition(
                "rs1", "Memory address to load from (+ *offset*)")
        ], "Loads memory at address *rs1* + *offset* and writes the value to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"


class SaveInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "save", [
            RegisterParamDefinition("rs1", "Register that will be saved"),
            ImmediateParamDefinition(
                "offset", "12-bit immediate offset added to *rs2*"),
            RegisterParamDefinition(
                "rs2", "Memory address to save *rs1* to (+ *offset*)")
        ], "Saves *rs1* to memory at address *rs2* + *offset*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"

class JumpregisterInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "jumpregister", [
            RegisterParamDefinition("rd", "Register to save return address to"),
            ImmediateParamDefinition(
                "offset", "12-bit immediate offset added to *rs1*"),
            RegisterParamDefinition(
                "rs1", "Address to jump to (set pc to)")
        ], "Writes the return address (pc) to *rd* and jumps to address *rs1* + *offset*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"


class BranchInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "branch", [
            RegisterParamDefinition("rs1", "First register to compare"),
            RegisterParamDefinition("rs2", "Second register to compare"),
            ImmediateParamDefinition(
                "offset", "12-bit immediate offset that will be added to pc")
        ], "Branches (adds *offset* to pc) if the condition with *rs1* and *rs2* is fullfilled.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class BigimmediateInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str) -> None:
        super().__init__(name, "bigimmediate", [
            RegisterParamDefinition("rd", "Destination register"),
            ImmediateParamDefinition("imm20", "Immediate value to compute")
        ], "Computes *imm20* and saves result to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}"


class ParseContext:
    current_type: str
    current_instruction: InstructionDefinition


class AssemblerDoc:
    instructions: Dict[str, InstructionDefinition] = {}

    def __init__(self, file_path: str):
        self.instructions = self.parse(file_path)

    def parse(self, file_path: str):
        context = ParseContext()
        instructions = {}
        with open(file_path, "r") as file_content:
            for line in file_content:
                stripped = line.strip()
                if stripped.startswith("@"):
                    self.parse_annotation(line[1:], context)
                elif len(stripped) > 0:
                    name = stripped
                    instructions[name] = globals(
                    )[f"{context.current_type.capitalize()}InstructionDefinition"](name)
                    context.current_instruction = instructions[name]
        return instructions

    def parse_annotation(self, line: str, context: ParseContext):
        split_line = line.split(" ")
        annotation_name = split_line[0].strip()
        match annotation_name:
            case "type":
                type = split_line[1].strip()
                context.current_type = type
            case "param":
                name = split_line[1].strip()
                description = " ".join(split_line[2:]).removesuffix("\n")
                for param_definition in context.current_instruction.param_definitions:
                    if param_definition.name == name:
                        param_definition.description = description
            case "description":
                description = " ".join(split_line[1:]).removesuffix(
                    "\n").replace("\\n", "\n")
                context.current_instruction.set_description(description)
            case "deprecated":
                context.current_instruction.set_deprecated(True)

    def get_instruction_completions(self) -> List[CompletionItem]:
        return [definition.get_completion() for definition in self.instructions.values()]

    def get_param_completion_for_instruction(self, instruction_name: str, param_index: int) -> List[CompletionItem]:
        if instruction_name in self.instructions:
            instruction_definition = self.instructions[instruction_name]
            return instruction_definition.get_param_completion(param_index)
        return []

    def get_hover_for(self, name: str) -> Hover:
        if name in self.instructions:
            instruction_definition = self.instructions[name]
            return instruction_definition.get_hover()
        if name in dictionaries.registers:
            return Hover(contents=dictionaries.registers[name])
        return None

    def get_signature_info_for_instruction(self, instruction_name: str) -> SignatureInformation:
        if instruction_name in self.instructions:
            instruction_definition = self.instructions[instruction_name]
            return instruction_definition.get_signature_info()
        return None
