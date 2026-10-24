import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

KEYWORDS = {
    "process", "where", "end", "init", "integer", "boolean", "event", "true", "false",
    "when", "default", "and", "or", "xor", "not", "modulo", "short", "long", "shl", "shr", "type", "enum",
    "constant", "next", "iterate", "of", "with", "if", "then", "else", "procedure", "node", "function", "automaton", "label", "on",
    "external",
}

KIND_EVENT = "EVENT"
KIND_BOOLEAN = "BOOLEAN"
KIND_INT = "INT"
KIND_POINTER = "POINTER"
KIND_ENUM = "ENUM"
KIND_ARRAY = "ARRAY"
KIND_EXTERNAL = "EXTERNAL"
ENUM_BYTES = 4
BUILTIN_TYPES = (
    ("event", KIND_EVENT, 1, False),
    ("boolean", KIND_BOOLEAN, 1, False),
    ("short", KIND_INT, 2, True),
    ("integer", KIND_INT, 4, True),
    ("long", KIND_INT, 8, True),
    ("ubyte", KIND_INT, 1, False),
    ("ushort", KIND_INT, 2, False),
    ("uinteger", KIND_INT, 4, False),
    ("ulong", KIND_INT, 8, False),
    ("pointer", KIND_POINTER, 8, False),
)
EVENT, BOOLEAN, SHORT, INTEGER, LONG, UBYTE, USHORT, UINTEGER, ULONG, POINTER = range(len(BUILTIN_TYPES))
TYPE_NAMES = {name: type_id for type_id, (name, _, _, _) in enumerate(BUILTIN_TYPES)}
LITERAL_TYPES = (SHORT, INTEGER, LONG)
MASK64 = (1 << 64) - 1
WINDOW_BYTES = 16384

