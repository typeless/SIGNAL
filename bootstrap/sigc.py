import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

KEYWORDS = {
    "process", "where", "end", "init", "integer", "boolean", "event", "true", "false",
    "when", "default", "and", "or", "xor", "not", "modulo",
}
TYPE_KEYWORDS = ("integer", "boolean", "event")

TOKEN_PATTERN = re.compile(
    r"(?P<space>\s+)"
    r"|(?P<comment>%[^%]*%)"
    r"|(?P<number>\d+)"
    r"|(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"|(?P<symbol>\(\||\|\)|-->|:=|\^=|/=|<=|>=|[|$+\-*/()=;,?!<>^])"
)

OP_CONST = "CONST"
OP_SIGNAL = "SIGNAL"
OP_COPY = "COPY"
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

BINARY_OPS = {
    "default": OP_DEFAULT, "when": OP_WHEN, "xor": OP_XOR, "or": OP_OR, "and": OP_AND,
    "=": OP_EQ, "/=": OP_NE, "<": OP_LT, "<=": OP_LE, ">": OP_GT, ">=": OP_GE,
    "+": OP_ADD, "-": OP_SUB, "*": OP_MUL, "/": OP_DIV, "modulo": OP_MOD,
}
BINARY_PRECEDENCE = {
    "default": 3, "when": 4, "xor": 11, "or": 12, "and": 13,
    "=": 16, "/=": 16, "<": 16, "<=": 16, ">": 16, ">=": 16,
    "+": 17, "-": 17, "*": 18, "/": 18, "modulo": 18,
}
PREFIX_OPS = {"when": OP_UWHEN, "not": OP_NOT, "-": OP_NEG, "^": OP_CLOCK}
PREFIX_PRECEDENCE = {"when": 8, "not": 14, "-": 20, "^": 24}
DELAY_PRECEDENCE = 21
EXPRESSION_TERMINATORS = {"|", "|)", ";", "^="}
OP_TEXT = {**{op: text for text, op in BINARY_OPS.items()}, **{op: text for text, op in PREFIX_OPS.items()}, OP_DELAY: "$"}

