import functools
import random
import re
import subprocess
import sys
from pathlib import Path

import run
from run import QEMU_COMMANDS, read_trace

COMPILE_TIMEOUT_SECONDS = 180
compile_case = functools.partial(run.compile_case, timeout=COMPILE_TIMEOUT_SECONDS)

ROOT = Path(__file__).resolve().parent.parent
SEEDS = ROOT / "tests" / "differential_seeds.txt"
BUILD = ROOT / "build" / "differential"
COMPILER = ROOT / "build" / "m4" / "stage2"
CASES = ROOT / "tests" / "cases"
SOURCE = ROOT / "compiler" / "sigc.sig"
M9A_BUILD = ROOT / "build" / "m9"
M9A_SUITES = ("m0", "m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8")
M9A_CASES = {
    "m9/clocks_default_chain1100.sig", "m9/clocks_when_chain1100.sig", "m9/const_reader_default.sig",
    "m9/const_reader_when.sig", "m9/many_roots.sig",
}
M9A_REJECTED = {
    "m9/many_roots.sig": "clock of S0 is undefined: its definition is a constant",
    "m9/const_reader_default.sig": "clock of X is undefined: its definition is a constant",
    "m9/const_reader_when.sig": "clock of X is undefined: its definition is a constant",
}
M9A_MOVED = {
    "m9/clocks_not_inside_pairs.sig": "accepted",
    "m9/exclusive_cycle.sig": "accepted",
    "m1/restructure_alone.sig": "accepted",
    "m2/input_array.sig": "accepted",
    "m2/submodel_array_input.sig": "accepted",
    "m4/lower_array_definition.sig": "accepted",
}
DUMP_PASS_LINE = "constant integer DUMP_PASS = 0;"
CLOCKS_DUMP_PASS_LINE = "constant integer DUMP_PASS = 5;"
FRESH_SEEDS = 200
TICKS = 8
TABLE_SIZE = 8
MAX_DEPTH = 4
TYPES = {
    "short": (16, True),
    "integer": (32, True),
    "long": (64, True),
    "ubyte": (8, False),
    "ushort": (16, False),
    "uinteger": (32, False),
    "ulong": (64, False),
}
ARITHMETIC = ["+", "-", "*", "/", "modulo"]
BITWISE = ["and", "or", "xor"]
SHIFTS = ["shl", "shr"]
COMPARISONS = ["=", "/=", "<", "<=", ">", ">=", "==", "<<="]
EVENT_OPERATORS = ["^+", "^*", "^-"]
CONNECTIVES = ["and", "or", "xor"]
LONG_MAX = 2**63 - 1
M9B_RELATIONS = {
    "^<": lambda left, right: not left or right,
    "^>": lambda left, right: not right or left,
    "^#": lambda left, right: not (left and right),
}

MACHINE_PRAGMAS = """  pragmas
    Machine "mps2-an385"
    Boot {START}
    Interrupt {TICK} "15"
  end pragmas
"""
SYSTICK_BODY = """   | RELOAD :: store{SYSTICK, uinteger}(pointer(SYST_RVR) when START, uinteger(250000))
   | CURRENT :: store{SYSTICK, uinteger}(pointer(SYST_CVR) when START, uinteger(0))
   | CONTROL :: store{SYSTICK, uinteger}(pointer(SYST_CSR) when START, uinteger(7))
   | RELOAD --> CURRENT --> CONTROL
"""
SYSTICK_DECLARATIONS = """    type SYSTICK = external;
    constant ulong SYST_CSR = ulong(3758153744);
    constant ulong SYST_RVR = ulong(3758153748);
    constant ulong SYST_CVR = ulong(3758153752);
    label RELOAD, CURRENT, CONTROL;
"""