TOKEN_PATTERN = re.compile(
    r"(?P<space>\s+)"
    r"|(?P<comment>%[^%]*%)"
    r"|(?P<number>\d+)"
    r"|(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"|(?P<symbol>\(\||\|\)|-->|::|:=|\^=|/=|<=|>=|[|$+\-*/()=;,?!<>^#\[\]:{}])",
    re.ASCII,
)

OP_CONST = "CONST"
OP_SIGNAL = "SIGNAL"
OP_COPY = "COPY"
OP_INPUT = "INPUT"
OP_NEG = "NEG"
OP_NOT = "NOT"
OP_ADD = "ADD"
OP_SUB = "SUB"
OP_MUL = "MUL"
OP_DIV = "DIV"
OP_MOD = "MOD"
OP_EQ = "EQ"
OP_NE = "NE"
OP_LT = "LT"
OP_LE = "LE"
OP_GT = "GT"
OP_GE = "GE"
OP_AND = "AND"
OP_OR = "OR"
OP_XOR = "XOR"
OP_DELAY = "DELAY"
OP_WHEN = "WHEN"
OP_UWHEN = "UWHEN"
OP_DEFAULT = "DEFAULT"
OP_CLOCK = "CLOCK"
OP_CALL = "CALL"
OP_CONVERT = "CONVERT"
OP_SHL = "SHL"
OP_SHR = "SHR"
OP_ENUMCONST = "ENUMCONST"
OP_TABLE = "TABLE"
OP_INDEX = "INDEX"
OP_ELEMENT = "ELEMENT"
OP_GATHER = "GATHER"
OP_PAIR = "PAIR"
OP_NEXT = "NEXT"
OP_PREV = "PREV"
OP_ITER = "ITER"
OP_SEED = "SEED"
OP_IF = "IF"
OP_BRANCH = "BRANCH"
OP_EFFECT = "EFFECT"
OP_ARG = "ARG"
DEFINE = "DEFINE"
SEED = "SEED"

BINARY_OPS = {
    "default": OP_DEFAULT, "when": OP_WHEN, "xor": OP_XOR, "or": OP_OR, "and": OP_AND,
    "=": OP_EQ, "/=": OP_NE, "<": OP_LT, "<=": OP_LE, ">": OP_GT, ">=": OP_GE,
    "+": OP_ADD, "-": OP_SUB, "*": OP_MUL, "/": OP_DIV, "modulo": OP_MOD, "shl": OP_SHL, "shr": OP_SHR,
    "next": OP_NEXT, ":": OP_PAIR,
}
BINARY_PRECEDENCE = {
    "default": 3, "when": 4, "xor": 11, "or": 12, "and": 13,
    "=": 16, "/=": 16, "<": 16, "<=": 16, ">": 16, ">=": 16,
    "+": 17, "-": 17, "*": 18, "/": 18, "modulo": 18, "shl": 18, "shr": 18,
    "next": 1, ":": 2,
}
OPENERS = {"(", "[", OP_CALL, "if", "then"}
MISSING_KEYWORD = {"if": "expected 'then'", "then": "expected 'else'"}
CONDITION_PRECEDENCE = 9
PREFIX_OPS = {"when": OP_UWHEN, "not": OP_NOT, "-": OP_NEG, "^": OP_CLOCK}
PREFIX_PRECEDENCE = {"when": 8, "not": 14, "-": 20, "^": 24}
DELAY_PRECEDENCE = 21
EXPRESSION_TERMINATORS = {"|", "|)", ";", "^=", "with", "end", "::"}
OP_TEXT = {**{op: text for text, op in BINARY_OPS.items()}, **{op: text for text, op in PREFIX_OPS.items()}, OP_DELAY: "$",
    OP_IF: "if", OP_BRANCH: "if",
}

INTEGER_OPS = {OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD, OP_NEG}
ORDER_OPS = {OP_LT, OP_LE, OP_GT, OP_GE}
EQUALITY_OPS = {OP_EQ, OP_NE}
LOGIC_OPS = {OP_AND, OP_OR, OP_XOR, OP_NOT}
SHIFT_OPS = {OP_SHL: "lsl", OP_SHR: "lsr"}
MONOCHRONOUS_OPS = INTEGER_OPS | ORDER_OPS | EQUALITY_OPS | LOGIC_OPS | set(SHIFT_OPS) | {
    OP_CONVERT, OP_ELEMENT, OP_GATHER, OP_PAIR, OP_NEXT, OP_PREV, OP_ITER, OP_IF, OP_BRANCH, OP_ARG,
}
UNARY_OPS = {OP_NEG, OP_NOT, OP_UWHEN, OP_CLOCK, OP_DELAY, OP_CALL, OP_PREV}
INSTRUCTIONS = {OP_ADD: "add", OP_SUB: "sub", OP_MUL: "mul", OP_AND: "and", OP_OR: "orr", OP_XOR: "eor"}
SIGNED_CONDITIONS = {OP_EQ: "eq", OP_NE: "ne", OP_LT: "lt", OP_LE: "le", OP_GT: "gt", OP_GE: "ge"}
UNSIGNED_CONDITIONS = {OP_EQ: "eq", OP_NE: "ne", OP_LT: "lo", OP_LE: "ls", OP_GT: "hi", OP_GE: "hs"}
LOAD = {
    (1, False): "ldrb w", (1, True): "ldrsb x", (2, False): "ldrh w", (2, True): "ldrsh x",
    (4, False): "ldr w", (4, True): "ldrsw x", (8, False): "ldr x", (8, True): "ldr x",
}
STORE = {1: "strb w", 2: "strh w", 4: "str w", 8: "str x"}
DATA_DIRECTIVES = {1: ".byte", 2: ".short", 4: ".long", 8: ".quad"}

MODEL_CLASSES = ("process", "procedure", "node", "function", "automaton")
ORDERED_CLASSES = {"procedure", "node", "function", "automaton"}
PURE_CLASSES = {"automaton", "node", "function"}
AUTOMATON_INTRINSICS = {"Automaton_Initial_State": 1, "Automaton_Transition": 3, "Automaton_IsIn": 1}
BUILTINS = {
    "load": (("type",), 1, True),
    "store": (("type",), 2, False),
    "syscall": ((), 7, True),
    "instruction": (("word",), 1, True),
}

ROOT = "ROOT"
SAMPLE = "SAMPLE"
PRODUCT = "PRODUCT"
SUM = "SUM"


class CompileError(Exception):
    def __init__(self, message, line, column):
        super().__init__(message)
        self.line = line
        self.column = column


@dataclass
class Tokens:
    kinds: list = field(default_factory=list)
    texts: list = field(default_factory=list)
    lines: list = field(default_factory=list)
    columns: list = field(default_factory=list)


@dataclass
class Types:
    kind: list = field(default_factory=list)
    bytes: list = field(default_factory=list)
    signed: list = field(default_factory=list)
    name: list = field(default_factory=list)
    values: list = field(default_factory=list)
    element: list = field(default_factory=list)
    size: list = field(default_factory=list)


def builtin_types():
    types = Types()
    for name, kind, size, signed in BUILTIN_TYPES:
        types.name.append(name)
        types.kind.append(kind)
        types.bytes.append(size)
        types.signed.append(signed)
        types.values.append(())
        types.element.append(-1)
        types.size.append(0)
    return types


def intern_array(types, element, size):
    for type_id, kind in enumerate(types.kind):
        if kind == KIND_ARRAY and types.element[type_id] == element and types.size[type_id] == size:
            return type_id
    types.name.append(f"[{size}] {types.name[element]}")
    types.kind.append(KIND_ARRAY)
    types.bytes.append(8)
    types.signed.append(False)
    types.values.append(())
    types.element.append(element)
    types.size.append(size)
    return len(types.kind) - 1


def is_integer(types, type_id):
    return types.kind[type_id] == KIND_INT


def is_logical(types, type_id):
    return types.kind[type_id] in (KIND_EVENT, KIND_BOOLEAN)


def lub(types, first, second):
    if first == second:
        return first
    if is_logical(types, first) and is_logical(types, second):
        return BOOLEAN
    if not (is_integer(types, first) and is_integer(types, second)):
        return -1
    if types.signed[first] == types.signed[second]:
        return first if types.bytes[first] > types.bytes[second] else second
    signed, unsigned = (first, second) if types.signed[first] else (second, first)
    if types.bytes[signed] > types.bytes[unsigned]:
        return signed
    for candidate in range(len(types.kind)):
        if types.signed[candidate] and types.bytes[candidate] == 2 * types.bytes[unsigned]:
            return candidate
    return -1


def subtype(types, small, big):
    return lub(types, small, big) == big


def resolve_enum(types, type_name, value_name, line, column):
    if type_name is None:
        holders = [t for t, values in enumerate(types.values) if value_name in values]
        if not holders:
            raise CompileError(f"enumerated value {value_name} is not declared", line, column)
        if len(holders) > 1:
            raise CompileError(f"enumerated value {value_name} is ambiguous", line, column)
        type_id = holders[0]
    elif type_name not in types.name:
        raise CompileError(f"type {type_name} is not declared", line, column)
    else:
        type_id = types.name.index(type_name)
        if value_name not in types.values[type_id]:
            raise CompileError(f"type {type_name} has no value {value_name}", line, column)
    return types.values[type_id].index(value_name), type_id


@dataclass
class Models:
    name: list = field(default_factory=list)
    kind: list = field(default_factory=list)
    parent: list = field(default_factory=list)
    line: list = field(default_factory=list)
    column: list = field(default_factory=list)
    labels: list = field(default_factory=list)


@dataclass
class Program:
    name: str = ""
    types: Types = field(default_factory=builtin_types)
    models: Models = field(default_factory=Models)
    signal_names: list = field(default_factory=list)
    signal_roles: list = field(default_factory=list)
    signal_types: list = field(default_factory=list)
    signal_models: list = field(default_factory=list)
    signal_positions: list = field(default_factory=list)
    constant_names: list = field(default_factory=list)
    constant_types: list = field(default_factory=list)
    constant_values: list = field(default_factory=list)
    table_types: list = field(default_factory=list)
    table_values: list = field(default_factory=list)
    equation_targets: list = field(default_factory=list)
    equation_ops: list = field(default_factory=list)
    equation_args: list = field(default_factory=list)
    equation_positions: list = field(default_factory=list)
    equation_loops: list = field(default_factory=list)
    equation_kinds: list = field(default_factory=list)
    equation_models: list = field(default_factory=list)
    equation_labels: list = field(default_factory=list)
    equation_guards: list = field(default_factory=list)
    guard_models: list = field(default_factory=list)
    guard_ops: list = field(default_factory=list)
    guard_args: list = field(default_factory=list)
    guard_positions: list = field(default_factory=list)
    guard_context: list = field(default_factory=list)
    guard_labels: list = field(default_factory=list)
    guard_signals: list = field(default_factory=list)
    label_names: list = field(default_factory=list)
    label_uses: list = field(default_factory=list)
    loop_names: list = field(default_factory=list)
    loop_positions: list = field(default_factory=list)
    loop_models: list = field(default_factory=list)
    constraint_groups: list = field(default_factory=list)
    constraint_positions: list = field(default_factory=list)
    constraint_models: list = field(default_factory=list)
    constraint_guards: list = field(default_factory=list)
    dependence_from: list = field(default_factory=list)
    dependence_to: list = field(default_factory=list)
    dependence_positions: list = field(default_factory=list)
    dependence_models: list = field(default_factory=list)
    dependence_guards: list = field(default_factory=list)


@dataclass
class Effects:
    kind: list = field(default_factory=list)
    resource: list = field(default_factory=list)
    param: list = field(default_factory=list)


@dataclass
class Rows:
    op: list = field(default_factory=list)
    left: list = field(default_factory=list)
    right: list = field(default_factory=list)
    value: list = field(default_factory=list)
    type: list = field(default_factory=list)
    ctx: list = field(default_factory=list)
    line: list = field(default_factory=list)
    column: list = field(default_factory=list)
    owner: list = field(default_factory=list)
    loop: list = field(default_factory=list)
    guard: list = field(default_factory=list)
    groups: list = field(default_factory=list)
    group_positions: list = field(default_factory=list)
    dependence_from: list = field(default_factory=list)
    dependence_to: list = field(default_factory=list)
    war: list = field(default_factory=list)
    snapshotted: set = field(default_factory=set)
    effects: Effects = field(default_factory=Effects)


@dataclass
class Loops:
    index: list = field(default_factory=list)
    size: list = field(default_factory=list)
    defined: list = field(default_factory=list)
    snapshots: list = field(default_factory=list)


@dataclass
class Clocks:
    parent: list = field(default_factory=list)
    sample_rows: list = field(default_factory=list)
    def_kind: list = field(default_factory=list)
    def_target: list = field(default_factory=list)
    def_left: list = field(default_factory=list)
    def_right: list = field(default_factory=list)
    def_line: list = field(default_factory=list)
    def_column: list = field(default_factory=list)
    def_pending: list = field(default_factory=list)
    ob_small: list = field(default_factory=list)
    ob_big: list = field(default_factory=list)
    ob_line: list = field(default_factory=list)
    ob_column: list = field(default_factory=list)
    node_kind: list = field(default_factory=list)
    node_parent: list = field(default_factory=list)
    node_depth: list = field(default_factory=list)
    node_root: list = field(default_factory=list)
    node_left: list = field(default_factory=list)
    node_right: list = field(default_factory=list)
    roots: list = field(default_factory=list)


def lex(source):
    tokens = Tokens()
    position = 0
    line = 1
    line_start = 0
    while position < len(source):
        match = TOKEN_PATTERN.match(source, position)
        if not match:
            raise CompileError(f"unexpected character {source[position]!r}", line, position - line_start + 1)
        kind = match.lastgroup
        text = match.group()
        if kind == "name" and (text in KEYWORDS or text.lower() in KEYWORDS and text.isupper()):
            kind = "keyword"
            text = text.lower()
        if kind not in ("space", "comment"):
            tokens.kinds.append(kind)
            tokens.texts.append(text)
            tokens.lines.append(line)
            tokens.columns.append(position - line_start + 1)
        newlines = text.count("\n")
        if newlines:
            line += newlines
            line_start = match.start() + text.rindex("\n") + 1
        position = match.end()
    tokens.kinds.append("eof")
    tokens.texts.append("")
    tokens.lines.append(line)
    tokens.columns.append(position - line_start + 1)
    return tokens


class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.index = 0
        self.program = Program()
        self.model_stack = []

    def peek(self):
        return self.tokens.texts[self.index]

    def position(self):
        return self.tokens.lines[self.index], self.tokens.columns[self.index]

    def fail(self, message):
        raise CompileError(message, *self.position())

    def expect(self, text):
        if self.peek() != text:
            self.fail(f"expected {text!r}, found {self.peek() or 'end of file'!r}")
        self.index += 1

    def expect_name(self):
        if self.tokens.kinds[self.index] != "name":
            self.fail(f"expected a name, found {self.peek() or 'end of file'!r}")
        text = self.peek()
        self.index += 1
        return text

    def is_declared(self, name):
        program = self.program
        model = self.model_stack[-1]
        return (
            any(owner == model and signal == name for signal, owner in zip(program.signal_names, program.signal_models))
            or name in program.models.labels[model]
            or name in program.constant_names
            or name in program.types.name[len(BUILTIN_TYPES):]
            or name in program.models.name
            or name in AUTOMATON_INTRINSICS
            or name in BUILTINS
        )

    def clash(self, role, name, line, column):
        if name in BUILTINS or name in AUTOMATON_INTRINSICS:
            return CompileError(f"{name} is a reserved name", line, column)
        if name in self.program.models.name and role != "model":
            return CompileError(f"{name} is the name of a model", line, column)
        return CompileError(f"{role} {name} is declared twice", line, column)

    def integer_literal_value(self):
        text = self.peek()
        if len(text) > 20 or int(text) >> 63:
            self.fail(f"integer literal {text if len(text) <= 20 else text[:20] + '...'} does not fit in long")
        return int(text)

    def parse_type(self):
        program = self.program
        types = program.types
        size = 0
        if self.peek() == "[":
            self.index += 1
            line, column = self.position()
            text = self.peek()
            if self.tokens.kinds[self.index] == "number":
                size = self.integer_literal_value()
            elif text in program.constant_names and is_integer(types, program.constant_types[program.constant_names.index(text)]):
                size = program.constant_values[program.constant_names.index(text)]
            elif self.tokens.kinds[self.index] == "name" and not self.is_declared(text):
                raise CompileError(f"constant {text} is not declared", line, column)
            else:
                self.fail(f"expected an integer constant, found {text or 'end of file'!r}")
            if size <= 0:
                raise CompileError("array capacity must be strictly positive", line, column)
            self.index += 1
            self.expect("]")
        if self.peek() not in types.name:
            self.fail(f"expected a type, found {self.peek() or 'end of file'!r}")
        element = types.name.index(self.peek())
        if size and element == EVENT:
            self.fail("arrays of event are not supported")
        self.index += 1
        return intern_array(types, element, size) if size else element

    def declare(self, role):
        types = self.program.types
        signal_type = self.parse_type()
        while True:
            line, column = self.position()
            name = self.expect_name()
            if self.is_declared(name):
                raise self.clash("signal", name, line, column)
            base_type = types.element[signal_type] if types.kind[signal_type] == KIND_ARRAY else signal_type
            if types.kind[base_type] == KIND_EXTERNAL:
                raise CompileError(f"type {types.name[base_type]} is external; signals cannot have that type", line, column)
            if role == "input" and types.kind[signal_type] == KIND_ARRAY and self.model_stack[-1] == 0:
                raise CompileError(f"input signal {name} must be a scalar", line, column)
            if role == "input" and types.kind[signal_type] == KIND_ARRAY:
                raise CompileError("arrays cannot be passed to models", line, column)
            if role == "output" and types.kind[signal_type] == KIND_ARRAY:
                raise CompileError(f"{role} {name} has an array type; {role}s must be scalar", line, column)
            self.program.signal_names.append(name)
            self.program.signal_roles.append(role)
            self.program.signal_types.append(signal_type)
            self.program.signal_models.append(self.model_stack[-1])
            self.program.signal_positions.append((line, column))
            if self.peek() != ",":
                break
            self.index += 1
        self.expect(";")

    def parse_program(self):
        for index, (kind, text) in enumerate(zip(self.tokens.kinds, self.tokens.texts)):
            if kind == "keyword" and text == "type":
                self.index = index
                self.parse_type_declaration()
        self.index = 0
        self.parse_model()
        while self.model_stack:
            if self.peek() in MODEL_CLASSES and self.tokens.kinds[self.index] == "keyword":
                self.parse_model()
            elif self.peek() == "end":
                self.index += 1
                self.expect(";")
                self.finish_model(self.model_stack.pop())
            elif self.peek() == "type":
                self.index += 1
                line, column = self.position()
                name = self.peek()
                if (
                    name in self.program.signal_names
                    or any(name in labels for labels in self.program.models.labels)
                    or name in self.program.constant_names
                    or name in self.program.models.name
                ):
                    raise self.clash("type", name, line, column)
                while self.peek() != ";":
                    self.index += 1
                self.index += 1
            elif self.peek() == "constant":
                self.parse_constant()
            elif self.peek() == "label":
                self.parse_label_declaration()
            else:
                self.declare("local")
        if self.tokens.kinds[self.index] != "eof":
            self.fail(f"unexpected {self.peek()!r} after the process model")
        return self.program

    def parse_model(self):
        program = self.program
        models = program.models
        if self.model_stack:
            kind = self.peek()
            self.index += 1
        else:
            self.expect("process")
            kind = "process"
        line, column = self.position()
        name = self.expect_name()
        if (
            name in models.name
            or name in program.signal_names
            or any(name in labels for labels in models.labels)
            or name in program.constant_names
            or name in program.types.name[len(BUILTIN_TYPES):]
            or name in BUILTINS
        ):
            raise self.clash("model", name, line, column)
        if not models.name:
            program.name = name
        models.name.append(name)
        models.kind.append(kind)
        models.parent.append(self.model_stack[-1] if self.model_stack else -1)
        models.line.append(line)
        models.column.append(column)
        models.labels.append([])
        self.model_stack.append(len(models.name) - 1)
        self.expect("=")
        self.expect("(")
        if self.peek() == "?":
            self.index += 1
            while self.peek() not in ("!", ")"):
                self.declare("input")
        if self.peek() == "!":
            self.index += 1
            while self.peek() != ")":
                self.declare("output")
        self.expect(")")
        if self.peek() != "(|":
            self.expect("(|")
        self.parse_process()
        if self.peek() == "where":
            self.index += 1
        else:
            self.expect(";")
            self.finish_model(self.model_stack.pop())

    def finish_model(self, model):
        program = self.program
        for owner, name, line, column in program.label_uses:
            if owner == model and name not in program.models.labels[model]:
                raise CompileError(f"label {name} is not declared", line, column)
        models = program.models
        model_name = models.name[model]
        model_position = (models.line[model], models.column[model])
        is_automaton = models.kind[model] == "automaton"
        states = []
        transitions = []
        if is_automaton:
            inputs = [
                name
                for name, role, owner in zip(program.signal_names, program.signal_roles, program.signal_models)
                if owner == model and role == "input"
            ]
            if not inputs:
                raise CompileError(
                    f"automaton {model_name} has no input; its control clock is the upper bound of its inputs", *model_position
                )
            statements = [
                equation
                for equation, (owner, target, ops, args) in enumerate(
                    zip(program.equation_models, program.equation_targets, program.equation_ops, program.equation_args)
                )
                if owner == model
                and target is None
                and ops[-1] == OP_CALL
                and args[-1][2] in ("Automaton_Initial_State", "Automaton_Transition")
            ]
            initials = []
            for equation in statements:
                ops = program.equation_ops[equation]
                args = program.equation_args[equation]
                line, column, intrinsic, _, count = args[-1]
                if count != AUTOMATON_INTRINSICS[intrinsic]:
                    raise CompileError(
                        f"wrong number of arguments for {intrinsic}: expected {AUTOMATON_INTRINSICS[intrinsic]}, found {count}",
                        line,
                        column,
                    )
                if program.equation_labels[equation]:
                    raise CompileError(
                        f"label {program.equation_labels[equation][-1]} cannot be placed on {intrinsic}", line, column
                    )
                guards = program.equation_guards[equation]
                if guards and intrinsic == "Automaton_Initial_State":
                    raise CompileError(f"{intrinsic} cannot be guarded", line, column)
                state_count = 1 if intrinsic == "Automaton_Initial_State" else 2
                trigger_start = call_segments(ops, args)[-2] if count == 3 else len(ops) - 1
                if trigger_start != state_count or any(op != OP_SIGNAL for op in ops[:state_count]):
                    raise CompileError(f"{intrinsic} expects a state name of automaton {model_name}", line, column)
                for state, state_line, state_column in args[:state_count]:
                    if state not in models.labels[model]:
                        raise CompileError(f"{state} is not a label of automaton {model_name}", state_line, state_column)
                    if state not in states:
                        states.append(state)
                if count == 1:
                    if initials:
                        raise CompileError(f"automaton {model_name} needs exactly one Automaton_Initial_State", line, column)
                    initials.append(args[0][0])
                else:
                    trigger_ops = ops[2:-1]
                    trigger_args = args[2:-1]
                    if guards:
                        number = [g for g, owner in enumerate(program.guard_models) if owner == model].index(guards[-1]) + 1
                        trigger_ops += [OP_SIGNAL, OP_WHEN]
                        trigger_args += [(f"on'{number}", line, column), (line, column)]
                    transitions.append((args[0][0], args[1][0], trigger_ops, trigger_args, line, column))
            if not initials:
                raise CompileError(f"automaton {model_name} needs exactly one Automaton_Initial_State", *model_position)
            for equation in reversed(statements):
                for column_list in (
                    program.equation_targets,
                    program.equation_ops,
                    program.equation_args,
                    program.equation_positions,
                    program.equation_loops,
                    program.equation_kinds,
                    program.equation_models,
                    program.equation_labels,
                    program.equation_guards,
                ):
                    del column_list[equation]
            types = program.types
            state_type = len(types.name)
            types.name.append(f"{model_name}'state")
            types.kind.append(KIND_ENUM)
            types.bytes.append(ENUM_BYTES)
            types.signed.append(False)
            types.values.append(())
            types.element.append(-1)
            types.size.append(0)
        postfixes = [
            (program.equation_ops[equation], program.equation_args[equation], program.equation_targets[equation] is None)
            for equation, owner in enumerate(program.equation_models)
            if owner == model
        ]
        postfixes.extend(
            (ops, args, False)
            for group, owner in enumerate(program.constraint_models)
            if owner == model
            for ops, args in program.constraint_groups[group]
        )
        postfixes.extend(
            (ops, args, False)
            for ops, args, owner in zip(program.guard_ops, program.guard_args, program.guard_models)
            if owner == model
        )
        postfixes.extend((trigger_ops, trigger_args, False) for _, _, trigger_ops, trigger_args, _, _ in transitions)
        for ops, args, statement in postfixes:
            out_ops = []
            out_args = []
            for index, (op, arg) in enumerate(zip(ops, args)):
                if op != OP_CALL or arg[2] not in AUTOMATON_INTRINSICS:
                    out_ops.append(op)
                    out_args.append(arg)
                    continue
                line, column, intrinsic, _, count = arg
                if not is_automaton:
                    raise CompileError(f"{intrinsic} is allowed only in an automaton", line, column)
                if intrinsic != "Automaton_IsIn":
                    raise CompileError(f"model {intrinsic} has no output and cannot be used in an expression", line, column)
                if statement and index == len(ops) - 1:
                    raise CompileError(f"model {intrinsic} has an output and cannot be called as a process", line, column)
                if count != 1:
                    raise CompileError(f"wrong number of arguments for {intrinsic}: expected 1, found {count}", line, column)
                if out_ops[-1] != OP_SIGNAL:
                    raise CompileError(f"{intrinsic} expects a state name of automaton {model_name}", line, column)
                if out_args[-1][0] not in states:
                    raise CompileError(f"{out_args[-1][0]} is not a state of automaton {model_name}", *out_args[-1][1:])
                out_ops[-1:] = [OP_SIGNAL, OP_CONST, OP_EQ]
                out_args[-1:] = [("state'", line, column), (states.index(out_args[-1][0]), state_type), (line, column)]
            ops[:] = out_ops
            args[:] = out_args
        if is_automaton:
            line, column = model_position
            clock_ops = []
            clock_args = []
            for position, name in enumerate(inputs):
                clock_ops.extend([OP_SIGNAL, OP_CLOCK] + [OP_DEFAULT] * (position > 0))
                clock_args.extend([(name, line, column), (line, column)] + [(line, column)] * (position > 0))
            next_ops = []
            next_args = []
            for position, (source, destination, trigger_ops, trigger_args, call_line, call_column) in enumerate(transitions):
                next_ops.extend([OP_CONST, OP_SIGNAL, OP_CONST, OP_EQ, OP_WHEN, *trigger_ops, OP_WHEN])
                next_args.extend(
                    [
                        (states.index(destination), state_type),
                        ("state'", call_line, call_column),
                        (states.index(source), state_type),
                        (call_line, call_column),
                        (call_line, call_column),
                        *trigger_args,
                        (call_line, call_column),
                    ]
                )
                if position > 0:
                    next_ops.append(OP_DEFAULT)
                    next_args.append((call_line, call_column))
            next_ops.append(OP_SIGNAL)
            next_args.append(("state'", line, column))
            if transitions:
                next_ops.append(OP_DEFAULT)
                next_args.append((line, column))
            initial = (OP_CONST, (states.index(initials[0]), state_type))
            for target, signal_type, ops, args in (
                ("clock'", EVENT, clock_ops, clock_args),
                ("state'", state_type, [OP_SIGNAL, OP_DELAY], [("cur'", line, column), (line, column, initial)]),
                ("cur'", state_type, next_ops, next_args),
            ):
                self.define_local(model, target, signal_type, ops, args, model_position, (), ())
            program.constraint_groups.append(
                [([OP_SIGNAL], [("cur'", line, column)]), ([OP_SIGNAL], [("clock'", line, column)])]
            )
            program.constraint_positions.append(model_position)
            program.constraint_models.append(model)
            program.constraint_guards.append(())
        own_types = {
            name: signal_type
            for name, signal_type, owner in zip(program.signal_names, program.signal_types, program.signal_models)
            if owner == model
        }
        own_guards = [guard for guard, owner in enumerate(program.guard_models) if owner == model]
        for number, guard in reversed(list(enumerate(own_guards, 1))):
            equations = [
                equation
                for equation, (owner, chain) in enumerate(zip(program.equation_models, program.equation_guards))
                if owner == model and guard in chain
            ]
            constraints = [
                group
                for group, (owner, chain) in enumerate(zip(program.constraint_models, program.constraint_guards))
                if owner == model and guard in chain
            ]
            dependences = [
                dependence
                for dependence, (owner, chain) in enumerate(zip(program.dependence_models, program.dependence_guards))
                if owner == model and guard in chain
            ]
            postfixes = [(program.equation_ops[e], program.equation_args[e]) for e in equations]
            postfixes.extend(member for group in constraints for member in program.constraint_groups[group])
            reads = [arg[0] for ops, args in postfixes for op, arg in zip(ops, args) if op == OP_SIGNAL]
            reads.extend(end[0] for d in dependences for end in (program.dependence_from[d], program.dependence_to[d]))
            defined = {program.equation_targets[e] for e in equations}
            inputs = [name for name in dict.fromkeys(reads) if name in own_types and name not in defined]
            renamed = {name: f"{name}'{number}" for name in inputs}
            for e in equations:
                program.equation_args[e] = [
                    (renamed.get(arg[0], arg[0]), *arg[1:]) if op == OP_SIGNAL else arg
                    for op, arg in zip(program.equation_ops[e], program.equation_args[e])
                ]
            for group in constraints:
                program.constraint_groups[group] = [
                    (ops, [(renamed.get(arg[0], arg[0]), *arg[1:]) if op == OP_SIGNAL else arg for op, arg in zip(ops, args)])
                    for ops, args in program.constraint_groups[group]
                ]
            for d in dependences:
                for ends in (program.dependence_from, program.dependence_to):
                    ends[d] = (renamed.get(ends[d][0], ends[d][0]), *ends[d][1:])
            clock_signal = f"on'{number}"
            program.guard_signals[guard] = clock_signal
            line, column = program.guard_positions[guard]
            filters = [(clock_signal, EVENT, program.guard_ops[guard], program.guard_args[guard])]
            filters.extend(
                (
                    renamed[name],
                    own_types[name],
                    [OP_SIGNAL, OP_SIGNAL, OP_WHEN],
                    [(name, line, column), (clock_signal, line, column), (line, column)],
                )
                for name in inputs
            )
            for target, signal_type, ops, args in filters:
                own_types[target] = signal_type
                self.define_local(
                    model, target, signal_type, ops, args, (line, column), program.guard_labels[guard], program.guard_context[guard]
                )

    def define_local(self, model, target, signal_type, ops, args, position, labels, guards):
        program = self.program
        program.signal_names.append(target)
        program.signal_roles.append("local")
        program.signal_types.append(signal_type)
        program.signal_models.append(model)
        program.signal_positions.append(position)
        program.equation_targets.append(target)
        program.equation_ops.append(ops)
        program.equation_args.append(args)
        program.equation_positions.append(position)
        program.equation_loops.append(-1)
        program.equation_kinds.append(DEFINE)
        program.equation_models.append(model)
        program.equation_labels.append(labels)
        program.equation_guards.append(guards)

    def parse_type_declaration(self):
        types = self.program.types
        self.expect("type")
        line, column = self.position()
        name = self.expect_name()
        if name in types.name or name in BUILTINS or name in AUTOMATON_INTRINSICS:
            raise self.clash("type", name, line, column)
        self.expect("=")
        values = []
        kind = KIND_EXTERNAL
        if self.peek() == "external":
            self.index += 1
        else:
            kind = KIND_ENUM
            self.expect("enum")
            self.expect("(")
            while True:
                line, column = self.position()
                value = self.expect_name()
                if value in values:
                    raise CompileError(f"enumerated value {value} is declared twice", line, column)
                values.append(value)
                if self.peek() != ",":
                    break
                self.index += 1
            self.expect(")")
        self.expect(";")
        types.name.append(name)
        types.kind.append(kind)
        types.bytes.append(ENUM_BYTES if kind == KIND_ENUM else 0)
        types.signed.append(False)
        types.values.append(tuple(values))
        types.element.append(-1)
        types.size.append(0)

    def parse_constant(self):
        program = self.program
        types = program.types
        self.expect("constant")
        constant_type = self.parse_type()
        is_array = types.kind[constant_type] == KIND_ARRAY
        type_text = types.name[constant_type]
        while True:
            line, column = self.position()
            name = self.expect_name()
            if self.is_declared(name) or name in program.signal_names or any(name in labels for labels in program.models.labels):
                raise self.clash("constant", name, line, column)
            self.expect("=")
            if self.peek() == "[":
                if not is_array:
                    raise CompileError(f"constant {name} has type {type_text} but its definition is a list", line, column)
                self.index += 1
                values = []
                while True:
                    value, value_type = self.parse_integer_constant()
                    if not subtype(types, value_type, types.element[constant_type]):
                        raise CompileError(
                            f"constant {name} has type {type_text} but its definition has an element of type "
                            f"{types.name[value_type]}",
                            line,
                            column,
                        )
                    values.append(value)
                    if self.peek() != ",":
                        break
                    self.index += 1
                self.expect("]")
                if len(values) != types.size[constant_type]:
                    raise CompileError(
                        f"constant {name} has type {type_text} but its definition has {len(values)} elements", line, column
                    )
                constant_value = len(program.table_types)
                program.table_types.append(constant_type)
                program.table_values.append(tuple(values))
            else:
                constant_value, value_type = self.parse_integer_constant()
                if is_array or not subtype(types, value_type, constant_type):
                    raise CompileError(
                        f"constant {name} has type {type_text} but its definition has type {types.name[value_type]}",
                        line,
                        column,
                    )
            program.constant_names.append(name)
            program.constant_types.append(constant_type)
            program.constant_values.append(constant_value)
            if self.peek() != ",":
                break
            self.index += 1
        self.expect(";")

    def parse_label_declaration(self):
        labels = self.program.models.labels[self.model_stack[-1]]
        self.expect("label")
        while True:
            line, column = self.position()
            name = self.expect_name()
            if self.is_declared(name):
                raise self.clash("label", name, line, column)
            labels.append(name)
            if self.peek() != ",":
                break
            self.index += 1
        self.expect(";")

    def parse_integer_constant(self):
        types = self.program.types
        target = -1
        if self.tokens.texts[self.index + 1] == "(" and self.peek() != "-":
            if self.peek() not in types.name or not is_integer(types, types.name.index(self.peek())):
                self.fail("a conversion in a constant must name an integer type")
            target = types.name.index(self.peek())
            self.index += 2
        negated = self.peek() == "-"
        self.index += negated
        if self.tokens.kinds[self.index] != "number":
            self.fail("a constant must be defined by an integer literal, a conversion of one, or a list of them")
        _, (value, value_type) = self.parse_literal()
        value = -value if negated else value
        if target < 0:
            return value, value_type
        self.expect(")")
        bits = 8 * types.bytes[target]
        value &= (1 << bits) - 1
        if types.signed[target] and value >> (bits - 1):
            value -= 1 << bits
        return value, target

    def parse_process(self):
        program = self.program
        frames = []
        while True:
            loop, kind = next(((frame[1], frame[2]) for frame in reversed(frames) if frame[0] == "iterate"), (-1, DEFINE))
            if self.peek() == "(|":
                frames.append(("compose",))
                self.index += 1
                continue
            if self.tokens.kinds[self.index] == "name" and self.tokens.texts[self.index + 1] == "::":
                if loop >= 0:
                    self.fail("only definitions are allowed inside iterate")
                program.label_uses.append((self.model_stack[-1], self.peek(), *self.position()))
                frames.append(("label", self.peek()))
                self.index += 2
                continue
            labels = tuple(frame[1] for frame in frames if frame[0] == "label")
            guards = tuple(frame[1] for frame in frames if frame[0] == "guard")
            if self.peek() == "on" and self.tokens.kinds[self.index] == "keyword":
                if loop >= 0:
                    self.fail("only definitions are allowed inside iterate")
                program.guard_positions.append(self.position())
                self.index += 1
                ops, args = self.parse_expression()
                self.expect("::")
                program.guard_models.append(self.model_stack[-1])
                program.guard_ops.append(ops)
                program.guard_args.append(args)
                program.guard_context.append(guards)
                program.guard_labels.append(labels)
                program.guard_signals.append(None)
                frames.append(("guard", len(program.guard_models) - 1))
                continue
            if self.peek() == "iterate" and self.tokens.kinds[self.index] == "keyword":
                if loop >= 0:
                    self.fail("iterate cannot be nested")
                if guards:
                    self.fail("iterate is not allowed inside a guarded process")
                self.index += 1
                name_position = self.position()
                program.loop_names.append(self.expect_name())
                program.loop_positions.append(name_position)
                program.loop_models.append(self.model_stack[-1])
                self.expect("of")
                frames.append(["iterate", len(program.loop_names) - 1, DEFINE])
                continue
            self.parse_equation(loop, kind, labels, guards)
            while frames:
                frame = frames[-1]
                if frame[0] in ("label", "guard"):
                    frames.pop()
                elif frame[0] == "compose" and self.peek() == "|" and self.tokens.texts[self.index + 1] != "|)":
                    self.index += 1
                    break
                elif frame[0] == "compose":
                    self.index += self.peek() == "|"
                    self.expect("|)")
                    frames.pop()
                elif frame[2] == DEFINE and self.peek() == "with":
                    self.index += 1
                    frame[2] = SEED
                    break
                else:
                    self.expect("end")
                    frames.pop()
            if not frames:
                return

    def parse_equation(self, loop, kind, labels, guards):
        program = self.program
        line, column = self.position()
        follower = self.tokens.texts[self.index + 1] if self.tokens.kinds[self.index] == "name" else None
        if loop >= 0 and follower != ":=":
            self.fail("only definitions are allowed inside iterate")
        if follower == "-->":
            previous = (self.expect_name(), line, column)
            while self.peek() == "-->":
                self.index += 1
                if self.tokens.kinds[self.index] != "name":
                    self.fail("--> requires signal names")
                current = (self.peek(), *self.position())
                self.index += 1
                program.dependence_from.append(previous)
                program.dependence_to.append(current)
                program.dependence_positions.append((line, column))
                program.dependence_models.append(self.model_stack[-1])
                program.dependence_guards.append(guards)
                previous = current
            if self.peek() not in ("|", "|)"):
                self.fail("--> requires signal names")
            return
        target = None
        if follower == ":=":
            target = self.expect_name()
            self.expect(":=")
        ops, args = self.parse_expression()
        if target is None and (self.peek() == "^=" or ops[-1] != OP_CALL):
            if self.peek() != "^=":
                self.fail(f"expected ':=' or '^=', found {self.peek() or 'end of file'!r}")
            group = [(ops, args)]
            while self.peek() == "^=":
                self.index += 1
                group.append(self.parse_expression())
            program.constraint_groups.append(group)
            program.constraint_positions.append((line, column))
            program.constraint_models.append(self.model_stack[-1])
            program.constraint_guards.append(guards)
            return
        program.equation_targets.append(target)
        program.equation_ops.append(ops)
        program.equation_args.append(args)
        program.equation_positions.append((line, column))
        program.equation_loops.append(loop)
        program.equation_kinds.append(kind)
        program.equation_models.append(self.model_stack[-1])
        program.equation_labels.append(labels)
        program.equation_guards.append(guards)

    def parse_literal(self):
        text = self.peek()
        kind = self.tokens.kinds[self.index]
        line, column = self.position()
        if kind == "number":
            value = self.integer_literal_value()
            self.index += 1
            return OP_CONST, (value, next(t for t in LITERAL_TYPES if value >> (8 * BUILTIN_TYPES[t][2] - 1) == 0))
        if text in ("true", "false") and kind == "keyword":
            self.index += 1
            return OP_CONST, (int(text == "true"), BOOLEAN)
        type_name = None
        if kind == "name" and self.tokens.texts[self.index + 1] == "#":
            type_name = text
            self.index += 1
        if self.peek() == "#":
            self.index += 1
            return OP_ENUMCONST, (type_name, self.expect_name(), line, column)
        return None

    def parse_expression(self):
        ops = []
        args = []
        pending = []
        expect_operand = True
        while True:
            text = self.peek()
            kind = self.tokens.kinds[self.index]
            position = self.position()
            if expect_operand:
                if text == ")" and pending and pending[-1][0] == OP_CALL and self.tokens.texts[self.index - 1] == "(":
                    self.reduce(pending.pop(), ops, args)
                    self.index += 1
                    expect_operand = False
                    continue
                literal = self.parse_literal()
                if literal is not None:
                    ops.append(literal[0])
                    args.append(literal[1])
                    expect_operand = False
                    continue
                if (kind == "name" or text in TYPE_NAMES) and self.tokens.texts[self.index + 1] in ("(", "{"):
                    self.index += 1
                    params = []
                    if self.peek() == "{":
                        self.index += 1
                        while True:
                            if self.tokens.kinds[self.index] not in ("name", "keyword", "number"):
                                self.fail(f"expected a static parameter, found {self.peek() or 'end of file'!r}")
                            params.append((self.peek(), self.tokens.kinds[self.index], *self.position()))
                            self.index += 1
                            if self.peek() != ",":
                                break
                            self.index += 1
                        self.expect("}")
                        if self.peek() != "(":
                            self.expect("(")
                    pending.append((OP_CALL, 0, (*position, text, tuple(params), 0)))
                elif kind == "name":
                    ops.append(OP_SIGNAL)
                    args.append((text, *position))
                    expect_operand = False
                elif text == "(":
                    pending.append(("(", 0, position))
                elif text == "if" and kind == "keyword":
                    pending.append(("if", 0, position))
                elif text in PREFIX_OPS:
                    pending.append((PREFIX_OPS[text], PREFIX_PRECEDENCE[text], position))
                elif text != "+":
                    self.fail(f"expected an expression, found {text or 'end of file'!r}")
                self.index += 1
                continue
            if text in BINARY_PRECEDENCE:
                precedence = BINARY_PRECEDENCE[text]
                while pending and pending[-1][0] not in OPENERS and pending[-1][1] >= precedence:
                    self.reduce(pending.pop(), ops, args)
                pending.append((BINARY_OPS[text], precedence, position))
                self.index += 1
                expect_operand = True
            elif text in ("then", "else") and kind == "keyword" and any(entry[0] in OPENERS for entry in pending):
                while pending[-1][0] not in OPENERS:
                    self.reduce(pending.pop(), ops, args)
                opener = pending[-1][0]
                if opener != ("if" if text == "then" else "then"):
                    self.fail(MISSING_KEYWORD.get(opener, "unbalanced parenthesis"))
                marker = pending.pop()
                if text == "then":
                    pending.append(("then", 0, marker[2]))
                else:
                    pending.append((OP_IF, CONDITION_PRECEDENCE, marker[2]))
                    pending.append((OP_BRANCH, CONDITION_PRECEDENCE, marker[2]))
                self.index += 1
                expect_operand = True
            elif text == "$":
                while pending and pending[-1][0] not in OPENERS and pending[-1][1] > DELAY_PRECEDENCE:
                    self.reduce(pending.pop(), ops, args)
                self.index += 1
                initial = None
                if self.peek() == "init":
                    self.index += 1
                    negated = self.peek() == "-" and self.tokens.kinds[self.index + 1] == "number"
                    self.index += negated
                    initial = self.parse_literal()
                    if initial is None:
                        self.fail("the initial value of a delay must be a constant")
                    if negated:
                        initial = (OP_CONST, (-initial[1][0], initial[1][1]))
                ops.append(OP_DELAY)
                args.append((*position, initial))
            elif text == "[" and self.tokens.texts[self.index + 1] == "?":
                self.index += 2
                self.expect("]")
                ops.append(OP_PREV)
                args.append(position)
            elif text == "[":
                pending.append(("[", 0, position))
                self.index += 1
                expect_operand = True
            elif text in (")", "]") and any(entry[0] in OPENERS for entry in pending):
                while pending[-1][0] not in OPENERS:
                    self.reduce(pending.pop(), ops, args)
                opener = pending.pop()
                if opener[0] in MISSING_KEYWORD:
                    self.fail(MISSING_KEYWORD[opener[0]])
                if (opener[0] == "[") != (text == "]"):
                    self.fail("unbalanced parenthesis")
                if opener[0] == OP_CALL:
                    self.reduce((OP_CALL, 0, (*opener[2][:4], opener[2][4] + 1)), ops, args)
                elif opener[0] == "[":
                    self.reduce((OP_INDEX, 0, opener[2]), ops, args)
                self.index += 1
            elif text == "," and [entry[0] for entry in pending if entry[0] in OPENERS][-1:] == [OP_CALL]:
                while pending[-1][0] != OP_CALL:
                    self.reduce(pending.pop(), ops, args)
                call = pending.pop()
                pending.append((OP_CALL, 0, (*call[2][:4], call[2][4] + 1)))
                self.index += 1
                expect_operand = True
            elif text in EXPRESSION_TERMINATORS or text == ")":
                while pending:
                    if pending[-1][0] in OPENERS:
                        self.fail(MISSING_KEYWORD.get(pending[-1][0], "unbalanced parenthesis"))
                    self.reduce(pending.pop(), ops, args)
                return ops, args
            else:
                openers = [entry[0] for entry in pending if entry[0] in OPENERS]
                self.fail(
                    MISSING_KEYWORD.get(openers[-1] if openers else None, f"expected an operator, found {text or 'end of file'!r}")
                )

    def reduce(self, entry, ops, args):
        op, _, position = entry
        ops.append(op)
        args.append(position)


def call_segments(ops, args):
    starts = []
    open_starts = []
    for index, (op, arg) in enumerate(zip(ops, args)):
        arity = 0 if op in (OP_SIGNAL, OP_CONST, OP_ENUMCONST) else arg[4] if op == OP_CALL else 1 if op in UNARY_OPS else 2
        start = open_starts[-arity] if arity else index
        del open_starts[len(open_starts) - arity:]
        open_starts.append(start)
        starts.append(start)
    return starts


def instantiate(source):
    models = source.models
    flat = Program(
        name=source.name,
        types=source.types,
        constant_names=source.constant_names,
        constant_types=source.constant_types,
        constant_values=source.constant_values,
        table_types=source.table_types,
        table_values=source.table_values,
    )
    instance_models = [0]
    instance_parents = [-1]
    instance_prefixes = [""]
    instance_labels = [()]
    instance_guards = [()]
    instance_counts = [0] * len(models.name)
    instance = 0
    while instance < len(instance_models):
        model = instance_models[instance]
        prefix = instance_prefixes[instance]
        own_labels = models.labels[model]
        flat.label_names.extend(prefix + label for label in own_labels)
        own = set()
        for name, role, signal_type, owner, position in zip(
            source.signal_names, source.signal_roles, source.signal_types, source.signal_models, source.signal_positions
        ):
            if owner == model:
                own.add(name)
                flat.signal_names.append(prefix + name)
                flat.signal_roles.append(role if instance == 0 else "local")
                flat.signal_types.append(signal_type)
                flat.signal_positions.append(position)
        flat_loops = {}
        for loop, owner in enumerate(source.loop_models):
            if owner != model:
                continue
            name = source.loop_names[loop]
            if name not in own:
                raise CompileError(f"signal {name} is not declared", *source.loop_positions[loop])
            flat_loops[loop] = len(flat.loop_names)
            flat.loop_names.append(prefix + name)
            flat.loop_positions.append(source.loop_positions[loop])
        postfixes = [(equation, -1) for equation, owner in enumerate(source.equation_models) if owner == model]
        postfixes.extend(
            (group, member)
            for group, owner in enumerate(source.constraint_models)
            if owner == model
            for member in range(len(source.constraint_groups[group]))
        )
        for item, member in postfixes:
            if member < 0:
                ops = source.equation_ops[item]
                args = source.equation_args[item]
                target = source.equation_targets[item]
                loop = source.equation_loops[item]
                labels = instance_labels[instance] + tuple(prefix + label for label in source.equation_labels[item])
                guards = instance_guards[instance] + tuple(
                    prefix + source.guard_signals[guard] for guard in source.equation_guards[item]
                )
                if target is not None and target not in own and source.equation_kinds[item] == DEFINE:
                    raise CompileError(f"signal {target} is not declared", *source.equation_positions[item])
            else:
                ops, args = source.constraint_groups[item][member]
                target = ""
                loop = -1
                labels = instance_labels[instance]
                guards = instance_guards[instance] + tuple(
                    prefix + source.guard_signals[guard] for guard in source.constraint_guards[item]
                )
            out_ops = []
            out_args = []
            starts = []
            for index, (op, arg) in enumerate(zip(ops, args)):
                if op in (OP_SIGNAL, OP_CONST, OP_ENUMCONST):
                    if op == OP_SIGNAL and arg[0] in own:
                        arg = (prefix + arg[0], arg[1], arg[2])
                    elif op == OP_SIGNAL and arg[0] in own_labels:
                        raise CompileError(f"label {arg[0]} cannot be used as a signal", arg[1], arg[2])
                    elif op == OP_SIGNAL and arg[0] not in source.constant_names:
                        raise CompileError(f"signal {arg[0]} is not declared", arg[1], arg[2])
                    starts.append(len(out_ops))
                    out_ops.append(op)
                    out_args.append(arg)
                    continue
                arity = arg[4] if op == OP_CALL else 1 if op in UNARY_OPS else 2
                operand_starts = starts[len(starts) - arity:]
                del starts[len(starts) - arity:]
                start = operand_starts[0] if operand_starts else len(out_ops)
                if op == OP_CALL:
                    line, column, name, params, count = arg
                    called_as_process = target is None and index == len(ops) - 1
                    if name in source.types.name or name == "indices":
                        if called_as_process:
                            raise CompileError(f"model {name} has an output and cannot be called as a process", line, column)
                        if count != 1 or params:
                            message = f"conversion to {name} expects one argument" if name != "indices" else "indices expects a positive constant"
                            raise CompileError(message, line, column)
                    elif name in BUILTINS:
                        _, input_count, has_output = BUILTINS[name]
                        if loop >= 0:
                            raise CompileError("model calls are not allowed inside iterate", line, column)
                        if count != input_count:
                            raise CompileError(
                                f"wrong number of arguments for {name}: expected {input_count}, found {count}", line, column
                            )
                        if called_as_process and has_output:
                            raise CompileError(f"model {name} has an output and cannot be called as a process", line, column)
                        if not called_as_process and not has_output:
                            raise CompileError(f"model {name} has no output and cannot be used in an expression", line, column)
                        caller = instance
                        while caller >= 0 and models.kind[instance_models[caller]] not in PURE_CLASSES:
                            caller = instance_parents[caller]
                        if caller >= 0:
                            pure_model = instance_models[caller]
                            raise CompileError(
                                f"unsafe model {name} is called from {models.kind[pure_model]} {models.name[pure_model]}",
                                line,
                                column,
                            )
                        op = OP_EFFECT
                    else:
                        if name not in models.name:
                            raise CompileError(f"model {name} is not declared", line, column)
                        callee = models.name.index(name)
                        if params:
                            raise CompileError(f"model {name} takes no static parameters", line, column)
                        if loop >= 0:
                            raise CompileError("model calls are not allowed inside iterate", line, column)
                        caller = instance
                        while caller >= 0:
                            if instance_models[caller] == callee:
                                raise CompileError(f"model {name} calls itself", line, column)
                            caller = instance_parents[caller]
                        interface = [
                            (signal, role)
                            for signal, role, owner in zip(source.signal_names, source.signal_roles, source.signal_models)
                            if owner == callee and role != "local"
                        ]
                        inputs = [signal for signal, role in interface if role == "input"]
                        outputs = [signal for signal, role in interface if role == "output"]
                        if count != len(inputs):
                            raise CompileError(
                                f"wrong number of arguments for {name}: expected {len(inputs)}, found {count}", line, column
                            )
                        if len(outputs) >= 2:
                            raise CompileError(
                                f"model {name} has {len(outputs)} outputs; only models with at most one output can be called",
                                line,
                                column,
                            )
                        if called_as_process and outputs:
                            raise CompileError(f"model {name} has an output and cannot be called as a process", line, column)
                        if not called_as_process and not outputs:
                            raise CompileError(f"model {name} has no output and cannot be used in an expression", line, column)
                        instance_counts[callee] += 1
                        callee_prefix = f"{name}#{instance_counts[callee]}."
                        instance_models.append(callee)
                        instance_parents.append(instance)
                        instance_prefixes.append(callee_prefix)
                        instance_guards.append(guards)
                        if member < 0 and target is not None and source.equation_kinds[item] == DEFINE:
                            flat.label_names.append(f"{prefix}{target}'call")
                            instance_labels.append((*labels, f"{prefix}{target}'call"))
                        else:
                            instance_labels.append(labels)
                        bounds = operand_starts + [len(out_ops)]
                        for position, signal in enumerate(inputs):
                            flat.equation_targets.append(callee_prefix + signal)
                            flat.equation_ops.append(out_ops[bounds[position]:bounds[position + 1]])
                            flat.equation_args.append(out_args[bounds[position]:bounds[position + 1]])
                            flat.equation_positions.append((line, column))
                            flat.equation_loops.append(-1)
                            flat.equation_kinds.append(DEFINE)
                            flat.equation_labels.append(labels)
                            flat.equation_guards.append(guards)
                        if models.kind[callee] in ORDERED_CLASSES:
                            for signal in inputs:
                                for result in outputs:
                                    flat.dependence_from.append((callee_prefix + signal, line, column))
                                    flat.dependence_to.append((callee_prefix + result, line, column))
                                    flat.dependence_positions.append((line, column))
                        del out_ops[start:]
                        del out_args[start:]
                        if not outputs:
                            continue
                        op = OP_SIGNAL
                        arg = (callee_prefix + outputs[0], line, column)
                starts.append(start)
                out_ops.append(op)
                out_args.append(arg)
            if member >= 0:
                if member == 0:
                    flat.constraint_groups.append([])
                    flat.constraint_positions.append(source.constraint_positions[item])
                    flat.constraint_guards.append(guards)
                flat.constraint_groups[-1].append((out_ops, out_args))
            elif out_ops:
                flat.equation_targets.append(None if target is None else prefix + target)
                flat.equation_ops.append(out_ops)
                flat.equation_args.append(out_args)
                flat.equation_positions.append(source.equation_positions[item])
                flat.equation_loops.append(flat_loops[loop] if loop >= 0 else -1)
                flat.equation_kinds.append(source.equation_kinds[item])
                flat.equation_labels.append(labels)
                flat.equation_guards.append(guards)
        for source_end, destination_end, position, owner in zip(
            source.dependence_from, source.dependence_to, source.dependence_positions, source.dependence_models
        ):
            if owner != model:
                continue
            for name, line, column in (source_end, destination_end):
                if name not in own and name not in own_labels:
                    raise CompileError(f"signal {name} is not declared", line, column)
            flat.dependence_from.append((prefix + source_end[0], source_end[1], source_end[2]))
            flat.dependence_to.append((prefix + destination_end[0], destination_end[1], destination_end[2]))
            flat.dependence_positions.append(position)
        instance += 1
    return flat


def flatten(rows, program, indices, ops, args, owner, line, column, loop, loops):
    types = program.types
    stack = []
    for op, arg in zip(ops, args):
        left = right = -1
        value = 0
        if op == OP_SIGNAL and loop >= 0 and arg[0] == program.loop_names[loop]:
            op = OP_ITER
            left = loops.index[loop]
            row_type = types.element[rows.type[left]]
            line, column = arg[1], arg[2]
        elif op == OP_SIGNAL:
            name, line, column = arg
            if name in indices:
                stack.append(indices[name])
                continue
            if name not in program.constant_names:
                raise CompileError(f"signal {name} is not declared", line, column)
            constant = program.constant_names.index(name)
            arg = program.constant_values[constant], program.constant_types[constant]
            op = OP_TABLE if types.kind[arg[1]] == KIND_ARRAY else OP_CONST
        if op == OP_ENUMCONST:
            op = OP_CONST
            arg = resolve_enum(types, *arg)
        if op in (OP_CONST, OP_TABLE):
            value, row_type = arg
        elif op == OP_EFFECT:
            line, column, name, params, count = arg
            parameter_kinds = ("resource", *BUILTINS[name][0])
            if len(params) != len(parameter_kinds):
                raise CompileError(
                    f"{name} expects {len(parameter_kinds)} static parameters, found {len(params)}", line, column
                )
            resource = param = -1
            for (text, token_kind, param_line, param_column), param_kind in zip(params, parameter_kinds):
                constant = program.constant_names.index(text) if text in program.constant_names else -1
                if param_kind == "word" and token_kind == "number":
                    param = int(text)
                elif param_kind == "word" and constant >= 0 and is_integer(types, program.constant_types[constant]):
                    param = program.constant_values[constant]
                elif param_kind == "word":
                    raise CompileError(f"the word of {name} must be an integer constant", param_line, param_column)
                elif text not in types.name:
                    raise CompileError(f"type {text} is not declared", param_line, param_column)
                elif param_kind == "resource" and types.kind[types.name.index(text)] != KIND_EXTERNAL:
                    raise CompileError(f"the resource of {name} must be an external type", param_line, param_column)
                elif param_kind == "resource":
                    resource = types.name.index(text)
                elif types.kind[types.name.index(text)] not in (KIND_INT, KIND_POINTER):
                    raise CompileError(f"{name} accesses an integer or pointer type, found {text}", param_line, param_column)
                else:
                    param = types.name.index(text)
                if param_kind == "word" and not 0 <= param < 1 << 32:
                    raise CompileError(f"the word of {name} must fit in 32 bits", param_line, param_column)
            operands = stack[len(stack) - count:]
            del stack[len(stack) - count:]
            operand_types = [types.name[rows.type[operand]] for operand in operands]
            for operand in operands:
                if rows.op[operand] == OP_PAIR:
                    raise CompileError("':' is supported only as the right operand of next", rows.line[operand], rows.column[operand])
            if name in ("load", "store") and rows.type[operands[0]] != POINTER:
                raise CompileError(f"input 1 of {name} must be a pointer, found {operand_types[0]}", line, column)
            if name == "store" and not subtype(types, rows.type[operands[1]], param):
                raise CompileError(
                    f"input 2 of store must have type {types.name[param]}, found {operand_types[1]}", line, column
                )
            for position, operand in enumerate(operands, 1):
                if name == "syscall" and types.kind[rows.type[operand]] not in (KIND_INT, KIND_POINTER):
                    raise CompileError(
                        f"input {position} of syscall must be an integer or a pointer, found {operand_types[position - 1]}",
                        line,
                        column,
                    )
            if name == "instruction" and not subtype(types, rows.type[operands[0]], ULONG):
                raise CompileError(f"input 1 of instruction must have type ulong, found {operand_types[0]}", line, column)
            row_type = {"load": param, "store": EVENT, "syscall": LONG, "instruction": ULONG}[name]
            for operand in reversed(operands):
                for column_list, cell in zip(
                    (rows.op, rows.left, rows.right, rows.value, rows.type, rows.ctx, rows.line, rows.column, rows.owner, rows.loop),
                    (
                        OP_ARG,
                        operand,
                        left,
                        0,
                        rows.type[operand],
                        rows.ctx[operand] and (left < 0 or rows.ctx[left]),
                        line,
                        column,
                        owner,
                        loop,
                    ),
                ):
                    column_list.append(cell)
                left = len(rows.op) - 1
            value = len(rows.effects.kind)
            rows.effects.kind.append(name)
            rows.effects.resource.append(resource)
            rows.effects.param.append(param)
        elif op != OP_ITER:
            line, column = arg[0], arg[1]
            if op in UNARY_OPS:
                left = stack.pop()
            else:
                right = stack.pop()
                left = stack.pop()
            left_type = rows.type[left]
            right_type = rows.type[right] if right >= 0 else left_type
            if loop >= 0 and op in (OP_WHEN, OP_UWHEN, OP_DEFAULT, OP_DELAY, OP_CLOCK):
                raise CompileError(f"operator {OP_TEXT[op]} is not allowed inside iterate", line, column)
            for operand in (left, right):
                if operand >= 0 and rows.op[operand] == OP_PAIR and not (op == OP_NEXT and operand == right):
                    raise CompileError("':' is supported only as the right operand of next", rows.line[operand], rows.column[operand])
                if operand >= 0 and rows.op[operand] in (OP_GATHER, OP_NEXT):
                    raise CompileError("an array value can only be the whole definition of a signal", line, column)
            array_operand = KIND_ARRAY in (types.kind[left_type], types.kind[right_type])
            if op == OP_PREV:
                if left >= len(program.signal_names):
                    raise CompileError("[?] applies only to a signal name", line, column)
                name = program.signal_names[left]
                if loop < 0:
                    raise CompileError(f"{name}[?] is allowed only inside iterate", line, column)
                if left not in loops.defined[loop]:
                    raise CompileError(f"{name}[?] refers to a signal the iterate body does not define", line, column)
            if op == OP_CALL and arg[2] == "indices":
                if rows.op[left] != OP_CONST or not is_integer(types, left_type) or rows.value[left] <= 0:
                    raise CompileError("indices expects a positive constant", line, column)
                table_type = intern_array(types, INTEGER, rows.value[left])
                table_values = tuple(range(rows.value[left]))
                tables = list(zip(program.table_types, program.table_values))
                if (table_type, table_values) not in tables:
                    program.table_types.append(table_type)
                    program.table_values.append(table_values)
                    tables.append((table_type, table_values))
                rows.op[left] = OP_TABLE
                rows.value[left] = tables.index((table_type, table_values))
                rows.type[left] = table_type
                rows.ctx[left] = True
                stack.append(left)
                continue
            if op in (OP_INDEX, OP_NEXT) and types.kind[left_type] != KIND_ARRAY:
                raise CompileError("indexing a value that is not an array", line, column)
            if op == OP_PREV:
                row_type = left_type
            elif op == OP_INDEX and types.kind[right_type] == KIND_ARRAY:
                if not is_integer(types, types.element[right_type]):
                    raise CompileError("an array index must be an integer", line, column)
                op = OP_GATHER
                row_type = intern_array(types, types.element[left_type], types.size[right_type])
            elif op in (OP_INDEX, OP_NEXT):
                if op == OP_NEXT and rows.op[right] != OP_PAIR:
                    raise CompileError("next expects 'index : value' on its right", line, column)
                index = rows.left[right] if op == OP_NEXT else right
                size = types.size[left_type]
                if not is_integer(types, rows.type[index]):
                    raise CompileError("an array index must be an integer", rows.line[index], rows.column[index])
                if rows.op[index] == OP_CONST and not 0 <= rows.value[index] < size:
                    raise CompileError(
                        f"constant index {rows.value[index]} is outside 0..{size - 1}", rows.line[index], rows.column[index]
                    )
                element = types.element[left_type]
                if op == OP_NEXT and not subtype(types, right_type, element):
                    raise CompileError(
                        f"next expects a value of type {types.name[element]}, found {types.name[right_type]}", line, column
                    )
                row_type = left_type if op == OP_NEXT else element
                op = OP_NEXT if op == OP_NEXT else OP_ELEMENT
            elif op == OP_DELAY and array_operand:
                raise CompileError("$ is not supported on arrays", line, column)
            elif array_operand and op != OP_CALL:
                raise CompileError(f"operator {OP_TEXT[op]} expects scalar operands", line, column)
            elif op == OP_PAIR:
                row_type = right_type
            elif op == OP_BRANCH:
                row_type = lub(types, left_type, right_type)
                if row_type < 0:
                    raise CompileError(
                        "operator if expects operands of comparable types, "
                        f"found {types.name[left_type]} and {types.name[right_type]}",
                        line,
                        column,
                    )
            elif op == OP_IF:
                if not is_logical(types, left_type):
                    raise CompileError("the condition of if must be boolean", line, column)
                row_type = right_type
            elif op == OP_CALL:
                op = OP_CONVERT
                row_type = types.name.index(arg[2])
                if not (
                    left_type == row_type
                    or is_integer(types, row_type)
                    and (is_integer(types, left_type) or types.kind[left_type] in (KIND_BOOLEAN, KIND_ENUM))
                    or row_type == POINTER and left_type in (ULONG, UINTEGER)
                    or left_type == POINTER and row_type in (ULONG, UINTEGER)
                ):
                    raise CompileError(
                        f"no conversion from {types.name[left_type]} to {types.name[row_type]}", line, column
                    )
            elif op in (OP_ADD, OP_SUB) and POINTER in (left_type, right_type):
                if left_type != POINTER or not is_integer(types, right_type):
                    raise CompileError(f"operator {OP_TEXT[op]} expects a pointer and an integer offset", line, column)
                row_type = POINTER
            elif op in INTEGER_OPS:
                if not (is_integer(types, left_type) and is_integer(types, right_type)):
                    raise CompileError(f"operator {OP_TEXT[op]} expects integer operands", line, column)
                row_type = lub(types, left_type, right_type)
                if row_type < 0:
                    raise CompileError(
                        f"operator {OP_TEXT[op]} expects operands of comparable types, "
                        f"found {types.name[left_type]} and {types.name[right_type]}",
                        line,
                        column,
                    )
                if op == OP_MOD:
                    row_type = right_type
            elif op in EQUALITY_OPS or op in ORDER_OPS:
                if lub(types, left_type, right_type) < 0:
                    if is_integer(types, left_type) and is_integer(types, right_type):
                        raise CompileError(
                            f"operator {OP_TEXT[op]} expects operands of comparable types, "
                            f"found {types.name[left_type]} and {types.name[right_type]}",
                            line,
                            column,
                        )
                    raise CompileError(f"operator {OP_TEXT[op]} expects operands of one type", line, column)
                row_type = BOOLEAN
            elif op in LOGIC_OPS:
                if is_logical(types, left_type) and is_logical(types, right_type):
                    row_type = BOOLEAN
                elif not (is_integer(types, left_type) and is_integer(types, right_type)):
                    raise CompileError(f"operator {OP_TEXT[op]} expects boolean operands", line, column)
                elif types.signed[left_type] or types.signed[right_type]:
                    raise CompileError(f"operator {OP_TEXT[op]} expects unsigned operands", line, column)
                else:
                    row_type = lub(types, left_type, right_type)
            elif op in SHIFT_OPS:
                if not (is_integer(types, left_type) and not types.signed[left_type] and is_integer(types, right_type)):
                    raise CompileError(f"operator {OP_TEXT[op]} expects unsigned operands", line, column)
                row_type = left_type
            elif op in (OP_WHEN, OP_UWHEN):
                if not is_logical(types, rows.type[right if op == OP_WHEN else left]):
                    raise CompileError("the condition of when must be boolean", line, column)
                row_type = left_type if op == OP_WHEN else EVENT
            elif op == OP_DEFAULT:
                row_type = lub(types, left_type, right_type)
                if row_type < 0:
                    raise CompileError(f"operator {OP_TEXT[op]} expects operands of one type", line, column)
            elif op == OP_CLOCK:
                row_type = EVENT
            else:
                row_type = left_type
                initial = arg[2]
                if initial is not None:
                    initial = resolve_enum(types, *initial[1]) if initial[0] == OP_ENUMCONST else initial[1]
                if initial is not None and (row_type == EVENT or not subtype(types, initial[1], row_type)):
                    raise CompileError("the initial value of a delay must match its type", line, column)
                value = 1 if row_type == EVENT else initial[0] if initial else 0
        ctx = (
            op in (OP_CONST, OP_TABLE)
            or op in MONOCHRONOUS_OPS and rows.ctx[left] and (right < 0 or rows.ctx[right])
            or op == OP_DEFAULT and rows.ctx[left]
        )
        stack.append(len(rows.op))
        rows.op.append(op)
        rows.left.append(left)
        rows.right.append(right)
        rows.value.append(value)
        rows.type.append(row_type)
        rows.ctx.append(ctx)
        rows.line.append(line)
        rows.column.append(column)
        rows.owner.append(owner)
        rows.loop.append(loop)
    if rows.op[stack[-1]] == OP_PAIR:
        raise CompileError("':' is supported only as the right operand of next", rows.line[stack[-1]], rows.column[stack[-1]])
    return stack[-1]


def lower(program):
    names = program.signal_names
    types = program.signal_types
    indices = {name: i for i, name in enumerate(names)}
    rows = Rows()
    for signal, role in enumerate(program.signal_roles):
        rows.op.append(OP_INPUT if role == "input" else OP_COPY)
        rows.left.append(-1)
        rows.right.append(-1)
        rows.value.append(0)
        rows.type.append(types[signal])
        rows.ctx.append(False)
        rows.line.append(1)
        rows.column.append(1)
        rows.owner.append(signal)
        rows.loop.append(-1)
        rows.guard.append(-1)
    loops = Loops()
    for name, (line, column) in zip(program.loop_names, program.loop_positions):
        if name not in indices:
            raise CompileError(f"signal {name} is not declared", line, column)
        index_type = types[indices[name]]
        if program.types.kind[index_type] != KIND_ARRAY or not is_integer(program.types, program.types.element[index_type]):
            raise CompileError("the index of iterate must be an array of integers", line, column)
        loops.index.append(indices[name])
        loops.size.append(program.types.size[index_type])
        loops.defined.append(set())
    for equation, target in enumerate(program.equation_targets):
        loop = program.equation_loops[equation]
        if loop < 0 or program.equation_kinds[equation] != DEFINE:
            continue
        line, column = program.equation_positions[equation]
        if target == program.loop_names[loop]:
            raise CompileError(f"iterate body cannot define its index {target}", line, column)
        if target not in indices:
            raise CompileError(f"signal {target} is not declared", line, column)
        loops.defined[loop].add(indices[target])
        rows.loop[indices[target]] = loop
    def_range = [(-1, -1)] * len(names)
    label_rows = {label: [] for label in program.label_names}
    for equation, target in enumerate(program.equation_targets):
        line, column = program.equation_positions[equation]
        loop = program.equation_loops[equation]
        ops = program.equation_ops[equation]
        args = program.equation_args[equation]
        start = len(rows.op)
        if program.equation_kinds[equation] == SEED:
            signal = indices.get(target, -1)
            if signal not in loops.defined[loop]:
                raise CompileError(f"signal {target} in with is not defined by the iterate body", line, column)
            if any(op == OP_SIGNAL and indices.get(arg[0], -1) in loops.defined[loop] for op, arg in zip(ops, args)):
                raise CompileError(f"the initial value of {target} cannot read a signal the iterate defines", line, column)
            top = flatten(rows, program, indices, ops, args, signal, line, column, -1, loops)
            if program.types.kind[types[signal]] == KIND_ARRAY and not (
                rows.op[top] == OP_TABLE or top < len(names) and rows.type[top] == types[signal]
            ):
                raise CompileError("with initializes an array only from an array constant or an array signal", line, column)
            if not subtype(program.types, rows.type[top], types[signal]):
                raise CompileError(
                    f"signal {target} has type {program.types.name[types[signal]]} "
                    f"but its definition has type {program.types.name[rows.type[top]]}",
                    line,
                    column,
                )
            rows.op.append(OP_SEED)
            rows.left.append(top)
            rows.right.append(signal)
            rows.value.append(0)
            rows.type.append(types[signal])
            rows.ctx.append(False)
            rows.line.append(line)
            rows.column.append(column)
            rows.owner.append(signal)
            rows.loop.append(loop)
        elif target is None:
            signal = -1
            flatten(rows, program, indices, ops, args, signal, line, column, loop, loops)
        else:
            if target not in indices:
                raise CompileError(f"signal {target} is not declared", line, column)
            signal = indices[target]
            if rows.op[signal] == OP_INPUT:
                raise CompileError(f"input signal {target} cannot be defined", line, column)
            if rows.left[signal] >= 0:
                raise CompileError(f"signal {target} is defined twice", line, column)
            top = flatten(rows, program, indices, ops, args, signal, line, column, loop, loops)
            if not subtype(program.types, rows.type[top], types[signal]):
                raise CompileError(
                    f"signal {target} has type {program.types.name[types[signal]]} "
                    f"but its definition has type {program.types.name[rows.type[top]]}",
                    line,
                    column,
                )
            if program.types.kind[types[signal]] == KIND_ARRAY and rows.op[top] not in (OP_TABLE, OP_GATHER, OP_NEXT):
                raise CompileError("an array signal must be defined by a constant, indices, a gather, or next", line, column)
            rows.left[signal] = top
            rows.line[signal] = line
            rows.column[signal] = column
            def_range[signal] = (start, len(rows.op))
        guards = program.equation_guards[equation]
        guard = indices[guards[-1]] if guards else -1
        rows.guard.extend([guard] * (len(rows.op) - len(rows.guard)))
        if signal >= 0 and program.equation_kinds[equation] == DEFINE:
            rows.guard[signal] = guard
        for label in program.equation_labels[equation]:
            label_rows[label].extend(range(start, len(rows.op)))
            if signal >= 0:
                label_rows[label].append(signal)
    for signal, name in enumerate(names):
        if rows.left[signal] < 0 and rows.op[signal] != OP_INPUT:
            raise CompileError(f"signal {name} is never defined", 1, 1)
    for group, (line, column), guards in zip(program.constraint_groups, program.constraint_positions, program.constraint_guards):
        members = [flatten(rows, program, indices, ops, args, -1, line, column, -1, loops) for ops, args in group]
        rows.guard.extend([indices[guards[-1]] if guards else -1] * (len(rows.op) - len(rows.guard)))
        if any(rows.op[member] in (OP_GATHER, OP_NEXT) for member in members):
            raise CompileError("an array value can only be the whole definition of a signal", line, column)
        rows.groups.append(members)
        rows.group_positions.append((line, column))
    for source, destination in zip(program.dependence_from, program.dependence_to):
        for name, line, column in (source, destination):
            if name not in indices and name not in label_rows:
                raise CompileError(f"signal {name} is not declared", line, column)
        source_rows = (
            [indices[source[0]], *label_rows.get(f"{source[0]}'call", ())]
            if source[0] in indices
            else label_rows[source[0]]
        )
        destination_rows = (
            [
                indices[destination[0]],
                *range(*def_range[indices[destination[0]]]),
                *label_rows.get(f"{destination[0]}'call", ()),
            ]
            if destination[0] in indices
            else label_rows[destination[0]]
        )
        for source_row in source_rows:
            rows.dependence_from.extend([source_row] * len(destination_rows))
            rows.dependence_to.extend(destination_rows)
    for previous, op in enumerate(rows.op):
        if op != OP_PREV:
            continue
        signal = rows.left[previous]
        writer = rows.left[signal]
        if program.types.kind[types[signal]] != KIND_ARRAY:
            rows.dependence_from.append(previous)
            rows.dependence_to.append(signal)
            continue
        for reader in range(len(rows.op)):
            if reader != writer and previous in (rows.left[reader], rows.right[reader]):
                rows.war.append((reader, writer, signal))
    return rows, loops


def find(clocks, clock):
    parent = clocks.parent
    while parent[clock] != clock:
        parent[clock] = parent[parent[clock]]
        clock = parent[clock]
    return clock


def union(clocks, first, second):
    first = find(clocks, first)
    second = find(clocks, second)
    if first != second:
        clocks.parent[first] = second


def ancestor_or_self(clocks, ancestor, clock):
    while clocks.node_depth[clock] > clocks.node_depth[ancestor]:
        clock = clocks.node_parent[clock]
    return clock == ancestor


def define(clocks, kind, target, left, right, line, column):
    clocks.def_kind.append(kind)
    clocks.def_target.append(target)
    clocks.def_left.append(left)
    clocks.def_right.append(right)
    clocks.def_line.append(line)
    clocks.def_column.append(column)
    clocks.def_pending.append(True)


def oblige(clocks, small, big, line, column):
    clocks.ob_small.append(small)
    clocks.ob_big.append(big)
    clocks.ob_line.append(line)
    clocks.ob_column.append(column)


def clock_name(clocks, rows, program, clock):
    names = program.signal_names
    for signal, name in enumerate(names):
        if find(clocks, signal) == clock:
            return name
    first = min(c for c in range(len(clocks.parent)) if find(clocks, c) == clock)
    if first >= len(rows.op):
        first = clocks.sample_rows[first - len(rows.op)]
        if first < len(names):
            return f"[{names[first]}]"
    return f"[expression at {rows.line[first]}:{rows.column[first]}]"


def root_order(clocks, signal_count):
    order = []
    for signal in range(signal_count):
        clock = find(clocks, signal)
        if clocks.node_kind[clock] is not None and clocks.node_root[clock] not in order:
            order.append(clocks.node_root[clock])
    for clock, kind in enumerate(clocks.node_kind):
        if kind == ROOT and clock not in order:
            order.append(clock)
    return order


def fits_no_tree(clocks, rows, program, clock, roots, line, column):
    order = root_order(clocks, len(program.signal_names))
    first, second = sorted(roots, key=order.index)
    return CompileError(
        f"clock of {clock_name(clocks, rows, program, clock)} fits no tree: it relates root clocks "
        f"{clock_name(clocks, rows, program, first)} and {clock_name(clocks, rows, program, second)}",
        line,
        column,
    )


def clock_calculus(rows, program, loops):
    row_count = len(rows.op)
    clocks = Clocks(parent=list(range(row_count)))
    sample_of_row = [-1] * row_count
    for row in range(row_count):
        op = rows.op[row]
        left = rows.left[row]
        right = rows.right[row]
        line = rows.line[row]
        column = rows.column[row]
        if op in (OP_WHEN, OP_UWHEN):
            condition = right if op == OP_WHEN else left
            if rows.ctx[condition]:
                raise CompileError("a constant has no clock", line, column)
            sample = condition
            if rows.type[condition] != EVENT:
                if sample_of_row[condition] < 0:
                    sample_of_row[condition] = len(clocks.parent)
                    clocks.parent.append(len(clocks.parent))
                    clocks.sample_rows.append(condition)
                sample = sample_of_row[condition]
        if rows.loop[row] >= 0:
            union(clocks, row, loops.index[rows.loop[row]])
        if op in (OP_COPY, OP_SEED, OP_EFFECT) or op in MONOCHRONOUS_OPS:
            union(clocks, row, left)
            if right >= 0:
                union(clocks, row, right)
        elif op in (OP_DELAY, OP_CLOCK):
            if rows.ctx[left]:
                message = "the argument of $ cannot be a constant" if op == OP_DELAY else "a constant has no clock"
                raise CompileError(message, line, column)
            union(clocks, row, left)
        elif op == OP_UWHEN:
            union(clocks, row, sample)
        elif op == OP_WHEN:
            if rows.ctx[left]:
                union(clocks, row, left)
                union(clocks, row, sample)
            else:
                define(clocks, PRODUCT, row, left, sample, line, column)
        elif op == OP_DEFAULT:
            if rows.ctx[left]:
                union(clocks, row, left)
                if rows.ctx[right]:
                    union(clocks, row, right)
            elif rows.ctx[right]:
                union(clocks, row, right)
                oblige(clocks, left, row, line, column)
            else:
                define(clocks, SUM, row, left, right, line, column)
    for sample, condition in enumerate(clocks.sample_rows):
        define(clocks, SAMPLE, row_count + sample, condition, -1, rows.line[condition], rows.column[condition])
    for group, (line, column) in zip(rows.groups, rows.group_positions):
        if any(rows.ctx[member] for member in group):
            raise CompileError("a constant has no clock", line, column)
        for member in group[1:]:
            union(clocks, group[0], member)
    for d in range(len(clocks.def_kind)):
        merged = clocks.def_target[d]
        if clocks.def_kind[d] != SUM or rows.op[rows.left[merged]] != OP_WHEN or rows.op[rows.right[merged]] != OP_WHEN:
            continue
        first, second = rows.right[rows.left[merged]], rows.right[rows.right[merged]]
        if rows.op[second] == OP_NOT and rows.left[second] == first:
            condition = first
        elif rows.op[first] == OP_NOT and rows.left[first] == second:
            condition = second
        else:
            continue
        values = rows.left[rows.left[merged]], rows.left[rows.right[merged]]
        if rows.ctx[values[0]] and rows.ctx[values[1]]:
            union(clocks, merged, condition)
            clocks.def_pending[d] = False
        elif not rows.ctx[values[0]] and not rows.ctx[values[1]] and find(clocks, values[0]) == find(clocks, values[1]):
            clocks.def_kind[d] = PRODUCT
            clocks.def_left[d] = values[0]
            clocks.def_right[d] = condition

    total = len(clocks.parent)
    clocks.node_kind = [None] * total
    clocks.node_parent = [-1] * total
    clocks.node_depth = [0] * total
    clocks.node_root = [-1] * total
    clocks.node_left = [-1] * total
    clocks.node_right = [-1] * total
    definitions = range(len(clocks.def_kind))
    progress = True
    while progress:
        progress = False
        targets = {find(clocks, clocks.def_target[d]) for d in definitions if clocks.def_pending[d]}
        class_guards = {}
        for row in range(row_count):
            if rows.guard[row] >= 0:
                class_guards.setdefault(find(clocks, row), rows.guard[row])
        for clock in range(total):
            if find(clocks, clock) == clock and clocks.node_kind[clock] is None and clock not in targets:
                guard_clock = find(clocks, class_guards.get(clock, clock))
                if guard_clock != clock:
                    if clocks.node_kind[guard_clock] is not None:
                        clocks.parent[clock] = guard_clock
                        progress = True
                    continue
                clocks.node_kind[clock] = ROOT
                clocks.node_root[clock] = clock
                progress = True
        for d in definitions:
            if not clocks.def_pending[d]:
                continue
            kind = clocks.def_kind[d]
            target = find(clocks, clocks.def_target[d])
            line = clocks.def_line[d]
            column = clocks.def_column[d]
            if kind == SAMPLE:
                operands = (find(clocks, clocks.def_left[d]),)
            else:
                operands = (find(clocks, clocks.def_left[d]), find(clocks, clocks.def_right[d]))
            if kind != SAMPLE and target in operands:
                others = [operand for operand in operands if operand != target]
                if others and kind == SUM:
                    oblige(clocks, others[0], target, line, column)
                elif others:
                    oblige(clocks, target, others[0], line, column)
                clocks.def_pending[d] = False
                progress = True
                continue
            if kind != SAMPLE and operands[0] == operands[1] and clocks.node_kind[target] is None:
                clocks.parent[target] = operands[0]
                clocks.def_pending[d] = False
                progress = True
                continue
            if any(clocks.node_kind[operand] is None for operand in operands):
                continue
            alias = -1
            if kind == SAMPLE:
                parent = operands[0]
                node_left = clocks.def_left[d]
                node_right = -1
            else:
                first, second = operands
                if clocks.node_root[first] != clocks.node_root[second]:
                    raise fits_no_tree(
                        clocks, rows, program, target, (clocks.node_root[first], clocks.node_root[second]), line, column
                    )
                node_left = first
                node_right = second
                if ancestor_or_self(clocks, first, second):
                    alias = second if kind == PRODUCT else first
                elif ancestor_or_self(clocks, second, first):
                    alias = first if kind == PRODUCT else second
                elif kind == PRODUCT:
                    parent = second if clocks.node_depth[second] > clocks.node_depth[first] else first
                else:
                    while clocks.node_depth[first] > clocks.node_depth[second]:
                        first = clocks.node_parent[first]
                    while clocks.node_depth[second] > clocks.node_depth[first]:
                        second = clocks.node_parent[second]
                    while first != second:
                        first = clocks.node_parent[first]
                        second = clocks.node_parent[second]
                    parent = first
            if clocks.node_kind[target] is None:
                if alias >= 0:
                    clocks.parent[target] = alias
                else:
                    clocks.node_kind[target] = kind
                    clocks.node_parent[target] = parent
                    clocks.node_depth[target] = clocks.node_depth[parent] + 1
                    clocks.node_root[target] = clocks.node_root[parent]
                    clocks.node_left[target] = node_left
                    clocks.node_right[target] = node_right
            elif not (
                alias == target
                if alias >= 0
                else clocks.node_kind[target] == kind
                and {clocks.node_left[target], clocks.node_right[target]} == {node_left, node_right}
            ):
                raise CompileError(
                    f"clock of {clock_name(clocks, rows, program, target)} has two definitions that cannot be shown equal",
                    line,
                    column,
                )
            clocks.def_pending[d] = False
            progress = True
    stalled = [d for d in definitions if clocks.def_pending[d]]
    if stalled:
        classes = {find(clocks, clocks.def_target[d]) for d in stalled}
        names = sorted(
            {name for signal, name in enumerate(program.signal_names) if find(clocks, signal) in classes}
            or {clock_name(clocks, rows, program, clock) for clock in classes}
        )
        raise CompileError(
            f"clocks of {', '.join(names)} are defined in terms of each other",
            clocks.def_line[stalled[0]],
            clocks.def_column[stalled[0]],
        )
    waiting_guards = sorted(
        {rows.guard[row] for row in range(row_count) if clocks.node_kind[find(clocks, row)] is None and rows.guard[row] >= 0},
        key=lambda guard: (rows.line[guard], rows.column[guard], program.signal_names[guard]),
    )
    if waiting_guards:
        raise CompileError(
            f"the clocks of guards {', '.join(program.signal_names[guard] for guard in waiting_guards)} depend on each other",
            rows.line[waiting_guards[0]],
            rows.column[waiting_guards[0]],
        )

    for o in range(len(clocks.ob_small)):
        big = find(clocks, clocks.ob_big[o])
        line = clocks.ob_line[o]
        column = clocks.ob_column[o]
        small = find(clocks, clocks.ob_small[o])
        if clocks.node_root[small] != clocks.node_root[big]:
            raise fits_no_tree(clocks, rows, program, big, (clocks.node_root[small], clocks.node_root[big]), line, column)
        pairs = [(small, big)]
        pair_index = {(small, big): 0}
        alternatives = []
        cursor = 0
        while cursor < len(pairs):
            clock, container = pairs[cursor]
            cursor += 1
            options = []
            if ancestor_or_self(clocks, container, clock):
                options.append([])
            else:
                kind = clocks.node_kind[clock]
                if kind != ROOT:
                    options.append([(clocks.node_parent[clock], container)])
                if kind in (SUM, PRODUCT):
                    left = find(clocks, clocks.node_left[clock])
                    right = find(clocks, clocks.node_right[clock])
                    if kind == SUM:
                        options.append([(left, container), (right, container)])
                    else:
                        options.extend([[(left, container)], [(right, container)]])
                container_kind = clocks.node_kind[container]
                if container_kind in (SUM, PRODUCT):
                    left = find(clocks, clocks.node_left[container])
                    right = find(clocks, clocks.node_right[container])
                    if container_kind == SUM:
                        options.extend([[(clock, left)], [(clock, right)]])
                    else:
                        options.append([(clock, left), (clock, right)])
            for option in options:
                for pair in option:
                    if pair not in pair_index:
                        pair_index[pair] = len(pairs)
                        pairs.append(pair)
            alternatives.append([[pair_index[pair] for pair in option] for option in options])
        holds = [False] * len(pairs)
        changed = True
        while changed:
            changed = False
            for pair in range(len(pairs)):
                if not holds[pair] and any(all(holds[q] for q in option) for option in alternatives[pair]):
                    holds[pair] = True
                    changed = True
        if not holds[0]:
            raise CompileError(
                f"clock of {clock_name(clocks, rows, program, small)} cannot be shown inside the clock "
                f"{clock_name(clocks, rows, program, big)}",
                line,
                column,
            )
    for signal, role in enumerate(program.signal_roles):
        if role == "input" and clocks.node_kind[find(clocks, signal)] != ROOT:
            raise CompileError(
                f"input signal {program.signal_names[signal]} must have a root of its own", *program.signal_positions[signal]
            )
    clocks.roots = root_order(clocks, len(program.signal_names))
    return clocks


def kahn(program, rows, present, edges, super_node, cyclic_ok=False):
    node_count = len(present)
    row_count = len(rows.op)
    successors = [[] for _ in range(node_count)]
    unmet = [0] * node_count
    for source, destination in edges:
        successors[source].append(destination)
        unmet[destination] += 1
    ready = [node for node in range(node_count) if present[node] and unmet[node] == 0]
    order = []
    while ready:
        node = ready.pop()
        order.append(node)
        for successor in successors[node]:
            unmet[successor] -= 1
            if unmet[successor] == 0:
                ready.append(successor)
    if len(order) < sum(present):
        if cyclic_ok:
            return None
        core = {node for node in range(node_count) if present[node] and unmet[node] > 0}
        while True:
            sinks = {node for node in core if not any(successor in core for successor in successors[node])}
            if not sinks:
                break
            core -= sinks
        owners = {rows.owner[row] for row in range(row_count) if super_node[row] in core and rows.owner[row] >= 0}
        if not owners:
            positions = sorted(
                (rows.line[row], rows.column[row])
                for row in range(row_count)
                if super_node[row] in core and rows.op[row] == OP_EFFECT
            )
            if not positions:
                raise CompileError(
                    "causality cycle between clocks",
                    *min(((rows.line[row], rows.column[row]) for row in range(row_count) if super_node[row] in core), default=(1, 1)),
                )
            raise CompileError(
                f"causality cycle between effects at {', '.join(f'{line}:{column}' for line, column in positions)}",
                *positions[0],
            )
        names = sorted(program.signal_names[owner] for owner in owners)
        line, column = min((rows.line[owner], rows.column[owner]) for owner in owners)
        raise CompileError(f"causality cycle between signals {', '.join(names)}", line, column)
    return order


def schedule(program, rows, clocks, loops):
    row_count = len(rows.op)
    loop_base = row_count + len(clocks.parent)
    edges = []
    for row in range(row_count):
        op = rows.op[row]
        left = rows.left[row]
        right = rows.right[row]
        edges.append((row_count + find(clocks, row), row))
        if op == OP_SEED:
            edges.append((left, row))
            edges.append((row, right))
            continue
        if op != OP_PREV and (op in (OP_COPY, OP_EFFECT) or op in MONOCHRONOUS_OPS or op in (OP_WHEN, OP_DEFAULT)):
            edges.append((left, row))
        if right >= 0 and (op in MONOCHRONOUS_OPS or op == OP_DEFAULT and not rows.ctx[left]):
            edges.append((right, row))
    for clock, kind in enumerate(clocks.node_kind):
        if kind == SAMPLE:
            edges.append((row_count + clocks.node_parent[clock], row_count + clock))
            edges.append((clocks.node_left[clock], row_count + clock))
        elif kind in (PRODUCT, SUM):
            edges.append((row_count + clocks.node_left[clock], row_count + clock))
            edges.append((row_count + clocks.node_right[clock], row_count + clock))
    edges.extend(zip(rows.dependence_from, rows.dependence_to))
    super_node = [loop_base + rows.loop[row] if rows.loop[row] >= 0 else row for row in range(row_count)]
    super_node.extend(range(row_count, loop_base + len(loops.index)))
    outer_edges = [(super_node[a], super_node[b]) for a, b in edges if a == b or super_node[a] != super_node[b]]
    present = [loop < 0 for loop in rows.loop] + [kind is not None for kind in clocks.node_kind] + [True] * len(loops.index)
    order = kahn(program, rows, present, outer_edges, super_node)
    loop_orders = []
    for loop in range(len(loops.index)):
        members = [rows.loop[row] == loop and rows.op[row] != OP_SEED for row in range(row_count)]
        inner_edges = [(a, b) for a, b in edges if a < row_count and b < row_count and members[a] and members[b]]
        snapshots = {
            rows.owner[row]
            for row in range(row_count)
            if members[row]
            and rows.op[row] == OP_GATHER
            and rows.op[rows.left[row]] == OP_PREV
            and rows.left[rows.left[row]] == rows.owner[row]
        }
        loop_war = [(reader, writer, signal) for reader, writer, signal in rows.war if members[reader]]
        war_kept = [(reader, writer) for reader, writer, signal in loop_war if signal not in snapshots]
        loop_order = kahn(program, rows, members, inner_edges + war_kept, range(row_count), cyclic_ok=True)
        if loop_order is None:
            loop_order = kahn(program, rows, members, inner_edges, range(row_count))
            snapshots |= {signal for _, _, signal in loop_war}
        loops.snapshots.append(sorted(snapshots))
        rows.snapshotted |= snapshots
        loop_orders.append(loop_order)
    successors = [[] for _ in range(loop_base)]
    for source, destination in edges:
        successors[source].append(destination)
    effects = rows.effects
    effect_rows = [row for row in range(row_count) if rows.op[row] == OP_EFFECT]
    reached = {}
    for row in effect_rows:
        seen = {row}
        pending = [row]
        while pending:
            node = pending.pop()
            for successor in successors[node]:
                if successor not in seen:
                    seen.add(successor)
                    pending.append(successor)
        reached[row] = seen
    for position, first in enumerate(effect_rows):
        for second in effect_rows[position + 1:]:
            first_effect = rows.value[first]
            second_effect = rows.value[second]
            if effects.resource[first_effect] != effects.resource[second_effect]:
                continue
            if second in reached[first] or first in reached[second]:
                continue
            raise CompileError(
                f"effects {effects.kind[first_effect]} at {rows.line[first]}:{rows.column[first]} and "
                f"{effects.kind[second_effect]} at {rows.line[second]}:{rows.column[second]} on resource "
                f"{program.types.name[effects.resource[first_effect]]} have no order between them; order them with -->",
                rows.line[second],
                rows.column[second],
            )
    return order, loop_orders


RUNTIME_ASSEMBLY = """
    .p2align 2
_rt_put_int:
    cmp x0, #0
    b.ge _rt_put_uint
    mov w10, #45
    strb w10, [x20], #1
    neg x0, x0
_rt_put_uint:
    mov x9, x0
    sub sp, sp, #32
    mov x11, sp
    mov x15, sp
    mov x12, #10
2:
    udiv x13, x9, x12
    msub x14, x13, x12, x9
    add w14, w14, #48
    strb w14, [x11], #1
    mov x9, x13
    cbnz x9, 2b
3:
    ldrb w14, [x11, #-1]!
    strb w14, [x20], #1
    cmp x11, x15
    b.ne 3b
    add sp, sp, #32
    ret

    .p2align 2
_rt_put_bool:
    cbz w0, 1f
    mov w9, #0x7274
    movk w9, #0x6575, lsl #16
    str w9, [x20], #4
    ret
1:
    mov w9, #0x6166
    movk w9, #0x736c, lsl #16
    str w9, [x20], #4
    mov w9, #101
    strb w9, [x20], #1
    ret
"""


def load(lines, register, symbol, types, type_id):
    lines.append(f"    adrp x8, {symbol}@PAGE")
    lines.append(f"    {LOAD[types.bytes[type_id], types.signed[type_id]]}{register}, [x8, {symbol}@PAGEOFF]")


def store(lines, register, symbol, types, type_id):
    lines.append(f"    adrp x8, {symbol}@PAGE")
    lines.append(f"    {STORE[types.bytes[type_id]]}{register}, [x8, {symbol}@PAGEOFF]")


def load_immediate(lines, register, value):
    value &= MASK64
    lines.append(f"    mov x{register}, #{value & 0xFFFF}")
    for shift in (16, 32, 48):
        if (value >> shift) & 0xFFFF:
            lines.append(f"    movk x{register}, #{(value >> shift) & 0xFFFF}, lsl #{shift}")


def load_operand(lines, register, types, rows, row):
    if rows.op[row] == OP_CONST:
        load_immediate(lines, register, rows.value[row])
    else:
        load(lines, register, f"_sig_{row}", types, rows.type[row])


def storage_key(rows, row):
    while rows.op[row] in (OP_COPY, OP_PREV):
        if rows.op[row] == OP_PREV and rows.left[row] in rows.snapshotted:
            return f"p{rows.left[row]}"
        row = rows.left[row]
    return f"t{rows.value[row]}" if rows.op[row] == OP_TABLE else f"a{rows.owner[row]}"


def address(lines, register, key):
    lines.append(f"    adrp x8, _addr_{key}@PAGE")
    lines.append(f"    ldr x{register}, [x8, _addr_{key}@PAGEOFF]")


def copy_words(lines, source_key, destination_key, words, label):
    address(lines, 12, source_key)
    address(lines, 13, destination_key)
    load_immediate(lines, 15, words)
    lines.append(f"{label}:")
    lines.append("    ldr x9, [x12], #8")
    lines.append("    str x9, [x13], #8")
    lines.append("    subs x15, x15, #1")
    lines.append(f"    b.ne {label}")


def element_operand(base, index, size):
    return f"[x{base}, x{index}]" if size == 1 else f"[x{base}, x{index}, lsl #{size.bit_length() - 1}]"


def emit_row(lines, program, rows, clocks, row, gated):
    types = program.types
    op = rows.op[row]
    left = rows.left[row]
    right = rows.right[row]
    row_type = rows.type[row]
    if op in (OP_TABLE, OP_PAIR, OP_BRANCH, OP_INPUT, OP_ARG) or op in (OP_COPY, OP_PREV) and types.kind[row_type] == KIND_ARRAY:
        return
    if gated:
        load(lines, 9, f"_clk_{find(clocks, row)}", types, UINTEGER)
        lines.append(f"    cbz w9, Lr{row}")
    effect_kind = rows.effects.kind[rows.value[row]] if op == OP_EFFECT else None
    if op == OP_SEED and types.kind[row_type] == KIND_ARRAY:
        words = -(-types.size[row_type] * types.bytes[types.element[row_type]] // 8)
        copy_words(lines, storage_key(rows, left), f"a{right}", words, f"Ls{row}")
    elif op == OP_SEED:
        load_operand(lines, 9, types, rows, left)
        store(lines, 9, f"_sig_{right}", types, row_type)
    elif op == OP_EFFECT:
        operands = []
        argument = left
        while argument >= 0:
            operands.append(rows.left[argument])
            argument = rows.right[argument]
        param = rows.effects.param[rows.value[row]]
        if effect_kind == "load":
            load_operand(lines, 9, types, rows, operands[0])
            lines.append(f"    {LOAD[types.bytes[param], types.signed[param]]}9, [x9]")
        elif effect_kind == "store":
            load_operand(lines, 9, types, rows, operands[0])
            load_operand(lines, 10, types, rows, operands[1])
            lines.append(f"    {STORE[types.bytes[param]]}10, [x9]")
        elif effect_kind == "syscall":
            for register, operand in enumerate(operands[1:]):
                load_operand(lines, register, types, rows, operand)
            load_operand(lines, 16, types, rows, operands[0])
            lines.append("    svc #0x80")
            lines.append("    cneg x9, x0, cs")
        else:
            load_operand(lines, 0, types, rows, operands[0])
            lines.append(f"    .inst 0x{param:08x}")
            lines.append("    mov x9, x0")
    elif op == OP_ITER:
        element_size = types.bytes[row_type]
        address(lines, 12, storage_key(rows, left))
        lines.append(f"    {LOAD[element_size, types.signed[row_type]]}9, {element_operand(12, 23, element_size)}")
    elif op == OP_PREV:
        load(lines, 9, f"_sig_{left}", types, row_type)
    elif op == OP_ELEMENT:
        element_size = types.bytes[row_type]
        address(lines, 12, storage_key(rows, left))
        load_operand(lines, 10, types, rows, right)
        load_immediate(lines, 11, types.size[rows.type[left]])
        lines.append("    mov x9, #0")
        lines.append("    cmp x10, x11")
        lines.append(f"    b.hs Le{row}")
        lines.append(f"    {LOAD[element_size, types.signed[row_type]]}9, {element_operand(12, 10, element_size)}")
        lines.append(f"Le{row}:")
    elif op == OP_GATHER:
        element = types.element[row_type]
        index_element = types.element[rows.type[right]]
        address(lines, 12, storage_key(rows, left))
        address(lines, 13, storage_key(rows, right))
        address(lines, 14, f"a{rows.owner[row]}")
        lines.append("    mov x15, #0")
        lines.append(f"Lg{row}:")
        lines.append(
            f"    {LOAD[types.bytes[index_element], types.signed[index_element]]}10, "
            f"{element_operand(13, 15, types.bytes[index_element])}"
        )
        lines.append("    mov x9, #0")
        load_immediate(lines, 11, types.size[rows.type[left]])
        lines.append("    cmp x10, x11")
        lines.append(f"    b.hs Lgs{row}")
        lines.append(f"    {LOAD[types.bytes[element], types.signed[element]]}9, {element_operand(12, 10, types.bytes[element])}")
        lines.append(f"Lgs{row}:")
        lines.append(f"    {STORE[types.bytes[element]]}9, {element_operand(14, 15, types.bytes[element])}")
        lines.append("    add x15, x15, #1")
        load_immediate(lines, 17, types.size[row_type])
        lines.append("    cmp x15, x17")
        lines.append(f"    b.lo Lg{row}")
    elif op == OP_NEXT:
        element = types.element[row_type]
        destination = f"a{rows.owner[row]}"
        source = storage_key(rows, left)
        if source != destination:
            copy_words(lines, source, destination, -(-types.size[row_type] * types.bytes[element] // 8), f"Lc{row}")
        address(lines, 12, destination)
        load_operand(lines, 10, types, rows, rows.left[right])
        load_operand(lines, 9, types, rows, rows.right[right])
        load_immediate(lines, 11, types.size[row_type])
        lines.append("    cmp x10, x11")
        lines.append(f"    b.hs Ln{row}")
        lines.append(f"    {STORE[types.bytes[element]]}9, {element_operand(12, 10, types.bytes[element])}")
        lines.append(f"Ln{row}:")
    elif op == OP_CONST:
        load_operand(lines, 9, types, rows, row)
    elif op == OP_DELAY:
        load(lines, 9, f"_mem_{row}", types, row_type)
    elif op in (OP_UWHEN, OP_CLOCK):
        lines.append("    mov x9, #1")
    elif op == OP_IF:
        load_operand(lines, 9, types, rows, left)
        load_operand(lines, 10, types, rows, rows.left[right])
        load_operand(lines, 11, types, rows, rows.right[right])
        lines.append("    cmp x9, #0")
        lines.append("    csel x9, x10, x11, ne")
    elif op == OP_DEFAULT and not rows.ctx[left]:
        load(lines, 11, f"_clk_{find(clocks, left)}", types, UINTEGER)
        load_operand(lines, 9, types, rows, left)
        load_operand(lines, 10, types, rows, right)
        lines.append("    cmp w11, #0")
        lines.append("    csel x9, x9, x10, ne")
    else:
        load_operand(lines, 9, types, rows, left)
        if right >= 0 and op not in (OP_WHEN, OP_DEFAULT):
            load_operand(lines, 10, types, rows, right)
            operands_signed = types.signed[lub(types, rows.type[left], rows.type[right])]
        if op == OP_NEG:
            lines.append("    neg x9, x9")
        elif op == OP_NOT and is_logical(types, row_type):
            lines.append("    eor x9, x9, #1")
        elif op == OP_NOT:
            lines.append("    mvn x9, x9")
        elif op in INSTRUCTIONS:
            lines.append(f"    {INSTRUCTIONS[op]} x9, x9, x10")
        elif op == OP_DIV:
            lines.append(f"    {'sdiv' if operands_signed else 'udiv'} x9, x9, x10")
        elif op in SIGNED_CONDITIONS:
            lines.append("    cmp x9, x10")
            lines.append(f"    cset w9, {(SIGNED_CONDITIONS if operands_signed else UNSIGNED_CONDITIONS)[op]}")
        elif op == OP_MOD and operands_signed:
            lines.append("    sdiv x11, x9, x10")
            lines.append("    msub x11, x11, x10, x9")
            lines.append("    cmp x10, #0")
            lines.append("    cneg x12, x10, lt")
            lines.append("    add x12, x11, x12")
            lines.append("    cmp x11, #0")
            lines.append("    csel x9, x12, x11, lt")
        elif op == OP_MOD:
            lines.append("    udiv x11, x9, x10")
            lines.append("    msub x9, x11, x10, x9")
        elif op in SHIFT_OPS:
            lines.append("    cmp x10, #64")
            lines.append(f"    {SHIFT_OPS[op]} x11, x9, x10")
            lines.append("    csel x9, x11, xzr, lo")
    if op not in (OP_GATHER, OP_NEXT, OP_SEED) and effect_kind != "store":
        store(lines, 9, f"_sig_{row}", types, row_type)
    if gated:
        lines.append(f"Lr{row}:")


def emit_assembly(program, rows, clocks, loops, order, loop_orders):
    types = program.types
    row_count = len(rows.op)
    root_count = len(clocks.roots)
    inputs = [signal for signal, role in enumerate(program.signal_roles) if role == "input"]
    value_inputs = [signal for signal in inputs if types.kind[rows.type[signal]] != KIND_EVENT]
    reads_line = root_count >= 2 or bool(inputs)
    line_capacity = root_count + 22 * len(value_inputs)
    windows = []
    reservation_bytes = 0
    arrays = [
        signal
        for signal in range(len(program.signal_names))
        if rows.op[signal] == OP_COPY and rows.op[rows.left[signal]] in (OP_GATHER, OP_NEXT)
    ]
    for key, signal in [(f"a{signal}", signal) for signal in arrays] + [(f"p{signal}", signal) for signal in sorted(rows.snapshotted)]:
        signal_type = rows.type[signal]
        used_bytes = -(-types.size[signal_type] * types.bytes[types.element[signal_type]] // 8) * 8
        window_bytes = -(-used_bytes // WINDOW_BYTES) * WINDOW_BYTES
        windows.append((key, reservation_bytes, window_bytes))
        reservation_bytes += window_bytes + WINDOW_BYTES
        if reservation_bytes >> 64:
            raise CompileError("arrays need more than 2^64 bytes of address space", rows.line[signal], rows.column[signal])
    lines = [
        "    .section __TEXT,__text,regular,pure_instructions",
        "    .globl _start",
        "    .p2align 2",
        "_start:",
        "    mov x22, #0",
    ]
    if windows:
        lines.append("    mov x0, #0")
        load_immediate(lines, 1, reservation_bytes)
        lines.extend([
            "    mov x2, #0",
            "    mov x3, #0x1002",
            "    mov x4, #-1",
            "    mov x5, #0",
            "    mov x16, #197",
            "    svc #0x80",
            "    b.cs Lreserve_failed",
            "    mov x24, x0",
        ])
        for key, offset, window_bytes in windows:
            load_immediate(lines, 9, offset)
            lines.append("    add x0, x24, x9")
            lines.append(f"    adrp x8, _addr_{key}@PAGE")
            lines.append(f"    str x0, [x8, _addr_{key}@PAGEOFF]")
            load_immediate(lines, 1, window_bytes)
            lines.append("    mov x2, #3")
            lines.append("    mov x16, #74")
            lines.append("    svc #0x80")
            lines.append("    b.cs Lreserve_failed")
    lines.append("Lstep:")
    lines.append("    add x22, x22, #1")
    if reads_line:
        lines.extend([
            "    adrp x21, _in_buffer@PAGE",
            "    add x21, x21, _in_buffer@PAGEOFF",
            "    mov x19, #0",
            "Lread:",
            "    mov x0, #0",
            "    add x1, x21, x19",
            "    mov x2, #1",
            "    mov x16, #3",
            "    svc #0x80",
            "    b.cs Lmalformed",
            "    cbnz x0, Lread_byte",
            "    cbnz x19, Lmalformed",
            "    mov x0, #0",
            "    mov x16, #1",
            "    svc #0x80",
            "Lread_byte:",
            "    ldrb w9, [x21, x19]",
            "    cmp w9, #10",
            "    b.eq Lread_line",
            "    add x19, x19, #1",
        ])
        load_immediate(lines, 11, line_capacity)
        lines.extend([
            "    cmp x19, x11",
            "    b.ls Lread",
            "    b Lmalformed",
            "Lread_line:",
        ])
        load_immediate(lines, 11, root_count)
        lines.extend([
            "    cmp x19, x11",
            "    b.lo Lmalformed",
            "    mov x19, #0",
            "Lpresence:",
            "    cmp x19, x11",
            "    b.eq Lpresence_done",
            "    ldrb w9, [x21, x19]",
            "    sub w9, w9, #48",
            "    cmp w9, #1",
            "    b.hi Lmalformed",
            "    add x19, x19, #1",
            "    b Lpresence",
            "Lpresence_done:",
        ])
        for signal in value_inputs:
            input_type = rows.type[signal]
            lines.append(f"    ldrb w9, [x21, #{clocks.roots.index(clocks.node_root[find(clocks, signal)])}]")
            lines.append("    cmp w9, #49")
            lines.append(f"    b.ne Lin{signal}")
            lines.append("    bl Lread_value")
            if types.kind[input_type] in (KIND_BOOLEAN, KIND_ENUM):
                lines.append("    cbnz x11, Lmalformed")
                load_immediate(lines, 12, 2 if types.kind[input_type] == KIND_BOOLEAN else len(types.values[input_type]))
                lines.append("    cmp x0, x12")
                lines.append("    b.hs Lmalformed")
            store(lines, 0, f"_sig_{signal}", types, input_type)
            lines.append(f"Lin{signal}:")
        lines.extend([
            "    ldrb w9, [x21, x19]",
            "    cmp w9, #10",
            "    b.eq Lread_done",
            "Lmalformed:",
            "    mov x0, #2",
            "    adrp x1, Lmalformed_text@PAGE",
            "    add x1, x1, Lmalformed_text@PAGEOFF",
            "    mov x2, #33",
            "    mov x16, #4",
            "    svc #0x80",
            "    adrp x20, _out_buffer@PAGE",
            "    add x20, x20, _out_buffer@PAGEOFF",
            "    mov x0, x22",
            "    bl _rt_put_int",
            "    mov w10, #10",
            "    strb w10, [x20], #1",
            "    mov x0, #2",
            "    adrp x1, _out_buffer@PAGE",
            "    add x1, x1, _out_buffer@PAGEOFF",
            "    sub x2, x20, x1",
            "    mov x16, #4",
            "    svc #0x80",
            "    mov x0, #2",
            "    mov x16, #1",
            "    svc #0x80",
            "Lmalformed_text:",
            '    .ascii "presence input malformed at step "',
            "    .p2align 2",
            "Lread_done:",
        ])
    loop_base = row_count + len(clocks.parent)
    for node in order:
        if node >= loop_base:
            loop = node - loop_base
            load(lines, 9, f"_clk_{find(clocks, loops.index[loop])}", types, UINTEGER)
            lines.append(f"    cbz w9, Lloop_end{loop}")
            for row in range(row_count):
                if rows.op[row] == OP_SEED and rows.loop[row] == loop:
                    emit_row(lines, program, rows, clocks, row, False)
            lines.append("    mov x23, #0")
            lines.append(f"Lloop{loop}:")
            for signal in loops.snapshots[loop]:
                signal_type = rows.type[signal]
                words = -(-types.size[signal_type] * types.bytes[types.element[signal_type]] // 8)
                copy_words(lines, f"a{signal}", f"p{signal}", words, f"Lp{loop}_{signal}")
            for row in loop_orders[loop]:
                emit_row(lines, program, rows, clocks, row, False)
            lines.append("    add x23, x23, #1")
            load_immediate(lines, 11, loops.size[loop])
            lines.append("    cmp x23, x11")
            lines.append(f"    b.lo Lloop{loop}")
            lines.append(f"Lloop_end{loop}:")
            continue
        if node >= row_count:
            clock = node - row_count
            kind = clocks.node_kind[clock]
            if kind == ROOT and reads_line:
                lines.append(f"    ldrb w9, [x21, #{clocks.roots.index(clock)}]")
                lines.append("    cmp w9, #49")
                lines.append("    cset w9, eq")
            elif kind == ROOT:
                lines.append("    mov w9, #1")
            elif kind == SAMPLE:
                load(lines, 9, f"_clk_{clocks.node_parent[clock]}", types, UINTEGER)
                load_operand(lines, 10, types, rows, clocks.node_left[clock])
                lines.append("    and w9, w9, w10")
            else:
                load(lines, 9, f"_clk_{clocks.node_left[clock]}", types, UINTEGER)
                load(lines, 10, f"_clk_{clocks.node_right[clock]}", types, UINTEGER)
                lines.append(f"    {'and' if kind == PRODUCT else 'orr'} w9, w9, w10")
            store(lines, 9, f"_clk_{clock}", types, UINTEGER)
            continue
        emit_row(lines, program, rows, clocks, node, True)
    delays = [row for row in range(row_count) if rows.op[row] == OP_DELAY]
    for row in delays:
        load(lines, 9, f"_clk_{find(clocks, row)}", types, UINTEGER)
        lines.append(f"    cbz w9, Ld{row}")
        load(lines, 9, f"_sig_{rows.left[row]}", types, rows.type[row])
        store(lines, 9, f"_mem_{row}", types, rows.type[row])
        lines.append(f"Ld{row}:")
    outputs = [i for i, role in enumerate(program.signal_roles) if role == "output"]
    if outputs:
        lines.append("    adrp x20, _out_buffer@PAGE")
        lines.append("    add x20, x20, _out_buffer@PAGEOFF")
        for position, signal in enumerate(outputs):
            if position:
                lines.append("    mov w10, #32")
                lines.append("    strb w10, [x20], #1")
            load(lines, 9, f"_clk_{find(clocks, signal)}", types, UINTEGER)
            lines.append(f"    cbz w9, Labsent{signal}")
            signal_type = rows.type[signal]
            load(lines, 0, f"_sig_{signal}", types, signal_type)
            if is_logical(types, signal_type):
                lines.append("    bl _rt_put_bool")
            else:
                lines.append(f"    bl {'_rt_put_int' if types.signed[signal_type] else '_rt_put_uint'}")
            lines.append(f"    b Lput{signal}")
            lines.append(f"Labsent{signal}:")
            lines.append("    mov w10, #45")
            lines.append("    strb w10, [x20], #1")
            lines.append(f"Lput{signal}:")
        lines.append("    mov w10, #10")
        lines.append("    strb w10, [x20], #1")
        lines.append("    adrp x1, _out_buffer@PAGE")
        lines.append("    add x1, x1, _out_buffer@PAGEOFF")
        lines.append("    sub x2, x20, x1")
        lines.append("    mov x0, #1")
        lines.append("    mov x16, #4")
        lines.append("    svc #0x80")
    lines.append("    b Lstep")
    if windows:
        lines.extend([
            "Lreserve_failed:",
            "    mov x0, #2",
            "    adrp x1, Lreserve_text@PAGE",
            "    add x1, x1, Lreserve_text@PAGEOFF",
            "    mov x2, #26",
            "    mov x16, #4",
            "    svc #0x80",
            "    mov x0, #3",
            "    mov x16, #1",
            "    svc #0x80",
            "Lreserve_text:",
            '    .ascii "memory reservation failed\\n"',
        ])
    if value_inputs:
        lines.extend([
            "    .p2align 2",
            "Lread_value:",
            "    ldrb w9, [x21, x19]",
            "    cmp w9, #32",
            "    b.ne Lmalformed",
            "    add x19, x19, #1",
            "    mov x11, #0",
            "    ldrb w9, [x21, x19]",
            "    cmp w9, #45",
            "    b.ne Lread_digits",
            "    mov x11, #1",
            "    add x19, x19, #1",
            "Lread_digits:",
            "    mov x0, #0",
            "    mov x12, #0",
            "    mov x13, #10",
            "Lread_digit:",
            "    ldrb w9, [x21, x19]",
            "    sub w9, w9, #48",
            "    cmp w9, #9",
            "    b.hi Lread_digits_end",
            "    umulh x14, x0, x13",
            "    cbnz x14, Lmalformed",
            "    mul x0, x0, x13",
            "    adds x0, x0, x9",
            "    b.cs Lmalformed",
            "    add x19, x19, #1",
            "    add x12, x12, #1",
            "    b Lread_digit",
            "Lread_digits_end:",
            "    cbz x12, Lmalformed",
            "    cmp x12, #20",
            "    b.hi Lmalformed",
            "    cbz x11, Lread_value_done",
            "    neg x0, x0",
            "Lread_value_done:",
            "    ret",
        ])
    lines.append(RUNTIME_ASSEMBLY)
    lines.append("    .section __DATA,__data")
    for table, (table_type, values) in enumerate(zip(program.table_types, program.table_values)):
        element_size = types.bytes[types.element[table_type]]
        lines.append("    .p2align 3")
        lines.append(f"_tab_{table}:")
        for start in range(0, len(values), 16):
            chunk = values[start:start + 16]
            lines.append(f"    {DATA_DIRECTIVES[element_size]} " + ", ".join(str(v & ((1 << 8 * element_size) - 1)) for v in chunk))
    lines.append("    .p2align 3")
    for table in range(len(program.table_types)):
        lines.append(f"_addr_t{table}: .quad _tab_{table}")
    for key, _, _ in windows:
        lines.append(f"_addr_{key}: .quad 0")
    for row in range(row_count):
        lines.append(f"_sig_{row}: .quad {int(row in inputs and row not in value_inputs)}")
    for row in delays:
        lines.append(f"_mem_{row}: .quad {rows.value[row] & MASK64}")
    for clock, kind in enumerate(clocks.node_kind):
        if kind is not None:
            lines.append(f"_clk_{clock}: .long 0")
    lines.append(f"_in_buffer: .space {line_capacity + 1}")
    lines.append(f"_out_buffer: .space {24 * (len(outputs) + 1)}")
    return "\n".join(lines) + "\n"


def link(assembly, output):
    object_path = output.with_suffix(".o")
    assembly_path = output.with_suffix(".s")
    assembly_path.write_text(assembly)
    sdk = subprocess.run(["xcrun", "--show-sdk-path"], capture_output=True, text=True, check=True).stdout.strip()
    steps = [
        ["as", "-arch", "arm64", str(assembly_path), "-o", str(object_path)],
        ["ld", "-arch", "arm64", "-e", "_start", "-syslibroot", sdk, "-lSystem", str(object_path), "-o", str(output)],
    ]
    for step in steps:
        result = subprocess.run(step, capture_output=True, text=True)
        if result.returncode != 0:
            sys.stderr.write(result.stderr)
            raise SystemExit(f"{step[0]} failed with exit {result.returncode}")


def main():
    arguments = argparse.ArgumentParser(description="SIGNAL bootstrap compiler")
    arguments.add_argument("source", type=Path)
    arguments.add_argument("-o", "--output", type=Path, required=True)
    options = arguments.parse_args()
    try:
        program = instantiate(Parser(lex(options.source.read_text())).parse_program())
        rows, loops = lower(program)
        clocks = clock_calculus(rows, program, loops)
        order, loop_orders = schedule(program, rows, clocks, loops)
        assembly = emit_assembly(program, rows, clocks, loops, order, loop_orders)
        link(assembly, options.output)
        if len(clocks.roots) >= 2:
            print("presence inputs: " + ", ".join(clock_name(clocks, rows, program, root) for root in clocks.roots))
    except CompileError as error:
        sys.stderr.write(f"{options.source}:{error.line}:{error.column}: error: {error}\n")
        return 1
    except (OSError, UnicodeDecodeError) as error:
        sys.stderr.write(f"sigc: error: {error}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