INTEGER_OPS = {OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD, OP_NEG}
ORDER_OPS = {OP_LT, OP_LE, OP_GT, OP_GE}
EQUALITY_OPS = {OP_EQ, OP_NE}
LOGIC_OPS = {OP_AND, OP_OR, OP_XOR, OP_NOT}
MONOCHRONOUS_OPS = INTEGER_OPS | ORDER_OPS | EQUALITY_OPS | LOGIC_OPS
UNARY_OPS = {OP_NEG, OP_NOT, OP_UWHEN, OP_CLOCK, OP_DELAY}
INSTRUCTIONS = {OP_ADD: "add", OP_SUB: "sub", OP_MUL: "mul", OP_DIV: "sdiv", OP_AND: "and", OP_OR: "orr", OP_XOR: "eor"}
CONDITIONS = {OP_EQ: "eq", OP_NE: "ne", OP_LT: "lt", OP_LE: "le", OP_GT: "gt", OP_GE: "ge"}

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
class Program:
    name: str = ""
    signal_names: list = field(default_factory=list)
    signal_roles: list = field(default_factory=list)
    signal_types: list = field(default_factory=list)
    equation_targets: list = field(default_factory=list)
    equation_ops: list = field(default_factory=list)
    equation_args: list = field(default_factory=list)
    equation_positions: list = field(default_factory=list)
    constraint_groups: list = field(default_factory=list)
    constraint_positions: list = field(default_factory=list)
    dependence_from: list = field(default_factory=list)
    dependence_to: list = field(default_factory=list)
    dependence_positions: list = field(default_factory=list)


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
    groups: list = field(default_factory=list)
    group_positions: list = field(default_factory=list)
    dependence_from: list = field(default_factory=list)
    dependence_to: list = field(default_factory=list)


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

    def declare(self, role):
        if self.peek() not in TYPE_KEYWORDS:
            self.fail(f"expected a type, found {self.peek() or 'end of file'!r}")
        signal_type = self.peek()
        self.index += 1
        while True:
            line, column = self.position()
            name = self.expect_name()
            if name in self.program.signal_names:
                raise CompileError(f"signal {name} is declared twice", line, column)
            self.program.signal_names.append(name)
            self.program.signal_roles.append(role)
            self.program.signal_types.append(signal_type)
            if self.peek() != ",":
                break
            self.index += 1
        self.expect(";")

    def parse_program(self):
        self.expect("process")
        self.program.name = self.expect_name()
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
        self.expect("(|")
        while True:
            self.parse_equation()
            if self.peek() == "|)":
                break
            self.expect("|")
            if self.peek() == "|)":
                break
        self.expect("|)")
        if self.peek() == "where":
            self.index += 1
            while self.peek() != "end":
                self.declare("local")
            self.expect("end")
        self.expect(";")
        if self.tokens.kinds[self.index] != "eof":
            self.fail(f"unexpected {self.peek()!r} after the process model")
        return self.program

    def parse_equation(self):
        line, column = self.position()
        follower = self.tokens.texts[self.index + 1] if self.tokens.kinds[self.index] == "name" else None
        if follower == ":=":
            target = self.expect_name()
            self.expect(":=")
            ops, args = self.parse_expression()
            self.program.equation_targets.append(target)
            self.program.equation_ops.append(ops)
            self.program.equation_args.append(args)
            self.program.equation_positions.append((line, column))
        elif follower == "-->":
            previous = (self.expect_name(), line, column)
            while self.peek() == "-->":
                self.index += 1
                if self.tokens.kinds[self.index] != "name":
                    self.fail("--> requires signal names")
                current = (self.peek(), *self.position())
                self.index += 1
                self.program.dependence_from.append(previous)
                self.program.dependence_to.append(current)
                self.program.dependence_positions.append((line, column))
                previous = current
            if self.peek() not in ("|", "|)"):
                self.fail("--> requires signal names")
        else:
            group = [self.parse_expression()]
            if self.peek() != "^=":
                self.fail(f"expected ':=' or '^=', found {self.peek() or 'end of file'!r}")
            while self.peek() == "^=":
                self.index += 1
                group.append(self.parse_expression())
            self.program.constraint_groups.append(group)
            self.program.constraint_positions.append((line, column))

    def parse_literal(self):
        text = self.peek()
        if self.tokens.kinds[self.index] == "number":
            if int(text) > 0x7FFFFFFF:
                self.fail(f"integer literal {text} does not fit in 32 bits")
            return int(text), "integer"
        if text in ("true", "false") and self.tokens.kinds[self.index] == "keyword":
            return int(text == "true"), "boolean"
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
                literal = self.parse_literal()
                if literal is not None:
                    ops.append(OP_CONST)
                    args.append(literal)
                    expect_operand = False
                elif kind == "name":
                    ops.append(OP_SIGNAL)
                    args.append((text, *position))
                    expect_operand = False
                elif text == "(":
                    pending.append(("(", 0, position))
                elif text in PREFIX_OPS:
                    pending.append((PREFIX_OPS[text], PREFIX_PRECEDENCE[text], position))
                elif text != "+":
                    self.fail(f"expected an expression, found {text or 'end of file'!r}")
                self.index += 1
                continue
            if text in BINARY_PRECEDENCE:
                precedence = BINARY_PRECEDENCE[text]
                while pending and pending[-1][0] != "(" and pending[-1][1] >= precedence:
                    self.reduce(pending.pop(), ops, args)
                pending.append((BINARY_OPS[text], precedence, position))
                self.index += 1
                expect_operand = True
            elif text == "$":
                while pending and pending[-1][0] != "(" and pending[-1][1] > DELAY_PRECEDENCE:
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
                        initial = (-initial[0], initial[1])
                    self.index += 1
                ops.append(OP_DELAY)
                args.append((*position, initial))
            elif text == ")" and any(entry[0] == "(" for entry in pending):
                while pending[-1][0] != "(":
                    self.reduce(pending.pop(), ops, args)
                pending.pop()
                self.index += 1
            elif text in EXPRESSION_TERMINATORS or text == ")":
                while pending:
                    if pending[-1][0] == "(":
                        self.fail("unbalanced parenthesis")
                    self.reduce(pending.pop(), ops, args)
                return ops, args
            else:
                self.fail(f"expected an operator, found {text or 'end of file'!r}")

    def reduce(self, entry, ops, args):
        op, _, position = entry
        ops.append(op)
        args.append(position)