def boundary_values(bits):
    half = 2 ** (bits - 1)
    return [0, 1, 2, -1, -2, half - 1, half, -half, -half + 1, 2**bits - 1, 2**bits - 2, 2 ** (bits // 2), 3, 7, 10]


def literal(rng, name, constant=False):
    bits = TYPES[name][0]
    if rng.random() < 0.7:
        value = rng.choice(boundary_values(rng.choice([bits, bits, 8, 16, 32, 64])))
    else:
        value = rng.randrange(-(2 ** (bits - 1)), 2**bits)
    if value > LONG_MAX:
        value -= 2**64
    if value < -LONG_MAX and constant:
        value = -LONG_MAX
    if value < -LONG_MAX:
        return f"({name}(-{LONG_MAX}) - {name}(1))"
    return f"{name}({value})"


class Program:
    def __init__(self, seed):
        self.rng = random.Random(seed)
        rng = self.rng
        self.table_type = rng.choice(list(TYPES))
        self.table = [literal(rng, self.table_type, constant=True) for _ in range(TABLE_SIZE)]
        self.order = [str(rng.randrange(TABLE_SIZE)) for _ in range(TABLE_SIZE)]
        self.sum_type = rng.choice(list(TYPES))
        self.outputs = []
        for index in range(rng.randrange(3, 8)):
            name = rng.choice(list(TYPES) + ["boolean"])
            self.outputs.append((f"O{index}", name))
        self.definitions = []
        for signal, name in self.outputs:
            if name == "boolean":
                self.definitions.append(f"{signal} := {self.condition(MAX_DEPTH)}")
            else:
                self.definitions.append(f"{signal} := {self.expression(name, MAX_DEPTH)}")
        self.sum_body = self.expression(self.sum_type, 2, inside_iterate=True)
        self.templates()

    def templates(self):
        rng = self.rng
        scalars = [o for o in self.outputs if o[1] != "boolean"]
        repeated, repeated_type = rng.choice([(f"(N * {rng.randrange(1, 9)})", "integer")] + scalars)
        repeat_count = rng.randrange(1, 5)
        array_bound = rng.randrange(1, 5)
        self.template_outputs = ["MC", "MV", "MA", "MF", "MK", "MR", "ME", "MAR"]
        self.template_body = [
            f"XC := ({self.expression('integer', 1)}) when {self.phase()}",
            f"MC := XC cell {self.phase()} init {rng.randrange(-3, 4)}",
            f"VE := (N * {rng.randrange(1, 9)}) when {self.phase()}",
            f"MV := (var VE init {rng.randrange(-3, 4)}) + N",
            f"H1 := when {self.phase()}",
            f"H2 := when {self.phase()}",
            "MA := H1 after H2",
            "MF := H1 from H2",
            f"MK := H1 count {rng.randrange(1, 5)}",
            f"XR := {repeated} |* {repeat_count}",
            f"MR := integer(XR[{rng.randrange(repeat_count)}])",
            f"HE := when {self.phase()}",
            f"XE := HE |* {repeat_count}",
            f"ME := N when XE[{rng.randrange(repeat_count)}]",
            f"array J to {array_bound} of (| AR := AR[?] + J * N |) with AR := 0 end",
            "MAR := AR",
        ]
        self.template_declarations = [
            "integer XC, VE, AR;",
            "event H1, H2, HE;",
            f"[{repeat_count}] {repeated_type} XR;",
            f"[{repeat_count}] event XE;",
        ]
        self.m8()

    def m8(self):
        rng = self.rng
        first, second, back_first, back_second = (rng.randrange(2, 5) for _ in range(4))
        self.m8_outputs = ["PS", "PQ", "PR", "PP", "PX", "PH", "PT"]
        self.m8_module = [
            f"constant integer CK = ({rng.randrange(0, 20)} * 2 + 1) ** 2;",
            "process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K |);",
            "process SPLIT = ( ? integer X; ! integer Q, R; ) (| Q := X / 3 | R := X modulo 3 |);",
        ]
        self.m8_body = [
            "PS := SCALE{CK}(N) + CK",
            "(PQ, PR) := SPLIT(N)",
            f"PP := N ** {rng.randrange(1, 5)}",
            "LT :: PX := N + 1",
            "PH := N when ^LT",
            "PT := TOGGLE(N)",
        ]
        self.m8_declarations = [
            "use M8;",
            "label LT;",
            "automaton TOGGLE =",
            "  ( ? integer X; ! integer ST; )",
            "  (| Automaton_Initial_State(A)",
            f"   | Automaton_Transition(A, B, when (X modulo {first} = 0))",
            f"   | Automaton_Transition(A, C, when (X modulo {second} = 0), 1)",
            f"   | Automaton_Transition(B, A, when (X modulo {back_first} = 0))",
            f"   | Automaton_Transition(C, A, when (X modulo {back_second} = 1))",
            "   | ST := (1 when Automaton_IsIn(A)) default (2 when Automaton_IsIn(B)) default 3",
            "   | ST ^= X",
            "   |)",
            "  where",
            "    label A, B, C;",
            "  end;",
        ]

    def leaf(self, name, inside_iterate):
        rng = self.rng
        choices = ["literal", "table"] if inside_iterate else ["literal", "count", "delay", "table", "gather", "sum"]
        kind = rng.choice(choices)
        if kind == "literal":
            return literal(rng, name)
        if kind == "count":
            return f"{name}(N)"
        if kind == "delay":
            signal, source = rng.choice([o for o in self.outputs if o[1] != "boolean"] or [("ZN", "integer")])
            return f"{name}(Z{signal})" if signal != "ZN" else f"{name}(ZN)"
        if kind == "table":
            if inside_iterate:
                return f"{name}(TAB[I])"
            return f"{name}(TAB[(integer({self.expression('integer', 1)}) modulo {TABLE_SIZE + 2})])"
        if kind == "gather":
            return f"{name}(G[(N + {rng.randrange(TABLE_SIZE)}) modulo {TABLE_SIZE}])"
        return f"{name}(SUM)"

    def expression(self, name, depth, inside_iterate=False):
        rng = self.rng
        if depth == 0 or rng.random() < 0.2:
            return self.leaf(name, inside_iterate)
        bits, signed = TYPES[name]
        kinds = ["arithmetic", "arithmetic", "convert", "if"]
        kinds += ["negate"] if signed else ["bitwise", "bitwise", "not", "shift", "shift"]
        kinds += ["abs"] if signed else []
        if not inside_iterate:
            kinds += ["merge", "recover", "clocked"]
        kind = rng.choice(kinds)
        below = depth - 1
        if kind == "arithmetic":
            return f"({self.expression(name, below, inside_iterate)} {rng.choice(ARITHMETIC)} {self.expression(name, below, inside_iterate)})"
        if kind == "bitwise":
            return f"({self.expression(name, below, inside_iterate)} {rng.choice(BITWISE)} {self.expression(name, below, inside_iterate)})"
        if kind == "not":
            return f"(not {self.expression(name, below, inside_iterate)})"
        if kind == "abs":
            return f"abs({self.expression(name, min(below, 1), inside_iterate)})"
        if kind == "recover":
            index = f"((integer({self.expression('integer', 0)}) + (N - N)) modulo {TABLE_SIZE + 2})"
            return f"{name}(TAB[{index}] \\\\ {literal(rng, self.table_type)})"
        if kind == "clocked":
            return (f"((({self.expression(name, below)}) when ({self.event(1)}))"
                    f" default (({name}(N) - {name}(N)) + {self.expression(name, below)}))")
        if kind == "negate":
            return f"(-{self.expression(name, below, inside_iterate)})"
        if kind == "shift":
            amount_type = rng.choice(list(TYPES))
            if rng.random() < 0.6:
                amount = f"{amount_type}({rng.choice([0, 1, bits - 1, bits, bits + 1, 31, 32, 33, 63, 64, 65, -1, rng.randrange(70)])})"
            else:
                amount = self.expression(amount_type, below, inside_iterate)
            return f"({self.expression(name, below, inside_iterate)} {rng.choice(SHIFTS)} {amount})"
        if kind == "convert":
            return f"{name}({self.expression(rng.choice(list(TYPES)), below, inside_iterate)})"
        if kind == "merge":
            return (f"((({self.expression(name, below)}) when ((N modulo {rng.randrange(2, 5)}) = {rng.randrange(2)}))"
                    f" default (({name}(N) - {name}(N)) + {self.expression(name, below)}))")
        return (f"(if {self.condition(below, inside_iterate)} then {self.expression(name, below, inside_iterate)}"
                f" else {self.expression(name, below, inside_iterate)})")

    def phase(self):
        modulus = self.rng.randrange(2, 5)
        return f"((N modulo {modulus}) = {self.rng.randrange(modulus)})"

    def event(self, depth):
        rng = self.rng
        kind = rng.choice(["when", "true", "false", "combine"] if depth > 0 else ["when", "true", "false"])
        if kind == "when":
            return f"(when {self.phase()})"
        if kind == "true":
            return f"[: {self.phase()}]"
        if kind == "false":
            return f"[/: {self.phase()}]"
        return f"({self.event(depth - 1)} {rng.choice(EVENT_OPERATORS)} {self.event(depth - 1)})"

    def condition(self, depth, inside_iterate=False):
        rng = self.rng
        below = max(depth - 1, 0)
        kinds = ["compare", "compare", "compare", "not", "connective"] + ([] if inside_iterate else ["left_tt"])
        kind = rng.choice(kinds) if depth > 0 else "compare"
        if kind == "left_tt":
            return f"left_tt(({self.comparison(below)} and (N = N)), ({self.comparison(below)} and (N = N)))"
        if kind == "not":
            return f"(not {self.condition(below, inside_iterate)})"
        if kind == "connective":
            return f"({self.condition(below, inside_iterate)} {rng.choice(CONNECTIVES)} {self.condition(below, inside_iterate)})"
        return self.comparison(below, inside_iterate)

    def comparison(self, depth, inside_iterate=False):
        name = self.rng.choice(list(TYPES))
        return f"({self.expression(name, depth, inside_iterate)} {self.rng.choice(COMPARISONS)} {self.expression(name, depth, inside_iterate)})"

    def source(self, machine):
        outputs = "; ".join([f"{name} {signal}" for signal, name in self.outputs]
                            + [f"integer {signal}" for signal in self.template_outputs + self.m8_outputs])
        signals = [signal for signal, _ in self.outputs]
        delays = [f"Z{signal} := {signal} $" for signal, name in self.outputs if name != "boolean"]
        body = [
            "N := ZN + 1",
            "ZN := N $ init 0",
            "N ^= TICK",
            "I := indices(TABLE_SIZE)",
            f"iterate I of (| R := R[?] + ({self.sum_body}) | P := P[?] next I : R |) with R := {self.sum_type}(0) end",
            "SUM := P[(N - 1) modulo TABLE_SIZE]",
            *(["G := TAB[ORDER]"] if any("G[" in line for line in self.definitions + self.template_body) else []),
            *self.definitions,
            *delays,
            *self.template_body,
            *self.m8_body,
            " ^= ".join(signals + ["TICK"]),
        ]
        module = [
            "constant integer TABLE_SIZE = 8;",
            f"constant [TABLE_SIZE] {self.table_type} TAB = [{', '.join(self.table)}];",
            f"constant [TABLE_SIZE] integer ORDER = [{', '.join(self.order)}];",
            *self.m8_module,
        ]
        declarations = [
            *self.m8_declarations,
            "integer N, ZN;",
            f"{self.sum_type} R, SUM;",
            f"[TABLE_SIZE] {self.sum_type} P;",
            "[TABLE_SIZE] integer I;",
            *([f"[TABLE_SIZE] {self.table_type} G;"] if any("G[" in line for line in self.definitions + self.template_body) else []),
            *[f"{name} Z{signal};" for signal, name in self.outputs if name != "boolean"],
            *self.template_declarations,
        ]
        lines = ["module M8 =", *[f"  {line}" for line in module], "end;"]
        lines += ["process RANDOM =", "  ( ? event START, TICK;", f"    ! {outputs}; )"]
        if machine:
            lines.append(MACHINE_PRAGMAS.rstrip("\n"))
        lines.append(f"  (| {body[0]}")
        lines += [f"   | {line}" for line in body[1:]]
        if machine:
            lines.append(SYSTICK_BODY.rstrip("\n"))
        lines.append("   |)")
        lines.append("  where")
        lines += [f"    {line}" for line in declarations]
        if machine:
            lines.append(SYSTICK_DECLARATIONS.rstrip("\n"))
        lines.append("  end;")
        return "\n".join(lines) + "\n"


class M9bProgram:
    def __init__(self, seed):
        rng = random.Random(seed)
        self.conditions = []
        for index in range(rng.randrange(2, 4)):
            modulus = rng.randrange(2, 5)
            self.conditions.append((f"C{index}", modulus, rng.randrange(modulus)))
        self.signals = [f"S{index}" for index in range(rng.randrange(3, 7))]
        self.definitions = []
        for index, signal in enumerate(self.signals):
            earlier = self.signals[:index]
            kind = rng.choice(["sample", "when", "default", "sync"]) if earlier else "sample"
            if kind == "sample":
                self.definitions.append(f"{signal} := (N * {rng.randrange(1, 9)} + {rng.randrange(0, 9)}) when {self.condition(rng)}")
            elif kind == "when":
                self.definitions.append(f"{signal} := {rng.choice(earlier)} when {self.condition(rng)}")
            elif kind == "default":
                self.definitions.append(f"{signal} := {rng.choice(earlier)} default {rng.choice(earlier + ['N'])}")
            else:
                self.definitions.append(f"{signal} := (N + {rng.randrange(0, 9)}) when {self.condition(rng)}")
                self.definitions.append(f"{signal} ^= {rng.choice(earlier)}")
        left, right = rng.sample(range(len(self.signals)), 2)
        self.relation = (left, rng.choice(list(M9B_RELATIONS)), right)
        exclusive = [(a[0], b[0]) for a in self.conditions for b in self.conditions
                     if a[0] < b[0] and not any(t % a[1] == a[2] and t % b[1] == b[2] for t in range(1, 13))]
        if exclusive:
            first, second = rng.choice(exclusive)
            self.assertion = f"assert(not ({first} and {second}))"
        else:
            name = rng.choice(self.conditions)[0]
            self.assertion = f"assert({name} or not {name})"
        self.cycle = None
        if rng.randrange(2):
            offsets = (rng.randrange(1, 9) * 10, rng.randrange(1, 9) * 100)
            by_name = {condition[0]: condition for condition in self.conditions}
            if exclusive and rng.randrange(2):
                self.cycle = (by_name[first], False, by_name[second], *offsets)
            else:
                condition = rng.choice(self.conditions)
                self.cycle = (condition, True, condition, *offsets)

    def cycle_lines(self):
        if self.cycle is None:
            return []
        (first, _, _), negated, (second, _, _), left_offset, right_offset = self.cycle
        right_condition = f"not {first}" if negated else second
        return [
            f"X := ((Y + {left_offset}) when {first}) default N",
            f"Y := ((X + {right_offset}) when {right_condition}) default N",
            "X ^= Y ^= N",
        ]

    def cycle_expected(self, n):
        (_, first_modulus, first_residue), negated, (_, second_modulus, second_residue), left_offset, right_offset = self.cycle
        first_holds = n % first_modulus == first_residue
        second_holds = not first_holds if negated else n % second_modulus == second_residue
        if first_holds:
            return [n + left_offset, n]
        if second_holds:
            return [n, n + right_offset]
        return [n, n]

    def condition(self, rng):
        name = rng.choice(self.conditions)[0]
        return name if rng.randrange(2) else f"(not {name})"

    def source(self, machine):
        left, relation, right = self.relation
        body = [
            "N := ZN + 1",
            "ZN := N $ init 0",
            "N ^= TICK",
            *[f"{name} := (N modulo {modulus}) = {residue}" for name, modulus, residue in self.conditions],
            *self.definitions,
            f"{self.signals[left]} {relation} {self.signals[right]}",
            self.assertion,
            *self.cycle_lines(),
        ]
        outputs = self.signals + (["X", "Y"] if self.cycle else [])
        lines = ["process RANDOM =", "  ( ? event START, TICK;", f"    ! integer {', '.join(outputs)}; )"]
        if machine:
            lines.append(MACHINE_PRAGMAS.rstrip("\n"))
        lines.append(f"  (| {body[0]}")
        lines += [f"   | {line}" for line in body[1:]]
        if machine:
            lines.append(SYSTICK_BODY.rstrip("\n"))
        lines.append("   |)")
        lines.append("  where")
        lines.append("    integer N, ZN;")
        lines.append(f"    boolean {', '.join(name for name, _, _ in self.conditions)};")
        if machine:
            lines.append(SYSTICK_DECLARATIONS.rstrip("\n"))
        lines.append("  end;")
        return "\n".join(lines) + "\n"


def check_m9b(compiler, seed):
    program = M9bProgram(seed)
    directory = BUILD / "m9b" / str(seed)
    directory.mkdir(parents=True, exist_ok=True)
    outcomes = []
    for variant, machine in (("macos", False), ("mps2", True)):
        source = directory / f"{variant}.sig"
        source.write_text(program.source(machine))
        executable = directory / variant
        compiled = compile_case(compiler, source, executable)
        if compiled.returncode != 0:
            message = compiled.stderr.strip().partition(": error: ")[2]
            source_lines = source.read_text().splitlines()
            located = re.sub(r"at (\d+):(\d+)",
                             lambda found: f"at '{source_lines[int(found[1]) - 1].strip()}':{found[2]}", message)
            outcomes.append(("rejected", located))
            continue
        input_path = directory / f"{variant}.in"
        if machine:
            input_path.unlink(missing_ok=True)
            command = [*QEMU_COMMANDS["mps2-an385"], str(executable)]
        else:
            input_path.write_text("10\n" + "01\n" * TICKS)
            command = [str(executable)]
        lines, timed_out, returncode = read_trace(command, TICKS + 1, input_path)
        outcomes.append(("trace", lines))
    (macos_kind, macos), (mps2_kind, mps2) = outcomes
    if macos_kind != mps2_kind or macos != mps2:
        return [f"{directory}: macos {macos_kind} {macos!r}, mps2 {mps2_kind} {mps2!r}"], macos_kind
    if macos_kind == "rejected" and program.cycle and macos.startswith("causality cycle"):
        return [f"{directory}: exclusive cycle rejected: {macos}"], macos_kind
    if macos_kind == "rejected":
        return [], macos_kind
    left, relation, right = program.relation
    holds = M9B_RELATIONS[relation]
    width = len(program.signals) + (2 if program.cycle else 0)
    ticks = 0
    for step, line in enumerate(macos):
        values = line.split()
        if len(values) != width:
            return [f"{directory}: step {step} has {len(values)} values, expected {width}: {line!r}"], macos_kind
        if not holds(values[left] != "-", values[right] != "-"):
            return [f"{directory}: step {step} breaks {program.signals[left]} {relation} {program.signals[right]}: {line!r}"], macos_kind
        if program.cycle and values[-2:] != ["-", "-"]:
            ticks += 1
            expected = [str(value) for value in program.cycle_expected(ticks)]
            if values[-2:] != expected:
                return [f"{directory}: step {step} has X, Y {values[-2:]}, expected {expected}: {line!r}"], macos_kind
    return [], "cycle" if program.cycle and macos_kind == "trace" else macos_kind


def m9b(compiler, count):
    seeds = [random.SystemRandom().randrange(2**32) for _ in range(count)]
    print(f"m9b seeds: {' '.join(map(str, seeds))}")
    failures = 0
    accepted = 0
    cycles = 0
    for seed in seeds:
        report, kind = check_m9b([str(compiler)], seed)
        accepted += kind in ("trace", "cycle")
        cycles += kind == "cycle"
        if report:
            failures += 1
            print(f"FAIL seed {seed}")
            for line in report:
                print(f"  {line}")
    print(f"{count - failures} seeds passed ({accepted} accepted, {cycles} with an exclusive cycle), {failures} failed")
    return 1 if failures else 0


def affine_source(phase, period):
    return f"""process AFFINE =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := affine_sample{{{phase}, {period}}}(N)
   |)
  where
    integer ZN;
  end;
"""


def partial_source(modulus, branches, otherwise, initial):
    arms = [f"{{{', '.join(map(str, residues))}}}: X ::= N * {factor}" for residues, factor in branches]
    if otherwise is not None:
        arms.append(f"else X ::= {otherwise}")
    lines = ["process PARTIAL =", "  ( ! integer N, Y; )", "  (| N := ZN + 1", "   | ZN := N $ init 0",
             f"   | K := N modulo {modulus}", "   | case K in"]
    lines += [f"       {arm}" for arm in arms]
    lines += ["     end", "   | X ^= N", "   | Y := X", "   |)", "  where", "    integer ZN, K; shared integer X" + ("" if initial is None else f" init {initial}") + ";", "  end;"]
    return "\n".join(lines) + "\n"


def run_m9c_program(compiler, directory, name, text):
    source = directory / f"{name}.sig"
    source.write_text(text)
    executable = directory / name
    compiled = compile_case(compiler, source, executable)
    if compiled.returncode != 0:
        return None, f"{source}: compile failed: {compiled.stderr.strip()}"
    lines, timed_out, returncode = read_trace([str(executable)], TICKS, directory / f"{name}.in")
    return lines, None


def check_m9c(compiler, seed):
    rng = random.Random(seed)
    directory = BUILD / "m9c" / str(seed)
    directory.mkdir(parents=True, exist_ok=True)
    report = []
    period = rng.randrange(1, 5)
    phase = rng.randrange(3 * period)
    lines, failure = run_m9c_program(compiler, directory, "affine", affine_source(phase, period))
    if failure:
        report.append(failure)
    else:
        expected = [f"{tick} {tick if tick > phase and (tick - phase - 1) % period == 0 else '-'}" for tick in range(1, TICKS + 1)]
        if lines != expected:
            report.append(f"{directory}/affine.sig phase {phase} period {period}: trace {lines!r}, expected {expected!r}")
    modulus = rng.randrange(2, 6)
    residues = list(range(modulus))
    rng.shuffle(residues)
    covered = residues[:rng.randrange(1, modulus + 1)]
    branches = []
    while covered:
        size = rng.randrange(1, len(covered) + 1)
        branches.append((sorted(covered[:size]), rng.randrange(1, 100)))
        covered = covered[size:]
    otherwise = rng.randrange(0, 1000) if rng.randrange(2) else None
    initial = rng.randrange(-50, 50) if rng.randrange(2) else None
    lines, failure = run_m9c_program(compiler, directory, "partial", partial_source(modulus, branches, otherwise, initial))
    if failure:
        report.append(failure)
    else:
        expected = []
        held = 0 if initial is None else initial
        for tick in range(1, TICKS + 1):
            picked = [factor for group, factor in branches if tick % modulus in group]
            held = tick * picked[0] if picked else held if otherwise is None else otherwise
            expected.append(f"{tick} {held}")
        if lines != expected:
            report.append(f"{directory}/partial.sig: trace {lines!r}, expected {expected!r}")
    return report


def m9c(compiler, count):
    seeds = [random.SystemRandom().randrange(2**32) for _ in range(count)]
    print(f"m9c seeds: {' '.join(map(str, seeds))}")
    failures = 0
    for seed in seeds:
        report = check_m9c([str(compiler)], seed)
        if report:
            failures += 1
            print(f"FAIL seed {seed}")
            for line in report:
                print(f"  {line}")
    print(f"{count - failures} seeds passed, {failures} failed")
    return 1 if failures else 0


def typed_literal(name, value):
    bits, signed = TYPES[name]
    if not signed and value > LONG_MAX:
        value -= 2**bits
    if value < -LONG_MAX:
        return f"({name}(-{LONG_MAX}) - {name}(1))"
    return f"{name}({value})"


def nested_list(values, dims):
    if not dims:
        return values[0]
    stride = len(values) // dims[0]
    return "[" + ", ".join(nested_list(values[i * stride:(i + 1) * stride], dims[1:]) for i in range(dims[0])) + "]"


def spelling(dims, rng):
    groups = []
    rest = list(dims)
    while rest:
        size = rng.randrange(1, len(rest) + 1)
        groups.append("[" + ", ".join(map(str, rest[:size])) + "]")
        rest = rest[size:]
    return " ".join(groups)


class M10aProgram:
    def __init__(self, seed):
        rng = random.Random(seed)
        self.rank = rng.randrange(1, 5)
        limit = 4 if self.rank <= 2 else 3
        self.dims = [rng.randrange(1, limit + 1) for _ in range(self.rank)]
        self.element = rng.choice(list(TYPES))
        bits, signed = TYPES[self.element]
        low, high = (max(-(2 ** (bits - 1)), -LONG_MAX), 2 ** (bits - 1) - 1) if signed else (0, 2**bits - 1)
        total = 1
        for size in self.dims:
            total *= size
        self.values = [rng.choice([low, high, 0, 1, -1 if signed else 2, rng.randrange(low, high + 1)]) for _ in range(total)]
        self.indices = [[self.index_value(rng, size) for _ in range(TICKS)] for size in self.dims]
        self.axis = rng.randrange(1, self.rank + 1)
        self.low, self.high = rng.randrange(-5, 11), rng.randrange(-5, 11)
        self.spellings = [spelling(self.dims, rng), spelling(self.dims[1:], rng), spelling(self.dims[2:], rng)]
        self.width = self.dims[0]
        self.vector = self.values[:self.width]
        self.scatter = rng.sample(range(self.width), rng.randrange(1, self.width + 1))

    @staticmethod
    def index_value(rng, size):
        if rng.random() < 0.8:
            return rng.randrange(size)
        return rng.choice([-1, size, size + 1, 2147483647, -2147483647])

    def element_at(self, point):
        if any(not 0 <= index < size for index, size in zip(point, self.dims)):
            return 0
        flat = 0
        for index, size in zip(point, self.dims):
            flat = flat * size + index
        return self.values[flat]

    def properties(self, first):
        restructured = [0] * self.width
        for position, index in enumerate(self.scatter):
            restructured[index] = self.vector[position]
        reversed_element = self.vector[self.width - 1 - first] if 0 <= first < self.width else 0
        return [*self.vector, *restructured, *self.vector[:len(self.scatter)], reversed_element]

    def expected(self):
        lines = ["- - - - - - - - - -"]
        block = len(self.values) // self.dims[0]
        for tick in range(1, TICKS + 1):
            point = [column[tick % TICKS] for column in self.indices]
            value = self.element_at(point)
            first = point[0]
            bounded = self.low if first < self.low else self.high if first > self.high else first
            if self.rank == 1:
                whole = self.values
            elif 0 <= first < self.dims[0]:
                whole = self.values[first * block:(first + 1) * block]
            else:
                whole = [0] * block
            lines.append(f"{value} {value} {value} {self.rank * 1000 + self.dims[self.axis - 1] * 10} {bounded} "
                         + " ".join(map(str, whole + self.properties(first))))
        return lines

    def source(self, machine):
        names = [f"I{level}" for level in range(1, self.rank + 1)]
        body = ["N := ZN + 1", "ZN := N $ init 0", "N ^= TICK"]
        body += [f"{name} := P{level}[N modulo {TICKS}]" for level, name in enumerate(names, 1)]
        body.append(f"A := M[{', '.join(names)}]")
        declarations = [f"integer ZN, N, {', '.join(names)};"]
        if self.rank >= 2:
            body += ["R := M[I1]", "B := R" + "".join(f"[{name}]" for name in names[1:])]
            declarations.append(f"{self.spellings[1]} {self.element} R;")
        else:
            body.append("B := M[I1]")
        if self.rank >= 3:
            body += ["S := M[I1, I2]", f"C := S[{', '.join(names[2:])}]"]
            declarations.append(f"{self.spellings[2]} {self.element} S;")
        else:
            body.append("C := M" + "".join(f"[{name}]" for name in names))
        body.append(f"D := dim(M) * 1000 + size(M, {self.axis}) * 10 + I1 - I1")
        body.append(f"E := bounds(I1, {self.low}, {self.high})")
        body.append("F := M next I1 : A" if self.rank == 1 else "F := M[I1]")
        width, picked = self.width, len(self.scatter)
        body += [
            "V := VC",
            f"H := V[0 .. {width - 1}]",
            f"Q := [{', '.join(f'V[{position}]' for position in range(picked))}]",
            "RS := QI : Q",
            "G := RS[QI]",
            f"L := [{', '.join(f'V[{width - 1 - position}]' for position in range(width))}]",
            "LO := L[I1]",
            "V ^= TICK",
        ]
        declarations += [
            f"[{width}] {self.element} V, L;",
            f"[{picked}] {self.element} Q;",
            f"constant [{width}] {self.element} VC = [{', '.join(typed_literal(self.element, value) for value in self.vector)}];",
            f"constant [{picked}] integer QI = [{', '.join(map(str, self.scatter))}];",
        ]
        literals = [typed_literal(self.element, value) for value in self.values]
        declarations.append(f"constant {self.spellings[0]} {self.element} M = {nested_list(literals, self.dims)};")
        for level, column in enumerate(self.indices, 1):
            declarations.append(f"constant [{TICKS}] integer P{level} = [{', '.join(map(str, column))}];")
        lines = ["process M10A =", "  ( ? event START, TICK;",
                 f"    ! {self.element} A, B, C; integer D, E; {self.spellings[0 if self.rank == 1 else 1]} {self.element} F;",
                 f"      [{self.width}] {self.element} H, RS; [{len(self.scatter)}] {self.element} G; {self.element} LO; )"]
        if machine:
            lines.append(MACHINE_PRAGMAS.rstrip("\n"))
        lines.append("  (| " + "\n   | ".join(body))
        if machine:
            lines.append(SYSTICK_BODY.rstrip("\n"))
        lines.append("   |)")
        lines.append("  where")
        lines += [f"    {declaration}" for declaration in declarations]
        if machine:
            lines.append(SYSTICK_DECLARATIONS.rstrip("\n"))
        lines.append("  end;")
        return "\n".join(lines) + "\n"


def check_m10a(compiler, seed):
    program = M10aProgram(seed)
    directory = BUILD / "m10a" / str(seed)
    directory.mkdir(parents=True, exist_ok=True)
    expected = program.expected()
    report = []
    for variant, machine in (("macos", False), ("mps2", True)):
        source = directory / f"{variant}.sig"
        source.write_text(program.source(machine))
        executable = directory / variant
        compiled = compile_case(compiler, source, executable)
        if compiled.returncode != 0:
            report.append(f"{source}: compile failed (exit {compiled.returncode}): {compiled.stderr.strip()}")
            continue
        input_path = directory / f"{variant}.in"
        if machine:
            input_path.unlink(missing_ok=True)
            command = [*QEMU_COMMANDS["mps2-an385"], str(executable)]
        else:
            input_path.write_text("10\n" + "01\n" * TICKS)
            command = [str(executable)]
        lines, timed_out, returncode = read_trace(command, TICKS + 1, input_path)
        if lines != expected:
            report.append(f"{source}: trace {lines!r}, expected {expected!r}")
    return report


def m10a(compiler, count):
    seeds = [random.SystemRandom().randrange(2**32) for _ in range(count)]
    print(f"m10a seeds: {' '.join(map(str, seeds))}")
    failures = 0
    for seed in seeds:
        report = check_m10a([str(compiler)], seed)
        if report:
            failures += 1
            print(f"FAIL seed {seed}")
            for line in report:
                print(f"  {line}")
    print(f"{count - failures} seeds passed, {failures} failed")
    return 1 if failures else 0


def check(compiler, seed):
    program = Program(seed)
    directory = BUILD / str(seed)
    directory.mkdir(parents=True, exist_ok=True)
    traces = []
    for variant, machine in (("macos", False), ("mps2", True)):
        source = directory / f"{variant}.sig"
        source.write_text(program.source(machine))
        executable = directory / variant
        compiled = compile_case(compiler, source, executable)
        if compiled.returncode != 0:
            return [f"{source}: compile failed (exit {compiled.returncode}): {compiled.stderr.strip()}"], variant == "mps2"
        input_path = directory / f"{variant}.in"
        if machine:
            input_path.unlink(missing_ok=True)
            command = [*QEMU_COMMANDS["mps2-an385"], str(executable)]
        else:
            input_path.write_text("10\n" + "01\n" * TICKS)
            command = [str(executable)]
        lines, timed_out, returncode = read_trace(command, TICKS + 1, input_path)
        traces.append((variant, lines, timed_out, returncode))
    (_, expected, _, _), (_, actual, timed_out, returncode) = traces
    if expected == actual:
        return [], False
    report = [f"{directory}: traces differ (mps2 exit {returncode}{', timed out' if timed_out else ''})"]
    for step, (want, got) in enumerate(zip(expected + [None] * len(actual), actual + [None] * len(expected))):
        if want != got:
            report.append(f"  step {step}: macos {want!r}, mps2 {got!r}")
    return report, True


def clocks_dump_compiler(compiler, source, name):
    executable = M9A_BUILD / name
    newest_input = max(compiler.stat().st_mtime, source.stat().st_mtime)
    if executable.exists() and executable.stat().st_mtime >= newest_input:
        return executable
    text = source.read_text()
    if DUMP_PASS_LINE not in text:
        sys.exit(f"{source} has no line {DUMP_PASS_LINE!r}")
    patched = M9A_BUILD / f"{name}.sig"
    patched.write_text(text.replace(DUMP_PASS_LINE, CLOCKS_DUMP_PASS_LINE, 1))
    executable.unlink(missing_ok=True)
    finished = subprocess.run([str(compiler), str(patched), "-o", str(executable)], env={"PATH": ""})
    if finished.returncode != 0:
        sys.exit(f"{compiler} exit {finished.returncode} on {patched}")
    return executable


def dump_columns(dump):
    columns = {}
    lines = dump.decode(errors="replace").split("\n")
    position = 0
    while position < len(lines) and lines[position]:
        name, _, count = lines[position].rpartition(" ")
        if not count.isdigit():
            columns["?"] = lines[position:]
            break
        columns[name] = lines[position + 1:position + 1 + int(count)]
        position += 1 + int(count)
    return columns


def m9a_outcome(compiler, dumper, source, directory):
    executable = directory / "image"
    executable.unlink(missing_ok=True)
    compiled = compile_case([str(compiler)], source, executable)
    dump = directory / "clocks"
    dump.unlink(missing_ok=True)
    compile_case([str(dumper)], source, dump)
    return compiled.returncode, compiled.stdout, compiled.stderr, dump.read_bytes() if dump.exists() else None


def m9a(compiler, against):
    M9A_BUILD.mkdir(parents=True, exist_ok=True)
    against_source = against.with_name(against.name + ".sig")
    if not against_source.exists():
        sys.exit(f"--against {against} needs its source at {against_source}")
    old_dumper = clocks_dump_compiler(against, against_source, "against_clocks")
    new_dumper = clocks_dump_compiler(compiler, SOURCE, "compiler_clocks")
    sources = sorted(s for s in CASES.rglob("*.sig")
                     if s.relative_to(CASES).parts[0] in M9A_SUITES or s.relative_to(CASES).as_posix() in M9A_CASES | M9A_MOVED.keys())
    differing = 0
    missing = 0
    for source in sources:
        name = source.relative_to(CASES).as_posix()
        sides = []
        for side, side_compiler, dumper in (("old", against, old_dumper), ("new", compiler, new_dumper)):
            directory = M9A_BUILD / "cases" / side
            directory.mkdir(parents=True, exist_ok=True)
            sides.append(m9a_outcome(side_compiler, dumper, source, directory))
        (old_status, old_stdout, old_stderr, old_dump), (new_status, new_stdout, new_stderr, new_dump) = sides
        if name in M9A_REJECTED:
            if new_status == 0 or M9A_REJECTED[name] not in new_stderr:
                missing += 1
                print(f"EXPECTED {name}: rejection containing {M9A_REJECTED[name]!r}, got exit {new_status}: {new_stderr.strip()!r}")
            continue
        if name in M9A_MOVED:
            outcome = new_stderr.strip() if new_status else "accepted"
            if M9A_MOVED[name] not in outcome:
                missing += 1
                print(f"EXPECTED {name}: moved to {M9A_MOVED[name]!r}, got exit {new_status}: {outcome!r}")
            else:
                print(f"MOVED {name}: {outcome!r}")
            continue
        report = []
        if old_status != new_status:
            report.append(f"exit {old_status} vs {new_status}")
        if old_stdout != new_stdout:
            report.append("stdout differs")
        if old_stderr != new_stderr:
            report.append(f"stderr {old_stderr.strip()!r} vs {new_stderr.strip()!r}")
        if old_dump != new_dump:
            old_columns = dump_columns(old_dump or b"")
            new_columns = dump_columns(new_dump or b"")
            names = sorted(c for c in old_columns.keys() | new_columns.keys() if old_columns.get(c) != new_columns.get(c))
            report.append(f"clocks dump differs in {', '.join(names) or 'layout'}")
        if report:
            differing += 1
            print(f"DIFF {name}: {'; '.join(report)}")
    print(f"{len(sources)} cases, {differing} differ, {missing} expected rejections missing")
    return 1 if differing or missing else 0


def main():
    arguments = sys.argv[1:]
    compiler = COMPILER
    if "--compiler" in arguments:
        position = arguments.index("--compiler")
        compiler = Path(arguments[position + 1]).resolve()
        del arguments[position:position + 2]
    if "--against" in arguments:
        position = arguments.index("--against")
        against = Path(arguments[position + 1]).resolve()
        del arguments[position:position + 2]
        if arguments != ["m9a"]:
            sys.exit("--against requires the method m9a")
        return m9a(compiler, against)
    if arguments and arguments[0] == "m9b":
        return m9b(compiler, int(arguments[1]) if len(arguments) > 1 else FRESH_SEEDS)
    if arguments and arguments[0] == "m9c":
        return m9c(compiler, int(arguments[1]) if len(arguments) > 1 else FRESH_SEEDS)
    if arguments and arguments[0] == "m10a":
        return m10a(compiler, int(arguments[1]) if len(arguments) > 1 else FRESH_SEEDS)
    fresh_count = int(arguments[0]) if arguments else FRESH_SEEDS
    kept = [int(line) for line in SEEDS.read_text().split()] if SEEDS.exists() else []
    fresh = [random.SystemRandom().randrange(2**32) for _ in range(fresh_count)]
    print(f"fresh seeds: {' '.join(map(str, fresh))}")
    checked = kept + fresh
    failures = 0
    for seed in checked:
        report, backend_difference = check([str(compiler)], seed)
        if report:
            failures += 1
            print(f"FAIL seed {seed}")
            for line in report:
                print(f"  {line}")
            if backend_difference and seed not in kept:
                with SEEDS.open("a") as seeds:
                    seeds.write(f"{seed}\n")
                kept.append(seed)
    print(f"{len(checked) - failures} seeds passed, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
