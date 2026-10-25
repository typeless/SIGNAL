import random
import sys
from pathlib import Path

from run import QEMU_COMMANDS, compile_case, read_trace

ROOT = Path(__file__).resolve().parent.parent
SEEDS = ROOT / "tests" / "differential_seeds.txt"
BUILD = ROOT / "build" / "differential"
COMPILER = ROOT / "build" / "m4" / "stage2"
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
COMPARISONS = ["=", "/=", "<", "<=", ">", ">="]
CONNECTIVES = ["and", "or", "xor"]
LONG_MAX = 2**63 - 1

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
        if not inside_iterate:
            kinds.append("merge")
        kind = rng.choice(kinds)
        below = depth - 1
        if kind == "arithmetic":
            return f"({self.expression(name, below, inside_iterate)} {rng.choice(ARITHMETIC)} {self.expression(name, below, inside_iterate)})"
        if kind == "bitwise":
            return f"({self.expression(name, below, inside_iterate)} {rng.choice(BITWISE)} {self.expression(name, below, inside_iterate)})"
        if kind == "not":
            return f"(not {self.expression(name, below, inside_iterate)})"
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

    def condition(self, depth, inside_iterate=False):
        rng = self.rng
        below = max(depth - 1, 0)
        kind = rng.choice(["compare", "compare", "compare", "not", "connective"]) if depth > 0 else "compare"
        if kind == "not":
            return f"(not {self.condition(below, inside_iterate)})"
        if kind == "connective":
            return f"({self.condition(below, inside_iterate)} {rng.choice(CONNECTIVES)} {self.condition(below, inside_iterate)})"
        name = rng.choice(list(TYPES))
        return f"({self.expression(name, below, inside_iterate)} {rng.choice(COMPARISONS)} {self.expression(name, below, inside_iterate)})"

    def source(self, machine):
        outputs = "; ".join(f"{name} {signal}" for signal, name in self.outputs)
        signals = [signal for signal, _ in self.outputs]
        delays = [f"Z{signal} := {signal} $" for signal, name in self.outputs if name != "boolean"]
        body = [
            "N := ZN + 1",
            "ZN := N $ init 0",
            "N ^= TICK",
            "I := indices(TABLE_SIZE)",
            f"iterate I of (| R := R[?] + ({self.sum_body}) | P := P[?] next I : R |) with R := {self.sum_type}(0) end",
            "SUM := P[(N - 1) modulo TABLE_SIZE]",
            *(["G := TAB[ORDER]"] if any("G[" in line for line in self.definitions) else []),
            *self.definitions,
            *delays,
            " ^= ".join(signals + ["TICK"]),
        ]
        declarations = [
            "constant integer TABLE_SIZE = 8;",
            f"constant [TABLE_SIZE] {self.table_type} TAB = [{', '.join(self.table)}];",
            f"constant [TABLE_SIZE] integer ORDER = [{', '.join(self.order)}];",
            "integer N, ZN;",
            f"{self.sum_type} R, SUM;",
            f"[TABLE_SIZE] {self.sum_type} P;",
            "[TABLE_SIZE] integer I;",
            *([f"[TABLE_SIZE] {self.table_type} G;"] if any("G[" in line for line in self.definitions) else []),
            *[f"{name} Z{signal};" for signal, name in self.outputs if name != "boolean"],
        ]
        lines = ["process RANDOM =", "  ( ? event START, TICK;", f"    ! {outputs}; )"]
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
            command = [*QEMU_COMMANDS["m6"], str(executable)]
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


def main():
    arguments = sys.argv[1:]
    compiler = COMPILER
    if "--compiler" in arguments:
        position = arguments.index("--compiler")
        compiler = Path(arguments[position + 1]).resolve()
        del arguments[position:position + 2]
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
