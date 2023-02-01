import abc
import re as re
from .dictionaries import registers
import lsprotocol.types as types
from dataclasses import dataclass
from typing import Dict, List
from lsprotocol.types import (
    CompletionItem, Hover, SignatureInformation, ParameterInformation)
from demonass_parser.dictionarys import pseudoDic
from demonass_parser.ast_base import ParseContext

indentation_level = 10


@dataclass
class ParamDefinition(abc.ABC):
    name: str
    description: str

    @abc.abstractmethod
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        pass

    def get_param_info(self) -> ParameterInformation:
        return ParameterInformation(self.name, self.description)


class RegisterParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        items = []
        for register in registers:
            items.append(CompletionItem(
                label=register, kind=types.CompletionItemKind.Variable, detail=registers[register]))
        return items


class Immediate5ParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        items = []
        items.append(CompletionItem(
            label="0", kind=types.CompletionItemKind.Constant, detail=f"Number"))
        return items

class Immediate12ParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        items = []
        items.append(CompletionItem(
            label="0", kind=types.CompletionItemKind.Constant, detail=f"Number"))
        items.append(CompletionItem(
            label="%lo", kind=types.CompletionItemKind.Variable, detail=f"Lower 12 address bits",
            insert_text=f"%lo(${{1:var}})",
            insert_text_format=types.InsertTextFormat.Snippet))
        return items

class Immediate20ParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        items = []
        items.append(CompletionItem(
            label="0", kind=types.CompletionItemKind.Constant, detail=f"Number"))
        items.append(CompletionItem(
            label="%hi", kind=types.CompletionItemKind.Variable, detail=f"Higher 20 address bits",
            insert_text=f"%hi(${{1:var}})",
            insert_text_format=types.InsertTextFormat.Snippet))
        return items

class VariableParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        if not context:
            return []
        items = []
        for var_name, variable in context.variables.items():
            items.append(CompletionItem(
                label=var_name, kind=types.CompletionItemKind.Variable, detail=f"Memory address: {variable.address}"))
        return items


class LabelParamDefinition(ParamDefinition):
    def get_completion(self, context: ParseContext) -> List[CompletionItem]:
        if not context:
            return []
        items = []
        for label_name in context.labels:
            items.append(CompletionItem(
                label=label_name, kind=types.CompletionItemKind.Variable, detail=f"Label"))
        return items


class InstructionDefinition(abc.ABC):
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

    def get_param_completion(self, param_index: int, context: ParseContext) -> List[CompletionItem]:
        if param_index >= len(self.param_definitions):
            return []
        return self.param_definitions[param_index].get_completion(context)

    def get_completion(self) -> CompletionItem:
        name = self.name
        indentation = ' ' * \
            (indentation_level - len(name))
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
        return SignatureInformation(label=self.get_signature_label(), documentation=types.MarkupContent(types.MarkupKind.Markdown, self.description), parameters=parameters)

    def get_signature_label(self) -> str:
        return re.sub(r"\${\d+:(\w+)}", r"\1", self.get_insert_text())

    def _set_markdown_documentation(self) -> None:
        lines = []
        if self.deprecated:
            lines.append("## Deprecated  \n")
        lines.extend([
            '**' + self.get_signature_label().rstrip() + '**',
            '\n---\n',
        ])
        lines.append(self.description)
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

    def get_snippet_by_name(self, name: str) -> str:
        for definition in self.param_definitions:
            if definition.name == name:
                return self.get_snippet(self.param_definitions.index(definition))
        raise ValueError(
            f"Param definition {name} not found in {self.__name__}")

    @abc.abstractmethod
    def get_insert_text(self, indentation=" ") -> str:
        pass


class RegisterInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "register", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "First operation register"),
            RegisterParamDefinition("rs2", "Second operation register")
        ], "Computes *rs1* and *rs2* into *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class ImmediateInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "immediate", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "First operation register"),
            Immediate12ParamDefinition("imm12", "12-bit immediate value")
        ], "Computes *rs1* and *imm12* to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class ImmediateshamtInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "immediate", [
            RegisterParamDefinition("rd", "Destination register"),
            RegisterParamDefinition("rs1", "Register to shift"),
            Immediate5ParamDefinition(
                "shamt", "5-bit immediate value to shift with")
        ], "Shifts *rs1* by *shamt* and writes the result to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class LoadInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "load", [
            RegisterParamDefinition("rd", "Register that will be loaded to"),
            Immediate12ParamDefinition(
                "offset", "12-bit immediate offset added to *rs1*"),
            RegisterParamDefinition(
                "rs1", "Memory address to load from (+ *offset*)")
        ], "Loads memory at address *rs1* + *offset* and writes the value to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"


class SaveInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "save", [
            RegisterParamDefinition("rs1", "Register that will be saved"),
            Immediate12ParamDefinition(
                "offset", "12-bit immediate offset added to *rs2*"),
            RegisterParamDefinition(
                "rs2", "Memory address to save *rs1* to (+ *offset*)")
        ], "Saves *rs1* to memory at address *rs2* + *offset*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"


class JumpregisterInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "jumpregister", [
            RegisterParamDefinition(
                "rd", "Register to save return address to"),
            Immediate12ParamDefinition(
                "offset", "12-bit immediate offset added to *rs1*"),
            RegisterParamDefinition(
                "rs1", "Address to jump to (set pc to)")
        ], "Writes the return address (pc) to *rd* and jumps to address *rs1* + *offset*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}({self.get_snippet(2)})"


class BranchInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "branch", [
            RegisterParamDefinition("rs1", "First register to compare"),
            RegisterParamDefinition("rs2", "Second register to compare"),
            Immediate12ParamDefinition(
                "offset", "12-bit immediate offset that will be added to pc")
        ], "Branches (adds *offset* to pc) if the condition with *rs1* and *rs2* is fullfilled.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}, {self.get_snippet(2)}"


class BigimmediateInstructionDefinition(InstructionDefinition):
    def __init__(self, name: str, context) -> None:
        super().__init__(name, "bigimmediate", [
            RegisterParamDefinition("rd", "Destination register"),
            Immediate20ParamDefinition("imm20", "Immediate value to compute")
        ], "Computes *imm20* and saves result to *rd*.")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}{self.get_snippet(0)}, {self.get_snippet(1)}"


class DocParseContext:
    current_type: str
    current_instruction: InstructionDefinition
    current_pseudo_param_format: str
    current_description: str
    is_description: bool

    def __init__(self) -> None:
        self.current_type = None
        self.current_instruction = None
        self.current_pseudo_param_format = ""
        self.current_description = ""
        self.is_description = False


class PseudoInstructionDefinition(InstructionDefinition):
    format: str
    expands_to_description: str

    def __init__(self, name: str, context: DocParseContext) -> None:
        param_definitions = []
        format_string = context.current_pseudo_param_format
        self.format = format_string
        self.expands_to_description = (
            ("Expands to:\n```demonass\n"
             + '\n'.join(pseudoDic[name])
             + "\n```")
            if name in pseudoDic else ""
        )
        for match in re.findall(r"(\w+):(\w+)", format_string):
            param_definitions.append(
                globals()[f"{match[1]}ParamDefinition"](match[0], ""))
        super().__init__(name, "pseudo", param_definitions)

    def set_description(self, description: str) -> None:
        return super().set_description(f"{description}\n\n{self.expands_to_description}")

    def get_insert_text(self, indentation=" ") -> str:
        return f"{self.name}{indentation}" + re.sub(r"(\w+):(\w+)", lambda match: self.get_snippet_by_name(match.groups()[0]), self.format).removesuffix("\n").removesuffix("\r")


class AssemblerDoc:
    instructions: Dict[str, InstructionDefinition] = {}

    def __init__(self, file_path: str):
        self.instructions = self.parse(file_path)

    def parse(self, file_path: str):
        context = DocParseContext()
        instructions = {}
        with open(file_path, "r") as file_content:
            for line in file_content:
                stripped = line.strip()
                if stripped.startswith("@"):
                    self.parse_annotation(line[1:], context)
                elif context.is_description:
                    context.current_description += line.replace("\\n", "\n")
                elif len(stripped) > 0:
                    name = stripped
                    instructions[name] = globals(
                    )[f"{context.current_type.capitalize()}InstructionDefinition"](name, context)
                    context.current_instruction = instructions[name]
        return instructions

    def parse_annotation(self, line: str, context: DocParseContext):
        split_line = line.split(" ")
        annotation_name = split_line[0].strip()
        match annotation_name:
            case "type":
                type = split_line[1].strip()
                if type == "pseudo":
                    self.parse_pseudo_types(split_line[2:], context)
                context.current_type = type
            case "param":
                name = split_line[1].strip()
                description = " ".join(split_line[2:]).removesuffix("\n")
                for param_definition in context.current_instruction.param_definitions:
                    if param_definition.name == name:
                        param_definition.description = description
                        break
                context.current_instruction._set_markdown_documentation()
            case "description":
                description = " ".join(split_line[1:]).removesuffix(
                    "\n").replace("\\n", "\n")
                context.current_instruction.set_description(description)
            case "description_start":
                context.is_description = True
            case "description_end":
                context.is_description = False
                context.current_instruction.set_description(
                    context.current_description.removesuffix("\n"))
                context.current_description = ""
            case "deprecated":
                context.current_instruction.set_deprecated(True)

    def parse_pseudo_types(self, args: List[str], context: DocParseContext) -> None:
        context.current_pseudo_param_format = " ".join(args)

    def get_instruction_completions(self) -> List[CompletionItem]:
        return [definition.get_completion() for definition in self.instructions.values()]

    def get_param_completion_for_instruction(self, instruction_name: str, param_index: int, context: ParseContext) -> List[CompletionItem]:
        if instruction_name in self.instructions:
            instruction_definition = self.instructions[instruction_name]
            return instruction_definition.get_param_completion(param_index, context)
        return []

    def get_hover_for(self, name: str, context: ParseContext) -> Hover:
        if name in self.instructions:
            instruction_definition = self.instructions[name]
            return instruction_definition.get_hover()
        if name in registers:
            return Hover(contents=registers[name])
        if context and name in context.variables:
            variable = context.variables[name]
            hex_address = f"0x{variable.address:x}"
            return Hover(contents=f"Variable *{name}* points to address {variable.address} ({hex_address}).")
        if context and name in context.labels:
            return Hover(contents=f"Label *{name}*  \nCan be jumped to (e.g. with **j**)")
        return None

    def get_signature_info_for_instruction(self, instruction_name: str) -> SignatureInformation:
        if instruction_name in self.instructions:
            instruction_definition = self.instructions[instruction_name]
            return instruction_definition.get_signature_info()
        return None
