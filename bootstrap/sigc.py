import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

KEYWORDS = {"process", "where", "end", "init", "integer"}

TOKEN_PATTERN = re.compile(
    r"(?P<space>\s+)"
    r"|(?P<comment>%[^%]*%)"
    r"|(?P<number>\d+)"
    r"|(?P<name>[A-Za-z_][A-Za-z0-9_]*)"
    r"|(?P<symbol>\(\||\|\)|:=|[|$+\-*/()=;,?!])"
)

BINARY_PRECEDENCE = {"+": 17, "-": 17, "*": 18, "/": 18}
UNARY_PRECEDENCE = 20
DELAY_PRECEDENCE = 21
EXPRESSION_TERMINATORS = {"|", "|)", ";"}

OP_CONST = "const"
OP_SIGNAL = "signal"
OP_DELAY = "delay"
OP_NEG = "neg"
OP_ADD = "add"
OP_SUB = "sub"
OP_MUL = "mul"
OP_DIV = "sdiv"
BINARY_OPS = {"+": OP_ADD, "-": OP_SUB, "*": OP_MUL, "/": OP_DIV}
EVALUATION_REGISTERS = ["w9", "w10", "w11", "w12", "w13", "w14", "w15"]


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
    equation_targets: list = field(default_factory=list)
    equation_ops: list = field(default_factory=list)
    equation_args: list = field(default_factory=list)
    equation_positions: list = field(default_factory=list)
    delay_inits: list = field(default_factory=list)
    delay_ops: list = field(default_factory=list)
    delay_args: list = field(default_factory=list)


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
        self.expect("integer")
        while True:
            line, column = self.position()
            name = self.expect_name()
            if name in self.program.signal_names:
                raise CompileError(f"signal {name} is declared twice", line, column)
            self.program.signal_names.append(name)
            self.program.signal_roles.append(role)
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
        target = self.expect_name()
        self.expect(":=")
        ops, args = self.parse_expression()
        self.program.equation_targets.append(target)
        self.program.equation_ops.append(ops)
        self.program.equation_args.append(args)
        self.program.equation_positions.append((line, column))

    def parse_expression(self):
        ops = []
        args = []
        operand_starts = []
        pending = []
        expect_operand = True
        while True:
            text = self.peek()
            kind = self.tokens.kinds[self.index]
            if expect_operand:
                if kind == "number":
                    operand_starts.append(len(ops))
                    ops.append(OP_CONST)
                    args.append(int(text))
                    self.index += 1
                    expect_operand = False
                elif kind == "name":
                    operand_starts.append(len(ops))
                    ops.append(OP_SIGNAL)
                    args.append((text, *self.position()))
                    self.index += 1
                    expect_operand = False
                elif text == "(":
                    pending.append(("(", 0, len(ops)))
                    self.index += 1
                elif text == "-":
                    pending.append((OP_NEG, UNARY_PRECEDENCE, len(ops)))
                    self.index += 1
                elif text == "+":
                    self.index += 1
                else:
                    self.fail(f"expected an expression, found {text or 'end of file'!r}")
                continue
            if text in BINARY_PRECEDENCE:
                precedence = BINARY_PRECEDENCE[text]
                while pending and pending[-1][0] != "(" and pending[-1][1] >= precedence:
                    self.reduce(pending.pop(), ops, args, operand_starts)
                pending.append((BINARY_OPS[text], precedence, None))
                self.index += 1
                expect_operand = True
            elif text == "$":
                self.index += 1
                start = operand_starts[-1]
                initial = 0
                if self.peek() == "init":
                    self.index += 1
                    if self.tokens.kinds[self.index] != "number":
                        self.fail("the initial value of a delay must be an integer constant")
                    initial = int(self.peek())
                    self.index += 1
                delay = len(self.program.delay_inits)
                self.program.delay_inits.append(initial)
                self.program.delay_ops.append(ops[start:])
                self.program.delay_args.append(args[start:])
                del ops[start:]
                del args[start:]
                ops.append(OP_DELAY)
                args.append(delay)
            elif text == ")" and any(entry[0] == "(" for entry in pending):
                while pending[-1][0] != "(":
                    self.reduce(pending.pop(), ops, args, operand_starts)
                opened = pending.pop()
                operand_starts[-1] = opened[2]
                self.index += 1
            elif text in EXPRESSION_TERMINATORS or text == ")":
                while pending:
                    if pending[-1][0] == "(":
                        self.fail("unbalanced parenthesis")
                    self.reduce(pending.pop(), ops, args, operand_starts)
                return ops, args
            else:
                self.fail(f"expected an operator, found {text or 'end of file'!r}")

    def reduce(self, entry, ops, args, operand_starts):
        op, _, start = entry
        ops.append(op)
        args.append(None)
        if op == OP_NEG:
            operand_starts[-1] = start
        else:
            operand_starts.pop()