def flatten(rows, indices, ops, args, owner, line, column):
    stack = []
    for op, arg in zip(ops, args):
        if op == OP_SIGNAL:
            name, name_line, name_column = arg
            if name not in indices:
                raise CompileError(f"signal {name} is not declared", name_line, name_column)
            stack.append(indices[name])
            continue
        left = right = -1
        value = 0
        if op == OP_CONST:
            value, row_type = arg
        else:
            line, column = arg[0], arg[1]
            if op in UNARY_OPS:
                left = stack.pop()
            else:
                right = stack.pop()
                left = stack.pop()
            left_type = rows.type[left]
            right_type = rows.type[right] if right >= 0 else None
            text = OP_TEXT[op]
            if op in INTEGER_OPS:
                if left_type != "integer" or right >= 0 and right_type != "integer":
                    raise CompileError(f"operator {text} expects integer operands", line, column)
                row_type = "integer"
            elif op in EQUALITY_OPS or op in ORDER_OPS:
                if (left_type == "integer") != (right_type == "integer"):
                    raise CompileError(f"operator {text} expects operands of one type", line, column)
                row_type = "boolean"
            elif op in LOGIC_OPS:
                if left_type == "integer" or right_type == "integer":
                    raise CompileError(f"operator {text} expects boolean operands", line, column)
                row_type = "boolean"
            elif op in (OP_WHEN, OP_UWHEN):
                if rows.type[right if op == OP_WHEN else left] == "integer":
                    raise CompileError("the condition of when must be boolean", line, column)
                row_type = left_type if op == OP_WHEN else "event"
            elif op == OP_DEFAULT:
                if (left_type == "integer") != (right_type == "integer"):
                    raise CompileError(f"operator {text} expects operands of one type", line, column)
                row_type = left_type if left_type == right_type else "boolean"
            elif op == OP_CLOCK:
                row_type = "event"
            else:
                row_type = left_type
                initial = arg[2]
                if initial is not None and initial[1] != (None if row_type == "event" else row_type):
                    raise CompileError("the initial value of a delay must match its type", line, column)
                value = 1 if row_type == "event" else initial[0] if initial else 0
        ctx = (
            op == OP_CONST
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
    return stack[-1]


def lower(program):
    names = program.signal_names
    types = program.signal_types
    indices = {name: i for i, name in enumerate(names)}
    for name, role in zip(names, program.signal_roles):
        if role == "input":
            raise CompileError(f"input signal {name} is not supported yet", 1, 1)
    rows = Rows()
    for signal in range(len(names)):
        rows.op.append(OP_COPY)
        rows.left.append(-1)
        rows.right.append(-1)
        rows.value.append(0)
        rows.type.append(types[signal])
        rows.ctx.append(False)
        rows.line.append(1)
        rows.column.append(1)
        rows.owner.append(signal)
    for equation, target in enumerate(program.equation_targets):
        line, column = program.equation_positions[equation]
        if target not in indices:
            raise CompileError(f"signal {target} is not declared", line, column)
        signal = indices[target]
        if rows.left[signal] >= 0:
            raise CompileError(f"signal {target} is defined twice", line, column)
        top = flatten(rows, indices, program.equation_ops[equation], program.equation_args[equation], signal, line, column)
        if rows.type[top] != types[signal] and not (rows.type[top] == "event" and types[signal] == "boolean"):
            raise CompileError(
                f"signal {target} has type {types[signal]} but its definition has type {rows.type[top]}", line, column
            )
        rows.left[signal] = top
        rows.line[signal] = line
        rows.column[signal] = column
    for signal, name in enumerate(names):
        if rows.left[signal] < 0:
            raise CompileError(f"signal {name} is never defined", 1, 1)
    for group, (line, column) in zip(program.constraint_groups, program.constraint_positions):
        rows.groups.append([flatten(rows, indices, ops, args, -1, line, column) for ops, args in group])
        rows.group_positions.append((line, column))
    for source, destination in zip(program.dependence_from, program.dependence_to):
        for name, line, column in (source, destination):
            if name not in indices:
                raise CompileError(f"signal {name} is not declared", line, column)
        rows.dependence_from.append(indices[source[0]])
        rows.dependence_to.append(indices[destination[0]])
    return rows


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
    return f"the expression at {rows.line[first]}:{rows.column[first]}"


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


def clock_calculus(rows, program):
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
            if rows.type[condition] != "event":
                if sample_of_row[condition] < 0:
                    sample_of_row[condition] = len(clocks.parent)
                    clocks.parent.append(len(clocks.parent))
                    clocks.sample_rows.append(condition)
                sample = sample_of_row[condition]
        if op == OP_COPY or op in MONOCHRONOUS_OPS:
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
        for clock in range(total):
            if find(clocks, clock) == clock and clocks.node_kind[clock] is None and clock not in targets:
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
    clocks.roots = root_order(clocks, len(program.signal_names))
    return clocks


def schedule(program, rows, clocks):
    row_count = len(rows.op)
    node_count = row_count + len(clocks.parent)
    edges = []
    for row in range(row_count):
        op = rows.op[row]
        left = rows.left[row]
        right = rows.right[row]
        edges.append((row_count + find(clocks, row), row))
        if op == OP_COPY or op in MONOCHRONOUS_OPS or op in (OP_WHEN, OP_DEFAULT):
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
    present = [True] * row_count + [kind is not None for kind in clocks.node_kind]
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
        core = {node for node in range(node_count) if present[node] and unmet[node] > 0}
        while True:
            sinks = {node for node in core if not any(successor in core for successor in successors[node])}
            if not sinks:
                break
            core -= sinks
        owners = {rows.owner[node] for node in core if node < row_count and rows.owner[node] >= 0}
        names = sorted(program.signal_names[owner] for owner in owners)
        line, column = min((rows.line[owner], rows.column[owner]) for owner in owners)
        raise CompileError(f"causality cycle between signals {', '.join(names)}", line, column)
    return order


RUNTIME_ASSEMBLY = """
    .p2align 2
_rt_put_int:
    sxtw x9, w0
    cmp x9, #0
    b.ge 1f
    mov w10, #45
    strb w10, [x20], #1
    neg x9, x9
1:
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


def load(lines, register, symbol):
    lines.append(f"    adrp x8, {symbol}@PAGE")
    lines.append(f"    ldr {register}, [x8, {symbol}@PAGEOFF]")


def store(lines, register, symbol):
    lines.append(f"    adrp x8, {symbol}@PAGE")
    lines.append(f"    str {register}, [x8, {symbol}@PAGEOFF]")


def load_operand(lines, register, rows, row):
    if rows.op[row] == OP_CONST:
        value = rows.value[row] & 0xFFFFFFFF
        lines.append(f"    mov {register}, #{value & 0xFFFF}")
        if value >> 16:
            lines.append(f"    movk {register}, #{value >> 16}, lsl #16")
    else:
        load(lines, register, f"_sig_{row}")


def emit_assembly(program, rows, clocks, order):
    row_count = len(rows.op)
    root_count = len(clocks.roots)
    lines = [
        "    .section __TEXT,__text,regular,pure_instructions",
        "    .globl _start",
        "    .p2align 2",
        "_start:",
        "    mov x22, #0",
        "Lstep:",
        "    add x22, x22, #1",
    ]
    if root_count >= 2:
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
            f"    cmp x19, #{root_count}",
            "    b.ge Lmalformed",
            "    sub w9, w9, #48",
            "    cmp w9, #1",
            "    b.hi Lmalformed",
            "    add x19, x19, #1",
            "    b Lread",
            "Lread_line:",
            f"    cmp x19, #{root_count}",
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
    for node in order:
        if node >= row_count:
            clock = node - row_count
            kind = clocks.node_kind[clock]
            if kind == ROOT and root_count >= 2:
                lines.append(f"    ldrb w9, [x21, #{clocks.roots.index(clock)}]")
                lines.append("    cmp w9, #49")
                lines.append("    cset w9, eq")
            elif kind == ROOT:
                lines.append("    mov w9, #1")
            elif kind == SAMPLE:
                load(lines, "w9", f"_clk_{clocks.node_parent[clock]}")
                load(lines, "w10", f"_sig_{clocks.node_left[clock]}")
                lines.append("    and w9, w9, w10")
            else:
                load(lines, "w9", f"_clk_{clocks.node_left[clock]}")
                load(lines, "w10", f"_clk_{clocks.node_right[clock]}")
                lines.append(f"    {'and' if kind == PRODUCT else 'orr'} w9, w9, w10")
            store(lines, "w9", f"_clk_{clock}")
            continue
        row = node
        op = rows.op[row]
        left = rows.left[row]
        right = rows.right[row]
        load(lines, "w9", f"_clk_{find(clocks, row)}")
        lines.append(f"    cbz w9, Lr{row}")
        if op == OP_CONST:
            load_operand(lines, "w9", rows, row)
        elif op == OP_DELAY:
            load(lines, "w9", f"_mem_{row}")
        elif op in (OP_UWHEN, OP_CLOCK):
            lines.append("    mov w9, #1")
        elif op == OP_DEFAULT and not rows.ctx[left]:
            load(lines, "w11", f"_clk_{find(clocks, left)}")
            load_operand(lines, "w9", rows, left)
            load_operand(lines, "w10", rows, right)
            lines.append("    cmp w11, #0")
            lines.append("    csel w9, w9, w10, ne")
        else:
            load_operand(lines, "w9", rows, left)
            if right >= 0 and op not in (OP_WHEN, OP_DEFAULT):
                load_operand(lines, "w10", rows, right)
            if op == OP_NEG:
                lines.append("    neg w9, w9")
            elif op == OP_NOT:
                lines.append("    eor w9, w9, #1")
            elif op in INSTRUCTIONS:
                lines.append(f"    {INSTRUCTIONS[op]} w9, w9, w10")
            elif op in CONDITIONS:
                lines.append("    cmp w9, w10")
                lines.append(f"    cset w9, {CONDITIONS[op]}")
            elif op == OP_MOD:
                lines.append("    sdiv w11, w9, w10")
                lines.append("    msub w11, w11, w10, w9")
                lines.append("    cmp w10, #0")
                lines.append("    cneg w12, w10, lt")
                lines.append("    add w12, w11, w12")
                lines.append("    cmp w11, #0")
                lines.append("    csel w9, w12, w11, lt")
        store(lines, "w9", f"_sig_{row}")
        lines.append(f"Lr{row}:")
    delays = [row for row in range(row_count) if rows.op[row] == OP_DELAY]
    for row in delays:
        load(lines, "w9", f"_clk_{find(clocks, row)}")
        lines.append(f"    cbz w9, Ld{row}")
        load(lines, "w9", f"_sig_{rows.left[row]}")
        store(lines, "w9", f"_mem_{row}")
        lines.append(f"Ld{row}:")
    lines.append("    adrp x20, _out_buffer@PAGE")
    lines.append("    add x20, x20, _out_buffer@PAGEOFF")
    outputs = [i for i, role in enumerate(program.signal_roles) if role == "output"]
    for position, signal in enumerate(outputs):
        if position:
            lines.append("    mov w10, #32")
            lines.append("    strb w10, [x20], #1")
        load(lines, "w9", f"_clk_{find(clocks, signal)}")
        lines.append(f"    cbz w9, Labsent{signal}")
        load(lines, "w0", f"_sig_{signal}")
        lines.append(f"    bl {'_rt_put_int' if rows.type[signal] == 'integer' else '_rt_put_bool'}")
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
    lines.append(RUNTIME_ASSEMBLY)
    lines.append("    .section __DATA,__data")
    lines.append("    .p2align 2")
    for row in range(row_count):
        lines.append(f"_sig_{row}: .long 0")
    for row in delays:
        lines.append(f"_mem_{row}: .long {rows.value[row]}")
    for clock, kind in enumerate(clocks.node_kind):
        if kind is not None:
            lines.append(f"_clk_{clock}: .long 0")
    lines.append(f"_in_buffer: .space {root_count + 1}")
    lines.append(f"_out_buffer: .space {16 * (len(outputs) + 1)}")
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
        program = Parser(lex(options.source.read_text())).parse_program()
        rows = lower(program)
        clocks = clock_calculus(rows, program)
        order = schedule(program, rows, clocks)
        assembly = emit_assembly(program, rows, clocks, order)
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