def resolve(program):
    indices = {name: i for i, name in enumerate(program.signal_names)}
    for name, role in zip(program.signal_names, program.signal_roles):
        if role == "input":
            raise CompileError(f"input signal {name} is not supported yet", 1, 1)
    all_op_lists = [(program.equation_ops, program.equation_args), (program.delay_ops, program.delay_args)]
    for op_lists, arg_lists in all_op_lists:
        for ops, args in zip(op_lists, arg_lists):
            for i, op in enumerate(ops):
                if op == OP_SIGNAL:
                    name, line, column = args[i]
                    if name not in indices:
                        raise CompileError(f"signal {name} is not declared", line, column)
                    args[i] = indices[name]
    defining_equation = [None] * len(program.signal_names)
    for equation, target in enumerate(program.equation_targets):
        line, column = program.equation_positions[equation]
        if target not in indices:
            raise CompileError(f"signal {target} is not declared", line, column)
        signal = indices[target]
        if defining_equation[signal] is not None:
            raise CompileError(f"signal {target} is defined twice", line, column)
        defining_equation[signal] = equation
    for signal, equation in enumerate(defining_equation):
        if equation is None:
            raise CompileError(f"signal {program.signal_names[signal]} is never defined", 1, 1)
    return defining_equation


def schedule(program, defining_equation):
    count = len(program.equation_targets)
    dependents = [[] for _ in range(count)]
    unmet = [0] * count
    for equation in range(count):
        for op, arg in zip(program.equation_ops[equation], program.equation_args[equation]):
            if op == OP_SIGNAL:
                dependents[defining_equation[arg]].append(equation)
                unmet[equation] += 1
    ready = [e for e in range(count) if unmet[e] == 0]
    order = []
    while ready:
        equation = ready.pop()
        order.append(equation)
        for dependent in dependents[equation]:
            unmet[dependent] -= 1
            if unmet[dependent] == 0:
                ready.append(dependent)
    if len(order) < count:
        cyclic = sorted(program.equation_targets[e] for e in range(count) if unmet[e] > 0)
        line, column = min(program.equation_positions[e] for e in range(count) if unmet[e] > 0)
        raise CompileError(f"causality cycle between signals {', '.join(cyclic)}", line, column)
    return order


def emit_evaluation(ops, args, lines):
    depth = 0
    for op, arg in zip(ops, args):
        if op in (OP_CONST, OP_SIGNAL, OP_DELAY):
            if depth == len(EVALUATION_REGISTERS):
                raise CompileError("expression too deep", 1, 1)
            register = EVALUATION_REGISTERS[depth]
            if op == OP_CONST:
                lines.append(f"    mov {register}, #{arg & 0xFFFF}")
                if arg >> 16:
                    lines.append(f"    movk {register}, #{(arg >> 16) & 0xFFFF}, lsl #16")
            else:
                symbol = f"_sig_{arg}" if op == OP_SIGNAL else f"_mem_{arg}"
                lines.append(f"    adrp x8, {symbol}@PAGE")
                lines.append(f"    ldr {register}, [x8, {symbol}@PAGEOFF]")
            depth += 1
        elif op == OP_NEG:
            register = EVALUATION_REGISTERS[depth - 1]
            lines.append(f"    neg {register}, {register}")
        else:
            left = EVALUATION_REGISTERS[depth - 2]
            right = EVALUATION_REGISTERS[depth - 1]
            lines.append(f"    {op} {left}, {left}, {right}")
            depth -= 1
    return EVALUATION_REGISTERS[0]


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
"""


def emit_assembly(program, order):
    lines = [
        "    .section __TEXT,__text,regular,pure_instructions",
        "    .globl _start",
        "    .p2align 2",
        "_start:",
        "Lstep:",
    ]
    for equation in order:
        result = emit_evaluation(program.equation_ops[equation], program.equation_args[equation], lines)
        signal = program.signal_names.index(program.equation_targets[equation])
        lines.append(f"    adrp x8, _sig_{signal}@PAGE")
        lines.append(f"    str {result}, [x8, _sig_{signal}@PAGEOFF]")
    for delay in range(len(program.delay_inits)):
        result = emit_evaluation(program.delay_ops[delay], program.delay_args[delay], lines)
        lines.append(f"    adrp x8, _next_{delay}@PAGE")
        lines.append(f"    str {result}, [x8, _next_{delay}@PAGEOFF]")
    for delay in range(len(program.delay_inits)):
        lines.append(f"    adrp x8, _next_{delay}@PAGE")
        lines.append(f"    ldr w9, [x8, _next_{delay}@PAGEOFF]")
        lines.append(f"    adrp x8, _mem_{delay}@PAGE")
        lines.append(f"    str w9, [x8, _mem_{delay}@PAGEOFF]")
    lines.append("    adrp x20, _out_buffer@PAGE")
    lines.append("    add x20, x20, _out_buffer@PAGEOFF")
    outputs = [i for i, role in enumerate(program.signal_roles) if role == "output"]
    for position, signal in enumerate(outputs):
        if position:
            lines.append("    mov w10, #32")
            lines.append("    strb w10, [x20], #1")
        lines.append(f"    adrp x8, _sig_{signal}@PAGE")
        lines.append(f"    ldr w0, [x8, _sig_{signal}@PAGEOFF]")
        lines.append("    bl _rt_put_int")
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
    for signal in range(len(program.signal_names)):
        lines.append(f"_sig_{signal}: .long 0")
    for delay, initial in enumerate(program.delay_inits):
        lines.append(f"_mem_{delay}: .long {initial}")
        lines.append(f"_next_{delay}: .long 0")
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
        order = schedule(program, resolve(program))
        assembly = emit_assembly(program, order)
    except CompileError as error:
        sys.stderr.write(f"{options.source}:{error.line}:{error.column}: error: {error}\n")
        return 1
    link(assembly, options.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
